import type { ReactNode } from 'react'
import { EdvanceCard } from '@/components/edvance'
import { EdvanceLogo } from '@/components/brand/EdvanceLogo'
import type { UserRole } from '@/types'

/** Startseite je Rolle — dieselbe Weiche wie nach dem Login. */
export const ROLLEN_START: Record<UserRole, string> = {
  student: '/student',
  parent: '/parent',
  coach: '/coach',
  admin: '/admin',
}

type Props = {
  titel: string
  satz?: string
  children: ReactNode
}

/**
 * Rahmen der Konto-Seiten ausserhalb der Huelle (Einladung, neues Passwort,
 * Passwort vergessen). Flach und ruhig: Die Seiten sind fuer Mitarbeitende,
 * nicht der Schueler-Nachthimmel der Login-Seite.
 */
export function AuthRahmen({ titel, satz, children }: Props): JSX.Element {
  return (
    <main className="flex min-h-screen items-center justify-center bg-[var(--color-bg-app)] px-4 py-12">
      <EdvanceCard className="flex w-full max-w-[440px] flex-col gap-6 p-6 md:p-8">
        <EdvanceLogo size={20} />
        <div className="flex flex-col gap-2">
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">{titel}</h1>
          {satz && <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{satz}</p>}
        </div>
        {children}
      </EdvanceCard>
    </main>
  )
}
