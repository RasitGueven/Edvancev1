-- PRUEFUNG zur K8-Charge 1 (Binomische Formeln).
-- Laeuft in begin/rollback und mutiert NICHTS dauerhaft.
--
--   psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 \
--        -f supabase/checks/k8_binomische_formeln.PRUEFUNG.sql
--
-- Ohne Migrations-Zeitstempel im Dateinamen: bei a21_freigabe_muster hiessen
-- Migration und Pruefung bis auf die Endung gleich, und genau das hat einmal
-- die falsche Datei eingespielt.
--
-- Diese Pruefung bindet die Migration NICHT per \ir ein. Die Migration klammert
-- sich selbst mit begin/commit — ein \ir innerhalb dieses Blocks wuerde
-- mittendrin committen, und das abschliessende rollback liefe ins Leere. Sie
-- laeuft deshalb GEGEN DEN EINGESPIELTEN STAND, nach scripts/db-migrate.sh.

begin;

do $$
declare
  v_scope     text    := 'term_binom_';
  v_erwartet  text[]  := array['term_binom_quadrat', 'term_binom_quadratdifferenz',
                               'term_binom_faktorisieren', 'term_binom_gemischt'];
  v_slugs     text[]  := array['quadrat_gliedweise', 'quadratdifferenz_vorzeichen',
                               'faktorisierung_unvollstaendig'];
  v_ist       integer;
  v_soll      integer;
  v_fehlend   text;
  v_gebrochen boolean;
