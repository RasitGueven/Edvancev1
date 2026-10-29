// /coach/pruefen/bauformen/:bauformId: Lena prueft eine Bauform als Ganzes (Konzept §6): Steckbrief, sechs Beispiele wie
// auf dem Tablet (je Stufe mindestens eines), „Andere Beispiele“, Fehlbilder mit Rueckmeldungen, Hinweise,
// Loesungsbeispiel, Befund von Pruefmaschine und Blindloeser; Entscheidung passt | unsicher | passt nicht (Tasten 1/2/3).
// M1: oben „gebraucht in Session n“ aus dem Standardplan (bauform_pruef_plan).
import { useCallback, useEffect, useRef, useState, type JSX } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { BauformBeispiel } from '@/components/edvance/pruefen/bauform/BauformBeispiel'
import { BauformEntscheidung } from '@/components/edvance/pruefen/bauform/BauformEntscheidung'
import { BauformSteckbrief } from '@/components/edvance/pruefen/bauform/BauformSteckbrief'
import { bauformPruefen, getBauformDetail, getBauformPlan } from '@/lib/supabase/bauformPruefung'
import type { BauformDetail, BauformEntscheidung as Entscheidung, BauformPlanZeile } from '@/types/bauformPruefung'

export function BauformDetailPage(): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const { bauformId = '' } = useParams()
  const [seed, setSeed] = useState(0)
  const [detail, setDetail] = useState<BauformDetail | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [plan, setPlan] = useState<BauformPlanZeile | null>(null)
  const start = useRef(Date.now())

  useEffect(() => {
    void getBauformDetail(bauformId, seed).then((r) => {
      setDetail(r.data)
      setFehler(r.error?.message ?? null)
    })
  }, [bauformId, seed])

  // Ohne Plan fehlt nur die Zeile „gebraucht in Session n“.
  useEffect(() => {
    void getBauformPlan().then((r) => setPlan(r.data?.find((z) => z.bauform_id === bauformId) ?? null))
  }, [bauformId])

  const entscheide = useCallback(async (e: Entscheidung, gruende: string[], notiz: string | null): Promise<void> => {
    if (!detail || busy) return
    setBusy(true)
    const r = await bauformPruefen(detail.bauform_id, detail.version, e, gruende, notiz, Math.round((Date.now() - start.current) / 1000))
    setBusy(false)
    if (r.error) {
      setMeldung(r.error.code === 'ED409' ? t('entscheidung.geaendert') : t('entscheidung.fehler', { message: r.error.message }))
      return
    }
    setMeldung(t('entscheidung.gespeichert', { status: t(`status.${r.data?.status ?? ''}`) }))
    setDetail({ ...detail, status: (r.data?.status ?? detail.status) as BauformDetail['status'] })
  }, [detail, busy, t])

  if (fehler) return <EmptyState icon="🔒" title={t('liste.titel')} description={fehler} />
  if (!detail) return <LoadingPulse type="card" />
  const offen = detail.status === 'zur_pruefung' || detail.status === 'rueckfrage'
  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={`${detail.schluessel} · ${detail.skill_label}`} satz={detail.steckbrief.text ?? ''}
        zurueckZu="/coach/pruefen/bauformen" zurueckLabel={t('detail.zurueck')}
        aktionen={<EdvanceBadge variant={offen ? 'warning' : 'muted'}>{t(`status.${detail.status}`)} · {t('liste.version', { version: detail.version })}</EdvanceBadge>} />
      {plan && (
        <p className="text-sm font-semibold text-[var(--color-text-primary)]">
          {plan.session_nr != null ? t('plan.gebrauchtIn', { nr: plan.session_nr }) : t('plan.gebrauchtVoraussetzung')}
          {plan.kernidee_titel ? ` · ${plan.kernidee_titel}` : ''}
        </p>
      )}
      {meldung && <p role="status" className="text-sm text-[var(--color-text-secondary)]">{meldung}</p>}
      <BauformSteckbrief detail={detail} />
      <section className="flex flex-col gap-4">
        <div className="flex items-center justify-between gap-4">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">{t('detail.beispiele')}</h2>
          <Button variant="outline" onClick={() => setSeed((s) => s + 1)}>{t('detail.andere')}</Button>
        </div>
        {detail.beispiele.length === 0 ? (
          <EmptyState icon="🧩" title={t('detail.keineBeispiele')} description={t('liste.leerSatz')} />
        ) : (
          detail.beispiele.map((b) => <BauformBeispiel key={b.task_id} beispiel={b} />)
        )}
      </section>
      <BauformEntscheidung aktiv={offen} busy={busy} onEntscheide={(e, g, n) => void entscheide(e, g, n)} />
    </div>
  )
}
