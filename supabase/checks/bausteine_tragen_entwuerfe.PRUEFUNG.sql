-- PRUEFUNG zu 20261004095314_bausteine_tragen_entwuerfe.
--
--   ~/bin/dbread -f supabase/checks/bausteine_tragen_entwuerfe.PRUEFUNG.sql
--
-- AUSSCHLIESSLICH lesend. Gilt auch nach Lenas Abnahme (dann steht der Entwurf
-- in text, entwurf ist leer). Platzhalter wie {traegt} zaehlen nicht als Text.

\pset pager off

do $$
declare v_n int;
begin
  select count(*) into v_n from supabase_migrations.schema_migrations
   where version = '20261004095314';
  if v_n <> 1 then raise exception 'Migration 20261004095314 nicht eingetragen'; end if;

  -- 1. Kein gerenderter Satz in alter Sprache ohne Entwurf.
  select count(*) into v_n from report_bausteine
   where slot in ('befund_traegt', 'fazit', 'empfehlung', 'rueckbezug', 'ausgangspunkt')
     and entwurf is null
     and regexp_replace(text, '\{\w+\}', '', 'g') ~* '(trägt|trug|getragen|\mtragen|Ebene|Fundament)';
  if v_n > 0 then raise exception '% Saetze sagen noch tragen/Ebene und haben keinen Entwurf', v_n; end if;

  -- 2. Kein Entwurf in alter Sprache.
  select count(*) into v_n from report_bausteine
   where regexp_replace(entwurf, '\{\w+\}', '', 'g') ~* '(trägt|trug|getragen|\mtragen|Ebene|Fundament)';
  if v_n > 0 then raise exception '% Entwuerfe in alter Sprache', v_n; end if;

  -- 3. Kein Fall ist aus dem Report gefallen.
  select count(*) into v_n from (
    select slot, fall from report_bausteine where slot in ('befund_traegt', 'fazit', 'empfehlung')
     group by slot, fall having count(freigegeben_am) < 2) x;
  if v_n > 0 then raise exception '% Faelle mit weniger als zwei abgenommenen Varianten', v_n; end if;

  raise notice 'bausteine_tragen_entwuerfe: alle Bedingungen gehalten';
end $$;

select schluessel, case when entwurf is null then 'abgenommen' else 'Entwurf offen' end as stand
  from report_bausteine
 where schluessel in ('befund_traegt.standard.a', 'befund_traegt.standard.b', 'empfehlung.keine.b',
                      'fazit.mehrere.b', 'fazit.zwei.b')
 order by 1;
