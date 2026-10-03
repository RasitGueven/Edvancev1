#!/usr/bin/env node
/**
 * k8-lgs-charge.mjs — erzeugt docs/prefill/k8-lgs.json (Charge-Format von vorlauf-build.mjs) aus
 * tools/k8-lgs-aufgaben.mjs und tools/k8-lgs-aufgaben-2.mjs. Vor dem Schreiben wird exakt geprueft
 * (prefill-rechnen, Brueche statt Gleitkomma); bei jeder Abweichung bricht das Skript ab:
 *   - jede Gleichung (gl, MC-Optionen) wird in a·x + b·y = c zerlegt; steht das System in der Frage,
 *     muss es dort woertlich stehen; bei Figuren muss gl genau die gezeichneten Geraden beschreiben,
 *   - x und y sind die eindeutige Loesung (Cramer), die MC-Antwort ist die echte Loesungsanzahl,
 *     die richtige Systemoption ist gleichwertig zu gl, jede andere nicht,
 *   - jeder falsche Wert ist nachgerechnet, keiner steht unter den richtigen Schreibweisen,
 *   - sechs Aufgaben je Knoten, jedes neue Fehlbild in mindestens drei Aufgaben, alt_text ohne Ziffer,
 *     Schnittpunkte ganzzahlig, mindestens eine Einheit vom Fensterrand, Steigungen |m| <= 2.
 *
 *   node tools/k8-lgs-charge.mjs     # schreibt die Charge (ids bleiben stabil)
 *
 * Danach: node tools/vorlauf-build.mjs docs/prefill/k8-lgs.json 20261003104947 aufgaben_k8_lgs
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import { zahl, Q } from './prefill-rechnen.mjs';
import { A as A1 } from './k8-lgs-aufgaben.mjs';
import { A as A2 } from './k8-lgs-aufgaben-2.mjs';

const A = [...A1, ...A2];
const ALGEBRA_FUNKTIONEN = 'edbb548a-54d9-4a8f-8be4-3052f9025524'; // Themengebiet „Algebra & Funktionen"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;
const NEU = ['nicht_alle_glieder_multipliziert', 'seiten_ungleich_verknuepft', 'loesungsanzahl_verwechselt', 'parallele_uebersehen'];
const SKILLS = ['gleichung_lgs_einsetzen', 'gleichung_lgs_gleichsetzen', 'gleichung_lgs_addition', 'gleichung_lgs_grafisch', 'gleichung_lgs_sachaufgabe'];
const ANZAHL = [{ id: 'a', label: 'genau eine Lösung' }, { id: 'b', label: 'keine Lösung' }, { id: 'c', label: 'unendlich viele Lösungen' }];

// ── Schreibweisen (wie k8-linfkt-charge) ───────────────────────────────────────
// lsa_is_correct und lsa_fehlbild_match vergleichen Text (trim, Komma->Punkt, lower); das
// Unicode-Minus und ein fuehrendes "+" normalisieren sie NICHT. Je Wert deshalb: Komma/Punkt,
// "-"/"−"/"- ", "+" bei positiven Werten, mit Einheit (mit und ohne Leerzeichen).
function formen(wert, einheit) {
  const s = wert.replace('.', ',');
  const zahlen = s.includes(',') ? [s, s.replace(',', '.')] : [s];
  const vz = [];
  for (const z of zahlen) {
    if (z.startsWith('-')) vz.push(z, `−${z.slice(1)}`, `- ${z.slice(1)}`);
    else if (z !== '0') vz.push(z, `+${z}`);
    else vz.push(z);
  }
  const out = [...vz];
  if (einheit) for (const v of vz) out.push(`${v} ${einheit}`, `${v}${einheit}`);
  return [...new Set(out)];
}

// ── Gleichungen exakt ──────────────────────────────────────────────────────────
const punkt = (s) => String(s).replace(/(\d),(\d)/g, '$1.$2');
const q = (n) => Q.von(String(n));
/** "3x - 2y = 7" -> [a, b, c] mit a·x + b·y = c (Q); prueft Linearitaet an zwei weiteren Stellen. */
function koeff(gl) {
  const seiten = gl.split('=');
  if (seiten.length !== 2) throw new Error(`keine Gleichung: "${gl}"`);
  const t = `(${punkt(seiten[0])})-(${punkt(seiten[1])})`.replace(/x/g, 'u');
  const D = (u, y) => zahl(t, { u: q(u), y: q(y) });
  const d0 = D(0, 0), a = D(1, 0).sub(d0), b = D(0, 1).sub(d0);
  for (const [u, y] of [[2, 3], [-1, 5]]) {
    if (!D(u, y).eq(d0.add(a.mul(q(u))).add(b.mul(q(y))))) throw new Error(`nicht linear: "${gl}"`);
  }
  if (a.istNull() && b.istNull()) throw new Error(`keine Variable: "${gl}"`);
  return [a, b, d0.neg()];
}
const proportional = (e, f) => [[0, 1], [0, 2], [1, 2]].every(([i, j]) => e[i].mul(f[j]).eq(e[j].mul(f[i])));
const gleichesSystem = (s, t) => proportional(s[0], t[0]) && proportional(s[1], t[1]);
const det = ([[a1, b1], [a2, b2]]) => a1.mul(b2).sub(a2.mul(b1));
function loesung(s) {
  const [[a1, b1, c1], [a2, b2, c2]] = s;
  const d = det(s);
  if (d.istNull()) return null;
  return { x: c1.mul(b2).sub(c2.mul(b1)).div(d), y: a1.mul(c2).sub(a2.mul(c1)).div(d) };
}
const anzahl = (s) => (loesung(s) ? 'a' : proportional(s[0], s[1]) ? 'c' : 'b');
// Rechnung fuer pruefung (verify-prefill rechnet sie nach): Cramer mit den Koeffizienten.
const k = (v) => `(${v})`;
const cramer = (s, was) => {
  const [[a1, b1, c1], [a2, b2, c2]] = s;
  const nenner = `(${k(a1)}*${k(b2)}-${k(a2)}*${k(b1)})`;
  return was === 'x' ? `(${k(c1)}*${k(b2)}-${k(c2)}*${k(b1)})/${nenner}` : `(${k(a1)}*${k(c2)}-${k(a2)}*${k(c1)})/${nenner}`;
};
const optionSystem = (label) => label.split(';').map((g) => koeff(g.replace(/^\s*I{1,2}:\s*/, '')));

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k8-lgs-ids.json';
const IDS = fs.existsSync(IDS_PFAD) ? JSON.parse(fs.readFileSync(IDS_PFAD, 'utf8')) : {};
for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
fs.writeFileSync(IDS_PFAD, JSON.stringify(IDS, null, 1) + '\n');

