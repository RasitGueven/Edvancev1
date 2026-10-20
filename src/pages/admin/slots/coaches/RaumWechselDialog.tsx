import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import { stammschichtRaumWechseln } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsCoaches } from '@/types/slotplan'
import { datumVoll, wochentagName } from '../slotsFormat'
import { endetVorher, konfliktSatzWechsel, standardAb, zielraumBesetzt, type Block, type CoachDaten } from './coaches.model'

export const DATUM_FELD = 'h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm tabular-nums'
export const FELD_LABEL = 'flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]'

type Props = {
  coach: CoachDaten
  block: Block
  daten: SlotsCoaches
  onClose: () => void
  onGespeichert: (meldung: string) => void
}

/**
 * W4, Entscheidung 3: Raum eines Blocks ab einem Datum ändern (Standard: nächster Montag). Die Kinder hängen am Raum;
 * nur mit Häkchen ziehen ihre Stammplätze mit. Ist der Zielraum zu einer der Zeiten laut slots_coaches schon besetzt,
 * ist „Raum ändern“ gesperrt und der Grund steht darüber.
 */
export function RaumWechselDialog({ coach, block, daten, onClose, onGespeichert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const ziele = daten.raeume.filter((r) => r.id !== block.raumId)
  const [zielId, setZielId] = useState(ziele[0]?.id ?? '')
  const [ab, setAb] = useState(standardAb(block))
  const [mit, setMit] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  const ziel = ziele.find((r) => r.id === zielId)
  const tag = wochentagName(block.wochentag, i18n.language)
  const besetzt = ziel ? zielraumBesetzt(block, ziel.id, ab, daten.coaches) : []
  const n = block.kinder
  const sperre = !ziel
    ? t('coaches2.wechsel.keinZiel')
    : endetVorher(block, ab) && block.gueltigBis
      ? t('coaches2.wechsel.endet', { datum: datumVoll(block.gueltigBis, i18n.language) })
    : besetzt.length > 0
      ? t('coaches2.wechsel.gesperrt')
      : null

  const speichern = async (): Promise<void> => {
    if (!ziel || sperre) return
    setSpeichert(true)
    setFehler(null)
    const mitKindern = mit && n > 0
    const res = await stammschichtRaumWechseln(block.ids, ziel.id, ab, mitKindern)
    setSpeichert(false)
    if (res.error !== null) {
      const satz = konfliktSatzWechsel(res, block, { id: ziel.id, name: ziel.name, ab }, daten.coaches)
      return setFehler(satz ? t(satz.schluessel, { ...satz.werte, tag }) : t(slotsFehlerSchluessel(res)))
    }
    const werte = { coach: coach.name ?? t('kind.ohneName'), datum: datumVoll(ab, i18n.language), ziel: ziel.name, alt: block.raumName }
    onGespeichert(mitKindern
      ? t('coaches2.wechsel.gespeichertMit', { ...werte, count: res.data?.kinder ?? 0 })
      : t('coaches2.wechsel.gespeichert', werte))
  }

  return (
    <Modal
      open
      onClose={onClose}
      size="md"
      title={t('coaches2.wechsel.titel')}
      description={t('coaches2.wechsel.kopf', { coach: coach.name ?? t('kind.ohneName'), tag, beginn: block.beginn, ende: block.ende, raum: block.raumName })}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" onClick={() => void speichern()} disabled={sperre !== null || speichert} loading={speichert} title={sperre ?? undefined}>
              {t('coaches2.wechsel.knopf')}
            </Button>
          </div>
          {sperre && <p className="text-xs text-[var(--color-text-secondary)]">{sperre}</p>}
        </div>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="grid grid-cols-2 gap-4">
          <label className={FELD_LABEL}>
            {t('coaches2.wechsel.ziel')}
            <select autoFocus className={SELECT_MD} value={zielId} disabled={ziele.length === 0}
              onChange={(e) => { setZielId(e.target.value); setFehler(null) }}>
              {ziele.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
            </select>
          </label>
          <label className={FELD_LABEL}>
            {t('coaches2.wechsel.ab')}
            <input type="date" value={ab} min={berlinToday()} max={block.gueltigBis ?? undefined} className={DATUM_FELD}
              onChange={(e) => { if (e.target.value) { setAb(e.target.value); setFehler(null) } }} />
          </label>
        </div>
        {besetzt.length > 0 && ziel && (
          <p role="alert" className="rounded-[var(--radius-md)] bg-[var(--color-error-coach-light)] p-4 text-sm text-[var(--color-error-coach)]">
            {t('coaches2.wechsel.besetzt', {
              raum: ziel.name,
              liste: besetzt
                .map((b) => b.coach
                  ? t('coaches2.wechsel.besetztEintrag', { tag, beginn: b.beginn, coach: b.coach })
                  : t('coaches2.wechsel.besetztOhneName', { tag, beginn: b.beginn }))
                .join(', '),
            })}
          </p>
        )}
        <p className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-4 text-sm text-[var(--color-text-secondary)]">
          {t('coaches2.wechsel.satz', { count: n, raum: block.raumName })}
        </p>
        {n > 0 && ziel && (
          <label className="flex min-h-[44px] cursor-pointer items-center gap-2 text-sm text-[var(--color-text-primary)]">
            <input type="checkbox" checked={mit} onChange={(e) => setMit(e.target.checked)} className="h-5 w-5 accent-[var(--color-primary)]" />
            {t('coaches2.wechsel.mit', { count: n, ziel: ziel.name })}
          </label>
        )}
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{fehler}</p>}
      </div>
    </Modal>
  )
}
