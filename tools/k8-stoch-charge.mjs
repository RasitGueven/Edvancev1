#!/usr/bin/env node
/**
 * k8-stoch-charge.mjs — erzeugt docs/prefill/k8-stoch.json (Charge-Format von vorlauf-build.mjs)
 * aus tools/k8-stoch-aufgaben.mjs und tools/k8-stoch-aufgaben-2.mjs. Jede Antwort und jeder
 * falsche Wert wird vor dem Schreiben mit prefill-rechnen exakt nachgerechnet; weicht etwas ab,
 * bricht das Skript ab.
 *
 *   node tools/k8-stoch-charge.mjs     # schreibt die Charge (ids bleiben stabil)
 *
 * Danach: node tools/vorlauf-build.mjs docs/prefill/k8-stoch.json 20261003104948 aufgaben_k8_stoch
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import { zahl, Q } from './prefill-rechnen.mjs';
import { A } from './k8-stoch-aufgaben.mjs';
import './k8-stoch-aufgaben-2.mjs';

const DATEN_ZUFALL = '9fdfed01-ebda-4c79-89ea-5accacefee93'; // Themengebiet „Daten & Zufall"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;
const NEU = ['verhaeltnis_statt_anteil', 'zuruecklegen_ignoriert', 'pfadregel_addiert', 'nur_ein_pfad',
  'gegenereignis_nicht_abgezogen', 'mittelwert_statt_median', 'median_ohne_sortieren'];
const SKILLS = ['stoch_kenngroessen', 'stoch_laplace', 'stoch_gegenereignis', 'stoch_pfad_produkt', 'stoch_pfad_summe'];

// ── Werte und Schreibweisen ────────────────────────────────────────────────────
// lsa_is_correct / lsa_fehlbild_match vergleichen Text (trim, Komma->Punkt, lower).
const punkt = (s) => s.replace(',', '.');
const norm = (s) => s.trim().replaceAll(',', '.').toLowerCase();
/** "20 %" -> 1/5, "3/5" -> 3/5, "0,6" -> 3/5 */
const wertVon = (s) => (/%$/.test(s) ? zahl(punkt(s.replace(/\s*%$/, ''))).div(new Q(100n)) : zahl(punkt(s)));
/** endliche Dezimaldarstellung mit Komma, sonst null */
function dez(q) {
  let z2 = 0, z5 = 0, d = q.d;
  while (d % 2n === 0n) { d /= 2n; z2++; }
  while (d % 5n === 0n) { d /= 5n; z5++; }
  if (d !== 1n) return null;
  const k = Math.max(z2, z5);
  const ganz = (q.n * 10n ** BigInt(k)) / q.d;
  const neg = ganz < 0n ? '-' : '';
  const s = String(ganz < 0n ? -ganz : ganz).padStart(k + 1, '0');
  return k ? `${neg}${s.slice(0, -k)},${s.slice(-k)}` : `${neg}${s}`;
}
const teiler = (k) => { const t = []; for (let m = 1n; m <= k; m++) if (k % m === 0n) t.push(m); return t; };
/** Wahrscheinlichkeit: Bruch gekürzt und jede ungekürzte Form bis zum Rohnenner, Dezimal, Prozent */
// nackt: die Frage erlaubt Prozent -> die Prozentzahl ohne Zeichen gilt auch ("20" fuer 20 %),
// aber nur, wenn sie > 1 ist; sonst waere sie mit einer Dezimal-Wahrscheinlichkeit verwechselbar
// (Blind-Abgleich laplace-05: beide Loeser tippten "20").
function pFormen(q, roh = [], nackt = false) {
  const out = [];
  if (q.d === 1n) out.push(String(q.n));
  for (const d of new Set([q.d, ...roh.map(BigInt)])) {
    if (d % q.d !== 0n) continue;
    for (const m of teiler(d / q.d)) if (q.d * m !== 1n) out.push(`${q.n * m}/${q.d * m}`);
  }
  const z = dez(q);
  if (z) { out.push(z); if (z.includes(',')) out.push(punkt(z)); }
  const pq = q.mul(new Q(100n));
  const p = dez(pq);
  if (p) for (const v of p.includes(',') ? [p, punkt(p)] : [p]) {
    out.push(`${v} %`, `${v}%`);
    if (nackt && pq.n > pq.d) out.push(v);
  }
  return [...new Set(out)];
}
/** Erlaubt die Frage Prozent als Antwortform? */
const prozentErlaubt = (a) => /in Prozent/.test(a.frage);
/** Zahl (Kenngrößen, Anzahlen): Komma/Punkt, "-"/"−"/"- ", "+" bei positiven Werten, mit Einheit */
function zFormen(q, einheit) {
  const z = dez(q);
  const zahlen = z.includes(',') ? [z, punkt(z)] : [z];
  const vz = [];
  for (const v of zahlen) {
    if (v.startsWith('-')) vz.push(v, `−${v.slice(1)}`, `- ${v.slice(1)}`);
    else if (v !== '0') vz.push(v, `+${v}`);
    else vz.push(v);
  }
  const out = [...vz];
  if (einheit) for (const v of vz) out.push(`${v} ${einheit}`, `${v}${einheit}`);
  return [...new Set(out)];
}
const formen = (a, q, roh) => (a.art === 'p' ? pFormen(q, roh, prozentErlaubt(a)) : zFormen(q, a.einheit));
/** Wert einer Schreibweise; eine nackte Prozentzahl (nur art 'p' mit Prozent) zaehlt als Prozent. */
const wertDerForm = (a, f, soll) => {
  const w = wertVon(f.replace(/\s*(°C)$/, '').replace('−', '-').replace('- ', '-'));
  return w.eq(soll) || (a.art === 'p' && prozentErlaubt(a) && wertVon(`${f} %`).eq(soll));
};

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k8-stoch-ids.json';
const IDS = fs.existsSync(IDS_PFAD) ? JSON.parse(fs.readFileSync(IDS_PFAD, 'utf8')) : {};
for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
fs.writeFileSync(IDS_PFAD, JSON.stringify(IDS, null, 1) + '\n');

