// Eltern-Report — Erzählung v1 (GENERISCH GENERIERT).
//
// ⚠️  v1-PLATZHALTER. Dieser Block formuliert die auffälligsten Befunde aus den
// Zahlen: Bearbeitungszeit im Vergleich zum Median der Sitzung plus
// ausgelassene Aufgaben. Er kennt KEINE fachliche Kausalität.
// Die spätere System-Erzählung mit Voraussetzungs-Kausalkette („X wackelt, weil
// die Voraussetzung Y fehlt") ersetzt diese Datei vollständig.
//
// Invarianten (CLAUDE §6 + Report-Leitplanken): kein Gesamtscore, keine Note,
// keine Prozentränge. Vergleiche laufen ausschließlich INNERHALB der Sitzung
// (Thema gegen Thema desselben Kindes), nie gegen eine Kohorte.

import type { ReportTopic } from '@/types'

// „1:30 min" / „0:26 min" — die stärkste Zahl des Reports, deshalb bewusst
// menschlich und nicht als Millisekunden oder Dezimalminuten.
export function formatDuration(ms: number | null): string | null {
  if (ms === null || !Number.isFinite(ms) || ms <= 0) return null
  const totalSeconds = Math.round(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${String(seconds).padStart(2, '0')} min`
}

// Nur Themen mit echtem Bearbeitungssignal taugen als Beleg.
const answeredTopics = (topics: ReportTopic[]) =>
  topics.filter((t) => t.answered > 0)

function hitRate(t: ReportTopic): number {
  return t.answered > 0 ? t.correct / t.answered : 0
}

function median(values: number[]): number | null {
  if (values.length === 0) return null
  const sorted = [...values].sort((a, b) => a - b)
  const mid = Math.floor(sorted.length / 2)
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid]
}

// Die Stärke: bestes Verhältnis richtig/bearbeitet, bei Gleichstand die
// zügigere Bearbeitung. Bewusst EIN Thema — der Abschnitt soll tragen, nicht
// relativieren.
export function pickStrength(topics: ReportTopic[]): ReportTopic | null {
  const candidates = answeredTopics(topics)
  if (candidates.length === 0) return null
  return candidates.reduce((best, t) => {
    const d = hitRate(t) - hitRate(best)
    if (d > 0) return t
    if (d < 0) return best
    return (t.avgDurationMs ?? Infinity) < (best.avgDurationMs ?? Infinity)
      ? t
      : best
  })
}

// Auffällig = deutlich langsamer als der Median der Sitzung (Faktor 1.5) ODER
// ausgelassene Aufgaben. Die Stärke wird nie zugleich als Problem geführt.
export function pickConcerns(topics: ReportTopic[]): ReportTopic[] {
  const strength = pickStrength(topics)
  const durations = answeredTopics(topics)
    .map((t) => t.avgDurationMs)
    .filter((d): d is number => d !== null)
  const med = median(durations)

  return topics
    .filter((t) => t.topic !== strength?.topic)
    .filter((t) => {
      const slow =
        med !== null && t.avgDurationMs !== null && t.avgDurationMs > med * 1.5
      return slow || t.skipped > 0
    })
    .sort((a, b) => (b.avgDurationMs ?? 0) - (a.avgDurationMs ?? 0))
    .slice(0, 2)
}

export type NarrativeInput = {
  firstName: string | null
  topics: ReportTopic[]
}

// 2–3 Sätze. Erst die Stärke, dann die Auffälligkeiten — die Dramaturgie des
// Gesprächs beginnt schon hier.
export function buildNarrative({ firstName, topics }: NarrativeInput): string[] {
  const name = firstName?.trim() || 'Ihr Kind'
  const sentences: string[] = []

  const strength = pickStrength(topics)
  if (strength) {
    const time = formatDuration(strength.avgDurationMs)
    sentences.push(
      time
        ? `Bei ${strength.topic} arbeitete ${name} sicher und zügig — im Schnitt ${time} pro Aufgabe.`
        : `Bei ${strength.topic} arbeitete ${name} sicher.`,
    )
  }

  for (const c of pickConcerns(topics)) {
    const time = formatDuration(c.avgDurationMs)
    if (c.skipped > 0 && time) {
      sentences.push(
        `Bei ${c.topic} brauchte ${name} deutlich länger (${time} pro Aufgabe) und ließ ${c.skipped} Aufgabe${c.skipped === 1 ? '' : 'n'} aus.`,
      )
    } else if (c.skipped > 0) {
      sentences.push(
        `Bei ${c.topic} ließ ${name} ${c.skipped} Aufgabe${c.skipped === 1 ? '' : 'n'} aus.`,
      )
    } else if (time) {
      sentences.push(
        `Bei ${c.topic} brauchte ${name} deutlich länger als bei den übrigen Themen — im Schnitt ${time} pro Aufgabe.`,
      )
    }
  }

  if (sentences.length === 0) {
    sentences.push(
      `Für ${name} liegen noch zu wenige bearbeitete Aufgaben vor, um Auffälligkeiten zu beschreiben.`,
    )
  }
  return sentences
}
