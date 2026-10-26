import { Fragment, useMemo } from 'react'
import { Trans, useTranslation } from 'react-i18next'

import { kaSatz, kaTeile } from '@/lib/report/elternbericht/kaSatz'
import { duenneLueckenweg } from '@/lib/report/elternbericht/lueckenweg'
import type { EbFahrplan, EbKommtThema, EbStation, Elternbericht, KlassenarbeitStatus } from '@/types'

import { schuleGenitiv } from './berichtSaetze'
import { signalText, standZeile, tonVon } from './fahrplanText'
import type { SeitenProps } from './seitenProps'
import { useAusduennen } from './useAusduennen'

/**
 * Seite 3 des Eltern-Berichts (Bericht v4, Layout B): ein Block je Klassenarbeit.
 *
 * Über den Blöcken ein Satz, der auf die Angaben der Familie eingeht (hellblauer
 * Kasten mit Haken). Je kommender Arbeit mit Signal ein Block mit allen
 * Bereichen, die das Thema betreffen („Sitzt schon“ / „Fehlt noch“); ein Bereich
 * kann in mehreren Blöcken stehen. Darunter „Weitere Stärken“ und „Wird später
 * wichtig“. Läuft die Seite über, dünnt sie aus wie in v3 (useAusduennen).
 */
export function Seite3V4({ data, bericht }: SeitenProps): JSX.Element | null {
  const { t } = useTranslation('elternbericht')
  const voll = bericht.lueckenwegV4 ?? null
  const fahrplan = bericht.fahrplan ?? null
  const a = useAusduennen(voll)
  const lw = useMemo(() => (voll ? duenneLueckenweg(voll, a.stufe) : null), [voll, a.stufe])
  if (!lw || !fahrplan) return null

  const stationVon = (k: EbKommtThema): EbStation | undefined =>
    fahrplan.stationen.find((s) => s.nummer > 1 && s.titel === k.titel)
  const quelle =
    lw.quelle === 'klp'
      ? t('s3.v2.quelleKlp')
      : lw.schulname
        ? t('s3.v2.quelleSchule', { schule: schuleGenitiv(t, lw.schulname) })
        : t('s3.v2.quelleSchuleOhneName')
  const staerkenRest = lw.weitereStaerkenRest ?? 0
  const spaeter = lw.weitere.flatMap((g) => g.labels)
  const spaeterRest = lw.weitere.reduce((n, g) => n + (g.rest ?? 0), 0)

  return (
    <div className="eb-s3 eb-s3v4" ref={a.ref} data-stufe={a.stufe || undefined} data-layout="B" data-v4 data-testid="eb-s3">
      <p className="eb-kicker eb-s3-kicker">{t('v4.s3.kicker')}</p>
      <h1 className="eb-titel eb-s3-titel">{t('v4.s3.titel')}</h1>

      <Einstieg
        bericht={bericht}
        fahrplan={fahrplan}
        status={data.erstgespraech?.klassenarbeit ?? null}
        note={data.erstgespraech?.letzteNote ?? null}
      />

      <div className="eb-s3v4-bloecke">
        {lw.themen.map((k) => {
          const s = stationVon(k)
          const ton = s ? tonVon(s) : 'fehlt'
          return (
            <section key={k.titel} className="eb-s3v4-block" data-testid="eb-s3-block">
              <header className="eb-s3v4-kopf">
                <span className={`eb-s3v4-nr eb-ton-${ton}`} aria-hidden="true">
                  {s?.nummer}
                </span>
                <div className="eb-s3v4-titel">
                  <h2>{s ? t('v4.s3.blockTitel', { n: s.nummer, thema: k.titel }) : k.titel}</h2>
                  {s && <p>{standZeile(t, s)}</p>}
                </div>
                {s && (
                  <span className={`eb-s3v4-chip eb-ton-${ton}`} data-testid="eb-s3-signal">
                    {signalText(t, s)}
                  </span>
                )}
              </header>
              <div className="eb-s3v4-rumpf">
                {k.sitzt.length > 0 && (
                  <div className="eb-s3v4-spalte eb-s3v4-ja" data-testid="eb-s3-sitzt">
                    <h3>{t('v4.s3.sitzt')}</h3>
                    <Liste labels={k.sitzt.map((z) => z.label)} rest={k.restSitzt} />
                  </div>
                )}
                {k.fehlt.length > 0 && (
                  <div className="eb-s3v4-spalte eb-s3v4-nein" data-testid="eb-s3-fehlt">
                    <h3>{t('v4.s3.fehlt')}</h3>
                    <Liste labels={k.fehlt.map((z) => z.label)} rest={k.restFehlt} />
                  </div>
                )}
              </div>
            </section>
          )
        })}
      </div>

      {(lw.weitereStaerken.length > 0 || staerkenRest > 0 || spaeter.length > 0 || spaeterRest > 0) && (
        <div className="eb-s3v4-rest">
          {(lw.weitereStaerken.length > 0 || staerkenRest > 0) && (
            <section className="eb-s3v4-kasten eb-s3v4-staerken" data-testid="eb-s3-weitere-staerken">
              <h2 className="eb-kicker">{t('v4.s3.weitereStaerken')}</h2>
              <Chips labels={lw.weitereStaerken} rest={staerkenRest} />
            </section>
          )}
          {(spaeter.length > 0 || spaeterRest > 0) && (
            <section className="eb-s3v4-kasten eb-s3v4-spaeter" data-testid="eb-s3-weitere">
              <h2 className="eb-kicker">{t('v4.s3.spaeter')}</h2>
              <p className="eb-s3v4-intro">{t('v4.s3.spaeterIntro')}</p>
              <Chips labels={spaeter} rest={spaeterRest} />
            </section>
          )}
        </div>
      )}

      <p className="eb-s3-hinweis">{t('s3.v2.hinweis', { quelle })}</p>
    </div>
  )
}

