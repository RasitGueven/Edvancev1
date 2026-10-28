import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, CalendarRange } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { EmptyState } from '@/components/edvance/EmptyState'
import { LoadingPulse } from '@/components/edvance/LoadingPulse'
import { Button } from '@/components/ui/button'
import { useReihe } from '@/hooks/useReihe'
import { reiheAnsicht } from '@/lib/session/reiheAnsicht'
import { reiheBestaetigen, reiheVerschieben } from '@/lib/supabase/reihe'
import type { ReiheCoach, ReiheSession } from '@/types/reihe'
import { Pille } from '../bausteine'

const heuteIso = (): string => new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Berlin' }).format(new Date())

/**
 * Reihe 1 C1.4: Karte „Reihe“ im Vorher-Briefing und im Kind-Detail. Sessions bis zur Arbeit,
 * heutige Skills, Warnung „passt nicht“, Coach verschiebt einen Skill oder bestätigt den Plan.
 * Der Systemvorschlag bleibt in der Datenbank getrennt; die Karte zeigt den wirksamen Plan.
 */
export function ReiheKarte({ studentId, kompakt = false }: { studentId: string; kompakt?: boolean }): JSX.Element {
  const { t } = useTranslation('reihe')
  const { reihe, laedt, fehler, setzen } = useReihe(studentId)
  if (laedt) return <LoadingPulse type="card" />
  if (fehler) return <p className="text-sm text-[var(--color-text-secondary)]">{t('karte.fehler')}</p>
  if (!reihe) return kompakt ? <></> : <EmptyState icon="🗓️" title={t('karte.leerTitel')} description={t('karte.leerText')} />
  return <ReiheInhalt reihe={reihe} setzen={setzen} kompakt={kompakt} />
}

function ReiheInhalt({ reihe, setzen, kompakt }: { reihe: ReiheCoach; setzen: (r: ReiheCoach) => void; kompakt: boolean }): JSX.Element {
  const { t, i18n } = useTranslation('reihe')
  const [offen, setOffen] = useState(false)
  const [fehler, setFehler] = useState(false)
  const a = reiheAnsicht(reihe, heuteIso())
  const datum = (iso: string): string =>
    new Intl.DateTimeFormat(i18n.language, { timeZone: 'Europe/Berlin', day: '2-digit', month: '2-digit' }).format(new Date(`${iso}T12:00:00Z`))
  const liste = new Intl.ListFormat(i18n.language, { type: 'conjunction' })
    .format(a.entfallen.map((e) => (e === 'transfer' ? t('karte.transferBlock') : e)))
  const ergebnis = (r: { data: ReiheCoach | null; error: string | null }): void => {
    setFehler(r.error !== null)
    if (r.data) { setzen(r.data); setOffen(false) }
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-center gap-2">
        <CalendarRange className="h-4 w-4 text-[var(--color-text-tertiary)]" aria-hidden />
        <span className="text-base font-semibold">{t('karte.titel')}</span>
        {a.nr !== null && <Pille ton="navy">{t('karte.sessionVon', { nr: a.nr, gesamt: a.gesamt })}</Pille>}
        {reihe.plan.bestaetigt && <Pille ton="ok">{t('karte.bestaetigt')}</Pille>}
      </div>
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {a.bisArbeit !== null && reihe.ka_datum
          ? t('karte.bisArbeit', { count: a.bisArbeit, datum: datum(reihe.ka_datum) })
          : t('karte.rollierend', { count: reihe.plan.sessions.length })}
      </p>
      {!a.passt && (
        <p role="alert" className="flex gap-2 text-sm text-[var(--color-text-primary)]">
          <AlertTriangle className="mt-0.5 h-4 w-4 flex-none text-[var(--color-gold-warning)]" aria-hidden />
          {t('karte.warnung', { count: reihe.plan.warnung.sessions, liste })}
        </p>
      )}
      <ul className="flex flex-col gap-2">
        {(kompakt ? reihe.plan.sessions.slice(0, 2) : reihe.plan.sessions).map((s) => (
          <SessionZeile key={s.datum} s={s} reihe={reihe} heute={s === a.heute} datum={datum} />
        ))}
      </ul>
      {!kompakt && (
        <div className="flex flex-col gap-2">
          {offen && <Verschieben reihe={reihe} datum={datum} onFertig={ergebnis} onAbbrechen={() => setOffen(false)} />}
          <div className="flex flex-wrap gap-2">
            {!reihe.plan.bestaetigt && !offen && (
              <Button onClick={() => void reiheBestaetigen(reihe.reihe_id).then(ergebnis)}>{t('karte.bestaetigen')}</Button>
            )}
            {!offen && <Button variant="secondary" onClick={() => setOffen(true)}>{t('karte.verschieben')}</Button>}
          </div>
          {fehler && <p className="text-xs text-[var(--color-text-muted)]">{t('karte.speichernFehler')}</p>}
        </div>
      )}
    </EdvanceCard>
  )
}

function SessionZeile({ s, reihe, heute, datum }: { s: ReiheSession; reihe: ReiheCoach; heute: boolean; datum: (d: string) => string }): JSX.Element {
  const { t } = useTranslation('reihe')
  const skills = s.art === 'generalprobe'
    ? t('karte.generalprobe')
    : [...s.skills.map((k) => reihe.labels[k] ?? k), ...(s.transfer ? [t('karte.transfer')] : [])].join(' · ') || t('karte.keineSkills')
  const coach = s.kernideen.some((k) => k.coach)
  return (
    <li className="grid grid-cols-[72px_minmax(0,1fr)] gap-2 text-sm">
      <span className={heute ? 'font-semibold text-[var(--color-text-primary)]' : 'text-[var(--color-text-tertiary)]'}>
        {heute ? t('karte.heute') : datum(s.datum)}
      </span>
      <span className="min-w-0 text-[var(--color-text-secondary)]">
        {skills}
        {coach && <span className="text-xs text-[var(--color-text-muted)]"> · {t('karte.coach')}</span>}
      </span>
    </li>
  )
}

function Verschieben({ reihe, datum, onFertig, onAbbrechen }: {
  reihe: ReiheCoach; datum: (d: string) => string
  onFertig: (r: { data: ReiheCoach | null; error: string | null }) => void; onAbbrechen: () => void
}): JSX.Element {
  const { t } = useTranslation('reihe')
  const skills = [...new Set(reihe.plan.sessions.flatMap((s) => s.skills))]
  const ziele = reihe.plan.sessions.filter((s) => s.art === 'normal')
  const [skill, setSkill] = useState(skills[0] ?? '')
  const [ziel, setZiel] = useState(ziele[0]?.datum ?? '')
  const feld = 'min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'
  return (
    <div className="flex flex-wrap items-end gap-2">
      <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
        {t('karte.verschiebenSkill')}
        <select className={feld} value={skill} onChange={(e) => setSkill(e.target.value)}>
          {skills.map((k) => <option key={k} value={k}>{reihe.labels[k] ?? k}</option>)}
        </select>
      </label>
      <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
        {t('karte.verschiebenZiel')}
        <select className={feld} value={ziel} onChange={(e) => setZiel(e.target.value)}>
          {ziele.map((s) => <option key={s.datum} value={s.datum}>{datum(s.datum)}</option>)}
        </select>
      </label>
      <Button variant="secondary"
        onClick={() => void reiheVerschieben(reihe.reihe_id, skill, ziel).then(onFertig)}>{t('karte.verschiebenOk')}</Button>
      <Button variant="ghost" onClick={onAbbrechen}>{t('karte.abbrechen')}</Button>
    </div>
  )
}
