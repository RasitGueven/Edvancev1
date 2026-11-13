// IU-1 U2: Reiter „Session-Reihen“. Kennzahlen, vorhandene Reihen (Bauformen, Videos), Themen ohne Reihe.
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { KennzahlenLeiste } from '@/components/edvance/admin/KennzahlenLeiste'
import { reihenKennzahlen, reihenSchritte } from '@/lib/inhalte/uebersicht'
import { getSessionReihen, getThemenOhneReihe } from '@/lib/supabase/inhalte'
import type { InhalteReihe, InhalteThemaOhneReihe, ReihenAmpel } from '@/types/inhalte'

import { Ampel, KlasseTag, Legende, Schritte, Stapel, ZeilenTitel, useZeitfenster, type Farbe } from './Bausteine'

const AMPEL_FARBE: Record<ReihenAmpel, Farbe> = { bereit: 'gut', in_arbeit: 'achtung', nicht_bereit: 'handeln' }

/** Titel der Reihe: Textdatei der Bauform-Prüfung, sonst die Themen aus der Datenbank. */
export function useReihenTitel(): (r: { reihe: string; titel: string }) => string {
  const { t } = useTranslation('bauformPruefen')
  return (r) => t(`reihe.${r.reihe}.thema`, { defaultValue: r.titel })
}

type Props = { klasse: number | null; onReihe: (key: string) => void }

