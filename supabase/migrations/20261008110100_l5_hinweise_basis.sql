-- L5.1 Kinder-Hinweise pruefen und freigeben (Session-Rahmen P1, Paket L5; Entscheidungen Rasit 06.10.).
--
-- Teil 1: Grundlagen.
--   - Zwei neue Beanstandungsgruende (Entscheidung 1): hinweis_verraet_loesung, hinweis_passt_nicht.
--   - Neue Protokoll-Aktion hinweise_bestaetigen (Entscheidung 5).
--   - pruef_hinweise_setzen: der einzige Weg, der Kinder-Hinweise auf geprueft setzt. Nicht fuer
--     Clients freigegeben; aufgerufen nur aus den Freigabewegen und hinweise_bestaetigen (Teil 3).
--     Der Weg aus E1 bleibt: Flag edvance.hinweis_status transaktionslokal, dann der Trigger
--     hinweise_status_folgt_text (unveraendert, "der Status haengt am Text").
--   - hinweis_status_setzen (E1): geprueft gibt es nur noch ueber Freigabe bzw. hinweise_bestaetigen
--     (Entscheidung 2). Zurueck auf entwurf darf weiter jeder mit Pruefrecht.
--   - hinweise_offen(task_id) und pruef_admin_liste mit den Spalten hinweise / hinweise_ungeprueft
--     (Filter "Hinweise ungeprueft" in der Admin-Liste).

alter table public.task_reviews drop constraint task_reviews_kategorie_check;
alter table public.task_reviews add constraint task_reviews_kategorie_check
  check (kategorie = any (array['fehlbild_falsch', 'fehlbild_unrealistisch', 'zahlen_unguenstig', 'formulierung',
    'didaktisch', 'kontext', 'loesung_passt_nicht', 'aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch',
    'sprache_zu_schwer', 'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges',
    'hinweis_verraet_loesung', 'hinweis_passt_nicht']));

alter table public.task_admin_protokoll drop constraint task_admin_protokoll_aktion_check;
alter table public.task_admin_protokoll add constraint task_admin_protokoll_aktion_check
  check (aktion = any (array['freigeben', 'an_lena', 'zurueckweisen', 'freigabe_zurueck', 'ausschliessen',
    'aufnehmen', 'pilot_an', 'pilot_aus', 'fertigkeit', 'afb', 'rueckfrage_freigeben', 'rueckfrage_an_lena',
    'rueckfrage_zurueckweisen', 'hinweise_bestaetigen']));

create or replace function public.pruef_admin_gruende()
returns text[]
language sql
immutable
as $$
  select array['aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen',
               'passt_nicht_in_lsa', 'sonstiges', 'fehlbild_falsch', 'fehlbild_unrealistisch',
               'zahlen_unguenstig', 'formulierung', 'didaktisch', 'kontext', 'loesung_passt_nicht',
               'hinweis_verraet_loesung', 'hinweis_passt_nicht']
$$;

-- Setzt alle Kinder-Hinweise einer Aufgabe auf p_status. Liefert die geaenderten Stufen als
-- Aenderungsliste fuer das Admin-Protokoll ([] = nichts zu tun, dann bleibt auch pruef_version).
create function public.pruef_hinweise_setzen(p_task_id uuid, p_status text)
returns jsonb
language plpgsql
volatile
set search_path = public, pg_temp
as $$
declare
  v_hints jsonb;
  v_aend  jsonb;
begin
  if p_status is null or p_status not in ('entwurf', 'geprueft') then
    raise exception 'pruef_hinweise_setzen: Status entwurf oder geprueft' using errcode = '22023';
  end if;
  select hints into v_hints from public.task_solutions where task_id = p_task_id for update;
  if jsonb_typeof(v_hints) is distinct from 'array' then
    return '[]'::jsonb;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('feld', 'hinweis_status', 'teil', (h ->> 'level')::int,
                                               'vorher', coalesce(h ->> 'status', 'entwurf'), 'nachher', p_status)
                            order by (h ->> 'level')::int), '[]')
    into v_aend
    from jsonb_array_elements(v_hints) h
   where coalesce(h ->> 'status', 'entwurf') <> p_status;
  if v_aend = '[]'::jsonb then
    return v_aend;
  end if;

  perform set_config('edvance.hinweis_status', 'setzen', true);
  update public.task_solutions
     set hints = (select jsonb_agg(h || jsonb_build_object('status', p_status) order by ord)
                    from jsonb_array_elements(v_hints) with ordinality as e(h, ord)),
         updated_at = now()
   where task_id = p_task_id;
  perform set_config('edvance.hinweis_status', '', true);
  return v_aend;
end;
$$;

comment on function public.pruef_hinweise_setzen(uuid, text) is
  'L5: setzt alle Kinder-Hinweise einer Aufgabe auf entwurf/geprueft. Nur intern (Freigabewege, hinweise_bestaetigen).';

