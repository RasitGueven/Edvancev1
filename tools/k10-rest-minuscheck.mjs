#!/usr/bin/env node
/**
 * k10-rest-minuscheck.mjs — findet in den Pruefeintraegen einer Charge Ausdruecke, in denen ein
 * vorangestelltes Minus vor einer Potenz steht (`-(6/2)^2`). prefill-rechnen liest das als
 * (−3)² = +9, die Schulmathematik als −9. JavaScript lehnt `-a**b` als Syntaxfehler ab — genau
 * diese Stellen werden gemeldet. Aufruf: node tools/k10-rest-minuscheck.mjs docs/prefill/k10-*.json
 */
import fs from 'node:fs';
let treffer = 0;
for (const pfad of process.argv.slice(2)) {
  const c = JSON.parse(fs.readFileSync(pfad, 'utf8'));
  for (const a of c.aufgaben) for (const p of a.pruefung ?? []) {
    const js = p.rechnung.replace(/round\(/g, 'R(').replace(/\^/g, '**');
    try { new Function('R', `return ${js}`); } catch (e) {
      if (/\*\*|exponent/i.test(e.message) || /Unary/i.test(e.message)) { treffer++; console.log(`${pfad} ${a.basis.source_ref} ${p.rolle ?? 'richtig'}: ${p.rechnung.slice(0, 120)}`); }
      else console.log(`${pfad} ${a.basis.source_ref}: nicht pruefbar (${e.message})`);
    }
  }
}
console.log(treffer ? `${treffer} mehrdeutige Ausdruecke` : 'keine mehrdeutigen Ausdruecke');
process.exit(treffer ? 1 : 0);
