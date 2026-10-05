// Teile der Admin-Pruefkarte, die Lena nicht hat (Bauauftrag B 6 und B 7):
// - EditorLink: „im Editor“ neben jedem Abschnitt, springt an die passende Stelle.
// - VorFreigabeKlaeren: sperrende Befunde mit „im Editor beheben“, nicht sperrende zugeklappt als „n Hinweise“.
// - Verlauf: zugeklappt, die letzten 20 Admin-Aktionen aus task_admin_protokoll.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { formatBerlinDateTime } from '@/lib/datetime'
import { aenderungText, type Namen } from '@/lib/pruefung/anzeige'
import type { Befund, EditorAbschnitt } from '@/lib/pruefung/befunde'
import type { AdminProtokollZeile } from '@/types'

export function EditorLink({ ziel, onEditor, text }: { ziel: EditorAbschnitt; onEditor: (z: EditorAbschnitt) => void; text?: string }): JSX.Element {
  const { t } = useTranslation('pruefenAdmin')
  return (
    <button type="button" onClick={() => onEditor(ziel)}
      className="min-h-[44px] px-1 text-xs font-semibold text-[var(--color-text-link)] hover:underline">
      {text ?? t('karte.imEditor')}
    </button>
  )
}

type KlaerenProps = { sperrend: Befund[]; hinweise: Befund[]; onEditor: (z: EditorAbschnitt) => void }

export function VorFreigabeKlaeren({ sperrend, hinweise, onEditor }: KlaerenProps): JSX.Element | null {
  const { t } = useTranslation('pruefenAdmin')
  if (sperrend.length === 0 && hinweise.length === 0) return null
  const zeile = (b: Befund, i: number): JSX.Element => (
    <li key={i} className="flex flex-wrap items-center justify-between gap-2">
      <span>{t(b.key, b.vars)}</span>
      <EditorLink ziel={b.ziel} onEditor={onEditor} text={t('klaeren.beheben')} />
    </li>
  )
  return (
    <section className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-warning)] bg-[var(--color-warning-light)] p-4">
      {sperrend.length > 0 && (
        <>
          <h2 className="text-sm font-semibold text-[var(--color-warning)]">{t('klaeren.titel')}</h2>
          <ul className="flex flex-col text-sm text-[var(--color-text-primary)]">{sperrend.map(zeile)}</ul>
        </>
      )}
      {hinweise.length > 0 && (
        <details className="text-sm text-[var(--color-text-secondary)]">
          <summary className="min-h-[44px] cursor-pointer content-center font-semibold">{t('klaeren.hinweise', { count: hinweise.length })}</summary>
          <ul className="flex flex-col">{hinweise.map(zeile)}</ul>
        </details>
      )}
    </section>
  )
}

export function Verlauf({ zeilen, namen, mc }: { zeilen: AdminProtokollZeile[]; namen: Namen; mc: boolean }): JSX.Element {
  const { t, i18n } = useTranslation('pruefenAdmin')
  const { t: tp } = useTranslation('pruefen')
  return (
    <details className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4 text-sm">
      <summary className="min-h-[44px] cursor-pointer content-center font-semibold text-[var(--color-text-primary)]">
        {t('verlauf.titel', { count: zeilen.length })}
      </summary>
      {zeilen.length === 0 ? (
        <p className="text-[var(--color-text-tertiary)]">{t('verlauf.leer')}</p>
      ) : (
        <ol className="flex flex-col gap-3">
          {zeilen.map((z) => (
            <li key={z.id} className="flex flex-col gap-1 border-t border-[var(--color-border)] pt-2 first:border-t-0 first:pt-0">
              <span className="flex flex-wrap items-center gap-2">
                <strong className="text-[var(--color-text-primary)]">{t(`verlauf.aktion.${z.aktion}`)}</strong>
                {z.sammel && (
                  <span className="rounded-[var(--radius-full)] border border-[var(--color-border)] px-2 text-xs">{t('verlauf.sammel')}</span>
                )}
                <span className="text-xs text-[var(--color-text-tertiary)]">
                  {t('verlauf.zeile', { am: formatBerlinDateTime(z.am, i18n.language), wer: z.von ?? '—' })}
                </span>
              </span>
              {z.grund && <span className="text-[var(--color-text-secondary)]">„{z.grund}“</span>}
              {z.aenderungen.length > 0 && (
                <ul className="list-disc pl-5 text-[var(--color-text-secondary)]">
                  {z.aenderungen.map((a, i) => <li key={i}>{aenderungText(tp, a, namen, mc)}</li>)}
                </ul>
              )}
            </li>
          ))}
        </ol>
      )}
    </details>
  )
}
