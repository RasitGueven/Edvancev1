import { useTranslation } from 'react-i18next'
import { useReihe } from '@/hooks/useReihe'
import { reiheAnsicht } from '@/lib/session/reiheAnsicht'

const heuteIso = (): string => new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Berlin' }).format(new Date())

/** Reihe 1 C4.1: „Session 3 von 8“ (bzw. Generalprobe) auf der Live-Kachel. Ohne Reihe nichts. */
export function ReiheKachelZeile({ studentId }: { studentId: string }): JSX.Element | null {
  const { t } = useTranslation('reihe')
  const { reihe } = useReihe(studentId)
  if (!reihe) return null
  const a = reiheAnsicht(reihe, heuteIso())
  if (a.nr === null) return null
  return (
    <span className="px-4 text-xs text-[var(--color-text-secondary)]" data-testid="kachel-reihe">
      {a.heute?.art === 'generalprobe' ? t('kachel.generalprobe', { nr: a.nr, gesamt: a.gesamt }) : t('karte.sessionVon', { nr: a.nr, gesamt: a.gesamt })}
    </span>
  )
}
