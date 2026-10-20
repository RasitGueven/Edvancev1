import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { SELECT_MD } from '@/lib/formStyles'
import { terminFaelltAus, terminRaumOeffnen } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsTermin } from '@/types/slotplan'

type Props = { termin: SlotsTermin; onClose: () => void; onGespeichert: (meldung: string) => void }

function Fuss({ grund, children, onClose }: { grund?: string | null; children: React.ReactNode; onClose: () => void }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <div className="flex w-full flex-col items-end gap-2">
      <div className="flex gap-2">
        <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
        {children}
      </div>
      {grund && <p className="text-xs text-[var(--color-text-tertiary)]">{grund}</p>}
    </div>
  )
}

/** Raum öffnen: Raum und Coach nur für diesen Termin (Anforderung D 23). */
export function RaumOeffnenDialog({ termin, onClose, onGespeichert }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const freieCoaches = termin.coaches.filter((c) => c.raum_id === null)
  const [raum, setRaum] = useState(termin.raeume_schliessbar[0]?.raum_id ?? '')
  const [coach, setCoach] = useState(freieCoaches[0]?.id ?? '')
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)
  const grund = !raum ? t('dialog.raum.keinRaum') : !coach ? t('dialog.raum.keinCoach') : null

  const speichern = async (): Promise<void> => {
    setSpeichert(true)
    const res = await terminRaumOeffnen(termin.datum, termin.zeit.id, raum, coach)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(t('dialog.raum.geoeffnet', { raum: termin.raeume_schliessbar.find((r) => r.raum_id === raum)?.name }))
  }

  return (
    <Modal
      open
      size="md"
      onClose={onClose}
      title={t('dialog.raum.titel')}
      description={t('dialog.raum.nurDieser')}
      footer={
        <Fuss onClose={onClose} grund={grund}>
          <Button type="button" onClick={() => void speichern()} disabled={!!grund || speichert} loading={speichert}>
            {t('dialog.raum.speichern')}
          </Button>
        </Fuss>
      }
    >
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <label className="flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]">
          {t('dialog.raum.raum')}
          <select autoFocus className={SELECT_MD} value={raum} onChange={(e) => setRaum(e.target.value)}>
            {termin.raeume_schliessbar.map((r) => <option key={r.raum_id} value={r.raum_id}>{r.name}</option>)}
          </select>
        </label>
        <label className="flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]">
          {t('dialog.raum.coach')}
          <select className={SELECT_MD} value={coach} onChange={(e) => setCoach(e.target.value)}>
            {freieCoaches.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </label>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)] sm:col-span-2">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}

/** Ganzer Termin fällt aus: die einzige Bestätigung als Dialog, mit Zahl der Kinder. */
export function FaelltAusDialog({ termin, onClose, onGespeichert }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const anzahl = termin.raeume.reduce((n, r) => n + r.kinder.length, 0) + termin.ohne_raum.length
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  const speichern = async (): Promise<void> => {
    setSpeichert(true)
    const res = await terminFaelltAus(termin.datum, termin.zeit.id)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(t('dialog.faelltAus.gespeichert', { count: res.data?.betroffen ?? anzahl }))
  }

  return (
    <Modal
      open
      size="md"
      onClose={onClose}
      title={t('dialog.faelltAus.titel')}
      footer={
        <Fuss onClose={onClose}>
          <Button type="button" variant="destructive" autoFocus onClick={() => void speichern()} disabled={speichert} loading={speichert}>
            {t('dialog.faelltAus.speichern')}
          </Button>
        </Fuss>
      }
    >
      <div className="flex flex-col gap-2">
        <p className="text-sm text-[var(--color-text-primary)]">{t('dialog.faelltAus.frage', { count: anzahl })}</p>
        <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.faelltAus.einheiten')}</p>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
