// Ein Erklaerschritt so, wie das Kind ihn auf dem Tablet sieht (Klick-Dummy Schueler-Session, Schritte
// „Erklärschritt“, „Lösungsbeispiel“, „Andere Erklärung“): Kopfzeile mit Kernidee, Dachzeile, Text,
// Bild daneben. Formeln nur als SVG (Entscheidung 19); fehlt eine SVG noch, steht der Quelltext mit Hinweis da.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import ReactMarkdown, { type Components } from 'react-markdown'
import { cn } from '@/lib/utils'
import { FORMEL_FEHLT, mitFormelBildern } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerSchritt } from '@/types/erklaerPruefung'

function Formel({ src, alt }: { src?: string; alt?: string }): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  if (!src || src === FORMEL_FEHLT) {
    return (
      <code title={t('kind.formelFehlt')} data-testid="formel-quelltext"
        className="rounded-[var(--radius-sm)] border border-dashed border-[var(--color-warning)] bg-[var(--color-warning-light)] px-1 font-mono text-sm">
        ${alt}$
      </code>
    )
  }
  return <img src={src} alt={alt} data-testid="formel-svg" className="inline-block align-middle" />
}

const UEBERSCHRIFT = 'text-base font-bold text-[var(--color-text-primary)]'

const TEILE: Components = {
  // E2b-Entwuerfe beginnen mit einer Ueberschrift (# …): auf dem Tablet der Titel des Bildschirms.
  h1: ({ node: _n, ...props }) => <h3 className={UEBERSCHRIFT} {...props} />,
  h2: ({ node: _n, ...props }) => <h3 className={UEBERSCHRIFT} {...props} />,
  h3: ({ node: _n, ...props }) => <h3 className={UEBERSCHRIFT} {...props} />,
  p: ({ node: _n, ...props }) => <p className="text-base leading-relaxed text-[var(--color-text-primary)]" {...props} />,
  strong: ({ node: _n, ...props }) => <strong className="font-semibold" {...props} />,
  ol: ({ node: _n, ...props }) => <ol className="ml-6 flex list-decimal flex-col gap-2 text-base" {...props} />,
  ul: ({ node: _n, ...props }) => <ul className="ml-6 flex list-disc flex-col gap-2 text-base" {...props} />,
  img: ({ node: _n, src, alt }) => <Formel src={typeof src === 'string' ? src : undefined} alt={alt} />,
}

type Props = {
  schritt: ErklaerSchritt
  kernideeNr: number
  kernideen: number
}

export function ErklaerKindSchritt({ schritt, kernideeNr, kernideen }: Props): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const { markdown, fehlen } = mitFormelBildern(schritt.inhalt, schritt.kind.formeln)
  const bild = schritt.kind.bild
  const dach = schritt.art === 'beispiel' ? 'kind.dachBeispiel' : schritt.variante === 'A' ? 'kind.dachErst' : 'kind.dachAnders'

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-col gap-4 rounded-[var(--radius-xl)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-6 shadow-xs">
        <div className="flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
          {Array.from({ length: kernideen }, (_, i) => (
            <span key={i} aria-hidden="true"
              className={cn('h-2 w-2 rounded-[var(--radius-full)]', i < kernideeNr ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-border)]')} />
          ))}
          <span>{t('kind.kopf', { nr: kernideeNr, von: kernideen, art: t(`art.${schritt.art}`) })}</span>
        </div>
        <div className={cn('grid gap-6', bild && 'md:grid-cols-[3fr_2fr]')}>
          <div className="flex flex-col gap-2">
            <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-primary)]">{t(dach)}</span>
            <ReactMarkdown components={TEILE}>{markdown}</ReactMarkdown>
          </div>
          {bild && (
            <img src={bild.url} alt={bild.alt} className="max-h-72 w-full rounded-[var(--radius-md)] object-contain" />
          )}
        </div>
      </div>
      {fehlen > 0 && (
        <p role="note" className="text-xs text-[var(--color-warning)]">{t('kind.formelnFehlen', { count: fehlen })}</p>
      )}
    </div>
  )
}
