#!/usr/bin/env node
/**
 * erklaer-vorschau.mjs — Vorschau einer Erklär-Charge für Rasit und Lena (E2b), vor dem Einspielen.
 *
 *   node tools/erklaer-vorschau.mjs docs/prefill/erklaer-k8-linfkt.json docs/prefill/erklaer-k8-linfkt-vorschau.html
 *   node tools/erklaer-vorschau.mjs docs/prefill/erklaer-k8-linfkt.json --export <ordner>
 *
 * HTML: je Skill Kernidee für Kernidee, die Varianten nebeneinander, jeder Schritt als Tablet-Bildschirm
 * (iPad quer, 1194 × 834, verkleinert) wie im Schüler-Dummy: Text links, Bild rechts, Formeln als SVG
 * (formeln-svg.mjs), Bilder vom Generator im Theme 'dunkel'. Passt ein Bildschirm nicht ohne Scrollen,
 * markiert die Seite ihn rot. Unter jedem Check: Lösung, Fehlbilder und welche Variante danach kommt
 * (nur für Prüfer, das Kind sieht das nie).
 *
 * --export: Markdown + PNG (Theme 'hell') für die Zweitprüfung, OHNE Lösungen und known_errors der Checks.
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { texZuSvg } from './formeln-svg.mjs';
import { BILD_THEME, bilderPython, bloecke } from './erklaer-lib.mjs';
import { varianteNach } from './erklaer-rechnen.mjs';

const [chargePfad, ziel, ordner] = process.argv.slice(2);
if (!chargePfad || !ziel) {
  console.error('Aufruf: erklaer-vorschau.mjs <charge.json> <ziel.html> | --export <ordner>');
  process.exit(2);
}
const lies = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const charge = lies(chargePfad);
const checks = new Map(lies(charge.check_charge).aufgaben.map((a) => [a.id, a]));
const bestand = lies(charge.bestand);
const klartext = new Map(bestand.skills.flatMap((s) => s.fehlbilder.map((f) => [f.slug, f.klartext])));
const label = new Map(bestand.skills.map((s) => [s.skill_key, s.label]));
const skills = [...new Set(charge.kernideen.map((k) => k.skill_key))];
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const ARTNAME = { erklaerung: 'Erklärung', beispiel: 'Beispiel' };

// ── Export für die Zweitprüfung ─────────────────────────────────────────────
if (ziel === '--export') {
  if (!ordner) { console.error('--export braucht einen Ordner'); process.exit(2); }
  fs.mkdirSync(ordner, { recursive: true });
  const md = ['# Erklärsequenzen (Entwurf) — für die Zweitprüfung', '',
    'Formeln stehen in TeX zwischen $…$. Jede Variante B/C ist für die genannten Fehlbilder gedacht.', ''];
  const alle = charge.kernideen.flatMap((k) => k.schritte.filter((s) => s.bild));
  const png = (svg, name) => {
    const datei = path.join(ordner, `${name}.svg`);
    fs.writeFileSync(datei, svg);
    const p = path.join(ordner, `${name}.png`);
    if (spawnSync('convert', ['-background', 'white', '-density', '110', datei, p]).status === 0) { fs.rmSync(datei); return p; }
    return datei;
  };
  const bilder = bilderPython(alle.map((s) => s.bild), 'hell');
  const datei = new Map(alle.map((s, i) => [s.id, png(bilder[i].svg, `bild-${String(i + 1).padStart(2, '0')}`)]));
  for (const skill of skills) {
    md.push(`## ${label.get(skill)} (${skill})`, '');
    for (const k of charge.kernideen.filter((x) => x.skill_key === skill)) {
      md.push(`### Kernidee ${k.nr}: ${k.titel}`, '');
      for (const s of k.schritte) {
        const fb = s.fehlbild_slugs.map((x) => `${x} („${klartext.get(x)}“)`).join(', ');
        md.push(`#### Variante ${s.variante} · ${ARTNAME[s.art]}${fb ? ` · für Fehlbild ${fb}` : ''}`, '');
        md.push(s.inhalt, '');
        if (s.bild) md.push(`Bild: ${path.resolve(datei.get(s.id))} (Alt-Text: ${s.bild.alt})`, '');
      }
      for (const c of k.checks) md.push(`#### Check ${c.ref}`, '', checks.get(c.task_id).basis.frage, '');
    }
  }
  const text = md.join('\n');
  if (/known_errors|correct_answers|"antwort"|solution/.test(text)) { console.error('Abbruch: Lösungsschlüssel im Export'); process.exit(1); }
  fs.writeFileSync(path.join(ordner, 'sequenzen.md'), text + '\n');
  console.log(`${path.join(ordner, 'sequenzen.md')}: ${alle.length} Bilder`);
  process.exit(0);
}

// ── HTML ────────────────────────────────────────────────────────────────────
const alleBilder = [
  ...charge.kernideen.flatMap((k) => k.schritte.filter((s) => s.bild).map((s) => ({ key: s.id, bild: s.bild }))),
  ...[...checks.values()].filter((a) => a.basis.figur).map((a) => ({ key: a.id, bild: a.basis.figur })),
];
// Inline im selben Dokument: die feste clipPath-ID des Generators je Bild eindeutig machen.
const svgVon = new Map(bilderPython(alleBilder.map((b) => b.bild), BILD_THEME)
  .map((r, i) => [alleBilder[i].key, r.svg.replaceAll('edvance-plot', `b${i}-edvance-plot`)]));
let formelNr = 0;
const inline = (text) => esc(text).replace(/\$([^$]+)\$/g, (m, tex) => {
  const svg = texZuSvg(tex.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
  formelNr += 1;
  return `<span class="f">${svg}</span>`;
});
const textHtml = (inhalt) => bloecke(inhalt).map((b) => {
  if (b.art === 'titel') return `<h1>${inline(b.text)}</h1>`;
  if (b.art === 'merk') return `<div class="merk">${inline(b.text)}</div>`;
  if (b.art === 'schritte') return `<div class="worked">${b.zeilen.map((z, i) => `<div class="ws"><i>${i + 1}</i><span>${inline(z)}</span></div>`).join('')}</div>`;
  return `<p>${inline(b.text)}</p>`;
}).join('');
const dots = (k, n, teil) => `<div class="dots"><span class="kd">${Array.from({ length: n }, (_, i) => `<i class="${i + 1 < k ? 'done' : i + 1 === k ? 'on' : ''}"></i>`).join('')}</span><span class="st">Kernidee ${k} von ${n} · <b>${teil}</b></span></div>`;
const bildschirm = (kopf, links, rechts, fuss) => `<div class="tablet"><div class="screen"><div class="seq"><div class="seqtext">${kopf}${links}</div>${rechts ? `<div class="graph">${rechts}</div>` : ''}</div><div class="foot">${fuss}</div></div><span class="zulang">passt nicht ohne Scrollen</span></div>`;

const teile = [];
for (const skill of skills) {
  const ks = charge.kernideen.filter((x) => x.skill_key === skill);
  teile.push(`<section><h2>${esc(label.get(skill))} <code>${skill}</code></h2>`);
  for (const k of ks) {
    teile.push(`<h3>Kernidee ${k.nr} von ${ks.length}: ${esc(k.titel)}</h3><div class="varianten">`);
    for (const v of [...new Set(k.schritte.map((s) => s.variante))]) {
      const ss = k.schritte.filter((s) => s.variante === v);
      const fb = ss.flatMap((s) => s.fehlbild_slugs);
      teile.push(`<div class="variante"><div class="vkopf">Variante ${v}${fb.length ? ` · für ${fb.map((x) => `<span title="${esc(klartext.get(x) ?? '')}">${x}</span>`).join(', ')}` : ' · Start'}</div>`);
      for (const s of ss) {
        const teil = s.art === 'beispiel' ? 'Beispiel' : v === 'A' ? 'Erklärung' : 'Erklärung, Runde 2';
        const eyebrow = s.art === 'beispiel' ? 'So geht’s' : v === 'A' ? `Neu für dich: ${esc(label.get(skill))}` : 'Anders erklärt';
        teile.push(bildschirm(`${dots(k.nr, ks.length, teil)}<div class="eyebrow">${eyebrow}</div>`, textHtml(s.inhalt),
          s.bild ? svgVon.get(s.id) : '', s.art === 'beispiel' ? '<span class="btn">Jetzt ich</span>' : '<span class="btn">Weiter</span>'));
        if (s.bild) teile.push(`<div class="alt">Alt-Text: ${esc(s.bild.alt)}</div>`);
      }
      teile.push('</div>');
    }
    teile.push('</div>');
    for (const c of k.checks) {
      const a = checks.get(c.task_id);
      teile.push(`<div class="checkzeile">${bildschirm(`${dots(k.nr, ks.length, 'Check')}<div class="eyebrow">Kurz prüfen</div>`,
        a.basis.frage.split('\n\n').map((x) => `<p class="prompt">${esc(x)}</p>`).join('') + '<div class="feld">▢</div>',
        a.basis.figur ? svgVon.get(a.id) : '', '<span class="btn">Abgeben</span>')}`);
      const ke = new Map();
      for (const [wert, slug] of Object.entries(a.basis.known_errors)) { if (!ke.has(slug)) ke.set(slug, []); ke.get(slug).push(wert); }
      // Ab dem zweiten Check (Runde 2) heißt falsch: Signal (erklaerrunden_bis_signal = 2).
      const zweiter = c.reihenfolge >= 2;
      const zeilen = [...ke].map(([slug, werte]) => {
        const n = zweiter ? { variante: '–', grund: 'Signal an den Coach, Fehlbild wird gespeichert' } : varianteNach(k, slug);
        return `<tr><td>${werte.map(esc).join(' · ')}</td><td><b>${slug}</b><br><small>${esc(klartext.get(slug) ?? '')}</small></td><td>${n.variante === '–' ? '' : `Variante ${n.variante} `}<small>(${n.grund})</small></td></tr>`;
      });
      const ohne = zweiter ? { variante: '–', grund: 'Signal an den Coach' } : varianteNach(k, null);
      zeilen.push(`<tr><td>jede andere falsche Antwort</td><td>kein Fehlbild</td><td>${ohne.variante === '–' ? '' : `Variante ${ohne.variante} `}<small>(${ohne.grund})</small></td></tr>`);
      teile.push(`<div class="pruefer"><div class="vkopf">Nur für Prüfer · Runde ${c.reihenfolge} · ${esc(c.ref)} · ${esc(a.titel)}</div>
        <p><b>Richtig:</b> ${a.loesung.correct_answers.wert.slice(0, 6).map(esc).join(' · ')} …</p>
        <p><b>Lösungsweg:</b> ${esc(a.loesung.solution.wert).replace(/\n/g, '<br>')}</p>
        <table><tr><th>Falsche Antwort</th><th>Fehlbild</th><th>danach</th></tr>${zeilen.join('')}</table>
        ${k.ohne_variante ? Object.entries(k.ohne_variante).map(([s, g]) => `<p><small>${s} ohne eigene Variante: ${esc(g)}</small></p>`).join('') : ''}
        <p><small>Richtig → nächste Kernidee bzw. Üben. Nach erklaerrunden_bis_signal (2) falschen Checks dieser Kernidee: Signal an den Coach.</small></p></div></div>`);
    }
  }
  teile.push('</section>');
}

const html = `<!doctype html>
<html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Erklärsequenzen Vorschau</title>
<style>
:root{--navy:#0d1b3d;--navy-2:#16264f;--cream:#f6efe2;--cream-55:rgba(246,239,226,.62);--cream-20:rgba(246,239,226,.2);--gold:#e8b44a;--gold-light:#f3cf7f;--gold-soft:#b89148;--line:rgba(246,239,226,.14);--rot:#ff6b6b;--paper:#f7f5f0;--ink:#1d2433}
body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.5 system-ui,sans-serif}
header,section{max-width:1500px;margin:0 auto;padding:16px}
h2{border-bottom:2px solid var(--ink);padding-bottom:6px}
h3{margin:28px 0 10px}
.varianten{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:16px}
.variante{display:flex;flex-direction:column;gap:8px}
.vkopf{font-weight:600;font-size:13px;letter-spacing:.04em;text-transform:uppercase}
.tablet{position:relative;width:100%;aspect-ratio:1194/834;container-type:inline-size;border-radius:14px;overflow:hidden;background:var(--navy)}
.screen{position:absolute;inset:0;width:1194px;height:834px;transform-origin:0 0;transform:scale(calc(100cqw / 1194px));padding:40px 56px 0;box-sizing:border-box;color:var(--cream);background:radial-gradient(ellipse at top left,var(--navy-2),var(--navy));display:flex;flex-direction:column}
.seq{flex:1;display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:48px;align-items:center;min-height:0;overflow:hidden}
.seqtext{display:flex;flex-direction:column;gap:14px;min-width:0}
.seqtext h1{font:600 36px/1.2 Georgia,serif;margin:0}
.seqtext p{margin:0;font-size:18.5px;line-height:1.55}
.seqtext p.prompt{font-size:22px}
.eyebrow{font-size:13px;letter-spacing:.14em;text-transform:uppercase;color:var(--gold-light)}
.merk{border-left:3px solid var(--gold);padding:6px 0 6px 14px;font:24px Georgia,serif;color:var(--gold-light)}
.worked{display:flex;flex-direction:column;gap:10px}
.worked .ws{display:flex;gap:12px;align-items:baseline;font-size:17.5px}
.worked .ws i{font-style:normal;width:26px;height:26px;border-radius:50%;border:1px solid var(--gold-soft);color:var(--gold-light);display:inline-flex;align-items:center;justify-content:center;font-size:13px;flex:none}
.dots{display:flex;align-items:center;gap:14px}
.dots .kd{display:flex;gap:6px}.dots .kd i{width:28px;height:6px;border-radius:3px;background:var(--cream-20)}
.dots .kd i.on{background:var(--gold)}.dots .kd i.done{background:var(--gold-soft)}
.dots .st{font-size:13px;color:var(--cream-55)}.dots .st b{color:var(--gold-light)}
.graph{justify-self:center;max-width:440px;width:100%}.graph svg{width:100%;height:auto;max-height:520px;display:block}
.f svg{vertical-align:middle;color:var(--cream)}.merk .f svg{color:var(--gold-light)}
.feld{border:1px solid var(--line);border-radius:12px;padding:14px 18px;font-size:22px;width:220px}
.foot{height:96px;display:flex;align-items:center;justify-content:flex-end;border-top:1px solid var(--line)}
.btn{background:var(--gold);color:var(--navy);border-radius:12px;padding:14px 26px;font-weight:600;font-size:18px}
.zulang{display:none;position:absolute;top:8px;right:8px;background:var(--rot);color:#fff;font-size:12px;padding:2px 8px;border-radius:6px}
.tablet.ueber{outline:3px solid var(--rot)}.tablet.ueber .zulang{display:block}
.alt{font-size:12px;color:#667}
.checkzeile{display:grid;grid-template-columns:minmax(420px,1fr) minmax(360px,1fr);gap:16px;margin-top:16px;align-items:start}
.pruefer{background:#fff;border:1px dashed #889;border-radius:12px;padding:12px 16px}
.pruefer table{border-collapse:collapse;width:100%;font-size:13px}.pruefer td,.pruefer th{border-top:1px solid #dde;padding:6px;text-align:left;vertical-align:top}
@media (max-width:900px){.checkzeile{grid-template-columns:1fr}.varianten{grid-template-columns:1fr}}
</style></head><body>
<header><h1>Erklärsequenzen ${esc(bestand.thema_key)} — Vorschau (Entwurf, KI)</h1>
<p>Erzeugt von <code>tools/erklaer-vorschau.mjs</code> aus <code>${esc(chargePfad)}</code>. Nichts davon ist geprüft oder freigegeben.
Jeder Rahmen ist ein Tablet-Bildschirm (iPad quer). Rot umrandet: Inhalt passt nicht ohne Scrollen.
Formeln und Bilder wie in der App (SVG). Stellschrauben: kernideen_max ${charge.einstellungen.kernideen_max}, check_aufgaben_je_kernidee ${charge.einstellungen.check_aufgaben_je_kernidee}.</p></header>
${teile.join('\n')}
<script>
for (const t of document.querySelectorAll('.tablet')) {
  const s = t.querySelector('.seq');
  if (s.scrollHeight > s.clientHeight + 1 || s.scrollWidth > s.clientWidth + 1) t.classList.add('ueber');
}
</script>
</body></html>
`;
fs.writeFileSync(ziel, html);
console.log(`${ziel}: ${skills.length} Skill(s), ${charge.kernideen.length} Kernideen, ${formelNr} Formeln`);
