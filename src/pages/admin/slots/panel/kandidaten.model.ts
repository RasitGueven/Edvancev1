// Slots W2: reine Logik des Dialogs „Kind in <Raum>“ (Entscheidung 7). Ob ein Kind buchbar ist, entscheidet
// slots_kandidaten_alle (code null = buchbar); hier wird nur sortiert, gesucht und der Grund auf einen Satz gelegt.

import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { KandidatCode, SlotsKandidatAlle, StammplatzZeile } from '@/types/slotplan'
import { isoWochentag } from '../wochenplan/wochenplan.model'

export type KindModus = 'einmal' | 'jedeWoche'

/** Codes mit eigenem, aufs Kind bezogenem Satz unter wochenplan2.grund.*; alle anderen über fehler.* (fehler.ts). */
const EIGENE: readonly KandidatCode[] = [
  'kein_vertrag', 'vertrag_ab', 'SL001', 'SL002', 'SL003', 'SL004', 'SL005', 'SL006', 'SL007', 'SL011', 'SL012', 'SL013',
]

/** i18n-Schlüssel (Namespace slots) für den Grund, warum ein Kind hier nicht buchbar ist; null = buchbar. */
export function grundSchluesselKandidat(code: KandidatCode | null): string | null {
  if (code === null) return null
  if (EIGENE.includes(code)) return `wochenplan2.grund.${code}`
  return slotsFehlerSchluessel({ code, hint: null })
}

/** Buchbare Kinder zuerst, dann nach Name; Suche über den Namen. */
export function kandidatenSortiert(liste: SlotsKandidatAlle[], suche: string): SlotsKandidatAlle[] {
  const q = suche.trim().toLocaleLowerCase('de')
  return liste
    .filter((k) => q === '' || (k.name ?? '').toLocaleLowerCase('de').includes(q))
    .sort(
      (a, b) =>
        Number(a.code !== null) - Number(b.code !== null) || (a.name ?? '').localeCompare(b.name ?? '', 'de'),
    )
}

/** „Jede Woche“: eine Zeile mit Wochentag und Uhrzeit des Slots, Raum, Takt wöchentlich (gültig ab Termindatum). */
export function stammplatzZeile(datum: string, zeitId: string, raumId: string): StammplatzZeile {
  return { wochentag: isoWochentag(datum), slot_zeit_id: zeitId, takt: 'woechentlich', raum_id: raumId }
}
