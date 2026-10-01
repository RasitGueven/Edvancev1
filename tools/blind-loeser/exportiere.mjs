#!/usr/bin/env node
/**
 * exportiere.mjs — Schritt 1 des Blind-Loeser-Ablaufs (siehe README.md).
 *
 *   node tools/blind-loeser/exportiere.mjs docs/prefill/<batch>.json <zielordner>
 *
 * Schreibt <zielordner>/aufgaben.json und je Aufgabe mit Figur ein PNG (oder SVG, wenn
 * ImageMagick fehlt). Das ist ALLES, was der Blind-Loeser sehen darf:
 *   - Aufgabentext, Teilprompts, Einheit,
 *   - die Abbildung, gerendert vom selben Generator wie in upload_figures (Theme 'hell').
 * NICHT exportiert: Loesungen, known_errors, Loesungsweg, Figur-PARAMETER (die tragen bei
 * Ablese-Aufgaben die Antwort), CSV, Migration. Ein Selbstcheck bricht ab, wenn ein
 * Loesungsschluessel in aufgaben.json landen wuerde.
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const [chargePfad, ziel] = process.argv.slice(2);
if (!chargePfad || !ziel) {
  console.error('Aufruf: exportiere.mjs <charge.json> <zielordner>');
  process.exit(2);
}
const charge = JSON.parse(fs.readFileSync(chargePfad, 'utf8'));
fs.mkdirSync(ziel, { recursive: true });
const hatConvert = spawnSync('convert', ['-version']).status === 0;

// Rendert eine Figur ueber den Python-Generator; params kommen per stdin, nie auf die Platte.
const PY = `import sys, json, importlib
sys.path.insert(0, 'scripts')
a = json.load(sys.stdin)
gen = importlib.import_module('figures.' + a['generator'])
sys.stdout.write(gen.zeichne(a['params'], 'hell'))`;

const aufgaben = charge.aufgaben.map((a) => {
  const b = a.basis ?? {};
  const eintrag = { task_id: a.id, frage: b.frage };
  if (b.unit) eintrag.einheit = b.unit;
  if (b.input_type === 'MULTI_PART') eintrag.teile = (b.parts ?? []).map((p) => ({ part: String(p.nr), prompt: p.prompt }));
  if (b.figur) {
    const r = spawnSync('python3', ['-c', PY], {
      input: JSON.stringify({ generator: b.figur.generator ?? 'koordinatensystem', params: b.figur.params }),
    });
    if (r.status !== 0) { console.error(`Figur ${a.id}: ${r.stderr}`); process.exit(1); }
    const name = `abbildung-${String(a.nr ?? a.id).padStart(2, '0')}`;
    const svg = path.join(ziel, `${name}.svg`);
    fs.writeFileSync(svg, r.stdout);
    if (hatConvert) {
      const png = path.join(ziel, `${name}.png`);
      spawnSync('convert', ['-background', 'white', '-density', '110', svg, png]);
      fs.rmSync(svg);
      eintrag.abbildung = path.resolve(png);
    } else {
      eintrag.abbildung = path.resolve(svg);
    }
  }
  return eintrag;
});

const text = JSON.stringify(aufgaben, null, 1);
const leck = text.match(/"(correct_answers|acceptance|known_errors|solution|loesung|antwort|params|wert)"/);
if (leck) { console.error(`Abbruch: Loesungsschluessel ${leck[1]} im Export`); process.exit(1); }
fs.writeFileSync(path.join(ziel, 'aufgaben.json'), text + '\n');
console.log(`${aufgaben.length} Aufgaben, ${aufgaben.filter((x) => x.abbildung).length} Abbildungen → ${ziel}`);
