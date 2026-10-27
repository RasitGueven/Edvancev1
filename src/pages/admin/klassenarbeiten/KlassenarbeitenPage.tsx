import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { useAuthContext } from '@/context/AuthContext'
import {
  bestaetigeKaSchulArbeit,
  listKaGruppen,
  listKaPlanThemen,
  listKaSchulFolge,
  schuljahrHeute,
  type KaGruppe,
  type KaPlanThema,
  type KaSchulArbeit,
} from '@/lib/supabase/kaFolge'

import { KaArbeitKarte, type KaKorrektur } from './KaArbeitKarte'

type Meldung = { art: 'success' | 'error'; text: string; id: number }
const schluessel = (g: KaGruppe): string => `${g.schuleId}:${g.klasse}`

/**
 * Klassenarbeiten je Schule und Klasse (L5, Entscheidung 7): links die Klassen mit Angaben, rechts die abgeleiteten
 * Arbeiten des laufenden Schuljahrs mit der Zahl übereinstimmender Kinder; bestätigen bzw. korrigieren. Keine
 * Daten einzelner Kinder, nur die abgeleitete Folge. Nur Admins (Route und Datenbank).
 */
export function KlassenarbeitenPage(): JSX.Element {
  const { t } = useTranslation('admin')
  const { user } = useAuthContext()
  const schuljahr = schuljahrHeute()
  const [gruppen, setGruppen] = useState<KaGruppe[] | null>(null)
  const [gewaehlt, setGewaehlt] = useState<KaGruppe | null>(null)
  const [folge, setFolge] = useState<KaSchulArbeit[] | null>(null)
  const [plan, setPlan] = useState<KaPlanThema[]>([])
  const [busy, setBusy] = useState(false)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  const ladeGruppen = useCallback(async () => {
    const res = await listKaGruppen(schuljahr)
    if (res.error) setMeldung({ art: 'error', text: t('klassenarbeiten.ladeFehler'), id: Date.now() })
    setGruppen(res.data ?? [])
  }, [schuljahr, t])

  const ladeFolge = useCallback(
    async (g: KaGruppe) => {
      setFolge(null)
      const [f, p] = await Promise.all([listKaSchulFolge(g.schuleId, g.klasse, schuljahr), listKaPlanThemen(g.schuleId, g.klasse)])
      if (f.error) setMeldung({ art: 'error', text: t('klassenarbeiten.ladeFehler'), id: Date.now() })
      setFolge(f.data ?? [])
      setPlan(p.data ?? [])
    },
    [schuljahr, t],
  )

  useEffect(() => {
    void ladeGruppen()
  }, [ladeGruppen])
  useEffect(() => {
    if (gewaehlt) void ladeFolge(gewaehlt)
  }, [gewaehlt, ladeFolge])

  const bestaetigen = async (k: KaKorrektur): Promise<void> => {
    if (!gewaehlt || !user) return
    setBusy(true)
    const { error } = await bestaetigeKaSchulArbeit({ ...gewaehlt, schuljahr }, k, user.id)
    setBusy(false)
    setMeldung({ art: error ? 'error' : 'success', text: t(error ? 'klassenarbeiten.speicherFehler' : 'klassenarbeiten.gespeichert'), id: Date.now() })
    if (!error) {
      void ladeFolge(gewaehlt)
      void ladeGruppen()
    }
  }

  const spalten: Spalte<KaGruppe>[] = [
    { key: 'schule', kopf: t('klassenarbeiten.spalte.schule'), zelle: (g) => <span className="font-semibold">{g.schulname}</span> },
    { key: 'klasse', kopf: t('klassenarbeiten.spalte.klasse'), rechts: true, zelle: (g) => g.klasse },
    { key: 'kinder', kopf: t('klassenarbeiten.spalte.kinder'), rechts: true, zelle: (g) => g.kinder },
    { key: 'bestaetigt', kopf: t('klassenarbeiten.spalte.bestaetigt'), rechts: true, zelle: (g) => g.bestaetigte },
  ]

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t('klassenarbeiten.titel')} satz={t('klassenarbeiten.satz', { schuljahr })} />
      {gruppen === null ? (
        <LoadingPulse type="list" lines={4} />
      ) : gruppen.length === 0 ? (
        <EmptyState icon="📝" title={t('klassenarbeiten.leer')} description={t('klassenarbeiten.leerText')} />
      ) : (
        <div className="grid grid-cols-1 items-start gap-6 xl:grid-cols-[minmax(0,1fr)_420px]">
          <EdvanceTable
            beschriftung={t('klassenarbeiten.titel')}
            spalten={spalten}
            zeilen={gruppen}
            zeileKey={schluessel}
            onZeile={setGewaehlt}
            zeileClass={(g) => (gewaehlt && schluessel(g) === schluessel(gewaehlt) ? 'bg-[var(--color-primary-light)]' : '')}
          />
          {!gewaehlt ? (
            <EmptyState icon="👈" title={t('klassenarbeiten.waehlen')} description={t('klassenarbeiten.waehlenText')} />
          ) : folge === null ? (
            <LoadingPulse type="list" lines={3} />
          ) : folge.length === 0 ? (
            <EmptyState icon="🗓️" title={t('klassenarbeiten.keineFolge')} description={t('klassenarbeiten.keineFolgeText')} />
          ) : (
            <div className="flex flex-col gap-4" data-testid="ka-folge">
              {folge.map((a) => (
                <KaArbeitKarte key={`${a.nr ?? 'd'}-${a.datum ?? ''}-${a.themaKeys.join()}`} arbeit={a} plan={plan} busy={busy} onBestaetigen={(k) => void bestaetigen(k)} />
              ))}
            </div>
          )}
        </div>
      )}
      {meldung && <ToastBanner key={meldung.id} type={meldung.art} message={meldung.text} onClose={() => setMeldung(null)} />}
    </div>
  )
}
