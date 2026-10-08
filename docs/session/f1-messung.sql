-- F1 / A5: Messdaten fuer coach_raum_live und coach_kind_detail (nur Wegwerf-DB, nie Produktion).
-- Fuenf Kinder in einer Session, je 30 Antworten (Warm-up und Kernarbeit, gemischt richtig/falsch,
-- mit Hinweisen und Fehlbildern). Danach commit, damit f1-messung-lauf.sql getrennt messen kann.
--   psql -d <wegwerf-db> -v ON_ERROR_STOP=1 -f docs/session/f1-messung.sql
begin;
\ir ../../supabase/tests/session_a2_fixture.sql

-- Mehr Aufgaben zum zweiten Skill, damit jedes Kind 30 Antworten erreicht.
select pg_temp.aufgaben('zz_a2_s2', 25, 'ready', '{lsa,session}', 'f1-s2');
update task_solutions set acceptance = acceptance || '{"known_errors": {"0": "vorzeichen_ignoriert"}}'
 where task_id in (select id from tasks where source = 'test');

create table public.zz_f1_mess (session_id uuid, kind uuid, nr int);
do $$
declare v_k uuid[] := '{}'; v_s uuid; i int; n int; v jsonb;
begin
  for i in 1 .. 5 loop
    v_k := v_k || pg_temp.kind_mit('ZZ F1 Kind ' || i, 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}');
  end loop;
  v_s := pg_temp.neue_session(v_k, 6);
  for i in 1 .. 5 loop
    perform pg_temp.checkin(v_s, i);
    insert into public.zz_f1_mess values (v_s, v_k[i], i);
  end loop;
  -- reihum, damit die Zeitstempel der Kinder sich mischen wie im Raum
  for n in 1 .. 120 loop
    for i in 1 .. 5 loop
      if (select count(*) from session_antworten a where a.session_id = v_s and a.student_id = v_k[i]) < 30 then
        v := pg_temp.schritt(v_s, i);
        if v ->> 'art' in ('aufgabe', 'exit') then
          perform pg_temp.antwort(v_s, i, (n + i) % 3 <> 0, v ->> 'phase' = 'kern' and (n + i) % 7 = 0);
        end if;
        -- Ein offenes Entscheidungssignal haelt das Kind im Warm-up: der Coach bleibt beim Plan.
        if v ->> 'grund_code' = 'warten_entscheidung' then
          perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
          perform public.pfad_entscheiden(v_s, v_k[i], 'plan');
        end if;
      end if;
    end loop;
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select k.nr, count(a.*) as antworten from public.zz_f1_mess k
  left join session_antworten a on a.session_id = k.session_id and a.student_id = k.kind group by k.nr order by k.nr;
commit;
