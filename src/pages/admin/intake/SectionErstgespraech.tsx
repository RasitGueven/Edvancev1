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
import type { IntakeFormState } from './formState'

type SectionErstgespraechProps = {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
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
}: SectionErstgespraechProps): JSX.Element {
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
        <FieldLabel>Letzte Zeugnisnote</FieldLabel>
        <OptionChips
          options={GRADES.map((g) => ({ value: g, label: g }))}
          selected={form.last_grade ? [form.last_grade] : []}
          onToggle={(v) => patch({ last_grade: single(form.last_grade, v) })}
        />
      </div>

      <div className="flex flex-col gap-2">
        <FieldLabel>Tendenz</FieldLabel>
        <OptionChips
          options={GRADE_TRENDS}
          selected={form.grade_trend ? [form.grade_trend] : []}
          onToggle={(v) =>
            patch({ grade_trend: single<LeadGradeTrend>(form.grade_trend, v) })
          }
        />
      </div>

      <div className="flex flex-col gap-2">
        <FieldLabel>Seit wann fällt es schwer?</FieldLabel>
        <OptionChips
          options={STRUGGLING_SINCE}
          selected={form.struggling_since ? [form.struggling_since] : []}
          onToggle={(v) =>
            patch({ struggling_since: single<LeadStrugglingSince>(form.struggling_since, v) })
          }
        />
      </div>

      <div className="flex flex-col gap-2">
        <FieldLabel>Was wurde schon versucht?</FieldLabel>
        <OptionChips options={TRIED_BEFORE} selected={form.tried_before} onToggle={toggleTried} />
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="exam-date">Nächste Klassenarbeit</Label>
          <Input
            id="exam-date"
            type="date"
            value={form.next_exam_date}
            onChange={(e) => patch({ next_exam_date: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="exam-topic">Thema der Klassenarbeit</Label>
          <Input
            id="exam-topic"
            value={form.next_exam_topic}
            onChange={(e) => patch({ next_exam_topic: e.target.value })}
            placeholder="z. B. Bruchrechnung"
          />
        </div>
      </div>

      <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4">
        <FieldLabel>Eltern-Einschätzung: Wo vermuten Sie die Schwierigkeiten?</FieldLabel>
        <p className="text-xs text-[var(--color-text-tertiary)]">
          Fließt nicht in die Auswertung ein — Gesprächskontext für den Coach.
        </p>
        <div className="mt-1">
          <OptionChips
            options={PARENT_WEAK_TOPICS.map((t) => ({ value: t, label: t }))}
            selected={form.parent_weak_topics}
            onToggle={toggleTopic}
            columns
          />
        </div>
        <Input
          className="mt-2"
          value={form.parent_note}
          onChange={(e) => patch({ parent_note: e.target.value })}
          placeholder="Kurze Ergänzung der Eltern (optional)"
        />
      </div>

      <div className="flex flex-col gap-2">
        <Label htmlFor="intake-notes">Notiz</Label>
        <textarea
          id="intake-notes"
          className={TEXTAREA_MD}
          value={form.notes}
          onChange={(e) => patch({ notes: e.target.value })}
          placeholder="Freie Notiz zum Gespräch"
        />
      </div>
    </div>
  )
}
