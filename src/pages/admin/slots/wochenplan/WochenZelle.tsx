import { useTranslation } from 'react-i18next'
import type { WocheZelle } from '@/types/slotplan'
import { TestKennzeichen } from '../TestKennzeichen'
import { RaumZeile } from './RaumZeile'
import { freiePlaetze, zellRaeume } from './wochenplan.model'

/**
 * Eine Zelle des Wochenplans (Entscheidung 3): je Raum mit Coach oder Kindern eine Zeile, unten „x frei“ bzw.
 * „läuft gerade“. Vergangene Zellen gedämpft. Die ganze Zelle ist der Knopf ins Slot-Panel.
 */
export function WochenZelle({ zelle, onOeffnen }: { zelle: WocheZelle; onOeffnen: () => void }): JSX.Element {
  const { t } = useTranslation('slots')
  const raeume = zellRaeume(zelle)
  const frei = freiePlaetze(raeume)
  const zustand = zelle.laeuft
    ? 'border-[var(--color-primary)] ring-1 ring-[var(--color-primary)]'
    : zelle.vergangen
      ? 'opacity-60'
      : ''
  const basis = `flex h-full min-h-[84px] w-full min-w-0 flex-col gap-1 rounded-[var(--radius-md)] border p-2 text-left transition-shadow duration-150 ease-out hover:border-[var(--color-primary)] hover:shadow-md ${zustand}`

  // Kinder ohne Raum (Altbestand, Zusatz ohne Raum, Coach fällt aus) dürfen nicht hinter „kein Raum besetzt“ verschwinden.
  if (raeume.length === 0 && zelle.ohne_raum === 0) {
    return (
      <button
        type="button"
        onClick={onOeffnen}
        className={`${basis} items-center justify-center border-dashed border-[var(--color-border)] bg-[var(--color-bg-app)] text-xs text-[var(--color-text-tertiary)]`}
      >
        {t('woche.keinRaum')}
      </button>
    )
  }

  const kinder = raeume.reduce((s, r) => s + r.belegt, 0) + zelle.ohne_raum
  return (
    <button
      type="button"
      onClick={onOeffnen}
      aria-label={[
        t('wochenplan2.zelle.label', { count: kinder, frei }),
        zelle.laeuft ? t('wochenplan2.zelle.laeuft') : null,
        (zelle.test ?? 0) > 0 ? t('test.kennzeichen') : null,
        zelle.ohne_raum > 0 ? t('woche.ohneRaum', { count: zelle.ohne_raum }) : null,
      ].filter(Boolean).join(', ')}
      className={`${basis} border-[var(--color-border)] bg-[var(--color-bg-surface)]`}
    >
      {raeume.map((r) => (
        <RaumZeile key={r.raum_id} name={r.name} belegt={r.belegt} mitCoach={r.offen} className="w-full" />
      ))}
      <span className="mt-auto flex flex-wrap items-center gap-1 text-xs text-[var(--color-text-tertiary)]">
        {zelle.laeuft && <span className="font-semibold text-[var(--color-primary)]">{t('wochenplan2.zelle.laeuft')} ·</span>}
        {raeume.length > 0 && <span>{t('wochenplan2.zelle.frei', { count: frei })}</span>}
        {zelle.ohne_raum > 0 && (
          <span className="font-semibold text-[var(--color-error-coach)]">
            {raeume.length > 0 ? '· ' : ''}
            {t('woche.ohneRaum', { count: zelle.ohne_raum })}
          </span>
        )}
        {(zelle.test ?? 0) > 0 && <TestKennzeichen />}
      </span>
    </button>
  )
}
