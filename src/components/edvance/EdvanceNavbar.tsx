import { Button } from '@/components/ui/button'
import { MarkenLogo } from '@/components/brand/MarkenLogo'
import { useAuth } from '@/hooks/useAuth'
import { cn } from '@/lib/utils'

type EdvanceNavbarProps = {
  subtitle: string
  sticky?: boolean
}

// Einheitliche Navbar für alle Dashboards mit Logo, Titel, User-Mail und Logout.
export function EdvanceNavbar({ subtitle, sticky = false }: EdvanceNavbarProps): JSX.Element {
  const { user, signOut } = useAuth()

  return (
    <nav
      className={cn(
        'glass-card flex items-center justify-between border-b border-[var(--color-border)] px-6 py-3',
        sticky && 'sticky top-0 z-30',
      )}
    >
      <div className="flex items-center gap-3">
        <div>
          <MarkenLogo />
          <p className="mt-0.5 text-xs text-[var(--color-text-tertiary)] leading-tight">
            {subtitle}
          </p>
        </div>
      </div>
      <div className="flex items-center gap-3">
        <span className="hidden text-xs text-[var(--color-text-tertiary)] sm:block">{user?.email}</span>
        <Button variant="ghost" size="sm" onClick={signOut}>
          Abmelden
        </Button>
      </div>
    </nav>
  )
}
