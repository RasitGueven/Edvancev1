import { useEffect, useState, type JSX } from 'react'
import { XPBar } from '@/components/edvance'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

export function ScenarioCelebration(): JSX.Element {
  const [animKey, setAnimKey] = useState(0)
  const [visible, setVisible] = useState(true)

  // Badge-Animation beim ersten Render auslösen
  useEffect(() => { setAnimKey((k) => k + 1) }, [])

  function replay() {
    setVisible(false)
    setTimeout(() => {
      setVisible(true)
      setAnimKey((k) => k + 1)
    }, 200)
  }

  return (
    <div className="flex flex-col gap-5">
      {/* Erklärung */}
      <p className="text-sm text-[var(--text-muted)]">
        Dieser Screen erscheint max. 1× pro Session — ausgelöst durch echten Level-Aufstieg.
        Hintergrund-Token: <code className="font-mono text-xs">--color-moment-bg</code>
      </p>

      {visible && (
        <Card variant="moment" className="flex flex-col items-center gap-6 py-10 text-center">
          {/* Level-Badge mit bounce-pop */}
          <div
            key={animKey}
            className="flex h-24 w-24 items-center justify-center rounded-full text-4xl font-black animate-bounce-pop"
            style={{
              background: 'var(--color-moment-gold)',
              color: 'var(--color-moment-bg)',
              boxShadow: '0 0 40px color-mix(in srgb, var(--color-moment-gold) 40%, transparent)',
            }}
          >
            5
          </div>

          <div className="flex flex-col gap-2">
            <p className="text-xs font-semibold uppercase tracking-widest opacity-60">
              Neues Level erreicht
            </p>
            <h2 className="text-3xl font-black">Detektiv</h2>
            <p className="text-sm opacity-70 max-w-xs">
              Du hast „Daten &amp; Zufall" auf Level 5 gebracht. Stark!
            </p>
          </div>

          {/* Neues XP-Level startet bei 0 */}
          <div className="w-full max-w-xs">
            <XPBar current={0} max={600} level={5} levelName="Detektiv" />
          </div>

          {/* Verdientes Badge */}
          <div className="flex flex-col items-center gap-2">
            <p className="text-xs opacity-60 uppercase tracking-widest">Heutiges Achievement</p>
            <Badge variant="celebration">🏆 Wahrscheinlichkeits-Profi</Badge>
          </div>

          <div className="flex gap-3 pt-2">
            <Button variant="ghost" size="sm" onClick={replay}
              className="text-white/70 hover:text-white hover:bg-white/10"
            >
              Wiederholen
            </Button>
            <Button
              variant="secondary"
              onClick={() => setVisible(false)}
              className="border-white/30 text-white hover:bg-white/10"
            >
              Weiter lernen →
            </Button>
          </div>
        </Card>
      )}

      {!visible && (
        <Card variant="subtle" className="flex flex-col items-center gap-4 py-12 text-center">
          <p className="text-[var(--text-muted)]">Celebration beendet</p>
          <Button variant="primary" onClick={replay}>Nochmal auslösen</Button>
        </Card>
      )}
    </div>
  )
}