export function ReihenReiter({ klasse, onReihe }: Props): JSX.Element {
  const { t } = useTranslation('admin')
  const fenster = useZeitfenster()
  const titel = useReihenTitel()
  const [reihen, setReihen] = useState<InhalteReihe[] | null>(null)
  const [ohne, setOhne] = useState<InhalteThemaOhneReihe[] | null>(null)
  const [fehler, setFehler] = useState(false)

  useEffect(() => {
    let aktiv = true
    setReihen(null)
    setFehler(false)
    void Promise.all([getSessionReihen(klasse), getThemenOhneReihe(klasse)]).then(([r, o]) => {
      if (!aktiv) return
      setFehler(r.error !== null || o.error !== null)
      setReihen(r.data ?? [])
      setOhne(o.data ?? [])
    })
    return () => {
      aktiv = false
    }
  }, [klasse])

  if (fehler) return <EmptyState icon="⚠️" title={t('inhalte.ladeFehler')} description={t('inhalte.ladeFehlerText')} />
  if (!reihen || !ohne) return <LoadingPulse type="list" lines={6} />

  const k = reihenKennzahlen(reihen, ohne.length)
  const spalten: Spalte<InhalteReihe>[] = [
    {
      key: 'reihe', kopf: t('inhalte.reihen.spalte.reihe'),
      zelle: (r) => (
        <ZeilenTitel titel={titel(r)}>
          <KlasseTag klasse={r.klasse} />
          <span>{t('inhalte.reihen.sessions', { count: r.sessions })}</span>
          <span>{fenster(r.quartal, r.von, r.bis)}</span>
        </ZeilenTitel>
      ),
    },
    {
      key: 'bf', kopf: t('inhalte.reihen.spalte.bauformen'),
      zelle: (r) => {
        const text = t('inhalte.reihen.bfZahl', { frei: r.bf_freigegeben, zur: r.bf_zur_freigabe, rueck: r.bf_rueckfrage, offen: r.bf_offen })
        return (
          <div className="flex flex-col gap-1">
            <Stapel label={text} teile={[{ wert: r.bf_freigegeben, farbe: 'gut' }, { wert: r.bf_zur_freigabe, farbe: 'primaer' },
              { wert: r.bf_rueckfrage, farbe: 'achtung' }, { wert: r.bf_offen, farbe: 'offen' }]} />
            <span className="whitespace-nowrap text-xs text-[var(--color-text-secondary)]">{text}</span>
          </div>
        )
      },
    },
    {
      key: 'vid', kopf: t('inhalte.reihen.spalte.videos'),
      zelle: (r) => {
        const text = t('inhalte.reihen.vidZahl', { frei: r.vid_freigegeben, gesamt: r.vid_gesamt })
        return (
          <div className="flex flex-col gap-1">
            <Stapel label={text} teile={[{ wert: r.vid_freigegeben, farbe: 'gut' }, { wert: r.vid_in_pruefung, farbe: 'primaer' },
              { wert: r.vid_fehlt, farbe: 'offen' }]} />
            <span className="whitespace-nowrap text-xs text-[var(--color-text-secondary)]">{text}</span>
          </div>
        )
      },
    },
    { key: 'ampel', kopf: t('inhalte.reihen.spalte.bereit'), zelle: (r) => <Ampel farbe={AMPEL_FARBE[r.ampel]} text={t(`inhalte.reihen.ampel.${r.ampel}`)} /> },
    {
      key: 'wirkung', kopf: t('inhalte.reihen.spalte.wirkung'),
      zelle: (r) => (
        <div className="flex flex-col gap-1">
          <span className="font-semibold">{t('inhalte.lsa.schulen', { count: r.schulen })}</span>
          <span className="text-xs text-[var(--color-text-secondary)]">
            {t('inhalte.lsa.schulenUnter', { best: r.schulen_bestaetigt, gesch: r.schulen - r.schulen_bestaetigt })}
          </span>
        </div>
      ),
    },
    { key: 'schritt', kopf: t('inhalte.reihen.spalte.schritt'), zelle: (r) => <Schritte schritte={reihenSchritte(r)} /> },
  ]
  const ohneSpalten: Spalte<InhalteThemaOhneReihe>[] = [
    { key: 'thema', kopf: t('inhalte.ohne.spalte.thema'), zelle: (o) => <span className="font-semibold">{o.titel}</span> },
    { key: 'klasse', kopf: t('inhalte.ohne.spalte.klasse'), zelle: (o) => <KlasseTag klasse={o.klasse} /> },
    { key: 'fenster', kopf: t('inhalte.ohne.spalte.fenster'), zelle: (o) => <span className="whitespace-nowrap">{fenster(o.quartal, o.von, o.bis)}</span> },
    { key: 'schulen', kopf: t('inhalte.ohne.spalte.schulen'), rechts: true, zelle: (o) => <span className="font-semibold tabular-nums">{o.schulen}</span> },
    {
      key: 'vorarbeit', kopf: t('inhalte.ohne.spalte.vorarbeit'),
      zelle: (o) => (
        <span className="text-xs text-[var(--color-text-secondary)]">
          {o.vorarbeit === 'bauformen' ? t('inhalte.ohne.vorarbeit.bauformen', { count: o.bauformen }) : t(`inhalte.ohne.vorarbeit.${o.vorarbeit}`)}
        </span>
      ),
    },
    {
      key: 'aktion', kopf: t('inhalte.ohne.spalte.aktion'), rechts: true,
      zelle: (o) => (
        <span title={t('inhalte.ohne.spaeter')} className="inline-flex">
          <button type="button" disabled aria-describedby={`spaeter-${o.thema_key}`}
            className="min-h-[44px] cursor-not-allowed whitespace-nowrap rounded-[var(--radius-full)] border border-[var(--color-border)] px-4 text-xs font-semibold text-[var(--color-neutral-disabled)]">
            {t('inhalte.ohne.anlegen')}
          </button>
          <span id={`spaeter-${o.thema_key}`} className="sr-only">{t('inhalte.ohne.spaeter')}</span>
        </span>
      ),
    },
  ]

  return (
    <div className="flex flex-col gap-6">
      <div className="@container">
        <KennzahlenLeiste label={t('inhalte.kennzahlen')} breite="heute-kpi-4" zahlen={[
          { key: 'b', label: t('inhalte.kpi.bereit'), wert: String(k.bereit) },
          { key: 'a', label: t('inhalte.kpi.inArbeit'), wert: String(k.inArbeit) },
          { key: 'p', label: t('inhalte.kpi.inPlanung'), wert: String(k.inPlanung) },
          { key: 'o', label: t('inhalte.kpi.ohneReihe'), wert: String(k.ohneReihe) },
        ]} />
      </div>
      <section className="flex flex-col gap-2" aria-labelledby="reihen-panel">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h2 id="reihen-panel" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('inhalte.reihen.panel')}</h2>
          <p className="text-xs text-[var(--color-text-secondary)]">{t('inhalte.reihen.panelSatz')}</p>
        </div>
        {reihen.length === 0 ? (
          <EmptyState icon="🧩" title={t('inhalte.reihen.leer')} description={t('inhalte.reihen.leerText')} />
        ) : (
          <>
            <EdvanceTable beschriftung={t('inhalte.reihen.panel')} spalten={spalten} zeilen={reihen}
              zeileKey={(r) => r.reihe} onZeile={(r) => onReihe(r.reihe)} />
            <Legende eintraege={[
              { text: t('inhalte.reihen.legende.frei'), farbe: 'gut' }, { text: t('inhalte.reihen.legende.zur'), farbe: 'primaer' },
              { text: t('inhalte.reihen.legende.rueck'), farbe: 'achtung' }, { text: t('inhalte.reihen.legende.offen'), farbe: 'offen' },
            ]} />
          </>
        )}
      </section>
      <section className="flex flex-col gap-2" aria-labelledby="ohne-panel">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h2 id="ohne-panel" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('inhalte.ohne.panel')}</h2>
          <p className="text-xs text-[var(--color-text-secondary)]">{t('inhalte.ohne.panelSatz')}</p>
        </div>
        {ohne.length === 0 ? (
          <EmptyState icon="🎉" title={t('inhalte.ohne.leer')} description={t('inhalte.reihen.panelSatz')} />
        ) : (
          <EdvanceTable beschriftung={t('inhalte.ohne.panel')} spalten={ohneSpalten} zeilen={ohne} zeileKey={(o) => o.thema_key} />
        )}
      </section>
    </div>
  )
}
