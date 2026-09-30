// Schuelerakte (S2): Typen der S1-Schnittstellen. Alle Werte kommen aus der
// Datenbank (board_schueler, schuelerakten, einheiten_stand, eltern_reports,
// schueler_notizen); das Frontend rechnet nichts davon selbst.

import type { AttendanceStatus } from './session'

export type AkteZustand = 'aktiv' | 'ruhend'
export type EinheitenArt = 'laufend' | 'vorher' | 'keiner'
export type Ampel = 'im_plan' | 'leicht_im_rueckstand' | 'deutlich_im_rueckstand'
export type NotizKategorie = 'lernen' | 'verhalten' | 'organisatorisch'
export type ElternReportArt = 'lernstandsanalyse' | 'zwischenbericht'

/** Zeile aus board_schueler(): Akte + Einheiten-Stand, eine Abfrage fuer das Board. */
export type BoardSchueler = {
  student_id: string
  name: string | null
  klasse: number | null
  schule: string | null
  zustand: AkteZustand
  ruhend_seit: string | null
  letzte_session: string | null
  art: EinheitenArt
  einheiten: number | null
  beginn: string | null
  stichtag: string | null
  verbraucht: number | null
  offen: number | null
  soll: number | null
  rueckstand: number | null
  ampel: Ampel | null
}

/** Zeile aus der View schuelerakten. */
export type Schuelerakte = {
  student_id: string
  name: string | null
  klasse: number | null
  schule_id: string | null
  schule: string | null
  akte_seit: string | null
  zustand: AkteZustand
  ruhend_seit: string | null
  letzte_session: string | null
}

/** Rueckgabe von einheiten_stand(student). */
export type EinheitenStand = {
  art: EinheitenArt
  einheiten: number | null
  beginn: string | null
  stichtag: string | null
  verbraucht: number | null
  offen: number | null
  soll: number | null
  rueckstand: number | null
  ampel: Ampel | null
  wochen_rest: number | null
  noetig_pro_woche: number | null
  gleichmaessig_pro_woche: number | null
}

export type AkteSession = {
  session_id: string
  scheduled_at: string
  coach_name: string | null
  attendance: AttendanceStatus
}

export type SchuelerNotiz = {
  id: string
  kategorie: NotizKategorie
  text: string | null
  autor_name: string | null
  autor_rolle: 'admin' | 'coach'
  created_at: string
  ausgeblendet_am: string | null
  ausgeblendet_von_name: string | null
  ausgeblendet_grund: string | null
  entfernt_am: string | null
  entfernt_von_name: string | null
}

export type ElternReport = {
  id: string
  nr: number
  art: ElternReportArt
  berichtsmonat: string | null
  kernaussagen: Record<string, string> | null
  freigegeben_von_name: string | null
  versendet_am: string | null
  pdf_pfad: string | null
}

export type WortlisteEintrag = { wort: string; nur_ganzes_wort: boolean }
