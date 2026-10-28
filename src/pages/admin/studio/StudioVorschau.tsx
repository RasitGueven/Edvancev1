import { useEffect, useMemo, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Player, type PlayerRef } from '@remotion/player'

import { EdvanceCard, LoadingPulse, Reiterleiste, type Reiter } from '@/components/edvance'
import { ladeVorschauAudio } from '@/lib/supabase/studio'
import { videoDatenAus, type BeatAudio } from '@/studio/remotion/daten'
import { Erklaervideo } from '@/studio/remotion/Erklaervideo'
import { BREITE, FPS, HOEHE, zeitplan } from '@/studio/remotion/zeitplan'
import type { Skript } from '@/studio/skript/typen'

/**
 * Vorschau im Studio (Anforderung Studio §7): Remotion Player mit den echten Audiodateien, Zeitleiste der
 * Beats als Kapitel, Klick springt. Ohne Stimme läuft sie stumm mit geschätzter Dauer.
 */
export function StudioVorschau({ sequenzId, skript, stand }: { sequenzId: string; skript: Skript; stand: string }): JSX.Element {
  const { t } = useTranslation('studio')
  const spieler = useRef<PlayerRef>(null)
  const [welt, setWelt] = useState('skelett')
  const [audio, setAudio] = useState<BeatAudio | null>(null)
  const [fehler, setFehler] = useState(false)
  const [ruhig, setRuhig] = useState(() => typeof window !== 'undefined' && window.matchMedia?.('(prefers-reduced-motion: reduce)').matches)
  const [frame, setFrame] = useState(0)

  useEffect(() => {
    setAudio(null)
    void ladeVorschauAudio(sequenzId, welt).then((r) => {
      setFehler(Boolean(r.error))
      setAudio(r.data ?? {})
    })
  }, [sequenzId, welt, stand])

  const daten = useMemo(() => (audio ? videoDatenAus(skript, welt, audio, ruhig) : null), [skript, welt, audio, ruhig])
  const plan = useMemo(() => (daten ? zeitplan(daten.beats) : null), [daten])

  useEffect(() => {
    const p = spieler.current
    if (!p) return
    const auf = (e: { detail: { frame: number } }) => setFrame(e.detail.frame)
    p.addEventListener('frameupdate', auf)
    return () => p.removeEventListener('frameupdate', auf)
  }, [daten])

  const welten: Reiter<string>[] = skript.welten.map((w) => ({ key: w, titel: t(`welt.${w}`) }))
  const stumm = audio !== null && Object.keys(audio).length < skript.beats.length

  return (
    <EdvanceCard>
      <div className="flex flex-col gap-4" data-testid="studio-vorschau">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-base font-semibold">{t('vorschau.titel')}</h3>
          <label className="flex items-center gap-2 text-xs text-[var(--color-text-muted)]">
            <input type="checkbox" checked={ruhig} onChange={(e) => setRuhig(e.target.checked)} />
            {t('vorschau.ruhig')}
          </label>
        </div>
        <Reiterleiste reiter={welten} aktiv={welt} onWechsel={setWelt} label={t('vorschau.welt')} />
        {fehler && <p className="text-sm text-[var(--color-error-coach)]">{t('vorschau.ladeFehler')}</p>}
        {!daten || !plan ? (
          <LoadingPulse type="card" lines={2} />
        ) : (
          <>
            <Player
              ref={spieler}
              component={Erklaervideo}
              inputProps={daten}
              durationInFrames={plan.frames}
              fps={FPS}
              compositionWidth={BREITE}
              compositionHeight={HOEHE}
              controls
              className="aspect-video w-full overflow-hidden rounded-[var(--radius-lg)]"
            />
            {stumm && <p className="text-xs text-[var(--color-text-muted)]">{t('vorschau.stumm')}</p>}
            <div className="flex flex-col gap-2">
              <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">{t('vorschau.kapitel')}</span>
              <ol className="flex flex-wrap gap-2" data-testid="studio-kapitel">
                {plan.beats.map((b) => {
                  const aktiv = frame >= b.vonFrame && frame < b.vonFrame + b.frames
                  return (
                    <li key={b.key}>
                      <button
                        type="button"
                        onClick={() => spieler.current?.seekTo(b.vonFrame)}
                        aria-label={t('vorschau.springe', { beat: b.key, titel: b.titel })}
                        className={[
                          'min-h-[44px] rounded-lg border px-3 py-2 text-left text-xs',
                          aktiv
                            ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]'
                            : 'border-[var(--color-border)] text-[var(--color-text-secondary)]',
                        ].join(' ')}
                      >
                        <span className="font-semibold">{b.key}</span> · {b.titel}
                      </button>
                    </li>
                  )
                })}
              </ol>
            </div>
          </>
        )}
      </div>
    </EdvanceCard>
  )
}
