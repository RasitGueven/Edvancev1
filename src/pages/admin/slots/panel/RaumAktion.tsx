import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { terminSessionAnlegen } from '@/lib/supabase/slotplan'
import type { SlotsTermin, TerminRaum } from '@/types/slotplan'
import { betriebAktion, type BetriebZeile } from '@/pages/admin/heute/betriebModel'
import { PLAETZE } from '../wochenplan/wochenplan.model'

/** Der Raum eines Termins als Zeile von „Heute im Betrieb“, damit betriebAktion entscheidet (nicht kopiert). */
export function alsBetriebZeile(termin: SlotsTermin, raum: TerminRaum): BetriebZeile {
  return {
    art: 'raum',
    key: raum.raum_id,
    sortier: 0,
    t: {
      zeit_id: termin.zeit.id, beginn: termin.zeit.beginn, ende: termin.zeit.ende, raum_id: raum.raum_id, raum_name: raum.name,
      coach_id: raum.offen ? raum.coach_id : null, coach_name: raum.coach_name, art: raum.art, offen: raum.offen,
      kapazitaet: PLAETZE, belegt: raum.kinder.length, session_id: raum.session_id, gestartet: raum.gestartet, status: null,
    },
  }
}

const LINK = 'inline-flex min-h-[44px] items-center text-sm font-semibold text-[var(--color-text-link)] hover:underline'

/**
 * Rechts im Raum (W2, Entscheidung 6): Session öffnen, Live-Sicht oder Rückblick nach betriebAktion. Am Termintag
 * entscheidet betriebAktion; davor „Öffnen am Termintag“, danach nur der Rückblick einer gelaufenen Session.
 * Ein leerer Raum bekommt kein „Session öffnen“.
 */
export function RaumAktion({ termin, raum }: { termin: SlotsTermin; raum: TerminRaum }): JSX.Element | null {
  const { t } = useTranslation('slots')
  const navigate = useNavigate()
  const [laeuft, setLaeuft] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)

  if (!raum.offen && !raum.session_id) return null
  const leer = <span className="text-xs text-[var(--color-text-tertiary)]">{t('wochenplan2.aktion.leer')}</span>
  if (raum.kinder.length === 0 && !raum.session_id) return termin.vergangen ? null : leer
  const rueckblick = (id: string): JSX.Element => (
    <span className="flex items-center gap-2">
      <EdvanceBadge variant="muted">{t('wochenplan2.aktion.beendet')}</EdvanceBadge>
      <Link to={`/coach/session/${id}/live`} className={LINK}>{t('wochenplan2.aktion.rueckblick')}</Link>
    </span>
  )
  if (!termin.heute) {
    if (termin.vergangen) return raum.session_id ? rueckblick(raum.session_id) : null
    return <span className="text-xs text-[var(--color-text-tertiary)]">{t('wochenplan2.aktion.amTermintag')}</span>
  }

  const aktion = betriebAktion(alsBetriebZeile(termin, raum), termin.datum)
  if (aktion.art === 'live') {
    if (termin.vergangen && raum.session_id) return rueckblick(raum.session_id)
    return (
      <Button asChild variant="outline" size="sm" className="min-h-[44px]">
        <Link to={aktion.ziel}>{t('wochenplan2.aktion.live')}</Link>
      </Button>
    )
  }
  if (aktion.art === 'leer') return leer
  if (aktion.art !== 'oeffnen' || termin.vergangen) return null

  const oeffnen = async (): Promise<void> => {
    setLaeuft(true)
    setFehler(null)
    try {
      const res = await terminSessionAnlegen(aktion.datum, aktion.zeit_id, aktion.raum_id)
      if (res.error !== null || !res.data) return setFehler(slotsFehlerSchluessel(res))
      navigate(`/coach/session/${res.data.session_id}/live`)
    } catch (e) {
      console.warn('terminSessionAnlegen failed', e)
      setFehler(slotsFehlerSchluessel(null))
    } finally {
      setLaeuft(false)
    }
  }
  return (
    <span className="flex flex-col items-end gap-1">
      <Button type="button" variant="outline" size="sm" className="min-h-[44px]" loading={laeuft} onClick={() => void oeffnen()}>
        {t('termin.sessionOeffnen')}
      </Button>
      {fehler && <span role="alert" className="max-w-[16rem] text-right text-xs text-[var(--color-error-coach)]">{t(fehler)}</span>}
    </span>
  )
}
