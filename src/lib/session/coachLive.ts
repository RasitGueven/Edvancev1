// Session-Rahmen C2: die EINZIGE Datenquelle der Coach-Live-Sicht, jetzt mit echten Daten.
//
// Lesen: coach_raum_live fuer den Raum alle LIVE_ABFRAGE_MS; coach_kind_detail (mit Ziel,
// Pruefgespraech und Lernpfad-Belegen) nur fuer das Kind mit offener Schublade (offene-punkte-c1
// Nr. 9); session_briefing und satz_vorschlaege seltener (Zwischenspeicher). Die Abbildung auf das
// Ansichtsmodell steht in coachLiveAbbildung.ts, die Fehlerabbildung in coachLiveFehler.ts.
// Handeln: die R1-, A1- und A2b-Funktionen. Jede Aktion liefert null oder einen Fehler-Code.
// Die Beispieldaten aus C1 gibt es nur noch in Tests (coachLiveBeispielQuelle.ts).

import { listLernpfad, masteryEntscheiden as masteryEntscheidenRpc, skillPruefungen, zielFertigkeiten } from '@/lib/supabase/lernpfad'
import * as rpc from '@/lib/supabase/sessionCoach'
import { satzVorschlaege, sessionBriefing } from '@/lib/supabase/sessionC2'
import { pruefungAufsTablet as aufsTablet, pruefungVomTablet as vomTablet } from '@/lib/supabase/sessionPruefung'
import { listThemen } from '@/lib/supabase/themen'
import type { CoachLiveRaum } from '@/types/coachLive'
import type { LernpfadStandCoach } from '@/types/lernpfad'
import type { BriefingKind, SatzVorschlag } from '@/types/sessionC2'
import type { AbschlussEingabe, EingriffStufe, PfadEntscheidung, RaumLive, SessionFall, SignalArt } from '@/types/sessionLive'
import type { Thema } from '@/types/themen'
import type { SupabaseResult } from '@/types/ui'
import { raumAus, type LiveZusatz } from './coachLiveAbbildung'
import { alsAktion, fehlerCode, type CoachLiveFehler } from './coachLiveFehler'
import { abschlussMoeglich, eingriffAbsendbar, vertagenAbsendbar } from './coachLiveLogik'
import { zeitpunktAus } from './coachLiveTeile'

export type { CoachLiveFehler }

/** Abfrage-Takt der Live-Sicht (Entscheidung 17: Lesefunktion fuer den Raum, kein Realtime). */
export const LIVE_ABFRAGE_MS = 4000
/** Briefing und Satzvorschlaege aendern sich selten: hoechstens einmal je Minute neu laden. */
const ZWISCHENSPEICHER_MS = 60_000

type Gespeichert<T> = { am: number; wert: T }
type SessionZustand = {
  nichtErschienen: Set<string>
  pfadGeoeffnet: Record<string, string>
  briefing: Gespeichert<BriefingKind[]> | null
  satz: Record<string, Gespeichert<SatzVorschlag[]>>
  letzterRaum: CoachLiveRaum | null
}

const zustaende = new Map<string, SessionZustand>()
let themenCache: Map<string, string> | null = null

function zustand(sessionId: string): SessionZustand {
  let z = zustaende.get(sessionId)
  if (!z) {
    z = { nichtErschienen: new Set(), pfadGeoeffnet: {}, briefing: null, satz: {}, letzterRaum: null }
    zustaende.set(sessionId, z)
  }
  return z
}

const frisch = <T>(g: Gespeichert<T> | null | undefined): boolean => !!g && Date.now() - g.am < ZWISCHENSPEICHER_MS
const ok = (): SupabaseResult<null> => ({ data: null, error: null })
const fehler = (code: CoachLiveFehler): SupabaseResult<null> => ({ data: null, error: code })

/** Nur fuer Tests: Zwischenspeicher und Client-Zustand verwerfen. */
export function liveZuruecksetzen(): void {
  zustaende.clear()
  themenCache = null
}

async function themenLabels(): Promise<Map<string, string>> {
  if (themenCache) return themenCache
  const res = await listThemen('mathematik')
  if (res.data) themenCache = new Map(res.data.map((t) => [t.thema_key, t.label]))
  return themenCache ?? new Map()
}

