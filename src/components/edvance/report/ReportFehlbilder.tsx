import { useTranslation } from 'react-i18next'

import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import type { ReportFehlbild } from '@/types'

/**
 * Der Fehlbild-Abschnitt der Elternsicht — gebündelt auf Familienebene (AF5).
 *
 * Fünf Fehlbilder derselben Familie sind für Eltern EINE Information. Der Coach
 * sieht weiterhin jeden Einzelbefund über lsa_fehlbild_report; nur diese Fläche
 * bündelt.
 *
 * Gerendert wird ausschließlich der abgenommene Elterntext, wörtlich aus
 * fehlbild_familien.elterntext. NICHT gerendert werden:
 *   - der Slug        — interner Schlüssel, snake_case, kein Satz (INV-4.3)
 *   - der Familienschlüssel — dito, dient nur als React-key
 *   - der Coach-Klartext    — fachliche Arbeitsnotiz, keine Elternsprache;
 *     er verlässt die Datenbank über diesen Pfad ohnehin nicht mehr (AF4)
 *
 * Bleibt nach der Bündelung nichts übrig, entfällt der Abschnitt vollständig —
 * kein leerer Kasten, kein „keine Auffälligkeiten". Ein solcher Satz wäre eine
 * Aussage über das Kind, die niemand belegt hat: die Sitzung kann schlicht zu
 * kurz gewesen sein, oder die aufgetretenen Muster tragen noch keinen
 * abgenommenen Text.
 */
export function ReportFehlbilder({
  fehlbilder,
  name,
  titleClassName,
}: {
  fehlbilder: ReportFehlbild[]
  name: string
  titleClassName: string
}): JSX.Element | null {
  const { t } = useTranslation('report')

  // Die Weglass- und Sortierregeln stehen in der lib-Schicht, nicht hier:
  // sie entscheiden, WAS Eltern zu sehen bekommen, und sind dort ohne React
  // prüfbar (src/lib/reportFehlbilder.test.ts).
  const familien = gruppiereFehlbilderNachFamilie(fehlbilder)
  if (familien.length === 0) return null

  return (
    <section className="report-block flex flex-col gap-2">
      <h3 className={titleClassName}>
        {t('fehlbild.title', { count: familien.length })}
      </h3>
      <p className="mb-1 text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
        {t('fehlbild.description', { name })}
      </p>
      <ul className="flex flex-col gap-3">
        {familien.map((familie) => (
          <li
            key={familie.familie}
            className="rounded-[var(--radius-lg)] border-l-4 border-[var(--color-report-navy)] bg-[var(--color-report-cream)] p-5"
          >
            <p className="text-base leading-relaxed text-[var(--color-report-navy)]">
              {familie.elterntext}
            </p>
          </li>
        ))}
      </ul>
    </section>
  )
}
