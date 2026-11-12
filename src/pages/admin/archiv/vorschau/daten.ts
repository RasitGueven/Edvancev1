// Vorschau „Archiv“ (MSA-1 M3): Testdaten im Speicher, keine Prod-Daten, keine Personen.
// Drei aktive LSA-Aufgaben, zwei archivierte (nicht_notwendig). Ändert sich nur über task_wiederherstellen.
export type Zeile = Record<string, unknown> & { id: string }

const basis = {
  content_type: 'exercise', input_type: 'NUMERIC', afb: 'I', status: 'draft', skill_key: 'bruch_add', class_level: 6,
  curriculum_grade: 6, parts: [], assets: [], needs_image: false, licence_text: null, question_payload: null,
  source: 'vorschau', source_ref: null, is_active: true, created_at: '2026-11-01T10:00:00Z', einsatz: ['lsa'],
  bauform_id: null, cluster_id: null, archiviert_am: null, archiviert_grund: null, archiviert_von: null, unit: null,
  competency_content: null, competency_process: null, est_duration_sec: 60,
}

export const TASKS: Zeile[] = [
  { ...basis, id: 'a0000000-0000-4000-8000-000000000001', title: 'Aktiv Pizza', question: 'Lea isst 1/4 einer Pizza.' },
  { ...basis, id: 'a0000000-0000-4000-8000-000000000002', title: 'Aktiv Kuchen', question: 'Tom isst 1/3 eines Kuchens.' },
  { ...basis, id: 'a0000000-0000-4000-8000-000000000003', title: 'Aktiv Saft', question: 'Ein Glas ist zu 2/5 gefüllt.', status: 'ready' },
  { ...basis, id: 'b0000000-0000-4000-8000-000000000001', title: 'Archiv Brot', question: 'Ein Brot wird in 8 Teile geteilt.',
    is_active: false, archiviert_am: '2026-11-12T16:00:00Z', archiviert_grund: 'nicht_notwendig' },
  { ...basis, id: 'b0000000-0000-4000-8000-000000000002', title: 'Archiv Torte', question: 'Eine Torte hat 12 Stücke.', status: 'ready',
    is_active: false, archiviert_am: '2026-11-12T16:00:00Z', archiviert_grund: 'nicht_notwendig' },
]
