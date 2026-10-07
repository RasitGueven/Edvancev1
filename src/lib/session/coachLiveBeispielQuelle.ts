// NUR FUER TESTS: die Beispiel-Datenquelle aus C1 (fuenf Kinder des Dummys in allen sechs
// Zeitpunkten), gleiche Schnittstelle wie coachLive.ts. Die Seitentests mocken coachLive.ts
// hiermit; die App benutzt sie nicht (Auftrag C2 Punkt 4). Aktionen aendern nur den lokalen Zustand.

import type { CoachLiveRaum, LiveZeitpunkt } from '@/types/coachLive'
import type { EingriffStufe, PfadEntscheidung, SessionFall, SignalArt } from '@/types/sessionLive'
import type { LernpfadStandCoach } from '@/types/lernpfad'
import type { Thema } from '@/types/themen'
import type { SupabaseResult } from '@/types/ui'
import { BEISPIEL_KATALOG, BEISPIEL_ZEIT } from './coachLiveBeispiel'
import { baueBeispielRaum, neuerBeispielZustand, type BeispielZustand } from './coachLiveBeispielBau'
import type { CoachLiveFehler } from './coachLiveFehler'
import { abschlussMoeglich, eingriffAbsendbar, vertagenAbsendbar } from './coachLiveLogik'

/** Abfrage-Takt der Live-Sicht (Entscheidung 17: Lesefunktion fuer den Raum, kein Realtime). */
export const LIVE_ABFRAGE_MS = 4000


// ── Beispielmodus ─────────────────────────────────────────────────────────

const zustaende = new Map<string, BeispielZustand>()

function zustand(sessionId: string): BeispielZustand {
  let z = zustaende.get(sessionId)
  if (!z) {
    z = neuerBeispielZustand()
    zustaende.set(sessionId, z)
  }
  return z
}

const ok = (): SupabaseResult<null> => ({ data: null, error: null })
const fehler = (code: CoachLiveFehler): SupabaseResult<null> => ({ data: null, error: code })
const jetzt = (z: BeispielZustand): string => BEISPIEL_ZEIT[z.zeitpunkt]
const VON = 'Sara'

/** Nur fuer Tests: Beispielzustand verwerfen. */
export function beispielZuruecksetzen(): void {
  zustaende.clear()
}

/** Nur im Beispielmodus: Zeitpunkt der Beispielleiste umschalten. */
export async function beispielZeitpunktSetzen(sessionId: string, z: LiveZeitpunkt): Promise<SupabaseResult<null>> {
  zustand(sessionId).zeitpunkt = z
  return ok()
}

// ── Lesen ─────────────────────────────────────────────────────────────────

/** Der ganze Raum in einer Abfrage (C2: coach_raum_live + coach_kind_detail + A1/E1/Q1). */
export async function ladeRaumLive(sessionId: string, _kindId: string | null = null): Promise<SupabaseResult<CoachLiveRaum>> {
  return { data: baueBeispielRaum(sessionId, zustand(sessionId)), error: null }
}

/** Themenkatalog fuer die Themensuche im Check-in (C2: listThemen aus lib/supabase/themen). */
export async function themenKatalog(): Promise<SupabaseResult<Thema[]>> {
  return { data: BEISPIEL_KATALOG, error: null }
}

// ── Aktionen (Namen wie in R1 sessionCoach.ts und A1 lernpfad.ts) ─────────

export async function sessionStarten(sessionId: string): Promise<SupabaseResult<null>> {
  zustand(sessionId).zeitpunkt = 'checkin'
  return ok()
}

export async function tabletZuweisen(sessionId: string, studentId: string, tabletNr: number): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  const raum = baueBeispielRaum(sessionId, z)
  if (raum.kinder.some((k) => k.id !== studentId && k.tablet === tabletNr)) return fehler('tabletBelegt')
  z.tablets[studentId] = tabletNr
  z.nichtErschienen = z.nichtErschienen.filter((id) => id !== studentId)
  return ok()
}

export async function tabletLoesen(sessionId: string, studentId: string): Promise<SupabaseResult<null>> {
  zustand(sessionId).tablets[studentId] = null
  return ok()
}

/** Fall waehlen und/oder ein neues Schulthema setzen (altes wird „behandelt“). */
export async function checkinCoachSetzen(
  sessionId: string,
  studentId: string,
  fall: SessionFall | null,
  themaKey: string | null = null,
): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (fall) z.fall[studentId] = fall
  if (themaKey) z.thema[studentId] = themaKey
  return ok()
}

