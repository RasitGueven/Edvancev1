import { useTranslation } from 'react-i18next'

import type { ReportSkillbefunde } from '@/types'

/**
 * „Was wir uns genauer ansehen" — die Skill-Ebene der Diagnose (R2).
 *
 * Bis R2 erhob die LSA je Sitzung Dutzende Skill-Urteile, von denen im
 * Elternreport keines auftauchte. Ein Kind mit sechs nicht tragenden Skills
 * bekam einen Report, in dem „Das läuft gut" stand und die gescheiterten
 * Bereiche nirgends vorkamen.
 *
 * DIESER ABSCHNITT IST EIN BEFUND, KEIN URTEIL.
 * Bei zwei Proben je Skill steht `offen = true` in den Daten — ein Urteil aus
 * zwei Aufgaben ist eine Beobachtung. Der Coach validiert sie in den ersten
 * Sitzungen. Die Sprache muss diese Vorläufigkeit tragen: „Diese Bereiche sehen
 * wir uns genauer an", nicht „Hier bestehen Lücken", nicht „Ihr Kind kann das
 * nicht".
 *
 * Gerendert wird `label` aus `skills.label`, nie der `skill_key` — der ist
 * snake_case und kein Satz für Eltern (INV-4.3).
 *
 * Trägt alles Geprüfte, entfällt der Abschnitt vollständig — kein leerer
 * Kasten, kein „keine Auffälligkeiten".
 */
export function ReportSkillbefunde({
  befunde,
  titleClassName,
}: {
  befunde: ReportSkillbefunde | null
  titleClassName: string
}): JSX.Element | null {
  const { t } = useTranslation('report')

  if (!befunde || befunde.nichtTragend.length === 0) return null

  return (
    <section className="report-block flex flex-col gap-2">
      <h3 className={titleClassName}>{t('skillbefunde.title')}</h3>
      <p className="mb-1 text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
        {t('skillbefunde.description')}
      </p>

      <ul className="flex flex-col gap-2">
        {befunde.nichtTragend.map((skill) => (
          <li
            key={skill.skillKey}
            className="flex items-baseline gap-3 rounded-[var(--radius-lg)] bg-[var(--color-report-cream)] px-5 py-3"
          >
            <span aria-hidden="true" className="text-[var(--color-report-gold)]">
              •
            </span>
            <span className="text-base text-[var(--color-report-navy)]">
              {skill.label}
            </span>
          </li>
        ))}
      </ul>

      {/* Die Fundamenttiefe als EINE Aussage, nie je Skill und nie als Zahl.
          Eine Stufenzahl wäre für Eltern bedeutungslos und läse sich wie eine
          Note. Liegen alle Befunde auf einer Stufe, gibt es dazu nichts zu
          sagen — dann steht hier nichts. */}
      {befunde.zurueckgegangen && (
        <p className="mt-1 text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
          {t('skillbefunde.tiefe')}
        </p>
      )}

      {/* Die tragenden Bereiche als EINE Aussage, nie einzeln aufgezählt: eine
          Liste von 33 Häkchen erschlägt die drei Befunde, um die es geht. */}
      {befunde.tragendAnzahl > 0 && (
        <p className="text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
          {t('skillbefunde.rest', { count: befunde.tragendAnzahl })}
        </p>
      )}
    </section>
  )
}
