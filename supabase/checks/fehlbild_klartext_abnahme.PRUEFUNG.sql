-- PRUEFUNG zu AF3 (Abnahme-Schranke auf fehlbild_labels.freigegeben_am).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/fehlbild_klartext_abnahme.PRUEFUNG.sql
--
-- Ergaenzt fehlbild_auswertung.PRUEFUNG.sql, ersetzt sie NICHT: dort steht,
-- dass gezaehlt und eingestuft wird, hier steht, WELCHER TEXT dabei die
-- Datenbank verlaesst. Getrennt, weil die Faelle unabhaengig brechen koennen —
-- eine kaputte Einstufung ist ein Rechenfehler, ein durchgerutschter Entwurf
-- ein Textfehler im Elterngespraech.
--
-- Laeuft gegen eine bereits migrierte Datenbank (tools/neuaufbau-test.sh baut
-- sie) und faengt sich SELBST in begin/rollback.

begin;

do $$
declare
  v_coach   uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_sess    uuid := gen_random_uuid();
  v_t       uuid[];
  v_txt     text;
  v_n       bigint;
  v_ctrl    boolean;
begin
  -- ══ Testdaten ═════════════════════════════════════════════════════════════

  insert into auth.users (id, email) values (v_coach, 'af3-coach@edvance.test');
  insert into public.profiles (id, email, role)
    values (v_coach, 'af3-coach@edvance.test', 'coach');
  perform set_config('request.jwt.claim.sub', v_coach::text, true);

  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('AF3_PROBE', 'AF3 Probe', 'mathematik', 8, 1);

  insert into public.students (id, class_level) values (v_student, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade)
  values (v_sess, v_student, 'mathematik', 8);

  select array_agg(id order by nr) into v_t
    from (select gen_random_uuid() as id, nr from generate_series(1, 4) as nr) x;

  insert into public.tasks (id, content_type, skill_key, question)
  values (v_t[1], 'exercise', 'AF3_PROBE', 'AF3 Probe 1'),
         (v_t[2], 'exercise', 'AF3_PROBE', 'AF3 Probe 2'),
         (v_t[3], 'exercise', 'AF3_PROBE', 'AF3 Probe 3'),
         (v_t[4], 'exercise', 'AF3_PROBE', 'AF3 Probe 4');

  -- Zwei Labels mit IDENTISCHEM Klartext-Aufbau, nur die Abnahme trennt sie.
  -- Genau eine Variable — sonst belegt ein gruener Lauf nicht, dass es die
  -- Abnahme war und nicht der Text.
  insert into public.fehlbild_labels (slug, klartext, erklaerung, freigegeben_am, freigegeben_von)
  values ('af3_abgenommen', 'abgenommener Text', 'Probe', now(), v_coach),
         ('af3_entwurf',    'ENTWURF-Text',      'Probe', null,  null);

  -- Je zwei Vorkommen in zwei Aufgaben -> beide werden 'befund'. Die Einstufung
  -- ist damit fuer beide gleich; unterschiedlich ist nur der Klartext.
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values
    (v_sess, v_t[1], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af3_abgenommen'),
    (v_sess, v_t[2], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af3_abgenommen'),
    (v_sess, v_t[3], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af3_entwurf'),
    (v_sess, v_t[4], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af3_entwurf');

  -- ══ Fall 1: abgenommener Klartext wird ausgeliefert ═══════════════════════
  --
  -- Ab AF4 ist klartext der COACH-Satz und verlaesst die Datenbank nur noch
  -- ueber lsa_fehlbild_report. Der Eltern-Pfad (lsa_fehlbild_auswertung) fuehrt
  -- die Spalte nicht mehr — deshalb steht die Textprobe hier auf der
  -- Coach-Sicht. Fall 3 belegt, dass es im Eltern-Pfad wirklich keinen Weg gibt.

  select klartext into v_txt
    from public.lsa_fehlbild_report(v_sess)
   where fehlbild_slug = 'af3_abgenommen';
  if v_txt is distinct from 'abgenommener Text' then
    raise exception 'F1: abgenommener Klartext fehlt (bekam %)', coalesce(v_txt, '<null>');
  end if;
  raise notice 'F1 ok: abgenommener Klartext wird ausgeliefert';

  -- ══ Fall 2: unabgenommener Entwurf kommt NICHT heraus ═════════════════════
  --
  -- Der Kern von AF3. Die Zeile muss weiterhin ERSCHEINEN (das Fehlbild ist
  -- belegt und traegt die Einstufung), nur der Text fehlt. Die Belegzahl kommt
  -- aus dem Eltern-Pfad, der Text aus der Coach-Sicht — genau die Aufteilung,
  -- die AF4 hergestellt hat.

  select anzahl into v_n
    from public.lsa_fehlbild_auswertung(v_sess)
   where fehlbild_slug = 'af3_entwurf';
  if v_n is distinct from 2 then
    raise exception 'F2: Entwurfs-Zeile fehlt oder zaehlt falsch (anzahl=%)', coalesce(v_n::text, '<keine Zeile>');
  end if;
  select klartext into v_txt
    from public.lsa_fehlbild_report(v_sess)
   where fehlbild_slug = 'af3_entwurf';
  if v_txt is not null then
    raise exception 'F2: unabgenommener Entwurf ausgeliefert: %', v_txt;
  end if;
  raise notice 'F2 ok: Entwurf erscheint als Zeile, aber ohne Klartext';

  -- ══ Fall 3: der Eltern-Pfad fuehrt gar keinen Klartext mehr ═══════════════
  --
  -- Bis AF3 trugen BEIDE RPCs die Schranke, und dieser Fall prueft, dass keine
  -- der beiden ein offener Auslieferungspfad ist. Ab AF4 ist die Antwort im
  -- Eltern-Pfad struktureller Natur: die Spalte existiert dort nicht. Das ist
  -- die staerkere Zusicherung — eine Spalte, die es nicht gibt, kann keine
  -- Schranke vergessen. Der Elternsatz laeuft ueber familie_elterntext mit
  -- eigener Schranke (supabase/checks/fehlbild_familien.PRUEFUNG.sql).

  if exists (
    select 1 from pg_proc p
     join unnest(p.proallargtypes, p.proargnames) as a(atttype, attname) on true
    where p.proname = 'lsa_fehlbild_auswertung'
      and p.pronamespace = 'public'::regnamespace
      and a.attname = 'klartext'
  ) then
    raise exception 'F3: lsa_fehlbild_auswertung fuehrt wieder klartext — der '
                    'Coach-Satz hat im Eltern-Pfad nichts zu suchen (INV-4.3)';
  end if;
  raise notice 'F3 ok: kein Klartext-Pfad zum Elternreport';

  -- ══ Fall 4: Abnahme wirkt sofort ══════════════════════════════════════════
  --
  -- Belegt, dass die Schranke an freigegeben_am haengt und nicht an etwas
  -- anderem, das zufaellig mitlaeuft (etwa dem Alter der Zeile).

  update public.fehlbild_labels
     set freigegeben_am = now(), freigegeben_von = v_coach
   where slug = 'af3_entwurf';

  select klartext into v_txt
    from public.lsa_fehlbild_report(v_sess)
   where fehlbild_slug = 'af3_entwurf';
  if v_txt is distinct from 'ENTWURF-Text' then
    raise exception 'F4: nach Abnahme kommt der Text nicht durch (bekam %)', coalesce(v_txt, '<null>');
  end if;
  raise notice 'F4 ok: Abnahme schaltet den Text frei';

  -- ══ Fall 5: Ruecknahme wirkt ebenfalls ════════════════════════════════════

  update public.fehlbild_labels
     set freigegeben_am = null, freigegeben_von = null
   where slug = 'af3_entwurf';

  select klartext into v_txt
    from public.lsa_fehlbild_report(v_sess)
   where fehlbild_slug = 'af3_entwurf';
  if v_txt is not null then
    raise exception 'F5: nach Ruecknahme wird weiter ausgeliefert: %', v_txt;
  end if;
  raise notice 'F5 ok: Ruecknahme sperrt den Text wieder';

  -- ══ Fall 6: 'nicht zugeordnet' bleibt unabhaengig von der Abnahme ═════════
  --
  -- Die Zeile ohne Slug traegt keinen Klartext ueber ein Kind, sondern einen
  -- Befund ueber die Registry (AF2). Sie darf die Schranke nicht treffen.

  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_t[1], 2, 'antwort', false, '{"text":"x"}'::jsonb, null);

  select klartext into v_txt
    from public.lsa_fehlbild_report(v_sess)
   where fehlbild_slug is null;
  if v_txt is distinct from 'nicht zugeordnet' then
    raise exception 'F6: "nicht zugeordnet" verschwunden (bekam %)', coalesce(v_txt, '<null>');
  end if;
  raise notice 'F6 ok: "nicht zugeordnet" passiert die Schranke unveraendert';

  -- ══ Fall 7: die AF3-Elternentwuerfe sind durch Coach-Saetze ersetzt ════════
  --
  -- ABGELOEST DURCH AF4. Bis AF4 stand hier, dass linearer_faktor und
  -- faktor_zehn_daneben NICHT freigegeben sein duerfen: ihr klartext war ein
  -- LLM-Entwurf in ELTERNSPRACHE, und ein Elternsatz braucht Lenas Abnahme.
  --
  -- Mit AF4 ist klartext der COACH-Satz (die Elternsprache ist nach
  -- fehlbild_familien.elterntext gewandert) und beide Slugs sind bewusst in
  -- einer Migration freigegeben — ein Coach-Satz ist eine Arbeitsnotiz zwischen
  -- Fachleuten, kein Satz ueber ein Kind an dessen Eltern.
  --
  -- Der Fall prueft jetzt genau diesen Uebergang: die Elternprosa aus AF3 darf
  -- nicht als freigegebener klartext ueberleben. Waeren die Migrationen je
  -- umsortiert oder AF4 zurueckgerollt, stuende der Entwurf wieder freigegeben
  -- im Coachreport — und genau das faengt diese Probe.

  select klartext into v_txt from public.fehlbild_labels where slug = 'linearer_faktor';
  if v_txt is distinct from 'Nutzt den linearen Umrechnungsfaktor, wo der quadrierte gilt.' then
    raise exception 'F7: linearer_faktor traegt nicht den AF4-Coach-Satz (bekam %)',
      coalesce(v_txt, '<null>');
  end if;
  select klartext into v_txt from public.fehlbild_labels where slug = 'faktor_zehn_daneben';
  if v_txt is distinct from 'Ergebnis um den Faktor 10 daneben, in beide Richtungen.' then
    raise exception 'F7: faktor_zehn_daneben traegt nicht den AF4-Coach-Satz (bekam %)',
      coalesce(v_txt, '<null>');
  end if;
  if exists (
    select 1 from public.fehlbild_labels
     where freigegeben_am is not null
       and (klartext ilike '%Ihr Kind%' or klartext ilike '%vergrößert%')
  ) then
    raise exception 'F7: ein Elternsatz steht als freigegebener Coach-Klartext';
  end if;
  raise notice 'F7 ok: AF3-Elternentwuerfe sind durch Coach-Saetze ersetzt';

  -- ══ Fall 8: falsche_operation ist in der Registry ═════════════════════════

  if not exists (select 1 from public.fehlbild_labels where slug = 'falsche_operation') then
    raise exception 'F8: der Slug falsche_operation fehlt weiterhin in der Registry';
  end if;
  raise notice 'F8 ok: falsche_operation ist nachgetragen';

  -- ══ Negativkontrolle des Harnischs selbst ═════════════════════════════════

  v_ctrl := false;
  begin
    if (select count(*) from public.lsa_fehlbild_auswertung(v_sess)) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'AF3: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
