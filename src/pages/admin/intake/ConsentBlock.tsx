import { useState } from 'react'
import { CheckCircle2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { OptionChips } from './OptionChips'
import { ConsentDialog } from './ConsentDialog'
import type { IntakeFormState } from './formState'

export type ConsentState = {
  at: string | null
  by: string | null
  signature: string | null
}

type ConsentBlockProps = {
  form: IntakeFormState
  consent: ConsentState
  saving: boolean
  onSign: (signature: string) => void
  /** Fachwahl, wenn der Lead mehrere Faecher hat. */
  selectedSubject: string | null
  onSelectSubject: (subject: string) => void
  /** Anzeigename der erfassenden Person. */
  byLabel: string | null
  /** Ohne angelegten Lead laesst sich noch nichts unterschreiben. */
  disabled: boolean
}

const berlinDate = (iso: string): string =>
  new Date(iso).toLocaleString('de-DE', {
    timeZone: 'Europe/Berlin',
    dateStyle: 'medium',
    timeStyle: 'short',
  })

/**
 * Abgesetzter Block am Ende von Schritt 2: Fachwahl (bei mehreren Faechern)
 * und die DSGVO-Einwilligung. Eine erteilte Einwilligung ist endgueltig — sie
 * laesst sich nur noch ansehen.
 */
export function ConsentBlock({
  form,
  consent,
  saving,
  onSign,
  selectedSubject,
  onSelectSubject,
  byLabel,
  disabled,
}: ConsentBlockProps): JSX.Element {
  const [dialogOpen, setDialogOpen] = useState(false)
  const given = consent.at !== null

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
      {form.subjects.length > 1 && (
        <div className="flex flex-col gap-2">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Für welches Fach ist die LSA?
          </p>
          <OptionChips
            options={form.subjects.map((s) => ({ value: s, label: s }))}
            selected={selectedSubject ? [selectedSubject] : []}
            onToggle={onSelectSubject}
          />
        </div>
      )}

      <div className="flex flex-col gap-2">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          DSGVO-Einwilligung
        </p>

        {given ? (
          <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2 text-sm text-[var(--color-success)]">
              <CheckCircle2 className="h-5 w-5 shrink-0" />
              <span>
                Unterschrieben am {berlinDate(consent.at as string)}
                {byLabel ? ` · erfasst von ${byLabel}` : ''}
              </span>
            </div>
            {consent.signature && (
              <img
                src={consent.signature}
                alt="Unterschrift der Eltern"
                className="h-16 w-48 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] object-contain"
              />
            )}
            <button
              type="button"
              onClick={() => setDialogOpen(true)}
              className="self-start text-sm font-medium text-[var(--color-text-link)] underline"
            >
              Dokument ansehen
            </button>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            <p className="text-sm text-[var(--color-text-secondary)]">
              DSGVO-Einwilligung erforderlich
            </p>
            <Button
              onClick={() => setDialogOpen(true)}
              disabled={disabled}
              className="self-start"
            >
              Einwilligung einholen
            </Button>
            {disabled && (
              <p className="text-xs text-[var(--color-text-tertiary)]">
                Zuerst Schritt 1 speichern — die Einwilligung hängt am Lead.
              </p>
            )}
          </div>
        )}
      </div>

      <ConsentDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        signature={given ? consent.signature : null}
        saving={saving}
        onSign={(dataUrl) => {
          onSign(dataUrl)
          setDialogOpen(false)
        }}
      />
    </div>
  )
}
