import { useTranslation } from 'react-i18next'

import type { ReportData } from '@/types'

import { NAME_MAX } from './namensMessung'
import { Seite } from './Seite'

/**
 * Der ganze Bogen einer nicht auswertbaren LSA (LSA-R2): eine Seite, nur der
 * Kopf von Seite 1 und ein sachlicher Kasten. Keine Zahlen, kein Profil, kein
 * Lernweg, kein Förderansatz, keine Paketempfehlung — so kurze Antwortzeiten
 * zeigen nicht, was das Kind kann.
 *
 * Kopfdaten wie Seite 1, ohne „Umfang“ (eine Aufgabenzahl wäre ein Ergebnis).
 * Der Rufname steht bis NAME_MAX Zeichen; gemessen wird nicht, die Seite hat
 * Platz genug.
 */
export function NichtAuswertbarSeite({ data }: { data: ReportData }): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const rufname = data.firstName?.trim() || null
  const name = rufname && [...rufname].length <= NAME_MAX ? rufname : null

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
    ...(datum ? [{ key: 'datum', label: t('s1.meta.datum'), wert: datum }] : []),
  ]

  return (
    <div className="eb-bogen" data-testid="eb-nicht-auswertbar">
      <Seite nummer={1} gesamt={1} testlauf={data.testlauf} name={name}>
        <div className="eb-s1">
          <p className="eb-kicker eb-s1-kicker">{t('s1.kicker', { fach: data.subject })}</p>
          <h1 className="eb-titel eb-s1-titel">
            {name ? t('nichtAuswertbar.titel', { name }) : t('nichtAuswertbar.titelOhneName')}
          </h1>

          <dl className="eb-s1-meta">
            {meta.map((m) => (
              <div key={m.key} className="eb-s1-meta-spalte">
                <dt>{m.label}</dt>
                <dd>{m.wert}</dd>
              </div>
            ))}
          </dl>

          <div className="eb-s1-kaesten eb-s1-kaesten-voll">
            <section className="eb-s1-kasten eb-s1-geprueft">
              <h2 className="eb-kicker">{t('nichtAuswertbar.kicker')}</h2>
              <p className="eb-s1-geprueft-text">
                {t('nichtAuswertbar.text', { name: name ?? t('kind') })}
              </p>
            </section>
          </div>
        </div>
      </Seite>
    </div>
  )
}
