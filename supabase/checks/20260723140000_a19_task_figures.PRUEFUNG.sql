-- A19 Pruefung — nach der Migration im selben begin/…/rollback.
do $$
declare
  tF uuid; tV uuid; t5 uuid; t3 uuid; t4 uuid;
  p jsonb; v_n int; v_txt text; v_ctrl boolean;
begin
  -- Testaufgaben.
  select id into tF from tasks where source='edvance_fundament' order by id limit 1;
  select id into t3 from tasks where source='edvance_fundament' order by id offset 1 limit 1;
  select id into t4 from tasks where source='edvance_fundament' order by id offset 2 limit 1;
  select id into t5 from tasks where source='edvance_fundament'
     and jsonb_array_length(coalesce(assets,'[]'::jsonb))=0 order by id offset 3 limit 1;
  select id into tV from tasks where source='VERA8_IQB' and jsonb_array_length(assets)>0 limit 1;

  -- 1. Kein Grant fuer anon/authenticated.
  select count(*) into v_n from information_schema.role_table_grants
   where table_name='task_figures' and grantee in ('anon','authenticated');
  if v_n <> 0 then raise exception 'P1 task_figures hat % anon/auth-Grants', v_n; end if;
  raise notice 'P1 ok: task_figures ohne anon/auth-Grant';

  -- 2. Testzeile -> Payload enthaelt url/alt/content_type, NICHT params/generator/svg_hash.
  insert into task_figures (task_id, generator, params, alt_text, svg_hash, erzeugt_am)
    values (tF, 'koordinatensystem', '{"m":2,"b":1}'::jsonb,
            'Koordinatensystem mit einer eingezeichneten Geraden', 'deadbeef', now());
  p := public.lsa_question_payload(tF);
  select count(*) into v_n from jsonb_array_elements(p->'assets') a
    where a ->> 'content_type' = 'image/svg+xml'
      and a ->> 'url' like '%/generiert/'||tF::text||'/koordinatensystem-dunkel.svg'
      and a ->> 'alt' = 'Koordinatensystem mit einer eingezeichneten Geraden';
  if v_n <> 1 then raise exception 'P2 Abbildung nicht korrekt im Payload (%)', v_n; end if;
  if p::text ~ '"(params|generator|svg_hash|erzeugt_am|m|b)"\s*:' then
    raise exception 'P2 verbotener Schluessel im Payload';
  end if;
  raise notice 'P2 ok: url/alt/content_type im Payload, keine params/generator/svg_hash';

  -- 3. alt_text mit Ziffer -> abgewiesen.
  v_ctrl := false;
  begin
    insert into task_figures (task_id, generator, params, alt_text)
      values (t3, 'koordinatensystem', '{}'::jsonb, 'Gerade mit Steigung 2');
  exception when others then v_ctrl := true; end;
  if not v_ctrl then raise exception 'P3 alt_text mit Ziffer nicht abgewiesen'; end if;
  raise notice 'P3 ok: alt_text mit Ziffer abgewiesen';

  -- 4. generator ausserhalb der Positivliste -> abgewiesen.
  v_ctrl := false;
  begin
    insert into task_figures (task_id, generator, params, alt_text)
      values (t4, 'phantasie_generator', '{}'::jsonb, 'Ein Bild');
  exception when others then v_ctrl := true; end;
  if not v_ctrl then raise exception 'P4 unbekannter generator nicht abgewiesen'; end if;
  raise notice 'P4 ok: generator ausserhalb der Positivliste abgewiesen';

  -- 5. Aufgabe ohne task_figures-Eintrag: assets unveraendert wie heute.
  p := public.lsa_question_payload(t5);
  if public.lsa_task_assets(t5) is distinct from public.lsa_public_assets((select assets from tasks where id=t5)) then
    raise exception 'P5 assets ohne Figur weichen vom Bestand ab';
  end if;
  if jsonb_array_length(p->'assets') <> 0 then raise exception 'P5 assets nicht leer bei figurloser Aufgabe'; end if;
  raise notice 'P5 ok: Aufgabe ohne Figur -> Payload unveraendert';

  -- 6. Bestandsasset (VERA, kandidaten/) liefert weiterhin wie bisher.
  if tV is not null then
    p := public.lsa_question_payload(tV);
    select count(*) into v_n from jsonb_array_elements(p->'assets') a where a->>'url' like '%/kandidaten/%';
    if v_n = 0 then raise exception 'P6 VERA-Asset fehlt im Payload'; end if;
    if exists (select 1 from jsonb_array_elements(p->'assets') a where a->>'url' like '%/kandidaten/%' and a ? 'content_type') then
      raise exception 'P6 VERA-Asset traegt unerwartet content_type';
    end if;
    raise notice 'P6 ok: VERA-Asset unveraendert (kandidaten/, kein content_type)';
  else
    raise notice 'P6 uebersprungen: kein VERA-Asset in der DB';
  end if;

  -- 7. Negativkontrolle.
  v_ctrl := false;
  begin
    if (select count(*) from task_figures) <> -1 then raise exception 'kontrolle: absichtlich falsch'; end if;
  exception when others then v_ctrl := true; end;
  if not v_ctrl then raise exception 'P7 Negativkontrolle hat NICHT ausgeloest'; end if;
  raise notice 'P7 ok: Negativkontrolle greift';

  raise notice 'ALLE 7 PRUEFUNGEN BESTANDEN';
end;
$$;
