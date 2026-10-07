// /coach/pruefen/erklaerungen/:kernideeId (Lena) und /admin/pruefen/erklaerungen/:kernideeId (Admin):
// eine Kernidee als Ganzes (Bauauftrag L6, Punkte 6 und 7). Varianten als Reiter mit Kinderansicht und
// Entwurf, Checks mit Kinderansicht und Link zur Aufgaben-Pruefung, Protokoll. Lena entscheidet in der
// Leiste unten (1/2/3 wie bei den Aufgaben), der Admin gibt frei oder nimmt zurueck.

import { useEffect, useState, type JSX } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceBadge } from '@/components/edvance/EdvanceBadge'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { EntscheidungsMeldung } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { ErklaerAdminBereich } from '@/components/edvance/pruefen/erklaer/ErklaerAdminBereich'
import { ErklaerChecks } from '@/components/edvance/pruefen/erklaer/ErklaerChecks'
import { ErklaerLeiste, type ErklaerPanel } from '@/components/edvance/pruefen/erklaer/ErklaerLeiste'
import { ErklaerProtokoll } from '@/components/edvance/pruefen/erklaer/ErklaerProtokoll'
import { VariantenAnsicht } from '@/components/edvance/pruefen/erklaer/VariantenAnsicht'
import { STATUS_VARIANTE } from '@/lib/pruefung/erklaerAnzeige'
import { aufgabenPfad, erklaerBasis, erklaerFehlerSchluessel, type ErklaerModus } from '@/lib/pruefung/erklaerTexte'
import type { ErklaerEntscheidung } from '@/types/erklaerPruefung'
import { useErklaerDetail } from './useErklaerDetail'

export function ErklaerDetailPage({ modus }: { modus: ErklaerModus }): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const { kernideeId } = useParams<{ kernideeId: string }>()
  const d = useErklaerDetail(kernideeId)
  const [panel, setPanel] = useState<ErklaerPanel>(null)
  const [meldung, setMeldung] = useState<ErklaerEntscheidung | 'freigegeben' | 'zurueck' | 'antwort' | null>(null)
  const admin = modus === 'admin'
  const detail = d.detail
  const k = detail?.kernidee

  const keineErklaerung = !!detail && !detail.schritte.some((s) => s.art === 'erklaerung')
  const nurFrei = k?.status === 'freigegeben' && !!detail && detail.schritte.every((s) => s.status !== 'entwurf')
  const passtGesperrt = keineErklaerung ? t('leiste.keineErklaerung') : nurFrei ? t('leiste.gesperrtFreigegeben') : null
  const nichtGesperrt = k?.status === 'freigegeben' ? t('leiste.nichtFreigegeben') : null

  const entscheiden = async (e: ErklaerEntscheidung, gruende?: Parameters<typeof d.pruefen>[1], notiz?: string): Promise<void> => {
    if (await d.pruefen(e, gruende, notiz)) {
      setPanel(null)
      setMeldung(e)
    }
  }

  useEffect(() => {
    if (admin || !detail) return
    const taste = (e: KeyboardEvent): void => {
      const el = document.activeElement as HTMLElement | null
      if (el && ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName)) return
      if (e.key === '1' && !nichtGesperrt) setPanel((p) => (p === 'nicht' ? null : 'nicht'))
      if (e.key === '2') setPanel((p) => (p === 'unsicher' ? null : 'unsicher'))
      if (e.key === '3' && !passtGesperrt && !d.arbeitet) void entscheiden('passt')
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  })

  useEffect(() => {
    if (!meldung) return
    const timer = setTimeout(() => setMeldung(null), 5000)
    return () => clearTimeout(timer)
  }, [meldung])

  if (d.ladeFehler) {
    return <EmptyState icon="🔒" title={t('detail.fehlerTitel')} description={t(erklaerFehlerSchluessel(d.ladeFehler))} />
  }
  if (!detail || !k) return <LoadingPulse type="card" />

  const fehlerText = d.fehler ? t(d.fehler.schluessel) : null
  const stand = admin && k.rueckfrage ? 'rueckfrage' : k.stand

  return (
    <>
      <div className={admin ? 'flex flex-col gap-8' : 'flex flex-col gap-8 pb-40'}>
        <PageHeader rubrik={t('detail.rubrik', { skill: k.skill_label ?? k.skill_key, nr: k.nr, von: Math.max(k.kernideen, k.nr) })}
          titel={k.titel} zurueckZu={erklaerBasis(modus)} zurueckLabel={t('detail.zurueck')}
          satz={t('detail.satz', { quelle: t(`detail.quelle.${k.quelle}`), stand: t(`stand.${stand}`) })} />
        <div className="flex flex-wrap items-center gap-2">
          <EdvanceBadge variant={STATUS_VARIANTE[k.status]}>{t(`status.${k.status}`)}</EdvanceBadge>
          {k.rueckfrage && <EdvanceBadge variant="warning">{t('stand.rueckfrage')}</EdvanceBadge>}
        </div>
        {admin && (
          <ErklaerAdminBereich detail={detail} arbeitet={d.arbeitet} fehler={fehlerText} fehltAusFehler={d.fehler?.fehlt ?? null}
            onFreigeben={() => void d.freigeben().then((ok) => ok && setMeldung('freigegeben'))}
            onZuruecknehmen={(grund) => void d.zuruecknehmen(grund).then((ok) => ok && setMeldung('zurueck'))}
            onAntworten={(antwort) => void d.antworten(antwort).then((ok) => ok && setMeldung('antwort'))} />
        )}
        <VariantenAnsicht detail={detail} gesperrt={k.status === 'freigegeben' ? t('editor.gesperrtFreigegeben') : null}
          onSpeichern={async (s, inhalt, slugs) => {
            const fehler = await d.schrittSpeichern(s, inhalt, slugs)
            return fehler ? t(fehler) : null
          }} />
        <ErklaerChecks detail={detail} aufgabenPfad={(id) => aufgabenPfad(modus, id)} />
        <ErklaerProtokoll zeilen={detail.protokoll} />
      </div>
      {!admin && (
        <ErklaerLeiste panel={panel} setPanel={setPanel} info={t(`leiste.info.${k.stand}`)}
          passtGesperrt={passtGesperrt} nichtGesperrt={nichtGesperrt} arbeitet={d.arbeitet}
          fehler={fehlerText}
          onPasst={() => void entscheiden('passt')}
          onNicht={(gruende, notiz) => void entscheiden('passt_nicht', gruende, notiz)}
          onUnsicher={(frage) => void entscheiden('unsicher', undefined, frage)} />
      )}
      {meldung && (
        <EntscheidungsMeldung text={t(`meldung.${meldung}`)} onZu={() => setMeldung(null)}
          onRueckgaengig={!admin && meldung !== 'zurueckgenommen' ? () => void entscheiden('zurueckgenommen') : undefined} />
      )}
    </>
  )
}
