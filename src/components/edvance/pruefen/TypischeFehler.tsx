// Pruefkarte, Abschnitt "Typische Fehler" (32.6): Gruppen je Denkfehler mit Klartext, Werten und dem
// Satz zur Aufgabe. Entfernen / Wieder rein; Ergaenzen nur mit einem bestehenden Denkfehler.

import { useState, type JSX, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui'
import { fehlerErgaenzen, fehlerUmschalten, type Bearbeitung } from '@/lib/pruefung/entwurf'
import type { Fehlbild, PruefAufgabe, PruefFehlerWert } from '@/types'
import { GeaendertMarke, InfoTip } from './InfoTip'
import { teilLabel } from './RichtigeAntwort'

const FELD = 'min-h-[44px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'

type Props = {
  aufgabe: PruefAufgabe
  b: Bearbeitung
  fehlbilder: Fehlbild[]
  geaendert: boolean
  lesend: boolean
  onChange: (b: Bearbeitung) => void
  onZurueck: () => void
  /** Rechts im Abschnittskopf, z. B. „im Editor“ in der Admin-Pruefansicht. */
  kopfAktion?: ReactNode
}

export function TypischeFehler({ aufgabe, b, fehlbilder, geaendert, lesend, onChange, onZurueck, kopfAktion }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [form, setForm] = useState(false)
  const [wert, setWert] = useState('')
  const [teil, setTeil] = useState<number | null>(aufgabe.aufgabe.parts[0]?.nr ?? null)
  const [slug, setSlug] = useState('')
  const [satz, setSatz] = useState('')
  const [fehler, setFehler] = useState<string | null>(null)
  const typ = aufgabe.aufgabe.input_type
  const klartext = (s: string): string =>
    fehlbilder.find((f) => f.slug === s)?.klartext ?? aufgabe.fehler.find((f) => f.slug === s)?.klartext ?? s
  const optionLabel = (id: string): string => {
    const o = aufgabe.aufgabe.optionen.find((x) => x.id === id)
    return o ? `${id}) ${o.label}` : id
  }
  const wertText = (v: PruefFehlerWert): string =>
    typ === 'MC' ? optionLabel(v.wert) : `${v.teil !== null ? `${teilLabel(v.teil)} ` : ''}${v.wert.replace(/-/g, '−')}`

  const hinzufuegen = (): void => {
    const w = typ === 'MC' ? wert || aufgabe.aufgabe.optionen.find((o) => o.id !== b.mc)?.id || '' : wert.trim()
    if (!w) return setFehler(t('fehler.formFehltWert'))
    if (!slug) return setFehler(t('fehler.formFehltDenkfehler'))
    onChange(fehlerErgaenzen(b, { slug, teil: typ === 'MULTI_PART' ? teil : null, wert: w.replace(/[−–]/g, '-'), text: satz }))
    setForm(false)
    setWert('')
    setSlug('')
    setSatz('')
    setFehler(null)
  }

  return (
    <section className="flex flex-col gap-3 border-t border-[var(--color-border)] pt-6">
      <h3 className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        <span className="inline-flex items-center gap-2">{t('fehler.titel')} <InfoTip schluessel="fehler" /></span>
        <GeaendertMarke an={geaendert && !lesend} onZurueck={onZurueck} />
        {kopfAktion && <span className="ml-auto normal-case tracking-normal">{kopfAktion}</span>}
      </h3>
      {aufgabe.ohne_erkennung ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('fehler.ohneErkennung')}</p>
      ) : (
        <>
          <p className="text-sm text-[var(--color-text-secondary)]">{t('fehler.sub')}</p>
          {b.fehler.length === 0 && <p className="text-sm text-[var(--color-text-tertiary)]">{t('fehler.keine')}</p>}
          <ul className="flex flex-col">
            {b.fehler.map((f, i) => (
              <li key={`${f.slug}-${i}`} className="flex items-start gap-3 border-t border-[var(--color-border)] py-3 first:border-t-0">
                <div className={cn('flex min-w-0 flex-1 flex-col gap-1', f.raus && 'text-[var(--color-text-tertiary)] line-through')}>
                  <span className="text-sm font-semibold">
                    {klartext(f.slug)}
                    {f.neu && (
                      <span className="ml-2 rounded-[var(--radius-sm)] bg-[var(--color-primary-light)] px-1.5 text-xs font-semibold text-[var(--color-primary)] no-underline">
                        {t('fehler.neu')}
                      </span>
                    )}
                  </span>
                  <span className="text-sm text-[var(--color-text-secondary)]">
                    {t('fehler.antwort')} {f.werte.map(wertText).join(' · ')}
                  </span>
                  {f.text && (
                    <span className="text-sm text-[var(--color-text-secondary)]">
                      <span className="text-[var(--color-text-tertiary)]">{t('fehler.hier')}</span> {f.text}
                    </span>
                  )}
                </div>
                {!lesend && (
                  <Button variant="secondary" size="sm" onClick={() => onChange(fehlerUmschalten(b, i))}>
                    {f.raus ? t('fehler.wiederRein') : t('fehler.entfernen')}
                  </Button>
                )}
              </li>
            ))}
          </ul>
          {!lesend && !form && (
            <button type="button" onClick={() => setForm(true)}
              className="min-h-[44px] self-start rounded-[var(--radius-md)] border border-dashed border-[var(--color-border)] px-3 text-sm text-[var(--color-primary)] hover:border-[var(--color-primary)]">
              {t('fehler.ergaenzen')}
            </button>
          )}
          {!lesend && form && (
            <div className="flex flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3">
              <div className="flex flex-wrap gap-2">
                {typ === 'MULTI_PART' && (
                  <select aria-label={t('fehler.formTeil')} value={teil ?? ''} onChange={(e) => setTeil(Number(e.target.value))} className={cn(FELD, 'sm:w-40')}>
                    {aufgabe.aufgabe.parts.map((p) => <option key={p.nr} value={p.nr}>{teilLabel(p.nr)} {p.prompt}</option>)}
                  </select>
                )}
                {typ === 'MC' ? (
                  <select aria-label={t('fehler.formOption')} value={wert} onChange={(e) => setWert(e.target.value)} className={FELD}>
                    {aufgabe.aufgabe.optionen.filter((o) => o.id !== b.mc).map((o) => (
                      <option key={o.id} value={o.id}>{o.id}) {o.label}</option>
                    ))}
                  </select>
                ) : (
                  <input autoFocus aria-label={t('fehler.formWert')} placeholder={t('fehler.formWert')} value={wert}
                    onChange={(e) => setWert(e.target.value)} className={cn(FELD, 'sm:w-40')} />
                )}
              </div>
              <select aria-label={t('fehler.formDenkfehler')} value={slug} onChange={(e) => setSlug(e.target.value)} className={FELD}>
                <option value="">{t('fehler.formDenkfehler')}</option>
                {fehlbilder.filter((f) => f.klartext).map((f) => <option key={f.slug} value={f.slug}>{f.klartext}</option>)}
              </select>
              <input aria-label={t('fehler.formSatz')} placeholder={t('fehler.formSatz')} value={satz}
                onChange={(e) => setSatz(e.target.value)} className={FELD} />
              <p className="text-xs text-[var(--color-text-tertiary)]">{t('fehler.formHinweis')}</p>
              {fehler && <p role="alert" className="text-sm text-[var(--color-destructive)]">{fehler}</p>}
              <div className="flex flex-wrap justify-end gap-2">
                <Button variant="ghost" size="sm" onClick={() => { setForm(false); setFehler(null) }}>{t('fehler.abbrechen')}</Button>
                <Button size="sm" onClick={hinzufuegen}>{t('fehler.hinzufuegen')}</Button>
              </div>
            </div>
          )}
        </>
      )}
    </section>
  )
}
