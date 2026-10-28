// Reihe 1 C1/C4: Ansichtsmodell der Karte „Reihe“ aus reihe_coach_lesen (rein, ohne Texte).
import type { ReiheCoach, ReihePlan, ReiheSession } from '@/types/reihe'

export type ReiheAnsicht = {
  /** Session des Tages (Datum = heute) oder die nächste. */
  heute: ReiheSession | null
  /** „Session n von N“ */
  nr: number | null
  gesamt: number
  /** Sessions ab heute bis zur Arbeit (einschliesslich Generalprobe); null ohne Datum. */
  bisArbeit: number | null
  /** Entfallenes als Text-Bausteine: Skill-Label + Kernidee bzw. 'transfer'. */
  entfallen: string[]
  passt: boolean
}

export function reiheAnsicht(r: ReiheCoach, heuteIso: string): ReiheAnsicht {
  const s = r.plan.sessions
  const heute = s.find((x) => x.datum >= heuteIso) ?? null
  return {
    heute,
    nr: heute?.nr ?? null,
    gesamt: r.sessions_gesamt,
    bisArbeit: r.plan.modus === 'klassenarbeit' ? s.length : null,
    entfallen: r.plan.warnung.entfallen.map((e) =>
      e.art === 'transfer' ? 'transfer' : r.kernideen[`${e.skill_key}.${e.kernidee_key}`] ?? r.labels[e.skill_key] ?? e.skill_key),
    passt: r.plan.warnung.passt,
  }
}

/** Änderungen gegenüber der Vorversion (C4 Danach): Kernideen, die die Session gewechselt haben oder neu sind. */
export function reiheAenderungen(neu: ReihePlan, alt: ReihePlan | null): { schluessel: string; von: string | null; nach: string | null }[] {
  if (!alt) return []
  const ort = (p: ReihePlan): Map<string, string> => {
    const m = new Map<string, string>()
    for (const s of p.sessions) for (const k of s.kernideen) m.set(`${k.skill_key}.${k.kernidee_key}`, s.datum)
    return m
  }
  const a = ort(alt)
  const n = ort(neu)
  const alle = [...new Set([...a.keys(), ...n.keys()])]
  return alle
    .map((k) => ({ schluessel: k, von: a.get(k) ?? null, nach: n.get(k) ?? null }))
    .filter((x) => x.von !== x.nach && !(x.von !== null && x.nach === null && x.von < (neu.sessions[0]?.datum ?? '')))
}
