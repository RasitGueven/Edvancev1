import { Mail } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { Versandanlass } from '@/lib/supabase/vertragMail'

type AktionenKarteProps = {
  busy: boolean
  /** Liegen Vertrag UND SEPA-Mandat im Archiv? Ohne sie gibt es nichts zu verschicken. */
  buendelDa: boolean
  elternEmail: string | null
  zugangscode: string | null
  widerrufMoeglich: boolean
  onFolgevertrag: () => void
  onVersenden: (anlass: Versandanlass) => void
  onWiderruf: () => void
  onKuendigung: () => void
}

/**
 * Was man mit diesem Vertrag tun kann.
 *
 * Jeder gesperrte Knopf trägt den Grund im `title` — ein Knopf, der nicht geht
 * und nicht sagt warum, schickt die Person am Empfang auf die Suche.
 */
export function AktionenKarte({
  busy,
  buendelDa,
  elternEmail,
  zugangscode,
  widerrufMoeglich,
  onFolgevertrag,
  onVersenden,
  onWiderruf,
  onKuendigung,
}: AktionenKarteProps): JSX.Element {
  const { t } = useTranslation('vertraege')

  const versandGrund = !buendelDa
    ? t('detailansicht.versandBraucht')
    : !elternEmail
      ? t('detailansicht.keineAdresse')
      : undefined

  const codeGrund = !zugangscode
    ? t('detailansicht.keinCode')
    : !elternEmail
      ? t('detailansicht.keineAdresse')
      : undefined

  return (
    <EdvanceCard className="flex flex-col gap-2 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('menue.spalte.aktionen')}
      </h2>

      <Button disabled={busy} onClick={onFolgevertrag}>
        {t('menue.neuerVertrag')}
      </Button>

      <span title={versandGrund}>
        <Button
          variant="outline"
          className="w-full"
          disabled={busy || versandGrund !== undefined}
          onClick={() => onVersenden('bestaetigung')}
        >
          <Mail className="h-4 w-4" />
          {t('detailansicht.bestaetigungSenden')}
        </Button>
      </span>

      <span title={codeGrund}>
        <Button
          variant="outline"
          className="w-full"
          disabled={busy || codeGrund !== undefined}
          onClick={() => onVersenden('zugangscode')}
        >
          <Mail className="h-4 w-4" />
          {t('detailansicht.codeSenden')}
        </Button>
      </span>

      <span title={widerrufMoeglich ? undefined : t('detailansicht.widerrufVorbei')}>
        <Button
          variant="outline"
          className="w-full"
          disabled={!widerrufMoeglich || busy}
          onClick={onWiderruf}
        >
          {t('detailansicht.widerrufErfassen')}
        </Button>
      </span>

      <Button
        variant="ghost"
        className="text-[var(--color-destructive)]"
        disabled={busy}
        onClick={onKuendigung}
      >
        {t('detailansicht.kuendigungErfassen')}
      </Button>
    </EdvanceCard>
  )
}
