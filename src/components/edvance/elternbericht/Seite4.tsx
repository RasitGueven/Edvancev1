import { useTranslation } from 'react-i18next'

import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import type { EbGrund, EbSchwerpunkt } from '@/types'

import { grundText } from './berichtSaetze'
import { Kurve } from './Kurve'
import { AnsatzKaesten, LernpfadV4 } from './LernpfadV4'
import { baueListe, schwerpunktKey, schwerpunktTitel, type Liste } from './liste'
import type { SeitenProps } from './seitenProps'
import { useStufe } from './useStufe'

/**
 * Seite 4 des Eltern-Berichts (v2): Fazit und Lernplan als Kurve.
 *
 * Im Fluss: das Fehlermuster mit Überschrift (entfällt ohne Befund), Titel,
 * Schwerpunkte mit ihrem Grund („weil …“, aus den Daten), die übrigen Felder
 * und der einzige Coach-Satz des Berichts. Die Kurve liegt als SVG darüber und
 * misst die Lagen nach dem Layout (Kurve.tsx). Die Ziele stehen auf Seite 5.
 *
 * Bericht v4 (mit bericht.fahrplan): Lernpfad nach Klassenarbeiten statt Kurve,
 * ohne Fehlermuster; darunter „Unser Ansatz“ und „Was dazu gehört“.
 */
export function Seite4({ data, bericht, satz, name, wessen }: SeitenProps): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const { schwerpunkte, danach } = bericht
  const anzahl = schwerpunkte.length

  const muster = fehlermusterAus(data.fehlbilder)
  // Der abgenommene Familientext beginnt mit „Ihr Kind“ — im Bericht steht der Vorname.
  const musterText = muster?.sorgfalt
    ? t('s4.muster.sorgfalt', { sorgfalt: muster.sorgfaltAufgaben, eingeordnet: muster.aufgaben })
    : muster?.haeufigste
      ? name
        ? muster.haeufigste.replace(/^Ihr Kind\b/, name)
        : muster.haeufigste
      : null
  const stufe = useStufe(bericht.fahrplan ? 2 : DICHT)
  const keine = anzahl === 0 ? satz.waehle('fazit', 'keine', data.sessionId) : null

  const liste = baueListe(t, i18n.language)

  const fahrplan = bericht.fahrplan ?? null
  if (fahrplan) {
    const lernpfad = bericht.lernpfad ?? []
    const status = data.erstgespraech?.klassenarbeit ?? null
    // L5: ohne bekannte Folge sprechen Titel und Einleitung von Themen, nicht von Arbeiten.
    const thema = fahrplan.folge === 'unbekannt' ? 'Thema' : ''
    return (
      <div
        className="eb-s4 eb-s4-v4"
        ref={stufe.ref}
        data-dicht={stufe.wert >= DICHT || undefined}
        data-stufe={stufe.wert || undefined}
      >
        <p className="eb-kicker eb-s4-kicker">{t('v4.s4.kicker')}</p>
        <h1 className="eb-titel eb-s4-titel">{lernpfad.length === 0 ? t('s4.titelKeiner') : t(`v4.s4.titel${thema}`)}</h1>
        {lernpfad.length === 0 && keine && <p className="eb-s4-keine">{keine}</p>}
        {lernpfad.length > 0 && (
          <p className="eb-s4-hinweis" data-testid="eb-s4-intro">
            {t(`v4.s4.intro${thema}.${status ?? 'unbekannt'}`, { thema: fahrplan.stationen[0].titel })}
          </p>
        )}
        {lernpfad.length > 0 && (
          <LernpfadV4
            punkte={lernpfad}
            fahrplan={fahrplan}
            schwerpunkte={schwerpunkte}
            liste={liste}
            name={name}
          />
        )}
        <AnsatzKaesten wessen={wessen} />
        <p className="eb-s4-stand eb-s4-stand-voll">{t('s4.coach')}</p>
      </div>
    )
  }

  return (
    <div
      className="eb-s4"
      ref={stufe.ref}
      data-dicht={stufe.wert >= DICHT || undefined}
      data-stufe={stufe.wert || undefined}
    >
      {musterText && (
        <section className="eb-s4-fazit-bereich" data-testid="eb-fazit">
          <h2 className="eb-kicker eb-s4-kicker">{t('s4.muster.kicker')}</h2>
          <p className="eb-s4-fazit">{musterText}</p>
        </section>
      )}

      <h1 className="eb-titel eb-s4-titel">
        {anzahl === 0 ? t('s4.titelKeiner') : t(`s4.titel.${anzahl}`)}
      </h1>
      {keine && <p className="eb-s4-keine">{keine}</p>}

      {anzahl > 0 && (
        <ol className="eb-s4-liste" data-testid="eb-schwerpunkte">
          {schwerpunkte.map((s, i) => (
            <Schwerpunkt
              key={schwerpunktKey(s)}
              schwerpunkt={s}
              grund={bericht.gruende?.[i]}
              liste={liste}
              danach={
                i === anzahl - 1 && danach.length > 0
                  ? t('s4.danach', { liste: liste(danach.map((f) => t(`feld.${f}`))) })
                  : null
              }
            />
          ))}
        </ol>
      )}

      <p className={anzahl === 0 ? 'eb-s4-stand eb-s4-stand-voll' : 'eb-s4-stand'}>
        {t('s4.coach')}
      </p>

      {anzahl > 0 && <Kurve />}
    </div>
  )
}

/** Stufen, wenn Seite 4 überläuft (Gründer-Entscheidung R7-5): engere Abstände (`[data-dicht]` in seite4.css). */
const DICHT = 1

/**
 * Ein Schwerpunkt: Titel und Grund (Bericht v3, ohne die Listen „Sicher / Noch
 * nicht sicher“); unter dem letzten die übrigen Felder („Danach …“). Ist die
 * Klassenarbeit zum Thema geschrieben, heißt der Thema-Schwerpunkt nach seinen
 * Lücken und trägt das Schild „Vorhandene Lücke“ statt „Aktuelles Thema“.
 */
function Schwerpunkt({
  schwerpunkt,
  grund,
  liste,
  danach,
}: {
  schwerpunkt: EbSchwerpunkt
  grund: EbGrund | undefined
  liste: Liste
  danach: string | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const { thema, uebung } = schwerpunkt
  const luecke = grund?.art === 'spaeterGebraucht' || grund?.art === 'themaGeschrieben'

  return (
    <li className="eb-s4-punkt">
      <h3 className="eb-s4-punkt-titel">
        <span className="eb-s4-grund" aria-hidden="true" />
        {luecke ? liste(uebung) : schwerpunktTitel(t, schwerpunkt)}
        {thema && (
          <span className="eb-s4-chip" data-testid="eb-s4-chip-thema">
            {t(luecke ? 's4.chip.luecke' : 's4.chip.thema')}
          </span>
        )}
      </h3>
      {grund && (
        <p className="eb-s4-grund-text">
          {grund.art === 'spaeterGebraucht'
            ? t('s4.spaeterZeile', { titel: grund.titel })
            : t('s4.grund', { grund: grundText(t, grund) })}
        </p>
      )}
      {danach && <p className="eb-s4-danach">{danach}</p>}
    </li>
  )
}
