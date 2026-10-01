#!/usr/bin/env node
/**
 * vorlauf-build.mjs — erzeugt aus einer Charge NEUER Aufgaben (docs/prefill/<batch>.json)
 * die Datenmigration, den Snapshot fuer verify-prefill und die CSV fuer Lena.
 *
 *   node tools/vorlauf-build.mjs docs/prefill/k8-vorlauf.json <14-stellige Version> aufgaben_k8_vorlauf
 *
 * Unterschied zu prefill-build.mjs: dort werden VORHANDENE Aufgaben per Compare-and-set
 * ergaenzt. Hier entstehen die Aufgaben erst. Jede Aufgabe traegt deshalb neben dem
 * Charge-Format (felder/teile/loesung/leer/pruefung) einen Block `basis`: Text, Format,
 * Teile, known_errors, Figur. Der Snapshot ist der Rohzustand aus `basis` (ohne die
 * Lena-Felder) — verify-prefill prueft dann jedes Lena-Feld als "neu".
 *
 * Die Migration
 *   - legt jede Aufgabe mit festem id als status 'draft' an, alle Lena-Felder gesetzt und
 *     im Kennzeichen tasks.vorbefuellt (wertfrei, Loesungsschutz) markiert,
 *   - schreibt die Loesung ueber public.task_solution_upsert (Aufgabe UND jede
 *     Teilaufgabe in einem correct_answers-Objekt, Lösungsweg, acceptance.known_errors),
 *   - legt fuer Aufgaben mit Figur die task_figures-Zeile an (Upload macht Rasit),
 *   - ist idempotent: on conflict do nothing, Loesung nur, wenn noch keine Zeile besteht.
 * sondierrang: Rang 1 und 2 je Skill nach scripts/content/sondierrang_vorschlag.py.
 */

import fs from 'node:fs';
import path from 'node:path';
import { kennzeichenGrund, wirksam } from './prefill-lib.mjs';

const [chargePfad, version, name] = process.argv.slice(2);
if (!chargePfad || !/^\d{14}$/.test(version ?? '') || !name) {
  console.error('Aufruf: vorlauf-build.mjs <charge.json> <14-stellige Version> <name>');
  process.exit(2);
}
const charge = JSON.parse(fs.readFileSync(chargePfad, 'utf8'));
const basisPfad = chargePfad.replace(/\.json$/, '');
const fehler = [];

// ── Rohzustand (Snapshot) aus basis ──
const roh = (a) => {
  const b = a.basis;
  const mp = b.input_type === 'MULTI_PART';
  return {
    task: {
      id: a.id, title: a.titel, question: b.frage, input_type: b.input_type, skill_key: b.skill_key,
      question_payload: mp ? null : { kind: 'short_input', prompt: b.frage },
      parts: (b.parts ?? []).map((p) => ({ nr: p.nr, kind: p.kind, prompt: p.prompt, unit: null, competency_process: null })),
      unit: b.unit ?? null, status: 'draft', source: charge.source, source_ref: b.source_ref, created_at: null,
      afb: null, est_duration_sec: null, curriculum_grade: null, cluster_id: null,
      competency_content: null, competency_process: null, needs_image: null, vorbefuellt: {},
    },
    sol: null,
  };
};

