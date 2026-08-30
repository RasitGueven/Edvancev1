-- Lead-Wizard: Themenauswahl + unterschriebene DSGVO-Einwilligung.
--
-- NICHT ANGEWENDET. Diese Datei liegt bewusst unter supabase/pending/ und ist
-- noch keine Migration. Vor dem Merge nach supabase/migrations/ verschieben und
-- anwenden — ohne sie schlaegt „Fuer die LSA freigeben" fehl, weil der Wizard
-- auf Spalten schreibt, die es in der Datenbank noch nicht gibt.

-- 1. Aktuelles Thema am Lead: Verweis auf das Themencluster, das im
--    Erstgespraech ausgewaehlt wurde. Ersetzt das Freitextfeld
--    next_exam_topic; die alte Spalte bleibt unangetastet bestehen.
alter table public.leads
  add column if not exists current_topic_cluster_id uuid
    references public.skill_clusters(id);

-- 2. Schulform am Themencluster. Vom Frontend noch NICHT verwendet — die
--    Themenauswahl filtert vorerst nur nach Fach und Klasse.
alter table public.skill_clusters
  add column if not exists school_types text[];

-- 3. Unterschriebene DSGVO-Einwilligung.
--    consent_dsgvo_at und consent_dsgvo_by existieren bereits (S7,
--    20260716100000_s7_lead_lsa.sql). Fuer die Unterschrift im Wizard fehlen
--    Bild und Dokumentversion — ohne diese beiden Spalten laeuft
--    setLeadConsent in einen Fehler.
alter table public.leads
  add column if not exists consent_dsgvo_signature text;

alter table public.leads
  add column if not exists consent_dsgvo_document_version text;

comment on column public.leads.current_topic_cluster_id is
  'Im Erstgespraech gewaehltes Themencluster (skill_clusters). Ersetzt next_exam_topic.';
comment on column public.leads.consent_dsgvo_signature is
  'Unterschrift der Eltern als PNG-Data-URL, erfasst im Lead-Wizard.';
comment on column public.leads.consent_dsgvo_document_version is
  'Versionskennung des unterzeichneten Einwilligungstexts (CONSENT_DOCUMENT_VERSION).';
