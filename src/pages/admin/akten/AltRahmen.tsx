import type { ReactNode } from 'react'
import { AdminHeader } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'

export type AltKopf = {
  eyebrow?: string
  title: string
  description?: string
  backTo: string
  backLabel: string
  actions?: ReactNode
}

/**
 * Der bisherige Rahmen der Admin-Seiten — nur noch außerhalb der Hülle, also
 * für den Coach (Schülerakte, Content-Gesundheit, Eltern-Report), bis die
 * Coach-Sicht dieselbe Hülle bekommt (Bauauftrag Admin-Hülle, Entscheidung 12).
 * Danach fällt diese Datei weg. `blatt`: Druckbild des Eltern-Reports.
 */
export function AltRahmen({
  untertitel,
  breite,
  kopf,
  blatt = false,
  children,
}: {
  untertitel: string
  breite: 'max-w-7xl' | 'max-w-5xl' | 'max-w-3xl'
  kopf: AltKopf | null
  blatt?: boolean
  children: ReactNode
}): JSX.Element {
  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      {/* contents: der Wrapper bildet keine Box, die Leiste bleibt sticky. */}
      <div className="print-hide contents">
        <EdvanceNavbar subtitle={untertitel} sticky />
      </div>
      <main className={`mx-auto flex ${breite} flex-col gap-6 px-4 py-8 ${blatt ? 'report-sheet' : ''}`}>
        {kopf && (
          <div className={blatt ? 'print-hide contents' : 'contents'}>
            <AdminHeader {...kopf} />
          </div>
        )}
        {children}
      </main>
    </div>
  )
}
