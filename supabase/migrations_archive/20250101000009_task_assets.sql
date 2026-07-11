-- ============================================================================
-- Migration 009 – tasks.assets (Bilder / Abbildungen pro Aufgabe)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund:
--   Viele Aufgaben aus dem Mathebuch referenzieren visuelle Hilfsmittel
--   (Wuerfel-Skizzen, Diagramme, Fotos). Ohne sie verliert die Aufgabe
--   Kontext. Daher braucht jede Task die Moeglichkeit, eine geordnete
--   Liste von Assets mitzufuehren.
--
-- Format (validiert auf Client-Seite, nicht in DB):
--   [
--     { "url": "https://...", "alt": "Wuerfel mit ...", "caption": "Abb. 1" },
--     ...
--   ]
--   - url     : Pflicht. Vollstaendige Public-URL (Supabase Storage oder extern).
--   - alt     : Pflicht. Beschreibung fuer Screenreader + Fallback.
--   - caption : optional. Bildunterschrift.
--
--   Speicher-Empfehlung: Supabase Storage Bucket "task-assets" (public).
--   Auto-Upload macht der Importer (noch) nicht – wer JSON erzeugt, ist
--   fuer die URL verantwortlich.
--
-- ⚠️  Voraussetzung: Migration 008 wurde ausgefuehrt.
-- ============================================================================

begin;

alter table tasks
  add column if not exists assets jsonb not null default '[]'::jsonb;

-- Filter-Index: schnelle Abfrage "alle Aufgaben mit mindestens einem Asset"
create index if not exists tasks_has_assets_idx
  on tasks ((jsonb_array_length(assets) > 0))
  where jsonb_array_length(assets) > 0;

commit;
