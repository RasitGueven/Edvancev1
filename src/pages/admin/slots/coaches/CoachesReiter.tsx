import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse, ToastBanner, WochenNavigation } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import { stammschichtAnlegen, stammschichtBeenden } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsCoaches, Stammschicht } from '@/types/slotplan'
import type { Geladen } from '../useSlotsLaden'
import { datumKurz, wochentagName } from '../slotsFormat'

type Auswahl = { art: 'neu'; wochentag: number; zeitId: string; raumId: string } | { art: 'weg'; schicht: Stammschicht } | null

/** Reiter Coaches (Bauauftrag SL2, Umfang 7). */
export function CoachesReiter({ coaches, montag, onWoche }: { coaches: Geladen<SlotsCoaches>; montag: string; onWoche: (m: string) => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [gewaehltId, setGewaehltId] = useState<string | null>(null)
  const [auswahl, setAuswahl] = useState<Auswahl>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const d = coaches.daten

  if (!d) return coaches.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(coaches.fehler)}</p> : <LoadingPulse type="list" lines={5} />
  if (d.coaches.length === 0) {
    return <EdvanceCard><EmptyState icon="🧑‍🏫" title={t('coaches.leerTitel')} description={t('coaches.leerText')} /></EdvanceCard>
  }
  const coach = d.coaches.find((c) => c.id === gewaehltId) ?? d.coaches[0]
  const schichtBei = (w: number, z: string): Stammschicht | undefined => coach.stammschichten.find((s) => s.wochentag === w && s.zeit_id === z)
  const zeitName = (z: string): string => d.zeiten.find((x) => x.id === z)?.beginn ?? ''

  const speichern = async (): Promise<void> => {
    if (!auswahl) return
    setFehler(null)
    const res = auswahl.art === 'neu'
      ? await stammschichtAnlegen(coach.id, auswahl.wochentag, auswahl.zeitId, auswahl.raumId)
      : await stammschichtBeenden(auswahl.schicht.id, berlinToday())
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    setMeldung(t(auswahl.art === 'neu' ? 'coaches.angelegt' : 'coaches.entfernt', { coach: coach.name }))
    setAuswahl(null)
    coaches.neuLaden()
  }

  return (
    <div className="@container">
      <div className="grid grid-cols-1 items-start gap-6 @slots-coaches:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
        <EdvanceCard className="flex flex-col p-2">
          <ul aria-label={t('coaches.liste')} className="flex flex-col">
            {d.coaches.map((c) => {
              const an = c.id === coach.id
              const tage = [...new Set(c.stammschichten.map((s) => s.wochentag))].sort()
              return (
                <li key={c.id}>
                  <button type="button" aria-pressed={an} onClick={() => { setGewaehltId(c.id); setAuswahl(null); setFehler(null) }}
                    className={`flex min-h-[56px] w-full flex-col gap-1 rounded-[var(--radius-md)] px-4 py-2 text-left transition-colors duration-150 ease-out ${
                      an ? 'bg-[var(--color-primary-light)]' : 'hover:bg-[var(--color-bg-subtle)]'
                    }`}>
                    <span className="flex items-center justify-between gap-2">
                      <span className="truncate text-sm font-semibold">{c.name}</span>
                      {c.abweichungen.length > 0 && <EdvanceBadge variant="warning">{t('coaches.abweichungenAnzahl', { count: c.abweichungen.length })}</EdvanceBadge>}
                    </span>
                    <span className="flex flex-wrap items-center gap-1 text-xs text-[var(--color-text-tertiary)]">
                      <span className="tabular-nums">{t('coaches.stunden', { count: c.stunden_pro_woche })}</span>
                      {tage.map((w) => (
                        <span key={w} className="rounded-[var(--radius-full)] border border-[var(--color-border)] px-2">{wochentagName(w, i18n.language)}</span>
                      ))}
                    </span>
                  </button>
                </li>
              )
            })}
          </ul>
        </EdvanceCard>

        <div className="flex min-w-0 flex-col gap-4">
          <EdvanceCard className="flex flex-col gap-4 p-4">
            <h2 className="text-base font-semibold">{t('coaches.raster', { coach: coach.name })}</h2>
            <div role="grid" aria-label={t('coaches.raster', { coach: coach.name })} className="grid grid-cols-[3.5rem_repeat(5,minmax(0,1fr))] gap-1">
              <span />
              {[1, 2, 3, 4, 5].map((w) => (
                <span key={w} role="columnheader" className="px-1 text-xs font-semibold text-[var(--color-text-tertiary)]">{wochentagName(w, i18n.language)}</span>
              ))}
              {d.zeiten.map((z) => (
                <div key={z.id} role="row" className="contents">
                  <span role="rowheader" className="flex min-h-[44px] items-center px-1 text-xs font-semibold tabular-nums text-[var(--color-text-secondary)]">{z.beginn}</span>
                  {[1, 2, 3, 4, 5].map((w) => {
                    const s = schichtBei(w, z.id)
                    const offen = auswahl?.art === 'neu' && auswahl.wochentag === w && auswahl.zeitId === z.id
                    return (
                      <span key={w} role="gridcell">
                        {s ? (
                          <button type="button" onClick={() => { setFehler(null); setAuswahl({ art: 'weg', schicht: s }) }}
                            aria-label={t('coaches.schichtLabel', { tag: wochentagName(w, i18n.language, true), beginn: z.beginn, raum: s.raum_name })}
                            className="flex min-h-[44px] w-full items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-primary)] px-1 text-xs font-semibold text-[var(--color-text-inverse)]">
                            <span className="truncate">{s.raum_name}</span>
                          </button>
                        ) : (
                          <button type="button" onClick={() => { setFehler(null); setAuswahl({ art: 'neu', wochentag: w, zeitId: z.id, raumId: d.raeume[0]?.id ?? '' }) }}
                            aria-label={t('coaches.neuLabel', { tag: wochentagName(w, i18n.language, true), beginn: z.beginn })}
                            className={`flex min-h-[44px] w-full items-center justify-center rounded-[var(--radius-md)] border border-dashed text-sm transition-colors duration-150 ease-out ${
                              offen ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]' : 'border-[var(--color-border)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-subtle)]'
                            }`}>
                            <span aria-hidden="true">+</span>
                          </button>
                        )}
                      </span>
                    )
                  })}
                </div>
              ))}
            </div>

            {auswahl && (
              <div className="flex flex-wrap items-end gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-4" aria-live="polite">
                {auswahl.art === 'neu' ? (
                  <>
                    <label className="flex flex-col gap-1 text-xs text-[var(--color-text-tertiary)]">
                      {t('coaches.neuFrage', { tag: wochentagName(auswahl.wochentag, i18n.language, true), beginn: zeitName(auswahl.zeitId) })}
                      <select autoFocus className={SELECT_MD} value={auswahl.raumId} onChange={(e) => setAuswahl({ ...auswahl, raumId: e.target.value })}>
                        {d.raeume.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
                      </select>
                    </label>
                    <Button type="button" onClick={() => void speichern()} disabled={!auswahl.raumId}>{t('coaches.anlegen')}</Button>
                  </>
                ) : (
                  <>
                    <p className="text-sm text-[var(--color-text-primary)]">
                      {t('coaches.wegFrage', { tag: wochentagName(auswahl.schicht.wochentag, i18n.language, true), beginn: auswahl.schicht.beginn, raum: auswahl.schicht.raum_name })}
                    </p>
                    <Button type="button" variant="destructive" autoFocus onClick={() => void speichern()}>{t('coaches.entfernen')}</Button>
                  </>
                )}
                <Button type="button" variant="ghost" onClick={() => { setAuswahl(null); setFehler(null) }}>{t('dialog.abbrechen')}</Button>
                {d.raeume.length === 0 && auswahl.art === 'neu' && <p className="w-full text-xs text-[var(--color-text-secondary)]">{t('coaches.keineRaeume')}</p>}
                {fehler && <p role="alert" className="w-full text-xs text-[var(--color-error-coach)]">{t(fehler)}</p>}
              </div>
            )}
            <p className="text-xs text-[var(--color-text-tertiary)]">{t('coaches.hinweis')}</p>
          </EdvanceCard>

          <EdvanceCard className="flex flex-col gap-2 p-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h2 className="text-base font-semibold">{t('coaches.abweichungen')}</h2>
              <WochenNavigation montag={montag} onWechsel={onWoche} pfeiltasten={false} />
            </div>
            {coach.abweichungen.length === 0 ? (
              <p className="text-sm text-[var(--color-text-tertiary)]">{t('coaches.keineAbweichungen')}</p>
            ) : (
              <ul className="flex flex-col">
                {coach.abweichungen.map((a) => (
                  <li key={`${a.datum}-${a.zeit_id}-${a.raum_id}`} className="border-t border-[var(--color-border)]">
                    <Link to={`/admin/slots/termin/${a.datum}/${a.zeit_id}`} className="flex min-h-[44px] items-center justify-between gap-2 text-sm hover:bg-[var(--color-bg-subtle)]">
                      <span className="tabular-nums">{`${datumKurz(a.datum, i18n.language)} ${a.beginn} · ${a.raum_name}`}</span>
                      <EdvanceBadge variant={a.art === 'faellt_aus' ? 'coach-emergency' : 'warning'}>{t(`raumArt.${a.art}`)}</EdvanceBadge>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </EdvanceCard>
        </div>
      </div>
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </div>
  )
}