// ── Charge bauen ───────────────────────────────────────────────────────────────
const fehler = [];
const slugsVerwendet = new Map();
const proSkill = new Map();
const merkeSlug = (slug, ref) => { if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set()); slugsVerwendet.get(slug).add(ref); };

function pruefeSystem(a, wo) {
  const s = a.gl.map(koeff);
  if (a.inFrage && !(a.frage.includes(`I: ${a.gl[0]}`) && a.frage.includes(`II: ${a.gl[1]}`))) fehler.push(`${wo}: System steht nicht woertlich in der Frage`);
  if (a.figur) {
    const p = a.figur.params;
    const geraden = p.funktionen.map((f) => [q(f.m).neg(), q(1), q(f.b)]);
    if (!gleichesSystem(s, geraden)) fehler.push(`${wo}: gl beschreibt nicht die gezeichneten Geraden`);
    if (p.funktionen.some((f) => Math.abs(f.m) > 2)) fehler.push(`${wo}: Steigung steiler als 2`);
    if (/\d/.test(a.figur.alt_text)) fehler.push(`${wo}: alt_text mit Ziffer`);
    const l = loesung(s);
    if (l) {
      const ganz = l.x.d === 1n && l.y.d === 1n;
      const xi = Number(l.x.n), yi = Number(l.y.n);
      if (!ganz || xi < p.x_min + 1 || xi > p.x_max - 1 || yi < p.y_min + 1 || yi > p.y_max - 1) fehler.push(`${wo}: Schnittpunkt (${l.x} | ${l.y}) nicht gut ablesbar im Fenster`);
    }
  }
  return s;
}

