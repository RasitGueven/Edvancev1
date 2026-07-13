#!/usr/bin/env node
/**
 * C07 — Sichtungsliste fuer die MULTI_PART-Items aus dem VERA8-Bestand.
 *
 * Reiner Analyse-Lauf: liest data/vera8_komplett_enriched.json, prueft jedes Item
 * (status='ready', task_type='MULTI_PART') maschinell auf Defekte und schreibt
 * data/c07_sichtung.md (zum Lesen) + data/c07_sichtung.json (zum Weiterverarbeiten).
 *
 * Kein Import, kein DB-Zugriff, keine Migration, keine Reparatur. status='ready'
 * heisst "Pipeline durchgelaufen", nicht "geprueft" — die Freigabe macht ein Mensch.
 *
 * Aufruf: node scripts/c07_sichtung.cjs [--debug]
 */
const fs = require('fs');
const path = require('path');

const D = require('./c07/detect.cjs');
const { makeLicenseInfo } = require('./c07/lizenz.cjs');
const { renderMarkdown, renderJson } = require('./c07/render.cjs');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'data/vera8_komplett_enriched.json');
const MANIFEST = path.join(ROOT, 'data/vera8_assets_manifest.json');
const OUT_MD = path.join(ROOT, 'data/c07_sichtung.md');
const OUT_JSON = path.join(ROOT, 'data/c07_sichtung.json');
const DEBUG = process.argv.includes('--debug');

const FLAGS = {
  STAMM: 'kein Stamm',
  TEXT: 'Text defekt',
  GRADE: 'nicht auto-gradebar',
  LOESUNG: 'Loesung unklar',
  EINHEIT: 'Einheiten',
  ASSET: 'Asset fehlt',
  RECHTE: 'Rechte unklar',
};

const all = JSON.parse(fs.readFileSync(SRC, 'utf8'));
const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
const { score, endOk } = D.buildLanguageModel(all.map((i) => i.aufgabe_text || ''));
const licenseInfo = makeLicenseInfo(manifest, ROOT);

const items = all.filter((i) => i.status === 'ready' && i.task_type === 'MULTI_PART');

const slugOf = (it) => {
  const url = it.iqb_urls && it.iqb_urls.aufgabe;
  if (!url) return null;
  const file = url.split('/').pop() || '';
  return file.split('_')[0].toLowerCase() || null;
};

const results = [];

