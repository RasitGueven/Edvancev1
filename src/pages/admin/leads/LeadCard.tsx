import { useState } from 'react'
import { MonitorSmartphone, MoreHorizontal } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { Lead } from '@/types'
import type { LeadPlatz } from '@/lib/supabase/platz'
import { ageDisplay, type BoardColumn } from './boardModel'

type LeadCardProps = {
  lead: Lead
  platz?: LeadPlatz
  column: BoardColumn
  /** Wizard auf Schritt 1 (Stammdaten) oeffnen — Klick auf den Namen. */
  onOpen: (lead: Lead) => void
  /** Wizard direkt auf Schritt 2 (Erstgespraech) oeffnen. */
  onOpenErstgespraech: (lead: Lead) => void
  onAssignPlatz: (lead: Lead) => void
  onReject: (lead: Lead) => void
}

function ageClass(accent: boolean, bold: boolean): string {
  if (bold) return 'font-bold text-[var(--color-accent)]'
  if (accent) return 'text-[var(--color-accent)]'
  return 'text-[var(--color-text-tertiary)]'
}

export function LeadCard({
  lead,
  platz,
  column,
  onOpen,
  onOpenErstgespraech,
  onAssignPlatz,
  onReject,
}: LeadCardProps): JSX.Element {
  const [menuOpen, setMenuOpen] = useState(false)
  const age = ageDisplay(lead, column)
  // Der vollstaendige Name traegt die Karte; bei vielen Leads ist der Rufname
  // allein nicht mehr unterscheidbar. Fehlt er, bleibt der Rufname.
  const name = lead.full_name.trim() || lead.first_name?.trim() || '—'
  // Leere Werte fallen raus, damit keine Trennpunkte ins Leere zeigen.
  const meta = [
    lead.class_level !== null ? `Kl. ${lead.class_level}` : null,
    lead.school_type,
    lead.subjects.length > 0 ? lead.subjects.join(', ') : null,
  ].filter((part): part is string => part !== null && part !== '')

  return (
    <EdvanceCard className="flex min-w-0 flex-col gap-3 p-4">
      <div className="flex min-w-0 items-start justify-between gap-2">
        <button
          type="button"
          onClick={() => onOpen(lead)}
          title={name}
          className="min-w-0 flex-1 truncate text-left text-base font-semibold text-[var(--color-text-primary)] hover:text-[var(--color-primary)]"
        >
          {name}
        </button>
        <div
          className="relative shrink-0"
          onBlur={(e) => {
            if (!e.currentTarget.contains(e.relatedTarget as Node | null)) setMenuOpen(false)
          }}
        >
          <button
            type="button"
            aria-label="Weitere Aktionen"
            aria-haspopup="menu"
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((v) => !v)}
            onKeyDown={(e) => {
              if (e.key === 'Escape') setMenuOpen(false)
            }}
            className="rounded-full p-2 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-surface)]"
          >
            <MoreHorizontal className="h-5 w-5" />
          </button>
          {menuOpen && (
            <div
              role="menu"
              className="absolute right-0 z-10 mt-1 min-w-[10rem] rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-1 shadow-elevation-lg"
            >
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  setMenuOpen(false)
                  onReject(lead)
                }}
                className="w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-[var(--color-destructive)] hover:bg-[var(--color-bg-app)]"
              >
                Ablehnen
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="flex flex-col gap-0.5">
        <p className={`text-xs ${ageClass(age.accent, age.bold)}`}>{age.label}</p>
        {age.createdLabel !== null && (
          <p className="text-[10px] text-[var(--color-text-tertiary)]">
            {age.createdLabel}
          </p>
        )}
      </div>

      {meta.length > 0 && (
        <p className="truncate text-xs text-[var(--color-text-secondary)]">
          {meta.join(' · ')}
        </p>
      )}

      {platz && (
        <EdvanceBadge variant="success">
          <MonitorSmartphone className="mr-1 inline h-3.5 w-3.5" />
          {platz.label}
        </EdvanceBadge>
      )}

      {column.key === 'neu' && (
        <Button size="sm" onClick={() => onOpenErstgespraech(lead)}>
          Erstgespräch erfassen
        </Button>
      )}
      {column.key === 'gespraech' && (
        <Button size="sm" onClick={() => onOpenErstgespraech(lead)}>
          Für LSA freigeben
        </Button>
      )}
      {column.key === 'analyse' && (
        <>
          <Button size="sm" onClick={() => onAssignPlatz(lead)}>
            Platz vergeben
          </Button>
          <p className="text-xs text-[var(--color-text-tertiary)]">
            Analyse läuft — Ergebnis abwarten.
          </p>
        </>
      )}
      {column.key === 'entscheidung' && (
        <Button size="sm" onClick={() => onAssignPlatz(lead)}>
          Platz vergeben
        </Button>
      )}
    </EdvanceCard>
  )
}
