/**
 * bewertung.mjs — JS-Gegenstueck zur Bewertung im Schuelerpfad, fuer den Abgleich
 * blind geloester Antworten (verify-tasks.mjs --answers-from).
 *
 * Zwei SQL-Wege, getreu nachgebildet:
 *   1. lsa_is_correct  (lsa_submit → lsa_responses.correct; MC, MULTI_PART, alles)
 *        Normalisieren (lsa_normalize_answer), dann Gleichheit mit einer Variante aus
 *        correct_answers. MC: Mengengleichheit der Options-IDs. TERM: lsa_normalize_term.
 *   2. lsa_grade       (nur adaptives Skill-Urteil, nur flache Nicht-MC-Items, nur mit
 *        acceptance.canonical): canonical + equivalents, Zahl gegen Zahl ueber
 *        lsa_values_equal mit tolerance {exact|absolute|decimals}.
 * Eine Antwort, die NUR ueber Weg 2 stimmt, gilt als richtig (lsa_grade = voll), wird
 * aber als `nurToleranz` gemeldet: lsa_responses.correct speichert fuer sie false.
 */

import { Q } from '../prefill-rechnen.mjs';

/** lsa_normalize_answer: btrim, Leerraum → ein Leerzeichen, ERSTES Komma → Punkt, lower. */
export const normalisiere = (s) => (s == null ? null
  : String(s).trim().replace(/\s+/g, ' ').replace(',', '.').toLowerCase());
/** lsa_normalize_term: zusaetzlich jeder Leerraum weg. */
export const normalisiereTerm = (s) => (s == null ? null : normalisiere(s).replace(/\s+/g, ''));

/** lsa_is_correct(input_type, correct_answers[], antwort). antwort: Text, bei MC IDs per , oder ;. */
export function istRichtig(inputType, akzeptiert, antwort) {
  if (!Array.isArray(akzeptiert) || !akzeptiert.length || antwort == null) return false;
  const term = inputType === 'TERM';
  const n = term ? normalisiereTerm : normalisiere;
  const erlaubt = akzeptiert.map((x) => n(String(x)));
  if (inputType === 'MC') {
    const gewaehlt = String(antwort).split(/[;,]/).map((x) => normalisiere(x)).filter(Boolean);
    return gewaehlt.length > 0 && erlaubt.every((a) => gewaehlt.includes(a)) && gewaehlt.every((g) => erlaubt.includes(g));
  }
  const g = n(String(antwort));
  return g !== '' && erlaubt.includes(g);
}

/** lsa_parse_fraction auf dem normalisierten Zahlteil: ganze Zahl, Dezimalzahl, Bruch. */
function alsBruch(s) {
  const t = normalisiere(s)?.replace(/\s+/g, '');
  if (!t) return null;
  const b = t.match(/^(-?\d+)\/(\d+)$/);
  try {
    if (b) return Number(b[2]) === 0 ? null : new Q(BigInt(b[1]), BigInt(b[2]));
    return /^-?\d+(\.\d+)?$/.test(t) ? Q.von(t) : null;
  } catch { return null; }
}

/** lsa_values_equal(a, b, tolerance). */
export function werteGleich(a, b, toleranz) {
  const x = alsBruch(a), y = alsBruch(b);
  if (!x || !y) return false;
  const modus = toleranz?.mode ?? 'exact';
  const wert = toleranz?.value;
  if (modus === 'exact' || wert == null) return x.eq(y);
  const zx = Number(x.n) / Number(x.d), zy = Number(y.n) / Number(y.d);
  if (modus === 'absolute') return Math.abs(zx - zy) <= Number(wert) + 1e-12;
  if (modus === 'decimals') {
    // round() wie Postgres numeric: halbe Stelle weg von 0 — exakt ueber Q.round.
    return x.round(Number(wert)).eq(y.round(Number(wert)));
  }
  return false;
}

/** lsa_grade (Kern, ohne Einheiten): stimmt die Antwort mit canonical/equivalents? */
export function stimmtUeberAcceptance(regel, antwort) {
  if (!regel || typeof regel !== 'object' || regel.canonical == null || antwort == null) return false;
  const kandidaten = [regel.canonical, ...(Array.isArray(regel.equivalents) ? regel.equivalents : [])];
  return kandidaten.some((k) => werteGleich(antwort, k, regel.tolerance)
    || normalisiere(antwort) === normalisiere(String(k)));
}

/**
 * Bewertet eine Aufgabe gegen die Blind-Antworten.
 *   task:     { input_type, teilArten?: { nr: 'mc'|'short_input' } }
 *   loesung:  { correct_answers, acceptance }
 *   antworten:[{ part, antwort, unsicher }] dieser Aufgabe
 * → { ok, nurToleranz, fehlt: [teil], falsch: [teil], unsicher, anzeige }
 */
export function bewerteAufgabe(task, loesung, antworten) {
  const ca = loesung?.correct_answers;
  const mp = ca && typeof ca === 'object' && !Array.isArray(ca);
  const teile = mp ? Object.keys(ca).sort((a, b) => Number(a) - Number(b)) : [null];
  const von = (t) => antworten.find((a) => String(a.part ?? '') === String(t ?? ''));
  const fehlt = [], falsch = [];
  let nurToleranz = false;
  for (const t of teile) {
    const a = von(t);
    if (!a || a.antwort == null || String(a.antwort).trim() === '') { fehlt.push(t); continue; }
    const art = mp ? (task.teilArten?.[t] === 'mc' ? 'MC' : 'SHORT_TEXT') : task.input_type;
    if (istRichtig(art, mp ? ca[t] : ca, a.antwort)) continue;
    // Weg 2 nur, wo lsa_grade ihn geht: flach, nicht MC, nicht TERM, mit canonical.
    if (!mp && !['MC', 'TERM'].includes(task.input_type) && stimmtUeberAcceptance(loesung?.acceptance, a.antwort)) {
      nurToleranz = true; continue;
    }
    falsch.push(t);
  }
  return {
    ok: !fehlt.length && !falsch.length,
    nurToleranz,
    fehlt,
    falsch,
    unsicher: antworten.some((a) => a.unsicher === 'ja'),
    anzeige: teile.map((t) => von(t)?.antwort ?? '—').join(';'),
  };
}
