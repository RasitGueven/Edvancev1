#!/usr/bin/env node
/**
 * k8-linfkt-charge.mjs — erzeugt docs/prefill/k8-linfkt.json (Charge-Format von vorlauf-build.mjs)
 * aus tools/k8-linfkt-aufgaben.mjs. Jede Antwort und jeder falsche Wert wird vor dem Schreiben
 * mit prefill-rechnen exakt nachgerechnet; weicht etwas ab, bricht das Skript ab.
 *
 *   node tools/k8-linfkt-charge.mjs     # schreibt die Charge (ids bleiben stabil)
 *
 * Danach: node tools/vorlauf-build.mjs docs/prefill/k8-linfkt.json <version> aufgaben_k8_linfkt
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import { zahl } from './prefill-rechnen.mjs';
import { A } from './k8-linfkt-aufgaben.mjs';

const ALGEBRA_FUNKTIONEN = 'edbb548a-54d9-4a8f-8be4-3052f9025524'; // Themengebiet „Algebra & Funktionen"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;
const NEU = ['steigung_kehrwert', 'm_b_vertauscht', 'achsenabschnitt_verwechselt'];
const SKILLS = ['fkt_linear_steigung', 'fkt_linear_yabschnitt', 'fkt_linear_graph', 'fkt_linear_gleichung', 'fkt_linear_nullstelle'];

// ── Schreibweisen ──────────────────────────────────────────────────────────────
// lsa_is_correct und lsa_fehlbild_match vergleichen Text (trim, Komma->Punkt, lower).
// Das Unicode-Minus und ein fuehrendes "+" normalisieren sie NICHT (Stand 2026-10-01),
// deshalb je Wert: Komma/Punkt, "-"/"−"/"- ", "+" bei positiven Werten, mit Einheit.
function formen(wert, einheit) {
  const s = wert.replace('.', ',');
  const basis = [s];
  if (einheit === '€' && /^-?\d+,\d$/.test(s)) basis.push(`${s}0`);  // 1,5 -> 1,50
  const zahlen = [];
  for (const b of basis) {
    zahlen.push(b);
    if (b.includes(',')) zahlen.push(b.replace(',', '.'));
  }
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
const alleFormen = (a) => [...new Set([a.antwort, ...(a.auch ?? [])].flatMap((w) => formen(w, a.einheit)))];

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k8-linfkt-ids.json';
const IDS = fs.existsSync(IDS_PFAD) ? JSON.parse(fs.readFileSync(IDS_PFAD, 'utf8')) : {};
for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
fs.writeFileSync(IDS_PFAD, JSON.stringify(IDS, null, 1) + '\n');

// ── Charge bauen ───────────────────────────────────────────────────────────────
const fehler = [];
const punkt = (s) => s.replace(',', '.');
const nachgerechnet = (rechnung, soll, wo) => {
  const ist = zahl(rechnung), sollQ = zahl(punkt(soll));
  if (!ist.eq(sollQ)) fehler.push(`${wo}: ${rechnung} = ${ist}, nicht ${soll}`);
};
const slugsVerwendet = new Map();
const proSkill = new Map();

const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  if (!SKILLS.includes(a.skill)) fehler.push(`${wo}: unbekannter Skill ${a.skill}`);
  proSkill.set(a.skill, (proSkill.get(a.skill) ?? 0) + 1);
  nachgerechnet(a.r, a.antwort, wo);
  for (const w of a.auch ?? []) nachgerechnet(a.r, w, `${wo} Variante ${w}`);
  const richtig = alleFormen(a);
  const known = {};
  for (const [wert, slug, rechnung] of a.ke) {
    nachgerechnet(rechnung, wert, `${wo} known_error ${slug}`);
    if (zahl(punkt(wert)).eq(zahl(punkt(a.antwort)))) fehler.push(`${wo}: falscher Wert ${wert} = richtige Antwort`);
    for (const f of formen(wert, a.einheit)) {
      if (richtig.includes(f)) fehler.push(`${wo}: falscher Wert ${f} steht unter den richtigen`);
      if (known[f] && known[f] !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs`);
      known[f] = slug;
    }
    if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set());
    slugsVerwendet.get(slug).add(a.ref);
  }
  if (a.figur && /\d/.test(a.figur.alt_text)) fehler.push(`${wo}: alt_text mit Ziffer`);
  if (!!a.figur !== (a.skill === 'fkt_linear_graph')) fehler.push(`${wo}: Figur nur bei fkt_linear_graph`);
  const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
  const pruefung = [{ rechnung: a.r, antwort: a.antwort }];
  for (const [wert, slug, rechnung] of a.ke) pruefung.push({ rechnung, antwort: wert, rolle: `fehlbild:${slug}` });
  return {
    nr: i + 1,
    id: IDS[a.ref],
    titel: a.titel,
    basis: {
      skill_key: a.skill, source_ref: a.ref, input_type: 'NUMERIC',
      ...(a.einheit ? { unit: a.einheit } : {}),
      frage: a.frage, known_errors: known,
      ...(a.figur ? { figur: a.figur } : {}),
    },
    felder: {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: 8, sicher: 'hoch', grund: 'Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.' },
      cluster_id: { wert: ALGEBRA_FUNKTIONEN, sicher: 'hoch', grund: 'Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.' },
      competency_content: { wert: 'funktionen', sicher: 'hoch', grund: 'Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).' },
      competency_process: { wert: a.prozess, sicher: 'mittel', grund: a.sach
        ? 'Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.'
        : a.prozess === 'Problemlösen' ? 'Rückrichtung: Lösungsweg selbst finden, dann rechnen.' : 'Rechnen bzw. Ablesen nach festem Verfahren.' },
      needs_image: { wert: !!a.figur, sicher: 'hoch', grund: a.figur
        ? 'Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.'
        : 'Alle Angaben stehen im Text, keine Abbildung nötig.' },
    },
    loesung: {
      correct_answers: { wert: richtig, sicher: 'hoch', grund: 'Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.' },
      solution: { wert: a.weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
      typical_errors: {
        wert: a.ke.map(([, , , error, socratic_question]) => ({ error, socratic_question })),
        sicher: 'hoch',
        grund: `Aus acceptance.known_errors (${[...new Set(a.ke.map((k) => k[1]))].join(', ')}).`,
      },
    },
    leer: { hints: 'Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.' },
    pruefung,
  };
});

for (const s of SKILLS) if (proSkill.get(s) !== 6) fehler.push(`${s}: ${proSkill.get(s) ?? 0} statt 6 Aufgaben`);
for (const s of NEU) {
  const n = slugsVerwendet.get(s)?.size ?? 0;
  if (n < 3) fehler.push(`Fehlbild ${s} nur in ${n} Aufgaben`);
}
if (fehler.length) { console.error('Charge abgelehnt:\n  ' + fehler.join('\n  ')); process.exit(1); }

const charge = {
  batch: 'k8-linfkt',
  kopf: [
    `K8 Lineare Funktionen, Migration 2 von 2 — ${aufgaben.length} Aufgaben, je sechs zu den fuenf fkt_linear_*-Knoten.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-linfkt.json (Quelle: tools/k8-linfkt-aufgaben.mjs',
    'und tools/k8-linfkt-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261001124808_substrat_k8_linfkt.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendungen mit steigender Schwierigkeit (AFB I, I, II, II) und zwei mit Sachkontext (Fkt-6: Grundgebühr, Preis je km/Stunde/Minute, Anfangswert) oder Rückrichtung. Alle NUMERIC, damit die Fehlbild-Erkennung greift; die Graph-Aufgaben lesen am Generator koordinatensystem ab. Keine Hinweise, keine Personen.',
  source: 'edvance_k8_linfkt',
  zeitregel: {
    beschreibung: 'est_duration_sec wie im Pilot/Vorlauf/Zins: AFB I 45 s, AFB II 60 s, AFB III 90 s; +30 s bei Sachkontext. Zeitbudget und Stoffanker nur auf Aufgabenebene (Entscheidung Rasit).',
    basis: ZEIT,
    sachkontext_zuschlag: SACH,
  },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k8-linfkt.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k8-linfkt.json: ${aufgaben.length} Aufgaben`);
for (const [s, refs] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${refs.size} Aufgaben${NEU.includes(s) ? ' (neu)' : ''}`);
