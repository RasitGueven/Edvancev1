-- E3 (Session-Rahmen): Die LSA läuft ohne Hinweise, für echte Kinder und für Testkonten.
-- Entscheidung Rasit 12.10.2026: Hinweise gibt es nur in der Session (hinweis_abrufen). Anlass: E3 legt Hinweise für
-- Aufgaben mit Einsatz lsa und session an; nach Lenas Freigabe hätte lsa_hint sie auch in einer echten LSA geliefert.
--
-- lsa_hint liefert immer {"level": p_level, "text": null, "available": false}. Die Prüfungen auf Session, Zugriff
-- und Item bleiben unverändert und kommen vorher, damit die Fehlercodes gleich bleiben (P0002, 42501, P0001).
-- Signatur, SECURITY DEFINER, search_path und Rechte unverändert (create or replace behält die Grants).
-- Aufrufer (12.10.2026): keine andere Funktion in Prod (pg_proc), kein Aufruf in src/ und edvance-app/src.
-- Vorher: 20261013151404_t3_lsa_testkonto_inhalte.sql (geprüfte Hinweise, für Testkonten jeder mit Text).

CREATE OR REPLACE FUNCTION public.lsa_hint(p_session_id uuid, p_task_id uuid, p_level integer DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session lsa_sessions;
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

  -- Entscheidung Rasit 12.10.2026: Hinweise sind nur fuer die Session (hinweis_abrufen). Die LSA misst den Stand
  -- ohne Hilfe, fuer echte Kinder und fuer Testkonten; auch gepruefte Hinweise kommen hier nicht.
  return jsonb_build_object('level', p_level, 'text', null, 'available', false);
end;
$function$;
