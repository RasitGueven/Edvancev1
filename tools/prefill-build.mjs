#!/usr/bin/env node
/**
 * prefill-build.mjs — erzeugt aus einer Charge die Datenmigration, die CSV fuer
 * Lena und eine rein lesende Pruef-SQL gegen die DB-Validatoren.
 *
 *   node tools/prefill-build.mjs docs/prefill/mathe8-pilot.json \
 *        docs/prefill/mathe8-pilot-snapshot.json 20260930150000 prefill_mathe8_pilot
 *
 * Jede schreibende Anweisung traegt
 *   - eine Compare-and-set-Bedingung, markiert als  /*cas*\/ (...):  Feld leer
 *     ODER Feld = exakter alter Wert (nur bei Ueberschreibungen),
 *   - status = 'draft' und den VERA8-Ausschluss,
 *   - das Kennzeichen tasks.vorbefuellt in DERSELBEN Anweisung — es entsteht nur,
 *     wenn der Wert wirklich geschrieben wurde (Loesungsfelder per CTE).
 * Damit ist die Datei idempotent und ueberschreibt keine zwischenzeitlichen Aenderungen.
 */

import fs from 'node:fs';
import path from 'node:path';
import { kennzeichenGrund, keinVera8Sql, ladeCharge, vera8Verstoesse, wirksam } from './prefill-lib.mjs';

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
const TYP = { est_duration_sec: 'int', curriculum_grade: 'int', needs_image: 'bool', cluster_id: 'uuid' };
const lit = (feld, v) => ({ int: String(v), bool: String(v), uuid: `${q(v)}::uuid` }[TYP[feld]] ?? q(v));
const leerSql = (f, a = '') =>
  TYP[f] ? `${a}${f} is null` : `coalesce(btrim(${a}${f}), '') = ''`;
const jsonLeer = (f, a = '') => `coalesce(${a}${f}, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)`;
const cas = (leerBed, altBed) => `/*cas*/ (${leerBed}${altBed ? ` or ${altBed}` : ''})`;
const draft = (id, a = 'd') =>
  `exists (select 1 from public.tasks ${a} where ${a}.id = ${q(id)} and ${a}.status = 'draft' and ${keinVera8Sql(`${a}.`)})`;
const kennzeichen = (c) =>
  j({ [c.schluessel]: { art: c.art, grund: kennzeichenGrund(c.schluessel, c.grund), charge: charge.batch } });
const setzeKennzeichen = (c, a = '') => `vorbefuellt = ${a}vorbefuellt || ${kennzeichen(c)}, vorbefuellt_am = now()`;
const tasksWo = (id, a = '') => `${a}id = ${q(id)} and ${a}status = 'draft' and ${keinVera8Sql(a)}`;

const sql = [];
const csv = [['Aufgabe-ID', 'Teilaufgabe', 'Feld', 'alter Wert', 'neuer Wert', 'Art', 'Unsicherheit', 'Begründung']];
const pruef = [];
const zelle = (v) => (v == null ? '' : typeof v === 'string' ? v : JSON.stringify(v));

