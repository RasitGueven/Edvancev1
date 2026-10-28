// Reiter „Auffaellig“: gemeldete und von der Bewaehrung markierte Aufgaben mit Antworthaeufigkeiten (Konzept §6).
import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui'
import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import type { AuffaelligZeile } from '@/types/bauformPruefung'

type Props = {
  zeilen: AuffaelligZeile[]
  onReaktivieren: (taskId: string) => void
  onUeberarbeiten: (bauformId: string, grund: string) => void
  onBauformReaktivieren: (bauformId: string, grund: string) => void
}

export function AuffaelligListe({ zeilen, onReaktivieren, onUeberarbeiten, onBauformReaktivieren }: Props): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const [grund, setGrund] = useState<Record<string, string>>({})
  if (zeilen.length === 0) return <EmptyState icon="✅" title={t('auffaellig.leer')} description={t('auffaellig.leerSatz')} />
  return (
    <ul className="flex flex-col gap-4">
      {zeilen.map((z) => (
        <li key={z.task_id}>
          <EdvanceCard className="flex flex-col gap-3">
            <div className="flex flex-wrap items-center gap-2">
              {z.schluessel && <EdvanceBadge variant="primary">{z.schluessel}</EdvanceBadge>}
              <EdvanceBadge variant="warning">{t(`auffaellig.grund.${z.grund ?? 'gemeldet'}`, { defaultValue: z.grund ?? '' })}</EdvanceBadge>
              {z.stufe && <span className="text-xs text-[var(--color-text-muted)]">S{z.stufe} · {z.rolle}</span>}
            </div>
            <p className="text-base text-[var(--color-text-primary)]">{z.frage}</p>
            <p className="text-sm text-[var(--color-text-secondary)]">{t('auffaellig.bearbeitungen', { richtig: z.richtig, bearbeitungen: z.bearbeitungen })}</p>
            {z.haeufigste_unbekannte && (
              <p className="text-sm text-[var(--color-text-secondary)]">
                {t('auffaellig.unbekannt', { antwort: `${z.haeufigste_unbekannte} (${z.unbekannt[z.haeufigste_unbekannte] ?? 0}×)` })}
              </p>
            )}
            {z.meldungen.map((m, i) => (
              <p key={i} className="text-sm text-[var(--color-text-secondary)]">{t('auffaellig.meldung', { grund: m.grund })}{m.von ? ` · ${m.von}` : ''}</p>
            ))}
            <div className="flex flex-wrap items-center gap-2">
              <Button variant="outline" onClick={() => onReaktivieren(z.task_id)}>{t('auffaellig.reaktivieren')}</Button>
              {z.bauform_id && (
                <>
                  <input aria-label={t('auffaellig.grundPlatzhalter')} placeholder={t('auffaellig.grundPlatzhalter')}
                    value={grund[z.task_id] ?? ''} onChange={(e) => setGrund((g) => ({ ...g, [z.task_id]: e.target.value }))}
                    className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] px-3 text-sm" />
                  <Button variant="outline" disabled={!(grund[z.task_id] ?? '').trim()}
                    onClick={() => onUeberarbeiten(z.bauform_id as string, (grund[z.task_id] ?? '').trim())}>{t('auffaellig.ueberarbeiten')}</Button>
                  {z.bauform_status === 'pausiert' && (
                    <Button variant="outline" disabled={!(grund[z.task_id] ?? '').trim()}
                      onClick={() => onBauformReaktivieren(z.bauform_id as string, (grund[z.task_id] ?? '').trim())}>{t('auffaellig.bauformReaktivieren')}</Button>
                  )}
                </>
              )}
            </div>
          </EdvanceCard>
        </li>
      ))}
    </ul>
  )
}
