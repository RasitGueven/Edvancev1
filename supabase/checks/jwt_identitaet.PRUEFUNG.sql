-- jwt_identitaet.PRUEFUNG.sql
--
-- Prueft den auth.uid()-Stub aus supabase/test-grundlage.sql: erreichen BEIDE
-- Schreibweisen der Identitaet die Funktion, und liefert sie ohne gesetzte
-- Identitaet wirklich null?
--
-- Hintergrund: Die Pruefskripte setzen die Identitaet uneinheitlich. Die
-- Einzahlform (request.jwt.claim.sub) nutzt fehlbild_auswertung.PRUEFUNG.sql,
-- die Mehrzahlform (request.jwt.claims als JSON) nutzen A16, A17, A20, A21.
-- Verstand der Stub nur die Einzahlform, blieb auth.uid() in allen anderen
-- null — und `if not lsa_may_act_for(...) then raise` feuert bei null nicht.
-- Siehe docs/jwt-identitaet-befund.md.
--
-- J3 ist die eigentliche Kontrolle: sie schlaegt an, wenn jemand einen festen
-- Wert in den Stub einbaut.
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/jwt_identitaet.PRUEFUNG.sql

begin;

do $$
declare
  v_einzahl  uuid := '11111111-1111-1111-1111-111111111111';
  v_mehrzahl uuid := '22222222-2222-2222-2222-222222222222';
  v_ist      uuid;
  v_ctrl     boolean;
begin

  -- ---- J1: Einzahlform request.jwt.claim.sub -----------------------------
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims',    '', true);
  perform set_config('request.jwt.claim.sub', v_einzahl::text, true);
  v_ist := auth.uid();
  if v_ist is distinct from v_einzahl then
    raise exception 'J1 request.jwt.claim.sub gesetzt -> auth.uid()=%, erwartet %',
      coalesce(v_ist::text, 'null'), v_einzahl;
  end if;
  raise notice 'J1 ok: request.jwt.claim.sub erreicht auth.uid() (%)', v_ist;

  -- ---- J2: Mehrzahlform request.jwt.claims als JSON -----------------------
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_mehrzahl)::text, true);
  v_ist := auth.uid();
  if v_ist is distinct from v_mehrzahl then
    raise exception 'J2 request.jwt.claims gesetzt -> auth.uid()=%, erwartet %',
      coalesce(v_ist::text, 'null'), v_mehrzahl;
  end if;
  raise notice 'J2 ok: request.jwt.claims (JSON) erreicht auth.uid() (%)', v_ist;

  -- ---- J3: nichts gesetzt -> null ----------------------------------------
  -- Die Negativkontrolle. Ein fest verdrahteter Wert im Stub faellt hier auf.
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims',    '', true);
  v_ist := auth.uid();
  if v_ist is not null then
    raise exception 'J3 ohne Identitaet liefert auth.uid()=% statt null', v_ist;
  end if;
  raise notice 'J3 ok: ohne gesetzte Identitaet ist auth.uid() null';

  -- ---- J4: beides gesetzt -> Einzahlform gewinnt --------------------------
  perform set_config('request.jwt.claim.sub', v_einzahl::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_mehrzahl)::text, true);
  v_ist := auth.uid();
  if v_ist is distinct from v_einzahl then
    raise exception 'J4 beide gesetzt -> auth.uid()=%, erwartet Einzahlform %',
      coalesce(v_ist::text, 'null'), v_einzahl;
  end if;
  raise notice 'J4 ok: bei beiden Formen gewinnt die Einzahlform (dokumentierter Vorrang)';

  -- ---- J5: auth.role() hat dieselben zwei Formen -------------------------
  perform set_config('request.jwt.claim.role', '', true);
  perform set_config('request.jwt.claims',     '', true);
  if auth.role() <> 'anon' then
    raise exception 'J5 ohne Rolle liefert auth.role()=% statt anon', auth.role();
  end if;
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  if auth.role() <> 'authenticated' then
    raise exception 'J5 request.jwt.claim.role -> auth.role()=%', auth.role();
  end if;
  perform set_config('request.jwt.claim.role', '', true);
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
  if auth.role() <> 'service_role' then
    raise exception 'J5 request.jwt.claims.role -> auth.role()=%', auth.role();
  end if;
  raise notice 'J5 ok: auth.role() liest beide Formen, Rueckfall anon';

  -- ---- JKontrolle: falsche Erwartung bricht den Lauf ab -------------------
  v_ctrl := false;
  begin
    if (select count(*) from pg_proc) <> -1 then raise exception 'kontrolle: absichtlich falsch'; end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'JKontrolle hat NICHT ausgeloest'; end if;
  raise notice 'JKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'JWT-IDENTITAET: ALLE PRUEFUNGEN BESTANDEN';
end;
$$;

rollback;
