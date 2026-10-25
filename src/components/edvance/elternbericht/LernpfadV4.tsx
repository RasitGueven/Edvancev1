import type { TFunction } from 'i18next'
import { useTranslation } from 'react-i18next'

import type { EbFahrplan, EbGrund, EbLernpfadPunkt, EbSchwerpunkt } from '@/types'

import { grundText } from './berichtSaetze'
import type { Liste } from './liste'

/**
 * Der Lernpfad nach Klassenarbeiten (Bauauftrag V4, V4-2 Entscheidung 5): je
 * Punkt links eine Marke mit der Nummer der Klassenarbeit, rechts eine Karte mit
 * „Schritt n · Voraussetzung für Klassenarbeit n“, Titel, Begründung („weil …“,
 * aus den Daten) und dem Kasten „Das üben wir“. Zuletzt, grau, die Themen
 * späterer Schuljahre. Nie „bis Klassenarbeit …“: das klänge wie eine Zusage.
 */
export function LernpfadV4({
  punkte,
  fahrplan,
  schwerpunkte,
  liste,
  name,
}: {
  punkte: EbLernpfadPunkt[]
  fahrplan: EbFahrplan
  /** Für den Titel des Thema-Schwerpunkts (Lücke). */
  schwerpunkte: EbSchwerpunkt[]
  liste: Liste
  name: string | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const themaSchwerpunkt = schwerpunkte.find((s) => s.feld === null)
  return (
    <ol className="eb-s4v4-liste" data-testid="eb-lernpfad">
      {punkte.map((p, i) => {
        const station = fahrplan.stationen.find((s) => s.nummer === p.ziele[0])
        if (p.art === 'spaeter') {
          return (
            <li key="spaeter" className="eb-s4v4-punkt eb-s4v4-spaeter" data-testid="eb-lernpfad-spaeter">
              <div className="eb-s4v4-marke" aria-hidden="true">
                <small>{t('v4.s4.danach')}</small>
                <b>+</b>
              </div>
              <div className="eb-s4v4-karte">
                <p className="eb-s4v4-zeile">{t('v4.s4.spaeter')}</p>
                <h3>{t('v4.s4.spaeterTitel')}</h3>
                <p className="eb-s4v4-text">
                  {liste((p.felder ?? []).map((f) => t(`feld.${f}`)))}
                  {'. '}
                  {name ? t('v4.s4.spaeterText', { name }) : t('v4.s4.spaeterTextOhneName')}
                </p>
              </div>
            </li>
          )
        }
        const luecke = p.grund?.art === 'spaeterGebraucht' || p.grund?.art === 'themaGeschrieben'
        const titel =
          p.art === 'gruppe'
            ? t('v4.s4.gruppe', { thema: p.titelThema })
            : p.art === 'feld'
              ? t(`feld.${p.titelFeld ?? 'weitere'}`)
              : luecke && themaSchwerpunkt
                ? liste(themaSchwerpunkt.uebung)
                : (p.titelThema ?? '')
        const voraus =
          p.ziele.length >= 2
            ? t('v4.s4.voraussetzungZwei', { n: p.ziele[0], m: p.ziele[1] })
            : p.ziele.length === 1
              ? t('v4.s4.voraussetzung', { n: p.ziele[0] })
              : p.art === 'luecke'
                ? t(luecke ? 's4.chip.luecke' : 's4.chip.thema')
                : null
        const zeile = [t('v4.s4.schritt', { n: i + 1 }), voraus].filter(Boolean).join(t('s2.profil.trenner'))
        return (
          <li key={`${p.art}-${i}`} className="eb-s4v4-punkt" data-testid="eb-lernpfad-punkt">
            <div className={station ? 'eb-s4v4-marke eb-s4v4-marke-ka' : 'eb-s4v4-marke eb-s4v4-marke-leise'} aria-hidden="true">
              {station ? (
                <>
                  <small>{t('v4.s4.fuer')}</small>
                  <b>{station.nummer}</b>
                  <span>{station.titel}</span>
                </>
              ) : (
                <small>{t('v4.s4.schritt', { n: i + 1 })}</small>
              )}
            </div>
            <div className="eb-s4v4-karte">
              <p className="eb-s4v4-zeile">{zeile}</p>
              <h3>{titel}</h3>
              {p.grund && <p className="eb-s4v4-text">{begruendung(t, p.grund)}</p>}
              {p.teile.length > 0 && (
                <div className="eb-s4v4-uebt" data-testid="eb-uebt">
                  <h4>{t('v4.s4.uebt')}</h4>
                  <ul className="eb-s4v4-chips">
                    {p.teile.map((l) => (
                      <li key={l}>{l}</li>
                    ))}
                    {p.rest > 0 && <li className="eb-s4v4-chips-mehr">{t('s3.weitere', { count: p.rest })}</li>}
                  </ul>
                </div>
              )}
            </div>
          </li>
        )
      })}
    </ol>
  )
}

function begruendung(t: TFunction<'elternbericht'>, g: EbGrund): string {
  return g.art === 'spaeterGebraucht'
    ? t('s4.spaeterZeile', { titel: g.titel })
    : t('s4.grund', { grund: grundText(t, g) })
}

/** „Unser Ansatz“ und „Was dazu gehört“, zwei Kästen nebeneinander (Entscheidung 10). */
export function AnsatzKaesten({ wessen }: { wessen: string | null }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  return (
    <div className="eb-s4v4-ansatz" data-testid="eb-ansatz">
      <section className="eb-s4v4-kasten eb-s4v4-ansatz-links">
        <h2>{t('v4.s4.ansatzTitel')}</h2>
        <p>{t('v4.s4.ansatz')}</p>
      </section>
      <section className="eb-s4v4-kasten eb-s4v4-ansatz-rechts">
        <h2>{t('v4.s4.dazuTitel')}</h2>
        <ul>
          <li>{wessen ? t('v4.s4.dazu1', { wessen }) : t('v4.s4.dazu1OhneName')}</li>
          <li>{t('v4.s4.dazu2')}</li>
          <li>{t('v4.s4.dazu3')}</li>
          <li>{t('v4.s4.dazu4')}</li>
        </ul>
      </section>
    </div>
  )
}
