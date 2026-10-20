import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { LoadingPulse } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import {
  ladeEinstellungen, ladePlanbilanzVorschau, ladeStammplatzVorschau, stammplatzAendern, stammplatzVergeben,
} from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { wocheVerschieben, dieseWoche } from '@/components/edvance/wochenNavigation.model'
import type {
  PlanbilanzVorschau, Rhythmus, SlotsEinstellungen, Stammplatz, StammplatzZeile, Takt,
} from '@/types/slotplan'
import { datumKurz, wochentagName } from '../slotsFormat'
import { PlanbilanzBadge, planbilanzSatz } from '../kinder/Einheiten'
import { aktivAm, ersterTermintag, istAWoche, kwVon } from './stammplatz.model'
import { StammplatzRaeume, StammplatzTermine, sperrSatz, type RaumVorschau } from './StammplatzRaeume'

export type StammplatzKind = { student_id: string; name: string | null; beginn: string; vertrag_laeuft: boolean; rhythmus: Rhythmus | null }
export type Zeile = { wochentag: number | null; zeit_id: string | null; takt: Takt; raum_id: string | null }

const TAKTE: Takt[] = ['woechentlich', 'a_woche', 'b_woche']
const LABEL = 'flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]'

/** Zeilen nach dem Rhythmus (Anforderung E 26): wöchentliche zuerst, dann 14-tägliche (A-Woche). */
export function zeilenNachRhythmus(r: Rhythmus | null): Zeile[] {
  const leer = (takt: Takt): Zeile => ({ wochentag: null, zeit_id: null, takt, raum_id: null })
  const z: Zeile[] = [
    ...Array.from({ length: r?.woechentlich ?? 1 }, () => leer('woechentlich')),
    ...Array.from({ length: r?.vierzehntaeglich ?? 0 }, () => leer('a_woche')),
  ]
  return z.length > 0 ? z : [leer('woechentlich')]
}

/**
 * Standard für „gültig ab“: beim Ändern der spätere von nächstem Montag, Beginn des Stammplatzes und Vertragsbeginn;
 * beim Vergeben heute oder der spätere Vertragsbeginn.
 */
export function abStandard(kind: Pick<StammplatzKind, 'beginn'>, heute: string, aendern?: Pick<Stammplatz, 'gueltig_ab'>): string {
  const kandidaten = aendern ? [wocheVerschieben(dieseWoche(), 1), aendern.gueltig_ab, kind.beginn] : [heute, kind.beginn]
  return kandidaten.reduce((a, b) => (b > a ? b : a))
}

const mitSlot = (z: Zeile): z is Zeile & { wochentag: number; zeit_id: string } => z.wochentag !== null && z.zeit_id !== null
const vollstaendig = (z: Zeile): z is Zeile & { wochentag: number; zeit_id: string; raum_id: string } => mitSlot(z) && z.raum_id !== null

/**
 * Stammplatz vergeben oder ab einem Datum ändern (Bauauftrag W3, Entscheidungen 3–6): Tag, Uhrzeit, Takt, gültig ab,
 * darunter je aktivem Raum eine Karte, „Die nächsten Termine“ aus stammplatz_vorschau und die Planbilanz.
 */
