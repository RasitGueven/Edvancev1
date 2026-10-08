#!/usr/bin/env node
/**
 * erklaer-rechnen.mjs — rechnet eine Erklär-Charge nach (E2b), wie prefill-rechnen die Aufgaben.
 *
 *   node tools/erklaer-rechnen.mjs docs/prefill/erklaer-k8-linfkt.json
 *
 * Liest die Erklär-Charge, die Check-Charge (Feld check_charge), den Bestand (Feld bestand,
 * aus dbread) und die Aufgaben-Charge des Themas (Feld aufgaben_charge). Exit 1 bei Fehlern.
 *
 * Regeln:
 *   Zahlen   R1 jede Rechnung eines Schritts stimmt exakt; R2 jede Zahl im Text (auch in $…$)
 *            ist belegt: Term oder Ergebnis einer Rechnung, Bildpunkt, m oder b der Geraden;
 *            R3 keine Zahlwörter; R4 jeder Bildpunkt liegt auf der Geraden, jeder Punkt im Text
 *            ist ein Bildpunkt mit denselben Koordinaten.
 *   Checks   R5 Antwort und jeder falsche Wert sind nachgerechnet (Check-Charge, pruefung);
 *            R6 Slugs nur aus den known_errors der Aufgaben DIESES Skills (Bestand);
 *            R7 jeder Slug eines Checks hat eine Variante der Kernidee oder steht begründet in
 *            ohne_variante; jede Variante B/C hat Slugs, und jeder davon kommt in einem Check vor;
 *            R8 kein Schritt der Kernidee nennt die Antwort eines ihrer Checks als Ergebnis;
 *            R9 kein Schritt des Skills nennt alle Punkte eines Checks (verrät ihn nicht), kein
 *            Lösungsbeispiel rechnet mit den Punkten eines Checks; R10 kein Check wiederholt
 *            die Zahlen einer Aufgabe des Themas; R11 Einsatz nur check, Status draft.
 *   Umfang   R12 2 bis kernideen_max Kernideen je Skill, checks_je_kernidee (mindestens die Stellschraube
 *            check_aufgaben_je_kernidee) Checks je Kernidee, Variante A mit Erklärung und Beispiel, B/C nur Erklärung.
 *   Bild     R4b jedes Steigungsdreieck liegt mit beiden Ecken auf der Geraden (hoch : rüber = m), seine
 *            Zahlen gelten als belegt; Check-Figuren tragen nie ein Steigungsdreieck.
 *   Sprache  R13 ein Bildschirm: Überschrift ≤ 50 Zeichen, Lesetext ≤ 330 Zeichen, ≤ 5 Blöcke;
 *            Sätze ≤ 16 Wörter; Du-Form (kein "Sie"); keine Mastery-Sprache.
 *   Markdown R14 "# " nur als erste Zeile, "> " Merksatz, "1. " nummerierte Schritte, $…$ Formeln,
 *            sonst Absätze aus einer Zeile; kein Fett, keine Aufzählungspunkte, keine anderen
 *            Markdown-Zeichen (erklaer-lib markdownFehler; der Player in E2a stellt genau das dar).
 */

import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import { zahl } from './prefill-rechnen.mjs';
import { ZAHLWORT, aufGerade, bloecke, lesetext, markdownFehler, punkteImText, qAus, zahlen } from './erklaer-lib.mjs';

const punkt = (s) => String(s).replace(',', '.');
const enthalten = (liste, q) => liste.some((x) => x.eq(q));
const schluessel = (p) => `${p.x}|${p.y}`;

/** Belegte Zahlen eines Schritts: Rechnungen (Terme und Ergebnisse) und Bild. */
function belegt(s) {
  const out = [];
  for (const [term, wert] of s.rechnungen ?? []) out.push(...zahlen(term), zahl(punkt(wert)));
  const p = s.bild?.params;
  for (const f of p?.funktionen ?? []) out.push(qAus(f.m), qAus(f.b));
  for (const pt of p?.punkte ?? []) out.push(qAus(pt.x), qAus(pt.y));
  for (const d of p?.steigungsdreiecke ?? []) out.push(qAus(d.dx), qAus(d.dy));
  return out;
}

