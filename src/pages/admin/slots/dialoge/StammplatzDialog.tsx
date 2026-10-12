import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import { ladeFrei, ladePlanbilanzVorschau, stammplatzAendern, stammplatzVergeben } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { wocheVerschieben, dieseWoche } from '@/components/edvance/wochenNavigation.model'
import type { PlanbilanzVorschau, Rhythmus, SlotsFrei, Stammplatz, StammplatzZeile, Takt } from '@/types/slotplan'
import { datumKurz, wochentagName } from '../slotsFormat'
import { PlanbilanzBadge, planbilanzSatz } from '../kinder/Einheiten'
import { FreiRaster } from './FreiRaster'

export type StammplatzKind = { student_id: string; name: string | null; beginn: string; vertrag_laeuft: boolean; rhythmus: Rhythmus | null }
export type Zeile = { wochentag: number | null; zeit_id: string | null; takt: Takt }

const TAKTE: Takt[] = ['woechentlich', 'a_woche', 'b_woche']

/** Zeilen nach dem Rhythmus (Anforderung E 26): wöchentliche zuerst, dann 14-tägliche (A-Woche). */
export function zeilenNachRhythmus(r: Rhythmus | null): Zeile[] {
  const w = r?.woechentlich ?? 1
  const v = r?.vierzehntaeglich ?? 0
  const z: Zeile[] = [
    ...Array.from({ length: w }, () => ({ wochentag: null, zeit_id: null, takt: 'woechentlich' as Takt })),
    ...Array.from({ length: v }, () => ({ wochentag: null, zeit_id: null, takt: 'a_woche' as Takt })),
  ]
  return z.length > 0 ? z : [{ wochentag: null, zeit_id: null, takt: 'woechentlich' }]
}

const vollstaendig = (z: Zeile): z is Zeile & { wochentag: number; zeit_id: string } => z.wochentag !== null && z.zeit_id !== null

