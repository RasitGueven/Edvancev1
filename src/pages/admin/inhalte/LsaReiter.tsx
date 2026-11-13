// IU-1 U2: Reiter „Lernstandsanalyse“. Kennzahlen, MSA-Zeile oben (Prüfziel), Tabelle je Thema.
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'

import { EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { KennzahlenLeiste } from '@/components/edvance/admin/KennzahlenLeiste'
import { LSA_FREIGABE, PRUEFZIEL_MSA, heuteIso, lsaKennzahlen, lsaReihenfolge, lsaSchritte } from '@/lib/inhalte/uebersicht'
import { getLsaPruefziel, getLsaThemen } from '@/lib/supabase/inhalte'
import type { InhaltePruefzielBereich, InhalteThema, ThemaAmpel } from '@/types/inhalte'

import { Ampel, KlasseTag, Legende, Schritte, Stapel, ZeilenTitel, useZeitfenster, type Farbe } from './Bausteine'

const AMPEL_FARBE: Record<ThemaAmpel, Farbe> = { vollstaendig: 'gut', eingeschraenkt: 'achtung', noch_nicht: 'handeln' }

type Zeile = { art: 'ziel'; z: InhaltePruefzielBereich } | { art: 'thema'; z: InhalteThema }

type Props = { klasse: number | null; onThema: (key: string) => void; onZiel: (key: string) => void }

export function LsaReiter({ klasse, onThema, onZiel }: Props): JSX.Element {
  const { t } = useTranslation('admin')
  const fenster = useZeitfenster()
  const [themen, setThemen] = useState<InhalteThema[] | null>(null)
  const [ziel, setZiel] = useState<InhaltePruefzielBereich | null>(null)
  const [fehler, setFehler] = useState(false)

  useEffect(() => {
    let aktiv = true
    setThemen(null)
    setFehler(false)
    const mitZiel = klasse === null || klasse === 10
    void Promise.all([getLsaThemen(klasse), mitZiel ? getLsaPruefziel(PRUEFZIEL_MSA) : Promise.resolve(null)]).then(
      ([th, zi]) => {
        if (!aktiv) return
        setFehler(th.error !== null || (zi !== null && zi.error !== null))
        setThemen(th.data ?? [])
        setZiel(zi?.data?.find((b) => b.bereich === null) ?? null)
      },
    )
    return () => {
      aktiv = false
    }
  }, [klasse])

  if (fehler) return <EmptyState icon="⚠️" title={t('inhalte.ladeFehler')} description={t('inhalte.ladeFehlerText')} />
  if (!themen) return <LoadingPulse type="list" lines={6} />

  const k = lsaKennzahlen(themen)
  // IU-1b: MSA oben, dann laufende und kommende Themen, am Ende „Schon geschrieben“.
  const folge = lsaReihenfolge(themen, heuteIso())
  const vorbei = new Set(folge.vorbei.map((x) => x.thema_key))
  const zeilen: Zeile[] = [
    ...(ziel ? [{ art: 'ziel' as const, z: ziel }] : []),
    ...[...folge.laufend, ...folge.vorbei].map((z) => ({ art: 'thema' as const, z })),
  ]
  const komp = (z: { komp_bereit: number; komp_teil: number; komp_offen: number }): JSX.Element => (
    <div className="flex flex-col gap-1">
      <Stapel label={t('inhalte.lsa.kompetenzenZahl', { bereit: z.komp_bereit, teil: z.komp_teil, offen: z.komp_offen })}
        teile={[{ wert: z.komp_bereit, farbe: 'gut' }, { wert: z.komp_teil, farbe: 'achtung' }, { wert: z.komp_offen, farbe: 'offen' }]} />
      <span className="whitespace-nowrap text-xs text-[var(--color-text-secondary)]">
        {t('inhalte.lsa.kompetenzenZahl', { bereit: z.komp_bereit, teil: z.komp_teil, offen: z.komp_offen })}
      </span>
    </div>
  )
  const aufgaben = (frei: number, zur: number, zu: number): JSX.Element => (
    <div className="flex flex-col gap-1">
      <span><span className="font-semibold tabular-nums">{frei}</span> {t('inhalte.lsa.freigegeben')}</span>
      <span className="text-xs text-[var(--color-text-secondary)]">{t('inhalte.lsa.aufgabenUnter', { zur, zu })}</span>
    </div>
  )
  const warum = (th: InhalteThema): string | undefined => {
    if (th.ampel === 'eingeschraenkt') return t('inhalte.lsa.warum.eingeschraenkt')
    if (th.ampel === 'vollstaendig') return undefined
    if (!th.hat_einstieg) return t('inhalte.lsa.warum.ohneEinstieg')
    return t('inhalte.lsa.warum.pflichtFehlt', { count: th.pflicht_gesamt - th.pflicht_bereit })
  }

  const spalten: Spalte<Zeile>[] = [
    {
      key: 'thema', kopf: t('inhalte.lsa.spalte.thema'),
      zelle: (r) => r.art === 'ziel' ? (
        <ZeilenTitel titel={r.z.titel}>
          <KlasseTag klasse={10} /><EdvanceBadge variant="warning">{t('inhalte.lsa.zielTag')}</EdvanceBadge>
          <span>{t('inhalte.lsa.msaFenster')}</span>
        </ZeilenTitel>
      ) : (
        <ZeilenTitel titel={r.z.titel}><KlasseTag klasse={r.z.klasse} /><span>{fenster(r.z.quartal, r.z.von, r.z.bis)}</span></ZeilenTitel>
      ),
    },
    { key: 'komp', kopf: t('inhalte.lsa.spalte.kompetenzen'), zelle: (r) => komp(r.z) },
    {
      key: 'aufgaben', kopf: t('inhalte.lsa.spalte.aufgaben'),
      zelle: (r) => aufgaben(r.z.aufgaben_frei, r.z.aufgaben_zur_freigabe, r.z.aufgaben_zu_pruefen),
    },
    {
      key: 'moeglich', kopf: t('inhalte.lsa.spalte.moeglich'),
      zelle: (r) => r.art === 'ziel'
        ? <Ampel farbe={AMPEL_FARBE[r.z.ampel]} text={t(`inhalte.lsa.ampel.${r.z.ampel}`)}
            unter={r.z.ampel === 'vollstaendig' ? undefined : t('inhalte.lsa.warum.kompFehlt', { count: r.z.komp_teil + r.z.komp_offen })} />
        : <Ampel farbe={AMPEL_FARBE[r.z.ampel]} text={t(`inhalte.lsa.ampel.${r.z.ampel}`)} unter={warum(r.z)} />,
    },
    {
      key: 'wirkung', kopf: t('inhalte.lsa.spalte.wirkung'),
      zelle: (r) => (
        <Link to={LSA_FREIGABE} onClick={(e) => e.stopPropagation()} title={t('inhalte.lsa.zurAbdeckung')}
          className="flex flex-col gap-1 hover:underline">
          <span className="font-semibold text-[var(--color-text-primary)]">
            {r.art === 'ziel' ? t('inhalte.lsa.msaWirkung') : t('inhalte.lsa.schulen', { count: r.z.schulen })}
          </span>
          <span className="text-xs text-[var(--color-text-secondary)]">
            {r.art === 'ziel' ? t('inhalte.lsa.msaWirkungUnter')
              : t('inhalte.lsa.schulenUnter', { best: r.z.schulen_bestaetigt, gesch: r.z.schulen - r.z.schulen_bestaetigt })}
          </span>
        </Link>
      ),
    },
    {
      key: 'schritt', kopf: t('inhalte.lsa.spalte.schritt'),
      zelle: (r) => <Schritte schritte={lsaSchritte(r.z, r.art === 'ziel' ? PRUEFZIEL_MSA : null)} />,
    },
  ]

  return (
    <div className="flex flex-col gap-6">
      <div className="@container">
        <KennzahlenLeiste label={t('inhalte.kennzahlen')} breite="heute-kpi-4" zahlen={[
          { key: 'v', label: t('inhalte.kpi.vollstaendig'), wert: String(k.vollstaendig) },
          { key: 'e', label: t('inhalte.kpi.eingeschraenkt'), wert: String(k.eingeschraenkt) },
          { key: 'n', label: t('inhalte.kpi.nochNicht'), wert: String(k.nochNicht) },
          { key: 'p', label: t('inhalte.kpi.zuPruefen'), wert: String(k.zuPruefen), ziel: '/coach/pruefen' },
        ]} />
      </div>
      <section className="flex flex-col gap-2" aria-labelledby="lsa-panel">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h2 id="lsa-panel" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('inhalte.lsa.panel')}
          </h2>
          <p className="text-xs text-[var(--color-text-secondary)]">{t('inhalte.lsa.panelSatz')}</p>
        </div>
        {zeilen.length === 0 ? (
          <EmptyState icon="🗓️" title={t('inhalte.lsa.leer')} description={t('inhalte.lsa.leerText')} />
        ) : (
          <>
            <EdvanceTable beschriftung={t('inhalte.lsa.panel')} spalten={spalten} zeilen={zeilen}
              zeileKey={(r) => (r.art === 'ziel' ? `ziel-${PRUEFZIEL_MSA}` : r.z.thema_key)}
              onZeile={(r) => (r.art === 'ziel' ? onZiel(PRUEFZIEL_MSA) : onThema(r.z.thema_key))}
              abschnitt={(r) => (r.art === 'thema' && vorbei.has(r.z.thema_key) ? t('inhalte.lsa.schonGeschrieben') : null)} />
            <Legende eintraege={[
              { text: t('inhalte.lsa.legende.bereit'), farbe: 'gut' },
              { text: t('inhalte.lsa.legende.teil'), farbe: 'achtung' },
              { text: t('inhalte.lsa.legende.offen'), farbe: 'offen' },
            ]} />
          </>
        )}
      </section>
    </div>
  )
}