// ── Charge bauen ───────────────────────────────────────────────────────────────
const fehler = [];
const slugsVerwendet = new Map();
const proSkill = new Map();
const MASTERY = /gemeistert|meisterst|mastered|beherrscht/i;

const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  if (!SKILLS.includes(a.skill)) fehler.push(`${wo}: unbekannter Skill ${a.skill}`);
  proSkill.set(a.skill, (proSkill.get(a.skill) ?? 0) + 1);
  const soll = zahl(a.r);
  if (!wertVon(a.antwort).eq(soll)) fehler.push(`${wo}: ${a.r} = ${soll}, nicht ${a.antwort}`);
  let richtig = formen(a, soll, a.roh);
  if (!richtig.includes(a.antwort)) fehler.push(`${wo}: Antwort ${a.antwort} nicht unter den Schreibweisen`);
  richtig = [a.antwort, ...richtig.filter((f) => f !== a.antwort)];
  for (const f of richtig) if (!wertDerForm(a, f, soll)) fehler.push(`${wo}: Schreibweise ${f} ≠ ${soll}`);
  const richtigNorm = new Set(richtig.map(norm));
  const known = {};
  const knownNorm = new Map();
  for (const [wert, slug, rechnung, , , roh] of a.ke) {
    const ist = zahl(rechnung);
    if (!wertVon(wert).eq(ist)) fehler.push(`${wo} known_error ${slug}: ${rechnung} = ${ist}, nicht ${wert}`);
    if (ist.eq(soll)) fehler.push(`${wo}: falscher Wert ${wert} = richtige Antwort`);
    const fs_ = formen(a, ist, roh);
    if (!fs_.includes(wert)) fehler.push(`${wo}: falscher Wert ${wert} nicht unter seinen Schreibweisen`);
    for (const f of fs_) {
      if (richtigNorm.has(norm(f))) fehler.push(`${wo}: falscher Wert ${f} kollidiert mit einer richtigen Schreibweise`);
      if (knownNorm.has(norm(f)) && knownNorm.get(norm(f)) !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs`);
      knownNorm.set(norm(f), slug);
      known[f] = slug;
    }
    if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set());
    slugsVerwendet.get(slug).add(a.ref);
  }
  if (MASTERY.test(JSON.stringify(a))) fehler.push(`${wo}: Mastery-Sprache`);
  if (a.figur) fehler.push(`${wo}: keine Figuren in diesem Thema`);
  const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
  const pruefung = [{ rechnung: a.r, antwort: soll.toString() }];
  for (const [wert, slug, rechnung] of a.ke) pruefung.push({ rechnung, antwort: wertVon(wert).toString(), rolle: `fehlbild:${slug}` });
  const kenn = a.skill === 'stoch_kenngroessen';
  return {
    nr: i + 1,
    id: IDS[a.ref],
    titel: a.titel,
    basis: {
      skill_key: a.skill, source_ref: a.ref, input_type: 'NUMERIC',
      ...(a.einheit ? { unit: a.einheit } : {}),
      frage: a.frage, known_errors: known,
    },
    felder: {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: 8, sicher: 'hoch', grund: `Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (${kenn ? 'Sto-1/Sto-2: Kenngrößen' : 'Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente'}); an Kölner Gymnasien üblich in Klasse 8.` },
      cluster_id: { wert: DATEN_ZUFALL, sicher: 'hoch', grund: 'Daten & Zufall, Themengebiet der Stochastik (phase1 e).' },
      competency_content: { wert: 'stochastik', sicher: 'hoch', grund: 'Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).' },
      competency_process: { wert: a.prozess, sicher: 'mittel', grund: a.sach
        ? 'Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.'
        : a.prozess === 'Problemlösen' ? 'Rückrichtung: Lösungsweg selbst finden, dann rechnen.' : 'Rechnen nach festem Verfahren.' },
      needs_image: { wert: false, sicher: 'hoch', grund: 'Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.' },
    },
    loesung: {
      correct_answers: { wert: richtig, sicher: 'hoch', grund: a.art === 'p'
        ? 'Nachgerechnet; Bruch gekürzt und ungekürzt, Dezimalzahl und Prozent (wo endlich), Komma/Punkt; erlaubt die Frage Prozent, auch die Prozentzahl ohne Zeichen (nur > 1).'
        : 'Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.' },
      solution: { wert: a.weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
      typical_errors: {
        wert: a.ke.map(([, , , error, socratic_question]) => ({ error, socratic_question })),
        sicher: 'hoch',
        grund: `Aus acceptance.known_errors (${[...new Set(a.ke.map((k) => k[1]))].join(', ')}).`,
      },
    },
    leer: { hints: 'Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.' },
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
  batch: 'k8-stoch',
  kopf: [
    `K8 Daten und Wahrscheinlichkeit, Migration 2 von 2 — ${aufgaben.length} Aufgaben, je sechs zu den fuenf stoch_*-Knoten.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-stoch.json (Quelle: tools/k8-stoch-aufgaben.mjs,',
    'tools/k8-stoch-aufgaben-2.mjs und tools/k8-stoch-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003104944_substrat_k8_stoch.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendungen mit steigender Schwierigkeit (AFB I, I, II, II) und zwei mit Sachkontext (Tombola, Lostrommel, Messreihe, Torstatistik, Abfüllmaschine, Jahrmarkt) oder Rückrichtung. Alle NUMERIC ohne Abbildung: Experimente als Text, Datenreihen als Liste. Wahrscheinlichkeiten gelten als Bruch (gekürzt und ungekürzt), Dezimalzahl und Prozent, sofern endlich. Keine Hinweise, keine Personen.',
  source: 'edvance_k8_stoch',
  class_level: 8,
  acceptance_equivalents: true,
  ohne_transaktion: true,
  ohne_sondierrang: [],
  zeitregel: {
    beschreibung: 'est_duration_sec wie im Pilot/Vorlauf/Zins/Linear: AFB I 45 s, AFB II 60 s, AFB III 90 s; +30 s bei Sachkontext.',
    basis: ZEIT,
    sachkontext_zuschlag: SACH,
  },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k8-stoch.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k8-stoch.json: ${aufgaben.length} Aufgaben`);
for (const [s, refs] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${refs.size} Aufgaben${NEU.includes(s) ? ' (neu)' : ''}`);
