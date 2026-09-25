import { Mail, PenLine, Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'

/** vor_ort = hier unterschreiben · email / druck = Unterlagen gehen mit. */
export type AbschlussWahl = 'vor_ort' | 'email' | 'druck'

type Schritt3Props = {
  wahl: AbschlussWahl | null
  onWahl: (wahl: AbschlussWahl) => void
  disabled: boolean
}

const WEGE: { key: AbschlussWahl; Icon: typeof PenLine }[] = [
  { key: 'vor_ort', Icon: PenLine },
  { key: 'email', Icon: Mail },
  { key: 'druck', Icon: Printer },
]

/**
 * Die Wahl steht vor den Bedingungen (Anforderung C.9): erst sie entscheidet,
 * ob der Elternteil hier abhakt oder auf dem Ausdruck.
 *
 * Bei jedem der drei Wege gehen dieselben fuenf Unterlagen mit. Deshalb steht
 * der Satz darunter und nicht nur an einem der drei Knoepfe.
 */
export function Schritt3Weg({ wahl, onWahl, disabled }: Schritt3Props): JSX.Element {
  const { t } = useTranslation('vertraege')
  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('wizard.step3Title')}
      </h2>
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
        {WEGE.map(({ key, Icon }) => {
          const aktiv = wahl === key
          return (
            <button
              key={key}
              type="button"
              disabled={disabled}
              aria-pressed={aktiv}
              onClick={() => onWahl(key)}
              className={[
                'flex min-h-[44px] items-center justify-center gap-2 rounded-xl border px-4 py-3 text-sm font-semibold transition-colors',
                aktiv
                  ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-primary)] hover:border-[var(--color-primary)]',
              ].join(' ')}
            >
              <Icon className="h-4 w-4" />
              {t(`wizard.weg.${key}`)}
            </button>
          )
        })}
      </div>
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {t('wizard.wegHint')}
      </p>
      {wahl === null && (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('wizard.wegMissing')}</p>
      )}
    </EdvanceCard>
  )
}
