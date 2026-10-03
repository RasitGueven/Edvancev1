#!/usr/bin/env node
/**
 * k8-flaeche-charge.mjs — erzeugt docs/prefill/k8-flaeche.json (Charge-Format von vorlauf-build.mjs)
 * aus tools/k8-flaeche-aufgaben.mjs und tools/k8-flaeche-aufgaben-2.mjs.
 *
 *   node tools/k8-flaeche-charge.mjs     # schreibt die Charge (ids bleiben stabil)
 *
 * Jede Antwort und jeder falsche Wert wird mit prefill-rechnen exakt nachgerechnet; bei MC
 * wird jede Option als Term in x mit dem Flaechenterm bzw. ihrem Fehlerterm verglichen.
 * Weicht etwas ab, bricht das Skript ab.
 * Danach: node tools/vorlauf-build.mjs docs/prefill/k8-flaeche.json 20261003104949 aufgaben_k8_flaeche
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import { zahl, gleichwertig } from './prefill-rechnen.mjs';
import { A as A1 } from './k8-flaeche-aufgaben.mjs';
import { A as A2 } from './k8-flaeche-aufgaben-2.mjs';

const A = [...A1, ...A2];
const GEO = '3156b22e-ad3b-46c8-8c76-4155176cc52a'; // Themengebiet „Geometrie & Messen"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;
const NEU = ['nur_eine_grundseite', 'teilflaeche_vergessen'];
const SKILLS = ['geo_flaeche_trapez', 'geo_flaeche_drachen_raute', 'geo_flaeche_zusammengesetzt', 'geo_flaeche_term', 'geo_flaeche_rueck'];
const PERSONEN = /\b(Lisa|Tom|Paul|Anna|Herr|Frau|Familie)\b/;

// ── Schreibweisen ──────────────────────────────────────────────────────────────
// lsa_is_correct und lsa_fehlbild_match vergleichen Text (trim, Komma->Punkt, lower).
// Je Wert: Komma/Punkt, "+" bei positiven Werten, bei € die Cent-Form, mit Einheit.
// Alle Werte dieses Laufs sind positiv; ein Minus-Wert bricht ab (siehe unten).
function formen(wert, einheit) {
  const basis = [wert];
  if (einheit === '€') basis.push(/,\d$/.test(wert) ? `${wert}0` : /,/.test(wert) ? wert : `${wert},00`);
  const zahlen = [];
  for (const b of basis) { zahlen.push(b); if (b.includes(',')) zahlen.push(b.replace(',', '.')); }
  const vz = zahlen.flatMap((z) => (z === '0' ? [z] : [z, `+${z}`]));
  const out = [...vz];
  if (einheit) for (const v of vz) out.push(`${v} ${einheit}`, `${v}${einheit}`);
  return [...new Set(out)];
}

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k8-flaeche-ids.json';
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
const merke = (slug, ref) => { if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set()); slugsVerwendet.get(slug).add(ref); };
const proSkill = new Map();
const refs = new Set();

/** NUMERIC: Antwort, Varianten, known_errors, Pruefeintraege. */
function numeric(a, wo) {
  if (a.antwort.startsWith('-')) fehler.push(`${wo}: negative Antwort – formen() kennt kein Minus`);
  nachgerechnet(a.r, a.antwort, wo);
  const richtig = formen(a.antwort, a.einheit);
  const known = {};
  for (const [wert, slug, rechnung] of a.ke) {
    nachgerechnet(rechnung, wert, `${wo} known_error ${slug}`);
    if (wert.startsWith('-')) fehler.push(`${wo}: negativer falscher Wert ${wert}`);
    if (zahl(punkt(wert)).eq(zahl(punkt(a.antwort)))) fehler.push(`${wo}: falscher Wert ${wert} = richtige Antwort`);
    for (const f of formen(wert, a.einheit)) {
      if (richtig.includes(f)) fehler.push(`${wo}: falscher Wert ${f} steht unter den richtigen`);
      if (known[f] && known[f] !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs`);
      known[f] = slug;
    }
    merke(slug, a.ref);
  }
  const pruefung = [{ rechnung: a.r, antwort: punkt(a.antwort) }];
  for (const [wert, slug, rechnung] of a.ke) pruefung.push({ rechnung, antwort: punkt(wert), rolle: `fehlbild:${slug}` });
  const typical = a.ke.map(([, , , error, socratic_question]) => ({ error, socratic_question }));
  const basis = { input_type: 'NUMERIC', unit: a.einheit, known_errors: known };
  return { basis, richtig, pruefung, typical, slugs: a.ke.map((k) => k[1]) };
}

/** MC: genau die richtige Option ist gleichwertig zum Flaechenterm. */
function mc(a, wo) {
  const opts = a.options.map(([id, label]) => ({ id, label }));
  const richtige = a.options.filter(([, label]) => gleichwertig(label, a.term)).map(([id]) => id);
  if (richtige.length !== 1) fehler.push(`${wo}: ${richtige.length} Optionen gleichwertig zu ${a.term}`);
  for (const [i, [id, label]] of a.options.entries()) {
    for (const [id2, label2] of a.options.slice(i + 1)) if (gleichwertig(label, label2)) fehler.push(`${wo}: Optionen ${id} und ${id2} gleichwertig`);
  }
  const known = {};
  for (const [id, label, slug, fterm] of a.options) {
    if (!slug) continue;
    if (!gleichwertig(label, fterm)) fehler.push(`${wo}: Option ${id} „${label}“ ist nicht ${fterm} (${slug})`);
    if (richtige.includes(id)) fehler.push(`${wo}: Option ${id} richtig und Fehlbild`);
    known[id] = slug;
    merke(slug, a.ref);
  }
  const loesungLabel = a.options.find(([id]) => id === richtige[0])?.[1] ?? '';
  if (!a.weg.replace(/\s/g, '').includes(loesungLabel.replace(/\s/g, ''))) fehler.push(`${wo}: Lösungsweg nennt ${loesungLabel} nicht`);
  const typical = a.options.filter((o) => o[2]).map(([, , , , error, socratic_question]) => ({ error, socratic_question }));
  const basis = { input_type: 'MC', options: opts, known_errors: known };
  return { basis, richtig: richtige, pruefung: [{ term: a.term }], typical, slugs: Object.values(known) };
}

const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  if (refs.has(a.ref)) fehler.push(`${wo}: ref doppelt`);
  refs.add(a.ref);
  if (!SKILLS.includes(a.skill)) fehler.push(`${wo}: unbekannter Skill ${a.skill}`);
  if (!ZEIT[a.afb]) fehler.push(`${wo}: afb ${a.afb}`);
  if (PERSONEN.test(a.frage)) fehler.push(`${wo}: Person im Aufgabentext`);
  if (/gemeistert|meisterst|mastered|beherrscht/i.test(JSON.stringify(a))) fehler.push(`${wo}: Mastery-Sprache`);
  proSkill.set(a.skill, (proSkill.get(a.skill) ?? 0) + 1);
  const x = a.mc ? mc(a, wo) : numeric(a, wo);
  const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
  return {
    nr: i + 1,
    id: IDS[a.ref],
    titel: a.titel,
    basis: { skill_key: a.skill, source_ref: a.ref, frage: a.frage, ...x.basis },
    felder: {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: 8, sicher: 'hoch', grund: 'Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).' },
      cluster_id: { wert: GEO, sicher: 'hoch', grund: 'Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.' },
      competency_content: { wert: 'geometrie', sicher: 'hoch', grund: 'Inhaltsfeld Geometrie (KLP Geo-8).' },
      competency_process: { wert: a.prozess, sicher: 'mittel', grund: a.sach
        ? 'Sachsituation in eine Flächenformel übersetzen, dann rechnen.'
        : a.mc ? 'Flächeninhalt als Term darstellen und gleichwertige Form erkennen.'
        : /Problemlösen/.test(a.prozess) ? 'Rückrichtung in zwei Schritten: Lösungsweg selbst finden.' : 'Rechnen nach festem Verfahren.' },
      needs_image: { wert: false, sicher: 'hoch', grund: 'Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).' },
    },
    loesung: {
      correct_answers: { wert: x.richtig, sicher: 'hoch', grund: a.mc
        ? 'Einzige Option, die als Term in x gleichwertig zum Flächenterm ist (prefill-rechnen).'
        : 'Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.' },
      solution: { wert: a.weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
      typical_errors: { wert: x.typical, sicher: 'hoch', grund: `Aus acceptance.known_errors (${[...new Set(x.slugs)].join(', ')}).` },
    },
    leer: { hints: 'Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.' },
    pruefung: x.pruefung,
  };
});

for (const s of SKILLS) if (proSkill.get(s) !== 6) fehler.push(`${s}: ${proSkill.get(s) ?? 0} statt 6 Aufgaben`);
for (const s of NEU) {
  const n = slugsVerwendet.get(s)?.size ?? 0;
  if (n < 3) fehler.push(`Fehlbild ${s} nur in ${n} Aufgaben`);
}
if (fehler.length) { console.error('Charge abgelehnt:\n  ' + [...new Set(fehler)].join('\n  ')); process.exit(1); }

const charge = {
  batch: 'k8-flaeche',
  kopf: [
    `K8 Flaechen, Migration 2 von 2 — ${aufgaben.length} Aufgaben, je sechs zu den fuenf geo_flaeche_*-Knoten (Geo-8).`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-flaeche.json (Quelle: tools/k8-flaeche-aufgaben.mjs,',
    'tools/k8-flaeche-aufgaben-2.mjs und tools/k8-flaeche-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003104945_substrat_k8_flaeche.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendungen mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Dachfläche, Grundstück, Papierdrachen, Fliesen, Garten, Giebelwand, Terrasse, Beet, Segel). Keine Abbildungen: jede Figur ist mit allen Maßen und ihrer Lage im Text beschrieben. Flächenterme als MC (falsche Optionen → Fehlbild) oder NUMERIC (Term aufstellen und auswerten), nie TERM. Keine Hinweise, keine Personen.',
  source: 'edvance_k8_flaeche',
  class_level: 8,
  acceptance_equivalents: true,
  ohne_transaktion: true,
  ohne_sondierrang: [],
  zeitregel: {
    beschreibung: 'est_duration_sec wie Pilot/Vorlauf/Zins/Kreis: AFB I 45 s, AFB II 60 s, AFB III 90 s; +30 s bei Sachkontext.',
    basis: ZEIT,
    sachkontext_zuschlag: SACH,
  },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k8-flaeche.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k8-flaeche.json: ${aufgaben.length} Aufgaben (${aufgaben.filter((a) => a.basis.input_type === 'MC').length} MC)`);
for (const [s, r] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${r.size} Aufgaben${NEU.includes(s) ? ' (neu)' : ''}`);
