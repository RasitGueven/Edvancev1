#!/usr/bin/env node
/**
 * k10-rest-graph-check.mjs — prueft docs/k10-rest/graph.json gegen einen Abzug des Bestands-Graphen.
 *
 *   dbread -tAc "select json_build_object('skills', …, 'kanten', …)" > bestand.json
 *   node tools/k10-rest-graph-check.mjs bestand.json
 *
 * Regeln (Tiefen-Guard + Muster Binom/Kreis): jede Kante echt flacher, Tiefe = 1 + tiefste direkte
 * Voraussetzung, Tiefe 1..12, Voraussetzungen existieren, keine transitiv redundante Kante,
 * keine Kante auf einen Knoten, der nicht in Prod/origin/dev oder in diesem Plan steht.
 */
import fs from 'node:fs';
const bestand = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const plan = JSON.parse(fs.readFileSync('docs/k10-rest/graph.json', 'utf8'));
const tiefe = new Map(bestand.skills.map((s) => [s.k, s.t]));
const kanten = new Map();
for (const [s, v] of bestand.kanten) { if (!kanten.has(s)) kanten.set(s, []); kanten.get(s).push(v); }
const fehler = [];
const neu = plan.themen.flatMap((t) => t.knoten);
for (const k of neu) { if (tiefe.has(k.key)) fehler.push(`${k.key} existiert schon`); tiefe.set(k.key, k.tiefe); kanten.set(k.key, k.kanten.map((e) => e[0])); }
const erreichbar = (von, ohne) => { // alle transitiv erreichbaren Knoten ueber Kanten von `von`, ohne die direkte Kante `ohne`
  const seen = new Set(); const stack = (kanten.get(von) ?? []).filter((v) => v !== ohne);
  while (stack.length) { const x = stack.pop(); if (seen.has(x)) continue; seen.add(x); stack.push(...(kanten.get(x) ?? [])); }
  return seen;
};
for (const k of neu) {
  if (k.tiefe < 1 || k.tiefe > 12) fehler.push(`${k.key}: Tiefe ${k.tiefe}`);
  let max = 0;
  for (const [v] of k.kanten) {
    if (!tiefe.has(v)) { fehler.push(`${k.key} -> ${v}: Knoten unbekannt`); continue; }
    if (tiefe.get(v) >= k.tiefe) fehler.push(`${k.key} (${k.tiefe}) -> ${v} (${tiefe.get(v)}): nicht echt flacher`);
    max = Math.max(max, tiefe.get(v));
    if (erreichbar(k.key, v).has(v)) fehler.push(`${k.key} -> ${v}: transitiv redundant`);
  }
  if (k.tiefe !== max + 1) fehler.push(`${k.key}: Tiefe ${k.tiefe}, erwartet ${max + 1}`);
}
const slugs = plan.fehlbilder_neu.map((f) => f.slug);
if (new Set(slugs).size !== slugs.length) fehler.push('Fehlbild doppelt');
console.log(`${neu.length} Knoten, ${neu.reduce((s, k) => s + k.kanten.length, 0)} Kanten, max. Tiefe ${Math.max(...neu.map((k) => k.tiefe))}, ${slugs.length} neue Fehlbilder`);
if (fehler.length) { console.error(fehler.join('\n')); process.exit(1); }
console.log('Graph ok');
