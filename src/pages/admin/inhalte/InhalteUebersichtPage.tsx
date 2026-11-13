// IU-1 U2: Admin-Seite „Inhalte-Übersicht“ (Bauauftrag IU-1, Dummy docs/inhalte/iu1/referenz/). Zwei Reiter, Filter
// Klasse, Details für Thema, Prüfziel und Reihe. Der Zustand steht in der Adresse (teilbar); Zurück aus dem Detail
// behält Reiter und Klasse. Beim ersten Laden frischt die Seite die Zwischenspeicher auf (inhalte_auffrischen).
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useSearchParams } from 'react-router-dom'

import { LoadingPulse, Reiterleiste } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { KLASSEN, ansichtAusSuche, sucheAusAnsicht, type InhalteReiter } from '@/lib/inhalte/uebersicht'
import { frischeInhalte, getLsaPruefziel, getSessionReihen } from '@/lib/supabase/inhalte'
import type { InhalteReihe } from '@/types/inhalte'

import { OptionChips } from '../intake/OptionChips'
import { LsaReiter } from './LsaReiter'
import { PruefzielDetail, ThemaDetail, useThemaKopf } from './LsaDetail'
import { ReiheDetail } from './ReiheDetail'
import { ReihenReiter, useReihenTitel } from './ReihenReiter'

function ThemaSeite({ themaKey, zurueck }: { themaKey: string; zurueck: string }): JSX.Element {
  const { t } = useTranslation('admin')
  const kopf = useThemaKopf(themaKey)
  return (
    <div className="flex flex-col gap-6">
      <PageHeader rubrik={t('inhalte.titel')} titel={kopf?.titel ?? themaKey} zurueckZu={zurueck} zurueckLabel={t('inhalte.thema.zurueck')} />
      <ThemaDetail themaKey={themaKey} kopf={kopf} />
    </div>
  )
}

function ZielSeite({ zielKey, zurueck }: { zielKey: string; zurueck: string }): JSX.Element {
  const { t } = useTranslation('admin')
  const [titel, setTitel] = useState<string>(zielKey)
  useEffect(() => {
    void getLsaPruefziel(zielKey).then((r) => r.data?.[0] && setTitel(r.data[0].titel))
  }, [zielKey])
  return (
    <div className="flex flex-col gap-6">
      <PageHeader rubrik={t('inhalte.titel')} titel={titel} zurueckZu={zurueck} zurueckLabel={t('inhalte.thema.zurueck')} />
      <PruefzielDetail zielKey={zielKey} />
    </div>
  )
}

function ReiheSeite({ reihe, zurueck }: { reihe: string; zurueck: string }): JSX.Element {
  const { t } = useTranslation('admin')
  const titel = useReihenTitel()
  const [kopf, setKopf] = useState<InhalteReihe | null | undefined>(undefined)
  useEffect(() => {
    void getSessionReihen(null).then((r) => setKopf(r.data?.find((x) => x.reihe === reihe) ?? null))
  }, [reihe])
  return (
    <div className="flex flex-col gap-6">
      <PageHeader rubrik={t('inhalte.titel')} titel={kopf ? titel(kopf) : reihe} zurueckZu={zurueck}
        zurueckLabel={t('inhalte.session.zurueck')} />
      <ReiheDetail reihe={reihe} kopf={kopf} />
    </div>
  )
}

export function InhalteUebersichtPage(): JSX.Element {
  const { t } = useTranslation('admin')
  const [suche, setSuche] = useSearchParams()
  const a = ansichtAusSuche(suche)
  const [frisch, setFrisch] = useState(false)

  useEffect(() => {
    // Fehler beim Auffrischen sind nicht schlimm: die Funktionen rechnen dann live.
    void frischeInhalte().finally(() => setFrisch(true))
  }, [])

  const liste = `/admin/inhalte?${sucheAusAnsicht({ reiter: a.reiter, klasse: a.klasse }).toString()}`
  const oeffne = (detail: { thema?: string; ziel?: string; reihe?: string }): void =>
    setSuche(sucheAusAnsicht({ reiter: a.reiter, klasse: a.klasse, ...detail }))

  if (!frisch) return <LoadingPulse type="list" lines={6} />
  if (a.thema) return <ThemaSeite themaKey={a.thema} zurueck={liste} />
  if (a.ziel) return <ZielSeite zielKey={a.ziel} zurueck={liste} />
  if (a.reihe) return <ReiheSeite reihe={a.reihe} zurueck={liste} />

  return (
    <div className="flex flex-col gap-6">
      <PageHeader rubrik={t('nav.gruppe.inhalte')} titel={t('inhalte.titel')} satz={t(`inhalte.satz.${a.reiter}`)} />
      <Reiterleiste<InhalteReiter> label={t('inhalte.reiter.label')} aktiv={a.reiter}
        reiter={[{ key: 'lsa', titel: t('inhalte.reiter.lsa') }, { key: 'reihen', titel: t('inhalte.reiter.reihen') }]}
        onWechsel={(r) => setSuche(sucheAusAnsicht({ reiter: r, klasse: a.klasse }))} />
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('inhalte.filter.klasse')}</span>
        <OptionChips<number> selected={[a.klasse ?? 0]}
          options={[{ value: 0, label: t('inhalte.filter.alle') }, ...KLASSEN.map((k) => ({ value: k as number, label: t('inhalte.filter.klasseN', { klasse: k }) }))]}
          onToggle={(k) => setSuche(sucheAusAnsicht({ reiter: a.reiter, klasse: k || null }))} />
      </div>
      {a.reiter === 'lsa' ? (
        <LsaReiter klasse={a.klasse} onThema={(thema) => oeffne({ thema })} onZiel={(ziel) => oeffne({ ziel })} />
      ) : (
        <ReihenReiter klasse={a.klasse} onReihe={(reihe) => oeffne({ reihe })} />
      )}
    </div>
  )
}