-- Prod-Fassung (pg_get_functiondef, 06.10.) mit Entscheidung 2: geprueft nur ueber die Freigabe.
create or replace function public.hinweis_status_setzen(p_task_id uuid, p_level integer, p_status text)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_hints jsonb;
begin
  if not public.darf_pruefen() then
    raise exception 'hinweis_status_setzen: nur Pruefer oder Admin' using errcode = '42501';
  end if;
  if p_status is null or p_status not in ('entwurf', 'geprueft') then
    raise exception 'hinweis_status_setzen: Status entwurf oder geprueft' using errcode = '22023';
  end if;
  -- L5 Entscheidung 2: Kinder-Hinweise werden mit der Aufgabe freigegeben (pruef_admin_freigeben,
  -- pruef_rueckfrage_klaeren, pruef_sammel) oder bei freigegebenen Aufgaben per hinweise_bestaetigen.
  if p_status = 'geprueft' then
    raise exception 'hinweis_status_setzen: geprueft nur ueber die Freigabe der Aufgabe' using errcode = '42501';
  end if;

  -- Sperrreihenfolge wie die Freigabewege: erst tasks, dann task_solutions (Consensus-Check L5, Befund 5).
  perform 1 from public.tasks where id = p_task_id for update;
  select hints into v_hints from public.task_solutions where task_id = p_task_id for update;
  if v_hints is null or not exists (select 1 from jsonb_array_elements(v_hints) h
                                     where (h ->> 'level')::int = p_level) then
    raise exception 'hinweis_status_setzen: Hinweis nicht gefunden' using errcode = 'P0002';
  end if;

  perform set_config('edvance.hinweis_status', 'setzen', true);
  update public.task_solutions
     set hints = (select jsonb_agg(case when (h ->> 'level')::int = p_level
                                        then h || jsonb_build_object('status', p_status)
                                        else h end order by ord)
                    from jsonb_array_elements(v_hints) with ordinality as e(h, ord)),
         updated_at = now()
   where task_id = p_task_id
  returning hints into v_hints;
  perform set_config('edvance.hinweis_status', '', true);
  return v_hints;
end;
$$;

comment on function public.hinweis_status_setzen(uuid, integer, text) is
  'Setzt einen Hinweis zurueck auf entwurf (darf_pruefen). geprueft nur ueber die Freigabe der Aufgabe (L5).';


-- Hat die Aufgabe Kinder-Hinweise, die nicht geprueft sind?
create function public.hinweise_offen(p_task_id uuid)
returns boolean
language sql
stable
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.task_solutions s,
                        jsonb_array_elements(case when jsonb_typeof(s.hints) = 'array' then s.hints else '[]' end) h
                  where s.task_id = p_task_id and coalesce(h ->> 'status', 'entwurf') <> 'geprueft')
$$;

-- pruef_admin_liste: zwei Spalten mehr (Filter "Hinweise ungeprueft"). Rueckgabetyp aendert sich, deshalb
-- drop + create; Aufrufer: src/lib/supabase/pruefung.ts (getPruefAdminListe). Rest wie Prod.
drop function public.pruef_admin_liste();
create function public.pruef_admin_liste()
returns table(task_id uuid, lena_status text, ausschluss text, pilot boolean, entscheidung text, gruende text[],
              notiz text, aenderungen jsonb, aenderung_grund text, dauer_sek integer, geprueft_von text,
              geprueft_am timestamp with time zone, antwort text, beantwortet_am timestamp with time zone,
              geaendert boolean, ausschluss_grund text, ausschluss_von text, ausschluss_am timestamp with time zone,
              hinweise integer, hinweise_ungeprueft integer)
language plpgsql
stable security definer
set search_path = public, pg_temp
as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_admin_liste: nur admin' using errcode = '42501';
  end if;
  return query
  select t.id, public.pruef_lena_status(t.status), public.pruef_ausschluss(t.id), t.pruef_pilot,
         lp.entscheidung, lp.gruende, lp.notiz, lp.aenderungen, lp.aenderung_grund, lp.dauer_sek,
         pr.full_name, lp.geprueft_am, lp.antwort, lp.beantwortet_am,
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         h.grund, hv.full_name, h.am,
         coalesce(hz.n, 0), coalesce(hz.offen, 0)
    from public.tasks t
    left join lateral (select p.* from public.task_pruefungen p where p.task_id = t.id
                        order by p.geprueft_am desc limit 1) lp on true
    left join public.profiles pr on pr.id = lp.geprueft_von
    left join public.task_pruef_ausschluss h on h.task_id = t.id
    left join public.profiles hv on hv.id = h.von
    left join lateral (select count(*)::int n,
                              (count(*) filter (where coalesce(x ->> 'status', 'entwurf') <> 'geprueft'))::int offen
                         from public.task_solutions s,
                              jsonb_array_elements(case when jsonb_typeof(s.hints) = 'array' then s.hints else '[]' end) x
                        where s.task_id = t.id) hz on true;
end;
$$;

revoke all on function public.hinweise_offen(uuid) from public, anon, authenticated;
revoke all on function public.pruef_admin_liste() from public, anon, authenticated;
grant execute on function public.pruef_admin_liste() to authenticated;
revoke all on function public.pruef_hinweise_setzen(uuid, text) from public, anon, authenticated;
revoke all on function public.hinweis_status_setzen(uuid, integer, text) from public, anon, authenticated;
grant execute on function public.hinweis_status_setzen(uuid, integer, text) to authenticated;
