import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { stammschichtBeenden } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { datumVoll, wochentagName } from '../slotsFormat'
import { standardAb, type Block, type CoachDaten } from './coaches.model'
import { DATUM_FELD, FELD_LABEL } from './RaumWechselDialog'

type Props = {
  coach: CoachDaten
  block: Block
  onClose: () => void
  onGespeichert: (meldung: string) => void
  /** Nach einem Teilerfolg: Schichten neu laden, der Dialog bleibt mit dem Fehler offen. */
  onTeilweise: () => void
}

/**
 * W4, Entscheidung 4: Block entfernen mit Bestätigung im Dialog (kein confirm()). stammschicht_beenden je Stunde ab
 * dem gewählten Datum (Standard: nächster Montag), nacheinander. Scheitert eine Stunde, steht der Fehler im Dialog,
 * und die Liste lädt neu (die übrigen Stunden sind dann schon beendet).
 */
export function EntfernenDialog({ coach, block, onClose, onGespeichert, onTeilweise }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [ab, setAb] = useState(standardAb(block))
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)
  const werte = {
    coach: coach.name ?? t('kind.ohneName'), tag: wochentagName(block.wochentag, i18n.language),
    beginn: block.beginn, ende: block.ende, raum: block.raumName,
  }

  const entfernen = async (): Promise<void> => {
    setSpeichert(true)
    setFehler(null)
    let fertig = 0
    for (const id of block.ids) {
      const res = await stammschichtBeenden(id, ab)
      if (res.error !== null) {
        setSpeichert(false)
        if (fertig === 0) return setFehler(t(slotsFehlerSchluessel(res)))
        setFehler(t('coaches2.weg.teilweise', { fertig, gesamt: block.ids.length, fehler: t(slotsFehlerSchluessel(res)) }))
        return onTeilweise()
      }
      fertig += 1
    }
    setSpeichert(false)
    onGespeichert(t('coaches2.weg.gespeichert', { ...werte, datum: datumVoll(ab, i18n.language) }))
  }

  return (
    <Modal
      open
      onClose={onClose}
      size="md"
      title={t('coaches2.weg.titel')}
      description={t('coaches2.weg.kopf', werte)}
      footer={
        <div className="flex gap-2">
          <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
          <Button type="button" variant="destructive" onClick={() => void entfernen()} disabled={speichert} loading={speichert}>
            {t('coaches2.weg.knopf')}
          </Button>
        </div>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('coaches2.weg.satz', { raum: block.raumName })}</p>
        <label className={`${FELD_LABEL} self-start`}>
          {t('coaches2.weg.ab')}
          <input type="date" autoFocus value={ab} min={berlinToday()} className={DATUM_FELD}
            onChange={(e) => { if (e.target.value) { setAb(e.target.value); setFehler(null) } }} />
        </label>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{fehler}</p>}
      </div>
    </Modal>
  )
}
