// /coach/pruefen/bauformen (Lena und Admin, Pruefrecht): Reiter Bauformen | Auffaellig | Pruefragen (Sessionreihe 1, A5).
// M1: Muster nach Sessions gruppiert (bauform_pruef_plan), Plan Standard oder eines Kindes mit aktiver Reihe (?kind=),
// Status-Filter innerhalb der Gruppen (?filter=). Admins geben je Session oder die ganze Reihe frei (bauform_freigeben).
import { useCallback, useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { AuffaelligListe } from '@/components/edvance/pruefen/bauform/AuffaelligListe'
import { PrueffragenListe } from '@/components/edvance/pruefen/bauform/PrueffragenListe'
import { MusterSessionGruppe } from '@/components/edvance/pruefen/bauform/MusterSessionGruppe'
import { MUSTER_FILTER, nachSessions, type MusterFilter } from '@/lib/pruefung/bauformPlan'
import { musterStand } from '@/lib/pruefung/bauformStand'
import { useAuth } from '@/hooks/useAuth'
import {
  aufgabeReaktivieren, bauformFreigeben, bauformReaktivieren, bauformZurUeberarbeitung, getAuffaellig, getBauformPlan,
  getPlanKinder, getPrueffragen, prueffrageEntscheiden,
} from '@/lib/supabase/bauformPruefung'
import type { AuffaelligZeile, BauformPlanZeile, PlanKind, PrueffrageZeile } from '@/types/bauformPruefung'

type Reiter = 'bauformen' | 'auffaellig' | 'prueffragen'
const REITER: Reiter[] = ['bauformen', 'auffaellig', 'prueffragen']
const REIHE = 'quadratische_funktionen_gleichungen'

export function BauformListePage(): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const navigate = useNavigate()
  const { role } = useAuth()
  const [params, setParams] = useSearchParams()
  const reiter: Reiter = REITER.includes(params.get('reiter') as Reiter) ? (params.get('reiter') as Reiter) : 'bauformen'
  const kind = params.get('kind')
  const filter: MusterFilter = MUSTER_FILTER.includes(params.get('filter') as MusterFilter) ? (params.get('filter') as MusterFilter) : 'alle'
  const [liste, setListe] = useState<BauformPlanZeile[] | null>(null)
  const [kinder, setKinder] = useState<PlanKind[]>([])
  const [auff, setAuff] = useState<AuffaelligZeile[] | null>(null)
  const [fragen, setFragen] = useState<PrueffrageZeile[] | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)

  const laden = useCallback(() => {
    void getBauformPlan(kind).then((r) => setListe(r.data ?? []))
    void getAuffaellig().then((r) => setAuff(r.data ?? []))
    void getPrueffragen().then((r) => setFragen(r.data ?? []))
  }, [kind])
  useEffect(laden, [laden])
  // Ohne Kinderliste bleibt nur der Standardplan waehlbar.
  useEffect(() => void getPlanKinder().then((r) => setKinder(r.data ?? [])), [])
  const gruppen = useMemo(() => (liste ? nachSessions(liste) : []), [liste])
  const gesamt = liste ? musterStand(liste) : null
  const setze = (key: string, wert: string | null): void => {
    const n = new URLSearchParams(params)
    if (wert) n.set(key, wert)
    else n.delete(key)
    setParams(n, { replace: true })
  }

  const nach = async (p: Promise<{ error: { message: string } | null }>): Promise<void> => {
    const r = await p
    setMeldung(r.error ? t('entscheidung.fehler', { message: r.error.message }) : t('auffaellig.erledigt'))
    laden()
  }
  const freigeben = async (schluessel?: string[]): Promise<void> => {
    const r = await bauformFreigeben(REIHE, schluessel)
    setMeldung(r.error ? t('entscheidung.fehler', { message: r.error.message }) : t('liste.freigegeben', { count: r.data ?? 0 }))
    laden()
  }

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t('liste.titel')} satz={t('liste.satz')} zurueckZu="/coach/pruefen" zurueckLabel={t('liste.zurueck')}
        aktionen={role === 'admin' ? <Button variant="outline" title={t('liste.freigebenHinweis')} onClick={() => void freigeben()}>{t('liste.freigeben')}</Button> : undefined} />
      {meldung && <p role="status" className="text-sm text-[var(--color-text-secondary)]">{meldung}</p>}
      <div role="tablist" className="flex flex-wrap gap-2">
        {REITER.map((r) => (
          <Button key={r} role="tab" aria-selected={reiter === r} variant={reiter === r ? 'default' : 'outline'}
            onClick={() => setze('reiter', r === 'bauformen' ? null : r)}>
            {t(`liste.reiter.${r}`)}
            {r === 'auffaellig' && auff && auff.length > 0 ? ` (${auff.length})` : ''}
          </Button>
        ))}
      </div>
      {reiter === 'bauformen' && (!liste ? <LoadingPulse type="card" /> : liste.length === 0 ? (
        <EmptyState icon="🧩" title={t('liste.leer')} description={t('liste.leerSatz')} />
      ) : (
        <div className="flex flex-col gap-6">
          {gesamt && (
            <p className="text-sm text-[var(--color-text-secondary)]">
              {t('plan.kopf', { geprueft: gesamt.geprueft, total: gesamt.total, frei: gesamt.freigegeben })}
            </p>
          )}
          <div className="flex flex-wrap items-center gap-2" role="group" aria-label={t('plan.umschalter')}>
            <span className="text-xs text-[var(--color-text-muted)]">{t('plan.umschalter')}</span>
            <Button variant={!kind ? 'default' : 'outline'} aria-pressed={!kind} onClick={() => setze('kind', null)}>
              {t('plan.standard')}
            </Button>
            {kinder.map((k) => (
              <Button key={k.student_id} variant={kind === k.student_id ? 'default' : 'outline'} aria-pressed={kind === k.student_id}
                onClick={() => setze('kind', k.student_id)}>
                {k.ist_test ? t('plan.testkind', { name: k.name }) : k.name}
              </Button>
            ))}
          </div>
          <div className="flex flex-wrap gap-2" role="group" aria-label={t('plan.filter.label')}>
            {MUSTER_FILTER.map((f) => (
              <Button key={f} size="sm" variant={filter === f ? 'default' : 'outline'} aria-pressed={filter === f}
                onClick={() => setze('filter', f === 'alle' ? null : f)}>
                {t(`plan.filter.${f}`, { count: f === 'alle' ? liste.length : liste.filter((b) => b.status === f).length })}
              </Button>
            ))}
          </div>
          {gruppen.every((g) => g.zeilen.every((b) => filter !== 'alle' && b.status !== filter)) && (
            <EmptyState icon="🧩" title={t('plan.keineImFilter')} description={t('plan.keineImFilterSatz')} />
          )}
          {gruppen.map((g) => (
            <MusterSessionGruppe key={g.nr ?? 'ohne'} gruppe={g} filter={filter} isAdmin={role === 'admin'}
              onOeffnen={(id) => navigate(`/coach/pruefen/bauformen/${id}`)} onFreigeben={freigeben} />
          ))}
        </div>
      ))}
      {reiter === 'auffaellig' && (!auff ? <LoadingPulse type="card" /> : (
        <AuffaelligListe zeilen={auff} onReaktivieren={(id) => void nach(aufgabeReaktivieren(id))}
          onUeberarbeiten={(id, g) => void nach(bauformZurUeberarbeitung(id, g))}
          onBauformReaktivieren={(id, g) => void nach(bauformReaktivieren(id, g))} />
      ))}
      {reiter === 'prueffragen' && (!fragen ? <LoadingPulse type="card" /> : (
        <PrueffragenListe zeilen={fragen} onEntscheide={(id, e, n) => void nach(prueffrageEntscheiden(id, e, n))} />
      ))}
    </div>
  )
}
