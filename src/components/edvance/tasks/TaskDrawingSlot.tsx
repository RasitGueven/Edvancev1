// Optionaler Rechenweg-Slot unter der Hauptantwort. Per Default kollabiert,
// damit das Kind nicht abgelenkt wird. Erscheint nur bei freien Antworten
// (NUMERIC, OPEN, MULTI-STEP) — MC und Zuordnung brauchen keinen
// Rechenweg, weil die Antwort selbst ausgewählt/zugeordnet wird.

import { useState, type JSX } from 'react'
import { Pencil, Trash2, X } from 'lucide-react'
import { DrawCanvas } from '../DrawCanvas'

type Props = {
  value: string | null
  onChange: (dataUrl: string | null) => void
  disabled?: boolean
}

export function TaskDrawingSlot({ value, onChange, disabled }: Props): JSX.Element {
  const [open, setOpen] = useState<boolean>(false)

  if (disabled && !value) return <></>

  // Geschlossen + ohne Skizze → schmaler CTA.
  if (!open && !value) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        disabled={disabled}
        className="inline-flex items-center gap-2 self-start rounded-[var(--radius-md)] border border-dashed border-[var(--color-border)] bg-[var(--color-bg-subtle)] px-3 py-2 text-sm text-[var(--color-text-secondary)] transition-colors hover:bg-[var(--color-bg-surface)] hover:text-[var(--color-text-primary)] disabled:cursor-not-allowed disabled:opacity-50"
      >
        <Pencil className="h-4 w-4" /> Rechenweg zeichnen (optional)
      </button>
    )
  }

  // Geschlossen, aber Skizze vorhanden → Thumbnail mit Bearbeiten/Verwerfen.
  if (!open && value) {
    return (
      <div className="flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-2">
        <img
          src={value}
          alt="Rechenweg-Skizze"
          className="h-16 w-24 rounded border border-[var(--color-border)] object-contain"
        />
        <div className="flex flex-1 flex-col gap-1">
          <p className="text-xs font-semibold text-[var(--color-text-primary)]">
            Skizze hinterlegt
          </p>
          <p className="text-xs text-[var(--color-text-tertiary)]">
            Wird mit deiner Antwort gespeichert.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="rounded-[var(--radius-md)] px-2 py-1 text-xs font-medium text-[var(--color-primary)] hover:bg-[var(--color-primary-light)]"
        >
          Bearbeiten
        </button>
        <button
          type="button"
          onClick={() => onChange(null)}
          aria-label="Skizze verwerfen"
          className="rounded-[var(--radius-md)] p-1 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-subtle)] hover:text-[var(--color-error-gap)]"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
    )
  }

  // Geöffnet → Canvas. onChange feuert bei jedem Stroke-Ende.
  return (
    <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3">
      <div className="flex items-center justify-between">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Rechenweg
        </p>
        <button
          type="button"
          onClick={() => setOpen(false)}
          aria-label="Schliessen"
          className="rounded-[var(--radius-md)] p-1 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-subtle)]"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
      <DrawCanvas onChange={onChange} initialDataUrl={value} />
    </div>
  )
}
