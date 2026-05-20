// Eltern-Report als Mock-Showcase. Spiegelt /parent/screening, aber rein
// aus Frontend-Mocks für Stakeholder-Demos.

import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import {
  EdvanceCard,
  EdvanceBadge,
  CompetencyRadar,
  type RadarAxis,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import {
  MOCK_CHILD,
  MOCK_CLUSTER_NAMES,
  MOCK_PARSED_RESULT,
} from '@/lib/mocks/screeningMock'
import { formatDateLongDe } from '@/lib/utils'
import type { ParsedClusterResult } from '@/lib/screening/screeningResult'

function statusLabel(
  displayLevel: number,
): { label: string; variant: 'success' | 'primary' | 'warning' } {
  if (displayLevel <= 3) return { label: 'Lücke', variant: 'warning' }
  if (displayLevel <= 6) return { label: 'Erkennbar', variant: 'primary' }
  return { label: 'Sicher', variant: 'success' }
}

function clusterLabel(c: ParsedClusterResult): string {
  return MOCK_CLUSTER_NAMES.get(c.clusterId) ?? c.clusterId
}

export function MockScreeningParent(): JSX.Element {
  const completedAt = formatDateLongDe(new Date(MOCK_CHILD.completedAt))
  const sorted = [...MOCK_PARSED_RESULT.clusters].sort(
    (a, b) => b.displayLevel - a.displayLevel,
  )
  const strengths = sorted.slice(0, 2)
  const gaps = [...sorted].reverse().slice(0, 2)

  const axes: RadarAxis[] = MOCK_PARSED_RESULT.clusters.map((c) => ({
    label: clusterLabel(c),
    value: c.displayLevel,
  }))

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Mock · Eltern-Report" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <Link
          to="/mock"
          className="flex items-center gap-1 text-sm text-[var(--text-muted)]"
        >
          <ArrowLeft className="h-4 w-4" /> Mock-Index
        </Link>

        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Lernstand Ihres Kindes
          </h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Eine ruhige Übersicht: wo steht Ihr Kind aktuell, was läuft gut, wo
            unterstützen wir gezielt.
          </p>
        </div>

        <EdvanceCard variant="premium" className="flex flex-col gap-6 p-6">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <h2 className="text-xl font-bold text-[var(--text-primary)]">
                {MOCK_CHILD.fullName}
              </h2>
              <p className="text-xs text-[var(--text-muted)]">
                Klasse {MOCK_CHILD.classLevel}
              </p>
            </div>
            <EdvanceBadge variant="muted">Stand: {completedAt}</EdvanceBadge>
          </div>

          <div className="flex flex-col items-center gap-2">
            <CompetencyRadar axes={axes} max={10} />
            <p className="text-xs text-[var(--text-muted)]">
              Je weiter außen, desto sicherer ist Ihr Kind in diesem Bereich.
            </p>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <ReportColumn
              title="Stärken"
              accent="success"
              items={strengths.map((c) => ({
                label: clusterLabel(c),
                status: statusLabel(c.displayLevel),
              }))}
            />
            <ReportColumn
              title="Entwicklungsfelder"
              accent="warning"
              items={gaps.map((c) => ({
                label: clusterLabel(c),
                status: statusLabel(c.displayLevel),
              }))}
            />
          </div>

          {MOCK_CHILD.coachNote && (
            <div className="rounded-xl border border-[var(--primary-light)] bg-[var(--primary-pale)] p-4">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--primary)]">
                Notiz vom Coach
              </p>
              <p className="mt-2 text-sm leading-relaxed text-[var(--text-primary)]">
                {MOCK_CHILD.coachNote}
              </p>
            </div>
          )}
        </EdvanceCard>
      </main>
    </div>
  )
}

function ReportColumn({
  title,
  accent,
  items,
}: {
  title: string
  accent: 'success' | 'warning'
  items: Array<{ label: string; status: ReturnType<typeof statusLabel> }>
}): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <p
        className="text-xs font-semibold uppercase tracking-widest"
        style={{
          color: accent === 'success' ? 'var(--success)' : 'var(--warning)',
        }}
      >
        {title}
      </p>
      {items.map((it) => (
        <div
          key={it.label}
          className="flex items-center justify-between gap-2 rounded-xl border border-[var(--border)] bg-card p-3"
        >
          <span className="text-sm text-[var(--text-primary)]">{it.label}</span>
          <EdvanceBadge variant={it.status.variant}>
            {it.status.label}
          </EdvanceBadge>
        </div>
      ))}
    </div>
  )
}
