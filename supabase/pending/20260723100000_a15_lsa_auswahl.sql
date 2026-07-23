-- ============================================================================
-- A15: Laufzeitlogik der LSA — adaptive Auswahl und Skill-Urteil
--
-- Baut auf dem A14-Substrat auf (skills 32, skill_kante 41, tasks.skill_key).
-- Fasst lsa_grade NICHT an. Legt keine Seeds an. Setzt tasks.sondierrang nicht.
--
-- ----------------------------------------------------------------------------
-- BEFUND BEIM MESSEN (was heute laeuft) — im PR ausfuehrlich
-- ----------------------------------------------------------------------------
--   lsa_start(student, grade, subject): waehlt EINMALIG einen festen
--     item_ids uuid[] (Zeitbudget ~1200 s als CAP auf die Liste, gemischt ueber
--     AFB x Kompetenz), legt lsa_sessions an (started_at=now()), gibt
--     {session_id, total_items, item=payload(item_ids[1])} zurueck.
--   lsa_submit(session, task, response, dur): schreibt EINE lsa_responses-Zeile
--     (abgabeart via lsa_abgabeart, correct via lsa_is_correct nur bei
--     abgabeart='antwort'), gibt {ok, next} — next = naechstes UNBEANTWORTETES
--     item aus der FESTEN item_ids-Liste, in Reihenfolge; null = Liste zu Ende.
--
--   DAS LOCH: Es gibt KEINE Laufzeit-Uhr und KEIN adaptives Nachladen. Das
--   Sitzungsende ist heute "feste Liste abgearbeitet", nicht "Zeit um". Der
--   Auftrag sagt "uebernimm die bestehende Zeitlogik" — die gibt es so nicht.
--   Vorhanden ist nur started_at + das 1200-s-Budget, das lsa_start beim START
--   zum Kappen der Liste nutzt. Diese Migration baut die Uhr aus started_at +
--   dem 19-Minuten-Fenster (keine neuen Aufgaben ab ~Minute 19) und macht sie
--   fuer Tests ueber einen p_jetzt-Parameter pruefbar.
--
--   FOLGE (im PR als Nachzieher benannt, NICHT in diesem PR): lsa_submit gated
--   auf `p_task_id = any(item_ids)`. Eine adaptiv (ueber lsa_select_next)
--   gezogene Aufgabe steht NICHT in item_ids und wuerde von lsa_submit
--   abgewiesen. Die Verdrahtung (adaptiver Submit-/Start-Pfad) ist ein eigener
--   Schritt. Diese Migration liefert die ENGINE, die Urteilsbuchung liest
--   lsa_responses und ist unabhaengig von diesem Gate testbar.
--
-- ----------------------------------------------------------------------------
-- ABWEICHUNGEN VON DER VORLAGE (Loecher gestopft, hier begruendet)
-- ----------------------------------------------------------------------------
--   (1) SPALTE `offen boolean` auf lsa_skill_urteil, zusaetzlich zur Vorgabe.
--       Grund: Der 5-Werte-Enum + proben_anzahl kann "final nach 1 Probe"
--       (NUMERIC voll -> traegt, 1 Probe) NICHT von "provisorisch nach 1 Probe"
--       (MC richtig -> braucht Zweitprobe) unterscheiden — beide waeren
--       (traegt, 1). `offen=true` markiert den offenen Zweitbeleg; die Vorgabe
--       "Skill mit proben_anzahl=1 und noch keinem endgueltigen Zustand" ist
--       damit exakt `offen=true`.
--   (2) DECKUNG = "hat IRGENDEINE Urteilszeile" (auch provisorisch), nicht nur
--       final. Die Vorlage sagt "Menge der Skills, ueber die die Sitzung ein
--       Urteil hat" — eine provisorische Zeile IST ein (Teil-)Urteil. Nur so
--       ist Pruefung 4 (14 Proben) mit der MC-Zweitprobe-Pflicht vereinbar:
--       term_ausklammern (einziges MC-Blatt) zaehlt nach seiner 1. Probe als
--       gedeckt, die Pflicht-Zweitprobe laeuft danach als offener Zweitbeleg.
--   (3) REGEL-4-ZEITSCHUTZ: Der "max 3 Schritte je Ast"-Zaehler braucht
--       Ast-Zustand, den die Tabelle nicht traegt. In diesem PR NICHT streng
--       erzwungen. Der Abstieg terminiert trotzdem (jeder Schritt deckt einen
--       Knoten -> endliche Menge) und ist zusaetzlich durch das 19-Minuten-
--       Fenster begrenzt. Ein exakter Ast-Schrittzaehler ist ein Nachzieher
--       (eigene Spalte oder Abstiegs-Log). Pruefung 5 (ein Schritt) haelt.
--   (4) REGEL-2-AUFLOESUNGSTABELLE: Die Vorlage nennt 4 Kombinationen. Die
--       uebrigen (mc_ja+*, *+weiss_nicht) sind konservativ gefuellt: eine
--       falsche/leere Zweitprobe ergibt NIE 'traegt'; nur eine bestaetigte
--       'voll' hebt. Siehe lsa_urteil_aufloesung.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Tabelle lsa_skill_urteil
-- ============================================================================

