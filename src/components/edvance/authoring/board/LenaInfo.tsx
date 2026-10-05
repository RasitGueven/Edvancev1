// Lenas Ergebnis zu einer Aufgabe in der Item-Pflege (Entscheidungen 39, 40, 43, 44): Status mit
// "geaendert", Gruende oder Frage, geprueft von/am, Dauer, aufklappbar die Aenderungsliste mit Grund.
// Bei einer Rueckfrage: Antwort an Lena und Klaerung (RueckfrageKlaeren).

import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { formatBerlinDateTime } from '@/lib/datetime'
import { aenderungText } from '@/lib/pruefung/anzeige'
import { setzePilot } from '@/lib/supabase/pruefungAdmin'
import type { PruefAdminZeile } from '@/types'
import { RueckfrageKlaeren } from './RueckfrageKlaeren'

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
  const [meldung, setMeldung] = useState<string | null>(null)
  if (!zeile) return null

  const pilot = async (an: boolean): Promise<void> => {
    const res = await setzePilot(taskId, an)
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
      {zeile.lena_status === 'unsicher' && <RueckfrageKlaeren taskId={taskId} onReload={onReload} />}
      {meldung && <p role="alert" className="text-[var(--color-destructive)]">{meldung}</p>}
    </div>
  )
}
