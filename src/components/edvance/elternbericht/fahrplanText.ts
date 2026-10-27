// Eltern-Bericht v4 — Texte und Farbton einer Station des Fahrplans.
// Reine Funktionen über t; Leiste, Seite 1, Seite 3 und Seite 5 teilen sie.

import type { TFunction } from 'i18next'

import type { EbFahrplan, EbStation } from '@/types'

type T = TFunction<'elternbericht'>

/** Farbton einer Station: das Signal, bei der aktuellen ihr Stand. */
export type Ton = 'fehlt' | 'erfuellt' | 'ohne' | 'geschrieben' | 'naechste' | 'aktuell'

export function tonVon(s: EbStation): Ton {
  if (s.signal) return s.signal
  if (s.stand === 'geschrieben') return 'geschrieben'
  return s.stand === 'naechste' || s.stand === 'steht' ? 'naechste' : 'aktuell'
}

/** L5: Ist die Folge der Klassenarbeiten bekannt? Sonst nennt kein Text eine Nummer (Entscheidung 12). */
export const folgeBekannt = (f: EbFahrplan): boolean => f.folge !== 'unbekannt'

/** L5: Kurzes Datum einer Arbeit („12.11.“) in der Sprache der Seite; null ohne Datum. */
export function datumKurz(sprache: string, iso: string | null): string | null {
  if (!iso) return null
  const d = new Date(`${iso.slice(0, 10)}T12:00:00Z`)
  return new Intl.DateTimeFormat(sprache, { day: '2-digit', month: '2-digit', timeZone: 'Europe/Berlin' }).format(d)
}

/** L5: Themen einer Station („Kreise, Prismen und Zylinder · Potenzen“); bei einem Thema dessen Titel. */
export const themenZeile = (t: T, s: EbStation): string => s.themen.map((x) => x.titel).join(t('s2.profil.trenner'))

/** „nächste Arbeit · 2. Halbjahr“, „geschrieben · Note 4“; Halbjahr, Note und Datum nur, wenn bekannt. */
export function standZeile(t: T, s: EbStation, sprache = 'de'): string {
  return [
    t(`v4.stand.${s.stand}`),
    s.stand === 'geschrieben' && s.note !== null ? t('v4.stand.note', { note: s.note }) : null,
    s.ka !== null ? datumKurz(sprache, s.datum) : null,
    s.halbjahr ? t('v4.stand.halbjahr', { halbjahr: s.halbjahr }) : null,
  ]
    .filter((x): x is string => Boolean(x))
    .join(t('s2.profil.trenner'))
}

/** „Voraussetzungen fehlen noch“ usw.; null bei der aktuellen Station. */
export const signalText = (t: T, s: EbStation): string | null => (s.signal ? t(`v4.signal.${s.signal}`) : null)

/**
 * Vorlesetext einer Station: „Klassenarbeit 2: Quadratische Funktionen, nächste Arbeit“; ohne bekannte Arbeit
 * „Quadratische Funktionen, als Nächstes im Unterricht“.
 */
export const stationAria = (t: T, s: EbStation): string =>
  s.ka !== null
    ? t('v4.leiste.aria', { n: s.ka, thema: themenZeile(t, s), stand: standZeile(t, s) })
    : t('v4.leiste.ariaThema', { thema: s.titel, stand: standZeile(t, s) })

/** L5: Quellenzeile unter dem Fahrplan bzw. in Station 03, mit dem Zusatz zur Zuordnung bei bekannter Folge. */
export function quelleZeile(t: T, f: EbFahrplan, genitiv: (name: string) => string): string {
  const bekannt = folgeBekannt(f)
  const satz =
    f.quelle === 'klp'
      ? t(bekannt ? 'v4.quelle.klp' : 'v4.quelle.klpThema')
      : f.schulname
        ? t(bekannt ? 'v4.quelle.schuleGenitiv' : 'v4.quelle.schuleGenitivThema', { schule: genitiv(f.schulname) })
        : t('v4.quelle.schuleOhneNameThema')
  const zusatz = f.folge === 'schule' ? t('v4.quelle.zusatzSchule') : f.folge === 'eigen' ? t('v4.quelle.zusatzEigen') : null
  return zusatz ? `${satz} ${zusatz}` : satz
}

/** L5: Satz im Mint-Kasten (Seite 1, Station 01, Station 03). */
export const satzKey = (f: EbFahrplan): string | null =>
  f.satz === null
    ? null
    : `v4.s1.${f.satz === 'fehlt' ? 'satzFehlt' : 'satzErfuellt'}${folgeBekannt(f) ? '' : 'Thema'}`

/**
 * Trenner vor Station i: „Klasse k“ beim Wechsel ins nächste Schuljahr,
 * „Halbjahreszeugnis“ beim Wechsel vom 1. ins 2. Halbjahr (nur wenn der Plan
 * Halbjahre liefert).
 */
export function trennerVor(f: EbFahrplan, i: number): 'klasse' | 'halbjahr' | null {
  const s = f.stationen[i]
  const vorher = f.stationen.slice(0, i)
  if (i === 0 || !s) return null
  if (s.schuljahr === 'naechstes') {
    return vorher[vorher.length - 1]?.schuljahr === 'dieses' && f.klassenTrenner !== null ? 'klasse' : null
  }
  const letztes = [...vorher].reverse().find((x) => x.halbjahr !== null)?.halbjahr
  return f.halbjahrTrenner && s.halbjahr === 2 && letztes === 1 ? 'halbjahr' : null
}

export const trennerText = (t: T, f: EbFahrplan, art: 'klasse' | 'halbjahr'): string =>
  art === 'klasse' ? t('v4.stand.klasse', { klasse: f.klassenTrenner }) : t('v4.stand.zeugnis')

/**
 * L5: „Voraussetzung für Klassenarbeit 2 und 3“ bei bekannten Arbeiten, sonst „Voraussetzung für „Kreise“ und
 * „Potenzen““. `ziele` sind Positionen im Fahrplan (EbLernpfadPunkt.ziele); null ohne Ziel.
 */
export function voraussetzungText(t: T, f: EbFahrplan, ziele: readonly number[]): string | null {
  const st = ziele
    .slice(0, 2)
    .map((n) => f.stationen.find((s) => s.nummer === n))
    .filter((s): s is EbStation => s !== undefined)
  if (st.length === 0) return null
  if (st.every((s) => s.ka !== null)) {
    return st.length >= 2
      ? t('v4.s4.voraussetzungZwei', { n: st[0].ka, m: st[1].ka })
      : t('v4.s4.voraussetzung', { n: st[0].ka })
  }
  return st.length >= 2
    ? t('v4.s4.voraussetzungThemaZwei', { thema: st[0].titel, thema2: st[1].titel })
    : t('v4.s4.voraussetzungThema', { thema: st[0].titel })
}