function pruefeSchritt(s, wo, f) {
  for (const [term, wert] of s.rechnungen ?? []) {
    const ist = zahl(punkt(term));
    if (!ist.eq(zahl(punkt(wert)))) f.push(`${wo}: Rechnung ${term} = ${ist}, nicht ${wert}`);
  }
  const ok = belegt(s);
  for (const q of zahlen(s.inhalt)) if (!enthalten(ok, q)) f.push(`${wo}: Zahl ${q} im Text ist nicht belegt`);
  const wort = s.inhalt.match(ZAHLWORT);
  if (wort) f.push(`${wo}: Zahlwort "${wort[0]}" (Ziffern verwenden)`);
  const gerade = s.bild?.params?.funktionen?.[0];
  const bildpunkte = (s.bild?.params?.punkte ?? []).map((p) => ({ label: p.label, x: qAus(p.x), y: qAus(p.y) }));
  for (const p of bildpunkte) {
    if (gerade && !aufGerade(gerade, p.x, p.y)) f.push(`${wo}: Bildpunkt ${p.label}(${p.x}|${p.y}) liegt nicht auf der Geraden`);
    if (/\d/.test(p.label)) f.push(`${wo}: Bildpunkt ${p.label} trägt Ziffern (nur Buchstaben)`);
  }
  // Steigungsdreieck: Start- und Endecke auf der Geraden, also hoch : rüber = m. Die Beschriftung
  // („rüber dx“, „hoch dy“) schreibt der Generator aus dx und dy; pruefe_koordinatensystem (f) vergleicht sie.
  for (const [i, d] of (s.bild?.params?.steigungsdreiecke ?? []).entries()) {
    const x = qAus(d.x), y = qAus(d.y), dx = qAus(d.dx), dy = qAus(d.dy);
    if (!gerade || !aufGerade(gerade, x, y) || !aufGerade(gerade, x.add(dx), y.add(dy))) {
      f.push(`${wo}: Steigungsdreieck ${i + 1} (${x}|${y}) +${dx}/+${dy} liegt nicht mit beiden Ecken auf der Geraden`);
    } else if (!dy.div(dx).eq(qAus(gerade.m))) f.push(`${wo}: Steigungsdreieck ${i + 1}: hoch : rüber ≠ m`);
    // Platz für die Beschriftung (Näherung in Einheiten): neben „hoch“ 1,5 bis zum Rand, „rüber“
    // nicht auf der x-Achse und 1 bis zum Rand, die Mitte von „hoch“ nicht auf Höhe der x-Achse.
    const p = s.bild.params, xe = d.x + d.dx, mitte = d.y + d.dy / 2;
    if ((d.dx > 0 ? p.x_max - xe : xe - p.x_min) < 1.5) f.push(`${wo}: Steigungsdreieck ${i + 1}: kein Platz für „hoch“ am Rand`);
    if (d.y === 0 || Math.abs(mitte) < 0.5) f.push(`${wo}: Steigungsdreieck ${i + 1}: Beschriftung auf der x-Achse`);
    if ((d.dy > 0 ? d.y - p.y_min : p.y_max - d.y) < 1) f.push(`${wo}: Steigungsdreieck ${i + 1}: kein Platz für „rüber“`);
    // „rüber …“ ist etwa 1,4 Einheiten breit und steht mittig unter bzw. über der Waagerechten:
    // nicht über der y-Achse und nicht über dem senkrechten Schenkel eines anderen Dreiecks.
    const mx = d.x + d.dx / 2;
    if (p.x_min < 0 && Math.abs(mx) < 0.75) f.push(`${wo}: Steigungsdreieck ${i + 1}: „rüber“ liegt auf der y-Achse`);
    for (const e of p.steigungsdreiecke) {
      if (e !== d && Math.abs(e.x + e.dx - mx) < 0.75 && Math.min(e.y, e.y + e.dy) <= d.y + 1 && Math.max(e.y, e.y + e.dy) >= d.y - 1) {
        f.push(`${wo}: Steigungsdreieck ${i + 1}: „rüber“ kreuzt ein anderes Dreieck`);
      }
    }
  }
  for (const p of punkteImText(s.inhalt)) {
    const b = bildpunkte.find((x) => x.label === p.label);
    if (!b || !b.x.eq(p.x) || !b.y.eq(p.y)) f.push(`${wo}: Punkt ${p.label}(${p.x}|${p.y}) im Text fehlt im Bild oder weicht ab`);
  }
  if (s.bild && /\d/.test(s.bild.alt)) f.push(`${wo}: Alt-Text mit Ziffer`);
  // R13 Sprache und Bildschirm; R14 Markdown nur in den Formen, die der Player darstellt
  for (const m of markdownFehler(s.inhalt)) f.push(`${wo}: Markdown: ${m}`);
  const bl = bloecke(s.inhalt);
  if (bl[0]?.art !== 'titel') f.push(`${wo}: erster Block muss die Überschrift sein ("# …")`);
  if (bl.filter((b) => b.art === 'titel').length !== 1) f.push(`${wo}: genau eine Überschrift`);
  if ((bl[0]?.text ?? '').length > 50) f.push(`${wo}: Überschrift länger als 50 Zeichen`);
  if (bl.length > 5) f.push(`${wo}: mehr als 5 Blöcke`);
  const lese = bl.slice(1).map(lesetext).join(' ').replace(/\$([^$]+)\$/g, (m, t) => t.replace(/\\[a-z]+|[{}]/g, ''));
  if (lese.length > 330) f.push(`${wo}: Lesetext ${lese.length} Zeichen (höchstens 330)`);
  for (const satz of bl.flatMap((b) => lesetext(b).replace(/\$[^$]+\$/g, 'F').split(/(?<=[.!?:])\s+/))) {
    const w = satz.split(/\s+/).filter(Boolean).length;
    if (w > 16) f.push(`${wo}: Satz mit ${w} Wörtern: "${satz}"`);
  }
  if (/(^|[^.!?]\s)(Sie|Ihnen|Ihr)\b/.test(s.inhalt)) f.push(`${wo}: Sie-Form`);
  if (/gemeistert|meisterst|mastered|beherrscht/i.test(s.inhalt)) f.push(`${wo}: Mastery-Sprache`);
}

