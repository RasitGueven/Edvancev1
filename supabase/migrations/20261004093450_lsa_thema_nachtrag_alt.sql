-- Thema fuer vier alte LSA-Sitzungen nachtragen (W5-d, Teil 5 c).
-- Entscheidung Rasit 04.10.2026; Liste und Begruendung:
-- docs/report/themenraum-entscheidungen.md (Abschnitt "Teil 5").
--
-- Die alte adaptive LSA begann fuer alle bei den Gleichungen (Einstieg
-- gleichung_modellieren). Ein Thema war nie gewaehlt; thema_key ist NULL, der
-- Report gliedert diese Sitzungen bisher "ohne Thema". Fuer die vier Sitzungen
-- unten wird das Thema terme_gleichungen nachgetragen und der Themenraum aus dem
-- heutigen Stand gesichert — gekennzeichnet mit stand = 'nachgetragen'. Daran
-- erkennt der Report, dass niemand das Thema gewaehlt hat: kein
-- "Gewaehlt war das Thema", kein "genau dort haben wir angesetzt", Kopf
-- "Ausgangspunkt der Analyse" (src/lib/report/suche.ts).
--
--   143215f5  Leon, Kl. 8    Einstieg geprueft (noch nicht sicher)
--   d0ba7a1b  Batu, Kl. 9    Einstieg nicht geprueft, Pruefungsthema Lineare Gleichungen
--   4fe409f0  Batu, Kl. 9    Einstieg nicht geprueft, Pruefungsthema Lineare Gleichungen
--   6d868c5f  Ilkay, Kl. 10  Einstieg geprueft (sicher)
--
-- Bewusst NICHT: 920d00ae, d8b0d885, 6f64b51e, e7b63e2d (Gruender-Testlaeufe),
-- ed93da46 (Einstieg nicht geprueft, nur drei Bereiche), alle Testprofile,
-- die Juli-Sitzungen ohne direkte Urteile.
--
-- Nur wo thema_key leer ist und noch kein Themenraum steht; Grenze hoechstens 4.
-- Status und completed_at bleiben: die Trigger auf lsa_sessions haengen an
-- UPDATE OF status und laufen nicht. Bestehende Felder in result_summary bleiben
-- (|| ergaenzt nur themenraum). Im CI-Neuaufbau 0 Zeilen; zweiter Lauf 0 Zeilen.
-- Ohne begin/commit: der Runner klammert.

do $$
declare n int;
begin
  update lsa_sessions s
     set thema_key = 'terme_gleichungen',
         result_summary = s.result_summary || jsonb_build_object(
           'themenraum',
           public.lsa_themenraum('terme_gleichungen')
             || jsonb_build_object('stand', 'nachgetragen'))
   where s.id in (
           '143215f5-c9e4-4a26-b4e6-b634589626c3',
           'd0ba7a1b-7f2e-4b95-8207-c82cff162362',
           '4fe409f0-69e1-402a-adfb-5d63af6eb971',
           '6d868c5f-b982-4d1e-9e21-f2768fb706ce')
     and s.status = 'completed'
     and s.thema_key is null
     and s.result_summary is not null
     and not (s.result_summary ? 'themenraum');
  get diagnostics n = row_count;
  if n > 4 then raise exception 'Erwartet hoechstens 4 Sitzungen, geaendert %', n; end if;
  raise notice 'thema nachgetragen: % Sitzungen', n;
end $$;
