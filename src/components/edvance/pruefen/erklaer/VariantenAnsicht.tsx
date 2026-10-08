// Varianten einer Kernidee als Reiter (A, B, C). Je Schritt links die Kinderansicht, rechts der Entwurf
// zum Bearbeiten; beim Erklaerschritt die Fehlbild-Zuordnung der Variante (danach waehlt
// erklaer_check_abgeben die Variante nach einem falschen Check).

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { variantenVon } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerDetail, ErklaerSchritt, ErklaerVariante } from '@/types/erklaerPruefung'
import { ErklaerKindSchritt } from './ErklaerKindSchritt'
import { SchrittEditor } from './SchrittEditor'

type Props = {
  detail: ErklaerDetail
  /** Grund, warum nicht bearbeitet werden kann (Admin-Sicht, freigegeben); null = bearbeitbar. */
  gesperrt: string | null
  onSpeichern: (schritt: ErklaerSchritt, inhalt: string, slugs: string[]) => Promise<string | null>
}

export function VariantenAnsicht({ detail, gesperrt, onSpeichern }: Props): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const varianten = variantenVon(detail.schritte)
  const [aktiv, setAktiv] = useState<ErklaerVariante>(varianten[0] ?? 'A')
  const schritte = detail.schritte.filter((s) => s.variante === aktiv)
  const k = detail.kernidee

  if (varianten.length === 0) {
    return <p className="text-sm text-[var(--color-text-secondary)]">{t('detail.keineSchritte')}</p>
  }

  return (
    <section className="flex flex-col gap-4">
      <div role="tablist" aria-label={t('detail.varianten')} className="flex flex-wrap gap-2">
        {varianten.map((v) => {
          const erkl = detail.schritte.find((s) => s.variante === v && s.art === 'erklaerung')
          return (
            <button key={v} type="button" role="tab" aria-selected={v === aktiv} onClick={() => setAktiv(v)}
              className={cn('flex min-h-[44px] items-center gap-2 rounded-[var(--radius-full)] border px-4 text-sm',
                v === aktiv ? 'border-[var(--color-primary)] bg-[var(--color-primary)] font-semibold text-[var(--color-text-inverse)]'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]')}>
              {t('detail.variante', { variante: v })}
              {erkl && erkl.fehlbild_slugs.length > 0 && (
                <span className="text-xs opacity-80">{t('detail.fuerFehlbilder', { count: erkl.fehlbild_slugs.length })}</span>
              )}
            </button>
          )
        })}
      </div>
      <div role="tabpanel" className="flex flex-col gap-6">
        {schritte.map((s) => (
          <div key={s.id} className="grid gap-4 lg:grid-cols-[3fr_2fr]">
            <ErklaerKindSchritt schritt={s} kernideeNr={k.nr} kernideen={Math.max(k.kernideen, k.nr)} />
            <SchrittEditor key={`${s.id}:${s.geaendert_am}`} schritt={s} fehlbilder={detail.fehlbilder} gesperrt={gesperrt}
              onSpeichern={(inhalt, slugs) => onSpeichern(s, inhalt, slugs)} />
          </div>
        ))}
      </div>
    </section>
  )
}
