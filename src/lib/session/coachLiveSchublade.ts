// Session-Rahmen C3: Teile der Schublade aus coach_kind_detail (Migration 20261011100200) → Ansichtsmodell.
// Rein: ohne Supabase, ohne React. Was der Server nicht belegt, bleibt null; die Seite laesst die Zeile weg.

import type { GrundLetzterSchritt, HeuteZeile, Kernidee, LiveErklaersequenz, MasteryBeleg, PfadVorschlag } from '@/types/coachLive'
import type { KindRaum } from '@/types/sessionC2'
import type { HeuteLive, KernideeLive, PfadVorschlagLive, SchrittDetails, StellschraubeWert } from '@/types/sessionLive'

/**
 * Pfad-Vorschlag nur, solange das Signal offen ist, oder wenn der Coach seine Entscheidung zum Aendern
 * geoeffnet hat (Client-Zustand seit `geoeffnet`). Sonst steht die Entscheidung wie bisher an der Kachel.
 */
export function pfadVorschlagAus(
  p: PfadVorschlagLive | null | undefined,
  entscheidung: KindRaum['pfad_entscheidung'],
  geoeffnet: string | undefined,
): PfadVorschlag | null {
  if (!p || !p.ziel_label || !p.label) return null
  const wiederOffen = !!entscheidung && !!geoeffnet && Date.parse(geoeffnet) >= Date.parse(entscheidung.zeit)
  if (!p.offen && !wiederOffen) return null
  const zahlen = p.warmup_aufgaben !== null && p.warmup_richtig !== null
  return {
    skillPlan: p.ziel_label,
    skillTiefer: p.label,
    klasseTiefer: p.klasse,
    warmupRichtig: zahlen ? p.warmup_richtig : null,
    warmupVon: zahlen ? p.warmup_aufgaben : null,
    fehlbild: p.fehlbild,
    fehlbildAm: p.fehlbild ? p.fehlbild_am : null,
    themaLabel: p.thema_label,
    entscheidung: null,
  }
}

/** „Heute“-Zeilen in der Reihenfolge des Servers; ohne erledigte Aufgabe keine Zahl. */
export function heuteAus(zeilen: HeuteLive[]): HeuteZeile[] {
  return zeilen.map((h): HeuteZeile => {
    const leer: HeuteZeile = { abschnitt: h.abschnitt, skill: null, richtig: null, von: null, hinweise: null, zusatz: null, kernideen: null, zeit: null }
    if (h.abschnitt === 'ankommen') return { ...leer, zeit: h.zeit }
    if (h.abschnitt === 'erklaerung') {
      return { ...leer, skill: h.label, kernideen: { sicher: h.sicher, aktuell: h.aktuell, runde: h.runde } }
    }
    return {
      ...leer,
      skill: h.label,
      richtig: h.von > 0 ? h.richtig : null,
      von: h.von > 0 ? h.von : null,
      hinweise: h.hinweise,
      zusatz: h.abschnitt === 'eingemischt' ? 'mischanteil' : null,
    }
  })
}

/** Beleg „Warm-up heute n von m“, wenn der Skill heute im Warm-up dran war. */
export function warmupBelegAus(zeilen: HeuteLive[], skillKey: string): MasteryBeleg | null {
  let richtig = 0
  let von = 0
  for (const h of zeilen) {
    if (h.abschnitt === 'warmup' && h.skill_key === skillKey) {
      richtig += h.richtig
      von += h.von
    }
  }
  return von > 0 ? { art: 'warmupHeute', richtig, von } : null
}

/**
 * Grund des letzten Schritts. Mit details (C3): Fenster mit Zahl bzw. Mischanteil. Ohne (aeltere Zeilen, Schublade
 * zu): grob aus grund_code und den Stellschrauben wie in C2.
 */
export function grundAus(k: KindRaum, details: SchrittDetails | null, e: Record<string, StellschraubeWert>): GrundLetzterSchritt | null {
  if (details && typeof details.aenderung === 'number' && typeof details.ziel === 'number') {
    const zahl = { quote: details.ziel, richtig: details.richtig ?? null, von: details.von ?? null }
    if (details.aenderung > 0) return { art: 'ueberQuote', ...zahl }
    if (details.aenderung < 0) return { art: 'unterQuote', ...zahl }
    return zahl.richtig !== null && zahl.von !== null ? { art: 'imZiel', quote: zahl.quote, richtig: zahl.richtig, von: zahl.von } : null
  }
  if (details && typeof details.mischanteil === 'number') return { art: 'eingemischt', anteil: details.mischanteil }
  const g = k.schritt?.grund_code ?? ''
  const quote = Number(e.ziel_erfolgsquote ?? 0.8)
  if (g.includes('ueber')) return { art: 'ueberQuote', quote, richtig: null, von: null }
  if (g.includes('unter')) return { art: 'unterQuote', quote, richtig: null, von: null }
  if (k.schritt?.eingemischt) return { art: 'eingemischt', anteil: Number(e.mischanteil ?? 0.3) }
  return g.includes('tiefer') ? { art: 'tiefer' } : null
}

/** Erklaersequenz mit allen Kernideen (Titel, Stand, Runde, Fehlbild der letzten Runde) statt „Kernidee n“. */
export function sequenzMitKernideen(seq: LiveErklaersequenz | null, kernideen: KernideeLive[]): LiveErklaersequenz | null {
  if (!seq || kernideen.length === 0) return seq
  return {
    ...seq,
    kernideen: kernideen.map((k): Kernidee => ({
      text: k.titel,
      stand: k.stand,
      runde: k.runde ?? 1,
      fehlbild: k.fehlbild,
      variante: k.variante,
    })),
  }
}
