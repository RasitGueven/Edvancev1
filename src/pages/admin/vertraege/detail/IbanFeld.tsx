import { useState } from 'react'
import { Eye } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { vertragIbanAnzeigen } from '@/lib/supabase/vertraegeMenue'
import { formatIban } from '@/lib/vertrag/iban'

type IbanFeldProps = {
  vertragId: string
  /** DE** **** 1234 — steht am Vertrag und ist immer sichtbar. */
  maskiert: string | null
  onFehler: (text: string) => void
}

/**
 * Die Bankverbindung: maskiert sichtbar, vollständig nur auf Klick.
 *
 * Das Aufdecken geht über `vertrag_iban_anzeigen`, und die RPC schreibt den
 * Protokolleintrag, BEVOR sie die Zahl herausgibt (Entscheidung 17). Die volle
 * IBAN lebt nur im Zustand dieser Komponente — sie landet nie in der
 * Adresszeile und wird beim Zuklappen wieder vergessen.
 */
export function IbanFeld({ vertragId, maskiert, onFehler }: IbanFeldProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const [voll, setVoll] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const aufdecken = async (): Promise<void> => {
    setBusy(true)
    const { data, error } = await vertragIbanAnzeigen(vertragId)
    setBusy(false)
    if (error || !data) {
      onFehler(error ?? t('detailansicht.ibanFehler'))
      return
    }
    setVoll(data)
  }

  if (voll) {
    return (
      <div className="flex flex-col gap-1">
        <span className="font-mono text-sm text-[var(--color-text-primary)]">
          {formatIban(voll)}
        </span>
        <button
          type="button"
          onClick={() => setVoll(null)}
          className="w-fit text-xs text-[var(--color-text-link)] hover:underline"
        >
          {t('detailansicht.ibanVerbergen')}
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="font-mono text-sm text-[var(--color-text-primary)]">{maskiert ?? '—'}</span>
      <Button size="sm" variant="outline" disabled={busy} loading={busy} onClick={() => void aufdecken()}>
        <Eye className="h-4 w-4" />
        {t('detailansicht.ibanAnzeigen')}
      </Button>
    </div>
  )
}
