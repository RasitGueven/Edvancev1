#!/usr/bin/env node
/**
 * lena-board-daten.mjs — erzeugt die Datenmigration 4 des Lena-Boards (Entscheidungen 24 bis 28)
 * aus den Chargen und einem lesenden Prod-Abzug.
 *
 *   ~/bin/dbread -tA -f tools/lena-board-snapshot.sql -o docs/lena-board/daten-snapshot.json
 *   node tools/lena-board-daten.mjs <14-stellige Version>
 *
 * Schreibt (mit fs, nie per Shell-Umleitung):
 *   supabase/migrations/<V>_pruefung_daten.sql   die Migration
 *   docs/lena-board/pilot.csv                    die Pilotliste (Thema, Kurztitel, Typ, AFB, ID)
 *   docs/lena-board/daten-zahlen.md              die Zahlen fuers PR
 *
 * Regeln wie tools/prefill-build.mjs: idempotent, Compare-and-set, nur status draft, nie VERA8.
 *   28  review ohne task_pruefungen-Zeile → draft (nicht VERA8).
 *   24  vorbefuellt.<feld>.sicher aus den Chargen, nur wo der Eintrag existiert und noch kein
 *       "sicher" traegt. Schluessel wie im Bestand: felder/loesung = Feldname, teile =
 *       parts.<nr>.<feld> bzw. correct_answers.<nr> (antwort).
 *   25  typical_errors[].fehlbild, wenn der Grund "Aus acceptance.known_errors (a, b, …)" lautet,
 *       die Anzahl stimmt und typical_errors in Prod noch dem Chargenwert entspricht.
 *   26  Pilot: 100 Aufgaben aus dem Board, ueber alle Themen verteilt; je Thema zuerst
 *       MULTI_PART, dann AFB II/III, dann MC, sonst in der Board-Reihenfolge. Dazu nur_pilot.
 */

import fs from 'node:fs';
import path from 'node:path';

const [version] = process.argv.slice(2);
if (!/^\d{14}$/.test(version ?? '')) {
  console.error('Aufruf: lena-board-daten.mjs <14-stellige Version (date -u +%Y%m%d%H%M%S)>');
  process.exit(2);
}
const PILOT = 100;
const snap = JSON.parse(fs.readFileSync('docs/lena-board/daten-snapshot.json', 'utf8'));
const aufgaben = new Map(snap.aufgaben.map((a) => [a.id, a]));

// ── Chargen: nur Dateien mit "aufgaben", nicht -blind, -ids, -snapshot ──────
const dateien = [
  ...fs.readdirSync('docs/prefill').map((f) => path.join('docs/prefill', f)),
  ...fs.readdirSync('docs/prefill', { withFileTypes: true }).filter((d) => d.isDirectory())
    .flatMap((d) => fs.readdirSync(path.join('docs/prefill', d.name)).map((f) => path.join('docs/prefill', d.name, f))),
].filter((f) => f.endsWith('.json') && !/-(blind|ids|snapshot)[^/]*\.json$/.test(f)).sort();
const chargen = dateien.map((f) => ({ f, d: JSON.parse(fs.readFileSync(f, 'utf8')) })).filter((c) => Array.isArray(c.d.aufgaben));

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const j = (v) => `${q(JSON.stringify(v))}::jsonb`;
const gleich = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// ── 24 · sicher ─────────────────────────────────────────────────────────────
const sicher = []; // [id, {schluessel: sicher}]
let sicherZahl = 0;
// ── 25 · fehlbild ───────────────────────────────────────────────────────────
const fehlbild = []; // [id, alt, neu]
const z25 = { zugeordnet: 0, ohneZuordnung: 0, abweichend: 0, eintraege: 0 };
const MUSTER = /^Aus acceptance\.known_errors \(([^)]*)\)\.?$/;

