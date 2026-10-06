import { useEffect, useMemo, useState } from 'react'
import { Outlet } from 'react-router-dom'
import { AppShell } from '@/components/edvance/shell/AppShell'
import { getDarfPruefen } from '@/lib/supabase/freigabe'
import { coachNav } from './coachNav'
import { useCoachZaehler } from './useCoachZaehler'

/**
 * Hülle der Coach-Seiten (Coach-Sicht H6): dieselbe AppShell wie Admin, mit
 * der Coach-Leiste. Wer sie bekommt, entscheidet die Rollenweiche in
 * AdminLayout; das Prüfrecht fragt die Leiste einmal bei der DB ab.
 */
export function CoachLayout(): JSX.Element {
  const [darfPruefen, setDarfPruefen] = useState(false)
  const zaehler = useCoachZaehler(darfPruefen)
  const konfig = useMemo(() => coachNav(darfPruefen), [darfPruefen])

  useEffect(() => {
    let aktiv = true
    void getDarfPruefen().then((r) => {
      if (aktiv) setDarfPruefen(r.data === true)
    })
    return () => {
      aktiv = false
    }
  }, [])

  return (
    <AppShell konfig={konfig} zaehler={zaehler}>
      <Outlet />
    </AppShell>
  )
}
