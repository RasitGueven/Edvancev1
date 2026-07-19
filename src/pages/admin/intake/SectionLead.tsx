import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import type { SchoolKind } from '@/types'
import { CLASS_LEVELS, SCHOOL_TYPES, SUBJECTS } from './intakeConstants'
import { OptionChips } from './OptionChips'
import type { IntakeFormState } from './formState'

type SectionLeadProps = {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
}

// Schritt 1 — Stammdaten in einem Rutsch. first_name gross und prominent, weil
// der Rufname auf dem Tablet erscheint.
export function SectionLead({ form, patch }: SectionLeadProps): JSX.Element {
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
          Rufname des Kindes *
        </Label>
        <Input
          id="lead-first-name"
          className="h-12 text-lg"
          value={form.first_name}
          onChange={(e) => patch({ first_name: e.target.value })}
          placeholder="z. B. Mia"
        />
        <p className="text-xs text-[var(--color-text-tertiary)]">
          Erscheint auf dem Tablet als „Hi {form.first_name.trim() || '…'}" — muss exakt stimmen.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-full-name">Vollständiger Name *</Label>
          <Input
            id="lead-full-name"
            value={form.full_name}
            onChange={(e) => patch({ full_name: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-birth">Geburtsdatum</Label>
          <Input
            id="lead-birth"
            type="date"
            value={form.birth_date}
            onChange={(e) => patch({ birth_date: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-class">Klasse</Label>
          <select
            id="lead-class"
            className={SELECT_MD}
            value={form.class_level ?? ''}
            onChange={(e) =>
              patch({ class_level: e.target.value ? Number(e.target.value) : null })
            }
          >
            <option value="">–</option>
            {CLASS_LEVELS.map((lvl) => (
              <option key={lvl} value={lvl}>
                {lvl}. Klasse
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-schooltype">Schulform</Label>
          <select
            id="lead-schooltype"
            className={SELECT_MD}
            value={form.school_type ?? ''}
            onChange={(e) =>
              patch({ school_type: (e.target.value || null) as SchoolKind | null })
            }
          >
            <option value="">–</option>
            {SCHOOL_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2 sm:col-span-2">
          <Label htmlFor="lead-schoolname">Schule (optional)</Label>
          <Input
            id="lead-schoolname"
            value={form.school_name}
            onChange={(e) => patch({ school_name: e.target.value })}
            placeholder="z. B. Gymnasium Köln-Nippes"
          />
          <p className="text-xs text-[var(--color-text-tertiary)]">
            Schulen setzen Themen in unterschiedlichen Jahrgangsstufen an — hilft
            später bei der Einordnung. Kein Einfluss auf die Aufgabenwahl.
          </p>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-email">E-Mail (Eltern)</Label>
          <Input
            id="lead-email"
            type="email"
            value={form.contact_email}
            onChange={(e) => patch({ contact_email: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-phone">Telefon (Eltern)</Label>
          <Input
            id="lead-phone"
            value={form.contact_phone}
            onChange={(e) => patch({ contact_phone: e.target.value })}
          />
        </div>
      </div>

      <div className="flex flex-col gap-2">
        <Label>Fach / Fächer *</Label>
        <OptionChips
          options={SUBJECTS.map((s) => ({ value: s, label: s }))}
          selected={form.subjects}
          onToggle={toggleSubject}
        />
      </div>
    </div>
  )
}
