// Pruefkarte, Abschnitt "Richtige Antwort" (Entscheidung 32.2). Eine Liste je Teil; bei Multiple
// Choice alle Optionen, ein Klick setzt die richtige; bei "Bereich" Wert ± Toleranz statt Liste.

import { useState, type JSX, type KeyboardEvent, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { zahlVon, type Bearbeitung } from '@/lib/pruefung/entwurf'
import type { PruefAufgabe } from '@/types'
import { GeaendertMarke, InfoTip } from './InfoTip'

export const teilLabel = (nr: number | null): string => (nr === null ? '' : `${String.fromCharCode(96 + nr)})`)
const anzeige = (w: string): string => w.replace(/-/g, '−')

type Props = {
  aufgabe: PruefAufgabe
  b: Bearbeitung
  geaendert: boolean
  lesend: boolean
  onChange: (b: Bearbeitung) => void
  onZurueck: () => void
  /** Rechts im Abschnittskopf, z. B. „im Editor“ in der Admin-Pruefansicht. */
  kopfAktion?: ReactNode
}

function ChipFeld({ wert, onFertig }: { wert: string; onFertig: (w: string | null) => void }): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [text, setText] = useState(wert)
  const taste = (e: KeyboardEvent<HTMLInputElement>): void => {
    if (e.key === 'Enter') {
      e.preventDefault()
      e.stopPropagation()
      onFertig(text)
    } else if (e.key === 'Escape') {
      e.preventDefault()
      e.stopPropagation()
      onFertig(null)
    }
  }
  return (
    <input
      autoFocus
      aria-label={t('antwort.neu')}
      value={text}
      onChange={(e) => setText(e.target.value)}
      onKeyDown={taste}
      onBlur={() => onFertig(text)}
      className="min-h-[44px] w-28 rounded-[var(--radius-md)] border border-[var(--color-primary)] bg-[var(--color-bg-surface)] px-3 text-sm font-semibold"
    />
  )
}

