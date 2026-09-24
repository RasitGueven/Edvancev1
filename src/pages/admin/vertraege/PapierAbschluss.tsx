import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { berlinToday } from '@/lib/datetime'

type PapierAbschlussProps = {
  idPrefix: string
  saving: boolean
  onConfirm: (unterschriebenAm: string) => void
}

/**
 * "Unterschrieben erhalten" fuer zurueckgekommene Papiervertraege — inline mit
 * Abschlussdatum statt Bestaetigungs-Modal.
 */
export function PapierAbschluss({ idPrefix, saving, onConfirm }: PapierAbschlussProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const { t: tc } = useTranslation('common')
  const [open, setOpen] = useState(false)
  const [datum, setDatum] = useState(berlinToday())

  if (!open) {
    return (
      <Button size="sm" onClick={() => setOpen(true)}>
        {t('paper.action')}
      </Button>
    )
  }

  return (
    <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] p-4">
      <Label htmlFor={`${idPrefix}-signed-on`}>{t('paper.date')}</Label>
      <Input
        id={`${idPrefix}-signed-on`}
        type="date"
        max={berlinToday()}
        value={datum}
        onChange={(e) => setDatum(e.target.value)}
      />
      <div className="flex flex-wrap gap-2">
        <Button size="sm" disabled={datum === '' || saving} loading={saving} onClick={() => onConfirm(datum)}>
          {t('paper.confirm')}
        </Button>
        <Button size="sm" variant="outline" disabled={saving} onClick={() => setOpen(false)}>
          {tc('cancel')}
        </Button>
      </div>
    </div>
  )
}
