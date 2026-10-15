import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceTable } from '@/components/edvance/EdvanceTable'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { berlinToday } from '@/lib/datetime'
import { ladeEinstellungen, raumAnlegen, raumDeaktivieren, slotZeitAnlegen, slotZeitDeaktivieren, type SlotsResult } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsEinstellungen } from '@/types/slotplan'
import { datumKurz, datumVoll } from '../slotsFormat'
import { useSlotsLaden } from '../useSlotsLaden'

type Raum = SlotsEinstellungen['raeume'][number]
type Offen = { art: 'raumNeu' | 'zeitNeu' } | { art: 'raumAus' | 'zeitAus'; id: string } | null

const FELD = 'h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm tabular-nums'

/** Reiter Einstellungen (Bauauftrag SL2, Umfang 8): Räume, Uhrzeiten, Tage ohne Betrieb. */
export function EinstellungenReiter(): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const einst = useSlotsLaden(() => ladeEinstellungen(), 'einstellungen')
  const heute = berlinToday()
  const [offen, setOffen] = useState<Offen>(null)
  const [wert, setWert] = useState('')
  const [datum, setDatum] = useState(heute)
  const [fehler, setFehler] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const d = einst.daten

  const oeffne = (o: Offen): void => {
    setOffen(o)
    setWert('')
    setDatum(heute)
    setFehler(null)
  }
  const speichern = async (aufruf: Promise<SlotsResult<unknown>>, text: string): Promise<void> => {
    const res = await aufruf
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    setOffen(null)
    setMeldung(text)
    einst.neuLaden()
  }

  if (!d) return einst.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(einst.fehler)}</p> : <LoadingPulse type="list" lines={6} />

  /** Inline-Formular unter einer Karte (Bestätigungen inline, nicht als Dialog). */
  const formular = (feld: JSX.Element, knopf: string, los: () => void, gesperrt: string | null): JSX.Element => (
    <div className="flex flex-wrap items-end gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-4">
      {feld}
      <span className="flex flex-col gap-1">
        <span className="flex gap-2">
          <Button type="button" onClick={los} disabled={!!gesperrt}>{knopf}</Button>
          <Button type="button" variant="ghost" onClick={() => setOffen(null)}>{t('dialog.abbrechen')}</Button>
        </span>
        {gesperrt && <span className="text-xs text-[var(--color-text-tertiary)]">{gesperrt}</span>}
      </span>
      {fehler && <p role="alert" className="w-full text-xs text-[var(--color-error-coach)]">{t(fehler)}</p>}
    </div>
  )
  const datumFeld = (label: string): JSX.Element => (
    <label className="flex flex-col gap-1 text-xs text-[var(--color-text-tertiary)]">
      {label}
      <input type="date" autoFocus min={heute} value={datum} onChange={(e) => setDatum(e.target.value)} className={FELD} />
    </label>
  )

  const tage = [
    ...d.ferien.map((f) => ({ key: `f-${f.von}`, von: f.von, text: `${datumVoll(f.von, i18n.language)} – ${datumVoll(f.bis, i18n.language)}`, name: f.name })),
    ...d.feiertage.map((f) => ({ key: `t-${f.datum}`, von: f.datum, text: datumKurz(f.datum, i18n.language), name: f.name })),
  ].sort((a, b) => a.von.localeCompare(b.von))

  return (
    <div className="flex flex-col gap-6">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <header className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex flex-col">
            <h2 className="text-base font-semibold">{t('einst.raeume.titel')}</h2>
            <p className="text-xs text-[var(--color-text-tertiary)]">{t('einst.raeume.satz')}</p>
          </div>
          <Button type="button" variant="outline" onClick={() => oeffne({ art: 'raumNeu' })}>{t('einst.raeume.neu')}</Button>
        </header>
        {d.raeume.length === 0 ? (
          <EmptyState icon="🚪" title={t('einst.raeume.leerTitel')} description={t('einst.raeume.leerText')}
            action={<Button type="button" onClick={() => oeffne({ art: 'raumNeu' })}>{t('einst.raeume.neu')}</Button>} />
        ) : (
          <EdvanceTable<Raum>
            beschriftung={t('einst.raeume.titel')}
            zeilen={d.raeume}
            zeileKey={(r) => r.id}
            spalten={[
              { key: 'name', kopf: t('einst.raeume.name'), zelle: (r) => <span className="font-semibold">{r.name}</span> },
              { key: 'ab', kopf: t('einst.aktivAb'), zelle: (r) => <span className="tabular-nums">{datumVoll(r.aktiv_ab, i18n.language)}</span> },
              { key: 'bis', kopf: t('einst.inaktivAb'), zelle: (r) => <span className="tabular-nums">{r.inaktiv_ab ? datumVoll(r.inaktiv_ab, i18n.language) : '–'}</span> },
              { key: 'schichten', kopf: t('einst.raeume.schichten'), rechts: true, zelle: (r) => <span className="tabular-nums">{r.stammschichten}</span> },
              {
                key: 'aktion', kopf: '', rechts: true,
                zelle: (r) => (r.inaktiv_ab ? null : (
                  <Button type="button" variant="ghost" size="sm" className="min-h-[44px]" onClick={() => oeffne({ art: 'raumAus', id: r.id })}>
                    {t('einst.deaktivieren')}
                  </Button>
                )),
              },
            ]}
          />
        )}
        {offen?.art === 'raumNeu' && formular(
          <label className="flex flex-col gap-1 text-xs text-[var(--color-text-tertiary)]">
            {t('einst.raeume.name')}
            <Input autoFocus value={wert} onChange={(e) => setWert(e.target.value)} className="min-h-[44px]" />
          </label>,
          t('einst.raeume.anlegen'),
          () => void speichern(raumAnlegen(wert.trim()), t('einst.raeume.angelegt', { name: wert.trim() })),
          wert.trim() ? null : t('einst.raeume.nameFehlt'),
        )}
        {offen?.art === 'raumAus' && formular(
          datumFeld(t('einst.inaktivAb')),
          t('einst.deaktivierenKnopf'),
          () => void speichern(raumDeaktivieren(offen.id, datum), t('einst.raeume.deaktiviert', { datum: datumKurz(datum, i18n.language) })),
          null,
        )}
      </EdvanceCard>

      <EdvanceCard className="flex flex-col gap-4 p-6">
        <header className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex flex-col">
            <h2 className="text-base font-semibold">{t('einst.zeiten.titel')}</h2>
            <p className="text-xs text-[var(--color-text-tertiary)]">{t('einst.zeiten.satz')}</p>
          </div>
          <Button type="button" variant="outline" onClick={() => oeffne({ art: 'zeitNeu' })}>{t('einst.zeiten.neu')}</Button>
        </header>
        <ul className="flex flex-wrap gap-2">
          {d.zeiten.map((z) => (
            <li key={z.id}>
              <button type="button" onClick={() => !z.inaktiv_ab && oeffne({ art: 'zeitAus', id: z.id })}
                aria-label={z.inaktiv_ab ? t('einst.zeiten.inaktivLabel', { beginn: z.beginn, datum: datumKurz(z.inaktiv_ab, i18n.language) }) : t('einst.zeiten.deaktivierenLabel', { beginn: z.beginn })}
                className={`flex min-h-[44px] items-center gap-2 rounded-[var(--radius-full)] border px-4 text-sm tabular-nums ${
                  z.inaktiv_ab ? 'border-[var(--color-border)] text-[var(--color-text-tertiary)] line-through' : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-primary)] hover:border-[var(--color-primary)]'
                }`}>
                {`${z.beginn}–${z.ende}`}
              </button>
            </li>
          ))}
        </ul>
        {offen?.art === 'zeitNeu' && formular(
          <label className="flex flex-col gap-1 text-xs text-[var(--color-text-tertiary)]">
            {t('einst.zeiten.beginn')}
            <input type="time" autoFocus step={3600} value={wert} onChange={(e) => setWert(e.target.value)} className={FELD} />
          </label>,
          t('einst.zeiten.anlegen'),
          () => void speichern(slotZeitAnlegen(wert), t('einst.zeiten.angelegt', { beginn: wert })),
          wert ? null : t('einst.zeiten.beginnFehlt'),
        )}
        {offen?.art === 'zeitAus' && formular(
          datumFeld(t('einst.inaktivAb')),
          t('einst.deaktivierenKnopf'),
          () => void speichern(slotZeitDeaktivieren(offen.id, datum), t('einst.zeiten.deaktiviert', { datum: datumKurz(datum, i18n.language) })),
          null,
        )}
      </EdvanceCard>

      <EdvanceCard className="flex flex-col gap-4 p-6">
        <div className="flex flex-col">
          <h2 className="text-base font-semibold">{t('einst.tage.titel')}</h2>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('einst.tage.satz', { datum: datumVoll(d.schuljahr_bis, i18n.language) })}</p>
        </div>
        <ul className="flex flex-col">
          {tage.map((x) => (
            <li key={x.key} className="flex min-h-[44px] items-center justify-between gap-4 border-t border-[var(--color-border)] text-sm">
              <span className="tabular-nums">{x.text}</span>
              <span className="text-[var(--color-text-secondary)]">{x.name}</span>
            </li>
          ))}
        </ul>
        <p className="text-xs text-[var(--color-text-tertiary)]">{t('einst.tage.vertragsende')}</p>
      </EdvanceCard>

      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </div>
  )
}
