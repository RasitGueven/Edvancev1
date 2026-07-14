// Degraded-Modus. Solange docs/schema/A01-authoring.proposal.sql nicht eingespielt
// ist, fehlen dem Tool drei Dinge: der Stoffanker (Spalte), der Lesepfad zu den
// Loesungen (RPC) und der Freigabe-Stempel (RPC).
//
// Das Tool laeuft trotzdem — aber es sagt, was es nicht kann. Ein Werkzeug, das
// still weniger tut als es soll, ist schlimmer als eins, das gar nicht startet:
// hier wuerde es Loesungen blind ueberschreiben.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle } from 'lucide-react'
import type { AuthoringSchema } from '@/types'

export function SchemaBanner({ schema }: { schema: AuthoringSchema }): JSX.Element | null {
  const { t } = useTranslation('authoring')
  const missing: string[] = []
  if (!schema.hasStoffanker) missing.push(t('schema.stoffanker'))
  if (!schema.hasSolutionRead) missing.push(t('schema.solutionRead'))
  if (!schema.hasStatusGate) missing.push(t('schema.statusGate'))

  if (missing.length === 0) return null

  return (
    <div className="flex gap-3 rounded-[var(--radius-md)] border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning)]/10 p-4">
      <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-[var(--color-gold-warning)]" />
      <div className="flex flex-col gap-2">
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">
          {t('schema.title')}
        </span>
        <ul className="flex list-disc flex-col gap-1 pl-4">
          {missing.map((line) => (
            <li key={line} className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
              {line}
            </li>
          ))}
        </ul>
        <code className="text-xs text-[var(--color-text-tertiary)]">{t('schema.action')}</code>
      </div>
    </div>
  )
}
