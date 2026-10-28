/**
 * Import-Format der Studio-Skripte (Anforderung Studio, Anhang A; Bauauftrag B1).
 *
 * Ein Skript ist eine Liste von Beats. Ein Beat = ein Satz, ein Baustein mit
 * Parametern, eine Sprungmarke (titel). Welten tauschen nur Sprechtext und
 * Bildparameter; Zahlen, Reihenfolge und Rücksprünge kommen aus dem Skelett.
 */

export type Welt = string

/** Text je Welt; `skelett` ist Pflicht, fehlt eine Welt, gilt das Skelett. */
export type WeltTexte = Record<Welt, string>

export type SkriptBeat = {
  id: string
  /** Sprungmarke, höchstens 40 Zeichen. */
  titel: string
  /** "k1" (Skill der Sequenz) oder "<skill_key>:k1" (weiterer Skill). */
  kernidee: string
  baustein: string
  params: Record<string, unknown>
  text: WeltTexte
  /** Bildparameter je Welt (keine Zahlen, keine Mathematik). */
  bild?: Record<Welt, Record<string, unknown>>
}

export type SkriptOption = {
  antwort: string
  richtig?: boolean
  fehlbild?: string
  ruecksprung?: string
  rueckmeldung: string
}

/** Dieselbe Frage mit anderen Zahlen (kommt nach einem Rücksprung). */
export type SkriptZwilling = { frage: WeltTexte; optionen: SkriptOption[] }

export type SkriptMiniCheck = {
  nach_beat: string
  frage: WeltTexte
  optionen: SkriptOption[]
  zwillinge?: SkriptZwilling[]
}

export type Skript = {
  skill_key: string
  titel: string
  welten: Welt[]
  beats: SkriptBeat[]
  minichecks: SkriptMiniCheck[]
}

/**
 * sperre   – das Skript wird nicht gespeichert
 * welt     – nur diese Welt ist gesperrt, Skelett und andere Welten bleiben prüfbar
 * hinweis  – wird angezeigt, sperrt nichts
 */
export type BefundStufe = 'sperre' | 'welt' | 'hinweis'

export type Befund = {
  stufe: BefundStufe
  /** i18n-Schlüssel unter `studio:befund.<code>`. */
  code: string
  beat?: string
  welt?: Welt
  /** Werte für die Meldung (z. B. param, wert, erwartet). */
  werte?: Record<string, string | number>
}

export type PruefErgebnis = {
  /** true: speicherbar (keine Befunde der Stufe sperre). */
  ok: boolean
  befunde: Befund[]
  /** Welten mit einem Befund der Stufe welt. */
  gesperrteWelten: Welt[]
  /** Beat-Bereiche je Kernidee-Schlüssel (normalisiert auf "<skill>:k<n>"). */
  bereiche: Record<string, { von: string; bis: string }>
}
