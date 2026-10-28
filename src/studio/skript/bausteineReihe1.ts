import type { BausteinSpec } from './bausteine'

/**
 * Bausteine für die Reihe „Quadratische Funktionen und Gleichungen“ (Bauauftrag B7, Konzept §8).
 *
 * koordinatensystem: Achsen, Raster, Parabel y = a·(x − d)² + e, animiert zu parabel_ziel (strecken, stauchen,
 *   spiegeln, verschieben), Scheitel und Nullstellen markieren, Gerade y = c mit Schnittpunkten, Punkte, Wertetabelle.
 * flaechenmodell: Quadrat x · x, zwei Streifen b/2 · x, fehlendes Eckquadrat (b/2)² (quadratische Ergänzung).
 */
export const BAUSTEINE_REIHE1: Record<string, BausteinSpec> = {
  koordinatensystem: {
    params: {
      x_bereich: { art: 'zahl_liste', min: 2, max: 2 },
      y_bereich: { art: 'zahl_liste', min: 2, max: 2 },
      raster: { art: 'bool' },
      parabel: { art: 'zahl_liste', min: 3, max: 3 },
      parabel_ziel: { art: 'zahl_liste', min: 3, max: 3 },
      normalparabel: { art: 'bool' },
      scheitel_markieren: { art: 'bool' },
      nullstellen_markieren: { art: 'bool' },
      gerade_y: { art: 'zahl', min: -50, max: 50 },
      schnitt_markieren: { art: 'bool' },
      punkte: { art: 'punkte', max: 8 },
      wertetabelle: { art: 'zahl_liste', min: 0, max: 7 },
      gleichung: { art: 'tex' },
    },
    bild: [],
  },
  flaechenmodell: {
    params: {
      b: { art: 'zahl', min: 0.5, max: 20, pflicht: true },
      zeigen: { art: 'wahl', werte: ['quadrat', 'streifen', 'ecke'], pflicht: true },
      x_beschriftung: { art: 'text', max: 4 },
      gleichung: { art: 'tex' },
    },
    bild: [],
  },
}
