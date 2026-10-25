import { useTranslation } from 'react-i18next'

import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import { bereicheAus } from '@/lib/report/elternbericht/bereiche'
import { stufeVon } from '@/lib/report/elternbericht/plan'
import { ursachenAntworten } from '@/lib/report/elternbericht/ursache'

import {
  anliegenSaetzeV2,
  lueckenFelder,
  startSatz,
  stufenKlasse,
  stufenUrteil,
  ursachenSaetze,
} from './berichtSaetze'
import { FahrplanSeite1 } from './FahrplanSeite1'
import type { SeitenProps } from './seitenProps'
import { useStufe } from './useStufe'

/** Stufen des Verdichtens von Seite 1 mit Fahrplan. */
const STUFEN_V4 = 2

/**
 * Seite 1 des Eltern-Berichts (v2): Überblick.
 *
 * Von oben nach unten: Kicker, Überschrift, Kopfdaten, „Ihr Anliegen“ mit der
 * Antwort der Analyse und „So gehen wir vor“ (fester Text für alle Berichte),
 * dann „Auf einen Blick“: eine Zeile je Klassenstufe, wo die Lücken liegen,
 * womit wir beginnen. Keine Listen einzelner Bereiche. Fehlt ein Datum,
 * entfällt sein Satz still.
 *
 * Bericht v4 (mit bericht.fahrplan): statt „Wir beginnen mit …“ der Fahrplan
 * der Klassenarbeiten mit einem Signal je Arbeit (FahrplanSeite1); der Satz zum
 * Sorgfalts-Muster steht im Anliegen-Kasten unter „Was die Analyse dazu zeigt“.
 */
