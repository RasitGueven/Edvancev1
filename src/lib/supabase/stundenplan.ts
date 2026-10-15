// Slots S1: Sofort-Session und Buchbarkeit mit Grund (nur Admin). Alles geht über RPCs; die Rolle prüft
// die Datenbank. Im Fehlerfall gehen SQLSTATE (code), Hinweis (hint) und Detail (bei einem nicht buchbaren
// Kind dessen student_id) mit; die Oberfläche übersetzt sie über src/lib/slots/fehler.ts.
// p_jetzt (nur für Tests) wird nie übergeben. Datenvertrag: docs/api/DATENVERTRAG.md, Abschnitt 12.

import { sessionRpc as rpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type {
  KindBuchbar, SessionLeitung, SofortSessionErgebnis, StundenplanWoche,
} from '@/types/stundenplan'

/** Alle Kinder (ohne vorläufige) mit Grund für das Datum; sessionId prüft zusätzlich die Art der Session. */
export function ladeKinderBuchbar(datum: string, sessionId: string | null = null): Promise<RpcResult<KindBuchbar[]>> {
  return rpc('kinder_buchbar', { p_datum: datum, p_session_id: sessionId }, 'Kinder konnten nicht geladen werden')
}

/** Session ab jetzt (auf die Minute), auch Wochenende, Ferien, Feiertag. Nur Testkinder → Testlauf. */
export function sofortSessionAnlegen(
  coachId: string, raumId: string, studentIds: string[],
): Promise<RpcResult<SofortSessionErgebnis>> {
  return rpc('sofort_session_anlegen', { p_coach_id: coachId, p_raum_id: raumId, p_student_ids: studentIds },
    'Session konnte nicht angelegt werden')
}

/** Mögliche Leitung einer Einzel-Session: Coaches und Admins. */
export function ladeSessionLeitung(): Promise<RpcResult<SessionLeitung[]>> {
  return rpc('session_leitung', {}, 'Leitung konnte nicht geladen werden')
}

/** Einzel-Sessions Mo–So; montag darf ein beliebiger Tag der Woche sein. */
export function ladeStundenplanWoche(montag: string): Promise<RpcResult<StundenplanWoche>> {
  return rpc('stundenplan_woche', { p_montag: montag }, 'Stundenplan konnte nicht geladen werden')
}
