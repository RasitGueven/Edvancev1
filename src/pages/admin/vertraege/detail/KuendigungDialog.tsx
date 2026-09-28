import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { TEXTAREA_MD } from '@/lib/formStyles'

type Props = {
  offen: boolean
  saving: boolean
  onAbbruch: () => void
  onBestaetigen: (zum: string, grund: string) => void
}

/**
 * Sonderkündigung: Datum UND Grund, beides Pflicht.
 *
 * Eine ordentliche Kündigung gibt es nicht (Entscheidung 7). Was es gibt, ist
 * der Einzelfall — und für den steht sonst später niemand mehr gerade, wenn
 * nicht dabeisteht, warum.
 */
export function KuendigungDialog({ offen, saving, onAbbruch, onBestaetigen }: Props): JSX.Element | null {
  const { t } = useTranslation('vertraege')
  const { t: tc } = useTranslation('common')
  const [zum, setZum] = useState('')
  const [grund, setGrund] = useState('')
  const unvollstaendig = zum === '' || grund.trim() === ''

  return (
    <Modal
      open={offen}
      onClose={onAbbruch}
      title={t('detailansicht.kuendigungTitel')}
      description={t('detailansicht.kuendigungHinweis')}
      size="md"
      footer={
        <div className="flex flex-wrap justify-end gap-2">
          <Button variant="outline" disabled={saving} onClick={onAbbruch}>
            {tc('cancel')}
          </Button>
          <span title={unvollstaendig ? t('detailansicht.kuendigungFehlt') : undefined}>
            <Button
              disabled={saving || unvollstaendig}
              loading={saving}
              onClick={() => onBestaetigen(zum, grund.trim())}
            >
              {t('detailansicht.kuendigungBestaetigen')}
            </Button>
          </span>
        </div>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <Label htmlFor="kuendigung-zum">
            {t('detailansicht.kuendigungZum')}
            <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
          </Label>
          <Input
            id="kuendigung-zum"
            type="date"
            className="max-w-xs"
            value={zum}
            disabled={saving}
            onChange={(e) => setZum(e.target.value)}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="kuendigung-grund">
            {t('detailansicht.kuendigungGrund')}
            <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
          </Label>
          <textarea
            id="kuendigung-grund"
            className={TEXTAREA_MD}
            value={grund}
            disabled={saving}
            onChange={(e) => setGrund(e.target.value)}
          />
        </div>
      </div>
    </Modal>
  )
}
