-- PRUEFUNG: Vertragsprozess (Migrationen 20260922120000, 20260925120000/140000).
-- Laeuft komplett in einer Transaktion und rollt am Ende zurueck.
-- Testdaten mit Praefix ZZ_. Claims mit Rolle — ohne 'role' gilt der Aufruf
-- als Systemaufruf.

begin;

do $$
declare
  v_admin  uuid;
  v_lead   uuid;
  v1       uuid;
  v2       uuid;
  v_n      integer;
  v_text   text;
  v_ok     boolean;
  v_alle   jsonb;
  v_kind   uuid := gen_random_uuid();
  v_beginn date := (date_trunc('month', current_date) + interval '1 month')::date;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;

  -- Auth-Konto fuer den Abschluss. Die RPC legt das Profil an, den auth-User
  -- legt sonst die Edge Function an — hier von Hand, alles im Rollback.
  insert into auth.users (id, email, instance_id, aud, role)
  values (v_kind, 'zz_pruefung_kind@edvance.invalid',
          '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  insert into leads (full_name, first_name, status, contact_phone, class_level, subjects)
  values ('ZZ_Test Kind', 'ZZ_Test', 'lsa_fertig', '0221 000000', 8, array['Mathematik'])
  returning id into v_lead;

  -- 1. vertrag_starten ist idempotent und nimmt den Lead vom Board.
  v1 := public.vertrag_starten(v_lead);
  v2 := public.vertrag_starten(v_lead);
  assert v1 = v2, 'vertrag_starten legt einen zweiten Vertrag an';
  select count(*) into v_n from vertraege where lead_id = v_lead;
  assert v_n = 1, 'mehr als ein Vertrag je Lead';
  select status into v_text from leads where id = v_lead;
  assert v_text = 'vertrag', 'Lead-Status nicht vertrag';
  select kind_vorname || '|' || kind_nachname || '|' || eltern_telefon into v_text
    from vertraege where id = v1;
  assert v_text = 'ZZ_Test|Kind|0221 000000', 'Vorbelegung falsch: ' || coalesce(v_text, 'null');
  raise notice '1 ok  vertrag_starten idempotent, Vorbelegung aus dem Lead';

  -- 2. Direkter Statuswechsel wird abgewiesen.
  v_ok := false;
  begin
    update vertraege set status = 'abgeschlossen' where id = v1;
  exception when insufficient_privilege then
    v_ok := true;
  end;
  assert v_ok, 'direktes UPDATE auf status nicht abgewiesen';
  raise notice '2 ok  Status-Guard';

  -- 3. Preis kommt aus dem Tarif und laesst sich nicht direkt setzen.
  update vertraege
     set tier_id = (select id from tiers where name = 'Standard'),
         laufzeit_monate = 12, vertragsbeginn = v_beginn
   where id = v1;
  update vertraege set preis_cents = 1, einheiten = 1 where id = v1;
  select preis_cents into v_n from vertraege where id = v1;
  assert v_n = 26990, 'preis_cents nicht aus tier_laufzeiten (Jahr): ' || v_n;
  select einheiten into v_n from vertraege where id = v1;
  assert v_n = 57, 'einheiten nicht aus tier_laufzeiten (Jahr): ' || v_n;
  -- Laufzeitwechsel zieht Preis und Einheiten nach.
  update vertraege set laufzeit_monate = 6 where id = v1;
  select preis_cents into v_n from vertraege where id = v1;
  assert v_n = 29990, 'preis_cents nicht aus tier_laufzeiten (Halbjahr): ' || v_n;
  select einheiten into v_n from vertraege where id = v1;
  assert v_n = 29, 'einheiten nicht aus tier_laufzeiten (Halbjahr): ' || v_n;
  update vertraege set laufzeit_monate = 12 where id = v1;
  raise notice '3 ok  Preis und Einheiten aus tier_laufzeiten, nicht ueberschreibbar';

  -- 4. IBAN wird maskiert gespiegelt.
  insert into vertrag_bankdaten (vertrag_id, iban) values (v1, 'DE89370400440532013000');
  select iban_masked into v_text from vertraege where id = v1;
  assert v_text = 'DE** **** 3000', 'Maskierung falsch: ' || coalesce(v_text, 'null');
  raise notice '4 ok  IBAN maskiert';

  -- 5. Abschluss vor Ort ohne Haekchen scheitert.
  v_ok := false;
  begin
    perform public.vertrag_abschliessen(v1, 'vor_ort', '[]'::jsonb, 'data:a', 'data:b',
                                       p_student_uid => v_kind);
  exception when sqlstate 'P0001' then
    v_ok := true;
  end;
  assert v_ok, 'Abschluss ohne Zustimmungen moeglich';
  raise notice '5 ok  Pflicht-Gate';

  -- 6. Abschluss mit allen Pflicht-Haekchen, zweiter Aufruf aendert nichts.
  select jsonb_agg(jsonb_build_object('schluessel', schluessel, 'version', version,
                                      'akzeptiert_at', now()))
    into v_alle from vertrag_dokumente where aktiv and pflicht;
  perform public.vertrag_abschliessen(v1, 'vor_ort', v_alle, 'data:a', 'data:b',
                                     p_student_uid => v_kind);
  perform public.vertrag_abschliessen(v1, 'vor_ort', v_alle, 'data:a', 'data:b',
                                     p_student_uid => v_kind);
  select status into v_text from vertraege where id = v1;
  assert v_text = 'abgeschlossen', 'Status nicht abgeschlossen';
  select count(*) into v_n from vertrag_zustimmungen where vertrag_id = v1;
  assert v_n = 5, 'Zustimmungen: ' || v_n;
  select count(*) into v_n from vertrag_unterschriften where vertrag_id = v1;
  assert v_n = 2, 'Unterschriften: ' || v_n;
  raise notice '6 ok  Abschluss idempotent, 5 Zustimmungen, 2 Unterschriften';

  -- 7. Ein abgeschlossener Vertrag laesst sich nicht mehr ablehnen.
  v_ok := false;
  begin
    perform public.vertrag_ablehnen(v1, 'preis');
  exception when sqlstate 'P0001' then
    v_ok := true;
  end;
  assert v_ok, 'abgeschlossener Vertrag ablehnbar';
  raise notice '7 ok  kein Ablehnen nach Abschluss';

  -- 8. Ablehnen mit Grund: Vertrag und Lead ins Archiv, Sonstiges nur mit Text.
  update leads set status = 'lsa_fertig' where id = v_lead;
  delete from vertraege where id = v1;
  v1 := public.vertrag_starten(v_lead);
  v_ok := false;
  begin
    perform public.vertrag_ablehnen(v1, 'sonstiges');
  exception when check_violation then
    v_ok := true;
  end;
  assert v_ok, 'Sonstiges ohne Freitext moeglich';
  perform public.vertrag_ablehnen(v1, 'anderer_anbieter');
  select v.status || '|' || l.status || '|' || l.rejection_reason || '|' || (l.rejected_at is not null)
    into v_text from vertraege v join leads l on l.id = v.lead_id where v.id = v1;
  assert v_text = 'abgelehnt|rejected|anderer_anbieter|true', 'Ablehnen: ' || coalesce(v_text, 'null');
  raise notice '8 ok  Ablehnen mit Grund, Lead im Archiv';

  -- 9. Nicht-Admin sieht keine Vertraege.
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.vertrag_starten(v_lead);
  exception when insufficient_privilege then
    v_ok := true;
  end;
  assert v_ok, 'vertrag_starten ohne Admin moeglich';
  raise notice '9 ok  RPCs nur fuer Admin';
end $$;

-- RLS: als authenticated ohne Admin-Profil keine Zeile sichtbar.
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
do $$
begin
  assert (select count(*) from public.vertraege) = 0, 'RLS: Nicht-Admin sieht Vertraege';
  assert (select count(*) from public.vertrag_bankdaten) = 0, 'RLS: Nicht-Admin sieht IBAN';
  raise notice '10 ok RLS vertraege + vertrag_bankdaten';
end $$;

rollback;
