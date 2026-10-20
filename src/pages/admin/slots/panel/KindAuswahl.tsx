import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { Input } from '@/components/ui/input'
import type { KindBuchbar } from '@/types/stundenplan'
import { datumVoll } from '../slotsFormat'
import { TestKennzeichen } from '../TestKennzeichen'
import { grundSchluessel, kinderSortiert } from './stundenplan.model'

type Props = {
  /** Ausgabe von kinder_buchbar; null = lädt noch. */
  kinder: KindBuchbar[] | null
  /** i18n-Schlüssel (fehler.*), wenn das Laden scheiterte. */
  fehler: string | null
  gewaehlt: string[]
  onWahl: (ids: string[]) => void
  /** Wie viele Kinder insgesamt noch gewählt werden dürfen (freie Plätze im Raum). */
  frei: number
  /** Schon gebuchte Kinder der Session erscheinen nicht noch einmal. */
  ohne?: string[]
}

/**
 * Kinderwahl mit Suchfeld (Slots S2, Entscheidung 5). Alle Kinder erscheinen; wer nicht buchbar ist, steht
 * ausgegraut mit dem Grund aus kinder_buchbar da und lässt sich nicht wählen. Geteilt von Session-Karte und Sofort-Dialog.
 */
export function KindAuswahl({ kinder, fehler, gewaehlt, onWahl, frei, ohne = [] }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [suche, setSuche] = useState('')

  if (fehler) return <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>
  if (!kinder) return <LoadingPulse type="list" lines={4} />

  const liste = kinderSortiert(kinder.filter((k) => !ohne.includes(k.student_id)), suche)
  const voll = gewaehlt.length >= frei

  const grund = (k: KindBuchbar): string | null => {
    if (k.code !== 'ok') {
      const g = grundSchluessel(k.code)
      return t(g.schluessel, g.mitDatum && k.detail ? { datum: datumVoll(k.detail, i18n.language) } : {})
    }
    return voll && !gewaehlt.includes(k.student_id) ? t('stundenplan.auswahl.voll', { max: frei }) : null
  }

  const umschalten = (id: string): void =>
    onWahl(gewaehlt.includes(id) ? gewaehlt.filter((x) => x !== id) : [...gewaehlt, id])

  return (
    <div className="flex flex-col gap-2">
      <Input
        type="search"
        value={suche}
        onChange={(e) => setSuche(e.target.value)}
        placeholder={t('stundenplan.auswahl.suche')}
        aria-label={t('stundenplan.auswahl.suche')}
      />
      {kinder.length === 0 ? (
        <EmptyState icon="🧒" title={t('stundenplan.auswahl.leerTitel')} description={t('stundenplan.auswahl.leerText')} />
      ) : liste.length === 0 ? (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('stundenplan.auswahl.keinTreffer')}</p>
      ) : (
        <ul className="flex max-h-80 flex-col overflow-y-auto rounded-[var(--radius-md)] border border-[var(--color-border)]" aria-label={t('stundenplan.auswahl.liste')}>
          {liste.map((k) => {
            const satz = grund(k)
            const gesperrt = satz !== null
            return (
              <li key={k.student_id} className="border-t border-[var(--color-border)] first:border-t-0">
                <label className={`flex min-h-[44px] items-center gap-3 px-3 py-2 ${gesperrt ? 'cursor-not-allowed opacity-60' : 'cursor-pointer'}`}>
                  <input
                    type="checkbox"
                    className="h-5 w-5 accent-[var(--color-primary)]"
                    checked={gewaehlt.includes(k.student_id)}
                    disabled={gesperrt}
                    onChange={() => !gesperrt && umschalten(k.student_id)}
                  />
                  <span className="flex min-w-0 flex-1 flex-col">
                    <span className="flex flex-wrap items-center gap-2 text-sm font-semibold text-[var(--color-text-primary)]">
                      {k.name ?? t('stundenplan.unbenannt')}
                      {k.klasse !== null && (
                        <span className="text-xs font-normal text-[var(--color-text-tertiary)]">{t('stundenplan.klasse', { klasse: k.klasse })}</span>
                      )}
                      {k.ist_test && <TestKennzeichen />}
                    </span>
                    {satz && <span className="text-xs text-[var(--color-text-secondary)]">{satz}</span>}
                  </span>
                </label>
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
