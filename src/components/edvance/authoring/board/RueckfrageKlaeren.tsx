// Rueckfrage klaeren (Entscheidung 40, Festlegung Rasit zu PR 208): hoechstens zwei Knoepfe.
// "Freigeben" primaer, "Zurueck an Lena" sekundaer; "Zurueckweisen" steckt im "…"-Menue und
// verlangt weiter mindestens einen Grund.

import { useEffect, useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { MoreHorizontal } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { fehlerSchluessel } from '@/lib/pruefung/texte'
import { pruefRueckfrageKlaeren } from '@/lib/supabase/pruefung'
import { GRUENDE } from '@/components/edvance/pruefen/Entscheidungsleiste'
import type { PasstNichtGrund, PruefRueckfrageAktion } from '@/types'

export function RueckfrageKlaeren({ taskId, onReload }: { taskId: string; onReload: () => void }): JSX.Element {
  const { t } = useTranslation('authoring')
  const { t: tp } = useTranslation('pruefen')
  const [antwort, setAntwort] = useState('')
  const [gruende, setGruende] = useState<PasstNichtGrund[]>([])
  const [menue, setMenue] = useState(false)
  const [ablehnen, setAblehnen] = useState(false)
  const [busy, setBusy] = useState(false)
  const [meldung, setMeldung] = useState<string | null>(null)
  const box = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!menue) return
    const zu = (e: Event): void => {
      if (e instanceof KeyboardEvent && e.key !== 'Escape') return
      if (e instanceof PointerEvent && box.current?.contains(e.target as Node)) return
      setMenue(false)
    }
    document.addEventListener('keydown', zu)
    document.addEventListener('pointerdown', zu)
    return () => {
      document.removeEventListener('keydown', zu)
      document.removeEventListener('pointerdown', zu)
    }
  }, [menue])

  const klaeren = async (aktion: PruefRueckfrageAktion): Promise<void> => {
    if (aktion === 'zurueckweisen' && gruende.length === 0) return setMeldung(t('lena.fehltGrund'))
    setBusy(true)
    setMeldung(null)
    const res = await pruefRueckfrageKlaeren(taskId, aktion, antwort, aktion === 'zurueckweisen' ? gruende : undefined)
    setBusy(false)
    if (res.error) return setMeldung(res.error.code === 'P0001' ? res.error.message : tp(fehlerSchluessel(res.error) ?? 'fehlermeldung.allgemein'))
    onReload()
  }

  return (
    <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-2">
      <label htmlFor={`antwort-${taskId}`}>{t('lena.antwortLabel')}</label>
      <textarea id={`antwort-${taskId}`} rows={2} value={antwort} placeholder={t('lena.antwortPlatzhalter')}
        onChange={(e) => setAntwort(e.target.value)}
        className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-2 text-sm" />
      {ablehnen ? (
        <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-destructive)] p-2">
          <span>{t('lena.zurueckweisenGruende')}</span>
          <div className="flex flex-wrap gap-2">
            {GRUENDE.map((g) => {
              const an = gruende.includes(g)
              return (
                <button key={g} type="button" aria-pressed={an} onClick={() => setGruende(an ? gruende.filter((x) => x !== g) : [...gruende, g])}
                  className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-3',
                    an ? 'border-[var(--color-destructive)] text-[var(--color-destructive)]' : 'border-[var(--color-border)]')}>
                  {tp(`gruende.${g}`)}
                </button>
              )
            })}
          </div>
          <div className="flex flex-wrap gap-2">
            <Button size="sm" variant="destructive" loading={busy} onClick={() => void klaeren('zurueckweisen')}>{t('lena.zurueckweisen')}</Button>
            <Button size="sm" variant="ghost" onClick={() => { setAblehnen(false); setMeldung(null) }}>{t('lena.abbrechen')}</Button>
          </div>
        </div>
      ) : (
        <div ref={box} className="relative flex flex-wrap items-center gap-2">
          <Button size="sm" loading={busy} onClick={() => void klaeren('freigeben')}>{t('lena.freigeben')}</Button>
          <Button size="sm" variant="outline" loading={busy} onClick={() => void klaeren('an_lena')}>{t('lena.anLena')}</Button>
          <Button size="icon" variant="ghost" aria-label={t('lena.weitereAktionen')} aria-haspopup="menu" aria-expanded={menue}
            onClick={() => setMenue((m) => !m)}>
            <MoreHorizontal className="h-4 w-4" aria-hidden="true" />
          </Button>
          {menue && (
            <div role="menu" className="absolute left-0 top-full z-20 mt-1 min-w-48 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-1 shadow-lg">
              <button type="button" role="menuitem" onClick={() => { setMenue(false); setAblehnen(true) }}
                className="flex min-h-[44px] w-full items-center rounded-[var(--radius-sm)] px-3 text-left text-sm text-[var(--color-destructive)] hover:bg-[var(--color-destructive-light)]">
                {t('lena.zurueckweisenMenue')}
              </button>
            </div>
          )}
        </div>
      )}
      {meldung && <p role="alert" className="text-[var(--color-destructive)]">{meldung}</p>}
    </div>
  )
}
