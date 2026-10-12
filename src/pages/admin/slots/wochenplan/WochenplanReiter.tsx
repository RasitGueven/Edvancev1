import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, WochenNavigation } from '@/components/edvance'
import { KennzahlenLeiste, type Kennzahl } from '@/components/edvance/admin/KennzahlenLeiste'
import type { SlotsWoche } from '@/types/slotplan'
import type { Geladen } from '../useSlotsLaden'
import { datumKurz, prozent } from '../slotsFormat'
import { TagesAnsicht, WochenRaster } from './WochenRaster'

/** Wochenraster als Skelett, solange die Woche lädt. */
function RasterSkelett(): JSX.Element {
  return (
    <div className="grid grid-cols-[3.5rem_repeat(5,minmax(0,1fr))] gap-1" aria-hidden="true">
      {Array.from({ length: 6 * 7 }, (_, i) => (
        <div key={i} className={`h-14 rounded-[var(--radius-md)] ${i % 6 === 0 ? '' : 'bg-[var(--color-border)] animate-skeleton'}`} />
      ))}
    </div>
  )
}

function Legende(): JSX.Element {
  const { t } = useTranslation('slots')
  const punkt = 'inline-block h-4 w-4 rounded-sm'
  return (
    <ul className="flex flex-wrap items-center gap-4 text-xs text-[var(--color-text-tertiary)]">
      <li className="flex items-center gap-2">
        <span aria-hidden="true" className={`${punkt} bg-[var(--color-gold-warning-light)] shadow-[inset_3px_0_0_var(--color-gold-warning)]`} />
        {t('woche.legende.achtung')}
      </li>
      <li className="flex items-center gap-2">
        <span aria-hidden="true" className={`${punkt} bg-[var(--color-error-coach-light)] shadow-[inset_3px_0_0_var(--color-error-coach)]`} />
        {t('woche.legende.handeln')}
      </li>
      <li className="flex items-center gap-2">
        <span aria-hidden="true">–</span>
        {t('woche.keinRaum')}
      </li>
      <li>{t('woche.legende.faecher')}</li>
    </ul>
  )
}

export function WochenplanReiter({
  woche,
  montag,
  onWoche,
}: {
  woche: Geladen<SlotsWoche>
  montag: string
  onWoche: (montag: string) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [leereZeigen, setLeereZeigen] = useState(false)
  const w = woche.daten && woche.daten.montag === montag ? woche.daten : null
  const kopf = w?.kopf

  const zahlen: Kennzahl[] = kopf
    ? [
        { key: 'plaetze', label: t('woche.kpi.plaetze'), wert: String(kopf.plaetze), unterzeile: t('woche.kpi.plaetzeSub') },
        { key: 'belegt', label: t('woche.kpi.belegt'), wert: String(kopf.belegt), unterzeile: t('woche.kpi.belegtSub') },
        {
          key: 'auslastung',
          label: t('woche.kpi.auslastung'),
          wert: kopf.auslastung === null ? '–' : prozent(kopf.auslastung, i18n.language),
          unterzeile: t('woche.kpi.auslastungSub'),
        },
        {
          key: 'ohneRaum',
          label: t('woche.kpi.ohneRaum'),
          wert: String(kopf.ohne_raum),
          ton: kopf.ohne_raum > 0 ? 'handeln' : 'neutral',
          unterzeile: kopf.erster_ohne_raum
            ? t('woche.kpi.ohneRaumErster', { datum: datumKurz(kopf.erster_ohne_raum.datum, i18n.language) })
            : t('woche.kpi.ohneRaumKeiner'),
          ziel: kopf.erster_ohne_raum
            ? `/admin/slots/termin/${kopf.erster_ohne_raum.datum}/${kopf.erster_ohne_raum.zeit_id}`
            : undefined,
        },
        {
          key: 'ohneStammplatz',
          label: t('woche.kpi.ohneStammplatz'),
          wert: String(kopf.ohne_stammplatz),
          ton: kopf.ohne_stammplatz_laufend > 0 ? 'handeln' : 'neutral',
          unterzeile: t('woche.kpi.ohneStammplatzSub', { count: kopf.ohne_stammplatz_laufend }),
          ziel: kopf.ohne_stammplatz > 0 ? '/admin/slots?reiter=kinder&filter=kein_stammplatz' : undefined,
        },
      ]
    : []

  return (
    <div className="flex flex-col gap-4">
      {w ? <KennzahlenLeiste zahlen={zahlen} label={t('woche.kpi.label')} breite="slots-kpi" /> : <LoadingPulse type="stat" />}

      <EdvanceCard className="@container flex flex-col gap-4 p-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{t('woche.titel')}</h2>
          <WochenNavigation montag={montag} onWechsel={onWoche} />
        </div>

        {woche.fehler && !w ? (
          <p className="text-sm text-[var(--color-text-secondary)]">{t(woche.fehler)}</p>
        ) : !w ? (
          <RasterSkelett />
        ) : w.zeiten.length === 0 ? (
          <EmptyState icon="🕓" title={t('woche.leerTitel')} description={t('woche.leerText')} />
        ) : (
          <>
            <div className="hidden @slots-woche:block">
              <WochenRaster woche={w} leereZeigen={leereZeigen} />
            </div>
            <div className="@slots-woche:hidden">
              <TagesAnsicht key={w.montag} woche={w} leereZeigen={leereZeigen} />
            </div>
          </>
        )}

        <footer className="flex flex-wrap items-center justify-between gap-2 border-t border-[var(--color-border)] pt-2">
          <Legende />
          <label className="flex min-h-[44px] items-center gap-2 text-xs text-[var(--color-text-secondary)]">
            <input type="checkbox" checked={leereZeigen} onChange={(e) => setLeereZeigen(e.target.checked)} className="h-4 w-4" />
            {t('woche.leereZeigen')}
          </label>
        </footer>
      </EdvanceCard>
    </div>
  )
}
