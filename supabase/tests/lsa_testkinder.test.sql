-- ============================================================================
-- LSA-T: tools/lsa-testkinder/erzeugen.sql im Neuaufbau (Bauauftraege docs/lsa/Bauauftrag-LSA-T.md, -LSA-T2.md).
--
-- Der Neuaufbau hat Skills, Kanten, Themen, Einstiege und den FWG-Plan aus den Migrationen, aber keine
-- LSA-Aufgaben. Die Fixture gibt deshalb jedem Skill drei Aufgaben (Zahl, MC, Multi-Part; richtig ist
-- 7 bzw. a) mit hinterlegten Fehlbildern. Dann laeuft das Skript zweimal unveraendert, danach mit nur=Max
-- und mit einem unbekannten Namen.
--
-- Bewiesen wird je Kind:
--   1. Die neueste Sitzung ist abgeschlossen, mit result_summary und Themenraum.
--   2. Jeder direkt beurteilte Bereich passt zum Profil (sicher → traegt, uebung → traegt_nicht,
--      teilweise → traegt oder traegt_teilweise, nicht_angesetzt → nicht_angesetzt).
--   3. Jede Sitzung endet durch die Zeit (Summe der Antwortdauern 18,5 bis 21 Minuten) oder vorher, weil die
--      Auswahl keine Aufgabe mehr liefert (lsa_select_next_core gibt null; LSA-V, Entscheidung 2d: eine LSA
--      darf vor Minute 19 enden). Dauer und Grund je Kind stehen als diag in der Ausgabe.
--   4. Lina hat mindestens 80 % sicher, Jonas hoechstens 20 %.
--   5. Emre, Sophie und Nele loesen ihr bevorzugtes Fehlbild aus.
--   6. Die Anliegen stammen nur aus den Intake-Werten (PARENT_WEAK_TOPICS) und stehen wie im Profil am Lead.
--   7. Der zweite Lauf legt neue Sitzungen an, findet dieselben Leads und Schueler und loescht nichts.
--   8. Max (LSA-T2): 100 % sicher, kein Uebungsbedarf, nichts ohne Ansatz, und die Liste „richtig beantwortet,
--      nicht angenommen“ ist leer (die Loesungen der Fixture sind konsistent). LSA-V2: ausser im Ausblick — dort
--      kann Max laut Profil nur das erste kommende Thema.
--   9. Schalter: nur=Max legt genau eine Sitzung an, fuer Max; ein unbekannter Name bricht ab, bevor etwas
--      angelegt wird.
--  10. Tim (LSA-R2) klickt sich durch (2–4 s, fast alles falsch): seine Sitzung ist nicht auswertbar, die
--      der sieben anderen ist auswertbar (lsa_finish ueber lsa_durchklick_stand).
--  11. LSA-V2: Max und Lina bekommen den Ausblick, mit mindestens einem sicheren Knoten, und er endet mit genau
--      zwei nicht sicheren Knoten hintereinander (Stopp). Kein Kind ueber 40 Aufgaben, Tim ohne 'hoechstens'.
--      „Weiß ich nicht“ hat nie einen Zweitbeleg. Jonas kommt bis Klasse 5/6.
--  12. LSA-L2: Batu (Klasse 9, FWG, Reelle Zahlen, Profil aus einem echten Testlauf) laeuft wie die anderen durch
--      (1–3, 6, 10); acht Kinder im zweiten Lauf.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(62);

\ir ../../tools/lsa-testkinder/neuaufbau-fixture.sql

select is((select count(*) from tasks where source_ref like 'lsat-%' and public.lsa_im_pool(id, false)),
          (select 3 * count(*) from skills), 'Fixture: drei Aufgaben je Skill im Pool');

-- Erwarteter Zustand eines direkt beurteilten Bereichs laut Profil des Kindes; true = passt.
create function pg_temp.passt(p_kind jsonb, p_skill text, p_zustand text) returns boolean language sql as $$
  select p_zustand = any (case coalesce(p_kind -> 'ausnahmen' ->> p_skill,
                                        p_kind -> 'grund' ->> (select case when s.klasse_herkunft <= 6 then '56'
                                                                           when s.klasse_herkunft <= 8 then '78'
                                                                           else '910' end
                                                                  from skills s where s.skill_key = p_skill))
                            when 'sicher' then array['traegt']
                            when 'uebung' then array['traegt_nicht']
                            when 'teilweise' then array['traegt', 'traegt_teilweise']
                            else array['nicht_angesetzt'] end)
$$;
create function pg_temp.kind(p_name text) returns jsonb language sql as $$
  select k from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) k where k ->> 'kind' = p_name
$$;
-- Die Sitzung des letzten Laufs (das Skript merkt sie sich in lsat.sitzungen).
create function pg_temp.sitzung(p_name text) returns uuid language sql as $$
  select (current_setting('lsat.sitzungen')::jsonb ->> p_name)::uuid
