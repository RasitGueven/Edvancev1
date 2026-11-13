// IU-1 U2: Details im Reiter Lernstandsanalyse. Thema: Pflicht und Tiefe je Kompetenz („n von 2“, In Lenas Liste).
// Prüfziel: je Bereich eine Karte.
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'

import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { lenaListe } from '@/lib/inhalte/uebersicht'
import { getLsaPruefziel, getLsaThema, getLsaThemen } from '@/lib/supabase/inhalte'
import type { InhalteKompetenz, InhaltePruefzielBereich, InhalteThema } from '@/types/inhalte'

import { Ampel, Stapel, useZeitfenster } from './Bausteine'

const REGEL = 2

function Pips({ n }: { n: number }): JSX.Element {
  const { t } = useTranslation('admin')
  return (
    <span className="inline-flex items-center gap-2 text-xs text-[var(--color-text-secondary)]">
      {Array.from({ length: REGEL }, (_, i) => (
        <span key={i} aria-hidden="true" className={`inline-block h-2 w-6 rounded-[var(--radius-full)] ${
          i < n ? 'bg-[var(--color-success)]' : 'bg-[var(--color-bg-subtle)]'}`} />
      ))}
      <span className="tabular-nums">{t('inhalte.thema.nVon', { n, m: REGEL })}</span>
    </span>
  )
}

function KompetenzZeile({ k }: { k: InhalteKompetenz }): JSX.Element {
  const { t } = useTranslation('admin')
  const stand = k.erfuellt ? 'bereit' : k.texte > 0 ? 'teilweise' : 'offen'
  return (
    <li className="grid grid-cols-1 items-center gap-2 border-t border-[var(--color-border)] px-4 py-3 first:border-t-0 md:grid-cols-[minmax(0,1fr)_7rem_7rem_minmax(0,16rem)] md:gap-4">
      <span className="font-semibold text-[var(--color-text-primary)]">{k.label}</span>
      <Pips n={k.texte} />
      <span><EdvanceBadge variant={stand === 'bereit' ? 'success' : stand === 'teilweise' ? 'warning' : 'muted'}>
        {t(`inhalte.thema.status.${stand}`)}</EdvanceBadge></span>
      <span className="flex flex-wrap items-center gap-2 text-xs text-[var(--color-text-secondary)]">
        {k.erfuellt ? t('inhalte.schritt.nichtsOffen') : k.zu_pruefen > 0 ? (
          <>
            <span><span className="font-semibold text-[var(--color-text-primary)]">{t('inhalte.schritt.lena')}:</span>{' '}
              {t('inhalte.thema.lenaPrueft', { count: k.zu_pruefen })}</span>
            <Link to={lenaListe({ skill: k.skill_key })} aria-label={t('inhalte.thema.inLenasListeLabel', { kompetenz: k.label })}
              className="inline-flex min-h-[44px] items-center rounded-[var(--radius-full)] border border-[var(--color-border)] px-4 font-semibold text-[var(--color-primary)] hover:bg-[var(--color-primary-light)]">
              {t('inhalte.thema.inLenasListe')}
            </Link>
          </>
        ) : t('inhalte.thema.fehlen', { count: Math.max(k.fehlen, REGEL - k.texte) })}
      </span>
    </li>
  )
}

function Gruppe({ titel, satz, liste }: { titel: string; satz: string; liste: InhalteKompetenz[] }): JSX.Element | null {
  if (liste.length === 0) return null
  return (
    <>
      <div className="border-y border-[var(--color-border)] bg-[var(--color-bg-app)] px-4 py-2 text-xs text-[var(--color-text-secondary)]">
        <span className="font-semibold text-[var(--color-text-primary)]">{titel}</span> · {satz}
      </div>
      <ul>{liste.map((k) => <KompetenzZeile key={k.skill_key} k={k} />)}</ul>
    </>
  )
}

/** Kopfzeile unter dem Titel (Klasse, Zeitfenster, Schulen, Ampel). */
export function useThemaKopf(themaKey: string): InhalteThema | null | undefined {
  const [kopf, setKopf] = useState<InhalteThema | null | undefined>(undefined)
  useEffect(() => {
    void getLsaThemen(null).then((r) => setKopf(r.data?.find((x) => x.thema_key === themaKey) ?? null))
  }, [themaKey])
  return kopf
}

