import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import type { SchoolKind } from '@/types'
import { CLASS_LEVELS, SCHOOL_TYPES, SUBJECTS } from './intakeConstants'
import { OptionChips } from './OptionChips'
import { SchulAuswahl } from './SchulAuswahl'
import type { IntakeFormState } from './formState'

type SectionLeadProps = {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
}

// Schritt 1 — Stammdaten in einem Rutsch. first_name gross und prominent, weil
// der Rufname auf dem Tablet erscheint.
export function SectionLead({ form, patch }: SectionLeadProps): JSX.Element {
  const { t } = useTranslation('admin')
  const toggleSubject = (subject: string): void => {
    const list = form.subjects
    patch({
      subjects: list.includes(subject)
        ? list.filter((s) => s !== subject)
        : [...list, subject],
    })
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <Label htmlFor="lead-first-name" className="text-base font-semibold">
          {t('intake.lead.firstName')}
        </Label>
        <Input
          id="lead-first-name"
          className="h-12 text-lg"
          value={form.first_name}
          onChange={(e) => patch({ first_name: e.target.value })}
          placeholder={t('intake.lead.firstNamePlaceholder')}
        />
        <p className="text-xs text-[var(--color-text-tertiary)]">
          {t('intake.lead.firstNameHint', { name: form.first_name.trim() || '…' })}
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-full-name">{t('intake.lead.fullName')}</Label>
          <Input
            id="lead-full-name"
            value={form.full_name}
            onChange={(e) => patch({ full_name: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-birth">{t('intake.lead.birthDate')}</Label>
          <Input
            id="lead-birth"
            type="date"
            value={form.birth_date}
            onChange={(e) => patch({ birth_date: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-class">{t('intake.lead.classLevel')}</Label>
          <select
            id="lead-class"
            className={SELECT_MD}
            value={form.class_level ?? ''}
            onChange={(e) =>
              patch({ class_level: e.target.value ? Number(e.target.value) : null })
            }
          >
            <option value="">{t('intake.lead.none')}</option>
            {CLASS_LEVELS.map((level) => (
              <option key={level} value={level}>
                {t('intake.lead.classOption', { level })}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-schooltype">{t('intake.lead.schoolType')}</Label>
          <select
            id="lead-schooltype"
            className={SELECT_MD}
            value={form.school_type ?? ''}
            onChange={(e) =>
              patch({ school_type: (e.target.value || null) as SchoolKind | null })
            }
          >
            <option value="">{t('intake.lead.none')}</option>
            {SCHOOL_TYPES.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
        </div>
        <div className="sm:col-span-2">
          <SchulAuswahl
            schulform={form.school_type}
            schuleId={form.schule_id}
            schoolName={form.school_name}
            onChange={patch}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-email">{t('intake.lead.contactEmail')}</Label>
          <Input
            id="lead-email"
            type="email"
            value={form.contact_email}
            onChange={(e) => patch({ contact_email: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-phone">{t('intake.lead.contactPhone')}</Label>
          <Input
            id="lead-phone"
            value={form.contact_phone}
            onChange={(e) => patch({ contact_phone: e.target.value })}
          />
        </div>
        <p className="text-xs text-[var(--color-text-tertiary)] sm:col-span-2">
          {t('intake.lead.contactHint')}
        </p>
      </div>

      <div className="flex flex-col gap-2">
        <Label>{t('intake.lead.subjects')}</Label>
        <OptionChips
          options={SUBJECTS.map((s) => ({ value: s, label: s }))}
          selected={form.subjects}
          onToggle={toggleSubject}
        />
      </div>
    </div>
  )
}
