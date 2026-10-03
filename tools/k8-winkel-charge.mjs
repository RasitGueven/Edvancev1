#!/usr/bin/env node
/**
 * k8-winkel-charge.mjs — erzeugt docs/prefill/k8-winkel.json (Charge-Format von vorlauf-build.mjs)
 * aus tools/k8-winkel-aufgaben.mjs und tools/k8-winkel-aufgaben-2.mjs. Jede Antwort und jeder
 * falsche Wert wird vor dem Schreiben mit prefill-rechnen exakt nachgerechnet; weicht etwas ab,
 * bricht das Skript ab.
 *
 *   node tools/k8-winkel-charge.mjs     # schreibt die Charge (ids bleiben stabil)
 *
 * Danach: node tools/vorlauf-build.mjs docs/prefill/k8-winkel.json 20261003104950 aufgaben_k8_winkel
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import { zahl } from './prefill-rechnen.mjs';
import { A as A1 } from './k8-winkel-aufgaben.mjs';
import { A2 } from './k8-winkel-aufgaben-2.mjs';

const A = [...A1, ...A2];
const GEO = '3156b22e-ad3b-46c8-8c76-4155176cc52a'; // Themengebiet „Geometrie & Messen"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;
const EINHEIT = '°';
const NEU = ['winkelbeziehung_verwechselt', 'basiswinkel_falsch_zugeordnet', 'rechter_winkel_falsche_ecke', 'aussenwinkel_verwechselt'];
const SKILLS = ['geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales'];
const FIGUR_SKILLS = ['geo_winkel_neben_scheitel'];

// ── Schreibweisen ──────────────────────────────────────────────────────────────
// lsa_is_correct und lsa_fehlbild_match vergleichen Text (trim, Komma->Punkt, lower).
// Ein fuehrendes "+" normalisieren sie nicht, deshalb je Wert: Zahl, "+Zahl", jeweils
// mit und ohne Einheit (mit/ohne Leerzeichen). Alle Werte hier sind positive ganze Zahlen.
function formen(wert) {
  if (!/^\d+$/.test(wert)) throw new Error(`nur positive ganze Zahlen vorgesehen: ${wert}`);
  const vz = wert === '0' ? [wert] : [wert, `+${wert}`];
  const out = [...vz];
  for (const v of vz) out.push(`${v} ${EINHEIT}`, `${v}${EINHEIT}`);
  return [...new Set(out)];
}

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k8-winkel-ids.json';
const IDS = fs.existsSync(IDS_PFAD) ? JSON.parse(fs.readFileSync(IDS_PFAD, 'utf8')) : {};
for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
fs.writeFileSync(IDS_PFAD, JSON.stringify(IDS, null, 1) + '\n');

// ── Charge bauen ───────────────────────────────────────────────────────────────
const fehler = [];
const nachgerechnet = (rechnung, soll, wo) => {
  const ist = zahl(rechnung), sollQ = zahl(soll);
  if (!ist.eq(sollQ)) fehler.push(`${wo}: ${rechnung} = ${ist}, nicht ${soll}`);
};
const slugsVerwendet = new Map();
const proSkill = new Map();
const refs = new Set();

const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  if (refs.has(wo)) fehler.push(`${wo}: ref doppelt`);
  refs.add(wo);
  if (!SKILLS.includes(a.skill)) fehler.push(`${wo}: unbekannter Skill ${a.skill}`);
  proSkill.set(a.skill, (proSkill.get(a.skill) ?? 0) + 1);
  nachgerechnet(a.r, a.antwort, wo);
  const richtig = formen(a.antwort);
  const known = {};
  for (const [wert, slug, rechnung] of a.ke) {
    nachgerechnet(rechnung, wert, `${wo} known_error ${slug}`);
    if (zahl(wert).eq(zahl(a.antwort))) fehler.push(`${wo}: falscher Wert ${wert} = richtige Antwort`);
    for (const f of formen(wert)) {
      if (richtig.includes(f)) fehler.push(`${wo}: falscher Wert ${f} steht unter den richtigen`);
      if (known[f] && known[f] !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs`);
      known[f] = slug;
    }
    if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set());
    slugsVerwendet.get(slug).add(a.ref);
  }
  if (a.figur) {
    if (/\d/.test(a.figur.alt_text)) fehler.push(`${wo}: alt_text mit Ziffer`);
    if (a.figur.generator !== 'winkel') fehler.push(`${wo}: Generator ${a.figur.generator} statt winkel`);
    if (!FIGUR_SKILLS.includes(a.skill)) fehler.push(`${wo}: Figur nur bei ${FIGUR_SKILLS.join(', ')}`);
    const g = a.figur.params.grad;
    if (!(Number.isInteger(g) && g >= 1 && g <= 359)) fehler.push(`${wo}: grad ${g} außerhalb 1..359`);
    if (!a.frage.includes('Abbildung')) fehler.push(`${wo}: Figur, aber der Text verweist nicht auf die Abbildung`);
  } else if (a.frage.includes('Abbildung')) fehler.push(`${wo}: Text verweist auf eine Abbildung, die fehlt`);
  if (/gemeistert|meisterst|mastered|beherrscht/i.test(JSON.stringify(a))) fehler.push(`${wo}: Mastery-Sprache`);
  const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
  const pruefung = [{ rechnung: a.r, antwort: a.antwort }];
  for (const [wert, slug, rechnung] of a.ke) pruefung.push({ rechnung, antwort: wert, rolle: `fehlbild:${slug}` });
  return {
    nr: i + 1,
    id: IDS[a.ref],
    titel: a.titel,
    basis: {
      skill_key: a.skill, source_ref: a.ref, input_type: 'NUMERIC', unit: EINHEIT,
      frage: a.frage, known_errors: known,
      ...(a.figur ? { figur: a.figur } : {}),
    },
    felder: {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: 8, sicher: 'hoch', grund: 'Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.' },
      cluster_id: { wert: GEO, sicher: 'hoch', grund: 'Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.' },
      competency_content: { wert: 'geometrie', sicher: 'hoch', grund: 'Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).' },
      competency_process: { wert: a.prozess, sicher: 'mittel', grund: a.sach
        ? 'Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.'
        : a.prozess === 'Problemlösen' ? 'Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.' : 'Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).' },
      needs_image: { wert: !!a.figur, sicher: 'hoch', grund: a.figur
        ? 'Die Gradzahl steht nur in der Abbildung (Generator winkel, task_figures).'
        : 'Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.' },
    },
    loesung: {
      correct_answers: { wert: richtig, sicher: 'hoch', grund: 'Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.' },
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
  batch: 'k8-winkel',
  kopf: [
    `K8 Thales und Winkelsätze, Migration 2 von 2 — ${aufgaben.length} Aufgaben, je sechs zu den vier geo_winkel_*-Knoten.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-winkel.json (Quelle: tools/k8-winkel-aufgaben.mjs,',
    'tools/k8-winkel-aufgaben-2.mjs und tools/k8-winkel-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003104946_substrat_k8_winkel.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendungen mit steigender Schwierigkeit (AFB I, I, II, II) und zwei mit Sachkontext (Leiter, Straßenkreuzung, Bahnschienen, Zaunlatten, Satteldach, Halbkreisfenster) oder Rückrichtung. Alle NUMERIC mit Einheit °, ganzzahlige Grad. Parallelen, Dreiecke und Thaleskreise sind als Text beschrieben (kein Generator zeichnet sie); zwei Aufgaben zu Neben- und Scheitelwinkel zeigen einen einzelnen Winkel (Generator winkel). Keine Konstruktionen, keine Hinweise, keine Personen.',
  source: 'edvance_k8_winkel',
  class_level: 8,
  acceptance_equivalents: true,
  ohne_transaktion: true,
  ohne_sondierrang: [],
  zeitregel: {
    beschreibung: 'est_duration_sec wie Pilot/Vorlauf/Zins/Linear/Kreis: AFB I 45 s, AFB II 60 s, AFB III 90 s; +30 s bei Sachkontext.',
    basis: ZEIT,
    sachkontext_zuschlag: SACH,
  },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k8-winkel.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k8-winkel.json: ${aufgaben.length} Aufgaben, ${aufgaben.filter((a) => a.basis.figur).length} mit Figur`);
for (const [s, r] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${r.size} Aufgaben${NEU.includes(s) ? ' (neu)' : ''}`);
