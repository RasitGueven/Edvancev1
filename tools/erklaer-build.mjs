#!/usr/bin/env node
/**
 * erklaer-build.mjs — erzeugt aus einer Erklär-Charge (docs/prefill/<batch>.json) die Daten-Migration
 * für erklaer_kernidee, erklaer_schritt und erklaer_check (E1-Tabellen).
 *
 *   node tools/erklaer-build.mjs docs/prefill/erklaer-k8-linfkt.json <14-stellige Version> erklaer_k8_linfkt
 *
 * Die Check-Aufgaben entstehen vorher über tools/vorlauf-build.mjs (eigene Charge, einsatz {check}).
 * Vor dem Schreiben läuft tools/erklaer-rechnen.mjs; ist die Nachrechnung rot, entsteht keine Datei.
 *
 * Die Migration
 *   - legt jede Kernidee und jeden Schritt mit fester id an, Status entwurf, Quelle ki,
 *     und hängt die Checks an (erklaer_check, Reihenfolge),
 *   - ist idempotent: on conflict do nothing; ein zweiter Lauf ändert nichts, auch nicht, was
 *     Lena inzwischen geprüft hat,
 *   - schreibt direkt in die Tabellen (Migration als Systemrolle, wie die Aufgaben-Chargen),
 *     nicht über erklaer_*_speichern: die Funktionen vergeben eigene ids und erhöhen pruef_version,
 *   - lässt formeln leer: tools/formeln-svg.mjs erzeugt die SVGs nach dem Einspielen und trägt
 *     die Hashes über erklaer_formeln_setzen ein (offene-punkte-e1 14),
 *   - trägt Bilder als {svg_hash, alt} ein; die Datei lädt tools/erklaer-bilder.mjs nach
 *     task-assets/erklaer/bilder/<svg_hash>.svg,
 *   - prüft am Ende: jedes Fehlbild steht in fehlbild_labels, jeder Check hat Einsatz nur check.
 */

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { ladeUndPruefe } from './erklaer-rechnen.mjs';

const q = (s) => (s == null ? 'null' : `'${String(s).replace(/'/g, "''")}'`);
const j = (v) => (v == null ? 'null' : `${q(JSON.stringify(v))}::jsonb`);
const arr = (a) => `${q(`{${a.join(',')}}`)}::text[]`;

/** Migration als Text aus einer Charge. */
export function migration(charge, chargePfad) {
  const ks = charge.kernideen;
  const schritte = ks.flatMap((k) => k.schritte.map((s) => ({ ...s, kernidee_id: k.id })));
  const checks = ks.flatMap((k) => k.checks.map((c) => ({ ...c, kernidee_id: k.id })));
  const slugs = [...new Set(schritte.flatMap((s) => s.fehlbild_slugs))].sort();
  const kids = ks.map((k) => `${q(k.id)}::uuid`).join(', ');
  const skills = [...new Set(ks.map((k) => k.skill_key))];

  const kopf = [
    `-- Erklärsequenzen ${charge.thema_key} (E2b), Migration 2 von 2 — ${ks.length} Kernideen, ${schritte.length} Schritte,`,
    `-- ${checks.length} Checks zu ${skills.join(', ')}.`,
    `-- Erzeugt von tools/erklaer-build.mjs aus ${chargePfad} — nicht von Hand editieren.`,
    '--',
    '-- Einspiel-Reihenfolge: nach der Check-Migration (erklaer_check verweist auf die Check-Aufgaben).',
    '--',
    '-- Alles ist KI-Entwurf: Kernideen und Schritte status entwurf, quelle ki. Freigegeben wird nichts;',
    '-- Lena prüft in L6, ein Admin gibt frei (Entscheidung 18). erklaer_start liefert die Sequenz nur',
    '-- im Testlauf (20261008124414_a2_erklaer_testlauf.sql), sonst nichts.',
    '--',
    '-- formeln bleibt leer, bis tools/formeln-svg.mjs gelaufen ist; Bilder {svg_hash, alt} lädt',
    '-- tools/erklaer-bilder.mjs nach task-assets/erklaer/bilder/<svg_hash>.svg.',
    '--',
    '-- Idempotent: on conflict do nothing. Kein begin/commit: mig spielt mit psql -1 in einer',
    '-- Transaktion ein, die CI ohne Klammer.',
    '',
  ];
  const sql = [...kopf];
  sql.push('insert into public.erklaer_kernidee (id, skill_key, nr, titel, status, quelle) values');
  sql.push(ks.map((k) => `  (${q(k.id)}::uuid, ${q(k.skill_key)}, ${k.nr}, ${q(k.titel)}, 'entwurf', 'ki')`).join(',\n'));
  sql.push('on conflict do nothing;\n');
  for (const s of schritte) {
    const k = ks.find((x) => x.id === s.kernidee_id);
    sql.push(`-- ${k.skill_key} · Kernidee ${k.nr} · Variante ${s.variante} · ${s.art}`);
    const bild = s.bild ? { svg_hash: s.bild.svg_hash, alt: s.bild.alt } : null;
    sql.push('insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)');
    sql.push(`values (${q(s.id)}::uuid, ${q(s.kernidee_id)}::uuid, ${q(s.variante)}, ${q(s.art)},\n` +
      `  ${q(s.inhalt)},\n  ${j(bild)}, ${arr(s.fehlbild_slugs)}, 'entwurf')`);
    sql.push('on conflict do nothing;\n');
  }
  sql.push('insert into public.erklaer_check (kernidee_id, task_id, reihenfolge) values');
  sql.push(checks.map((c) => `  -- ${c.ref}\n  (${q(c.kernidee_id)}::uuid, ${q(c.task_id)}::uuid, ${c.reihenfolge})`).join(',\n'));
  sql.push('on conflict do nothing;\n');
  sql.push(`-- Prüfungen: Fehlbilder im Katalog, Checks nur mit Einsatz check.
do $pruefung$
begin
  if exists (select 1 from unnest(${arr(slugs)}) s(slug)
              where not exists (select 1 from public.fehlbild_labels l where l.slug = s.slug)) then
    raise exception 'erklaer: Fehlbild fehlt in fehlbild_labels';
  end if;
  if exists (select 1 from public.erklaer_check c join public.tasks t on t.id = c.task_id
              where c.kernidee_id in (${kids})
                and t.einsatz is distinct from '{check}'::text[]) then
    raise exception 'erklaer: Check-Aufgabe mit anderem Einsatz als check';
  end if;
end
$pruefung$;`);
  return sql.join('\n') + '\n';
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const [chargePfad, version, name] = process.argv.slice(2);
  if (!chargePfad || !/^\d{14}$/.test(version ?? '') || !name) {
    console.error('Aufruf: erklaer-build.mjs <charge.json> <14-stellige Version> <name>');
    process.exit(2);
  }
  const fehler = ladeUndPruefe(chargePfad);
  if (fehler.length) { console.error(`Nachrechnung rot:\n  ${fehler.join('\n  ')}`); process.exit(1); }
  const charge = JSON.parse(fs.readFileSync(chargePfad, 'utf8'));
  const ziel = path.join('supabase/migrations', `${version}_${name}.sql`);
  fs.writeFileSync(ziel, migration(charge, chargePfad));
  console.log(`${ziel}: ${charge.kernideen.length} Kernideen`);
}
