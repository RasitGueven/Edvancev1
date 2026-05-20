-- ============================================================================
-- Migration 029 – screening_items als VERA-8-Itembank-Basis
--
-- VERA-8 IQB ist die erste Source-of-Truth für Screening-Aufgaben. Im
-- Gegensatz zu den selbstgebauten Edvance-Items haben VERA-Aufgaben:
--   - keinen Cluster-Bezug (Leitideen L1..L5 statt skill_clusters)
--   - keinen festen input_type-Code (Aufgabe kann mehrteilig/offen sein)
--   - eine Coach-Kodierung statt Auto-Grading (input_type=OPEN, check_type=manual,
--     bereits durch Migration 028 zugelassen)
--
-- Konsequenz: bisherige NOT NULL-Constraints (cluster_id, topic, skill_code,
-- skill_label, level, prompt, canonical) werden gelockert. VERA-Felder
-- kommen als eigene Spalten dazu, Rohdaten landen in meta jsonb.
-- iqb_titel ist UNIQUE => Idempotenz im Seed-Script.
--
-- Keine RLS-Aenderung. FKs aus screening_item_results/_ratings bleiben.
-- ============================================================================

alter table screening_items
  alter column cluster_id  drop not null,
  alter column topic       drop not null,
  alter column skill_code  drop not null,
  alter column skill_label drop not null,
  alter column level       drop not null,
  alter column prompt      drop not null,
  alter column canonical   drop not null;

alter table screening_items
  add column if not exists iqb_titel             text,
  add column if not exists kompetenzfelder       text[],
  add column if not exists aufgabe_typ           text,
  add column if not exists teilaufgaben          jsonb,
  add column if not exists kontext               text,
  add column if not exists loesung_pro_ta        jsonb,
  add column if not exists akzeptierte_antworten jsonb,
  add column if not exists kodierung             text,
  add column if not exists kommentar_highlights  jsonb,
  add column if not exists urls                  jsonb,
  add column if not exists datei_ext             text,
  add column if not exists quelle                text,
  add column if not exists fix_anker             boolean default false,
  add column if not exists meta                  jsonb;

alter table screening_items
  add constraint screening_items_iqb_titel_uniq unique (iqb_titel);

create index if not exists screening_items_quelle_idx
  on screening_items (quelle);