const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  if (!SKILLS.includes(a.skill)) fehler.push(`${wo}: unbekannter Skill ${a.skill}`);
  proSkill.set(a.skill, (proSkill.get(a.skill) ?? 0) + 1);
  if (a.figur && a.skill !== 'gleichung_lgs_grafisch') fehler.push(`${wo}: Figur nur bei gleichung_lgs_grafisch`);
  let s;
  try { s = pruefeSystem(a, wo); } catch (e) { fehler.push(`${wo}: ${e.message}`); return null; }
  const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
  const typical = { wert: a.ke.map((e) => ({ error: e.error, socratic_question: e.frage })), sicher: 'hoch',
    grund: `Aus acceptance.known_errors (${[...new Set(a.ke.map((e) => e.slug))].join(', ')}).` };
  for (const e of a.ke) merkeSlug(e.slug, a.ref);
  const felder = {
    afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
    est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
    curriculum_grade: { wert: 8, sicher: 'hoch', grund: 'Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.' },
    cluster_id: { wert: ALGEBRA_FUNKTIONEN, sicher: 'hoch', grund: 'Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.' },
    competency_content: { wert: 'arithmetik_algebra', sicher: 'hoch', grund: 'Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).' },
    competency_process: { wert: a.prozess, sicher: 'mittel', grund: {
      Operieren: 'Lösen nach festem Verfahren.', Darstellen: 'Lösung aus der grafischen Darstellung ablesen.',
      Argumentieren: 'Lösungsanzahl aus Rechnung oder Lage der Geraden begründen.', Problemlösen: 'Rechenweg (Faktor) selbst finden, dann lösen.',
      Modellieren: 'Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.' }[a.prozess] },
    needs_image: { wert: !!a.figur, sicher: 'hoch', grund: a.figur
      ? 'Ohne Abbildung (zwei Geraden im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.'
      : 'Alle Angaben stehen im Text, keine Abbildung nötig.' },
  };
  const basis = { skill_key: a.skill, source_ref: a.ref, frage: a.frage, ...(a.figur ? { figur: a.figur } : {}) };
  const kopf = { nr: i + 1, id: IDS[a.ref], titel: a.titel };
  const leer = { hints: 'Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.' };

  // ── MC: Loesungsanzahl ──
  if (a.typ === 'mc') {
    const ist = anzahl(s);
    if (ist !== a.richtig) fehler.push(`${wo}: Loesungsanzahl ist ${ist}, nicht ${a.richtig}`);
    if (ist === 'a') fehler.push(`${wo}: MC-Aufgabe mit genau einer Loesung`);
    const known = {};
    for (const e of a.ke) {
      if (e.mc === a.richtig || !ANZAHL.some((o) => o.id === e.mc)) fehler.push(`${wo}: MC-Fehlbild auf Option ${e.mc}`);
      known[e.mc] = e.slug;
    }
    if (Object.keys(known).length !== 2) fehler.push(`${wo}: nicht jede falsche Option hat ein Fehlbild`);
    return { ...kopf, basis: { ...basis, input_type: 'MC', options: ANZAHL, known_errors: known }, felder,
      loesung: { correct_answers: { wert: [a.richtig], sicher: 'hoch', grund: 'Lösungsanzahl aus dem Koeffizientensystem nachgerechnet (Determinante, Verträglichkeit).' },
        solution: { wert: a.weg, sicher: 'hoch', grund: 'Nachgerechnet.' }, typical_errors: typical },
      leer, pruefung: [] };
  }

  // ── MULTI_PART: (MC-Teil) + x + y ──
  const l = loesung(s);
  if (!l) { fehler.push(`${wo}: System nicht eindeutig loesbar`); return null; }
  if (!l.x.eq(zahl(punkt(a.x))) || !l.y.eq(zahl(punkt(a.y)))) fehler.push(`${wo}: Loesung ist (${l.x} | ${l.y}), nicht (${a.x} | ${a.y})`);
  const mc = a.typ === 'sach3';
  const nrX = mc ? 2 : 1, nrY = nrX + 1;
  const parts = [];
  const known = {};
  const teile = {};
  const zeitTeile = {};
  if (mc) {
    let richtige = 0;
    for (const o of a.options) {
      const gleich = gleichesSystem(optionSystem(o.label), s);
      if (gleich) richtige += 1;
      if (gleich !== (o.id === a.richtig)) fehler.push(`${wo}: Option ${o.id} ${gleich ? 'gleichwertig zu gl, aber nicht richtig' : 'als richtig markiert, aber nicht gleichwertig'}`);
    }
    if (richtige !== 1) fehler.push(`${wo}: ${richtige} gleichwertige Optionen`);
    parts.push({ nr: 1, kind: 'mc', prompt: a.mcPrompt, options: a.options });
    known['1'] = {};
    for (const e of a.ke.filter((x) => x.mc)) {
      if (e.mc === a.richtig) fehler.push(`${wo}: Fehlbild auf der richtigen Option`);
      known['1'][e.mc] = e.slug;
    }
    if (Object.keys(known['1']).length !== a.options.length - 1) fehler.push(`${wo}: nicht jede falsche Option hat ein Fehlbild`);
    teile['1'] = { afb: { wert: a.afb, sicher: 'mittel', grund: 'Wie die Aufgabe.' },
      competency_content: { wert: 'arithmetik_algebra', sicher: 'hoch', grund: 'Wie die Aufgabe.' },
      antwort: { wert: [a.richtig], sicher: 'hoch', grund: 'Option gleichwertig zum nachgerechneten System (Koeffizientenvergleich).' } };
    zeitTeile['1'] = 30;
  }
  const pruefung = [];
  for (const [nr, was, prompt] of [[nrX, 'x', a.teile[0]], [nrY, 'y', a.teile[1]]]) {
    const einheit = a.einheit[was];
    parts.push({ nr, kind: 'short_input', prompt });
    const richtig = formen(a[was], einheit);
    const ke = {};
    for (const e of a.ke.filter((x) => x[was])) {
      const [wert, rechnung] = e[was];
      if (!zahl(rechnung).eq(zahl(punkt(wert)))) fehler.push(`${wo} ${was} ${e.slug}: ${rechnung} = ${zahl(rechnung)}, nicht ${wert}`);
      if (zahl(punkt(wert)).eq(zahl(punkt(a[was])))) fehler.push(`${wo} ${was}: falscher Wert ${wert} = richtige Antwort`);
      for (const f of formen(wert, einheit)) {
        if (richtig.includes(f)) fehler.push(`${wo} ${was}: falscher Wert ${f} steht unter den richtigen`);
        if (ke[f] && ke[f] !== e.slug) fehler.push(`${wo} ${was}: Wert ${f} mit zwei Slugs`);
        ke[f] = e.slug;
      }
      pruefung.push({ teil: String(nr), rechnung, antwort: wert, rolle: `fehlbild:${e.slug}` });
    }
    if (!Object.keys(ke).length) fehler.push(`${wo} ${was}: Teil ohne known_errors`);
    known[String(nr)] = ke;
    pruefung.unshift({ teil: String(nr), rechnung: cramer(s, was), antwort: a[was] });
    teile[String(nr)] = { afb: { wert: a.afb, sicher: 'mittel', grund: 'Wie die Aufgabe.' },
      competency_content: { wert: 'arithmetik_algebra', sicher: 'hoch', grund: 'Wie die Aufgabe.' },
      antwort: { wert: richtig, sicher: 'hoch', grund: 'Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.' } };
  }
  zeitTeile[String(nrY)] = 15;
  zeitTeile[String(nrX)] = zeit - 15 - (mc ? 30 : 0);
  return { ...kopf,
    basis: { ...basis, input_type: 'MULTI_PART', parts, known_errors: known, zeit_teile: zeitTeile },
    felder, teile,
    loesung: { solution: { wert: a.weg, sicher: 'hoch', grund: 'Nachgerechnet.' }, typical_errors: typical },
    leer, pruefung };
});