for (const { d } of chargen) {
  for (const a of d.aufgaben) {
    const x = aufgaben.get(a.id);
    if (!x || x.vera8 || x.status !== 'draft') continue;
    const vb = x.vorbefuellt ?? {};
    const m = {};
    const merk = (schluessel, e) => {
      if (e?.sicher && vb[schluessel] && !('sicher' in vb[schluessel])) m[schluessel] = e.sicher;
    };
    for (const [feld, e] of Object.entries(a.felder ?? {})) merk(feld, e);
    for (const [feld, e] of Object.entries(a.loesung ?? {})) merk(feld, e);
    for (const [nr, t] of Object.entries(a.teile ?? {})) {
      for (const [feld, e] of Object.entries(t)) merk(feld === 'antwort' ? `correct_answers.${nr}` : `parts.${nr}.${feld}`, e);
    }
    if (Object.keys(m).length) {
      sicher.push([a.id, m]);
      sicherZahl += Object.keys(m).length;
    }

    const te = a.loesung?.typical_errors;
    if (!te || !Array.isArray(te.wert)) continue;
    const treffer = MUSTER.exec(te.grund ?? '');
    const slugs = treffer ? treffer[1].split(',').map((s) => s.trim()).filter(Boolean) : [];
    if (!treffer || slugs.length !== te.wert.length) {
      z25.ohneZuordnung += 1;
      continue;
    }
    if (!gleich(x.typical_errors, te.wert)) {
      z25.abweichend += 1;
      continue;
    }
    fehlbild.push([a.id, te.wert, te.wert.map((e, i) => ({ ...e, fehlbild: slugs[i] }))]);
    z25.zugeordnet += 1;
    z25.eintraege += te.wert.length;
  }
}

// ── 26 · Pilot ──────────────────────────────────────────────────────────────
const themen = new Map();
for (const z of snap.board) {
  if (!themen.has(z.thema_key)) themen.set(z.thema_key, []);
  themen.get(z.thema_key).push(z);
}
const rang = (z) => (z.input_type === 'MULTI_PART' ? 0 : z.afb === 'II' || z.afb === 'III' ? 1 : z.input_type === 'MC' ? 2 : 3);
const listen = [...themen.values()].map((l) => [...l].sort((a, b) => rang(a) - rang(b) || a.reihenfolge - b.reihenfolge));
const pilot = [];
// Reihum: je Runde eine Aufgabe je Thema, bis 100 erreicht sind. So sind alle Themen dabei, und ein
// kleines Thema gibt seinen Anteil an die grossen ab.
for (let runde = 0; pilot.length < PILOT && listen.some((l) => l.length > runde); runde += 1) {
  for (const l of listen) {
    if (pilot.length >= PILOT) break;
    if (l[runde]) pilot.push(l[runde]);
  }
}
pilot.sort((a, b) => a.reihenfolge - b.reihenfolge);
const kurz = (t) => (t ?? '').replace(/^AFB (I|II|III) · /, '');

// ── Migration schreiben ─────────────────────────────────────────────────────
const VERA = "source is distinct from 'VERA8_IQB'";
const teile = [];
teile.push(`-- Lena-Board, Migration 4 von 4: pruefung_daten (Entscheidungen 24 bis 28)
-- Erzeugt von tools/lena-board-daten.mjs aus den Chargen (docs/prefill) und dem Abzug
-- docs/lena-board/daten-snapshot.json (${snap.abgezogen_am}) — nicht von Hand editieren.
-- Regeln: nur status = 'draft', nie VERA8, Compare-and-set, keine DDL. Idempotent: ein zweiter Lauf
-- aendert nichts. Kein Ziel-DB-Guard: CI spielt alle Migrationen in eine leere DB ein (0 Zeilen).

-- ── 28 · Alte Staende "zur Freigabe" zurueck auf offen ──────────────────────
-- review ohne task_pruefungen-Zeile hat niemand im neuen Ablauf geprueft. beanstandet bleibt beim Admin.
update public.tasks t
   set status = 'draft', reviewed_by = null, reviewed_at = null
 where t.status = 'review' and t.${VERA}
   and not exists (select 1 from public.task_pruefungen p where p.task_id = t.id);
`);

teile.push(`-- ── 24 · vorbefuellt.<feld>.sicher (${sicherZahl} Eintraege in ${sicher.length} Aufgaben) ──
with m(id, sicher) as (values
${sicher.map(([id, m]) => `  (${q(id)}::uuid, ${j(m)})`).join(',\n')}
)
update public.tasks t
   set vorbefuellt = (select jsonb_object_agg(e.key, case when m.sicher ? e.key and not (e.value ? 'sicher')
                                                         then e.value || jsonb_build_object('sicher', m.sicher ->> e.key)
                                                         else e.value end)
                        from jsonb_each(t.vorbefuellt) e)
  from m
 where t.id = m.id and t.status = 'draft' and t.${VERA}
   and exists (select 1 from jsonb_each(t.vorbefuellt) e where m.sicher ? e.key and not (e.value ? 'sicher'));
`);

