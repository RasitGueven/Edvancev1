// Prüfansicht (SP-1b N3): Aufgaben mit Figur in den Optionen (Graph-Auswahl) über die volle Kartenbreite. Optionen
// nebeneinander auf dunklem Grund wie im Player, mindestens 280 px breit (dreispaltig, sobald Platz ist). Die richtige
// Option ist für Lena markiert (Rahmen, Etikett „richtig“) – nur hier, nie im Player. Klick öffnet die Option groß.
import { useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui'

const ANKER = 'ABCDEFGH'

export type GraphOption = { id: string; alt: string; bild?: string | null }

/** Optionen mit Figur aus dem Payload einer Graph-Auswahl, sonst null. */
export function graphOptionen(payload: unknown): { prompt: string; optionen: GraphOption[] } | null {
  const p = payload as { kind?: string; format?: string; prompt?: string; payload?: { optionen?: GraphOption[] } }
  if (p?.kind !== 'format' || p.format !== 'graph_auswahl' || !Array.isArray(p.payload?.optionen)) return null
  return { prompt: p.prompt ?? '', optionen: p.payload.optionen }
}

export function GraphOptionenGross({ prompt, optionen, richtig }: { prompt: string; optionen: GraphOption[]; richtig: string | null }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const [gross, setGross] = useState<number | null>(null)
  const knoepfe = useRef<(HTMLButtonElement | null)[]>([])
  const schliessen = (): void => {
    const i = gross
    setGross(null)
    if (i != null) window.setTimeout(() => knoepfe.current[i]?.focus(), 0)
  }
  const offen = gross != null ? optionen[gross] : null

  return (
    <div className="preview-stage flex flex-col gap-4 rounded-[var(--radius-lg)] p-4">
      <EdvanceCard>
        <p className="whitespace-pre-wrap text-sm leading-relaxed text-[var(--color-text-primary)]">{prompt}</p>
      </EdvanceCard>
      <div className="grid grid-cols-[repeat(auto-fill,minmax(min(100%,280px),1fr))] gap-4">
        {optionen.map((o, i) => {
          const ist = o.id === richtig
          return (
            <button
              key={o.id}
              ref={(el) => { knoepfe.current[i] = el }}
              type="button"
              data-testid="graph-option-gross"
              aria-label={t('ansicht.optionGross', { anker: ANKER[i] })}
              onClick={() => setGross(i)}
              className={`flex flex-col gap-2 rounded-[var(--radius-md)] border p-2 text-left focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-stage-text)] ${
                ist
                  ? 'border-[var(--color-stage-accent)] bg-[color-mix(in_srgb,var(--color-stage-accent)_12%,transparent)]'
                  : 'border-[color-mix(in_srgb,var(--color-stage-text)_20%,transparent)] bg-[color-mix(in_srgb,var(--color-stage-text)_8%,transparent)]'
              }`}
            >
              <span className="flex items-center gap-2 text-xs font-bold text-[var(--color-stage-text)]">
                {ANKER[i]}
                {ist && (
                  <span className="rounded-[var(--radius-sm)] bg-[var(--color-stage-accent)] px-2 py-0.5 text-[var(--color-stage-overlay)]">
                    {t('ansicht.richtig')}
                  </span>
                )}
              </span>
              {o.bild ? (
                <img src={o.bild} alt={o.alt} className="block aspect-square h-auto w-full rounded-[var(--radius-md)]" />
              ) : (
                <span className="text-xs text-[var(--color-stage-text)]">{o.alt}</span>
              )}
            </button>
          )
        })}
      </div>
      <Modal open={offen != null} onClose={schliessen} size="xl"
        title={offen ? t('ansicht.optionDialog', { anker: ANKER[gross ?? 0] }) : ''}
        description={offen?.alt}
        footer={<Button autoFocus onClick={schliessen}>{t('ansicht.schliessen')}</Button>}>
        {offen?.bild && (
          <div className="preview-stage rounded-[var(--radius-lg)] p-4">
            <img src={offen.bild} alt={offen.alt} className="mx-auto block aspect-square max-h-[70vh] w-auto" />
          </div>
        )}
      </Modal>
    </div>
  )
}
