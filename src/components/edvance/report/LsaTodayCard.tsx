import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { RefreshCw } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { listTodaysLsaSessions } from '@/lib/supabase/lsaReport'
import type { LsaSessionListItem } from '@/types'

/**
 * Fertig-Signal: die heutigen Analyse-Sitzungen mit Zustand „läuft" / „fertig".
 *
 * Bewusst KEIN Live-Dashboard mit vier Zuständen — das ist verschoben. Hier
 * genügt die Frage „ist das Kind durch?": ein leichtes Polling (60 s) plus ein
 * Knopf zum sofortigen Neuladen. Bei fertigen Sitzungen führt „Report öffnen"
 * direkt ins Elterngespräch.
 */
const POLL_MS = 60_000

export function LsaTodayCard(): JSX.Element {
  const { t } = useTranslation('report')
  const [sessions, setSessions] = useState<LsaSessionListItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    const { data, error: err } = await listTodaysLsaSessions()
    if (err) setError(err)
    else {
      setSessions(data ?? [])
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
                    <EdvanceBadge
                      variant={
                        session.status === 'completed' ? 'strength' : 'muted'
                      }
                    >
                      {t(`today.state.${session.status}`)}
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

                {session.status === 'completed' && (
                  <Button asChild>
                    <Link to={`/admin/report/${session.session_id}`}>
                      {t('today.openReport')}
                    </Link>
                  </Button>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </EdvanceCard>
  )
}
