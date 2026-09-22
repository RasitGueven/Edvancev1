import { useState } from 'react'
import { Mail, PenLine, Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { UnterschriftPanel } from './UnterschriftPanel'

type AbschlussWegeProps = {
  /** Warum Versand und Unterschrift noch gesperrt sind (fehlende/ungespeicherte Daten). */
  datenSperre: string | null
  /** Zusaetzlich fuer die Unterschrift vor Ort: fehlende Pflicht-Haekchen. */
  hakenSperre: string | null
  saving: boolean
  onSign: (signaturVertrag: string, signaturSepa: string) => void
  onPrint: () => void
}

/**
 * Die drei Wege zum Vertrag: vor Ort unterschreiben (primaer), per E-Mail
 * (noch ohne Versand-Infrastruktur, deshalb deaktiviert) oder ausdrucken.
 */
export function AbschlussWege({
  datenSperre,
  hakenSperre,
  saving,
  onSign,
  onPrint,
}: AbschlussWegeProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const [signing, setSigning] = useState(false)
  const signSperre = datenSperre ?? hakenSperre

  if (signing && signSperre === null) {
    return (
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
          {t('ways.sign')}
        </h2>
        <UnterschriftPanel saving={saving} onCancel={() => setSigning(false)} onSign={onSign} />
      </EdvanceCard>
    )
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
        {t('ways.title')}
      </h2>
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
        <span title={signSperre ?? undefined}>
          <Button className="w-full" disabled={signSperre !== null || saving} onClick={() => setSigning(true)}>
            <PenLine className="h-4 w-4" />
            {t('ways.sign')}
          </Button>
        </span>
        <span title={t('ways.emailDisabled')}>
          <Button className="w-full" variant="outline" disabled>
            <Mail className="h-4 w-4" />
            {t('ways.email')}
          </Button>
        </span>
        <span title={datenSperre ?? undefined}>
          <Button
            className="w-full"
            variant="outline"
            disabled={datenSperre !== null || saving}
            onClick={onPrint}
          >
            <Printer className="h-4 w-4" />
            {t('ways.print')}
          </Button>
        </span>
      </div>
      {signSperre && <p className="text-xs text-[var(--color-text-muted)]">{signSperre}</p>}
    </EdvanceCard>
  )
}
