import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { ladeZiele, zusatzterminBuchen } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsZiel, SlotsZiele } from '@/types/slotplan'
import { datumKurz } from '../slotsFormat'
import { ZieleRaster, zielKey } from './ZieleRaster'

/** Zusatztermin vom Kind aus (Anforderung G 43–46): wie Umbuchen, ohne Absage-Teil. */
export function ZusatzterminDialog({
  kind,
  onClose,
  onGespeichert,
}: {
  kind: { student_id: string; name: string | null } | null
  onClose: () => void
  onGespeichert: (meldung: string) => void
}): JSX.Element | null {
  const { t, i18n } = useTranslation('slots')
  const [ziele, setZiele] = useState<SlotsZiele | null>(null)
  const [ziel, setZiel] = useState<SlotsZiel | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  useEffect(() => {
    if (!kind) return
    let aktiv = true
    void ladeZiele(kind.student_id, null, null, berlinToday(), 4).then((res) => {
      if (!aktiv) return
      setZiele(res.data)
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
    })
    return () => {
      aktiv = false
    }
  }, [kind])

  if (!kind) return null

  const speichern = async (): Promise<void> => {
    if (!ziel) return
    setSpeichert(true)
    setFehler(null)
    const res = await zusatzterminBuchen(kind.student_id, ziel.datum, ziel.zeit_id)
    setSpeichert(false)
    if (res.error !== null) {
      setFehler(slotsFehlerSchluessel(res))
      return
    }
    onGespeichert(t('dialog.zusatz.gebucht', { name: kind.name, datum: datumKurz(ziel.datum, i18n.language), beginn: ziel.beginn }))
  }

  return (
    <Modal
      open
      onClose={onClose}
      title={t('dialog.zusatz.titel')}
      description={t('dialog.zusatz.wer', { name: kind.name })}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" autoFocus onClick={() => void speichern()} disabled={!ziel || speichert} loading={speichert}>
              {t('dialog.zusatz.buchen')}
            </Button>
          </div>
          {!ziel && <p className="text-xs text-[var(--color-text-tertiary)]">{t('dialog.ziele.waehlen')}</p>}
        </div>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.ziele.regeln')}</p>
        {ziele?.kein_budget ? (
          <p className="text-sm text-[var(--color-text-secondary)]">{t('fehler.SL005')}</p>
        ) : ziele ? (
          <ZieleRaster ziele={ziele.ziele} gewaehlt={ziel ? zielKey(ziel) : null} onWahl={setZiel} />
        ) : null}
        {ziel?.verdraengt && (
          <p className="text-sm text-[var(--color-gold-warning)]">
            {t('dialog.ziele.verdraengt', { datum: datumKurz(ziel.verdraengt, i18n.language) })}
          </p>
        )}
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
