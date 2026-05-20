/**
 * Coach-Auswertung als Mock-Showcase. v2-Design: ruhig/sachlich,
 * blau-getoente Shadows, v2-Tokens, error-coach fuer offene
 * Bewertungen, success-eltern als status-positiv im Kompetenz-Kontext.
 */
import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import {
  MasteryBar,
  CompetencyRadar,
  type RadarAxis,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { formatMedianSeconds } from '@/lib/screening/results/kpis'
import {
  MOCK_CHILD,
  MOCK_CLUSTER_NAMES,
  MOCK_KPIS,
  MOCK_MEDIAN_BY_CLUSTER,
  MOCK_PARSED_RESULT,
  MOCK_PENDING_ITEMS,
} from '@/lib/mocks/screeningMock'
import type { ScreeningAfb } from '@/types'

const AFBS: ScreeningAfb[] = ['I', 'II', 'III']

type AfbTone = 'success' | 'primary' | 'gold' | 'muted'

function afbTone(afb: ScreeningAfb | null): AfbTone {
  if (afb === 'I')   return 'success'
  if (afb === 'II')  return 'primary'
  if (afb === 'III') return 'gold'
  return 'muted'
}

const TONE_BADGE: Record<AfbTone, string> = {
  success: 'bg-[var(--color-success-light)] text-[var(--color-success)]',
  primary: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
  gold:    'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]',
  muted:   'bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)]',
}

function V2Card({ children, className = '' }: { children: JSX.Element | JSX.Element[]; className?: string }): JSX.Element {
  return (
    <div className={`rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-5 shadow-md ${className}`}>
      {children}
    </div>
  )
}

function StatBox({ label, value, hint, tone = 'neutral' }: {
  label: string
  value: string | number
  hint?: string
  tone?: 'neutral' | 'success' | 'warning' | 'primary'
}): JSX.Element {
  const toneText: Record<typeof tone, string> = {
    neutral: 'text-[var(--color-text-primary)]',
    success: 'text-[var(--color-success)]',
    warning: 'text-[var(--color-gold-warning)]',
    primary: 'text-[var(--color-primary)]',
  }
  return (
    <div className="rounded-[var(--radius-lg)] bg-[var(--color-bg-subtle)] p-4">
      <p className="text-[10px] font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{label}</p>
      <p className={`mt-1 text-3xl font-bold ${toneText[tone]}`}>{value}</p>
      {hint ? <p className="mt-1 text-xs text-[var(--color-text-tertiary)]">{hint}</p> : null}
    </div>
  )
}

export function MockScreeningCoach(): JSX.Element {
  const [drafts, setDrafts] = useState<
    Record<string, { afb: ScreeningAfb | null; note: string; saved: boolean }>
  >({})

  const setDraft = (
    id: string,
    patch: Partial<{ afb: ScreeningAfb | null; note: string; saved: boolean }>,
  ): void => {
    setDrafts((prev) => ({
      ...prev,
      [id]: {
        afb: prev[id]?.afb ?? null,
        note: prev[id]?.note ?? '',
        saved: prev[id]?.saved ?? false,
        ...patch,
      },
    }))
  }

  const pendingRemaining = MOCK_PENDING_ITEMS.filter((p) => !drafts[p.id]?.saved).length

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mock · Coach-Auswertung" sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/mock"
            className="mb-2 inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)] transition-colors duration-fast hover:text-[var(--color-text-secondary)]"
          >
            <ArrowLeft className="h-4 w-4" /> Mock-Index
          </Link>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            {MOCK_CHILD.fullName}{' '}
            <span className="text-base font-normal text-[var(--color-text-tertiary)]">
              · Kl. {MOCK_CHILD.classLevel}
            </span>
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            Lernstand-Check vom 14. Mai 2026 · Beispiel-Daten, nicht persistent.
          </p>
        </div>

        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          <StatBox label="Beantwortet" value={MOCK_PARSED_RESULT.overallAnswered} />
          <StatBox label="Trefferquote" value={`${MOCK_PARSED_RESULT.overallPct}%`} tone="success" />
          <StatBox label="Ø Zeit / Aufgabe" value={formatMedianSeconds(MOCK_KPIS.medianDurationMs)} tone="primary" />
          <StatBox
            label="Wartet auf Bewertung"
            value={pendingRemaining}
            tone={pendingRemaining > 0 ? 'warning' : 'neutral'}
            hint={pendingRemaining > 0 ? 'offen' : 'alle bewertet'}
          />
        </div>

        <V2Card className="flex flex-col items-center gap-2">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Kompetenz-Profil
          </h2>
          <CompetencyRadar
            axes={MOCK_PARSED_RESULT.clusters.map<RadarAxis>((c) => ({
              label: MOCK_CLUSTER_NAMES.get(c.clusterId) ?? c.clusterId,
              value: c.displayLevel,
            }))}
            max={10}
          />
        </V2Card>

        <div className="flex flex-col gap-4">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Kompetenzbereiche
          </h2>
          {MOCK_PARSED_RESULT.clusters.map((c) => {
            const med = MOCK_MEDIAN_BY_CLUSTER.get(c.clusterId) ?? 0
            const tone = afbTone(c.reachedAfb)
            return (
              <V2Card key={c.clusterId} className="flex flex-col gap-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-base font-semibold text-[var(--color-text-primary)]">
                    {MOCK_CLUSTER_NAMES.get(c.clusterId) ?? c.clusterId}
                  </span>
                  <div className="flex flex-wrap items-center gap-2">
                    {c.pending > 0 && (
                      <span className="inline-flex items-center rounded-sm bg-[var(--color-gold-warning-light)] px-2 py-0.5 text-xs font-medium text-[var(--color-gold-warning)]">
                        {c.pending} offen
                      </span>
                    )}
                    <span className={`inline-flex items-center rounded-sm px-2 py-0.5 text-xs font-medium ${TONE_BADGE[tone]}`}>
                      {c.reachedAfb ? `AFB ${c.reachedAfb}` : 'unter AFB I'}
                    </span>
                  </div>
                </div>
                <MasteryBar level={c.displayLevel} showLabel />
                <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-[var(--color-text-secondary)]">
                  <span>Beantwortet: {c.answered}</span>
                  <span>Richtig: {c.correct}</span>
                  <span>Trefferquote: {Math.round(c.mastery * 100)}%</span>
                  {med > 0 && <span>Ø Zeit: {formatMedianSeconds(med)}</span>}
                </div>
              </V2Card>
            )
          })}
        </div>

        <div className="flex flex-col gap-3">
          <div className="flex items-baseline justify-between">
            <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              Wartet auf Bewertung
            </h2>
            <span className="text-xs text-[var(--color-text-tertiary)]">{pendingRemaining} offen</span>
          </div>
          {MOCK_PENDING_ITEMS.map((p) => {
            const d = drafts[p.id] ?? { afb: null, note: '', saved: false }
            return (
              <V2Card key={p.id} className="flex flex-col gap-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                    {MOCK_CLUSTER_NAMES.get(p.clusterId) ?? p.clusterId}
                  </span>
                  {d.saved ? (
                    <span className="inline-flex items-center rounded-sm bg-[var(--color-success-light)] px-2 py-0.5 text-xs font-medium text-[var(--color-success)]">
                      Bewertet: AFB {d.afb}
                    </span>
                  ) : (
                    <span className="inline-flex items-center rounded-sm bg-[var(--color-error-coach-light)] px-2 py-0.5 text-xs font-medium text-[var(--color-error-coach)]">
                      offen
                    </span>
                  )}
                </div>
                <p className="text-sm leading-relaxed text-[var(--color-text-primary)]">
                  {p.prompt}
                </p>
                <div className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3">
                  <p className="text-xs font-semibold text-[var(--color-text-tertiary)]">
                    Schüler-Antwort
                  </p>
                  <p className="mt-1 whitespace-pre-wrap text-sm text-[var(--color-text-primary)]">
                    {p.answer}
                  </p>
                </div>
                <div className="flex flex-wrap gap-2">
                  {AFBS.map((afb) => {
                    const selected = d.afb === afb
                    return (
                      <button
                        key={afb}
                        type="button"
                        onClick={() => setDraft(p.id, { afb })}
                        className={[
                          'min-h-[44px] flex-1 rounded-[var(--radius-md)] border px-3 text-sm font-semibold transition-all duration-fast',
                          selected
                            ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)] shadow-md'
                            : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)] hover:bg-[var(--color-primary-light)]',
                        ].join(' ')}
                      >
                        AFB {afb}
                      </button>
                    )
                  })}
                </div>
                <textarea
                  value={d.note}
                  onChange={(e) => setDraft(p.id, { note: e.target.value })}
                  placeholder="Notiz (optional)"
                  rows={2}
                  className="min-h-[60px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm leading-relaxed text-[var(--color-text-primary)] shadow-xs transition-all duration-instant focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/10"
                />
                <button
                  type="button"
                  disabled={!d.afb || d.saved}
                  onClick={() => setDraft(p.id, { saved: true })}
                  className="min-h-[44px] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-5 text-sm font-medium text-white shadow-md transition-all duration-fast ease-out hover:-translate-y-0.5 hover:bg-[var(--color-primary-hover)] disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:translate-y-0"
                >
                  {d.saved ? 'Gespeichert (Mock)' : 'Bewertung speichern (Mock)'}
                </button>
              </V2Card>
            )
          })}
        </div>
      </main>
    </div>
  )
}
