// Vorschau für Cloze-DnD und Tabellen-Beschriftung — ohne Persistenz.
// Hier zum visuellen Testen, bevor Items in der DB angelegt werden.

import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { ClozeDndWidget, type ClozeDndPayload } from '@/components/edvance/tasks/ClozeDndWidget'
import { TableLabelWidget, type TableLabelPayload } from '@/components/edvance/tasks/TableLabelWidget'
import { TaskDrawingSlot } from '@/components/edvance/tasks/TaskDrawingSlot'

const CLOZE: ClozeDndPayload = {
  type: 'cloze-dnd',
  segments: [
    { kind: 'text', text: 'Die Funktion f(x) = 2x + 3 hat die Steigung ' },
    { kind: 'blank', id: 'b1' },
    { kind: 'text', text: ' und den y-Achsenabschnitt ' },
    { kind: 'blank', id: 'b2' },
    { kind: 'text', text: '.' },
  ],
  chips: [
    { id: 'c-2', label: '2' },
    { id: 'c-3', label: '3' },
    { id: 'c-x', label: 'x' },
    { id: 'c-0', label: '0' },
  ],
}

const TABLE: TableLabelPayload = {
  type: 'table-label',
  firstColHeader: 'Häufigkeit',
  columnHeaders: ['Mathe', 'Deutsch', 'Englisch', 'Σ'],
  rows: [
    { slotId: 's-abs', cells: [12, 8, 5, 25] },
    { slotId: 's-rel', cells: ['0,48', '0,32', '0,20', '1,00'] },
  ],
  labels: [
    { id: 'L-abs', label: 'absolute Häufigkeit' },
    { id: 'L-rel', label: 'relative Häufigkeit' },
    { id: 'L-sum', label: 'Summenhäufigkeit' },
  ],
}

export function MockDndWidgets(): JSX.Element {
  const [clozeSlots, setClozeSlots] = useState<Record<string, string | null>>({})
  const [tableSlots, setTableSlots] = useState<Record<string, string | null>>({})
  const [drawing, setDrawing] = useState<string | null>(null)

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mock · Drag-and-Drop-Widgets" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <Link
          to="/mock"
          className="inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
        >
          <ArrowLeft className="h-4 w-4" /> Mock-Index
        </Link>

        <div>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Drag-and-Drop-Widgets
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            Lückentext mit Wort-Pool und Tabellen-Beschriftung. Maus, Touch und
            Tap-Fallback (Chip antippen → dann Slot antippen).
          </p>
        </div>

        <EdvanceCard className="p-6">
          <p className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Cloze · Lückentext
          </p>
          <ClozeDndWidget
            payload={CLOZE}
            assignments={clozeSlots}
            onChange={(slotId, chipId) =>
              setClozeSlots((prev) => ({ ...prev, [slotId]: chipId }))
            }
          />
        </EdvanceCard>

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Rechenweg-Skizze (optional)
          </p>
          <p className="text-sm text-[var(--color-text-secondary)]">
            Erscheint im Screening unter freien Aufgaben (NUMERIC, OPEN,
            Multi-Step). Kollabiert per Default — Tap auf „Rechenweg zeichnen"
            klappt das Canvas auf.
          </p>
          <TaskDrawingSlot value={drawing} onChange={setDrawing} />
        </EdvanceCard>

        <EdvanceCard className="p-6">
          <p className="mb-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Tabelle · Zeilen beschriften
          </p>
          <p className="mb-4 text-sm text-[var(--color-text-secondary)]">
            Ordne den Zeilen die passenden Begriffe zu.
          </p>
          <TableLabelWidget
            payload={TABLE}
            assignments={tableSlots}
            onChange={(slotId, chipId) =>
              setTableSlots((prev) => ({ ...prev, [slotId]: chipId }))
            }
          />
        </EdvanceCard>
      </main>
    </div>
  )
}
