import { useTranslation } from 'react-i18next'

import { Seite1Kaesten } from './Seite1Kaesten'
import { Seite1Karten } from './Seite1Karten'
import { Weg } from './Weg'
import type { SeitenProps } from './seitenProps'

/**
 * Seite 1 des Eltern-Berichts R7: Überblick (Maßblatt E7, „Seite 1“).
 *
 * Von oben nach unten im Fluss: Kicker, Überschrift, Kopfdaten, „Auf einen
 * Blick“ mit drei Karten, Anliegen und Prüfweg, der Weg durch den Bericht.
 * Fehlt ein Datum, entfällt der Satz still (Entscheidung 9).
 */
export function Seite1({ data, bericht, satz, name, wessen }: SeitenProps): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const { zaehlung } = bericht

  // Überschrift: abgenommener Kopfsatz, sonst die neutrale Ersatzüberschrift.
  const titel =
    satz.waehle('kopf', bericht.kopfFall, data.sessionId, { name: name ?? t('kind') }) ??
    (name ? t('s1.kopfErsatz', { name }) : t('s1.kopfErsatzOhneName'))

  // Rückbezüge wie in ReportRueckbezug (R6), ohne Marken.
  const rueckbezuege = data.erzaehlung.rueckbezuege
    .map((r) => ({
      thema: r.thema,
      text: satz.waehle('rueckbezug', r.fall, `${data.sessionId} ${r.thema}`, {
        belege: r.belege,
      }),
    }))
    .filter((r): r is { thema: string; text: string } => r.text !== null)

  const datum = data.analysedAt
    ? new Intl.DateTimeFormat(i18n.language, {
        dateStyle: 'long',
        timeZone: 'Europe/Berlin',
      }).format(new Date(data.analysedAt))
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
    <div className="eb-s1">
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

      <p className="eb-kicker eb-s1-blick-kicker">{t('s1.blick.kicker')}</p>
      <p className="eb-s1-zeile">
        {t('s1.blick.zeile', {
          untersucht: zaehlung.untersucht,
          katalog: zaehlung.katalog,
          sicher: zaehlung.sicher,
          uebung: zaehlung.uebung,
          offen: zaehlung.offen,
        })}
      </p>

      <Seite1Karten bericht={bericht} />

      <Seite1Kaesten
        data={data}
        zaehlung={zaehlung}
        wessen={wessen}
        rueckbezuege={rueckbezuege}
      />

      {/* Bei mehr als einem Rückbezug fehlt der Platz (Bauauftrag, Entscheidung 10). */}
      {rueckbezuege.length <= 1 && <Weg />}
    </div>
  )
}
