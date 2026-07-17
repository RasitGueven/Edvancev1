// Die Mängel-Diagnose des Item-Bestands (Content-Gesundheit).
//
// Reine Funktionen über einer tasks-Zeile — keine Lösung, kein Grounding nötig,
// deshalb testbar (health.test.ts). Die Seite /admin/content-gesundheit zeigt nur
// an, WO die Arbeit liegt; korrigiert wird im Editor. Ein Mangel hier ist bewusst
// enger gefasst als ein ItemFlag (flags.ts): es sind die vier Befunde, die sich
// allein aus assets, curriculum_grade und status ablesen lassen.

import type { AuthoringTask, GroundingRecord, TaskAsset } from '@/types'

export type HealthDefect =
  | 'deadPath'
  | 'stoffankerMissing'
  | 'altMissing'
  | 'noAsset'
  | 'imageRefNoAsset'

/** Reihenfolge der Zählerkacheln — toter Pfad zuerst, das ist die eine Aktion. */
export const DEFECT_ORDER: HealthDefect[] = [
  'deadPath',
  'stoffankerMissing',
  'altMissing',
  'noAsset',
  'imageRefNoAsset',
]

/**
 * Ein toter Bildpfad: ein relativer Render-Pfad (data/r01_render/<slug>/…) statt
 * einer echten Bucket-URL. Zu diesen Pfaden existiert KEIN Bild im Bucket
 * task-assets — C09 hat sie wegen Lizenz nicht hochgeladen. Erkennung: nicht-leer
 * und kein http(s)-Präfix. Eine Bucket-URL beginnt immer mit https://.
 */
export function isDeadAssetUrl(url: string): boolean {
  const u = url.trim()
  return u !== '' && !/^https?:\/\//i.test(u)
}

/** Die Asset-Einträge eines Items, deren Pfad tot ist. */
export function deadAssets(task: AuthoringTask): TaskAsset[] {
  return task.assets.filter((a) => isDeadAssetUrl(a.url))
}

/**
 * Verweis-Heuristik: Textstellen, die auf eine Abbildung deuten.
 *
 * Bewusst großzügig — das ist eine VORAUSWAHL, kein Urteil. Ein Treffer ist ein
 * Verdacht, den ein Mensch sichtet: „rechts" meint „rechts im Bild" ODER „rechts
 * in der Gleichung". „abbildung" fängt allein schon viel; die Alternativen decken
 * Wörter ab (figur, grafik, skizze, schaubild …), die sonst durchrutschen würden.
 * `folgende[nr]?` fängt „folgende/folgenden/folgender". Case-insensitive.
 */
const IMAGE_REF_RE =
  /abbildung|abgebildet|dargestellt|nebenstehend|schraffiert|eingezeichnet|siehe\s+(?:bild|grafik|figur|zeichnung|skizze)|in\s+der\s+(?:figur|grafik|zeichnung|skizze|abbildung)|im\s+bild|folgende[nr]?\s+(?:abbildung|grafik|figur|diagramm|schaubild)/i

/**
 * Eine gefundene Verdachtsstelle: WO der Verweis steht (Fragetext oder Nummer der
 * Teilaufgabe), das getroffene Verweiswort und ein Textausschnitt drumherum —
 * damit der Pfleger sofort sieht, worauf sich der Verweis bezieht.
 */
export type ImageRefFinding = {
  source: 'question' | number
  match: string
  excerpt: string
}

