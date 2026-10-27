// Ein Beispiel einer Bauform in Lenas Pruefansicht: links wie auf dem Tablet (PreviewStage), rechts Loesung,
// Fehlbild-Antworten, Hinweise und Loesungsweg (nur fuer Lena).
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { PreviewStage } from '@/components/edvance/authoring/PreviewStage'
import type { BauformBeispiel as Beispiel } from '@/types/bauformPruefung'
import { loesungText } from './loesungText'

export function BauformBeispiel({ beispiel }: { beispiel: Beispiel }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const fehlbilder = (beispiel.loesung?.fehlbilder ?? []) as Array<Record<string, unknown> & { key: string }>
  return (
    <EdvanceCard className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-2">
        <EdvanceBadge variant="primary">{t('detail.stufe', { stufe: beispiel.stufe })}</EdvanceBadge>
        <EdvanceBadge variant="muted">{t('detail.rolle', { rolle: beispiel.rolle })}</EdvanceBadge>
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <PreviewStage payload={beispiel.payload} />
        <dl className="flex flex-col gap-3 text-sm">
          <div>
            <dt className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('detail.loesung')}</dt>
            <dd className="text-base font-semibold text-[var(--color-text-primary)]">{loesungText(beispiel.loesung)}</dd>
          </div>
          {fehlbilder.length > 0 && (
            <div>
              <dt className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('detail.fehlbilder')}</dt>
              {fehlbilder.map((f) => (
                <dd key={f.key} className="text-[var(--color-text-secondary)]">
                  <span className="font-mono text-xs">{f.key}</span>: {loesungText(f)}
                </dd>
              ))}
            </div>
          )}
          <div>
            <dt className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('detail.hinweise')}</dt>
            {beispiel.hinweise.map((h) => (
              <dd key={h.level} className="text-[var(--color-text-secondary)]">
                {t('detail.hinweis', { stufe: h.level })}: {h.text}
              </dd>
            ))}
          </div>
          {beispiel.loesungsweg && (
            <div>
              <dt className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('detail.loesungsweg')}</dt>
              <dd className="whitespace-pre-wrap text-[var(--color-text-secondary)]">{beispiel.loesungsweg}</dd>
            </div>
          )}
        </dl>
      </div>
    </EdvanceCard>
  )
}
