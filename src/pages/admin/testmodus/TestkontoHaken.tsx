import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { testkontoSetzen, type TestkontoArt } from '@/lib/supabase/testmodus'

type TestkontoHakenProps = {
  art: TestkontoArt
  id: string
  wert: boolean
  /** Nur Admins sehen und setzen den Haken. */
  istAdmin: boolean
  onGeaendert: (wert: boolean) => void
  onFehler: (text: string) => void
}

/** Haken "Testkonto" in Akte (Kind) und Lead (Entscheidung 27). */
export function TestkontoHaken({ art, id, wert, istAdmin, onGeaendert, onFehler }: TestkontoHakenProps): JSX.Element | null {
  const { t } = useTranslation('admin')
  const [busy, setBusy] = useState(false)
  if (!istAdmin) return null

  const umschalten = async (neu: boolean): Promise<void> => {
    setBusy(true)
    const { error } = await testkontoSetzen(art, id, neu)
    setBusy(false)
    if (error) {
      onFehler(t('testmodus.haken.fehler'))
      return
    }
    onGeaendert(neu)
  }

  return (
    <label className="flex min-h-11 cursor-pointer items-center gap-3">
      <input
        type="checkbox"
        className="h-5 w-5 accent-[var(--color-primary)]"
        checked={wert}
        disabled={busy}
        onChange={(e) => void umschalten(e.target.checked)}
      />
      <span className="flex flex-col gap-1">
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">{t('testmodus.haken.label')}</span>
        <span className="text-xs text-[var(--color-text-tertiary)]">{t(`testmodus.haken.hilfe.${art}`)}</span>
      </span>
    </label>
  )
}