$$;
create function pg_temp.anteil_sicher(p_name text, p_ohne_ausblick boolean default false) returns numeric
language sql as $$
  select round(count(*) filter (where u.zustand = 'traegt')::numeric / nullif(count(*), 0), 2)
    from lsa_skill_urteil u
   where u.session_id = pg_temp.sitzung(p_name) and u.belegt_direkt and u.zustand <> 'ungeprueft'
     and not (p_ohne_ausblick and public.lsa_ist_ausblick(u.session_id, u.skill_key))
$$;
-- LSA-V2: die direkt beurteilten Ausblick-Knoten in Ausblick-Reihenfolge, je 't' (traegt) oder 'n' (sonst).
create function pg_temp.ausblick(p_name text) returns text language sql as $$
  select coalesce(string_agg(case when u.zustand = 'traegt' then 't' else 'n' end, '' order by x.nr), '')
    from unnest(public.lsa_ausblick_knoten(pg_temp.sitzung(p_name))) with ordinality x(sk, nr)
    join lsa_skill_urteil u on u.session_id = pg_temp.sitzung(p_name) and u.skill_key = x.sk and u.belegt_direkt
$$;

-- ── Erster Lauf ─────────────────────────────────────────────────────────────
\ir ../../tools/lsa-testkinder/erzeugen.sql
create temp table zz_lsat_lauf1 as select l.id from lsa_sessions l where l.student_id::text like 'a5a7c41d-5c00-%';

-- 1–3 je Kind
select is((select l.status from lsa_sessions l where l.id = pg_temp.sitzung(n)), 'completed', n || ': Sitzung abgeschlossen')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Batu']) n;
select ok((select l.result_summary ? 'themenraum' and l.thema_key = pg_temp.kind(n) ->> 'thema'
             from lsa_sessions l where l.id = pg_temp.sitzung(n)),
          n || ': result_summary mit Themenraum des Themas aus dem Erstgespraech')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Batu']) n;
select is((select string_agg(u.skill_key || '=' || u.zustand, ', ') from lsa_skill_urteil u
            where u.session_id = pg_temp.sitzung(n) and u.belegt_direkt and u.zustand <> 'ungeprueft'
              and not pg_temp.passt(pg_temp.kind(n), u.skill_key, u.zustand)),
          null, n || ': jeder direkt beurteilte Bereich passt zum Profil')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Batu']) n;
-- Summe der Antwortdauern einer Sitzung in ms (die Uhr des Skripts: p_jetzt = Beginn + diese Summe).
create function pg_temp.dauer_ms(p_s uuid) returns numeric language sql as $$
  select sum(r.d) from (select distinct r.task_id, r.duration_ms as d from lsa_responses r
                         where r.session_id = p_s) r
$$;
-- Warum die Sitzung endete: 'Zeit' (18,5 bis 21 Minuten), 'Auswahl leer' (vorher, und lsa_select_next_core
-- gibt zum Endzeitpunkt null) oder 'offen' (vorher, aber die Auswahl haette noch eine Aufgabe).
-- Die Auswahl wird in einem zurueckgerollten Teilblock gefragt: sie braucht die Sitzung als in_progress
-- und kann Urteile schreiben; beides bleibt nicht stehen.
create function pg_temp.ende_grund(p_s uuid) returns text language plpgsql as $$
declare v_d numeric := pg_temp.dauer_ms(p_s); v_next uuid; v_beginn timestamptz;
begin
  if v_d between 18.5 * 60000 and 21 * 60000 then
    return 'Zeit';
  end if;
  if (select count(*) from lsa_ausgegeben a where a.session_id = p_s) >= 40 then
    return 'Deckel';  -- LSA-V2
  end if;
  if v_d > 21 * 60000 then
    return 'zu lang';
  end if;
  begin
    update lsa_sessions set status = 'in_progress' where id = p_s
    returning coalesce(diagnose_ab, started_at, created_at) into v_beginn;
    v_next := public.lsa_select_next_core(p_s, array['ready'], v_beginn + make_interval(secs => v_d / 1000.0));
    raise exception using errcode = 'P0A57';
  exception when sqlstate 'P0A57' then null;
  end;
  return case when v_next is null then 'Auswahl leer' else 'offen' end;
end $$;

select ok(pg_temp.ende_grund(pg_temp.sitzung(n)) in ('Zeit', 'Auswahl leer', 'Deckel'),
          n || ': endet durch die Zeit, den Deckel oder weil die Auswahl keine Aufgabe mehr liefert')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Batu']) n;
