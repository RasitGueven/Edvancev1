import { useState, type JSX, type ReactNode } from 'react'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

function Section({ title, children }: { title: string; children: ReactNode }): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </p>
      {children}
    </div>
  )
}

function Row({ children }: { children: ReactNode }): JSX.Element {
  return <div className="flex flex-wrap items-center gap-3">{children}</div>
}

export function ScenarioUIKit(): JSX.Element {
  const [loading, setLoading] = useState(false)

  function triggerLoad() {
    setLoading(true)
    setTimeout(() => setLoading(false), 1500)
  }

  return (
    <div className="flex flex-col gap-8">

      {/* ── Button ──────────────────────────────────────────────── */}
      <EdvanceCard>
        <div className="flex flex-col gap-5">
          <Section title="Button — Varianten">
            <Row>
              <Button variant="primary">Primary</Button>
              <Button variant="secondary">Secondary</Button>
              <Button variant="ghost">Ghost</Button>
              <Button variant="destructive">Destructive</Button>
            </Row>
          </Section>

          <Section title="Button — Größen">
            <Row>
              <Button size="sm">Klein (sm)</Button>
              <Button size="md">Mittel (md)</Button>
              <Button size="lg">Groß (lg)</Button>
            </Row>
          </Section>

          <Section title="Button — Zustände">
            <Row>
              <Button loading={loading} onClick={triggerLoad}>
                {loading ? 'Wird geladen…' : 'Loading auslösen'}
              </Button>
              <Button disabled>Disabled</Button>
              <Button variant="secondary" loading>Immer loading</Button>
            </Row>
          </Section>
        </div>
      </EdvanceCard>

      {/* ── Badge (neue Tokens) ─────────────────────────────────── */}
      <EdvanceCard>
        <div className="flex flex-col gap-5">
          <Section title="Badge — Semantisch">
            <Row>
              <Badge variant="success">Erfolgreich</Badge>
              <Badge variant="warning">Aufmerksamkeit</Badge>
              <Badge variant="error">Fehler</Badge>
              <Badge variant="info">Info</Badge>
              <Badge variant="accent">Neu</Badge>
              <Badge variant="celebration">🏆 Achievement</Badge>
            </Row>
          </Section>

          <Section title="Badge — Status (Rückwärts-kompatibel)">
            <Row>
              <Badge variant="active" />
              <Badge variant="done" />
              <Badge variant="upcoming" />
            </Row>
          </Section>
        </div>
      </EdvanceCard>

      {/* ── EdvanceBadge ────────────────────────────────────────── */}
      <EdvanceCard>
        <Section title="EdvanceBadge — Gamification">
          <Row>
            <EdvanceBadge variant="xp-day">+20 XP</EdvanceBadge>
            <EdvanceBadge variant="streak-presence">5 Tage</EdvanceBadge>
            <EdvanceBadge variant="primary">FACT</EdvanceBadge>
            <EdvanceBadge variant="mastered">Exzellent</EdvanceBadge>
            <EdvanceBadge variant="warning">Lücke</EdvanceBadge>
            <EdvanceBadge variant="muted">FREE_INPUT</EdvanceBadge>
          </Row>
        </Section>
      </EdvanceCard>

      {/* ── Card ────────────────────────────────────────────────── */}
      <div className="flex flex-col gap-3">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Card — Varianten
        </p>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <Card variant="default" title="Default">
            <p className="text-sm text-[var(--color-text-secondary)]">
              Weißer Hintergrund, dezenter Rahmen. Standard für alle strukturierten Inhalte.
            </p>
          </Card>
          <Card variant="subtle" title="Subtle">
            <p className="text-sm text-[var(--color-text-secondary)]">
              Leicht getönter Hintergrund. Gut für eingebettete Blöcke innerhalb einer Seite.
            </p>
          </Card>
          <Card variant="moment" title="Moment">
            <p className="text-sm opacity-70">
              Dunkler Hintergrund. Ausschließlich für Celebration-Screens — max. 1× pro Session.
            </p>
          </Card>
        </div>
      </div>

      {/* ── Farb-Token Übersicht ─────────────────────────────────── */}
      <EdvanceCard>
        <Section title="Design Tokens — Primärpalette">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { token: '--color-primary',     label: 'primary' },
              { token: '--color-primary-hover', label: 'primary-hover' },
              { token: '--color-primary-light', label: 'primary-light' },
              { token: '--color-accent',        label: 'accent' },
              { token: '--color-success',       label: 'success' },
              { token: '--color-warning',       label: 'warning' },
              { token: '--color-error',         label: 'error' },
              { token: '--color-moment-bg',     label: 'moment-bg' },
            ].map(({ token, label }) => (
              <div key={token} className="flex items-center gap-2">
                <div
                  className="h-8 w-8 flex-none rounded-lg border border-[var(--color-border)] shadow-card"
                  style={{ backgroundColor: `var(${token})` }}
                />
                <span className="text-xs font-mono text-[var(--color-text-secondary)] truncate">{label}</span>
              </div>
            ))}
          </div>
        </Section>
      </EdvanceCard>

    </div>
  )
}
