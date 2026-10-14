-- hinweise-e3-abgleich.sql — nur Wegwerf-DB (tools/hinweise-e3-wegwerf-db.sh): Stand vor und nach der E3-Migration.
-- e3_vorher.ts / e3_vorher.tasks = vor dem ersten Lauf, e3_vorher.ts_nach1 = nach dem ersten Lauf.
-- Bricht mit einer Ausnahme ab, wenn eine Zusage nicht hält; sonst eine Zeile je Zusage.

\set ON_ERROR_STOP on
create temp table e3_skills(skill_key text primary key);
insert into e3_skills values ('gleichung_quadr_faktor'), ('gleichung_quadr_wurzel'), ('gleichung_quadr_formel'),
  ('gleichung_quadr_anzahl'), ('gleichung_einschrittig'), ('gleichung_zweischrittig'), ('term_ausklammern'),
  ('vorzeichen_add_sub');

-- Aufgaben aus Schritt 1: Session-Aufgaben der acht Skills, vorher ohne Hinweise, nicht VERA8
create temp table e3_soll as
  select t.id from e3_vorher.tasks t join e3_vorher.ts s on s.task_id = t.id
   where t.skill_key in (select skill_key from e3_skills) and 'session' = any (t.einsatz)
     and coalesce(s.hints, '[]') = '[]' and t.source is distinct from 'VERA8_IQB';

create temp table e3_geaendert as
  select n.task_id from public.task_solutions n join e3_vorher.ts v using (task_id)
   where to_jsonb(n) is distinct from to_jsonb(v);

do $$
declare
  v_soll int := (select count(*) from e3_soll);
  v_ist int := (select count(*) from e3_geaendert);
  v_n int;
begin
  if v_soll <> 49 then raise exception 'Bestand: % Aufgaben statt 49', v_soll; end if;
  if exists (select id from e3_soll except select task_id from e3_geaendert)
     or exists (select task_id from e3_geaendert except select id from e3_soll) then
    raise exception 'geändert sind nicht genau die Aufgaben aus Schritt 1 (soll %, ist %)', v_soll, v_ist;
  end if;
  if (select count(*) from public.task_solutions) <> (select count(*) from e3_vorher.ts) then
    raise exception 'Zeilenzahl task_solutions hat sich geändert';
  end if;
  -- außer hints keine Spalte geändert
  select count(*) into v_n from public.task_solutions n join e3_vorher.ts v using (task_id)
   where to_jsonb(n) - 'hints' is distinct from to_jsonb(v) - 'hints';
  if v_n <> 0 then raise exception '% Zeilen mit geänderter Spalte außer hints', v_n; end if;
  -- je Aufgabe genau Stufe 1, 2, 3 mit Text, alle entwurf
  select count(*) into v_n from public.task_solutions s join e3_soll on e3_soll.id = s.task_id
   where jsonb_array_length(s.hints) <> 3
      or (select array_agg((h ->> 'level')::int order by (h ->> 'level')::int) from jsonb_array_elements(s.hints) h) <> array[1, 2, 3]
      or exists (select 1 from jsonb_array_elements(s.hints) h
                  where h ->> 'status' is distinct from 'entwurf' or nullif(btrim(h ->> 'text'), '') is null);
  if v_n <> 0 then raise exception '% Aufgaben ohne drei Entwurfs-Hinweise', v_n; end if;
  -- tasks: pruef_version der 49 Aufgaben (Trigger task_solutions_pruef_version); bei den 24 gleichung_quadr_*
  -- dazu vorbefuellt.hints „leer“ → „neu“ und vorbefuellt_am (Entscheidung Rasit 12.10.2026); sonst nichts
  select count(*) into v_n from public.tasks n join e3_vorher.tasks v using (id)
   where to_jsonb(n) - 'pruef_version' - 'vorbefuellt' - 'vorbefuellt_am'
         is distinct from to_jsonb(v) - 'pruef_version' - 'vorbefuellt' - 'vorbefuellt_am'
      or n.vorbefuellt - 'hints' is distinct from v.vorbefuellt - 'hints';
  if v_n <> 0 then raise exception '% tasks-Zeilen geändert (außer pruef_version und Kennzeichen hints)', v_n; end if;
  select count(*) into v_n from public.tasks n join e3_vorher.tasks v using (id)
   where (n.vorbefuellt -> 'hints' is distinct from v.vorbefuellt -> 'hints'
          or n.vorbefuellt_am is distinct from v.vorbefuellt_am)
     and not (n.skill_key like 'gleichung_quadr\_%' and n.id in (select id from e3_soll)
              and v.vorbefuellt -> 'hints' ->> 'art' = 'leer'
              and n.vorbefuellt -> 'hints' = '{"art":"neu","grund":"E3: drei Hinweisstufen für die Session. In der LSA gibt es keine Hinweise (lsa_hint gesperrt)."}'::jsonb);
  if v_n <> 0 then raise exception '% tasks mit unerwartetem Kennzeichen hints', v_n; end if;
  select count(*) into v_n from public.tasks n join e3_vorher.tasks v using (id)
   where n.pruef_version is distinct from v.pruef_version and n.id not in (select id from e3_soll);
  if v_n <> 0 then raise exception '% fremde tasks mit neuer pruef_version', v_n; end if;
  -- zweiter Lauf ändert nichts, weder task_solutions noch tasks
  select count(*) into v_n from public.task_solutions n join e3_vorher.ts_nach1 v using (task_id)
   where to_jsonb(n) is distinct from to_jsonb(v);
  if v_n <> 0 then raise exception 'zweiter Lauf hat % Zeilen geändert', v_n; end if;
  select count(*) into v_n from public.tasks n join e3_vorher.tasks_nach1 v using (id)
   where to_jsonb(n) is distinct from to_jsonb(v);
  if v_n <> 0 then raise exception 'zweiter Lauf hat % tasks-Zeilen geändert', v_n; end if;
end $$;

select 'ok  Bestand: ' || count(*) || ' Aufgaben (Session, ohne Hinweise, nicht VERA8)' from e3_soll;
select 'ok  geändert: genau diese ' || count(*) || ' task_solutions-Zeilen, nur Spalte hints' from e3_geaendert;
select 'ok  je Aufgabe Stufe 1–3 mit Text, alle entwurf; geprüft: '
       || count(*) filter (where h ->> 'status' = 'geprueft')
  from public.task_solutions s join e3_soll on e3_soll.id = s.task_id, jsonb_array_elements(s.hints) h;
select 'ok  ' || count(*) || ' andere task_solutions-Zeilen unverändert' from public.task_solutions where task_id not in (select id from e3_soll);
select 'ok  tasks: pruef_version der ' || count(*) || ' Aufgaben hochgezählt, sonst unverändert'
  from public.tasks n join e3_vorher.tasks v using (id) where n.pruef_version is distinct from v.pruef_version;
select 'ok  Kennzeichen vorbefuellt.hints leer → neu: ' || count(*) || ' Aufgaben (' ||
       string_agg(distinct n.skill_key, ', ') || ')'
  from public.tasks n join e3_vorher.tasks v using (id) where n.vorbefuellt -> 'hints' is distinct from v.vorbefuellt -> 'hints';
select 'ok  zweiter Lauf: keine Änderung';
select 'je Skill: ' || string_agg(t.skill_key || ' ' || n, ', ' order by t.skill_key)
  from (select t.skill_key, count(*) n from public.tasks t join e3_soll on e3_soll.id = t.id group by 1) t;
