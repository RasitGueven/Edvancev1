/**
 * hinweise-e3.mjs — Hinweis-Entwürfe (Paket E3): nachrechnen, Vorschau, Daten-Migration.
 *
 *   node tools/hinweise-e3.mjs pruefen   [skill…]                 Exit 1 bei jedem Befund
 *   node tools/hinweise-e3.mjs vorschau  <datei.md> [skill…]
 *   node tools/hinweise-e3.mjs migration <version> <name> [skill…]  schreibt supabase/migrations/<v>_<n>.sql
 *   node tools/hinweise-e3.mjs fixture   [skill…]                 SQL nur für die Wegwerf-DB (fehlende Aufgaben)
 *
 * Quelle: tools/hinweise-e3/<skill>.mjs (Schlüssel tasks.source_ref). Bestand: docs/prefill/hinweise-e3-snapshot.json
 * (Prod per dbread, nur gelesen). Ohne Skill-Liste gelten alle Quellen im Ordner. Keine DB, kein LLM.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { pruefeAufgabe, alsHints, fehlbilder } from './hinweise-e3-lib.mjs';

const WURZEL = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const QUELLEN = path.join(WURZEL, 'tools/hinweise-e3');
const SNAPSHOT = path.join(WURZEL, 'docs/prefill/hinweise-e3-snapshot.json');
const VERA8 = 'VERA8_IQB';
/** Kennzeichen für Lena (L5), Entscheidung Rasit 12.10.2026: nur wo die k9-Charge „leer“ eingetragen hat. */
const KENNZEICHEN = { art: 'neu', grund: 'E3: drei Hinweisstufen für die Session. In der LSA gibt es keine Hinweise (lsa_hint gesperrt).' };

export async function ladeQuellen(skills) {
  const dateien = fs.readdirSync(QUELLEN).filter((f) => f.endsWith('.mjs')).sort();
  const out = [];
  for (const f of dateien) {
    const q = (await import(pathToFileURL(path.join(QUELLEN, f)).href)).default;
    if (!skills.length || skills.includes(q.skill)) out.push(q);
  }
  if (skills.length && out.length !== skills.length) throw new Error(`Quelle fehlt für: ${skills.filter((s) => !out.some((q) => q.skill === s)).join(', ')}`);
  return out;
}

const bestand = () => JSON.parse(fs.readFileSync(SNAPSHOT, 'utf8')).aufgaben;

/** Paare (Aufgabe, Eintrag) und Abdeckungsfehler. */
function paare(quellen) {
  const alle = bestand();
  const fehler = [], liste = [];
  for (const q of quellen) {
    const aufgaben = alle.filter((t) => t.skill_key === q.skill);
    if (!aufgaben.length) fehler.push(`${q.skill}: keine Aufgabe im Bestand`);
    for (const t of aufgaben) {
      const e = q.aufgaben[t.source_ref];
      if (!e) { fehler.push(`${q.skill}: keine Hinweise für ${t.source_ref}`); continue; }
      if (t.source === VERA8) fehler.push(`${t.source_ref}: VERA8 wird nie angefasst`);
      if (!(t.einsatz ?? []).includes('session')) fehler.push(`${t.source_ref}: kein Einsatz session`);
      if (Array.isArray(t.hints) && t.hints.length) fehler.push(`${t.source_ref}: hat schon Hinweise`);
      liste.push({ t, e, skill: q.skill });
    }
    for (const ref of Object.keys(q.aufgaben)) {
      if (!aufgaben.some((t) => t.source_ref === ref)) fehler.push(`${q.skill}: ${ref} steht nicht im Bestand`);
    }
  }
  return { fehler, liste };
}

export function pruefen(quellen) {
  const { fehler, liste } = paare(quellen);
  for (const { t, e } of liste) fehler.push(...pruefeAufgabe(t, e).fehler);
  return { fehler, liste };
}

const md = (s) => String(s ?? '').replace(/\|/g, '\\|').replace(/\n+/g, '<br>');

