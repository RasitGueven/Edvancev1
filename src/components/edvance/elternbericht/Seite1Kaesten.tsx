import { useTranslation } from 'react-i18next'

import type { EbZaehlung, ReportData } from '@/types'

/**
 * Zwei Kästen nebeneinander, gleich hoch: links das Anliegen der Eltern,
 * rechts, wie geprüft wurde.
 *
 * Der linke Kasten nennt, was die Eltern angegeben haben, das nächste Thema
 * und die Antwort der Analyse darauf (Rückbezüge). Gibt es nichts davon,
 * entfällt er und der rechte steht in voller Breite — ein leerer Kasten läse
 * sich wie „nichts angegeben“.
 */
export function Seite1Kaesten({
  data,
  zaehlung,
  wessen,
  rueckbezuege,
}: {
  data: ReportData
  zaehlung: EbZaehlung
  wessen: string | null
  rueckbezuege: { thema: string; text: string }[]
}): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const punkte = data.erzaehlung.anlassNamen
  const liste = new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(punkte)
  const mitAnliegen = punkte.length > 0 || Boolean(data.naechstesThema) || rueckbezuege.length > 0

  return (
    <div className={mitAnliegen ? 'eb-s1-kaesten' : 'eb-s1-kaesten eb-s1-kaesten-voll'}>
      {mitAnliegen && (
        <section className="eb-s1-kasten eb-s1-anliegen" data-testid="eb-anliegen">
          <h2 className="eb-kicker">{t('s1.anliegen.kicker')}</h2>
          {punkte.length > 0 && (
            <p className="eb-s1-anliegen-satz">
              {wessen
                ? t('s1.anliegen.genannt', { wessen, punkte: liste })
                : t('s1.anliegen.genanntOhneName', { punkte: liste, count: punkte.length })}
            </p>
          )}
          {data.naechstesThema && (
            <p className="eb-s1-anliegen-thema">
              {t('s1.anliegen.thema', { thema: data.naechstesThema })}
            </p>
          )}
          {rueckbezuege.length > 0 && (
            <ul className="eb-s1-rueckbezuege">
              {rueckbezuege.map((r) => (
                <li key={r.thema}>{r.text}</li>
              ))}
            </ul>
          )}
        </section>
      )}
      <section className="eb-s1-kasten eb-s1-geprueft" data-testid="eb-geprueft">
        <h2 className="eb-kicker">{t('s1.geprueft.kicker')}</h2>
        <p className="eb-s1-geprueft-text">
          {t('s1.geprueft.text', {
            untersucht: zaehlung.untersucht,
            katalog: zaehlung.katalog,
            klasse: zaehlung.bisKlasse,
          })}
        </p>
        {zaehlung.offen > 0 && (
          <p className="eb-s1-geprueft-hinweis">
            {t('s1.geprueft.hinweis', { count: zaehlung.offen })}
          </p>
        )}
      </section>
    </div>
  )
}
