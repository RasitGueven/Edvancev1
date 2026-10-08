/**
 * erklaer-lib.mjs — gemeinsame Bausteine der Erklär-Werkzeuge (E2b):
 *   - Bilder über den Python-Generator scripts/figures (derselbe wie task_figures und
 *     upload_figures.py): SVG zeichnen und prüfen, Hash wie upload_figures.params_hash,
 *   - Markdown-Blöcke eines Schritts (Überschrift, Absatz, Merksatz, nummerierte Schritte),
 *   - Zahlen in Text und TeX, exakt als Q (prefill-rechnen).
 */

import { spawnSync } from 'node:child_process';
import { Q } from './prefill-rechnen.mjs';

/** Pfadregel aus E1 (erklaer_schritt_json): task-assets/erklaer/bilder/<svg_hash>.svg */
export const BILD_PFAD = 'erklaer/bilder';
/** Die App zeigt die Session auf dunklem Grund; es gibt nur eine Datei je Bild (offene-punkte-e1 12). */
export const BILD_THEME = 'dunkel';

// Ein Python-Aufruf für viele Bilder; params kommen per stdin.
const PY = `import sys, json, importlib
sys.path.insert(0, 'scripts')
auftraege = json.load(sys.stdin)
up = importlib.import_module('figures.upload_figures')
out = []
for a in auftraege:
    gen = importlib.import_module('figures.' + a['generator'])
    pr = importlib.import_module('figures.pruefe_' + a['generator'])
    e = {'hash': up.params_hash(a['generator'], a['params'])}
    if a.get('theme'):
        svg = gen.zeichne(a['params'], a['theme'])
        ok, meldung = pr.pruefe(svg, a['params'])
        e.update(svg=svg, ok=bool(ok), meldung=meldung)
    out.append(e)
json.dump(out, sys.stdout)`;

/**
 * Bilder [{generator, params}] → [{hash, svg?, ok?, meldung?}]. Mit theme wird gezeichnet und
 * geprüft (pruefe_<generator>.pruefe), sonst nur der Hash berechnet.
 */
export function bilderPython(bilder, theme = null) {
  if (!bilder.length) return [];
  const r = spawnSync('python3', ['-c', PY], {
    input: JSON.stringify(bilder.map((b) => ({ generator: b.generator, params: b.params, theme }))),
    encoding: 'utf8', maxBuffer: 64 * 1024 * 1024,
  });
  if (r.status !== 0) throw new Error(`Generator: ${r.stderr}`);
  return JSON.parse(r.stdout);
}

/**
 * Blöcke eines Schritts. Leerzeile trennt Blöcke; "# " Überschrift (nur als erster Block),
 * "> " Merksatz, Zeilen "1. …" nummerierte Schritte, sonst Absatz.
 */
export function bloecke(inhalt) {
  return String(inhalt).split(/\n\s*\n/).map((roh) => roh.trim()).filter(Boolean).map((b) => {
    if (b.startsWith('# ')) return { art: 'titel', text: b.slice(2).trim() };
    if (b.startsWith('> ')) return { art: 'merk', text: b.slice(2).trim() };
    const zeilen = b.split('\n');
    if (zeilen.every((z) => /^\d+\. /.test(z))) return { art: 'schritte', zeilen: zeilen.map((z) => z.replace(/^\d+\. /, '')) };
    return { art: 'absatz', text: b };
  });
}

/**
 * Markdown-Regel (E2b, der Player in E2a stellt genau diese Formen dar): "# " nur als erste
 * Zeile, "> " für Merksätze (eine Zeile), "1. " für nummerierte Schritte (1, 2, 3 …), Formeln in
 * $…$, sonst nur Absätze aus einer Zeile. Kein Fett, keine Aufzählungspunkte, keine anderen
 * Markdown-Zeichen. Liefert die Verstöße als Text.
 */
