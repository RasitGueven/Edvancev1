import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'

type MockEntry = {
  href: string
  title: string
  description: string
  badge: string
}

const ENTRIES: MockEntry[] = [
  {
    href: '/mock/screening-coach',
    title: 'Coach-Auswertung',
    description:
      'KPI-Reihe, Kompetenz-Radar, Cluster-Karten mit AFB-Badges und eine interaktive Bewertungs-Inbox — alles aus Mock-Daten.',
    badge: 'Coach',
  },
  {
    href: '/mock/screening-parent',
    title: 'Eltern-Report',
    description:
      'Kuratierte Sicht für Eltern: Radar, Stärken & Entwicklungsfelder als qualitative Labels, Coach-Notiz.',
    badge: 'Eltern',
  },
  {
    href: '/mock/dnd-widgets',
    title: 'Drag-and-Drop-Widgets',
    description:
      'Lückentext mit Wort-Pool und Tabellen-Beschriftung. Maus, Touch und Tap-Fallback für Drag-faule Geräte.',
    badge: 'Widgets',
  },
  {
    href: '/mock/task-widgets',
    title: 'Basis-Widgets',
    description:
      'MC, Zahl, Freitext und Multi-Step im v2-Look — Touch-Targets, Focus-States, Hover-Lift.',
    badge: 'Widgets',
  },
]

export function MockIndex(): JSX.Element {
  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mock-Showcase" sticky />
      <main className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-10">
        <div>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Mock-Showcase
          </h1>
          <p className="mt-1 text-sm leading-relaxed text-[var(--color-text-secondary)]">
            Interaktive Vorschau der Screening-Auswertung ohne Supabase-Daten.
            Eingaben werden nicht persistiert.
          </p>
        </div>

        {ENTRIES.map((e) => (
          <Link key={e.href} to={e.href} className="group">
            <div className="flex items-start justify-between gap-4 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-6 shadow-md transition-all duration-base ease-bounce hover:-translate-y-0.5 hover:shadow-lg">
              <div className="flex flex-1 flex-col gap-2">
                <div className="flex items-center gap-2">
                  <h2 className="text-base font-semibold text-[var(--color-text-primary)]">
                    {e.title}
                  </h2>
                  <span className="inline-flex items-center rounded-sm bg-[var(--color-primary-light)] px-2 py-0.5 text-xs font-medium text-[var(--color-primary)]">
                    {e.badge}
                  </span>
                </div>
                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                  {e.description}
                </p>
              </div>
              <ArrowRight className="mt-1 h-5 w-5 text-[var(--color-text-tertiary)] transition-transform duration-fast group-hover:translate-x-0.5" />
            </div>
          </Link>
        ))}
      </main>
    </div>
  )
}
