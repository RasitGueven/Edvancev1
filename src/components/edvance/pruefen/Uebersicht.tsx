// Uebersicht "Aufgaben pruefen" (Entscheidung 29): Karte "Als Naechstes", Reiter je Stufe,
// Themenliste mit Balken und "x / y"; ein Thema klappt auf und zeigt seine Aufgaben. Dazu der
// Abschluss (Anforderung G 52).

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ChevronRight } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui'
import { cn } from '@/lib/utils'
import { stand, themenDerStufe, type Stand } from '@/lib/pruefung/reihenfolge'
import type { LenaStatus, PruefBoardZeile, Stufe } from '@/types'
import { Taste } from './InfoTip'

const STATUS_FARBE: Record<LenaStatus, string> = {
  offen: 'text-[var(--color-text-tertiary)]',
  passt: 'text-[var(--color-success)]',
  unsicher: 'text-[var(--color-warning)]',
  passt_nicht: 'text-[var(--color-destructive)]',
  freigegeben: 'text-[var(--color-success)]',
}

function Pille({ farbe, children }: { farbe?: string; children: string }): JSX.Element {
  return <span className={cn('rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)] px-3 py-0.5 text-xs', farbe)}>{children}</span>
}

export function Kennzahlen({ s }: { s: Stand }): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <div className="flex flex-wrap gap-2">
      <Pille>{t('naechstes.geprueft', { x: s.geprueft, y: s.gesamt })}</Pille>
      <Pille farbe="bg-[var(--color-success-light)] text-[var(--color-success)]">{t('naechstes.passt', { n: s.passt })}</Pille>
      {s.geaendert > 0 && <Pille farbe="bg-[var(--color-primary-light)] text-[var(--color-primary)]">{t('naechstes.geaendert', { n: s.geaendert })}</Pille>}
      <Pille farbe="bg-[var(--color-warning-light)] text-[var(--color-warning)]">{t('naechstes.unsicher', { n: s.unsicher })}</Pille>
      <Pille farbe="bg-[var(--color-destructive-light)] text-[var(--color-destructive)]">{t('naechstes.passtNicht', { n: s.passtNicht })}</Pille>
    </div>
  )
}

type NaechstesProps = {
  board: PruefBoardZeile[]
  naechste: PruefBoardZeile | null
  position: { nr: number; anzahl: number } | null
  onWeiter: () => void
}

export function AlsNaechstes({ board, naechste, position, onWeiter }: NaechstesProps): JSX.Element {
  const { t } = useTranslation('pruefen')
  const s = stand(board)
  return (
    <EdvanceCard className="grid gap-4 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center">
      <div className="flex flex-col gap-2">
        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {naechste ? t('naechstes.eyebrow') : t('naechstes.fertigEyebrow')}
        </span>
        <h2 className="text-sm font-semibold text-[var(--color-text-primary)]">
          {naechste && position
            ? t('naechstes.position', { thema: naechste.thema_label, nr: position.nr, anzahl: position.anzahl })
            : t('naechstes.alleBewertet')}
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)]">
          {!naechste ? t('naechstes.alleBewertetText')
            : s.geprueft > 0 ? t('naechstes.weiter') : t('naechstes.erstesMal', { stufe: t(`stufe.${naechste.stufe}`) })}
        </p>
        <Kennzahlen s={s} />
      </div>
      {naechste && (
        <Button size="lg" onClick={onWeiter}>
          {t('naechstes.knopf')} <Taste>Enter</Taste>
        </Button>
      )}
    </EdvanceCard>
  )
}

type ListeProps = {
  board: PruefBoardZeile[]
  stufen: Stufe[]
  aktiv: Stufe
  offen: Set<string>
  onReiter: (s: Stufe) => void
  onThema: (key: string) => void
  onPruefen: (key: string) => void
  onAufgabe: (id: string) => void
}

