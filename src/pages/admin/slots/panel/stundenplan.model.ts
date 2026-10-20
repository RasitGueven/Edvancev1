// Slots S2/W2: reine Logik für Einzel-Sessions (Panel) und Sofort-Dialog (ohne React). Ob ein Kind buchbar ist,
// entscheidet die Datenbank (kinder_buchbar); hier wird nur sortiert, gruppiert und der Grund in Text-Parameter übersetzt.

import type { SlotsEinstellungen } from '@/types/slotplan'
import type { BuchbarCode, KindBuchbar } from '@/types/stundenplan'

/** Höchstens 5 Kinder pro Raum (Live-Sicht hat 5 Tablet-Plätze; sofort_session_anlegen: hint 'zu_viele'). */
export const MAX_KINDER = 5

type Raum = SlotsEinstellungen['raeume'][number]

/** Räume, die an einem Tag in Betrieb sind (wie raum_inaktiv in sofort_session_anlegen). */
export function raeumeAktivAm(raeume: Raum[], datum: string): Raum[] {
  return raeume
    .filter((r) => r.aktiv_ab <= datum && (r.inaktiv_ab === null || datum < r.inaktiv_ab))
    .sort((a, b) => a.name.localeCompare(b.name, 'de'))
}

/** Buchbare Kinder zuerst, dann nach Name; Suche über den Namen. */
export function kinderSortiert(kinder: KindBuchbar[], suche: string): KindBuchbar[] {
  const q = suche.trim().toLocaleLowerCase('de')
  return kinder
    .filter((k) => q === '' || (k.name ?? '').toLocaleLowerCase('de').includes(q))
    .sort((a, b) => Number(b.code === 'ok') - Number(a.code === 'ok') || (a.name ?? '').localeCompare(b.name ?? '', 'de'))
}

/** Codes mit Datum im Satz (detail ist ein ISO-Tag). */
const MIT_DATUM: BuchbarCode[] = ['widerrufen', 'vertrag_ab', 'vertrag_beendet']

/** i18n-Schlüssel (Namespace slots) und ob detail als Datum in den Satz gehört. */
export function grundSchluessel(code: BuchbarCode): { schluessel: string; mitDatum: boolean } {
  return { schluessel: `buchbar.${code}`, mitDatum: MIT_DATUM.includes(code) }
}

/** Testkonto und echtes Kind gemischt (sofort_session_anlegen bricht mit art_konflikt ab). */
export function gemischt(kinder: KindBuchbar[], gewaehlt: string[]): boolean {
  const arten = new Set(kinder.filter((k) => gewaehlt.includes(k.student_id)).map((k) => k.ist_test))
  return arten.size > 1
}
