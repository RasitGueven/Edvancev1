// Block „Lenas Ergebnis“ ueber der Pruefkarte (Bauauftrag B 5). Feste Reihenfolge: Status-Marke; geprueft von/am,
// Dauer; Frage bzw. Gruende und „Was genau?“; Antwort vom Team; Lenas Aenderungen aus ihrer letzten
// task_pruefungen-Zeile, ab drei Eintraegen zugeklappt. Ohne Bewertung: „Lena hat diese Aufgabe noch nicht
// geprueft.“ Bei Ausschluss: „Nicht bei Lena: ⟨Grund⟩“, bei Hand-Ausschluss mit Grund, wer, wann.

import { useState, type JSX, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { cn } from '@/lib/utils'
import { formatBerlinDateTime } from '@/lib/datetime'
import { aenderungText, type Namen } from '@/lib/pruefung/anzeige'
import type { AdminPruefKontext, PruefAufgabe } from '@/types'

type Ton = 'neutral' | 'ok' | 'warn' | 'bad' | 'navy'
const TON: Record<Ton, string> = {
  neutral: 'border-[var(--color-border)] bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
  ok: 'border-[var(--color-success)] bg-[var(--color-success-light)] text-[var(--color-success)]',
  warn: 'border-[var(--color-warning)] bg-[var(--color-warning-light)] text-[var(--color-warning)]',
  bad: 'border-[var(--color-destructive)] bg-[var(--color-destructive-light)] text-[var(--color-destructive)]',
  navy: 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]',
}

export function Marke({ ton, children }: { ton: Ton; children: ReactNode }): JSX.Element {
  return <span className={cn('rounded-[var(--radius-full)] border px-3 py-0.5 text-xs font-semibold', TON[ton])}>{children}</span>
}

function Zitat({ ton = 'neutral', unter, children }: { ton?: Ton; unter: string; children: ReactNode }): JSX.Element {
  return (
    <div className={cn('flex flex-col gap-1 rounded-[var(--radius-md)] border-l-4 p-3 text-sm text-[var(--color-text-primary)]', TON[ton])}>
      <div className="text-[var(--color-text-primary)]">{children}</div>
      <span className="text-xs text-[var(--color-text-tertiary)]">{unter}</span>
    </div>
  )
}

type Props = { aufgabe: PruefAufgabe; kontext: AdminPruefKontext | null; namen: Namen }

export function LenasErgebnis({ aufgabe, kontext, namen }: Props): JSX.Element {
  const { t, i18n } = useTranslation('pruefenAdmin')
  const { t: tp } = useTranslation('pruefen')
  const [auf, setAuf] = useState(false)
  const a = aufgabe.aufgabe
  const lena = kontext?.lena?.entscheidung === 'zurueckgenommen' ? null : kontext?.lena ?? null
  const am = (iso: string | null | undefined): string => (iso ? formatBerlinDateTime(iso, i18n.language) : '')
  const grund = (g: string): string => t([`pruefen:gruende.${g}`, `authoring:reject.kategorie.${g}`, g])
  const offen = a.lena_status === 'offen'
  const aenderungen = lena && !offen ? lena.aenderungen : []
  const zugeklappt = aenderungen.length >= 3 && !auf

  let marke: JSX.Element
  if (a.ausschluss) marke = <Marke ton="neutral">{t('lena.nichtBeiLena', { grund: t(`authoring:lena.ausschluss.${a.ausschluss}`) })}</Marke>
  else if (a.status === 'ready') marke = <Marke ton="ok">{t('lena.marke.freigegeben')}</Marke>
  else if (a.team_beanstandet) marke = <Marke ton="bad">{t('lena.marke.team')}</Marke>
  else if (a.lena_status === 'passt') {
    marke = aenderungen.length > 0 ? <Marke ton="navy">{t('lena.marke.passtGeaendert')}</Marke> : <Marke ton="ok">{t('lena.marke.passt')}</Marke>
  } else if (a.lena_status === 'unsicher') marke = <Marke ton="warn">{t('lena.marke.unsicher')}</Marke>
  else if (a.lena_status === 'passt_nicht') marke = <Marke ton="bad">{t('lena.marke.passt_nicht')}</Marke>
  else marke = <Marke ton="neutral">{t('lena.marke.offen')}</Marke>

  return (
    <EdvanceCard className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-3">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('lena.titel')}</h2>
        {marke}
        {lena && !offen && (
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('lena.geprueft', { wer: lena.geprueft_von ?? t('lena.unbekannt'), am: am(lena.geprueft_am) })}
            {lena.dauer_sek !== null && <> · {t('lena.dauer', { n: lena.dauer_sek })}</>}
          </span>
        )}
      </div>
      {kontext?.hand && (
        <Zitat unter={t('lena.handVon', { wer: kontext.hand.von ?? t('lena.unbekannt'), am: am(kontext.hand.am) })}>
          {t('lena.hand', { grund: kontext.hand.grund })}
        </Zitat>
      )}
      {offen && !a.ausschluss && (
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('lena.nochNicht')}</p>
      )}
      {lena && a.lena_status === 'unsicher' && lena.notiz && <Zitat ton="warn" unter={t('lena.frage')}>„{lena.notiz}“</Zitat>}
      {lena && a.lena_status === 'passt_nicht' && !a.team_beanstandet && (
        <Zitat ton="bad" unter={t('lena.gruende')}>
          <strong>{lena.gruende.map(grund).join(' · ')}</strong>
          {lena.notiz && <><br />{lena.notiz}</>}
        </Zitat>
      )}
      {a.team_beanstandet && kontext?.team && (
        <Zitat ton="bad" unter={t('lena.team', { wer: kontext.team.von ?? t('lena.unbekannt'), am: am(kontext.team.am) })}>
          <strong>{kontext.team.gruende.map(grund).join(' · ')}</strong>
          {kontext.team.notiz && <><br />{kontext.team.notiz}</>}
        </Zitat>
      )}
      {kontext?.lena?.antwort && (
        <Zitat ton="navy" unter={t('lena.antwort', { wer: kontext.lena.beantwortet_von ?? t('lena.unbekannt'), am: am(kontext.lena.beantwortet_am) })}>
          „{kontext.lena.antwort}“
        </Zitat>
      )}
      {aenderungen.length > 0 && (
        <div className="flex flex-col gap-1">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('lena.aenderungen', { count: aenderungen.length })}
          </p>
          {!zugeklappt && (
            <ul className="list-disc pl-5 text-sm text-[var(--color-text-secondary)]">
              {aenderungen.map((x, i) => <li key={i}>{aenderungText(tp, x, namen, a.input_type === 'MC')}</li>)}
              {lena?.aenderung_grund && <li className="list-none">{t('lena.warum', { grund: lena.aenderung_grund })}</li>}
            </ul>
          )}
          {aenderungen.length >= 3 && (
            <button type="button" onClick={() => setAuf((x) => !x)} className="min-h-[44px] self-start text-sm text-[var(--color-text-link)] hover:underline">
              {auf ? t('lena.aenderungenVerbergen') : t('lena.aenderungenZeigen', { count: aenderungen.length })}
            </button>
          )}
        </div>
      )}
    </EdvanceCard>
  )
}
