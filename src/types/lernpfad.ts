// Lernpfad und Mastery auf skill_key (Session-Rahmen P1, Paket A1).
//
// Systemzustand und Coach-Entscheidung sind getrennte Felder: stand_system
// setzt nur das System (Belege aus Sessions, Uebernahme aus der LSA),
// stand_coach nur der Coach ueber mastery_entscheiden. „Gemeistert“ gibt es
// ausschliesslich in stand_coach (Bauauftrag, Entscheidungen 3 und 6).

export type LernpfadStandSystem = 'offen' | 'aktiv' | 'sicher' | 'noch_nicht_sicher' | 'kandidat'

export type LernpfadStandCoach = 'gemeistert' | 'vertagt'

export type LernpfadQuelle = 'lsa' | 'session' | 'coach'

export type BelegErgebnis = 'richtig' | 'teilweise' | 'falsch'

/** Verdichtung je Session in lernpfad.belege. */
export type LernpfadSessionBeleg = {
  session_id: string
  am: string
  gesamt: number
  richtig_ohne_hinweis: number
}

/** Eine Zeile aus lernpfad (Coach und Admin lesen direkt, RLS wie die Akte). */
export type LernpfadEintrag = {
  id: string
  student_id: string
  skill_key: string
  stand_system: LernpfadStandSystem
  stand_system_seit: string
  stand_coach: LernpfadStandCoach | null
  coach_grund: string | null
  coach_von: string | null
  coach_am: string | null
  coach_session_id: string | null
  quelle: LernpfadQuelle
  lsa_session_id: string | null
  letzte_uebung_am: string | null
  letzte_session_id: string | null
  belege: LernpfadSessionBeleg[]
}

/** Rolle einer Zeile in „Ziel der Stunde“. */
export type ZielRolle = 'einstieg' | 'thema' | 'voraussetzung' | 'voraussetzung_sicher'

/** Anzeige-Stand: stand_system, ausser der Coach hat „gemeistert“ gebucht. */
export type ZielStand = LernpfadStandSystem | 'gemeistert'

export type ZielFertigkeit = {
  reihenfolge: number
  skill_key: string
  label: string
  klasse_herkunft: number
  rolle: ZielRolle
  stand_system: LernpfadStandSystem | null
  stand_coach: LernpfadStandCoach | null
  stand: ZielStand
  /** Kandidat zur Mastery-Pruefung vorgeschlagen (nach „vertagt“ erst mit neuen Belegen). */
  pruefung_faellig: boolean
}

/** Anlass einer Pfad-Entscheidung: Warm-up oder Interventionsstufe 4. */
export type PfadAnlass = 'warmup' | 'eingriff'

export type MasteryVorschlag = {
  skill_key: string
  label: string
  stand_coach: 'vertagt' | null
  coach_grund: string | null
  letzte_uebung_am: string | null
}

export type NaechsteLuecke = {
  skill_key: string
  label: string
  thema_key: string | null
  stand_system: LernpfadStandSystem
  /** 'lsa': Ziel kommt aus der LSA (noch kein Session-Beleg). */
  quelle: 'lsa' | 'lernpfad'
}

export type SkillPruefung = {
  id: string
  skill_key: string
  frage: string
  erwartung: string
  kriterium: string
  quelle: 'ki' | 'mensch'
}

/** Sicht des Kindes: ein Mastery-Kandidat erscheint als „sicher“. */
export type MeinLernpfadEintrag = {
  skill_key: string
  label: string
  stand: Exclude<LernpfadStandSystem, 'kandidat'> | 'gemeistert'
  seit: string
}

export type LernpfadUebernahme = {
  ok: boolean
  angelegt: number
  aktualisiert: number
}

export type MasteryEntscheidung = {
  ok: boolean
  skill_key: string
  stand_system: LernpfadStandSystem
  stand_coach: LernpfadStandCoach
}
