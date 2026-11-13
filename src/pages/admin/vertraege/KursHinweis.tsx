import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { kindKursZumLead, type KindKursZeile } from '@/lib/supabase/kindKurs'
import type { VertragMitLead } from '@/types'

/**
 * SF-1: Hat das provisorische Kind schon einen Mathe-Verlauf, übernimmt der Abschluss die Angabe am Lead
 * nicht (Trigger kind_kurs_von_lead). Weichen beide ab, sagt der Hinweis das vor dem Abschluss.
 * Folgeverträge betrifft es nicht: Dort wird der Lead nicht mehr umgestellt.
 */
export function KursHinweis({ vertrag }: { vertrag: VertragMitLead }): JSX.Element | null {
  const { t } = useTranslation('vertraege')
  const { t: ta } = useTranslation('admin')
  const [akte, setAkte] = useState<KindKursZeile | null>(null)
  const lead = vertrag.lead
  const offen = vertrag.status === 'in_vorbereitung' || vertrag.status === 'unterschrift_ausstehend'
  const leadKurs = lead?.kurs_mathe ?? null
  const leadZiel = lead?.abschlussziel ?? null
  const relevant = offen && vertrag.student_id === null && (leadKurs !== null || leadZiel !== null)

  useEffect(() => {
    if (!relevant) return
    void kindKursZumLead(vertrag.lead_id).then(({ data }) => setAkte(data))
  }, [relevant, vertrag.lead_id])

  if (!relevant || !akte) return null
  if (akte.kurs === leadKurs && akte.abschlussziel === leadZiel) return null

  const text = (kurs: string | null, ziel: string | null): string =>
    [kurs ? ta(`intake.kurs.kurse.${kurs}`) : null, ziel ? ta(`intake.kurs.ziele.${ziel}`) : null]
      .filter(Boolean)
      .join(' · ') || ta('intake.kurs.offen')

  return (
    <EdvanceCard className="border border-[var(--color-warning)] bg-[var(--color-warning-light)] p-6">
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]" data-testid="vertrag-kurs-hinweis">
        {t('kursHinweis.text', {
          lead: text(leadKurs, leadZiel),
          akte: text(akte.kurs, akte.abschlussziel),
        })}
      </p>
    </EdvanceCard>
  )
}
