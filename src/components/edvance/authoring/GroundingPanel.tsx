// Der Quellenbeleg — READ-ONLY.
//
// Das ist die Stelle, an der die Pflege aufhoert zu raten. Was stand im
// Original-Aufgabenblatt? Was hat die Extraktion selbst als unsicher markiert?
// Was konnte der Import nicht uebernehmen? Ein Zitat mit Dateinamen, sonst nichts.
//
// Nichts hier ist editierbar, und nichts davon wird gespeichert. Der Beleg ist die
// Quelle, gegen die geprueft wird — waere er aenderbar, waere er keine.
//
// NICHT HIER: der Loesungsbeleg. Der Index ist eine statische Datei in public/,
// also oeffentlich lesbar — auch fuer ein Kind mitten in der LSA (INV-6). Worauf
// sich die LOESUNG stuetzt, steht deshalb neben dem Loesungsweg (task_solutions.
// beleg, gegated auf Coach/Admin ueber task_solution_get — B01).

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, BookOpen, ChevronDown, ChevronRight, ExternalLink } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { getGrounding, hasGroundingSource } from '@/lib/authoring/grounding'
import type { GroundingRecord } from '@/types'
import { BelegQuote } from './BelegQuote'

function Section({ title, children }: { title: string; children: React.ReactNode }): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </span>
      {children}
    </div>
  )
}

/** Flags sind kein Schmuck: sie sind der Grund, warum das Item noch draft ist. */
function WarnList({ title, entries }: { title: string; entries: string[] }): JSX.Element | null {
  if (entries.length === 0) return null
  return (
    <div className="flex flex-col gap-1 rounded-[var(--radius-md)] bg-[var(--color-gold-warning)]/10 p-3">
      <span className="flex items-center gap-2 text-xs font-semibold text-[var(--color-gold-warning)]">
        <AlertTriangle className="h-3.5 w-3.5" />
        {title}
      </span>
      {entries.map((e, i) => (
        <span key={i} className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {e}
        </span>
      ))}
    </div>
  )
}

function RohTabelle({ table }: { table: NonNullable<GroundingRecord['tabelle_roh']> }): JSX.Element {
  const headers = table.headers ?? table.header ?? []
  const rows = table.rows ?? []
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-xs">
        <tbody>
          {[headers, ...rows].map((row, r) => (
            <tr key={r}>
              {row.map((cell, c) => (
                <td
                  key={c}
                  className="border border-[var(--color-border)] px-2 py-1 text-[var(--color-text-secondary)]"
                >
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
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
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">{t('grounding.hint')}</p>

          {!loaded && <p className="text-sm text-[var(--color-text-tertiary)]">…</p>}

          {loaded && !record && (
            <p className="text-sm text-[var(--color-text-tertiary)]">{t('grounding.unavailable')}</p>
          )}

          {record && (
            <>
              <WarnList title={t('grounding.importFlags')} entries={record.import_flags ?? []} />
              <WarnList title={t('grounding.flags')} entries={record.flags ?? []} />
              <WarnList title={t('grounding.problems')} entries={record.problems ?? []} />

              {record.teilaufgaben_roh && record.teilaufgaben_roh.length > 0 && (
                <Section title={t('grounding.rohteile')}>
                  <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
                    {t('grounding.rohteileHint')}
                  </p>
                  {record.teilaufgaben_roh.map((p) => (
                    <div
                      key={p.nr}
                      className="flex flex-col gap-1 border-l-2 border-[var(--color-border)] pl-3"
                    >
                      <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
                        {t('grounding.rohteil', { nr: p.nr, kind: p.kind })}
                      </span>
                      <span className="whitespace-pre-wrap text-sm leading-relaxed text-[var(--color-text-secondary)]">
                        {p.prompt}
                      </span>
                      {p.options && p.options.length > 0 && (
                        <span className="text-xs text-[var(--color-text-tertiary)]">
                          {p.options.map((o) => `${o.id}) ${o.label}`).join('   ')}
                        </span>
                      )}
                    </div>
                  ))}
                </Section>
              )}

              {record.tabelle_roh && (
                <Section title={t('grounding.rohtabelle')}>
                  <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
                    {t('grounding.rohtabelleHint')}
                  </p>
                  <RohTabelle table={record.tabelle_roh} />
                </Section>
              )}

              {record.belege && record.belege.length > 0 && (
                <Section title={t('grounding.belege')}>
                  <div className="flex flex-col gap-3">
                    {record.belege.map((b, i) => (
                      <BelegQuote key={i} beleg={b} />
                    ))}
                  </div>
                </Section>
              )}

              <p className="rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-3 text-xs leading-relaxed text-[var(--color-text-tertiary)]">
                {t('grounding.solutionElsewhere')}
              </p>

              {record.lizenz_status && (
                <Section title={t('grounding.license')}>
                  <span className="text-xs leading-relaxed text-[var(--color-text-secondary)]">
                    {record.lizenz_status}
                  </span>
                </Section>
              )}

              {record.iqb_urls && Object.keys(record.iqb_urls).length > 0 && (
                <Section title={t('grounding.sources')}>
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
                </Section>
              )}
            </>
          )}
        </div>
      )}
    </EdvanceCard>
  )
}
