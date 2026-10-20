import { useState, type CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import { useLernwegTexte } from '@/components/edvance/elternbericht/lernwegTexte'
import type { Lernweg, LwInsel, LwZone } from '@/types'

import { infoEintrag, infoKommt, infoLeer, verbunden } from './lernwegInfo'
import type { Fahrt } from './useLernwegFahrt'

type Spalte = { key: string; inseln: LwInsel[]; art: 'normal' | 'jahr' | 'naechste' | 'leer' }

/** Eine Spalte bis 3 Inseln, sonst zwei; Kommt noch: dieses Schuljahr und die nächste Klasse. */
export function spaltenVon(z: LwZone, lw: Lernweg): Spalte[] {
  if (z.key === 'kommt') {
    return [
      { key: 'kommt-jahr', inseln: z.inseln, art: 'jahr' },
      ...(lw.naechsteKlasse ? [{ key: 'kommt-naechste', inseln: lw.naechsteKlasse.inseln, art: 'naechste' as const }] : []),
    ]
  }
  if (z.inseln.length === 0) return [{ key: z.key, inseln: [], art: 'leer' }]
  if (z.inseln.length <= 3) return [{ key: z.key, inseln: z.inseln, art: 'normal' }]
  const h = Math.ceil(z.inseln.length / 2)
  return [
    { key: `${z.key}-1`, inseln: z.inseln.slice(0, h), art: 'normal' },
    { key: `${z.key}-2`, inseln: z.inseln.slice(h), art: 'normal' },
  ]
}

/** Lage eines Eintrags in der Folge seiner Insel: für das Nacheinander (je 300 ms). */
const folge = (i: number): CSSProperties => ({ '--tp-i': i }) as CSSProperties

/**
 * Station 03 · die waagrechte Bühne des Lernwegs (R7-9, Entscheidungen 20–25):
 * Zonen nebeneinander, Inseln in Spalten, goldene Linien darüber, die Zukunft
 * hellblau mit Wolken. Darunter Fortschrittsbalken, Zonennamen und Infofeld.
 */
export function LernwegBuehne({ lw, f }: { lw: Lernweg; f: Fahrt }): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const tx = useLernwegTexte(lw)
  const [sel, setSel] = useState<string | null>(null)
  const [plan, setPlan] = useState<string | null>(null)

  const liste = (l: string[]): string => new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(l)
  const nah = sel ? verbunden(lw, sel) : null
  const sichtbar = (id: string): boolean => f.sicht === null || f.sicht.has(id)
  const alleInseln = [...lw.zonen.flatMap((z) => z.inseln), ...(lw.naechsteKlasse?.inseln ?? [])]
  const info = sel
    ? infoEintrag(lw, sel, t, tb, liste)
    : plan
      ? infoKommt(lw, alleInseln.find((i) => i.id === plan)!, t, liste)
      : infoLeer(t)

  const tippen = (id: string): void => {
    if (f.unterdrueckt()) return
    f.unterbrechen()
    setPlan(null)
    setSel((alt) => (alt === id ? null : id))
  }
  const klaeren = (id: string): void => {
    if (f.unterdrueckt()) return
    f.unterbrechen()
    setSel(null)
    setPlan((alt) => (alt === id ? null : id))
  }
  const knopf = (id: string, basis: string): string =>
    [basis, sel === id && 'tp-s3-gewaehlt', nah && !nah.has(id) && 'tp-s3-blass'].filter(Boolean).join(' ')

  const insel = (i: LwInsel, art: Spalte['art']): JSX.Element => {
    const kommt = i.zone === 'kommt'
    const klasse = [
      'tp-s3-insel',
      kommt && 'tp-s3-insel-kommt',
      art === 'jahr' && 'tp-s3-dunst',
      art === 'naechste' && 'tp-s3-weit',
      plan === i.id && 'tp-s3-klar',
      i.broeckelt && 'tp-s3-broeckelt',
      sichtbar(i.id) && 'tp-s3-da',
    ]
    let n = 0
    return (
      <div key={i.id} className={klasse.filter(Boolean).join(' ')} data-insel={i.id}>
        {kommt ? (
          <button type="button" className="tp-s3-kbtn" aria-pressed={plan === i.id} onClick={() => klaeren(i.id)}>
            <span className="tp-s3-insel-titel">{tx.inselTitel(i)}</span>
          </button>
        ) : (
          <p className="tp-s3-insel-titel">{tx.inselTitel(i)}</p>
        )}
        {i.eintraege.length > 0 && (
          <ul className="tp-s3-eintraege">
            {i.eintraege.map((e) => (
              <li key={e.id} style={folge(n++)}>
                <button
                  type="button"
                  className={knopf(e.id, `tp-s3-e tp-s3-e-${e.stand}`)}
                  aria-pressed={sel === e.id}
                  data-eintrag={e.id}
                  onClick={() => tippen(e.id)}
                >
                  <span className="tp-s3-punkt" data-anker="" aria-hidden="true" />
                  <span className="tp-s3-label" data-tp-text="">
                    {e.label}
                    {e.spaeter && <small>{tx.spaeter(e.klasse)}</small>}
                  </span>
                </button>
                {e.unter.map((u) => (
                  <button
                    key={u.id}
                    type="button"
                    style={folge(n++)}
                    className={knopf(u.id, `tp-s3-e tp-s3-unter tp-s3-unter-${u.stand}`)}
                    aria-pressed={sel === u.id}
                    data-eintrag={u.id}
                    onClick={() => tippen(u.id)}
                  >
                    <span className="tp-s3-pfeil" data-anker="" aria-hidden="true">
                      ↳
                    </span>
                    <span className="tp-s3-label" data-tp-text="">
                      {u.label}
                      <small>{tx.unterZeile(u)}</small>
                    </span>
                  </button>
                ))}
              </li>
            ))}
          </ul>
        )}
      </div>
    )
  }

  const klassen = ['tp-s3-scroller', f.frei && 'tp-s3-frei', f.zieht && 'tp-s3-zieht'].filter(Boolean).join(' ')

  return (
    <div className="tp-s3-buehne tp-reveal">
      <div
        ref={f.scrollerRef}
        className={klassen}
        role="region"
        aria-label={t('s3.weg.buehneAria')}
        onScroll={f.handler.onScroll}
        onWheel={f.handler.onWheel}
        onPointerDown={f.handler.onPointerDown}
        onPointerMove={f.handler.onPointerMove}
        onPointerUp={f.handler.onPointerUp}
        onPointerLeave={f.handler.onPointerUp}
        onTouchStart={f.handler.onTouchStart}
        data-testid="tp-s3-scroller"
      >
        <div ref={f.aussenRef} className="tp-s3-aussen">
          {f.rast.map((x, i) => (
            <span key={i} className="tp-s3-rastpunkt" style={{ left: x }} />
          ))}
          <div ref={f.spurRef} className="tp-s3-spur">
            {lw.zonen.map((z) => (
              <section
                key={z.key}
                className={`tp-s3-zone tp-s3-zone-${z.key}${sichtbar(`z:${z.key}`) ? ' tp-s3-da' : ''}`}
                data-zone={z.key}
                data-rast=""
              >
                {z.key === 'kommt' && (
                  <>
                    <div className="tp-s3-wolken" aria-hidden="true">
                      {[1, 2, 3, 4, 5].map((w) => (
                        <i key={w} className={`tp-s3-wolke tp-s3-wolke-${w}`} />
                      ))}
                    </div>
                    {f.hier && (
                      <p className="tp-s3-hier" data-testid="tp-s3-hier">
                        <span className="tp-s3-kugel" aria-hidden="true" />
                        <span className="tp-s3-schild">{tx.hier}</span>
                      </p>
                    )}
                  </>
                )}
                <header className="tp-s3-zone-kopf" data-kopf="" data-tp-ueberschrift="">
                  <p className="tp-s3-zone-name">{tx.zoneName(z.key)}</p>
                  <p className="tp-s3-zone-klasse">{tx.zoneKlasse(z.key, true)}</p>
                </header>
                <div className="tp-s3-spalten">
                  {spaltenVon(z, lw).map((sp) => (
                    <div
                      key={sp.key}
                      className={`tp-s3-spalte tp-s3-spalte-${sp.art}`}
                      data-spalte={sp.key}
                      data-rast={sp.art === 'naechste' ? '' : undefined}
                    >
                      {sp.art === 'naechste' && <p className="tp-s3-naechste">{tb('s3.weg.zone.naechste', { klasse: lw.naechsteKlasse!.klasse })}</p>}
                      {sp.inseln.map((i) => insel(i, sp.art))}
                    </div>
                  ))}
                </div>
              </section>
            ))}
            <svg className="tp-s3-linien" aria-hidden="true" focusable="false">
              {f.pfade.map((p) => {
                const key = `${p.von}-${p.zu}`
                const blass = nah && !(nah.has(p.von) && nah.has(p.zu)) ? ' tp-s3-blass' : ''
                return (
                  <g key={key} data-linie={key}>
                    <path ref={f.pfadRef(key, 'linie')} className={`tp-s3-linie${blass}`} d={p.d} />
                    <path ref={f.pfadRef(key, 'spitze')} className={`tp-s3-spitze${blass}`} d={p.spitzeD} />
                  </g>
                )
              })}
            </svg>
          </div>
        </div>
      </div>

      <div className="tp-s3-fuss">
        <div className="tp-s3-leiste">
          <span className="tp-s3-balken" aria-hidden="true">
            <span />
          </span>
          <ul className="tp-s3-zonennamen" aria-label={t('s3.weg.zonenAria')}>
            {lw.zonen.map((z, i) => (
              <li key={z.key} className={Math.min(f.zone, lw.zonen.length - 1) === i ? 'tp-s3-an' : undefined}>
                {tx.zoneName(z.key)}
              </li>
            ))}
          </ul>
        </div>
        <p className="tp-s3-info" aria-live="polite" data-testid="tp-s3-info">
          {info.titel && <strong>{info.titel}</strong>} {info.text}
        </p>
      </div>
    </div>
  )
}
