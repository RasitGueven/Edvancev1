// Kleine Bausteine der Prüfansicht (SP-1 S4): Abschnittstitel, Etikett, Kommentar-Knopf, Ankerkarte (markiert und
// anspringbar), Wert-Text einer Antwort.
import type { JSX, ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { MessageSquarePlus, MessageSquareText } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { loesungText } from '../loesungText'

export const Abschnitt = ({ children }: { children: string }): JSX.Element => (
  <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">{children}</h2>
)

export const Etikett = ({ children, ton = 'grau' }: { children: ReactNode; ton?: 'grau' | 'blau' | 'kuerzel' }): JSX.Element => (
  <span
    className={`inline-flex items-center rounded-[var(--radius-sm)] px-2 py-0.5 text-xs font-semibold ${
      ton === 'blau'
        ? 'bg-[var(--color-primary-light)] text-[var(--color-primary)]'
        : ton === 'kuerzel'
          ? 'bg-[var(--color-bg-subtle)] font-mono font-medium text-[var(--color-text-tertiary)]'
          : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]'
    }`}
  >
    {children}
  </span>
)

export function KommentarKnopf({ aktiv, onClick, ort }: { aktiv: boolean; onClick: () => void; ort: string }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const Icon = aktiv ? MessageSquareText : MessageSquarePlus
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={aktiv}
      aria-label={`${t(aktiv ? 'ansicht.kommentiert' : 'ansicht.kommentar')}: ${ort}`}
      className={`inline-flex min-h-[44px] shrink-0 items-center gap-2 rounded-[var(--radius-full)] border px-4 text-sm font-semibold focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
        aktiv
          ? 'border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]'
          : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-primary)] hover:bg-[var(--color-primary-light)]'
      }`}
    >
      <Icon aria-hidden="true" className="h-4 w-4" />
      {t(aktiv ? 'ansicht.kommentiert' : 'ansicht.kommentar')}
    </button>
  )
}

/** Karte, an der ein Kommentar hängen kann: id zum Anspringen, Rahmen markiert, solange kommentiert. */
export function AnkerKarte({ id, markiert, children }: { id: string; markiert: boolean; children: ReactNode }): JSX.Element {
  return (
    <section id={id} tabIndex={-1} className="scroll-mt-4 rounded-[var(--radius-lg)] focus:outline-none">
      <EdvanceCard
        className={`flex flex-col gap-4 ${markiert ? 'ring-2 ring-[var(--color-gold-warning)]' : ''}`}
      >
        {children}
      </EdvanceCard>
    </section>
  )
}

/** Antwort als Text: Zeichenkette direkt, sonst die Kurzform aus loesungText. */
export function wertText(w: unknown): string {
  if (typeof w === 'string') return w
  if (w && typeof w === 'object' && typeof (w as { wert?: unknown }).wert === 'string') return (w as { wert: string }).wert
  return loesungText(w as Record<string, unknown> | null)
}
