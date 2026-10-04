-- Themenraum fuer bereits abgeschlossene LSA-Sitzungen nachtragen (W5-d, Teil 1).
-- Setzt 20261004001437_lsa_finish_themenraum voraus (public.lsa_themenraum).
-- Begruendung: docs/report/themenraum-entscheidungen.md.
--
-- Sitzungen, die VOR der Erweiterung von lsa_finish abgeschlossen wurden, haben
-- kein result_summary.themenraum. Er wird aus dem HEUTIGEN Stand von
-- thema_einstieg/skill_kante nachgetragen und als solcher gekennzeichnet:
-- stand = 'nachgetragen' statt eines Abschlusszeitpunkts. Der Report behandelt
-- ihn wie einen gespeicherten — ab jetzt verschiebt er sich nicht mehr.
--
-- Nur wo das Feld fehlt und ein thema_key gesetzt ist. Bestehende Felder bleiben
-- unberuehrt (||  ergaenzt nur den neuen Schluessel). Kein Trigger betroffen:
-- lsa_session_lead_fertig_trg und lsa_session_platz_release_trg haengen an
-- UPDATE OF status. Ein zweiter Lauf trifft 0 Zeilen; im CI-Neuaufbau ebenso.
-- Stand Prod 04.10.2026: 0 abgeschlossene Sitzungen mit thema_key.
--
-- Ohne begin/commit: der Runner klammert.

do $$
declare n int;
begin
  update lsa_sessions s
     set result_summary = s.result_summary || jsonb_build_object(
           'themenraum',
           public.lsa_themenraum(s.thema_key)
             || jsonb_build_object('stand', 'nachgetragen'))
   where s.status = 'completed'
     and s.thema_key is not null
     and s.result_summary is not null
     and not (s.result_summary ? 'themenraum');
  get diagnostics n = row_count;
  raise notice 'themenraum nachgetragen: % Sitzungen', n;
end $$;