export function RichtigeAntwort({ aufgabe, b, geaendert, lesend, onChange, onZurueck, kopfAktion }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [edit, setEdit] = useState<{ teil: number | null; i: number | 'neu' } | null>(null)
  const typ = aufgabe.aufgabe.input_type
  const titel = typ === 'MULTI_PART' ? t('antwort.titelTeile') : t('antwort.titel')
  const info = typ === 'MC' ? 'mc' : typ === 'MULTI_PART' ? 'teile' : 'antwort'

  const setzeWert = (teil: number | null, i: number | 'neu', w: string | null): void => {
    setEdit(null)
    if (w === null) return
    const v = w.trim().replace(/[−–]/g, '-').replace(/\s+/g, ' ')
    const werte = b.werte.map((x) => {
      if (x.teil !== teil) return x
      const liste = [...x.werte]
      if (i === 'neu') { if (v && !liste.includes(v)) liste.push(v) }
      else if (v) liste[i] = liste[i].replace(/[−–]/g, '-') === v ? liste[i] : v
      else liste.splice(i, 1)
      return { ...x, werte: liste }
    })
    onChange({ ...b, werte })
  }

  const kopf = (
    <h3 className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
      <span className="inline-flex items-center gap-2">{titel} <InfoTip schluessel={info} /></span>
      <GeaendertMarke an={geaendert && !lesend} onZurueck={onZurueck} />
      {kopfAktion && <span className="ml-auto normal-case tracking-normal">{kopfAktion}</span>}
    </h3>
  )

  if (typ === 'MC') {
    return (
      <div className="flex flex-col gap-2">
        {kopf}
        <p className="text-sm text-[var(--color-text-secondary)]">{t('antwort.subMc')}</p>
        <div className="grid gap-2">
          {aufgabe.aufgabe.optionen.map((o) => {
            const an = b.mc === o.id
            return (
              <button
                key={o.id}
                type="button"
                disabled={lesend}
                aria-pressed={an}
                onClick={() => onChange({ ...b, mc: o.id, werte: [{ teil: null, werte: [o.id] }] })}
                className={cn(
                  'flex min-h-[44px] items-center gap-3 rounded-[var(--radius-md)] border px-3 text-left text-sm',
                  an ? 'border-[var(--color-success)] bg-[var(--color-success-light)]' : 'border-[var(--color-border)] hover:border-[var(--color-primary)]',
                )}
              >
                <span className="font-semibold text-[var(--color-text-tertiary)]">{o.id})</span>
                <span className="flex-1">{o.label}</span>
                {an && <span className="text-xs font-semibold text-[var(--color-success)]">{t('antwort.richtig')}</span>}
              </button>
            )
          })}
        </div>
      </div>
    )
  }

  if (b.regel?.art === 'bereich') {
    const m = zahlVon(b.regel.mitte)
    const tol = zahlVon(b.regel.toleranz)
    const fmt = (n: number): string => anzeige(String(Math.round(n * 1000) / 1000).replace('.', ','))
    const setze = (feld: 'mitte' | 'toleranz', v: string): void =>
      onChange({ ...b, regel: b.regel ? { ...b.regel, [feld]: v } : null })
    return (
      <div className="flex flex-col gap-2">
        {kopf}
        <p className="text-sm text-[var(--color-text-secondary)]">{t('regel.bereichSub')}</p>
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <input aria-label={t('regel.mitte')} inputMode="decimal" disabled={lesend} value={b.regel.mitte ?? ''}
            onChange={(e) => setze('mitte', e.target.value)}
            className="min-h-[44px] w-24 rounded-[var(--radius-md)] border border-[var(--color-border)] px-2 text-center font-semibold" />
          <span>±</span>
          <input aria-label={t('regel.toleranz')} inputMode="decimal" disabled={lesend} value={b.regel.toleranz ?? ''}
            onChange={(e) => setze('toleranz', e.target.value)}
            className="min-h-[44px] w-24 rounded-[var(--radius-md)] border border-[var(--color-border)] px-2 text-center font-semibold" />
          <span>{aufgabe.regel?.einheit ?? ''}</span>
          {m !== null && tol !== null && (
            <span className="text-xs text-[var(--color-text-tertiary)]">{t('regel.von', { von: fmt(m - tol), bis: fmt(m + tol) })}</span>
          )}
        </div>
      </div>
    )
  }

  const erster = b.werte[0]?.werte[0]
  const beispiele = erster && aufgabe.flach_regel
    ? [erster.includes(',') ? erster.replace(',', '.') : `${erster},0`, ...(aufgabe.regel?.einheit ? [`${erster} ${aufgabe.regel.einheit}`] : [])]
    : []
  return (
    <div className="flex flex-col gap-2">
      {kopf}
      <p className="text-sm text-[var(--color-text-secondary)]">
        {typ === 'MULTI_PART' ? t('antwort.subTeile') : aufgabe.flach_regel ? t('antwort.sub') : t('antwort.subTerm')}
      </p>
      {b.werte.map((teil) => {
        const prompt = aufgabe.aufgabe.parts.find((p) => p.nr === teil.teil)
        return (
          <div key={teil.teil ?? 0} className="flex flex-wrap items-center gap-2">
            {teil.teil !== null && (
              <span className="w-full text-sm font-semibold text-[var(--color-text-secondary)] sm:w-auto sm:min-w-16">
                {teilLabel(teil.teil)} {prompt?.prompt}
              </span>
            )}
            {prompt?.kind === 'mc' && prompt.options.map((o) => {
              const an = teil.werte.includes(o.id)
              return (
                <button key={o.id} type="button" disabled={lesend} aria-pressed={an}
                  onClick={() => onChange({ ...b, werte: b.werte.map((x) => (x.teil === teil.teil ? { ...x, werte: [o.id] } : x)) })}
                  className={cn('min-h-[44px] rounded-[var(--radius-md)] border px-3 text-left text-sm',
                    an ? 'border-[var(--color-success)] bg-[var(--color-success-light)]' : 'border-[var(--color-border)] hover:border-[var(--color-primary)]')}>
                  <span className="font-semibold text-[var(--color-text-tertiary)]">{o.id})</span> {o.label}
                </button>
              )
            })}
            {prompt?.kind !== 'mc' && teil.werte.map((w, i) =>
              edit?.teil === teil.teil && edit.i === i ? (
                <ChipFeld key={i} wert={anzeige(w)} onFertig={(v) => setzeWert(teil.teil, i, v)} />
              ) : (
                <span key={i} className="inline-flex min-h-[44px] items-center rounded-[var(--radius-md)] border border-[var(--color-border)] text-sm font-semibold">
                  <button type="button" disabled={lesend} onClick={() => setEdit({ teil: teil.teil, i })}
                    aria-label={t('antwort.aendern', { wert: anzeige(w) })} className="min-h-[44px] px-3">
                    {anzeige(w)}
                  </button>
                  {!lesend && (
                    <button type="button" onClick={() => setzeWert(teil.teil, i, '')}
                      aria-label={t('antwort.loeschen', { wert: anzeige(w) })}
                      className="min-h-[44px] w-9 rounded-r-[var(--radius-md)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-destructive-light)] hover:text-[var(--color-destructive)]">
                      <X className="mx-auto h-4 w-4" aria-hidden="true" />
                    </button>
                  )}
                </span>
              ),
            )}
            {!lesend && prompt?.kind !== 'mc' && (edit?.teil === teil.teil && edit.i === 'neu' ? (
              <ChipFeld wert="" onFertig={(v) => setzeWert(teil.teil, 'neu', v)} />
            ) : (
              <button type="button" onClick={() => setEdit({ teil: teil.teil, i: 'neu' })}
                className="min-h-[44px] rounded-[var(--radius-md)] border border-dashed border-[var(--color-border)] px-3 text-sm text-[var(--color-primary)] hover:border-[var(--color-primary)]">
                {t('antwort.plus')}
              </button>
            ))}
          </div>
        )
      })}
      {beispiele.length > 0 && (
        <p className="text-xs text-[var(--color-text-tertiary)]">
          {t('antwort.schreibweisen', { beispiele: beispiele.map(anzeige).join(t('antwort.oder')) })}
        </p>
      )}
    </div>
  )
}
