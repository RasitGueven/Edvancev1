-- PRUEFUNG zu P5 Items 2-10 (gleichung_modellieren).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/gleichung_modellieren_items2_10.PRUEFUNG.sql
--
-- Schwesterdatei zu gleichung_modellieren_item1.PRUEFUNG.sql. Dort steht ein
-- Item im Detail, hier die neun als MENGE: was bei einem Item eine Nachlaessig-
-- keit waere, ist bei neun ein Muster — deshalb pruefen die Faelle unten
-- durchgaengig ueber alle und melden die Zahl der Abweichler, nicht den ersten.
--
-- Der Cluster wird bewusst NICHT geprueft: supabase/seed.sql laeuft in CI erst
-- NACH den Migrationen, dort ist cluster_id legitim null. Die Zusicherung steht
-- in der Migration (Teil 4), wo der Zeitpunkt bekannt ist.
--
-- Laeuft gegen eine bereits migrierte Datenbank und faengt sich SELBST in
-- begin/rollback. Legt keine Testdaten an — geprueft wird der Bestand.

begin;

do $$
declare
  v_n    integer;
  v_txt  text;
  v_ctrl boolean;
begin
  -- ══ Fall 1: neun Aufgaben mit je zwei Teilen ══════════════════════════════

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref <> 'handytarif-01';
  if v_n <> 9 then
    raise exception 'F1: % Aufgaben aus Items 2-10, erwartet 9', v_n;
  end if;

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren'
     and (input_type <> 'MULTI_PART' or jsonb_array_length(parts) <> 2);
  if v_n <> 0 then
    raise exception 'F1: % Aufgaben sind nicht MULTI_PART mit genau 2 Teilen', v_n;
  end if;

  -- Teil 1 immer mc, Teil 2 immer short_input — die Reihenfolge traegt die
  -- Diagnostik: erst modellieren, dann rechnen.
  select count(*) into v_n from public.tasks t
   where t.source = 'edvance_p5_modellieren'
     and not (
       (select p ->> 'kind' from jsonb_array_elements(t.parts) e(p) where p ->> 'nr' = '1') = 'mc'
       and
       (select p ->> 'kind' from jsonb_array_elements(t.parts) e(p) where p ->> 'nr' = '2') = 'short_input'
     );
  if v_n <> 0 then
    raise exception 'F1: bei % Aufgaben ist Teil 1 nicht mc oder Teil 2 nicht short_input', v_n;
  end if;
  raise notice 'F1 ok: neun Aufgaben, je zwei Teile (mc + short_input)';

  -- ══ Fall 2: afb AM ITEM ═══════════════════════════════════════════════════
  --
  -- Der Fehler, der Item 1 die Freigabe gekostet hat. task_status_set prueft
  -- die SPALTE am Item; ein afb nur in den Teilaufgaben reicht nicht.

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and afb is null;
  if v_n <> 0 then
    raise exception 'F2: % Aufgaben ohne afb AM ITEM — task_status_set bricht '
                    'dort mit "AFB fehlt" (P0001) ab', v_n;
  end if;

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and afb not in ('I', 'II', 'III');
  if v_n <> 0 then
    raise exception 'F2: % Aufgaben mit afb ausserhalb I/II/III', v_n;
  end if;
  raise notice 'F2 ok: afb am Item gesetzt und im Wertebereich';

  -- ══ Fall 3: afb und competency_content in BEIDEN Teilen ═══════════════════
  --
  -- partAfbMissing und partCompetencyMissing sind blockierende Flags des
  -- Autorentools. Fehlen sie, laesst sich das Item ueber die Oberflaeche nicht
  -- freigeben — auch wenn die DB es durchliesse.
  --
  -- ITEM 1 IST HIER AUSGENOMMEN, und das ist ein Befund, keine Bequemlichkeit:
  -- seine beiden Teilaufgaben tragen kein competency_content (die Item-1-
  -- Migration hat es auf null gelassen). In der DB stoert das nicht — das Gate
  -- in task_status_set kennt kein competency —, im Autorentool schon: wer das
  -- Item dort oeffnet und freigeben will, wird von partCompetencyMissing
  -- geblockt. Es steht heute auf 'ready', ein Rueckweg ueber die Oberflaeche
  -- waere aber versperrt. Nachzutragen in einem eigenen Schritt (siehe PR);
  -- diese Datei prueft Items 2-10 und soll nicht an einem Altbestand haengen.

  select count(*) into v_n
    from public.tasks t, jsonb_array_elements(t.parts) e(p)
   where t.source = 'edvance_p5_modellieren'
     and t.source_ref <> 'handytarif-01'
     and (coalesce(p ->> 'afb', '') = ''
          or coalesce(p ->> 'competency_content', '') = '');
  if v_n <> 0 then
    raise exception 'F3: % Teilaufgaben ohne afb oder competency_content — das '
                    'Autorentool blockt die Freigabe', v_n;
  end if;
  raise notice 'F3 ok: alle 18 Teilaufgaben aus Items 2-10 tragen afb und competency_content';

  -- ══ Fall 4: uebrige Pflichtfelder des Gates ═══════════════════════════════
  --
  -- Einzeln benannt, nicht als Sammelbedingung: bei neun Aufgaben ist "irgendwo
  -- fehlt was" keine brauchbare Meldung.

  select string_agg(fehlt || ' (' || anzahl || ')', ', ' order by fehlt) into v_txt
    from (
      select 'question' as fehlt, count(*) as anzahl from public.tasks
        where source = 'edvance_p5_modellieren' and coalesce(btrim(question), '') = ''
      union all
      select 'curriculum_grade', count(*) from public.tasks
        where source = 'edvance_p5_modellieren' and curriculum_grade is null
      union all
      select 'est_duration_sec', count(*) from public.tasks
        where source = 'edvance_p5_modellieren' and est_duration_sec is null
      union all
      select 'skill_key', count(*) from public.tasks
        where source = 'edvance_p5_modellieren' and skill_key is distinct from 'gleichung_modellieren'
    ) x where anzahl > 0;
  if v_txt is not null then
    raise exception 'F4: Pflichtfelder fehlen: %', v_txt;
  end if;
  raise notice 'F4 ok: question, curriculum_grade, est_duration_sec, skill_key gesetzt';

  -- ══ Fall 4b: competency_content AM ITEM ══════════════════════════════════
  --
  -- KEIN Feld des Freigabe-Gates — task_status_set prueft es nicht. Der
  -- Eltern-Report baut daraus aber die Themengliederung: fehlt der Wert,
  -- erscheinen die Aufgaben dort unter "ohne Zuordnung". Genau so ist es
  -- passiert (Nachtrag 20260816100000). Fall 3 prueft den Wert in den
  -- TEILAUFGABEN — der war nie das Problem, er stand von Anfang an.

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref <> 'handytarif-01'
     and coalesce(btrim(competency_content), '') = '';
  if v_n <> 0 then
    raise exception 'F4b: % Aufgaben ohne competency_content AM ITEM — der '
                    'Elternreport fuehrt sie unter "ohne Zuordnung"', v_n;
  end if;

  -- Item und Teilaufgabe muessen denselben Bereich fuehren.
  select count(*) into v_n
    from public.tasks t, jsonb_array_elements(t.parts) e(p)
   where t.source = 'edvance_p5_modellieren' and t.source_ref <> 'handytarif-01'
     and coalesce(btrim(p ->> 'competency_content'), '') <> ''
     and p ->> 'competency_content' is distinct from t.competency_content;
  if v_n <> 0 then
    raise exception 'F4b: bei % Teilaufgaben weicht der Kompetenzbereich vom Item ab', v_n;
  end if;
  raise notice 'F4b ok: competency_content am Item gesetzt und deckungsgleich mit den Teilen';

  -- ══ Fall 5: lsa_parts_valid ═══════════════════════════════════════════════
  --
  -- Der CHECK auf tasks erzwingt das bereits beim Insert. Hier steht es als
  -- Zusicherung ueber den BESTAND — falls jemand parts spaeter von Hand aendert
  -- und der CHECK dabei transaktionslokal fallengelassen wurde.

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and not public.lsa_parts_valid(parts);
  if v_n <> 0 then
    raise exception 'F5: % Aufgaben mit ungueltigen parts (lsa_parts_valid)', v_n;
  end if;
  raise notice 'F5 ok: parts aller Aufgaben sind wohlgeformt';

  -- ══ Fall 6: acceptance verschachtelt und gueltig ══════════════════════════
  --
  -- Der Kern des Aufbaus. Laege acceptance flach, wuerde Teil 1 gegen die
  -- Fehlbilder von Teil 2 gematcht — der AF1-Trigger liest
  -- acceptance -> part_nr::text -> 'known_errors'.

  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = 'edvance_p5_modellieren'
     and (s.acceptance is null or s.acceptance ? 'canonical');
  if v_n <> 0 then
    raise exception 'F6: % Aufgaben ohne acceptance oder mit FLACHER Form', v_n;
  end if;

  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = 'edvance_p5_modellieren'
     and not public.lsa_acceptance_valid(s.acceptance);
  if v_n <> 0 then
    raise exception 'F6: % acceptance sind ungueltig (lsa_acceptance_valid)', v_n;
  end if;

  -- Zu JEDEM Teil eine Regel mit known_errors.
  select count(*) into v_n
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id,
         jsonb_array_elements(t.parts) e(p)
   where t.source = 'edvance_p5_modellieren'
     and s.acceptance -> (p ->> 'nr') -> 'known_errors' is null;
  if v_n <> 0 then
    raise exception 'F6: % Teile ohne known_errors unter ihrer part_nr', v_n;
  end if;
  raise notice 'F6 ok: acceptance je part_nr verschachtelt, gueltig, mit known_errors';

  -- ══ Fall 7: correct_answers als Objekt je part_nr ═════════════════════════

  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = 'edvance_p5_modellieren'
     and not public.lsa_has_answers(t.input_type, t.parts, s.correct_answers);
  if v_n <> 0 then
    raise exception 'F7: % Loesungen erfuellen lsa_has_answers nicht — die '
                    'Freigabe wuerde mit "Loesung unvollstaendig" scheitern', v_n;
  end if;

  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = 'edvance_p5_modellieren'
     and jsonb_typeof(s.correct_answers) <> 'object';
  if v_n <> 0 then
    raise exception 'F7: % correct_answers sind kein Objekt je part_nr', v_n;
  end if;
  raise notice 'F7 ok: correct_answers als Objekt je part_nr, Arrays nicht leer';

  -- ══ Fall 8: MC-Schluessel sind Option-IDs ═════════════════════════════════
  --
  -- lsa_fehlbild_match vergleicht bei mc gegen response->'selected'->>0, also
  -- gegen die ID. Stuende dort der Optionstext, matchte nie etwas — still.

  select count(*) into v_n
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id,
         jsonb_array_elements(t.parts) e(p),
         jsonb_each_text(s.acceptance -> (p ->> 'nr') -> 'known_errors') ke(wert, slug)
   where t.source = 'edvance_p5_modellieren'
     and p ->> 'kind' = 'mc'
     and not exists (
       select 1 from jsonb_array_elements(p -> 'options') o
        where o ->> 'id' = ke.wert);
  if v_n <> 0 then
    raise exception 'F8: % known_errors-Schluessel in mc-Teilen sind keine Option-ID', v_n;
  end if;

  -- Die richtige Option darf nirgends als Fehlbild gelistet sein.
  select count(*) into v_n
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id,
         jsonb_array_elements(t.parts) e(p)
   where t.source = 'edvance_p5_modellieren'
     and p ->> 'kind' = 'mc'
     and s.acceptance -> (p ->> 'nr') -> 'known_errors'
         ? (s.correct_answers -> (p ->> 'nr') ->> 0);
  if v_n <> 0 then
    raise exception 'F8: bei % Aufgaben steht die richtige Option in known_errors', v_n;
  end if;
  raise notice 'F8 ok: MC-Fehlbilder haengen an der Option-ID, richtige Option nicht dabei';

  -- ══ Fall 9: alle known_errors zeigen auf Labels MIT Familie ═══════════════
  --
  -- Ohne Familie faellt der Befund im Elternreport still weg (AF5) — er
  -- erscheint dann nur in der Coach-Sicht. Fuer ein neu gebautes Item ist das
  -- kein akzeptabler Zustand, deshalb blockierend geprueft.

  select string_agg(distinct ke.slug, ', ' order by ke.slug) into v_txt
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id,
         jsonb_each(s.acceptance) teil(nr, regel),
         jsonb_each_text(teil.regel -> 'known_errors') ke(wert, slug)
   where t.source = 'edvance_p5_modellieren'
     and not exists (select 1 from public.fehlbild_labels l
                      where l.slug = ke.slug and l.familie is not null);
  if v_txt is not null then
    raise exception 'F9: known_errors ohne Label oder ohne Familie: %', v_txt;
  end if;
  raise notice 'F9 ok: alle known_errors zeigen auf Labels mit Familie';

  -- ══ Fall 10: Teil 2 verraet die Gleichung nicht ═══════════════════════════
  --
  -- Der diagnostische Wert haengt daran, dass Teil b ohne Teil a beantwortbar
  -- ist. Steht die Gleichung im Prompt, misst Teil b nur noch Einsetzen.

  select count(*) into v_n
    from public.tasks t, jsonb_array_elements(t.parts) e(p)
   where t.source = 'edvance_p5_modellieren'
     and p ->> 'nr' = '2'
     and (p ->> 'prompt') ~ '[0-9]\s*x|=';
  if v_n <> 0 then
    raise exception 'F10: bei % Aufgaben enthaelt der Prompt von Teil 2 eine Gleichung', v_n;
  end if;
  raise notice 'F10 ok: kein Teil 2 setzt die Gleichung aus Teil 1 voraus';

  -- ══ Fall 11: sondierrang nur an Item 2 ════════════════════════════════════

  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref <> 'handytarif-01'
     and sondierrang is not null;
  if v_n <> 1 then
    raise exception 'F11: % Aufgaben aus Items 2-10 mit sondierrang, erwartet 1', v_n;
  end if;
  select sondierrang into v_n from public.tasks where source_ref = 'trikot-02';
  if v_n is distinct from 2 then
    raise exception 'F11: trikot-02 hat sondierrang %, erwartet 2', coalesce(v_n::text, '<null>');
  end if;
  raise notice 'F11 ok: sondierrang 2 nur an Item 2, uebrige NULL';

  -- ══ Fall 12: Optionen wohlgeformt ═════════════════════════════════════════

  select count(*) into v_n
    from public.tasks t, jsonb_array_elements(t.parts) e(p)
   where t.source = 'edvance_p5_modellieren'
     and p ->> 'kind' = 'mc'
     and (jsonb_array_length(p -> 'options') <> 4
          or exists (select 1 from jsonb_array_elements(p -> 'options') o
                      where coalesce(o ->> 'id', '') = '' or coalesce(o ->> 'label', '') = ''));
  if v_n <> 0 then
    raise exception 'F12: % mc-Teile ohne vier vollstaendige Optionen', v_n;
  end if;
  raise notice 'F12 ok: jeder mc-Teil hat vier Optionen mit id und label';

  -- ══ Negativkontrolle des Harnischs selbst ═════════════════════════════════

  v_ctrl := false;
  begin
    if (select count(*) from public.tasks where source = 'edvance_p5_modellieren') <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'P5 Items 2-10: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
