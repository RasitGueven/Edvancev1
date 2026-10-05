// Kleine Karte in der Item-Pflege (Entscheidung 44): Hilfsmittel, "nur Pilot" und "Grund Pflicht"
// fuer Lenas Board. Die Pilotmarke je Aufgabe sitzt unter der Aufgabe (LenaInfo). Nur admin
// (RLS pruef_einstellungen_admin).

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { getPruefEinstellungen, setPruefEinstellungen } from '@/lib/supabase/pruefung'
import type { PruefEinstellungen } from '@/types'

export function PruefEinstellungenKarte({ pilotAnzahl }: { pilotAnzahl: number }): JSX.Element | null {
  const { t } = useTranslation('authoring')
  const [werte, setWerte] = useState<PruefEinstellungen | null>(null)
  const [busy, setBusy] = useState(false)
  const [meldung, setMeldung] = useState<string | null>(null)

  useEffect(() => {
    void getPruefEinstellungen().then((r) => setWerte(r.data))
  }, [])
  if (!werte) return null

  const speichern = async (): Promise<void> => {
    setBusy(true)
    const res = await setPruefEinstellungen(werte)
    setBusy(false)
    setMeldung(res.error ? t('lena.einstellungen.fehler', { fehler: res.error.message }) : t('lena.einstellungen.gespeichert'))
  }

  return (
    <EdvanceCard className="flex flex-col gap-4">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{t('lena.einstellungen.titel')}</h2>
        <span className="text-xs text-[var(--color-text-tertiary)]">{t('lena.einstellungen.pilotAnzahl', { count: pilotAnzahl })}</span>
      </div>
      <label className="flex flex-col gap-2 text-sm text-[var(--color-text-secondary)]">
        {t('lena.einstellungen.hilfsmittel')}
        <input value={werte.hilfsmittel} onChange={(e) => setWerte({ ...werte, hilfsmittel: e.target.value })}
          className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm" />
      </label>
      <div className="flex flex-wrap gap-4 text-sm text-[var(--color-text-secondary)]">
        <label className="flex min-h-[44px] items-center gap-2">
          <input type="checkbox" className="h-4 w-4" checked={werte.nur_pilot} onChange={(e) => setWerte({ ...werte, nur_pilot: e.target.checked })} />
          {t('lena.einstellungen.nurPilot')}
        </label>
        <label className="flex min-h-[44px] items-center gap-2">
          <input type="checkbox" className="h-4 w-4" checked={werte.grund_pflicht} onChange={(e) => setWerte({ ...werte, grund_pflicht: e.target.checked })} />
          {t('lena.einstellungen.grundPflicht')}
        </label>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" loading={busy} onClick={() => void speichern()}>{t('lena.einstellungen.speichern')}</Button>
        {meldung && <span className="text-xs text-[var(--color-text-secondary)]">{meldung}</span>}
      </div>
    </EdvanceCard>
  )
}
