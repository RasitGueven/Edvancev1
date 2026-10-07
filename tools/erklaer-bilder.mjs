#!/usr/bin/env node
/**
 * erklaer-bilder.mjs — Bilder der Erklärschritte erzeugen, prüfen und hochladen (E2b).
 *
 *   node tools/erklaer-bilder.mjs docs/prefill/erklaer-k8-linfkt.json --dry-run   prüfen, nichts laden
 *   node tools/erklaer-bilder.mjs docs/prefill/erklaer-k8-linfkt.json             laden (x-upsert)
 *   node tools/erklaer-bilder.mjs docs/prefill/erklaer-k8-linfkt.json --erreichbar  öffentliche URLs abfragen
 *
 * Wie scripts/figures/upload_figures.py: derselbe Generator, dieselbe Prüfung (pruefe_<generator>),
 * derselbe Hash (params_hash). Je Bild EINE Datei im Theme 'dunkel' nach der Pfadregel aus E1:
 * task-assets/erklaer/bilder/<svg_hash>.svg (erklaer_schritt_json). Fällt die Prüfung oder passt der
 * Hash nicht zur Charge (Parameter geändert, Charge nicht neu gebaut), wird nichts geladen.
 *
 * Zugänge aus der Umgebung (nicht im --dry-run): SUPABASE_URL, SUPABASE_SERVICE_KEY.
 */

import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import { BILD_PFAD, BILD_THEME, bilderPython } from './erklaer-lib.mjs';

const BUCKET = 'task-assets';

function env(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Umgebungsvariable ${name} fehlt.`);
  return v;
}

/** Eindeutige Bilder einer Charge: [{svg_hash, generator, params, alt, wo}] */
export function bilderDerCharge(charge) {
  const out = new Map();
  for (const k of charge.kernideen) {
    for (const s of k.schritte) {
      if (s.bild && !out.has(s.bild.svg_hash)) out.set(s.bild.svg_hash, { ...s.bild, wo: `${k.skill_key} K${k.nr} ${s.variante}/${s.art}` });
    }
  }
  return [...out.values()];
}

export async function main(argv = process.argv.slice(2)) {
  const [pfad] = argv;
  if (!pfad) throw new Error('Aufruf: erklaer-bilder.mjs <erklaer-charge.json> [--dry-run | --erreichbar]');
  const bilder = bilderDerCharge(JSON.parse(fs.readFileSync(pfad, 'utf8')));

  if (argv.includes('--erreichbar')) {
    let fehlt = 0;
    for (const b of bilder) {
      const url = `${env('SUPABASE_URL')}/storage/v1/object/public/${BUCKET}/${BILD_PFAD}/${b.svg_hash}.svg`;
      const res = await fetch(url, { method: 'GET' });
      const typ = res.headers.get('content-type') ?? '';
      console.log(`  ${res.status} ${typ.padEnd(14)} ${b.svg_hash.slice(0, 12)}  ${b.wo}`);
      if (!res.ok || !typ.includes('svg')) fehlt += 1;
    }
    console.log(`\nerreichbar=${bilder.length - fehlt} fehlt=${fehlt}`);
    return fehlt ? 1 : 0;
  }

  const dryRun = argv.includes('--dry-run');
  const gerendert = bilderPython(bilder, BILD_THEME);
  let fehler = 0;
  for (const [i, b] of bilder.entries()) {
    const r = gerendert[i];
    if (r.hash !== b.svg_hash) { console.log(`  FEHLER ${b.wo}: Hash ${r.hash.slice(0, 12)} ≠ Charge ${b.svg_hash.slice(0, 12)} — Charge neu bauen`); fehler += 1; continue; }
    if (!r.ok) { console.log(`  FEHLER ${b.wo}: ${r.meldung} — nichts geladen`); fehler += 1; continue; }
  }
  if (fehler) { console.log(`\nfehler=${fehler}, nichts geladen`); return 1; }
  for (const [i, b] of bilder.entries()) {
    const ziel = `${BILD_PFAD}/${b.svg_hash}.svg`;
    if (dryRun) { console.log(`  [dry-run] wuerde laden: ${ziel} (${gerendert[i].svg.length} B)  ${b.wo}`); continue; }
    const res = await fetch(`${env('SUPABASE_URL')}/storage/v1/object/${BUCKET}/${ziel}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${env('SUPABASE_SERVICE_KEY')}`, 'Content-Type': 'image/svg+xml', 'x-upsert': 'true' },
      body: gerendert[i].svg,
    });
    if (!res.ok) throw new Error(`Upload ${ziel} fehlgeschlagen: HTTP ${res.status}`);
    console.log(`  geladen: ${ziel}  ${b.wo}`);
  }
  console.log(`\nbilder=${bilder.length}${dryRun ? ' (dry-run)' : ' geladen'}`);
  return 0;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().then((code) => process.exit(code), (e) => { console.error(e.message); process.exit(1); });
}