/** Punkte eines Checks: aus dem Text ("A(1 | 2)") und aus der Figur. */
function checkPunkte(aufgabe) {
  const ausText = punkteImText(aufgabe.basis.frage);
  const ausFigur = (aufgabe.basis.figur?.params?.punkte ?? []).map((p) => ({ x: qAus(p.x), y: qAus(p.y) }));
  return [...ausText, ...ausFigur].map(schluessel);
}

/** Zahlen der Fragestellung eines Checks (Text, Figurpunkte, m und b der Figur), sortiert als Profil. */
function profil(aufgabe) {
  const fp = aufgabe.basis.figur?.params;
  const z = [...zahlen(aufgabe.basis.frage), ...(fp?.punkte ?? []).flatMap((p) => [qAus(p.x), qAus(p.y)]),
    ...(fp?.funktionen ?? []).flatMap((f) => [qAus(f.m), qAus(f.b)])];
  return z.map(String).sort().join(',');
}

export function pruefeCharge(charge, checks, bestand, themaAufgaben) {
  const f = [];
  const aufgabeVon = new Map(checks.aufgaben.map((a) => [a.id, a]));
  const slugsVon = new Map(bestand.skills.map((s) => [s.skill_key, new Set((s.fehlbilder ?? []).map((x) => x.slug))]));
  const { kernideen_max: kMax, check_aufgaben_je_kernidee: cJe } = charge.einstellungen;
  const themaProfile = new Map(themaAufgaben.aufgaben.map((a) => [profil(a), a.basis.source_ref]));

  // R5 Check-Charge: jede Antwort und jeder falsche Wert nachgerechnet
  for (const a of checks.aufgaben) {
    for (const p of a.pruefung ?? []) {
      if (!zahl(punkt(p.rechnung)).eq(zahl(punkt(p.antwort)))) f.push(`${a.basis.source_ref}: ${p.rechnung} ≠ ${p.antwort}`);
    }
    if (!(a.pruefung ?? []).length) f.push(`${a.basis.source_ref}: keine Nachrechnung`);
    // R11 nur Einsatz check, nur Entwurf
    if (JSON.stringify(checks.einsatz) !== '["check"]') f.push('Check-Charge: einsatz muss genau {check} sein');
    const dup = themaProfile.get(profil(a));
    if (dup) f.push(`${a.basis.source_ref}: dieselben Zahlen wie die Aufgabe ${dup} (R10)`);
  }

  const proSkill = new Map();
  for (const k of charge.kernideen) {
    if (!proSkill.has(k.skill_key)) proSkill.set(k.skill_key, []);
    proSkill.get(k.skill_key).push(k);
  }
  for (const [skill, ks] of proSkill) {
    const erlaubt = slugsVon.get(skill);
    if (!erlaubt) { f.push(`${skill}: nicht im Bestand des Themas`); continue; }
    if (ks.length < 2 || ks.length > kMax) f.push(`${skill}: ${ks.length} Kernideen (2 bis ${kMax})`);
    const nrs = ks.map((k) => k.nr);
    if (nrs.join() !== nrs.map((_, i) => i + 1).join()) f.push(`${skill}: Kernideen nicht 1..n in Reihenfolge`);
    const alleSchritte = ks.flatMap((k) => k.schritte.map((s) => ({ ...s, k })));

    for (const k of ks) {
      const wo = `${skill} K${k.nr}`;
      const varianten = [...new Set(k.schritte.map((s) => s.variante))].sort();
      if (varianten[0] !== 'A') f.push(`${wo}: Variante A fehlt`);
      for (const v of varianten) {
        const arten = k.schritte.filter((s) => s.variante === v).map((s) => s.art).sort().join(',');
        const soll = v === 'A' ? 'beispiel,erklaerung' : 'erklaerung';
        if (arten !== soll) f.push(`${wo} ${v}: Schritte ${arten}, erwartet ${soll}`);
      }
      for (const s of k.schritte) pruefeSchritt(s, `${wo} ${s.variante}/${s.art}`, f);

      // R6/R7 Fehlbilder
      const variantSlugs = new Map();
      for (const s of k.schritte.filter((x) => x.art === 'erklaerung')) {
        if (s.variante === 'A' && s.fehlbild_slugs.length) f.push(`${wo} A: Variante A ohne Fehlbild`);
        if (s.variante !== 'A' && !s.fehlbild_slugs.length) f.push(`${wo} ${s.variante}: Variante ohne Fehlbild`);
        for (const slug of s.fehlbild_slugs) {
          if (!erlaubt.has(slug)) f.push(`${wo} ${s.variante}: Fehlbild ${slug} nicht in den known_errors von ${skill}`);
          variantSlugs.set(slug, s.variante);
        }
      }
      const soll = charge.checks_je_kernidee ?? cJe;
      if (soll < cJe) f.push(`${wo}: checks_je_kernidee ${soll} unter der Stellschraube ${cJe}`);
      if (k.checks.length !== soll) f.push(`${wo}: ${k.checks.length} Checks, verlangt ${soll}`);
      const checkSlugs = new Set();
      for (const c of k.checks) {
        const a = aufgabeVon.get(c.task_id);
        if (!a) { f.push(`${wo}: Check ${c.ref} fehlt in der Check-Charge`); continue; }
        if (a.basis.skill_key !== skill) f.push(`${wo}: Check ${c.ref} hat Skill ${a.basis.skill_key}`);
        if (a.basis.figur?.params?.steigungsdreiecke) f.push(`${wo}: Check ${c.ref} mit Steigungsdreieck (verrät die Lösung)`);
        const antwort = zahl(punkt(a.pruefung[0].antwort));
        for (const slug of new Set(Object.values(a.basis.known_errors))) {
          checkSlugs.add(slug);
          if (!erlaubt.has(slug)) f.push(`${wo} ${c.ref}: Fehlbild ${slug} nicht in den known_errors von ${skill}`);
          if (!variantSlugs.has(slug) && !k.ohne_variante?.[slug]) f.push(`${wo} ${c.ref}: Fehlbild ${slug} ohne Variante und ohne Begründung`);
        }
        // R8 Antwort nicht als Ergebnis in der Kernidee
        for (const s of k.schritte) {
          for (const [, wert, falsch] of s.rechnungen ?? []) {
            if (!falsch && zahl(punkt(wert)).eq(antwort)) f.push(`${wo} ${s.variante}/${s.art}: Ergebnis ${wert} = Antwort von ${c.ref}`);
          }
        }
        // R9 kein Schritt des Skills nennt alle Punkte des Checks; Beispiele nie dieselben Punkte
        const cp = checkPunkte(a);
        for (const s of alleSchritte) {
          const sp = new Set([...punkteImText(s.inhalt), ...(s.bild?.params?.punkte ?? []).map((p) => ({ x: qAus(p.x), y: qAus(p.y) }))].map(schluessel));
          if (cp.length && cp.every((p) => sp.has(p))) f.push(`K${s.k.nr} ${s.variante}/${s.art}: enthält alle Punkte von ${c.ref}`);
          if (s.art === 'beispiel' && cp.some((p) => sp.has(p))) f.push(`K${s.k.nr} Beispiel: rechnet mit einem Punkt von ${c.ref}`);
        }
      }
      for (const [slug, v] of variantSlugs) if (!checkSlugs.has(slug)) f.push(`${wo} ${v}: Fehlbild ${slug} kommt in keinem Check vor`);
      for (const slug of Object.keys(k.ohne_variante ?? {})) if (!checkSlugs.has(slug)) f.push(`${wo}: ohne_variante ${slug} kommt in keinem Check vor`);
    }
  }
  return f;
}

