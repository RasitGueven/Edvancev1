import { useTranslation } from 'react-i18next'
import type { ReportTopic } from '@/types'
import { formatDuration } from '@/lib/reportNarrative'

/**
 * Ein Themen-Beleg im Eltern-Report.
 *
 * Die Bearbeitungszeit ist die stärkste Zahl des Gesprächs („1:30 min" gegen
 * „0:26 min") und steht deshalb groß rechts. Der Balken ist bewusst RELATIV zur
 * längsten Zeit derselben Sitzung skaliert — er vergleicht das Kind mit sich
 * selbst, nie mit einer Kohorte. Kein Score, kein Prozentrang.
 */
interface ReportTopicBarProps {
  topic: ReportTopic
  /** Längste Durchschnittszeit der Sitzung — der Maßstab des Balkens. */
  maxDurationMs: number
}

export function ReportTopicBar({
  topic,
  maxDurationMs,
}: ReportTopicBarProps): JSX.Element {
  const { t } = useTranslation('report')
  const time = formatDuration(topic.avgDurationMs)

  // Lange Balken = viel Zeit. Mindestbreite, damit auch der schnellste Anker
  // sichtbar bleibt.
  const pct =
    topic.avgDurationMs && maxDurationMs > 0
      ? Math.max(6, Math.round((topic.avgDurationMs / maxDurationMs) * 100))
      : 0

  return (
    <div className="report-block flex flex-col gap-2 border-b border-[color-mix(in_srgb,var(--color-report-navy)_12%,transparent)] py-4 last:border-b-0">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
        <h4 className="text-base font-semibold text-[var(--color-report-navy)]">
          {topic.topic}
        </h4>
        <p className="text-2xl font-bold tabular-nums text-[var(--color-report-navy)]">
          {time ?? (
            <span className="text-sm font-normal text-[color-mix(in_srgb,var(--color-report-navy)_55%,transparent)]">
              {t('evidence.noTime')}
            </span>
          )}
        </p>
      </div>

      <div
        className="report-bar h-2.5 w-full overflow-hidden rounded-full bg-[color-mix(in_srgb,var(--color-report-navy)_10%,transparent)]"
        role="presentation"
      >
        <div
          className="report-bar-fill h-full rounded-full bg-[var(--color-report-gold)]"
          style={{ width: `${pct}%` }}
        />
      </div>

      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-[color-mix(in_srgb,var(--color-report-navy)_65%,transparent)]">
        {time && <span>{t('evidence.avgTime')}</span>}
        <span>
          {t('evidence.answered', {
            answered: topic.answered,
            planned: topic.planned,
          })}
        </span>
        {topic.answered > 0 && (
          <span>{t('evidence.correct', { correct: topic.correct })}</span>
        )}
        {topic.skipped > 0 && (
          <span className="font-medium text-[var(--color-gold-warning)]">
            {t('evidence.skipped', { count: topic.skipped })}
          </span>
        )}
      </div>
    </div>
  )
}
