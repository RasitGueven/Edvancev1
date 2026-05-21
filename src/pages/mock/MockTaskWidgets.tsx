// Vorschau für die polierten Basis-Widgets (MC, NUMERIC, OPEN, Multi-Step).
// Ohne Persistenz — rein zum visuellen Abnehmen der v2-Tokens.

import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { MCWidget } from '@/components/edvance/tasks/MCWidget'
import { NumericWidget } from '@/components/edvance/tasks/NumericWidget'
import { OpenWidget } from '@/components/edvance/tasks/OpenWidget'
import { MultiStepWidget } from '@/components/edvance/tasks/MultiStepWidget'
import type { ScreeningTeilaufgabe } from '@/types'

const MC_OPTIONS = [
  'f(x) = 2x + 3 hat die Steigung 2.',
  'f(x) = 2x + 3 hat die Steigung 3.',
  'f(x) = 2x + 3 hat die Steigung -3.',
  'f(x) = 2x + 3 hat keine Steigung.',
]

const STEPS: ScreeningTeilaufgabe[] = [
  { key: '1a', prompt: 'Berechne f(2) für f(x) = 2x + 3.', input_type: 'NUMERIC' },
  { key: '1b', prompt: 'Bestimme die Nullstelle der Funktion.', input_type: 'NUMERIC' },
  { key: '1c', prompt: 'Beschreibe, wie sich der Graph verschiebt, wenn man +3 durch -1 ersetzt.', input_type: 'OPEN' },
]

function Section({ title, children }: { title: string; children: JSX.Element }): JSX.Element {
  return (
    <EdvanceCard className="p-6">
      <p className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </p>
      {children}
    </EdvanceCard>
  )
}

export function MockTaskWidgets(): JSX.Element {
  const [mc, setMc] = useState<number | null>(null)
  const [num, setNum] = useState<string>('')
  const [open, setOpen] = useState<string>('')
  const [steps, setSteps] = useState<Record<string, string>>({})

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mock · Basis-Widgets" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <Link
          to="/mock"
          className="inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
        >
          <ArrowLeft className="h-4 w-4" /> Mock-Index
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Basis-Widgets
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            MC, Zahl, Freitext und Multi-Step im v2-Look. Touch-Targets ≥ 56 px,
            Focus-Ringe, dezente Hover-Lift bei MC.
          </p>
        </div>

        <Section title="Multiple Choice">
          <MCWidget options={MC_OPTIONS} selected={mc} onChange={setMc} disabled={false} />
        </Section>

        <Section title="Zahleneingabe">
          <NumericWidget value={num} onChange={setNum} unit="€" />
        </Section>

        <Section title="Freitext">
          <OpenWidget
            value={open}
            onChange={setOpen}
            kontext="Gegeben ist die Funktion f(x) = 2x + 3. Erkläre, was die Zahl 3 für den Graphen bedeutet."
          />
        </Section>

        <Section title="Multi-Step">
          <MultiStepWidget
            steps={STEPS}
            values={steps}
            onChange={(key, value) => setSteps((prev) => ({ ...prev, [key]: value }))}
          />
        </Section>
      </main>
    </div>
  )
}
