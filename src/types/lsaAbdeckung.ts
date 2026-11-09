// FR-2 (Migration 20261109114850_fr2_lsa_pakete): Pakete je Klassenarbeit, Ampel, gezielte Prüfliste.
// Die Formen spiegeln die Zeilen der Funktionen lsa_abdeckung, lsa_paket_skills, pruef_ziel_liste und lsa_wirkung.

export type LsaAmpel = 'gruen' | 'gelb' | 'rot'
export type LsaPaketQuelle = 'bestaetigt' | 'geschaetzt'
export type LsaPaketFall = 'A' | 'B'
export type LsaPaketTeil = 'einstieg' | 'voraussetzung' | 'tiefe' | 'rand' | 'rand_tiefe'

/** Eine Zeile von lsa_abdeckung: ein Paket (Klassenarbeit) einer Schule mit Ampel. */
export type LsaAbdeckungZeile = {
  schule_id: string
  schule: string
  fokus: boolean
  klasse: number
  paket_nr: number
  thema_keys: string[]
  thema_labels: string[]
  quelle: LsaPaketQuelle
  datum: string | null
  quartal: number
  lage: number
  ampel: LsaAmpel
  fehlende_pflicht_skills: number
  fehlende_skills: number
  fehlende_texte: number
  hat_einstieg: boolean
}

/** Eine Zeile von lsa_paket_skills: ein Skill eines Pakets mit Stand und Prüfbedarf. */
export type LsaPaketSkill = {
  skill_key: string
  skill_label: string
  thema_label: string | null
  fall: LsaPaketFall
  teil: LsaPaketTeil
  pflicht: boolean
  erfuellt: boolean
  texte_im_pool: number
  fehlende_texte: number
  /** Aufgaben, die Lena für diesen Skill noch prüft (ohne Reserve). */
  vorschlaege: number
}

export type PruefZielAbschnitt = 'gezielt' | 'nachpruefen'

/** Eine Zeile von pruef_ziel_liste: ein Skill mit vorgeschlagenen Aufgaben. */
export type PruefZielZeile = {
  abschnitt: PruefZielAbschnitt
  skill_key: string
  skill_label: string
  thema_key: string | null
  thema_label: string | null
  fehlende_texte: number
  rest: number
  hebel_pakete: number
  hebel_schulen: number
  fokus_treffer: number
  sort: number
  /** Entwürfe für Lena (bzw. im Abschnitt nachpruefen: die ready-Aufgaben ohne letztes „passt“). */
  task_ids: string[]
  /** Schon „passt“ und freigabefähig: warten nur auf die Admin-Freigabe. */
  freigabe_ids: string[]
  /** Vorschläge, die Lena erst nach pruef_sammel('pilot_an') sieht. */
  pilot_fehlt: string[]
}

/** Eine Zeile von lsa_wirkung: ein Paket, dessen Ampel sich ändert. */
export type LsaWirkungZeile = {
  schule_id: string
  schule: string
  klasse: number
  paket_nr: number
  thema_keys: string[]
  ampel_vorher: LsaAmpel
  ampel_nachher: LsaAmpel
  schule_neu: boolean
}