export function ThemaDetail({ themaKey, kopf }: { themaKey: string; kopf: InhalteThema | null | undefined }): JSX.Element {
  const { t } = useTranslation('admin')
  const fenster = useZeitfenster()
  const [liste, setListe] = useState<InhalteKompetenz[] | null>(null)
  const [fehler, setFehler] = useState(false)
  useEffect(() => {
    void getLsaThema(themaKey).then((r) => {
      setFehler(r.error !== null)
      setListe(r.data ?? [])
    })
  }, [themaKey])

  if (fehler) return <EmptyState icon="⚠️" title={t('inhalte.ladeFehler')} description={t('inhalte.ladeFehlerText')} />
  if (!liste || kopf === undefined) return <LoadingPulse type="list" lines={8} />
  const p = liste.filter((k) => k.teil === 'pflicht')
  const ti = liste.filter((k) => k.teil === 'tiefe')
  const bereit = (l: InhalteKompetenz[]): number => l.filter((k) => k.erfuellt).length
  return (
    <div className="flex flex-col gap-4">
      {kopf && (
        <div className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <span>{t('inhalte.thema.unter', { klasse: t('inhalte.klasseTag', { klasse: kopf.klasse }),
            fenster: fenster(kopf.quartal, kopf.von, kopf.bis), schulen: t('inhalte.lsa.schulen', { count: kopf.schulen }) })}</span>
          <Ampel farbe={kopf.ampel === 'vollstaendig' ? 'gut' : kopf.ampel === 'eingeschraenkt' ? 'achtung' : 'handeln'}
            text={t(`inhalte.lsa.ampel.${kopf.ampel}`)} />
        </div>
      )}
      {kopf === null && <p className="text-sm text-[var(--color-text-secondary)]">{t('inhalte.thema.unbekannt')}</p>}
      {liste.length === 0 ? (
        <EmptyState icon="🧭" title={t('inhalte.thema.leer')} description={t('inhalte.lsa.leerText')} />
      ) : (
        <EdvanceCard className="overflow-hidden p-0">
          <Gruppe titel={t('inhalte.thema.pflicht')} satz={t('inhalte.thema.pflichtSatz', { bereit: bereit(p), gesamt: p.length })} liste={p} />
          <Gruppe titel={t('inhalte.thema.tiefe')} satz={t('inhalte.thema.tiefeSatz', { bereit: bereit(ti), gesamt: ti.length })} liste={ti} />
        </EdvanceCard>
      )}
    </div>
  )
}

export function PruefzielDetail({ zielKey }: { zielKey: string }): JSX.Element {
  const { t } = useTranslation('admin')
  const [bereiche, setBereiche] = useState<InhaltePruefzielBereich[] | null>(null)
  const [fehler, setFehler] = useState(false)
  useEffect(() => {
    void getLsaPruefziel(zielKey).then((r) => {
      setFehler(r.error !== null)
      setBereiche(r.data ?? [])
    })
  }, [zielKey])
  if (fehler) return <EmptyState icon="⚠️" title={t('inhalte.ladeFehler')} description={t('inhalte.ladeFehlerText')} />
  if (!bereiche) return <LoadingPulse type="card" />
  const kopf = bereiche.find((b) => b.bereich === null)
  return (
    <div className="flex flex-col gap-4">
      {kopf && (
        <div className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <span>{t('inhalte.klasseTag', { klasse: 10 })} · {t('inhalte.lsa.msaFenster')} · {t('inhalte.lsa.msaWirkung')}</span>
          <Ampel farbe={kopf.ampel === 'vollstaendig' ? 'gut' : 'handeln'} text={t(`inhalte.lsa.ampel.${kopf.ampel}`)}
            unter={kopf.ampel === 'vollstaendig' ? undefined : t('inhalte.lsa.warum.kompFehlt', { count: kopf.komp_teil + kopf.komp_offen })} />
        </div>
      )}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        {bereiche.filter((b) => b.bereich !== null).map((b) => {
          const gesamt = b.komp_bereit + b.komp_teil + b.komp_offen
          return (
            <EdvanceCard key={b.bereich} className="flex flex-col gap-2">
              <span><EdvanceBadge variant={b.komp_bereit === gesamt ? 'success' : b.komp_bereit ? 'warning' : 'muted'}>
                {t('inhalte.ziel.bereitVon', { bereit: b.komp_bereit, gesamt })}</EdvanceBadge></span>
              <h3 className="text-sm font-semibold text-[var(--color-text-primary)]">{t(`inhalte.ziel.bereich.${b.bereich}`, { defaultValue: b.bereich })}</h3>
              <Stapel label={t('inhalte.lsa.kompetenzenZahl', { bereit: b.komp_bereit, teil: b.komp_teil, offen: b.komp_offen })}
                teile={[{ wert: b.komp_bereit, farbe: 'gut' }, { wert: b.komp_teil, farbe: 'achtung' }, { wert: b.komp_offen, farbe: 'offen' }]} />
              <dl className="flex flex-col text-sm">
                {[
                  [t('inhalte.ziel.kompetenzen'), t('inhalte.lsa.kompetenzenZahl', { bereit: b.komp_bereit, teil: b.komp_teil, offen: b.komp_offen })],
                  [t('inhalte.ziel.zuLeicht'), t('inhalte.ziel.zuLeichtWert', { count: b.zu_leicht })],
                ].map(([k, v]) => (
                  <div key={k} className="flex justify-between gap-2 border-t border-[var(--color-border)] py-2">
                    <dt className="text-[var(--color-text-secondary)]">{k}</dt><dd className="tabular-nums">{v}</dd>
                  </div>
                ))}
                <div className="flex justify-between gap-2 border-t border-[var(--color-border)] py-2">
                  <dt className="text-[var(--color-text-secondary)]">{t('inhalte.ziel.naechster')}</dt>
                  <dd>{b.aufgaben_zu_pruefen > 0 ? (
                    <Link to={lenaListe({ ziel: zielKey })} className="text-[var(--color-text-link)] hover:underline">
                      {t('inhalte.ziel.rundN', { count: b.aufgaben_zu_pruefen })}</Link>
                  ) : t('inhalte.ziel.nichts')}</dd>
                </div>
              </dl>
            </EdvanceCard>
          )
        })}
      </div>
    </div>
  )
}
