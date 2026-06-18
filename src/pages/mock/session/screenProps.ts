import type { Dispatch } from 'react'
import type { SessionState, SessionAction } from '@/lib/mocks/sessionMachine'

/** Gemeinsame Props aller Screens: gelesener State + Dispatch in die Maschine. */
export interface ScreenProps {
  state: SessionState
  dispatch: Dispatch<SessionAction>
}
