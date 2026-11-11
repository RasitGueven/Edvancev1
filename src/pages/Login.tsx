import { useEffect, useState, type FormEvent, type JSX } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { MarkenLogo } from '@/components/brand/MarkenLogo'
import { ROLLEN_START as ROLE_ROUTES } from '@/pages/auth/AuthRahmen'
import { LoginHorizont, LoginSterne } from '@/pages/login/LoginHimmel'

export function Login(): JSX.Element {
  const { t } = useTranslation('konto')
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
    if (signInError) setError(t('login.falsch'))
  }

  // CI-1 Teil A: vollflächiger Nachthimmel, Horizont aus der Logo-Schale mit
  // Amber-Lichtpunkt, Ivory-Karte schwebt rechts (Hochformat: mittig).
  return (
    <main className="marke-himmel relative min-h-dvh overflow-x-hidden">
      <LoginSterne />
      <LoginHorizont className="absolute inset-x-0 bottom-0 h-[42vh] min-h-[240px] w-full" />

      <div className="relative z-10 mx-auto flex min-h-dvh w-full max-w-6xl flex-col items-center gap-6 px-6 pb-[max(1.5rem,env(safe-area-inset-bottom))] pt-[max(2rem,env(safe-area-inset-top))] md:landscape:flex-row md:landscape:items-stretch md:landscape:justify-between md:landscape:gap-16 md:landscape:px-12 md:landscape:py-12">
        <aside className="contents md:landscape:flex md:landscape:max-w-md md:landscape:flex-col md:landscape:justify-between">
          <MarkenLogo grund="dunkel" className="order-1 h-9 md:h-11" />
          <div className="order-4 flex flex-col items-center gap-2 text-center md:landscape:items-start md:landscape:text-left">
            <p className="text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-marke-ivory)_82%,transparent)]">
              {t('login.markeZeile')}
            </p>
            <p className="text-xs tabular-nums text-[color-mix(in_srgb,var(--color-marke-ivory)_64%,transparent)]">
              {t('login.fuss')}
            </p>
          </div>
        </aside>

        <section className="order-2 w-full max-w-[420px] shrink-0 self-center rounded-[var(--radius-flaeche)] bg-[var(--color-marke-ivory)] p-6 text-[var(--color-marke-navy)] shadow-[var(--shadow-marke-schwebend)] md:p-8">
          <div className="mb-6 flex flex-col gap-2">
            <h1 className="text-2xl font-bold">{t('login.titel')}</h1>
            <p className="text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-marke-navy)_72%,transparent)]">
              {t('login.satz')}
            </p>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="email" className="text-[var(--color-marke-navy)]">
                {t('login.email')}
              </Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                placeholder={t('login.emailPlatzhalter')}
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
                className="marke-feld h-12 focus-visible:ring-0"
              />
            </div>

            <div className="flex flex-col gap-2">
              <Label htmlFor="password" className="text-[var(--color-marke-navy)]">
                {t('login.passwort')}
              </Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                placeholder="••••••••"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
                className="marke-feld h-12 focus-visible:ring-0"
              />
            </div>

            {error && (
              <p className="rounded-[var(--radius-md)] bg-[var(--color-error-exam-light)] px-3 py-2 text-sm font-medium text-[var(--color-error-exam)]">
                {error}
              </p>
            )}

            <Button
              type="submit"
              size="lg"
              className="marke-knopf mt-2 w-full rounded-[var(--radius-feld)] hover:translate-y-0 hover:brightness-105"
              loading={submitting}
            >
              {submitting ? t('login.meldetAn') : t('login.anmelden')}
            </Button>
          </form>

          <Link
            to="/auth/passwort-vergessen"
            className="mt-4 inline-flex min-h-[44px] items-center text-sm font-medium text-[var(--color-marke-cobalt)] hover:underline"
          >
            {t('login.vergessen')}
          </Link>
        </section>

        {/* Hochformat: Platz für Horizont und Lichtpunkt unter der Karte */}
        <div aria-hidden="true" className="order-3 min-h-[16vh] flex-1 md:landscape:hidden" />
      </div>
    </main>
  )
}