/** Schublade: Detail, Ziel der Stunde, Pruefgespraech und Belege nur fuer dieses Kind. */
async function ladeDetail(sessionId: string, raum: RaumLive, kindId: string): Promise<LiveZusatz['detail']> {
  const kind = raum.kinder.find((k) => k.student_id === kindId)
  if (!kind) return null
  const themaKey = kind.ziel_thema_key ?? kind.schulthema_key
  const skill = kind.mastery_kandidat?.skill_key ?? kind.mastery_heute.at(-1)?.skill_key ?? null
  const [detail, ziel, pruefung, lernpfad] = await Promise.all([
    rpc.kindDetail(sessionId, kindId),
    themaKey ? zielFertigkeiten(kindId, themaKey) : Promise.resolve({ data: [], error: null }),
    skill ? skillPruefungen(skill) : Promise.resolve({ data: [], error: null }),
    skill ? listLernpfad(kindId) : Promise.resolve({ data: [], error: null }),
  ])
  if (!detail.data) return null
  return {
    kindId,
    detail: detail.data,
    ziel: ziel.data ?? [],
    // Wie das Tablet: die erste freigegebene Pruefung des Skills (offene-punkte-a2b Nr. 6).
    pruefung: pruefung.data?.[0] ?? null,
    lernpfad: lernpfad.data?.find((l) => l.skill_key === skill) ?? null,
  }
}

async function ladeSaetze(sessionId: string, z: SessionZustand, raum: RaumLive): Promise<Record<string, SatzVorschlag[]>> {
  const kinder = raum.kinder.filter((k) => k.tablet_nr !== null && !frisch(z.satz[k.student_id]))
  await Promise.all(
    kinder.map(async (k) => {
      const res = await satzVorschlaege(sessionId, k.student_id)
      if (res.data) z.satz[k.student_id] = { am: Date.now(), wert: res.data }
    }),
  )
  return Object.fromEntries(Object.entries(z.satz).map(([id, g]) => [id, g.wert]))
}

/** Der ganze Raum; `kindId` ist das Kind mit offener Schublade (sonst null). */
export async function ladeRaumLive(sessionId: string, kindId: string | null = null): Promise<SupabaseResult<CoachLiveRaum>> {
  const z = zustand(sessionId)
  const res = await rpc.raumLive(sessionId)
  if (res.error !== null) return { data: null, error: fehlerCode(res) }
  if (!res.data?.session) return { data: null, error: 'allgemein' }
  const raum = res.data
  const zeitpunkt = zeitpunktAus(raum.session, raum.stand)

  const [detail, themen] = await Promise.all([kindId ? ladeDetail(sessionId, raum, kindId) : Promise.resolve(null), themenLabels()])
  const bisher = z.briefing
  if (!frisch(bisher) && (zeitpunkt === 'vorher' || bisher === null)) {
    const b = await sessionBriefing(sessionId)
    z.briefing = { am: Date.now(), wert: b.data ?? bisher?.wert ?? [] }
  }
  const satz = zeitpunkt === 'checkout' || zeitpunkt === 'danach' ? await ladeSaetze(sessionId, z, raum) : {}

  const ansicht = raumAus(raum, {
    detail, briefing: z.briefing?.wert ?? [], satz, themen, nichtErschienen: z.nichtErschienen, pfadGeoeffnet: z.pfadGeoeffnet,
  })
  z.letzterRaum = ansicht
  return { data: ansicht, error: null }
}

/** Themenkatalog fuer die Themensuche im Check-in. */
export async function themenKatalog(): Promise<SupabaseResult<Thema[]>> {
  const res = await listThemen('mathematik')
  return res.data ? { data: res.data, error: null } : { data: null, error: 'allgemein' }
}

// ── Aktionen ──────────────────────────────────────────────────────────────

export const sessionStarten = async (sessionId: string): Promise<SupabaseResult<null>> =>
  alsAktion(await rpc.sessionStarten(sessionId))

export const tabletZuweisen = async (sessionId: string, studentId: string, tabletNr: number): Promise<SupabaseResult<null>> => {
  const res = alsAktion(await rpc.tabletZuweisen(sessionId, studentId, tabletNr))
  if (res.error === null) zustand(sessionId).nichtErschienen.delete(studentId)
  return res
}

