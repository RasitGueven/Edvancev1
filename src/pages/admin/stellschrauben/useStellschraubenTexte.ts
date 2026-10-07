import { useTranslation } from 'react-i18next'
import type { Stellschraube, StellschraubeWert } from '@/types/sessionLive'

/** Werte der Stellschrauben als Text: Anteile in Prozent, Zahlen mit Einheit, Schalter an/aus. */
export function useStellschraubenTexte() {
  const { t, i18n } = useTranslation('admin')
  const lang = i18n.language

  const zahl = (n: number): string => new Intl.NumberFormat(lang, { maximumFractionDigits: 2 }).format(n)

  const wert = (s: Stellschraube, w: StellschraubeWert | null): string => {
    if (w === null) return '–'
    if (typeof w === 'boolean') return t(`stellschrauben.schalter.${w ? 'an' : 'aus'}`)
    if (typeof w === 'string') return t(`stellschrauben.auswahl.${w}`, { defaultValue: w })
    if (s.einheit === 'anteil') return new Intl.NumberFormat(lang, { style: 'percent', maximumFractionDigits: 0 }).format(w)
    return s.einheit ? t(`stellschrauben.einheit.${s.einheit}`, { count: w, wert: zahl(w) }) : zahl(w)
  }

  const spanne = (s: Stellschraube): string => {
    if (s.typ === 'schalter') return t('stellschrauben.spanneSchalter')
    if (s.typ === 'auswahl') return (s.werte ?? []).map((x) => t(`stellschrauben.auswahl.${x}`, { defaultValue: x })).join(' / ')
    return t('stellschrauben.spanneZahl', { min: wert(s, s.min), max: wert(s, s.max) })
  }

  const datumZeit = (iso: string): string =>
    new Intl.DateTimeFormat(lang, { timeZone: 'Europe/Berlin', dateStyle: 'medium', timeStyle: 'short' }).format(new Date(iso))

  return { t, wert, spanne, datumZeit }
}
