import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import type { Skript } from '@/studio/skript/typen'

/** Mini-Checks der Sequenz mit Fehlbild und Rücksprung je Antwort (Änderungen über „Skript einfügen“). */
export function MiniCheckReiter({ skript }: { skript: Skript }): JSX.Element {
  const { t } = useTranslation('studio')
  if (skript.minichecks.length === 0)
    return <EmptyState icon="❔" title={t('minicheck.leer')} description={t('minicheck.leerText')} />
  return (
    <div className="flex flex-col gap-4">
      {skript.minichecks.map((m, i) => (
        <EdvanceCard key={i}>
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <span className="text-xs text-[var(--color-text-muted)]">{t('minicheck.nach', { beat: m.nach_beat })}</span>
              <h3 className="text-base font-semibold">{m.frage.skelett}</h3>
            </div>
            <ul className="flex flex-col gap-2">
              {m.optionen.map((o) => (
                <li key={o.antwort} className="flex flex-wrap items-baseline gap-2 text-sm leading-relaxed text-[var(--color-text-secondary)]">
                  <span className="font-semibold">{o.antwort}</span>
                  {o.richtig && <EdvanceBadge variant="strength">{t('minicheck.richtig')}</EdvanceBadge>}
                  {o.fehlbild && <EdvanceBadge variant="muted">{t('minicheck.fehlbild', { fehlbild: o.fehlbild })}</EdvanceBadge>}
                  {o.ruecksprung && <EdvanceBadge variant="primary">{t('minicheck.ruecksprung', { beat: o.ruecksprung })}</EdvanceBadge>}
                  <span>{o.rueckmeldung}</span>
                </li>
              ))}
            </ul>
            {(m.zwillinge?.length ?? 0) > 0 && (
              <span className="text-xs text-[var(--color-text-muted)]">{t('minicheck.zwillinge', { count: m.zwillinge?.length })}</span>
            )}
          </div>
        </EdvanceCard>
      ))}
    </div>
  )
}
