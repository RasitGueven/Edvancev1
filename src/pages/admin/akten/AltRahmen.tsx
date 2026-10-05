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
 * Der bisherige Rahmen der Schülerakte — nur noch außerhalb der Hülle, also
 * für den Coach, bis die Coach-Sicht dieselbe Hülle bekommt (Bauauftrag
 * Admin-Hülle, Entscheidung 12). Danach fällt diese Datei weg.
 */
export function AltRahmen({
  untertitel,
  breite,
  kopf,
  children,
}: {
  untertitel: string
  breite: 'max-w-7xl' | 'max-w-5xl'
  kopf: AltKopf | null
  children: ReactNode
}): JSX.Element {
  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={untertitel} sticky />
      <main className={`mx-auto flex ${breite} flex-col gap-6 px-4 py-8`}>
        {kopf && <AdminHeader {...kopf} />}
        {children}
      </main>
    </div>
  )
}