create table if not exists lsa_skill_urteil (
  session_id    uuid not null references lsa_sessions(id) on delete cascade,
  skill_key     text not null references skills(skill_key),
  zustand       text not null check (zustand in
                  ('traegt','traegt_teilweise','traegt_nicht',
                   'nicht_angesetzt','ungeprueft')),
  belegt_direkt boolean not null,
  -- true = offener Zweitbeleg (Probe 1 gestellt, Zweitprobe faellig). Siehe
  -- Kopf, Abweichung (1). Final = offen=false.
  offen         boolean not null default false,
  proben_anzahl int not null default 0,
  aktualisiert  timestamptz not null default now(),
  primary key (session_id, skill_key)
);

comment on table lsa_skill_urteil is
  'Pro Sitzung und Skill das Trag-Urteil der LSA (A15). belegt_direkt=true nur, '
  'wenn zu diesem Skill wirklich eine Aufgabe gestellt wurde; abgeleitete '
  'Urteile (Mit-Belegung) sind false. offen=true = offener Zweitbeleg. '
  'Report-Material — kein Schueler-Zugriff.';

alter table lsa_skill_urteil enable row level security;

-- Default privileges (api_role_grants) geben jeder neuen Tabelle DML an
-- authenticated. Wegnehmen: die Zeilen schreibt ausschliesslich die
-- DEFINER-Engine. Nur SELECT bleibt, RLS gated auf coach/admin/parent.
revoke all on table lsa_skill_urteil from anon, authenticated;
grant select on table lsa_skill_urteil to authenticated;
grant select, insert, update, delete on table lsa_skill_urteil to service_role;

drop policy if exists lsa_skill_urteil_coach_admin_read on lsa_skill_urteil;
drop policy if exists lsa_skill_urteil_parent_read on lsa_skill_urteil;
create policy lsa_skill_urteil_coach_admin_read on lsa_skill_urteil
  for select using (public.get_my_role() in ('coach','admin'));
create policy lsa_skill_urteil_parent_read on lsa_skill_urteil
  for select using (
    session_id in (
      select id from lsa_sessions where public.is_parent_of_student(student_id)
    )
  );
-- KEIN Schueler-/anon-Policy: das Urteil ist nicht Schueler-Material.

-- ============================================================================
-- 2. Topologie-Helfer: Abschluss (Voraussetzungen, rekursiv, OHNE self)
-- ============================================================================

create or replace function public.lsa_abschluss(p_skill_key text)
returns table (skill_key text)
language sql
stable
as $$
  with recursive dep(sk) as (
    select k.voraussetzt_skill_key
      from skill_kante k where k.skill_key = p_skill_key
    union
    select k.voraussetzt_skill_key
      from skill_kante k join dep on k.skill_key = dep.sk
  )
  select sk from dep
$$;

comment on function public.lsa_abschluss(text) is
  'Alle transitiv erreichbaren Voraussetzungen eines Skills (ohne den Skill '
  'selbst). Immer zur Laufzeit — nie materialisiert.';

-- ============================================================================
-- 3. Regel 2 — die Aufloesung zweier Proben (rein, immutable)
--
--    a = normierte erste Probe:  'mc_ja' (MC richtig), 'nicht', 'weiss_nicht'
--    b = normierte zweite Probe:  'voll', 'nicht', 'weiss_nicht'
--    (NUMERIC/TERM 'voll' der ERSTEN Probe ist bereits final und kommt hier
--     nie an.)
-- ============================================================================

