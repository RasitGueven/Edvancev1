-- Lead-Wizard: Themenauswahl + unterschriebene DSGVO-Einwilligung.
--
-- Legt vier Spalten an, alle nicht-destruktiv (add column if not exists):
--   leads.current_topic_cluster_id        Themencluster aus dem Erstgespraech,
--                                         Verweis auf skill_clusters(id)
--   leads.consent_dsgvo_signature         Unterschrift als PNG-Data-URL
--   leads.consent_dsgvo_document_version  Version des unterzeichneten Textes
--   skill_clusters.school_types           Schulform, vom Frontend noch ungenutzt
--
-- Ohne diese Spalten laeuft setLeadConsent in einen Fehler und die Freigabe
-- fuer die LSA schlaegt fehl: der Wizard schreibt auf Felder, die es in der
-- Datenbank sonst nicht gibt.
--
-- Wird diese Migration eingespielt, muss supabase/schema-erwartet.sql neu
-- erzeugt werden (bash tools/schema-snapshot.sh). Der CI-Job "neuaufbau"
-- spielt alle Migrationen in eine leere Datenbank und vergleicht das Ergebnis
-- gegen diesen Schnappschuss; bleibt er alt, meldet er genau diese vier
-- Spalten als Abweichung. Von Hand editieren geht nicht, guard-paths.sh weist
-- den Schnappschuss ab.
--
-- Historie: die Datei lag zwischenzeitlich unter docs/pending-migrations/, weil
-- supabase/pending/ seit #107 vom CI zurueckgewiesen wird; sie gehoert hierher
-- und liegt jetzt hier.

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
