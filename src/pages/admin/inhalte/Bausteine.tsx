// IU-1 U2: kleine Bausteine der Inhalte-Übersicht (Balken, Ampel, nächste Schritte, Zeitfenster).
import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'

import { EdvanceBadge } from '@/components/edvance'
import { anteile, monate, type Schritt } from '@/lib/inhalte/uebersicht'

/** Farben der Balkenteile, nur aus Tokens. */
export const FARBE = {
  gut: 'bg-[var(--color-success)]',
  primaer: 'bg-[var(--color-primary)]',
  achtung: 'bg-[var(--color-warning)]',
  offen: 'bg-[var(--color-neutral-inactive)]',
  handeln: 'bg-[var(--color-error-coach)]',
} as const
export type Farbe = keyof typeof FARBE

/** Gestapelter Balken; Breiten sind berechnet (einzige Inline-Styles). */
export function Stapel({ teile, label }: { teile: { wert: number; farbe: Farbe }[]; label: string }): JSX.Element {
  const p = anteile(teile.map((t) => t.wert))
  return (
    <div role="img" aria-label={label}
      className="flex h-2 w-36 overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)]">
      {teile.map((t, i) => (
        <span key={i} className={`block h-full ${FARBE[t.farbe]}`} style={{ width: `${p[i]}%` }} />
      ))}
    </div>
  )
}

export function Legende({ eintraege }: { eintraege: { text: string; farbe: Farbe }[] }): JSX.Element {
  return (
    <div className="flex flex-wrap gap-4 px-4 py-2 text-xs text-[var(--color-text-secondary)]">
      {eintraege.map((e) => (
        <span key={e.text} className="inline-flex items-center gap-2">
          <span aria-hidden="true" className={`inline-block h-2.5 w-2.5 rounded-[var(--radius-sm)] ${FARBE[e.farbe]}`} />
          {e.text}
        </span>
      ))}
    </div>
  )
}

export function Ampel({ farbe, text, unter }: { farbe: Farbe; text: string; unter?: string }): JSX.Element {
  return (
    <div className="flex flex-col gap-1">
      <span className="inline-flex items-center gap-2 whitespace-nowrap font-semibold text-[var(--color-text-primary)]">
        <span aria-hidden="true" className={`inline-block h-2.5 w-2.5 rounded-[var(--radius-full)] ${FARBE[farbe]}`} />
        {text}
      </span>
      {unter && <span className="text-xs text-[var(--color-text-secondary)]">{unter}</span>}
    </div>
  )
}

/** „Wer: was“ je Zeile; mit Ziel als Link zur Stelle, an der die Arbeit passiert. */
export function Schritte({ schritte }: { schritte: Schritt[] }): JSX.Element {
  const { t } = useTranslation('admin')
  return (
    <div className="flex flex-col gap-1 text-xs text-[var(--color-text-secondary)]">
      {schritte.map((s) => {
        const inhalt: ReactNode = (
          <>
            <span className="font-semibold text-[var(--color-text-primary)]">{t(`inhalte.schritt.${s.wer}`)}:</span>{' '}
            {t(`inhalte.schritt.${s.art}`, { count: s.anzahl })}
          </>
        )
        return s.ziel ? (
          <Link key={s.art} to={s.ziel} onClick={(e) => e.stopPropagation()}
            className="hover:text-[var(--color-text-link)] hover:underline">{inhalt}</Link>
        ) : (
          <span key={s.art}>{inhalt}</span>
        )
      })}
    </div>
  )
}

/** „Q2 · Nov bis Jan“ (Monate in Europe/Berlin, Sprache aus i18n). */
export function useZeitfenster(): (quartal: number | null, von: string | null, bis: string | null) => string {
  const { t, i18n } = useTranslation('admin')
  return (quartal, von, bis) => {
    if (!quartal) return ''
    const m = monate(von, bis, i18n.language)
    return m ? t('inhalte.zeitfenster', { q: quartal, von: m.von, bis: m.bis }) : t('inhalte.zeitfensterQ', { q: quartal })
  }
}

export function KlasseTag({ klasse }: { klasse: number | null }): JSX.Element | null {
  const { t } = useTranslation('admin')
  return klasse ? <EdvanceBadge variant="primary" className="whitespace-nowrap">{t('inhalte.klasseTag', { klasse })}</EdvanceBadge> : null
}

/** Titel einer Zeile mit Etiketten darunter. */
export function ZeilenTitel({ titel, children }: { titel: string; children?: ReactNode }): JSX.Element {
  return (
    <div className="flex flex-col gap-1">
      <span className="font-semibold text-[var(--color-text-primary)]">{titel}</span>
      <span className="flex flex-wrap items-center gap-2 text-xs text-[var(--color-text-secondary)]">{children}</span>
    </div>
  )
}
