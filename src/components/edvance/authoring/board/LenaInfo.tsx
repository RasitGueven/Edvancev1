// Lenas Ergebnis zu einer Aufgabe in der Item-Pflege (Entscheidungen 39, 40, 43, 44): Status mit
// "geaendert", Gruende oder Frage, geprueft von/am, Dauer, aufklappbar die Aenderungsliste mit Grund.
// Bei einer Rueckfrage: Antwort an Lena und Freigeben / Zurueckweisen / Zurueck an Lena.

import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { formatBerlinDateTime } from '@/lib/datetime'
import { aenderungText } from '@/lib/pruefung/anzeige'
import { fehlerSchluessel } from '@/lib/pruefung/texte'
import { pruefRueckfrageKlaeren, setPruefPilot } from '@/lib/supabase/pruefung'
import { GRUENDE } from '@/components/edvance/pruefen/Entscheidungsleiste'
import type { PasstNichtGrund, PruefAdminZeile, PruefRueckfrageAktion } from '@/types'

type Props = {
  taskId: string
  zeile: PruefAdminZeile | undefined
  fehlbildName: (slug: string) => string
  onReload: () => void
}

export function LenaInfo({ taskId, zeile, fehlbildName, onReload }: Props): JSX.Element | null {
  const { t, i18n } = useTranslation('authoring')
  const { t: tp } = useTranslation('pruefen')
  const [auf, setAuf] = useState(false)
  const [antwort, setAntwort] = useState('')
  const [gruende, setGruende] = useState<PasstNichtGrund[]>([])
  const [busy, setBusy] = useState(false)
  const [meldung, setMeldung] = useState<string | null>(null)
  if (!zeile) return null

  const klaeren = async (aktion: PruefRueckfrageAktion): Promise<void> => {
    if (aktion === 'zurueckweisen' && gruende.length === 0) return setMeldung(t('lena.fehltGrund'))
    setBusy(true)
    setMeldung(null)
    const res = await pruefRueckfrageKlaeren(taskId, aktion, antwort, aktion === 'zurueckweisen' ? gruende : undefined)
    setBusy(false)
    if (res.error) return setMeldung(res.error.code === 'P0001' ? res.error.message : tp(fehlerSchluessel(res.error) ?? 'fehlermeldung.allgemein'))
    onReload()
  }
  const pilot = async (an: boolean): Promise<void> => {
    const res = await setPruefPilot(taskId, an)
    if (res.error) setMeldung(res.error.message)
    else onReload()
  }

  const aenderungen = zeile.aenderungen ?? []
  const namen = { fehlbild: fehlbildName, fertigkeit: (k: string) => k, option: (id: string) => `${id})` }
  const status = zeile.lena_status === 'passt' && zeile.geaendert ? tp('status.passtGeaendert') : tp(`status.${zeile.lena_status}`)

  return (
    <div className="flex flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3 text-xs text-[var(--color-text-secondary)]">
      <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
        {zeile.ausschluss ? (
          <span className="font-semibold text-[var(--color-warning)]">
            {t('lena.nichtBeiLena', { grund: t(`lena.ausschluss.${zeile.ausschluss}`) })}
          </span>
        ) : (
          <span className="font-semibold text-[var(--color-text-primary)]">{t('lena.status', { status })}</span>
        )}
        {zeile.geprueft_am && (
          <span>{t('lena.geprueft', { wer: zeile.geprueft_von ?? '—', am: formatBerlinDateTime(zeile.geprueft_am, i18n.language) })}</span>
        )}
        {zeile.dauer_sek !== null && <span>{t('lena.dauer', { n: zeile.dauer_sek })}</span>}
        <label className="flex min-h-[44px] items-center gap-2">
          <input type="checkbox" className="h-4 w-4" checked={zeile.pilot} onChange={(e) => void pilot(e.target.checked)} />
          {t('lena.pilot')}
        </label>
        {!zeile.ausschluss || !['vera8', 'inaktiv', 'typ'].includes(zeile.ausschluss) ? (
          <Link to={`/coach/pruefen/${taskId}`} className="min-h-[44px] content-center text-[var(--color-text-link)] hover:underline">
            {t('lena.inPruefansicht')}
          </Link>
        ) : null}
      </div>
      {zeile.entscheidung === 'passt_nicht' && zeile.gruende?.length ? (
        <span>{t('lena.gruende', { gruende: zeile.gruende.map((g) => tp(`gruende.${g}`)).join(', ') })}</span>
      ) : null}
      {zeile.notiz && (
        <span>{zeile.entscheidung === 'unsicher' ? t('lena.frage', { frage: zeile.notiz }) : t('lena.notiz', { notiz: zeile.notiz })}</span>
      )}
      {zeile.antwort && <span>{t('lena.antwortTeam', { antwort: zeile.antwort })}</span>}
      {aenderungen.length > 0 && (
        <div className="flex flex-col gap-1">
          <button type="button" onClick={() => setAuf((a) => !a)} className="min-h-[44px] self-start text-[var(--color-text-link)] hover:underline">
            {auf ? t('lena.aenderungenVerbergen') : t('lena.aenderungenZeigen', { count: aenderungen.length })}
          </button>
          {auf && (
            <ul className="list-disc pl-5">
              {aenderungen.map((a, i) => <li key={i}>{aenderungText(tp, a, namen)}</li>)}
              {zeile.aenderung_grund && <li className="list-none">{t('lena.grund', { grund: zeile.aenderung_grund })}</li>}
            </ul>
          )}
        </div>
      )}
      {zeile.lena_status === 'unsicher' && (
        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-2">
          <label htmlFor={`antwort-${taskId}`}>{t('lena.antwortLabel')}</label>
          <textarea id={`antwort-${taskId}`} rows={2} value={antwort} placeholder={t('lena.antwortPlatzhalter')}
            onChange={(e) => setAntwort(e.target.value)}
            className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-2 text-sm" />
          <div className="flex flex-wrap gap-2">
            {GRUENDE.map((g) => {
              const an = gruende.includes(g)
              return (
                <button key={g} type="button" aria-pressed={an} onClick={() => setGruende(an ? gruende.filter((x) => x !== g) : [...gruende, g])}
                  className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-3',
                    an ? 'border-[var(--color-destructive)] text-[var(--color-destructive)]' : 'border-[var(--color-border)]')}>
                  {tp(`gruende.${g}`)}
                </button>
              )
            })}
          </div>
          <div className="flex flex-wrap gap-2">
            <Button size="sm" loading={busy} onClick={() => void klaeren('freigeben')}>{t('lena.freigeben')}</Button>
            <Button size="sm" variant="destructive" disabled={busy} onClick={() => void klaeren('zurueckweisen')}>{t('lena.zurueckweisen')}</Button>
            <Button size="sm" variant="outline" disabled={busy} onClick={() => void klaeren('an_lena')}>{t('lena.anLena')}</Button>
          </div>
        </div>
      )}
      {meldung && <p role="alert" className="text-[var(--color-destructive)]">{meldung}</p>}
    </div>
  )
}
