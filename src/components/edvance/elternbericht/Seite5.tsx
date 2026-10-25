import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import { KONTAKT, TABLET_LINK } from '@/lib/report/elternbericht/berichtKonfig'
import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import { paketVorschlag } from '@/lib/report/elternbericht/paketVorschlag'
import { zieleV4 } from '@/lib/report/elternbericht/zielbild'

import { fazitSaetze, lueckenFelder, startSatz, zieleSaetze } from './berichtSaetze'
import { fazitSaetzeV4 } from './fazitV4'
import { Mitgliedschaften } from './Mitgliedschaften'
import { paketWahl } from './seite5Rechnung'
import type { SeitenProps } from './seitenProps'
import { useStufe } from './useStufe'

/**
 * Seite 5 des Eltern-Berichts (v3): der rote Faden zum Schluss.
 *
 *   1. Fazit: Seite 1–4 in drei bis vier Sätzen, aus denselben Daten.
 *   2. Pakete mit Vorschlag; die Begründung knüpft an das Fazit an.
 *   3. Ziele für die nächsten 6 Monate — nur wenn im Gespräch bestätigt
 *      (notes.zieleBestaetigt): das Zielbild des Coachs, sonst der
 *      Systemvorschlag (zieleSaetze). Unbestätigte Freitexte erscheinen nie.
 *   4. Kontakt: wer die Analyse begleitet hat, Telefon aus der Konfig, Vertrag.
 * Kein Preis, keine Laufzeit — außer in der Ansicht mit eingeschaltetem
 * Schalter „Preise einblenden“ (`preise`, Bericht v4).
 *
 * Bericht v4 (mit bericht.fahrplan): Fazit im mint Kasten (fazitV4.ts), Ziele aus
 * zieleV4 als nummerierte Liste mit „Wir versprechen keine Noten“.
 */
export function Seite5({ data, bericht, notes, tiers, name, wessen, preise = false }: SeitenProps): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const { zaehlung } = bericht
  const fahrplan = bericht.fahrplan ?? null
  // Bericht v4: Ziele, Fazit im Kasten und Preise brauchen mehr Platz; läuft die Seite über, rückt sie enger zusammen.
  const dicht = useStufe(fahrplan ? 2 : 0)
  const liste = (s: readonly string[]): string =>
    new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(s)

  const vorschlag = paketVorschlag(bericht.schwerpunkte.length, zaehlung.uebung, zaehlung.untersucht)
  const bestaetigt = notes?.paketBestaetigt === true && notes.paket !== null ? notes.paket : null
  const paket = bestaetigt ?? vorschlag.paket
  const { pakete, vorschlag: gewaehlt, eindeutig } = paketWahl(tiers, paket)

  useEffect(() => {
    if (pakete.length > 0 && !eindeutig) {
      console.warn(`elternbericht: ${pakete.length} active tiers instead of 3 — no card highlighted`)
    }
  }, [pakete.length, eindeutig])

  const muster = fehlermusterAus(data.fehlbilder)
  const start = startSatz(t, bericht.schwerpunkte[0], bericht.gruende?.[0])
  const fazit = fahrplan
    ? fazitSaetzeV4(t, {
        stufen: bericht.stufen ?? [],
        felder: lueckenFelder(bericht.profil),
        fahrplan,
        lernpfad: bericht.lernpfad ?? [],
        sorgfalt: muster?.sorgfalt === true,
        wessen,
        startV3: start,
      })
    : fazitSaetze(t, {
        stufen: bericht.stufen ?? [],
        felder: lueckenFelder(bericht.profil),
        sorgfalt: muster?.sorgfalt === true,
        start,
      })

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

  const zielbild = notes?.zielbild.trim() || null
  const spaeterLuecken = (bericht.lueckenwegV4?.weitere ?? []).reduce((n, g) => n + g.labels.length + (g.rest ?? 0), 0)
  const systemZiele = fahrplan
    ? zieleV4({ fahrplan, muster, name, spaeterLuecken }).map((z) => t(z.schluessel, z.werte))
    : zieleSaetze(t, {
        schwerpunkte: bericht.schwerpunkte,
        gruende: bericht.gruende ?? [],
        paket,
        sorgfalt: muster?.sorgfalt === true,
        liste,
      })
  const ziele = notes?.zieleBestaetigt ? (zielbild ? [zielbild] : systemZiele) : []

  const kontakt = data.erzaehlung.ansprechpartner
  const kontaktName = kontakt.name?.trim() || null
  const mail = kontaktName ? kontakt.email : t('s5.kontakt.mail')

  return (
    <div className="eb-s5" ref={dicht.ref} data-stufe={dicht.wert || undefined} data-v4={fahrplan ? true : undefined}>
      <p className="eb-kicker eb-s5-kicker">{t('s5.kicker')}</p>
      <h1 className="eb-titel eb-s5-titel">{t('s5.titel', { name: name ?? t('kind') })}</h1>
      {fazit.length > 0 && (
        <p className={fahrplan ? 'eb-s5-intro eb-s5-fazit eb-s5-fazit-v4' : 'eb-s5-intro eb-s5-fazit'} data-testid="eb-s5-fazit">
          {fazit.join(' ')}
        </p>
      )}

      {pakete.length > 0 && (
        <Mitgliedschaften pakete={pakete} vorschlag={gewaehlt} bestaetigt={bestaetigt !== null} preise={preise} />
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

      {ziele.length > 0 && (
        <section className={fahrplan ? 'eb-s5-ziele eb-s5-ziele-v4' : 'eb-s5-ziele'} data-testid="eb-ziele">
          <h2 className="eb-kicker">{t('s5.ziele.kicker')}</h2>
          <ul className="eb-s5-ziele-liste">
            {ziele.map((z, i) => (
              <li key={z}>
                {fahrplan && <span className="eb-s5-ziel-nr">{i + 1}</span>}
                {z}
              </li>
            ))}
          </ul>
          {fahrplan && (
            <p className="eb-s5-keine-noten" data-testid="eb-keine-noten">
              {name ? t('v4.s5.keineNoten', { name }) : t('v4.s5.keineNotenOhneName')}
            </p>
          )}
        </section>
      )}

      <section className="eb-s5-kontakt" data-testid="eb-kontakt">
        <div className="eb-s5-kontakt-person">
          <h2 className="eb-kicker">{t('s5.kontakt.kickerV2')}</h2>
          <p className="eb-titel eb-s5-kontakt-name">{kontaktName ?? t('s5.kontakt.team')}</p>
          {kontaktName && <p className="eb-s5-kontakt-rolle">{t('s5.kontakt.rolle')}</p>}
          {KONTAKT.telefon && (
            <p className="eb-s5-kontakt-telefon" data-testid="eb-telefon">
              {t('s5.kontakt.telefon', { telefon: KONTAKT.telefon })}
            </p>
          )}
          {mail && (
            <a className="eb-s5-kontakt-mail" href={`mailto:${mail}`}>
              {mail}
            </a>
          )}
        </div>
        <div className="eb-s5-kontakt-fragen">
          <h2 className="eb-kicker">{t('s5.fragen.kicker')}</h2>
          <p className="eb-s5-fragen-text">{t(KONTAKT.telefon ? 's5.fragen.text' : 's5.fragen.textOhneTelefon')}</p>
          <p className="eb-s5-fragen-text">{t('s5.fragen.vertrag')}</p>
          {TABLET_LINK && (
            <p className="eb-s5-fragen-text" data-testid="eb-tablet">
              {t('s5.kontakt.tablet', { link: TABLET_LINK })}
            </p>
          )}
        </div>
      </section>
    </div>
  )
}