export const tabletLoesen = async (sessionId: string, studentId: string): Promise<SupabaseResult<null>> =>
  alsAktion(await rpc.tabletLoesen(sessionId, studentId))

/** Fall waehlen und/oder ein neues Schulthema setzen (altes wird „behandelt“). */
export const checkinCoachSetzen = async (
  sessionId: string,
  studentId: string,
  fall: SessionFall | null,
  themaKey: string | null = null,
): Promise<SupabaseResult<null>> => alsAktion(await rpc.checkinCoachSetzen(sessionId, studentId, fall, themaKey))

export const signalErledigen = async (sessionId: string, studentId: string, art: SignalArt): Promise<SupabaseResult<null>> =>
  alsAktion(await rpc.signalErledigen(sessionId, studentId, art))

/** Ab Stufe 3 Fehlbild Pflicht; Stufe 4 setzt den Pfad sofort tiefer (Entscheidung 14). */
export async function eingriffNotieren(
  sessionId: string,
  studentId: string,
  stufe: EingriffStufe,
  fehlbildSlug: string | null = null,
): Promise<SupabaseResult<null>> {
  if (!eingriffAbsendbar(stufe, fehlbildSlug)) return fehler('fehlbildPflicht')
  return alsAktion(await rpc.eingriffNotieren(sessionId, studentId, stufe, fehlbildSlug), { '22023': 'fehlbildPflicht' })
}

/** null oeffnet die Entscheidung wieder (nur Ansicht); der Server kennt kein Zuruecknehmen. */
export async function pfadEntscheiden(
  sessionId: string,
  studentId: string,
  entscheidung: PfadEntscheidung | null,
): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (entscheidung === null) {
    z.pfadGeoeffnet[studentId] = new Date().toISOString()
    return ok()
  }
  const res = alsAktion(await rpc.pfadEntscheiden(sessionId, studentId, entscheidung))
  if (res.error === null) delete z.pfadGeoeffnet[studentId]
  return res
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
  delete z.satz[args.studentId]
  return alsAktion(await masteryEntscheidenRpc(args), { '22023': 'grundPflicht' })
}

/** Check-out je Kind; nicht gesetzte Felder bleiben unveraendert (R1 abschluss_setzen). */
export const abschlussSetzen = async (sessionId: string, studentId: string, e: AbschlussEingabe): Promise<SupabaseResult<null>> =>
  alsAktion(await rpc.abschlussSetzen(sessionId, studentId, e), { P0001: 'abgeschlossen' })

export const questTerminSetzenCoach = async (sessionId: string, studentId: string, terminIso: string): Promise<SupabaseResult<null>> =>
  alsAktion(await rpc.questTerminSetzenCoach(sessionId, studentId, terminIso))

/** A2b: Pruefrage aufs Tablet des Kindes legen bzw. wieder wegnehmen (Entscheidung 31). */
export const pruefungAufsTablet = async (sessionId: string, studentId: string, skillKey: string): Promise<SupabaseResult<null>> =>
  alsAktion(await aufsTablet(sessionId, studentId, skillKey))

export const pruefungVomTablet = async (sessionId: string, studentId: string): Promise<SupabaseResult<null>> =>
  alsAktion(await vomTablet(sessionId, studentId))

/**
 * Kein eigener Server-Aufruf: R1 setzt beim Abschluss jedes Kind ohne Tablet auf
 * „nicht erschienen“ (offene-punkte-r1 Nr. 6). Die Bestaetigung bleibt im Client.
 */
export async function nichtErschienenBestaetigen(sessionId: string, studentId: string): Promise<SupabaseResult<null>> {
  zustand(sessionId).nichtErschienen.add(studentId)
  return ok()
}

export async function sessionAbschliessen(sessionId: string): Promise<SupabaseResult<null>> {
  const z = zustand(sessionId)
  if (z.letzterRaum?.session.abgeschlossen) return fehler('abgeschlossen')
  if (z.letzterRaum && !abschlussMoeglich(z.letzterRaum.kinder)) return fehler('ohneTabletOffen')
  return alsAktion(await rpc.sessionAbschliessen(sessionId), { P0001: 'abgeschlossen' })
}
