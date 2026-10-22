import { useTranslation } from 'react-i18next'

import type { EbBereich, Elternbericht } from '@/types'

import { baueListe, schwerpunktTitel } from './liste'
import { ansatzThemaSaetze } from './seite1Saetze'

/** Höchstens so viele Einträge je Liste; der Rest steht als „+n weitere“. */
const EINTRAEGE = 4

/**
 * „Auf einen Blick“: was klappte, wo es Übung braucht, der erste Ansatz.
 *
 * Die Listen kommen sortiert aus der Rechnung (Themenfeld, Klasse, Label; mit
 * Thema die Bereiche des Themas zuerst). Der erste Ansatz ist Schwerpunkt 1 —
 * derselbe, den Seite 4 als ersten nennt; mit Thema ist das das Thema (R7-11).
 */
export function Seite1Karten({ bericht, name }: { bericht: Elternbericht; name: string | null }): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const erster = bericht.schwerpunkte[0] ?? null
  const liste = baueListe(t, i18n.language)

  return (
    <div className="eb-s1-karten">
      <Liste
        art="sicher"
        titel={t('s1.blick.sicher')}
        bereiche={bericht.sicherListe}
        leer={t('s1.blick.keinSicher')}
      />
      <Liste
        art="uebung"
        titel={t('s1.blick.uebung')}
        bereiche={bericht.uebungListe}
        leer={t('s1.blick.keineUebung')}
      />
      <section className="eb-s1-karte eb-s1-karte-ansatz" data-testid="eb-ansatz">
        <h2 className="eb-s1-karte-kopf">{t('s1.blick.ansatz')}</h2>
        {erster ? (
          <>
            <div className="eb-s1-ansatz-kopf">
              <span className="eb-s1-ansatz-kreis" aria-hidden="true">
                1
              </span>
              <p className="eb-s1-ansatz-titel">{schwerpunktTitel(t, erster)}</p>
            </div>
            <p className="eb-s1-ansatz-text">
              {/* Mit Thema die konkreten Sätze (R7-11, Entscheidung 8), sonst die Bausteine. */}
              {erster.thema
                ? ansatzThemaSaetze(t, erster, name, liste).join(' ')
                : t(erster.gemischt ? 's1.blick.ansatzGemischt' : 's1.blick.ansatzUebung')}
            </p>
          </>
        ) : (
          <p className="eb-s1-ansatz-text eb-s1-ansatz-keiner">{t('s1.blick.ansatzKeiner')}</p>
        )}
      </section>
    </div>
  )
}

function Liste({
  art,
  titel,
  bereiche,
  leer,
}: {
  art: 'sicher' | 'uebung'
  titel: string
  bereiche: EbBereich[]
  leer: string
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const rest = bereiche.length - EINTRAEGE

  return (
    <section className={`eb-s1-karte eb-s1-karte-${art}`} data-testid={`eb-liste-${art}`}>
      <h2 className="eb-s1-karte-kopf">{titel}</h2>
      {bereiche.length === 0 ? (
        <p className="eb-s1-leer">{leer}</p>
      ) : (
        <ul className="eb-s1-liste">
          {bereiche.slice(0, EINTRAEGE).map((b) => (
            <li key={b.skillKey}>{b.label}</li>
          ))}
        </ul>
      )}
      {rest > 0 && <p className="eb-s1-weitere">{t('s1.blick.weitere', { count: rest })}</p>}
    </section>
  )
}
