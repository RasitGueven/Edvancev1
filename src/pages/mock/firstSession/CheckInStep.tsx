import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { cn } from '@/lib/utils'
import {
  MOCK_STUDENT_FIRST_SESSION,
  MOCK_TEACHER_TOPICS,
  type MockMood,
} from '@/lib/mocks/firstSession'

export interface CheckInAnswers {
  mood: MockMood
  moodReason: string
  hasExam: boolean
  teacherTopicIds: string[]
  teacherTopicCustom: string
  goal: string
}

interface CheckInStepProps {
  onComplete: (answers: CheckInAnswers) => void
}

type SubStep = 'mood' | 'mood-reason' | 'exam' | 'topics' | 'goal'

const MOODS: { value: MockMood; emoji: string; labelKey: string }[] = [
  { value: 'happy', emoji: '😊', labelKey: 'firstSession.checkIn.mood.happy' },
  { value: 'neutral', emoji: '😐', labelKey: 'firstSession.checkIn.mood.neutral' },
  { value: 'low', emoji: '😟', labelKey: 'firstSession.checkIn.mood.low' },
]

export function CheckInStep({ onComplete }: CheckInStepProps): JSX.Element {
  const { t } = useTranslation('student')
  const [sub, setSub] = useState<SubStep>('mood')
  const [mood, setMood] = useState<MockMood | null>(null)
  const [moodReason, setMoodReason] = useState<string>('')
  const [hasExam, setHasExam] = useState<boolean | null>(null)
  const [topicIds, setTopicIds] = useState<string[]>([])
  const [topicCustom, setTopicCustom] = useState<string>('')
  const [goal, setGoal] = useState<string>('')

  const advance = (): void => {
    if (sub === 'mood' && mood) {
      setSub(mood === 'happy' ? 'exam' : 'mood-reason')
    } else if (sub === 'mood-reason') {
      setSub('exam')
    } else if (sub === 'exam' && hasExam !== null) {
      setSub('topics')
    } else if (sub === 'topics') {
      setSub('goal')
    } else if (sub === 'goal') {
      onComplete({
        mood: mood ?? 'neutral',
        moodReason: moodReason.trim(),
        hasExam: hasExam ?? false,
        teacherTopicIds: topicIds,
        teacherTopicCustom: topicCustom.trim(),
        goal: goal.trim(),
      })
    }
  }

  const canAdvance =
    (sub === 'mood' && mood !== null) ||
    sub === 'mood-reason' ||
    (sub === 'exam' && hasExam !== null) ||
    sub === 'topics' ||
    sub === 'goal'

  const toggleTopic = (id: string): void => {
    setTopicIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    )
  }

  return (
    <div key={sub} className="flex flex-col gap-6 animate-fly-in">
      <EdvanceCard>
        {sub === 'mood' && <MoodPicker mood={mood} setMood={setMood} t={t} />}
        {sub === 'mood-reason' && (
          <MoodReason value={moodReason} setValue={setMoodReason} t={t} />
        )}
        {sub === 'exam' && (
          <ExamPicker hasExam={hasExam} setHasExam={setHasExam} t={t} />
        )}
        {sub === 'topics' && (
          <TopicsPicker
            topicIds={topicIds}
            toggleTopic={toggleTopic}
            custom={topicCustom}
            setCustom={setTopicCustom}
            t={t}
          />
        )}
        {sub === 'goal' && <GoalPicker goal={goal} setGoal={setGoal} t={t} />}
      </EdvanceCard>

      <button
        type="button"
        onClick={advance}
        disabled={!canAdvance}
        className={cn(
          'min-h-[44px] w-full rounded-[var(--radius-lg)] px-6 py-3',
          'text-sm font-semibold text-white shadow-md transition-all duration-base',
          'bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)]',
          'disabled:cursor-not-allowed disabled:opacity-50',
        )}
      >
        {sub === 'goal'
          ? t('firstSession.checkIn.start')
          : t('firstSession.checkIn.next')}
      </button>
    </div>
  )
}

interface MoodProps {
  mood: MockMood | null
  setMood: (m: MockMood) => void
  t: (key: string) => string
}
function MoodPicker({ mood, setMood, t }: MoodProps): JSX.Element {
  return (
    <div className="flex flex-col gap-5">
      <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
        {t('firstSession.checkIn.mood.question')}
      </h2>
      <div className="grid grid-cols-3 gap-3">
        {MOODS.map((m) => (
          <button
            key={m.value}
            type="button"
            onClick={() => setMood(m.value)}
            className={cn(
              'flex flex-col items-center justify-center gap-2 min-h-[96px]',
              'rounded-[var(--radius-lg)] border-2 p-4 transition-all duration-base ease-bounce',
              mood === m.value
                ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] hover:-translate-y-0.5 hover:shadow-md',
            )}
          >
            <span className="text-4xl leading-none" aria-hidden="true">
              {m.emoji}
            </span>
            <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
              {t(m.labelKey)}
            </span>
          </button>
        ))}
      </div>
    </div>
  )
}

