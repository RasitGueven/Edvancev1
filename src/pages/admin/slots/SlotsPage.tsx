import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Reiterleiste, type Reiter } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { dieseWoche, montagVon } from '@/components/edvance/wochenNavigation.model'
import { ladeCoaches, ladeWoche } from '@/lib/supabase/slotplan'
import { reiterAusSuche, sucheMitReiter, type SlotsReiter } from './slots.model'
import { useSlotsLaden } from './useSlotsLaden'
import { WochenplanReiter } from './wochenplan/WochenplanReiter'
import { KinderReiter } from './kinder/KinderReiter'
import { CoachesReiter } from './coaches/CoachesReiter'
import { EinstellungenReiter } from './einstellungen/EinstellungenReiter'

/**
 * Menüpunkt Slots (Bauauftrag Slots, SL2): Seitenkopf, Reiterleiste (Reiter und Woche in der URL,
 * Zurück funktioniert) und der Inhalt des Reiters.
 */
export function SlotsPage(): JSX.Element {
  const { t } = useTranslation('slots')
  const [suche, setSuche] = useSearchParams()
  const reiter = reiterAusSuche(suche)
  const montag = montagVon(suche.get('woche') ?? dieseWoche())

  const woche = useSlotsLaden(() => ladeWoche(montag), montag)
  const coaches = useSlotsLaden(() => ladeCoaches(montag), montag)
  const kopf = woche.daten?.montag === montag ? woche.daten.kopf : null
  const abweichungen = coaches.daten?.coaches.reduce((n, c) => n + c.abweichungen.length, 0)

  const setWoche = (m: string): void => {
    const neu = new URLSearchParams(suche)
    if (m === dieseWoche()) neu.delete('woche')
    else neu.set('woche', m)
    setSuche(neu)
  }

  const reiterListe: Reiter<SlotsReiter>[] = [
    { key: 'wochenplan', titel: t('reiter.wochenplan') },
    {
      key: 'kinder',
      titel: t('reiter.kinder'),
      anzahl: kopf?.ohne_stammplatz,
      ton: kopf && kopf.ohne_stammplatz_laufend > 0 ? 'handeln' : 'neutral',
    },
    { key: 'coaches', titel: t('reiter.coaches'), anzahl: abweichungen },
    { key: 'einstellungen', titel: t('reiter.einstellungen') },
  ]

  const satz = kopf
    ? [
        t('seite.kw', { kw: woche.daten?.kw }),
        t('seite.belegt', { belegt: kopf.belegt, plaetze: kopf.plaetze }),
        t('seite.ohneStammplatz', { count: kopf.ohne_stammplatz }),
      ].join(' · ')
    : undefined

  return (
    <>
      <PageHeader rubrik={t('seite.rubrik')} titel={t('seite.titel')} satz={satz} />
      <Reiterleiste
        reiter={reiterListe}
        aktiv={reiter}
        label={t('seite.reiterLabel')}
        onWechsel={(r) => setSuche(sucheMitReiter(suche, r))}
      />
      {reiter === 'wochenplan' && <WochenplanReiter woche={woche} montag={montag} onWoche={setWoche} />}
      {reiter === 'kinder' && <KinderReiter />}
      {reiter === 'coaches' && <CoachesReiter coaches={coaches} montag={montag} onWoche={setWoche} />}
      {reiter === 'einstellungen' && <EinstellungenReiter />}
    </>
  )
}
