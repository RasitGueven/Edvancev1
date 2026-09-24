import { useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { SignaturePad, type SignaturePadHandle } from '../intake/SignaturePad'

type UnterschriftPanelProps = {
  saving: boolean
  onCancel: () => void
  onSign: (signaturVertrag: string, signaturSepa: string) => void
}

/** Zwei Unterschriftsfelder — Vertrag und SEPA-Mandat — mit dem vorhandenen SignaturePad. */
export function UnterschriftPanel({ saving, onCancel, onSign }: UnterschriftPanelProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const { t: tc } = useTranslation('common')
  const vertragRef = useRef<SignaturePadHandle>(null)
  const sepaRef = useRef<SignaturePadHandle>(null)
  const [inkVertrag, setInkVertrag] = useState(false)
  const [inkSepa, setInkSepa] = useState(false)
  const complete = inkVertrag && inkSepa

  const feld = (
    label: string,
    ref: React.RefObject<SignaturePadHandle>,
    onInk: (ink: boolean) => void,
  ): JSX.Element => (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm font-semibold text-[var(--color-text-primary)]">{label}</p>
        <Button size="sm" variant="ghost" onClick={() => ref.current?.clear()} disabled={saving}>
          {t('sign.clear')}
        </Button>
      </div>
      <SignaturePad ref={ref} onInkChange={onInk} />
    </div>
  )

  return (
    <div className="flex flex-col gap-4">
      {feld(t('sign.vertrag'), vertragRef, setInkVertrag)}
      {feld(t('sign.sepa'), sepaRef, setInkSepa)}
      <div className="flex flex-wrap justify-end gap-2">
        <Button variant="outline" onClick={onCancel} disabled={saving}>
          {tc('cancel')}
        </Button>
        <span title={complete ? undefined : t('sign.missing')}>
          <Button
            disabled={!complete || saving}
            loading={saving}
            onClick={() => {
              const v = vertragRef.current?.toDataURL()
              const s = sepaRef.current?.toDataURL()
              if (v && s) onSign(v, s)
            }}
          >
            {t('sign.submit')}
          </Button>
        </span>
      </div>
    </div>
  )
}
