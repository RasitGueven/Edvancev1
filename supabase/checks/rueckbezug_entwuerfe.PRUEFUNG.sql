-- PRUEFUNG zu W5-d Nachtrag 2 (Rueckbezug-Entwuerfe).
--
--   ~/bin/dbread -f supabase/checks/rueckbezug_entwuerfe.PRUEFUNG.sql
--
-- AUSSCHLIESSLICH lesend, nach dem Einspielen von
--   20261004003309_report_bausteine_entwurf
--   20261004003310_rueckbezug_entwuerfe
-- Bricht bei jeder verletzten Bedingung ab. Gilt auch NACH Lenas Abnahme:
-- ein abgenommener Entwurf steht dann in text, entwurf ist leer.

\pset pager off

do $$
declare
  v_n int;
begin
  select count(*) into v_n
    from supabase_migrations.schema_migrations
   where version in ('20261004003309', '20261004003310');
  if v_n <> 2 then
    raise exception 'Migrationen eingetragen: % von 2', v_n;
  end if;

  -- 1. Jeder der elf Saetze hat entweder einen Entwurf oder ist schon abgenommen
  --    (dann ohne Trage-/Ebenensprache im text).
  select count(*) into v_n from report_bausteine
   where slot = 'rueckbezug'
     and (fall like 'grundlagen%' or schluessel = 'rueckbezug.textverstaendnis_bestaetigend.b')
     and entwurf is null
     and text ~* '(trägt|trug|getragen|tragen|Ebene|Fundament|aktuellen Themas)';
  if v_n > 0 then
    raise exception '% Rueckbezug-Saetze in alter Sprache ohne Entwurf', v_n;
  end if;

  -- 2. Die Entwuerfe selbst sind frei davon.
  select count(*) into v_n from report_bausteine
   where entwurf ~* '(trägt|trug|getragen|tragen|Ebene|Fundament|aktuellen Themas)';
  if v_n > 0 then
    raise exception '% Entwuerfe in alter Sprache', v_n;
  end if;

  -- 3. Kein Satz ist aus dem Report gefallen: jeder Rueckbezug-Fall hat
  --    weiterhin beide Varianten abgenommen.
  select count(*) into v_n from (
    select fall from report_bausteine where slot = 'rueckbezug'
     group by fall having count(freigegeben_am) < 2) x;
  if v_n > 0 then
    raise exception '% Rueckbezug-Faelle mit weniger als zwei abgenommenen Varianten', v_n;
  end if;

  raise notice 'rueckbezug_entwuerfe: alle Bedingungen gehalten';
end $$;

-- Uebersicht fuer die Abnahme
select schluessel,
       case when entwurf is null then 'abgenommen' else 'Entwurf offen' end as stand
  from report_bausteine
 where slot = 'rueckbezug'
   and (fall like 'grundlagen%' or schluessel = 'rueckbezug.textverstaendnis_bestaetigend.b')
 order by schluessel;
