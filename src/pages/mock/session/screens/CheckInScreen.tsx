import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AvatarInitials } from '@/components/edvance'
import { SessionShell } from '../components/SessionShell'
import { SessionButton } from '../components/SessionButton'
import { MOCK_SESSION_STUDENT } from '@/lib/mocks/session'
import type { ScreenProps } from '../screenProps'

/**
 * Screen 1 — Check-in am Platz. Ankommen ohne Login-Hürde: nur Avatar,
 * Begrüßung, eine Zeile zum Heute, ein großer CTA. Keine Zahlen, kein Druck.
 */
export function CheckInScreen({ dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const student = MOCK_SESSION_STUDENT

  return (
    <SessionShell center showExit maxWidth="sm">
      <div className="flex animate-fade-in flex-col items-center gap-7 text-center">
        <AvatarInitials name={student.fullName} size="lg" />

        <div className="flex flex-col gap-3">
          <p className="text-eyebrow text-warm-56">{t('session.checkin.eyebrow')}</p>
          <h1 className="text-display text-3xl leading-tight text-warm">
            {t('session.checkin.welcome', { name: student.displayName })}
          </h1>
          <p className="text-base text-warm-72">
            {t('session.checkin.today', {
              subject: student.subject,
              minutes: student.durationMin,
            })}
          </p>
          <p className="text-sm text-warm-56">{t('session.checkin.hint')}</p>
        </div>

        <SessionButton block onClick={() => dispatch({ type: 'CHECK_IN' })}>
          {t('session.checkin.cta')}
        </SessionButton>
      </div>
    </SessionShell>
  )
}