// ── Sondierrang: Algorithmus aus sondierrang_vorschlag.py (waehle) ──
const ZAHL = /\d+(?:[.,]\d+)?/g;
const zahlen = (t) => (t.match(ZAHL) ?? []).reduce((s, z) => s + Number(z.replace(',', '.')), 0);
const kes = (b) => (b.input_type === 'MULTI_PART' ? Object.values(b.known_errors) : [b.known_errors]);
function waehle(posten) {
  const nachProfil = new Map();
  for (const a of posten) {
    const k = a.fehlbilder.join(',');
    if (!nachProfil.has(k)) nachProfil.set(k, []);
    nachProfil.get(k).push(a);
  }
  for (const g of nachProfil.values()) g.sort((x, y) => x.zahlen - y.zahlen || x.ref.localeCompare(y.ref));
  const breite = (k) => (k ? k.split(',').length : 0);
  const ordnung = [...nachProfil.keys()].sort((p, q) => breite(q) - breite(p)
    || nachProfil.get(p)[0].zahlen - nachProfil.get(q)[0].zahlen || p.localeCompare(q));
  const erst = ordnung[0];
  if (ordnung.length < 2) return [nachProfil.get(erst)[0], nachProfil.get(erst)[1], 'nur ein Profil'];
  const neu = (p) => p.split(',').filter((s) => !erst.split(',').includes(s)).length;
  // max(key=(neu, breite, -zahlen)) wie in Python: bei Gleichstand gewinnt das erste.
  const schluessel = (p) => [neu(p), breite(p), -nachProfil.get(p)[0].zahlen];
  const groesser = (a, b) => { const i = a.findIndex((v, k) => v !== b[k]); return i >= 0 && a[i] > b[i]; };
  const zweit = ordnung.slice(1).reduce((best, p) => (groesser(schluessel(p), schluessel(best)) ? p : best));
  return [nachProfil.get(erst)[0], nachProfil.get(zweit)[0],
    `Rang 1 aus Profil {${erst}}, Rang 2 aus Profil {${zweit}} (${neu(zweit)} neue Fehlbilder)`];
}
const rang = new Map();
const begruendung = {};
const proSkill = new Map();
for (const a of charge.aufgaben) {
  const fb = [...new Set(kes(a.basis).flatMap((k) => Object.values(k)))].sort();
  const e = { id: a.id, ref: a.basis.source_ref, fehlbilder: fb, zahlen: zahlen(a.basis.frage) };
  if (!proSkill.has(a.basis.skill_key)) proSkill.set(a.basis.skill_key, []);
  proSkill.get(a.basis.skill_key).push(e);
}
for (const [skill, posten] of proSkill) {
  // Auffuell-Skills (Charge-Feld ohne_sondierrang): Rang 1 und 2 tragen dort schon
  // freigegebene Aufgaben; neue Entwuerfe bleiben NULL.
  if ((charge.ohne_sondierrang ?? []).includes(skill)) {
    begruendung[skill] = 'kein Rang: Auffuellung, Rang 1 und 2 liegen auf freigegebenen Bestandsaufgaben';
    continue;
  }
  const [r1, r2, grund] = waehle(posten);
  rang.set(r1.id, 1); rang.set(r2.id, 2);
  begruendung[skill] = `${r1.ref} = 1, ${r2.ref} = 2. ${grund}`;
  const p1 = r1.fehlbilder.join(','), p2 = r2.fehlbilder.join(',');
  if (p1 === p2) fehler.push(`${skill}: Rang 1 und 2 im selben Fehlbildprofil`);
}

// ── SQL-Bausteine ──
const q = (s) => (s == null ? 'null' : `'${String(s).replace(/'/g, "''")}'`);
const j = (v) => `${q(JSON.stringify(v))}::jsonb`;
const sql = [];
const csv = [['Aufgabe-ID', 'source_ref', 'Teilaufgabe', 'Feld', 'neuer Wert', 'Art', 'Unsicherheit', 'Begründung']];
const zelle = (v) => (v == null ? '' : typeof v === 'string' ? v : JSON.stringify(v));
const snapshot = [];

