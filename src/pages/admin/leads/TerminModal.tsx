import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { berlinLocalParts, berlinLocalToIso } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import type { ErstgespraechStandort, Lead } from '@/types'

const STANDORTE: ErstgespraechStandort[] = ['koeln']

export type TerminInput = { at: string; standort: ErstgespraechStandort }

type TerminModalProps = {
  /** Lead, fuer den der Termin erfasst wird; null = geschlossen. */
  lead: Lead | null
  saving: boolean
  onClose: () => void
  onSave: (lead: Lead, termin: TerminInput) => void
}

/**
 * Termin des Erstgespraechs: Datum, Uhrzeit (Berliner Zeit), Standort. Beim
 * ersten Erfassen wechselt der Lead erst mit dem Speichern die Spalte; ein
 * gesetzter Termin laesst sich hier nachtraeglich aendern.
 */
export function TerminModal({ lead, saving, onClose, onSave }: TerminModalProps): JSX.Element {
  const { t } = useTranslation('leads')
  const { t: tc } = useTranslation('common')
  const [date, setDate] = useState('')
  const [time, setTime] = useState('')
  const [standort, setStandort] = useState<ErstgespraechStandort>('koeln')

  useEffect(() => {
    if (!lead) return
    const current = lead.erstgespraech_at ? berlinLocalParts(lead.erstgespraech_at) : null
    setDate(current?.date ?? '')
    setTime(current?.time ?? '')
    setStandort(lead.erstgespraech_standort ?? 'koeln')
  }, [lead])

  const complete = date !== '' && time !== ''
  const editing = lead?.erstgespraech_at != null

  return (
    <Modal
      open={lead !== null}
      onClose={onClose}
      size="md"
      title={editing ? t('termin.editTitle') : t('termin.title')}
      description={lead ? t('termin.description', { name: lead.full_name }) : undefined}
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={saving}>
            {tc('cancel')}
          </Button>
          <span title={complete ? undefined : t('termin.missing')}>
            <Button
              disabled={!complete || saving}
              loading={saving}
              onClick={() => {
                if (lead) onSave(lead, { at: berlinLocalToIso(date, time), standort })
              }}
            >
              {tc('save')}
            </Button>
          </span>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="termin-date">{t('termin.date')}</Label>
            <Input
              id="termin-date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="termin-time">{t('termin.time')}</Label>
            <Input
              id="termin-time"
              type="time"
              step={300}
              value={time}
              onChange={(e) => setTime(e.target.value)}
            />
          </div>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="termin-standort">{t('termin.location')}</Label>
          <select
            id="termin-standort"
            className={SELECT_MD}
            value={standort}
            onChange={(e) => setStandort(e.target.value as ErstgespraechStandort)}
          >
            {STANDORTE.map((s) => (
              <option key={s} value={s}>
                {t(`standort.${s}`)}
              </option>
            ))}
          </select>
        </div>
      </div>
    </Modal>
  )
}
