import { useContext, useLayoutEffect, useRef, useState, type RefObject } from 'react'
import { useTranslation } from 'react-i18next'

import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import type { EbGrund, EbSchwerpunkt } from '@/types'

import { grundText } from './berichtSaetze'
import { Kurve } from './Kurve'
import { baueListe, schwerpunktKey, schwerpunktTitel, type Liste } from './liste'
import { NamensMessungFertig } from './namensMessung'
import type { SeitenProps } from './seitenProps'

/**
 * Seite 4 des Eltern-Berichts (v2): Fazit und Lernplan als Kurve.
 *
 * Im Fluss: das Fehlermuster mit Überschrift (entfällt ohne Befund), Titel,
 * Schwerpunkte mit ihrem Grund („weil …“, aus den Daten), die übrigen Felder
 * und der einzige Coach-Satz des Berichts. Die Kurve liegt als SVG darüber und
 * misst die Lagen nach dem Layout (Kurve.tsx). Die Ziele stehen auf Seite 5.
 */
export function Seite4({ data, bericht, satz, name }: SeitenProps): JSX.Element {
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
  const stufe = useStufe(DICHT)
  const keine = anzahl === 0 ? satz.waehle('fazit', 'keine', data.sessionId) : null

  const liste = baueListe(t, i18n.language)

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

/** Stufen, wenn Seite 4 überläuft (Gründer-Entscheidung R7-5), nacheinander. */
const DICHT = 1 // engere Abstände (`[data-dicht]` in seite4.css)

/**
 * Läuft die Seite mit den Abständen des Musters über (langes Fazit, lange
 * Texte), geht sie eine Stufe weiter, bis alles passt oder `hoechste` erreicht
 * ist — statt dass die Fußnote am Papierrand abgeschnitten wird. Text wird nie
 * gekürzt, nur weggelassen. Geprüft nach dem Layout, solange Schriften laden
 * aber erst nach `document.fonts.ready` — sonst bliebe eine Stufe stehen, die
 * nur die Ersatzschrift brauchte. Eine erreichte Stufe bleibt.
 */
function useStufe(hoechste: number): { ref: RefObject<HTMLDivElement>; wert: number } {
  const ref = useRef<HTMLDivElement>(null)
  const [wert, setWert] = useState(0)
  // Erst entscheidet der Bogen über den Namen, dann misst Seite 4.
  const nameEntschieden = useContext(NamensMessungFertig)

  useLayoutEffect(() => {
    const kasten = ref.current?.parentElement
    if (!nameEntschieden || !kasten || wert >= hoechste) return
    let aktiv = true
    const pruefen = (): void => {
      if (aktiv && kasten.scrollHeight > kasten.clientHeight) setWert(wert + 1)
    }
    void kasten.offsetHeight // Layout erzwingen, damit die Schriften angefordert sind
    if (!document.fonts || document.fonts.status === 'loaded') pruefen()
    else void document.fonts.ready.then(pruefen)
    return () => {
      aktiv = false
    }
  }, [wert, hoechste, nameEntschieden])

  return { ref, wert }
}

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
