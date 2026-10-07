import { useCallback, useEffect, useState } from 'react'
import { Info } from 'lucide-react'
import { EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { listStellschrauben } from '@/lib/supabase/sessionEinstellungen'
import type { Stellschraube } from '@/types/sessionLive'
import { StellschraubeBearbeiten } from './StellschraubeBearbeiten'
import { useStellschraubenTexte } from './useStellschraubenTexte'

type Meldung = { art: 'success' | 'error'; text: string; id: number }

/**
 * Stellschrauben der Session (Entscheidung 22, Paket C2): alle pädagogischen Werte mit
 * Beschreibung, Wert, Startwert, Spanne und Einheit. Ändern nur mit Grund (einstellung_setzen),
 * Verlauf je Schlüssel aus dem Protokoll. Nur Admins (Route und Datenbank).
 */
export function StellschraubenPage(): JSX.Element {
  const tx = useStellschraubenTexte()
  const { t } = tx
  const [liste, setListe] = useState<Stellschraube[] | null>(null)
  const [fehler, setFehler] = useState(false)
  const [gewaehlt, setGewaehlt] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  const laden = useCallback(async () => {
    const res = await listStellschrauben()
    setFehler(res.error !== null)
    setListe(res.data ?? [])
  }, [])

  useEffect(() => {
    void laden()
  }, [laden])

  const spalten: Spalte<Stellschraube>[] = [
    {
      key: 'name',
      kopf: t('stellschrauben.spalte.name'),
      zelle: (s) => (
        <span className="flex flex-col">
          <span className="font-semibold">{s.beschreibung}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{s.schluessel}</span>
        </span>
      ),
    },
    { key: 'wert', kopf: t('stellschrauben.spalte.wert'), rechts: true, zelle: (s) => <b className="tabular-nums">{tx.wert(s, s.wert)}</b> },
    { key: 'start', kopf: t('stellschrauben.spalte.start'), rechts: true, zelle: (s) => <span className="tabular-nums">{tx.wert(s, s.startwert)}</span> },
    { key: 'spanne', kopf: t('stellschrauben.spalte.spanne'), zelle: (s) => tx.spanne(s) },
    { key: 'einheit', kopf: t('stellschrauben.spalte.einheit'), zelle: (s) => (s.einheit ? t(`stellschrauben.einheitName.${s.einheit}`) : '–') },
    { key: 'geaendert', kopf: t('stellschrauben.spalte.geaendert'), zelle: (s) => (s.geaendert_am ? tx.datumZeit(s.geaendert_am) : '–') },
  ]

  const auswahl = liste?.find((s) => s.schluessel === gewaehlt) ?? null

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t('stellschrauben.titel')} satz={t('stellschrauben.satz')} />
      <EdvanceCard variant="subtle" className="flex items-start gap-2 p-4 text-sm leading-relaxed text-[var(--color-text-secondary)]">
        <Info className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-primary)]" aria-hidden />
        {t('stellschrauben.hinweisSnapshot')}
      </EdvanceCard>
      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{t('stellschrauben.ladeFehler')}</p>}
      {liste === null ? (
        <LoadingPulse type="list" lines={6} />
      ) : liste.length === 0 ? (
        <EmptyState icon="🎚️" title={t('stellschrauben.leer')} description={t('stellschrauben.leerText')} />
      ) : (
        <div className="grid grid-cols-1 items-start gap-6 xl:grid-cols-[minmax(0,1fr)_380px]">
          <EdvanceTable
            beschriftung={t('stellschrauben.titel')}
            spalten={spalten}
            zeilen={liste}
            zeileKey={(s) => s.schluessel}
            onZeile={(s) => setGewaehlt(s.schluessel)}
            zeileClass={(s) => (s.schluessel === gewaehlt ? 'bg-[var(--color-primary-light)]' : '')}
          />
          {auswahl ? (
            <StellschraubeBearbeiten
              key={auswahl.schluessel}
              s={auswahl}
              onFehler={(text) => setMeldung({ art: 'error', text, id: Date.now() })}
              onGespeichert={(text) => {
                setMeldung({ art: 'success', text, id: Date.now() })
                void laden()
              }}
            />
          ) : (
            <EmptyState icon="👈" title={t('stellschrauben.waehlen')} description={t('stellschrauben.waehlenText')} />
          )}
        </div>
      )}
      {meldung && <ToastBanner key={meldung.id} type={meldung.art} message={meldung.text} onClose={() => setMeldung(null)} />}
    </div>
  )
}