for (const s of SKILLS) if (proSkill.get(s) !== 6) fehler.push(`${s}: ${proSkill.get(s) ?? 0} statt 6 Aufgaben`);
for (const s of NEU) {
  const n = slugsVerwendet.get(s)?.size ?? 0;
  if (n < 3) fehler.push(`Fehlbild ${s} nur in ${n} Aufgaben`);
}
if (/gemeistert|meisterst|mastered|beherrscht/i.test(JSON.stringify(A))) fehler.push('Mastery-Sprache');
if (fehler.length) { console.error('Charge abgelehnt:\n  ' + fehler.join('\n  ')); process.exit(1); }

const charge = {
  batch: 'k8-lgs',
  kopf: [
    `K8 Lineare Gleichungssysteme, Migration 2 von 2 — ${aufgaben.length} Aufgaben, je sechs zu den fuenf gleichung_lgs_*-Knoten.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-lgs.json (Quelle: tools/k8-lgs-aufgaben.mjs,',
    'tools/k8-lgs-aufgaben-2.mjs und tools/k8-lgs-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003104943_substrat_k8_lgs.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendungen mit steigender Schwierigkeit und zwei mit Sachkontext (Eintritt, Tarife, Mischung, Zahlenrätsel) bzw. Deutung; im Sachknoten alle sechs mit Kontext (vier mit MC-Teil „Welches Gleichungssystem passt?“, zwei selbst aufstellen). Lösungen als MULTI_PART x | y mit known_errors je Teil; Lösungsanzahl (keine/unendlich viele) als MC. Grafisch: zwei Geraden am Generator koordinatensystem. Keine Hinweise, keine Personen.',
  source: 'edvance_k8_lgs',
  class_level: 8,
  acceptance_equivalents: true,
  ohne_transaktion: true,
  ohne_sondierrang: [],
  zeitregel: {
    beschreibung: 'est_duration_sec wie im Pilot/Vorlauf/Zins/Linear: AFB I 45 s, AFB II 60 s, AFB III 90 s; +30 s bei Sachkontext. MULTI_PART: zeit_teile summiert genau dazu (MC-Teil 30 s, y-Teil 15 s, Rest x-Teil).',
    basis: ZEIT,
    sachkontext_zuschlag: SACH,
  },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k8-lgs.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k8-lgs.json: ${aufgaben.length} Aufgaben, ${aufgaben.filter((a) => a.basis.figur).length} mit Figur`);
for (const s of SKILLS) console.log(`  ${s}: ${proSkill.get(s)} Aufgaben`);
for (const [s, refs] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${refs.size} Aufgaben${NEU.includes(s) ? ' (neu)' : ''}`);
