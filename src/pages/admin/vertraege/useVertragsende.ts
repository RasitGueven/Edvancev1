import { useEffect, useState, type Dispatch, type SetStateAction } from 'react'
import {
  berechneVertragsende,
  pilotVorschlag,
  type PilotVorschlag,
  type VertragEnde,
} from '@/lib/supabase/vertragEnde'
import { pilotVorschlagFuellen, type VertragFormState } from './vertragForm'

export type Vertragsende = {
  /** Vorschau aus vertrag_ende_berechnen (regulaer); null, solange etwas fehlt. */
  ende: VertragEnde | null
  endeFehler: string | null
  /** V5: Vorschlag aus vertrag_pilot_vorschlag (Pilot). */
  vorschlag: PilotVorschlag | null
  vorschlagFehler: string | null
}

/**
 * Vertragsende aus der Datenbank, nicht aus dem Frontend. Regulaer: Vorschau
 * der Ferienrechnung. Pilot: Vorschlag fuer Ende und Einheiten — er fuellt das
 * Formular, solange dort noch nichts steht.
 */
export function useVertragsende(
  form: VertragFormState | null,
  setForm: Dispatch<SetStateAction<VertragFormState | null>>,
): Vertragsende {
  const [stand, setStand] = useState<Vertragsende>({
    ende: null,
    endeFehler: null,
    vorschlag: null,
    vorschlagFehler: null,
  })
  const beginn = form?.vertragsbeginn ?? ''
  const laufzeit = form?.laufzeit_monate ?? ''
  const pilot = form?.vertragsart === 'pilot'

  useEffect(() => {
    const leer: Vertragsende = { ende: null, endeFehler: null, vorschlag: null, vorschlagFehler: null }
    if (beginn === '' || (!pilot && laufzeit === '')) {
      setStand(leer)
      return
    }
    let aktuell = true
    if (pilot) {
      void pilotVorschlag(beginn).then(({ data, error }) => {
        if (!aktuell) return
        setStand({ ...leer, vorschlag: data, vorschlagFehler: error })
        setForm((f) => {
          const fill = f ? pilotVorschlagFuellen(f, data) : null
          return f && fill ? { ...f, ...fill } : f
        })
      })
    } else {
      void berechneVertragsende(beginn, Number(laufzeit)).then(({ data, error }) => {
        if (aktuell) setStand({ ...leer, ende: data, endeFehler: error })
      })
    }
    return () => {
      aktuell = false
    }
  }, [beginn, laufzeit, pilot, setForm])

  return stand
}
