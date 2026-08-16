import { useTranslation } from 'react-i18next'
import { EmptyState } from '@/components/edvance'
import { ReportFehlbilder } from '@/components/edvance/report/ReportFehlbilder'
import { ReportSchluss } from '@/components/edvance/report/ReportSchluss'
import { ReportSkillbefunde } from '@/components/edvance/report/ReportSkillbefunde'
import { ReportTopicBar } from '@/components/edvance/report/ReportTopicBar'
import { buildNarrative, formatDuration, pickStrength } from '@/lib/reportNarrative'
import { TOPIC_UNASSIGNED } from '@/lib/supabase/lsaReport'
import type { ReportData } from '@/types'

/**
 * Der lesende Teil des Eltern-Reports — die Dramaturgie des Gesprächs:
 * erst die Geschichte, dann die Zahlen als Beleg, und immer eine Stärke zuerst.
 *
 * Kein Gesamtscore, keine Note, kein Prozentrang. Alle Vergleiche laufen
 * innerhalb der Sitzung (Thema gegen Thema desselben Kindes).
 */
export function ReportBody({ data }: { data: ReportData }): JSX.Element {
  const { t, i18n } = useTranslation('report')
  const name = data.firstName?.trim() || t('head.childFallback')

  // `topic` trägt seit R2 den ROHEN competency_content-Schlüssel
  // (arithmetik_algebra, geometrie, funktionen, stochastik) — eine interne
  // Konstante, kein Satz. Sie wird HIER zu einem, einmal und zentral, bevor
  // irgendetwas sie rendert oder in einen Erzählsatz einbaut (CLAUDE §12).
  // Ein unbekannter Schlüssel würde sonst als snake_case an Eltern gehen.
  const topics = data.topics.map((topic) => ({
    ...topic,
    topic:
      topic.topic === TOPIC_UNASSIGNED
        ? t('topics.area.unassigned')
        : t(`topics.area.${topic.topic}`, { defaultValue: t('topics.area.unassigned') }),
  }))

  const strength = pickStrength(topics)
  const narrative = buildNarrative({
    firstName: data.firstName,
    topics,
  })
  const answeredAny = topics.some((topic) => topic.answered > 0)

  const dateLabel = data.analysedAt
    ? new Intl.DateTimeFormat(i18n.language, {
        dateStyle: 'long',
        timeZone: 'Europe/Berlin',
      }).format(new Date(data.analysedAt))
    : '—'

  // Drei Gewichte statt sieben gleichwertiger Abschnitte (R3). Die Ordnung ist
  // in src/styles/report.css begründet; hier steht nur die Typografie dazu.
  const titelHaupt =
    'font-serif text-[1.375rem] font-semibold text-[var(--color-report-navy)]'
  const titelBeleg =
    'font-serif text-[1.0625rem] font-semibold text-[var(--color-report-navy)]'
  const titelAnhang =
    'text-[0.6875rem] font-semibold uppercase tracking-[0.16em] text-[color-mix(in_srgb,var(--color-report-navy)_55%,transparent)]'

  return (
    <>
      {/* 1. KOPF */}
      <header className="report-block flex flex-col gap-3 border-b-2 border-[var(--color-report-gold)] pb-5">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-report-gold)]">
          {t('head.title')}
        </p>
        <h2 className="font-serif text-3xl font-bold text-[var(--color-report-navy)]">
          {name}
        </h2>
        <dl className="flex flex-wrap gap-x-8 gap-y-1 text-sm text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
          <div className="flex gap-2">
            <dt>{t('head.grade')}:</dt>
            <dd className="font-medium">{data.grade}</dd>
          </div>
          <div className="flex gap-2">
            <dt>{t('head.subject')}:</dt>
            <dd className="font-medium">{data.subject}</dd>
          </div>
          <div className="flex gap-2">
            <dt>{t('head.date')}:</dt>
            <dd className="font-medium">{dateLabel}</dd>
          </div>
        </dl>
      </header>

      {/* 2. ERZÄHLUNG (v1: generisch aus den Daten gefüllt) */}
      <section className="report-block rounded-[var(--radius-lg)] bg-[var(--color-report-navy)] p-6 text-white">
        <div className="mb-3 flex flex-wrap items-baseline justify-between gap-2">
          <h3 className="font-serif text-xl font-semibold">
            {t('narrative.title')}
          </h3>
          <span className="text-[10px] uppercase tracking-widest text-[color-mix(in_srgb,var(--color-report-gold)_90%,white)]">
            {t('narrative.generated')}
          </span>
        </div>
        <div className="flex flex-col gap-2">
          {narrative.map((sentence) => (
            <p key={sentence} className="text-base leading-relaxed">
              {sentence}
            </p>
          ))}
        </div>
      </section>

      {/* 3. STÄRKE ZUERST — vor allen Problembefunden. */}
      {strength && (
        <section className="report-block rounded-[var(--radius-lg)] border-l-4 border-[var(--color-report-gold)] bg-[var(--color-report-cream)] p-6">
          <h3 className={titelBeleg}>{t('strength.title')}</h3>
          <p className="mt-2 text-base font-semibold text-[var(--color-report-navy)]">
            {strength.topic}
          </p>
          <p className="mt-1 text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_75%,transparent)]">
            {t('strength.lead', { name })}{' '}
            {formatDuration(strength.avgDurationMs)
              ? t('strength.detail', {
                  correct: strength.correct,
                  answered: strength.answered,
                  time: formatDuration(strength.avgDurationMs),
                })
              : t('strength.detailNoTime', {
                  correct: strength.correct,
                  answered: strength.answered,
                })}
          </p>
        </section>
      )}

      {/* 4. BELEGE */}
      <section className="report-block flex flex-col gap-1">
        <h3 className={titelBeleg}>{t('evidence.title')}</h3>
        <p className="mb-2 text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
          {t('evidence.description')}
        </p>
        {answeredAny ? (
          topics.map((topic) => (
            <ReportTopicBar key={topic.topic} topic={topic} />
          ))
        ) : (
          <EmptyState
            icon="🕒"
            title={t('evidence.empty.title')}
            description={t('evidence.empty.description')}
          />
        )}
      </section>

      {/* 4b. WIEDERKEHRENDE DENKSCHRITTE (AF3/AF4/AF5)

          Nach den Belegen, damit die Zahlen zuerst stehen und der Denkschritt
          sie deutet — nicht umgekehrt. Nur Einstufung 'befund' erreicht diese
          Liste (Filter in lsaReport.loadFehlbilder).

          Gebündelt auf Familienebene: mehrere Fehlbilder derselben Art sind
          für Eltern EIN Satz, nicht fünf. Die Weglass- und Sortierregeln
          stehen in src/lib/reportFehlbilder.ts; bleibt nichts übrig, rendert
          die Komponente nichts. */}
      <ReportFehlbilder
        fehlbilder={data.fehlbilder}
        name={name}
        titleClassName={titelHaupt}
      />

      {/* 4c. WAS WIR UNS GENAUER ANSEHEN (R2)

          Die Skill-Ebene der Diagnose. Nach den Denkschritten, weil sie
          gröber ist: dort steht, WIE das Kind gerechnet hat, hier, WELCHE
          Bereiche der Coach nachprüft.

          Ein Befund, kein Urteil — bei zwei Proben je Skill steht offen=true
          in den Daten. Trägt alles Geprüfte, rendert die Komponente nichts. */}
      <ReportSkillbefunde
        befunde={data.skillbefunde}
        titleClassName={titelHaupt}
      />

      {/* 5. WAS ABGEFRAGT WURDE */}
      {topics.length > 0 && (
        <section className="report-block report-anhang flex flex-col gap-2">
          <h3 className={titelAnhang}>{t('topics.title')}</h3>
          <p className="text-sm text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
            {t('topics.description')}
          </p>
          <ul className="mt-1 flex flex-col gap-1">
            {topics.map((topic) => (
              <li
                key={topic.topic}
                className="flex items-baseline gap-2 text-sm text-[var(--color-report-navy)]"
              >
                <span aria-hidden="true" className="text-[var(--color-report-gold)]">
                  •
                </span>
                {topic.topic}
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* 6. ELTERN-EINSCHÄTZUNG — nur wenn beim Lead etwas erfasst wurde. */}
      {data.parentAssessment && (
        <section className="report-block report-anhang flex flex-col gap-4">
          <h3 className={titelAnhang}>{t('parent.title')}</h3>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="rounded-[var(--radius-lg)] bg-[var(--color-report-cream)] p-5">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-report-gold)]">
                {t('parent.yours')}
              </p>
              {data.parentAssessment.note && (
                <p className="mt-2 text-sm leading-relaxed text-[var(--color-report-navy)]">
                  {data.parentAssessment.note}
                </p>
              )}
              {data.parentAssessment.weakTopics.length > 0 && (
                <ul className="mt-2 flex flex-wrap gap-2">
                  {data.parentAssessment.weakTopics.map((topic) => (
                    <li
                      key={topic}
                      className="rounded-full bg-white px-3 py-1 text-xs font-medium text-[var(--color-report-navy)]"
                    >
                      {topic}
                    </li>
                  ))}
                </ul>
              )}
            </div>
            <div className="rounded-[var(--radius-lg)] border border-[color-mix(in_srgb,var(--color-report-navy)_15%,transparent)] p-5">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-report-gold)]">
                {t('parent.analysis')}
              </p>
              <div className="mt-2 flex flex-col gap-2">
                {narrative.map((sentence) => (
                  <p
                    key={sentence}
                    className="text-sm leading-relaxed text-[var(--color-report-navy)]"
                  >
                    {sentence}
                  </p>
                ))}
              </div>
            </div>
          </div>
        </section>
      )}

      {/* 7. SCHLUSS — Fazit und Empfehlung (R3: Gestaltung, Daten folgen)

          Bewusst KEIN weiterer Abschnitt in der Reihe: der Report zaehlt
          Beobachtungen auf, der Schluss zieht sie zusammen. Eine gemeinsame
          Flaeche mit Vorlauf, damit das Dokument sichtbar endet. Fehlen die
          Daten, rendert die Komponente nichts. */}
      <ReportSchluss fazit={data.fazit} empfehlung={data.empfehlung} />
    </>
  )
}
