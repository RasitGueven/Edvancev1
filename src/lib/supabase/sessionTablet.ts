// Session-Rahmen R1, Tablet-Seite (Kiosk-Geraet). Das Kind ergibt sich auf dem
// Server aus der Tablet-Zuweisung; ein Aufruf ohne aktiven Platz bekommt 42501.
// Antworten liefern nur Ergebnis und Fehlbild-Klartext, nie die Loesung.

import { sessionRpc } from '@/lib/supabase/sessionRpc'
import type {
  AntwortRueckmeldung,
  CheckinKind,
  HinweisAntwort,
  SupabaseResult,
  TabletStand,
} from '@/types'

export const tabletStand = (): Promise<SupabaseResult<TabletStand>> =>
  sessionRpc('tablet_stand', {}, 'Could not load tablet state')

export const checkinKindSpeichern = (sessionId: string, c: CheckinKind): Promise<SupabaseResult<{ fertig: boolean }>> =>
  sessionRpc('checkin_kind_speichern', {
    p_session_id: sessionId,
    p_stimmung: c.stimmung,
    p_klassenarbeit_datum: c.klassenarbeitDatum,
    p_klassenarbeit_thema_key: c.klassenarbeitThemaKey,
    p_thema_antwort: c.themaAntwort,
    p_thema_stichwort: c.themaStichwort ?? null,
  }, 'Could not save check-in')

export const antwortAbgeben = (
  sessionId: string,
  taskId: string,
  teil: number | null,
  eingabe: unknown,
  dauerMs: number | null = null,
): Promise<SupabaseResult<AntwortRueckmeldung>> =>
  sessionRpc('antwort_abgeben',
    { p_session_id: sessionId, p_task_id: taskId, p_teil: teil, p_eingabe: eingabe, p_dauer_ms: dauerMs },
    'Could not submit answer')

export const hinweisAbrufen = (sessionId: string, taskId: string, stufe: number): Promise<SupabaseResult<HinweisAntwort>> =>
  sessionRpc('hinweis_abrufen', { p_session_id: sessionId, p_task_id: taskId, p_stufe: stufe }, 'Could not load hint')

export const questTerminSetzen = (sessionId: string, terminIso: string): Promise<SupabaseResult<null>> =>
  sessionRpc('quest_termin_setzen', { p_session_id: sessionId, p_student_id: null, p_termin: terminIso },
    'Could not save quest date')
