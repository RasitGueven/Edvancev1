import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { terminSessionAnlegen } from '@/lib/supabase/slotplan'
import type { BetriebAktion } from './betriebModel'

/**
 * Rechte Spalte einer Zeile in „Heute im Betrieb“ (Slots S3): ein Knopf je Zeile. „Session öffnen“
 * schreibt den Raum-Termin fest und führt in die Live-Sicht; ein Fehler steht als übersetzter Satz
 * (Namespace slots) unter dem Knopf, nie der Rohtext.
 */
export function BetriebAktionKnopf({ aktion }: { aktion: BetriebAktion }): JSX.Element {
  const { t } = useTranslation('admin')
  const { t: tSlots } = useTranslation('slots')
  const navigate = useNavigate()
  const [laeuft, setLaeuft] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)

  if (aktion.art === 'live') {
    return (
      <Button asChild variant="outline" className="min-h-[44px]">
        <Link to={aktion.ziel}>{t('heute.betrieb.aktion.live')}</Link>
      </Button>
    )
  }

  if (aktion.art === 'ohneCoach') {
    return (
      <span className="flex flex-col items-end text-right">
        <span className="text-xs text-[var(--color-text-tertiary)]">{t('heute.betrieb.aktion.ohneCoach')}</span>
        <Link
          to={aktion.ziel}
          className="inline-flex min-h-[44px] items-center text-sm font-semibold text-[var(--color-text-link)] hover:underline"
        >
          {t('heute.betrieb.aktion.zumTermin')}
        </Link>
      </span>
    )
  }

  const oeffnen = async (): Promise<void> => {
    setLaeuft(true)
    setFehler(null)
    const res = await terminSessionAnlegen(aktion.datum, aktion.zeit_id, aktion.raum_id)
    setLaeuft(false)
    if (res.error !== null || !res.data) {
      setFehler(slotsFehlerSchluessel(res))
      return
    }
    navigate(`/coach/session/${res.data.session_id}/live`)
  }

  return (
    <span className="flex flex-col items-end gap-2">
      <Button loading={laeuft} onClick={() => void oeffnen()} className="min-h-[44px]">
        {t('heute.betrieb.aktion.oeffnen')}
      </Button>
      {fehler && (
        <span role="alert" className="max-w-[16rem] text-right text-xs text-[var(--color-error-coach)]">
          {tSlots(fehler)}
        </span>
      )}
    </span>
  )
}
