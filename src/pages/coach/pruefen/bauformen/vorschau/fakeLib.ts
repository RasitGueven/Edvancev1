// Attrappe für src/lib/supabase/bauformPruefung.ts in der Vorschau „Session-Aufgaben prüfen“ (SP-1). Daten aus
// fixtures.json (tools/sp1-vorschau-daten.sh, read-only aus Prod, keine Personendaten); Entscheidungen ändern nur den
// Zustand im Speicher. Gleiche Exporte wie das Original.
import type {
  AuffaelligZeile, BauformDetail, BauformPlanZeile, PlanKind, PrueffrageZeile,
} from '@/types/bauformPruefung'
import daten from './fixtures.json'

export type BauformFehler = { code: string | null; hint: string | null; message: string }
export type BauformResult<T> = { data: T | null; error: BauformFehler | null }
export type BauformKommentarEingabe = {
  anker: 'grundgeruest' | 'stufen' | 'fehlbilder' | 'beispiel'; task_id?: string; gruende: string[]; text: string | null
}

type Fixtures = { plan: BauformPlanZeile[]; detail: Record<string, { s0: BauformDetail; s1: BauformDetail }> }
const F = daten as unknown as Fixtures
const plan: BauformPlanZeile[] = F.plan.map((z) => ({ ...z }))
const ok = async <T,>(data: T): Promise<BauformResult<T>> => ({ data, error: null })
const fehlt = async <T,>(): Promise<BauformResult<T>> => ({ data: null, error: { code: 'P0002', hint: null, message: 'nicht in den Fixtures' } })

export const getBauformListe = (): Promise<BauformResult<BauformPlanZeile[]>> => ok(plan)
export const getBauformPlan = (): Promise<BauformResult<BauformPlanZeile[]>> => ok(plan.map((z) => ({ ...z })))
export const getPlanKinder = (): Promise<BauformResult<PlanKind[]>> => ok([])
export const getAuffaellig = (): Promise<BauformResult<AuffaelligZeile[]>> => ok([])
export const getPrueffragen = (): Promise<BauformResult<PrueffrageZeile[]>> => ok([])

export function getBauformDetail(bauformId: string, seed = 0, behalten: string[] = []): Promise<BauformResult<BauformDetail>> {
  const d = F.detail[bauformId]
  if (!d) return fehlt()
  const zeile = plan.find((z) => z.bauform_id === bauformId)
  const basis: BauformDetail = { ...d.s0, status: zeile?.status ?? d.s0.status }
  if (seed === 0) return ok(basis)
  const quelle = seed % 2 === 1 ? d.s1 : d.s0
  const alle = [...d.s0.beispiele, ...d.s1.beispiele]
  const fest = behalten.map((id) => alle.find((b) => b.task_id === id)).filter((b): b is NonNullable<typeof b> => !!b)
  const rest = quelle.beispiele.filter((b) => !fest.some((x) => x.task_id === b.task_id))
  return ok({ ...basis, beispiele: [...fest, ...rest].slice(0, 6).sort((a, b) => a.stufe - b.stufe) })
}

export function bauformPruefungSenden(bauformId: string, version: number, kommentare: BauformKommentarEingabe[]):
  Promise<BauformResult<{ status: string; version: number; pruefung_id: string; kommentare: number }>> {
  const z = plan.find((x) => x.bauform_id === bauformId)
  if (!z) return fehlt()
  z.status = kommentare.length ? 'rueckfrage' : 'zur_freigabe'
  return ok({ status: z.status, version, pruefung_id: 'vorschau', kommentare: kommentare.length })
}

export const bauformPruefen = (bauformId: string, version: number, entscheidung: string) =>
  bauformPruefungSenden(bauformId, version, entscheidung === 'passt' ? [] : [{ anker: 'grundgeruest', gruende: [], text: entscheidung }])
export const bauformFreigeben = (): Promise<BauformResult<number>> => ok(0)
export const aufgabeReaktivieren = (): Promise<BauformResult<null>> => ok(null)
export const bauformZurUeberarbeitung = (): Promise<BauformResult<null>> => ok(null)
export const bauformReaktivieren = (): Promise<BauformResult<string>> => ok('')
export const prueffrageEntscheiden = (): Promise<BauformResult<string>> => ok('')
export const aufgabeMelden = (): Promise<BauformResult<null>> => ok(null)
