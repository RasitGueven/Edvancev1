import { useRef, useState, type JSX } from 'react'
import { MatchingWidget, type MatchPairs } from '../MatchingWidget'
import type { AnswerOption } from '@/types'
import type { TaskAnswerInputProps } from './types'

// Reicht das bestehende MatchingWidget (index-basiert) durch und übersetzt die
// links→rechts-Index-Map zurück in id-Paare für die StudentAnswer.
export function MatchingInput({
  payload,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  const shuffledRef = useRef<AnswerOption[] | null>(null)
  const [map, setMap] = useState<MatchPairs>(new Map())
  if (payload.input_type !== 'MATCHING') return null

  if (shuffledRef.current === null) {
    shuffledRef.current = [...payload.right].sort(() => Math.random() - 0.5)
  }
  const right = shuffledRef.current
  const left = payload.left

  function handleChange(next: MatchPairs): void {
    setMap(next)
    const pairs: [string, string][] = []
    next.forEach((rIdx, lIdx) => {
      const l = left[lIdx]
      const r = right[rIdx]
      if (l && r) pairs.push([l.id, r.id])
    })
    onChange({ input_type: 'MATCHING', pairs })
  }

  return (
    <MatchingWidget
      left={left.map((o) => o.label)}
      right={right.map((o) => o.label)}
      pairs={map}
      onChange={handleChange}
      disabled={disabled ?? false}
    />
  )
}
