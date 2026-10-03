/**
 * k10-rest-lib.mjs — gemeinsamer Baukasten fuer die Chargen des Laufs "Klasse 10" (Exponential-
 * funktionen, Trigonometrie, Sinusfunktion; tools/k10-<thema>-charge.mjs). Abgeleitet aus
 * tools/k9-rest-lib.mjs, erweitert um Winkel- und Exponentialfunktionen. Erzeugt das Charge-Format
 * von vorlauf-build.mjs.
 *
 * Grundsatz wie beim Kreis: Die Bewertung ist ein EXAKTER Textvergleich (lsa_is_correct,
 * lsa_fehlbild_match). Darum rechnet die Bibliothek jeden Wert exakt nach (Brueche, Wurzeln auf
 * 40 Stellen, π auf 35 Stellen), rundet selbst und legt jede gleichwertige Schreibweise ab:
 * Komma/Punkt, ohne Endnull, Minus als - / − (U+2212) / "- ", Plus-Vorzeichen, Bruch/Dezimal.
 * Ein falscher Wert, der zugleich richtig ist, oder ein Wert mit zwei Slugs bricht ab, ebenso ein
 * ungerundeter Wert an einer Rundungsgrenze.
 *
 * Ausdruecke: Syntax von prefill-rechnen.mjs (+ - * / ^, Klammern), dazu
 *   P      Kreiszahl π (bei pi: true zwei Rechenwege: π-Taste und 3,14)
 *   W(x)   Quadratwurzel von x (exakt, wenn x ein Quadrat ist, sonst 40 Stellen)
 *   S(x) C(x) T(x)        sin, cos, tan von x im GRADMASS (40 Stellen)
 *   SR(x) CR(x) TR(x)     sin, cos, tan von x im BOGENMASS (fuer den Fehler "falscher Modus")
 *   AS(x) AC(x) AT(x)     sin⁻¹, cos⁻¹, tan⁻¹ von x, Ergebnis in GRAD
 *   L(x)                  natuerlicher Logarithmus (log c : log b ist von der Basis unabhaengig)
 *   H(b;x)                bˣ fuer beliebige (auch nicht ganzzahlige) Hochzahl x
 * Die Funktionswerte rechnet decimal.js (Abhaengigkeit von jsdom, nur fuer dieses lokale Werkzeug)
 * auf 60 Stellen und setzt sie als Bruch mit 40 Nachkommastellen ein; prefill-rechnen (und damit
 * verify-prefill) sieht nur noch dieses Literal.
 * Rundung je Wert (n):  Zahl = Nachkommastellen · 'exakt' · 'auf' / 'ab' = ganzzahlig auf/ab.
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import Decimal from 'decimal.js';
import { zahl, Q } from './prefill-rechnen.mjs';

Decimal.set({ precision: 60, rounding: Decimal.ROUND_HALF_UP });
const DPI = Decimal.acos(-1);

export const PI = '3.14159265358979323846264338327950288';
export const CLUSTER = {
  zahl: 'e7108c9a-d19e-4021-8499-55b4f3d5d70c', // Zahl & Rechnen
  algebra: 'edbb548a-54d9-4a8f-8be4-3052f9025524', // Algebra & Funktionen
  geo: '3156b22e-ad3b-46c8-8c76-4155176cc52a', // Geometrie & Messen
  daten: '9fdfed01-ebda-4c79-89ea-5accacefee93', // Daten & Zufall
};
export const ZEIT = { I: 45, II: 60, III: 90 };
export const SACH = 30;
export const SATZ_PI = 'Rechne mit der π-Taste oder mit π ≈ 3,14.';

// ── Wurzel und Ausdruecke ──────────────────────────────────────────────────────
function isqrt(n) {
  if (n < 0n) throw new Error('Wurzel aus negativer Zahl');
  if (n < 2n) return n;
  let x = 1n << BigInt(Math.ceil(n.toString(2).length / 2) + 1); // sicher oberhalb der Wurzel
  for (;;) { const y = (x + n / x) / 2n; if (y >= x) break; x = y; }
  while (x * x > n) x -= 1n;
  while ((x + 1n) * (x + 1n) <= n) x += 1n;
  return x;
}
function wurzelLiteral(q) {
  if (q.n < 0n) throw new Error(`Wurzel aus negativer Zahl ${q}`);
  const rn = isqrt(q.n), rd = isqrt(q.d);
  if (rn * rn === q.n && rd * rd === q.d) return rd === 1n ? `(${rn})` : `(${rn}/${rd})`;
  const s = isqrt(q.n * q.d * 10n ** 80n); // sqrt(n/d) = sqrt(n·d)/d, auf 40 Stellen abgeschnitten
  return `(${s}/${q.d * 10n ** 40n})`;
}
function dez(q) { return new Decimal(q.n.toString()).div(q.d.toString()); }
function literal(d) {
  const n = BigInt(d.mul(new Decimal(10).pow(40)).toDecimalPlaces(0, Decimal.ROUND_HALF_UP).toFixed(0));
  const g = new Q(n, 10n ** 40n);
  return g.n < 0n ? `(0-${-g.n}/${g.d})` : `(${g.n}/${g.d})`;
}
const GRAD = (d) => d.mul(DPI).div(180);
const INGRAD = (d) => d.mul(180).div(DPI);
/** Wertet eine Funktion mit exaktem Argument aus und liefert ein Literal. */
function funktion(name, arg) {
  if (name === 'W') return wurzelLiteral(zahl(arg));
  if (name === 'H') {
    const teile = arg.split(';');
    if (teile.length !== 2) throw new Error(`H(b;x) braucht zwei Argumente: ${arg}`);
    const b = zahl(teile[0]), x = zahl(teile[1]);
    if (x.d === 1n && x.n >= 0n) return `((${b.n}/${b.d})^${x.n})`; // ganzzahlig: exakt
    return literal(dez(b).pow(dez(x)));
  }
  const x = dez(zahl(arg));
  const f = {
    S: () => Decimal.sin(GRAD(x)), C: () => Decimal.cos(GRAD(x)), T: () => Decimal.tan(GRAD(x)),
    SR: () => Decimal.sin(x), CR: () => Decimal.cos(x), TR: () => Decimal.tan(x),
    AS: () => INGRAD(Decimal.asin(x)), AC: () => INGRAD(Decimal.acos(x)), AT: () => INGRAD(Decimal.atan(x)),
    L: () => { if (x.lte(0)) throw new Error(`L(${arg}): Logarithmus braucht ein positives Argument`); return Decimal.ln(x); },
  }[name];
  if (!f) throw new Error(`Funktion ${name} unbekannt`);
  if (['AS', 'AC'].includes(name) && x.abs().gt(1)) throw new Error(`${name}(${arg}): Argument ausserhalb [−1; 1]`);
  return literal(f());
}
const FN = /(AS|AC|AT|SR|CR|TR|S|C|T|W|L|H)\(/g;
/** Ersetzt P durch π des Rechenwegs und jede Funktion (innen zuerst) durch ein exaktes Literal. */
export function ausdruck(expr, p = PI) {
  // prefill-rechnen (und damit verify-prefill) kennt keine negativen Hochzahlen: 1/2^3 statt 2^-3.
  if (/\^\s*[-−(]/.test(expr)) throw new Error(`negative oder geklammerte Hochzahl in ${expr} — als 1/a^n oder H(b;x) schreiben`);
  let e = String(expr).replaceAll('P', `(${p})`);
  for (;;) {
    let treffer = null;
    for (const m of e.matchAll(FN)) treffer = m; // letzte Funktion = innerste ohne weitere Funktion rechts
    if (!treffer) break;
    const i = treffer.index, start = i + treffer[1].length;
    let tiefe = 0, j = start;
    for (; j < e.length; j++) { if (e[j] === '(') tiefe++; else if (e[j] === ')' && --tiefe === 0) break; }
    if (j >= e.length) throw new Error(`${treffer[1]}( ohne Klammerende in ${expr}`);
    e = e.slice(0, i) + funktion(treffer[1], e.slice(start + 1, j)) + e.slice(j + 1);
  }
  return e;
}

// ── Werte und Schreibweisen ─────────────────────────────────────────────────────
const zehn = (n) => 10n ** BigInt(n);
const ceil = (q) => (q.n % q.d === 0n ? q.n / q.d : q.n / q.d + (q.n > 0n ? 1n : 0n));
const floor = (q) => (q.n % q.d === 0n || q.n > 0n ? q.n / q.d : q.n / q.d - 1n);
function dezimalText(q, stellen) {
  const ganz = (q.n * zehn(stellen)) / q.d;
  const neg = ganz < 0n ? '-' : '';
  const s = String(ganz < 0n ? -ganz : ganz).padStart(stellen + 1, '0');
  return stellen ? `${neg}${s.slice(0, -stellen)},${s.slice(-stellen)}` : `${neg}${s}`;
}
/** Abbrechende Dezimaldarstellung eines Bruchs oder null. */
function abbrechend(q) {
  let d = q.d, k = 0;
  while (d % 2n === 0n) { d /= 2n; k++; }
  let m = 0;
  while (d % 5n === 0n) { d /= 5n; m++; }
  if (d !== 1n) return null;
  return dezimalText(q, Math.max(k, m));
}

/**
 * Wert eines Ausdrucks fuer einen Rechenweg.
 * Rueckgabe { haupt, exakt (Q), bruch (Text oder null), roh (Q) }.
 */
export function wert(expr, n, { p = PI, wo = expr, fehler = [], bruch = false } = {}) {
  const roh = zahl(ausdruck(expr, p));
  if (n === 'auf') return { haupt: String(ceil(roh)), roh, bruch: null };
  if (n === 'ab') return { haupt: String(floor(roh)), roh, bruch: null };
  if (n === 'exakt') {
    const dez = abbrechend(roh);
    const br = roh.d === 1n ? null : `${roh.n}/${roh.d}`;
    if (!dez && !(bruch && br)) fehler.push(`${wo}: ${expr} = ${roh} ist nicht abbrechend (Rundung angeben oder bruch: true)`);
    return { haupt: dez ?? br, roh, bruch: bruch ? br : null };
  }
  if (!Number.isInteger(n)) throw new Error(`${wo}: Rundung ${n} unbekannt`);
  const skal = roh.mul(new Q(zehn(n)));
  const rest = Number(((skal.n % skal.d) * 1000000n) / skal.d) / 1e6;
  if (Math.abs(Math.abs(rest) - 0.5) < 0.002) fehler.push(`${wo}: ${expr} liegt an einer Rundungsgrenze`);
  if (roh.round(n).n === 0n && !roh.istNull()) fehler.push(`${wo}: ${expr} rundet auf 0`);
  return { haupt: dezimalText(roh.round(n), n), roh, bruch: null };
}

/** Alle gleichwertigen Schreibweisen eines Wertes. */
export function formen(w, { einheit = null, plus = !einheit, bruch = null } = {}) {
  const basis = [w];
  if (/,\d*0$/.test(w)) basis.push(w.replace(/0+$/, '').replace(/,$/, ''));
  if (bruch && !basis.includes(bruch)) basis.push(bruch);
  const out = [];
  const zeichen = (b) => {
    const r = [b];
    if (b.includes(',')) r.push(b.replace(',', '.'));
    return r;
  };
  for (const b of basis) {
    for (const z of zeichen(b)) {
      out.push(z);
      if (z.startsWith('-')) out.push(`−${z.slice(1)}`, `- ${z.slice(1)}`);
      else if (plus && !/^0([.,]0*)?$/.test(z)) out.push(`+${z}`);
    }
  }
  if (einheit) for (const b of basis) if (!b.includes('/')) out.push(`${b} ${einheit}`, `${b}${einheit}`);
  return [...new Set(out)];
}

// ── Eine Antwort (Aufgabe oder Teil) ───────────────────────────────────────────
/**
 * a: { r, n, ke: [[slug, expr, fehlertext, frage, n?]], bruch?, einheit?, plus? } · wege: [['pi', PI]] oder zwei
 * Rueckgabe { correct, known, pruefung, haupt: {weg: haupt}, slugs, typical }
 */
function antwort(a, wege, wo, fehler, teil = null) {
  const opt = { einheit: a.einheit ?? null, plus: a.plus ?? !a.einheit };
  const richtig = {};
  const correct = [];
  const pruefung = [];
  for (const [k, p] of wege) {
    const w = wert(a.r, a.n, { p, wo, fehler, bruch: a.bruch });
    richtig[k] = w.haupt;
    correct.push(...formen(w.haupt, { ...opt, bruch: w.bruch }));
    pruefung.push(pruefEintrag(a.r, p, a.n, w, null, teil));
  }
  const corr = [...new Set(correct)];
  const known = {};
  const slugs = new Set();
  for (const [slug, expr, , , eigen] of a.ke ?? []) {
    slugs.add(slug);
    const n = eigen ?? a.n;
    for (const [k, p] of wege) {
      const w = wert(expr, n, { p, wo: `${wo} ${slug}`, fehler, bruch: a.bruch });
      pruefung.push(pruefEintrag(expr, p, n, w, `fehlbild:${slug}:${k}`, teil));
      for (const f of formen(w.haupt, { ...opt, bruch: w.bruch })) {
        if (corr.includes(f)) fehler.push(`${wo}: falscher Wert ${f} (${slug}) ist eine richtige Antwort`);
        if (known[f] && known[f] !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs (${known[f]}, ${slug})`);
        known[f] = slug;
      }
    }
  }
  const typical = (a.ke ?? []).map(([, , error, socratic_question]) => ({ error, socratic_question }));
  return { correct: corr, known, pruefung, richtig, slugs, typical };
}
/** Pruefeintrag fuer verify-prefill: die Rechnung muss EXAKT den Wert ergeben. */
function pruefEintrag(expr, p, n, w, rolle, teil) {
  const e = ausdruck(expr, p);
  const t = teil != null ? { teil: String(teil) } : {};
  const r = rolle ? { rolle } : {};
  if (typeof n === 'number') return { ...t, rechnung: `round(${e},${n})`, antwort: w.haupt.replace(',', '.'), ...r };
  if (n === 'exakt') return { ...t, rechnung: e, antwort: (w.bruch ?? w.haupt).replace(',', '.'), ...r };
  const vor = dezimalText(w.roh.round(4), 4).replace(',', '.');
  return { ...t, rechnung: `round(${e},4)`, antwort: vor, rolle: `${rolle ?? 'richtig'}:vor-${n}runden=${w.haupt}` };
}

// ── Charge ─────────────────────────────────────────────────────────────────────
/**
 * Aufgabe (Definition je Thema):
 *  { skill, ref, titel, afb, sach, afbGrund, frage, weg, inhalt, cluster, stoff, stoffGrund, clusterGrund,
 *    inhaltGrund, prozess?, prozessGrund?, pi?, einheit?, class_level?,
 *    // eine Antwort:   r, n, ke, bruch?, plus?
 *    // Teilaufgaben:   teile: [{ prompt, r, n, ke, afb, afbGrund?, bruch?, plus? }]
 *    figur?: { params, alt_text } }
 * weg: Loesungsweg; {A} = Ergebnis π-Taste bzw. einziges Ergebnis, {B} = Ergebnis mit 3,14,
 *      bei Teilaufgaben {1}, {2}, … = Ergebnis des Teils.
 */
export function baueCharge(def) {
  const { batch, source, idsPfad, aufgaben: A, kopf, auswahl, thema } = def;
  // Erlaubte Slugs: Bestand in Prod (docs/k10-rest/fehlbild-bestand.json, Abzug per dbread) und die
  // zentral geplanten neuen dieses Themas (graph.json). Ein neuer Slug muss in mindestens drei
  // Aufgaben des Themas stehen, das ihn als erstes einfuehrt (themen[0]).
  const plan = JSON.parse(fs.readFileSync('docs/k10-rest/graph.json', 'utf8'));
  const bestandSlugs = new Set(JSON.parse(fs.readFileSync('docs/k10-rest/fehlbild-bestand.json', 'utf8')));
  const planSlugs = new Set(plan.fehlbilder_neu.filter((f) => f.themen.includes(thema)).map((f) => f.slug));
  const neueSlugs = plan.fehlbilder_neu.filter((f) => f.themen[0] === thema).map((f) => f.slug);
  const knotenThema = new Set(plan.themen.find((t) => t.kurz === thema)?.knoten.map((k) => k.key) ?? []);
  if (!knotenThema.size) { console.error(`Thema ${thema} fehlt in graph.json`); process.exit(2); }
  const IDS = fs.existsSync(idsPfad) ? JSON.parse(fs.readFileSync(idsPfad, 'utf8')) : {};
  for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
  fs.writeFileSync(idsPfad, JSON.stringify(IDS, null, 1) + '\n');

  const fehler = [];
  const slugsVerwendet = new Map();
  const merke = (slugs, ref) => { for (const s of slugs) { if (!slugsVerwendet.has(s)) slugsVerwendet.set(s, new Set()); slugsVerwendet.get(s).add(ref); } };
  const refs = new Set();

  const aufgaben = A.map((a, i) => {
    const wo = a.ref;
    if (refs.has(a.ref)) fehler.push(`${wo}: source_ref doppelt`);
    refs.add(a.ref);
    for (const f of ['skill', 'ref', 'titel', 'afb', 'afbGrund', 'frage', 'weg', 'inhalt', 'cluster', 'stoff']) {
      if (a[f] == null || a[f] === '') fehler.push(`${wo}: Feld ${f} fehlt`);
    }
    if (!['I', 'II', 'III'].includes(a.afb)) fehler.push(`${wo}: afb ${a.afb}`);
    const wege = a.pi ? [['pi', PI], ['314', '3.14']] : [['', PI]];
    if (a.pi && !a.frage.includes('3,14')) fehler.push(`${wo}: π-Aufgabe nennt 3,14 nicht`);
    if (/\bhinweis\b|tipp:/i.test(a.frage)) fehler.push(`${wo}: Hinweis im Aufgabentext`);
    const mp = Array.isArray(a.teile);
    const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
    const prozess = a.prozess ?? (a.afb === 'III' ? 'Problemlösen, Operieren' : a.sach ? 'Modellieren, Operieren' : 'Operieren');
    const prozessGrund = a.prozessGrund ?? (a.afb === 'III' ? 'Lösungsweg selbst finden, dann rechnen.'
      : a.sach ? 'Sachsituation in eine Rechnung übersetzen, dann rechnen.' : 'Rechnen nach festem Verfahren.');
    const felder = {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: a.stoff, sicher: 'hoch', grund: a.stoffGrund },
      cluster_id: { wert: a.cluster, sicher: 'hoch', grund: a.clusterGrund },
      competency_content: { wert: a.inhalt, sicher: 'hoch', grund: a.inhaltGrund },
      competency_process: { wert: prozess, sicher: 'mittel', grund: prozessGrund },
      needs_image: a.figur
        ? { wert: true, sicher: 'hoch', grund: 'Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.' }
        : { wert: false, sicher: 'hoch', grund: 'Alle Angaben stehen im Text, keine Abbildung nötig.' },
    };
    const basis = { skill_key: a.skill, source_ref: a.ref, input_type: mp ? 'MULTI_PART' : 'NUMERIC', frage: a.frage };
    if (a.einheit && !mp) basis.unit = a.einheit;
    if (a.figur) {
      basis.figur = { params: a.figur.params, alt_text: a.figur.alt_text };
      if (/\d/.test(a.figur.alt_text)) fehler.push(`${wo}: alt_text mit Ziffer`);
    }
    let weg = a.weg;
    let loesung, teile, pruefung;
    let ke = {};
    if (!mp) {
      const r = antwort(a, wege, wo, fehler);
      merke(r.slugs, a.ref);
      basis.known_errors = r.known;
      weg = weg.replaceAll('{A}', r.richtig[wege[0][0]]).replaceAll('{B}', r.richtig[wege[1]?.[0]] ?? '');
      pruefung = r.pruefung;
      loesung = {
        correct_answers: { wert: r.correct, sicher: 'hoch', grund: `Exakt nachgerechnet${a.pi ? ' mit π-Taste und mit 3,14' : ''}; alle gleichwertigen Schreibweisen.` },
        solution: { wert: weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
        typical_errors: { wert: r.typical, sicher: 'hoch', grund: `Aus acceptance.known_errors (${[...r.slugs].join(', ') || 'keine'}).` },
      };
      ke = r.known;
    } else {
      basis.parts = a.teile.map((t, k) => ({ nr: k + 1, kind: 'short_input', prompt: t.prompt }));
      basis.known_errors = {};
      basis.zeit_teile = {};
      teile = {};
      pruefung = [];
      const typical = [];
      const slugsAlle = new Set();
      const anteil = Math.floor(zeit / a.teile.length);
      a.teile.forEach((t, k) => {
        const nr = k + 1;
        const r = antwort(t, wege, `${wo} Teil ${nr}`, fehler, nr);
        merke(r.slugs, a.ref);
        r.slugs.forEach((s) => slugsAlle.add(s));
        basis.known_errors[nr] = r.known;
        basis.zeit_teile[nr] = anteil + (k === 0 ? zeit - anteil * a.teile.length : 0);
        teile[nr] = {
          afb: { wert: t.afb ?? a.afb, sicher: 'mittel', grund: t.afbGrund ?? 'Wie die Aufgabe.' },
          competency_content: { wert: a.inhalt, sicher: 'hoch', grund: 'Wie die Aufgabe.' },
          antwort: { wert: r.correct, sicher: 'hoch', grund: 'Exakt nachgerechnet; alle gleichwertigen Schreibweisen.' },
        };
        pruefung.push(...r.pruefung);
        typical.push(...r.typical);
        weg = weg.replaceAll(`{${nr}}`, r.richtig[wege[0][0]]);
      });
      loesung = {
        solution: { wert: weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
        typical_errors: { wert: typical, sicher: 'hoch', grund: `Aus acceptance.known_errors (${[...slugsAlle].join(', ') || 'keine'}).` },
      };
    }
    if (/\{[AB1-9]\}/.test(weg)) fehler.push(`${wo}: Platzhalter im Lösungsweg nicht ersetzt`);
    // verify-prefill: der Loesungsweg nennt die erste Zahlenantwort je Teil woertlich.
    const pruefWeg = (ant, teil) => { const z = ant.find((s) => /^-?\d+(,\d+)?$/.test(s)); if (z && !weg.includes(z)) fehler.push(`${wo}${teil}: Lösungsweg nennt ${z} nicht`); };
    if (!mp) pruefWeg(loesung.correct_answers.wert, '');
    else for (const [nr, t] of Object.entries(teile)) pruefWeg(t.antwort.wert, ` Teil ${nr}`);
    if (/gemeistert|meisterst|mastered|beherrscht/i.test(JSON.stringify(a))) fehler.push(`${wo}: Mastery-Sprache`);
    void ke;
    const out = {
      nr: i + 1, id: IDS[a.ref], titel: a.titel, basis, felder,
      ...(teile ? { teile } : {}),
      loesung,
      leer: { hints: 'Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.' },
      pruefung,
    };
    if (a.class_level !== undefined) out.class_level = a.class_level;
    return out;
  });

  for (const s of neueSlugs) if ((slugsVerwendet.get(s)?.size ?? 0) < 3) fehler.push(`neues Fehlbild ${s} in weniger als drei Aufgaben`);
  for (const s of slugsVerwendet.keys()) if (!bestandSlugs.has(s) && !planSlugs.has(s)) fehler.push(`Slug ${s} weder im Bestand noch für dieses Thema geplant`);
  for (const a of A) if (!knotenThema.has(a.skill)) fehler.push(`${a.ref}: Knoten ${a.skill} gehört nicht zum Thema ${thema}`);
  for (const k of knotenThema) if (!A.some((a) => a.skill === k)) fehler.push(`Knoten ${k} ohne Aufgaben`);
  // sechs Aufgaben je Knoten (Auffuellung ausgenommen)
  const jeSkill = new Map();
  for (const a of A) jeSkill.set(a.skill, (jeSkill.get(a.skill) ?? 0) + 1);
  for (const [s, n] of jeSkill) if (!(def.auffuellung ?? []).includes(s) && n !== 6) fehler.push(`${s}: ${n} statt 6 Aufgaben`);
  if (fehler.length) { console.error('Charge abgelehnt:\n  ' + [...new Set(fehler)].join('\n  ')); process.exit(1); }

  const charge = {
    batch, kopf, auswahl, source,
    class_level: 10,
    acceptance_equivalents: true,
    ohne_transaktion: true,
    ...(def.auffuellung?.length ? { ohne_sondierrang: def.ohne_sondierrang ?? [] } : {}),
    zeitregel: { beschreibung: 'est_duration_sec wie Pilot/Vorlauf/Zins/Kreis: AFB I 45 s, II 60 s, III 90 s; +30 s bei Sachkontext.', basis: ZEIT, sachkontext_zuschlag: SACH },
    aufgaben,
  };
  fs.writeFileSync(`docs/prefill/${batch}.json`, JSON.stringify(charge, null, 1) + '\n');
  console.log(`docs/prefill/${batch}.json: ${aufgaben.length} Aufgaben`);
  for (const [s, r] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${r.size} Aufgaben${neueSlugs.includes(s) ? ' (neu)' : ''}`);
  return charge;
}
