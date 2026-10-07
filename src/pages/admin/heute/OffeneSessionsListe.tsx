import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { CalendarClock } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { sessionsNichtGestartet, sessionsOffen } from '@/lib/supabase/sessionC2'
import type { OffeneSession } from '@/types'
import { ArbeitsListe, type ListenZeile } from './ArbeitsListe'
import { berlinZeit } from './ListenVertrieb'

/**
 * Gestartete Sessions, die nach ihrem Ende plus 30 Minuten noch nicht abgeschlossen sind (offene-punkte-a2
 * Befund 16). Der Link fuehrt in die Live-Sicht, dort schliesst man ab. Vergangene, nie gestartete Sessions
 * stehen nur als Zahl darunter, mit Link zum Stundenplan und ohne Aktion (Rasit 07.10.: ein Abschluss wuerde
 * Einheiten verbrauchen). Die Liste laedt selbst.
 */
export function OffeneSessionsListe(): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [sessions, setSessions] = useState<OffeneSession[]>([])
  const [fehler, setFehler] = useState(false)
  const [nieGestartet, setNieGestartet] = useState(0)

  useEffect(() => {
    let aktiv = true
    void sessionsOffen().then((res) => {
      if (!aktiv) return
      setFehler(res.error !== null)
      setSessions(res.data ?? [])
    })
    void sessionsNichtGestartet().then((res) => {
      if (aktiv) setNieGestartet(res.data?.length ?? 0)
    })
    return () => {
      aktiv = false
    }
  }, [])

  const zeilen: ListenZeile[] = sessions.map((s) => ({
    key: s.session_id,
    titel: t('heute.offeneSessions.zeile', {
      zeit: berlinZeit(s.scheduled_at, i18n.language, true),
      raum: s.room ?? t('heute.betrieb.session'),
    }),
    unterzeile: t('heute.offeneSessions.status.active', {
      coach: s.coach_name ?? t('heute.betrieb.ohneCoach'),
      count: s.kinder,
    }),
    rechts: (
      <>
        {s.testlauf && <EdvanceBadge variant="warning">{t('heute.offeneSessions.testlauf')}</EdvanceBadge>}
        <Link
          to={`/coach/session/${s.session_id}/live`}
          className="inline-flex min-h-[44px] items-center text-sm font-semibold text-[var(--color-text-link)] hover:underline"
        >
          {t('heute.offeneSessions.oeffnen')}
        </Link>
      </>
    ),
  }))

  return (
    <ArbeitsListe
      icon={CalendarClock}
      titel={t('heute.offeneSessions.titel')}
      unterzeile={fehler ? t('heute.offeneSessions.fehler') : t('heute.offeneSessions.unterzeile')}
      anzahl={sessions.length}
      zeilen={zeilen}
      leerText={t('heute.offeneSessions.leer')}
      nachZeilen={
        nieGestartet > 0 ? (
          <li className="flex min-h-[54px] items-center gap-2 border-t border-[var(--color-border)] py-2" data-testid="nicht-gestartet">
            <div className="flex min-w-0 flex-1 flex-col">
              <span className="truncate text-sm font-semibold">{t('heute.offeneSessions.nichtGestartet', { count: nieGestartet })}</span>
              <Link to="/admin/schedule" className="truncate text-xs text-[var(--color-text-link)] hover:underline">
                {t('heute.offeneSessions.nichtGestartetText')}
              </Link>
            </div>
          </li>
        ) : undefined
      }
      fussLabel={t('heute.betrieb.fuss')}
      fussZiel="/admin/schedule"
    />
  )
}
