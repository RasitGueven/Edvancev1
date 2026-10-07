// Erklaersequenzen pruefen (Paket L6): Rueckgaben von erklaer_pruef_liste, erklaer_pruef_detail und den
// Pruef-/Freigabefunktionen (Migrationen 20261010121014 … 121017).

export type ErklaerStatus = 'entwurf' | 'geprueft' | 'freigegeben'
export type ErklaerStand = 'offen' | 'unsicher' | 'passt_nicht' | 'passt' | 'freigegeben'
export type ErklaerVariante = 'A' | 'B' | 'C'
export type ErklaerArt = 'erklaerung' | 'beispiel'
export type ErklaerEntscheidung = 'passt' | 'unsicher' | 'passt_nicht' | 'zurueckgenommen'
export type ErklaerProtokollArt = ErklaerEntscheidung | 'freigegeben' | 'freigabe_zurueck' | 'geaendert' | 'status'

/** Gruende fuer „Passt nicht“ (erklaer_pruefen); Reihenfolge der Knoepfe in lib/pruefung/erklaerAnzeige.ts. */
export type ErklaerGrund =
  | 'fachlich_falsch' | 'unklar' | 'zu_lang' | 'sprache_klassenstufe' | 'formel_bild_fehlerhaft'
  | 'variante_fehlbild' | 'check_passt_nicht' | 'sonstiges'

export type ErklaerListenZeile = {
  kernidee_id: string
  skill_key: string
  skill_label: string
  thema_key: string | null
  thema_label: string | null
  klasse: number
  nr: number
  titel: string
  status: ErklaerStatus
  stand: ErklaerStand
  rueckfrage: boolean
  bereit: boolean
  varianten: number
  schritte: number
  schritte_offen: number
  checks: number
  checks_soll: number
  geaendert_am: string
}

export type ErklaerBild = { url?: string; svg_hash?: string; alt: string }

/** So wie erklaer_schritt_json es dem Kind liefert: Formeln nur als SVG-URL. */
export type ErklaerKindSchritt = {
  art: ErklaerArt
  inhalt: string
  formeln: string[]
  bild?: { url: string; alt: string; content_type?: string }
}

export type ErklaerSchritt = {
  id: string
  variante: ErklaerVariante
  art: ErklaerArt
  inhalt: string
  bild: ErklaerBild | null
  fehlbild_slugs: string[]
  status: ErklaerStatus
  formeln_soll: number
  formeln_ist: number
  geaendert_am: string
  kind: ErklaerKindSchritt
}

export type ErklaerFehlbild = { slug: string; klartext: string | null; aufgaben: number }

export type ErklaerCheck = {
  task_id: string
  reihenfolge: number
  titel: string
  status: string
  lena_status: string | null
  einsatz_check: boolean
  aktiv: boolean
  zaehlt: boolean
}

export type ErklaerFehlt =
  | { was: 'kernidee_ungeprueft' | 'keine_erklaerung' }
  | { was: 'schritt_ungeprueft' | 'formeln_fehlen' | 'schritt_nicht_freigegeben'; variante: ErklaerVariante; art: ErklaerArt }
  | { was: 'checks'; soll: number; ist: number }

export type ErklaerAenderung = {
  objekt: 'kernidee' | 'schritt' | 'check'
  feld: string
  vorher: unknown
  nachher: unknown
  variante?: ErklaerVariante
  art?: ErklaerArt
  task_id?: string
}

export type ErklaerProtokollZeile = {
  id: number
  entscheidung: ErklaerProtokollArt
  gruende: string[]
  notiz: string | null
  aenderungen: ErklaerAenderung[]
  pruef_version: number | null
  von: string | null
  am: string
  antwort: string | null
  beantwortet_von: string | null
  beantwortet_am: string | null
}

export type ErklaerDetail = {
  kernidee: {
    id: string
    skill_key: string
    skill_label: string | null
    klasse: number | null
    nr: number
    titel: string
    status: ErklaerStatus
    quelle: 'ki' | 'mensch'
    pruef_version: number
    geaendert_am: string
    stand: ErklaerStand
    rueckfrage: boolean
    kernideen: number
  }
  schritte: ErklaerSchritt[]
  fehlbilder: ErklaerFehlbild[]
  checks: ErklaerCheck[]
  checks_soll: number
  freigabe_fehlt: ErklaerFehlt[]
  protokoll: ErklaerProtokollZeile[]
}

export type ErklaerAntwort = { pruef_version: number; status?: ErklaerStatus; stand?: ErklaerStand }

/** Fehler mit SQLSTATE, HINT (Schluessel fuer i18n) und DETAIL (bei freigabe_unvollstaendig die Liste). */
export type ErklaerFehler = { code: string | null; hint: string | null; message: string; fehlt: ErklaerFehlt[] | null }
export type ErklaerResult<T> = { data: T | null; error: ErklaerFehler | null }
