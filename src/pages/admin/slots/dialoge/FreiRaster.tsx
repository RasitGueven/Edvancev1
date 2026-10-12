import { useTranslation } from 'react-i18next'
import type { SlotsFrei } from '@/types/slotplan'
import { wochentagName } from '../slotsFormat'
import type { Zeile } from './StammplatzDialog'

/**
 * Raster der freien Plätze (slots_frei): kleinster Wert der nächsten sechs Termine im Takt der aktiven Zeile.
 * Ein Tippen übernimmt den Slot in die aktive Zeile. "voll" und "kein Raum" sind gedämpft und nicht wählbar
 * (kein gesperrter Knopf, sondern ein Text).
 */
export function FreiRaster({
  frei,
  zeilen,
  aktiv,
  onWahl,
}: {
  frei: SlotsFrei
  zeilen: Zeile[]
  aktiv: number
  onWahl: (wochentag: number, zeitId: string) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <div className="grid grid-cols-[3.5rem_repeat(5,minmax(0,1fr))] gap-1" role="grid" aria-label={t('dialog.stamm.rasterLabel')}>
      <span />
      {[1, 2, 3, 4, 5].map((w) => (
        <span key={w} role="columnheader" className="px-1 text-xs font-semibold text-[var(--color-text-tertiary)]">{wochentagName(w, i18n.language)}</span>
      ))}
      {frei.zeiten.map((zeit) => {
        // Eine Uhrzeit ohne Raum an allen Tagen wird eine schmale Zeile statt fünf "kein Raum"-Zellen.
        const ohneRaum = [1, 2, 3, 4, 5].every((w) => {
          const c = frei.zellen.find((x) => x.wochentag === w && x.zeit_id === zeit.id)
          return (!c || !c.raum) && !zeilen.some((z) => z.wochentag === w && z.zeit_id === zeit.id)
        })
        if (ohneRaum) {
          return (
            <div key={zeit.id} role="row" className="contents">
              <span role="rowheader" className="px-1 text-xs tabular-nums text-[var(--color-text-tertiary)]">{zeit.beginn}</span>
              <span role="gridcell" className="col-span-5 border-t border-dashed border-[var(--color-border)] px-1 text-xs text-[var(--color-text-tertiary)]">
                {t('dialog.stamm.zeitOhneRaum')}
              </span>
            </div>
          )
        }
        return (
        <div key={zeit.id} role="row" className="contents">
          <span role="rowheader" className="flex min-h-[44px] items-center px-1 text-xs font-semibold tabular-nums text-[var(--color-text-secondary)]">{zeit.beginn}</span>
          {[1, 2, 3, 4, 5].map((w) => {
            const zelle = frei.zellen.find((c) => c.wochentag === w && c.zeit_id === zeit.id)
            const gewaehlt = zeilen.findIndex((z) => z.wochentag === w && z.zeit_id === zeit.id)
            if (gewaehlt >= 0) {
              return (
                <span key={w} role="gridcell" className={`flex min-h-[44px] items-center justify-center rounded-[var(--radius-md)] text-xs font-semibold ${
                  gewaehlt === aktiv ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]' : 'bg-[var(--color-primary-light)] text-[var(--color-primary)]'
                }`}>
                  {t('dialog.stamm.zeile', { zeile: gewaehlt + 1 })}
                </span>
              )
            }
            if (zelle?.raum && !zelle.voll && zelle.art_konflikt) {
              // SL2b (Entscheidung 4): Testkonto und echtes Kind nie im selben Termin; wie "voll" nicht wählbar.
              return (
                <span key={w} role="gridcell" title={t('dialog.stamm.artKonfliktTitel')} className="flex min-h-[44px] items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] text-xs text-[var(--color-text-tertiary)]">
                  {t('dialog.stamm.artKonflikt')}
                </span>
              )
            }
            if (!zelle || !zelle.raum || zelle.voll) {
              return (
                <span key={w} role="gridcell" className="flex min-h-[44px] items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] text-xs text-[var(--color-text-tertiary)]">
                  {t(!zelle || !zelle.raum ? 'dialog.stamm.keinRaum' : 'dialog.stamm.voll')}
                </span>
              )
            }
            return (
              <span key={w} role="gridcell">
                <button type="button" onClick={() => onWahl(w, zeit.id)}
                  aria-label={t('dialog.stamm.freiLabel', { tag: wochentagName(w, i18n.language, true), beginn: zeit.beginn, count: zelle.frei })}
                  className={`flex min-h-[44px] w-full items-center justify-center rounded-[var(--radius-md)] border text-xs font-semibold tabular-nums transition-colors duration-150 ease-out hover:bg-[var(--color-primary-light)] ${
                    zelle.frei <= 1 ? 'border-[var(--color-gold-warning)] text-[var(--color-gold-warning)]' : 'border-[var(--color-border)] text-[var(--color-text-primary)]'
                  }`}>
                  {t('dialog.ziele.frei', { count: zelle.frei })}
                </button>
              </span>
            )
          })}
        </div>
        )
      })}
    </div>
  )
}
