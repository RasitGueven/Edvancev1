-- Reihe 1 · A1 Pool-Trennung (Konzept Sessionreihe 1 §1 Entscheidung 4, Entscheidung Rasit vom 27.10.2026).
--
-- Eine Aufgabe gehoert entweder zur LSA oder zur Session, nie zu beiden. Die Pool-Angabe ist die vorhandene
-- Spalte tasks.einsatz (A0 §1): lsa und session schliessen sich ab jetzt aus, check und quest bleiben eigene
-- Einsaetze ohne Pool.
--   1. Daten: alle Aufgaben mit {lsa,session} verlieren session (vorher 1184, nachher 0). Nichts wird geloescht.
--      pruef_version bleibt unveraendert: tasks_pruef_version ist nur fuer dieses UPDATE aus — es ist keine
--      inhaltliche Aenderung, offene Pruefansichten sollen nicht an der Versionssperre scheitern.
--   2. Der Default {lsa,session} entfaellt: neue Aufgaben nennen ihren Einsatz ausdruecklich
--      (Bauform-Instanzen setzen {session}).
--   3. tasks_einsatz_ein_pool verbietet lsa und session zugleich; tasks_einsatz_nicht_leer verbietet {}.
--   4. Den Einsatz aendert nur ein Admin (tasks_pruefer_guard, wie source und is_diagnostic).
--
-- Folge (A0 §2): lsa_im_pool und session_im_pool filtern beide ueber einsatz. Ohne Session-Aufgaben zieht die
-- Session nichts, bis die ersten Bauform-Instanzen freigegeben sind (docs/reihe1/A/an-C.md); das gilt ab dem
-- Einspielen auch fuer laufende Sessions vor Ort. Im Lena-Board fallen die Session-Anlaesse (pruef_soll.einsatz =
-- session) fuer den Bestand weg; die Aufgaben stehen nur noch unter "Fuer die LSA". Gewollt (Entscheidung Rasit).
-- Einfuegewege ohne einsatz scheitern ab jetzt hart (not null, kein Default): in pg_proc gibt es keinen
-- (27.10.2026), wohl aber alte Chargen-Generatoren unter tools/ und scripts/ — wer sie wieder nutzt, setzt einsatz.
--
-- Funktionen, die einsatz lesen (pg_proc, 27.10.2026): erklaer_checks, erklaer_pruef_detail, lsa_im_pool,
-- pruef_board, quest_aufgaben_waehlen, session_im_pool — alle nur lesend mit `'<wert>' = any (einsatz)`;
-- keine schreibt die Spalte, keine verlaesst sich auf den Default.

alter table public.tasks disable trigger tasks_pruef_version;
update public.tasks set einsatz = array_remove(einsatz, 'session') where einsatz @> array['lsa', 'session']::text[];
alter table public.tasks enable trigger tasks_pruef_version;
do $$
begin
  if exists (select 1 from public.tasks where einsatz @> array['lsa', 'session']::text[]) then
    raise exception 'reihe1_a1: nach der Datenaenderung steht noch eine Aufgabe in beiden Pools';
  end if;
end $$;

alter table public.tasks alter column einsatz drop default;

alter table public.tasks drop constraint if exists tasks_einsatz_ein_pool;
alter table public.tasks add constraint tasks_einsatz_ein_pool
  check (not (einsatz @> array['lsa', 'session']::text[]));
alter table public.tasks drop constraint if exists tasks_einsatz_nicht_leer;
alter table public.tasks add constraint tasks_einsatz_nicht_leer check (cardinality(einsatz) >= 1);

comment on column public.tasks.einsatz is
  'Einsatz und Pool (Reihe 1 A1): genau einer von lsa | session (nie beide, CHECK tasks_einsatz_ein_pool), oder check (Mini-Check) bzw. quest. Kein Default: jede neue Aufgabe nennt ihn. Aendert nur admin.';

