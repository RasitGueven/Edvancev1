import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import { Mitgliedschaften } from './Mitgliedschaften'
import { paketWahl } from './seite5Rechnung'
import type { SeitenProps } from './seitenProps'

/**
 * Seite 5 des Eltern-Berichts R7: Einschätzung, Mitgliedschaften und
 * Ansprechpartner (Maßblatt E7, „Seite 5“). Kein Preis, keine Laufzeit, keine
 * Vertragsangabe.
 */
export function Seite5({ data, notes, tiers, name }: SeitenProps): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const { pakete, vorschlag, eindeutig } = paketWahl(tiers, notes?.paket)

  useEffect(() => {
    if (pakete.length > 0 && !eindeutig) {
      console.warn(
        `elternbericht: ${pakete.length} active tiers instead of 3 — no card highlighted`,
      )
    }
  }, [pakete.length, eindeutig])

  const merkmal = vorschlag?.features[0]
  const empfehlung = notes?.empfehlung.trim() || null
  const zeile = [
    vorschlag &&
      (merkmal
        ? t('s5.vorschlag.zeile', { paket: vorschlag.name, merkmal })
        : t('s5.vorschlag.zeileOhneMerkmal', { paket: vorschlag.name })),
    empfehlung,
  ].filter((s): s is string => Boolean(s))

  const kontakt = data.erzaehlung.ansprechpartner
  const kontaktName = kontakt.name?.trim() || null
  const mail = kontaktName ? kontakt.email : t('s5.kontakt.mail')

  return (
    <div className="eb-s5">
      <p className="eb-kicker eb-s5-kicker">{t('s5.kicker')}</p>
      <h1 className="eb-titel eb-s5-titel">{t('s5.titel', { name: name ?? t('kind') })}</h1>
      <p className="eb-s5-intro">{t('s5.intro')}</p>

      <section className="eb-s5-vorschlag" data-testid="eb-vorschlag">
        <p className="eb-s5-vorschlag-chip">{t('s5.vorschlag.chip')}</p>
        <h2 className="eb-titel eb-s5-vorschlag-titel">
          {name ? t('s5.vorschlag.titel', { name }) : t('s5.vorschlag.titelOhneName')}
        </h2>
        {zeile.length > 0 && (
          <p className="eb-s5-vorschlag-zeile" data-testid="eb-vorschlag-zeile">
            {zeile.map((s, i) => (
              <span key={i}>
                {i > 0 && ' '}
                {s}
              </span>
            ))}
          </p>
        )}
      </section>

      {pakete.length > 0 && <Mitgliedschaften pakete={pakete} vorschlag={vorschlag} />}

      <section className="eb-s5-kontakt" data-testid="eb-kontakt">
        <div className="eb-s5-kontakt-person">
          <h2 className="eb-kicker">{t('s5.kontakt.kicker')}</h2>
          <p className="eb-titel eb-s5-kontakt-name">{kontaktName ?? t('s5.kontakt.team')}</p>
          {kontaktName && <p className="eb-s5-kontakt-rolle">{t('s5.kontakt.rolle')}</p>}
          {mail && (
            <a className="eb-s5-kontakt-mail" href={`mailto:${mail}`}>
              {mail}
            </a>
          )}
        </div>
        <div className="eb-s5-kontakt-fragen">
          <h2 className="eb-kicker">{t('s5.fragen.kicker')}</h2>
          <p className="eb-s5-fragen-text">{t('s5.fragen.text')}</p>
        </div>
      </section>
    </div>
  )
}
