import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import { KONTAKT } from '@/lib/report/elternbericht/berichtKonfig'
import { paketVorschlag } from '@/lib/report/elternbericht/paketVorschlag'

import { Mitgliedschaften } from './Mitgliedschaften'
import { paketWahl } from './seite5Rechnung'
import type { SeitenProps } from './seitenProps'

/**
 * Seite 5 des Eltern-Berichts (v2): Pakete, Vorschlag, Ziele, Kontakt.
 *
 * Ein Paket ist vorausgewählt: der Vorschlag des Systems (paketVorschlag.ts,
 * Schild „Vorschlag“), oder — wenn der Coach ein Paket bestätigt hat — seine
 * Wahl (Schild „Empfehlung Ihres Coachs“). Je Paket nur der Rhythmus, kein
 * Preis, keine Laufzeit. Die Ziele entfallen ohne Eintrag.
 */
export function Seite5({ data, bericht, notes, tiers, name }: SeitenProps): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const { zaehlung } = bericht

  const vorschlag = paketVorschlag(bericht.schwerpunkte.length, zaehlung.uebung, zaehlung.untersucht)
  const bestaetigt = notes?.paketBestaetigt === true && notes.paket !== null ? notes.paket : null
  const { pakete, vorschlag: gewaehlt, eindeutig } = paketWahl(tiers, bestaetigt ?? vorschlag.paket)

  useEffect(() => {
    if (pakete.length > 0 && !eindeutig) {
      console.warn(`elternbericht: ${pakete.length} active tiers instead of 3 — no card highlighted`)
    }
  }, [pakete.length, eindeutig])

  const satz = gewaehlt
    ? bestaetigt && bestaetigt !== vorschlag.paket
      ? t('s5.vorschlag.satzBestaetigt', { paket: gewaehlt.name })
      : t('s5.vorschlag.satz', {
          paket: gewaehlt.name,
          grund: t(`s5.grund.${vorschlag.grund}`, {
            count: vorschlag.schwerpunkte,
            uebung: zaehlung.uebung,
            untersucht: zaehlung.untersucht,
          }),
        })
    : null
  const ziele = notes?.zielbild.trim() || data.erstgespraech?.ziele || null

  const kontakt = data.erzaehlung.ansprechpartner
  const kontaktName = kontakt.name?.trim() || null
  const mail = kontaktName ? kontakt.email : t('s5.kontakt.mail')

  return (
    <div className="eb-s5">
      <p className="eb-kicker eb-s5-kicker">{t('s5.kicker')}</p>
      <h1 className="eb-titel eb-s5-titel">{t('s5.titel', { name: name ?? t('kind') })}</h1>
      <p className="eb-s5-intro">{t('s5.intro')}</p>

      {pakete.length > 0 && (
        <Mitgliedschaften pakete={pakete} vorschlag={gewaehlt} bestaetigt={bestaetigt !== null} />
      )}

      {satz && (
        <section className="eb-s5-vorschlag" data-testid="eb-vorschlag">
          <p className="eb-s5-vorschlag-satz" data-testid="eb-vorschlag-zeile">
            {satz}
          </p>
          <p className="eb-s5-vorschlag-frei">
            {t(gewaehlt?.sort_order === pakete[0]?.sort_order ? 's5.vorschlag.freiwilligBasic' : 's5.vorschlag.freiwillig')}
          </p>
        </section>
      )}

      {ziele && (
        <section className="eb-s5-ziele" data-testid="eb-ziele">
          <h2 className="eb-kicker">{t('s5.ziele.kicker')}</h2>
          <p className="eb-s5-ziele-text">{ziele}</p>
        </section>
      )}

      <section className="eb-s5-kontakt" data-testid="eb-kontakt">
        <div className="eb-s5-kontakt-person">
          <h2 className="eb-kicker">{t('s5.kontakt.kickerV2')}</h2>
          <p className="eb-titel eb-s5-kontakt-name">{kontaktName ?? t('s5.kontakt.team')}</p>
          {kontaktName && <p className="eb-s5-kontakt-rolle">{t('s5.kontakt.rolle')}</p>}
          {mail && (
            <a className="eb-s5-kontakt-mail" href={`mailto:${mail}`}>
              {mail}
            </a>
          )}
          {KONTAKT.telefon && (
            <p className="eb-s5-kontakt-telefon" data-testid="eb-telefon">
              {t('s5.kontakt.telefon', { telefon: KONTAKT.telefon })}
            </p>
          )}
        </div>
        <div className="eb-s5-kontakt-fragen">
          <h2 className="eb-kicker">{t('s5.fragen.kicker')}</h2>
          <p className="eb-s5-fragen-text">{t('s5.fragen.text')}</p>
          <p className="eb-s5-fragen-text">{t('s5.fragen.vertrag')}</p>
        </div>
      </section>
    </div>
  )
}
