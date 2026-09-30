#!/usr/bin/env node
/**
 * prefill-build.mjs — erzeugt aus einer Charge die Datenmigration, die CSV fuer
 * Lena und eine rein lesende Pruef-SQL gegen die DB-Validatoren.
 *
 *   node tools/prefill-build.mjs docs/prefill/mathe8-pilot.json \
 *        docs/prefill/mathe8-pilot-snapshot.json 20260930120000 prefill_mathe8_pilot
 *
 * Jedes UPDATE traegt "Feld ist leer" UND "status = 'draft'" im WHERE — die Datei
 * ist idempotent und fasst weder gesetzte Werte noch gepruefte Aufgaben an.
 */

import fs from 'node:fs';
import path from 'node:path';
import { keinVera8Sql, ladeCharge, vera8Verstoesse, wirksam } from './prefill-lib.mjs';

const [chargePfad, snapPfad, version, name] = process.argv.slice(2);
if (!name || !/^\d{14}$/.test(version)) {
  console.error('Aufruf: prefill-build.mjs <charge.json> <snapshot.json> <14-stellige Version> <name>');
  process.exit(2);
}
const { charge, stand } = ladeCharge(chargePfad, snapPfad);
const vera = vera8Verstoesse(charge, stand);
if (vera.length) {
  console.error(`VERA8 wird nicht vorbefuellt — Charge abgelehnt:\n  ${vera.join('\n  ')}`);
  process.exit(1);
}

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const j = (v) => `${q(JSON.stringify(v))}::jsonb`;
const INT = new Set(['est_duration_sec', 'curriculum_grade']);
const leerSql = (f) => (INT.has(f) ? `${f} is null` : `coalesce(btrim(${f}), '') = ''`);
// Jede Anweisung traegt den VERA8-Ausschluss selbst — auch wenn eine Charge ihn
// einmal nicht haette, fasst die Datei keine VERA8-Aufgabe an (verify prueft das).
const draft = (id) => `exists (select 1 from public.tasks d where d.id = ${q(id)} and d.status = 'draft' and ${keinVera8Sql('d.')})`;

const sql = [];
const csv = [['Aufgabe-ID', 'Teilaufgabe', 'Feld', 'neuer Wert', 'Unsicherheit/Begründung']];
const pruef = [];

