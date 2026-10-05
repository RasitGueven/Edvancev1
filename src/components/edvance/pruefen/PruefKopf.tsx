// Kopf der Pruefansicht (Entscheidung 31): Stufe · Lernstandsanalyse Mathe · Erlaubt: ⟨Hilfsmittel⟩ ⓘ,
// Thema, "Aufgabe x von y", Zurueck / Ueberspringen / Pause und der Fortschritt im Thema.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui'
import type { Position } from '@/lib/pruefung/reihenfolge'
import type { PruefAufgabe } from '@/types'
import { InfoTip } from './InfoTip'

type Props = {
  aufgabe: PruefAufgabe
  position: Position | null
  hatVorige: boolean
  onZurueck: () => void
  onUeberspringen: () => void
  onPause: () => void
}

/** Kopfzeile: Stufe · Lernstandsanalyse Mathe · Erlaubt: ⟨Hilfsmittel⟩ ⓘ (auch in der Admin-Pruefansicht). */
export function KopfMeta({ aufgabe }: { aufgabe: PruefAufgabe }): JSX.Element {
  const { t } = useTranslation('pruefen')
  const k = aufgabe.kopf
  return (
    <p className="flex flex-wrap items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
      {t('ansicht.meta', { stufe: k.stufe ? t(`stufe.${k.stufe}`) : '', hilfsmittel: k.hilfsmittel ?? '' })}
      <InfoTip schluessel="hilfsmittel" />
    </p>
  )
}

export function PruefKopf({ aufgabe, position, hatVorige, onZurueck, onUeberspringen, onPause }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const k = aufgabe.kopf
  const anteil = position && position.anzahl > 0 ? (position.bewertet / position.anzahl) * 100 : 0
  return (
    <EdvanceCard className="flex flex-col gap-3">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex min-w-0 flex-col gap-1">
          <KopfMeta aufgabe={aufgabe} />
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">{k.thema_label ?? k.kurztitel}</h1>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {position && (
            <span className="text-sm text-[var(--color-text-secondary)]">
              {t('ansicht.position', { nr: position.nr, anzahl: position.anzahl })}
            </span>
          )}
          <span title={hatVorige ? undefined : t('ansicht.ersteAufgabe')}>
            <Button variant="secondary" size="sm" disabled={!hatVorige} onClick={onZurueck}>{t('ansicht.zurueck')}</Button>
          </span>
          <Button variant="secondary" size="sm" onClick={onUeberspringen}>{t('ansicht.ueberspringen')}</Button>
          <Button variant="secondary" size="sm" onClick={onPause}>{t('ansicht.pause')}</Button>
        </div>
      </div>
      {position && (
        <div
          className="h-1 w-full overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)]"
          title={t('ansicht.fortschritt', { x: position.bewertet, y: position.anzahl })}
          role="progressbar" aria-valuemin={0} aria-valuemax={position.anzahl} aria-valuenow={position.bewertet}
        >
          <div className="h-full bg-[var(--color-gold-altgold)] transition-[width]" style={{ width: `${anteil}%` }} />
        </div>
      )}
    </EdvanceCard>
  )
}
