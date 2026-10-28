import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { LoadingPulse } from '@/components/edvance/LoadingPulse'
import { useReihe } from '@/hooks/useReihe'
import { reiheAenderungen } from '@/lib/session/reiheAnsicht'
import { ReiheKarte } from './ReiheKarte'

/**
 * Reihe 1 C4.2: Danach-Ansicht — neuer Reihenplan nach dem Abschluss (neu geplant per Trigger) mit den
 * Änderungen gegenüber der Vorversion.
 */
export function ReiheDanach({ studentId, name }: { studentId: string; name: string }): JSX.Element | null {
  const { t, i18n } = useTranslation('reihe')
  const { reihe, laedt } = useReihe(studentId)
  if (laedt) return <LoadingPulse type="card" />
  if (!reihe) return null
  const datum = (iso: string): string =>
    new Intl.DateTimeFormat(i18n.language, { timeZone: 'Europe/Berlin', day: '2-digit', month: '2-digit' }).format(new Date(`${iso}T12:00:00Z`))
  const ae = reiheAenderungen(reihe.plan, reihe.vorher)
  const name_ = (k: string): string => reihe.kernideen[k] ?? k
  return (
    <div className="flex flex-col gap-2">
      <EdvanceCard className="flex flex-col gap-2 p-6">
        <span className="text-base font-semibold">{t('danach.titel')} · {name}</span>
        {ae.length === 0 ? (
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('danach.keineAenderung')}</p>
        ) : (
          <ul className="flex flex-col gap-2 text-sm text-[var(--color-text-secondary)]">
            {ae.map((x) => (
              <li key={x.schluessel}>
                {x.von && x.nach ? t('danach.verschoben', { kernidee: name_(x.schluessel), von: datum(x.von), nach: datum(x.nach) })
                  : x.nach ? t('danach.neu', { kernidee: name_(x.schluessel), nach: datum(x.nach) })
                  : t('danach.fertig', { kernidee: name_(x.schluessel) })}
              </li>
            ))}
          </ul>
        )}
      </EdvanceCard>
      <ReiheKarte studentId={studentId} kompakt />
    </div>
  )
}
