/**
 * C07 — Ausgabe der Sichtungsliste (Markdown zum Lesen, JSON zum Weiterverarbeiten).
 */
const { trunc } = require('./detect.cjs');

const FLAG_DOC = {
  'kein Stamm': 'Kein gemeinsamer Stamm von den Teilaufgaben abtrennbar',
  'Text defekt': 'Zerfallene Extraktion: verschraenkte Zeichen, verdoppelte Buchstaben, zerfallene Brueche',
  'nicht auto-gradebar': 'Zeichnen/Messen/Konstruieren/Freitext — oder die Auswertung beschreibt die Loesung nur',
  'Loesung unklar': 'Intervall, Mehrfachbedingung, Prosa, falsche Einheit oder fehlende Loesung statt eines Werts',
  Einheiten: 'Dieselbe Zahl in mehreren Einheiten (P01: keine Umrechnung)',
  'Asset fehlt': 'Abbildung/Tabelle noetig, aber kein verwendbares Asset',
  'Rechte unklar': 'Grafik vorhanden, aber vom eingebetteten Lizenzhinweis nicht gedeckt (C04)',
};

function renderMarkdown(results, summe) {
  const md = [];
  md.push('# C07 — Sichtungsliste MULTI_PART');
  md.push('');
  md.push(
    "Erzeugt aus `data/vera8_komplett_enriched.json` (`status='ready'`, `task_type='MULTI_PART'`) via `scripts/c07_sichtung.cjs`."
  );
  md.push('');
  md.push("**Nichts hiervon ist importiert.** `status='ready'` heisst \"Pipeline durchgelaufen\", nicht \"geprueft\"");
  md.push('(`_derivation.review_durch_lena_erforderlich = true`). Der VORSCHLAG ist eine Maschinen-Empfehlung —');
  md.push('die Freigabe erfolgt durch einen Menschen. Defekte Texte sind markiert, nicht geraten.');
  md.push('');
  md.push(`**Bestand:** ${summe.items} Items · **ohne Flag:** ${summe.ohne_flag} · **mit Flags:** ${summe.mit_flag}`);
  md.push('');
  md.push('| Flag | Items | Bedeutung |');
  md.push('|---|---|---|');
  for (const [f, n] of Object.entries(summe.flag_counts).sort((a, b) => b[1] - a[1])) {
    md.push(`| ${f} | ${n} | ${FLAG_DOC[f] || ''} |`);
  }
  md.push('');
  md.push(
    `An den ${summe.ohne_flag} flagfreien Items haengen **${summe.teilaufgaben_ohne_flag} Teilaufgaben** und **${summe.kompetenz_datenpunkte_ohne_flag} Kompetenz-Datenpunkte** (TA x Kompetenz).`
  );
  md.push('');
  md.push('Flagfreie Items stehen zuerst — die sind am schnellsten durchzusehen. Danach steigt die Flag-Anzahl.');
  md.push('');
  md.push('Zu pruefen ist bei jedem Item vor allem, **ob die Loesung stimmt** — das kann keine Maschine entscheiden.');
  md.push('');
  md.push('---');
  md.push('');

  results.forEach((r, i) => {
    md.push(`===== ${i + 1}/${results.length} — ${r.titel} (id ${r.id.slice(0, 8)})`);
    md.push(`STAMM:  ${r.stamm ? trunc(r.stamm, 400) : '— kein gemeinsamer Stamm abtrennbar —'}`);
    for (const p of r.teilaufgaben) {
      const akz = p.akzeptierte_antworten.length ? p.akzeptierte_antworten.join(' | ') : '—';
      md.push(
        `TA ${p.nr}:   [${p.kind}] ${trunc(p.prompt, 220) || '— kein Prompt-Text —'}  | Loesung: ${
          trunc(p.loesung || akz, 120) || '—'
        } | AFB ${p.afb ?? '?'} | Kompetenzen: ${p.kompetenzen.join(', ') || '—'}`
      );
    }
    md.push(`FLAGS:  ${r.flags.length ? r.flags.join(', ') : '—'}`);
    for (const g of r.flag_gruende) md.push(`        · ${g}`);
    md.push(`VORSCHLAG: ${r.vorschlag}   (${r.vorschlag_begruendung})`);
    md.push('');
  });

  return `${md.join('\n')}\n`;
}

function renderJson(results, summe) {
  return `${JSON.stringify(
    {
      erzeugt_von: 'scripts/c07_sichtung.cjs',
      quelle: 'data/vera8_komplett_enriched.json',
      filter: { status: 'ready', task_type: 'MULTI_PART' },
      hinweis:
        'Reiner Analyse-Lauf. Nichts importiert. VORSCHLAG ist eine Empfehlung, keine Freigabe — die trifft ein Mensch. Ein spaeterer Import laeuft gegen eine von Hand freigegebene ID-Liste, nicht gegen dieses Feld.',
      summe,
      // Maschinen-Kandidaten, KEINE Freigabe: die flagfreien Items. Die
      // freigegebene ID-Liste fuer den Import entsteht durch menschliche Sichtung.
      kandidaten_ohne_flag_ids: results.filter((r) => !r.flags.length).map((r) => r.id),
      items: results,
    },
    null,
    2
  )}\n`;
}

module.exports = { renderMarkdown, renderJson, FLAG_DOC };
