import { useCallback, useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EdvanceCard, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { ladeRenderStand, starteRender, type RenderStand } from '@/lib/supabase/studio'

const POLL_MS = 15000

/**
 * Render je Welt (Anforderung Studio §7, Abweichung §11): Status des letzten Auftrags, „Render veraltet“,
 * Knopf für den Server-Render. Läuft ein Auftrag, wird der Stand alle 15 s neu gelesen.
 */
export function RenderPanel({ sequenzId, stand, onFertig }: { sequenzId: string; stand: string; onFertig?: () => void }): JSX.Element {
  const { t } = useTranslation('studio')
  const [welten, setWelten] = useState<RenderStand[] | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const aktuellVorher = useRef<Set<string> | null>(null)
  const fertigRef = useRef(onFertig)
  fertigRef.current = onFertig

  const lade = useCallback(async () => {
    const r = await ladeRenderStand(sequenzId)
    setWelten(r.data ?? [])
    // Ist eine Welt neu aktuell gerendert, kann sie freigabefähig geworden sein.
    const jetzt = new Set((r.data ?? []).filter((w) => w.aktuell).map((w) => w.welt))
    if (aktuellVorher.current && [...jetzt].some((w) => !aktuellVorher.current?.has(w))) fertigRef.current?.()
    aktuellVorher.current = jetzt
  }, [sequenzId])
  useEffect(() => {
    void lade()
  }, [lade, stand])
  const laeuft = (welten ?? []).some((w) => w.letzterStatus === 'wartet' || w.letzterStatus === 'laeuft')
  useEffect(() => {
    if (!laeuft) return
    const id = window.setInterval(() => void lade(), POLL_MS)
    return () => window.clearInterval(id)
  }, [laeuft, lade])

  const rendern = async (welt: string): Promise<void> => {
    const r = await starteRender(sequenzId, welt)
    setMeldung(r.error ? t('render.fehler', { grund: r.error.message }) : t('render.gestartet', { welt: t(`welt.${welt}`) }))
    await lade()
  }

  return (
    <EdvanceCard>
      <div className="flex flex-col gap-4" data-testid="studio-render">
        <div className="flex flex-col gap-2">
          <h3 className="text-base font-semibold">{t('render.titel')}</h3>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('render.satz')}</p>
        </div>
        {welten === null ? (
          <LoadingPulse type="list" lines={2} />
        ) : (
          <ul className="flex flex-col gap-2">
            {welten.map((w) => {
              const beschaeftigt = w.letzterStatus === 'wartet' || w.letzterStatus === 'laeuft'
              return (
                <li key={w.welt} className="flex flex-wrap items-center gap-2 text-sm">
                  <span className="min-w-[88px] font-semibold">{t(`welt.${w.welt}`)}</span>
                  <EdvanceBadge variant={w.letzterStatus === 'fehler' ? 'gap' : 'muted'}>
                    {t(`render.status.${w.letzterStatus ?? 'keiner'}`)}
                  </EdvanceBadge>
                  {w.fertigId && (
                    <EdvanceBadge variant={w.aktuell ? 'strength' : 'warning'}>{t(w.aktuell ? 'render.aktuell' : 'render.veraltet')}</EdvanceBadge>
                  )}
                  {!w.stimmeVollstaendig && <span className="text-xs text-[var(--color-text-muted)]">{t('render.stimmeFehlt')}</span>}
                  <Button
                    variant="secondary"
                    className="ml-auto"
                    disabled={beschaeftigt || w.aktuell}
                    title={beschaeftigt || w.aktuell ? t('render.gesperrtTooltip') : undefined}
                    onClick={() => void rendern(w.welt)}
                  >
                    {t('render.knopf')}
                  </Button>
                </li>
              )
            })}
          </ul>
        )}
        {meldung && <p className="text-sm text-[var(--color-text-secondary)]">{meldung}</p>}
        <p className="text-xs text-[var(--color-text-muted)]">{t('render.lokal', { id: sequenzId })}</p>
      </div>
    </EdvanceCard>
  )
}
