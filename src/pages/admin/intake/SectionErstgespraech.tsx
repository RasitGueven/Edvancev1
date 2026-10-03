import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { TEXTAREA_MD } from '@/lib/formStyles'
import type { LeadGradeTrend, LeadStrugglingSince } from '@/types'
import {
  GRADES,
  GRADE_TRENDS,
  PARENT_WEAK_TOPICS,
  STRUGGLING_SINCE,
  TRIED_BEFORE,
} from './intakeConstants'
import { OptionChips } from './OptionChips'
import { ThemenAuswahl, type ThemenStatus } from './ThemenAuswahl'
import { ConsentBlock, type ConsentState } from './ConsentBlock'
import type { IntakeFormState } from './formState'

type SectionErstgespraechProps = {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
  /** Fach fuer die Themenauswahl — bei mehreren Faechern die Auswahl unten. */
  subject: string | null
  onSelectSubject: (subject: string) => void
  /** Angelegter Lead; lead_themen haengen an ihm. */
  leadId: string | null
  onThemenStatus: (status: ThemenStatus) => void
  consent: ConsentState
  consentSaving: boolean
  onSign: (signature: string) => void
  consentByLabel: string | null
  /** Ohne angelegten Lead haengt die Einwilligung an nichts. */
  consentDisabled: boolean
}

const FieldLabel = ({ children }: { children: string }): JSX.Element => (
  <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
    {children}
  </p>
)

// Schritt 2 — das eigentliche Erstgespraech. Fast alles Klick-Auswahl, EIN
// Freitextfeld am Ende.
export function SectionErstgespraech({
  form,
  patch,
  subject,
  onSelectSubject,
  leadId,
  onThemenStatus,
  consent,
  consentSaving,
  onSign,
  consentByLabel,
  consentDisabled,
}: SectionErstgespraechProps): JSX.Element {
  const { t } = useTranslation('admin')
  const toggleTried = (value: string): void => {
    const list = form.tried_before
    patch({
      tried_before: list.includes(value)
        ? list.filter((v) => v !== value)
        : [...list, value],
    })
  }

  const toggleTopic = (value: string): void => {
    const list = form.parent_weak_topics
    patch({
      parent_weak_topics: list.includes(value)
        ? list.filter((v) => v !== value)
        : [...list, value],
    })
  }

  // Single-Select-Helfer: Klick auf die aktive Option waehlt sie ab.
  const single = <T extends string>(current: T | null, value: T): T | null =>
    current === value ? null : value

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <FieldLabel>{t('intake.erstgespraech.lastGrade')}</FieldLabel>
        <OptionChips
          options={GRADES.map((g) => ({ value: g, label: g }))}
          selected={form.last_grade ? [form.last_grade] : []}
          onToggle={(v) => patch({ last_grade: single(form.last_grade, v) })}
        />
      </div>

      <div className="flex flex-col gap-2">
        <FieldLabel>{t('intake.erstgespraech.gradeTrend')}</FieldLabel>
        <OptionChips
          options={GRADE_TRENDS.map((v) => ({
            value: v,
            label: t(`intake.optionen.gradeTrend.${v}`),
          }))}
          selected={form.grade_trend ? [form.grade_trend] : []}
          onToggle={(v) =>
            patch({ grade_trend: single<LeadGradeTrend>(form.grade_trend, v) })
          }
        />
      </div>

      <div className="flex flex-col gap-2">
        <FieldLabel>{t('intake.erstgespraech.strugglingSince')}</FieldLabel>
        <OptionChips
          options={STRUGGLING_SINCE.map((v) => ({
            value: v,
            label: t(`intake.optionen.strugglingSince.${v}`),
          }))}
          selected={form.struggling_since ? [form.struggling_since] : []}
          onToggle={(v) =>
            patch({ struggling_since: single<LeadStrugglingSince>(form.struggling_since, v) })
          }
        />
      </div>

      <div className="flex flex-col gap-2">
        <FieldLabel>{t('intake.erstgespraech.triedBefore')}</FieldLabel>
        <OptionChips
          options={TRIED_BEFORE.map((v) => ({
            value: v,
            label: t(`intake.optionen.triedBefore.${v}`),
          }))}
          selected={form.tried_before}
          onToggle={toggleTried}
        />
      </div>

      <ThemenAuswahl
        form={form}
        patch={patch}
        subject={subject}
        leadId={leadId}
        onStatus={onThemenStatus}
      />

      <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4">
        <FieldLabel>{t('intake.erstgespraech.parentWeak')}</FieldLabel>
        <p className="text-xs text-[var(--color-text-tertiary)]">
          {t('intake.erstgespraech.parentWeakHint')}
        </p>
        <div className="mt-1">
          <OptionChips
            options={PARENT_WEAK_TOPICS.map((o) => ({
              value: o.value,
              label: t(`intake.optionen.parentWeak.${o.key}`),
            }))}
            selected={form.parent_weak_topics}
            onToggle={toggleTopic}
            columns
          />
        </div>
        <Input
          className="mt-2"
          value={form.parent_note}
          onChange={(e) => patch({ parent_note: e.target.value })}
          placeholder={t('intake.erstgespraech.parentNotePlaceholder')}
        />
      </div>

      <div className="flex flex-col gap-2">
        <Label htmlFor="intake-notes">{t('intake.erstgespraech.notes')}</Label>
        <textarea
          id="intake-notes"
          className={TEXTAREA_MD}
          value={form.notes}
          onChange={(e) => patch({ notes: e.target.value })}
          placeholder={t('intake.erstgespraech.notesPlaceholder')}
        />
      </div>

      <ConsentBlock
        form={form}
        consent={consent}
        saving={consentSaving}
        onSign={onSign}
        selectedSubject={subject}
        onSelectSubject={onSelectSubject}
        byLabel={consentByLabel}
        disabled={consentDisabled}
      />
    </div>
  )
}
