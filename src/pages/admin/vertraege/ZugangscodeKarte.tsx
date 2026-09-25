import { KeyRound } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { formatDateOnly } from '@/lib/datetime'

type ZugangscodeKarteProps = {
  code: string
  erzeugtAm: string | null
  gesperrtAm: string | null
}

/**
 * Der Zugangscode entsteht im Moment des Abschlusses, nie vorher
 * (Anforderung E.15). Er steht hier gross, weil er vorgelesen oder
 * abgeschrieben wird — das Alphabet kennt kein O, I, L, 0 und 1.
 */
export function ZugangscodeKarte({ code, erzeugtAm, gesperrtAm }: ZugangscodeKarteProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  return (
    <EdvanceCard className="flex flex-col gap-2 p-6">
      <div className="flex items-center gap-2">
        <KeyRound className="h-5 w-5 text-[var(--color-primary)]" />
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
          {t('code.title')}
        </h2>
      </div>
      <p className="font-mono text-3xl font-bold tracking-widest text-[var(--color-text-primary)]">
        {code}
      </p>
      {gesperrtAm ? (
        <p className="text-sm text-[var(--color-error-exam)]">
          {t('code.blocked', { date: formatDateOnly(gesperrtAm, i18n.language) })}
        </p>
      ) : (
        <p className="text-xs text-[var(--color-text-muted)]">
          {erzeugtAm
            ? t('code.created', { date: formatDateOnly(erzeugtAm, i18n.language) })
            : t('code.hint')}
        </p>
      )}
    </EdvanceCard>
  )
}
