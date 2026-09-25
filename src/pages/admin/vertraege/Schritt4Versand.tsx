import { useState } from 'react'
import { Mail, Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { berlinToday, formatDateOnly } from '@/lib/datetime'

type Schritt4VersandProps = {
  weg: 'email' | 'druck'
  empfaenger: string | null
  datenSperre: string | null
  saving: boolean
  onVersenden: (rueckmeldungBis: string) => void
  onDrucken: () => void
}

/** Standardfrist fuer den Ruecklauf: zwei Wochen. */
function standardFrist(): string {
  const heute = berlinToday()
  const d = new Date(`${heute}T00:00:00Z`)
  d.setUTCDate(d.getUTCDate() + 14)
  return d.toISOString().slice(0, 10)
}

/**
 * Schritt 4, Wege B und C. Hier entsteht KEIN Vertrag — das ist der Satz, der
 * gross dastehen muss, weil der Knopf sonst wie ein Abschluss aussieht
 * (Anforderung D.13).
 *
 * Der Mailversand ueber hello@ kommt in P4. Bis dahin verschickt der Empfang
 * die Unterlagen von Hand und haelt hier fest, dass es passiert ist — das
 * Protokoll stimmt dadurch, der Weg ist nur noch nicht automatisch.
 */
export function Schritt4Versand({
  weg,
  empfaenger,
  datenSperre,
  saving,
  onVersenden,
  onDrucken,
}: Schritt4VersandProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const [bis, setBis] = useState(standardFrist())
  const Icon = weg === 'email' ? Mail : Printer

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
        {t(`wizard.weg.${weg}`)}
      </h2>

      <div className="rounded-xl border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] px-4 py-3">
        <p className="text-sm leading-relaxed text-[var(--color-text-primary)]">
          {t('wizard.noContractYet')}
        </p>
      </div>

      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {weg === 'email'
          ? t('wizard.emailManual', { empfaenger: empfaenger ?? '—' })
          : t('wizard.printHint')}
      </p>

      <div className="flex flex-col gap-2">
        <Label htmlFor="vertrag-rueckmeldung">{t('wizard.rueckmeldungBis')}</Label>
        <Input
          id="vertrag-rueckmeldung"
          type="date"
          className="max-w-xs"
          value={bis}
          disabled={saving}
          onChange={(e) => setBis(e.target.value)}
        />
        <p className="text-xs text-[var(--color-text-muted)]">
          {t('wizard.rueckmeldungHint', { date: formatDateOnly(standardFrist(), i18n.language) })}
        </p>
      </div>

      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        <Button variant="outline" disabled={saving} onClick={onDrucken}>
          <Printer className="h-4 w-4" />
          {t('wizard.printDocs')}
        </Button>
        <span title={datenSperre ?? undefined}>
          <Button
            className="w-full"
            disabled={datenSperre !== null || saving || bis === ''}
            loading={saving}
            onClick={() => onVersenden(bis)}
          >
            <Icon className="h-4 w-4" />
            {t('wizard.markSent')}
          </Button>
        </span>
      </div>
      {datenSperre && <p className="text-sm text-[var(--color-text-muted)]">{datenSperre}</p>}
    </EdvanceCard>
  )
}
