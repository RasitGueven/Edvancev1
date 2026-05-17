// Stiller, adaptiver Lernstand-Check (CLAUDE.md §6: das Kind sieht NIE
// richtig/falsch). Auto-Grading + Item-Wahl laufen clientseitig im reinen
// Controller; der Coach ist hier reiner Beobachter (kein Rating, kein
// Coach-View in diesem Flow). P5a: In-Memory-Lauf gegen den freigegebenen
// Item-Pool, robust bei leerem Pool. Persistenz/Resume folgt (P5b).

import { useEffect, useRef, useState } from 'react'
import type { JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { MCWidget } from '@/components/edvance/tasks/MCWidget'
import {
  createAdaptiveSession,
  isComplete,
  nextItem,
  submitAnswer,
  type AdaptiveSession,
} from '@/lib/screening/adaptive'
import {
  buildScreeningAnswer,
  finishScreeningTest,
  isMcPayload,
  loadActiveScreeningPool,
  persistScreeningAnswer,
  resolveScreeningStudentId,
  startOrResumeScreeningTest,
} from '@/lib/screening/screeningRuntime'
import type { ScreeningItem } from '@/types'

type Phase = 'loading' | 'empty' | 'error' | 'running' | 'done'

// Wechselnde, neutrale Ermutigungen — nie wertend (kein richtig/falsch).
const KICKERS = [
  'Weiter geht’s',
  'Nächste Aufgabe',
  'Bleib dran',
  'Du machst das gut',
  'Konzentriert weiter',
]

export function ScreeningSession(): JSX.Element {
  const navigate = useNavigate()
  const { user } = useAuth()
  const sessionRef = useRef<AdaptiveSession | null>(null)
  const startedAtRef = useRef<number>(Date.now())
  const testIdRef = useRef<string | null>(null)
  const initRef = useRef(false)

  const [phase, setPhase] = useState<Phase>('loading')
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [item, setItem] = useState<ScreeningItem | null>(null)
  const [step, setStep] = useState(1)
  const [mcIndex, setMcIndex] = useState<number | null>(null)
  const [text, setText] = useState('')

  useEffect(() => {
    if (initRef.current) return
    initRef.current = true
    void (async () => {
      // Persistenz best effort: scheitert test-start (kein Schüler-Row,
      // RLS …), läuft das Screening trotzdem in-memory weiter.
      if (user?.id) {
        const studentId = await resolveScreeningStudentId(user.id)
        if (studentId) {
          const t = await startOrResumeScreeningTest(studentId)
          testIdRef.current = t.data
        }
      }

      const { data, error } = await loadActiveScreeningPool()
      if (error) {
        setErrorMsg(error)
        setPhase('error')
        return
      }
      const pool = data ?? []
      if (pool.length === 0) {
        setPhase('empty')
        return
      }
      const session = createAdaptiveSession(pool, {})
      sessionRef.current = session
      const first = nextItem(session)
      if (!first) {
        setPhase('empty')
        return
      }
      setItem(first)
      startedAtRef.current = Date.now()
      setPhase('running')
    })()
  }, [user?.id])

  function handleNext(): void {
    const session = sessionRef.current
    if (!session || !item) return
    const answer = buildScreeningAnswer(item, { mcIndex, text })
    const log = submitAnswer(session, answer, Date.now() - startedAtRef.current)
    const testId = testIdRef.current
    if (log && testId) void persistScreeningAnswer(testId, log, answer)

    const next = isComplete(session) ? null : nextItem(session)
    if (!next) {
      if (testId) void finishScreeningTest(testId)
      setPhase('done')
      return
    }
    setItem(next)
    setMcIndex(null)
    setText('')
    setStep((s) => s + 1)
    startedAtRef.current = Date.now()
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Lernstand-Check" sticky />
      <main className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-10">
        {phase === 'loading' && (
          <EdvanceCard className="p-8">
            <LoadingPulse type="card" lines={4} />
          </EdvanceCard>
        )}

        {phase === 'error' && (
          <EmptyState
            icon="⚠️"
            title="Kurz hängen geblieben"
            description={errorMsg ?? 'Bitte später noch einmal versuchen.'}
            action={
              <Button variant="outline" onClick={() => navigate(-1)}>
                Zurück
              </Button>
            }
          />
        )}

        {phase === 'empty' && (
          <EmptyState
            icon="🧩"
            title="Gleich geht’s los"
            description="Für deinen Lernstand-Check sind noch keine Aufgaben freigegeben. Schau später noch einmal vorbei."
            action={
              <Button variant="outline" onClick={() => navigate(-1)}>
                Zurück
              </Button>
            }
          />
        )}

        {phase === 'running' && item && (
          <EdvanceCard
            key={item.id}
            variant="premium"
            className="flex animate-fade-in flex-col gap-6 p-8"
          >
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
              {KICKERS[(step - 1) % KICKERS.length]}
            </p>
            <h1 className="text-xl font-bold leading-snug text-[var(--text-primary)]">
              {item.prompt}
            </h1>

            {item.check_type === 'mc_index' && isMcPayload(item.payload) ? (
              <MCWidget
                options={item.payload.options}
                selected={mcIndex}
                onChange={setMcIndex}
                disabled={false}
              />
            ) : (
              <Input
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder="Deine Antwort …"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleNext()
                }}
              />
            )}

            <Button
              size="lg"
              className="w-full rounded-xl"
              onClick={handleNext}
            >
              Weiter
            </Button>
          </EdvanceCard>
        )}

        {phase === 'done' && (
          <EdvanceCard
            variant="hero"
            className="flex animate-scale-in flex-col items-center gap-4 p-10 text-center"
          >
            <div className="select-none text-6xl leading-none">🎉</div>
            <h1 className="text-2xl font-bold">Geschafft!</h1>
            <p className="max-w-sm text-sm leading-relaxed opacity-90">
              Danke, das hast du richtig gut gemacht. Deinen Lernweg
              besprichst du gleich mit deinem Coach.
            </p>
            <Button
              variant="secondary"
              className="mt-2 rounded-xl"
              onClick={() => navigate(-1)}
            >
              Fertig
            </Button>
          </EdvanceCard>
        )}
      </main>
    </div>
  )
}
