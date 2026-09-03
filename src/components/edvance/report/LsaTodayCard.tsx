import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { RefreshCw } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { listTodaysLsaSessions } from '@/lib/supabase/lsaReport'
import type { LsaSessionListItem } from '@/types'

/**
 * Fertig-Signal: die heute abgeschlossenen Analyse-Sitzungen.
 *
 * Bewusst KEIN Live-Dashboard — laufende Sitzungen stehen im Lead-Board unter
 * „Analyse", hier zaehlt nur die Frage „wer ist heute durch?". Gefiltert und
 * sortiert wird ueber lsa_sessions.completed_at, den echten Abschluss-
 * Zeitstempel: neuester Abschluss zuoberst. Dazu ein leichtes Polling (60 s)
 * plus ein Knopf zum sofortigen Neuladen; „Report oeffnen" fuehrt direkt ins
 * Elterngespraech.
 */
const POLL_MS = 60_000

// Abschluss liegt im heutigen Kalendertag (lokale Zeit).
function completedToday(completedAt: string | null): boolean {
  if (completedAt === null) return false
  const done = new Date(completedAt)
  if (Number.isNaN(done.getTime())) return false
  const start = new Date()
  start.setHours(0, 0, 0, 0)
  return done.getTime() >= start.getTime()
}

export function LsaTodayCard(): JSX.Element {
  const { t } = useTranslation('report')
  const [sessions, setSessions] = useState<LsaSessionListItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    const { data, error: err } = await listTodaysLsaSessions()
    if (err) setError(err)
    else {
      const done = (data ?? [])
        .filter((s) => s.status === 'completed' && completedToday(s.completed_at))
        .sort(
          (a, b) =>
            new Date(b.completed_at ?? 0).getTime() -
            new Date(a.completed_at ?? 0).getTime(),
        )
      setSessions(done)
      setError(null)
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    void load()
    const timer = window.setInterval(() => void load(), POLL_MS)
    return () => window.clearInterval(timer)
  }, [load])

  return (
    <EdvanceCard>
      <div className="flex flex-col gap-4">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="flex flex-col gap-1">
            <h2 className="text-base font-semibold">{t('today.title')}</h2>
            <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
              {t('today.description')}
            </p>
          </div>
          <Button
            type="button"
            variant="secondary"
            onClick={() => void load()}
            aria-label={t('today.refresh')}
          >
            <RefreshCw className="mr-2 h-4 w-4" />
            {t('today.refresh')}
          </Button>
        </div>

        {error && <p className="text-sm text-[var(--color-error-gap)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : sessions.length === 0 ? (
          <EmptyState
            icon="📋"
            title={t('today.empty.title')}
            description={t('today.empty.description')}
          />
        ) : (
          <ul className="flex flex-col gap-2">
            {sessions.map((session) => (
              <li
                key={session.session_id}
                className="flex flex-wrap items-center justify-between gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
              >
                <div className="flex min-w-0 flex-col gap-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-semibold">
                      {session.first_name ?? '—'}
                    </span>
                    <EdvanceBadge variant="strength">
                      {t('today.state.completed')}
                    </EdvanceBadge>
                  </div>
                  <p className="text-xs text-[var(--color-text-tertiary)]">
                    {t('today.meta', {
                      grade: session.grade,
                      subject: session.subject,
                    })}{' '}
                    ·{' '}
                    {t('today.progress', {
                      answered: session.answered,
                      planned: session.planned,
                    })}
                  </p>
                </div>

                <Button asChild>
                  <Link to={`/admin/report/${session.session_id}`}>
                    {t('today.openReport')}
                  </Link>
                </Button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </EdvanceCard>
  )
}
