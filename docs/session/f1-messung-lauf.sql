-- F1 / A5: Laufzeit von coach_raum_live und coach_kind_detail auf den Daten aus f1-messung.sql.
-- Je Funktion 20 Aufrufe als Coach der Session, Mittel und Maximum in ms; dazu ein EXPLAIN ANALYZE.
\pset pager off
select session_id as s, kind as k from public.zz_f1_mess where nr = 1 \gset
begin;
select set_config('request.jwt.claims', json_build_object('sub', 'a2a2a2a2-0001-4000-8000-000000000002',
       'role', 'authenticated')::text, true);
create temp table zeiten (fn text, ms numeric);
do $$
declare t0 timestamptz; i int; r record; v_s uuid := (select session_id from public.zz_f1_mess limit 1);
begin
  for i in 1 .. 20 loop
    t0 := clock_timestamp(); perform public.coach_raum_live(v_s);
    insert into zeiten values ('coach_raum_live', extract(epoch from clock_timestamp() - t0) * 1000);
    for r in select kind from public.zz_f1_mess loop
      t0 := clock_timestamp(); perform public.coach_kind_detail(v_s, r.kind);
      insert into zeiten values ('coach_kind_detail', extract(epoch from clock_timestamp() - t0) * 1000);
    end loop;
  end loop;
end $$;
select fn, count(*) as aufrufe, round(avg(ms), 1) as mittel_ms,
       round((percentile_cont(0.5) within group (order by ms))::numeric, 1) as median_ms, round(max(ms), 1) as max_ms
  from zeiten group by fn order by fn;
explain (analyze, costs off, timing on) select public.coach_raum_live(:'s');
explain (analyze, costs off, timing on) select public.coach_kind_detail(:'s', :'k');
-- Ergebnis-Fingerabdruck (ohne den Zeitstempel "stand"), fuer den Vergleich vorher/nachher.
select md5((public.coach_raum_live(:'s') - 'stand')::text) as raum_md5;
select string_agg(md5(public.coach_kind_detail(:'s', kind)::text), ' ' order by nr) as detail_md5 from public.zz_f1_mess;
rollback;
