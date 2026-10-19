import { Fragment, useLayoutEffect, useRef, useState, type RefObject } from 'react'
import { useTranslation } from 'react-i18next'

import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import type { EbSchwerpunkt } from '@/types'

import { Kurve } from './Kurve'
import type { SeitenProps } from './seitenProps'

/** Höchstens so viele Elterntexte im Fazit (Bauauftrag R7, Entscheidung 10). */
const FAZIT_TEXTE = 2
/** Bis zu so vielen Labels als Aufzählung, darüber „… und n weitere“. */
const LISTE_VOLL = 3

/**
 * Seite 4 des Eltern-Berichts R7: Lernplan als Kurve (Maßblatt E7, „Seite 4“).
 *
 * Im Fluss: Fazit (entfällt ohne Elterntext), Titel, Schwerpunkte, die übrigen
 * Felder, Lernziel (entfällt ohne Zielbild) und die Fußnote. Die Kurve liegt
 * als SVG darüber und misst die Lagen nach dem Layout (Kurve.tsx).
 */
export function Seite4({ data, bericht, satz, notes }: SeitenProps): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const dicht = useDicht()
  const { schwerpunkte, danach } = bericht
  const anzahl = schwerpunkte.length

  const fazit = gruppiereFehlbilderNachFamilie(data.fehlbilder).slice(0, FAZIT_TEXTE)
  const keine = anzahl === 0 ? satz.waehle('fazit', 'keine', data.sessionId) : null
  const zielbild = notes?.zielbild.trim() || null

  const liste = (labels: readonly string[]): string =>
    labels.length <= LISTE_VOLL
      ? new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(labels)
      : t('liste.weitere', {
          liste: labels.slice(0, LISTE_VOLL).join(', '),
          count: labels.length - LISTE_VOLL,
        })

  return (
    <div className="eb-s4" ref={dicht.ref} data-dicht={dicht.an || undefined}>
      {fazit.length > 0 && (
        <section className="eb-s4-fazit-bereich" data-testid="eb-fazit">
          <h2 className="eb-kicker eb-s4-kicker">{t('s4.fazit.kicker')}</h2>
          <p className="eb-s4-fazit">
            {fazit.map((f) => (
              <Fragment key={f.familie}>{f.elterntext} </Fragment>
            ))}
            {t('s4.fazit.coach')}
          </p>
        </section>
      )}

      <h1 className="eb-titel eb-s4-titel">
        {anzahl === 0 ? t('s4.titelKeiner') : t(`s4.titel.${anzahl}`)}
      </h1>
      {anzahl >= 2 && <p className="eb-s4-hinweis">{t('s4.reihenfolge')}</p>}
      {keine && <p className="eb-s4-keine">{keine}</p>}

      {anzahl > 0 && (
        <ol className="eb-s4-liste" data-testid="eb-schwerpunkte">
          {schwerpunkte.map((s, i) => (
            <Schwerpunkt
              key={s.feld}
              schwerpunkt={s}
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

      {zielbild && (
        <section className="eb-s4-lernziel" data-kurve-ziel data-testid="eb-lernziel">
          <h2 className="eb-kicker">{t('s4.lernziel')}</h2>
          <p className="eb-s4-lernziel-text">{zielbild}</p>
        </section>
      )}
      <p className="eb-s4-stand">{t('s4.stand')}</p>

      {anzahl > 0 && <Kurve />}
    </div>
  )
}

/**
 * Läuft die Seite mit den Abständen des Musters über (langes Fazit, lange
 * Texte), rücken die Abschnitte enger zusammen (`[data-dicht]` in seite4.css),
 * statt dass die Fußnote am Papierrand abgeschnitten wird. Geprüft nach dem
 * Layout und nach dem Laden der Schriften; einmal dicht, bleibt es dicht.
 */
function useDicht(): { ref: RefObject<HTMLDivElement>; an: boolean } {
  const ref = useRef<HTMLDivElement>(null)
  const [an, setAn] = useState(false)

  useLayoutEffect(() => {
    const kasten = ref.current?.parentElement
    if (!kasten || an) return
    let aktiv = true
    const pruefen = (): void => {
      if (aktiv && kasten.scrollHeight > kasten.clientHeight) setAn(true)
    }
    pruefen()
    void document.fonts?.ready.then(pruefen)
    return () => {
      aktiv = false
    }
  }, [an])

  return { ref, an }
}

/** Ein Schwerpunkt; unter dem letzten die übrigen Felder („Danach …“). */
function Schwerpunkt({
  schwerpunkt,
  liste,
  danach,
}: {
  schwerpunkt: EbSchwerpunkt
  liste: (labels: readonly string[]) => string
  danach: string | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const { feld, sicher, uebung } = schwerpunkt

  return (
    <li className="eb-s4-punkt">
      <h3 className="eb-s4-punkt-titel">
        <span className="eb-s4-grund" aria-hidden="true" />
        {t(`feld.${feld}`)}
      </h3>
      <p className="eb-s4-punkt-text">
        {sicher.length > 0 && <>{t('s4.punkt.sicher', { liste: liste(sicher) })} </>}
        {t('s4.punkt.uebung', { liste: liste(uebung) })}
      </p>
      {danach && <p className="eb-s4-danach">{danach}</p>}
    </li>
  )
}