begin

  -- ── Vorbedingung: die Migration muss eingespielt sein ─────────────────────
  select count(*) into v_ist
    from public.skills where skill_key = any (v_erwartet);
  if v_ist = 0 then
    raise exception 'Migration 20260830120000_k8_binomische_formeln ist nicht eingespielt — erst einspielen, dann pruefen.';
  end if;

  -- ── B1: vier neue Skills, klasse_herkunft = 8 ─────────────────────────────
  select count(*) into v_ist
    from public.skills
   where skill_key = any (v_erwartet) and klasse_herkunft = 8 and fach = 'mathematik';
  if v_ist <> 4 then
    raise exception 'B1 gebrochen: % von 4 Knoten mit klasse_herkunft 8 und fach mathematik', v_ist;
  end if;
  -- Gegenprobe: kein Knoten der Charge ausserhalb der erwarteten vier.
  select string_agg(skill_key, ', ') into v_fehlend
    from public.skills
   where left(skill_key, length(v_scope)) = v_scope and not (skill_key = any (v_erwartet));
  if v_fehlend is not null then
    raise exception 'B1 gebrochen: unerwarteter Knoten im Namensraum %: %', v_scope, v_fehlend;
  end if;
  raise notice 'B1 ok: vier Knoten, klasse_herkunft 8, keine Fremdknoten im Namensraum %', v_scope;

  -- ── B2: jeder neue Knoten hat mindestens eine Kante nach unten ────────────
  -- Gilt fuer den ganzen Namensraum, nicht nur fuer die vier erwarteten — sonst
  -- koennte B5 nicht brechen.
  select count(*) into v_ist
    from public.skills s
   where left(s.skill_key, length(v_scope)) = v_scope
     and not exists (select 1 from public.skill_kante k where k.skill_key = s.skill_key);
  if v_ist <> 0 then
    select string_agg(s.skill_key, ', ') into v_fehlend
      from public.skills s
     where left(s.skill_key, length(v_scope)) = v_scope
       and not exists (select 1 from public.skill_kante k where k.skill_key = s.skill_key);
    raise exception 'B2 gebrochen: % Knoten ohne Kante nach unten (%), erwartet 0', v_ist, v_fehlend;
  end if;
  raise notice 'B2 ok: kein Knoten im Namensraum % ohne Kante nach unten', v_scope;

  -- ── B3: fundament_tiefe konsistent zur Semantik ───────────────────────────
  -- Semantik laut Tabellenkommentar: "Stufe im Fundament (1 traegt alles)",
  -- durchgesetzt von skill_kante_tiefe_guard — eine Voraussetzung liegt ECHT
  -- flacher. Geprueft wird der gespeicherte Zustand, nicht der Insert-Moment.
  select count(*) into v_ist
    from public.skill_kante k
    join public.skills s  on s.skill_key = k.skill_key
    join public.skills v  on v.skill_key = k.voraussetzt_skill_key
   where left(k.skill_key, length(v_scope)) = v_scope
     and v.fundament_tiefe >= s.fundament_tiefe;
  if v_ist <> 0 then
    raise exception 'B3 gebrochen: % Kanten mit Voraussetzung nicht ECHT flacher, erwartet 0', v_ist;
  end if;
  -- Und innerhalb der Schranke 1..8 (skills_fundament_tiefe_check).
  select count(*) into v_ist
    from public.skills
   where left(skill_key, length(v_scope)) = v_scope
     and (fundament_tiefe < 1 or fundament_tiefe > 8);
  if v_ist <> 0 then
    raise exception 'B3 gebrochen: % Knoten ausserhalb fundament_tiefe 1..8', v_ist;
  end if;
  -- Und die Form, die der Schnitt behauptet: Anwendung ueber Formel.
  if (select fundament_tiefe from public.skills where skill_key = 'term_binom_faktorisieren')
     <= (select fundament_tiefe from public.skills where skill_key = 'term_binom_quadrat') then
    raise exception 'B3 gebrochen: faktorisieren liegt nicht ueber quadrat';
  end if;
  if (select fundament_tiefe from public.skills where skill_key = 'term_binom_gemischt')
     <= (select fundament_tiefe from public.skills where skill_key = 'term_binom_quadratdifferenz') then
    raise exception 'B3 gebrochen: gemischt liegt nicht ueber quadratdifferenz';
  end if;
  raise notice 'B3 ok: jede Voraussetzung echt flacher, alle Tiefen in 1..8, Anwendung ueber Formel';

  -- ── B4: jeder neue Fehlbild-Slug hat klartext und erklaerung ──────────────
  select count(*) into v_ist
    from public.fehlbild_labels
   where slug = any (v_slugs)
     and coalesce(btrim(klartext), '') <> '' and coalesce(btrim(erklaerung), '') <> '';
  if v_ist <> array_length(v_slugs, 1) then
    select string_agg(s, ', ') into v_fehlend from unnest(v_slugs) s
     where not exists (select 1 from public.fehlbild_labels l
                        where l.slug = s
                          and coalesce(btrim(l.klartext), '') <> ''
                          and coalesce(btrim(l.erklaerung), '') <> '');
    raise exception 'B4 gebrochen: % von % Slugs vollstaendig, unvollstaendig: %',
      v_ist, array_length(v_slugs, 1), coalesce(v_fehlend, '-');
  end if;
  -- Familienzuordnung vorhanden und auf eine existierende Familie zeigend.
  select count(*) into v_ist
    from public.fehlbild_labels l
    join public.fehlbild_familien f on f.schluessel = l.familie
   where l.slug = any (v_slugs);
  if v_ist <> array_length(v_slugs, 1) then
    raise exception 'B4 gebrochen: % von % Slugs mit gueltiger Familie',
      v_ist, array_length(v_slugs, 1);
  end if;
  -- Entwurfsstand: bis zu Lenas Abnahme bleibt freigegeben_am NULL.
  select count(*) into v_ist
    from public.fehlbild_labels where slug = any (v_slugs) and freigegeben_am is not null;
  if v_ist <> 0 then
    raise notice 'B4 Hinweis: % Slug(s) sind bereits abgenommen (freigegeben_am gesetzt)', v_ist;
  else
    raise notice 'B4 ok: drei Slugs mit klartext, erklaerung und Familie; noch nicht abgenommen (Entwurf)';
  end if;

  -- ── B5: Negativkontrolle — ein Knoten ohne Kante MUSS B2 brechen ──────────
  -- Der Probe-Knoten faellt in den B2-Namensraum, bekommt aber keine Kante.
  -- Das aeussere rollback raeumt ihn weg.
  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('term_binom_probe_ohne_kante', 'B5 Probe (ohne Kante)', 'mathematik', 8, 8);

  v_soll := 0;
  select count(*) into v_ist
    from public.skills s
   where left(s.skill_key, length(v_scope)) = v_scope
     and not exists (select 1 from public.skill_kante k where k.skill_key = s.skill_key);

  -- Dieselbe Zusicherung wie in B2, jetzt scharf gestellt.
  v_gebrochen := false;
  begin
    if v_ist <> v_soll then
      raise exception 'B2 gebrochen: % Knoten ohne Kante nach unten, erwartet %', v_ist, v_soll;
    end if;
  exception when others then
    v_gebrochen := true;
    raise notice 'B5 ok: B2 hat gebrochen — Ist = % Knoten ohne Kante, Soll = %. Meldung: %',
      v_ist, v_soll, sqlerrm;
  end;

  if not v_gebrochen then
    raise exception 'B5 gebrochen: B2 hat den kantenlosen Probe-Knoten NICHT bemerkt (Ist = %, Soll = %). Die Zusicherung ist wertlos.',
      v_ist, v_soll;
  end if;

  raise notice 'K8-Binomische-Formeln: ALLE PRUEFUNGEN BESTANDEN (B1-B5)';
end $$;

rollback;
