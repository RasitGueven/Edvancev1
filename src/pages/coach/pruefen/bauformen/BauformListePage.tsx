// /coach/pruefen/bauformen (Lena und Admin, Pruefrecht): Reiter Bauformen | Auffaellig | Pruefragen (Sessionreihe 1, A5).
// Admins geben die Reihe gesammelt frei (bauform_freigeben).
import { useCallback, useEffect, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { AuffaelligListe } from '@/components/edvance/pruefen/bauform/AuffaelligListe'
import { PrueffragenListe } from '@/components/edvance/pruefen/bauform/PrueffragenListe'
import { useAuth } from '@/hooks/useAuth'
import {
  aufgabeReaktivieren, bauformFreigeben, bauformReaktivieren, bauformZurUeberarbeitung, getAuffaellig, getBauformListe,
  getPrueffragen, prueffrageEntscheiden,
} from '@/lib/supabase/bauformPruefung'
import type { AuffaelligZeile, BauformListenZeile, PrueffrageZeile } from '@/types/bauformPruefung'

type Reiter = 'bauformen' | 'auffaellig' | 'prueffragen'
const REITER: Reiter[] = ['bauformen', 'auffaellig', 'prueffragen']
const REIHE = 'quadratische_funktionen_gleichungen'

export function BauformListePage(): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const navigate = useNavigate()
  const { role } = useAuth()
  const [params, setParams] = useSearchParams()
  const reiter: Reiter = REITER.includes(params.get('reiter') as Reiter) ? (params.get('reiter') as Reiter) : 'bauformen'
  const [liste, setListe] = useState<BauformListenZeile[] | null>(null)
  const [auff, setAuff] = useState<AuffaelligZeile[] | null>(null)
  const [fragen, setFragen] = useState<PrueffrageZeile[] | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)

  const laden = useCallback(() => {
    void getBauformListe().then((r) => setListe(r.data ?? []))
    void getAuffaellig().then((r) => setAuff(r.data ?? []))
    void getPrueffragen().then((r) => setFragen(r.data ?? []))
  }, [])
  useEffect(laden, [laden])

  const nach = async (p: Promise<{ error: { message: string } | null }>): Promise<void> => {
    const r = await p
    setMeldung(r.error ? t('entscheidung.fehler', { message: r.error.message }) : t('auffaellig.erledigt'))
    laden()
  }
  const freigeben = async (): Promise<void> => {
    const r = await bauformFreigeben(REIHE)
    setMeldung(r.error ? t('entscheidung.fehler', { message: r.error.message }) : t('liste.freigegeben', { count: r.data ?? 0 }))
    laden()
  }

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t('liste.titel')} satz={t('liste.satz')} zurueckZu="/coach/pruefen" zurueckLabel={t('liste.zurueck')}
        aktionen={role === 'admin' ? <Button title={t('liste.freigebenHinweis')} onClick={() => void freigeben()}>{t('liste.freigeben')}</Button> : undefined} />
      {meldung && <p role="status" className="text-sm text-[var(--color-text-secondary)]">{meldung}</p>}
      <div role="tablist" className="flex flex-wrap gap-2">
        {REITER.map((r) => (
          <Button key={r} role="tab" aria-selected={reiter === r} variant={reiter === r ? 'default' : 'outline'}
            onClick={() => setParams(r === 'bauformen' ? {} : { reiter: r }, { replace: true })}>
            {t(`liste.reiter.${r}`)}
            {r === 'auffaellig' && auff && auff.length > 0 ? ` (${auff.length})` : ''}
          </Button>
        ))}
      </div>
      {reiter === 'bauformen' && (!liste ? <LoadingPulse type="card" /> : liste.length === 0 ? (
        <EmptyState icon="🧩" title={t('liste.leer')} description={t('liste.leerSatz')} />
      ) : (
        <ul className="flex flex-col gap-4">
          {liste.map((b) => (
            <li key={b.bauform_id}>
              <button type="button" onClick={() => navigate(`/coach/pruefen/bauformen/${b.bauform_id}`)} className="w-full text-left">
                <EdvanceCard className="flex flex-wrap items-center gap-3 hover:shadow-md">
                  <span className="text-base font-semibold text-[var(--color-text-primary)]">{b.schluessel}</span>
                  <span className="flex-1 text-sm text-[var(--color-text-secondary)]">{b.skill_label} · {b.format}</span>
                  <span className="text-xs text-[var(--color-text-muted)]">{t('liste.version', { version: b.version })} · {t('liste.gruen', { count: b.gruen })}</span>
                  <EdvanceBadge variant={b.status === 'zur_pruefung' ? 'warning' : 'muted'}>{t(`status.${b.status}`)}</EdvanceBadge>
                </EdvanceCard>
              </button>
            </li>
          ))}
        </ul>
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
