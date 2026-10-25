import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import { duenneLueckenweg } from '@/lib/report/elternbericht/lueckenweg'
import type { EbKommtThema, EbLueckenweg, EbZuordnung } from '@/types'

import { schuleGenitiv } from './berichtSaetze'
import type { SeitenProps } from './seitenProps'
import { Seite3V4 } from './Seite3V4'
import { useAusduennen } from './useAusduennen'

type Liste = (s: readonly string[]) => string

/**
 * Seite 3 des Eltern-Berichts (v3): Einordnung — erst was sitzt, dann was fehlt.
 *
 * Je kommendem Schulthema, das direkt auf geprüften Bereichen aufbaut, ein
 * grüner Kasten („Sitzt schon“), ein roter („Fehlt noch“) und der blaue
 * Themenkasten. Zwei Layouts (berichtKonfig.EINORDNUNG_LAYOUT):
 *   A — oben alle grünen, darunter alle roten Kästen; die Themen stehen einmal
 *       in einer gemeinsamen rechten Spalte, verbunden über ihre Nummer,
 *   B — je Thema eine Zeile: grün · rot → blau.
 * Jeder Bereich steht genau einmal („betrifft auch …“ für weitere Themen).
 * Darunter „Weitere Stärken“ als kurze Liste, zuletzt „Weitere Bereiche mit
 * Übungsbedarf“. Pfeile bleiben in ihrer Zeile. Rechnung:
 * src/lib/report/elternbericht/lueckenweg.ts.
 */
export function Seite3(props: SeitenProps): JSX.Element | null {
  // Bericht v4: Mit Fahrplan und Layout B steht ein Block je Klassenarbeit (Seite3V4).
  return props.einordnung !== 'A' && props.bericht.fahrplan && props.bericht.lueckenwegV4 ? (
    <Seite3V4 {...props} />
  ) : (
    <Seite3V3 {...props} />
  )
}

function Seite3V3({ bericht, einordnung = 'B' }: SeitenProps): JSX.Element | null {
  const { t, i18n } = useTranslation('elternbericht')
  const voll = bericht.lueckenweg ?? null
  const a = useAusduennen(voll)
  const lw = useMemo(() => (voll ? duenneLueckenweg(voll, a.stufe) : null), [voll, a.stufe])
  if (!lw) return null
  const liste: Liste = (s) => new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(s)
  const quelle =
    lw.quelle === 'klp'
      ? t('s3.v2.quelleKlp')
      : lw.schulname
        ? t('s3.v2.quelleSchule', { schule: schuleGenitiv(t, lw.schulname) })
        : t('s3.v2.quelleSchuleOhneName')
  const rest = lw.weitereStaerkenRest ?? 0

  return (
    <div
      className="eb-s3 eb-s3v3"
      ref={a.ref}
      data-stufe={a.stufe || undefined}
      data-layout={einordnung}
      data-testid="eb-s3"
    >
      <p className="eb-kicker eb-s3-kicker">{t('s3.v2.kicker')}</p>
      <h1 className="eb-titel eb-s3-titel">{t('s3.v3.titel')}</h1>
      {lw.themen.length > 0 && <p className="eb-s3-intro">{t('s3.v3.intro', { quelle })}</p>}

      {lw.themen.length > 0 &&
        (einordnung === 'A' ? <LayoutA lw={lw} liste={liste} /> : <LayoutB lw={lw} liste={liste} />)}

      {(lw.weitereStaerken.length > 0 || rest > 0) && (
        <section className="eb-s3v3-weitere-staerken" data-testid="eb-s3-weitere-staerken">
          <h2 className="eb-kicker">{t('s3.v3.weitereStaerken')}</h2>
          <p>
            {lw.weitereStaerken.length === 0
              ? t('s3.v2.nurAnzahl', { count: rest })
              : [...lw.weitereStaerken, ...(rest > 0 ? [t('s3.v2.undWeitere', { count: rest })] : [])].join(' · ')}
          </p>
        </section>
      )}

      {lw.weitere.length > 0 && <Weitere lw={lw} />}

      <p className="eb-s3-hinweis">{t('s3.v2.hinweis', { quelle })}</p>
    </div>
  )
}

/** Die Bereiche eines Kastens, je mit „betrifft auch …“, dazu der Rest als Zahl. */
function Bereiche({ liste, eintraege, rest }: { liste: Liste; eintraege: EbZuordnung[]; rest?: number }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <ul className="eb-s3v3-bereiche">
      {eintraege.map((z) => (
        <li key={z.label}>
          {z.label}
          {z.auch.length > 0 && <small className="eb-s3v3-auch">{t('s3.v3.auch', { themen: liste(z.auch.map((titel) => t('s3.v3.titelZitat', { titel }))) })}</small>}
        </li>
      ))}
      {(rest ?? 0) > 0 && <li className="eb-s3v3-rest">{t('s3.v2.undWeitere', { count: rest })}</li>}
    </ul>
  )
}

