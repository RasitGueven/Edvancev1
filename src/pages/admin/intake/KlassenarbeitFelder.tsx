import { useTranslation } from 'react-i18next'

import { Input } from '@/components/ui/input'
import type { KlassenarbeitSpalten } from '@/lib/supabase/leads'

import { GRADES } from './intakeConstants'
import { KLASSENARBEIT_ANKER } from './KlassenarbeitHinweis'
import { OptionChips } from './OptionChips'
import type { IntakeFormState } from './formState'

const STAENDE = ['bevorstehend', 'geschrieben', 'weissNicht'] as const

/**
 * Bericht v4 (V4-E): Klassenarbeit zum aktuellen Thema im Erstgespräch.
 * Auswahl „steht noch an / schon geschrieben / weiß nicht“; bei „steht noch an“
 * das Datum der nächsten Arbeit (optional), bei „schon geschrieben“ die Note der
 * letzten Arbeit (optional, 1–6). Keine Pflichtfelder. Fehlt eine Spalte in der
 * DB, bleibt ihr Feld ausgeblendet.
 */
export function KlassenarbeitFelder({
  form,
  patch,
  spalten,
}: {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
  spalten: KlassenarbeitSpalten
}): JSX.Element | null {
  const { t } = useTranslation('admin')
  if (!spalten.status) return null
  const k = 'intake.erstgespraech.klassenarbeit'

  return (
    <div className="flex flex-col gap-2" data-testid="intake-klassenarbeit" id={KLASSENARBEIT_ANKER}>
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t(`${k}.titel`)}
      </p>
      <OptionChips
        options={STAENDE.map((v) => ({ value: v, label: t(`${k}.${v}`) }))}
        selected={form.klassenarbeit ? [form.klassenarbeit] : []}
        onToggle={(v) => patch({ klassenarbeit: form.klassenarbeit === v ? null : v })}
      />
      <p className="text-xs text-[var(--color-text-tertiary)]">{t(`${k}.hilfe`)}</p>

      {form.klassenarbeit === 'bevorstehend' && (
        <label className="mt-2 flex flex-col gap-2 text-sm" htmlFor="intake-naechste-arbeit">
          <span>{t(`${k}.datum`)}</span>
          <Input
            id="intake-naechste-arbeit"
            type="date"
            className="min-h-11 max-w-xs"
            value={form.naechste_arbeit_datum}
            onChange={(e) => patch({ naechste_arbeit_datum: e.target.value })}
          />
        </label>
      )}

      {form.klassenarbeit === 'geschrieben' && spalten.note && (
        <div className="mt-2 flex flex-col gap-2" data-testid="intake-letzte-note">
          <p className="text-sm">{t(`${k}.note`)}</p>
          <OptionChips
            options={GRADES.map((g) => ({ value: g, label: g }))}
            selected={form.letzte_note ? [String(form.letzte_note)] : []}
            onToggle={(v) => patch({ letzte_note: form.letzte_note === Number(v) ? null : Number(v) })}
          />
          <p className="text-xs text-[var(--color-text-tertiary)]">{t(`${k}.noteHilfe`)}</p>
        </div>
      )}
    </div>
  )
}
