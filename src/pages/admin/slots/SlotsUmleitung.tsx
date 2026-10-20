import { Navigate, useLocation, useParams } from 'react-router-dom'
import { slotZiel, sucheOhneStundenplan } from './wochenplan/wochenplan.model'

/** W2, Entscheidung 6: Die Termin-Seite ist im Slot-Panel aufgegangen; die alte Adresse öffnet das Panel. */
export function TerminUmleitung(): JSX.Element {
  const { datum = '', zeitId = '' } = useParams()
  return <Navigate to={slotZiel(datum, zeitId)} replace />
}

/** W2, Entscheidung 1: /admin/schedule (früher Stundenplan) landet im Wochenplan; die Woche aus der URL bleibt. */
export function ScheduleUmleitung(): JSX.Element {
  const { search } = useLocation()
  const suche = sucheOhneStundenplan(new URLSearchParams(search)).toString()
  return <Navigate to={suche ? `/admin/slots?${suche}` : '/admin/slots'} replace />
}
