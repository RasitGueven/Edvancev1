import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceTable } from '@/components/edvance/EdvanceTable'
import { Input } from '@/components/ui/input'
import { ladeKinder, stammplaetzeWeiterfuehren } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsKinderZeile } from '@/types/slotplan'
import { KINDER_FILTER, anzahlJeFilter, filterAusSuche, kinderGefiltert, kinderSortiert, type KinderFilter } from '../slots.model'
import { useSlotsLaden } from '../useSlotsLaden'
import { StammplatzDialog } from '../dialoge/StammplatzDialog'
import { OhneStammplatzListe } from './OhneStammplatzListe'
import { KindZellen, useKinderSpalten } from './KinderSpalten'

/** Reiter Kinder (Bauauftrag SL2, Umfang 5). */
export function KinderReiter(): JSX.Element {
  const { t } = useTranslation('slots')
  const navigate = useNavigate()
  const [suche, setSuche] = useSearchParams()
  const filter = filterAusSuche(suche)
  const [q, setQ] = useState('')
  const [dialogKind, setDialogKind] = useState<SlotsKinderZeile | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [fehlerBei, setFehlerBei] = useState<{ ort: string; text: string } | null>(null)
  const kinder = useSlotsLaden(() => ladeKinder(), 'kinder')
  const spalten = useKinderSpalten()

  const setFilter = (f: KinderFilter): void => {
    const neu = new URLSearchParams(suche)
    if (f === 'alle') neu.delete('filter')
    else neu.set('filter', f)
    setSuche(neu, { replace: true })
  }
  const fertig = (text: string): void => {
    setDialogKind(null)
    setMeldung(text)
    kinder.neuLaden()
  }
  const weiterfuehren = async (k: SlotsKinderZeile): Promise<void> => {
    setFehlerBei(null)
    const res = await stammplaetzeWeiterfuehren(k.student_id)
    if (res.error !== null) return setFehlerBei({ ort: k.student_id, text: slotsFehlerSchluessel(res) })
    fertig(t('kinder.weitergefuehrt', { name: k.name }))
  }

  if (!kinder.daten) {
    return kinder.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(kinder.fehler)}</p> : <LoadingPulse type="list" lines={6} />
  }

  const alle = kinder.daten
  const liste = kinderGefiltert(alle, filter, q)
  const zahl = anzahlJeFilter(alle)
  const ohne = kinderSortiert(alle).filter((k) => k.ohne_stammplatz)

  const chip = (an: boolean): string =>
    `min-h-[44px] rounded-[var(--radius-full)] px-4 text-sm font-semibold transition-colors duration-150 ease-out ${
      an
        ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
        : 'border border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-primary)]'
    }`

  return (
    <div className="flex flex-col gap-6">
      {alle.length === 0 ? (
        <EdvanceCard>
          <EmptyState icon="🧒" title={t('kinder.leerTitel')} description={t('kinder.leerText')} />
        </EdvanceCard>
      ) : (
        <>
          {ohne.length > 0 && (
            <OhneStammplatzListe kinder={ohne} fehlerBei={fehlerBei} onVergeben={setDialogKind} onWeiterfuehren={(k) => void weiterfuehren(k)} />
          )}

          <section className="flex flex-col gap-4" aria-label={t('kinder.liste')}>
            <div className="flex flex-wrap items-center gap-2">
              <div role="group" aria-label={t('kinder.filterLabel')} className="flex flex-wrap gap-2">
                {KINDER_FILTER.map((f) => (
                  <button key={f} type="button" aria-pressed={filter === f} onClick={() => setFilter(f)} className={chip(filter === f)}>
                    {t(`kinder.filter.${f}`)} <span className="tabular-nums">{zahl[f]}</span>
                  </button>
                ))}
              </div>
              <Input
                type="search"
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder={t('kinder.suche')}
                aria-label={t('kinder.suche')}
                className="min-h-[44px] w-full max-w-xs"
              />
            </div>

            {liste.length === 0 ? (
              <EdvanceCard>
                <EmptyState icon="🔎" title={t('kinder.keinTrefferTitel')} description={t('kinder.keinTrefferText')} />
              </EdvanceCard>
            ) : (
              <div className="@container">
                <div className="hidden @slots-tabelle:block">
                  <EdvanceTable
                    spalten={spalten}
                    zeilen={liste}
                    zeileKey={(k) => k.student_id}
                    onZeile={(k) => navigate(`/admin/slots/kind/${k.student_id}`)}
                    beschriftung={t('kinder.liste')}
                  />
                </div>
                <ul className="flex flex-col gap-4 @slots-tabelle:hidden">
                  {liste.map((k) => (
                    <li key={k.student_id}>
                      <Link to={`/admin/slots/kind/${k.student_id}`} className="block rounded-[var(--radius-lg)]">
                        <EdvanceCard className="flex flex-col gap-2 p-4 hover:shadow-elevation-md">
                          <KindZellen kind={k} />
                        </EdvanceCard>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </section>
        </>
      )}

      {dialogKind && (
        <StammplatzDialog
          kind={{
            student_id: dialogKind.student_id, name: dialogKind.name, beginn: dialogKind.beginn,
            vertrag_laeuft: dialogKind.vertrag_laeuft, rhythmus: dialogKind.rhythmus,
          }}
          onClose={() => setDialogKind(null)}
          onGespeichert={fertig}
        />
      )}
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </div>
  )
}
