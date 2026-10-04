-- PRUEFUNG zu W5-d Teil 5 (Thema fuer vier alte Sitzungen, Ausgangspunkt-Bausteine).
--
--   ~/bin/dbread -f supabase/checks/thema_nachtrag_alt.PRUEFUNG.sql
--
-- AUSSCHLIESSLICH lesend, nach dem Einspielen von
--   20261004093449_report_ausgangspunkt_entwuerfe
--   20261004093450_lsa_thema_nachtrag_alt
-- Bricht bei jeder verletzten Bedingung ab. Gilt auch nach Lenas Abnahme.

\pset pager off

do $$
declare
  v_n int;
  v_ziel uuid[] := array[
    '143215f5-c9e4-4a26-b4e6-b634589626c3',
    'd0ba7a1b-7f2e-4b95-8207-c82cff162362',
    '4fe409f0-69e1-402a-adfb-5d63af6eb971',
    '6d868c5f-b982-4d1e-9e21-f2768fb706ce']::uuid[];
  v_nicht uuid[] := array[
    '920d00ae-22ed-4eac-88a4-2f7ea719d45d',
    'd8b0d885-b72d-4b68-a17b-6b35db301103',
    '6f64b51e-3f65-4383-9fa7-0fa36e43d0d5',
    'e7b63e2d-b9d9-4b40-9273-5dcfda83b0bc',
    'ed93da46-7076-4cfa-96b4-26e6be429768']::uuid[];
begin
  select count(*) into v_n from supabase_migrations.schema_migrations
   where version in ('20261004093449', '20261004093450');
  if v_n <> 2 then raise exception 'Migrationen eingetragen: % von 2', v_n; end if;

  -- 1. Genau die vier Sitzungen: Thema + nachgetragener Raum, Rest erhalten.
  select count(*) into v_n from lsa_sessions
   where id = any (v_ziel)
     and thema_key = 'terme_gleichungen'
     and result_summary -> 'themenraum' ->> 'stand' = 'nachgetragen'
     and result_summary -> 'themenraum' ->> 'thema_key' = 'terme_gleichungen'
     and result_summary ?& array['answered', 'planned', 'competencies', 'afb', 'proposal'];
  if v_n <> 4 then raise exception 'Nachgetragen: % von 4 Sitzungen', v_n; end if;

  -- 2. Die ausdruecklich ausgenommenen bleiben ohne Thema.
  select count(*) into v_n from lsa_sessions
   where id = any (v_nicht) and (thema_key is not null or result_summary ? 'themenraum');
  if v_n > 0 then raise exception '% ausgenommene Sitzungen haben ein Thema', v_n; end if;

  -- 3. Sonst traegt keine Sitzung einen nachgetragenen Raum.
  select count(*) into v_n from lsa_sessions
   where result_summary -> 'themenraum' ->> 'stand' = 'nachgetragen' and not (id = any (v_ziel));
  if v_n > 0 then raise exception '% weitere Sitzungen mit nachgetragenem Raum', v_n; end if;

  -- 4. Ausgangspunkt-Bausteine: vier Zeilen, kein abgenommener Satz mit Wahl.
  select count(*) into v_n from report_bausteine where slot = 'ausgangspunkt';
  if v_n <> 4 then raise exception 'Ausgangspunkt-Bausteine: % von 4', v_n; end if;
  select count(*) into v_n from report_bausteine
   where slot = 'ausgangspunkt' and freigegeben_am is not null
     and text ~* '(gewählt|ausgesucht|vereinbart|besprochen|aktuell|angesetzt)';
  if v_n > 0 then raise exception '% abgenommene Ausgangspunkt-Saetze setzen eine Wahl voraus', v_n; end if;

  -- 5. fazit.keine.a: Entwurf offen oder schon abgenommen ohne "aktuelle Thema".
  select count(*) into v_n from report_bausteine
   where schluessel = 'fazit.keine.a' and entwurf is null and text ~* 'aktuelle';
  if v_n > 0 then raise exception 'fazit.keine.a in alter Fassung ohne Entwurf'; end if;

  raise notice 'thema_nachtrag_alt: alle Bedingungen gehalten';
end $$;

select left(id::text, 8) as sitzung, grade, thema_key,
       result_summary -> 'themenraum' ->> 'stand' as stand,
       jsonb_array_length(result_summary -> 'themenraum' -> 'darunter') as darunter
  from lsa_sessions where thema_key is not null order by completed_at;
-- Drei Zustaende: neue Zeile ohne Abnahme, alter Satz live mit offenem Entwurf,
-- Entwurf abgenommen. "abgenommen" allein hiesse bei fazit.keine.a sonst auch
-- "alter Satz live" — genau das, was die Uebersicht unterscheiden soll.
select schluessel,
       case when freigegeben_am is null then 'Entwurf offen (neu, nicht live)'
            when entwurf is not null    then 'Entwurf offen (alter Satz live)'
            else 'abgenommen' end as stand
  from report_bausteine where slot = 'ausgangspunkt' or schluessel = 'fazit.keine.a' order by 1;
