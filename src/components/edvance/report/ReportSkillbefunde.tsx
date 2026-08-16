import { useTranslation } from 'react-i18next'

import type { ReportSkillbefunde } from '@/types'

/**
 * „Was wir uns genauer ansehen" — die Skill-Ebene der Diagnose (R2/R3).
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
 * R3 — AUFGEKLAPPT NUR AUF WUNSCH:
 * Am Bildschirm steht der Abschnitt zugeklappt. Die Überschrift nennt die Zahl
 * der Bereiche, die Namen kommen auf Klick — Eltern, die zu Hause tiefer
 * schauen wollen, öffnen ihn. Gelöst über `<details>`: kein Skript, kein
 * Zustand, und im Druck steht er offen (siehe src/styles/print.css). Der
 * UA-Pfeil ist abgeschaltet und durch einen Winkel in Gold ersetzt, damit die
 * Zeile wie eine Abschnittsüberschrift aussieht und nicht wie ein Bedienelement.
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
    <details className="report-block report-hauptteil">
      <summary className="flex cursor-pointer list-none items-baseline gap-3">
        <span className="report-winkel mt-1 shrink-0" aria-hidden="true" />
        <span className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
          <h3 className={titleClassName}>{t('skillbefunde.title')}</h3>
          <span className="report-details-hint text-xs text-[color-mix(in_srgb,var(--color-report-navy)_55%,transparent)]">
            {t('skillbefunde.count', { count: befunde.nichtTragend.length })}
          </span>
        </span>
      </summary>

      <div className="report-details-body mt-3 flex flex-col gap-2">
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
            Note. Liegen alle Befunde auf einer Stufe, steht hier nichts. */}
        {befunde.zurueckgegangen && (
          <p className="mt-1 text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
            {t('skillbefunde.tiefe')}
          </p>
        )}

        {/* Die tragenden Bereiche als EINE Aussage, nie einzeln aufgezählt: eine
            Liste von Häkchen erschlägt die Befunde, um die es geht. */}
        {befunde.tragendAnzahl > 0 && (
          <p className="text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
            {t('skillbefunde.rest', { count: befunde.tragendAnzahl })}
          </p>
        )}
      </div>
    </details>
  )
}