for (const a of charge.aufgaben) {
  const x = stand.get(a.id);
  const { task, sol, aenderungen, leerKennzeichen, hatteLoesungszeile } = wirksam(a, x);
  sql.push(`\n-- #${a.nr} ${a.titel}`);
  if (!hatteLoesungszeile && aenderungen.some((c) => c.tabelle === 'task_solutions')) {
    sql.push(`insert into public.task_solutions (task_id) select ${q(a.id)} where ${draft(a.id)} on conflict (task_id) do nothing;`);
  }
  for (const c of aenderungen) {
    const alt = c.casAlt;
    if (c.tabelle === 'tasks') {
      const altBed = alt !== undefined ? `${c.feld} = ${lit(c.feld, alt)}` : null;
      sql.push(`update public.tasks set ${c.feld} = ${lit(c.feld, c.wert)}, ${setzeKennzeichen(c)}\n` +
        ` where ${tasksWo(a.id)} and ${cas(leerSql(c.feld), altBed)};`);
    } else if (c.tabelle === 'tasks.parts') {
      const pk = q(c.feld);
      const altBed = alt !== undefined ? `p->${pk} = ${j(alt)}` : null;
      sql.push(`update public.tasks t set parts = (select jsonb_agg(case when e.p->>'nr' = ${q(c.teil)} ` +
        `then e.p || jsonb_build_object(${pk}, ${j(c.wert)}) else e.p end order by e.o) ` +
        `from jsonb_array_elements(t.parts) with ordinality e(p, o)), ${setzeKennzeichen(c, 't.')}\n` +
        ` where ${tasksWo(a.id, 't.')} and exists (select 1 from jsonb_array_elements(t.parts) p ` +
        `where p->>'nr' = ${q(c.teil)} and ${cas(`coalesce(btrim(p->>${pk}), '') = ''`, altBed)});`);
    } else {
      let set;
      let bed;
      if (c.feld === 'correct_answers' && c.teil) {
        const k = q(c.teil);
        set = `correct_answers = (case when jsonb_typeof(s.correct_answers) = 'object' then s.correct_answers else '{}'::jsonb end) || jsonb_build_object(${k}, ${j(c.wert)})`;
        bed = `(jsonb_typeof(s.correct_answers) = 'object' or s.correct_answers = '[]'::jsonb) and ` +
          cas(`coalesce(jsonb_array_length(case when jsonb_typeof(s.correct_answers->${k}) = 'array' then s.correct_answers->${k} end), 0) = 0`,
            alt !== undefined ? `s.correct_answers->${k} = ${j(alt)}` : null);
      } else if (c.feld === 'solution') {
        set = `solution = ${q(c.wert)}`;
        bed = cas(leerSql('solution', 's.'), alt !== undefined ? `s.solution = ${q(alt)}` : null);
      } else {
        set = `${c.feld} = ${j(c.wert)}`;
        bed = cas(jsonLeer(c.feld, 's.'), alt !== undefined ? `s.${c.feld} = ${j(alt)}` : null);
      }
      sql.push(`with u as (update public.task_solutions s set ${set}\n` +
        `   where s.task_id = ${q(a.id)} and ${draft(a.id)} and ${bed} returning s.task_id)\n` +
        `update public.tasks set ${setzeKennzeichen(c)} where id in (select task_id from u);`);
    }
    const feld = c.tabelle === 'tasks.parts' ? `tasks.parts[${c.teil}].${c.feld}`
      : c.teil ? `task_solutions.${c.feld}[${c.teil}]` : `${c.tabelle}.${c.feld}`;
    csv.push([a.id, c.teil ?? '', feld, zelle(c.alt), zelle(c.wert), c.art, c.sicher, c.grund]);
  }
  for (const l of leerKennzeichen) {
    const c = { schluessel: l.schluessel, art: 'leer', grund: l.grund };
    const leerBed = ['correct_answers', 'solution', 'hints', 'typical_errors'].includes(l.spalte)
      ? `not exists (select 1 from public.task_solutions s where s.task_id = tasks.id and not (${
        l.spalte === 'solution' ? leerSql('solution', 's.') : jsonLeer(l.spalte, 's.')}))`
      : leerSql(l.spalte);
    sql.push(`update public.tasks set ${setzeKennzeichen(c)}\n` +
      ` where ${tasksWo(a.id)} and not (vorbefuellt ? ${q(l.schluessel)}) and ${cas(leerBed)};`);
    csv.push([a.id, '', l.schluessel, '', '', 'bewusst leer', '', l.grund]);
  }

  pruef.push(
    `select ${q(a.nr + ' ' + a.titel)} as aufgabe,\n` +
      `  ${task.input_type === 'MULTI_PART' ? `public.lsa_parts_valid(${j(task.parts)})` : 'null::boolean'} as parts_ok,\n` +
      `  public.lsa_answers_valid(${j(sol.correct_answers)}) as answers_ok,\n` +
      `  public.lsa_has_answers(${task.input_type ? q(task.input_type) : 'null'}, ${j(task.parts)}, ${j(sol.correct_answers)}) as has_answers,\n` +
      `  ${task.afb == null ? 'null' : q(task.afb)} in ('I','II','III') as afb_ok,\n` +
      `  ${task.est_duration_sec ?? 'null'} between 10 and 3600 as dauer_ok,\n` +
      `  ${task.needs_image == null ? 'false' : 'true'} as bildbedarf_gesetzt,\n` +
      `  jsonb_typeof(${j(sol.hints)}) = 'array' and jsonb_typeof(${j(sol.typical_errors)}) = 'array' as json_ok`,
  );
}

const kopf = `-- Datenmigration ${charge.batch}: Vorbefuellung fuer Lenas Pruefung (Item-Pflege).
-- Erzeugt von tools/prefill-build.mjs aus ${chargePfad} — nicht von Hand editieren.
-- ${charge.auswahl}${charge.ersetzt ? `\n-- Ersetzt ${charge.ersetzt}.` : ''}${charge.versionsausnahme ? `\n-- ${charge.versionsausnahme}` : ''}
-- Regeln: nur status = 'draft', nie VERA8 (${keinVera8Sql()} in jedem WHERE),
-- jede Aenderung als Compare-and-set (/*cas*/: leer ODER exakter alter Wert),
-- Kennzeichen tasks.vorbefuellt in derselben Anweisung, keine DDL, keine Status-Felder.
-- Idempotent: ein zweiter Lauf aendert nichts. Werte + Gruende: docs/prefill/${charge.batch}.csv
-- Kein Ziel-DB-Guard in der Datei: CI spielt alle Migrationen in eine leere DB 'neuaufbau' ein
-- (dort treffen die UPDATEs 0 Zeilen). Der Ziel-DB-Check steht in der Apply-Kette (docs/prefill/README.md).
`;
const migPfad = path.join('supabase/migrations', `${version}_${name}.sql`);
fs.writeFileSync(migPfad, kopf + sql.join('\n') + '\n');
const csvZelle = (v) => (/[",\n;]/.test(v) ? `"${String(v).replace(/"/g, '""')}"` : String(v));
fs.writeFileSync(`docs/prefill/${charge.batch}.csv`, csv.map((r) => r.map((v) => csvZelle(v ?? '')).join(',')).join('\n') + '\n');
fs.writeFileSync(`docs/prefill/${charge.batch}-dbcheck.sql`,
  `-- Rein lesend: prueft den aus Snapshot + Charge BERECHNETEN Endstand (Werte eingebettet) mit den DB-Validatoren.\n` +
  pruef.join('\nunion all\n') + ';\n');
console.log(`${migPfad}: ${sql.filter((s) => !s.startsWith('\n--')).length} Anweisungen; CSV: ${csv.length - 1} Zeilen`);
