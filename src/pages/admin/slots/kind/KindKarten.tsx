import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { CardMenu, type CardMenuItem } from '@/pages/admin/leads/CardMenu'
import type { KindLetzterTermin, KindNaechsterTermin, SlotsKind, Stammplatz } from '@/types/slotplan'
import { datumKurz, datumVoll } from '../slotsFormat'
import { EinheitenBalken, PlanbilanzBadge, planbilanzSatz } from '../kinder/Einheiten'
import { paketText, rhythmusText, stammplatzText } from '../kinder/KinderSpalten'
import { ZustandBadge } from '../termin/TerminKarten'

const FELD = 'h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm tabular-nums'
const NAECHSTE = 8

/** Rechte Spalte: Einheiten mit Stapelbalken und Planbilanz (Wortlaut nach Anforderung J 57). */
export function EinheitenKarte({ kind }: { kind: SlotsKind }): JSX.Element | null {
  const { t, i18n } = useTranslation('slots')
  if (!kind.einheiten || !kind.planbilanz) return null
  const e = kind.einheiten
  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-base font-semibold">{t('kind.einheiten')}</h2>
      <EinheitenBalken verbraucht={e.verbraucht} geplant={e.geplant} gesamt={e.gesamt} />
      <dl className="grid grid-cols-3 gap-2">
        {(['verbraucht', 'geplant', 'gesamt'] as const).map((k) => (
          <div key={k} className="flex flex-col">
            <dt className="text-xs text-[var(--color-text-tertiary)]">{t(`einheiten.${k}Label`)}</dt>
            <dd className="font-serif text-2xl font-semibold tabular-nums">{e[k]}</dd>
          </div>
        ))}
      </dl>
      <span><PlanbilanzBadge planbilanz={kind.planbilanz} vertragLaeuft={!!kind.vertrag_laeuft} /></span>
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{planbilanzSatz(kind.planbilanz, t, i18n.language)}</p>
    </EdvanceCard>
  )
}

/** Rechte Spalte: Auszug aus dem Vertrag, nur Ansicht. */
export function VertragKarte({ kind }: { kind: SlotsKind }): JSX.Element | null {
  const { t, i18n } = useTranslation('slots')
  const v = kind.vertrag
  if (!v) return null
  const zeilen: [string, string][] = [
    [t('kind.vertrag.paket'), paketText(v, t)],
    [t('kind.vertrag.rhythmus'), rhythmusText(v.rhythmus, t)],
    [t('kind.vertrag.einheiten'), String(v.einheiten)],
    [t('kind.vertrag.beginn'), datumVoll(v.beginn, i18n.language)],
    [t('kind.vertrag.stichtag'), datumVoll(v.stichtag, i18n.language)],
  ]
  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-base font-semibold">{t('kind.vertrag.titel')}</h2>
      <dl className="grid grid-cols-[auto_minmax(0,1fr)] gap-x-4 gap-y-2 text-sm">
        {zeilen.map(([k, w]) => (
          <div key={k} className="contents">
            <dt className="text-[var(--color-text-tertiary)]">{k}</dt>
            <dd className="tabular-nums">{w}</dd>
          </div>
        ))}
      </dl>
      <Link to={`/admin/vertraege/${v.vertrag_id}/detail`} className="inline-flex min-h-[44px] items-center text-sm font-semibold text-[var(--color-text-link)] hover:underline">
        {t('kind.vertrag.oeffnen')}
      </Link>
    </EdvanceCard>
  )
}

