import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { listKaPlanThemen, type KaPlanThema } from '@/lib/supabase/kaFolge'

import { OptionChips } from './OptionChips'
import type { IntakeFormState } from './formState'

const ANZAHLEN = [4, 5, 6, 'weissNicht'] as const

/**
 * L5 Teil B (Entscheidung 6): Zahl der Mathearbeiten im Schuljahr und die Themen der nächsten bzw. der geschriebenen
 * Arbeit, alles optional. Die Themen kommen aus dem Schulplan der Klasse; ohne Schule oder Plan entfällt die Auswahl.
 * Bei „schon geschrieben“ ist das aktuelle Thema vorausgewählt (KlassenarbeitFelder setzt es beim Umschalten).
 */
export function KaFolgeFelder({
  form,
  patch,
}: {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
}): JSX.Element {
  const { t } = useTranslation('admin')
  const k = 'intake.erstgespraech.klassenarbeit'
  const [plan, setPlan] = useState<KaPlanThema[]>([])
  useEffect(() => {
    if (!form.schule_id || form.class_level === null) {
      setPlan([])
      return
    }
    let aktiv = true
    void listKaPlanThemen(form.schule_id, form.class_level).then(({ data }) => {
      if (aktiv) setPlan(data ?? [])
    })
    return () => {
      aktiv = false
    }
  }, [form.schule_id, form.class_level])

  const toggleThema = (key: string): void =>
    patch({ ka_themen: form.ka_themen.includes(key) ? form.ka_themen.filter((x) => x !== key) : [...form.ka_themen, key] })
  const frage = form.klassenarbeit === 'geschrieben' ? 'themenGeschrieben' : 'themenNaechste'

  return (
    <div className="mt-2 flex flex-col gap-2" data-testid="intake-ka-folge">
      <p className="text-sm">{t(`${k}.anzahl`)}</p>
      <OptionChips
        options={ANZAHLEN.map((v) => ({ value: v, label: v === 'weissNicht' ? t(`${k}.weissNicht`) : String(v) }))}
        selected={form.ka_anzahl === null ? [] : [form.ka_anzahl]}
        onToggle={(v) => patch({ ka_anzahl: form.ka_anzahl === v ? null : v })}
      />
      {(form.klassenarbeit === 'bevorstehend' || form.klassenarbeit === 'geschrieben') && plan.length > 0 && (
        <div className="mt-2 flex flex-col gap-2" data-testid="intake-ka-themen">
          <p className="text-sm">{t(`${k}.${frage}`)}</p>
          <OptionChips
            options={plan.map((p) => ({ value: p.themaKey, label: p.titel }))}
            selected={form.ka_themen}
            onToggle={toggleThema}
            columns
          />
        </div>
      )}
      <p className="text-xs text-[var(--color-text-tertiary)]">{t(`${k}.termineHilfe`)}</p>
    </div>
  )
}
