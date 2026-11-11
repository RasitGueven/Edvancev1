import { Link, useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { LogOut, PanelLeftClose, PanelLeftOpen, UserRound } from 'lucide-react'
import { MarkenLogo } from '@/components/brand/MarkenLogo'
import { AvatarInitials } from '@/components/edvance/AvatarInitials'
import { useAuth } from '@/hooks/useAuth'
import { LEISTEN_TON } from './leistenTon'
import { LeistenHorizont } from './LeistenHorizont'
import {
  bereichAlsEintrag,
  bereichZaehler,
  istAktiv,
  type LeistenTon,
  type NavEintrag,
  type NavKonfiguration,
  type Zaehlerwerte,
} from './navTypes'
import { ShellNavEintrag } from './ShellNavEintrag'
import { useProfilName } from './useProfilName'

type Props = {
  konfig: NavKonfiguration
  zaehler: Zaehlerwerte
  variante: 'voll' | 'schmal'
  ton?: LeistenTon
  /** Schmale Spalte: der Knopf „Menü“ klappt die volle Leiste aus. */
  onMenue?: () => void
  /** Ausgeklappt (Überlagerung/Schublade): „Menü einklappen“. */
  onSchliessen?: () => void
}

/**
 * Die Leiste der Hülle. Rollenneutral: Einträge, Zähler und die Marke neben
 * dem Logo kommen aus der Konfiguration, Name/E-Mail/Abmelden aus der Sitzung.
 */
export function ShellSidebar({
  konfig,
  zaehler,
  variante,
  ton: tonName = 'navy',
  onMenue,
  onSchliessen,
}: Props): JSX.Element {
  const { t } = useTranslation(konfig.namespace)
  const { t: tc } = useTranslation('common')
  const { user, signOut } = useAuth()
  const { pathname } = useLocation()
  const ton = LEISTEN_TON[tonName]
  const schmal = variante === 'schmal'
  const email = user?.email ?? ''
  // Name aus profiles.full_name; fehlt er, steht nur die E-Mail da.
  const name = useProfilName() ?? email

  const fussKnopf = `flex min-h-[44px] w-full items-center rounded-[var(--radius-md)] text-sm font-medium ${ton.gedimmt} ${ton.hover} ${
    schmal ? 'flex-col justify-center gap-1 px-1 py-2' : 'gap-3 px-3'
  }`

  const eintrag = (e: NavEintrag, wert: number | undefined): JSX.Element => (
    <ShellNavEintrag
      key={e.id}
      eintrag={e}
      namespace={konfig.namespace}
      ton={ton}
      schmal={schmal}
      aktiv={istAktiv(e, pathname)}
      wert={wert}
    />
  )

  return (
    <nav
      aria-label={tc('shell.navigation')}
      className={`print-hide relative flex h-full min-h-0 flex-col gap-4 overflow-hidden ${schmal ? 'px-2' : 'px-4'} pb-[max(1rem,env(safe-area-inset-bottom))] pt-[max(1rem,env(safe-area-inset-top))] ${ton.flaeche} ${ton.text}`}
    >
      <div className={`flex min-h-[44px] items-center ${schmal ? 'justify-center' : 'justify-between gap-2 px-2'}`}>
        {schmal ? (
          <MarkenLogo fassung="zeichen" grund={ton.logoGrund} className="h-8" />
        ) : (
          <>
            <MarkenLogo fassung="wortmarke" grund={ton.logoGrund} className="h-6" />
            <span className={`text-xs font-semibold uppercase tracking-widest ${ton.gruppe}`}>{t(konfig.rolleKey)}</span>
          </>
        )}
      </div>

      <div className="flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto">
        {konfig.gruppen.map((gruppe, i) => (
          <div
            key={gruppe.id}
            className={`flex flex-col gap-1 ${schmal && i > 0 && !gruppe.icon ? `border-t pt-2 ${ton.linie}` : ''}`}
          >
            {!schmal && gruppe.titelKey && (
              <p className={`px-3 pt-2 text-xs font-semibold uppercase tracking-widest ${ton.gruppe}`}>
                {t(gruppe.titelKey)}
              </p>
            )}
            {schmal && gruppe.icon && gruppe.titelKey
              ? eintrag(bereichAlsEintrag({ ...gruppe, icon: gruppe.icon, titelKey: gruppe.titelKey }), bereichZaehler(gruppe, zaehler))
              : gruppe.eintraege.map((e) => eintrag(e, e.zaehler ? zaehler[e.zaehler] : undefined))}
          </div>
        ))}
      </div>

      <div className={`relative z-10 flex flex-col gap-2 border-t pt-4 ${ton.linie}`}>
        {konfig.fuss?.map((e) => eintrag(e, e.zaehler ? zaehler[e.zaehler] : undefined))}
        {(onMenue || onSchliessen) && (
          <button type="button" onClick={onMenue ?? onSchliessen} aria-expanded={Boolean(onSchliessen)} className={fussKnopf}>
            {onSchliessen ? <PanelLeftClose aria-hidden="true" className="h-5 w-5" /> : <PanelLeftOpen aria-hidden="true" className="h-5 w-5" />}
            <span className={schmal ? 'text-[11px] leading-tight' : ''}>
              {onSchliessen ? tc('shell.menueEinklappen') : schmal ? tc('shell.menue') : tc('shell.menueAusklappen')}
            </span>
          </button>
        )}
        {schmal ? (
          <div className="flex justify-center py-1" title={name}>
            <AvatarInitials name={name || '?'} size="sm" />
          </div>
        ) : (
          <div className="flex items-center gap-3 px-2">
            <AvatarInitials name={name || '?'} size="sm" />
            <div className="flex min-w-0 flex-col">
              <span className="truncate text-sm font-semibold">{name}</span>
              {name !== email && <span className={`truncate text-xs ${ton.gruppe}`}>{email}</span>}
            </div>
          </div>
        )}
        <Link to="/konto" aria-current={pathname === '/konto' ? 'page' : undefined} className={fussKnopf}>
          <UserRound aria-hidden="true" className="h-5 w-5" />
          <span className={schmal ? 'text-[11px] leading-tight' : ''}>{tc('shell.meinKonto')}</span>
        </Link>
        <button type="button" onClick={() => void signOut()} className={fussKnopf}>
          <LogOut aria-hidden="true" className="h-5 w-5" />
          <span className={schmal ? 'text-[11px] leading-tight' : ''}>{tc('shell.abmelden')}</span>
        </button>
      </div>
      {konfig.horizont && tonName === 'navy' && <LeistenHorizont />}
    </nav>
  )
}
