-- P5b, dritter Teil — Auflage N1 aus der Nachpruefung des Consensus-Checks.
-- Setzt 20260930100000_session_platz_zugang.sql und
-- 20260930100100_session_platz_zugang_nachtrag.sql voraus (beide committet und
-- durch guard-paths.sh gesperrt, deshalb eine weitere Datei). Alle drei gehoeren
-- zu P5b und werden nacheinander eingespielt.
--
-- Fehler in der Nachtrag-Fassung: session_platz_zugang pruefte hat_zugang und
-- "irgendein begonnener Vertrag" unabhaengig voneinander. hat_zugang ist ab
-- Abschluss wahr (auch vor Beginn), und das zweite exists konnte ein laengst
-- beendeter Altvertrag erfuellen: ein Rueckkehrer nach einem Jahr Pause bekam
-- schon vor Beginn des neuen Vertrags einen Platz.
--
-- Jetzt:
--   vertrag_bruecke(s, d)     einzige Implementierung der Bruecke vor einem
--                             Folgevertrag (ohne Widerruf alt/neu).
--   hat_zugang(s, d)          Status-Zweig wie bisher OR vertrag_bruecke —
--                             inhaltlich unveraendert gegenueber dem Nachtrag.
--   session_platz_zugang(s,d) hat_zugang(s, d) AND ( derselbe Vertrag laeuft am
--                             Datum: abgeschlossen, wirksamer Status aktiv/
--                             im_widerruf, vertragsbeginn <= d <= vertrag_ende,
--                             Ende gesetzt  OR  vertrag_bruecke(s, d) ).
-- Trigger und session_platz_kandidaten rufen weiter session_platz_zugang.

begin;

create or replace function public.vertrag_bruecke(p_student_id uuid, p_datum date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.vertraege alt
      join public.vertraege neu on neu.vorgaenger_id = alt.id
     where alt.student_id = p_student_id
       and alt.status = 'abgeschlossen'
       and alt.widerrufen_am is null
       and alt.vertrag_ende is not null
       and alt.vertrag_ende < p_datum
       and neu.status = 'abgeschlossen'
       and neu.widerrufen_am is null
       and neu.vertragsbeginn is not null
       and neu.vertragsbeginn > p_datum
  );
$$;

comment on function public.vertrag_bruecke(uuid, date) is
  'Bruecke vor einem Folgevertrag: Vorgaenger beendet, verknuepfter Folgevertrag abgeschlossen mit Beginn nach dem Datum, keiner von beiden widerrufen. Einzige Implementierung; genutzt von hat_zugang und session_platz_zugang.';

revoke all on function public.vertrag_bruecke(uuid, date) from public, anon, authenticated;

create or replace function public.hat_zugang(p_student_id uuid, p_datum date default current_date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.vertraege v
     where v.student_id = p_student_id
       and v.status = 'abgeschlossen'
       and public.vertrag_wirksamer_status(
             v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
           ) in ('im_widerruf', 'aktiv')
  )
  or public.vertrag_bruecke(p_student_id, p_datum);
$$;

create or replace function public.session_platz_zugang(p_student_id uuid, p_datum date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.hat_zugang(p_student_id, p_datum)
     and (
       exists (
         select 1
           from public.vertraege v
          where v.student_id = p_student_id
            and v.status = 'abgeschlossen'
            and v.vertragsbeginn is not null
            and v.vertrag_ende is not null
            and p_datum between v.vertragsbeginn and v.vertrag_ende
            and public.vertrag_wirksamer_status(
                  v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
                ) in ('im_widerruf', 'aktiv')
       )
       or public.vertrag_bruecke(p_student_id, p_datum)
     );
$$;

comment on function public.session_platz_zugang(uuid, date) is
  'Platz in einer regulaeren Session: hat_zugang am Datum UND (ein Vertrag laeuft am Datum — aktiv/im_widerruf, Beginn <= Datum <= Ende — ODER vertrag_bruecke).';

revoke all on function public.session_platz_zugang(uuid, date) from public, anon, authenticated;

commit;
