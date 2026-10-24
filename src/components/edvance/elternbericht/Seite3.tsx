import { useContext, useLayoutEffect, useMemo, useRef, useState, type RefObject } from 'react'
import { useTranslation } from 'react-i18next'

import { duenneLueckenweg, LUECKENWEG_STUFEN } from '@/lib/report/elternbericht/lueckenweg'
import type { EbKommtThema, EbLueckenweg } from '@/types'

import { schuleGenitiv } from './berichtSaetze'
import { NamensMessungFertig } from './namensMessung'
import type { SeitenProps } from './seitenProps'

/**
 * Stufe des Ausdünnens (duenneLueckenweg): Läuft die Seite über, geht sie eine
 * Stufe weiter, bis alles passt oder die letzte erreicht ist. Gemessen wie auf
 * Seite 4 am Inhaltskasten, nach der Namensentscheidung und den Schriften.
 */
function useAusduennen(schluessel: unknown): { ref: RefObject<HTMLDivElement>; stufe: number } {
  const ref = useRef<HTMLDivElement>(null)
  const [stufe, setStufe] = useState(0)
  const nameEntschieden = useContext(NamensMessungFertig)

  useLayoutEffect(() => setStufe(0), [schluessel])
  useLayoutEffect(() => {
    const kasten = ref.current?.parentElement
    if (!nameEntschieden || !kasten || stufe >= LUECKENWEG_STUFEN - 1) return
    let aktiv = true
    const pruefen = (): void => {
      if (aktiv && kasten.scrollHeight > kasten.clientHeight + 0.5) setStufe(stufe + 1)
    }
    void kasten.offsetHeight
    if (!document.fonts || document.fonts.status === 'loaded') pruefen()
    else void document.fonts.ready.then(pruefen)
    return () => {
      aktiv = false
    }
  }, [stufe, nameEntschieden])

  return { ref, stufe }
}

/**
 * Seite 3 des Eltern-Berichts (v2): Einordnung.
 *
 * Im Fokus die Lücken: je kommendem Schulthema eine Zeile — links die Bereiche
 * mit Übungsbedarf, auf denen es laut Voraussetzungsgraph direkt aufbaut,
 * rechts das Thema mit „voraussichtlich“ und Halbjahr aus dem Schulplan. Der
 * Pfeil steht nur zwischen den beiden Kästen einer Zeile; nichts läuft quer
 * über die Seite. Darunter die übrigen Lücken, ganz unten knapp die Stärken.
 * Rechnung: src/lib/report/elternbericht/lueckenweg.ts.
 *
 * Der bisherige Lernweg (bericht.lernweg) bleibt für Station 03 der
 * Präsentation bestehen.
 */
export function Seite3({ data, bericht }: SeitenProps): JSX.Element | null {
  const { t, i18n } = useTranslation('elternbericht')
  const voll = bericht.lueckenweg ?? null
  const a = useAusduennen(voll)
  const lw = useMemo(() => (voll ? duenneLueckenweg(voll, a.stufe) : null), [voll, a.stufe])
  if (!lw) return null
  const liste = (s: readonly string[]): string =>
    new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(s)
  const quelle =
    lw.quelle === 'klp'
      ? t('s3.v2.quelleKlp')
      : lw.schulname
        ? t('s3.v2.quelleSchule', { schule: schuleGenitiv(t, lw.schulname) })
        : t('s3.v2.quelleSchuleOhneName')
  const zeilen = lw.themen.filter((k) => k.luecken.length > 0)
  const mitLuecken = zeilen.length > 0 || lw.weitere.length > 0

  return (
    <div className="eb-s3 eb-s3v2" ref={a.ref} data-stufe={a.stufe || undefined}>
      <p className="eb-kicker eb-s3-kicker">{t('s3.v2.kicker')}</p>
      <h1 className="eb-titel eb-s3-titel">{t(mitLuecken ? 's3.v2.titel' : 's3.v2.titelOhneLuecken')}</h1>
      {zeilen.length > 0 && (
        <p className="eb-s3-intro">{t('s3.v2.intro', { quelle, klasse: data.grade })}</p>
      )}

      {zeilen.length > 0 && (
        <section className="eb-s3v2-wege" data-testid="eb-s3-wege">
          <div className="eb-s3v2-kopf" aria-hidden="true">
            <span>{t('s3.v2.spalteLuecken')}</span>
            <span>{t('s3.v2.spalteKommt')}</span>
          </div>
          {zeilen.map((k) => (
            <Zeile key={k.titel} k={k} klasse={data.grade} liste={liste} />
          ))}
        </section>
      )}

      {lw.weitere.length > 0 && <Weitere lw={lw} />}

      <Staerken lw={lw} liste={liste} />

      <p className="eb-s3-hinweis">{t('s3.v2.hinweis', { quelle })}</p>
    </div>
  )
}

