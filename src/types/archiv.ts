// MSA-1 M3: Archiv der Aufgaben (task_archiv, 20261112153053_msa1_archiv).

/** Grund der Archivierung, wie der CHECK tasks_archiv_grund_check. */
export type ArchivGrund = 'nicht_notwendig' | 'sonstiges'

/** Eine Zeile der Archiv-Seite (RPC task_archiv, nur admin). */
export type ArchivZeile = {
  id: string
  kurztext: string
  skill_key: string | null
  skill_label: string | null
  status: string
  input_type: string | null
  einsatz: string[] | null
  grund: ArchivGrund
  archiviert_am: string
  archiviert_von: string | null
}
