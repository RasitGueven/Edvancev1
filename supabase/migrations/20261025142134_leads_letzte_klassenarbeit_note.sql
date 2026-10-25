-- Bericht v4, Paket V4-E (Bauauftrag V4): Note der zuletzt geschriebenen Klassenarbeit aus dem Erstgespräch.
--
-- leads.letzte_klassenarbeit_note (1–6, optional). Erfasst nur bei „schon geschrieben“ und nur, wenn die
-- Familie sie nennen möchte. Der Bericht zeigt sie an der geschriebenen Station des Fahrplans
-- („geschrieben · Note 4“) und liest sie defensiv (eigene Abfrage, ohne Spalte null).
--
-- RLS: die Spalte fällt unter die bestehende leads-Policy (nur Admin). Keine Rechteänderung.
-- Rollback: supabase/rollback/20261025142134_leads_letzte_klassenarbeit_note.sql.

alter table public.leads
  add column letzte_klassenarbeit_note smallint
  constraint leads_letzte_klassenarbeit_note_check
    check (letzte_klassenarbeit_note between 1 and 6);

comment on column public.leads.letzte_klassenarbeit_note is
  'Bericht v4: Note der zuletzt geschriebenen Klassenarbeit (1–6), nur wenn die Familie sie nennt; null = unbekannt.';