export function Seite1({ data, bericht, satz, name, vollerName, wessen }: SeitenProps): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const { zaehlung } = bericht
  const stufen = bericht.stufen ?? []
  const fahrplan = bericht.fahrplan ?? null
  // Bericht v4: Läuft die Seite mit dem Fahrplan über, rückt sie enger zusammen (seite1 v4-rahmen.css).
  const dicht = useStufe(fahrplan ? STUFEN_V4 : 0)
  const liste = (s: readonly string[]): string =>
    new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(s)

  const titel =
    satz.waehle('kopf', bericht.kopfFall, data.sessionId, { name: vollerName ?? t('kind') }) ??
    (vollerName ? t('s1.kopfErsatz', { name: vollerName }) : t('s1.kopfErsatzOhneName'))

  const muster = fehlermusterAus(data.fehlbilder)
  const anliegen = anliegenSaetzeV2(t, {
    erstgespraech: data.erstgespraech ?? null,
    ursachen: data.erzaehlung.anlassNamen,
    fach: data.subject,
    liste,
  })
  const antwort = ursachenSaetze(
    t,
    ursachenAntworten({
      genannt: data.parentAssessment?.weakTopics ?? [],
      stufen,
      bereiche: bereicheAus(data.erzaehlung.kompetenzen),
      fehlbilder: data.fehlbilder,
      muster,
    }),
    stufen,
    name,
  )

  const felder = lueckenFelder(bericht.profil)
  const start = startSatz(t, bericht.schwerpunkte[0], bericht.gruende?.[0])
  // v4: Der Sorgfalt-Satz gehört in den Anliegen-Kasten, wenn es ihn gibt.
  const sorgfaltImKasten = fahrplan !== null && muster?.sorgfalt === true && anliegen.length > 0
  const antworten = sorgfaltImKasten
    ? [...antwort, t(name ? 'v4.s1.sorgfalt' : 'v4.s1.sorgfaltOhneName', { name })]
    : antwort
  const blickSaetze = [
    felder.length === 1 && t('s1.blick.luecken', { felder: t(`feldMit.${felder[0]}`) }),
    felder.length === 2 &&
      t('s1.blick.lueckenZwei', { erstes: t(`feldMit.${felder[0]}`), zweites: t(`feldMit.${felder[1]}`) }),
    muster?.sorgfalt && !sorgfaltImKasten && t('s1.blick.muster'),
  ].filter(Boolean)

  const datum = data.analysedAt
    ? new Intl.DateTimeFormat(i18n.language, { dateStyle: 'long', timeZone: 'Europe/Berlin' }).format(
        new Date(data.analysedAt),
      )
    : null
  const meta: { key: string; label: string; wert: string }[] = [
    {
      key: 'klasse',
      label: t('s1.meta.klasse'),
      wert: data.schulform
        ? t('s1.meta.klasseSchulform', { klasse: data.grade, schulform: data.schulform })
        : String(data.grade),
    },
    { key: 'fach', label: t('s1.meta.fach'), wert: data.subject },
    { key: 'umfang', label: t('s1.meta.umfang'), wert: t('s1.meta.aufgaben', { count: data.aufgaben }) },
    ...(datum ? [{ key: 'datum', label: t('s1.meta.datum'), wert: datum }] : []),
  ]

  return (
    <div
      className={fahrplan ? 'eb-s1 eb-s1-v4' : 'eb-s1'}
      ref={dicht.ref}
      data-stufe={dicht.wert || undefined}
      data-v4={fahrplan ? true : undefined}
    >
      <p className="eb-kicker eb-s1-kicker">{t('s1.kicker', { fach: data.subject })}</p>
      <h1 className="eb-titel eb-s1-titel">{titel}</h1>

      <dl className="eb-s1-meta">
        {meta.map((m) => (
          <div key={m.key} className="eb-s1-meta-spalte">
            <dt>{m.label}</dt>
            <dd>{m.wert}</dd>
          </div>
        ))}
      </dl>

      <div className={anliegen.length > 0 ? 'eb-s1-kaesten' : 'eb-s1-kaesten eb-s1-kaesten-voll'}>
        {anliegen.length > 0 && (
          <section className="eb-s1-kasten eb-s1-anliegen" data-testid="eb-anliegen">
            <h2 className="eb-kicker">{t('s1.anliegen.kicker')}</h2>
            <p className="eb-s1-anliegen-satz">{anliegen.join(' ')}</p>
            {antworten.length > 0 && (
              <div className="eb-s1-antwort" data-testid="eb-antwort">
                <h3 className="eb-s1-antwort-kicker">{t('s1.anliegen.antwortKicker')}</h3>
                <p className="eb-s1-antwort-satz">{antworten.join(' ')}</p>
              </div>
            )}
          </section>
        )}
        <section className="eb-s1-kasten eb-s1-geprueft" data-testid="eb-geprueft">
          <h2 className="eb-kicker">{t('s1.systematik.kicker')}</h2>
          <p className="eb-s1-geprueft-text">
            {t('s1.systematik.start')} {t(`s1.systematik.stufen.${stufeVon(data.grade)}`, { klasse: data.grade })}
          </p>
          <p className="eb-s1-geprueft-hinweis">{t('s1.systematik.seiten')}</p>
        </section>
      </div>

      <section className="eb-s1-blick" data-testid="eb-blick">
        <h2 className="eb-kicker eb-s1-blick-kicker">{t('s1.blick.kicker')}</h2>
        <ul className="eb-s1-stufen" data-testid="eb-stufen">
          {stufen.map((z) => (
            <li
              key={z.stufe}
              className={`eb-s1-stufe eb-s1-stufe-${z.urteil}`}
              aria-label={t('s1.stufen.aria', { stufe: stufenKlasse(t, z), sicher: z.sicher, uebung: z.uebung })}
            >
              <span className="eb-s1-stufe-name">
                {t(`s1.stufen.name.${z.stufe}`)}
                <small>{stufenKlasse(t, z)}</small>
              </span>
              <span className="eb-s1-stufe-punkte" aria-hidden="true">
                {Array.from({ length: z.sicher }, (_, i) => (
                  <span key={`s${i}`} className="eb-s1-punkt eb-s1-punkt-sicher" />
                ))}
                {Array.from({ length: z.uebung }, (_, i) => (
                  <span key={`u${i}`} className="eb-s1-punkt eb-s1-punkt-uebung" />
                ))}
              </span>
              <span className="eb-s1-stufe-urteil">{stufenUrteil(t, z)}</span>
            </li>
          ))}
        </ul>
        <p className="eb-s1-zeile">
          {t('s1.blick.zeile', { untersucht: zaehlung.untersucht, sicher: zaehlung.sicher, uebung: zaehlung.uebung })}
        </p>
        {blickSaetze.length > 0 && (
          <p className="eb-s1-blick-satz" data-testid="eb-luecken-satz">
            {blickSaetze.join(' ')}
          </p>
        )}
        {!fahrplan && (
          <p className="eb-s1-blick-satz eb-s1-start" data-testid="eb-start">
            {start ?? t('s1.blick.ansatzKeiner')}
          </p>
        )}
      </section>

      {fahrplan && <FahrplanSeite1 fahrplan={fahrplan} wessen={wessen} />}
    </div>
  )
}
