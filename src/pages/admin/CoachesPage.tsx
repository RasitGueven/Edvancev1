import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { getCoaches } from '@/lib/supabase/profiles'
import { provisionCoach } from '@/lib/supabase/provisionCoach'
import type { Coach } from '@/types'

export function CoachesPage(): JSX.Element {
  const { t } = useTranslation('admin')
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
      setError(t('coaches.pflichtfelder'))
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
    <>
      <PageHeader rubrik={t('coaches.rubrik')} titel={t('coaches.titel')} satz={t('coaches.satz')} />

      {/* Formular bleibt schmal und steht links; die Liste nutzt die volle Breite. */}
      <div className="flex flex-col gap-6 @4xl:max-w-3xl">
        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}
        {created && <p className="text-sm text-[var(--color-success)]">{t('coaches.angelegt', { name: created })}</p>}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('coaches.neu')}
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-name">{t('coaches.name')}</Label>
              <Input id="c-name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-email">{t('coaches.email')}</Label>
              <Input id="c-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-pw">{t('coaches.passwort')}</Label>
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
              {saving ? t('coaches.legtAn') : t('coaches.anlegen')}
            </Button>
          </div>
        </EdvanceCard>
      </div>

      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('coaches.bestehende')}
      </p>
      {loading ? (
        <LoadingPulse type="list" lines={3} />
      ) : coaches.length === 0 ? (
        <EmptyState icon="🧑‍🏫" title={t('coaches.leer.titel')} description={t('coaches.leer.beschreibung')} />
      ) : (
        <div className="grid grid-cols-1 gap-4 @3xl:grid-cols-2 @6xl:grid-cols-3">
          {coaches.map((c) => (
            <EdvanceCard key={c.id} className="flex flex-wrap items-center justify-between gap-2 p-6">
              <span className="text-base font-semibold text-[var(--color-text-primary)]">
                {c.full_name ?? t('coaches.unbenannt')}
              </span>
              <EdvanceBadge variant="mastered">{t('coaches.rolle')}</EdvanceBadge>
            </EdvanceCard>
          ))}
        </div>
      )}
    </>
  )
}
