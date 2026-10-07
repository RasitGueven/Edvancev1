// Entscheidungsleiste fuer eine Kernidee (L6), wie bei den Aufgaben: Passt nicht (1) · Unsicher (2) ·
// ✓ Passt (3). Gruende bzw. Frage oeffnen sich ueber der Leiste. Gesperrte Knoepfe nennen ihren Grund
// als Tooltip (CLAUDE.md §11: keine Disabled-Buttons ohne Tooltip).

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui'
import { Taste } from '@/components/edvance/pruefen/InfoTip'
import { leisteLinks } from '@/components/edvance/pruefen/leistenRand'
import { useImShell } from '@/components/edvance/shell/shellContext'
import { ERKLAER_GRUENDE } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerGrund } from '@/types/erklaerPruefung'

export type ErklaerPanel = 'nicht' | 'unsicher' | null

type Props = {
  panel: ErklaerPanel
  setPanel: (p: ErklaerPanel) => void
  /** Satz links neben den Knoepfen (Stand, Hinweis). */
  info: string
  /** Grund, warum „Passt“ gesperrt ist; null = frei. */
  passtGesperrt: string | null
  /** Grund, warum „Passt nicht“ gesperrt ist (z. B. freigegeben); null = frei. */
  nichtGesperrt: string | null
  arbeitet: boolean
  fehler: string | null
  onPasst: () => void
  onNicht: (gruende: ErklaerGrund[], notiz: string) => void
  onUnsicher: (frage: string) => void
}

export function ErklaerLeiste(p: Props): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const imShell = useImShell()
  const [gruende, setGruende] = useState<ErklaerGrund[]>([])
  const [notiz, setNotiz] = useState('')
  const [frage, setFrage] = useState('')
  const [lokal, setLokal] = useState<string | null>(null)

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
  const feld = 'min-h-[44px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'

  return (
    <div className={`fixed right-0 ${leisteLinks(imShell)} bottom-0 z-30 border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 pb-[calc(12px+env(safe-area-inset-bottom,0px))] pt-3 shadow-lg`}>
      <div className="mx-auto flex max-w-6xl flex-col gap-2">
        {p.panel === 'nicht' && (
          <div className="flex flex-col gap-2 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
            <span className="text-sm font-semibold">{t('leiste.nichtTitel')}</span>
            <div className="flex flex-wrap gap-2">
              {ERKLAER_GRUENDE.map((g) => {
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
            <input autoFocus aria-label={t('leiste.nichtWas')} placeholder={t('leiste.nichtWas')} value={notiz}
              onChange={(e) => setNotiz(e.target.value)} className={feld} />
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" size="sm" onClick={schliessen}>{t('leiste.abbrechen')}</Button>
              <Button variant="destructive" size="sm" loading={p.arbeitet} onClick={nicht}>{t('leiste.nichtSpeichern')}</Button>
            </div>
          </div>
        )}
        {p.panel === 'unsicher' && (
          <div className="flex flex-col gap-2 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
            <label htmlFor="erklaer-frage" className="text-sm font-semibold">{t('leiste.unsicherTitel')}</label>
            <textarea id="erklaer-frage" autoFocus rows={2} value={frage} placeholder={t('leiste.unsicherPlatzhalter')}
              onChange={(e) => setFrage(e.target.value)}
              className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm" />
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" size="sm" onClick={schliessen}>{t('leiste.abbrechen')}</Button>
              <Button size="sm" loading={p.arbeitet} onClick={unsicher} className="bg-[var(--color-warning)]">
                {t('leiste.unsicherSpeichern')}
              </Button>
            </div>
          </div>
        )}
        {meldung && <p role="alert" className="text-sm text-[var(--color-destructive)]">{meldung}</p>}
        <div className="flex flex-wrap items-center gap-2">
          <p className="min-w-0 flex-[1_1_240px] text-sm text-[var(--color-text-secondary)]">{p.info}</p>
          <div className="flex w-full flex-wrap gap-2 sm:w-auto">
            <span title={p.nichtGesperrt ?? undefined} className="flex flex-1 sm:flex-none">
              <button type="button" disabled={!!p.nichtGesperrt} aria-pressed={p.panel === 'nicht'}
                onClick={() => p.setPanel(p.panel === 'nicht' ? null : 'nicht')}
                className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-destructive)] px-4 text-sm font-semibold text-[var(--color-destructive)] hover:bg-[var(--color-destructive-light)] disabled:opacity-40">
                {t('leiste.passtNicht')} <Taste>1</Taste>
              </button>
            </span>
            <button type="button" aria-pressed={p.panel === 'unsicher'} onClick={() => p.setPanel(p.panel === 'unsicher' ? null : 'unsicher')}
              className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-warning)] px-4 text-sm font-semibold text-[var(--color-warning)] hover:bg-[var(--color-warning-light)] sm:flex-none">
              {t('leiste.unsicher')} <Taste>2</Taste>
            </button>
            <span title={p.passtGesperrt ?? undefined} className="flex flex-1 sm:flex-none">
              <button type="button" disabled={!!p.passtGesperrt || p.arbeitet} onClick={p.onPasst}
                className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] bg-[var(--color-success)] px-8 text-sm font-semibold text-[var(--color-text-inverse)] hover:brightness-110 disabled:cursor-not-allowed disabled:bg-[var(--color-neutral-disabled)]">
                {t('leiste.passt')} <Taste>3</Taste>
              </button>
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}