function Zeile({
  k,
  klasse,
  liste,
}: {
  k: EbKommtThema
  klasse: number
  liste: (s: readonly string[]) => string
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <div className="eb-s3v2-zeile" data-testid="eb-s3-zeile">
      <ul className="eb-s3v2-luecken">
        {k.luecken.map((l) => (
          <li key={l}>{l}</li>
        ))}
        {(k.rest ?? 0) > 0 && <li className="eb-s3v2-rest">{t('s3.v2.undWeitere', { count: k.rest })}</li>}
      </ul>
      <svg className="eb-s3v2-pfeil" viewBox="0 0 24 12" aria-hidden="true">
        <path d="M1 6 H20 M15 1.5 L21 6 L15 10.5" />
      </svg>
      <div className="eb-s3v2-kommt">
        <p className="eb-s3v2-kommt-titel">{k.titel}</p>
        <p className="eb-s3v2-kommt-wann">
          {k.halbjahr ? t('s3.v2.halbjahr', { halbjahr: k.halbjahr }) : t('s3.v2.ohneHalbjahr', { klasse })}
        </p>
        {k.staerken.length > 0 && !k.zeileOhneStaerken && (
          <p className="eb-s3v2-kommt-sitzt">{t('s3.v2.sitztSchon', { liste: liste(k.staerken) })}</p>
        )}
      </div>
    </div>
  )
}

function Weitere({ lw }: { lw: EbLueckenweg }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <section className="eb-s3v2-weitere" data-testid="eb-s3-weitere">
      <h2 className="eb-kicker">{t('s3.v2.weitereKicker')}</h2>
      {lw.themen.some((k) => k.luecken.length > 0) && !lw.weitere.some((g) => g.spaeter) && (
        <p className="eb-s3v2-leise">{t('s3.v2.weitereHinweis')}</p>
      )}
      <dl>
        {lw.weitere.map((g) => (
          <div key={g.spaeter ? 'spaeter' : (g.feld ?? 'thema')} className="eb-s3v2-gruppe">
            <dt>
              {g.spaeter
                ? t('s3.v2.weitereSpaeter')
                : g.thema
                  ? t('s3.v2.weitereThema', { thema: g.thema })
                  : t(`feld.${g.feld ?? 'weitere'}`)}
            </dt>
            <dd>
              {g.labels.length === 0
                ? t('s3.v2.nurAnzahl', { count: g.rest ?? 0 })
                : [...g.labels, ...((g.rest ?? 0) > 0 ? [t('s3.v2.undWeitere', { count: g.rest })] : [])].join(' · ')}
            </dd>
          </div>
        ))}
      </dl>
    </section>
  )
}

function Staerken({ lw, liste }: { lw: EbLueckenweg; liste: (s: readonly string[]) => string }): JSX.Element | null {
  const { t } = useTranslation('elternbericht')
  if (lw.sicherGesamt === 0) return null
  const themen = lw.themen.filter((k) => k.staerken.length > 0).map((k) => k.titel)
  const rest = lw.sicherGesamt - lw.staerken.length
  return (
    <section className="eb-s3v2-staerken" data-testid="eb-s3-staerken">
      <h2 className="eb-kicker">{t('s3.v2.staerkenKicker')}</h2>
      <p>
        {lw.staerken.length > 0 && themen.length > 0
          ? [
              t('s3.v2.staerken', { themen: liste(themen), liste: liste(lw.staerken) }),
              rest > 0 && t('s3.v2.staerkenRest', { count: rest }),
            ]
              .filter(Boolean)
              .join(' ')
          : t('s3.v2.staerkenOhneBezug', { count: lw.sicherGesamt })}
      </p>
    </section>
  )
}
