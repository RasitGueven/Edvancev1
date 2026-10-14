import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { passwortSetzen, tokenEinloesen, type LinkTyp } from '@/lib/supabase/konto'
import { AuthRahmen, ROLLEN_START } from './AuthRahmen'
import { PasswortFelder } from './PasswortFelder'

type Art = 'einladung' | 'neuesPasswort' | 'bestaetigen'

/** Welche type-Werte aus dem Mail-Link zu welcher Seite gehoeren. */
const ERWARTET: Record<Art, readonly LinkTyp[]> = {
  einladung: ['invite'],
  neuesPasswort: ['recovery'],
  bestaetigen: ['signup', 'magiclink', 'email_change'],
}

type Schritt = 'start' | 'passwort' | 'fertig' | 'ungueltig'

/**
 * Ziel der Links aus den Auth-Mails (/auth/einladung, /auth/neues-passwort,
 * /auth/bestaetigen). Der Token wird erst nach dem Klick auf „Weiter“
 * eingeloest, nie beim Laden: Mail-Scanner wie Safe Links oeffnen Links vorab
 * und wuerden den einmal gueltigen Token sonst verbrauchen.
 */
export function TokenSeite({ art }: { art: Art }): JSX.Element {
  const { t } = useTranslation('konto')
  const [params] = useSearchParams()
  const { pathname } = useLocation()
  const navigate = useNavigate()
  const { role } = useAuth()

  // Beim ersten Rendern festhalten; nach dem Einloesen verschwindet der Token aus der Adresse.
  const [link] = useState(() => ({ hash: params.get('token_hash') ?? '', type: params.get('type') ?? '' }))
  const vollstaendig = link.hash !== '' && (ERWARTET[art] as readonly string[]).includes(link.type)
  const [schritt, setSchritt] = useState<Schritt>(vollstaendig ? 'start' : 'ungueltig')
  const [laedt, setLaedt] = useState(false)

  const start = role ? ROLLEN_START[role] : '/login'
  useEffect(() => {
    if (schritt === 'fertig' && role) navigate(ROLLEN_START[role], { replace: true })
  }, [schritt, role, navigate])

  const weiter = async (): Promise<void> => {
    setLaedt(true)
    const { error } = await tokenEinloesen(link.hash, link.type as LinkTyp)
    setLaedt(false)
    if (error) {
      setSchritt('ungueltig')
      return
    }
    navigate(pathname, { replace: true })
    setSchritt(art === 'bestaetigen' ? 'fertig' : 'passwort')
  }

  if (schritt === 'ungueltig') {
    return (
      <AuthRahmen titel={t('link.ungueltigTitel')} satz={vollstaendig ? t(`${art}.ungueltig`) : t('link.ohneToken')}>
        <Button asChild size="lg" className="w-full">
          {art === 'neuesPasswort' ? (
            <Link to="/auth/passwort-vergessen">{t('link.neuerLink')}</Link>
          ) : (
            <Link to="/login">{t('link.zurAnmeldung')}</Link>
          )}
        </Button>
      </AuthRahmen>
    )
  }

  if (schritt === 'passwort') {
    const pa = art === 'einladung' ? 'einladung' : 'neuesPasswort'
    return (
      <AuthRahmen titel={t(`${pa}.passwortTitel`)} satz={t(`${pa}.passwortSatz`)}>
        <PasswortFelder
          knopf={t(`${pa}.speichern`)}
          knopfLaedt={t('link.prueft')}
          onSpeichern={async (neu) => {
            const { error } = await passwortSetzen(neu)
            if (!error) setSchritt('fertig')
            return error
          }}
        />
      </AuthRahmen>
    )
  }

  if (schritt === 'fertig') {
    return (
      <AuthRahmen titel={t('fertig.titel')} satz={t('fertig.satz')}>
        <Button asChild size="lg" className="w-full">
          <Link to={start} replace>
            {t('fertig.weiter')}
          </Link>
        </Button>
      </AuthRahmen>
    )
  }

  return (
    <AuthRahmen titel={t(`${art}.titel`)} satz={t(`${art}.satz`)}>
      <Button type="button" size="lg" className="w-full" loading={laedt} onClick={() => void weiter()}>
        {laedt ? t('link.prueft') : t('link.weiter')}
      </Button>
    </AuthRahmen>
  )
}
