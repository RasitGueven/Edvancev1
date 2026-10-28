-- Rollback zu 20261027141816_studio_null_waechter: studio_skript_speichern wieder in der Fassung aus 20261027130817_studio_modell,
-- danach den Eintrag in supabase_migrations.schema_migrations löschen.
create or replace function public.studio_skript_speichern(p_sequenz_id uuid, p_skript jsonb, p_pruefung jsonb default '{}')
returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_seq     public.studio_sequenz;
  v_skill   text := p_skript ->> 'skill_key';
  v_welten  text[];
  v_gesperrt text[] := coalesce((select array_agg(x) from jsonb_array_elements_text(p_pruefung -> 'gesperrteWelten') x), '{}');
  b         jsonb;
  m         jsonb;
  o         jsonb;
  z         jsonb;
  w         text;
  v_pos     integer := 0;
  v_k       text;
  v_kskill  text;
  v_knr     integer;
  v_kid     uuid;
  v_beat    uuid;
  v_mid     uuid;
  v_nach    public.studio_beat;
  v_tid     uuid;
  v_nr      integer;
  v_hash    text;
  v_alt     uuid[] := '{}';
  v_ziel    uuid;
begin
  if not public.studio_hat_rolle('autor') then
    raise exception 'studio: nur Autor oder Admin' using errcode = '42501';
  end if;
  if jsonb_typeof(p_skript -> 'beats') <> 'array' or jsonb_array_length(p_skript -> 'beats') = 0 then
    raise exception 'studio: Skript ohne Beats' using errcode = '22023';
  end if;
  select coalesce(array_agg(x), '{}') into v_welten from jsonb_array_elements_text(p_skript -> 'welten') x;

  if p_sequenz_id is null then
    insert into public.studio_sequenz (skill_key, titel, autor_id, welten, skript)
    values (v_skill, p_skript ->> 'titel', auth.uid(), v_welten, p_skript)
    returning * into v_seq;
  else
    select * into v_seq from public.studio_sequenz where id = p_sequenz_id for update;
    if v_seq.id is null then
      raise exception 'studio: Sequenz % fehlt', p_sequenz_id using errcode = 'P0002';
    end if;
    if v_seq.autor_id <> auth.uid() and coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'studio: nur der Autor der Sequenz oder ein Admin' using errcode = '42501';
    end if;
    update public.studio_sequenz set skill_key = v_skill, titel = p_skript ->> 'titel', welten = v_welten,
                                     skript = p_skript, geaendert_am = now()
     where id = v_seq.id;
    select coalesce(array_agg(a.task_id), '{}') into v_alt
      from public.studio_minicheck_aufgabe a join public.studio_minicheck m on m.id = a.minicheck_id
     where m.sequenz_id = v_seq.id and a.nr = 0;
    delete from public.studio_minicheck where sequenz_id = v_seq.id;
    delete from public.studio_bereich where sequenz_id = v_seq.id;
    delete from public.studio_beat where sequenz_id = v_seq.id;
  end if;

  -- Beats, Texte, Kernideen
  for b in select * from jsonb_array_elements(p_skript -> 'beats') loop
    v_pos := v_pos + 1;
    v_k := b ->> 'kernidee';
    if v_k is null or v_k !~ '^([a-z][a-z0-9_]*:)?k[1-9]$' then
      raise exception 'studio: Beat % hat keine gültige Kernidee', b ->> 'id' using errcode = '22023';
    end if;
    v_kskill := coalesce(nullif(split_part(v_k, ':', 1), v_k), v_skill);
    v_knr := substring(v_k from 'k([1-9])$')::int;
    select k.id into v_kid from public.erklaer_kernidee k where k.skill_key = v_kskill and k.nr = v_knr;
    if v_kid is null then
      insert into public.erklaer_kernidee (skill_key, nr, titel, quelle)
      values (v_kskill, v_knr, coalesce(p_skript #>> array['kernideen', v_k], b ->> 'titel'), 'mensch')
      returning id into v_kid;
    end if;
    insert into public.studio_beat (sequenz_id, pos, beat_key, titel, baustein, params, kernidee_id)
    values (v_seq.id, v_pos, b ->> 'id', b ->> 'titel', b ->> 'baustein', coalesce(b -> 'params', '{}'), v_kid)
    returning id into v_beat;
    for w in select jsonb_object_keys(b -> 'text') loop
      if not (w = any (v_welten)) then
        raise exception 'studio: Beat % nennt die Welt %, die das Skript nicht hat', b ->> 'id', w using errcode = '22023';
      end if;
      insert into public.studio_beat_text (beat_id, welt, sprechtext, bild_params)
      values (v_beat, w, b -> 'text' ->> w, coalesce(b -> 'bild' -> w, '{}'));
    end loop;
    if not exists (select 1 from public.studio_beat_text where beat_id = v_beat and welt = 'skelett') then
      raise exception 'studio: Beat % ohne Skelett-Text', b ->> 'id' using errcode = '22023';
    end if;
    -- Bereich: zusammenhängende Beats derselben Kernidee.
    update public.studio_bereich set bis_beat = b ->> 'id' where sequenz_id = v_seq.id and kernidee_id = v_kid
       and bis_beat = (select bb.beat_key from public.studio_beat bb where bb.sequenz_id = v_seq.id and bb.pos = v_pos - 1);
    if not found then
      begin
        insert into public.studio_bereich (sequenz_id, kernidee_id, von_beat, bis_beat)
        values (v_seq.id, v_kid, b ->> 'id', b ->> 'id');
      exception when unique_violation then
        raise exception 'studio: Kernidee % liegt schon in einem anderen Video oder ist hier nicht zusammenhängend', v_k
          using errcode = '23505';
      end;
    end if;
  end loop;

  -- Mini-Checks mit Check-Aufgaben und Rücksprüngen
  v_pos := 0;
  for m in select * from jsonb_array_elements(coalesce(p_skript -> 'minichecks', '[]')) loop
    v_pos := v_pos + 1;
    select * into v_nach from public.studio_beat where sequenz_id = v_seq.id and beat_key = m ->> 'nach_beat';
    if v_nach.id is null then
      raise exception 'studio: Mini-Check nach unbekanntem Beat %', m ->> 'nach_beat' using errcode = '22023';
    end if;
    select k.skill_key into v_kskill from public.erklaer_kernidee k where k.id = v_nach.kernidee_id;
    insert into public.studio_minicheck (sequenz_id, pos, nach_beat_id, kernidee_id, frage, optionen)
    values (v_seq.id, v_pos, v_nach.id, v_nach.kernidee_id, m -> 'frage', m -> 'optionen')
    returning id into v_mid;
    v_nr := 0;
    for z in select m union all select * from jsonb_array_elements(coalesce(m -> 'zwillinge', '[]')) loop
      for o in select * from jsonb_array_elements(z -> 'optionen') loop
        if o ? 'fehlbild' and not exists (select 1 from public.fehlbild_labels f where f.slug = o ->> 'fehlbild') then
          raise exception 'studio: Fehlbild % fehlt im Katalog', o ->> 'fehlbild' using errcode = '22023',
            hint = 'fehlbild_unbekannt';
        end if;
        if o ? 'ruecksprung' then
          select id into v_beat from public.studio_beat where sequenz_id = v_seq.id and beat_key = o ->> 'ruecksprung';
          if v_beat is null or not (o ? 'fehlbild') or btrim(coalesce(o ->> 'rueckmeldung', '')) = '' then
            raise exception 'studio: Rücksprung % ungültig (Ziel, Fehlbild und Rückmeldung nötig)', o ->> 'ruecksprung'
              using errcode = '22023';
          end if;
          select r.beat_id into v_ziel from public.studio_ruecksprung r
           where r.minicheck_id = v_mid and r.fehlbild_key = o ->> 'fehlbild';
          if v_ziel is null then
            insert into public.studio_ruecksprung (minicheck_id, fehlbild_key, beat_id, rueckmeldung)
            values (v_mid, o ->> 'fehlbild', v_beat, o ->> 'rueckmeldung');
          elsif v_ziel <> v_beat then
            raise exception 'studio: Fehlbild % springt in einem Zwilling auf einen anderen Beat', o ->> 'fehlbild'
              using errcode = '22023';
          end if;
        end if;
      end loop;
      v_tid := public.studio_check_aufgabe(v_seq.id, v_kskill, (p_skript ->> 'titel') || ' · ' || (m ->> 'nach_beat'),
                                           z -> 'frage' ->> 'skelett', z -> 'optionen');
      insert into public.studio_minicheck_aufgabe (minicheck_id, nr, task_id, frage, optionen)
      values (v_mid, v_nr, v_tid, z -> 'frage', z -> 'optionen');
      -- Nur die Hauptfrage, nur an Kernideen im Entwurf (geprüfte/freigegebene ändert nur der E1-Prüfweg).
      if v_nr = 0
         and not exists (select 1 from public.erklaer_check c where c.kernidee_id = v_nach.kernidee_id and c.task_id = v_tid)
         and exists (select 1 from public.erklaer_kernidee k where k.id = v_nach.kernidee_id and k.status = 'entwurf') then
        insert into public.erklaer_check (kernidee_id, task_id, reihenfolge)
        values (v_nach.kernidee_id, v_tid,
                coalesce((select max(c.reihenfolge) from public.erklaer_check c where c.kernidee_id = v_nach.kernidee_id), 0) + 1);
      end if;
      v_nr := v_nr + 1;
    end loop;
  end loop;

  -- Weggefallene Fassungen aus dem E1-Modell lösen (nur Entwurfs-Kernideen; die Aufgabe selbst bleibt).
  delete from public.erklaer_check c
   using public.erklaer_kernidee k
   where k.id = c.kernidee_id and k.status = 'entwurf' and c.task_id = any (v_alt)
     and not exists (select 1 from public.studio_minicheck_aufgabe a where a.task_id = c.task_id);

  -- Versionen: Skelett und jede Welt nur bei geändertem Inhalt hochzählen.
  v_hash := public.studio_inhalt_hash(v_seq.id, 'skelett');
  update public.studio_sequenz
     set version = version + case when inhalt_hash in ('', v_hash) then 0 else 1 end,
         inhalt_hash = v_hash,
         status = case when inhalt_hash = v_hash then status else 'entwurf' end
   where id = v_seq.id;
  delete from public.studio_welt where sequenz_id = v_seq.id and not (welt = any (v_welten));
  foreach w in array v_welten loop
    v_hash := public.studio_inhalt_hash(v_seq.id, w);
    insert into public.studio_welt as sw (sequenz_id, welt, inhalt_hash, gesperrt, befunde)
    values (v_seq.id, w, v_hash, w = any (v_gesperrt),
            coalesce((select jsonb_agg(x) from jsonb_array_elements(p_pruefung -> 'befunde') x
                       where x ->> 'welt' = w or (w = 'skelett' and not x ? 'welt')), '[]'))
    on conflict (sequenz_id, welt) do update
      set version = sw.version + case when sw.inhalt_hash = excluded.inhalt_hash then 0 else 1 end,
          inhalt_hash = excluded.inhalt_hash, gesperrt = excluded.gesperrt, befunde = excluded.befunde;
  end loop;
  return v_seq.id;
end;
$$;
