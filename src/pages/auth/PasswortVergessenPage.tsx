import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { passwortVergessen } from '@/lib/supabase/konto'
import { AuthRahmen } from './AuthRahmen'

/**
 * „Passwort vergessen“: Die Antwort ist immer dieselbe, ob es ein Konto mit
 * der Adresse gibt oder nicht — sonst liesse sich hier ausprobieren, wer ein
 * Konto hat.
 */
export function PasswortVergessenPage(): JSX.Element {
  const { t } = useTranslation('konto')
  const [email, setEmail] = useState('')
  const [laedt, setLaedt] = useState(false)
  const [gesendet, setGesendet] = useState(false)

  const absenden = async (e: FormEvent): Promise<void> => {
    e.preventDefault()
    if (email.trim() === '') return
    setLaedt(true)
    await passwortVergessen(email, `${window.location.origin}/auth/neues-passwort`)
    setLaedt(false)
    setGesendet(true)
  }

  if (gesendet) {
    return (
      <AuthRahmen titel={t('vergessen.titel')} satz={t('vergessen.antwort')}>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('vergessen.antwortSatz')}</p>
        <Button asChild size="lg" className="w-full">
          <Link to="/login">{t('vergessen.zurueck')}</Link>
        </Button>
      </AuthRahmen>
    )
  }

  return (
    <AuthRahmen titel={t('vergessen.titel')} satz={t('vergessen.satz')}>
      <form onSubmit={(e) => void absenden(e)} className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <Label htmlFor="vergessen-email">{t('vergessen.email')}</Label>
          <Input
            id="vergessen-email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </div>
        <Button type="submit" size="lg" className="w-full" loading={laedt}>
          {laedt ? t('vergessen.sendet') : t('vergessen.senden')}
        </Button>
        <Link
          to="/login"
          className="inline-flex min-h-[44px] items-center justify-center text-sm font-semibold text-[var(--color-text-link)] hover:underline"
        >
          {t('vergessen.zurueck')}
        </Link>
      </form>
    </AuthRahmen>
  )
}
