-- FR-2 F4.1 (09.11.2026): Einstiegsknoten für Themen der Klassen 8–10 ohne thema_einstieg.
-- Vorschlag und fachliche Zweitprüfung: docs/freigabe/fr2/einstiege-vorschlag.md. Nur die drei ohne Einwand
-- bestätigten Einstiege; rationale_zahlen → potenzen ist strittig und bleibt offen für Rasit.
-- Nur Daten. Idempotent; im CI-Neuaufbau fehlen Skills oder Themen evtl., dann trifft das Insert 0 Zeilen.
-- Kein begin/commit: mig klammert. Rollback: supabase/rollback/20261109130447_fr2_einstiege.sql

insert into public.thema_einstieg (thema_key, skill_key)
select v.thema_key, v.skill_key
  from (values ('rationale_zahlen', 'vorzeichen_vorrang'),
               ('zuordnungen', 'proportionalitaet'),
               ('statistik_beurteilen', 'stoch_bedingt_irrefuehrend')) v(thema_key, skill_key)
  join public.themen th on th.thema_key = v.thema_key
  join public.skills s on s.skill_key = v.skill_key
on conflict (thema_key, skill_key) do nothing;