select diag(n || ': ' || to_char(make_interval(secs => pg_temp.dauer_ms(pg_temp.sitzung(n)) / 1000.0), 'MI:SS')
            || ' Minuten, Ende: ' || pg_temp.ende_grund(pg_temp.sitzung(n)))
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Batu']) n;

-- 4
select ok(pg_temp.anteil_sicher('Lina') >= 0.8, 'Lina: mindestens 80 % sicher (' || pg_temp.anteil_sicher('Lina') || ')');
select ok(pg_temp.anteil_sicher('Jonas') <= 0.2, 'Jonas: hoechstens 20 % sicher (' || pg_temp.anteil_sicher('Jonas') || ')');

-- 8
select ok(pg_temp.anteil_sicher('Max', true) = 1,
          'Max: ausser im Ausblick 100 % der gewerteten Bereiche sicher (' || pg_temp.anteil_sicher('Max', true) || ')');
select is((select count(*) from lsa_skill_urteil u where u.session_id = pg_temp.sitzung('Max') and u.belegt_direkt
              and u.zustand in ('traegt_nicht', 'traegt_teilweise')
              and not public.lsa_ist_ausblick(u.session_id, u.skill_key)), 0::bigint,
          'Max: kein Uebungsbedarf ausser im Ausblick');
select is((select count(*) from lsa_skill_urteil u where u.session_id = pg_temp.sitzung('Max') and u.belegt_direkt
              and u.zustand = 'nicht_angesetzt'), 0::bigint, 'Max: nichts ohne Ansatz');
select is(current_setting('lsat.nicht_angenommen')::jsonb -> 'Max', '[]'::jsonb,
          'Max: jede richtige Antwort angenommen (Liste „richtig beantwortet, nicht angenommen“ leer)');

-- 11 (LSA-V2)
-- Die Folge haengt ueber md5(Sitzung || Aufgabe) an der zufaelligen Sitzungs-ID; endet die Zeit vor dem Stopp,
-- genuegt ein angefangener Ausblick.
select ok(pg_temp.ausblick(n) ~ '^t+nn$'
          or (pg_temp.ende_grund(pg_temp.sitzung(n)) = 'Zeit' and pg_temp.ausblick(n) ~ '^t+n?$'),
          n || ': Ausblick mit sicheren Knoten, Stopp nach zwei nicht sicheren (' || pg_temp.ausblick(n) || ')')
  from unnest(array['Max', 'Lina']) n;