for (const a of charge.aufgaben) {
  const b = a.basis;
  const x = roh(a);
  snapshot.push(x);
  const { task, sol, aenderungen, leerKennzeichen } = wirksam(a, x);
  const mp = b.input_type === 'MULTI_PART';

  // Kennzeichen: jedes gesetzte Lena-Feld und jedes bewusst leere.
  const vb = {};
  for (const c of aenderungen) {
    vb[c.schluessel] = { art: c.art, grund: kennzeichenGrund(c.schluessel, c.grund), charge: charge.batch };
    csv.push([a.id, b.source_ref, c.teil ?? '', c.schluessel, zelle(c.wert), c.art, c.sicher, c.grund]);
  }
  for (const l of leerKennzeichen) {
    vb[l.schluessel] = { art: 'leer', grund: l.grund, charge: charge.batch };
    csv.push([a.id, b.source_ref, '', l.schluessel, '', 'bewusst leer', '', l.grund]);
  }

  // Pruefungen, die verify-prefill nicht kennt (neue Aufgaben).
  if (mp) {
    const summe = Object.values(b.zeit_teile ?? {}).reduce((s, v) => s + v, 0);
    if (summe !== task.est_duration_sec) fehler.push(`#${a.nr}: Teilbudgets ${summe} s ≠ Aufgabe ${task.est_duration_sec} s`);
    for (const p of b.parts) csv.push([a.id, b.source_ref, p.nr, 'zeit_teile (nur CSV, keine DB-Spalte)', b.zeit_teile[p.nr], 'neu', 'mittel', 'Teilbudget; Summe = est_duration_sec']);
  }
  if (!task.competency_content) fehler.push(`#${a.nr}: competency_content fehlt am Item`);
  if (/gemeistert|meisterst|mastered|beherrscht/i.test(JSON.stringify(a))) fehler.push(`#${a.nr}: Mastery-Sprache`);
  if (b.figur && /\d/.test(b.figur.alt_text)) fehler.push(`#${a.nr}: alt_text mit Ziffer`);
  if (!!b.figur !== task.needs_image) fehler.push(`#${a.nr}: needs_image passt nicht zur Figur`);

  // acceptance: canonical = erste Variante, known_errors in Objektform.
  const ca = sol.correct_answers;
  const regel = (antw, ke) => ({ canonical: antw[0], known_errors: ke });
  const acceptance = mp
    ? Object.fromEntries(b.parts.map((p) => [String(p.nr), regel(ca[p.nr], b.known_errors[p.nr])]))
    : regel(ca, b.known_errors);
  for (const [teil, ke] of mp ? Object.entries(b.known_errors) : [['', b.known_errors]]) {
    const richtig = mp ? ca[teil] : ca;
    for (const w of Object.keys(ke)) if (richtig.includes(w)) fehler.push(`#${a.nr} ${teil}: known_error ${w} ist eine richtige Antwort`);
    csv.push([a.id, b.source_ref, teil, 'acceptance.known_errors (keine UI)', ke, 'neu', 'hoch', 'Falscher Wert → Fehlbild-Slug']);
  }
  if (rang.has(a.id)) csv.push([a.id, b.source_ref, '', 'sondierrang (keine UI)', rang.get(a.id), 'neu', 'mittel', begruendung[b.skill_key]]);

  const parts = task.parts.map((p) => ({ nr: p.nr, kind: p.kind, prompt: p.prompt, unit: p.unit,
    afb: p.afb, competency_content: p.competency_content, competency_process: p.competency_process }));
  sql.push(`\n-- #${a.nr} ${b.source_ref} · ${a.titel}`);
  sql.push(`insert into public.tasks (\n  id, content_type, title, question, question_payload, input_type, skill_key,\n` +
    `  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,\n` +
    `  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,\n` +
    `  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)\n` +
    `values (\n  ${q(a.id)}::uuid, 'exercise', ${q(a.titel)}, ${q(b.frage)},\n` +
    `  ${task.question_payload ? j(task.question_payload) : 'null'}, ${q(b.input_type)}, ${q(b.skill_key)},\n` +
    `  null, ${task.curriculum_grade},\n` +
    `  (select c.id from public.skill_clusters c where c.id = ${q(task.cluster_id)}::uuid),\n` +
    `  ${q(task.afb)}, ${q(task.competency_content)}, ${q(task.competency_process)},\n` +
    `  ${task.est_duration_sec}, ${q(task.unit)}, ${task.needs_image}, ${rang.get(a.id) ?? 'null'}, 'draft', ${q(charge.source)}, ${q(b.source_ref)},\n` +
    `  false, true, false, false, ${j(mp ? parts : [])}, '[]'::jsonb,\n  ${j(vb)}, now())\n` +
    `on conflict do nothing;`);
  sql.push(`select public.task_solution_upsert(\n  p_task_id         => ${q(a.id)}::uuid,\n` +
    `  p_correct_answers => ${j(ca)},\n  p_solution        => ${q(sol.solution)},\n` +
    `  p_hints           => '[]'::jsonb,\n  p_coach_hints     => '[]'::jsonb,\n` +
    `  p_typical_errors  => ${j(sol.typical_errors)},\n  p_acceptance      => ${j(acceptance)})\n` +
    ` where exists (select 1 from public.tasks t where t.id = ${q(a.id)}::uuid and t.status = 'draft' and t.source = ${q(charge.source)})\n` +
    `   and not exists (select 1 from public.task_solutions s where s.task_id = ${q(a.id)}::uuid);`);
  if (b.figur) {
    sql.push(`insert into public.task_figures (task_id, generator, params, alt_text)\n` +
      `select ${q(a.id)}::uuid, 'koordinatensystem', ${j(b.figur.params)}, ${q(b.figur.alt_text)}\n` +
      ` where exists (select 1 from public.tasks t where t.id = ${q(a.id)}::uuid and t.source = ${q(charge.source)})\n` +
      `on conflict (task_id) do nothing;`);
    csv.push([a.id, b.source_ref, '', 'task_figures (Upload: scripts/figures/upload_figures.py)', b.figur.params, 'neu', 'hoch', b.figur.alt_text]);
  }
}

