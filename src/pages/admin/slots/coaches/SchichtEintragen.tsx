import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { SELECT_MD } from '@/lib/formStyles'
import { stammschichtBlockAnlegen } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsCoaches } from '@/types/slotplan'
import { wochentagName } from '../slotsFormat'
import { konfliktSatzAnlegen } from './coaches.model'

const LABEL = 'flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]'
const TAGE = [1, 2, 3, 4, 5]

/**
 * W4, Entscheidung 2: „Schicht eintragen“ als ein Block (Coach, Wochentag, Raum, von, bis) über
 * stammschicht_block_anlegen. Konflikte erscheinen als Satz mit Uhrzeit, nie als Rohtext.
 */
export function SchichtEintragen({ daten, onGespeichert }: { daten: SlotsCoaches; onGespeichert: (meldung: string) => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const { coaches, raeume, zeiten } = daten
  const [coachId, setCoachId] = useState(coaches[0]?.id ?? '')
  const [wochentag, setWochentag] = useState(1)
  const [raumWahl, setRaumId] = useState(raeume[0]?.id ?? '')
  const [vonWahl, setVonId] = useState(zeiten[0]?.id ?? '')
  const [bisWahl, setBisId] = useState(zeiten[zeiten.length - 1]?.id ?? '')
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  // Nach dem Wochenwechsel können Uhrzeiten oder Räume fehlen: dann gilt die erste bzw. letzte.
  const raumId = raeume.some((r) => r.id === raumWahl) ? raumWahl : raeume[0]?.id ?? ''
  const vonId = zeiten.some((z) => z.id === vonWahl) ? vonWahl : zeiten[0]?.id ?? ''
  const bisId = zeiten.some((z) => z.id === bisWahl) ? bisWahl : zeiten[zeiten.length - 1]?.id ?? ''

  const von = zeiten.findIndex((z) => z.id === vonId)
  const bis = zeiten.findIndex((z) => z.id === bisId)
  const coach = coaches.find((c) => c.id === coachId) ?? coaches[0]
  const raum = raeume.find((r) => r.id === raumId)
  const tag = wochentagName(wochentag, i18n.language)
  const grund =
    raeume.length === 0 ? t('coaches2.neu.keinRaum')
      : zeiten.length === 0 ? t('coaches2.neu.keineZeit')
        : bis < von ? t('coaches2.neu.bisVorVon')
          : null

  const speichern = async (): Promise<void> => {
    if (grund || !coach || !raum) return
    setSpeichert(true)
    setFehler(null)
    const res = await stammschichtBlockAnlegen(coach.id, wochentag, vonId, bisId, raum.id, null)
    setSpeichert(false)
    if (res.error !== null) {
      const name = coach.name ?? t('kind.ohneName')
      const satz = konfliktSatzAnlegen(res, { coachId: coach.id, wochentag, raumId: raum.id }, coaches, { raum: raum.name, coach: name })
      return setFehler(satz ? t(satz.schluessel, { ...satz.werte, tag }) : t(slotsFehlerSchluessel(res)))
    }
    onGespeichert(t('coaches2.neu.gespeichert', {
      coach: coach.name ?? t('kind.ohneName'), tag, beginn: zeiten[von].beginn, ende: zeiten[bis].ende, raum: raum.name,
    }))
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-base font-semibold">{t('coaches2.neu.titel')}</h2>
      <p className="text-sm text-[var(--color-text-secondary)]">{t('coaches2.neu.satz')}</p>
      <div className="grid grid-cols-2 gap-4">
        <label className={`${LABEL} col-span-2`}>
          {t('coaches2.neu.coach')}
          <select className={SELECT_MD} value={coach?.id ?? ''} onChange={(e) => { setCoachId(e.target.value); setFehler(null) }}>
            {coaches.map((c) => <option key={c.id} value={c.id}>{c.name ?? t('kind.ohneName')}</option>)}
          </select>
        </label>
        <label className={LABEL}>
          {t('coaches2.neu.tag')}
          <select className={SELECT_MD} value={wochentag} onChange={(e) => { setWochentag(Number(e.target.value)); setFehler(null) }}>
            {TAGE.map((w) => <option key={w} value={w}>{wochentagName(w, i18n.language, true)}</option>)}
          </select>
        </label>
        <label className={LABEL}>
          {t('coaches2.neu.raum')}
          <select className={SELECT_MD} value={raumId} onChange={(e) => { setRaumId(e.target.value); setFehler(null) }}>
            {raeume.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
          </select>
        </label>
        <label className={LABEL}>
          {t('coaches2.neu.von')}
          <select className={SELECT_MD} value={vonId} onChange={(e) => { setVonId(e.target.value); setFehler(null) }}>
            {zeiten.map((z) => <option key={z.id} value={z.id}>{z.beginn}</option>)}
          </select>
        </label>
        <label className={LABEL}>
          {t('coaches2.neu.bis')}
          <select className={SELECT_MD} value={bisId} onChange={(e) => { setBisId(e.target.value); setFehler(null) }}>
            {zeiten.map((z) => <option key={z.id} value={z.id}>{z.ende}</option>)}
          </select>
        </label>
      </div>
      {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{fehler}</p>}
      <div className="flex flex-col items-start gap-2">
        <Button type="button" onClick={() => void speichern()} disabled={grund !== null || speichert} loading={speichert}
          title={grund ?? undefined}>
          {t('coaches2.neu.knopf')}
        </Button>
        {grund && <p className="text-xs text-[var(--color-text-secondary)]">{grund}</p>}
      </div>
    </EdvanceCard>
  )
}
