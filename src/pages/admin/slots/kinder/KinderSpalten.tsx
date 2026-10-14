import { useTranslation } from 'react-i18next'
import type { Spalte } from '@/components/edvance/EdvanceTable'
import type { Vertragsart } from '@/types'
import type { Rhythmus, SlotsKinderZeile, Stammplatz } from '@/types/slotplan'
import { PilotKennzeichen } from '../../vertraege/PilotKennzeichen'
import { datumVoll, wochentagName } from '../slotsFormat'
import { EinheitenBalken, PlanbilanzBadge } from './Einheiten'
import { KlasseFach } from '../KlasseFach'

type T = (k: string, o?: Record<string, unknown>) => string

/** "1× pro Woche + 14-täglich" */
export function rhythmusText(r: Rhythmus | null, t: T): string {
  if (!r) return '–'
  return [
    r.woechentlich > 0 ? t('rhythmus.woechentlich', { count: r.woechentlich }) : null,
    r.vierzehntaeglich > 0 ? t('rhythmus.vierzehntaeglich', { count: r.vierzehntaeglich }) : null,
  ]
    .filter(Boolean)
    .join(' + ')
}

/** "Basic · Halbjahr"; V5: eine Pilotvereinbarung heisst "Pilot" (ohne Paket und Laufzeit). */
export function paketText(
  k: { paket: string | null; laufzeit_monate: number | null; vertragsart?: Vertragsart },
  t: T,
): string {
  if (k.vertragsart === 'pilot') return t('vertragsart.pilot')
  return [k.paket ?? '–', k.laufzeit_monate ? t(`laufzeit.${k.laufzeit_monate}`) : null].filter(Boolean).join(' · ')
}

/** "Di 16:00", "Do 17:00 · A" */
export function stammplatzText(s: Pick<Stammplatz, 'wochentag' | 'beginn' | 'takt'>, sprache: string, t: T): string {
  return [`${wochentagName(s.wochentag, sprache)} ${s.beginn}`, s.takt === 'woechentlich' ? null : t(`taktKurz.${s.takt}`)]
    .filter(Boolean)
    .join(' · ')
}

function Kind({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <span className="flex min-w-0 flex-col">
      <span className="truncate text-sm font-semibold text-[var(--color-text-primary)]">{k.name ?? t('kind.ohneName')}</span>
      <KlasseFach klasse={k.klasse} fach={k.fach} test={k.ist_test} />
    </span>
  )
}

function Paket({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <span className="flex flex-col">
      {k.vertragsart === 'pilot' ? <PilotKennzeichen art="pilot" /> : <span className="text-sm">{paketText(k, t)}</span>}
      <span className="text-xs text-[var(--color-text-tertiary)]">{rhythmusText(k.rhythmus, t)}</span>
    </span>
  )
}

function Stammplaetze({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  if (k.stammplaetze.length === 0) return <span className="text-sm text-[var(--color-text-tertiary)]">–</span>
  return (
    <span className="flex flex-col text-sm tabular-nums">
      {k.stammplaetze.map((s) => <span key={s.id}>{stammplatzText(s, i18n.language, t)}</span>)}
    </span>
  )
}

function Einheiten({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <span className="flex min-w-[8rem] flex-col gap-1">
      <span className="flex items-center gap-2">
        <EinheitenBalken verbraucht={k.verbraucht} geplant={k.geplant} gesamt={k.einheiten} />
        <span className="shrink-0 text-sm tabular-nums">{t('einheiten.vonGesamt', { verbraucht: k.verbraucht, gesamt: k.einheiten })}</span>
      </span>
      <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{t('einheiten.geplant', { count: k.geplant })}</span>
    </span>
  )
}

export function useKinderSpalten(): Spalte<SlotsKinderZeile>[] {
  const { t, i18n } = useTranslation('slots')
  return [
    { key: 'kind', kopf: t('kinder.spalte.kind'), zelle: (k) => <Kind k={k} /> },
    { key: 'paket', kopf: t('kinder.spalte.paket'), zelle: (k) => <Paket k={k} /> },
    { key: 'stamm', kopf: t('kinder.spalte.stammplaetze'), zelle: (k) => <Stammplaetze k={k} /> },
    { key: 'einheiten', kopf: t('kinder.spalte.einheiten'), zelle: (k) => <Einheiten k={k} /> },
    { key: 'stichtag', kopf: t('kinder.spalte.stichtag'), zelle: (k) => <span className="text-sm tabular-nums">{datumVoll(k.stichtag, i18n.language)}</span> },
    { key: 'planbilanz', kopf: t('kinder.spalte.planbilanz'), zelle: (k) => <PlanbilanzBadge planbilanz={k.planbilanz} vertragLaeuft={k.vertrag_laeuft} /> },
  ]
}

/** Dieselben Felder als Karte (unter --container-slots-tabelle). */
export function KindZellen({ kind: k }: { kind: SlotsKinderZeile }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <>
      <span className="flex items-start justify-between gap-2">
        <Kind k={k} />
        <PlanbilanzBadge planbilanz={k.planbilanz} vertragLaeuft={k.vertrag_laeuft} />
      </span>
      <span className="grid grid-cols-2 gap-2">
        <Paket k={k} />
        {k.stammplaetze.length > 0 && <Stammplaetze k={k} />}
      </span>
      <Einheiten k={k} />
      <span className="text-xs text-[var(--color-text-tertiary)]">{t('kinder.stichtag', { datum: datumVoll(k.stichtag, i18n.language) })}</span>
    </>
  )
}
