import { useTranslation } from 'react-i18next'
import type { ReportTopic } from '@/types'
import { formatDuration } from '@/lib/reportNarrative'

/**
 * Ein Themen-Beleg im Eltern-Report (R3).
 *
 * ZEIGT KÖNNEN, NICHT TEMPO.
 * Bis R3 stand die Bearbeitungszeit groß rechts und der Balken war relativ zur
 * längsten Zeit skaliert — der Beleg beantwortete damit „wie schnell", während
 * die Eltern „wie sicher" lesen. Jetzt trägt die Zeile, wie viele der
 * gestellten Aufgaben gelöst wurden; die Zeit bleibt als leise Fußnote.
 *
 * DIE DARSTELLUNG DARF NICHT WIE EINE NOTE AUSSEHEN.
 * Deshalb eine Aufgabenspur aus einzelnen Marken statt eines Füllbalkens: eine
 * Marke je gestellter Aufgabe, gelöste gefüllt, offene als Ring. Das ist eine
 * ZÄHLUNG, keine Skala — es gibt kein Maximum, auf das man zuläuft, keine
 * Farbe, die Wertung trägt (Gold ist der einzige Akzent des Reports, Rot kommt
 * nirgends vor), und keine Prozentzahl.
 *
 * Ab `MAX_MARKEN` Aufgaben wird die Spur zur Zahlenzeile: 30 Punkte sind kein
 * Bild mehr, sondern ein Muster, das man nachzählen müsste.
 */

/** Mehr Marken liest niemand mehr — dann trägt der Satz allein. */
const MAX_MARKEN = 20

interface ReportTopicBarProps {
  topic: ReportTopic
}

export function ReportTopicBar({ topic }: ReportTopicBarProps): JSX.Element {
  const { t } = useTranslation('report')
  const time = formatDuration(topic.avgDurationMs)
  const geloest = Math.min(topic.correct, topic.answered)
  const offen = Math.max(0, topic.answered - geloest)
  const spurZeigen = topic.answered > 0 && topic.answered <= MAX_MARKEN

  const satz = t('evidence.solved', {
    correct: geloest,
    answered: topic.answered,
  })

  return (
    <div className="report-block flex flex-col gap-2 border-b border-[color-mix(in_srgb,var(--color-report-navy)_12%,transparent)] py-4 last:border-b-0">
      <h4 className="text-base font-semibold text-[var(--color-report-navy)]">
        {topic.topic}
      </h4>

      {/* Die Spur ist ein Bild derselben Aussage, die darunter als Satz steht —
          deshalb trägt der Satz die Bedeutung und die Spur ist dekorativ
          ausgezeichnet. Ein Screenreader liest sie nicht zweimal. */}
      {spurZeigen && (
        <div className="report-spur flex flex-wrap gap-1.5" aria-hidden="true">
          {Array.from({ length: geloest }, (_, i) => (
            <span
              key={`geloest-${i}`}
              className="report-marke report-marke-voll h-2.5 w-2.5 rounded-full bg-[var(--color-report-gold)]"
            />
          ))}
          {Array.from({ length: offen }, (_, i) => (
            <span
              key={`offen-${i}`}
              className="report-marke report-marke-leer h-2.5 w-2.5 rounded-full border border-[color-mix(in_srgb,var(--color-report-navy)_30%,transparent)]"
            />
          ))}
        </div>
      )}

      <p className="text-base text-[var(--color-report-navy)]">{satz}</p>

      {/* Zeit und ausgelassene Aufgaben sind Nebeninformation — klein, letzte
          Zeile, ohne eigene Auszeichnung. */}
      {(time || topic.skipped > 0) && (
        <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-[color-mix(in_srgb,var(--color-report-navy)_60%,transparent)]">
          {time && <span>{t('evidence.pace', { time })}</span>}
          {topic.skipped > 0 && (
            <span>{t('evidence.skipped', { count: topic.skipped })}</span>
          )}
        </div>
      )}
    </div>
  )
}
