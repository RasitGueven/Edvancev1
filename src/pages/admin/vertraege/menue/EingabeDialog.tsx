import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { TEXTAREA_MD } from '@/lib/formStyles'

export type DialogFeld = 'grund' | 'betrag' | 'datum'

type EingabeDialogProps = {
  offen: boolean
  titel: string
  beschreibung?: string
  feld: DialogFeld
  label: string
  /** Pflichtfeld — ohne Eingabe bleibt der Knopf gesperrt. */
  pflicht: boolean
  bestaetigen: string
  saving: boolean
  onAbbruch: () => void
  onBestaetigen: (wert: string) => void
}

/**
 * Eine Rueckfrage mit genau einem Feld: Grund, Betrag oder Datum.
 *
 * Kein window.confirm und kein window.prompt — die sind nicht gestaltbar, nicht
 * uebersetzbar und auf dem iPad am Empfang eine Zumutung. Die Modal-Komponente
 * des Designsystems kann alles, was hier gebraucht wird.
 */
export function EingabeDialog({
  offen,
  titel,
  beschreibung,
  feld,
  label,
  pflicht,
  bestaetigen,
  saving,
  onAbbruch,
  onBestaetigen,
}: EingabeDialogProps): JSX.Element | null {
  const { t: tc } = useTranslation('common')
  const [wert, setWert] = useState('')
  const leer = wert.trim() === ''

  return (
    <Modal
      open={offen}
      onClose={onAbbruch}
      title={titel}
      description={beschreibung}
      size="md"
      footer={
        <div className="flex flex-wrap justify-end gap-2">
          <Button variant="outline" disabled={saving} onClick={onAbbruch}>
            {tc('cancel')}
          </Button>
          <Button
            disabled={saving || (pflicht && leer)}
            loading={saving}
            onClick={() => onBestaetigen(wert.trim())}
          >
            {bestaetigen}
          </Button>
        </div>
      }
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="dialog-feld">
          {label}
          {pflicht && (
            <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
          )}
        </Label>
        {feld === 'grund' ? (
          <textarea
            id="dialog-feld"
            className={TEXTAREA_MD}
            value={wert}
            disabled={saving}
            onChange={(e) => setWert(e.target.value)}
          />
        ) : (
          <Input
            id="dialog-feld"
            type={feld === 'datum' ? 'date' : 'number'}
            inputMode={feld === 'betrag' ? 'decimal' : undefined}
            value={wert}
            disabled={saving}
            onChange={(e) => setWert(e.target.value)}
          />
        )}
      </div>
    </Modal>
  )
}
