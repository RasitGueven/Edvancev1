import { useRef, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Modal } from '@/components/edvance/Modal'
import {
  CONSENT_DOCUMENT_TEXT,
  CONSENT_DOCUMENT_TITLE,
} from './consentDocument'
import { SignaturePad, type SignaturePadHandle } from './SignaturePad'

type ConsentDialogProps = {
  open: boolean
  onClose: () => void
  /** Schreibgeschuetzt: zeigt eine bereits geleistete Unterschrift. */
  signature?: string | null
  saving?: boolean
  onSign?: (dataUrl: string) => void
}

/**
 * Der Einwilligungstext zum Lesen und Unterschreiben. Zwei Zustaende:
 * unterschreiben (Formular) oder ansehen (bereits erteilte Einwilligung).
 * Eine erteilte Einwilligung laesst sich hier nicht ueberschreiben.
 */
export function ConsentDialog({
  open,
  onClose,
  signature = null,
  saving = false,
  onSign,
}: ConsentDialogProps): JSX.Element {
  const padRef = useRef<SignaturePadHandle>(null)
  const [hasInk, setHasInk] = useState(false)
  const readOnly = signature !== null

  const sign = (): void => {
    const dataUrl = padRef.current?.toDataURL()
    if (!dataUrl || !onSign) return
    onSign(dataUrl)
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={CONSENT_DOCUMENT_TITLE}
      size="lg"
      footer={
        readOnly ? (
          <Button variant="outline" onClick={onClose}>
            Schließen
          </Button>
        ) : (
          <>
            <Button variant="outline" onClick={onClose} disabled={saving}>
              Abbrechen
            </Button>
            <Button
              variant="outline"
              onClick={() => padRef.current?.clear()}
              disabled={saving || !hasInk}
            >
              Löschen
            </Button>
            <Button onClick={sign} disabled={saving || !hasInk}>
              {saving ? 'Speichert …' : 'Unterschreiben'}
            </Button>
          </>
        )
      }
    >
      <div className="flex flex-col gap-4">
        <div className="max-h-72 overflow-y-auto rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
          <p className="whitespace-pre-line text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {CONSENT_DOCUMENT_TEXT}
          </p>
        </div>

        {readOnly ? (
          <div className="flex flex-col gap-2">
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              Unterschrift
            </p>
            <img
              src={signature}
              alt="Unterschrift der Eltern"
              className="h-40 w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] object-contain"
            />
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              Unterschrift der Eltern
            </p>
            <SignaturePad ref={padRef} onInkChange={setHasInk} />
            <p className="text-xs text-[var(--color-text-tertiary)]">
              Mit Maus, Stift oder Finger direkt im Feld unterschreiben.
            </p>
          </div>
        )}
      </div>
    </Modal>
  )
}
