import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import type { Spalte } from '@/components/edvance/EdvanceTable'
import { Button } from '@/components/ui/button'
import { CardMenu } from '@/pages/admin/leads/CardMenu'
import type { Vertragsart } from '@/types'
import type { Rhythmus, SlotsKinderZeile, Stammplatz } from '@/types/slotplan'
import { PilotKennzeichen } from '../../vertraege/PilotKennzeichen'
import { datumTagMonat, wochentagName } from '../slotsFormat'
import { PlanbilanzBadge } from './Einheiten'
import { KlasseFach } from '../KlasseFach'
import { ohneRaum, stammplatzKurz } from './kinder.model'

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

/** Was die Aktion-Spalte auslöst (Bauauftrag W3, Entscheidung 1). */
export type KindAktion =
  | { art: 'vergeben'; kind: SlotsKinderZeile }
  | { art: 'weiterfuehren'; kind: SlotsKinderZeile }
  | { art: 'aendern'; kind: SlotsKinderZeile; stammplatz: Stammplatz }

function Kind({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <span className="flex min-w-0 flex-col">
      <Link to={`/admin/slots/kind/${k.student_id}`} className="inline-flex min-h-[44px] items-center truncate text-sm font-semibold text-[var(--color-text-primary)] hover:text-[var(--color-primary)] hover:underline">
        {k.name ?? t('kind.ohneName')}
      </Link>
      <KlasseFach klasse={k.klasse} fach={k.fach} test={k.ist_test} />
    </span>
  )
}

function Paket({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <span className="flex flex-col">
      {k.vertragsart === 'pilot' ? <PilotKennzeichen art="pilot" /> : <span className="text-sm">{paketText(k, t)}</span>}
      <span className="text-xs text-[var(--color-text-tertiary)]">
        {k.vertrag_laeuft ? rhythmusText(k.rhythmus, t) : t('kinder2.paket.ab', { rhythmus: rhythmusText(k.rhythmus, t), datum: datumTagMonat(k.beginn, i18n.language) })}
      </span>
    </span>
  )
}

/** „Mo 14:00 · A1“, „(A-Woche)“; Altbestand „Raum: automatisch“. */
function Stammplaetze({ k }: { k: SlotsKinderZeile }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  if (k.stammplaetze.length === 0) return <span className="text-sm text-[var(--color-text-tertiary)]">{t('kinder2.stamm.ohne')}</span>
  return (
    <span className="flex flex-col gap-1 text-sm tabular-nums">
      {k.stammplaetze.map((s) => <span key={s.id}>{stammplatzKurz(s, i18n.language, t)}</span>)}
    </span>
  )
}

/** Coach aus der Schicht des Raums; ohne Schicht „keine Schicht“, ohne Raum (Altbestand) kein Coach. */
export function CoachZelle({ s }: { s: Stammplatz }): JSX.Element {
  const { t } = useTranslation('slots')
  if (ohneRaum(s)) return <span className="text-sm text-[var(--color-text-tertiary)]">–</span>
  if (s.coach_name) return <span className="text-sm">{s.coach_name}</span>
  return <span><EdvanceBadge variant="coach-emergency">{t('kinder2.coach.keineSchicht')}</EdvanceBadge></span>
}

function Coaches({ k }: { k: SlotsKinderZeile }): JSX.Element {
  if (k.stammplaetze.length === 0) return <span className="text-sm text-[var(--color-text-tertiary)]">–</span>
  return (
    <span className="flex flex-col gap-1">
      {k.stammplaetze.map((s) => <CoachZelle key={s.id} s={s} />)}
    </span>
  )
}

