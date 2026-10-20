import { Fragment } from 'react'
import { useTranslation } from 'react-i18next'
import type { SlotsWoche, WocheTag } from '@/types/slotplan'
import type { StundenplanSession } from '@/types/stundenplan'
import { datumTagMonat, uhrzeit, wochentagName } from '../slotsFormat'
import { zelleVon } from '../slots.model'
import { einzelAmTag, type Panel } from './wochenplan.model'
import { WochenZelle } from './WochenZelle'

type Props = {
  woche: SlotsWoche
  /** Einzel- und Sofort-Sessions der Woche (stundenplan_woche); null = lädt noch oder Fehler. */
  einzel: StundenplanSession[] | null
  onPanel: (panel: Panel) => void
}

/** Tageskopf als Knopf ins Tagespanel (Entscheidung 5); Tage ohne Betrieb sind kein Knopf. */
function Tageskopf({ tag, onOeffnen }: { tag: WocheTag; onOeffnen: () => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const inhalt = (
    <>
      <span className={`text-sm font-semibold ${tag.heute ? 'text-[var(--color-primary)]' : 'text-[var(--color-text-primary)]'}`}>
        {wochentagName(tag.wochentag, i18n.language, true)}
      </span>
      <span className={`text-xs tabular-nums ${tag.heute ? 'font-semibold text-[var(--color-primary)]' : 'text-[var(--color-text-tertiary)]'}`}>
        {tag.heute ? t('wochenplan2.tag.heute', { datum: datumTagMonat(tag.datum, i18n.language) }) : datumTagMonat(tag.datum, i18n.language)}
      </span>
    </>
  )
  const klasse = 'flex min-h-[52px] w-full flex-col items-start justify-center rounded-[var(--radius-md)] border border-transparent px-2 py-1 text-left'
  if (!tag.betrieb) return <div className={klasse}>{inhalt}</div>
  return (
    <button
      type="button"
      onClick={onOeffnen}
      title={t('wochenplan2.tag.oeffnen')}
      className={`${klasse} transition-colors duration-150 ease-out hover:border-[var(--color-primary)] hover:bg-[var(--color-primary-light)]`}
    >
      {inhalt}
    </button>
  )
}

/**
 * Raster Mo–Fr × Uhrzeiten (Entscheidung 3 und 4): eine Zelle je Tag und Uhrzeit, Tage ohne Betrieb als eine
 * Fläche mit Anlass, unten die Zeile „Einzel“. Auf schmalen Breiten scrollt nur das Raster seitlich.
 */
export function WochenRaster({ woche, einzel, onPanel }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const zeilen = woche.zeiten.length

  return (
    <div className="overflow-x-auto" role="region" aria-label={t('wochenplan2.raster.label')} tabIndex={0}>
      <div className="grid min-w-[880px] grid-cols-[4rem_repeat(5,minmax(9.5rem,1fr))] gap-2">
        <span aria-hidden="true" />
        {woche.tage.map((tag) => (
          <Tageskopf key={tag.datum} tag={tag} onOeffnen={() => onPanel({ art: 'tag', datum: tag.datum })} />
        ))}

        {woche.zeiten.map((zeit, i) => (
          <Fragment key={zeit.id}>
            <span className="flex flex-col pt-2 text-xs tabular-nums text-[var(--color-text-tertiary)]">
              <span className="font-semibold text-[var(--color-text-secondary)]">{zeit.beginn}</span>
              <span>{zeit.ende}</span>
            </span>
            {woche.tage.map((tag) => {
              if (!tag.betrieb) {
                if (i > 0) return null
                return (
                  <div
                    key={tag.datum}
                    // Die Fläche reicht über alle Uhrzeiten des Tages (berechneter Wert).
                    style={{ gridRow: `span ${zeilen}` }}
                    className="flex flex-col items-center justify-center gap-1 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-4 text-center text-xs text-[var(--color-text-tertiary)]"
                  >
                    <span className="font-semibold text-[var(--color-text-secondary)]">{tag.anlass ?? t('woche.keinBetrieb')}</span>
                    {tag.anlass && <span>{t('woche.keinBetrieb')}</span>}
                  </div>
                )
              }
              const zelle = zelleVon(woche, tag.datum, zeit.id)
              return zelle ? (
                <WochenZelle
                  key={tag.datum}
                  zelle={zelle}
                  onOeffnen={() => onPanel({ art: 'slot', datum: tag.datum, zeitId: zeit.id })}
                />
              ) : (
                <span key={tag.datum} />
              )
            })}
          </Fragment>
        ))}

        <span className="pt-2 text-xs font-semibold text-[var(--color-text-secondary)]">{t('wochenplan2.einzel.zeile')}</span>
        {woche.tage.map((tag) => (
          <div key={tag.datum} className="flex min-w-0 flex-col gap-1">
            {einzelAmTag(einzel ?? [], tag.datum).map((s) => (
              <button
                key={s.session_id}
                type="button"
                onClick={() => onPanel({ art: 'einzel', datum: tag.datum, sessionId: s.session_id })}
                className={`flex min-h-[44px] w-full min-w-0 flex-col items-start rounded-[var(--radius-sm)] border border-[var(--color-border)] border-l-[3px] bg-[var(--color-bg-surface)] px-2 py-1 text-left text-xs hover:bg-[var(--color-primary-light)] ${
                  s.testlauf ? 'border-l-[var(--color-gold-warning)]' : 'border-l-[var(--color-primary)]'
                }`}
              >
                <span className="font-semibold tabular-nums text-[var(--color-text-primary)]">
                  {t('wochenplan2.einzel.chip', { zeit: uhrzeit(s.scheduled_at, i18n.language), raum: s.room ?? t('stundenplan.ohneRaum') })}
                </span>
                <span className="max-w-full truncate text-[var(--color-text-tertiary)]">
                  {s.testlauf
                    ? t('wochenplan2.einzel.leitungTest', { leitung: s.coach_name ?? t('stundenplan.ohneCoach') })
                    : s.coach_name ?? t('stundenplan.ohneCoach')}
                </span>
              </button>
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}
