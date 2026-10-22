// Zwischenbild beim Themenwechsel im Prueflauf (P4, Entscheidung 12): Ist im Thema alles Noetige geprueft, oeffnet
// sich nicht sofort die naechste Aufgabe. Erst "<Thema> ist fertig", dann "Weiter mit <Thema> · noch n noetig",
// beim Stufenwechsel mit der neuen Stufe. Kein Modal; Enter = Weiter (nicht bei Fokus auf einem Knopf).

import { useEffect, useRef, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui'
import type { ThemaSoll } from '@/lib/pruefung/soll'
import type { Stufe } from '@/types'
import { Taste } from './InfoTip'

type Props = {
  fertig: { thema: string; soll: ThemaSoll | null }
  weiter: { thema: string; rest: number | null; stufe: Stufe | null }
  onWeiter: () => void
  onUebersicht: () => void
}

export function Themenwechsel({ fertig, weiter, onWeiter, onUebersicht }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const ref = useRef(onWeiter)
  useEffect(() => {
    ref.current = onWeiter
  })

  useEffect(() => {
    const taste = (e: KeyboardEvent): void => {
      const el = document.activeElement as HTMLElement | null
      const aufKnopf = !!el && ['BUTTON', 'A', 'INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)
      if (e.key === 'Enter' && !aufKnopf && !e.defaultPrevented) {
        e.preventDefault()
        ref.current()
      }
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [])

  return (
    <EdvanceCard className="flex animate-fade-in flex-col gap-6">
      <div className="flex flex-col gap-2">
        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('lauf.wechsel.eyebrow')}
        </span>
        <h1 className="text-base font-semibold text-[var(--color-text-primary)]">
          {fertig.soll
            ? t('lauf.wechsel.fertig', { thema: fertig.thema, x: fertig.soll.gezaehlt, y: fertig.soll.noetig })
            : t('lauf.wechsel.fertigOhneSoll', { thema: fertig.thema })}
        </h1>
        {weiter.stufe && (
          <p className="text-sm font-semibold text-[var(--color-primary)]">
            {t('lauf.wechsel.stufe', { stufe: t(`stufe.${weiter.stufe}`) })}
          </p>
        )}
        <p className="text-sm text-[var(--color-text-secondary)]">
          {weiter.rest === null
            ? t('lauf.wechsel.weiterOhneSoll', { thema: weiter.thema })
            : t('lauf.wechsel.weiter', { thema: weiter.thema, n: weiter.rest })}
        </p>
      </div>
      <div className="flex flex-wrap gap-2">
        <Button size="lg" onClick={onWeiter}>
          {t('lauf.wechsel.knopf')} <Taste>Enter</Taste>
        </Button>
        <Button size="lg" variant="secondary" onClick={onUebersicht}>{t('abschluss.zurUebersicht')}</Button>
      </div>
    </EdvanceCard>
  )
}