select is((select max(c) from (select count(*) as c from lsa_ausgegeben a
                                where a.session_id in (select pg_temp.sitzung(n)
                                                         from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Tim', 'Batu']) n)
                                group by a.session_id) x) <= 40, true, 'Kein Kind ueber 40 Aufgaben');
-- Tim hat ein Thema: Die Auswahl mit Thema endet nach Thema, Vorschau und Rueckblick von selbst (im Neuaufbau mit drei
-- Aufgaben je Skill vor 40). Ohne 'hoechstens' endet er durch die leere Auswahl oder den Deckel, nie spaeter; den
-- Deckel selbst belegt lsa_v2_ausblick (Fall e, Durchklicker ohne Thema).
select ok(pg_temp.ende_grund(pg_temp.sitzung('Tim')) in ('Deckel', 'Auswahl leer'),
          'Tim: endet durch den Deckel oder die leere Auswahl (' || pg_temp.ende_grund(pg_temp.sitzung('Tim')) || ', '
          || (select count(*) from lsa_ausgegeben a where a.session_id = pg_temp.sitzung('Tim')) || ' Aufgaben)');
select is((select count(*) from lsa_skill_urteil u
            where u.session_id in (select pg_temp.sitzung(n)
                                     from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Tim', 'Batu']) n)
              and u.zustand = 'nicht_angesetzt' and u.belegt_direkt and (u.proben_anzahl <> 1 or u.offen)),
          0::bigint, '„Weiß ich nicht“ ist mit der ersten Probe final, ohne Zweitbeleg');
select ok((select min(s.klasse_herkunft) from lsa_ausgegeben a join tasks t on t.id = a.task_id
             join skills s on s.skill_key = t.skill_key where a.session_id = pg_temp.sitzung('Jonas')) <= 6,
          'Jonas: kommt bis Klasse 5/6');

-- 5
select ok(exists (select 1 from lsa_responses r join fehlbild_labels f on f.slug = r.fehlbild_slug
                   where r.session_id = pg_temp.sitzung(n)
                     and (f.slug in (select jsonb_array_elements_text(pg_temp.kind(n) -> 'fehlbilder'))
                          or f.familie = pg_temp.kind(n) ->> 'familie')),
          n || ': das bevorzugte Fehlbild ist ausgeloest')
  from unnest(array['Emre', 'Sophie', 'Nele']) n;

-- 6
select is((select string_agg(k ->> 'kind' || ': ' || array_to_string(a.weak_topics, ', '), ' | ' order by k ->> 'kind')
             from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) k
             join lead_assessments a on a.lead_id = (k ->> 'lead')::uuid and a.source = 'parent'
            where a.weak_topics <@ array['Grundlagen fehlen', 'Textverständnis', 'Rechenwege', 'Konzentration',
                                         'Prüfungsangst', 'Zeiteinteilung']),
          'Batu: Grundlagen fehlen | Emre: Grundlagen fehlen | Jonas: Grundlagen fehlen, Konzentration | Lina: Rechenwege | Max: Rechenwege | '
            || 'Nele: Prüfungsangst | Sophie: Textverständnis, Konzentration | Tim: Konzentration',
          'Anliegen nur aus PARENT_WEAK_TOPICS, je Kind wie im Profil');

-- 10
select ok((select not l.auswertbar and l.status = 'completed'
                  and (l.nicht_auswertbar_grund ->> 'nicht_auswertbar')::boolean
                  and l.result_summary -> 'durchklick' = l.nicht_auswertbar_grund
             from lsa_sessions l where l.id = pg_temp.sitzung('Tim')),
          'Tim: abgeschlossen und nicht auswertbar, Grund = result_summary.durchklick');
select ok((select l.auswertbar and l.nicht_auswertbar_grund is null
                  and not (l.result_summary -> 'durchklick' ->> 'nicht_auswertbar')::boolean
             from lsa_sessions l where l.id = pg_temp.sitzung(n)),
          n || ': auswertbar')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele', 'Max', 'Batu']) n;
select diag('Tim: ' || (select (l.nicht_auswertbar_grund - 'schwellen')::text from lsa_sessions l where l.id = pg_temp.sitzung('Tim')));

-- ── Zweiter Lauf ────────────────────────────────────────────────────────────
\ir ../../tools/lsa-testkinder/erzeugen.sql

-- 7
select is((select count(*) from leads where id::text like 'a5a7c41d-1ead-%'), 8::bigint, 'Zweiter Lauf: dieselben acht Leads');
select is((select count(*) from students where id::text like 'a5a7c41d-5c00-%' and ist_test and is_provisional),
          8::bigint, 'Zweiter Lauf: dieselben acht Testkonten');
select is((select count(*) from lsa_sessions where student_id::text like 'a5a7c41d-5c00-%' and status = 'completed'),
          16::bigint, 'Zweiter Lauf: sechzehn abgeschlossene Sitzungen, je Kind zwei');
select is((select count(*) from zz_lsat_lauf1 a join lsa_sessions l on l.id = a.id), 8::bigint,
          'Zweiter Lauf: die Sitzungen des ersten Laufs stehen noch');
select ok(pg_temp.sitzung('Lina') not in (select id from zz_lsat_lauf1), 'Zweiter Lauf: die neueste Sitzung ist neu');
select is((select count(*) from leads where id::text like 'a5a7c41d-1ead-%' and status = 'lsa_fertig'), 8::bigint,
          'Zweiter Lauf: alle Leads stehen auf lsa_fertig');

-- ── Schalter (9) ────────────────────────────────────────────────────────────
create temp table zz_lsat_vor_nur as select l.id from lsa_sessions l where l.student_id::text like 'a5a7c41d-5c00-%';
\set nur Max
\ir ../../tools/lsa-testkinder/erzeugen.sql
\unset nur
select is((select array_agg(l.student_id) from lsa_sessions l
            where l.student_id::text like 'a5a7c41d-5c00-%' and l.id not in (select id from zz_lsat_vor_nur)),
          array[(pg_temp.kind('Max') ->> 'schueler')::uuid], 'nur=Max: genau eine neue Sitzung, fuer Max');
select is((select array_agg(k) from jsonb_object_keys(current_setting('lsat.sitzungen')::jsonb) k), array['Max'],
          'nur=Max: nur Max ist gelaufen und steht in der Ausgabe');

-- Ein unbekannter Name: Abbruch mit Meldung. Damit der Test weiterlaeuft, ohne ON_ERROR_STOP im Teilblock;
-- das Skript ueberspringt nach der Meldung alles Weitere (sonst stuende hier „current transaction is aborted“).
savepoint zz_unbekannt;
\set ON_ERROR_STOP off
\set nur 'Max, Moritz'
\ir ../../tools/lsa-testkinder/erzeugen.sql
\set ON_ERROR_STOP on
\unset nur
rollback to savepoint zz_unbekannt;
select is(:'LAST_ERROR_MESSAGE'::text,
          'LSA-T: unbekannte Kinder in nur: Moritz (bekannt: Lina, Emre, Sophie, Jonas, Nele, Max, Tim, Batu)',
          'Unbekannter Name: Abbruch mit klarer Meldung, nichts danach ausgefuehrt');

select * from finish();
rollback;
