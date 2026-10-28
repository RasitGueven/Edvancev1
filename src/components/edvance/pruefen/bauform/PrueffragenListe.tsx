// Coach-Pruefgespraeche: Lena prueft jede Frage einzeln (kurzer Text, Konzept §1 Entscheidung 6).
import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui'
import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import type { PrueffrageZeile } from '@/types/bauformPruefung'

type Props = { zeilen: PrueffrageZeile[]; onEntscheide: (id: string, e: 'passt' | 'passt_nicht', notiz: string | null) => void }

export function PrueffragenListe({ zeilen, onEntscheide }: Props): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const [notiz, setNotiz] = useState<Record<string, string>>({})
  if (zeilen.length === 0) return <EmptyState icon="💬" title={t('prueffragen.leer')} description={t('prueffragen.leerSatz')} />
  return (
    <ul className="flex flex-col gap-4">
      {zeilen.map((z) => (
        <li key={z.id}>
          <EdvanceCard className="flex flex-col gap-2">
            <div className="flex flex-wrap items-center gap-2">
              <EdvanceBadge variant="muted">{z.skill_label}</EdvanceBadge>
              <EdvanceBadge variant={z.status === 'entwurf' ? 'warning' : 'primary'}>{z.status}</EdvanceBadge>
              {z.geprueft_von && <span className="text-xs text-[var(--color-text-muted)]">{t('prueffragen.geprueftVon', { name: z.geprueft_von })}</span>}
            </div>
            <p className="text-base font-semibold text-[var(--color-text-primary)]">{z.frage}</p>
            <p className="text-sm text-[var(--color-text-secondary)]">{t('prueffragen.erwartung')}: {z.erwartung}</p>
            <p className="text-sm text-[var(--color-text-secondary)]">{t('prueffragen.kriterium')}: {z.kriterium}</p>
            {z.status !== 'freigegeben' && (
              <div className="flex flex-wrap items-center gap-2">
                <input aria-label={t('prueffragen.notizPlatzhalter')} placeholder={t('prueffragen.notizPlatzhalter')} value={notiz[z.id] ?? ''}
                  onChange={(e) => setNotiz((n) => ({ ...n, [z.id]: e.target.value }))}
                  className="min-h-[44px] flex-1 rounded-[var(--radius-md)] border border-[var(--color-border)] px-3 text-sm" />
                <Button variant="outline" disabled={!(notiz[z.id] ?? '').trim()} title={t('prueffragen.notizPlatzhalter')}
                  onClick={() => onEntscheide(z.id, 'passt_nicht', (notiz[z.id] ?? '').trim())}>{t('prueffragen.passtNicht')}</Button>
                <Button onClick={() => onEntscheide(z.id, 'passt', (notiz[z.id] ?? '').trim() || null)}>{t('prueffragen.passt')}</Button>
              </div>
            )}
          </EdvanceCard>
        </li>
      ))}
    </ul>
  )
}
