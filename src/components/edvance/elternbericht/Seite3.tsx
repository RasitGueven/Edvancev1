import { useContext, useLayoutEffect, useMemo, useRef, useState, type RefObject } from 'react'
import { useTranslation } from 'react-i18next'

import { KUERZUNGEN, kuerzeLernweg } from '@/lib/report/elternbericht/lernweg'

import { LernwegLegende, LernwegZonen } from './Lernweg'
import { LernwegLinien } from './LernwegLinien'
import { useLernwegTexte } from './lernwegTexte'
import { NamensMessungFertig } from './namensMessung'
import type { SeitenProps } from './seitenProps'

/**
 * Stufe der Kürzung (Entscheidung 18): Passt der Lernweg nicht in seinen
 * Bereich, kürzt die Seite nacheinander nicht geprüfte Einträge, Linien und
 * Kommt noch, bis er passt. Gemessen wird nur der eigene Bereich (er schneidet
 * ab), damit die Namensentscheidung des Bogens davon nichts merkt. Passt es
 * nach der letzten Stufe nicht, steht `data-ueberlauf` am Bereich (Druck-Test).
 */
function useKuerzung(bereit: boolean, schluessel: unknown) {
  const ref = useRef<HTMLDivElement>(null)
  const [stufe, setStufe] = useState(0)
  const [ueberlauf, setUeberlauf] = useState(false)

  useLayoutEffect(() => {
    setStufe(0)
    setUeberlauf(false)
  }, [schluessel])

  useLayoutEffect(() => {
    const bereich = ref.current
    if (!bereit || !bereich) return
    let aktiv = true
    const pruefen = (): void => {
      if (!aktiv) return
      const zuGross = bereich.scrollHeight > bereich.clientHeight + 0.5
      if (!zuGross) return
      if (stufe < KUERZUNGEN.length - 1) setStufe(stufe + 1)
      else setUeberlauf(true)
    }
    void bereich.offsetHeight
    if (!document.fonts || document.fonts.status === 'loaded') pruefen()
    else void document.fonts.ready.then(pruefen)
    return () => {
      aktiv = false
    }
  }, [bereit, stufe])

  return { ref, stufe, ueberlauf }
}

/**
 * Seite 3 des Eltern-Berichts R7: der Lernweg (R7-9) — Grundlagen →
 * Weiterführend → Aktuell → Kommt noch, mit Linien, worauf der kommende Stoff
 * aufbaut. Ersetzt die Pyramide. Styles in src/styles/elternbericht/seite3.css.
 */
export function Seite3({ bericht, name, wessen }: SeitenProps): JSX.Element | null {
  const { t } = useTranslation('elternbericht')
  const nameEntschieden = useContext(NamensMessungFertig)
  const voll = bericht.lernweg
  const k = useKuerzung(nameEntschieden && voll !== null, voll)
  const lw = useMemo(() => (voll ? kuerzeLernweg(voll, KUERZUNGEN[k.stufe]) : null), [voll, k.stufe])

  return (
    <div className="eb-s3">
      <p className="eb-kicker eb-s3-kicker">{wessen ? t('s3.kicker', { wessen }) : t('s3.kickerOhneName')}</p>
      <h1 className="eb-titel eb-s3-titel">
        {t(bericht.zaehlung.sicher > 0 ? 's3.titel' : 's3.titelOhneSicher')}
      </h1>
      {lw && <Inhalt lw={lw} name={name} bereich={k.ref} stufe={k.stufe} ueberlauf={k.ueberlauf} />}
    </div>
  )
}

function Inhalt({
  lw,
  name,
  bereich,
  stufe,
  ueberlauf,
}: {
  lw: NonNullable<SeitenProps['bericht']['lernweg']>
  name: string | null
  bereich: RefObject<HTMLDivElement>
  stufe: number
  ueberlauf: boolean
}): JSX.Element {
  const tx = useLernwegTexte(lw)
  return (
    <>
      <p className="eb-s3-intro">
        {name
          ? tx.t('s3.weg.intro', { name, klasse: lw.klasse, quelle: tx.quelle })
          : tx.t('s3.weg.introOhneName', { klasse: lw.klasse, quelle: tx.quelle })}
      </p>
      <LernwegLegende lw={lw} />
      <div
        ref={bereich}
        className="eb-s3-weg"
        data-testid="eb-s3-weg"
        data-stufe={stufe}
        data-ueberlauf={ueberlauf || undefined}
      >
        <LernwegZonen lw={lw} />
        <LernwegLinien linien={lw.linien} />
      </div>
      <p className="eb-s3-hinweis">{tx.t('s3.weg.hinweis', { quelle: tx.quelleAus })}</p>
    </>
  )
}
