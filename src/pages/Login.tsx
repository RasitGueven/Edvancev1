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

/* Verstreute Sterne: [x, y, r, opacity] im 1440×900-Raster. */
const STARS: Array<[number, number, number, number]> = [
  [90, 80, 1.4, 0.35], [210, 190, 1, 0.2], [340, 60, 1.8, 0.5],
  [470, 250, 1.2, 0.25], [560, 120, 1, 0.3], [660, 40, 1.6, 0.45],
  [740, 210, 1.1, 0.2], [830, 90, 2.2, 0.6], [920, 300, 1, 0.25],
  [1010, 150, 1.4, 0.4], [1120, 60, 1.2, 0.3], [1230, 230, 1.8, 0.55],
  [1330, 110, 1, 0.25], [1390, 330, 1.4, 0.35], [150, 420, 1.2, 0.2],
  [420, 480, 1, 0.25], [640, 430, 1.5, 0.35], [1080, 470, 1.1, 0.2],
  [1290, 540, 1.6, 0.4], [240, 640, 1, 0.2], [760, 620, 1.3, 0.3],
  [980, 720, 1, 0.2], [1180, 800, 1.4, 0.3], [520, 780, 1.1, 0.25],
  [60, 560, 1.8, 0.45], [880, 850, 1, 0.2],
]

/* Konstellations-Pfad: aufsteigend von links unten nach rechts oben.
   [x, y, r, opacity] — der oberste Punkt bekommt Glow-Halo separat. */
const CONSTELLATION: Array<[number, number, number, number]> = [
  [48, 388, 3.5, 0.4],
  [128, 330, 4.5, 0.55],
  [210, 258, 5.5, 0.7],
  [292, 172, 6.5, 0.85],
]
const CONSTELLATION_PEAK = { x: 368, y: 76, r: 9 }
const CONSTELLATION_LINE = [...CONSTELLATION, [CONSTELLATION_PEAK.x, CONSTELLATION_PEAK.y]]
  .map(([x, y]) => `${x},${y}`)
  .join(' ')

function NightSky(): JSX.Element {
  return (
    <svg
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 h-full w-full"
      viewBox="0 0 1440 900"
      preserveAspectRatio="xMidYMid slice"
    >
      {STARS.map(([x, y, r, opacity], index) => (
        <circle
          key={index}
          cx={x}
          cy={y}
          r={r}
          fill={index % 3 === 0 ? 'var(--color-gold-champagner)' : 'var(--color-bg-app)'}
          fillOpacity={opacity}
        />
      ))}
    </svg>
  )
}

function ConstellationPath(): JSX.Element {
  return (
    <svg
      aria-hidden="true"
      className="pointer-events-none absolute bottom-4 left-2 h-[38vh] max-h-[420px] w-auto opacity-50 md:bottom-8 md:left-8 md:h-[52vh] md:opacity-100"
      viewBox="0 0 420 440"
      fill="none"
    >
      <defs>
        <linearGradient id="constellation-line" x1="0" y1="440" x2="420" y2="0" gradientUnits="userSpaceOnUse">
          <stop offset="0" stopColor="var(--color-gold-altgold)" stopOpacity="0.35" />
          <stop offset="1" stopColor="var(--color-accent)" stopOpacity="0.9" />
        </linearGradient>
        <radialGradient id="constellation-glow">
          <stop offset="0" stopColor="var(--color-accent)" stopOpacity="0.45" />
          <stop offset="1" stopColor="var(--color-accent)" stopOpacity="0" />
        </radialGradient>
      </defs>
      <polyline
        points={CONSTELLATION_LINE}
        stroke="url(#constellation-line)"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      {CONSTELLATION.map(([x, y, r, opacity], index) => (
        <circle key={index} cx={x} cy={y} r={r} fill="var(--color-gold-altgold)" fillOpacity={opacity} />
      ))}
      {/* Glow-Halo nur am hellsten Punkt — trägt das Sternen-Motiv */}
      <circle cx={CONSTELLATION_PEAK.x} cy={CONSTELLATION_PEAK.y} r={34} fill="url(#constellation-glow)" />
      <circle cx={CONSTELLATION_PEAK.x} cy={CONSTELLATION_PEAK.y} r={CONSTELLATION_PEAK.r} fill="var(--color-accent)" />
    </svg>
  )
}

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
      <NightSky />
      <ConstellationPath />

      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center gap-10 px-6 py-12 md:flex-row md:items-center md:justify-between md:gap-16 md:px-12">
        {/* Marken-Block: goldene Kachel mit kalligrafischem Haken, Wortmarke, Zeile */}
        <aside className="flex flex-col items-center gap-4 text-center md:max-w-md md:items-start md:gap-6 md:text-left">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-linear-to-br from-[var(--color-gold-altgold)] to-[var(--color-gold-champagner)] md:h-20 md:w-20">
            <EdvanceSymbol size={38} filled color="var(--color-primary)" className="md:hidden" />
            <EdvanceSymbol size={48} filled color="var(--color-primary)" className="hidden md:block" />
          </div>
          <h1 className="font-serif text-4xl font-semibold text-[var(--color-bg-app)] md:text-5xl">
            Edvance
          </h1>
          <p className="text-sm text-[var(--color-gold-champagner)] md:text-base md:leading-relaxed">
            Hybride Lernakademie · Kleingruppen · Tablet-Lernpfad
          </p>
        </aside>

        {/* Formular: dunkle Glass-Card im Nachthimmel */}
        <EdvanceCard
          variant="glass"
          className="w-full max-w-[420px] shrink-0 rounded-[var(--radius-xl)] p-6 md:p-8"
        >
          <div className="mb-8">
            <h2 className="font-serif text-2xl font-semibold text-[var(--color-bg-app)]">
              Willkommen zurück
            </h2>
            <p className="mt-2 text-sm text-white/70">
              Melde dich an, um weiterzulernen
            </p>
          </div>

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

          <div className="mt-6 flex items-center gap-2 text-xs text-[var(--color-gold-champagner)]">
            <Sparkles className="h-3.5 w-3.5 text-[var(--color-accent)]" />
            <span>Klasse 5 – 13 · Köln · Pre-Launch</span>
          </div>
        </div>
      </div>
    </main>
  )
}
