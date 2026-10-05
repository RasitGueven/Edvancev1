// Mehrfachauswahl der Expertenliste (Bauauftrag E 18). Reine Funktionen:
// - Kopf „Alle im Filter (n)“: waehlt alle gefilterten Aufgaben, auch nicht sichtbare; halb markiert bei Teilauswahl.
// - Ein Filterwechsel leert die Auswahl (die Sortierung ist kein Filter).
// - „Ausgelassene anzeigen“ waehlt genau die ausgelassenen Aufgaben einer Sammelaktion.
// - Die Fertigkeitsauswahl fuer mehrere Aufgaben, wie pruef_fertigkeit_optionen: Thema der Aufgabe plus direkte
//   Voraussetzungen ihrer Fertigkeit. Nur Fertigkeiten mit Heimat-Thema. Der Server prueft je Aufgabe nach
//   (Grund nicht_erlaubt), die Liste hier ist nur die Auswahl.

import type { FilterState } from '@/components/edvance/authoring/AuthoringFilters'
import type { SammelErgebnis, SkillThema } from '@/types'

export type KopfZustand = 'alle' | 'teil' | 'keine'

export function kopfZustand(imFilter: string[], auswahl: ReadonlySet<string>): KopfZustand {
  const n = imFilter.filter((id) => auswahl.has(id)).length
  if (n === 0) return 'keine'
  return n === imFilter.length ? 'alle' : 'teil'
}

/** Kopf angeklickt: alle im Filter an, oder — wenn schon alle an sind — alle aus. */
export function alleUmschalten(imFilter: string[], auswahl: ReadonlySet<string>): Set<string> {
  return kopfZustand(imFilter, auswahl) === 'alle' ? new Set() : new Set(imFilter)
}

export function umschalten(auswahl: ReadonlySet<string>, id: string): Set<string> {
  const neu = new Set(auswahl)
  if (neu.has(id)) neu.delete(id)
  else neu.add(id)
  return neu
}

/** Hat sich der Filter geaendert? Die Sortierung zaehlt nicht. */
export function filterGeaendert(alt: FilterState, neu: FilterState): boolean {
  const ohneSort = ({ sort: _sort, ...rest }: FilterState): Omit<FilterState, 'sort'> => rest
  return JSON.stringify(ohneSort(alt)) !== JSON.stringify(ohneSort(neu))
}

/** Die Auswahl nach „Ausgelassene anzeigen“: genau die ausgelassenen IDs. */
export function ausgelasseneAuswahl(ergebnis: SammelErgebnis): Set<string> {
  return new Set(ergebnis.ausgelassen.map((a) => a.task_id))
}

export type FertigkeitWahl = { key: string; label: string; gruppe: string }

/**
 * Fertigkeiten, die fuer mindestens eine der Aufgaben erlaubt sind, gruppiert nach Thema („Im Thema …“) und
 * „Voraussetzungen“. basis = die Fertigkeiten der ausgewaehlten Aufgaben.
 */
export function fertigkeitWahl(
  basis: (string | null)[],
  themen: SkillThema[],
  skills: { skill_key: string; label: string; fundament_tiefe: number | null }[],
  kanten: { skill_key: string; voraussetzt_skill_key: string }[],
  voraussetzungLabel: string,
): FertigkeitWahl[] {
  const themaVon = new Map(themen.map((z) => [z.skill_key, z]))
  const label = new Map(skills.map((s) => [s.skill_key, s]))
  const tiefe = (k: string): number => label.get(k)?.fundament_tiefe ?? 0
  const imThema = new Map<string, FertigkeitWahl>()
  const vor = new Map<string, FertigkeitWahl>()
  for (const b of new Set(basis.filter((x): x is string => !!x))) {
    const th = themaVon.get(b)
    if (!th) continue
    for (const z of themen) {
      if (z.thema_key === th.thema_key) imThema.set(z.skill_key, { key: z.skill_key, label: label.get(z.skill_key)?.label ?? z.skill_key, gruppe: th.label })
    }
    for (const k of kanten) {
      if (k.skill_key === b && themaVon.has(k.voraussetzt_skill_key)) {
        vor.set(k.voraussetzt_skill_key, { key: k.voraussetzt_skill_key, label: label.get(k.voraussetzt_skill_key)?.label ?? k.voraussetzt_skill_key, gruppe: voraussetzungLabel })
      }
    }
  }
  const sortiert = (m: Map<string, FertigkeitWahl>): FertigkeitWahl[] =>
    [...m.values()].sort((a, b) => a.gruppe.localeCompare(b.gruppe, 'de') || tiefe(a.key) - tiefe(b.key) || a.key.localeCompare(b.key))
  return [...sortiert(imThema), ...sortiert(vor).filter((v) => !imThema.has(v.key))]
}
