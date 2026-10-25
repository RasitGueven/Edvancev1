import { useLayoutEffect, useRef, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import type { ReportData, ReportNotes, TierPlan } from '@/types'

import { Seitenleiste } from './Seitenleiste'

/**
 * Der Eltern-Bericht R7 am Bildschirm (Bauauftrag R7-7, Entscheidungen 2 und 3).
 *
 * Der Bogen selbst bleibt in pt und weiß nichts vom Bildschirm. Ist die Spalte
 * schmaler als eine Seite, verkleinert ihn diese Hülle von außen:
 * s = min(1, Spaltenbreite / Seitenbreite), per transform um die obere Mitte.
 * Weil transform das Layout nicht ändert, bekommt die Hülle die Höhe Bogen × s,
 * sonst bliebe unten der Platz der unskalierten Blätter leer. Der innere
 * Kasten steht oben (self-start), damit die gesetzte Höhe ihn nicht staucht —
 * sonst schrumpfte jede Messung die Höhe um einen weiteren Faktor s. Skala und Höhe
 * sind berechnete Werte und gehen über style.setProperty (CLAUDE.md §11).
 *
 * Bericht v4: Mit `onPreise` steht über dem Bogen ein Schalter „Preise
 * einblenden“ (nur am Bildschirm). Der eingestellte Zustand gilt auch im Druck;
 * er lebt als ?preise=an in der URL (ReportPage).
 *
 * Im Druck gilt die Skala nicht: kein transform, die feste Höhe hebt
 * rahmen.css (`:has(.eb-bogen)`) auf; Leiste, Ausblick und Fläche sind
 * print-hide bzw. transparent.
 */
export function BerichtAnsicht({
  data,
  notes,
  tiers,
  bogenKey,
  ausblick,
  preise = false,
  onPreise,
}: {
  data: ReportData
  /** Die Notizen, die der Bogen zeigt (entprellt, siehe ReportPage). */
  notes: ReportNotes
  tiers: TierPlan[]
  /** Neuer Wert = Bogen neu einhängen und neu messen (Entscheidung 5). */
  bogenKey: string
  /** Der Ausblick (ReportOutlook) für die rechte Spalte. */
  ausblick: ReactNode
  /** Preise je Paket auf Seite 5 zeigen (?preise=an). */
  preise?: boolean
  /** Ohne diesen Handler gibt es den Schalter nicht. */
  onPreise?: (an: boolean) => void
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const huelle = useRef<HTMLDivElement>(null)
  const innen = useRef<HTMLDivElement>(null)

  useLayoutEffect(() => {
    const aussen = huelle.current
    const bogen = innen.current
    if (!aussen || !bogen || typeof ResizeObserver === 'undefined') return
    const einpassen = (): void => {
      // Layoutwerte, nicht getBoundingClientRect: die sind schon skaliert.
      const seite = bogen.querySelector<HTMLElement>('.eb-seite')?.offsetWidth ?? 0
      const breite = aussen.clientWidth
      const s = seite > 0 && breite > 0 ? Math.min(1, breite / seite) : 1
      aussen.style.setProperty('--eb-skala', String(s))
      aussen.style.setProperty('height', `${bogen.offsetHeight * s}px`)
    }
    einpassen()
    const beobachter = new ResizeObserver(einpassen)
    beobachter.observe(aussen)
    beobachter.observe(bogen)
    return () => beobachter.disconnect()
  }, [])

  return (
    <div className="grid grid-cols-1 gap-6 @6xl:grid-cols-[minmax(0,1fr)_360px]">
      <div className="min-w-0 overflow-clip rounded-[var(--radius-lg)] bg-[var(--color-bg-subtle)] px-4 pb-4 print:bg-transparent">
        <Seitenleiste bogen={innen} bogenKey={bogenKey} />
        {onPreise && (
          <div className="print-hide mb-4 flex justify-end">
            <button
              type="button"
              aria-pressed={preise}
              onClick={() => onPreise(!preise)}
              data-testid="eb-preise-schalter"
              className={`min-h-[44px] rounded-[var(--radius-md)] px-4 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                preise
                  ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                  : 'bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]'
              }`}
            >
              {t(preise ? 'v4.s5.preise.ausblenden' : 'v4.s5.preise.einblenden')}
            </button>
          </div>
        )}
        <div
          ref={huelle}
          className="flex justify-center [&_.eb-seite]:scroll-mt-20"
          data-testid="eb-huelle"
        >
          <div
            ref={innen}
            className="origin-top self-start [transform:scale(var(--eb-skala,1))] print:[transform:none]"
            data-testid="eb-skaliert"
          >
            <ElternberichtBogen key={bogenKey} data={data} notes={notes} tiers={tiers} preise={preise} />
          </div>
        </div>
      </div>
      <aside className="print-hide min-w-0 @6xl:sticky @6xl:top-6 @6xl:max-h-[calc(100dvh-3rem)] @6xl:self-start @6xl:overflow-y-auto">
        {ausblick}
      </aside>
    </div>
  )
}