interface MoodReasonProps {
  value: string
  setValue: (v: string) => void
  t: (key: string) => string
}
function MoodReason({ value, setValue, t }: MoodReasonProps): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
        {t('firstSession.checkIn.moodReason.question')}
      </h2>
      <p className="text-xs text-[var(--color-text-tertiary)]">
        {t('firstSession.checkIn.moodReason.hint')}
      </p>
      <textarea
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={t('firstSession.checkIn.moodReason.placeholder')}
        rows={3}
        className={cn(
          'rounded-[var(--radius-md)] border border-[var(--color-border)]',
          'bg-[var(--color-bg-surface)] px-4 py-3 text-sm text-[var(--color-text-primary)]',
          'focus:border-[var(--color-primary)] focus:outline-none resize-none',
        )}
      />
    </div>
  )
}

interface ExamProps {
  hasExam: boolean | null
  setHasExam: (v: boolean) => void
  t: (key: string, opts?: Record<string, unknown>) => string
}
function ExamPicker({ hasExam, setHasExam, t }: ExamProps): JSX.Element {
  return (
    <div className="flex flex-col gap-5">
      <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
        {t('firstSession.checkIn.exam.question', {
          subject: MOCK_STUDENT_FIRST_SESSION.subject,
        })}
      </h2>
      <div className="grid grid-cols-2 gap-3">
        {[
          { value: true, labelKey: 'firstSession.checkIn.exam.yes' },
          { value: false, labelKey: 'firstSession.checkIn.exam.no' },
        ].map((opt) => (
          <button
            key={String(opt.value)}
            type="button"
            onClick={() => setHasExam(opt.value)}
            className={cn(
              'min-h-[56px] rounded-[var(--radius-lg)] border-2 p-4',
              'text-sm font-semibold transition-all duration-base ease-bounce',
              hasExam === opt.value
                ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:-translate-y-0.5 hover:shadow-md',
            )}
          >
            {t(opt.labelKey)}
          </button>
        ))}
      </div>
    </div>
  )
}

interface TopicsProps {
  topicIds: string[]
  toggleTopic: (id: string) => void
  custom: string
  setCustom: (v: string) => void
  t: (key: string) => string
}
function TopicsPicker({
  topicIds,
  toggleTopic,
  custom,
  setCustom,
  t,
}: TopicsProps): JSX.Element {
  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
          {t('firstSession.checkIn.teacherTopics.question')}
        </h2>
        <p className="text-xs text-[var(--color-text-tertiary)]">
          {t('firstSession.checkIn.teacherTopics.hint')}
        </p>
      </div>

      <div className="flex flex-wrap gap-2">
        {MOCK_TEACHER_TOPICS.map((topic) => {
          const active = topicIds.includes(topic.id)
          return (
            <button
              key={topic.id}
              type="button"
              onClick={() => toggleTopic(topic.id)}
              className={cn(
                'min-h-[44px] rounded-[var(--radius-full)] border-2 px-4 py-2',
                'text-sm font-semibold transition-all duration-base ease-bounce',
                active
                  ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:-translate-y-0.5 hover:shadow-md',
              )}
            >
              {active ? '✓ ' : ''}
              {topic.name}
            </button>
          )
        })}
      </div>

      <div className="flex flex-col gap-2">
        <label
          htmlFor="teacher-topics-custom"
          className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]"
        >
          {t('firstSession.checkIn.teacherTopics.customLabel')}
        </label>
        <input
          id="teacher-topics-custom"
          type="text"
          value={custom}
          onChange={(e) => setCustom(e.target.value)}
          placeholder={t('firstSession.checkIn.teacherTopics.customPlaceholder')}
          className={cn(
            'min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)]',
            'bg-[var(--color-bg-surface)] px-4 py-2 text-sm text-[var(--color-text-primary)]',
            'focus:border-[var(--color-primary)] focus:outline-none',
          )}
        />
      </div>
    </div>
  )
}

interface GoalProps {
  goal: string
  setGoal: (v: string) => void
  t: (key: string) => string
}
function GoalPicker({ goal, setGoal, t }: GoalProps): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
        {t('firstSession.checkIn.goal.question')}
      </h2>
      <p className="text-xs text-[var(--color-text-tertiary)]">
        {t('firstSession.checkIn.goal.hint')}
      </p>
      <textarea
        value={goal}
        onChange={(e) => setGoal(e.target.value)}
        placeholder={t('firstSession.checkIn.goal.placeholder')}
        rows={3}
        className={cn(
          'rounded-[var(--radius-md)] border border-[var(--color-border)]',
          'bg-[var(--color-bg-surface)] px-4 py-3 text-sm text-[var(--color-text-primary)]',
          'focus:border-[var(--color-primary)] focus:outline-none resize-none',
        )}
      />
    </div>
  )
}
