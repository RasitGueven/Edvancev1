// Slots SL2: reine Logik der Admin-Oberfläche (ohne React). Was der Server entscheidet (Kapazität,
// Wochengrenze, Planbilanz, Zuteilung), wird hier nicht nachgerechnet, nur dargestellt.

import type { PlanbilanzArt, SlotsKinderZeile, SlotsWoche, WocheZelle } from '@/types/slotplan'

// ── Reiter <-> URL ─────────────────────────────────────────────────────────────

export const REITER = ['wochenplan', 'stundenplan', 'kinder', 'coaches', 'einstellungen'] as const
export type SlotsReiter = (typeof REITER)[number]

export function reiterAusSuche(suche: URLSearchParams): SlotsReiter {
  const r = suche.get('reiter')
  return (REITER as readonly string[]).includes(r ?? '') ? (r as SlotsReiter) : 'wochenplan'
}

/** Neue Suchparameter beim Reiterwechsel: Woche bleibt, Filter nur im Reiter Kinder. */
export function sucheMitReiter(suche: URLSearchParams, reiter: SlotsReiter): URLSearchParams {
  const neu = new URLSearchParams(suche)
  if (reiter === 'wochenplan') neu.delete('reiter')
  else neu.set('reiter', reiter)
  if (reiter !== 'kinder') neu.delete('filter')
  return neu
}

// ── Wochenplan ───────────────────────────────────────────────────────────────

/** leer = kein Raum besetzt; achtung = ab 90 %; handeln = mehr Kinder als Plätze oder Coach fehlt. */
export type ZellZustand = 'leer' | 'normal' | 'achtung' | 'handeln'

export function zellZustand(z: WocheZelle): ZellZustand {
  if (z.kapazitaet === 0 && z.belegt === 0 && z.coach_fehlt === 0) return 'leer'
  if (z.belegt > z.kapazitaet || z.coach_fehlt > 0 || z.ohne_raum > 0) return 'handeln'
  if (z.belegt >= z.kapazitaet * 0.9) return 'achtung'
  return 'normal'
}

/** Uhrzeiten, die in der ganzen Woche keinen geöffneten Raum und kein Kind haben (fallen zusammen). */
export function leereZeiten(woche: SlotsWoche): Set<string> {
  const leer = new Set(woche.zeiten.map((z) => z.id))
  for (const z of woche.zellen) if (zellZustand(z) !== 'leer') leer.delete(z.zeit_id)
  return leer
}

export function zelleVon(woche: SlotsWoche, datum: string, zeitId: string): WocheZelle | undefined {
  return woche.zellen.find((z) => z.datum === datum && z.zeit_id === zeitId)
}

/** Belegung je geöffnetem Raum für die Platz-Punkte. */
export function raumBelegung(z: WocheZelle): number[] {
  return z.raeume.filter((r) => r.offen).map((r) => r.belegt)
}

// ── Kinder ───────────────────────────────────────────────────────────────────

export const KINDER_FILTER = ['alle', 'kein_stammplatz', 'reicht_nicht', 'einheiten_uebrig', 'aufgebraucht', 'passt'] as const
export type KinderFilter = (typeof KINDER_FILTER)[number]

const FILTER_ART: Record<Exclude<KinderFilter, 'alle'>, PlanbilanzArt> = {
  kein_stammplatz: 'kein_stammplatz',
  reicht_nicht: 'reicht_bis',
  einheiten_uebrig: 'ohne_termin',
  aufgebraucht: 'aufgebraucht',
  passt: 'passt',
}

export function filterAusSuche(suche: URLSearchParams): KinderFilter {
  const f = suche.get('filter')
  return (KINDER_FILTER as readonly string[]).includes(f ?? '') ? (f as KinderFilter) : 'alle'
}

/** Handlungsbedarf zuerst (Bauauftrag SL2, Umfang 5). */
const RANG: Record<PlanbilanzArt, number> = { kein_stammplatz: 0, reicht_bis: 1, ohne_termin: 2, aufgebraucht: 3, passt: 4 }

export function kinderSortiert(kinder: SlotsKinderZeile[]): SlotsKinderZeile[] {
  return [...kinder].sort(
    (a, b) =>
      RANG[a.planbilanz.art] - RANG[b.planbilanz.art] ||
      Number(b.vertrag_laeuft) - Number(a.vertrag_laeuft) ||
      a.beginn.localeCompare(b.beginn) ||
      (a.name ?? '').localeCompare(b.name ?? '', 'de'),
  )
}

export function kinderGefiltert(kinder: SlotsKinderZeile[], filter: KinderFilter, suche: string): SlotsKinderZeile[] {
  const q = suche.trim().toLocaleLowerCase('de')
  return kinderSortiert(kinder).filter(
    (k) =>
      (filter === 'alle' || k.planbilanz.art === FILTER_ART[filter]) &&
      (q === '' || (k.name ?? '').toLocaleLowerCase('de').includes(q)),
  )
}

export function anzahlJeFilter(kinder: SlotsKinderZeile[]): Record<KinderFilter, number> {
  const out = Object.fromEntries(KINDER_FILTER.map((f) => [f, 0])) as Record<KinderFilter, number>
  out.alle = kinder.length
  for (const k of kinder) {
    const f = (Object.keys(FILTER_ART) as Exclude<KinderFilter, 'alle'>[]).find((x) => FILTER_ART[x] === k.planbilanz.art)
    if (f) out[f] += 1
  }
  return out
}

/** Farbe der Planbilanz (Entscheidung 28). */
export function planbilanzVariante(art: PlanbilanzArt, vertragLaeuft: boolean): 'strength' | 'warning' | 'coach-emergency' | 'muted' {
  if (art === 'passt') return 'strength'
  if (art === 'aufgebraucht') return 'muted'
  if (art === 'kein_stammplatz') return vertragLaeuft ? 'coach-emergency' : 'warning'
  return 'warning'
}

// ── Absage (10-Uhr-Regel, nur Vorschau; entscheiden tut der Server) ─────────────

/** Eingang (Berliner Datum und Uhrzeit) vor 10:00 am Termintag = rechtzeitig. */
export function rechtzeitigVorschau(eingangDatum: string, eingangUhr: string, terminDatum: string): boolean {
  return `${eingangDatum}T${eingangUhr}` < `${terminDatum}T10:00`
}
