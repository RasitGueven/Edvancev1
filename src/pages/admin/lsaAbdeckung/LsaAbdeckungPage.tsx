import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EmptyState, LoadingPulse, StatCard, ToastBanner } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { frischeLsaAbdeckung, getFokusQuartal, getLsaAbdeckung, setSchuleFokus } from '@/lib/supabase/lsaAbdeckung'
import type { LsaAbdeckungZeile } from '@/types'

import { OptionChips } from '../intake/OptionChips'
import { kennzahlen, paketKey } from './abdeckung'
import { AbdeckungMatrix } from './AbdeckungMatrix'
import { FolgePflege } from './FolgePflege'
import { FreigabeLeiste } from './FreigabeLeiste'
import { PaketDetail } from './PaketDetail'

type Meldung = { art: 'success' | 'error'; text: string; id: number }
const KLASSEN = [8, 9, 10] as const
const QUARTALE = [1, 2, 3, 4] as const

/**
 * LSA-Abdeckung (FR-2 F2): Ampel je Schule und Klassenarbeit (lsa_abdeckung), Filter Klasse, Quartal (Standard:
 * Stellschraube lsa_fokus_quartal) und Fokus, Paket-Detail, Fokus je Schule, Folge der Klassenarbeiten für
 * Fokus-Schulen, Sammelfreigabe. Nur Admins (Route); die Datenbank prüft darf_pruefen bzw. Admin.
 */
export function LsaAbdeckungPage(): JSX.Element {
  const { t } = useTranslation('admin')
  const [klasse, setKlasse] = useState<number>(10)
  const [quartal, setQuartal] = useState<number | null>(null)
  const [nurFokus, setNurFokus] = useState(false)
  const [zeilen, setZeilen] = useState<LsaAbdeckungZeile[] | null>(null)
  const [fehler, setFehler] = useState(false)
  const [gewaehlt, setGewaehlt] = useState<LsaAbdeckungZeile | null>(null)
  const [busyFokus, setBusyFokus] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  useEffect(() => {
    void getFokusQuartal().then(setQuartal)
  }, [])

  const laden = useCallback(async () => {
    if (quartal === null) return
    await frischeLsaAbdeckung()
    const r = await getLsaAbdeckung({ klasse, quartal: quartal === 0 ? null : quartal, nurFokus })
    setFehler(r.error !== null)
    setZeilen(r.data ?? [])
  }, [klasse, quartal, nurFokus])

  useEffect(() => {
    setZeilen(null)
    setGewaehlt(null)
    void laden()
  }, [laden])

  const fokus = async (schuleId: string, an: boolean): Promise<void> => {
    setBusyFokus(schuleId)
    const r = await setSchuleFokus(schuleId, an)
    setBusyFokus(null)
    if (r.error) setMeldung({ art: 'error', text: t('lsaAbdeckung.fokusFehler'), id: Date.now() })
    else void laden()
  }

  const k = zeilen ? kennzahlen(zeilen) : null
  const fokusSchule = gewaehlt?.fokus ? gewaehlt : null

  return (
    <div className="flex flex-col gap-6">
      <PageHeader rubrik={t('nav.gruppe.inhalte')} titel={t('lsaAbdeckung.titel')} satz={t('lsaAbdeckung.satz')} />
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('lsaAbdeckung.filterKlasse')}</span>
          <OptionChips options={KLASSEN.map((x) => ({ value: x, label: t('lsaAbdeckung.klasse', { klasse: x }) }))}
            selected={[klasse]} onToggle={setKlasse} />
        </div>
        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('lsaAbdeckung.filterQuartal')}</span>
          <OptionChips
            options={[...QUARTALE.map((q) => ({ value: q as number, label: t(`lsaAbdeckung.quartal.${q}`) })), { value: 0, label: t('lsaAbdeckung.quartal.alle') }]}
            selected={quartal === null ? [] : [quartal]} onToggle={setQuartal} />
        </div>
        <div className="flex flex-col gap-2">
          <OptionChips options={[{ value: 'fokus', label: t('lsaAbdeckung.nurFokus') }]} selected={nurFokus ? ['fokus'] : []}
            onToggle={() => setNurFokus((x) => !x)} />
        </div>
      </div>
      {k && (
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4" data-testid="kennzahlen">
          <StatCard value={k.gruen} label={t('lsaAbdeckung.kpi.gruen')} icon="🟢" color="var(--color-success)" />
          <StatCard value={k.gelb} label={t('lsaAbdeckung.kpi.gelb')} icon="🟡" color="var(--color-warning)" />
          <StatCard value={k.rot} label={t('lsaAbdeckung.kpi.rot')} icon="🔴" color="var(--color-error-coach)" />
          <StatCard value={t('lsaAbdeckung.kpi.schulenWert', { bereit: k.schulenBereit, alle: k.schulen })}
            label={t('lsaAbdeckung.kpi.schulen')} icon="🏫" color="var(--color-primary)" />
        </div>
      )}
      <FreigabeLeiste onFertig={(e) => { setMeldung({ ...e, id: Date.now() }); void laden() }} />
      {zeilen === null && !fehler && <LoadingPulse type="list" lines={6} />}
      {fehler && <EmptyState icon="⚠️" title={t('lsaAbdeckung.ladeFehler')} description={t('lsaAbdeckung.ladeFehlerText')} />}
      {zeilen !== null && !fehler && zeilen.length === 0 && (
        <EmptyState icon="🗓️" title={t('lsaAbdeckung.leer')} description={t('lsaAbdeckung.leerText')} />
      )}
      {zeilen !== null && zeilen.length > 0 && (
        <div className="grid grid-cols-1 items-start gap-6 2xl:grid-cols-[minmax(0,1fr)_420px]">
          <AbdeckungMatrix zeilen={zeilen} gewaehlt={gewaehlt ? paketKey(gewaehlt) : null} busyFokus={busyFokus}
            onZelle={setGewaehlt} onFokus={(id, an) => void fokus(id, an)} />
          <div className="flex flex-col gap-4">
            {gewaehlt ? (
              <div data-testid="paket-detail"><PaketDetail paket={gewaehlt} /></div>
            ) : (
              <EmptyState icon="👈" title={t('lsaAbdeckung.waehlen')} description={t('lsaAbdeckung.waehlenText')} />
            )}
            {fokusSchule && (
              <FolgePflege schuleId={fokusSchule.schule_id} schule={fokusSchule.schule} klasse={fokusSchule.klasse}
                onGespeichert={(ok) => {
                  setMeldung({ art: ok ? 'success' : 'error', text: t(ok ? 'lsaAbdeckung.folgeGespeichert' : 'lsaAbdeckung.folgeFehler'), id: Date.now() })
                  if (ok) void laden()
                }} />
            )}
          </div>
        </div>
      )}
      {meldung && <ToastBanner key={meldung.id} type={meldung.art} message={meldung.text} onClose={() => setMeldung(null)} />}
    </div>
  )
}
