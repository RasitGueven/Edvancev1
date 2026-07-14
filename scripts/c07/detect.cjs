/**
 * C07 — maschinelle Defekt-Detektoren fuer die MULTI_PART-Sichtung.
 *
 * Reine Erkennung, keine Reparatur: jede Funktion beantwortet genau eine Frage
 * ueber ein Item und markiert einen Verdacht. Geraten wird nichts.
 */

/* ------------------------------------------------------------------ *
 * Textnormalisierung
 * ------------------------------------------------------------------ */

/**
 * Bindestrich/Apostroph werden zu Leerzeichen, nicht geloescht — sonst verklebt
 * "Baden-Württemberg" zu einem Token, das jede Statistik fuer Zerfall haelt.
 */
const SEP = /[-–—'’‘ʼ`´/]+/g;
const norm = (s) =>
  (s || '')
    .toLowerCase()
    .replace(SEP, ' ')
    .replace(/[^a-zäöüß ]+/g, ' ');

const wc = (s) => (s || '').trim().split(/\s+/).filter(Boolean).length;

const trunc = (s, n) => {
  const one = (s || '').replace(/\s+/g, ' ').trim();
  return one.length > n ? `${one.slice(0, n - 1)}…` : one;
};

/* ------------------------------------------------------------------ *
 * Zerfallener Text
 * ------------------------------------------------------------------ */

/**
 * Sprachmodell ueber den Gesamtbestand — die Defekte sind darin Minderheit.
 * Liefert einen Trigramm-Score und, datengetrieben statt handgepflegt, die
 * Menge der Auslaute, die im Korpus wirklich als Wortende vorkommen.
 */
function buildLanguageModel(texts) {
  const tri = Object.create(null);
  const bi = Object.create(null);
  const endings = Object.create(null);
  for (const t of texts) {
    for (const w of norm(t).split(/\s+/)) {
      if (w.length < 2) continue;
      if (w.length <= 20) {
        const e = w.slice(-2);
        endings[e] = (endings[e] || 0) + 1;
      }
      const p = `^${w}$`;
      for (let i = 0; i + 2 < p.length; i++) {
        const a = p.slice(i, i + 3);
        const b = p.slice(i, i + 2);
        tri[a] = (tri[a] || 0) + 1;
        bi[b] = (bi[b] || 0) + 1;
      }
    }
  }
  const score = (w) => {
    const p = `^${w}$`;
    let s = 0;
    let n = 0;
    for (let i = 0; i + 2 < p.length; i++) {
      s += Math.log((tri[p.slice(i, i + 3)] || 0) + 0.1) - Math.log((bi[p.slice(i, i + 2)] || 0) + 2);
      n++;
    }
    return n ? s / n : 0;
  };
  // Ein Auslaut gilt als legal, wenn er im Bestand oft genug vorkommt.
  const endOk = (w) => (endings[w.slice(-2)] || 0) >= 15;
  return { score, endOk };
}

/** Verdoppelte Zeichen ("bbrraauunn") — Artefakt der Spalten-Extraktion. */
function isDoubled(w) {
  if (w.length < 6) return false;
  let pairs = 0;
  let hits = 0;
  for (let i = 0; i + 1 < w.length; i += 2) {
    pairs++;
    if (w[i] === w[i + 1]) hits++;
  }
  return pairs >= 3 && hits / pairs >= 0.6;
}

/**
 * Morphologie-Gate: echte Woerter — auch Eigennamen und Fremdwoerter — laufen
 * legal aus und haben keine absurden Buchstaben-Laeufe. Genau das trennt
 * "Sarajevo"/"korrekt" (statistisch selten, aber echt) von "irneecnh" (Zerfall).
 */
function violatesMorphology(w, endOk) {
  const runC = /[^aeiouäöü]{5,}/.test(w); // 5+ Konsonanten am Stueck
  const runV = /[aeiouäöü]{4,}/.test(w); // 4+ Vokale am Stueck
  const badEnd = /[^aeiouäöü]{2}$/.test(w) && !endOk(w);
  return runC || runV || badEnd;
}

/**
 * Zerfalls-Detektor. Ein Token gilt als zerschossen, wenn es
 * (a) das Verdopplungs-Muster zeigt ("bbrraauunn"),
 * (b) eine verklebte Satzkette ohne Wortgrenzen ist, oder
 * (c) trigramm-unwahrscheinlich ist UND die deutsche Morphologie verletzt.
 */
function scrambledTokens(rawText, score, endOk) {
  const out = [];
  const seen = new Set();
  for (const w of norm(rawText).split(/\s+/)) {
    if (w.length < 6 || seen.has(w)) continue;
    seen.add(w);
    if (isDoubled(w)) out.push(w);
    else if (w.length >= 25) out.push(w); // fehlende Wortgrenzen
    else if (score(w) < -2.8 && violatesMorphology(w, endOk)) out.push(w);
  }
  // Innen liegende Grossbuchstaben ("EDirne") — nur im Rohtext sichtbar.
  // Erst an Bindestrich/Apostroph trennen, sonst gilt "Baden-Württemberg" oder
  // "DVD-Player" als Zerfall, obwohl es nur ein Kompositum ist.
  for (const raw of (rawText || '').split(/\s+/)) {
    for (const sub of raw.split(new RegExp(SEP.source))) {
      const t = sub.replace(/[^A-Za-zÄÖÜäöüß]/g, '');
      if (t.length < 6 || seen.has(t.toLowerCase())) continue;
      if (/^[A-ZÄÖÜ]?[a-zäöüß]{2,}[A-ZÄÖÜ]/.test(t)) {
        out.push(t.toLowerCase());
        seen.add(t.toLowerCase());
      }
    }
  }
  return out;
}

/**
 * Zerfallene Brueche: ein Bruch-Tableau kippt bei der Extraktion in zwei
 * aufeinanderfolgende Zahlenzeilen — Zaehler ueber Nenner:
 *   "1 | 3 | 1 | 1 | 1"  /  "3 | 25 | 25 | 300 | 7500"   (= 1/3, 3/25, 1/25, …)
 * Nur gleich lange, rein numerische Zeilenpaare zaehlen. Einzelne Zahlenzeilen
 * sind dagegen voellig normal (MC-Optionen, Achsenbeschriftungen) und kein Defekt.
 */
function bruchZerfall(text) {
  const lines = (text || '').split('\n').map((l) => l.trim());
  const cellsOf = (l) => {
    const c = l.split('|').map((x) => x.trim()).filter(Boolean);
    return c.length >= 2 && c.every((x) => /^\d+(?:[.,]\d+)?$/.test(x)) ? c : null;
  };
  for (let i = 0; i + 1 < lines.length; i++) {
    const a = cellsOf(lines[i]);
    const b = cellsOf(lines[i + 1]);
    if (a && b && a.length === b.length) return `${lines[i]}  /  ${lines[i + 1]}`;
  }
  return null;
}

/* ------------------------------------------------------------------ *
 * Auto-Gradebarkeit / Loesungs-Qualitaet
 * ------------------------------------------------------------------ */

const RE_HANDARBEIT =
  /\b(zeichne|zeichnen|zeichnet|einzeichn|eingezeichnet|konstruier|skizzier|skizze|geodreieck|zirkel|miss |messe |messen|abmessen|trage .{0,20}ein|markier|schraffier|faerbe|färbe|male|verbinde .{0,20}linie)/i;
const RE_BEGRUENDUNG =
  /\b(begründ|begruend|erkläre|erklaere|erläuter|erlaeuter|beschreibe|argumentier|nenne .{0,20}grund|warum|wieso|weshalb|urteile|bewerte|diskutier)/i;
const RE_PROSA_LOESUNG =
  /\b(ist eingezeichnet|wird notiert|wird eingetragen|individuelle|beliebige|eigene lösung|schülerlösung|schuelerloesung|sinngemäß|sinngemaess|z\. ?b\.|beispielhaft|mögliche antwort|moegliche antwort|korrekte reihenfolge|richtig gezeichnet)/i;
const RE_INTERVALL =
  /(intervall|\[\s*\d+[.,]?\d*\s*[;:]\s*\d+[.,]?\d*\s*\]|zwischen\s+\d+.{0,12}und\s+\d+|\d+\s*(bis|-|–)\s*\d+\s*(cm|m|km|g|kg|€|%|grad)?)/i;

/**
 * Platzhalter-Loesung statt Wert: "Richtiger Term", "Korrekte Reihenfolge".
 * Kein einziger Ziffernwert + ein Bewertungsadjektiv = die Auswertung beschreibt
 * die Loesung, statt sie anzugeben. Nicht auto-gradebar.
 */
const RE_PLATZHALTER = /\b(richtig|korrekt|passend|geeignet|entsprechend|beliebig|plausibel|angemessen|sinnvoll)\w*\b/i;
const isPlatzhalter = (s) => !!s && !/\d/.test(s) && RE_PLATZHALTER.test(s);

/** Zwei Werte in einer Antwort ("2015 UND 2016") — eine Mehrfachbedingung. */
const RE_MEHRFACH = /\s(UND|ODER)\s/;

const UNIT_RE = /(\d+(?:[.,]\d+)?)\s*(mm|cm|dm|m|km|mg|g|kg|t|ml|cl|l|s|min|h|€|ct|%)\b/gi;

/** Mehrere Varianten derselben Zahl in verschiedenen Einheiten (16 / 160 dm / 1600 cm). */
function hasUnitVariants(answers) {
  const vals = [];
  for (const a of answers) {
    let m;
    const re = new RegExp(UNIT_RE.source, 'gi');
    while ((m = re.exec(a)) !== null) {
      const num = parseFloat(m[1].replace(',', '.'));
      if (Number.isFinite(num) && num !== 0) vals.push({ num, unit: m[2].toLowerCase() });
    }
  }
  for (let i = 0; i < vals.length; i++) {
    for (let j = i + 1; j < vals.length; j++) {
      if (vals[i].unit === vals[j].unit) continue;
      const r = Math.max(vals[i].num, vals[j].num) / Math.min(vals[i].num, vals[j].num);
      const log = Math.log10(r);
      // gleiche Zahl, andere Einheit — Faktor 10^k (k=0..4)
      if (Math.abs(log - Math.round(log)) < 1e-6 && Math.round(log) <= 4) return true;
    }
  }
  return false;
}

/** Grobe Klassifikation der Antwortform — dient nur der Sichtung, nicht dem Import. */
function kindOf(prompt, loesung) {
  const p = prompt || '';
  const l = loesung || '';
  if (RE_HANDARBEIT.test(p) || RE_HANDARBEIT.test(l)) return 'ZEICHNEN';
  if (RE_BEGRUENDUNG.test(p)) return 'BEGRUENDUNG';
  if (/kreuze|ankreuzen|\bja\s*\|\s*nein\b|zutreffend/i.test(p)) return 'MC';
  if (l && /^[^a-zA-Z]*\d+(?:[.,]\d+)?\s*(mm|cm|dm|m|km|mg|g|kg|t|ml|l|s|min|h|€|%)?[^a-zA-Z]*$/.test(l.trim()))
    return 'ZAHL';
  if (/zuordn|ordne .{0,20}zu/i.test(p)) return 'ZUORDNUNG';
  if (l && wc(l) <= 3) return 'KURZTEXT';
  if (l) return 'FREITEXT';
  return 'UNKLAR';
}

/* ------------------------------------------------------------------ *
 * Bild-Abhaengigkeit
 * ------------------------------------------------------------------ */

const RE_BILDVERWEIS =
  /\b(abbildung|abb\.|grafik|diagramm|schaubild|zeichnung|nebenstehend|abgebildet|siehe bild|im bild|folgendes bild|dargestellt|figur|skizze|maßstabsgerecht|massstabsgerecht|koordinatensystem|umrandet|schraffiert|netz eines|abgebildeten)/i;

/**
 * Degenerierter Stamm: was als Stamm uebrig bleibt, sind nur noch Bruchstuecke
 * einer Grafik ("1cm 1cm", "C g a b b B a | c A"). Die eigentliche Aufgabe
 * steckte in einer EMF-Zeichnung, die die Pipeline zu Text zerlegt hat.
 */
function istDegenerierterStamm(stamm) {
  const toks = (stamm || '').split(/\s+/).filter(Boolean);
  if (!toks.length) return false;
  if (toks.length > 14) return false;
  const kurz = toks.filter((t) => t.replace(/[^A-Za-zÄÖÜäöüß]/g, '').length <= 2).length;
  return kurz / toks.length >= 0.4;
}

/**
 * Tabelle/Liste wird erwaehnt, enthaelt aber keine Datenzellen. Uhrzeiten und
 * Datumsangaben zaehlen nicht als Daten — sonst gilt die leere Terminliste der
 * "Sprechstunde" faelschlich als befuellt.
 */
function istLeereTabelle(text) {
  if (!/\b(tabelle|liste|übersicht|uebersicht)\b/i.test(text || '')) return false;
  const ohneZeit = (text || '')
    .replace(/\d{1,2}[.:]\d{2}\s*(uhr)?/gi, ' ')
    .replace(/\d{1,2}\.\d{1,2}\.\d{2,4}/g, ' ');
  const zellen = ohneZeit.match(/\d+([.,]\d+)?/g) || [];
  return zellen.length < 3;
}

module.exports = {
  buildLanguageModel,
  scrambledTokens,
  bruchZerfall,
  istDegenerierterStamm,
  istLeereTabelle,
  hasUnitVariants,
  kindOf,
  isPlatzhalter,
  RE_PROSA_LOESUNG,
  RE_INTERVALL,
  RE_MEHRFACH,
  RE_BILDVERWEIS,
  wc,
  trunc,
};
