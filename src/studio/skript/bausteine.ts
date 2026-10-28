/**
 * Parameter der Baustein-Bibliothek (Anforderung Studio §6). Einzige Quelle für
 * die Importprüfung (B1) und die Remotion-Bausteine (B3/B7): Ein Baustein, der
 * hier fehlt, ist unbekannt; ein Parameter, der hier fehlt, ist ungültig.
 */

export type ParamArt =
  | { art: 'text'; max?: number }
  | { art: 'zahl'; ganz?: boolean; min?: number; max?: number }
  | { art: 'bool' }
  | { art: 'wahl'; werte: readonly string[] }
  | { art: 'tex' }
  | { art: 'tex_liste'; min: number; max: number }
  | { art: 'text_liste'; min: number; max: number }
  | { art: 'zahl_liste'; min: number; max: number }
  | { art: 'punkte'; max: number }

export type ParamSpec = ParamArt & { pflicht?: boolean }

export type BausteinSpec = {
  params: Record<string, ParamSpec>
  /** Bildparameter, die eine Welt setzen darf (nur Wörter, keine Zahlen). */
  bild: readonly string[]
}

const WELT_BILD = ['einheit', 'gegenstand'] as const

export const BAUSTEINE: Record<string, BausteinSpec> = {
  titelkarte: {
    params: { titel: { art: 'text', max: 60, pflicht: true }, untertitel: { art: 'text', max: 80 } },
    bild: [],
  },
  raster: {
    params: {
      zeilen: { art: 'zahl', ganz: true, min: 1, max: 12, pflicht: true },
      spalten: { art: 'zahl', ganz: true, min: 1, max: 12, pflicht: true },
      aufbauen: { art: 'bool' },
      markiert: { art: 'zahl', ganz: true, min: 0, max: 144 },
      beschriftung: { art: 'text', max: 30 },
      seite_markieren: { art: 'wahl', werte: ['unten', 'links'] },
      seite_beschriftung: { art: 'text', max: 10 },
      zaehlen: { art: 'wahl', werte: ['untere_reihe', 'linke_spalte', 'alle'] },
    },
    bild: WELT_BILD,
  },
  term_zeile: {
    params: {
      terme: { art: 'tex_liste', min: 1, max: 6, pflicht: true },
      hervorheben: { art: 'zahl_liste', min: 0, max: 6 },
      durchstreichen: { art: 'zahl_liste', min: 0, max: 6 },
      umkehrpfeil: { art: 'bool' },
    },
    bild: [],
  },
  merksatz: {
    params: { text: { art: 'text', max: 120, pflicht: true }, formel: { art: 'tex' } },
    bild: [],
  },
  endkarte: {
    params: { frage: { art: 'text', max: 80, pflicht: true }, optionen: { art: 'text_liste', min: 0, max: 4 } },
    bild: [],
  },
}

/** Ergänzt die Bibliothek um weitere Bausteine (B7), ohne die Startbausteine anzufassen. */
export function bausteineMit(weitere: Record<string, BausteinSpec>): Record<string, BausteinSpec> {
  return { ...BAUSTEINE, ...weitere }
}

/** null, wenn der Wert passt; sonst der Code des Befunds. */
export function paramFehler(spec: ParamSpec, wert: unknown): string | null {
  switch (spec.art) {
    case 'text':
      if (typeof wert !== 'string' || wert.trim() === '') return 'param_text'
      return spec.max !== undefined && wert.length > spec.max ? 'param_zu_lang' : null
    case 'tex':
      return typeof wert === 'string' && wert.trim() !== '' ? null : 'param_tex'
    case 'zahl':
      if (typeof wert !== 'number' || !Number.isFinite(wert)) return 'param_zahl'
      if (spec.ganz && !Number.isInteger(wert)) return 'param_zahl'
      if ((spec.min !== undefined && wert < spec.min) || (spec.max !== undefined && wert > spec.max)) return 'param_bereich'
      return null
    case 'bool':
      return typeof wert === 'boolean' ? null : 'param_bool'
    case 'wahl':
      return typeof wert === 'string' && spec.werte.includes(wert) ? null : 'param_wahl'
    case 'tex_liste':
    case 'text_liste':
      if (!Array.isArray(wert) || wert.some((w) => typeof w !== 'string' || w.trim() === '')) return 'param_liste'
      return wert.length < spec.min || wert.length > spec.max ? 'param_bereich' : null
    case 'zahl_liste':
      if (!Array.isArray(wert) || wert.some((w) => typeof w !== 'number' || !Number.isFinite(w))) return 'param_liste'
      return wert.length < spec.min || wert.length > spec.max ? 'param_bereich' : null
    case 'punkte':
      if (!Array.isArray(wert) || wert.length > spec.max) return 'param_liste'
      return wert.every(
        (p) => Array.isArray(p) && p.length === 2 && p.every((z) => typeof z === 'number' && Number.isFinite(z)),
      )
        ? null
        : 'param_liste'
  }
}
