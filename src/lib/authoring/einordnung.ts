// Einordnung einer Aufgabe in der Pflege-Strecke: Themengebiet (= Cluster) und
// Inhaltsfeld (competency_content).
//
// Das Inhaltsfeld ist die Leitidee der Bildungsstandards — vier Werte im
// Bestand. Es haengt fachlich eng am Cluster; daraus kommt der VORSCHLAG. Er
// wird nie still gesetzt, sondern wie beim Stoffanker angeboten und bestaetigt.
// Gemessen am Bestand (22.09.2026): "Algebra & Funktionen" traegt beide Werte
// etwa gleich oft (funktionen 42, arithmetik_algebra 34) — dort bleibt der
// Vorschlag bewusst ein Vorschlag.
//
// Reine Funktionen, kein React, kein Supabase — testbar (einordnung.test.ts).

/** Die Inhaltsfelder des Bestands. Anzeige ueber authoring:inhaltsfeld.*. */
export const INHALTSFELDER = [
  'arithmetik_algebra',
  'funktionen',
  'geometrie',
  'stochastik',
] as const

const VORSCHLAG_JE_CLUSTER: Record<string, string> = {
  'Zahl & Rechnen': 'arithmetik_algebra',
  'Algebra & Funktionen': 'funktionen',
  'Geometrie & Messen': 'geometrie',
  'Daten & Zufall': 'stochastik',
  'Sachrechnen & Modellieren': 'arithmetik_algebra',
}

/** Vorschlag fuer das Inhaltsfeld aus dem Cluster-Namen; null = keiner. */
export function inhaltsfeldVorschlag(clusterName: string | null | undefined): string | null {
  if (!clusterName) return null
  return VORSCHLAG_JE_CLUSTER[clusterName] ?? null
}

/**
 * Die Flag-Codes, die Schritt 4 direkt setzbar macht. Alle anderen
 * blockierenden Befunde brauchen den Editor.
 */
export const DIREKT_SETZBAR = [
  'clusterMissing',
  'competencyMissing',
  'afbMissing',
  'stoffankerMissing',
] as const

export type DirektSetzbar = (typeof DIREKT_SETZBAR)[number]

export function istDirektSetzbar(code: string): code is DirektSetzbar {
  return (DIREKT_SETZBAR as readonly string[]).includes(code)
}