export function markdownFehler(inhalt) {
  const f = [];
  const roh = String(inhalt);
  if ((roh.match(/\$/g) ?? []).length % 2) f.push('ungerade Zahl von "$"');
  if (!roh.startsWith('# ')) f.push('erste Zeile ist keine Überschrift "# "');
  roh.split(/\n\s*\n/).map((b) => b.trim()).filter(Boolean).forEach((b, i) => {
    const zeilen = b.split('\n');
    if (zeilen.length > 1 && !zeilen.every((z) => /^\d+\. /.test(z))) f.push(`Block ${i + 1}: Zeilenumbruch nur in nummerierten Schritten`);
    if (zeilen.every((z) => /^\d+\. /.test(z))) {
      zeilen.forEach((z, j) => { if (!z.startsWith(`${j + 1}. `)) f.push(`Block ${i + 1}: Nummer ${z.split('.')[0]} statt ${j + 1}`); });
    }
    if (i > 0 && b.startsWith('#')) f.push(`Block ${i + 1}: "#" nur in der ersten Zeile`);
    for (const z of zeilen) {
      const text = z.replace(/^(# |> |\d+\. )/, '').replace(/\$[^$]*\$/g, 'F');
      const zeichen = text.match(/\*\*|__|[*_`#>~\\[\]<]|^\s*[-+•]\s/);
      if (zeichen) f.push(`Block ${i + 1}: Zeichen "${zeichen[0].trim()}" außerhalb einer Formel`);
    }
  });
  return f;
}

/** Formeln $…$ wie erklaer_formel_anzahl (SQL) und formeln-svg.mjs. */
export const formeln = (text) => [...String(text).matchAll(/\$([^$]+)\$/g)].map((m) => m[1]);

/**
 * Alle Zahlen eines Texts (auch in TeX) als Q. Ein Minus zählt zur Zahl, wenn davor keine
 * Ziffer und keine schließende Klammer steht ("5-(-1)" → 5, -1; "4-1" → 4, 1;
 * "$-3 - 3$" → -3, 3). Dezimalkomma und -punkt; Indizes wie y_B sind keine Zahlen.
 * Die Nummern nummerierter Schritte ("1. ") zählen nicht.
 */
export function zahlen(text) {
  const ohneNummern = String(text).replace(/^\d+\. /gm, '');
  return [...ohneNummern.matchAll(/(?<![\d)\]}])(-?)(\d+(?:[.,]\d+)?)(?![\d])/g)]
    .filter((m) => !/[A-Za-z_]$/.test(ohneNummern.slice(0, m.index)))
    .map((m) => Q.von(m[1] + m[2]));
}

/** Zahlwörter sind verboten: Jede Zahl steht als Ziffer da, damit das Skript sie nachrechnet. */
export const ZAHLWORT = /\b(null|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf|hundert|halb|halbe|halben|doppelt|doppelte|dreimal|zweimal|viermal)\b/i;

/** Punkte "A(1|-2)" bzw. "A(1 | -2)" im Text: [{label, x, y}] (x, y als Q). */
export function punkteImText(text) {
  return [...String(text).matchAll(/\b([A-Z])\((-?\d+(?:[.,]\d+)?)\s*\|\s*(-?\d+(?:[.,]\d+)?)\)/g)]
    .map((m) => ({ label: m[1], x: Q.von(m[2]), y: Q.von(m[3]) }));
}

/** Zahl aus JSON (z. B. 0.5) exakt als Q. */
export const qAus = (v) => Q.von(String(v));

/** Liegt (x|y) auf y = m·x + b? */
export const aufGerade = (f, x, y) => qAus(f.m).mul(x).add(qAus(f.b)).eq(y);

/** Der Text, den das Kind liest (ohne Markdown-Zeichen), für Längen- und Satzregeln. */
export const lesetext = (b) => (b.art === 'schritte' ? b.zeilen.join(' ') : b.text);
