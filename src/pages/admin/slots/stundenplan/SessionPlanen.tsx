import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { berlinLocalToIso, berlinToday } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import { createSession } from '@/lib/supabase/sessions'
import type { SlotsEinstellungen } from '@/types/slotplan'
import type { SessionLeitung } from '@/types/stundenplan'
import { raeumeAktivAm } from './stundenplan.model'

type Props = {
  leitung: SessionLeitung[]
  raeume: SlotsEinstellungen['raeume']
  /** Nach dem Anlegen: Tag der neuen Session (die Woche springt dorthin). */
  onAngelegt: (datum: string) => void
}

/**
 * „Session planen“ (Slots S2, Entscheidung 4): eine spätere Einzel-Session mit Leitung (Coach oder Admin),
 * Raum aus den aktiven Räumen des Tages, Datum und Uhrzeit. Kinder kommen danach in der Session-Karte dazu.
 */
export function SessionPlanen({ leitung, raeume, onAngelegt }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const [offen, setOffen] = useState(false)
  const [coach, setCoach] = useState('')
  const [datum, setDatum] = useState(berlinToday())
  const [zeit, setZeit] = useState('')
  const [raum, setRaum] = useState('')
  const [speichert, setSpeichert] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)

  const aktiv = datum ? raeumeAktivAm(raeume, datum) : []
  const raumName = aktiv.find((r) => r.id === raum)?.name ?? null
  const fehlt = !coach ? 'coach' : !datum || !zeit ? 'zeit' : !raumName ? 'raum' : null

  const anlegen = async (): Promise<void> => {
    if (fehlt || !raumName) return
    setSpeichert(true)
    setFehler(null)
    const res = await createSession(coach, berlinLocalToIso(datum, zeit), raumName)
    setSpeichert(false)
    if (res.error) return setFehler('fehler.allgemein')
    setOffen(false)
    setZeit('')
    onAngelegt(datum)
  }

  if (!offen) {
    return (
      <Button type="button" variant="outline" className="self-start" onClick={() => setOffen(true)}>
        {t('stundenplan.planen.oeffnen')}
      </Button>
    )
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6 @4xl:max-w-3xl">
      <h2 className="text-base font-semibold">{t('stundenplan.planen.titel')}</h2>
      <p className="text-sm text-[var(--color-text-secondary)]">{t('stundenplan.planen.satz')}</p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="sp-coach">{t('stundenplan.feld.leitung')}</Label>
          <select id="sp-coach" className={SELECT_MD} value={coach} onChange={(e) => setCoach(e.target.value)}>
            <option value="">{t('stundenplan.feld.waehlen')}</option>
            {leitung.map((l) => (
              <option key={l.id} value={l.id}>
                {l.rolle === 'admin' ? t('stundenplan.feld.leitungAdmin', { name: l.name }) : l.name}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="sp-raum">{t('stundenplan.feld.raum')}</Label>
          <select id="sp-raum" className={SELECT_MD} value={raum} onChange={(e) => setRaum(e.target.value)}>
            <option value="">{t('stundenplan.feld.waehlen')}</option>
            {aktiv.map((r) => (
              <option key={r.id} value={r.id}>{r.name}</option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="sp-datum">{t('stundenplan.feld.datum')}</Label>
          <Input id="sp-datum" type="date" value={datum} onChange={(e) => setDatum(e.target.value)} />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="sp-zeit">{t('stundenplan.feld.uhrzeit')}</Label>
          <Input id="sp-zeit" type="time" value={zeit} onChange={(e) => setZeit(e.target.value)} />
        </div>
      </div>
      <div className="flex flex-col gap-1">
        <span className="flex gap-2">
          <Button type="button" onClick={() => void anlegen()} disabled={!!fehlt || speichert} loading={speichert}>
            {t('stundenplan.planen.anlegen')}
          </Button>
          <Button type="button" variant="ghost" onClick={() => setOffen(false)}>{t('dialog.abbrechen')}</Button>
        </span>
        {fehlt && <span className="text-xs text-[var(--color-text-tertiary)]">{t(`stundenplan.planen.fehlt.${fehlt}`)}</span>}
      </div>
      {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
    </EdvanceCard>
  )
}
