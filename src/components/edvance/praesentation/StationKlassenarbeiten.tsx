import { Fragment, type CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import type { EbKommtThema, EbStation, EbZuordnung } from '@/types'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'
import { schuleGenitiv } from '@/components/edvance/elternbericht/berichtSaetze'

import type { PraesentationV4 } from './v4Daten'

/** Höchstens drei Einträge je Liste, dann „+n weitere“. */
const JE_LISTE = 3

function Liste({ art, eintraege }: { art: 'sitzt' | 'fehlt'; eintraege: EbZuordnung[] }): JSX.Element | null {
  const { t: tb } = useTranslation('elternbericht')
  if (eintraege.length === 0) return null
  const rest = eintraege.length - JE_LISTE
  return (
    <ul className={`tp-ka-liste-${art}`} data-testid={`tp-ka-${art}`}>
      {eintraege.slice(0, JE_LISTE).map((e) => (
        <li key={e.label}>{e.label}</li>
      ))}
      {rest > 0 && <li className="tp-ka-weitere">{tb('s1.blick.weitere', { count: rest })}</li>}
    </ul>
  )
}

/**
 * Der Satz zu einer offenen Lücke im aktuellen Thema: der erste Bereich mit
 * Übungsbedarf dort, und die erste kommende Station, die ihn wieder braucht.
 */
function offeneLuecke(v4: PraesentationV4): { bereich: string; thema: string } | null {
  const bereich = v4.bericht.thema?.uebung[0]
  if (!bereich) return null
  const signal = (v4.bericht.signale ?? []).find(
    (s) => s.fehlt.some((b) => b.label === bereich) && v4.fahrplan.stationen.some((k) => k.nummer > 1 && k.themaKey === s.themaKey),
  )
  const station = v4.fahrplan.stationen.find((k) => k.nummer > 1 && k.themaKey === signal?.themaKey)
  return station ? { bereich, thema: station.titel } : null
}

/** Teile einer Zeile, getrennt durch einen Punkt (CSS); das Leerzeichen erlaubt den Umbruch. */
function Teile({ teile }: { teile: (string | null)[] }): JSX.Element {
  return (
    <>
      {teile
        .filter((x): x is string => x !== null)
        .map((x, i) => (
          <Fragment key={x}>
            {i > 0 && ' '}
            <span>{x}</span>
          </Fragment>
        ))}
    </>
  )
}

function Karte({
  s,
  block,
  luecke,
  klasse,
}: {
  s: EbStation
  block: EbKommtThema | undefined
  luecke: { bereich: string; thema: string } | null
  klasse: number | null
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const art = s.stand === 'geschrieben' ? 'geschrieben' : (s.signal ?? s.stand)
  return (
    <article className={`tp-ka-karte tp-ka-${art}`} data-testid="tp-ka-karte" data-tp-pflicht="">
      <span className="tp-ka-chip" data-testid="tp-ka-chip">
        <Teile teile={[tb(`v4.stand.${s.stand}`), s.note !== null ? tb('v4.stand.note', { note: s.note }) : null]} />
      </span>
      <b>{s.titel}</b>
      <small>
        <Teile
          teile={[
            t('v4.s3.karte', { n: s.nummer }),
            s.halbjahr ? tb('v4.stand.halbjahr', { halbjahr: s.halbjahr }) : null,
            klasse !== null && s.schuljahr === 'naechstes' ? tb('v4.stand.klasse', { klasse }) : null,
          ]}
        />
      </small>
      {s.signal && <span className="tp-ka-signal">{tb(`v4.signal.${s.signal}`)}</span>}
      {block && s.signal !== 'ohne' && (
        <>
          <Liste art="sitzt" eintraege={block.sitzt} />
          <Liste art="fehlt" eintraege={block.fehlt} />
        </>
      )}
      {s.stand === 'geschrieben' && luecke && (
        <p className="tp-ka-offen" data-testid="tp-ka-offen">
          {t('v4.s3.offen', luecke)}
        </p>
      )}
    </article>
  )
}

/**
 * Station 03 · Klassenarbeiten (V4, Entscheidung 4): je Station des Fahrplans
 * eine Karte mit Stand, Titel und Nummer. Kommende Arbeiten zeigen bis zu drei
 * Bereiche, die sitzen, und die fehlen. Die geschriebene Arbeit steht
 * gestrichelt, mit einem Satz zu einer offenen Lücke. Fußzeile mit der Quelle.
 */
export function StationKlassenarbeiten({ v4 }: StationProps): JSX.Element | null {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  if (!v4) return null
  const { fahrplan, bericht } = v4
  const luecke = offeneLuecke(v4)
  const blocks = bericht.lueckenwegV4?.themen ?? []
  const quelle =
    fahrplan.quelle === 'schule' && fahrplan.schulname
      ? tb('v4.quelle.schuleGenitiv', { schule: schuleGenitiv(tb, fahrplan.schulname) })
      : tb('v4.quelle.klp')

  return (
    <div className="tp-szene tp-ka">
      <Kicker nummer={3}>{t('v4.s3.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {t('v4.s3.titel')}
      </h2>
      {fahrplan.satz && (
        <p className="tp-desc tp-reveal" data-testid="tp-ka-satz">
          {tb(fahrplan.satz === 'fehlt' ? 'v4.s1.satzFehlt' : 'v4.s1.satzErfuellt')}
        </p>
      )}
      <div
        className="tp-ka-raster tp-reveal"
        style={{ '--n': fahrplan.stationen.length } as CSSProperties}
        data-testid="tp-ka-raster"
      >
        {fahrplan.stationen.map((s) => (
          <Karte
            key={s.nummer}
            s={s}
            block={blocks.find((b) => b.titel === s.titel)}
            luecke={luecke}
            klasse={fahrplan.klassenTrenner}
          />
        ))}
      </div>
      {fahrplan.weitere > 0 && <p className="tp-ka-fuss tp-reveal">{tb('v4.stand.weitere', { count: fahrplan.weitere })}</p>}
      <p className="tp-ka-fuss tp-reveal" data-testid="tp-ka-quelle">
        {quelle}
      </p>
    </div>
  )
}
