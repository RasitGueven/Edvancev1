import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import {
  setSessionTestlauf,
  TESTLAUF_GESTARTET,
  TESTLAUF_NUR_TESTKONTEN,
} from '@/lib/supabase/sessions'
import type { CoachingSession } from '@/types'

type Props = {
  session: Pick<CoachingSession, 'id' | 'status' | 'gestartet_am'>
  wert: boolean
  onGeaendert: (wert: boolean) => void
}

/** Die Session laeuft oder ist vorbei; dann bleibt der Testlauf, wie er ist (T2). */
export function sessionGestartet(session: Pick<CoachingSession, 'status' | 'gestartet_am'>): boolean {
  return session.status !== 'upcoming' || Boolean(session.gestartet_am)
}

const FEHLER_KEY: Record<string, string> = {
  [TESTLAUF_NUR_TESTKONTEN]: 'stundenplan.testlauf.fehler.nurTestkonten',
  [TESTLAUF_GESTARTET]: 'stundenplan.testlauf.fehler.gestartet',
  '42501': 'stundenplan.testlauf.fehler.nurAdmin',
}

/**
 * Schalter "Testlauf" fuer eine Coaching-Session (Entscheidung 27). Die Seite ist
 * nur fuer Admins erreichbar; die Datenbank prueft Rolle, Start und Testkonten
 * selbst (session_testlauf_setzen). Ablehnungen stehen ruhig unter dem Schalter.
 */
export function SessionTestlaufSchalter({ session, wert, onGeaendert }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const [busy, setBusy] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const gestartet = sessionGestartet(session)

  const umschalten = async (neu: boolean): Promise<void> => {
    setBusy(true)
    setFehler(null)
    const { error, code } = await setSessionTestlauf(session.id, neu)
    setBusy(false)
    if (error) {
      setFehler(t(FEHLER_KEY[code ?? ''] ?? 'stundenplan.testlauf.fehler.unbekannt'))
      return
    }
    onGeaendert(neu)
  }

  return (
    <div className="flex flex-col gap-2">
      <label
        className="flex min-h-11 cursor-pointer items-start gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
        title={gestartet ? t('stundenplan.testlauf.gestartet') : undefined}
      >
        <input
          type="checkbox"
          role="switch"
          aria-checked={wert}
          className="mt-1 h-5 w-5 accent-[var(--color-gold-warning)]"
          checked={wert}
          disabled={busy || gestartet}
          onChange={(e) => void umschalten(e.target.checked)}
        />
        <span className="flex flex-col gap-1">
          <span className="text-sm font-semibold text-[var(--color-text-primary)]">
            {t('stundenplan.testlauf.label')}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {gestartet ? t('stundenplan.testlauf.gestartet') : t('stundenplan.testlauf.hilfe')}
          </span>
        </span>
      </label>
      {fehler && (
        <p role="status" className="text-sm text-[var(--color-text-secondary)]">
          {fehler}
        </p>
      )}
    </div>
  )
}
