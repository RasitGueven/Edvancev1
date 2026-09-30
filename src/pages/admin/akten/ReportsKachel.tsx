import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { datum } from '@/lib/akte/format'
import { reportLink } from '@/lib/supabase/akte'
import type { ElternReport } from '@/types'

/**
 * Reports (Anforderung H): was an die Eltern ging, aus eltern_reports.
 * Felder, die es (noch) nicht gibt — bei Report 1 heute freigegeben_von,
 * versendet_am und pdf_pfad — werden weggelassen bzw. als "keine gespeicherte
 * Fassung" gezeigt.
 */
export function ReportsKachel({ reports }: { reports: ElternReport[] }): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const lang = i18n.language
  const [fehler, setFehler] = useState<string | null>(null)

  const oeffnen = async (pfad: string): Promise<void> => {
    setFehler(null)
    const { data, error } = await reportLink(pfad)
    if (error || !data) {
      setFehler(t('reports.fassungFehler'))
      return
    }
    window.open(data, '_blank', 'noopener')
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('reports.titel')}
      </h2>
      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}
      {reports.length === 0 ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('reports.leer')}</p>
      ) : (
        <ul className="flex flex-col gap-4">
          {reports.map((r) => (
            <li key={r.id} className="flex flex-col gap-2 border-b border-[var(--color-border)] pb-4 last:border-b-0 last:pb-0">
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-base font-semibold text-[var(--color-text-primary)]">{t('reports.nr', { nr: r.nr })}</span>
                <EdvanceBadge variant="muted">{t(`reports.art.${r.art}`)}</EdvanceBadge>
              </div>
              {r.kernaussagen &&
                Object.entries(r.kernaussagen).map(([fach, satz]) => (
                  <p key={fach} className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                    <span className="font-semibold">{fach}:</span> {satz}
                  </p>
                ))}
              <div className="flex flex-wrap gap-4 text-xs text-[var(--color-text-tertiary)]">
                {r.freigegeben_von_name && <span>{t('reports.freigegebenVon', { name: r.freigegeben_von_name })}</span>}
                {r.versendet_am && <span>{t('reports.versendetAm', { datum: datum(r.versendet_am, lang) })}</span>}
              </div>
              {r.pdf_pfad ? (
                <div>
                  <Button size="sm" variant="outline" onClick={() => void oeffnen(r.pdf_pfad as string)}>
                    {t('reports.fassung')}
                  </Button>
                </div>
              ) : (
                <span className="text-xs text-[var(--color-text-tertiary)]">{t('reports.keineFassung')}</span>
              )}
            </li>
          ))}
        </ul>
      )}
    </EdvanceCard>
  )
}
