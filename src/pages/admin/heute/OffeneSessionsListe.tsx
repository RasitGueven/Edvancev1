import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { CalendarClock } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { sessionsOffen } from '@/lib/supabase/sessionC2'
import type { OffeneSession } from '@/types'
import { ArbeitsListe, type ListenZeile } from './ArbeitsListe'
import { berlinZeit } from './ListenVertrieb'

/**
 * Sessions, die nach ihrem Ende plus 30 Minuten noch nicht abgeschlossen sind (offene-punkte-a2
 * Befund 16). Der Link fuehrt in die Live-Sicht, dort schliesst man ab. Die Liste laedt selbst.
 */
export function OffeneSessionsListe(): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [sessions, setSessions] = useState<OffeneSession[]>([])
  const [fehler, setFehler] = useState(false)

  useEffect(() => {
    let aktiv = true
    void sessionsOffen().then((res) => {
      if (!aktiv) return
      setFehler(res.error !== null)
      setSessions(res.data ?? [])
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
    unterzeile: t(`heute.offeneSessions.status.${s.status}`, {
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
      fussLabel={t('heute.betrieb.fuss')}
      fussZiel="/admin/schedule"
    />
  )
}
