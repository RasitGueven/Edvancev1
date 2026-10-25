-- Eltern-Bericht v2 (Auftrag Rasit, 24.10.2026): zwei Spalten, keine neue Tabelle.
--
-- 1. leads.klassenarbeit_status — Stand der Klassenarbeit zum aktuellen Schulthema
--    aus dem Erstgespräch. Steuert die Startlogik der Schwerpunkte im Bericht
--    (src/lib/report/elternbericht/schwerpunkte.ts):
--      'bevorstehend' → zuerst das aktuelle Thema (Vorbereitung auf die Klassenarbeit)
--      'geschrieben'  → zuerst die Voraussetzungen der kommenden Schulthemen
--      null           → unbekannt; der Bericht leitet aus next_exam_date ab oder
--                       nimmt das aktuelle Thema zuerst.
--    Das Datum steht weiter in next_exam_date, das Thema in next_exam_topic.
--
-- 2. lsa_report_notes.paket_bestaetigt — der Coach hat das Paket bestätigt. Bis
--    dahin zeigt Seite 5 den Vorschlag des Systems (paketVorschlag.ts) mit dem
--    Schild „Vorschlag“; danach die Wahl des Coachs (paket) als „Empfehlung“.
--
-- RLS: beide Tabellen haben RLS und Policies; neue Spalten fallen unter dieselben
-- Policies (leads nur Admin, lsa_report_notes Coach/Admin). Keine Rechteänderung.
-- Rollback: supabase/rollback/20261024135226_bericht_v2.sql.

alter table public.leads
  add column klassenarbeit_status text
  constraint leads_klassenarbeit_status_check
    check (klassenarbeit_status in ('bevorstehend', 'geschrieben'));

comment on column public.leads.klassenarbeit_status is
  'Bericht v2: Klassenarbeit zum aktuellen Schulthema bevorstehend oder geschrieben; null = unbekannt.';

alter table public.lsa_report_notes
  add column paket_bestaetigt boolean not null default false;

comment on column public.lsa_report_notes.paket_bestaetigt is
  'Bericht v2: true, wenn der Coach das Paket (paket) bestätigt hat; sonst zeigt der Bericht den Systemvorschlag.';
