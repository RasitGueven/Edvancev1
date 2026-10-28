import { useCallback, useEffect, useState } from 'react'
import { reiheCoachLesen } from '@/lib/supabase/reihe'
import type { ReiheCoach } from '@/types/reihe'

/** Reihe 1 C1: Reihenplan eines Kindes für die Coach-Sicht; neu laden nach einer Änderung über setzen(). */
export function useReihe(studentId: string): {
  reihe: ReiheCoach | null; laedt: boolean; fehler: boolean; setzen: (r: ReiheCoach | null) => void; neuLaden: () => void
} {
  const [reihe, setReihe] = useState<ReiheCoach | null>(null)
  const [laedt, setLaedt] = useState(true)
  const [fehler, setFehler] = useState(false)
  const [takt, setTakt] = useState(0)

  useEffect(() => {
    let aktiv = true
    setLaedt(true)
    void reiheCoachLesen(studentId).then((r) => {
      if (!aktiv) return
      setReihe(r.data ?? null)
      setFehler(r.error !== null)
      setLaedt(false)
    })
    return () => { aktiv = false }
  }, [studentId, takt])

  const neuLaden = useCallback(() => setTakt((x) => x + 1), [])
  return { reihe, laedt, fehler, setzen: setReihe, neuLaden }
}
