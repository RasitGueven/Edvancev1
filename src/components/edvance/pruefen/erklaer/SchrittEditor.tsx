// Ein Schritt im Entwurf bearbeiten (erklaer_schritt_speichern, E1): Text (Markdown, Formeln in $…$) und
// beim Erklaerschritt die Fehlbild-Zuordnung der Variante. Speichern setzt den Schritt auf entwurf, neue
// Formeln erzeugt tools/formeln-svg.mjs. Der Elternteil setzt einen key je Fassung, damit der Entwurf
// nach dem Neuladen zuruecksetzt.

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui'
import { EdvanceBadge } from '@/components/edvance/EdvanceBadge'
import { STATUS_VARIANTE } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerFehlbild, ErklaerSchritt } from '@/types/erklaerPruefung'

type Props = {
  schritt: ErklaerSchritt
  fehlbilder: ErklaerFehlbild[]
  /** Grund, warum nicht bearbeitet werden kann; null = bearbeitbar. */
  gesperrt: string | null
  onSpeichern: (inhalt: string, slugs: string[]) => Promise<string | null>
}


export function SchrittEditor({ schritt, fehlbilder, gesperrt, onSpeichern }: Props): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const [inhalt, setInhalt] = useState(schritt.inhalt)
  const [slugs, setSlugs] = useState<string[]>(schritt.fehlbild_slugs)
  const [arbeitet, setArbeitet] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const geaendert = inhalt !== schritt.inhalt || slugs.join('|') !== schritt.fehlbild_slugs.join('|')
  const feldId = `schritt-${schritt.id}`

  const speichern = async (): Promise<void> => {
    if (!inhalt.trim()) return setFehler(t('editor.leer'))
    setArbeitet(true)
    setFehler(await onSpeichern(inhalt, slugs))
    setArbeitet(false)
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <label htmlFor={feldId} className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t(`art.${schritt.art}`)}
        </label>
        <EdvanceBadge variant={STATUS_VARIANTE[schritt.status]}>{t(`status.${schritt.status}`)}</EdvanceBadge>
      </div>
      <textarea id={feldId} rows={6} value={inhalt} disabled={!!gesperrt} title={gesperrt ?? undefined}
        onChange={(e) => setInhalt(e.target.value)}
        className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 font-mono text-sm leading-relaxed disabled:opacity-60" />
      {schritt.formeln_ist < schritt.formeln_soll && (
        <p className="text-xs text-[var(--color-warning)]">
          {t('editor.formelnOffen', { ist: schritt.formeln_ist, soll: schritt.formeln_soll })}
        </p>
      )}
      {schritt.art === 'erklaerung' && (
        <fieldset className="flex flex-col gap-2" disabled={!!gesperrt}>
          <legend className="text-xs text-[var(--color-text-tertiary)]">{t('editor.fehlbilder', { variante: schritt.variante })}</legend>
          {fehlbilder.length === 0 && <span className="text-xs text-[var(--color-text-tertiary)]">{t('editor.keineFehlbilder')}</span>}
          <div className="flex flex-wrap gap-2">
            {fehlbilder.map((f) => {
              const an = slugs.includes(f.slug)
              return (
                <button key={f.slug} type="button" aria-pressed={an} title={f.slug}
                  onClick={() => setSlugs(an ? slugs.filter((s) => s !== f.slug) : [...slugs, f.slug])}
                  className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-3 text-sm disabled:opacity-60',
                    an ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] font-semibold text-[var(--color-primary)]'
                      : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]')}>
                  {f.klartext ?? f.slug}
                </button>
              )
            })}
          </div>
        </fieldset>
      )}
      {fehler && <p role="alert" className="text-sm text-[var(--color-destructive)]">{fehler}</p>}
      {!gesperrt && geaendert && (
        <div className="flex flex-wrap justify-end gap-2">
          <Button variant="ghost" size="sm" onClick={() => { setInhalt(schritt.inhalt); setSlugs(schritt.fehlbild_slugs); setFehler(null) }}>
            {t('editor.verwerfen')}
          </Button>
          <Button size="sm" loading={arbeitet} onClick={() => void speichern()}>{t('editor.speichern')}</Button>
        </div>
      )}
      {gesperrt && <p className="text-xs text-[var(--color-text-tertiary)]">{gesperrt}</p>}
    </div>
  )
}
