import { useEffect, useState, type JSX } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  AdminHeader,
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { getCoaches } from '@/lib/supabase/profiles'
import { provisionCoach } from '@/lib/supabase/provisionCoach'
import type { Coach } from '@/types'

export function CoachesPage(): JSX.Element {
  const [coaches, setCoaches] = useState<Coach[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [saving, setSaving] = useState(false)
  const [created, setCreated] = useState<string | null>(null)

  const load = (): void => {
    setLoading(true)
    void getCoaches().then(({ data, error: e }) => {
      setCoaches(data ?? [])
      setError(e)
      setLoading(false)
    })
  }

  useEffect(load, [])

  const submit = async (): Promise<void> => {
    if (fullName.trim() === '' || email.trim() === '' || password.length < 6) {
      setError('Name, E-Mail und Passwort (min. 6 Zeichen) erforderlich.')
      return
    }
    setSaving(true)
    setError(null)
    setCreated(null)
    const { error: err } = await provisionCoach({
      full_name: fullName.trim(),
      email: email.trim(),
      password,
    })
    setSaving(false)
    if (err) {
      setError(err)
      return
    }
    setCreated(fullName.trim())
    setFullName('')
    setEmail('')
    setPassword('')
    load()
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle="Coaches" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow="Team"
          title="Coaches"
          description="Coach-Accounts anlegen und Zugangsdaten vergeben."
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}
        {created && (
          <p className="text-sm text-[var(--color-success)]">
            Coach „{created}" angelegt. Zugangsdaten persönlich mitteilen.
          </p>
        )}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Neuer Coach
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-name">Name *</Label>
              <Input
                id="c-name"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-email">E-Mail *</Label>
              <Input
                id="c-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-pw">Passwort (min. 6 Zeichen) *</Label>
              <Input
                id="c-pw"
                type="text"
                autoComplete="off"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>
          <div>
            <Button onClick={submit} disabled={saving}>
              {saving ? 'Legt an …' : 'Coach anlegen'}
            </Button>
          </div>
        </EdvanceCard>

        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Bestehende Coaches
        </p>
        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : coaches.length === 0 ? (
          <EmptyState
            icon="🧑‍🏫"
            title="Noch keine Coaches"
            description="Lege oben den ersten Coach an."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {coaches.map((c) => (
              <EdvanceCard
                key={c.id}
                className="flex flex-wrap items-center justify-between gap-2 p-6"
              >
                <span className="text-base font-semibold text-[var(--color-text-primary)]">
                  {c.full_name ?? 'Unbenannt'}
                </span>
                <EdvanceBadge variant="mastered">Coach</EdvanceBadge>
              </EdvanceCard>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
