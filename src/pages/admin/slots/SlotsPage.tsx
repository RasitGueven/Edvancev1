import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '@/hooks/useAuth'
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
import { StundenplanReiter } from './stundenplan/StundenplanReiter'
import { SofortKnopf } from './sofort/SofortKnopf'

/**
 * Menüpunkt Slots (Bauauftrag Slots, SL2): Seitenkopf mit „Session jetzt starten“ (S2), Reiterleiste (Reiter und
 * Woche in der URL, Zurück funktioniert) und der Inhalt des Reiters.
 */
export function SlotsPage(): JSX.Element {
  const { t } = useTranslation('slots')
  const { role } = useAuth()
  const [suche, setSuche] = useSearchParams()
  // Slots S2, Entscheidung 9: Stundenplan und Sofort-Session nur für Admins (die Route lässt ohnehin nur sie herein).
  const istAdmin = role === 'admin'
  const gewuenscht = reiterAusSuche(suche)
  const reiter = gewuenscht === 'stundenplan' && !istAdmin ? 'wochenplan' : gewuenscht
  const montag = montagVon(suche.get('woche') ?? dieseWoche())

  const woche = useSlotsLaden(() => ladeWoche(montag), montag)
  const coaches = useSlotsLaden(() => ladeCoaches(montag), montag)
  const kopf = woche.daten?.montag === montag ? woche.daten.kopf : null
  const abweichungen = coaches.daten?.coaches.reduce((n, c) => n + c.abweichungen.length, 0)
  const ausfall = coaches.daten?.coaches.some((c) => c.abweichungen.some((a) => a.art === 'faellt_aus')) ?? false

  const setWoche = (m: string): void => {
    const neu = new URLSearchParams(suche)
    if (m === dieseWoche()) neu.delete('woche')
    else neu.set('woche', m)
    setSuche(neu)
  }

  const reiterListe: Reiter<SlotsReiter>[] = [
    { key: 'wochenplan', titel: t('reiter.wochenplan') },
    ...(istAdmin ? [{ key: 'stundenplan' as const, titel: t('reiter.stundenplan') }] : []),
    {
      key: 'kinder',
      titel: t('reiter.kinder'),
      anzahl: kopf?.ohne_stammplatz,
      ton: kopf && kopf.ohne_stammplatz_laufend > 0 ? 'handeln' : 'neutral',
    },
    { key: 'coaches', titel: t('reiter.coaches'), anzahl: abweichungen, ton: ausfall ? 'handeln' : 'neutral' },
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
      <PageHeader rubrik={t('seite.rubrik')} titel={t('seite.titel')} satz={satz} aktionen={<SofortKnopf />} />
      <Reiterleiste
        reiter={reiterListe}
        aktiv={reiter}
        label={t('seite.reiterLabel')}
        onWechsel={(r) => setSuche(sucheMitReiter(suche, r))}
      />
      {reiter === 'wochenplan' && <WochenplanReiter woche={woche} montag={montag} onWoche={setWoche} />}
      {reiter === 'stundenplan' && <StundenplanReiter montag={montag} onWoche={setWoche} />}
      {reiter === 'kinder' && <KinderReiter />}
      {reiter === 'coaches' && <CoachesReiter coaches={coaches} montag={montag} onWoche={setWoche} />}
      {reiter === 'einstellungen' && <EinstellungenReiter />}
    </>
  )
}