for (const it of items) {
  const flags = [];
  const reasons = [];
  const add = (f, why) => {
    if (!flags.includes(f)) flags.push(f);
    reasons.push(`${f}: ${why}`);
  };

  const tas = it.teilaufgaben || [];
  const teile = it.aufgabe_teile || [];
  const probs = it._problems || [];

  /* --- 1. Stamm abtrennbar? --- */
  let stamm = '';
  let taTexts = [];
  if (teile.length > tas.length && tas.length > 0) {
    const k = teile.length - tas.length;
    stamm = teile.slice(0, k).join('\n\n').trim();
    taTexts = teile.slice(k);
  } else {
    taTexts = teile.slice(0, tas.length);
    add(
      FLAGS.STAMM,
      teile.length === tas.length
        ? `${teile.length} Textteile = ${tas.length} Teilaufgaben — kein gemeinsamer Stamm abtrennbar`
        : `${teile.length} Textteile < ${tas.length} Teilaufgaben — Struktur passt nicht`
    );
  }

  /* --- 2. Zerfallener Text --- */
  const scrambled = D.scrambledTokens(it.aufgabe_text || '', score, endOk);
  if (scrambled.length >= 2) {
    add(FLAGS.TEXT, `zerschossene Tokens: ${scrambled.slice(0, 5).join(', ')}${scrambled.length > 5 ? ' …' : ''}`);
  }
  const brueche = D.bruchZerfall(it.aufgabe_text || '');
  if (brueche) {
    add(FLAGS.TEXT, `Bruchdarstellung zerfallen (Zaehler-/Nennerzeile getrennt): "${D.trunc(brueche, 70)}"`);
  }

  /* --- Teilaufgaben aufbereiten --- */
  const lpt = it.loesung_pro_ta || [];
  const parts = tas.map((ta, idx) => {
    const sol = lpt.find((l) => l.nr === ta.nr) || lpt[idx] || {};
    const prompt = (taTexts[idx] || '').trim();
    const loesung = (sol.loesung || '').trim();
    const akz = (sol.akzeptierte_antworten && sol.akzeptierte_antworten.length
      ? sol.akzeptierte_antworten
      : idx === 0
        ? it.akzeptierte_antworten || []
        : []
    ).filter(Boolean);
    return {
      nr: ta.nr,
      kind: D.kindOf(prompt, loesung),
      prompt,
      loesung,
      akzeptierte_antworten: akz,
      afb: ta.afb ?? null,
      kompetenzen: ta.kompetenzen || [],
      kompetenzstufe: ta.kompetenzstufe ?? null,
    };
  });

  /* --- 3. Nicht auto-gradebar --- */
  const handTAs = parts.filter(
    (p) =>
      p.kind === 'ZEICHNEN' ||
      p.kind === 'BEGRUENDUNG' ||
      D.RE_PROSA_LOESUNG.test(p.loesung) ||
      D.isPlatzhalter(p.loesung) ||
      p.akzeptierte_antworten.some((a) => D.isPlatzhalter(a))
  );
  if (handTAs.length) {
    add(
      FLAGS.GRADE,
      `TA ${handTAs
        .map((p) => p.nr)
        .join(
          ','
        )}: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben`
    );
  }
  const probGrade = probs.filter((p) => /erfordert_begruendung|loesung_ist_freitext|antwort_ist_satz/.test(p));
  if (probGrade.length && !flags.includes(FLAGS.GRADE)) {
    add(FLAGS.GRADE, `Pipeline-Befund: ${probGrade.join(', ')}`);
  }

  /* --- 4. Loesung unklar / fehlend / falsch --- */
  const leer = parts.filter((p) => !p.loesung && !p.akzeptierte_antworten.length);
  if (leer.length) add(FLAGS.LOESUNG, `keine Loesung fuer TA ${leer.map((p) => p.nr).join(',')}`);
  if (lpt.length && lpt.length < tas.length) {
    add(FLAGS.LOESUNG, `nur ${lpt.length} Loesung(en) fuer ${tas.length} Teilaufgaben`);
  }
  const mehrdeutig = parts.filter(
    (p) =>
      D.RE_INTERVALL.test(p.loesung) ||
      p.akzeptierte_antworten.some((a) => D.RE_INTERVALL.test(a)) ||
      (p.loesung && D.wc(p.loesung) > 8 && p.kind !== 'MC')
  );
  if (mehrdeutig.length) {
    add(FLAGS.LOESUNG, `TA ${mehrdeutig.map((p) => p.nr).join(',')}: Intervall/Mehrfachbedingung/Prosa statt eines Werts`);
  }
  const mehrfach = parts.filter(
    (p) => D.RE_MEHRFACH.test(p.loesung) || p.akzeptierte_antworten.some((a) => D.RE_MEHRFACH.test(a))
  );
  if (mehrfach.length) {
    add(
      FLAGS.LOESUNG,
      `TA ${mehrfach.map((p) => p.nr).join(',')}: zwei Werte in einer Antwort ("${D.trunc(
        mehrfach[0].loesung || mehrfach[0].akzeptierte_antworten[0],
        40
      )}") — als eine Eingabe nicht auswertbar`
    );
  }
  // Flaeche mit Laengeneinheit ("15 cm" statt "15 cm²") — die Loesung ist schlicht falsch.
  for (const p of parts) {
    const fl = /fläche|flächeninhalt|oberfläche/i.test(p.prompt);
    const vol = /volumen|rauminhalt/i.test(p.prompt);
    if (fl && /\d\s*(mm|cm|dm|m|km)\b(?!²|\^2)/i.test(p.loesung)) {
      add(FLAGS.LOESUNG, `TA ${p.nr}: Flaeche mit Laengeneinheit ("${D.trunc(p.loesung, 20)}") — Einheit falsch`);
      break;
    }
    if (vol && /\d\s*(mm|cm|dm|m)(²)?\b(?!³|\^3)/i.test(p.loesung)) {
      add(FLAGS.LOESUNG, `TA ${p.nr}: Volumen ohne Volumeneinheit ("${D.trunc(p.loesung, 20)}") — Einheit falsch`);
      break;
    }
  }
  const probLoesung = probs.filter((p) =>
    /zelle_leer|ohne_konkrete_loesung|loesung_ist_intervall|nur_als_formelgrafik|nicht_zerlegbar|position_uneindeutig/.test(
      p
    )
  );
  if (probLoesung.length && !flags.includes(FLAGS.LOESUNG)) {
    add(FLAGS.LOESUNG, `Pipeline-Befund: ${probLoesung.join(', ')}`);
  }

  /* --- 5. Einheiten-Varianten (P01: keine Umrechnung) --- */
  for (const p of parts) {
    const pool = [p.loesung, ...p.akzeptierte_antworten].filter(Boolean);
    if (D.hasUnitVariants(pool)) {
      add(FLAGS.EINHEIT, `TA ${p.nr}: dieselbe Zahl in mehreren Einheiten — P01 rechnet nicht um`);
      break;
    }
  }

  /* --- 6. Bild / Rechte --- */
  const slug = slugOf(it);
  const lic = slug ? licenseInfo(slug) : { hasNote: false, coversGrafik: false, graphics: [] };
  const degenStamm = D.istDegenerierterStamm(stamm);
  const leereTab = D.istLeereTabelle(it.aufgabe_text || '');
  const bildVerweis = D.RE_BILDVERWEIS.test(it.aufgabe_text || '');
  const brauchtBild = it.benoetigt_bild === 'true' || bildVerweis || degenStamm || leereTab;
  const hatAsset = lic.graphics.length > 0 || (it.bild_pfade && it.bild_pfade.length > 0);
  if (brauchtBild && !hatAsset) {
    const warum = degenStamm
      ? 'der Stamm besteht nur noch aus Grafik-Bruchstuecken — die Aufgabe steckte in einer EMF-Zeichnung, die zu Text zerlegt wurde'
      : leereTab
        ? 'Text nennt eine Tabelle/Liste, die keine Datenzellen enthaelt — die Werte sind bei der Extraktion verloren gegangen'
        : 'Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)';
    add(FLAGS.ASSET, warum);
  }
  if (hatAsset && !lic.coversGrafik) {
    add(
      FLAGS.RECHTE,
      lic.hasNote
        ? 'eingebetteter Lizenzhinweis nennt nur Text/Teilaufgaben, nicht "Grafik" — Grafik nicht gedeckt (C04)'
        : 'kein eingebetteter Lizenzhinweis gefunden — Rechtelage der Grafik ungeklaert (C04)'
    );
  }
  if (probs.includes('grafik_als_emf_nicht_renderbar')) {
    add(FLAGS.ASSET, 'Pipeline-Befund: grafik_als_emf_nicht_renderbar');
  }

  /* --- Vorschlag: Empfehlung, keine Entscheidung --- */
  let vorschlag;
  let vBegruendung;
  if (!flags.length) {
    vorschlag = 'rein';
    vBegruendung = 'Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.';
  } else if (flags.includes(FLAGS.TEXT) || flags.includes(FLAGS.GRADE) || flags.includes(FLAGS.STAMM)) {
    vorschlag = 'raus';
    vBegruendung = flags.includes(FLAGS.TEXT)
      ? 'Quelltext ist zerfallen — nicht rekonstruierbar ohne Rueckgriff auf das Original.'
      : flags.includes(FLAGS.GRADE)
        ? 'Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.'
        : 'Kein gemeinsamer Stamm abtrennbar — passt nicht auf den MULTI_PART-Vertrag.';
  } else {
    vorschlag = 'fixen';
    vBegruendung = `Inhaltlich brauchbar, aber ${flags.join(' + ')} muss vor dem Import haendisch geklaert werden.`;
  }

  results.push({
    id: it.id,
    titel: it.titel,
    klasse: it.klasse,
    slug,
    stamm,
    teilaufgaben: parts,
    flags,
    flag_gruende: reasons,
    vorschlag,
    vorschlag_begruendung: vBegruendung,
    kompetenz_datenpunkte: parts.reduce((s, p) => s + p.kompetenzen.length, 0),
    _pipeline_problems: probs,
    _scrambled_tokens: scrambled,
    _lizenz: { hinweis_gefunden: lic.hasNote, deckt_grafik: lic.coversGrafik, grafik_assets: lic.graphics },
    _review_durch_lena_erforderlich: !!(it._derivation && it._derivation.review_durch_lena_erforderlich),
  });
}

