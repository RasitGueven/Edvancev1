import { readFileSync } from 'node:fs'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { completeTask } from '@/lib/supabase/taskProgress'
import { grantMastery } from '@/lib/supabase/competencyMastery'
import { evaluate } from '@/lib/answer/evaluators'
import { SessionWork } from './SessionWork'
import type { SessionTask } from './sessionQueue'

// Kein echter Supabase-/RPC-Call: die Session persistiert über denselben
// serverseitigen Pfad wie /student/task/:taskId (RPC complete_task).
vi.mock('@/lib/supabase/taskProgress', () => ({ completeTask: vi.fn() }))

// FernUSG-Wächter: der EINZIGE Client-Pfad, der Mastery schreibt (vgl. INV-1).
// Wird hier gespiegelt, damit ein versehentlicher Aufruf sichtbar würde.
vi.mock('@/lib/supabase/competencyMastery', () => ({ grantMastery: vi.fn() }))

vi.mock('@/lib/answer/evaluators', () => ({ evaluate: vi.fn() }))

// KaTeX-Rendering ist hier irrelevant.
vi.mock('@/lib/render/MathContent', () => ({
  MathContent: ({ text }: { text: string }) => <span>{text}</span>,
}))

// Die Renderer-Registry ist separat getestet; hier zählt nur der Persistenz-Flow.
vi.mock('@/components/edvance/tasks/answer', () => ({
  TaskAnswer: () => <div data-testid="answer-input" />,
  emptyAnswer: () => ({ input_type: 'NUMERIC', value: '' }),
  isAnswerReady: () => true,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

const completeTaskMock = vi.mocked(completeTask)
const grantMasteryMock = vi.mocked(grantMastery)
const evaluateMock = vi.mocked(evaluate)

const TASKS: SessionTask[] = [
  { id: 'task-a', prompt: 'Frage A', payload: { input_type: 'NUMERIC', accepted: [2] } },
  { id: 'task-b', prompt: 'Frage B', payload: { input_type: 'NUMERIC', accepted: [3] } },
]

function check(): void {
  fireEvent.click(screen.getByRole('button', { name: 'session.work.check' }))
}
function advance(name: 'session.work.next' | 'session.work.finish'): void {
  fireEvent.click(screen.getByRole('button', { name }))
}

beforeEach(() => {
  vi.clearAllMocks()
  evaluateMock.mockReturnValue({ correct: true })
  completeTaskMock.mockResolvedValue({
    data: { newly_completed: true, awarded_xp: 10 },
    error: null,
  })
})

describe('SessionWork — Persistenz über complete_task', () => {
  it('persistiert die abgegebene Aufgabe mit ihrer echten DB-id', async () => {
    render(<SessionWork tasks={TASKS} onDone={vi.fn()} />)
    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalledWith('task-a'))
    expect(completeTaskMock).toHaveBeenCalledTimes(1)
  })

  it('persistiert auch bei falscher Antwort — Abschluss zählt Abgabe, nicht Korrektheit', async () => {
    evaluateMock.mockReturnValue({ correct: false })
    render(<SessionWork tasks={TASKS} onDone={vi.fn()} />)
    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalledWith('task-a'))
  })

  it('persistiert jede Aufgabe des Durchlaufs und summiert die vergebenen XP', async () => {
    const onDone = vi.fn()
    render(<SessionWork tasks={TASKS} onDone={onDone} />)

    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalledWith('task-a'))
    advance('session.work.next')

    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalledWith('task-b'))
    advance('session.work.finish')

    expect(onDone).toHaveBeenCalledWith({ solved: 2, xp: 20 })
  })

  it('zählt keine XP, wenn die Aufgabe serverseitig schon abgeschlossen war', async () => {
    completeTaskMock.mockResolvedValue({
      data: { newly_completed: false, awarded_xp: 0 },
      error: null,
    })
    const onDone = vi.fn()
    render(<SessionWork tasks={[TASKS[0]]} onDone={onDone} />)

    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalled())
    advance('session.work.finish')

    expect(onDone).toHaveBeenCalledWith({ solved: 1, xp: 0 })
  })

  it('blockiert die Session nicht, wenn die Persistenz fehlschlägt', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
    completeTaskMock.mockResolvedValue({ data: null, error: 'RPC down' })
    const onDone = vi.fn()
    render(<SessionWork tasks={[TASKS[0]]} onDone={onDone} />)

    check()
    await waitFor(() => expect(consoleError).toHaveBeenCalled())
    advance('session.work.finish')

    expect(onDone).toHaveBeenCalledWith({ solved: 1, xp: 0 })
    consoleError.mockRestore()
  })
})

// FernUSG / CLAUDE §11: „Mastered" darf ausschließlich der Coach setzen
// (grantMastery + DB-Gate-Trigger). Die Session vergibt Fortschritt + XP —
// niemals Mastery. Regression-Guard analog INV-1.
describe('SessionWork — FernUSG: keine automatische Mastery', () => {
  it('schreibt über einen vollständigen Durchlauf keine Mastery', async () => {
    render(<SessionWork tasks={TASKS} onDone={vi.fn()} />)

    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalledWith('task-a'))
    advance('session.work.next')
    check()
    await waitFor(() => expect(completeTaskMock).toHaveBeenCalledWith('task-b'))
    advance('session.work.finish')

    expect(grantMasteryMock).not.toHaveBeenCalled()
  })

  // Stärker als „wurde nicht aufgerufen": im Session-Flow existiert gar kein
  // Codepfad zu einem Mastery-Writer. Bricht, sobald jemand einen importiert.
  it.each(['SessionWork.tsx', 'sessionQueue.ts', 'StudentSession.tsx'])(
    '%s importiert keinen Mastery-Writer',
    (file) => {
      const source = readFileSync(new URL(file, import.meta.url), 'utf8')
      expect(source).not.toMatch(/grantMastery|student_competency_mastery/)
    },
  )
})
