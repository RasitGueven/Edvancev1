-- PRUEFUNG zu K8 Lineare Funktionen, Migration 1 (Substrat: fuenf Knoten,
-- zwoelf Kanten, drei Fehlbilder). Laeuft in begin/rollback und mutiert NICHTS
-- dauerhaft.
--
--   psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -f supabase/checks/k8_linfkt_substrat.PRUEFUNG.sql
--
-- Bindet die Migration NICHT per \ir ein: sie klammert sich selbst mit
-- begin/commit. Laeuft gegen den eingespielten Stand.

begin;

do $$
declare
  v_ist  integer;
  v_text text;
begin
  -- ── Vorbedingung ──────────────────────────────────────────────────────────
  if not exists (select 1 from public.skills where skill_key = 'fkt_linear_steigung') then
    raise exception 'Migration 20261001124808_substrat_k8_linfkt.sql nicht eingespielt.';
  end if;

  -- ── L1: fuenf Knoten mit Herkunft 8 und geplanter Tiefe ──────────────────
  select count(*) into v_ist from public.skills
   where (skill_key, klasse_herkunft, fundament_tiefe) in (
     ('fkt_linear_steigung', 8, 5), ('fkt_linear_yabschnitt', 8, 6),
     ('fkt_linear_graph', 8, 7), ('fkt_linear_gleichung', 8, 7),
     ('fkt_linear_nullstelle', 8, 8));
  if v_ist <> 5 then raise exception 'L1: % von 5 Knoten wie geplant', v_ist; end if;
  raise notice 'L1 ok: 5 Knoten (5/6/7/7/8), klasse_herkunft 8';

  -- ── L2: genau die zwoelf Kanten ──────────────────────────────────────────
  select count(*) into v_ist from public.skill_kante where skill_key like 'fkt_linear_%';
  if v_ist <> 12 then raise exception 'L2: % statt 12 Kanten', v_ist; end if;
  select count(*) into v_ist from public.skill_kante
   where (skill_key, voraussetzt_skill_key) in (
     ('fkt_linear_steigung', 'geo_koordinaten'), ('fkt_linear_steigung', 'vorzeichen_mult_div'),
     ('fkt_linear_steigung', 'bruch_kuerzen'), ('fkt_linear_steigung', 'proportionalitaet'),
     ('fkt_linear_yabschnitt', 'term_einsetzen'), ('fkt_linear_yabschnitt', 'geo_koordinaten'),
     ('fkt_linear_graph', 'fkt_linear_steigung'), ('fkt_linear_graph', 'fkt_linear_yabschnitt'),
     ('fkt_linear_gleichung', 'fkt_linear_steigung'), ('fkt_linear_gleichung', 'fkt_linear_yabschnitt'),
     ('fkt_linear_nullstelle', 'fkt_linear_gleichung'), ('fkt_linear_nullstelle', 'gleichung_neg_koeffizient'));
  if v_ist <> 12 then raise exception 'L2: % von 12 geplanten Kanten', v_ist; end if;
  raise notice 'L2 ok: 12 Kanten wie geplant';

  -- ── L3: jede Kante echt flacher, kein Knoten ohne Kante nach unten ────────
  select count(*) into v_ist
    from public.skill_kante k
    join public.skills s on s.skill_key = k.skill_key
    join public.skills v on v.skill_key = k.voraussetzt_skill_key
   where k.skill_key like 'fkt_linear_%' and v.fundament_tiefe >= s.fundament_tiefe;
  if v_ist <> 0 then raise exception 'L3: % Kanten nicht echt flacher', v_ist; end if;
  select count(*) into v_ist from public.skills s
   where s.skill_key like 'fkt_linear_%'
     and not exists (select 1 from public.skill_kante k where k.skill_key = s.skill_key);
  if v_ist <> 0 then raise exception 'L3: % Knoten ohne Kante nach unten', v_ist; end if;
  raise notice 'L3 ok: alle Kanten echt flacher, jeder Knoten hat Unterbau';

  -- ── L4: keine transitiv redundante Kante ─────────────────────────────────
  -- Eine direkte Kante a -> c ist redundant, wenn c auch ueber einen anderen
  -- direkten Nachfolger b von a erreichbar ist.
  with recursive erreich (start, ziel) as (
    select k.skill_key, k.voraussetzt_skill_key from public.skill_kante k
    union
    select e.start, k.voraussetzt_skill_key
      from erreich e join public.skill_kante k on k.skill_key = e.ziel
  )
  select count(*) into v_ist
    from public.skill_kante a
    join public.skill_kante b on b.skill_key = a.skill_key
                             and b.voraussetzt_skill_key <> a.voraussetzt_skill_key
    join erreich e on e.start = b.voraussetzt_skill_key and e.ziel = a.voraussetzt_skill_key
   where a.skill_key like 'fkt_linear_%';
  if v_ist <> 0 then raise exception 'L4: % transitiv redundante Kanten', v_ist; end if;

  -- Bruchprobe zu L4: graph -> geo_koordinaten ist ueber graph -> steigung
  -- schon erreichbar. Die Zaehlung muss genau diese eine Kante finden. Der
  -- innere Block wird per eigenem SQLSTATE verlassen und rollt den Insert zurueck.
  begin
    insert into public.skill_kante (skill_key, voraussetzt_skill_key)
      values ('fkt_linear_graph', 'geo_koordinaten');
    with recursive erreich (start, ziel) as (
      select k.skill_key, k.voraussetzt_skill_key from public.skill_kante k
      union
      select e.start, k.voraussetzt_skill_key
        from erreich e join public.skill_kante k on k.skill_key = e.ziel
    )
    select count(distinct (a.skill_key, a.voraussetzt_skill_key)) into v_ist
      from public.skill_kante a
      join public.skill_kante b on b.skill_key = a.skill_key
                               and b.voraussetzt_skill_key <> a.voraussetzt_skill_key
      join erreich e on e.start = b.voraussetzt_skill_key and e.ziel = a.voraussetzt_skill_key
     where a.skill_key like 'fkt_linear_%';
    if v_ist <> 1 then raise exception 'L4-Bruchprobe: Ist = %, Soll = 1', v_ist; end if;
    raise sqlstate 'P0099';
  exception when sqlstate 'P0099' then null;
  end;
  raise notice 'L4 ok: keine transitiv redundante Kante (Bruchprobe: Ist = 1, Soll = 1)';

  -- ── L5: drei neue Fehlbilder als Entwurf in vorhandener Familie ───────────
  select count(*) into v_ist from public.fehlbild_labels l
    join public.fehlbild_familien f on f.schluessel = l.familie
   where l.slug in ('steigung_kehrwert', 'm_b_vertauscht', 'achsenabschnitt_verwechselt')
     and l.freigegeben_am is null and btrim(l.klartext) <> '' and btrim(l.erklaerung) <> ''
     and l.klartext !~* 'gemeistert' and l.erklaerung !~* 'gemeistert';
  if v_ist <> 3 then raise exception 'L5: % von 3 Fehlbildern als Entwurf', v_ist; end if;
  if exists (select 1 from public.fehlbild_labels where slug = 'kaestchen_gezaehlt') then
    raise exception 'L5: kaestchen_gezaehlt darf nicht angelegt sein';
  end if;
  raise notice 'L5 ok: 3 Fehlbilder (gleichungen_umformen), freigegeben_am NULL';

  -- ── L6: Bruchprobe — der Guard faengt eine nicht flachere Kante ───────────
  begin
    insert into public.skill_kante (skill_key, voraussetzt_skill_key)
      values ('fkt_linear_graph', 'fkt_linear_gleichung');   -- 7 ueber 7
    raise exception 'L6: Guard hat 7 ueber 7 angenommen';
  exception when check_violation then null;
  end;
  raise notice 'L6 ok: Bruchprobe — Guard weist 7 ueber 7 ab';
end $$;

rollback;