export function Themenliste({ board, stufen, aktiv, offen, onReiter, onThema, onPruefen, onAufgabe }: ListeProps): JSX.Element {
  const { t } = useTranslation('pruefen')
  const statusText = (z: PruefBoardZeile): string =>
    z.lena_status === 'passt' && z.geaendert ? t('status.passtGeaendert') : t(`status.${z.lena_status}`)
  return (
    <div className="flex flex-col gap-4">
      <div role="tablist" className="flex flex-wrap gap-2">
        {stufen.map((s) => {
          const st = stand(board.filter((z) => z.stufe === s))
          return (
            <button key={s} type="button" role="tab" aria-selected={s === aktiv} onClick={() => onReiter(s)}
              className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-4 text-sm',
                s === aktiv ? 'border-[var(--color-primary)] bg-[var(--color-primary)] font-semibold text-white'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]')}>
              {t(`stufe.${s}`)} <span className="ml-1 opacity-75">{t('themen.reiterZahl', { x: st.geprueft, y: st.gesamt })}</span>
            </button>
          )
        })}
      </div>
      <div className="flex flex-col gap-2">
        {themenDerStufe(board, aktiv).map((g) => {
          const st = stand(g.zeilen)
          const auf = offen.has(g.thema_key)
          const anteil = (n: number): string => `${(n / Math.max(st.gesamt, 1)) * 100}%`
          return (
            <EdvanceCard key={g.thema_key} className="flex flex-col gap-3 p-4">
              <div className="flex flex-wrap items-center gap-3">
                <button type="button" aria-expanded={auf} onClick={() => onThema(g.thema_key)}
                  aria-label={t(auf ? 'themen.zuklappen' : 'themen.aufklappen', { thema: g.label })}
                  className="flex min-h-[44px] min-w-0 flex-1 items-center gap-2 text-left">
                  <ChevronRight className={cn('h-4 w-4 shrink-0 text-[var(--color-text-tertiary)] transition-transform', auf && 'rotate-90')} aria-hidden="true" />
                  <span className="min-w-0 text-sm font-semibold text-[var(--color-text-primary)]">{g.label}</span>
                </button>
                <div className="hidden h-1.5 w-36 overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)] sm:flex" aria-hidden="true">
                  <span className="h-full bg-[var(--color-success)]" style={{ width: anteil(st.passt + st.freigegeben) }} />
                  <span className="h-full bg-[var(--color-warning)]" style={{ width: anteil(st.unsicher) }} />
                  <span className="h-full bg-[var(--color-destructive)]" style={{ width: anteil(st.passtNicht) }} />
                </div>
                <span className="w-14 text-right text-sm text-[var(--color-text-secondary)]">{t('themen.zaehler', { x: st.geprueft, y: st.gesamt })}</span>
                <Button variant="secondary" size="sm" onClick={() => onPruefen(g.thema_key)}>{t('themen.pruefen')}</Button>
              </div>
              {auf && (
                <ul className="flex flex-col border-t border-[var(--color-border)]">
                  {g.zeilen.map((z, i) => (
                    <li key={z.task_id}>
                      <button type="button" onClick={() => onAufgabe(z.task_id)}
                        className="flex min-h-[44px] w-full items-center gap-3 border-b border-[var(--color-border)] py-2 text-left text-sm hover:bg-[var(--color-bg-subtle)]">
                        <span className="flex min-w-0 flex-1 flex-col">
                          <span className="font-medium text-[var(--color-text-primary)]">{t('themen.aufgabe', { nr: i + 1, titel: z.kurztitel })}</span>
                          <span className="text-xs text-[var(--color-text-tertiary)]">{z.skill_label}</span>
                        </span>
                        <span className={cn('whitespace-nowrap text-xs', STATUS_FARBE[z.lena_status])}>{statusText(z)}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </EdvanceCard>
          )
        })}
      </div>
    </div>
  )
}

type AbschlussProps = { board: PruefBoardZeile[]; schnitt: number | null; onOffene: () => void; onUebersicht: () => void }

export function Abschluss({ board, schnitt, onOffene, onUebersicht }: AbschlussProps): JSX.Element {
  const { t } = useTranslation('pruefen')
  const s = stand(board)
  const zahlen: { label: string; wert: number; farbe: string; zusatz?: string }[] = [
    { label: t('abschluss.passt'), wert: s.passt, farbe: 'text-[var(--color-success)]',
      zusatz: s.geaendert ? t('abschluss.davonGeaendert', { n: s.geaendert }) : undefined },
    { label: t('abschluss.unsicher'), wert: s.unsicher, farbe: 'text-[var(--color-warning)]' },
    { label: t('abschluss.passtNicht'), wert: s.passtNicht, farbe: 'text-[var(--color-destructive)]' },
    { label: t('abschluss.offen'), wert: s.offen, farbe: 'text-[var(--color-text-primary)]' },
  ]
  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">{t('abschluss.titel')}</h1>
        <p className="text-sm text-[var(--color-text-secondary)]">{t('abschluss.text')}</p>
      </div>
      <EdvanceCard className="flex flex-col gap-4">
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          {zahlen.map((z) => (
            <div key={z.label} className="flex flex-col gap-1 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3">
              <span className="text-sm text-[var(--color-text-secondary)]">{z.label}</span>
              <span className={cn('text-3xl font-bold', z.farbe)}>{z.wert}</span>
              {z.zusatz && <span className="text-sm text-[var(--color-primary)]">{z.zusatz}</span>}
            </div>
          ))}
        </div>
        {schnitt !== null && <p className="text-sm text-[var(--color-text-secondary)]">{t('abschluss.schnitt', { count: schnitt })}</p>}
        <div className="flex flex-wrap gap-2">
          {s.offen > 0 && <Button onClick={onOffene}>{t('abschluss.offenePruefen')}</Button>}
          <Button variant="secondary" onClick={onUebersicht}>{t('abschluss.zurUebersicht')}</Button>
        </div>
      </EdvanceCard>
    </div>
  )
}
