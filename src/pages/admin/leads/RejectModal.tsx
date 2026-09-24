import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { TEXTAREA_MD } from '@/lib/formStyles'
import { REJECTION_REASONS, isRejectionComplete } from '@/lib/vertrag/rejection'
import type { RejectionReason } from '@/types'
import { OptionChips } from '../intake/OptionChips'

type RejectModalProps = {
  /** Name im Untertitel; null = geschlossen. */
  name: string | null
  saving: boolean
  onClose: () => void
  onConfirm: (reason: RejectionReason, note: string | null) => void
}

/**
 * Ablehnen mit Pflichtgrund — fuer Leads (Board) und Vertraege ("Doch
 * abgelehnt"). Nichts wird geloescht; der Eintrag wandert ins Archiv.
 */
export function RejectModal({ name, saving, onClose, onConfirm }: RejectModalProps): JSX.Element {
  const { t } = useTranslation('leads')
  const { t: tc } = useTranslation('common')
  const [reason, setReason] = useState<RejectionReason | null>(null)
  const [note, setNote] = useState('')
  const complete = isRejectionComplete(reason, note)

  const close = (): void => {
    setReason(null)
    setNote('')
    onClose()
  }

  return (
    <Modal
      open={name !== null}
      onClose={close}
      size="md"
      title={t('reject.title')}
      description={name ? t('reject.description', { name }) : undefined}
      footer={
        <>
          <Button variant="outline" onClick={close} disabled={saving}>
            {tc('cancel')}
          </Button>
          <Button
            variant="destructive"
            disabled={!complete || saving}
            loading={saving}
            onClick={() => {
              if (reason) onConfirm(reason, note.trim() === '' ? null : note.trim())
            }}
          >
            {t('reject.confirm')}
          </Button>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
            {t('reject.reason')}
          </p>
          <OptionChips
            columns
            options={REJECTION_REASONS.map((value) => ({ value, label: t(`reasons.${value}`) }))}
            selected={reason ? [reason] : []}
            onToggle={setReason}
          />
        </div>
        {reason === 'sonstiges' && (
          <div className="flex flex-col gap-2">
            <Label htmlFor="reject-note">{t('reject.note')}</Label>
            <textarea
              id="reject-note"
              className={TEXTAREA_MD}
              value={note}
              placeholder={t('reject.notePlaceholder')}
              onChange={(e) => setNote(e.target.value)}
            />
            {note.trim() === '' && (
              <p className="text-xs text-[var(--color-text-tertiary)]">{t('reject.noteRequired')}</p>
            )}
          </div>
        )}
      </div>
    </Modal>
  )
}
