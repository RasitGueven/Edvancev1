import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceTable } from '@/components/edvance/EdvanceTable'
import { Input } from '@/components/ui/input'
import { ladeEinstellungen, ladeKinder, stammplaetzeWeiterfuehren } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsKinderZeile, Stammplatz } from '@/types/slotplan'
import { useSlotsLaden } from '../useSlotsLaden'
import { StammplatzDialog } from '../dialoge/StammplatzDialog'
import type { Zeile } from '../dialoge/StammplatzDialog'
import { KindZellen, useKinderSpalten, type KindAktion, type RaumNamen } from './KinderSpalten'
import { filter2AusSuche, kinder2Anzahl, kinder2Gefiltert, testkontenAusSuche, type Kinder2Filter } from './kinder.model'

/** Reiter Kinder (Bauauftrag W3, Entscheidungen 1 und 2): Raum und Coach je Stammplatz, Filter, Aktion je Zeile. */
export function KinderReiter(): JSX.Element {
  const { t } = useTranslation('slots')
  const [suche, setSuche] = useSearchParams()
  const filter = filter2AusSuche(suche)
  const testkonten = testkontenAusSuche(suche)
  const [q, setQ] = useState('')
  const [dialog, setDialog] = useState<{ kind: SlotsKinderZeile; aendern?: Stammplatz; vorbelegt?: Zeile[] } | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [fehlerBei, setFehlerBei] = useState<{ ort: string; text: string } | null>(null)
  const kinder = useSlotsLaden(() => ladeKinder(), 'kinder')
  // Raumnamen nur, wenn ein Vorschlag „wie bisher“ Räume nennt (Knopftext „Mo 14:00 · A1“).
  const mitRaum = (kinder.daten ?? []).some((k) => k.weiterfuehren?.zeilen.some((z) => z.raum_id !== null))
  const einst = useSlotsLaden(
    () => (mitRaum ? ladeEinstellungen() : Promise.resolve({ data: null, error: null })),
    mitRaum ? 'raeume' : 'ohne',
  )
  const raumNamen: RaumNamen = Object.fromEntries((einst.daten?.raeume ?? []).map((r) => [r.id, r.name]))

  const setzeSuche = (schluessel: string, wert: string | null): void => {
    const neu = new URLSearchParams(suche)
    if (wert === null) neu.delete(schluessel)
    else neu.set(schluessel, wert)
    setSuche(neu, { replace: true })
  }
  const fertig = (text: string): void => {
    setDialog(null)
    setMeldung(text)
    kinder.neuLaden()
  }
  const weiterfuehren = async (k: SlotsKinderZeile): Promise<void> => {
    setFehlerBei(null)
    const res = await stammplaetzeWeiterfuehren(k.student_id)
    if (res.error !== null) return setFehlerBei({ ort: k.student_id, text: slotsFehlerSchluessel(res) })
    fertig(t('kinder.weitergefuehrt', { name: k.name }))
  }
  const onAktion = (a: KindAktion): void => {
    if (a.art === 'weiterfuehren') void weiterfuehren(a.kind)
    else if (a.art === 'aendern') setDialog({ kind: a.kind, aendern: a.stammplatz })
    else setDialog({ kind: a.kind, vorbelegt: a.vorbelegt })
  }
  const spalten = useKinderSpalten(onAktion, raumNamen)

  if (!kinder.daten) {
    return kinder.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(kinder.fehler)}</p> : <LoadingPulse type="list" lines={6} />
  }

  const alle = kinder.daten
  const liste = kinder2Gefiltert(alle, { filter, testkonten, suche: q })
  const zahl = kinder2Anzahl(alle, testkonten)

  const chip = (an: boolean): string =>
    `min-h-[44px] rounded-[var(--radius-full)] px-4 text-sm font-semibold transition-colors duration-150 ease-out ${
      an
        ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
        : 'border border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-primary)]'
    }`
  const filterKnopf = (f: Kinder2Filter): JSX.Element => (
    <button key={f} type="button" aria-pressed={filter === f} onClick={() => setzeSuche('filter', f === 'alle' ? null : 'ohne')} className={chip(filter === f)}>
      {t(`kinder2.filter.${f}`)} <span className="tabular-nums">{zahl[f]}</span>
    </button>
  )
  const fehlerZeile = fehlerBei && alle.find((k) => k.student_id === fehlerBei.ort)

  return (
    <div className="flex flex-col gap-6">
      {alle.length === 0 ? (
        <EdvanceCard>
          <EmptyState icon="🧒" title={t('kinder.leerTitel')} description={t('kinder.leerText')} />
        </EdvanceCard>
      ) : (
        <section className="flex flex-col gap-4" aria-label={t('kinder.liste')}>
          <div className="flex flex-wrap items-center gap-2">
            <Input
              type="search"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder={t('kinder.suche')}
              aria-label={t('kinder.suche')}
              className="min-h-[44px] w-full max-w-xs"
            />
            <div role="group" aria-label={t('kinder2.filter.label')} className="flex flex-wrap gap-2">
              {filterKnopf('alle')}
              {filterKnopf('ohne')}
              <button type="button" aria-pressed={testkonten} onClick={() => setzeSuche('test', testkonten ? 'aus' : null)} className={chip(testkonten)}>
                {t('kinder2.filter.test')} <span className="tabular-nums">{zahl.test}</span>
              </button>
            </div>
          </div>

          {fehlerZeile && fehlerBei && (
            <p role="alert" className="text-sm text-[var(--color-error-coach)]">
              {t('kinder2.fehlerBei', { name: fehlerZeile.name ?? t('kind.ohneName'), fehler: t(fehlerBei.text) })}
            </p>
          )}

          {liste.length === 0 ? (
            <EdvanceCard>
              <EmptyState icon="🔎" title={t('kinder.keinTrefferTitel')} description={t('kinder2.keinTrefferText')} />
            </EdvanceCard>
          ) : (
            <div className="@container">
              <div className="hidden @slots-tabelle:block">
                <EdvanceTable spalten={spalten} zeilen={liste} zeileKey={(k) => k.student_id} beschriftung={t('kinder.liste')} />
              </div>
              <ul className="flex flex-col gap-4 @slots-tabelle:hidden">
                {liste.map((k) => (
                  <li key={k.student_id}>
                    <EdvanceCard className="flex flex-col gap-2 p-4">
                      <KindZellen kind={k} raumNamen={raumNamen} onAktion={onAktion} />
                    </EdvanceCard>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </section>
      )}

      {dialog && (
        <StammplatzDialog
          kind={{
            student_id: dialog.kind.student_id, name: dialog.kind.name, beginn: dialog.kind.beginn,
            vertrag_laeuft: dialog.kind.vertrag_laeuft, rhythmus: dialog.kind.rhythmus,
          }}
          aendern={dialog.aendern}
          vorbelegt={dialog.vorbelegt}
          onClose={() => setDialog(null)}
          onGespeichert={fertig}
        />
      )}
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </div>
  )
}
