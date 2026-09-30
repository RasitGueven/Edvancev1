import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { EdvanceBadgeVariant } from '@/components/edvance/EdvanceBadge'
import { ANWESENHEIT_REIHENFOLGE, summeJeZustand } from '@/lib/akte/board'
import { formatBerlinDateTime } from '@/lib/datetime'
import type { AkteSession, AttendanceStatus } from '@/types'

const SICHTBAR = 8

// Status-Farbe nur, wo sie etwas sagt (Coach-Sicht: flach, keine Bewertung des Kindes in Rot
// ausser "unentschuldigt", das eine Einheit kostet).
const BADGE: Record<AttendanceStatus, EdvanceBadgeVariant> = {
  planned: 'muted',
  present: 'strength',
  cancelled: 'muted',
  unexcused: 'warning',
  cancelled_by_us: 'primary',
}

/**
 * Sessions und Anwesenheit (Anforderung E): Summe je Zustand, letzte 8, Rest
 * aufklappbar. Quelle akte_sessions (alle Sessions seit Beginn der Akte, auch
 * fuer Coaches). Fach und "woran gearbeitet" gibt es noch nicht — "—" mit
 * Hinweis, kommt mit Slots.
 */
export function SessionsKachel({ sessions }: { sessions: AkteSession[] }): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const [alle, setAlle] = useState(false)
  const summe = summeJeZustand(sessions.map((s) => s.attendance))
  const sichtbar = alle ? sessions : sessions.slice(0, SICHTBAR)
  const rest = sessions.length - SICHTBAR

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('sessions.titel')}
      </h2>

      {sessions.length === 0 ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('sessions.leer')}</p>
      ) : (
        <>
          <div className="flex flex-wrap gap-2">
            {ANWESENHEIT_REIHENFOLGE.filter((z) => summe[z] > 0).map((z) => (
              <EdvanceBadge key={z} variant={BADGE[z]}>
                {t('sessions.summe', { label: t(`sessions.anwesenheit.${z}`), count: summe[z] })}
              </EdvanceBadge>
            ))}
          </div>
          <ul className="flex flex-col gap-2">
            {sichtbar.map((s) => (
              <li key={s.session_id} className="flex flex-wrap items-center justify-between gap-2 text-sm">
                <span className="text-[var(--color-text-primary)]">{formatBerlinDateTime(s.scheduled_at, i18n.language)}</span>
                <span className="text-[var(--color-text-tertiary)]">{s.coach_name ?? t('sessions.coachUnbekannt')}</span>
                <span className="text-[var(--color-text-tertiary)]" title={t('sessions.kommtMitSlots')}>
                  {t('sessions.fach')}: —
                </span>
                <span className="text-[var(--color-text-tertiary)]" title={t('sessions.kommtMitSlots')}>
                  {t('sessions.gearbeitet')}: —
                </span>
                <EdvanceBadge variant={BADGE[s.attendance]}>{t(`sessions.anwesenheit.${s.attendance}`)}</EdvanceBadge>
              </li>
            ))}
          </ul>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('sessions.kommtMitSlotsHinweis')}</p>
          {rest > 0 && (
            <div>
              <Button size="sm" variant="outline" onClick={() => setAlle(!alle)}>
                {alle ? t('sessions.weniger') : t('sessions.mehr', { count: rest })}
              </Button>
            </div>
          )}
        </>
      )}
    </EdvanceCard>
  )
}
