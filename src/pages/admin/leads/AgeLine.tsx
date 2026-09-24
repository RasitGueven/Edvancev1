import { useTranslation } from 'react-i18next'
import type { AgeDisplay } from './boardModel'

function ageClass(accent: boolean, bold: boolean): string {
  if (bold) return 'font-bold text-[var(--color-accent)]'
  if (accent) return 'text-[var(--color-accent)]'
  return 'text-[var(--color-text-tertiary)]'
}

/**
 * Zeitangabe einer Board-Karte, darunter ggf. grau das Anlagedatum. Der
 * Nachfass-Hinweis steht als eigene orange Zeile darueber, wenn followUp gesetzt ist.
 */
export function AgeLine({
  age,
  followUp = null,
}: {
  age: AgeDisplay
  followUp?: number | null
}): JSX.Element {
  const { t } = useTranslation('leads')
  const main =
    age.kind === 'since'
      ? age.days === 0
        ? t('age.sinceToday')
        : t('age.since', { count: age.days })
      : age.days === 0
        ? t('age.createdToday')
        : t('age.created', { count: age.days })

  return (
    <div className="flex flex-col gap-0.5">
      {followUp !== null && (
        <p className="text-xs font-semibold text-[var(--color-accent)]">
          {t('age.followUp', { count: followUp })}
        </p>
      )}
      <p className={`text-xs ${ageClass(age.accent, age.bold)}`}>{main}</p>
      {age.createdDays !== null && (
        <p className="text-[10px] text-[var(--color-text-tertiary)]">
          {age.createdDays === 0
            ? t('age.createdToday')
            : t('age.created', { count: age.createdDays })}
        </p>
      )}
    </div>
  )
}
