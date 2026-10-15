import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { berlinLocalParts } from '@/lib/datetime'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { addStudentToSession, KEIN_PLATZ_ZUGANG, TESTLAUF_NUR_TESTKONTEN } from '@/lib/supabase/sessions'
import { ladeKinderBuchbar } from '@/lib/supabase/stundenplan'
import type { KindBuchbar, StundenplanSession } from '@/types/stundenplan'
import { uhrzeit } from '../slotsFormat'
import { TestKennzeichen } from '../TestKennzeichen'
import { KindAuswahl } from './KindAuswahl'
import { SessionTestlaufSchalter } from './SessionTestlaufSchalter'
import { MAX_KINDER } from './stundenplan.model'

const STATUS_VARIANTE = { upcoming: 'primary', active: 'warning', done: 'strength' } as const

/** Ablehnung beim Zuweisen als Schlüssel, nie Rohtext der Datenbank. */
function zuweisenFehler(code: string | null | undefined): string {
  if (code === KEIN_PLATZ_ZUGANG) return 'fehler.keinZugang'
  if (code === TESTLAUF_NUR_TESTKONTEN) return 'stundenplan.testlauf.nurTestkontenBuchen'
  return slotsFehlerSchluessel({ code: code ?? null, hint: null })
}

/**
 * Eine Einzel-Session im Reiter Stundenplan (Slots S2, Entscheidung 3, 5, 6): Uhrzeit, Raum, Leitung, Kinder,
 * Status, Live-Sicht. Kinder zuweisen über kinder_buchbar(Tag, Session); höchstens 5 Kinder pro Raum.
 */
