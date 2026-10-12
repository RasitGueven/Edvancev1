import { Fragment, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { SlotsWoche, SlotZeit, WocheTag } from '@/types/slotplan'
import { datumKurz, wochentagKurz } from '../slotsFormat'
import { leereZeiten, zelleVon } from '../slots.model'
import { WochenZelle } from './WochenZelle'

const terminZiel = (datum: string, zeitId: string): string => `/admin/slots/termin/${datum}/${zeitId}`

/** Schmale Zeile für eine Uhrzeit ohne geöffneten Raum in der ganzen Woche. */
function LeereZeile({ zeit }: { zeit: SlotZeit }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <div className="col-span-full flex min-h-[32px] items-center gap-2 border-t border-[var(--color-border)] px-2 text-xs text-[var(--color-text-tertiary)]">
      <span className="tabular-nums">{zeit.beginn}</span>
      <span aria-hidden="true">·</span>
      <span>{t('woche.keinRaum')}</span>
    </div>
  )
}

function Tageskopf({ tag }: { tag: WocheTag }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <div
      className={`sticky top-0 z-10 flex min-h-[44px] flex-col justify-center rounded-t-[var(--radius-md)] px-2 py-2 ${
        tag.heute
          ? 'bg-[var(--color-primary-light)] text-[var(--color-primary)]'
          : tag.betrieb
            ? 'bg-[var(--color-bg-surface)] text-[var(--color-text-primary)]'
            : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)]'
      }`}
    >
      <span className="text-sm font-semibold tabular-nums">{datumKurz(tag.datum, i18n.language)}</span>
      <span className="truncate text-xs">{tag.heute ? t('woche.heute') : tag.betrieb ? '' : tag.anlass ?? t('woche.keinBetrieb')}</span>
    </div>
  )
}

/** Raster Mo–Fr × Uhrzeiten (ab --container-slots-woche). Die Kopfzeile bleibt beim Scrollen stehen. */
export function WochenRaster({ woche, leereZeigen }: { woche: SlotsWoche; leereZeigen: boolean }): JSX.Element {
  const leer = leereZeiten(woche)
  return (
    <div role="grid" aria-rowcount={woche.zeiten.length + 1} className="grid grid-cols-[3.5rem_repeat(5,minmax(0,1fr))] gap-1">
      <div role="row" className="contents">
        <span aria-hidden="true" className="sticky top-0 z-10 bg-[var(--color-bg-surface)]" />
        {woche.tage.map((tag) => (
          <div key={tag.datum} role="columnheader">
            <Tageskopf tag={tag} />
          </div>
        ))}
      </div>
      {woche.zeiten.map((zeit) =>
        leer.has(zeit.id) && !leereZeigen ? (
          <LeereZeile key={zeit.id} zeit={zeit} />
        ) : (
          <div key={zeit.id} role="row" className="contents">
            <span role="rowheader" className="flex min-h-[44px] items-start px-1 pt-2 text-xs font-semibold tabular-nums text-[var(--color-text-secondary)]">
              {zeit.beginn}
            </span>
            {woche.tage.map((tag) => {
              const zelle = tag.betrieb ? zelleVon(woche, tag.datum, zeit.id) : undefined
              return (
                <div key={tag.datum} role="gridcell" className={tag.betrieb ? '' : 'rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)]'}>
                  {zelle && <WochenZelle zelle={zelle} ziel={terminZiel(tag.datum, zeit.id)} />}
                </div>
              )
            })}
          </div>
        ),
      )}
    </div>
  )
}

/** Unter --container-slots-woche: ein Tag, Umschalter Mo–Fr, Uhrzeiten als Zeilen. */
export function TagesAnsicht({ woche, leereZeigen }: { woche: SlotsWoche; leereZeigen: boolean }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const start = woche.tage.find((d) => d.heute) ?? woche.tage.find((d) => d.betrieb) ?? woche.tage[0]
  const [gewaehlt, setGewaehlt] = useState(start.datum)
  const tag = woche.tage.find((d) => d.datum === gewaehlt) ?? start
  const leer = leereZeiten(woche)

  return (
    <div className="flex flex-col gap-2">
      <div role="group" aria-label={t('woche.tagWaehlen')} className="grid grid-cols-5 gap-1">
        {woche.tage.map((d) => (
          <button
            key={d.datum}
            type="button"
            aria-pressed={d.datum === tag.datum}
            onClick={() => setGewaehlt(d.datum)}
            className={`min-h-[44px] rounded-[var(--radius-md)] text-sm font-semibold transition-colors duration-150 ease-out ${
              d.datum === tag.datum
                ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                : d.betrieb
                  ? 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]'
                  : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)] line-through'
            }`}
          >
            {wochentagKurz(d.datum, i18n.language)}
          </button>
        ))}
      </div>
      <Tageskopf tag={tag} />
      {!tag.betrieb ? (
        <p className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] px-4 py-6 text-center text-sm text-[var(--color-text-tertiary)]">
          {t('woche.keinBetriebTag', { anlass: tag.anlass ?? t('woche.keinBetrieb') })}
        </p>
      ) : (
        <div className="grid grid-cols-[3.5rem_minmax(0,1fr)] gap-1">
          {woche.zeiten.map((zeit) => {
            const zelle = zelleVon(woche, tag.datum, zeit.id)
            if (leer.has(zeit.id) && !leereZeigen) return <LeereZeile key={zeit.id} zeit={zeit} />
            return (
              <Fragment key={zeit.id}>
                <span className="flex min-h-[44px] items-start px-1 pt-2 text-xs font-semibold tabular-nums text-[var(--color-text-secondary)]">
                  {zeit.beginn}
                </span>
                {zelle ? <WochenZelle zelle={zelle} ziel={terminZiel(tag.datum, zeit.id)} /> : <span />}
              </Fragment>
            )
          })}
        </div>
      )}
    </div>
  )
}
