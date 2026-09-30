// Dezente Markierung vorbefuellter Felder in der Item-Pflege (tasks.vorbefuellt).
//
// Die Seite stellt das Kennzeichen der Aufgabe per Context bereit; jedes `Field`
// mit `feld`-Schluessel zeigt dann selbst, ob es vom Agenten stammt und noch
// unbestaetigt ist — oder warum es bewusst leer blieb.

import { createContext, useContext, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { eintragFuer } from '@/lib/authoring/vorbefuellt'
import type { Vorbefuellt } from '@/types'

export const VorbefuelltContext = createContext<Vorbefuellt | undefined>(undefined)

export function VorbefuelltMarke({ feld }: { feld: string }): JSX.Element | null {
  const { t } = useTranslation('authoring')
  const eintrag = eintragFuer(useContext(VorbefuelltContext), feld)
  if (!eintrag) return null

  if (eintrag.art === 'leer') {
    return (
      <span className="text-xs font-normal leading-relaxed text-[var(--color-text-tertiary)]">
        {t('vorbefuellt.leer', { grund: eintrag.grund })}
      </span>
    )
  }
  return (
    <span
      title={eintrag.grund}
      aria-label={t('vorbefuellt.aria', { art: t(`vorbefuellt.art.${eintrag.art}`), grund: eintrag.grund })}
      className="rounded-full border border-[var(--color-border)] bg-[var(--color-bg-subtle)] px-2 text-xs font-normal text-[var(--color-text-tertiary)]"
    >
      {t(`vorbefuellt.art.${eintrag.art}`)}
    </span>
  )
}
