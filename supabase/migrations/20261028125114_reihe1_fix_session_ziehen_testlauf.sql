-- Reihe 1 · Fix Session-Auswahl A2+C2 (Merge Reihe 1, 28.10.2026, Freigabe Rasit: Korrektur-Migration erlaubt).
--
-- session_ziehen (C2, 20261027133007) gab auf dem A-Weg (aufgabe_ziehen vorhanden) das Ergebnis direkt zurück.
-- aufgabe_ziehen hat laut Konzept §9 keinen Testlauf-Parameter und zieht nur ziehbare Instanzen; Testlauf-Entwürfe
-- fielen damit heraus, die Session lief in pool_leer/warten (pgTAP session_a2d, session_f1, session_f2_phasen in
-- Kombination A2 + C2). Jetzt: Liefert der A-Weg nichts und läuft ein Testlauf, fällt die Funktion für
-- warmup/uebung/recap/beispiel auf session_aufgabe_waehlen(…, true, …) zurück, angenommen nur Aufgaben ohne Bauform
-- oder Instanzen genau dieser Rolle (Zweitprüfung P1, §3.1). Echte Sessions und der Weg ohne A unverändert.
-- Signatur, Rechte und Rückgabe unverändert. LSA-Auswahl (lsa_start, platz_next, lsa_im_pool) nicht berührt.
-- Rollback: supabase/rollback/20261028125114_reihe1_fix_session_ziehen_testlauf.sql.

create or replace function public.session_ziehen(p_session_id uuid, p_student_id uuid, p_skill_key text, p_rolle text,
                                      p_stufe int, p_testlauf boolean, p_nur_ungesehen boolean default false,
                                      out task_id uuid, out difficulty int)
returns record
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_aus  uuid[] := public.session_ausschluss(p_session_id, p_student_id, p_nur_ungesehen);
  v_s    int;
  w      record;
begin
  if to_regprocedure('public.aufgabe_ziehen(uuid,text,text,integer,uuid[])') is not null then
    for v_s in
      select x from (select p_stufe as x, 0 as o where p_stufe is not null
                     union all select g, 1 + p_stufe - g from generate_series(1, coalesce(p_stufe, 1) - 1) g
                     union all select g, 10 + g from generate_series(coalesce(p_stufe, 5) + 1, 5) g
                     union all select null::int, 99 where p_stufe is null) s order by o
    loop
      begin
        execute 'select public.aufgabe_ziehen($1, $2, $3, $4, $5)' into task_id
          using p_student_id, p_skill_key, p_rolle, v_s, v_aus;
      exception when insufficient_privilege then
        -- Zweitprüfung C2-3: z. B. Coach-Vorschau ohne Akte; dann nichts ziehen statt abbrechen.
        task_id := null; return;
      end;
      if task_id is not null then
        difficulty := public.session_stufe(task_id);
        return;
      end if;
    end loop;
    -- aufgabe_ziehen kennt keinen Testlauf (Konzept §9). Im Testlauf weiter zum bisherigen Pool, der Entwürfe
    -- zeigt; in echten Sessions bleibt es beim A-Weg (§3.1: Beispiel nur als Instanz der Rolle beispiel).
    if not coalesce(p_testlauf, false) then
      return;
    end if;
    -- Testlauf: nur Aufgaben ohne Bauform oder Instanzen genau dieser Rolle (§3.1, z. B. nie home vor Ort).
    if p_rolle in ('warmup', 'uebung', 'recap', 'beispiel') then
      select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_skill_key, coalesce(p_stufe, 2),
                                                          true, p_rolle = 'beispiel');
      if w.task_id is not null and not (w.task_id = any (v_aus))
         and exists (select 1 from public.tasks t
                      where t.id = w.task_id and (t.bauform_id is null or t.rolle = p_rolle)) then
        task_id := w.task_id;
        difficulty := w.difficulty;
      end if;
    end if;
    return;
  end if;
  -- Ohne Auftrag A: bisheriger Session-Pool, nur für Rollen, die es dort schon gibt.
  if p_rolle in ('warmup', 'uebung', 'recap', 'beispiel') then
    select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_skill_key, coalesce(p_stufe, 2),
                                                        p_testlauf, p_rolle = 'beispiel');
    if w.task_id is not null and not (w.task_id = any (v_aus)) then
      task_id := w.task_id;
      difficulty := w.difficulty;
    end if;
  end if;
end;
$$;
