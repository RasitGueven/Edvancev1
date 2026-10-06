// Entscheidungsleiste der Admin-Pruefansicht (Bauauftrag C 8 bis C 12): unten, immer sichtbar. Links der
// Infotext, rechts hoechstens zwei Knoepfe und ein „…“-Menue (leistenKnoepfe). Ueber der Leiste oeffnen sich
// „Antwort an Lena“ (Rueckfrage), „Nachricht an Lena“, die Gruende fuers Zurueckweisen und die Rueckfrage
// vor „Freigabe zuruecknehmen“. Ein gesperrter Knopf zeigt seinen Sperrgrund als Tooltip.

import { useEffect, useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { MoreHorizontal } from 'lucide-react'
import { Button } from '@/components/ui'
import { GRUENDE } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { InfoTip, Taste } from '@/components/edvance/pruefen/InfoTip'
import { leisteLinks } from '@/components/edvance/pruefen/leistenRand'
import { useImShell } from '@/components/edvance/shell/shellContext'
import { cn } from '@/lib/utils'
import type { LeistenAktion, LeistenKnoepfe } from '@/lib/pruefung/leiste'
import type { PasstNichtGrund } from '@/types'

export type LeistenPanel = 'anLena' | 'zurueckweisen' | 'freigabeZurueck' | null

export type LeistenEingabe = { nachricht?: string; gruende?: PasstNichtGrund[]; notiz?: string }

type Props = {
  knoepfe: LeistenKnoepfe
  info: { text: string; warnung: boolean }
  /** Sperrgrund fuer „Freigeben“ (erster Befund vor der Freigabe), sonst null. */
  freigebenGesperrt: string | null
  /** Rueckfrage: das Feld „Antwort an Lena“ steht immer ueber der Leiste. */
  rueckfrage: boolean
  antwort: string
  setAntwort: (a: string) => void
  /** Lena hat nie bewertet: „Nachricht an Lena“ ist gesperrt, mit diesem Grund. */
  nachrichtGesperrt: string | null
  /** Bei Ausschluss: der uebersetzte Grund fuer „Auf Offen setzen“. */
  ausschluss: string | null
  panel: LeistenPanel
  setPanel: (p: LeistenPanel) => void
  arbeitet: boolean
  fehler: string | null
  onAktion: (a: LeistenAktion, eingabe?: LeistenEingabe) => void
}

const FELD = 'w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm disabled:opacity-60'
const PANEL = 'flex flex-col gap-2 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4'

export function AdminLeiste(p: Props): JSX.Element {
  const imShell = useImShell()
  const { t } = useTranslation('pruefenAdmin')
  const { t: tp } = useTranslation('pruefen')
  const [menue, setMenue] = useState(false)
  const [nachricht, setNachricht] = useState('')
  const [gruende, setGruende] = useState<PasstNichtGrund[]>([])
  const [notiz, setNotiz] = useState('')
  const [lokal, setLokal] = useState<string | null>(null)
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

  const klick = (a: LeistenAktion): void => {
    setMenue(false)
    setLokal(null)
    if (a === 'freigeben' || a === 'editor') return p.onAktion(a)
    // Bei einer Rueckfrage steht die Antwort schon ueber der Leiste: direkt ausfuehren.
    if (a === 'anLena' && p.rueckfrage) return p.onAktion('anLena', { nachricht: p.antwort })
    p.setPanel(a === 'aufOffen' ? 'anLena' : a)
  }
  const zurueckweisen = (): void => {
    if (gruende.length === 0) return setLokal(t('leiste.fehltGrund'))
    p.onAktion('zurueckweisen', { gruende, notiz, nachricht: p.antwort })
  }
  const knopf = (a: LeistenAktion, primaer: boolean): JSX.Element => {
    if (a === 'freigeben') {
      const sperre = p.freigebenGesperrt
      return (
        <span key={a} title={sperre ?? undefined} className="flex flex-1 sm:flex-none">
          <button type="button" disabled={!!sperre || p.arbeitet} onClick={() => klick(a)}
            aria-describedby={sperre ? 'admin-sperre' : undefined}
            className="flex min-h-[44px] flex-1 items-center justify-center gap-2 rounded-[var(--radius-md)] bg-[var(--color-success)] px-6 text-sm font-semibold text-white hover:brightness-110 disabled:cursor-not-allowed disabled:bg-[var(--color-neutral-disabled)]">
            ✓ {t('leiste.freigeben')} <Taste>↵</Taste>
          </button>
          {sperre && <span id="admin-sperre" className="sr-only">{sperre}</span>}
        </span>
      )
    }
    return (
      <Button key={a} variant={primaer ? 'primary' : 'outline'} loading={p.arbeitet && primaer} disabled={p.arbeitet}
        onClick={() => klick(a)} className="flex-1 sm:flex-none">
        {t(`leiste.${a}`)}
        {a === 'editor' && <Taste>E</Taste>}
      </Button>
    )
  }

  const meldung = lokal ?? p.fehler
  return (
    <div className={`fixed right-0 ${leisteLinks(imShell)} bottom-0 z-30 border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 pb-[calc(12px+env(safe-area-inset-bottom,0px))] pt-3 shadow-elevation-lg`}>
      <div className="mx-auto flex max-w-6xl flex-col gap-3">
        {p.rueckfrage && p.panel === null && (
          <div className={PANEL}>
            <label htmlFor="admin-antwort" className="text-sm font-semibold">
              {t('leiste.antwortLabel')} <span className="font-normal text-[var(--color-text-tertiary)]">{t('leiste.optional')}</span>
            </label>
            <textarea id="admin-antwort" rows={2} value={p.antwort} placeholder={t('leiste.antwortPlatzhalter')}
              onChange={(e) => p.setAntwort(e.target.value)} className={FELD} />
          </div>
        )}
        {p.panel === 'anLena' && (
          <div className={PANEL}>
            {p.ausschluss ? (
              <p className="text-sm">{t('leiste.aufOffenText', { grund: p.ausschluss })}</p>
            ) : (
              <>
                <label htmlFor="admin-nachricht" className="text-sm font-semibold">
                  {t('leiste.nachrichtLabel')} <span className="font-normal text-[var(--color-text-tertiary)]">{t('leiste.nachrichtHinweis')}</span>
                </label>
                <textarea id="admin-nachricht" autoFocus={!p.nachrichtGesperrt} rows={2} value={nachricht}
                  disabled={!!p.nachrichtGesperrt} title={p.nachrichtGesperrt ?? undefined}
                  onChange={(e) => setNachricht(e.target.value)} className={FELD} />
                {p.nachrichtGesperrt && <p className="text-xs text-[var(--color-text-tertiary)]">{p.nachrichtGesperrt}</p>}
              </>
            )}
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" onClick={() => p.setPanel(null)}>{t('leiste.abbrechen')}</Button>
              <Button loading={p.arbeitet} onClick={() => p.onAktion(p.ausschluss ? 'aufOffen' : 'anLena', { nachricht })}>
                {t(p.ausschluss ? 'leiste.aufOffen' : 'leiste.anLena')}
              </Button>
            </div>
          </div>
        )}
        {p.panel === 'zurueckweisen' && (
          <div className={PANEL}>
            <span className="text-sm font-semibold">{t('leiste.zurueckweisenTitel')}</span>
            <div className="flex flex-wrap gap-2">
              {GRUENDE.map((g) => {
                const an = gruende.includes(g)
                return (
                  <button key={g} type="button" aria-pressed={an} onClick={() => setGruende(an ? gruende.filter((x) => x !== g) : [...gruende, g])}
                    className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-3 text-sm',
                      an ? 'border-[var(--color-destructive)] bg-[var(--color-destructive-light)] font-semibold text-[var(--color-destructive)]'
                        : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]')}>
                    {tp(`gruende.${g}`)}
                  </button>
                )
              })}
            </div>
            <input aria-label={t('leiste.wasGenau')} placeholder={t('leiste.wasGenau')} value={notiz} onChange={(e) => setNotiz(e.target.value)}
              className={cn(FELD, 'min-h-[44px] py-0')} />
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" onClick={() => p.setPanel(null)}>{t('leiste.abbrechen')}</Button>
              <Button variant="destructive" loading={p.arbeitet} onClick={zurueckweisen}>{t('leiste.zurueckweisen')}</Button>
            </div>
          </div>
        )}
        {p.panel === 'freigabeZurueck' && (
          <div className={cn(PANEL, 'sm:flex-row sm:items-center sm:justify-between')}>
            <span className="text-sm font-semibold">{t('leiste.zuruecknehmenFrage')}</span>
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="ghost" onClick={() => p.setPanel(null)}>{t('leiste.abbrechen')}</Button>
              <Button loading={p.arbeitet} onClick={() => p.onAktion('freigabeZurueck')}>{t('leiste.zuruecknehmen')}</Button>
            </div>
          </div>
        )}
        {meldung && <p role="alert" className="text-sm text-[var(--color-destructive)]">{meldung}</p>}
        <div className="flex flex-wrap items-center gap-3">
          <p className="flex min-w-0 flex-[1_1_240px] items-center gap-2 text-sm text-[var(--color-text-secondary)]">
            <InfoTip schluessel="entscheidung" />
            <span className={cn(p.info.warnung && 'font-semibold text-[var(--color-warning)]')}>{p.info.text}</span>
          </p>
          <div ref={box} className="relative flex w-full flex-wrap gap-2 sm:w-auto">
            {p.knoepfe.sekundaer && knopf(p.knoepfe.sekundaer, false)}
            {p.knoepfe.primaer && knopf(p.knoepfe.primaer, true)}
            {p.knoepfe.menue.length > 0 && (
              <Button size="icon" variant="outline" aria-label={t('leiste.mehr')} title={t('leiste.mehr')} aria-haspopup="menu"
                aria-expanded={menue} onClick={() => setMenue((m) => !m)}>
                <MoreHorizontal className="h-4 w-4" aria-hidden="true" />
              </Button>
            )}
            {menue && (
              <div role="menu" className="absolute bottom-full right-0 z-40 mb-2 min-w-56 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-1 shadow-elevation-lg">
                {p.knoepfe.menue.map((a) => (
                  <button key={a} type="button" role="menuitem" onClick={() => klick(a)}
                    className={cn('flex min-h-[44px] w-full items-center rounded-[var(--radius-sm)] px-3 text-left text-sm hover:bg-[var(--color-bg-subtle)]',
                      (a === 'zurueckweisen' || a === 'freigabeZurueck') && 'text-[var(--color-destructive)]')}>
                    {t(`leiste.${a}`)}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
