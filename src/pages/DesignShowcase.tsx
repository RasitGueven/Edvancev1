import { useState } from 'react'
import { EdvanceCard, EdvanceBadge, ToastBanner } from '@/components/edvance'
import {
  Section,
  TypografieSection,
  SchattenSection,
  FarbTokensSection,
  SpacingSection,
  EdvanceCardSection,
  BadgeSection,
  MasteryBarSection,
  XPBarSection,
  StatCardSection,
  AvatarSection,
  ProgressStepSection,
  EmptyStateSection,
  LoadingPulseSection,
} from './ShowcaseSections'

type ToastConfig = {
  type: 'success' | 'xp' | 'warning' | 'error'
  message: string
  xpAmount?: number
}

const ANIMATIONS = [
  { label: 'bounce-pop', cls: 'animate-xp-float' },
  { label: 'scale-in',   cls: 'animate-scale-in' },
  { label: 'fade-in',    cls: 'animate-fade-in' },
  { label: 'xp-pulse',   cls: 'animate-xp-float' },
]

export function DesignShowcase() {
  const [toast, setToast] = useState<ToastConfig | null>(null)
  const [animKey, setAnimKey] = useState(0)

  function fireToast(config: ToastConfig) {
    setToast(null)
    setTimeout(() => setToast(config), 50)
  }

  return (
    <div className="min-h-full bg-[var(--color-bg-app)] pb-16">
      <div className="px-8 py-10 bg-[var(--color-primary)]">
        <div className="max-w-5xl mx-auto">
          <EdvanceBadge variant="xp-day" className="mb-4">Design System v2</EdvanceBadge>
          <h1 className="text-2xl font-bold text-white mt-2">Edvance Design Showcase</h1>
          <p className="text-sm text-[var(--color-primary-light)] mt-1 leading-relaxed max-w-lg">
            Alle Komponenten auf einen Blick – der visuelle Spiegel vor jedem Release.
            Jeder neue Screen muss mit dieser Seite konsistent sein.
          </p>
        </div>
      </div>

      <div className="px-8 py-10 flex flex-col gap-14 max-w-5xl mx-auto">
        <TypografieSection />
        <SchattenSection />
        <FarbTokensSection />
        <SpacingSection />
        <EdvanceCardSection />
        <BadgeSection />
        <MasteryBarSection />
        <XPBarSection />
        <StatCardSection />
        <AvatarSection />
        <ProgressStepSection />
        <EmptyStateSection />
        <LoadingPulseSection />

        <Section title="Animationen – Demo">
          <EdvanceCard>
            <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed mb-5">
              Klicke auf einen Button um die Animation einmalig zu triggern.
            </p>
            <div className="flex flex-wrap items-center gap-6">
              {ANIMATIONS.map(({ label, cls }) => (
                <div key={label} className="flex flex-col items-center gap-3">
                  <div
                    key={`${label}-${animKey}`}
                    className={`w-12 h-12 rounded-[var(--radius-lg)] bg-[var(--color-primary)] flex items-center justify-center text-white text-lg ${animKey > 0 ? cls : ''}`}
                  >
                    ⚡
                  </div>
                  <button
                    className="text-xs font-mono text-[var(--color-primary)] underline"
                    onClick={() => setAnimKey((k) => k + 1)}
                  >
                    .{label}
                  </button>
                </div>
              ))}
            </div>
          </EdvanceCard>
        </Section>

        <Section title="ToastBanner – alle Typen">
          <EdvanceCard>
            <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed mb-4">
              Erscheint oben-mittig, verschwindet nach 3s. XP-Toast feiert mit Bounce-Animation.
            </p>
            <div className="flex flex-wrap gap-3">
              <button
                onClick={() => fireToast({ type: 'xp', message: 'Aufgabe abgeschlossen!', xpAmount: 150 })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-[var(--color-primary)] bg-[var(--color-accent)] min-h-[44px]"
              >
                🎉 XP Toast
              </button>
              <button
                onClick={() => fireToast({ type: 'success', message: 'Gespeichert!' })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-white bg-[var(--color-success)] min-h-[44px]"
              >
                ✓ Erfolg
              </button>
              <button
                onClick={() => fireToast({ type: 'warning', message: 'Bitte vervollständige dein Profil.' })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] min-h-[44px]"
              >
                ⚠️ Warnung
              </button>
              <button
                onClick={() => fireToast({ type: 'error', message: 'Etwas ist schiefgelaufen.' })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-white bg-[var(--color-error-exam)] min-h-[44px]"
              >
                ✕ Fehler
              </button>
            </div>
          </EdvanceCard>
        </Section>
      </div>

      {toast && (
        <ToastBanner
          type={toast.type}
          message={toast.message}
          xpAmount={toast.xpAmount}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  )
}