if (fehler.length) {
  console.error(`Charge abgelehnt:\n  ${fehler.join('\n  ')}`);
  process.exit(1);
}

// charge.kopf (Zeilen ohne "-- ") ersetzt Titel und Einspiel-Reihenfolge; ohne das Feld
// bleibt der Vorlauf-Kopf unveraendert.
const titel = charge.kopf ?? [
  `K8-/K9-Vorlauf, Migration 3 von 3 — ${charge.aufgaben.length} Aufgaben zu geo_koordinaten und term_einsetzen.`,
  `Erzeugt von tools/vorlauf-build.mjs aus ${chargePfad} — nicht von Hand editieren.`,
  '',
  'Einspiel-Reihenfolge: nach 20261001115718_tiefe_k8_vorlauf.sql und',
  '20261001115812_substrat_k8_vorlauf.sql (Knoten + Fehlbild-Slugs muessen stehen).',
];
const kopf = `${titel.map((z) => (z ? `-- ${z}` : '--')).join('\n')}
--
-- ${charge.auswahl}
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/${charge.batch}.csv. Pruefprotokoll: docs/prefill/${charge.batch}-verifikation.md.
--
-- Loesungen ueber public.task_solution_upsert. Die RPC laesst nur admin, Pruefer oder
-- einen Systemaufruf (ist_systemaufruf(): auth.role() = 'service_role') schreiben.
-- In Prod liefert auth.role() ohne JWT NULL (-> Systemaufruf), in der CI-Grundlage
-- (supabase/test-grundlage.sql) aber 'anon' — dort scheiterte die Datei mit "kein
-- Pruefrecht". Deshalb erklaert sie sich ausdruecklich und TRANSAKTIONSLOKAL als
-- Systemaufruf (set_config(..., true)); die Einstellung endet mit dem commit.
-- correct_answers traegt bei MULTI_PART je
-- Teilaufgabe ein Array; acceptance.known_errors in Objektform {falscher_wert: slug},
-- genau so liest lsa_fehlbild_match sie.
--
-- cluster_id per Unterabfrage auf die feste id: skill_clusters wird geseedet, nicht
-- migriert — im CI-Neuaufbau bleibt cluster_id null, in Prod trifft die id.
-- Figuren: task_figures-Zeilen ohne svg_hash; die Abbildung erscheint erst nach
-- scripts/figures/upload_figures.py (Rasit). Bis dahin liefert der Payload kein Bild.
--
-- Sondierrang (Verfahren docs/sondierrang_vorschlag.md, Profil = Menge der Slugs,
-- bei MULTI_PART ueber alle Teile):
${Object.entries(begruendung).map(([s, g]) => `--   ${s}: ${g}`).join('\n')}
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne --single-transaction, und
-- eine Aufgabe ohne Loesung waere still kaputt.

begin;

select set_config('request.jwt.claim.role', 'service_role', true);
`;
const migPfad = path.join('supabase/migrations', `${version}_${name}.sql`);
fs.writeFileSync(migPfad, kopf + sql.join('\n') + '\n\ncommit;\n');
fs.writeFileSync(`${basisPfad}-snapshot.json`, JSON.stringify(snapshot, null, 1) + '\n');
const csvZelle = (v) => (/[",\n;]/.test(v) ? `"${String(v).replace(/"/g, '""')}"` : String(v));
fs.writeFileSync(`docs/prefill/${charge.batch}.csv`, csv.map((r) => r.map((v) => csvZelle(zelle(v))).join(',')).join('\n') + '\n');
console.log(`${migPfad}: ${charge.aufgaben.length} Aufgaben; CSV: ${csv.length - 1} Zeilen`);
for (const [s, g] of Object.entries(begruendung)) console.log(`  sondierrang ${s}: ${g}`);
