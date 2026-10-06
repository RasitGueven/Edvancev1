import { useTranslation } from 'react-i18next'
import { geltenderFall, zielSatz } from '@/lib/session/coachLiveLogik'
import type {
  CoachLiveKind,
  HeuteZeile,
  KachelMeta,
  LiveSignal,
  LiveZeitpunkt,
  ZielNotiz,
} from '@/types/coachLive'
import type { StellschraubeWert } from '@/types/sessionLive'

/** Texte der Live-Sicht: Werte aus dem Ansichtsmodell in Saetze (i18n, Intl, Europe/Berlin). */
export function useLiveTexte() {
  const { t, i18n } = useTranslation('coachLive')
  const sprache = i18n.language

  const uhrzeit = (iso: string): string =>
    new Intl.DateTimeFormat(sprache, { timeZone: 'Europe/Berlin', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

  /** „29.09.“ aus einem Datum (YYYY-MM-DD) oder ISO-Zeitpunkt. */
  const datum = (wert: string): string => {
    const d = wert.length === 10 ? new Date(`${wert}T12:00:00Z`) : new Date(wert)
    return new Intl.DateTimeFormat(sprache, { timeZone: 'Europe/Berlin', day: '2-digit', month: '2-digit' }).format(d)
  }

  const wochentag = (wert: string): string => {
    const d = wert.length === 10 ? new Date(`${wert}T12:00:00Z`) : new Date(wert)
    return new Intl.DateTimeFormat(sprache, { timeZone: 'Europe/Berlin', weekday: 'short' }).format(d).replace('.', '')
  }

  /** „Do 08.10.“ */
  const tagDatum = (wert: string): string => `${wochentag(wert)} ${datum(wert)}`

  /** „Do 08.10. · 17:00“ */
  const termin = (iso: string): string => `${tagDatum(iso)} · ${uhrzeit(iso)}`

  const prozent = (anteil: number): string =>
    new Intl.NumberFormat(sprache, { style: 'percent', maximumFractionDigits: 0 }).format(anteil)

  const fallKurz = (k: CoachLiveKind): string => {
    const fall = geltenderFall(k.ziel)
    if (fall === 'klassenarbeit' && k.ziel.klassenarbeit?.datum) {
      return t('fall.klassenarbeitTag', { tag: wochentag(k.ziel.klassenarbeit.datum) })
    }
    return fall ? t(`fall.${fall}`) : ''
  }

  const ziel = (k: CoachLiveKind): string => {
    const { key, werte } = zielSatz(k.ziel)
    return t(key, werte)
  }

  const taetigkeit = (k: CoachLiveKind): string => {
    const a = k.taetigkeit
    if (a.art === 'warmup') return t('taetigkeit.warmup', { nr: a.nr, von: a.von })
    if (a.art === 'erklaerung') return t('taetigkeit.erklaerung', { fall: fallKurz(k), kernidee: a.kernidee, von: a.von })
    if (a.art === 'ueben' || a.art === 'tiefer') return t(`taetigkeit.${a.art}`, { fall: fallKurz(k) })
    return t(`taetigkeit.${a.art}`)
  }

  const ankunft = (k: CoachLiveKind, beginn: string): string | null => {
    if (!k.tabletSeit) return null
    const spaet = Math.round((Date.parse(k.tabletSeit) - Date.parse(beginn)) / 60_000)
    return spaet > 0 ? t('taetigkeit.ankunft', { zeit: uhrzeit(k.tabletSeit), count: spaet }) : null
  }

  const band = (k: CoachLiveKind, zeitpunkt: LiveZeitpunkt): string => {
    if (k.status === 'gemeistert') return t('band.gemeistert', { skill: k.masteryKandidat?.label ?? '' })
    const s = k.signale.find((x) => x.art === k.status)
    if (!s) return t('band.laeuft')
    if (s.grund === 'kandidat') return t(`band.kandidat_${zeitpunkt === 'warmup' ? 'warmup' : 'kern'}`)
    return t(`band.${s.grund}`, { count: s.wert ?? 0 })
  }

  const meta = (m: KachelMeta | null): string => {
    if (m === null) return ''
    switch (m.art) {
      case 'ohneHinweis':
      case 'hinweise':
        return t(`meta.${m.art}`, { count: m.anzahl })
      case 'richtig':
        return m.ueberZiel === null
          ? t('meta.richtig', { richtig: m.richtig, von: m.von })
          : t('meta.richtigUeberZiel', { richtig: m.richtig, von: m.von, quote: prozent(m.ueberZiel) })
      case 'extrarunde':
        return t('meta.extrarunde', { variante: m.variante })
      case 'pfadTiefer':
        return t('meta.pfadTiefer', { von: m.von })
      default:
        return t(`meta.${m.art}`)
    }
  }

  const signalTitel = (s: LiveSignal, zeitpunkt: LiveZeitpunkt): string =>
    s.art === 'kandidat' ? t(`queue.art.kandidat_${zeitpunkt === 'warmup' ? 'warmup' : 'kern'}`) : t(`queue.art.${s.art}`)

  const signalGrund = (s: LiveSignal, einstellungen: Record<string, StellschraubeWert>): string =>
    t(`queue.grund.${s.grund}`, {
      count: s.wert ?? 0,
      skill: s.skill ?? '',
      nr: s.aufgabeNr ?? '',
      von: einstellungen.warmup_aufgaben,
      schwelle: einstellungen.signal_minuten_ohne_fortschritt,
    })

  const alter = (seit: string, jetzt: string): string => {
    const min = Math.floor((Date.parse(jetzt) - Date.parse(seit)) / 60_000)
    return min < 1 ? t('queue.gerade') : t('queue.alter', { count: min })
  }

  const zielNotiz = (n: ZielNotiz): string => {
    switch (n.art) {
      case 'am':
        return t('zielNotiz.am', { datum: datum(n.datum) })
      case 'bestaetigt':
        return t('zielNotiz.bestaetigt', { zeit: uhrzeit(n.zeit) })
      case 'heute':
      case 'warmup':
        return t(`zielNotiz.${n.art}`, { richtig: n.richtig, von: n.von })
      case 'erklaerung':
        return t('zielNotiz.erklaerung', { kernidee: n.kernidee, von: n.von })
      default:
        return t(`zielNotiz.${n.art}`)
    }
  }

  const heuteText = (h: HeuteZeile, beginn: string): string => {
    if (h.abschnitt === 'ankommen' && h.zeit) {
      const spaet = Math.round((Date.parse(h.zeit) - Date.parse(beginn)) / 60_000)
      return t('schublade.heuteZeile.ankunft', { zeit: uhrzeit(h.zeit), count: spaet })
    }
    if (h.kernideen) return t('schublade.heuteZeile.kernideen', h.kernideen)
    const teile: string[] = []
    if (h.skill) teile.push(h.skill)
    if (h.richtig !== null && h.von !== null) teile.push(t('schublade.heuteZeile.richtig', { richtig: h.richtig, von: h.von }))
    if (h.hinweise === 0) teile.push(t('schublade.heuteZeile.ohneHinweis'))
    else if (h.hinweise !== null) teile.push(t('schublade.heuteZeile.hinweise', { count: h.hinweise }))
    return teile.join(' · ')
  }

  const heuteZusatz = (h: HeuteZeile, einstellungen: Record<string, StellschraubeWert>): string | null => {
    if (h.zusatz === 'mischanteil') return t('schublade.heuteZeile.mischanteil', { anteil: prozent(Number(einstellungen.mischanteil)) })
    return h.zusatz ? t(`schublade.heuteZeile.${h.zusatz}`) : null
  }

  return {
    t, uhrzeit, datum, tagDatum, termin, prozent, fallKurz, ziel, taetigkeit, ankunft, band, meta,
    signalTitel, signalGrund, alter, zielNotiz, heuteText, heuteZusatz,
  }
}

export type LiveTexte = ReturnType<typeof useLiveTexte>
