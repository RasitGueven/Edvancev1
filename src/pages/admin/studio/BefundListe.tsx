import { useTranslation } from 'react-i18next'

import { EdvanceBadge } from '@/components/edvance'
import type { Befund } from '@/studio/skript/typen'

const VARIANTE = { sperre: 'gap', welt: 'warning', hinweis: 'muted' } as const

/** Befunde der Importprüfung, Sperren zuerst. Jede Meldung nennt Beat und Welt. */
export function BefundListe({ befunde }: { befunde: Befund[] }): JSX.Element {
  const { t } = useTranslation('studio')
  const rang = { sperre: 0, welt: 1, hinweis: 2 }
  const sortiert = [...befunde].sort((a, b) => rang[a.stufe] - rang[b.stufe])
  return (
    <ul className="flex flex-col gap-2" data-testid="studio-befunde">
      {sortiert.map((b, i) => (
        <li key={i} className="flex flex-wrap items-baseline gap-2 text-sm leading-relaxed text-[var(--color-text-secondary)]">
          <EdvanceBadge variant={VARIANTE[b.stufe]}>{t(`befund.stufe.${b.stufe}`)}</EdvanceBadge>
          {b.beat && <span className="font-semibold">{t('befund.beat', { beat: b.beat })}</span>}
          {b.welt && <span className="font-semibold">{t(`welt.${b.welt}`)}</span>}
          <span>{t(`befund.${b.code}`, b.werte ?? {})}</span>
        </li>
      ))}
    </ul>
  )
}