export async function signalErledigen(sessionId: string, studentId: string, art: SignalArt): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  z.erledigt = [...z.erledigt.filter((e) => e !== `${studentId}:${art}`), `${studentId}:${art}`]
  return ok()
}

/** Ab Stufe 3 Fehlbild Pflicht; Stufe 4 setzt den Pfad sofort tiefer (Entscheidung 14). */
export async function eingriffNotieren(
  sessionId: string,
  studentId: string,
  stufe: EingriffStufe,
  fehlbildSlug: string | null = null,
): Promise<SupabaseResult<null>> {
  if (!eingriffAbsendbar(stufe, fehlbildSlug)) return fehler('fehlbildPflicht')
  const z = zustand(sessionId)
  z.eingriffe = [...z.eingriffe, { kindId: studentId, stufe, zeit: jetzt(z) }]
  if (stufe === 4) z.pfad[studentId] = { art: 'tiefer', zeit: jetzt(z) }
  return ok()
}

export async function pfadEntscheiden(
  sessionId: string,
  studentId: string,
  entscheidung: PfadEntscheidung | null,
): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (entscheidung === null) delete z.pfad[studentId]
  else z.pfad[studentId] = { art: entscheidung, zeit: jetzt(z) }
  return ok()
}

/** Mastery-Entscheidung des Coaches; „vertagt“ braucht einen Grund (A1). */
export async function masteryEntscheiden(args: {
  sessionId: string
  studentId: string
  skillKey: string
  entscheidung: LernpfadStandCoach
  grund: string | null
}): Promise<SupabaseResult<null>> {
  if (args.entscheidung === 'vertagt' && !vertagenAbsendbar(args.grund)) return fehler('grundPflicht')
  const z = zustand(args.sessionId)
  z.mastery[args.studentId] = { art: args.entscheidung, grund: args.grund, zeit: jetzt(z), von: VON }
  return ok()
}

/** Check-out je Kind; nicht gesetzte Felder bleiben unveraendert (R1 abschluss_setzen). */
export async function abschlussSetzen(
  sessionId: string,
  studentId: string,
  e: { satzText?: string; satzGesagt?: boolean; notiz?: string; flagEltern?: boolean; flagPfad?: boolean },
): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (e.satzText !== undefined) z.satz[studentId] = e.satzText
  if (e.satzGesagt !== undefined) {
    z.gesagt = z.gesagt.filter((id) => id !== studentId)
    if (e.satzGesagt) z.gesagt.push(studentId)
  }
  if (e.notiz !== undefined) z.notiz[studentId] = e.notiz
  if (e.flagEltern !== undefined || e.flagPfad !== undefined) {
    const f = z.flags[studentId] ?? { eltern: false, pfad: false }
    z.flags[studentId] = { eltern: e.flagEltern ?? f.eltern, pfad: e.flagPfad ?? f.pfad }
  }
  return ok()
}

export async function questTerminSetzenCoach(sessionId: string, studentId: string, terminIso: string): Promise<SupabaseResult<null>> {
  zustand(sessionId).questA[studentId] = terminIso
  return ok()
}

/**
 * Kein eigener Server-Aufruf: R1 setzt beim Abschluss jedes Kind ohne Tablet auf
 * „nicht erschienen“ (offene-punkte-r1 Nr. 6). Die Bestaetigung bleibt im Client.
 */
export async function nichtErschienenBestaetigen(sessionId: string, studentId: string): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (!z.nichtErschienen.includes(studentId)) z.nichtErschienen.push(studentId)
  return ok()
}

export async function sessionAbschliessen(sessionId: string): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (z.abgeschlossen) return fehler('abgeschlossen')
  if (!abschlussMoeglich(baueBeispielRaum(sessionId, z).kinder)) return fehler('ohneTabletOffen')
  z.abgeschlossen = jetzt(z)
  return ok()
}

export async function pruefungAufsTablet(sessionId: string, studentId: string, _skillKey: string): Promise<SupabaseResult<null>> {
  zustand(sessionId).pruefung[studentId] = true
  return ok()
}

export async function pruefungVomTablet(sessionId: string, studentId: string): Promise<SupabaseResult<null>> {
  zustand(sessionId).pruefung[studentId] = false
  return ok()
}
