import { useEffect, useState, type FormEvent, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sparkles } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceSymbol } from '@/components/brand/EdvanceLogo'
import type { UserRole } from '@/types'

const ROLE_ROUTES: Record<UserRole, string> = {
  student: '/student',
  parent: '/parent',
  coach: '/coach',
  admin: '/admin',
}

const ERROR_INVALID_CREDENTIALS = 'E-Mail oder Passwort falsch.'

export function Login(): JSX.Element {
  const { signIn, role, loading } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState<string>('')
  const [password, setPassword] = useState<string>('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState<boolean>(false)

  useEffect(() => {
    if (!loading && role && ROLE_ROUTES[role]) {
      navigate(ROLE_ROUTES[role], { replace: true })
    }
  }, [loading, role, navigate])

  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault()
    setError(null)
    setSubmitting(true)
    const { error: signInError } = await signIn(email, password)
    setSubmitting(false)
    if (signInError) setError(ERROR_INVALID_CREDENTIALS)
  }

  return (
    <main className="flex min-h-screen flex-col md:flex-row">
      {/* Linke Marken-Flaeche: Navy, flaechig, ohne Glow */}
      <aside className="flex shrink-0 flex-row items-center justify-center gap-4 bg-[var(--color-navy-deep)] px-6 py-6 md:w-[45%] md:flex-col md:justify-center md:gap-10 md:px-10 md:py-16">
        {/* Freies Symbol statt Kachel — Navy auf Navy verschwindet sonst.
            Creme-Strich fuer Kontrast, goldener Pfeil als Marken-Akzent. */}
        <EdvanceSymbol
          size={44}
          color="var(--color-bg-app)"
          accentColor="var(--color-accent)"
          className="md:hidden"
        />
        <EdvanceSymbol
          size={120}
          color="var(--color-bg-app)"
          accentColor="var(--color-accent)"
          className="hidden md:block"
        />
        <p className="text-sm text-[var(--color-gold-champagner)] md:max-w-xs md:text-center md:text-base md:leading-relaxed">
          Hybride Lernakademie · Kleingruppen · Tablet-Lernpfad
        </p>
      </aside>

      {/* Rechte Spalte: Formular */}
      <div className="flex flex-1 items-center justify-center bg-[var(--color-bg-app)] px-6 py-12">
        <div className="w-full max-w-[380px]">
          <div className="mb-8">
            <h1 className="text-display text-3xl text-[var(--color-text-primary)]">
              Edvance
            </h1>
            <p className="mt-2 text-sm text-[var(--color-text-secondary)]">
              Willkommen zurück
            </p>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="email">E-Mail</Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                placeholder="name@beispiel.de"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
                className="h-11"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="password">Passwort</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                placeholder="••••••••"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
                className="h-11"
              />
            </div>

            {error && (
              <p className="rounded-lg bg-[var(--color-error-light)] px-3 py-2 text-sm font-medium text-[var(--color-error)]">
                {error}
              </p>
            )}

            <Button
              type="submit"
              size="lg"
              className="mt-2 w-full"
              loading={submitting}
            >
              {submitting ? 'Anmelden…' : 'Anmelden'}
            </Button>
          </form>

          <div className="mt-6 flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
            <Sparkles className="h-3.5 w-3.5" />
            <span>Klasse 5 – 13 · Köln · Pre-Launch</span>
          </div>
        </div>
      </div>
    </main>
  )
}
