// Entscheidungsleiste unten (Entscheidung 34) und der Kasten "Bitte genauer ansehen" (32.1).
// Passt nicht (1) · Unsicher (2) · ✓ Passt (3 / Enter). Gruende und Frage oeffnen sich ueber der
// Leiste. Ein gesperrtes "Passt" zeigt seinen Sperrgrund als Tooltip und im Infotext.

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui'
import type { PasstNichtGrund, PruefAufgabe } from '@/types'
import { InfoTip, Taste } from './InfoTip'
import { teilLabel } from './RichtigeAntwort'

export const GRUENDE: PasstNichtGrund[] = [
  'aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges',
]

export type Panel = 'nicht' | 'unsicher' | null

export function Auffaelligkeiten({ aufgabe, liste }: { aufgabe: PruefAufgabe; liste: PruefAufgabe['auffaelligkeiten'] }): JSX.Element | null {
  const { t } = useTranslation('pruefen')
  if (liste.length === 0) return null
  return (
    <section className="rounded-[var(--radius-md)] border border-[var(--color-warning)] bg-[var(--color-warning-light)] p-4" aria-live="polite">
      <h3 className="text-sm font-semibold text-[var(--color-warning)]">{t('auffaellig.titel')}</h3>
      <ul className="mt-1 list-disc pl-5 text-sm text-[var(--color-text-primary)]">
        {liste.map((a, i) => {
          const key = a.code === 'loesungsweg_endet_falsch' && a.stufe === 'teilweise' ? 'loesungsweg_endet_teilweise' : a.code
          const teil = a.teil !== null ? `${teilLabel(a.teil)} ${aufgabe.aufgabe.parts.find((p) => p.nr === a.teil)?.prompt ?? ''}`.trim() : ''
          return <li key={i}>{t(`auffaellig.${key}`, { wert: a.wert.replace(/-/g, '−'), teil })}</li>
        })}
      </ul>
    </section>
  )
}

type LeisteProps = {
  panel: Panel
  setPanel: (p: Panel) => void
  info: { art: 'sperre' | 'aenderungen' | 'vorbefuellt' | 'gesperrt'; text: string }
  passtGesperrt: string | null
  arbeitet: boolean
  fehler: string | null
  onPasst: () => void
  onNicht: (gruende: PasstNichtGrund[], notiz: string) => void
  onUnsicher: (frage: string) => void
}