/* --- Sortierung: flagfrei zuerst, dann nach Flag-Anzahl --- */
results.sort((a, b) => a.flags.length - b.flags.length || a.titel.localeCompare(b.titel, 'de'));

/* --- Kennzahlen. Alle Flag-Kategorien auftauchen lassen, auch die mit 0 Treffern
       — sonst sieht es aus, als waere die Kategorie nicht geprueft worden. --- */
const clean = results.filter((r) => !r.flags.length);
const flagCounts = {};
for (const f of Object.values(FLAGS)) flagCounts[f] = 0;
for (const r of results) for (const f of r.flags) flagCounts[f] += 1;

const summe = {
  items: results.length,
  ohne_flag: clean.length,
  mit_flag: results.length - clean.length,
  flag_counts: flagCounts,
  teilaufgaben_ohne_flag: clean.reduce((s, r) => s + r.teilaufgaben.length, 0),
  kompetenz_datenpunkte_ohne_flag: clean.reduce((s, r) => s + r.kompetenz_datenpunkte, 0),
};

fs.writeFileSync(OUT_MD, renderMarkdown(results, summe), 'utf8');
fs.writeFileSync(OUT_JSON, renderJson(results, summe), 'utf8');

/* --- Bericht --- */
console.log(`\nC07 Sichtung — ${results.length} MULTI_PART-Items (status=ready)\n`);
console.log(`  ohne Flag : ${clean.length}`);
console.log(`  mit Flag  : ${results.length - clean.length}\n`);
console.log('  Flags:');
for (const [f, n] of Object.entries(flagCounts).sort((a, b) => b[1] - a[1])) {
  console.log(`    ${f.padEnd(22)} ${String(n).padStart(3)}`);
}
console.log('\n  An den flagfreien Items haengen:');
console.log(`    Teilaufgaben          ${String(summe.teilaufgaben_ohne_flag).padStart(3)}`);
console.log(`    Kompetenz-Datenpunkte ${String(summe.kompetenz_datenpunkte_ohne_flag).padStart(3)}`);
console.log('\n  Vorschlaege (Empfehlung, keine Freigabe):');
const vs = {};
for (const r of results) vs[r.vorschlag] = (vs[r.vorschlag] || 0) + 1;
for (const [v, n] of Object.entries(vs)) console.log(`    ${v.padEnd(22)} ${String(n).padStart(3)}`);
console.log(`\n  → ${path.relative(ROOT, OUT_MD)}\n  → ${path.relative(ROOT, OUT_JSON)}\n`);

if (DEBUG) {
  console.log('--- DEBUG: Items mit "Text defekt" ---');
  for (const r of results.filter((x) => x.flags.includes(FLAGS.TEXT))) {
    console.log(`  ${r.titel}: ${r._scrambled_tokens.join(', ')}`);
  }
  console.log('--- DEBUG: flagfreie Items ---');
  for (const r of clean) console.log(`  ${r.titel} (${r.teilaufgaben.length} TA)`);
}