create or replace function public.lsa_urteil_aufloesung(a text, b text)
returns text
language sql
immutable
as $$
  select case a
    when 'mc_ja' then case b
      when 'voll' then 'traegt'                 -- MC-ja bestaetigt durch freie Eingabe
      else 'traegt_teilweise' end               -- MC-ja, aber frei falsch/leer -> teilweise
    when 'nicht' then case b
      when 'voll' then 'traegt_teilweise'       -- Vorlage: nicht + voll
      else 'traegt_nicht' end                   -- Vorlage: nicht + nicht; Fuellung: nicht + weiss_nicht
    when 'weiss_nicht' then case b
      when 'voll' then 'traegt_teilweise'       -- Vorlage: weiss_nicht + voll
      when 'weiss_nicht' then 'nicht_angesetzt' -- Vorlage: weiss_nicht + weiss_nicht
      else 'traegt_nicht' end                   -- Fuellung: weiss_nicht + nicht (hat angesetzt, falsch)
    else 'traegt_nicht'
  end
$$;

-- ============================================================================
-- 4. Regel 1 — Mit-Belegung nach unten (nur bei 'traegt')
--
--    Ergebnis 'traegt' auf X => jeder Skill im Abschluss von X bekommt
--    'traegt', belegt_direkt=false — SOFERN er noch keine Urteilszeile hat.
--    on conflict do nothing: ein vorhandenes Urteil (auch traegt_nicht) wird
--    NIE ueberschrieben.
-- ============================================================================

create or replace function public.lsa_mitbelegung(p_session_id uuid, p_skill_key text)
returns void
language sql
security definer
set search_path = public
as $$
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
  select p_session_id, a.skill_key, 'traegt', false, false, 0
    from public.lsa_abschluss(p_skill_key) a
  on conflict (session_id, skill_key) do nothing
$$;

-- ============================================================================
-- 5. Regel 1/2/6 — Urteil buchen (Kern, service_role)
--
--    Liest die eben geschriebene lsa_responses-Zeile (Regel 6: abgabeart
--    'weiss_nicht'/'leer' sind KEINE falschen Antworten; nur 'antwort' wird
--    ueber lsa_grade bzw. correct bewertet). Fuehrt die asymmetrische
--    Belegregel aus. Gibt den gebuchten Zustand zurueck.
-- ============================================================================

create or replace function public.lsa_urteil_buchen_core(p_session_id uuid, p_task_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task    tasks;
  v_resp    lsa_responses;
  v_sk      text;
  v_is_mc   boolean;
  v_res     text;   -- voll | teilweise | nicht | weiss_nicht | leer
  v_row     lsa_skill_urteil;
  v_prov    text;
  v_a       text;
  v_b       text;
  v_final   text;
begin
  select * into v_task from tasks where id = p_task_id;
  v_sk := v_task.skill_key;
  if v_sk is null then
    return null;  -- Nicht-Fundament-Aufgabe: kein Skill-Urteil.
  end if;

  -- Die flache Antwortzeile dieser Aufgabe (Fundament ist einteilig).
  select * into v_resp
    from lsa_responses
   where session_id = p_session_id and task_id = p_task_id and part_nr is null
   order by created_at desc limit 1;
  if not found then
    return null;  -- ohne Antwort kein Urteil.
  end if;

  v_is_mc := (v_task.input_type = 'MC');

  -- Regel 6: Ergebnis aus abgabeart ableiten.
  if v_resp.abgabeart = 'weiss_nicht' then
    v_res := 'weiss_nicht';
  elsif v_resp.abgabeart = 'leer' then
    v_res := 'leer';
  elsif v_is_mc then
    v_res := case when coalesce(v_resp.correct, false) then 'voll' else 'nicht' end;
  else
    -- NUMERIC/TERM: die dreistufige Bewertung.
    select public.lsa_grade(v_task.input_type, s.acceptance, s.correct_answers, v_resp.response)
      into v_res
      from task_solutions s where s.task_id = p_task_id;
    v_res := coalesce(v_res, 'nicht');
  end if;

  select * into v_row from lsa_skill_urteil
   where session_id = p_session_id and skill_key = v_sk;

  -- Vorhandenes FINALES Urteil wird nie ueberschrieben.
  if found and not v_row.offen then
    return v_row.zustand;
  end if;

  if not found then
    -- PROBE 1
    if not v_is_mc and v_res = 'voll' then
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_sk, 'traegt', true, false, 1);
      perform public.lsa_mitbelegung(p_session_id, v_sk);
      return 'traegt';
    end if;
    -- Zweitprobe faellig -> provisorisch schreiben. Der provisorische Zustand
    -- kodiert die erste Probe: traegt=mc_ja, traegt_nicht=nicht, nicht_angesetzt=weiss_nicht.
    v_prov := case
      when v_res = 'voll' then 'traegt'                         -- nur MC richtig
      when v_res in ('nicht','teilweise') then 'traegt_nicht'
      else 'nicht_angesetzt' end;                               -- weiss_nicht/leer
    insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
      values (p_session_id, v_sk, v_prov, true, true, 1);
    return v_prov;
  else
    -- PROBE 2 (offen=true)
    v_a := case v_row.zustand
             when 'traegt' then 'mc_ja'
             when 'traegt_nicht' then 'nicht'
             else 'weiss_nicht' end;               -- nicht_angesetzt
    v_b := case
             when v_res = 'voll' then 'voll'
             when v_res in ('weiss_nicht','leer') then 'weiss_nicht'
             else 'nicht' end;                     -- nicht/teilweise
    v_final := public.lsa_urteil_aufloesung(v_a, v_b);
    update lsa_skill_urteil
       set zustand = v_final, proben_anzahl = 2, offen = false, aktualisiert = now()
     where session_id = p_session_id and skill_key = v_sk;
    if v_final = 'traegt' then
      perform public.lsa_mitbelegung(p_session_id, v_sk);
    end if;
    return v_final;
  end if;
