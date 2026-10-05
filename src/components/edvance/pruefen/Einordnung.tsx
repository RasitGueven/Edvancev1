// Pruefkarte: Einordnung (32.7) und Aenderungen (32.8).
// Fertigkeit als Auswahl mit den Gruppen "Im Thema …" und "Voraussetzungen"; darunter Thema · Klasse
// und "Baut auf"; Anforderungsbereich I/II/III mit Namen und der Marke "mittel sicher".

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { aenderungText, type Namen } from '@/lib/pruefung/anzeige'
import type { Bearbeitung } from '@/lib/pruefung/entwurf'
import type { Afb, PruefAenderung, PruefAufgabe } from '@/types'
import { GeaendertMarke, InfoTip } from './InfoTip'

const AFB: Afb[] = ['I', 'II', 'III']

type Props = {
  aufgabe: PruefAufgabe
  b: Bearbeitung
  ausgang: Bearbeitung
  fertigkeitGeaendert: boolean
  afbGeaendert: boolean
  lesend: boolean
  onChange: (b: Bearbeitung) => void
  onZurueck: (feld: 'fertigkeit' | 'afb') => void
}

export function Einordnung({ aufgabe, b, ausgang, fertigkeitGeaendert, afbGeaendert, lesend, onChange, onZurueck }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const im = aufgabe.fertigkeit_optionen.filter((o) => o.gruppe === 'thema')
  const vor = aufgabe.fertigkeit_optionen.filter((o) => o.gruppe === 'voraussetzung')
  const f = aufgabe.fertigkeit
  const zeigeKontext = f && f.key === b.skill_key
  return (
    <section className="flex flex-col gap-4 border-t border-[var(--color-border)] pt-6">
      <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('einordnung.titel')}</h3>
      <div className="grid gap-2 sm:grid-cols-[170px_minmax(0,1fr)]">
        <label htmlFor="pruef-fertigkeit" className="flex flex-col items-start gap-1 text-sm text-[var(--color-text-secondary)]">
          <span className="inline-flex items-center gap-2">{t('einordnung.fertigkeit')} <InfoTip schluessel="fert" /></span>
          <GeaendertMarke an={fertigkeitGeaendert && !lesend} onZurueck={() => onZurueck('fertigkeit')} />
        </label>
        <div className="flex min-w-0 flex-col gap-1">
          <select id="pruef-fertigkeit" disabled={lesend} value={b.skill_key ?? ''}
            onChange={(e) => onChange({ ...b, skill_key: e.target.value })}
            className="min-h-[44px] w-full min-w-0 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm">
            <optgroup label={t('einordnung.imThema', { thema: aufgabe.kopf.thema_label ?? '' })}>
              {im.map((o) => <option key={o.key} value={o.key}>{o.label}</option>)}
            </optgroup>
            {vor.length > 0 && (
              <optgroup label={t('einordnung.voraussetzungen')}>
                {vor.map((o) => <option key={o.key} value={o.key}>{o.label}</option>)}
              </optgroup>
            )}
          </select>
          {zeigeKontext && (
            <p className="text-xs leading-relaxed text-[var(--color-text-secondary)]">
              <span className="text-[var(--color-text-tertiary)]">{t('einordnung.thema')}</span> {f.thema_label}
              {f.stufe && <> · {t(`stufe.${f.stufe}`)}</>}
              {f.voraussetzungen.length > 0 && (
                <><br /><span className="text-[var(--color-text-tertiary)]">{t('einordnung.bautAuf')}</span> {f.voraussetzungen.join(' · ')}</>
              )}
            </p>
          )}
          {b.skill_key !== ausgang.skill_key && (
            <p className="text-xs text-[var(--color-primary)]">{t('einordnung.neueFertigkeit')}</p>
          )}
        </div>
      </div>
      <div className="grid gap-2 sm:grid-cols-[170px_minmax(0,1fr)]">
        <span className="flex flex-col items-start gap-1 text-sm text-[var(--color-text-secondary)]">
          <span className="inline-flex items-center gap-2">{t('einordnung.afb')} <InfoTip schluessel="afb" /></span>
          {!afbGeaendert && aufgabe.afb_sicher === 'mittel' && (
            <span className="inline-flex items-center gap-1">
              <span className="rounded-[var(--radius-sm)] bg-[var(--color-warning-light)] px-2 text-xs font-semibold text-[var(--color-warning)]">
                {t('einordnung.mittelSicher')}
              </span>
              <InfoTip schluessel="sicher" />
            </span>
          )}
          <GeaendertMarke an={afbGeaendert && !lesend} onZurueck={() => onZurueck('afb')} />
        </span>
        <div className="flex flex-wrap items-center gap-3">
          <div role="group" aria-label={t('einordnung.afb')} className="inline-flex overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)]">
            {AFB.map((x) => (
              <button key={x} type="button" disabled={lesend} aria-pressed={b.afb === x} title={t(`einordnung.afbName.${x}`)}
                onClick={() => onChange({ ...b, afb: x })}
                className={cn('min-h-[44px] min-w-[48px] border-l border-[var(--color-border)] px-3 text-sm first:border-l-0',
                  b.afb === x ? 'bg-[var(--color-primary)] font-semibold text-white' : 'bg-[var(--color-bg-surface)] hover:bg-[var(--color-bg-subtle)]')}>
                {x}
              </button>
            ))}
          </div>
          {b.afb && <span className="text-xs text-[var(--color-text-tertiary)]">{t(`einordnung.afbName.${b.afb}`)}</span>}
        </div>
      </div>
    </section>
  )
}

type AenderungenProps = {
  aenderungen: PruefAenderung[]
  namen: Namen
  mc: boolean
  grund: string
  grundPflicht: boolean
  onGrund: (g: string) => void
}

export function AenderungenBox({ aenderungen, namen, mc, grund, grundPflicht, onGrund }: AenderungenProps): JSX.Element | null {
  const { t } = useTranslation('pruefen')
  if (aenderungen.length === 0) return null
  return (
    <section className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-primary-light)] bg-[var(--color-primary-light)] p-4">
      <h3 className="text-sm font-semibold text-[var(--color-primary)]">{t('aenderungen.titel', { count: aenderungen.length })}</h3>
      <ul className="list-disc pl-5 text-sm text-[var(--color-text-secondary)]">
        {aenderungen.map((a, i) => <li key={i}>{aenderungText(t, a, namen, mc)}</li>)}
      </ul>
      <label htmlFor="pruef-warum" className="text-xs text-[var(--color-text-secondary)]">
        {t('aenderungen.warum')}{' '}
        <span className="text-[var(--color-text-tertiary)]">{grundPflicht ? t('aenderungen.pflicht') : t('aenderungen.optional')}</span>
      </label>
      <input id="pruef-warum" value={grund} onChange={(e) => onGrund(e.target.value)} placeholder={t('aenderungen.warumPlatzhalter')}
        className="min-h-[44px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm" />
    </section>
  )
}