function vorschau(liste) {
  const z = ['# Hinweise E3 · Vorschau (KI-Entwurf, alles `entwurf`)', '',
    'Erzeugt von `node tools/hinweise-e3.mjs vorschau`. Quelle: `tools/hinweise-e3/<skill>.mjs`, Bestand:',
    '`docs/prefill/hinweise-e3-snapshot.json` (Prod, dbread 12.10.2026). Jede Zahl ist von',
    '`node tools/hinweise-e3.mjs pruefen` nachgerechnet. Nicht von Hand ändern.', ''];
  let skill = null;
  for (const { t, e, skill: s } of liste) {
    if (s !== skill) { z.push(`## ${s}`, ''); skill = s; }
    const ke = [...fehlbilder(t)].join(', ') || '–';
    const antwort = Array.isArray(t.correct_answers) ? t.correct_answers[0] : Object.entries(t.correct_answers ?? {}).map(([k, v]) => `${k}: ${v[0]}`).join(' · ');
    z.push(`### ${t.source_ref} · ${t.title}`, '',
      `Aufgabe (\`${t.input_type}\`, \`${t.id}\`): ${md(t.question)}`, '',
      ...(t.question_payload?.options ? [`Optionen: ${t.question_payload.options.map((o) => `${o.id}) ${md(o.label)}`).join(' · ')}`, ''] : []),
      `Antwort: ${md(antwort)} · Fehlbilder (known_errors): ${ke}`, '',
      '| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |',
      '|---|---|---|---|',
      `| ${md(t.solution)} | ${e.stufen.map((st) => md(st.text) + (st.fehlbild ? `<br>_Fehlbild: ${[].concat(st.fehlbild).join(', ')}_` : '')).join(' | ')} |`, '');
  }
  return z.join('\n');
}

const sql = (s) => `'${String(s).replace(/'/g, "''")}'`;

function migration(liste, version, name) {
  const quadr = liste.filter(({ t }) => t.skill_key.startsWith('gleichung_quadr_'));
  const zeilen = liste.map(({ t, e }, i) =>
    `  (${sql(t.id)}::uuid, ${sql(JSON.stringify(alsHints(e)))}::jsonb)${i < liste.length - 1 ? ',' : ''} -- ${t.skill_key} ${t.source_ref}`);
  return `-- E3 (Session-Rahmen): Hinweise als KI-Entwurf für die Session-Aufgaben aus dem Szenario Batu.
-- Erzeugt von: node tools/hinweise-e3.mjs migration ${version} ${name}
-- Quelle tools/hinweise-e3/<skill>.mjs, nachgerechnet von tools/hinweise-e3.mjs pruefen, zweitgeprüft
-- (docs/prefill/befunde-hinweise-e3.md). Nicht von Hand ändern.
--
-- Nur Daten. Setzt hints ausschließlich, wo noch keiner steht (hints = []), nur bei Einsatz session, nie VERA8.
-- Jeder Hinweis kommt als status entwurf; das Flag edvance.hinweis_status wird nicht gesetzt, der Trigger
-- hinweise_status_folgt_text macht jeden neuen Text ohnehin zum Entwurf. Aufgabe, Lösung, Status und
-- known_errors bleiben unverändert. Ein zweiter Lauf ändert nichts (Bedingung hints = []).
-- Nebenwirkung: task_solutions_pruef_version zählt tasks.pruef_version der ${liste.length} Aufgaben hoch (gewollt: L5 sieht neuen Stand).
--
-- Zweite Anweisung (Entscheidung Rasit 12.10.2026): Bei den ${quadr.length} Aufgaben gleichung_quadr_* steht in
-- tasks.vorbefuellt.hints noch „leer“ (Charge k9-quadrgl: „ohne Hilfe lösbar (LSA), keine Hinweise“). Das Kennzeichen
-- wird auf „neu“ gesetzt, vorbefuellt_am = now() wie bei jeder Vorbefüllung; nur wo es „leer“ ist und die drei
-- Hinweise stehen. pruef_version zählt dabei noch einmal hoch (in Ordnung). Ein zweiter Lauf ändert nichts.
-- Läuft nach 20261013173601_lsa_ohne_hinweise (lsa_hint liefert in der LSA keine Hinweise).

update public.task_solutions s
   set hints = v.hints
  from (values
${zeilen.join('\n')}
  ) as v(task_id, hints)
 where s.task_id = v.task_id
   and coalesce(s.hints, '[]'::jsonb) = '[]'::jsonb
   and exists (select 1 from public.tasks t
                where t.id = s.task_id
                  and 'session' = any (t.einsatz)
                  and t.source is distinct from '${VERA8}');

update public.tasks t
   set vorbefuellt = t.vorbefuellt || jsonb_build_object('hints', ${sql(JSON.stringify(KENNZEICHEN))}::jsonb),
       vorbefuellt_am = now()
 where t.id in (
${quadr.map(({ t: a }, i) => `  ${sql(a.id)}::uuid${i < quadr.length - 1 ? ',' : ''} -- ${a.source_ref}`).join('\n')}
       )
   and t.vorbefuellt -> 'hints' ->> 'art' = 'leer'
   and 'session' = any (t.einsatz)
   and t.source is distinct from '${VERA8}'
   and exists (select 1 from public.task_solutions s where s.task_id = t.id and jsonb_array_length(s.hints) = 3);
`;
}

