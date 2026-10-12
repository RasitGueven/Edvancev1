import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { uhrzeit } from '@/pages/admin/slots/slotsFormat'
import type { TagAbsage } from '@/types/slotplan'
import { OkZeile } from './ArbeitsListe'

/**
 * Block „Absagen heute“ in „Heute im Betrieb“ (Hüllen-Dummy): Name, Uhrzeit, Eingang und rechtzeitig
 * (strength) oder unentschuldigt (coach-emergency), darunter die 10-Uhr-Regel. Ob rechtzeitig,
 * entscheidet der Server; hier wird nur angezeigt. Leer: grün „nichts offen“ wie die Arbeitslisten.
 */
export function AbsagenHeute({ absagen }: { absagen: TagAbsage[] }): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const sortiert = [...absagen].sort((a, b) => a.beginn.localeCompare(b.beginn) || (a.name ?? '').localeCompare(b.name ?? '', 'de'))

  return (
    <section aria-labelledby="heute-absagen" className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
      <h4 id="heute-absagen" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('heute.absagen.titel')}
      </h4>
      <ul className="flex flex-col">
        {sortiert.map((a) => (
          <li key={a.termin_id} className="flex min-h-[44px] flex-wrap items-center gap-2 border-t border-[var(--color-border)] py-2 first:border-t-0">
            <span className="flex min-w-0 flex-1 flex-col">
              <span className="truncate text-sm font-semibold">{a.name ?? '—'}</span>
              <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                {t('heute.absagen.zeile', { beginn: a.beginn, eingang: uhrzeit(a.absage_eingang, i18n.language) })}
              </span>
            </span>
            <EdvanceBadge variant={a.rechtzeitig ? 'strength' : 'coach-emergency'}>
              {t(a.rechtzeitig ? 'heute.absagen.rechtzeitig' : 'heute.absagen.unentschuldigt')}
            </EdvanceBadge>
          </li>
        ))}
        {sortiert.length === 0 && <OkZeile text={t('heute.nichtsOffen')} />}
      </ul>
      <p className="text-xs text-[var(--color-text-tertiary)]">{t('heute.absagen.regel')}</p>
    </section>
  )
}
