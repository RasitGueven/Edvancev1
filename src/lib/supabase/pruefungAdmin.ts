import { supabase } from '@/lib/supabase/client'
import { alsFehler, rufe, type RpcFehler } from '@/lib/supabase/pruefung'
import type {
  AdminProtokollZeile,
  AdminPruefKontext,
  LenaEntscheidung,
  PruefResult,
  SammelAktion,
  SammelErgebnis,
  SammelWerte,
  TeamBeanstandung,
} from '@/types'

/**
 * Admin-Pruefansicht: Aufrufe der Admin-Funktionen (Migrationen 20261005131220, 20261005131306) und das
 * Lesen von Lenas Ergebnis, Team-Beanstandung, Ausschluss von Hand und Admin-Protokoll fuer eine Aufgabe.
 *
 * Die Funktionen und Tabellen stehen noch nicht in database.ts — die Casts halten das sichtbar, bis die Typen
 * nach dem Einspielen neu generiert sind (Muster pruefung.ts). Fehler behalten SQLSTATE und HINT
 * (ED422 traegt den Schluessel fuer i18n, lib/pruefung/adminTexte.ts).
 */

type Antwort<T> = { data: T[] | null; error: RpcFehler | null }
interface Abfrage<T> extends PromiseLike<Antwort<T>> {
  select: (cols: string) => Abfrage<T>
  eq: (col: string, wert: string) => Abfrage<T>
  in: (col: string, werte: string[]) => Abfrage<T>
  order: (col: string, opts: { ascending: boolean }) => Abfrage<T>
  limit: (n: number) => Abfrage<T>
}
const aus = <T>(name: string): Abfrage<T> =>
  (supabase.from.bind(supabase) as unknown as (t: string) => Abfrage<T>)(name)

async function lies<T>(abfrage: Abfrage<T>): Promise<T[]> {
  const { data, error } = await abfrage
  if (error) throw error
  return data ?? []
}

// ── Einzelaktionen ──────────────────────────────────────────────────────────

/** Zurueck an Lena (G3): draft, Ausgangsfassung weg, Nachricht als "Antwort vom Team". */
export function pruefAnLena(taskId: string, nachricht?: string | null): Promise<PruefResult<{ status: string }>> {
  return rufe('pruef_an_lena', { p_task_id: taskId, p_nachricht: nachricht?.trim() || null })
}

/** Freigeben (G4): ready ueber task_status_set, mit Gate und Stempel. */
export function pruefAdminFreigeben(taskId: string): Promise<PruefResult<{ status: string }>> {
  return rufe('pruef_admin_freigeben', { p_task_id: taskId })
}

/** Freigabe zuruecknehmen (G4): ready → draft. */
export function pruefFreigabeZuruecknehmen(taskId: string): Promise<PruefResult<{ status: string }>> {
  return rufe('pruef_freigabe_zuruecknehmen', { p_task_id: taskId })
}

/** Kinder-Hinweise einer freigegebenen Aufgabe bestaetigen (L5): alle auf geprueft, protokolliert. */
export function hinweiseBestaetigen(taskId: string): Promise<PruefResult<{ status: string; aenderungen: unknown[] }>> {
  return rufe('hinweise_bestaetigen', { p_task_id: taskId })
}

/** Zurueckweisen (G5): beanstandet, je Grund eine task_reviews-Zeile. */
export function pruefAdminZurueckweisen(
  taskId: string,
  gruende: string[],
  notiz?: string | null,
): Promise<PruefResult<{ status: string }>> {
  return rufe('pruef_admin_zurueckweisen', { p_task_id: taskId, p_gruende: gruende, p_notiz: notiz?.trim() || null })
}

/** Sammelaktion (G7). Vorschau und Ausfuehrung sind derselbe Aufruf; die Vorschau schreibt nichts. */
export function pruefSammel(
  aktion: SammelAktion,
  taskIds: string[],
  werte: SammelWerte,
  nurVorschau: boolean,
): Promise<PruefResult<SammelErgebnis>> {
  return rufe('pruef_sammel', { p_aktion: aktion, p_task_ids: taskIds, p_werte: werte, p_nur_vorschau: nurVorschau })
}

/** Pilot an/aus fuer eine Aufgabe, ueber pruef_sammel mit einer ID (ersetzt setPruefPilot). */
export async function setzePilot(taskId: string, an: boolean): Promise<PruefResult<true>> {
  const res = await pruefSammel(an ? 'pilot_an' : 'pilot_aus', [taskId], {}, false)
  if (res.error) return { data: null, error: res.error }
  const weg = res.data?.ausgelassen[0]
  if (weg && weg.grund !== 'schon_im_pilot' && weg.grund !== 'nicht_im_pilot') {
    return { data: null, error: { code: 'ED422', hint: String(weg.grund), message: weg.text ?? String(weg.grund) } }
  }
  return { data: true, error: null }
}