/** Stammplatz vergeben oder ab einem Datum ändern (Anforderung E 28–31). */
export function StammplatzDialog({
  kind,
  aendern,
  onClose,
  onGespeichert,
}: {
  kind: StammplatzKind
  /** Gesetzt: diesen Stammplatz ab "gültig ab" ändern. */
  aendern?: Stammplatz
  onClose: () => void
  onGespeichert: (meldung: string) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const heute = berlinToday()
  const [zeilen, setZeilen] = useState<Zeile[]>(() =>
    aendern ? [{ wochentag: aendern.wochentag, zeit_id: aendern.zeit_id, takt: aendern.takt }] : zeilenNachRhythmus(kind.rhythmus),
  )
  const [aktiv, setAktiv] = useState(0)
  const [ab, setAb] = useState(aendern ? wocheVerschieben(dieseWoche(), 1) : kind.beginn > heute ? kind.beginn : heute)
  const [frei, setFrei] = useState<SlotsFrei | null>(null)
  const [vorschau, setVorschau] = useState<PlanbilanzVorschau | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)
  const takt = zeilen[aktiv]?.takt ?? 'woechentlich'
  const fertigeZeilen = useMemo<StammplatzZeile[]>(
    () => zeilen.filter(vollstaendig).map(({ wochentag, zeit_id, takt: k }) => ({ wochentag, slot_zeit_id: zeit_id, takt: k })),
    [zeilen],
  )

  useEffect(() => {
    let aktivLauf = true
    void ladeFrei(takt, ab, kind.student_id).then((res) => aktivLauf && setFrei(res.data))
    return () => {
      aktivLauf = false
    }
  }, [takt, ab, kind.student_id])

  useEffect(() => {
    let aktivLauf = true
    if (fertigeZeilen.length === 0) {
      setVorschau(null)
      return undefined
    }
    void ladePlanbilanzVorschau(kind.student_id, fertigeZeilen, ab, aendern ? [aendern.id] : null).then((res) => {
      if (!aktivLauf) return
      setVorschau(res.data)
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
    })
    return () => {
      aktivLauf = false
    }
  }, [fertigeZeilen, ab, kind.student_id, aendern])

  const setze = (i: number, teil: Partial<Zeile>): void => setZeilen((zs) => zs.map((z, j) => (j === i ? { ...z, ...teil } : z)))
  const zeitName = (id: string | null): string => frei?.zeiten.find((z) => z.id === id)?.beginn ?? ''

  const gruende = [
    ...zeilen.flatMap((z, i) => (vollstaendig(z) ? [] : [t('dialog.stamm.zeileWaehlen', { zeile: i + 1 })])),
    ...(vorschau?.gruende ?? []).map((g) =>
      g.zeile === null ? t(`fehler.${g.code}`) : t('dialog.stamm.zeileGrund', { zeile: g.zeile + 1, grund: t(`fehler.${g.code}`) }),
    ),
  ]

  const speichern = async (): Promise<void> => {
    setSpeichert(true)
    setFehler(null)
    const res = aendern
      ? await stammplatzAendern(aendern.id, ab, fertigeZeilen[0])
      : await stammplatzVergeben(kind.student_id, fertigeZeilen, ab)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(t(aendern ? 'dialog.stamm.geaendert' : 'dialog.stamm.vergeben', { name: kind.name, ab: datumKurz(ab, i18n.language) }))
  }

  return (
    <Modal
      open
      size="xl"
      onClose={onClose}
      title={t(aendern ? 'dialog.stamm.titelAendern' : 'dialog.stamm.titel')}
      description={kind.name ?? undefined}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" onClick={() => void speichern()} disabled={gruende.length > 0 || speichert} loading={speichert}>
              {t('dialog.stamm.speichern')}
            </Button>
          </div>
          {gruende.length > 0 && (
            <ul aria-label={t('dialog.stamm.gruende')} className="flex flex-col items-end gap-1 text-xs text-[var(--color-error-coach)]">
              {gruende.map((g) => <li key={g}>{g}</li>)}
            </ul>
          )}
        </div>
      }
    >
      <div className="@container flex flex-col gap-4">
        {aendern && <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.stamm.aendernHinweis')}</p>}
        <div className="grid grid-cols-1 gap-6 @slots-dialog:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]">
          <section className="flex flex-col gap-2" aria-label={t('dialog.stamm.zeilen')}>
            {zeilen.map((z, i) => (
              <div
                key={i}
                className={`flex flex-col gap-2 rounded-[var(--radius-md)] border p-2 ${i === aktiv ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]' : 'border-[var(--color-border)]'}`}
              >
                <button type="button" aria-pressed={i === aktiv} onClick={() => setAktiv(i)} className="flex min-h-[44px] items-center justify-between text-left text-sm font-semibold">
                  <span>{t('dialog.stamm.zeile', { zeile: i + 1 })}</span>
                  <span className="tabular-nums text-[var(--color-text-secondary)]">
                    {vollstaendig(z) ? `${wochentagName(z.wochentag, i18n.language)} ${zeitName(z.zeit_id)}` : t('dialog.stamm.offen')}
                  </span>
                </button>
                <div className="grid grid-cols-2 gap-2">
                  <select autoFocus={i === 0} aria-label={t('dialog.stamm.tag')} className={SELECT_MD} value={z.wochentag ?? ''} onFocus={() => setAktiv(i)}
                    onChange={(e) => setze(i, { wochentag: e.target.value ? Number(e.target.value) : null })}>
                    <option value="">{t('dialog.stamm.tag')}</option>
                    {[1, 2, 3, 4, 5].map((w) => <option key={w} value={w}>{wochentagName(w, i18n.language, true)}</option>)}
                  </select>
                  <select aria-label={t('dialog.stamm.uhrzeit')} className={SELECT_MD} value={z.zeit_id ?? ''} onFocus={() => setAktiv(i)}
                    onChange={(e) => setze(i, { zeit_id: e.target.value || null })}>
                    <option value="">{t('dialog.stamm.uhrzeit')}</option>
                    {(frei?.zeiten ?? []).map((zt) => <option key={zt.id} value={zt.id}>{zt.beginn}</option>)}
                  </select>
                </div>
                <div role="group" aria-label={t('dialog.stamm.takt')} className="grid grid-cols-3 gap-1">
                  {TAKTE.map((k) => (
                    <button key={k} type="button" aria-pressed={z.takt === k} onClick={() => { setAktiv(i); setze(i, { takt: k }) }}
                      className={`min-h-[44px] rounded-[var(--radius-md)] px-2 text-xs font-semibold transition-colors duration-150 ease-out ${
                        z.takt === k ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]' : 'bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
                      }`}>
                      {t(`takt.${k}`)}
                    </button>
                  ))}
                </div>
              </div>
            ))}
            <label className="flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]">
              {t('dialog.stamm.ab')}
              <input type="date" value={ab} min={heute} onChange={(e) => e.target.value && setAb(e.target.value)}
                className="h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm tabular-nums" />
            </label>
          </section>

          <section className="flex flex-col gap-2" aria-label={t('dialog.stamm.frei', { zeile: aktiv + 1 })}>
            <h3 className="text-xs font-semibold text-[var(--color-text-tertiary)]">{t('dialog.stamm.frei', { zeile: aktiv + 1 })}</h3>
            {frei && <FreiRaster frei={frei} zeilen={zeilen} aktiv={aktiv} onWahl={(wochentag, zeit_id) => setze(aktiv, { wochentag, zeit_id })} />}
          </section>
        </div>

        <section className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4" aria-live="polite">
          <h3 className="text-xs font-semibold text-[var(--color-text-tertiary)]">{t('dialog.stamm.vorschau')}</h3>
          {vorschau?.planbilanz ? (
            <>
              <span><PlanbilanzBadge planbilanz={vorschau.planbilanz} vertragLaeuft={kind.vertrag_laeuft} /></span>
              <p className="text-sm text-[var(--color-text-secondary)]">{planbilanzSatz({ ...vorschau.planbilanz, uebersprungen: [] }, t, i18n.language)}</p>
            </>
          ) : (
            <p className="text-sm text-[var(--color-text-tertiary)]">{t('dialog.stamm.vorschauLeer')}</p>
          )}
          {(vorschau?.uebersprungen.length ?? 0) > 0 && (
            <p className="text-xs text-[var(--color-gold-warning)]">
              {t('dialog.stamm.uebersprungen', { daten: vorschau?.uebersprungen.map((d) => datumKurz(d, i18n.language)).join(', ') })}
            </p>
          )}
        </section>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