/** Welche Variante zeigt die Engine nach einem falschen Check (erklaer_check_abgeben, A2)? */
export function varianteNach(k, slug, gezeigt = 'A') {
  const erkl = k.schritte.filter((s) => s.art === 'erklaerung').map((s) => s.variante).sort();
  const passend = k.schritte.find((s) => s.art === 'erklaerung' && s.variante !== gezeigt && slug && s.fehlbild_slugs.includes(slug));
  if (passend) return { variante: passend.variante, grund: 'Fehlbild' };
  const naechste = erkl.filter((v) => v !== gezeigt).sort((a, b) => Number(a < gezeigt) - Number(b < gezeigt) || a.localeCompare(b))[0];
  return { variante: naechste ?? gezeigt, grund: 'nächste ungezeigte' };
}

export function ladeUndPruefe(pfad) {
  const charge = JSON.parse(fs.readFileSync(pfad, 'utf8'));
  const lies = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
  return pruefeCharge(charge, lies(charge.check_charge), lies(charge.bestand), lies(charge.aufgaben_charge));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const pfad = process.argv[2];
  if (!pfad) { console.error('Aufruf: erklaer-rechnen.mjs <erklaer-charge.json>'); process.exit(2); }
  const fehler = ladeUndPruefe(pfad);
  if (fehler.length) { console.error(`Nachrechnung rot (${fehler.length}):\n  ${fehler.join('\n  ')}`); process.exit(1); }
  const c = JSON.parse(fs.readFileSync(pfad, 'utf8'));
  const n = c.kernideen.reduce((s, k) => s + k.schritte.length, 0);
  console.log(`Nachrechnung grün: ${c.kernideen.length} Kernideen, ${n} Schritte, ${c.kernideen.reduce((s, k) => s + k.checks.length, 0)} Checks`);
}

