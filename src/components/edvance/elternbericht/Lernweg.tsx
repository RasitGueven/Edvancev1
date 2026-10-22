import { useLayoutEffect, useRef } from 'react'

import type { Lernweg as LernwegDaten, LwEintrag, LwInsel, LwZone, LwZusammen } from '@/types'

import { legendeFuer, useLernwegTexte } from './lernwegTexte'

/**
 * Seite 3 · Legende oben, nur mit den Einträgen, die auf der Seite vorkommen
 * (Entscheidung 12).
 */
export function LernwegLegende({ lw }: { lw: LernwegDaten }): JSX.Element {
  const tx = useLernwegTexte(lw)
  return (
    <ul className="eb-s3-legende" data-testid="eb-s3-legende">
      {legendeFuer(lw).map((a) => (
        <li key={a} className={`eb-s3-leg eb-s3-leg-${a}`} data-legende={a}>
          {a === 'unter' && (
            <span className="eb-s3-pfeil" aria-hidden="true">
              ↳
            </span>
          )}
          {tx.legende(a)}
        </li>
      ))}
    </ul>
  )
}

function Eintrag({ e, tx }: { e: LwEintrag; tx: ReturnType<typeof useLernwegTexte> }): JSX.Element {
  return (
    <li className={`eb-s3-e eb-s3-e-${e.stand}`} data-eintrag={e.id}>
      <span className="eb-s3-zeile">
        <span className="eb-s3-punkt" data-anker="" aria-hidden="true" />
        <span className="eb-s3-label">
          {e.label}
          {e.spaeter && <small className="eb-s3-spaeter">{tx.spaeter(e.klasse)}</small>}
        </span>
      </span>
      {e.unter.length > 0 && (
        <ul className="eb-s3-unterliste">
          {e.unter.map((u) => (
            <li key={u.id} className={`eb-s3-unter eb-s3-unter-${u.stand}`} data-eintrag={u.id}>
              <span className="eb-s3-pfeil" data-anker="" aria-hidden="true">
                ↳
              </span>
              <span className="eb-s3-label">
                {u.label}
                <small className="eb-s3-wie">{tx.unterZeile(u)}</small>
              </span>
            </li>
          ))}
        </ul>
      )}
    </li>
  )
}

function Insel({ i, tx }: { i: LwInsel; tx: ReturnType<typeof useLernwegTexte> }): JSX.Element {
  const kommt = i.zone === 'kommt'
  return (
    <div
      className={kommt ? 'eb-s3-insel eb-s3-insel-kommt' : 'eb-s3-insel'}
      data-insel={i.id}
      data-broeckelt={i.broeckelt || undefined}
    >
      <p className="eb-s3-insel-titel">{tx.inselTitel(i)}</p>
      {i.eintraege.length > 0 && (
        <ul className="eb-s3-eintraege">
          {i.eintraege.map((e) => (
            <Eintrag key={e.id} e={e} tx={tx} />
          ))}
        </ul>
      )}
      {i.weitere && <p className="eb-s3-weitere">{tx.weitere(i.weitere)}</p>}
    </div>
  )
}

/**
 * Eine zusammengefasste Zone (R7-12): je Themenfeld eine Zählzeile. Die erste
 * trägt den Anker der Linien, die in der Zone beginnen.
 */
function Zusammen({ z, tx }: { z: LwZusammen; tx: ReturnType<typeof useLernwegTexte> }): JSX.Element {
  return (
    <div className="eb-s3-insel eb-s3-zusammen" data-insel={z.id}>
      <ul className="eb-s3-eintraege">
        {z.zeilen.map((zeile, n) => (
          <li
            key={zeile.feld}
            className="eb-s3-zaehl"
            data-eintrag={n === 0 ? z.id : undefined}
            data-anker={n === 0 ? '' : undefined}
          >
            {tx.zaehlzeile(zeile)}
          </li>
        ))}
      </ul>
    </div>
  )
}

/** Gewicht einer Spalte: Zeilen der Einträge (↳ zählt mehr), Inseltitel; leer schmal. */
export function spaltenGewicht(z: LwZone): number {
  if (z.zusammen) return Math.max(0.8, 0.55 + z.zusammen.zeilen.length * 1.4 * 0.045)
  if (z.inseln.length === 0) return 0.68
  const zeilen = z.inseln.reduce(
    (n, i) => n + 1.2 + (i.weitere ? 1 : 0) + i.eintraege.reduce((m, e) => m + 1 + e.unter.length * 1.6, 0),
    0,
  )
  return Math.min(1.7, Math.max(z.key === 'kommt' ? 1.05 : 0.8, 0.55 + zeilen * 0.045))
}

/**
 * Seite 3 · die Zonen als zart getönte Spalten (Entscheidung 13), Inseln
 * darin, „Sie sind hier“ über der Grenze zu Kommt noch (Entscheidung 14). Die
 * Linien zeichnet LernwegLinien darüber.
 */
export function LernwegZonen({ lw }: { lw: LernwegDaten }): JSX.Element {
  const tx = useLernwegTexte(lw)
  const raster = useRef<HTMLDivElement>(null)
  // Spaltenbreiten nach Inhalt: eine leere Zone bleibt schmal stehen, eine volle
  // wird breiter und bricht weniger um (berechneter Wert, CLAUDE.md §11).
  useLayoutEffect(() => {
    raster.current?.style.setProperty('--eb-s3-spalten', lw.zonen.map((z) => `${spaltenGewicht(z)}fr`).join(' '))
  }, [lw])
  return (
    <div ref={raster} className="eb-s3-zonen" data-zonen={lw.zonen.length}>
      {lw.zonen.map((z) => (
        <section key={z.key} className={`eb-s3-zone eb-s3-zone-${z.key}`} data-spalte={z.key}>
          {z.key === 'kommt' && (
            <p className="eb-s3-hier" data-testid="eb-s3-hier">
              {tx.hier}
            </p>
          )}
          <header className="eb-s3-zone-kopf" data-kopf="">
            <p className="eb-s3-zone-name">{tx.zoneName(z.key)}</p>
            <p className="eb-s3-zone-klasse">{tx.zoneKlasse(z.key)}</p>
          </header>
          <div className="eb-s3-inseln" data-inseln="">
            {z.zusammen && z.zusammen.zeilen.length > 0 && <Zusammen z={z.zusammen} tx={tx} />}
            {z.inseln.map((i) => (
              <Insel key={i.id} i={i} tx={tx} />
            ))}
          </div>
        </section>
      ))}
    </div>
  )
}
