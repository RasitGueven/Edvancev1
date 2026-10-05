// Pruefkarte: "Gewertet wird" (32.3), "Antwort ausprobieren" (32.4) und Loesungsweg (32.5).
// Ausprobieren ruft pruef_wertung_testen mit dem ungespeicherten Entwurf: dieselbe Wertung wie die
// Engine, keine eigene.

import { useEffect, useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { bereichVorschlag, zuEntwurf, type Bearbeitung } from '@/lib/pruefung/entwurf'
import { pruefWertungTesten } from '@/lib/supabase/pruefung'
import type { PruefAufgabe, PruefWertung } from '@/types'
import { GeaendertMarke, InfoTip } from './InfoTip'
import { teilLabel } from './RichtigeAntwort'

const FELD = 'min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'

type RegelProps = {
  aufgabe: PruefAufgabe
  b: Bearbeitung
  geaendert: boolean
  lesend: boolean
  onChange: (b: Bearbeitung) => void
  onZurueck: () => void
}

export function RegelBlock({ aufgabe, b, geaendert, lesend, onChange, onZurueck }: RegelProps): JSX.Element | null {
  const { t } = useTranslation('pruefen')
  const regel = aufgabe.regel
  if (!regel || !b.regel) return null
  const amFeld = regel.einheit_am_feld && !b.regel.einheit_pflicht
  const setzeArt = (art: string): void => {
    if (!b.regel) return
    onChange({
      ...b,
      regel: art === 'bereich'
        ? { ...b.regel, art: 'bereich', ...bereichVorschlag(b.werte[0]?.werte[0]) }
        : { ...b.regel, art: 'wert', mitte: null, toleranz: null },
    })
  }
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
        <label htmlFor="pruef-regel" className="inline-flex items-center gap-2">
          {t('regel.titel')} <InfoTip schluessel="regel" />
        </label>
        <select id="pruef-regel" disabled={lesend} value={b.regel.art} onChange={(e) => setzeArt(e.target.value)} className={FELD}>
          <option value="wert">{t('regel.wert')}</option>
          <option value="bereich">{t('regel.bereich')}</option>
        </select>
        <GeaendertMarke an={geaendert && !lesend} onZurueck={onZurueck} />
      </div>
      {regel.einheit && (
        <label className={cn('flex min-h-[44px] items-start gap-2 text-sm', amFeld ? 'text-[var(--color-text-tertiary)]' : 'text-[var(--color-text-secondary)]')}
          title={amFeld ? t('regel.einheitAmFeld', { einheit: regel.einheit }) : undefined}>
          <input type="checkbox" className="mt-1 h-5 w-5" disabled={lesend || amFeld} checked={b.regel.einheit_pflicht}
            onChange={(e) => b.regel && onChange({ ...b, regel: { ...b.regel, einheit_pflicht: e.target.checked } })} />
          <span className="flex flex-col">
            {t('regel.einheit', { einheit: regel.einheit })}
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {amFeld ? t('regel.einheitAmFeld', { einheit: regel.einheit }) : t('regel.einheitSub')}
            </span>
          </span>
        </label>
      )}
    </div>
  )
}

export function AntwortTesten({ aufgabe, b }: { aufgabe: PruefAufgabe; b: Bearbeitung }): JSX.Element | null {
  const { t } = useTranslation('pruefen')
  const teile = aufgabe.aufgabe.parts.filter((p) => p.kind !== 'mc')
  const [offen, setOffen] = useState(false)
  const [eingabe, setEingabe] = useState('')
  const [teil, setTeil] = useState<number | null>(teile[0]?.nr ?? null)
  const [ergebnis, setErgebnis] = useState<PruefWertung | null>(null)
  const lauf = useRef(0)
  const entwurf = JSON.stringify(zuEntwurf(b))

  useEffect(() => {
    if (!offen || !eingabe.trim()) {
      setErgebnis(null)
      return
    }
    const nr = ++lauf.current
    const timer = setTimeout(() => {
      void pruefWertungTesten(aufgabe.task_id, aufgabe.aufgabe.input_type === 'MULTI_PART' ? teil : null, eingabe,
        JSON.parse(entwurf)).then((res) => {
        if (nr === lauf.current) setErgebnis(res.data)
      })
    }, 300)
    return () => clearTimeout(timer)
  }, [offen, eingabe, teil, entwurf, aufgabe.task_id, aufgabe.aufgabe.input_type])

  if (aufgabe.aufgabe.input_type === 'MC') return null
  if (!offen) {
    return (
      <button type="button" onClick={() => setOffen(true)} className="min-h-[44px] self-start text-sm text-[var(--color-text-link)] hover:underline">
        {t('testen.link')}
      </button>
    )
  }
  const farbe = ergebnis?.stufe === 'voll' ? 'text-[var(--color-success)]'
    : ergebnis?.stufe === 'teilweise' ? 'text-[var(--color-warning)]' : 'text-[var(--color-destructive)]'
  return (
    <div className="flex flex-col gap-2">
      <label htmlFor="pruef-testen" className="inline-flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
        {t('testen.titel')} <InfoTip schluessel="testen" />
      </label>
      <div className="flex flex-wrap items-center gap-2">
        {aufgabe.aufgabe.input_type === 'MULTI_PART' && (
          <select aria-label={t('testen.teil')} value={teil ?? ''} onChange={(e) => setTeil(Number(e.target.value))} className={FELD}>
            {teile.map((p) => <option key={p.nr} value={p.nr}>{teilLabel(p.nr)} {p.prompt}</option>)}
          </select>
        )}
        <input id="pruef-testen" autoFocus value={eingabe} placeholder={t('testen.platzhalter')}
          onChange={(e) => setEingabe(e.target.value)} className={cn(FELD, 'w-40')} />
        {ergebnis?.stufe && (
          <span className="flex flex-col text-sm">
            <span className={cn('font-semibold', farbe)}>{t(`testen.${ergebnis.stufe}`)}</span>
            {ergebnis.stufe !== 'voll' && (
              <span className="text-xs text-[var(--color-text-secondary)]">
                {ergebnis.fehlbild_klartext ? t('testen.erkannt', { klartext: ergebnis.fehlbild_klartext }) : t('testen.nichtErkannt')}
              </span>
            )}
          </span>
        )}
      </div>
    </div>
  )
}

export function Loesungsweg({ text }: { text: string | null }): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <div className="flex flex-col gap-1 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3">
      <span className="inline-flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
        {t('weg.titel')} <InfoTip schluessel="weg" />
      </span>
      <p className="whitespace-pre-line text-sm leading-relaxed text-[var(--color-text-secondary)]">{text ?? t('weg.leer')}</p>
    </div>
  )
}
