// Attrappe für @/lib/supabase/pruefung in der Vorschau „Lauf mit Prüfziel“ (IU-1b). Die Aufgabe ist eine feste
// Zahl-Aufgabe mit Kopf aus dem Board; „Passt“ setzt den Board-Status im Speicher.
import type { PruefAufgabe, PruefResult } from '@/types'
import { BOARD, ENTSCHIEDEN } from './speicher'

const ok = <T,>(data: T): Promise<PruefResult<T>> => Promise.resolve({ data, error: null })
const sicht = {
  werte: [{ teil: null, werte: [{ wert: '12', schreibweisen: ['12'] }] }],
  mc: null,
  regel: { art: 'wert' as const, mitte: null, toleranz: null, einheit_pflicht: false, einheit: null, einheit_am_feld: false },
  fehler: [], weitere_hinweise: [], hinweise: [], skill_key: 'x', afb: 'I' as const, flach_regel: true, ohne_erkennung: false,
}

export const rufe = (): Promise<PruefResult<null>> => ok(null)
export const alsFehler = (e: unknown) => ({ code: null, hint: null, message: String(e) })
export const getPruefBoard = () => ok(BOARD)
export const getPruefSoll = () => ok([])
export const getAufgabenTypen = () => ok({})
export const getFehlbilder = () => ok([])
export const getMeineDauer = () => ok(null)
export const getPruefAdminListe = () => ok([])
export const getPruefEinstellungen = () => ok({ hilfsmittel: 'Stift und Zettel', nur_pilot: false, grund_pflicht: false })
export const setPruefEinstellungen = () => ok(true)
export function getPruefAufgabe(taskId: string): Promise<PruefResult<PruefAufgabe>> {
  const z = BOARD.find((b) => b.task_id === taskId)
  return ok({
    task_id: taskId,
    kopf: { kurztitel: z?.kurztitel ?? taskId, stufe: z?.stufe ?? 'zweite', thema_key: z?.thema_key ?? '', thema_label: z?.thema_label ?? '', hilfsmittel: 'Stift und Zettel' },
    aufgabe: { input_type: 'NUMERIC', unit: null, status: 'draft', lena_status: z?.lena_status ?? 'offen', taschenrechner: false, pruef_version: 1, ausschluss: null, pilot: false, team_beanstandet: false, parts: [], optionen: [], bild_vorhanden: false },
    ...sicht, skill_key: z?.skill_key ?? 'x',
    loesungsweg: null,
    fertigkeit: { key: z?.skill_key ?? 'x', label: z?.skill_label ?? '', thema_key: z?.thema_key ?? '', thema_label: z?.thema_label ?? '', stufe: z?.stufe ?? 'zweite', voraussetzungen: [] },
    fertigkeit_optionen: [{ key: z?.skill_key ?? 'x', label: z?.skill_label ?? '', gruppe: 'thema' }],
    afb_sicher: 'hoch', ausgang: { ...sicht, skill_key: z?.skill_key ?? 'x' }, aenderungen: [], letzte_pruefung: null, auffaelligkeiten: [],
  } as unknown as PruefAufgabe)
}
export function pruefEntscheiden(args: { taskId: string; entscheidung: string }) {
  const z = BOARD.find((b) => b.task_id === args.taskId)
  if (z) z.lena_status = args.entscheidung === 'passt' ? 'passt' : 'offen'
  ENTSCHIEDEN.push(args.taskId)
  return ok({ pruef_version: 2, lena_status: z?.lena_status ?? 'passt' })
}
export const pruefRueckgaengig = () => ok({ pruef_version: 3, lena_status: 'offen' })
export const pruefSpeichern = () => ok({ pruef_version: 2, auffaelligkeiten: [], aenderungen: [] })
export const pruefWertungTesten = () => ok([])
export const pruefRueckfrageKlaeren = () => ok(null)
export const pruefTaschenrechnerSetzen = () => ok({ pruef_version: 2 })
