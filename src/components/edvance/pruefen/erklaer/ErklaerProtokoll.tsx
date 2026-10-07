// Pruefprotokoll einer Kernidee (erklaer_pruefungen): wer, wann, Entscheidung, Gruende, Notiz, Antwort
// des Admins und die Aenderungen vorher → nachher je Schritt. Neueste Zeile oben.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { berlinZeit } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerAenderung, ErklaerProtokollZeile } from '@/types/erklaerPruefung'

function wert(v: unknown): string {
  if (v === null || v === undefined) return '–'
  if (typeof v === 'string') return v
  if (Array.isArray(v)) return v.length ? v.join(', ') : '–'
  return JSON.stringify(v)
}

function Aenderung({ a }: { a: ErklaerAenderung }): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const wo = a.objekt === 'schritt'
    ? t('protokoll.wo.schritt', { variante: a.variante, art: t(`art.${a.art ?? 'erklaerung'}`) })
    : t(`protokoll.wo.${a.objekt}`)
  return (
    <li className="flex flex-col gap-1 text-xs">
      <span className="font-semibold text-[var(--color-text-secondary)]">{wo} · {t(`protokoll.feld.${a.feld}`, { defaultValue: a.feld })}</span>
      <span className="whitespace-pre-wrap break-words text-[var(--color-text-tertiary)]">
        {t('protokoll.vorherNachher', { vorher: wert(a.vorher), nachher: wert(a.nachher) })}
      </span>
    </li>
  )
}

export function ErklaerProtokoll({ zeilen }: { zeilen: ErklaerProtokollZeile[] }): JSX.Element {
  const { t, i18n } = useTranslation('erklaerPruefen')
  return (
    <section className="flex flex-col gap-2">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('protokoll.titel')}</h2>
      {zeilen.length === 0 && <p className="text-sm text-[var(--color-text-secondary)]">{t('protokoll.leer')}</p>}
      <ol className="flex flex-col">
        {zeilen.map((z) => (
          <li key={z.id} className="flex flex-col gap-2 border-b border-[var(--color-border)] py-2">
            <div className="flex flex-wrap items-baseline gap-2 text-sm">
              <span className="font-semibold text-[var(--color-text-primary)]">{t(`protokoll.art.${z.entscheidung}`)}</span>
              <span className="text-xs text-[var(--color-text-tertiary)]">
                {t('protokoll.wer', { von: z.von ?? t('protokoll.system'), am: berlinZeit(z.am, i18n.language) })}
              </span>
            </div>
            {z.gruende.length > 0 && (
              <p className="text-sm text-[var(--color-text-secondary)]">{z.gruende.map((g) => t(`gruende.${g}`)).join(' · ')}</p>
            )}
            {z.notiz && <p className="text-sm text-[var(--color-text-secondary)]">{t('protokoll.notiz', { notiz: z.notiz })}</p>}
            {z.antwort && (
              <p className="text-sm text-[var(--color-primary)]">
                {t('protokoll.antwort', { von: z.beantwortet_von ?? t('protokoll.system'), antwort: z.antwort })}
              </p>
            )}
            {z.aenderungen.length > 0 && (
              <details>
                <summary className="min-h-[44px] cursor-pointer content-center text-xs text-[var(--color-text-link)]">
                  {t('protokoll.aenderungen', { count: z.aenderungen.length })}
                </summary>
                <ul className="flex flex-col gap-2 pl-2">
                  {z.aenderungen.map((a, i) => <Aenderung key={i} a={a} />)}
                </ul>
              </details>
            )}
          </li>
        ))}
      </ol>
    </section>
  )
}
