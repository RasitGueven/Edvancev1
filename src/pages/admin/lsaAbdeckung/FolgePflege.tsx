import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceCard, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuthContext } from '@/context/AuthContext'
import {
  bestaetigeKaSchulArbeit,
  listKaPlanThemen,
  listKaSchulFolge,
  schuljahrHeute,
  type KaPlanThema,
  type KaSchulArbeit,
} from '@/lib/supabase/kaFolge'

import { OptionChips } from '../intake/OptionChips'

type Props = { schuleId: string; schule: string; klasse: number; onGespeichert: (ok: boolean) => void }

/**
 * Folge der Klassenarbeiten einer Fokus-Schule (F2 Punkt 5, F0 §2): die bestätigten Arbeiten des Schuljahrs und ein
 * schlichtes Formular (Nr., Themen aus dem Schulplan, Datum). Geschrieben wird über bestaetigeKaSchulArbeit
 * (schul_klassenarbeiten, bestaetigt = true, bestaetigt_von; RLS nur Admin) — wie auf der L5-Seite Klassenarbeiten.
 */
export function FolgePflege({ schuleId, schule, klasse, onGespeichert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const { user } = useAuthContext()
  const schuljahr = schuljahrHeute()
  const [folge, setFolge] = useState<KaSchulArbeit[] | null>(null)
  const [plan, setPlan] = useState<KaPlanThema[]>([])
  const [nr, setNr] = useState('1')
  const [themen, setThemen] = useState<string[]>([])
  const [datum, setDatum] = useState('')
  const [busy, setBusy] = useState(false)

  const laden = useCallback(async () => {
    const [f, p] = await Promise.all([listKaSchulFolge(schuleId, klasse, schuljahr), listKaPlanThemen(schuleId, klasse)])
    const bestaetigt = (f.data ?? []).filter((a) => a.bestaetigt)
    setFolge(bestaetigt)
    setPlan(p.data ?? [])
    setNr(String(Math.max(0, ...bestaetigt.map((a) => a.nr ?? 0)) + 1))
    setThemen([])
    setDatum('')
  }, [schuleId, klasse, schuljahr])

  useEffect(() => {
    void laden()
  }, [laden])

  const nrZahl = Number(nr)
  const gueltig = Number.isInteger(nrZahl) && nrZahl >= 1 && nrZahl <= 8 && themen.length > 0
  const titel = new Map(plan.map((p) => [p.themaKey, p.titel]))
  const fmt = (d: string): string =>
    new Intl.DateTimeFormat(i18n.language, { dateStyle: 'medium', timeZone: 'Europe/Berlin' }).format(new Date(`${d}T12:00:00Z`))

  const speichern = async (): Promise<void> => {
    if (!gueltig || !user) return
    setBusy(true)
    const { error } = await bestaetigeKaSchulArbeit(
      { schuleId, klasse, schuljahr },
      { nr: nrZahl, themaKeys: themen, datum: datum || null },
      user.id,
    )
    setBusy(false)
    onGespeichert(!error)
    if (!error) void laden()
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-col gap-2">
        <h2 className="text-base font-semibold">{t('lsaAbdeckung.folgeTitel', { schule, klasse })}</h2>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('lsaAbdeckung.folgeSatz', { schuljahr })}</p>
      </div>
      {folge === null ? (
        <LoadingPulse type="list" lines={2} />
      ) : folge.length === 0 ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('lsaAbdeckung.folgeLeer')}</p>
      ) : (
        <ul className="flex flex-col gap-2">
          {folge.map((a) => (
            <li key={a.nr ?? a.themaKeys.join()} className="text-sm">
              <span className="font-semibold">{t('lsaAbdeckung.folgeNr', { nr: a.nr })}</span>
              {' · '}
              {a.themaKeys.map((k) => titel.get(k) ?? k).join(', ')}
              {a.datum ? ` · ${fmt(a.datum)}` : ''}
            </li>
          ))}
        </ul>
      )}
      <div className="flex flex-col gap-2">
        <label className="flex flex-col gap-2 text-sm">
          <span className="font-semibold">{t('lsaAbdeckung.folgeFeldNr')}</span>
          <Input type="number" min={1} max={8} value={nr} onChange={(e) => setNr(e.target.value)} className="w-24" />
        </label>
        <span className="text-sm font-semibold">{t('lsaAbdeckung.folgeFeldThemen')}</span>
        <OptionChips
          options={plan.map((p) => ({ value: p.themaKey, label: p.titel }))}
          selected={themen}
          onToggle={(k) => setThemen((x) => (x.includes(k) ? x.filter((y) => y !== k) : [...x, k]))}
        />
        <label className="flex flex-col gap-2 text-sm">
          <span className="font-semibold">{t('lsaAbdeckung.folgeFeldDatum')}</span>
          <Input type="date" value={datum} onChange={(e) => setDatum(e.target.value)} className="w-48" />
        </label>
        <Button
          variant="outline"
          className="self-start"
          disabled={!gueltig || busy}
          title={!gueltig ? t('lsaAbdeckung.folgeUngueltig') : undefined}
          onClick={() => void speichern()}
        >
          {t('lsaAbdeckung.folgeSpeichern')}
        </Button>
      </div>
    </EdvanceCard>
  )
}
