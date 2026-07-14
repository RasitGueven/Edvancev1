/**
 * C07 — Lizenz- und Asset-Lage pro Item.
 *
 * Erkenntnis aus C04: das Feld `lizenz_status` im Bestand ist pauschal (bei allen
 * Items derselbe Satz) und fuer Grafiken schlicht FALSCH. Verbindlich ist nur der
 * je Aufgabe eingebettete Lizenzhinweis — eine EMF-Grafik im Word-Dokument.
 * Nennt dieser Hinweis das Wort "Grafik" nicht, deckt die Lizenz nur Text und
 * Teilaufgaben, und die Grafik ist nicht gedeckt.
 *
 *   "Text Grafik und Teilaufgaben … CC BY"  → Grafik gedeckt
 *   "Text und Teilaufgaben … CC BY"         → Grafik NICHT gedeckt
 */
const fs = require('fs');
const path = require('path');

/** EMF speichert Text als UTF-16LE-Records — daraus die Klartext-Fragmente ziehen. */
function emfText(file) {
  let b;
  try {
    b = fs.readFileSync(file);
  } catch {
    return '';
  }
  const parts = [];
  let cur = '';
  for (let i = 0; i + 1 < b.length; i += 2) {
    const lo = b[i];
    const hi = b[i + 1];
    if (hi === 0 && (lo >= 32 || lo >= 192)) cur += Buffer.from([lo, hi]).toString('utf16le');
    else {
      if (cur.length >= 4) parts.push(cur);
      cur = '';
    }
  }
  if (cur.length >= 4) parts.push(cur);
  return parts.join(' ');
}

/**
 * Liefert je Slug: gibt es einen eingebetteten Lizenzhinweis, deckt er die
 * Grafik, und welche echten Bild-Assets (raster/emf_graphic) haengen am Item.
 * EMF-Textrecords zaehlen NICHT als Bild — das ist zerlegter Text, kein Asset.
 */
function makeLicenseInfo(manifest, root) {
  const cache = new Map();
  return (slug) => {
    if (cache.has(slug)) return cache.get(slug);
    const entry = manifest[slug];
    const info = { hasNote: false, coversGrafik: false, graphics: [], noteText: '' };
    if (entry) {
      for (const m of entry.medien || []) {
        if (m.typ === 'license') {
          info.hasNote = true;
          info.noteText = emfText(path.join(root, 'data', m.pfad));
        } else if (m.typ === 'raster' || m.typ === 'emf_graphic') {
          info.graphics.push(m.pfad);
        }
      }
      info.coversGrafik = /grafik/i.test(info.noteText);
    }
    cache.set(slug, info);
    return info;
  };
}

module.exports = { emfText, makeLicenseInfo };
