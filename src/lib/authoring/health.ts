// Die Mängel-Diagnose des Item-Bestands (Content-Gesundheit).
//
// Reine Funktionen über einer tasks-Zeile — keine Lösung, kein Grounding nötig,
// deshalb testbar (health.test.ts). Die Seite /admin/content-gesundheit zeigt nur
// an, WO die Arbeit liegt; korrigiert wird im Editor. Ein Mangel hier ist bewusst
// enger gefasst als ein ItemFlag (flags.ts): es sind die vier Befunde, die sich
// allein aus assets, curriculum_grade und status ablesen lassen.

import type { AuthoringTask, GroundingRecord, TaskAsset } from '@/types'

export type HealthDefect = 'deadPath' | 'stoffankerMissing' | 'altMissing' | 'noAsset'

/** Reihenfolge der Zählerkacheln — toter Pfad zuerst, das ist die eine Aktion. */
export const DEFECT_ORDER: HealthDefect[] = [
  'deadPath',
  'stoffankerMissing',
  'altMissing',
  'noAsset',
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
