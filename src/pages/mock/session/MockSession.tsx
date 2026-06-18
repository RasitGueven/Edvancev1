import { useReducer, type JSX } from 'react'
import { BossChallengeModal, LevelUpModal, StreakRepairFlow } from '@/components/edvance/moments'
import {
  initSessionState,
  sessionReducer,
  levelFromXp,
  type SessionConfig,
} from '@/lib/mocks/sessionMachine'
import { MOCK_SESSION_STUDENT, MOCK_SESSION_TASKS } from '@/lib/mocks/session'
import { CheckInScreen } from './screens/CheckInScreen'
import { HubScreen } from './screens/HubScreen'
import { GoalScreen } from './screens/GoalScreen'
import { TaskScreen } from './screens/TaskScreen'
import { MasteryScreen } from './screens/MasteryScreen'
import { CompleteScreen } from './screens/CompleteScreen'
import { ProgressScreen } from './screens/ProgressScreen'
import { TrophiesScreen } from './screens/TrophiesScreen'
import type { ScreenProps } from './screenProps'

const CONFIG: SessionConfig = {
  startXp: MOCK_SESSION_STUDENT.startXp,
  presenceWeeks: MOCK_SESSION_STUDENT.presenceWeeks,
  taskCount: MOCK_SESSION_TASKS.length,
  repairTokens: MOCK_SESSION_STUDENT.repairTokens,
}

/**
 * Orchestrator des Vor-Ort-Session-Mocks (`/mock/session`).
 *
 * In-Memory-State über useReducer (keine Persistenz, kein Supabase, kein Auth).
 * Screens 1–11 als Komponenten; Boss (8), Level-Up und Streak-Repair als
 * Overlays aus `@/components/edvance/moments`. Die „max 1×"-Regeln und
 * Navigations-Invarianten liegen in der getesteten Maschine, nicht hier.
 */
export function MockSession(): JSX.Element {
  const [state, dispatch] = useReducer(sessionReducer, CONFIG, initSessionState)

  const screenProps: ScreenProps = { state, dispatch }

  const screen = ((): JSX.Element => {
    switch (state.screen) {
      case 'checkin':
        return <CheckInScreen {...screenProps} />
      case 'hub':
        return <HubScreen {...screenProps} />
      case 'goal':
        return <GoalScreen {...screenProps} />
      case 'task':
        return <TaskScreen key={state.taskIndex} {...screenProps} />
      case 'mastery':
        return <MasteryScreen {...screenProps} />
      case 'complete':
        return <CompleteScreen {...screenProps} />
      case 'progress':
        return <ProgressScreen {...screenProps} />
      case 'trophies':
        return <TrophiesScreen {...screenProps} />
    }
  })()

  return (
    <>
      {screen}

      <BossChallengeModal
        open={state.overlay === 'boss'}
        onClose={() => dispatch({ type: 'DISMISS_BOSS' })}
      />
      <LevelUpModal
        open={state.overlay === 'levelup'}
        onClose={() => dispatch({ type: 'DISMISS_LEVELUP' })}
        level={levelFromXp(state.xp)}
      />
      <StreakRepairFlow
        open={state.overlay === 'streak-repair'}
        tokens={state.repairTokens}
        onUseToken={() => dispatch({ type: 'USE_REPAIR_TOKEN' })}
        onCancel={() => dispatch({ type: 'CLOSE_STREAK_REPAIR' })}
      />
    </>
  )
}
