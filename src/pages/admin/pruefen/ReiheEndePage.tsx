// /admin/pruefen/ende — Ende der Reihe (Bauauftrag C 15): freigegeben, an Lena, zurueckgewiesen, uebersprungen.
// Darunter „Übersprungene prüfen“ (wenn es welche gibt) und „Zurück zur ⟨Herkunft⟩“.

import { useState, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, StatCard } from '@/components/edvance'
import { Button } from '@/components/ui'
import { leseReihe, OHNE_REIHE_ZURUECK, reiheDerUebersprungenen, reiheStarten, type ReiheArt } from '@/lib/pruefung/reihe'

const ZAHLEN: [ReiheArt, string][] = [['freigegeben', '✓'], ['anLena', '↩'], ['zurueckgewiesen', '✕'], ['uebersprungen', '⏭']]

export function ReiheEndePage(): JSX.Element {
  const { t } = useTranslation('pruefenAdmin')
  const navigate = useNavigate()
  const [reihe] = useState(() => leseReihe())

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-10">
        {!reihe ? (
          <EmptyState icon="✅" title={t('ende.titel')} description={t('ende.keineReihe')}
            action={<Button onClick={() => navigate(OHNE_REIHE_ZURUECK)}>{t('ansicht.zurListe')}</Button>} />
        ) : (
          <EdvanceCard className="flex flex-col gap-6 animate-scale-in">
            <div className="flex flex-col gap-2">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{reihe.label}</p>
              <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">{t('ende.titel')}</h1>
            </div>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              {ZAHLEN.map(([k, icon]) => <StatCard key={k} icon={icon} label={t(`ende.${k}`)} value={reihe.ergebnis[k].length} />)}
            </div>
            <div className="flex flex-wrap gap-2">
              {reihe.ergebnis.uebersprungen.length > 0 && (
                <Button onClick={() => navigate(reiheStarten(reiheDerUebersprungenen(reihe)))}>{t('ende.uebersprungenePruefen')}</Button>
              )}
              <Button variant={reihe.ergebnis.uebersprungen.length > 0 ? 'outline' : 'primary'} onClick={() => navigate(reihe.zurueck)}>
                {t(`ende.zurueck.${reihe.herkunft}`)}
              </Button>
            </div>
          </EdvanceCard>
        )}
      </main>
    </div>
  )
}