function Pfeil({ art }: { art: 'sitzt' | 'fehlt' }): JSX.Element {
  return (
    <svg className={`eb-s3v3-pfeil eb-s3v3-pfeil-${art}`} viewBox="0 0 24 12" aria-hidden="true">
      <path d="M1 6 H20 M15 1.5 L21 6 L15 10.5" />
    </svg>
  )
}

function Thema({ k, nummer }: { k: EbKommtThema; nummer?: number }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <div className="eb-s3v3-thema" data-testid="eb-s3-thema">
      <p className="eb-s3v3-thema-titel">
        {nummer !== undefined && <span className="eb-s3v3-nr">{nummer}</span>}
        {k.titel}
      </p>
      {k.halbjahr && <p className="eb-s3v3-wann">{t('s3.v3.halbjahr', { halbjahr: k.halbjahr })}</p>}
    </div>
  )
}

/** Variante A: oben alle Stärken, darunter alle Lücken; die Themen einmal rechts. */
function LayoutA({ lw, liste }: { lw: EbLueckenweg; liste: Liste }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const nr = (k: EbKommtThema): number => lw.themen.indexOf(k) + 1
  const kasten = (k: EbKommtThema, art: 'sitzt' | 'fehlt'): JSX.Element => (
    <div key={`${art}-${k.titel}`} className="eb-s3v3-zeile-a" data-testid={`eb-s3-${art}`}>
      <div className={`eb-s3v3-kasten eb-s3v3-${art}`}>
        <p className="eb-s3v3-fuer">
          <span className="eb-s3v3-nr">{nr(k)}</span>
          {k.titel}
        </p>
        <Bereiche
          liste={liste}
          eintraege={art === 'sitzt' ? k.sitzt : k.fehlt}
          rest={art === 'sitzt' ? k.restSitzt : k.restFehlt}
        />
      </div>
      <Pfeil art={art} />
    </div>
  )
  const mitSitzt = lw.themen.filter((k) => k.sitzt.length > 0)
  const mitFehlt = lw.themen.filter((k) => k.fehlt.length > 0)
  return (
    <section className="eb-s3v3-a" data-testid="eb-s3-wege">
      <div className="eb-s3v3-links">
        {mitSitzt.length > 0 && <p className="eb-s3v3-spalte">{t('s3.v3.sitzt')}</p>}
        {mitSitzt.map((k) => kasten(k, 'sitzt'))}
        {mitFehlt.length > 0 && <p className="eb-s3v3-spalte eb-s3v3-spalte-fehlt">{t('s3.v3.fehlt')}</p>}
        {mitFehlt.map((k) => kasten(k, 'fehlt'))}
      </div>
      <div className="eb-s3v3-rechts">
        <p className="eb-s3v3-spalte">{t('s3.v3.kommt')}</p>
        {lw.themen.map((k) => (
          <Thema key={k.titel} k={k} nummer={nr(k)} />
        ))}
      </div>
    </section>
  )
}

/** Variante B: je Thema eine Zeile — grün · rot → blau. */
function LayoutB({ lw, liste }: { lw: EbLueckenweg; liste: Liste }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <section className="eb-s3v3-b" data-testid="eb-s3-wege">
      <div className="eb-s3v3-kopf" aria-hidden="true">
        <span>{t('s3.v3.sitzt')}</span>
        <span>{t('s3.v3.fehlt')}</span>
        <span />
        <span>{t('s3.v3.kommt')}</span>
      </div>
      {lw.themen.map((k) => (
        <div key={k.titel} className="eb-s3v3-zeile-b" data-testid="eb-s3-zeile">
          <div className={k.sitzt.length > 0 ? 'eb-s3v3-kasten eb-s3v3-sitzt' : 'eb-s3v3-leer'} data-testid="eb-s3-sitzt">
            {k.sitzt.length > 0 && <Bereiche liste={liste} eintraege={k.sitzt} rest={k.restSitzt} />}
          </div>
          <div className={k.fehlt.length > 0 ? 'eb-s3v3-kasten eb-s3v3-fehlt' : 'eb-s3v3-leer'} data-testid="eb-s3-fehlt">
            {k.fehlt.length > 0 && <Bereiche liste={liste} eintraege={k.fehlt} rest={k.restFehlt} />}
          </div>
          <Pfeil art={k.fehlt.length > 0 ? 'fehlt' : 'sitzt'} />
          <Thema k={k} />
        </div>
      ))}
    </section>
  )
}

function Weitere({ lw }: { lw: EbLueckenweg }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <section className="eb-s3v2-weitere" data-testid="eb-s3-weitere">
      <h2 className="eb-kicker">{t('s3.v2.weitereKicker')}</h2>
      <p className="eb-s3v2-leise">{t('s3.v3.weitereIntro')}</p>
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
