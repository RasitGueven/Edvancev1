import type { CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import { stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import { anteileZeile, anzeigeZahlen, type TpAnteile } from '@/lib/report/praesentation/praesentation'
import type { EbBereich, EbStation, Stufe, TpAnzeige, TpZeile } from '@/types'

import { useKlassen } from './useKlassen'
import { wichtigFuer, type PraesentationV4 } from './v4Daten'
import { Zaehlung } from './Zaehlung'

/**
 * Eine Zeile des Kompetenzprofils in Station 02 (Entscheidung 7, PS-1
 * Entscheidung 9): Name, ein Balken mit zwei Anteilen (sicher, Übungsbedarf
 * mit übersprungen als Punktmuster darin), rechts die Zählung, dann der Pfeil.
 * Antippen öffnet das Detail. Der Balken ist für Vorleseprogramme verborgen,
 * die Zeile hat einen eigenen Vorlesetext.
 */
export function Profilzeile({
  zeile,
  index,
  anzeige,
  v4,
  offen,
  onUmschalten,
}: {
  zeile: TpZeile
  index: number
  anzeige: TpAnzeige
  /** Klassenarbeiten als roter Faden: Kästchen statt Balken, Klassenangabe, „Wichtig für“. */
  v4?: PraesentationV4 | null
  offen: boolean
  onUmschalten: () => void
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const klassen = useKlassen()
  const anteile = anteileZeile(zeile)
  const untersucht = anteile.sicher + anteile.uebung + anteile.uebersprungen
  const z = anzeigeZahlen(anteile, anzeige)
  const feldKey = zeile.feld
  const feld = tb(`feld.${feldKey}`)
  const werte = { feld, untersucht, vorhanden: zeile.vorhanden, sicher: z.sicher, uebung: z.uebung }
  let aria: string
  if (!z.dritte) aria = t('s2.zeileAria', werte)
  else if (z.dritte.art === 'davon') aria = t('s2.zeileAriaKombiniert', { ...werte, uebersprungen: z.dritte.wert })
  else aria = t('s2.zeileAriaGetrennt', { ...werte, uebersprungen: z.dritte.wert })

  const uebungMit = anteile.uebung + anteile.uebersprungen
  const alle = [...zeile.sicher, ...zeile.uebung, ...zeile.uebersprungen]
  const stufen = (['erprobung', 'erste', 'zweite'] as Stufe[]).filter((st) =>
    alle.some((b) => stufeAusKlasse(b.klasse) === st),
  )
  const wichtig = v4 ? wichtigFuer(v4, zeile.feld, uebungMit > 0) : null
  const detailId = `tp-s2-detail-${index}`

  return (
    <article
      className="tp-s2-zeile"
      data-offen={offen}
      data-tp-zeile=""
      data-tp-bereiche={untersucht}
      style={{ '--zeile': index } as CSSProperties}
    >
      <button
        type="button"
        className="tp-s2-zeile-knopf"
        aria-expanded={offen}
        aria-controls={detailId}
        onClick={onUmschalten}
      >
        <span className="sr-only">
          {aria} {t(offen ? 's2.detailsSchliessen' : 's2.detailsZeigen')}
        </span>
        <span className="tp-s2-feld" aria-hidden="true">
          {feld}
          {v4 && <small>{klassen(stufen)}</small>}
        </span>
        {/* Anteile als Zahl in --sicher/--uebung, im CSS flex-grow (station2.css). */}
        <span className={v4 ? 'tp-s2-balken tp-s2-kaestchen' : 'tp-s2-balken'} aria-hidden="true">
          {v4 && <Kaestchen anteile={anteile} zeile={index} />}
          {!v4 && anteile.sicher > 0 && (
            <i
              className="tp-s2-anteil tp-s2-anteil-sicher"
              data-testid="tp-s2-anteil"
              style={{ '--anteil': anteile.sicher } as CSSProperties}
            />
          )}
          {!v4 && uebungMit > 0 && (
            <i
              className="tp-s2-anteil tp-s2-anteil-uebung"
              data-testid="tp-s2-anteil"
              style={{ '--anteil': uebungMit, '--ueber': anteile.uebersprungen } as CSSProperties}
            >
              {anteile.uebersprungen > 0 && <i className="tp-s2-anteil-ueber tp-muster-ueber" />}
            </i>
          )}
        </span>
        <span className="tp-s2-rechts" aria-hidden="true">
          <Zaehlung anteile={anteile} anzeige={anzeige} className="tp-s2-zaehlung" />
        </span>
        <span className="tp-s2-pfeil" aria-hidden="true">
          ⌄
        </span>
      </button>
      <div className="tp-s2-detail" id={detailId} aria-hidden={!offen}>
        <div className="tp-s2-detail-innen">
          <Detail zeile={zeile} wichtig={wichtig} />
        </div>
      </div>
    </article>
  )
}

/**
 * Die Spalten im Detail: „Sicher im Test", „Hier weiterüben" und
 * „Übersprungen · „Weiß ich nicht"", die beiden letzten nur, wenn nicht leer.
 */
function Detail({ zeile, wichtig }: { zeile: TpZeile; wichtig: EbStation[] | 'spaeter' | null }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const keineUebung = zeile.uebung.length === 0 && zeile.uebersprungen.length === 0
  const spalten = 1 + (keineUebung ? 0 : 1) + (zeile.uebersprungen.length > 0 ? 1 : 0) + (wichtig ? 1 : 0)
  return (
    <div className="tp-s2-detail-inhalt" style={{ '--spalten': spalten } as CSSProperties}>
      <div className="tp-s2-spalte tp-s2-spalte-sicher" data-testid="tp-s2-spalte-sicher">
        <h4>{t('s2.detail.sicher')}</h4>
        {zeile.sicher.length > 0 ? <Bereiche liste={zeile.sicher} /> : <p>{t('s2.detail.keinSicher')}</p>}
      </div>
      {zeile.uebung.length > 0 && (
        <div className="tp-s2-spalte tp-s2-spalte-uebung" data-testid="tp-s2-spalte-uebung">
          <h4>{t('s2.detail.uebung')}</h4>
          <Bereiche liste={zeile.uebung} />
        </div>
      )}
      {zeile.uebersprungen.length > 0 && (
        <div className="tp-s2-spalte tp-s2-spalte-ueber" data-testid="tp-s2-spalte-ueber">
          <h4>
            {t('s2.detail.uebersprungen')} <em>· {t('s2.detail.weissNicht')}</em>
          </h4>
          <Bereiche liste={zeile.uebersprungen} />
        </div>
      )}
      {keineUebung && (
        <p className="tp-s2-spalte tp-s2-keine-uebung" data-testid="tp-s2-keine-uebung">
          {t('s2.detail.keineUebung')}
        </p>
      )}
      {wichtig && <WichtigFuer wichtig={wichtig} />}
    </div>
  )
}

/** Höchstens drei Bereiche je Liste, dann „+n weitere" (PS-1, Entscheidung 9). */
const JE_LISTE = 3

/** Die Bereiche mit Label, in der Reihenfolge der Rechnung (Klasse, dann Label). */
function Bereiche({ liste }: { liste: EbBereich[] }): JSX.Element {
  const { t: tb } = useTranslation('elternbericht')
  const rest = liste.length - JE_LISTE
  return (
    <ul className="tp-s2-bereiche">
      {liste.slice(0, JE_LISTE).map((b) => (
        <li key={b.skillKey}>{b.label}</li>
      ))}
      {rest > 0 && <li className="tp-s2-weitere">{tb('s1.blick.weitere', { count: rest })}</li>}
    </ul>
  )
}

/** Die Kästchen einer Zeile: eines je geprüftem Bereich, sicher zuerst; sie ploppen beim ersten Besuch auf. */
function Kaestchen({ anteile, zeile }: { anteile: TpAnteile; zeile: number }): JSX.Element {
  const arten = [
    ...Array<string>(anteile.sicher).fill('sicher'),
    ...Array<string>(anteile.uebung).fill('uebung'),
    ...Array<string>(anteile.uebersprungen).fill('ueber'),
  ]
  return (
    <>
      {arten.map((art, k) => (
        <i
          key={k}
          className={art === 'ueber' ? 'tp-s2-kasten tp-s2-kasten-uebung tp-muster-ueber' : `tp-s2-kasten tp-s2-kasten-${art}`}
          data-testid="tp-s2-kasten"
          style={{ '--zeile': zeile, '--k': k } as CSSProperties}
        />
      ))}
    </>
  )
}

/** Dritte Spalte im Detail (V4): die Klassenarbeiten, für die das Feld wichtig ist. */
function WichtigFuer({ wichtig }: { wichtig: EbStation[] | 'spaeter' }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  return (
    <div className="tp-s2-spalte tp-s2-spalte-wichtig" data-testid="tp-s2-wichtig">
      <h4>{t('v4.s2.wichtig')}</h4>
      {wichtig === 'spaeter' ? (
        <p>{tb('v4.s2.spaeter')}</p>
      ) : (
        <ul className="tp-s2-marken">
          {wichtig.map((s) => (
            <li key={s.nummer} className={s.stand === 'naechste' ? 'tp-s2-marke tp-s2-marke-naechste' : 'tp-s2-marke'}>
              <b>{s.nummer}</b> {s.titel}
              {s.stand === 'naechste' && <em>{tb('v4.s2.naechste')}</em>}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