teile.push(`-- ── 25 · typical_errors[].fehlbild (${z25.zugeordnet} Aufgaben, ${z25.eintraege} Eintraege) ──
-- Compare-and-set: nur wo typical_errors noch genau dem Chargenwert entspricht.
with m(id, alt, neu) as (values
${fehlbild.map(([id, alt, neu]) => `  (${q(id)}::uuid, ${j(alt)}, ${j(neu)})`).join(',\n')}
)
update public.task_solutions s
   set typical_errors = m.neu, updated_at = now()
  from m, public.tasks t
 where s.task_id = m.id and t.id = m.id and t.status = 'draft' and t.${VERA}
   and s.typical_errors = m.alt;
`);

teile.push(`-- ── 26 · Pilot: ${pilot.length} Aufgaben aus ${new Set(pilot.map((z) => z.thema_key)).size} Themen (docs/lena-board/pilot.csv) ──
update public.tasks t
   set pruef_pilot = true
 where t.id in (
${pilot.map((z) => `   ${q(z.id)}`).join(',\n')}
 ) and t.status = 'draft' and t.${VERA} and not t.pruef_pilot;

update public.pruef_einstellungen set nur_pilot = true where not nur_pilot;
`);

const mig = path.join('supabase/migrations', `${version}_pruefung_daten.sql`);
fs.writeFileSync(mig, teile.join('\n'));

const csvZelle = (v) => (/[",\n;]/.test(String(v)) ? `"${String(v).replace(/"/g, '""')}"` : String(v));
const TYP = { MULTI_PART: 'Teilaufgaben', MC: 'Multiple Choice', NUMERIC: 'Zahl', SHORT_TEXT: 'Kurzantwort', TERM: 'Term' };
fs.writeFileSync('docs/lena-board/pilot.csv',
  [['Thema', 'Kurztitel', 'Typ', 'AFB', 'ID'], ...pilot.map((z) => [z.thema_label, kurz(z.title), TYP[z.input_type] ?? z.input_type, z.afb ?? '', z.id])]
    .map((r) => r.map(csvZelle).join(',')).join('\n') + '\n');

const jeTyp = Object.entries(pilot.reduce((acc, z) => ({ ...acc, [z.input_type]: (acc[z.input_type] ?? 0) + 1 }), {}));
const jeAfb = Object.entries(pilot.reduce((acc, z) => ({ ...acc, [z.afb]: (acc[z.afb] ?? 0) + 1 }), {}));
const zahlen = `# Zahlen der Datenmigration 4 (pruefung_daten)

Abzug: \`docs/lena-board/daten-snapshot.json\` vom ${snap.abgezogen_am} (dbread, read-only).
Chargen: ${chargen.length} Dateien (${chargen.map((c) => path.basename(c.f)).join(', ')}).

| Datenpunkt | Zahl |
|---|---|
| 28 · review ohne task_pruefungen → draft | ${snap.review_ohne_pruefung} |
| 24 · sicher nachgetragen | ${sicherZahl} Einträge in ${sicher.length} Aufgaben |
| 25 · fehlbild zugeordnet | ${z25.zugeordnet} Aufgaben (${z25.eintraege} Einträge) |
| 25 · ohne Zuordnung (Grund ohne Slug-Liste oder Anzahl passt nicht) | ${z25.ohneZuordnung} Aufgaben |
| 25 · ohne Zuordnung (typical_errors weicht in Prod vom Chargenwert ab) | ${z25.abweichend} Aufgaben |
| 26 · Pilot | ${pilot.length} Aufgaben aus ${new Set(pilot.map((z) => z.thema_key)).size} Themen |

Pilot nach Typ: ${jeTyp.map(([k, v]) => `${TYP[k] ?? k} ${v}`).join(' · ')}.
Pilot nach AFB: ${jeAfb.map(([k, v]) => `${k} ${v}`).join(' · ')}.
Pilot nach Stufe: ${['erste', 'zweite', 'erprobung'].map((s) => `${{ erste: '7/8', zweite: '9/10', erprobung: '5/6' }[s]} ${pilot.filter((z) => z.stufe === s).length}`).join(' · ')}.
`;
fs.writeFileSync('docs/lena-board/daten-zahlen.md', zahlen);
console.log(`${mig}\n${zahlen}`);
