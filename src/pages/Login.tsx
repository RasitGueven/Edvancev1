import { useEffect, useState, type FormEvent, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sparkles } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceAppIcon } from '@/components/brand/EdvanceLogo'
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
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden bg-gradient-hero noise-overlay px-4 py-12">
      {/* Goldene Glow-Akzente */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-32 -right-32 h-96 w-96 rounded-full opacity-30 blur-3xl"
        style={{ background: 'var(--color-moment-gold)' }}
      />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -bottom-32 -left-32 h-96 w-96 rounded-full opacity-20 blur-3xl"
        style={{ background: 'var(--color-primary-light)' }}
      />

      {/* Glass-Card */}
      <div className="relative w-full max-w-md">
        <div className="glass-light rounded-[var(--radius-xl)] shadow-premium-xl p-8">
          {/* Logo + Headline */}
          <div className="flex flex-col items-center gap-4 mb-8">
            <div className="relative">
              <div className="absolute inset-0 rounded-2xl bg-gradient-gold blur-xl opacity-50" aria-hidden="true" />
              <EdvanceAppIcon size={64} className="relative shadow-premium-md" />
            </div>

            <div className="text-center">
              <h1 className="text-display text-3xl text-[var(--color-text-primary)]">
                Edvance
              </h1>
              <p className="mt-1 text-sm text-[var(--text-muted)]">
                Hybride Lernakademie · Kleingruppen · Tablet-Lernpfad
              </p>
            </div>
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

          <div className="mt-6 flex items-center justify-center gap-2 text-xs text-[var(--text-muted)]">
            <Sparkles className="h-3.5 w-3.5" />
            <span>Klasse 5 – 13 · Köln · Pre-Launch</span>
          </div>
        </div>
      </div>
    </main>
  )
}