/** Nur Wegwerf-DB: Aufgaben aus dem Bestand anlegen, die dort fehlen (Fundament kam nicht per Migration nach Prod). */
function fixture(liste) {
  const z = ['-- Wegwerf-DB E3: fehlende Aufgaben aus docs/prefill/hinweise-e3-snapshot.json (hints leer). Nie in Prod.'];
  for (const { t } of liste) {
    const j = (v) => (v == null ? 'null' : `${sql(JSON.stringify(v))}::jsonb`);
    const neu = `where not exists (select 1 from public.tasks where id = ${sql(t.id)})`;
    z.push(`insert into public.tasks (id, skill_key, title, status, einsatz, source, source_ref, input_type, question, parts, question_payload, content_type)
  select ${sql(t.id)}, ${sql(t.skill_key)}, ${sql(t.title)}, ${sql(t.status)}, ${sql(`{${t.einsatz.join(',')}}`)}, ${sql(t.source)}, ${sql(t.source_ref)},
         ${sql(t.input_type)}, ${sql(t.question)}, ${j(t.parts ?? [])}, ${j(t.question_payload)}, 'exercise'
  ${neu};`);
    z.push(`insert into public.task_solutions (task_id, correct_answers, solution, hints, acceptance)
  select ${sql(t.id)}, ${j(t.correct_answers)}, ${t.solution == null ? 'null' : sql(t.solution)}, '[]', ${j(t.acceptance)}
  where not exists (select 1 from public.task_solutions where task_id = ${sql(t.id)});`);
  }
  return z.join('\n') + '\n';
}

async function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  if (cmd === 'pruefen') {
    const { fehler, liste } = pruefen(await ladeQuellen(rest));
    const zahlen = liste.reduce((n, { e }) => n + e.stufen.length, 0);
    console.log(`Aufgaben ${liste.length}, Hinweise ${zahlen}, Befunde ${fehler.length}`);
    for (const f of fehler) console.log('  ✗ ' + f);
    process.exit(fehler.length ? 1 : 0);
  }
  if (cmd === 'vorschau') {
    const [datei, ...skills] = rest;
    const { fehler, liste } = pruefen(await ladeQuellen(skills));
    if (fehler.length) { console.error(`pruefen ist rot (${fehler.length}), keine Vorschau`); process.exit(1); }
    fs.writeFileSync(path.resolve(datei), vorschau(liste) + '\n');
    console.log(`${datei}: ${liste.length} Aufgaben`);
    return;
  }
  if (cmd === 'migration') {
    const [version, name, ...skills] = rest;
    if (!/^\d{14}$/.test(version ?? '') || !/^[a-z0-9_]+$/.test(name ?? '')) throw new Error('Aufruf: migration <version> <name>');
    const { fehler, liste } = pruefen(await ladeQuellen(skills));
    if (fehler.length) { console.error(`pruefen ist rot (${fehler.length}), keine Migration`); process.exit(1); }
    const datei = path.join(WURZEL, `supabase/migrations/${version}_${name}.sql`);
    fs.writeFileSync(datei, migration(liste, version, name));
    console.log(`${path.relative(WURZEL, datei)}: ${liste.length} Aufgaben`);
    return;
  }
  if (cmd === 'fixture') {
    const { liste } = paare(await ladeQuellen(rest));
    process.stdout.write(fixture(liste));
    return;
  }
  console.error('Aufruf: pruefen | vorschau <datei> | migration <version> <name>  [skill…]');
  process.exit(2);
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main().catch((e) => { console.error(e.message); process.exit(2); });
}
