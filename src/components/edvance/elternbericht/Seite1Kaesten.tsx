import { useTranslation } from 'react-i18next'

import type { ThemaAbdeckung } from '@/lib/report/elternbericht/themaAbdeckung'
import type { EbZaehlung, ReportData } from '@/types'

import { themaSaetze } from './themaSatz'

/**
 * Zwei Kästen nebeneinander, gleich hoch: links das Anliegen der Eltern,
 * rechts, wie geprüft wurde.
 *
 * Der linke Kasten nennt, was die Eltern angegeben haben, das nächste Thema
 * und die Antwort der Analyse darauf (Rückbezüge). Gibt es nichts davon,
 * entfällt er und der rechte steht in voller Breite — ein leerer Kasten läse
 * sich wie „nichts angegeben“.
 *
 * Rechts bei der abgestuften LSA mit Thema zusätzlich der Thema-Satz: wie viele
 * Bereiche zum Thema gehören, wie viele direkt geprüft wurden und wie viele
 * sich daraus ergeben (R7-6, Entscheidung 7). Nur dort zählen abgeleitete Urteile.
 */
export function Seite1Kaesten({
  data,
  zaehlung,
  thema,
  abdeckung,
  wessen,
  rueckbezuege,
}: {
  data: ReportData
  zaehlung: EbZaehlung
  thema: string | null
  abdeckung: ThemaAbdeckung | null
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
          {thema
            ? t('s1.geprueft.text', { thema, untersucht: zaehlung.untersucht })
            : t('s1.geprueft.textOhneThema', { untersucht: zaehlung.untersucht })}
        </p>
        {abdeckung && (
          <p className="eb-s1-geprueft-thema" data-testid="eb-thema-satz">
            {themaSaetze(t, abdeckung).map((s, i) => (
              <span key={i}>
                {i > 0 && ' '}
                {s}
              </span>
            ))}
          </p>
        )}
        <p className="eb-s1-geprueft-hinweis">
          {t(abdeckung ? 's1.geprueft.hinweisThema' : 's1.geprueft.hinweis')}
        </p>
      </section>
    </div>
  )
}