export function StammplatzDialog({
  kind,
  aendern,
  vorbelegt,
  onClose,
  onGespeichert,
}: {
  kind: StammplatzKind
  /** Gesetzt: diesen Stammplatz ab "gültig ab" ändern (Altbestand ohne Raum: „Raum festlegen“). */
  aendern?: Stammplatz
  /** Vergeben mit vorbelegten Zeilen (z. B. Tag, Uhrzeit, Takt der Vorgänger bei einem Folgevertrag ohne Raum). */
  vorbelegt?: Zeile[]
  onClose: () => void
  onGespeichert: (meldung: string) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const heute = berlinToday()
  const [zeilen, setZeilen] = useState<Zeile[]>(() =>
    aendern
      ? [{ wochentag: aendern.wochentag, zeit_id: aendern.zeit_id, takt: aendern.takt, raum_id: aendern.raum_id ?? null }]
      : vorbelegt && vorbelegt.length > 0 ? vorbelegt : zeilenNachRhythmus(kind.rhythmus),
  )
  const [aktiv, setAktiv] = useState(0)
  const [ab, setAb] = useState(() => abStandard(kind, heute, aendern))
  const [einst, setEinst] = useState<SlotsEinstellungen | null>(null)
  const [raumVorschau, setRaumVorschau] = useState<Record<string, RaumVorschau> | null>(null)
  const [bilanz, setBilanz] = useState<PlanbilanzVorschau | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)
  const z = zeilen[aktiv]
  const ersetzt = useMemo(() => (aendern ? [aendern.id] : null), [aendern])
  const raeume = useMemo(() => aktivAm(einst?.raeume ?? [], ab), [einst, ab])
  const zeiten = useMemo(() => aktivAm(einst?.zeiten ?? [], ab), [einst, ab])
  const raumIds = raeume.map((r) => r.id).join(',')
  const fertigeZeilen = useMemo<StammplatzZeile[]>(
    () => zeilen.filter(vollstaendig).map((x) => ({ wochentag: x.wochentag, slot_zeit_id: x.zeit_id, takt: x.takt, raum_id: x.raum_id })),
    [zeilen],
  )

  useEffect(() => {
    let lauf = true
    void ladeEinstellungen().then((res) => {
      if (!lauf) return
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
      setEinst(res.data)
    })
    return () => {
      lauf = false
    }
  }, [])

  // Je aktivem Raum die Vorschau der aktiven Zeile: speist die Raum-Karten und „Die nächsten Termine“.
  useEffect(() => {
    let lauf = true
    setRaumVorschau(null)
    const wochentag = z.wochentag
    const zeitId = z.zeit_id
    const takt = z.takt
    if (wochentag === null || zeitId === null || raumIds === '') return undefined
    void Promise.all(
      raumIds.split(',').map((id) => ladeStammplatzVorschau(kind.student_id, wochentag, zeitId, id, takt, ab, ersetzt).then((res) => [id, res] as const)),
    ).then((ergebnisse) => {
      if (!lauf) return
      // Scheitert die Vorschau eines Raums, ist seine Karte mit Satz gesperrt; beim nächsten Laden beginnt alles neu.
      setRaumVorschau(Object.fromEntries(ergebnisse.map(([id, res]) => [
        id, { zeilen: res.data ?? [], fehler: res.error !== null ? slotsFehlerSchluessel(res) : null },
      ])))
    })
    return () => {
      lauf = false
    }
  }, [kind.student_id, z.wochentag, z.zeit_id, z.takt, ab, raumIds, ersetzt])

  useEffect(() => {
    let lauf = true
    setBilanz(null)
    if (fertigeZeilen.length !== zeilen.length) return undefined
    void ladePlanbilanzVorschau(kind.student_id, fertigeZeilen, ab, ersetzt).then((res) => {
      if (!lauf) return
      setBilanz(res.data)
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
    })
    return () => {
      lauf = false
    }
  }, [fertigeZeilen, zeilen.length, ab, kind.student_id, ersetzt])

  const setze = (teil: Partial<Zeile>): void => setZeilen((zs) => zs.map((x, j) => (j === aktiv ? { ...x, ...teil } : x)))
  const zeit = (id: string | null): string => zeiten.find((x) => x.id === id)?.beginn ?? ''
  const raumName = (id: string | null): string => raeume.find((r) => r.id === id)?.name ?? ''
  const mitZeile = (i: number, satz: string): string => (zeilen.length > 1 ? t('dialog.stamm.zeileGrund', { zeile: i + 1, grund: satz }) : satz)

  const gewaehlteVorschau = z.raum_id && raumVorschau ? (raumVorschau[z.raum_id] ?? null) : null
  const sperre = gewaehlteVorschau ? sperrSatz(gewaehlteVorschau, raumName(z.raum_id), zeit(z.zeit_id), z.takt, t, i18n.language) : null
  const gruende = [
    ...zeilen.flatMap((x, i) => [
      ...(mitSlot(x) ? [] : [mitZeile(i, t('kinder2.dialog.slotWaehlen'))]),
      ...(mitSlot(x) && x.raum_id === null ? [mitZeile(i, t('kinder2.dialog.raumWaehlen'))] : []),
    ]),
    ...(sperre ? [mitZeile(aktiv, sperre)] : []),
    ...(bilanz?.gruende ?? []).map((g) => (g.zeile === null ? t(`fehler.${g.code}`) : mitZeile(g.zeile, t(`fehler.${g.code}`)))),
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

  const zeilenText = (x: Zeile): string =>
    mitSlot(x)
      ? [`${wochentagName(x.wochentag, i18n.language)} ${zeit(x.zeit_id)}`, x.raum_id ? raumName(x.raum_id) : null].filter(Boolean).join(' · ')
      : t('dialog.stamm.offen')
  const ersterTag = z.wochentag !== null ? ersterTermintag(ab, z.wochentag, z.takt) : null
  const titel = aendern ? (aendern.raum_id == null ? 'kinder2.dialog.titelRaum' : 'dialog.stamm.titelAendern') : 'dialog.stamm.titel'

  return (
    <Modal
      open
      size="xl"
      onClose={onClose}
      title={t(titel)}
      description={kind.name ?? undefined}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" onClick={() => void speichern()} disabled={gruende.length > 0 || speichert} loading={speichert}
              title={gruende.length > 0 ? t('dialog.stamm.gruende') : undefined}>
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
      <div className="@container flex flex-col gap-6">
        {aendern && <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.stamm.aendernHinweis')}</p>}
        {zeilen.length > 1 && (
          <div role="group" aria-label={t('dialog.stamm.zeilen')} className="flex flex-wrap gap-2">
            {zeilen.map((x, i) => (
              <button key={i} type="button" aria-pressed={i === aktiv} onClick={() => setAktiv(i)}
                className={`min-h-[44px] rounded-[var(--radius-md)] border px-4 text-left text-sm font-semibold ${
                  i === aktiv ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]' : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'
                }`}>
                {t('dialog.stamm.zeile', { zeile: i + 1 })} <span className="font-normal tabular-nums text-[var(--color-text-secondary)]">{zeilenText(x)}</span>
              </button>
            ))}
          </div>
        )}

        {!einst ? (
          <LoadingPulse type="list" lines={3} />
        ) : (
          <>
            <section className="flex flex-col gap-2">
              <div className="grid grid-cols-2 gap-4 @2xl:grid-cols-4">
                <label className={LABEL}>
                  {t('kinder2.dialog.wochentag')}
                  <select autoFocus className={SELECT_MD} value={z.wochentag ?? ''} onChange={(e) => setze({ wochentag: e.target.value ? Number(e.target.value) : null })}>
                    <option value="">{t('kinder2.dialog.waehlen')}</option>
                    {[1, 2, 3, 4, 5].map((w) => <option key={w} value={w}>{wochentagName(w, i18n.language, true)}</option>)}
                  </select>
                </label>
                <label className={LABEL}>
                  {t('dialog.stamm.uhrzeit')}
                  <select className={SELECT_MD} value={z.zeit_id ?? ''} onChange={(e) => setze({ zeit_id: e.target.value || null })}>
                    <option value="">{t('kinder2.dialog.waehlen')}</option>
                    {zeiten.map((x) => <option key={x.id} value={x.id}>{t('kinder2.dialog.zeit', { von: x.beginn, bis: x.ende })}</option>)}
                  </select>
                </label>
                <label className={LABEL}>
                  {t('dialog.stamm.takt')}
                  <select className={SELECT_MD} value={z.takt} onChange={(e) => setze({ takt: e.target.value as Takt })}>
                    {TAKTE.map((k) => <option key={k} value={k}>{t(`kinder2.takt.${k}`)}</option>)}
                  </select>
                </label>
                <label className={LABEL}>
                  {t('kinder2.dialog.ab')}
                  <input type="date" value={ab} min={heute} onChange={(e) => e.target.value && setAb(e.target.value)}
                    className="h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm tabular-nums" />
                </label>
              </div>
              {z.takt !== 'woechentlich' && ersterTag && (
                <p role="note" className="text-sm text-[var(--color-text-secondary)]">
                  {t('kinder2.dialog.abHinweis', { kw: kwVon(ersterTag), woche: t(istAWoche(ersterTag) ? 'takt.a_woche' : 'takt.b_woche') })}
                </p>
              )}
            </section>

            <section className="flex flex-col gap-2" aria-label={t('kinder2.raum.titel')}>
              <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('kinder2.raum.titel')}</h3>
              {mitSlot(z) ? (
                <StammplatzRaeume raeume={raeume} vorschau={raumVorschau} beginn={zeit(z.zeit_id)} takt={z.takt} gewaehlt={z.raum_id} onWahl={(raum_id) => setze({ raum_id })} />
              ) : (
                <p className="text-sm text-[var(--color-text-tertiary)]">{t('kinder2.raum.erstSlot')}</p>
              )}
            </section>

            <section className="flex flex-col gap-2" aria-live="polite">
              <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('kinder2.termine.titel')}</h3>
              {gewaehlteVorschau && !gewaehlteVorschau.fehler ? (
                <StammplatzTermine zeilen={gewaehlteVorschau.zeilen} raum={raumName(z.raum_id)} takt={z.takt} />
              ) : (
                <p className="text-sm text-[var(--color-text-tertiary)]">{t('kinder2.termine.leer')}</p>
              )}
            </section>
          </>
        )}

        <section className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4" aria-live="polite">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('dialog.stamm.vorschau')}</h3>
          {bilanz?.planbilanz ? (
            <>
              <span><PlanbilanzBadge planbilanz={bilanz.planbilanz} vertragLaeuft={kind.vertrag_laeuft} /></span>
              <p className="text-sm text-[var(--color-text-secondary)]">{planbilanzSatz({ ...bilanz.planbilanz, uebersprungen: [] }, t, i18n.language)}</p>
            </>
          ) : (
            <p className="text-sm text-[var(--color-text-tertiary)]">{t('kinder2.dialog.bilanzLeer')}</p>
          )}
        </section>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
