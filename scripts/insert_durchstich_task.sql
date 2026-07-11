-- ─────────────────────────────────────────────────────────────────────────────
-- Durchstich S — EINE echte VERA-8 MC-Aufgabe MIT BILD im Schüler-Player.
--
-- Quelle:  data/vera8_komplett_enriched.json → "Der Stern" (VERA8_IQB, CC BY 4.0)
--          Aufgabe: Flächeninhalt eines Sterns auf 1-cm-Gitter, 4 MC-Optionen.
--          Lösung laut Auswertung: 3. Kästchen = "16 cm²" → correct_index = 2.
--
-- VERTRAG: Stack A — Route /student/task/:taskId (TaskPlayer + TaskAnswerArea).
--          Dieser Renderer liest task.input_type = 'MC' und task.question_payload
--          im MCPayload-Format aus src/types/payloads.ts:
--              { "type": "mc", "options": string[], "correct_index": number }
--          (NICHT das AnswerPayload/MCAnswerPayload-Format der Präsenz-Session —
--           siehe RETRO-Durchstich.md, Abschnitt „Welcher Vertrag".)
--
-- cluster_id BEWUSST NULL: hält das Item aus der Präsenz-Session heraus, deren
--          Renderer (Stack B) ein ANDERES question_payload-Format erwartet. Der
--          Durchstich läuft ausschließlich über die Direkt-Route.
--
-- BILD:    Muss vor dem Insert in den öffentlichen Storage-Bucket `task-assets`.
--          Die Quelldatei data/vera8_assets/derstern/aufgabe_01.emf ist ein
--          Windows-Metafile (EMF) und NICHT browserfähig → erst nach PNG
--          konvertieren, dann hochladen. Schritte: siehe RETRO-Durchstich.md.
--          Passe unten <PROJECT_REF> an deine Supabase-Projekt-URL an.
--
-- Ausführen: Supabase SQL Editor (als Service-Rolle). Idempotent via
--          UNIQUE(source, source_ref) → erneutes Ausführen aktualisiert die Zeile.
-- ─────────────────────────────────────────────────────────────────────────────

insert into tasks (
  id,
  source,
  source_ref,
  content_type,
  title,
  question,
  input_type,
  is_diagnostic,
  is_active,
  class_level,
  difficulty,
  estimated_minutes,
  cognitive_type,
  question_payload,
  assets
) values (
  'b048eb46-8fe0-5e88-b4cf-4d90a6903812',
  'VERA8_IQB',
  'derstern',
  'exercise',
  'Der Stern',
  E'Wie groß ist der Flächeninhalt des abgebildeten Sterns?\n\nKreuze an.',
  'MC',
  false,
  true,
  8,
  2,
  3,
  'TRANSFER',
  '{"type":"mc","options":["7 cm²","12 cm²","16 cm²","20 cm²"],"correct_index":2}'::jsonb,
  jsonb_build_array(
    jsonb_build_object(
      'url',     'https://<PROJECT_REF>.supabase.co/storage/v1/object/public/task-assets/durchstich/derstern.png',
      'alt',     'Ein aus Quadraten zusammengesetzter Stern auf einem Zentimeter-Gitter (nicht maßstabsgerecht).',
      'caption', '1 Kästchen = 1 cm · Abbildung: IQB VERA-8, CC BY 4.0.'
    )
  )
)
on conflict (source, source_ref) do update set
  content_type     = excluded.content_type,
  title            = excluded.title,
  question         = excluded.question,
  input_type       = excluded.input_type,
  is_diagnostic    = excluded.is_diagnostic,
  is_active        = excluded.is_active,
  class_level      = excluded.class_level,
  difficulty       = excluded.difficulty,
  cognitive_type   = excluded.cognitive_type,
  question_payload = excluded.question_payload,
  assets           = excluded.assets;

-- Verifikation nach dem Insert:
--   select id, title, input_type, question_payload, assets
--   from tasks where source = 'VERA8_IQB' and source_ref = 'derstern';
-- Test-Route (siehe RETRO):
--   /student/task/b048eb46-8fe0-5e88-b4cf-4d90a6903812
