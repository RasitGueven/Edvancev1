// Der Quellenbeleg — READ-ONLY.
//
// Das ist die Stelle, an der die Pflege aufhoert zu raten. Was stand im
// Original-Aufgabenblatt? Was in der Auswertungsanleitung? Was in der
// didaktischen Kommentierung? Ein Zitat mit Dateinamen, sonst nichts.
//
// Nichts hier ist editierbar, und nichts davon wird gespeichert. Der Beleg ist
// die Quelle, gegen die geprueft wird — waere er aenderbar, waere er keine.

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { BookOpen, ChevronDown, ChevronRight, ExternalLink } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { getGrounding, hasGroundingSource } from '@/lib/authoring/grounding'
import type { GroundingQuote, GroundingRecord } from '@/types'

function Quote({ quote }: { quote: GroundingQuote }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <figure className="flex flex-col gap-1 border-l-2 border-[var(--color-border)] pl-3">
      <blockquote className="whitespace-pre-wrap text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {quote.zitat}
      </blockquote>
      <figcaption className="text-xs text-[var(--color-text-tertiary)]">
        {t('grounding.quelle', { file: quote.quelle })}
      </figcaption>
    </figure>
  )
}

function QuoteGroup({
  title,
  quotes,
}: {
  title: string
  quotes: GroundingQuote[] | undefined
}): JSX.Element | null {
  if (!quotes || quotes.length === 0) return null
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </span>
      {quotes.map((q, i) => (
        <Quote key={i} quote={q} />
      ))}
    </div>
  )
}

export function GroundingPanel({
  source,
  sourceRef,
}: {
  source: string
  sourceRef: string | null
}): JSX.Element | null {
  const { t } = useTranslation('authoring')
  const [record, setRecord] = useState<GroundingRecord | null>(null)
  const [open, setOpen] = useState(true)
  const [loaded, setLoaded] = useState(false)

  const available = hasGroundingSource(source, sourceRef)

  useEffect(() => {
    if (!available) return
    let alive = true
    void getGrounding(source, sourceRef).then((rec) => {
      if (!alive) return
      setRecord(rec)
      setLoaded(true)
    })
    return () => {
      alive = false
    }
  }, [available, source, sourceRef])

  // Eigenbauten (Bruchrechnung, Prozent …) haben keine Quelle — und sollen keine
  // haben. Dann verschwindet das Panel ganz, statt "kein Beleg" zu behaupten.
  if (!available) return null

  const g = record?.grounding

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex min-h-[44px] items-center justify-between gap-2"
        aria-expanded={open}
      >
        <span className="flex items-center gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          <BookOpen className="h-4 w-4" />
          {t('sections.grounding')}
        </span>
        {open ? (
          <ChevronDown className="h-4 w-4 text-[var(--color-text-tertiary)]" />
        ) : (
          <ChevronRight className="h-4 w-4 text-[var(--color-text-tertiary)]" />
        )}
      </button>

      {open && (
        <div className="flex flex-col gap-4">
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {t('grounding.hint')}
          </p>

          {!loaded && (
            <p className="text-sm text-[var(--color-text-tertiary)]">…</p>
          )}

          {loaded && !record && (
            <p className="text-sm text-[var(--color-text-tertiary)]">
              {t('grounding.unavailable')}
            </p>
          )}

          {record && (
            <>
              {record.problems && record.problems.length > 0 && (
                <div className="flex flex-col gap-1 rounded-[var(--radius-md)] bg-[var(--color-gold-warning)]/10 p-3">
                  <span className="text-xs font-semibold text-[var(--color-gold-warning)]">
                    {t('grounding.problems')}
                  </span>
                  {record.problems.map((p, i) => (
                    <span key={i} className="text-sm text-[var(--color-text-secondary)]">
                      {p}
                    </span>
                  ))}
                </div>
              )}

              <QuoteGroup
                title={t('grounding.originalText')}
                quotes={g?.aufgabe_text ? [g.aufgabe_text] : undefined}
              />
              <QuoteGroup
                title={t('grounding.acceptedAnswers')}
                quotes={g?.akzeptierte_antworten}
              />
              <QuoteGroup title={t('grounding.parts')} quotes={g?.teilaufgaben} />
              <QuoteGroup
                title={t('grounding.coding')}
                quotes={g?.kodierung ? [g.kodierung] : undefined}
              />
              <QuoteGroup
                title={t('grounding.typicalErrors')}
                quotes={g?.typische_fehler ? [g.typische_fehler] : undefined}
              />

              {record.lizenz_status && (
                <div className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                    {t('grounding.license')}
                  </span>
                  <span className="text-xs leading-relaxed text-[var(--color-text-secondary)]">
                    {record.lizenz_status}
                  </span>
                </div>
              )}

              {record.iqb_urls && Object.keys(record.iqb_urls).length > 0 && (
                <div className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                    {t('grounding.sources')}
                  </span>
                  {Object.entries(record.iqb_urls).map(([key, url]) => (
                    <a
                      key={key}
                      href={url}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-1 text-xs text-[var(--color-primary)] hover:underline"
                    >
                      {key}
                      <ExternalLink className="h-3 w-3" />
                    </a>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      )}
    </EdvanceCard>
  )
}
