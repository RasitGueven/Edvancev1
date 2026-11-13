// IU-1: Inhalte-Übersicht. Zeilen der Funktionen aus 20261113082550_iu1_inhalte (alle nur für Admins).

export type ThemaAmpel = 'vollstaendig' | 'eingeschraenkt' | 'noch_nicht'
export type ReihenAmpel = 'bereit' | 'in_arbeit' | 'nicht_bereit'
export type VideoStatus = 'freigegeben' | 'in_pruefung' | 'fehlt'
export type SessionSchritt = 'lena_prueft' | 'rueckfrage' | 'entwurf' | 'admin_gibt_frei' | 'video' | 'fertig'
export type Vorarbeit = 'bauformen' | 'lsa' | 'keine'

/** inhalte_lsa_themen: je Thema der Pläne Kl. 8–10. von/bis = Datum (ISO) der Pakete im Hauptquartal. */
export type InhalteThema = {
  thema_key: string
  titel: string
  klasse: number
  quartal: number
  von: string | null
  bis: string | null
  komp_bereit: number
  komp_teil: number
  komp_offen: number
  pflicht_bereit: number
  pflicht_gesamt: number
  hat_einstieg: boolean
  aufgaben_frei: number
  aufgaben_zur_freigabe: number
  aufgaben_zu_pruefen: number
  aufgaben_fehlen: number
  ampel: ThemaAmpel
  schulen: number
  schulen_bestaetigt: number
  /** Aufgaben für Lena über alle Themen der Auswahl, je Kompetenz einmal (auf jeder Zeile gleich). */
  alle_zu_pruefen: number
}

/** inhalte_lsa_thema: je Kompetenz. teil = pflicht | tiefe, rolle = einstieg | voraussetzung | tiefe. */
export type InhalteKompetenz = {
  skill_key: string
  label: string
  teil: 'pflicht' | 'tiefe'
  rolle: 'einstieg' | 'voraussetzung' | 'tiefe'
  /** Belegte Texte nach der Regel, 0..2 (2 = bereit). */
  texte: number
  erfuellt: boolean
  zu_pruefen: number
  fehlen: number
  offene_task_ids: string[]
}

/** inhalte_lsa_pruefziel: bereich null = Kopfzeile (gesamt). */
export type InhaltePruefzielBereich = {
  bereich: string | null
  titel: string
  komp_bereit: number
  komp_teil: number
  komp_offen: number
  fehlende_texte: number
  aufgaben_frei: number
  aufgaben_zur_freigabe: number
  aufgaben_zu_pruefen: number
  aufgaben_fehlen: number
  zu_leicht: number
  ampel: 'vollstaendig' | 'noch_nicht'
}

/** inhalte_session_reihen: je Reihe (bauformen.reihe). */
export type InhalteReihe = {
  reihe: string
  titel: string
  thema_keys: string[]
  klasse: number | null
  sessions: number
  quartal: number | null
  von: string | null
  bis: string | null
  bf_freigegeben: number
  bf_zur_freigabe: number
  bf_rueckfrage: number
  bf_offen: number
  bf_zu_pruefen: number
  vid_freigegeben: number
  vid_in_pruefung: number
  vid_fehlt: number
  vid_gesamt: number
  ampel: ReihenAmpel
  schulen: number
  schulen_bestaetigt: number
}

/** inhalte_session_reihe: je Session; nr null = Bauformen ohne Session. */
export type InhalteSession = {
  nr: number | null
  titel: string | null
  bauformen: number
  geprueft: number
  freigegeben: number
  rueckfrage: number
  zu_pruefen: number
  zur_freigabe: number
  video_status: VideoStatus | null
  naechster_schritt: SessionSchritt
}

/** inhalte_themen_ohne_reihe. */
export type InhalteThemaOhneReihe = {
  thema_key: string
  titel: string
  klasse: number
  quartal: number
  von: string | null
  bis: string | null
  schulen: number
  schulen_bestaetigt: number
  bauformen: number
  lsa_frei: number
  vorarbeit: Vorarbeit
}