create or replace function public.tasks_pruefer_guard()
returns trigger
language plpgsql
as $$
begin
  if current_user = 'authenticated'
     and public.get_my_role() is distinct from 'admin' then
    if new.status      is distinct from old.status
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'Freigabe: Status nur ueber task_status_set / lena_beanstande'
        using errcode = '42501';
    end if;
    -- Herkunft und Steuerung des Bestands pflegt der Pruefer nicht: sie
    -- entscheiden, woher eine Aufgabe kommt und ob/wie die LSA sie zieht.
    -- Reihe 1 A1: auch der Einsatz (Pool lsa | session).
    if new.id is distinct from old.id
       or new.source        is distinct from old.source
       or new.source_ref    is distinct from old.source_ref
       or new.created_at    is distinct from old.created_at
       or new.content_type  is distinct from old.content_type
       or new.is_active     is distinct from old.is_active
       or new.is_diagnostic is distinct from old.is_diagnostic
       or new.is_tutorial   is distinct from old.is_tutorial
       or new.skill_key     is distinct from old.skill_key
       or new.sondierrang   is distinct from old.sondierrang
       or new.einsatz       is distinct from old.einsatz then
      raise exception 'Freigabe: Herkunfts- und Steuerfelder aendert nur admin'
        using errcode = '42501';
    end if;
    if old.status = 'ready' then
      raise exception 'Freigabe: eine freigegebene Aufgabe aendert nur admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- 5. Lenas Board zeigt den Pool je Aufgabe (A1.4): pruef_board liefert zusaetzlich pool (lsa | session | null fuer
--    check/quest; {lsa,check} zeigt lsa). Die Spalte kommt ans Ende; pruef_board_soll liest nur benannte Spalten (plpgsql, zur Laufzeit).
drop function if exists public.pruef_board();
create function public.pruef_board()
returns table(task_id uuid, stufe text, thema_key text, thema_label text, thema_sort integer, skill_key text,
              skill_label text, kurztitel text, reihenfolge bigint, lena_status text, geaendert boolean,
              letzte_dauer_sek integer, anlaesse text[], hat_hinweise boolean, pool text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select t.id, t.title, t.status, t.source_ref, t.skill_key sk_jetzt, t.einsatz,
           coalesce(a.ausgang ->> 'skill_key', t.skill_key) sk,
           case when a.task_id is not null then (a.ausgang ->> 'sondierrang')::int else t.sondierrang end sr
      from public.tasks t
      left join public.task_pruefung_ausgang a on a.task_id = t.id
     where public.pruef_ausschluss(t.id) is null
       and (t.pruef_pilot or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)))
  select b.id, th.stufe, th.thema_key, th.label, th.sort, b.sk_jetzt, sj.label,
         public.pruef_kurztitel(b.title),
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                                     th.sort nulls last, s.fundament_tiefe, b.sk, b.sr nulls last,
                                     b.source_ref, b.id),
         public.pruef_lena_status(b.status),
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         lp.dauer_sek,
         coalesce((select array_agg(ps.anlass order by ps.anlass) from public.pruef_soll ps
                    where ps.aktiv and ps.skill_key = b.sk_jetzt and ps.einsatz = any (b.einsatz)), '{}'::text[]),
         coalesce((select jsonb_array_length(ts.hints) > 0
                     from public.task_solutions ts where ts.task_id = b.id), false),
         case when 'lsa' = any (b.einsatz) then 'lsa' when 'session' = any (b.einsatz) then 'session' end
    from b
    join public.skills s on s.skill_key = b.sk
    join public.skill_thema st on st.skill_key = b.sk
    join public.themen th on th.thema_key = st.thema_key
    left join public.skills sj on sj.skill_key = b.sk_jetzt
    left join lateral (select p.aenderungen, p.dauer_sek from public.task_pruefungen p
                        where p.task_id = b.id order by p.geprueft_am desc limit 1) lp on true;
end $$;
revoke all on function public.pruef_board() from public, anon;
grant execute on function public.pruef_board() to authenticated;
