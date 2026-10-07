// Session-Rahmen R1, Coach-Seite: Start, Tablets, Check-in, Live-Sicht,
// Signale, Eingriffe, Check-out und Abschluss. Nur der Coach der Session oder
// ein Admin; jede andere Rolle bekommt 42501 von der Datenbank.

import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type {
  AbschlussEingabe,
  EingriffStufe,
  KindDetail,
  PfadEntscheidung,
  RaumLive,
  RaumSignal,
  SessionAbschlussErgebnis,
  SessionFall,
  SessionPhase,
  SignalArt,
  StellschraubeWert,
} from '@/types'

type Ziel = { fall_vorschlag: SessionFall | null; fall_coach: SessionFall | null; ziel_thema_key: string | null }

export const sessionStarten = (sessionId: string): Promise<RpcResult<Record<string, StellschraubeWert>>> =>
  sessionRpc('session_starten', { p_session_id: sessionId }, 'Could not start session')

export const tabletZuweisen = (sessionId: string, studentId: string, tabletNr: number): Promise<RpcResult<string>> =>
  sessionRpc('tablet_zuweisen', { p_session_id: sessionId, p_student_id: studentId, p_tablet_nr: tabletNr },
    'Could not assign tablet')

export const tabletLoesen = (sessionId: string, studentId: string): Promise<RpcResult<null>> =>
  sessionRpc('tablet_loesen', { p_session_id: sessionId, p_student_id: studentId }, 'Could not release tablet')

export const phaseSetzen = (sessionId: string, studentId: string, phase: SessionPhase): Promise<RpcResult<null>> =>
  sessionRpc('phase_setzen', { p_session_id: sessionId, p_student_id: studentId, p_phase: phase },
    'Could not set phase')

export const fallVorschlag = (sessionId: string, studentId: string): Promise<RpcResult<SessionFall>> =>
  sessionRpc('fall_vorschlag', { p_session_id: sessionId, p_student_id: studentId }, 'Could not load case')

/** Fall waehlen und/oder ein neues Schulthema setzen (altes wird "behandelt"). */
export const checkinCoachSetzen = (
  sessionId: string,
  studentId: string,
  fall: SessionFall | null,
  themaKey: string | null = null,
): Promise<RpcResult<Ziel>> =>
  sessionRpc('checkin_coach_setzen',
    { p_session_id: sessionId, p_student_id: studentId, p_fall: fall, p_thema_key: themaKey },
    'Could not save check-in')

/** Bis A1 die Auswahl liefert: eine freigegebene Aufgabe an ein Kind geben. */
export const aufgabeAusgeben = (
  sessionId: string,
  studentId: string,
  taskId: string,
  eingemischt = false,
): Promise<RpcResult<string>> =>
  sessionRpc('aufgabe_ausgeben',
    { p_session_id: sessionId, p_student_id: studentId, p_task_id: taskId, p_eingemischt: eingemischt },
    'Could not hand out task')

/** Eine Abfrage fuer den ganzen Raum, alle paar Sekunden (kein Realtime). */
export const raumLive = (sessionId: string): Promise<RpcResult<RaumLive>> =>
  sessionRpc('coach_raum_live', { p_session_id: sessionId }, 'Could not load room')

export const kindDetail = (sessionId: string, studentId: string): Promise<RpcResult<KindDetail>> =>
  sessionRpc('coach_kind_detail', { p_session_id: sessionId, p_student_id: studentId }, 'Could not load child')

export const raumSignale = (sessionId: string): Promise<RpcResult<RaumSignal[]>> =>
  sessionRpc('raum_signale', { p_session_id: sessionId }, 'Could not load signals')

export const signalErledigen = (sessionId: string, studentId: string, art: SignalArt): Promise<RpcResult<null>> =>
  sessionRpc('signal_erledigen', { p_session_id: sessionId, p_student_id: studentId, p_art: art },
    'Could not resolve signal')

/** Ab Stufe 3 ist das Fehlbild Pflicht (sonst 22023). */
export const eingriffNotieren = (
  sessionId: string,
  studentId: string,
  stufe: EingriffStufe,
  fehlbildSlug: string | null = null,
): Promise<RpcResult<null>> =>
  sessionRpc('eingriff_notieren',
    { p_session_id: sessionId, p_student_id: studentId, p_stufe: stufe, p_fehlbild_slug: fehlbildSlug },
    'Could not record intervention')

export const pfadEntscheiden = (
  sessionId: string,
  studentId: string,
  entscheidung: PfadEntscheidung,
  skillKey: string | null = null,
): Promise<RpcResult<null>> =>
  sessionRpc('pfad_entscheiden',
    { p_session_id: sessionId, p_student_id: studentId, p_entscheidung: entscheidung, p_skill_key: skillKey },
    'Could not record path decision')

/** Nicht gesetzte Felder bleiben unveraendert. */
export const abschlussSetzen = (
  sessionId: string,
  studentId: string,
  e: AbschlussEingabe,
): Promise<RpcResult<null>> =>
  sessionRpc('abschluss_setzen', {
    p_session_id: sessionId,
    p_student_id: studentId,
    p_satz_text: e.satzText ?? null,
    p_satz_gesagt: e.satzGesagt ?? null,
    p_notiz: e.notiz ?? null,
    p_flag_eltern: e.flagEltern ?? null,
    p_flag_pfad: e.flagPfad ?? null,
    p_exit_ergebnis: e.exitErgebnis ?? null,
  }, 'Could not save check-out')

export const questTerminSetzenCoach = (
  sessionId: string,
  studentId: string,
  terminIso: string,
): Promise<RpcResult<null>> =>
  sessionRpc('quest_termin_setzen', { p_session_id: sessionId, p_student_id: studentId, p_termin: terminIso },
    'Could not save quest date')

export const sessionAbschliessen = (sessionId: string): Promise<RpcResult<SessionAbschlussErgebnis>> =>
  sessionRpc('session_abschliessen', { p_session_id: sessionId }, 'Could not close session')
