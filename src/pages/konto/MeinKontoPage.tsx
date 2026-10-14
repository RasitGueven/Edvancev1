import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { useAuth } from '@/hooks/useAuth'
import { passwortAendern } from '@/lib/supabase/konto'
import { PasswortFelder } from '@/pages/auth/PasswortFelder'

/**
 * Mein Konto (Admin und Coach, in der Huelle): Passwort aendern. Das alte
 * Passwort wird vor der Aenderung per erneuter Anmeldung geprueft; danach
 * sind die anderen Sitzungen des Kontos abgemeldet.
 */
export function MeinKontoPage(): JSX.Element {
  const { t } = useTranslation('konto')
  const { user } = useAuth()
  const email = user?.email ?? ''
  const [geaendert, setGeaendert] = useState(false)

  return (
    <>
      <PageHeader rubrik={t('meinKonto.rubrik')} titel={t('meinKonto.titel')} satz={t('meinKonto.satz')} />
      <div className="flex flex-col gap-6 @4xl:max-w-xl">
        <EdvanceCard className="flex flex-col gap-2 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('meinKonto.email')}
          </p>
          <p className="text-base font-semibold text-[var(--color-text-primary)]">{email}</p>
        </EdvanceCard>

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('meinKonto.passwortTitel')}
          </p>
          {geaendert && (
            <p role="status" className="text-sm text-[var(--color-success)]">
              {t('meinKonto.geaendert')}
            </p>
          )}
          <PasswortFelder
            mitAltem
            email={email}
            knopf={t('meinKonto.aendern')}
            knopfLaedt={t('meinKonto.aendert')}
            onSpeichern={async (neu, alt) => {
              setGeaendert(false)
              const { error } = await passwortAendern(email, alt, neu)
              if (!error) setGeaendert(true)
              return error
            }}
          />
        </EdvanceCard>
      </div>
    </>
  )
}
