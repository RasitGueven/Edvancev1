// Coach-Auswertung als Mock-Showcase: rendert das gleiche Layout wie
// /coach/screening-results, aber rein aus Frontend-Mocks. Hilfreich für
// Stakeholder-Demos und visuelle Reviews ohne Supabase-Daten.

import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import {
  EdvanceCard,
  EdvanceBadge,
  MasteryBar,
  StatCard,
  CompetencyRadar,
  type RadarAxis,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
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

function afbVariant(
  afb: ScreeningAfb | null,
): 'muted' | 'success' | 'primary' | 'xp' {
  return afb === 'I' ? 'success' : afb === 'II' ? 'primary' : afb === 'III' ? 'xp' : 'muted'
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

  const pendingRemaining = MOCK_PENDING_ITEMS.filter(
    (p) => !drafts[p.id]?.saved,
  ).length
  const pendingDisplay = pendingRemaining

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Mock · Coach-Auswertung" sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/mock"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Mock-Index
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            {MOCK_CHILD.fullName}{' '}
            <span className="text-base font-normal text-[var(--text-muted)]">
              · Kl. {MOCK_CHILD.classLevel}
            </span>
          </h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Lernstand-Check vom 14. Mai 2026 · Beispiel-Daten, nicht persistent.
          </p>
        </div>

        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          <StatCard
            icon="📝"
            label="Beantwortet"
            value={MOCK_PARSED_RESULT.overallAnswered}
          />
          <StatCard
            icon="⚡"
            label="Trefferquote"
            value={`${MOCK_PARSED_RESULT.overallPct}%`}
            color="var(--success)"
          />
          <StatCard
            icon="⏱️"
            label="Ø Zeit / Aufgabe"
            value={formatMedianSeconds(MOCK_KPIS.medianDurationMs)}
            color="var(--info)"
          />
          <StatCard
            icon="🧑‍🏫"
            label="Wartet auf Bewertung"
            value={pendingDisplay}
            color={
              pendingDisplay > 0 ? 'var(--warning)' : 'var(--text-muted)'
            }
          />
        </div>

        <EdvanceCard className="flex flex-col items-center gap-2 p-6">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
            Kompetenz-Profil
          </h2>
          <CompetencyRadar
            axes={MOCK_PARSED_RESULT.clusters.map<RadarAxis>((c) => ({
              label: MOCK_CLUSTER_NAMES.get(c.clusterId) ?? c.clusterId,
              value: c.displayLevel,
            }))}
            max={10}
          />
        </EdvanceCard>

        <div className="flex flex-col gap-4">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
            Kompetenzbereiche
          </h2>
          {MOCK_PARSED_RESULT.clusters.map((c) => {
            const med = MOCK_MEDIAN_BY_CLUSTER.get(c.clusterId) ?? 0
            return (
              <EdvanceCard
                key={c.clusterId}
                className="flex flex-col gap-3 p-5"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-base font-semibold text-[var(--text-primary)]">
                    {MOCK_CLUSTER_NAMES.get(c.clusterId) ?? c.clusterId}
                  </span>
                  <div className="flex flex-wrap items-center gap-2">
                    {c.pending > 0 && (
                      <EdvanceBadge variant="warning">
                        {c.pending} offen
                      </EdvanceBadge>
                    )}
                    <EdvanceBadge variant={afbVariant(c.reachedAfb)}>
                      {c.reachedAfb ? `AFB ${c.reachedAfb}` : 'unter AFB I'}
                    </EdvanceBadge>
                  </div>
                </div>
                <MasteryBar level={c.displayLevel} showLabel />
                <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-[var(--text-secondary)]">
                  <span>Beantwortet: {c.answered}</span>
                  <span>Richtig: {c.correct}</span>
                  <span>Trefferquote: {Math.round(c.mastery * 100)}%</span>
                  {med > 0 && <span>Ø Zeit: {formatMedianSeconds(med)}</span>}
                </div>
              </EdvanceCard>
            )
          })}
        </div>

        <div className="flex flex-col gap-3">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
            Wartet auf Bewertung ({pendingRemaining})
          </h2>
          {MOCK_PENDING_ITEMS.map((p) => {
            const d = drafts[p.id] ?? { afb: null, note: '', saved: false }
            return (
              <EdvanceCard key={p.id} className="flex flex-col gap-3 p-5">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                    {MOCK_CLUSTER_NAMES.get(p.clusterId) ?? p.clusterId}
                  </span>
                  {d.saved ? (
                    <EdvanceBadge variant="success">
                      Bewertet: AFB {d.afb}
                    </EdvanceBadge>
                  ) : (
                    <EdvanceBadge variant="warning">offen</EdvanceBadge>
                  )}
                </div>
                <p className="text-sm leading-relaxed text-[var(--text-primary)]">
                  {p.prompt}
                </p>
                <div className="rounded-xl border border-[var(--border)] bg-[var(--background)] p-3">
                  <p className="text-xs font-semibold text-[var(--text-muted)]">
                    Schüler-Antwort
                  </p>
                  <p className="mt-1 whitespace-pre-wrap text-sm text-[var(--text-primary)]">
                    {p.answer}
                  </p>
                </div>
                <div className="flex flex-wrap gap-2">
                  {AFBS.map((afb) => (
                    <button
                      key={afb}
                      type="button"
                      onClick={() => setDraft(p.id, { afb })}
                      className={[
                        'min-h-[44px] flex-1 rounded-xl border-2 px-3 text-sm font-semibold transition-colors',
                        d.afb === afb
                          ? 'border-[var(--primary)] bg-[var(--primary-pale)] text-[var(--primary)]'
                          : 'border-[var(--border)] bg-card text-[var(--text-secondary)] hover:border-[var(--primary-light)]',
                      ].join(' ')}
                    >
                      AFB {afb}
                    </button>
                  ))}
                </div>
                <textarea
                  value={d.note}
                  onChange={(e) => setDraft(p.id, { note: e.target.value })}
                  placeholder="Notiz (optional)"
                  rows={2}
                  className="min-h-[60px] w-full rounded-xl border-2 border-[var(--border)] bg-card p-3 text-sm leading-relaxed text-foreground focus:border-[var(--primary)] focus:outline-none"
                />
                <Button
                  size="lg"
                  className="rounded-xl"
                  disabled={!d.afb || d.saved}
                  onClick={() => setDraft(p.id, { saved: true })}
                >
                  {d.saved
                    ? 'Gespeichert (Mock)'
                    : 'Bewertung speichern (Mock)'}
                </Button>
              </EdvanceCard>
            )
          })}
        </div>
      </main>
    </div>
  )
}
