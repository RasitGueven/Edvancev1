import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { EdvanceCard, EdvanceBadge } from '@/components/edvance'
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
]

export function MockIndex(): JSX.Element {
  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Mock-Showcase" sticky />
      <main className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-10">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Mock-Showcase
          </h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Interaktive Vorschau der Screening-Auswertung ohne Supabase-Daten.
            Eingaben werden nicht persistiert.
          </p>
        </div>

        {ENTRIES.map((e) => (
          <Link key={e.href} to={e.href}>
            <EdvanceCard className="flex items-start justify-between gap-4 p-6 transition-transform hover:-translate-y-0.5">
              <div className="flex flex-1 flex-col gap-2">
                <div className="flex items-center gap-2">
                  <h2 className="text-base font-semibold text-[var(--text-primary)]">
                    {e.title}
                  </h2>
                  <EdvanceBadge variant="muted">{e.badge}</EdvanceBadge>
                </div>
                <p className="text-sm leading-relaxed text-[var(--text-secondary)]">
                  {e.description}
                </p>
              </div>
              <ArrowRight className="mt-1 h-5 w-5 text-[var(--text-muted)]" />
            </EdvanceCard>
          </Link>
        ))}
      </main>
    </div>
  )
}