for (const a of charge.aufgaben) {
  const x = stand.get(a.id);
  const { task, sol, aenderungen, hatteLoesungszeile } = wirksam(a, x);
  sql.push(`\n-- #${a.nr} ${a.titel}`);
  if (!hatteLoesungszeile && aenderungen.some((c) => c.tabelle === 'task_solutions')) {
    sql.push(`insert into public.task_solutions (task_id) select ${q(a.id)} where ${draft(a.id)} on conflict (task_id) do nothing;`);
  }
  for (const c of aenderungen) {
    if (c.tabelle === 'tasks') {
      const wert = INT.has(c.feld) ? String(c.wert) : q(c.wert);
      sql.push(`update public.tasks set ${c.feld} = ${wert} where id = ${q(a.id)} and status = 'draft' and ${keinVera8Sql()} and ${leerSql(c.feld)};`);
    } else if (c.tabelle === 'tasks.parts') {
      sql.push(
        `update public.tasks t set parts = (select jsonb_agg(case when e.p->>'nr' = ${q(c.teil)} ` +
          `then e.p || jsonb_build_object(${q(c.feld)}, ${q(c.wert)}) else e.p end order by e.o) ` +
          `from jsonb_array_elements(t.parts) with ordinality e(p, o))\n` +
          ` where t.id = ${q(a.id)} and t.status = 'draft' and ${keinVera8Sql('t.')} and exists (select 1 from jsonb_array_elements(t.parts) p ` +
          `where p->>'nr' = ${q(c.teil)} and coalesce(btrim(p->>${q(c.feld)}), '') = '');`,
      );
    } else if (c.feld === 'correct_answers' && c.teil) {
      const k = q(c.teil);
      sql.push(
        `update public.task_solutions set correct_answers = (case when jsonb_typeof(correct_answers) = 'object' ` +
          `then correct_answers else '{}'::jsonb end) || jsonb_build_object(${k}, ${j(c.wert)})\n` +
          ` where task_id = ${q(a.id)} and ${draft(a.id)} and (jsonb_typeof(correct_answers) = 'object' or correct_answers = '[]'::jsonb)` +
          ` and coalesce(jsonb_array_length(case when jsonb_typeof(correct_answers->${k}) = 'array' then correct_answers->${k} end), 0) = 0;`,
      );
    } else if (c.feld === 'solution') {
      sql.push(`update public.task_solutions set solution = ${q(c.wert)} where task_id = ${q(a.id)} and ${draft(a.id)} and ${leerSql('solution')};`);
    } else {
      sql.push(
        `update public.task_solutions set ${c.feld} = ${j(c.wert)} where task_id = ${q(a.id)} and ${draft(a.id)} ` +
          `and coalesce(${c.feld}, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb);`,
      );
    }
    const feld = c.tabelle === 'tasks.parts' ? `tasks.parts[${c.teil}].${c.feld}`
      : c.teil ? `task_solutions.${c.feld}[${c.teil}]` : `${c.tabelle}.${c.feld}`;
    csv.push([a.id, c.teil ?? '', feld, typeof c.wert === 'string' ? c.wert : JSON.stringify(c.wert), `Sicherheit ${c.sicher}: ${c.grund}`]);
  }
  for (const [feld, grund] of Object.entries(a.leer ?? {})) csv.push([a.id, '', feld, '', `LEER: ${grund}`]);

  pruef.push(
    `select ${q(a.nr + ' ' + a.titel)} as aufgabe,\n` +
      `  ${task.input_type === 'MULTI_PART' ? `public.lsa_parts_valid(${j(task.parts)})` : 'null::boolean'} as parts_ok,\n` +
      `  public.lsa_answers_valid(${j(sol.correct_answers)}) as answers_ok,\n` +
      `  public.lsa_has_answers(${task.input_type ? q(task.input_type) : 'null'}, ${j(task.parts)}, ${j(sol.correct_answers)}) as has_answers,\n` +
      `  ${task.afb == null ? 'null' : q(task.afb)} in ('I','II','III') as afb_ok,\n` +
      `  ${task.est_duration_sec ?? 'null'} between 10 and 3600 as dauer_ok,\n` +
      `  jsonb_typeof(${j(sol.hints)}) = 'array' and jsonb_typeof(${j(sol.typical_errors)}) = 'array' as json_ok`,
  );
}

for (const [feld, grund] of Object.entries(charge.leer_alle ?? {})) csv.push(['(alle)', '', feld, '', `LEER: ${grund}`]);

const kopf = `-- Datenmigration ${charge.batch}: Vorbefuellung fuer Lenas Pruefung (Item-Pflege).
-- Erzeugt von tools/prefill-build.mjs aus ${chargePfad} — nicht von Hand editieren.
-- ${charge.auswahl}
-- Regeln: nur leere Felder, nur status = 'draft', nie VERA8 (${keinVera8Sql()} in jedem WHERE),
-- Status-/Freigabefelder unangetastet, keine DDL. Idempotent: ein zweiter Lauf aendert nichts. Werte + Gruende: docs/prefill/${charge.batch}.csv
-- Kein Ziel-DB-Guard in der Datei: CI spielt alle Migrationen in eine leere DB 'neuaufbau' ein
-- (dort treffen die UPDATEs 0 Zeilen). Der Ziel-DB-Check steht in der Apply-Kette (docs/prefill/README.md).
`;
const migPfad = path.join('supabase/migrations', `${version}_${name}.sql`);
fs.writeFileSync(migPfad, kopf + sql.join('\n') + '\n');
const zelle = (v) => (/[",\n;]/.test(v) ? `"${String(v).replace(/"/g, '""')}"` : String(v));
fs.writeFileSync(`docs/prefill/${charge.batch}.csv`, csv.map((r) => r.map(zelle).join(',')).join('\n') + '\n');
fs.writeFileSync(`docs/prefill/${charge.batch}-dbcheck.sql`,
  `-- Rein lesend: prueft den aus Snapshot + Charge BERECHNETEN Endstand (Werte eingebettet) mit den DB-Validatoren.\n` +
  pruef.join('\nunion all\n') + ';\n');
console.log(`${migPfad}: ${sql.filter((s) => !s.startsWith('\n--')).length} Anweisungen; CSV: ${csv.length - 1} Zeilen`);
