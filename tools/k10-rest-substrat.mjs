#!/usr/bin/env node
/**
 * k10-rest-substrat.mjs — schreibt die Substrat-Migration eines Themas aus dem zentralen Plan
 * docs/k10-rest/graph.json (Knoten, Kanten mit Begruendung, neue Fehlbilder).
 *
 *   node tools/k10-rest-substrat.mjs <kurz>      # z. B. wurzel; Version aus docs/k10-rest/versionen.txt
 *
 * Warum zentral erzeugt: Die Themen haengen voneinander ab (Wurzel -> Pythagoras -> Kegel,
 * Wurzel -> quadratische Gleichungen -> Nullstellen). Der Graph wurde als Ganzes geplant und
 * mit tools/k10-rest-graph-check.mjs gegen Prod geprueft; die Migration gibt ihn nur wieder.
 * Datei ohne begin/commit: `mig` spielt sie mit psql -1 in einer Transaktion ein.
 */
import fs from 'node:fs';

const kurz = process.argv[2];
const plan = JSON.parse(fs.readFileSync('docs/k10-rest/graph.json', 'utf8'));
const thema = plan.themen.find((t) => t.kurz === kurz);
if (!thema) { console.error(`Thema ${kurz} fehlt in graph.json`); process.exit(2); }
const versionen = Object.fromEntries(fs.readFileSync('docs/k10-rest/versionen.txt', 'utf8').trim().split('\n')
  .map((z) => z.split(' ').reverse()));
const name = `substrat_k10_${kurz}`;
const version = versionen[name];
const aufgaben = versionen[`aufgaben_k10_${kurz}`];
const q = (s) => (s == null ? 'null' : `'${String(s).replace(/'/g, "''")}'`);
const umbruch = (text, einzug = '-- ') => {
  const worte = text.split(/\s+/); const zeilen = []; let z = '';
  for (const w of worte) { if ((z + ' ' + w).trim().length > 92) { zeilen.push(z.trim()); z = w; } else z += ' ' + w; }
  if (z.trim()) zeilen.push(z.trim());
  return zeilen.map((l) => einzug + l).join('\n');
};

const knoten = thema.knoten;
const kanten = knoten.flatMap((k) => k.kanten.map(([v, grund]) => ({ s: k.key, v, grund })));
const slugs = plan.fehlbilder_neu.filter((f) => f.themen.includes(kurz));
const themaKeys = [thema.thema_key].flat();
const intern = new Set(plan.themen.flatMap((t) => t.knoten.map((k) => k.key)));
const vorher = [...new Set(kanten.filter((k) => intern.has(k.v) && !knoten.some((x) => x.key === k.v))
  .map((k) => plan.themen.find((t) => t.knoten.some((x) => x.key === k.v)).kurz))];

const sql = `-- K10-Rest, Thema ${kurz} — Substrat: ${knoten.length} Knoten, ${kanten.length} Kanten, ${slugs.length} neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k10-rest-substrat.mjs aus docs/k10-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, ${thema.klp}.
-- klasse_herkunft = 10: Stoffjahrgang der Zweiten Stufe, in dem das Thema ${themaKeys.map((k) => `themen.${k}`).join(' / ')}
-- an Koelner Gymnasien ueberwiegend unterrichtet wird (Schulplaene: docs/themen/schulplaene.csv); der Katalog
-- fuehrt das Thema unter klasse 9 (Zweite Stufe 9/10). Eine Bindung an ein Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev${vorher.length ? ` und nach ${vorher.map((k) => `substrat_k10_${k}`).join(', ')}` : ''}
-- (Knoten der Kanten muessen stehen); vor ${aufgaben ?? '<Version>'}_aufgaben_k10_${kurz}.sql.
-- Alle Voraussetzungen ausserhalb dieses Laufs stehen in origin/dev UND in Prod (K8-Rest und K9-Rest
-- sind seit #193/#194 eingespielt). Deshalb keine eigene kanten_k10_k9.sql (docs/k10-rest/entscheidungen.md).
--
-- Kein begin/commit: \`mig\` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k10-rest/phase1.md, Teil 1b):
${knoten.map((k) => `--   ${k.key.padEnd(34)} ${k.tiefe}  ueber ${k.kanten.map(([v]) => v).join(', ')}`).join('\n')}

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
${knoten.map((k) => `  (${q(k.key)}, ${q(k.label)}, 'mathematik', 10, ${k.tiefe})`).join(',\n')}
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k10-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
${kanten.map((k, i) => `${umbruch(k.grund, '  -- ')}\n  (${q(k.s)}, ${q(k.v)})${i < kanten.length - 1 ? ',' : ''}`).join('\n')}
on conflict do nothing;
${slugs.length ? `

-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k10-rest/phase1.md (Teil 1d), gegen den Bestand (98 Slugs) und
-- gegen docs/k8-rest/phase1.md geprueft: keiner der Slugs hat dort eine gleichbedeutende
-- Entsprechung. Ein Slug, den mehrere Themen brauchen, steht in jedem dieser Substrate mit
-- wortgleichem Text; on conflict do nothing haelt das idempotent. freigegeben_am bleibt NULL
-- (Entwurf, wird nirgends ausgeliefert, bis Lena abnimmt). Familie nur aus den fuenf
-- vorhandenen, sonst NULL (Muster Kreis).

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
${slugs.map((f, i) => `  (${q(f.slug)}, ${q(f.familie)},\n   ${q(f.klartext)},\n   ${q(f.erklaerung)})${i < slugs.length - 1 ? ',' : ''}`).join('\n\n')}
on conflict (slug) do nothing;
` : ''}`;
fs.writeFileSync(`supabase/migrations/${version}_${name}.sql`, sql);
console.log(`supabase/migrations/${version}_${name}.sql: ${knoten.length} Knoten, ${kanten.length} Kanten, ${slugs.length} Fehlbilder`);
