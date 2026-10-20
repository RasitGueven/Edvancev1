import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { ladeStundenplanWoche } from '@/lib/supabase/stundenplan'
import { datumLang, uhrzeit } from '../slotsFormat'
import { useSlotsLaden } from '../useSlotsLaden'
import { SessionKarte } from './SessionKarte'
import { Seitenpanel } from './Seitenpanel'

type Props = {
  datum: string
  sessionId: string
  onClose: () => void
  onGeaendert: () => void
}

/**
 * Session-Panel einer Einzel- oder Sofort-Session (W2, Entscheidung 4): die Session-Karte aus dem bisherigen
 * Stundenplan mit Kinder zuweisen, Testlauf-Schalter und Live-Sicht. Daten aus stundenplan_woche des Tages.
 */
export function EinzelPanel({ datum, sessionId, onClose, onGeaendert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const woche = useSlotsLaden(() => ladeStundenplanWoche(datum), `einzel:${datum}`)
  const session = woche.daten?.sessions.find((s) => s.session_id === sessionId) ?? null

  const titel = session
    ? t('wochenplan2.einzelPanel.titel', { datum: datumLang(datum, i18n.language), zeit: uhrzeit(session.scheduled_at, i18n.language) })
    : t('wochenplan2.einzel.art')
  return (
    <Seitenpanel
      rubrik={t('wochenplan2.einzel.art')}
      titel={titel}
      satz={session ? t(session.testlauf ? 'wochenplan2.einzelPanel.satzTest' : 'wochenplan2.einzelPanel.satz') : undefined}
      onClose={onClose}
    >
      {woche.fehler && !woche.daten ? (
        <p role="alert" className="text-sm text-[var(--color-text-secondary)]">{t(woche.fehler)}</p>
      ) : !woche.daten ? (
        <LoadingPulse type="card" />
      ) : !session ? (
        <EdvanceCard>
          <EmptyState icon="🔎" title={t('wochenplan2.einzelPanel.wegTitel')} description={t('wochenplan2.einzelPanel.wegText')} />
        </EdvanceCard>
      ) : (
        <SessionKarte
          session={session}
          onGeaendert={() => {
            woche.neuLaden()
            onGeaendert()
          }}
        />
      )}
    </Seitenpanel>
  )
}