export function Entscheidungsleiste(p: LeisteProps): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [gruende, setGruende] = useState<PasstNichtGrund[]>([])
  const [notiz, setNotiz] = useState('')
  const [frage, setFrage] = useState('')
  const [lokal, setLokal] = useState<string | null>(null)
  // Freigegeben oder vom Team beanstandet: Lena liest nur.
  const gesperrt = p.info.art === 'gesperrt'

  const schliessen = (): void => {
    p.setPanel(null)
    setLokal(null)
  }
  const nicht = (): void => {
    if (gruende.length === 0) return setLokal(t('leiste.fehltGrund'))
    if (gruende.includes('sonstiges') && !notiz.trim()) return setLokal(t('leiste.fehltSonstiges'))
    setLokal(null)
    p.onNicht(gruende, notiz.trim())
  }
  const unsicher = (): void => {
    if (!frage.trim()) return setLokal(t('leiste.fehltFrage'))
    setLokal(null)
    p.onUnsicher(frage.trim())
  }
  const meldung = lokal ?? p.fehler

  return (
    <div className="fixed inset-x-0 bottom-0 z-30 border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 pb-[calc(12px+env(safe-area-inset-bottom,0px))] pt-3 shadow-lg">
      <div className="mx-auto flex max-w-6xl flex-col gap-3">
        {p.panel === 'nicht' && (
          <div className="flex flex-col gap-2 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
            <span className="text-sm font-semibold">{t('leiste.nichtTitel')}</span>
            <div className="flex flex-wrap gap-2">
              {GRUENDE.map((g) => {
                const an = gruende.includes(g)
                return (
                  <button key={g} type="button" aria-pressed={an}
                    onClick={() => setGruende(an ? gruende.filter((x) => x !== g) : [...gruende, g])}
                    className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-3 text-sm',
                      an ? 'border-[var(--color-destructive)] bg-[var(--color-destructive-light)] font-semibold text-[var(--color-destructive)]'
                        : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]')}>
                    {t(`gruende.${g}`)}
                  </button>
                )
              })}
            </div>
            <input autoFocus aria-label={t('leiste.nichtWas')} placeholder={t('leiste.nichtWas')} value={notiz} onChange={(e) => setNotiz(e.target.value)}
              className="min-h-[44px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm" />
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" size="sm" onClick={schliessen}>{t('leiste.abbrechen')}</Button>
              <Button variant="destructive" size="sm" loading={p.arbeitet} onClick={nicht}>{t('leiste.nichtSpeichern')}</Button>
            </div>
          </div>
        )}
        {p.panel === 'unsicher' && (
          <div className="flex flex-col gap-2 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
            <label htmlFor="pruef-frage" className="text-sm font-semibold">{t('leiste.unsicherTitel')}</label>
            <textarea id="pruef-frage" autoFocus rows={2} value={frage} placeholder={t('leiste.unsicherPlatzhalter')}
              onChange={(e) => setFrage(e.target.value)}
              className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm" />
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" size="sm" onClick={schliessen}>{t('leiste.abbrechen')}</Button>
              <Button size="sm" loading={p.arbeitet} onClick={unsicher}
                className="bg-[var(--color-warning)]">{t('leiste.unsicherSpeichern')}</Button>
            </div>
          </div>
        )}
        {meldung && <p role="alert" className="text-sm text-[var(--color-destructive)]">{meldung}</p>}
        <div className="flex flex-wrap items-center gap-3">
          <p className="flex min-w-0 flex-[1_1_240px] items-center gap-2 text-sm text-[var(--color-text-secondary)]">
            <InfoTip schluessel="entscheidung" />
            <span className={cn(p.info.art === 'sperre' && 'font-semibold text-[var(--color-warning)]')}>{p.info.text}</span>
          </p>
          <div className="flex w-full flex-wrap gap-2 sm:w-auto">
            <button type="button" disabled={gesperrt} title={gesperrt ? p.info.text : undefined} aria-pressed={p.panel === 'nicht'} onClick={() => p.setPanel(p.panel === 'nicht' ? null : 'nicht')}
              className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-destructive)] px-4 text-sm font-semibold text-[var(--color-destructive)] hover:bg-[var(--color-destructive-light)] disabled:opacity-40 sm:flex-none">
              {t('leiste.passtNicht')} <Taste>1</Taste>
            </button>
            <button type="button" disabled={gesperrt} title={gesperrt ? p.info.text : undefined} aria-pressed={p.panel === 'unsicher'} onClick={() => p.setPanel(p.panel === 'unsicher' ? null : 'unsicher')}
              className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-warning)] px-4 text-sm font-semibold text-[var(--color-warning)] hover:bg-[var(--color-warning-light)] disabled:opacity-40 sm:flex-none">
              {t('leiste.unsicher')} <Taste>2</Taste>
            </button>
            <span title={p.passtGesperrt ?? (gesperrt ? p.info.text : undefined)} className="flex flex-1 sm:flex-none">
              <button type="button" disabled={!!p.passtGesperrt || gesperrt || p.arbeitet} onClick={p.onPasst}
                aria-describedby={p.passtGesperrt ? 'pruef-sperre' : undefined}
                className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] bg-[var(--color-success)] px-8 text-sm font-semibold text-white hover:brightness-110 disabled:cursor-not-allowed disabled:bg-[var(--color-neutral-disabled)]">
                {t('leiste.passt')} <Taste>3</Taste>
              </button>
              {p.passtGesperrt && <span id="pruef-sperre" className="sr-only">{p.passtGesperrt}</span>}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

/** Meldung nach einer Entscheidung, 5 s lang mit "Rueckgaengig" (Entscheidung 34). */
export function EntscheidungsMeldung({ text, onRueckgaengig, onZu }: { text: string; onRueckgaengig?: () => void; onZu: () => void }): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <div role="status" className="fixed bottom-36 left-1/2 z-40 flex max-w-[calc(100%-32px)] -translate-x-1/2 items-center gap-3 rounded-[var(--radius-md)] bg-[var(--color-navy-deep)] py-2 pl-4 pr-2 text-sm text-[var(--color-stage-text)] shadow-lg animate-scale-in sm:bottom-28">
      <span>{text}</span>
      {onRueckgaengig && (
        <button type="button" onClick={onRueckgaengig} className="min-h-[44px] rounded-[var(--radius-sm)] border border-[var(--color-stage-text)] px-3 text-sm">
          {t('meldung.rueckgaengig')}
        </button>
      )}
      <button type="button" onClick={onZu} aria-label={t('meldung.schliessen')} className="min-h-[44px] min-w-[44px] text-lg leading-none">×</button>
    </div>
  )
}
