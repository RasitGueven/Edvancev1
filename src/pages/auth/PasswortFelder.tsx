import { useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PASSWORT_MIN, passwortPruefen } from '@/lib/passwort'
import type { KontoFehler } from '@/lib/supabase/konto'

type Props = {
  /** Mein Konto: das bisherige Passwort wird mit abgefragt. */
  mitAltem?: boolean
  /** Fuer Passwort-Manager (verstecktes Benutzerfeld). */
  email?: string
  knopf: string
  knopfLaedt: string
  onSpeichern: (neu: string, alt: string) => Promise<KontoFehler | null>
}

/**
 * Neues Passwort zweimal (und bei Bedarf das alte). Einzige Regel ist die
 * Laenge; der Hinweis erklaert, warum keine Sonderzeichen verlangt werden.
 */
export function PasswortFelder({ mitAltem = false, email, knopf, knopfLaedt, onSpeichern }: Props): JSX.Element {
  const { t } = useTranslation('konto')
  const [alt, setAlt] = useState('')
  const [neu, setNeu] = useState('')
  const [wiederholung, setWiederholung] = useState('')
  const [fehler, setFehler] = useState<string | null>(null)
  const [laedt, setLaedt] = useState(false)

  const absenden = async (e: FormEvent): Promise<void> => {
    e.preventDefault()
    const regel = passwortPruefen(neu, wiederholung)
    if (regel) {
      setFehler(regel)
      return
    }
    setFehler(null)
    setLaedt(true)
    const ergebnis = await onSpeichern(neu, alt)
    setLaedt(false)
    if (ergebnis) {
      setFehler(ergebnis === 'link_ungueltig' ? 'unbekannt' : ergebnis)
      return
    }
    setAlt('')
    setNeu('')
    setWiederholung('')
  }

  return (
    <form onSubmit={(e) => void absenden(e)} className="flex flex-col gap-4" noValidate>
      {email && <input type="email" autoComplete="username" value={email} readOnly hidden />}
      {mitAltem && (
        <div className="flex flex-col gap-2">
          <Label htmlFor="pw-alt">{t('passwort.alt')}</Label>
          <Input
            id="pw-alt"
            type="password"
            autoComplete="current-password"
            value={alt}
            onChange={(e) => setAlt(e.target.value)}
            required
          />
        </div>
      )}
      <div className="flex flex-col gap-2">
        <Label htmlFor="pw-neu">{t('passwort.neu')}</Label>
        <Input
          id="pw-neu"
          type="password"
          autoComplete="new-password"
          minLength={PASSWORT_MIN}
          value={neu}
          onChange={(e) => setNeu(e.target.value)}
          aria-describedby="pw-hinweis"
          required
        />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="pw-wdh">{t('passwort.wiederholen')}</Label>
        <Input
          id="pw-wdh"
          type="password"
          autoComplete="new-password"
          value={wiederholung}
          onChange={(e) => setWiederholung(e.target.value)}
          required
        />
      </div>
      <p id="pw-hinweis" className="text-xs text-[var(--color-text-tertiary)]">
        {t('passwort.hinweis', { min: PASSWORT_MIN })}
      </p>
      {fehler && (
        <p role="alert" className="text-sm text-[var(--color-error-exam)]">
          {t(`passwort.fehler.${fehler}`, { min: PASSWORT_MIN })}
        </p>
      )}
      <Button type="submit" size="lg" loading={laedt} className="w-full">
        {laedt ? knopfLaedt : knopf}
      </Button>
    </form>
  )
}
