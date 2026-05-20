// Auto-Grader fuer Screening-Items. Reine, deterministische Funktionen —
// keine Seiteneffekte, defensiv (unbekannte/fehlende Eingabe -> false).
// Das Kind sieht das Ergebnis NIE (CLAUDE.md §6); nur intern/Report.

import type { ScreeningCheckType } from '@/types'

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}

function toNumber(v: unknown): number | null {
  if (typeof v === 'number') return Number.isFinite(v) ? v : null
  if (typeof v === 'string') {
    const n = Number(v.trim().replace(/\s/g, '').replace(',', '.'))
    return Number.isFinite(n) ? n : null
  }
  return null
}

function norm(v: unknown): string | null {
  if (typeof v !== 'string') return null
  return v
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .replace(',', '.')
}

function pairKey(p: unknown): string | null {
  if (!isObj(p) || typeof p.left !== 'string' || typeof p.right !== 'string') {
    return null
  }
  return `${p.left.trim()}|||${p.right.trim()}`
}

function pairSet(raw: unknown): Set<string> | null {
  const arr = isObj(raw) && Array.isArray(raw.pairs) ? raw.pairs : null
  if (!arr) return null
  const set = new Set<string>()
  for (const p of arr) {
    const k = pairKey(p)
    if (k === null) return null
    set.add(k)
  }
  return set
}

// Versucht eine Freitext-/Open-Antwort gegen `accepted` zu matchen (lower-case,
// trim, Whitespace-collapse, Komma→Punkt). Treffer → true, sonst null
// (= unentschieden, wartet auf Coach-Rating). Bewusst kein false: ein nicht
// matchbares Open-Item ist nicht „falsch", sondern braucht manuelles Urteil.
export function tryAutoGradeOpen(
  accepted: string[] | null | undefined,
  rawAnswer: unknown,
): true | null {
  if (!Array.isArray(accepted) || accepted.length === 0) return null
  const a = isObj(rawAnswer)
    ? norm(rawAnswer.text) ?? norm(rawAnswer.value)
    : norm(rawAnswer)
  if (a === null || a === '') return null
  for (const candidate of accepted) {
    const c = norm(candidate)
    if (c !== null && c === a) return true
  }
  return null
}

// Bewertet eine Antwort gegen die kanonische Loesung eines Items.
// Rückgabe: true/false bei klaren Auto-Grading-Cases, null wenn der Fall
// manuell (Coach) entschieden werden muss — DB-Spalte `correct` ist nullable.
export function gradeScreeningAnswer(args: {
  check_type: ScreeningCheckType
  canonical: unknown
  answer: unknown
  tolerance?: number | null
  accepted?: string[] | null
}): boolean | null {
  const { check_type, canonical, answer } = args
  switch (check_type) {
    case 'mc_index': {
      if (!isObj(canonical) || !isObj(answer)) return false
      return (
        typeof canonical.index === 'number' &&
        canonical.index === answer.index
      )
    }
    case 'numeric': {
      const c = isObj(canonical) ? toNumber(canonical.value) : null
      const a = isObj(answer) ? toNumber(answer.value) : toNumber(answer)
      if (c === null || a === null) return false
      const tol = args.tolerance ?? 0
      return Math.abs(a - c) <= Math.abs(tol)
    }
    case 'matching_set': {
      const c = pairSet(canonical)
      const a = pairSet(answer)
      if (!c || !a || c.size !== a.size) return false
      for (const k of c) if (!a.has(k)) return false
      return true
    }
    case 'normalized': {
      const c = isObj(canonical) ? norm(canonical.value) : norm(canonical)
      const a = isObj(answer) ? norm(answer.value) : norm(answer)
      return c !== null && c === a
    }
    case 'manual': {
      // Hybrid: Treffer in akzeptierten Antworten → true; sonst Coach entscheidet.
      const accepted =
        args.accepted ??
        (isObj(canonical) && Array.isArray(canonical.accepted)
          ? (canonical.accepted as string[])
          : null)
      return tryAutoGradeOpen(accepted, answer)
    }
    default:
      return false
  }
}