/**
 * Der Satz, der auf die Angaben der Familie eingeht (V4 Entscheidung 4): LSA-L4 Teil D nach dem Stand der
 * Klassenarbeit beim LSA-Start (kaSatz), danach der Satz zum Aufbau der Seite.
 */
function Einstieg({
  bericht,
  fahrplan,
  status,
  note,
}: {
  bericht: Elternbericht
  fahrplan: EbFahrplan
  status: KlassenarbeitStatus | null
  note: number | null
}): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const satz = kaSatz(bericht, status, note)
  const aktuell = fahrplan.stationen[0]
  const n = fahrplan.stationen[1]?.nummer ?? aktuell.nummer + 1
  return (
    <div className="eb-s3v4-einstieg" data-testid="eb-s3-einstieg" data-ka={satz?.fall}>
      <svg viewBox="0 0 16 16" aria-hidden="true">
        <circle cx="8" cy="8" r="8" />
        <path d="M4.6 8.3 L7 10.6 L11.5 5.6" />
      </svg>
      <p>
        {satz &&
          kaTeile(satz, i18n.language, (label) => t('v4.s3.ka.bereich', { label })).map((teil) => (
            <Fragment key={teil.key}>
              <Trans t={t} i18nKey={`v4.s3.ka.${teil.key}`} values={teil.values} components={{ b: <b /> }} />{' '}
            </Fragment>
          ))}
        {t(status === 'geschrieben' ? 'v4.s3.rest.geschrieben' : 'v4.s3.rest.steht', { n })}
      </p>
    </div>
  )
}

function Liste({ labels, rest }: { labels: string[]; rest?: number }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <ul className="eb-s3v4-bereiche">
      {labels.map((l) => (
        <li key={l}>{l}</li>
      ))}
      {(rest ?? 0) > 0 && <li className="eb-s3v4-mehr">{t('s3.v2.undWeitere', { count: rest })}</li>}
    </ul>
  )
}

function Chips({ labels, rest }: { labels: string[]; rest: number }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <ul className="eb-s3v4-chips">
      {labels.map((l) => (
        <li key={l}>{l}</li>
      ))}
      {rest > 0 && <li className="eb-s3v4-chips-mehr">{t('s3.v2.undWeitere', { count: rest })}</li>}
    </ul>
  )
}
