-- T3.3 LSA eines Testkontos: Hinweise und Fehlbild-Klartext wie freigegeben (Paket T3, Entscheidung Rasit 08.10.).
--
-- Seit F1 E2 (20261011140200) zieht die LSA eines Testkontos auch ungepruefte Aufgaben. Die Anzeige blieb bei der
-- Freigabe stehen:
--   lsa_hint            nur Hinweise mit status 'geprueft'  -> fuer ein Testkonto jeder Hinweis mit Text
--   lsa_fehlbild_report Klartext nur mit freigegeben_am      -> fuer ein Testkonto jeder Klartext
-- Jeweils nur, wenn die Aufgabe die Pruefung des Lena-Boards besteht (testlauf_inhalt_sichtbar, T3.1). Ob die Regel
-- gilt, kommt aus der LSA (lsa_testinhalte: Testlauf oder Testkonto), nie vom Client. Fuer ein echtes Kind liefern
-- beide Funktionen dasselbe wie vorher. lsa_fehlbild_auswertung (Familien-Elterntext) bleibt unveraendert
-- (offene-punkte-t3).
--
-- Rumpf je Funktion zeilengleich mit der Prod-Definition nach SL1 (pg_get_functiondef per dbread, 12.10.2026);
-- Signatur, SECURITY, search_path und Grants unveraendert.

CREATE OR REPLACE FUNCTION public.lsa_hint(p_session_id uuid, p_task_id uuid, p_level integer DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session lsa_sessions;
  v_hint    jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if not (p_task_id = any (v_session.item_ids)) then
    raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
  end if;

  -- Entscheidung 20: nur geprueft. Ohne Status gilt ein Hinweis als entwurf.
  select h
    into v_hint
    from task_solutions s,
         lateral jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id
     and (h ->> 'level')::int = p_level
     and (h ->> 'status' = 'geprueft'
          -- T3: fuer ein Testkonto jeder Hinweis mit Text, wenn die Aufgabe die Pruefung des Lena-Boards besteht.
          or (public.lsa_testinhalte(p_session_id) and nullif(btrim(h ->> 'text'), '') is not null
              and public.testlauf_inhalt_sichtbar(p_task_id)))
   order by coalesce(h ->> 'status' = 'geprueft', false) desc
   limit 1;

  if v_hint is null then
    return jsonb_build_object('level', p_level, 'text', null, 'available', false);
  end if;

  return jsonb_build_object(
    'level',     p_level,
    'text',      v_hint ->> 'text',
    'available', true
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.lsa_fehlbild_report(p_session_id uuid)
 RETURNS TABLE(skill_key text, fehlbild_slug text, klartext text, anzahl bigint, anteil numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with falsch as (
    select t.skill_key     as sk,
           r.fehlbild_slug as slug,
           r.task_id       as task_id
      from public.lsa_responses r
      join public.tasks t on t.id = r.task_id
     where r.session_id = p_session_id
       and exists (
         select 1 from public.lsa_sessions s
          where s.id = p_session_id
            and coalesce(public.lsa_may_act_for(s.student_id), false)
       )
       and r.abgabeart  = 'antwort'
       and r.correct is false
  ),
  je_slug as (
    -- group by trifft slug null als eigene Gruppe (NULLs gelten hier als
    -- gleich) — das ist die "nicht zugeordnet"-Zeile.
    -- Das Fenster ueber der Aggregation liefert den Nenner je Skill, ohne die
    -- Basis ein zweites Mal zu lesen.
    select f.sk,
           f.slug,
           count(*)                            as n,
           sum(count(*)) over (partition by f.sk) as n_skill
      from falsch f
     group by f.sk, f.slug
  )
  select g.sk,
         g.slug,
         -- "nicht zugeordnet" bleibt unabhaengig von der Abnahme sichtbar: es
         -- ist kein Klartext ueber ein Kind, sondern ein Befund ueber die
         -- Registry — genau die Luecke, die Lena sehen muss (AF2).
         case when g.slug is null then 'nicht zugeordnet'
              -- T3: fuer ein Testkonto jeder Klartext, wenn eine der Aufgaben die Pruefung des Lena-Boards besteht.
              when l.freigegeben_am is null
               and not (public.lsa_testinhalte(p_session_id) and nullif(btrim(l.klartext), '') is not null
                        and exists (select 1 from falsch f where f.sk is not distinct from g.sk and f.slug = g.slug
                                       and public.testlauf_inhalt_sichtbar(f.task_id))) then null
              else l.klartext end,
         g.n,
         -- Anteil als Bruchteil 0..1, auf 4 Stellen gerundet. Gerundete
         -- Anteile summieren sich nicht zwingend exakt auf 1 — massgeblich
         -- ist `anzahl`.
         round(g.n::numeric / g.n_skill, 4)
    from je_slug g
    left join public.fehlbild_labels l on l.slug = g.slug
   order by g.sk asc, g.n desc, g.slug asc
$function$
;