// ── Lesen ───────────────────────────────────────────────────────────────────

type ReviewZeile = { kategorie: string; notiz: string | null; geprueft_von: string | null; geprueft_am: string }
type Profil = { id: string; full_name: string | null; email: string | null; role: string | null }

/**
 * Die juengste Beanstandung durch das Team: aufeinanderfolgende task_reviews-Zeilen desselben Admins
 * (oder eines Systemaufrufs) mit derselben Notiz — eine Zurueckweisung schreibt je Grund eine Zeile.
 */
export function teamBeanstandung(zeilen: ReviewZeile[], rolle: (id: string | null) => string | null): TeamBeanstandung | null {
  const erste = zeilen[0]
  if (!erste || !(erste.geprueft_von === null || rolle(erste.geprueft_von) === 'admin')) return null
  const gruppe: ReviewZeile[] = []
  for (const z of zeilen) {
    if (z.geprueft_von !== erste.geprueft_von || z.notiz !== erste.notiz) break
    gruppe.push(z)
  }
  return { gruende: [...gruppe].reverse().map((z) => z.kategorie), notiz: erste.notiz, von: erste.geprueft_von, am: erste.geprueft_am }
}

/** Lenas Ergebnis, Team-Beanstandung, Ausschluss von Hand, Freigabe und die letzten 20 Admin-Aktionen. */
export async function getAdminPruefKontext(taskId: string): Promise<PruefResult<AdminPruefKontext>> {
  try {
    const [pruefungen, reviews, hand, protokoll, task] = await Promise.all([
      lies(aus<LenaEntscheidung>('task_pruefungen')
        .select('entscheidung,gruende,notiz,aenderungen,aenderung_grund,dauer_sek,geprueft_von,geprueft_am,antwort,beantwortet_von,beantwortet_am')
        .eq('task_id', taskId).order('geprueft_am', { ascending: false }).limit(1)),
      lies(aus<ReviewZeile>('task_reviews').select('kategorie,notiz,geprueft_von,geprueft_am')
        .eq('task_id', taskId).order('geprueft_am', { ascending: false }).limit(20)),
      lies(aus<{ grund: string; von: string | null; am: string }>('task_pruef_ausschluss').select('grund,von,am')
        .eq('task_id', taskId).limit(1)),
      lies(aus<AdminProtokollZeile>('task_admin_protokoll').select('id,aktion,aenderungen,grund,sammel,von,am')
        .eq('task_id', taskId).order('am', { ascending: false }).limit(20)),
      lies(aus<{ reviewed_by: string | null; reviewed_at: string | null }>('tasks').select('reviewed_by,reviewed_at')
        .eq('id', taskId).limit(1)),
    ])
    const lena = pruefungen[0] ?? null
    const ids = [lena?.geprueft_von, lena?.beantwortet_von, hand[0]?.von, task[0]?.reviewed_by,
      ...reviews.map((r) => r.geprueft_von), ...protokoll.map((p) => p.von)].filter((x): x is string => !!x)
    const profile = ids.length
      ? await lies(aus<Profil>('profiles').select('id,full_name,email,role').in('id', [...new Set(ids)]))
      : []
    const name = (id: string | null | undefined): string | null => {
      const p = profile.find((x) => x.id === id)
      return p ? p.full_name || p.email : null
    }
    const team = teamBeanstandung(reviews, (id) => profile.find((x) => x.id === id)?.role ?? null)
    return {
      data: {
        lena: lena ? { ...lena, geprueft_von: name(lena.geprueft_von), beantwortet_von: name(lena.beantwortet_von) } : null,
        team: team ? { ...team, von: name(team.von) } : null,
        hand: hand[0] ? { ...hand[0], von: name(hand[0].von) } : null,
        protokoll: protokoll.map((p) => ({ ...p, von: name(p.von) })),
        freigabe: task[0]?.reviewed_at ? { von: name(task[0].reviewed_by), am: task[0].reviewed_at } : null,
      },
      error: null,
    }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

export type Fertigkeitsgraph = {
  skills: { skill_key: string; label: string; fundament_tiefe: number | null }[]
  kanten: { skill_key: string; voraussetzt_skill_key: string }[]
}

/** Fertigkeiten und Voraussetzungskanten fuer die Auswahl „Fertigkeit ändern“ (Sammelaktion). */
export async function getFertigkeitsgraph(): Promise<PruefResult<Fertigkeitsgraph>> {
  try {
    const [skills, kanten] = await Promise.all([
      lies(aus<Fertigkeitsgraph['skills'][number]>('skills').select('skill_key,label,fundament_tiefe')),
      lies(aus<Fertigkeitsgraph['kanten'][number]>('skill_kante').select('skill_key,voraussetzt_skill_key')),
    ])
    return { data: { skills, kanten }, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}
