import { useState } from 'react'
import { MonitorSmartphone, MoreHorizontal } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { Lead } from '@/types'
import type { LeadPlatz } from '@/lib/supabase/platz'
import { daysWaiting, type BoardColumnKey } from './boardModel'

type LeadCardProps = {
  lead: Lead
  platz?: LeadPlatz
  column: BoardColumnKey
  /** Wizard auf Schritt 1 (Stammdaten) oeffnen — Klick auf den Rufnamen. */
  onOpen: (lead: Lead) => void
  /** Wizard direkt auf Schritt 2 (Erstgespraech) oeffnen. */
  onOpenErstgespraech: (lead: Lead) => void
  onAssignPlatz: (lead: Lead) => void
  onConvert: (lead: Lead) => void
  onReject: (lead: Lead) => void
}

// Ab einer Woche faellt die Wartezeit farblich auf, ab zwei Wochen zusaetzlich
// durch Gewicht. Beides nur ueber vorhandene Tokens.
function waitingClass(days: number): string {
  if (days >= 14) return 'font-bold text-[var(--color-accent)]'
  if (days >= 7) return 'text-[var(--color-accent)]'
  return 'text-[var(--color-text-tertiary)]'
}

export function LeadCard({
  lead,
  platz,
  column,
  onOpen,
  onOpenErstgespraech,
  onAssignPlatz,
  onConvert,
  onReject,
}: LeadCardProps): JSX.Element {
  const [menuOpen, setMenuOpen] = useState(false)
  const days = daysWaiting(lead.created_at)
  // Leere Werte fallen raus, damit keine Trennpunkte ins Leere zeigen.
  const meta = [
    lead.class_level !== null ? `Kl. ${lead.class_level}` : null,
    lead.school_type,
    lead.subjects.length > 0 ? lead.subjects.join(', ') : null,
  ].filter((part): part is string => part !== null && part !== '')

  return (
    <EdvanceCard className="flex flex-col gap-3 p-4">
      <div className="flex items-start justify-between gap-2">
        <button
          type="button"
          onClick={() => onOpen(lead)}
          className="min-h-[44px] text-left text-base font-semibold text-[var(--color-text-primary)] hover:text-[var(--color-primary)]"
        >
          {lead.first_name?.trim() || lead.full_name}
        </button>
        <div
          className="relative"
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
              {lead.status !== 'converted' && lead.status !== 'rejected' && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => {
                    setMenuOpen(false)
                    onConvert(lead)
                  }}
                  className="w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-[var(--color-text-primary)] hover:bg-[var(--color-bg-app)]"
                >
                  In Schüler konvertieren
                </button>
              )}
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

      <p className={`text-xs ${waitingClass(days)}`}>
        {days === 0 ? 'seit heute' : days === 1 ? 'seit 1 Tag' : `seit ${days} Tagen`}
      </p>

      {meta.length > 0 && (
        <p className="text-xs text-[var(--color-text-secondary)]">{meta.join(' · ')}</p>
      )}

      {platz && (
        <EdvanceBadge variant="success">
          <MonitorSmartphone className="mr-1 inline h-3.5 w-3.5" />
          {platz.label}
        </EdvanceBadge>
      )}

      {column === 'neu' && (
        <Button size="sm" onClick={() => onOpenErstgespraech(lead)}>
          Erstgespräch erfassen
        </Button>
      )}
      {column === 'gespraech' && (
        <Button size="sm" onClick={() => onOpenErstgespraech(lead)}>
          Für LSA freigeben
        </Button>
      )}
      {column === 'analyse' && (
        <p className="text-xs text-[var(--color-text-tertiary)]">
          Analyse läuft — Ergebnis abwarten.
        </p>
      )}
      {column === 'entscheidung' && (
        <Button size="sm" onClick={() => onAssignPlatz(lead)}>
          Platz vergeben
        </Button>
      )}
    </EdvanceCard>
  )
}
