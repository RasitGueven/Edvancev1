import { useEffect, useState, type FormEvent, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sparkles } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard } from '@/components/edvance'
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
    <main className="student-hero relative min-h-screen overflow-hidden">
      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-[420px] flex-col items-center justify-center gap-6 px-6 py-12">
        {/* Marken-Block: Kachel mit kalligrafischem Haken, Wortmarke, Subline */}
        <div className="flex h-[72px] w-[72px] items-center justify-center rounded-2xl bg-linear-to-br from-[var(--color-gold-altgold)] to-[var(--color-gold-champagner)] md:h-20 md:w-20">
          <EdvanceSymbol size={42} filled color="var(--color-primary)" />
        </div>

        <div className="flex flex-col items-center gap-2 text-center">
          <h1 className="font-serif text-4xl font-semibold text-[var(--color-bg-app)]">
            Edvance
          </h1>
          <p className="text-sm text-white/70">Melde dich an.</p>
        </div>

        {/* Formular: ruhige Glass-Card, mittig */}
        <EdvanceCard
          variant="glass"
          className="w-full rounded-[var(--radius-xl)] p-6 md:p-8"
        >
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="email" className="text-[var(--color-bg-app)]">
                E-Mail
              </Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                placeholder="name@beispiel.de"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
                className="h-11 border-white/20 bg-white/10 text-[var(--color-bg-app)] placeholder:text-white/40"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="password" className="text-[var(--color-bg-app)]">
                Passwort
              </Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                placeholder="••••••••"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
                className="h-11 border-white/20 bg-white/10 text-[var(--color-bg-app)] placeholder:text-white/40"
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
              className="mt-2 w-full bg-[var(--color-bg-app)] text-[var(--color-primary)] hover:brightness-105"
              loading={submitting}
            >
              {submitting ? 'Anmelden…' : 'Anmelden'}
            </Button>
          </form>
        </EdvanceCard>

        <div className="flex items-center gap-2 text-xs text-white/60">
          <Sparkles className="h-3.5 w-3.5 text-[var(--color-gold-champagner)]" />
          <span>Klasse 5 – 13 · Köln · Pre-Launch</span>
        </div>
      </div>
    </main>
  )
}