/** Hat das Item ein echtes Bild? Nur eine http(s)-URL zählt — kein relativer Pfad. */
export function hasRealAsset(task: AuthoringTask): boolean {
  return (task.assets ?? []).some((a) => /^https?:\/\//i.test(a.url.trim()))
}

/** Ein Fenster um die Fundstelle, mit „…" wo gekürzt wird. Reine Textkosmetik. */
function excerptAround(text: string, start: number, length: number): string {
  const PAD = 45
  const from = Math.max(0, start - PAD)
  const to = Math.min(text.length, start + length + PAD)
  const prefix = from > 0 ? '… ' : ''
  const suffix = to < text.length ? ' …' : ''
  return prefix + text.slice(from, to).trim() + suffix
}

/**
 * Verweist der Text auf ein Bild, obwohl kein echtes Asset da ist? Textquelle ist
 * `tasks.question` UND die `parts`-Prompts — NICHT question_payload (das ist die
 * leere Client-Hülle). Der Fragetext hat Vorrang; sonst die erste Teilaufgabe mit
 * Treffer. Gibt es ein echtes Asset, ist es kein Verdacht — dann existiert das
 * Bild, auf das der Text verweist. Rein und getestet — fällt keine Entscheidung.
 */
export function imageRefFinding(task: AuthoringTask): ImageRefFinding | null {
  if (hasRealAsset(task)) return null

  const question = task.question ?? ''
  const inQuestion = question.match(IMAGE_REF_RE)
  if (inQuestion && inQuestion.index != null) {
    return {
      source: 'question',
      match: inQuestion[0],
      excerpt: excerptAround(question, inQuestion.index, inQuestion[0].length),
    }
  }

  for (const part of task.parts ?? []) {
    const prompt = part.prompt ?? ''
    const inPart = prompt.match(IMAGE_REF_RE)
    if (inPart && inPart.index != null) {
      return {
        source: part.nr,
        match: inPart[0],
        excerpt: excerptAround(prompt, inPart.index, inPart[0].length),
      }
    }
  }

  return null
}

/**
 * Welche Mängel hat dieses Item?
 *
 * `hasStoffanker` = false heißt: die Spalte curriculum_grade existiert in dieser
 * DB nicht (A01 nicht eingespielt). Dann ist ein fehlender Stoffanker kein Mangel
 * des Pflegers, sondern ein fehlendes Feld — er zählt nicht (Spiegel von flags.ts).
 */
export function computeDefects(
  task: AuthoringTask,
  hasStoffanker: boolean,
): Set<HealthDefect> {
  const defects = new Set<HealthDefect>()

  if (deadAssets(task).length > 0) defects.add('deadPath')
  if (hasStoffanker && task.curriculum_grade == null) defects.add('stoffankerMissing')
  // Bild ohne Alt-Text: ein vorhandenes Asset mit leerem Alt — blockiert Freigabe.
  if (task.assets.some((a) => a.url.trim() !== '' && a.alt.trim() === '')) {
    defects.add('altMissing')
  }
  if (task.assets.length === 0) defects.add('noAsset')
  // Verdacht (kein Urteil): Text verweist auf ein Bild, das nicht als Asset da ist.
  if (imageRefFinding(task) != null) defects.add('imageRefNoAsset')

  return defects
}

export type DefectCounts = Record<HealthDefect, number>

/** Zähler pro Mangel über eine Liste bereits diagnostizierter Items. */
export function countDefects(items: { defects: Set<HealthDefect> }[]): DefectCounts {
  const counts: DefectCounts = {
    deadPath: 0,
    stoffankerMissing: 0,
    altMissing: 0,
    noAsset: 0,
    imageRefNoAsset: 0,
  }
  for (const item of items) {
    for (const defect of item.defects) counts[defect] += 1
  }
  return counts
}

/**
 * Lizenzhinweise aus dem Grounding, die die Grafik betreffen.
 *
 * Der tote Pfad ist meist genau der Grund, warum das Bild fehlt: die IQB-Lizenz
 * deckt oft nur Text und Teilaufgaben, nicht die Abbildung. Diese Zeilen stehen
 * als _flags / _import_flags im Grounding-Index — wir zeigen sie, statt sie neu zu
 * formulieren. Read-only.
 */
export function graphicLicenseHints(record: GroundingRecord | null): string[] {
  if (!record) return []
  const all = [...(record.flags ?? []), ...(record.import_flags ?? [])]
  return all.filter((line) => /grafik|abbildung|graphic|lizenz|license/i.test(line))
}