/** Stammplätze: die aktuellen mit "Ändern ab …" und "Beenden" (inline mit Datum), frühere zugeklappt. */
export function StammplaetzeKarte({
  kind,
  heute,
  fehler,
  onVergeben,
  onAendern,
  onBeenden,
}: {
  kind: SlotsKind
  heute: string
  fehler: string | null
  onVergeben: () => void
  onAendern: (s: Stammplatz) => void
  onBeenden: (s: Stammplatz, ab: string) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [beenden, setBeenden] = useState<{ id: string; ab: string } | null>(null)
  const zeit = (s: Stammplatz): string =>
    s.gueltig_ab > heute ? t('kind.stamm.ab', { datum: datumKurz(s.gueltig_ab, i18n.language) }) : t('kind.stamm.seit', { datum: datumKurz(s.gueltig_ab, i18n.language) })

  return (
    <EdvanceCard className="flex flex-col gap-2 p-6">
      <h2 className="text-base font-semibold">{t('kind.stamm.titel')}</h2>
      {kind.stammplaetze.length === 0 ? (
        <EmptyState
          icon="📅"
          title={t('kind.stamm.leerTitel')}
          description={t('kind.stamm.leerText')}
          action={kind.zugelassen && kind.vertrag ? <Button type="button" onClick={onVergeben}>{t('aktion.stammplatzVergeben')}</Button> : undefined}
        />
      ) : (
        <ul className="flex flex-col">
          {kind.stammplaetze.map((s) => (
            <li key={s.id} className="flex flex-col gap-2 border-t border-[var(--color-border)] py-2">
              <div className="flex min-h-[44px] flex-wrap items-center justify-between gap-2">
                <span className="flex flex-col">
                  <span className="text-sm font-semibold tabular-nums">{stammplatzText(s, i18n.language, t)}</span>
                  <span className="text-xs text-[var(--color-text-tertiary)]">
                    {[zeit(s), s.gueltig_bis ? t('kind.stamm.bis', { datum: datumKurz(s.gueltig_bis, i18n.language) }) : null].filter(Boolean).join(' · ')}
                  </span>
                </span>
                <span className="flex items-center gap-2">
                  <Button type="button" variant="outline" size="sm" className="min-h-[44px]" onClick={() => onAendern(s)}>{t('aktion.aendernAb')}</Button>
                  <CardMenu items={[{ label: t('aktion.beenden'), onSelect: () => setBeenden({ id: s.id, ab: heute }), danger: true }]} />
                </span>
              </div>
              {beenden?.id === s.id && (
                <div className="flex flex-wrap items-end gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-2">
                  <label className="flex flex-col gap-1 text-xs text-[var(--color-text-tertiary)]">
                    {t('kind.stamm.beendenAb')}
                    <input type="date" autoFocus min={heute} value={beenden.ab} onChange={(e) => setBeenden({ id: s.id, ab: e.target.value })} className={FELD} />
                  </label>
                  <Button type="button" variant="destructive" onClick={() => { onBeenden(s, beenden.ab); setBeenden(null) }}>{t('aktion.beenden')}</Button>
                  <Button type="button" variant="ghost" onClick={() => setBeenden(null)}>{t('dialog.abbrechen')}</Button>
                  <p className="w-full text-xs text-[var(--color-text-secondary)]">{t('kind.stamm.beendenSatz')}</p>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
      {fehler && <p role="alert" className="text-xs text-[var(--color-error-coach)]">{t(fehler)}</p>}
      {kind.fruehere_stammplaetze.length > 0 && (
        <details className="border-t border-[var(--color-border)] pt-2">
          <summary className="flex min-h-[44px] cursor-pointer items-center text-sm font-semibold text-[var(--color-text-secondary)]">
            {t('kind.stamm.frueher', { count: kind.fruehere_stammplaetze.length })}
          </summary>
          <ul className="flex flex-col">
            {kind.fruehere_stammplaetze.map((s) => (
              <li key={s.id} className="flex min-h-[44px] items-center justify-between gap-2 text-sm text-[var(--color-text-tertiary)]">
                <span className="tabular-nums">{stammplatzText(s, i18n.language, t)}</span>
                <span className="text-xs tabular-nums">
                  {t('kind.stamm.zeitraum', { von: datumKurz(s.gueltig_ab, i18n.language), bis: s.gueltig_bis ? datumKurz(s.gueltig_bis, i18n.language) : '' })}
                </span>
              </li>
            ))}
          </ul>
        </details>
      )}
    </EdvanceCard>
  )
}

/** Nächste Termine: zuerst acht, dann "alle zeigen"; je Zeile das "…"-Menü (Absage, Umbuchen). */
export function NaechsteKarte({
  termine,
  fehlerBei,
  onAktion,
}: {
  termine: KindNaechsterTermin[]
  fehlerBei: { ort: string; text: string } | null
  onAktion: (termin: KindNaechsterTermin, aktion: 'absage' | 'umbuchen' | 'zuruecknehmen') => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [alle, setAlle] = useState(false)
  const sichtbar = alle ? termine : termine.slice(0, NAECHSTE)
  const menu = (x: KindNaechsterTermin): CardMenuItem[] =>
    x.zustand === 'planned'
      ? [{ label: t('aktion.absage'), onSelect: () => onAktion(x, 'absage') }, { label: t('aktion.umbuchen'), onSelect: () => onAktion(x, 'umbuchen') }]
      : x.absage_eingang
        ? [{ label: t('aktion.zuruecknehmen'), onSelect: () => onAktion(x, 'zuruecknehmen') }]
        : []
  return (
    <EdvanceCard className="flex flex-col gap-2 p-6">
      <h2 className="text-base font-semibold">{t('kind.naechste')}</h2>
      {termine.length === 0 ? (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('kind.keineNaechsten')}</p>
      ) : (
        <ul className="flex flex-col">
          {sichtbar.map((x) => (
            <li key={x.termin_id} className="flex flex-col border-t border-[var(--color-border)]">
              <div className="flex min-h-[44px] items-center justify-between gap-2">
                <span className="flex flex-wrap items-center gap-2">
                  <span className="w-28 text-sm font-semibold tabular-nums">{`${datumKurz(x.datum, i18n.language)} ${x.beginn}`}</span>
                  {x.zustand !== 'planned' && <ZustandBadge zustand={x.zustand} />}
                  {x.umgebucht_von && <EdvanceBadge variant="primary">{t('termin.umgebuchtVon', { datum: datumKurz(x.umgebucht_von, i18n.language) })}</EdvanceBadge>}
                  {!x.umgebucht_von && x.herkunft === 'zusatz' && <EdvanceBadge variant="primary">{t('termin.zusatz')}</EdvanceBadge>}
                  {x.festgeschrieben && <EdvanceBadge variant="primary">{t('kind.festgeschrieben')}</EdvanceBadge>}
                </span>
                <CardMenu items={menu(x)} />
              </div>
              {fehlerBei?.ort === x.termin_id && <p role="alert" className="pb-1 text-xs text-[var(--color-error-coach)]">{t(fehlerBei.text)}</p>}
            </li>
          ))}
        </ul>
      )}
      {termine.length > NAECHSTE && (
        <Button type="button" variant="ghost" className="self-start" onClick={() => setAlle((a) => !a)}>
          {alle ? t('kind.weniger') : t('kind.alleZeigen', { count: termine.length })}
        </Button>
      )}
    </EdvanceCard>
  )
}

/** Letzte Termine mit der Anwesenheit aus der Session. */
export function LetzteKarte({ termine }: { termine: KindLetzterTermin[] }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <EdvanceCard className="flex flex-col gap-2 p-6">
      <h2 className="text-base font-semibold">{t('kind.letzte')}</h2>
      {termine.length === 0 ? (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('kind.keineLetzten')}</p>
      ) : (
        <ul className="flex flex-col">
          {termine.slice(0, NAECHSTE).map((x, i) => (
            <li key={x.termin_id ?? `${x.datum}-${i}`} className="flex min-h-[44px] items-center gap-2 border-t border-[var(--color-border)]">
              <span className="w-28 text-sm tabular-nums">{`${datumKurz(x.datum, i18n.language)} ${x.beginn}`}</span>
              <ZustandBadge zustand={x.zustand} />
              {x.herkunft === 'einzel' && <span className="text-xs text-[var(--color-text-tertiary)]">{t('kind.einzelSession')}</span>}
            </li>
          ))}
        </ul>
      )}
      <p className="text-xs text-[var(--color-text-tertiary)]">{t('termin.anwesenheitAusSession')}</p>
    </EdvanceCard>
  )
}
