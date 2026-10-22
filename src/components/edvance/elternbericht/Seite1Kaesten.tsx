import { useTranslation } from 'react-i18next'

import type { ThemaAbdeckung } from '@/lib/report/elternbericht/themaAbdeckung'
import type { EbAnliegen, EbZaehlung } from '@/types'

import { baueListe } from './liste'
import { anliegenSaetze } from './seite1Saetze'
import { themaSaetze } from './themaSatz'

/**
 * Zwei Kästen nebeneinander, gleich hoch: links das Anliegen der Eltern,
 * rechts, wie geprüft wurde.
 *
 * Links Frage und Antwort (R7-11, Entscheidung 12): das Thema der LSA und wo es
 * dort hakt, die fachlichen Anliegen und wo wir ansetzen, dazu die Rückbezüge,
 * die antworten. Überfachliche Anliegen erscheinen nicht. Ist nichts zu sagen,
 * entfällt der Kasten und der rechte steht in voller Breite — ein leerer Kasten
 * läse sich wie „nichts angegeben“.
 *
 * Rechts bei der abgestuften LSA mit Thema zusätzlich der Thema-Satz: wie viele
 * Bereiche zum Thema gehören, wie viele direkt geprüft wurden und wie viele
 * sich daraus ergeben (R7-6, Entscheidung 7). Nur dort zählen abgeleitete Urteile.
 */
export function Seite1Kaesten({
  zaehlung,
  thema,
  abdeckung,
  anliegen,
  wessen,
  rueckbezuege,
}: {
  zaehlung: EbZaehlung
  thema: string | null
  abdeckung: ThemaAbdeckung | null
  anliegen: EbAnliegen | null
  wessen: string | null
  rueckbezuege: { thema: string; text: string }[]
}): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const saetze = anliegen ? anliegenSaetze(t, anliegen, wessen, baueListe(t, i18n.language), i18n.language) : []

  return (
    <div className={anliegen ? 'eb-s1-kaesten' : 'eb-s1-kaesten eb-s1-kaesten-voll'}>
      {anliegen && (
        <section className="eb-s1-kasten eb-s1-anliegen" data-testid="eb-anliegen">
          <h2 className="eb-kicker">{t('s1.anliegen.kicker')}</h2>
          <p className="eb-s1-anliegen-satz">{saetze.join(' ')}</p>
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
