-- P1 · M2: Batus Liste für Lena sichtbar (Pilot-Flag).
--
-- pruef_einstellungen.nur_pilot steht auf true und bleibt so; pruef_board zeigt dann nur Aufgaben mit
-- pruef_pilot. Am 14.10.2026 (dbread) hatten 19 der 29 LSA-Knoten aus Batus Freigabeliste und 7 der 8 Knoten der
-- E3-Session kein einziges Pilot-Flag (Liste in docs/themen/offene-punkte-p1.md). Entscheidung Rasit 14.10.2026:
-- Flag setzen für
--   a) alle Aufgaben mit 'lsa' in einsatz der 29 Knoten unten (Stufe 1, 2, 3; potenzen eingeschlossen),
--   b) die 49 Session-Aufgaben aus E3 (PR #244), über ihre IDs aus docs/prefill/hinweise-e3-snapshot.json.
-- Erwartung in Prod am 14.10.: 258 Zielaufgaben, davon 27 schon mit Flag, 231 neu.
--
-- Weg wie die Admin-Aktion pilot_an: pruef_sammel_schreiben('pilot_an', …) setzt pruef_pilot und schreibt
-- task_admin_protokoll (von = null, als Systemaufruf). Nur Aufgaben ohne Flag; nichts wird auf false gesetzt,
-- Status, Texte und Lösungen bleiben. Idempotent; fehlende Aufgaben (CI-Neuaufbau) werden übersprungen.
-- Kein begin/commit: mig klammert mit psql -1.

do $p1m2$
declare
  v_knoten text[] := array[
    -- Stufe 1
    'zahl_wurzel_irrational', 'zahl_wurzel_naeherung', 'zahl_wurzel_teilweise', 'zahl_wurzel_gesetze',
    'zahl_wurzel_quadrat',
    -- Stufe 2
    'potenzen', 'bruch_dezimal', 'dezimal_div', 'dezimal_mult', 'vorzeichen_mult_div', 'runden_ueberschlag',
    'dezimal_add_sub', 'bruch_kuerzen', 'vorzeichen_add_sub',
    -- Stufe 3
    'fkt_linear_gleichung', 'fkt_linear_steigung', 'fkt_linear_yabschnitt', 'term_binom_faktorisieren',
    'term_binom_gemischt', 'term_binom_quadrat', 'term_binom_quadratdifferenz', 'gleichung_lgs_addition',
    'gleichung_lgs_einsetzen', 'gleichung_lgs_grafisch', 'geo_flaeche_drachen_raute', 'geo_flaeche_term',
    'geo_flaeche_trapez', 'stoch_pfad_summe', 'geo_winkel_thales'];
  v_e3 uuid[] := array[
    '02b24419-d7e8-40b8-8b74-ef3b4e806b3f',
    '0c3d2396-131a-4cba-bd07-4597d92500cf',
    '1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee',
    '152bcdcd-897b-452b-9a8f-402375540a3f',
    '17674b19-fe14-42ca-98db-6598fa8c5a3a',
    '17f3e728-2249-42ba-b5bf-c2a4b344dd00',
    '1c4a31af-20bc-4348-b8d9-cd83b273ff38',
    '1f2a206f-1f63-4866-b446-c8305de6b725',
    '27f51c08-6a47-4ceb-b189-f5f07cbcf1cf',
    '3a42b89c-7f8a-4b64-94ff-d1d4ac576c32',
    '3b44eada-3589-4bdb-a33b-2fb2ca0a1726',
    '3e6fb055-111e-4888-9177-d2b17dd0fc54',
    '43f39bc1-e7b4-48e6-8b77-ff8e41e77142',
    '4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af',
    '4d1a2438-3610-4dc9-b5be-8d35cb5199bd',
    '4f6f7cdd-3415-4185-8eae-95083d061b71',
    '504bbd98-9c80-4124-a66a-9dc7b6651bb9',
    '56540a88-7b9e-4935-8702-26f9415e9d14',
    '5b36238f-c64c-4578-bd63-55249f185c78',
    '65841bd8-ee27-454f-b2a4-ea6f1bb0db33',
    '6fc6928a-6ae3-4c32-9c2e-b9a20451b97c',
    '725448a1-10e2-4e88-beb8-fe57f6e54d06',
    '738de19f-d3c9-43a0-b5ce-af6e30752c75',
    '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992',
    '81f97d0e-1e95-4bbd-bc6a-d05149786c58',
    '90635757-ba7c-4bde-bd7c-04bd79bf8c35',
    '9264f90a-1f7b-4170-97da-198c1acc89a3',
    '95077a87-7e8a-4463-83b0-dbbf6facc879',
    '9879542e-bb69-41c6-a77f-3916a26ffad1',
    '9d15a93e-961b-4569-be8b-c4482dc98301',
    '9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5',
    'a549083d-c72d-44d6-9aba-a138ad6d2dc0',
    'b01451c0-53e5-4da7-9591-280448264835',
    'b15b6be0-1b87-477d-bd88-23b095501581',
    'b47ef7d3-1933-416f-8fe8-edcbc8fe8929',
    'b6e77404-2577-4e03-b4ce-cb61a5f6a5f9',
    'bc0cdfe9-2416-4d02-a623-feb820083f07',
    'bfd877b9-cd3e-490c-82ad-0274b4f85a8b',
    'c3be2e88-1087-479f-bf95-9dbd732efa56',
    'c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0',
    'cd6693f5-cc93-4628-baf9-f45436706641',
    'd19c8070-85d9-44cc-b4cc-eac3e06010d0',
    'd7d81e80-6776-4308-a690-29675f7882d4',
    'e8348c89-67cb-4650-be91-235e69321776',
    'e96cd37d-0254-4051-bf2d-71a6f7fa2aaf',
    'ea237a07-681d-4680-bcd0-d94316c899e9',
    'ef911123-949d-4ea9-a61d-beef95cc8dc0',
    'fbd28765-b198-4ff6-bdbe-de9ccc5202de',
    'ff5710af-0c0a-47e5-9a57-b2a5bb4ef82d'
  ]::uuid[];
  v_n integer := 0;
  t public.tasks;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  for t in
    select * from public.tasks x
     where not x.pruef_pilot
       and ((x.skill_key = any (v_knoten) and 'lsa' = any (x.einsatz)) or x.id = any (v_e3))
     order by x.id
  loop
    perform public.pruef_sammel_schreiben('pilot_an', t,
      jsonb_build_object('grund', 'P1: Batus Freigabeliste für Lena sichtbar (Rasit, 14.10.2026)'));
    v_n := v_n + 1;
  end loop;
  raise notice 'p1_m2: pruef_pilot neu fuer % Aufgabe(n)', v_n;
end $p1m2$;