end;
$$;

-- ============================================================================
-- 6. Regel 3/4/5 — adaptive Auswahl (Kern, service_role)
--
--    Gibt task_id oder NULL. NUR die task_id — der Payload laeuft weiter ueber
--    lsa_question_payload. Kein task_solutions-Zugriff hier.
--    Seiteneffekt laut Vorlage: kein Kandidat zu einem faelligen Skill ->
--    zustand='ungeprueft' schreiben und weiter (nicht abstuerzen).
-- ============================================================================

create or replace function public.lsa_select_next_core(
  p_session_id    uuid,
  p_status_filter text[] default array['ready'],
  p_jetzt         timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sess    lsa_sessions;
  v_open    text;
  v_prefer_nonmc boolean;
  v_desc    text;
  v_leaf    text;
  v_task    uuid;
  v_iter    int := 0;
begin
  select * into v_sess from lsa_sessions where id = p_session_id;
  if not found or v_sess.status <> 'in_progress' then
    return null;
  end if;

  -- Regel 5: Ende ausschliesslich ueber die Zeit. Keine neuen Aufgaben ab
  -- ~Minute 19 (started_at + 19 min). Uhr aus started_at, testbar ueber p_jetzt.
  if p_jetzt > coalesce(v_sess.started_at, v_sess.created_at) + interval '19 minutes' then
    return null;
  end if;

  loop
    v_iter := v_iter + 1;
    if v_iter > 100 then
      return null;  -- Schutz gegen Fehlkonfiguration, nie im Normallauf.
    end if;

    -- Schritt 2: offener Zweitbeleg, immer Vorrang.
    select u.skill_key into v_open
      from lsa_skill_urteil u
     where u.session_id = p_session_id and u.offen = true
     order by u.skill_key
     limit 1;

    if v_open is not null then
      -- War die erste Probe MC (provisorisch 'traegt'), dann Zweitprobe NICHT-MC.
      select (zustand = 'traegt') into v_prefer_nonmc
        from lsa_skill_urteil where session_id = p_session_id and skill_key = v_open;

      select t.id into v_task
        from tasks t
       where t.skill_key = v_open
         and t.status = any (p_status_filter)
         and t.id not in (select task_id from lsa_responses where session_id = p_session_id)
       order by (case when coalesce(v_prefer_nonmc,false) and t.input_type <> 'MC' then 0 else 1 end),
                t.sondierrang nulls last,
                md5(p_session_id::text || t.id::text)
       limit 1;

      if v_task is not null then
        return v_task;
      end if;
      -- Keine Zweitprobe verfuegbar: konservativ finalisieren (provisorischer
      -- Zustand bleibt stehen), Schleife neu.
      update lsa_skill_urteil set offen = false, aktualisiert = now()
        where session_id = p_session_id and skill_key = v_open;
      continue;
    end if;

    -- Schritt 3: Abstieg. Tiefste noch ungedeckte DIREKTE Voraussetzung eines
    -- negativ-finalen Skills.
    select x.q into v_desc from (
      select k.voraussetzt_skill_key as q, s.fundament_tiefe as tf
        from lsa_skill_urteil u
        join skill_kante k on k.skill_key = u.skill_key
        join skills s on s.skill_key = k.voraussetzt_skill_key
       where u.session_id = p_session_id
         and u.offen = false
         and u.zustand in ('traegt_nicht','nicht_angesetzt')
         and not exists (
               select 1 from lsa_skill_urteil d
                where d.session_id = p_session_id and d.skill_key = k.voraussetzt_skill_key)
       order by s.fundament_tiefe desc, k.voraussetzt_skill_key
       limit 1
    ) x;

    if v_desc is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_desc
         and t.status = any (p_status_filter)
         and t.id not in (select task_id from lsa_responses where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      if v_task is not null then
        return v_task;
      end if;
      -- Kein Kandidat: 'ungeprueft', den Ast NICHT ueberspringen -> weiter.
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_desc, 'ungeprueft', false, false, 0)
        on conflict (session_id, skill_key) do nothing;
      continue;
    end if;

    -- Schritt 4: neues Blatt nach gieriger Deckung (zur Laufzeit gerechnet).
    select y.leaf into v_leaf from (
      select b.skill_key as leaf, s.fundament_tiefe as tf,
             1 + (select count(*) from public.lsa_abschluss(b.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu
        from skills b join skills s on s.skill_key = b.skill_key
       where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key = b.skill_key)
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = b.skill_key)
       order by neu desc, s.fundament_tiefe desc, b.skill_key
       limit 1
    ) y;

    if v_leaf is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_leaf
         and t.status = any (p_status_filter)
         and t.id not in (select task_id from lsa_responses where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      if v_task is not null then
        return v_task;
      end if;
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_leaf, 'ungeprueft', false, false, 0)
        on conflict (session_id, skill_key) do nothing;
      continue;
    end if;

    -- Schritt 5: Restzeit — beliebiger Skill ohne Urteil, der Aufgaben hat.
    select t.id into v_task
      from tasks t
     where t.skill_key is not null
       and t.status = any (p_status_filter)
       and t.id not in (select task_id from lsa_responses where session_id = p_session_id)
       and not exists (
             select 1 from lsa_skill_urteil u
              where u.session_id = p_session_id and u.skill_key = t.skill_key)
     order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
     limit 1;
    if v_task is not null then
      return v_task;
    end if;

    -- Schritt 6: nichts mehr.
    return null;
  end loop;
end;
$$;

-- ============================================================================
-- 7. Duenne Wrapper mit Zugriffspruefung (authenticated + service_role)
-- ============================================================================

create or replace function public.lsa_urteil_buchen(p_session_id uuid, p_task_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare v_student uuid;
begin
  select student_id into v_student from lsa_sessions where id = p_session_id;
  if v_student is null then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_student) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  return public.lsa_urteil_buchen_core(p_session_id, p_task_id);
end;
$$;

create or replace function public.lsa_select_next(
  p_session_id    uuid,
  p_status_filter text[] default array['ready']
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_student uuid;
begin
  select student_id into v_student from lsa_sessions where id = p_session_id;
  if v_student is null then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_student) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  return public.lsa_select_next_core(p_session_id, p_status_filter, now());
end;
$$;

-- ============================================================================
-- 8. Grants (S9-Muster)
-- ============================================================================

revoke execute on function public.lsa_abschluss(text)                          from public;
revoke execute on function public.lsa_urteil_aufloesung(text, text)            from public;
revoke execute on function public.lsa_mitbelegung(uuid, text)                  from public;
revoke execute on function public.lsa_urteil_buchen_core(uuid, uuid)           from public;
revoke execute on function public.lsa_select_next_core(uuid, text[], timestamptz) from public;
revoke execute on function public.lsa_urteil_buchen(uuid, uuid)                from public;
revoke execute on function public.lsa_select_next(uuid, text[])                from public;

grant execute on function public.lsa_abschluss(text)                          to service_role;
grant execute on function public.lsa_urteil_aufloesung(text, text)            to service_role;
grant execute on function public.lsa_mitbelegung(uuid, text)                  to service_role;
grant execute on function public.lsa_urteil_buchen_core(uuid, uuid)           to service_role;
grant execute on function public.lsa_select_next_core(uuid, text[], timestamptz) to service_role;
grant execute on function public.lsa_urteil_buchen(uuid, uuid)                to authenticated, service_role;
grant execute on function public.lsa_select_next(uuid, text[])                to authenticated, service_role;

commit;
