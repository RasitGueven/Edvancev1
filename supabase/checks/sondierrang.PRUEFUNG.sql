-- sondierrang.PRUEFUNG.sql
--
-- Prüft die Sondierrang-Vergabe nach dem Verfahren aus docs/sondierrang_vorschlag.md:
-- je Skill genau ein Rang 1 und ein Rang 2, und beide aus verschiedenen
-- Fehlbildprofilen, sofern der Skill mehr als eins hat.
--
-- Das Fehlbildprofil einer Aufgabe ist die Menge der Schlüssel in
-- task_solutions.acceptance -> 'known_errors'. Zwei Aufgaben mit derselben Menge
-- machen dieselben Denkfehler sichtbar.
--
-- Läuft lesend. Aufruf:
--     psql "$DBURL" -v ON_ERROR_STOP=1 -f supabase/checks/sondierrang.PRUEFUNG.sql

do $$
declare
  v_n int;
  v_liste text;
begin
  -- ── P1: je Skill genau ein Rang 1 ──────────────────────────────────────────
  select count(*), coalesce(string_agg(skill_key, ', '), '')
    into v_n, v_liste
    from (select skill_key
            from tasks
           where source = 'edvance_fundament' and status = 'ready'
           group by skill_key
          having count(*) filter (where sondierrang = 1) <> 1) x;
  if v_n <> 0 then
    raise exception 'P1 % Skill(s) ohne genau einen Rang 1: %', v_n, v_liste;
  end if;
  raise notice 'P1 ok: jeder Skill hat genau einen Rang 1';

  -- ── P2: je Skill genau ein Rang 2 ──────────────────────────────────────────
  select count(*), coalesce(string_agg(skill_key, ', '), '')
    into v_n, v_liste
    from (select skill_key
            from tasks
           where source = 'edvance_fundament' and status = 'ready'
           group by skill_key
          having count(*) filter (where sondierrang = 2) <> 1) x;
  if v_n <> 0 then
    raise exception 'P2 % Skill(s) ohne genau einen Rang 2: %', v_n, v_liste;
  end if;
  raise notice 'P2 ok: jeder Skill hat genau einen Rang 2';

  -- ── P3: keine Ränge jenseits von 2 ─────────────────────────────────────────
  select count(*) into v_n
    from tasks
   where source = 'edvance_fundament' and status = 'ready' and sondierrang > 2;
  if v_n <> 0 then
    raise exception 'P3 % Aufgabe(n) mit Rang > 2. Das Verfahren vergibt nur 1 und 2; '
                    'der Rest bleibt NULL und wird zufaellig gezogen', v_n;
  end if;
  raise notice 'P3 ok: keine Raenge jenseits von 2';

  -- ── P4: Rang 1 und 2 aus verschiedenen Fehlbildprofilen ────────────────────
  -- Nur dort verlangt, wo der Skill ueberhaupt mehr als ein Profil hat.
  with profil as (
    select t.id, t.skill_key, t.sondierrang,
           coalesce((select string_agg(distinct kv.key, ',' order by kv.key)
                       from task_solutions s
                       cross join lateral
                            jsonb_each(coalesce(s.acceptance -> 'known_errors', '{}'::jsonb)) kv
                      where s.task_id = t.id), '') as profil
      from tasks t
     where t.source = 'edvance_fundament' and t.status = 'ready'
  ),
  je_skill as (
    select skill_key,
           count(distinct profil)                                    as profile_gesamt,
           count(distinct profil) filter (where sondierrang in (1,2)) as profile_gewaehlt
      from profil
     group by skill_key
  )
  select count(*), coalesce(string_agg(skill_key, ', '), '')
    into v_n, v_liste
    from je_skill
   where profile_gesamt > 1 and profile_gewaehlt < 2;

  if v_n <> 0 then
    raise exception 'P4 % Skill(s) waehlen Rang 1 und 2 aus demselben Fehlbildprofil, '
                    'obwohl mehrere vorhanden sind — die zweite Sondierung ist dort '
                    'verschenkt: %', v_n, v_liste;
  end if;
  raise notice 'P4 ok: Rang 1 und 2 unterscheiden sich im Fehlbildprofil, wo moeglich';

  -- ── P5: Negativkontrolle — der Harnisch muss ausloesen koennen ─────────────
  declare v_ctrl boolean := false;
  begin
    begin
      if (select count(*) from tasks) <> -1 then
        raise exception 'kontrolle: absichtlich falsche Erwartung';
      end if;
    exception when others then v_ctrl := true;
    end;
    if not v_ctrl then raise exception 'P5 Negativkontrolle hat nicht ausgeloest'; end if;
  end;
  raise notice 'P5 ok: Negativkontrolle greift';

  raise notice 'SONDIERRANG: ALLE PRUEFUNGEN BESTANDEN';
end $$;