export function SessionKarte({ session, onGeaendert }: { session: StundenplanSession; onGeaendert: () => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [testlauf, setTestlauf] = useState(session.testlauf)
  const [offen, setOffen] = useState(false)
  const [kinder, setKinder] = useState<KindBuchbar[] | null>(null)
  const [ladeFehler, setLadeFehler] = useState<string | null>(null)
  const [gewaehlt, setGewaehlt] = useState<string[]>([])
  const [speichert, setSpeichert] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [runde, setRunde] = useState(0)
  // Neu geladene Woche gewinnt über den lokalen Stand.
  useEffect(() => setTestlauf(session.testlauf), [session.testlauf])

  const datum = berlinLocalParts(session.scheduled_at).date
  const frei = MAX_KINDER - session.kinder.length
  const planbar = session.status === 'upcoming' && !session.gestartet

  useEffect(() => {
    if (!offen) return undefined
    let aktiv = true
    setKinder(null)
    setLadeFehler(null)
    void ladeKinderBuchbar(datum, session.session_id).then((res) => {
      if (!aktiv) return
      if (res.error !== null) setLadeFehler(slotsFehlerSchluessel(res))
      else {
        setKinder(res.data)
        // Nach dem Umschalten des Testlaufs: nicht mehr buchbare Kinder fallen aus der Wahl.
        const ok = new Set((res.data ?? []).filter((k) => k.code === 'ok').map((k) => k.student_id))
        setGewaehlt((g) => g.filter((id) => ok.has(id)))
      }
    })
    return () => {
      aktiv = false
    }
  }, [offen, datum, session.session_id, runde])

  const zuweisen = async (): Promise<void> => {
    setSpeichert(true)
    setFehler(null)
    for (const id of gewaehlt) {
      const res = await addStudentToSession(session.session_id, id)
      if (res.error) {
        setSpeichert(false)
        setFehler(zuweisenFehler(res.code))
        setRunde((r) => r + 1)
        onGeaendert()
        return
      }
      // Gebuchte Kinder verlassen die Wahl sofort (bei einer späteren Ablehnung zählen sie sonst doppelt).
      setGewaehlt((g) => g.filter((x) => x !== id))
    }
    setSpeichert(false)
    setGewaehlt([])
    setOffen(false)
    onGeaendert()
  }

  const testlaufGeaendert = (wert: boolean): void => {
    setTestlauf(wert)
    setRunde((r) => r + 1)
    onGeaendert()
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="flex flex-col gap-1">
          <span className="text-base font-semibold tabular-nums text-[var(--color-text-primary)]">
            {t('stundenplan.uhr', { zeit: uhrzeit(session.scheduled_at, i18n.language) })}
          </span>
          <span className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
            {session.room ?? t('stundenplan.ohneRaum')}
            <span aria-hidden="true">·</span>
            {session.coach_name ?? t('stundenplan.ohneCoach')}
            {session.coach_rolle === 'admin' && <EdvanceBadge variant="muted">{t('stundenplan.admin')}</EdvanceBadge>}
          </span>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {testlauf && <EdvanceBadge variant="warning">{t('stundenplan.testlauf.kennzeichen')}</EdvanceBadge>}
          <EdvanceBadge variant={STATUS_VARIANTE[session.status]}>{t(`stundenplan.status.${session.status}`)}</EdvanceBadge>
        </div>
      </div>

      <div className="flex flex-col gap-2">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('stundenplan.kinder', { anzahl: session.kinder.length, max: MAX_KINDER })}
        </p>
        {session.kinder.length === 0 ? (
          <p className="text-sm text-[var(--color-text-tertiary)]">{t('stundenplan.niemand')}</p>
        ) : (
          <ul className="flex flex-wrap gap-2">
            {session.kinder.map((k) => (
              <li key={k.student_id} className="flex items-center gap-1">
                <EdvanceBadge variant="muted">{k.name ?? t('stundenplan.unbenannt')}</EdvanceBadge>
                {k.ist_test && <TestKennzeichen />}
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Verhalten wie bisher: nach dem Start gesperrt mit Hinweis. stundenplan_woche liefert nur „gestartet“;
          der Schalter prüft nur, ob gestartet_am gesetzt ist. */}
      <SessionTestlaufSchalter
        session={{ id: session.session_id, status: session.status, gestartet_am: session.gestartet ? session.scheduled_at : null }}
        wert={testlauf}
        onGeaendert={testlaufGeaendert}
      />

      {planbar && !offen && (
        <div className="flex flex-col gap-1">
          <Button type="button" variant="outline" className="self-start" disabled={frei <= 0} onClick={() => setOffen(true)}>
            {t('stundenplan.zuweisen')}
          </Button>
          {frei <= 0 && <p className="text-xs text-[var(--color-text-tertiary)]">{t('stundenplan.voll', { max: MAX_KINDER })}</p>}
        </div>
      )}

      {planbar && offen && (
        <div className="flex flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-4">
          <KindAuswahl
            kinder={kinder}
            fehler={ladeFehler}
            gewaehlt={gewaehlt}
            onWahl={setGewaehlt}
            frei={frei}
            ohne={session.kinder.map((k) => k.student_id)}
          />
          <div className="flex flex-col gap-1">
            <span className="flex gap-2">
              <Button type="button" onClick={() => void zuweisen()} disabled={gewaehlt.length === 0 || speichert} loading={speichert}>
                {gewaehlt.length === 0 ? t('stundenplan.zuweisen') : t('stundenplan.zuweisenKnopf', { count: gewaehlt.length })}
              </Button>
              <Button type="button" variant="ghost" onClick={() => setOffen(false)}>{t('dialog.abbrechen')}</Button>
            </span>
            {gewaehlt.length === 0 && <span className="text-xs text-[var(--color-text-tertiary)]">{t('stundenplan.waehleKind')}</span>}
          </div>
        </div>
      )}

      {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}

      <Link
        to={`/coach/session/${session.session_id}/live`}
        className="inline-flex min-h-[44px] items-center gap-2 self-start text-sm font-semibold text-[var(--color-text-link)] hover:underline"
      >
        {t('stundenplan.live')}
        <ArrowRight aria-hidden="true" className="h-4 w-4" />
      </Link>
    </EdvanceCard>
  )
}