/** Ein Knopf je Zeile: vergeben, wie bisher weiterführen, Raum festlegen (Altbestand) oder ändern. */
function Aktion({ k, onAktion }: { k: SlotsKinderZeile; onAktion: (a: KindAktion) => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const knopf = (text: string, a: KindAktion, primaer = false): JSX.Element => (
    <Button type="button" size="sm" variant={primaer ? 'default' : 'outline'} className="min-h-[44px]" onClick={() => onAktion(a)}>{text}</Button>
  )
  const vorschlag = k.ohne_stammplatz && k.weiterfuehren && k.weiterfuehren.zeilen.length > 0 ? k.weiterfuehren : null
  let inhalt: JSX.Element
  if (vorschlag) {
    const slot = vorschlag.zeilen.map((z) => `${wochentagName(z.wochentag, i18n.language)} ${z.beginn}`).join(', ')
    inhalt = (
      <>
        {knopf(t('kinder.ohne.weiterfuehren', { slot }), { art: 'weiterfuehren', kind: k })}
        <CardMenu items={[{ label: t('aktion.stammplatzVergeben'), onSelect: () => onAktion({ art: 'vergeben', kind: k }) }]} />
      </>
    )
  } else if (k.stammplaetze.length === 0) {
    inhalt = knopf(t('aktion.stammplatzVergeben'), { art: 'vergeben', kind: k }, true)
  } else {
    const alt = k.stammplaetze.find(ohneRaum)
    inhalt = alt
      ? knopf(t('kinder2.aktion.raumFestlegen'), { art: 'aendern', kind: k, stammplatz: alt })
      : k.stammplaetze.length === 1
        ? knopf(t('kinder2.aktion.aendern'), { art: 'aendern', kind: k, stammplatz: k.stammplaetze[0] })
        : (
          <CardMenu
            items={k.stammplaetze.map((s) => ({
              label: t('kinder2.aktion.aendernVon', { stammplatz: stammplatzKurz(s, i18n.language, t) }),
              onSelect: () => onAktion({ art: 'aendern', kind: k, stammplatz: s }),
            }))}
          />
        )
  }
  return <span className="flex items-center justify-end gap-2">{inhalt}</span>
}

export function useKinderSpalten(onAktion: (a: KindAktion) => void): Spalte<SlotsKinderZeile>[] {
  const { t } = useTranslation('slots')
  return [
    { key: 'kind', kopf: t('kinder.spalte.kind'), zelle: (k) => <Kind k={k} /> },
    { key: 'paket', kopf: t('kinder.spalte.paket'), zelle: (k) => <Paket k={k} /> },
    { key: 'stamm', kopf: t('kinder2.spalte.stammplatz'), zelle: (k) => <Stammplaetze k={k} /> },
    { key: 'coach', kopf: t('kinder2.spalte.coach'), zelle: (k) => <Coaches k={k} /> },
    { key: 'planbilanz', kopf: t('kinder.spalte.planbilanz'), zelle: (k) => <PlanbilanzBadge planbilanz={k.planbilanz} vertragLaeuft={k.vertrag_laeuft} /> },
    { key: 'aktion', kopf: t('kinder2.spalte.aktion'), rechts: true, zelle: (k) => <Aktion k={k} onAktion={onAktion} /> },
  ]
}

/** Dieselben Felder als Karte (unter --container-slots-tabelle). */
export function KindZellen({ kind: k, onAktion }: { kind: SlotsKinderZeile; onAktion: (a: KindAktion) => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <>
      <span className="flex items-start justify-between gap-2">
        <Kind k={k} />
        <PlanbilanzBadge planbilanz={k.planbilanz} vertragLaeuft={k.vertrag_laeuft} />
      </span>
      <Paket k={k} />
      {k.stammplaetze.map((s) => (
        <span key={s.id} className="flex flex-wrap items-center justify-between gap-2 text-sm tabular-nums">
          <span>{stammplatzKurz(s, i18n.language, t)}</span>
          <CoachZelle s={s} />
        </span>
      ))}
      {k.stammplaetze.length === 0 && <span className="text-sm text-[var(--color-text-tertiary)]">{t('kinder2.stamm.ohne')}</span>}
      <Aktion k={k} onAktion={onAktion} />
    </>
  )
}
