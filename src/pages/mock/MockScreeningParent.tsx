/**
 * Eltern-Report als Mock-Showcase. v2-Design: ruhig, faktisch.
 * - Staerken in success-eltern (lebendiger als status-gruen).
 * - Luecken in error-gap (faktisches Rot, nicht warning-gelb).
 * - Coach-Notiz mit Primary-Akzent, kein Glas (Regel 3).
 */
import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { CompetencyRadar, type RadarAxis } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import {
  MOCK_CHILD,
  MOCK_CLUSTER_NAMES,
  MOCK_PARSED_RESULT,
} from '@/lib/mocks/screeningMock'
import { formatDateLongDe } from '@/lib/utils'
import type { ParsedClusterResult } from '@/lib/screening/screeningResult'

type StatusTone = 'gap' | 'erkennbar' | 'sicher'

function statusFor(displayLevel: number): { label: string; tone: StatusTone } {
  if (displayLevel <= 3) return { label: 'Lücke',     tone: 'gap'       }
  if (displayLevel <= 6) return { label: 'Erkennbar', tone: 'erkennbar' }
  return                       { label: 'Sicher',    tone: 'sicher'    }
}

const TONE_BADGE: Record<StatusTone, string> = {
  gap:       'bg-[var(--color-error-gap-light)] text-[var(--color-error-gap)]',
  erkennbar: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
  sicher:    'bg-[var(--color-success-eltern-light)] text-[var(--color-success-eltern)]',
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
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mock · Eltern-Report" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <Link
          to="/mock"
          className="inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)] transition-colors duration-fast hover:text-[var(--color-text-secondary)]"
        >
          <ArrowLeft className="h-4 w-4" /> Mock-Index
        </Link>

        <header className="rounded-[var(--radius-lg)] bg-[var(--color-primary)] px-5 py-4 text-white shadow-md">
          <p className="text-[10px] font-semibold uppercase tracking-widest text-white/70">Lernstand Ihres Kindes</p>
          <h1 className="mt-0.5 text-lg font-semibold">
            {MOCK_CHILD.fullName}{' '}
            <span className="text-sm font-normal text-white/80">· Klasse {MOCK_CHILD.classLevel}</span>
          </h1>
          <p className="mt-1 text-xs text-white/70">Stand: {completedAt}</p>
        </header>

        <div className="rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-6 shadow-md transition-all duration-fast ease-out hover:-translate-y-0.5 hover:shadow-md">
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            Eine ruhige Übersicht: wo steht Ihr Kind aktuell, was läuft gut, wo
            unterstützen wir gezielt.
          </p>

          <div className="mt-5 flex flex-col items-center gap-2">
            <CompetencyRadar axes={axes} max={10} />
            <p className="text-xs text-[var(--color-text-tertiary)]">
              Je weiter außen, desto sicherer ist Ihr Kind in diesem Bereich.
            </p>
          </div>

          <div className="mt-6 grid grid-cols-1 gap-4 md:grid-cols-2">
            <ReportColumn
              title="Stärken"
              accent="sicher"
              items={strengths.map((c) => ({ label: clusterLabel(c), status: statusFor(c.displayLevel) }))}
            />
            <ReportColumn
              title="Entwicklungsfelder"
              accent="gap"
              items={gaps.map((c) => ({ label: clusterLabel(c), status: statusFor(c.displayLevel) }))}
            />
          </div>

          {MOCK_CHILD.coachNote && (
            <div className="mt-6 rounded-[var(--radius-md)] border-l-2 border-[var(--color-primary)] bg-[var(--color-primary-light)] p-4">
              <p className="text-[10px] font-semibold uppercase tracking-widest text-[var(--color-primary)]">
                Notiz vom Coach
              </p>
              <p className="mt-2 text-sm leading-relaxed text-[var(--color-text-primary)]">
                {MOCK_CHILD.coachNote}
              </p>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

const ACCENT_TEXT: Record<'sicher' | 'gap', string> = {
  sicher: 'text-[var(--color-success-eltern)]',
  gap:    'text-[var(--color-error-gap)]',
}

function ReportColumn({
  title,
  accent,
  items,
}: {
  title: string
  accent: 'sicher' | 'gap'
  items: Array<{ label: string; status: { label: string; tone: StatusTone } }>
}): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <p className={`text-xs font-semibold uppercase tracking-widest ${ACCENT_TEXT[accent]}`}>
        {title}
      </p>
      {items.map((it) => (
        <div
          key={it.label}
          className="flex items-center justify-between gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3"
        >
          <span className="text-sm text-[var(--color-text-primary)]">{it.label}</span>
          <span className={`inline-flex items-center rounded-sm px-2 py-0.5 text-xs font-medium ${TONE_BADGE[it.status.tone]}`}>
            {it.status.label}
          </span>
        </div>
      ))}
    </div>
  )
}
