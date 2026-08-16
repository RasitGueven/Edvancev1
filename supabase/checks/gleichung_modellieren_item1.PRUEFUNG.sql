-- PRUEFUNG zu P5 (gleichung_modellieren, Item 1 Handytarif).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/gleichung_modellieren_item1.PRUEFUNG.sql
--
-- Diese Datei prueft INHALT, nicht Mechanik: dass das Item mit beiden Teilen
-- steht, dass jeder known_errors-Wert auf ein existierendes Label zeigt und
-- dass die neun neuen Slugs eine Familie tragen.
--
-- Sie ist deshalb wichtig, weil Item 1 fuer ZWEI Dinge das erste seiner Art
-- ist: die erste MULTI_PART-Aufgabe mit acceptance (bisher 0 von 150) und die
-- erste MC-Zuordnung von known_errors ueberhaupt. Beide Pfade sind ueber die
-- Funktionsdefinitionen belegt, aber nie im Betrieb gelaufen. Was hier gruen
-- ist, ist wenigstens strukturell gedeckt.
--
-- Laeuft gegen eine bereits migrierte Datenbank und faengt sich SELBST in
-- begin/rollback. Sie legt keine Testdaten an — geprueft wird der Bestand, den
-- die Migration erzeugt hat.

begin;

do $$
declare
  v_task  uuid;
  v_parts jsonb;
  v_acc   jsonb;
  v_ca    jsonb;
  v_n     integer;
  v_txt   text;
  v_ctrl  boolean;
begin
  -- ══ Fall 1: Skill und Kante ═══════════════════════════════════════════════

  select fundament_tiefe into v_n from public.skills
   where skill_key = 'gleichung_modellieren';
  if v_n is null then
    raise exception 'F1: der Skill gleichung_modellieren fehlt';
  end if;
  if v_n <> 8 then
    raise exception 'F1: fundament_tiefe ist %, erwartet 8', v_n;
  end if;
  -- DREI Voraussetzungen. term_ausmultiplizieren ist die, die man vergisst:
  -- Item 7 (Rechteck, Umfang) und Item 10 (Klammer) aus dem Folge-PR setzen es
  -- voraus, und ohne die Kante steigt die LSA beim Scheitern nicht dorthin ab.
  select count(*) into v_n from public.skill_kante
   where skill_key = 'gleichung_modellieren'
     and voraussetzt_skill_key in ('gleichung_zweischrittig',
                                   'gleichung_beidseitig',
                                   'term_ausmultiplizieren');
  if v_n <> 3 then
    raise exception 'F1: nur % von 3 Voraussetzungskanten stehen — fehlt eine, '
                    'bricht die LSA den Ast beim Scheitern ab, statt abzusteigen', v_n;
  end if;

  -- Jede Voraussetzung muss ECHT flacher liegen (skill_kante_tiefe_guard). Das
  -- prueft der Trigger beim Schreiben; hier steht es als Zusicherung ueber den
  -- BESTAND, falls jemand spaeter eine Tiefe verschiebt.
  select count(*) into v_n
    from public.skill_kante k
    join public.skills v on v.skill_key = k.voraussetzt_skill_key
    join public.skills s on s.skill_key = k.skill_key
   where k.skill_key = 'gleichung_modellieren'
     and v.fundament_tiefe >= s.fundament_tiefe;
  if v_n <> 0 then
    raise exception 'F1: % Voraussetzung(en) liegen nicht mehr unter gleichung_modellieren', v_n;
  end if;
  raise notice 'F1 ok: Skill (Tiefe 8) und alle drei Voraussetzungskanten stehen';

  -- ══ Fall 2: das Item existiert mit beiden Teilen ══════════════════════════

  select t.id, t.parts into v_task, v_parts
    from public.tasks t
   where t.source = 'edvance_p5_modellieren' and t.source_ref = 'handytarif-01';
  if v_task is null then
    raise exception 'F2: Item 1 (Handytarif) fehlt';
  end if;

  if jsonb_array_length(v_parts) <> 2 then
    raise exception 'F2: % Teile, erwartet 2', jsonb_array_length(v_parts);
  end if;
  if not public.lsa_parts_valid(v_parts) then
    raise exception 'F2: parts sind nicht wohlgeformt (lsa_parts_valid)';
  end if;

  select p ->> 'kind' into v_txt from jsonb_array_elements(v_parts) e(p)
   where (p ->> 'nr') = '1';
  if v_txt is distinct from 'mc' then
    raise exception 'F2: Teil 1 ist kind=%, erwartet mc', coalesce(v_txt, '<fehlt>');
  end if;
  select p ->> 'kind' into v_txt from jsonb_array_elements(v_parts) e(p)
   where (p ->> 'nr') = '2';
  if v_txt is distinct from 'short_input' then
    raise exception 'F2: Teil 2 ist kind=%, erwartet short_input', coalesce(v_txt, '<fehlt>');
  end if;
  raise notice 'F2 ok: Item steht, Teil 1 mc + Teil 2 short_input';

  -- ══ Fall 3: Stammdaten, die das Freigabe-Gate verlangt ════════════════════
  --
  -- status bleibt bewusst 'draft' — die Freigabe macht Rasit. Geprueft wird,
  -- dass sie NICHT an einem fehlenden Pflichtfeld scheitern wuerde. Die Liste
  -- ist die aus task_status_set.

  -- Jedes Feld EINZELN, nicht als Sammelbedingung. Die erste Fassung meldete
  -- "ein Pflichtfeld fehlt (question/input_type/afb/curriculum_grade/
  -- est_duration_sec)" — sie schlug korrekt an, als afb am Item fehlte, sagte
  -- aber nicht WELCHES der fuenf. Bei neun Folge-Items ist das der Unterschied
  -- zwischen "sofort klar" und "fuenf Felder durchsehen".
  select string_agg(fehlt, ', ' order by fehlt) into v_txt
    from public.tasks t
    cross join lateral (values
      ('question',         coalesce(btrim(t.question), '') = ''),
      ('input_type',       t.input_type is null),
      ('afb',              t.afb is null),
      ('curriculum_grade', t.curriculum_grade is null),
      ('est_duration_sec', t.est_duration_sec is null)
    ) as p(fehlt, ist_leer)
   where t.id = v_task and p.ist_leer;
  if v_txt is not null then
    raise exception 'F3: Pflichtfeld(er) fuer die Freigabe fehlen: % — '
                    'task_status_set wuerde mit P0001 abbrechen', v_txt;
  end if;

  -- afb zusaetzlich auf den WERTEBEREICH: der CHECK auf tasks laesst nur
  -- I/II/III zu, aber eine spaetere Bestueckung koennte 'AFB II' oder '2'
  -- schreiben und liefe in den Constraint statt in eine lesbare Meldung.
  select afb into v_txt from public.tasks where id = v_task;
  if v_txt not in ('I', 'II', 'III') then
    raise exception 'F3: afb ist "%", erwartet eine roemische Ziffer I/II/III', v_txt;
  end if;
  -- cluster_id ist bewusst NICHT als "muss gesetzt sein" geprueft.
  --
  -- Die erste Fassung tat das bedingt ("wenn es den Cluster gibt, muss er am
  -- Item stehen") und war in CI rot. Der Grund ist die Reihenfolge im Workflow:
  --   1. test-grundlage.sql   — keine Cluster
  --   2. Migrationen          — P5 laeuft, die Unterabfrage findet nichts -> null
  --   3. seed.sql             — legt "Algebra & Funktionen" JETZT ERST an
  --   4. Pruefskripte         — Cluster da, cluster_id am Item null -> Abbruch
  -- Auf Produktion existiert der Cluster laengst, dort greift die Unterabfrage.
  -- Ein null-cluster_id im Neuaufbau ist also ein Artefakt der Seed-Reihenfolge
  -- und kein Befund. Die Zusicherung, die wirklich zaehlt, steht deshalb IN der
  -- Migration (Kontrollzaehlung, Teil 5) — dort ist der Zeitpunkt bekannt.
  --
  -- Was hier bleibt, ist reihenfolgeunabhaengig und faengt trotzdem den Fall,
  -- der wehtut: ein Item, das am FALSCHEN Cluster haengt.
  if exists (
    select 1 from public.tasks t
     left join public.skill_clusters c on c.id = t.cluster_id
     where t.id = v_task
       and t.cluster_id is not null
       and c.name is distinct from 'Algebra & Funktionen'
  ) then
    raise exception 'F3: das Item haengt an einem anderen Cluster als "Algebra & Funktionen"';
  end if;
  raise notice 'F3 ok: Pflichtfelder gesetzt, Cluster stimmig (oder im Neuaufbau leer)';

  -- ══ Fall 3b: competency_content AM ITEM ══════════════════════════════════
  --
  -- KEIN Feld des Freigabe-Gates — task_status_set prueft es nicht, das Item
  -- geht auch ohne auf 'ready'. Der Eltern-Report baut daraus aber die
  -- Themengliederung: fehlt der Wert, erscheint die Aufgabe dort unter "ohne
  -- Zuordnung". Genau so ist es passiert (Nachtrag 20260816100000), deshalb
  -- steht es jetzt als eigener Fall hier.
  --
  -- Geprueft wird zusaetzlich die Uebereinstimmung mit den Teilaufgaben: zwei
  -- verschiedene Kompetenzbereiche an einer Aufgabe waeren ein Widerspruch,
  -- den niemand bemerkt, weil beide Stellen fuer sich plausibel aussehen.
  select competency_content into v_txt from public.tasks where id = v_task;
  if coalesce(btrim(v_txt), '') = '' then
    raise exception 'F3b: competency_content am Item fehlt — der Elternreport '
                    'fuehrt die Aufgabe dann unter "ohne Zuordnung"';
  end if;
  -- Nur wo eine Teilaufgabe einen Bereich fuehrt: Item 1 hat in beiden Teilen
  -- keinen (Altbestand aus dem Item-1-PR, dort als offener Punkt benannt).
  -- Geprueft wird der Widerspruch, nicht die Luecke.
  if exists (
    select 1 from jsonb_array_elements(v_parts) e(p)
     where coalesce(btrim(p ->> 'competency_content'), '') <> ''
       and p ->> 'competency_content' is distinct from v_txt
  ) then
    raise exception 'F3b: Item fuehrt "%", eine Teilaufgabe etwas anderes', v_txt;
  end if;
  raise notice 'F3b ok: competency_content am Item gesetzt, kein Widerspruch zu den Teilen';

  -- ══ Fall 4: Loesung je Teil, in der Form die das Gate verlangt ════════════

  select ts.correct_answers, ts.acceptance into v_ca, v_acc
    from public.task_solutions ts where ts.task_id = v_task;
  if v_ca is null then
    raise exception 'F4: keine Loesungszeile zum Item';
  end if;
  if not public.lsa_has_answers('MULTI_PART', v_parts, v_ca) then
    raise exception 'F4: correct_answers erfuellt lsa_has_answers nicht — die '
                    'Freigabe wuerde mit "Loesung unvollstaendig" scheitern';
  end if;
  if v_ca -> '1' ->> 0 is distinct from 'a' then
    raise exception 'F4: Teil 1 erwartet die Option-ID "a", steht auf %',
      coalesce(v_ca -> '1' ->> 0, '<null>');
  end if;
  if v_ca -> '2' ->> 0 is distinct from '7' then
    raise exception 'F4: Teil 2 erwartet "7", steht auf %',
      coalesce(v_ca -> '2' ->> 0, '<null>');
  end if;
  raise notice 'F4 ok: Loesung je Teil vorhanden und in der Form des Gates';

  -- ══ Fall 5: acceptance liegt VERSCHACHTELT vor ════════════════════════════
  --
  -- Der Kern des Items. Der AF1-Trigger liest
  --   acceptance -> part_nr::text -> 'known_errors'
  -- und faellt nur ersatzweise auf die flache Form zurueck. Laege acceptance
  -- flach, wuerde Teil 1 gegen die Fehlbilder von Teil 2 gematcht.

  if v_acc is null then
    raise exception 'F5: das Item traegt kein acceptance';
  end if;
  if v_acc ? 'canonical' then
    raise exception 'F5: acceptance liegt FLACH vor — bei MULTI_PART muss es je '
                    'Teilnummer verschachtelt sein';
  end if;
  if not public.lsa_acceptance_valid(v_acc) then
    raise exception 'F5: acceptance ist nicht gueltig (lsa_acceptance_valid)';
  end if;
  if v_acc -> '1' -> 'known_errors' is null or v_acc -> '2' -> 'known_errors' is null then
    raise exception 'F5: known_errors fehlen fuer Teil 1 oder Teil 2';
  end if;
  raise notice 'F5 ok: acceptance verschachtelt je Teilnummer, beide mit known_errors';

  -- ══ Fall 6: die MC-Schluessel sind Option-IDs, keine Optionstexte ═════════
  --
  -- lsa_fehlbild_match vergleicht bei mc gegen response->'selected'->>0, also
  -- gegen die ID. Stuende hier der Optionstext, matchte nie etwas — still, ohne
  -- Fehlermeldung.

  select count(*) into v_n
    from jsonb_each_text(v_acc -> '1' -> 'known_errors') ke(wert, slug)
   where not exists (
     select 1 from jsonb_array_elements(v_parts) e(p),
                   jsonb_array_elements(p -> 'options') o
      where (p ->> 'nr') = '1' and o ->> 'id' = ke.wert
   );
  if v_n <> 0 then
    raise exception 'F6: % known_errors-Schluessel in Teil 1 sind keine Option-ID', v_n;
  end if;
  -- Und die richtige Option darf NICHT als Fehlbild gelistet sein.
  if v_acc -> '1' -> 'known_errors' ? (v_ca -> '1' ->> 0) then
    raise exception 'F6: die richtige Option steht in known_errors';
  end if;
  -- Alle drei Distraktoren sind abgedeckt (4 Optionen, 1 richtig).
  select count(*) into v_n from jsonb_each(v_acc -> '1' -> 'known_errors');
  if v_n <> 3 then
    raise exception 'F6: % gelabelte Distraktoren, erwartet 3', v_n;
  end if;
  raise notice 'F6 ok: alle drei Distraktoren ueber ihre Option-ID gelabelt';

  -- ══ Fall 7: jeder known_errors-Wert zeigt auf ein existierendes Label ═════

  select count(*) into v_n
    from jsonb_each(v_acc) teil(nr, regel),
         jsonb_each_text(teil.regel -> 'known_errors') ke(wert, slug)
   where not exists (select 1 from public.fehlbild_labels l where l.slug = ke.slug);
  if v_n <> 0 then
    raise exception 'F7: % known_errors zeigen auf einen unbekannten Slug', v_n;
  end if;
  raise notice 'F7 ok: alle known_errors des Items zeigen auf existierende Labels';

  -- ══ Fall 8: die neun neuen Slugs haben eine Familie ══════════════════════

  select count(*) into v_n from public.fehlbild_labels
   where slug in ('bedingung_unvollstaendig','differenz_ignoriert',
                  'falsche_groesse_beantwortet','text_direkt_gerechnet',
                  'groessen_vertauscht','umfang_falsch_modelliert',
                  'anteil_falsch_verteilt','klammer_vergessen',
                  'klammer_falsch_gesetzt');
  if v_n <> 9 then
    raise exception 'F8: % der 9 neuen Slugs stehen in der Registry', v_n;
  end if;

  select count(*) into v_n from public.fehlbild_labels
   where slug in ('bedingung_unvollstaendig','differenz_ignoriert',
                  'falsche_groesse_beantwortet','text_direkt_gerechnet',
                  'groessen_vertauscht','umfang_falsch_modelliert',
                  'anteil_falsch_verteilt','klammer_vergessen',
                  'klammer_falsch_gesetzt')
     and familie is not null;
  if v_n <> 9 then
    raise exception 'F8: nur % der 9 neuen Slugs haben eine Familie — die ohne '
                    'fallen im Elternreport still weg (AF5)', v_n;
  end if;

  -- Und die Familien existieren wirklich (der FK deckt das ab, die Probe
  -- benennt es).
  if exists (
    select 1 from public.fehlbild_labels l
     where l.slug in ('klammer_vergessen','klammer_falsch_gesetzt')
       and l.familie <> 'gleichungen_umformen'
  ) then
    raise exception 'F8: die zwei Klammer-Fehlbilder gehoeren nach gleichungen_umformen';
  end if;
  raise notice 'F8 ok: alle neun neuen Slugs stehen mit Familie in der Registry';

  -- ══ Fall 9: Teil 2 verraet die Gleichung nicht ═══════════════════════════
  --
  -- Der diagnostische Wert des zweiteiligen Aufbaus haengt daran, dass Teil b
  -- ohne Teil a beantwortbar ist. Steht die Gleichung im Prompt, misst Teil b
  -- nur noch Einsetzen.

  select p ->> 'prompt' into v_txt from jsonb_array_elements(v_parts) e(p)
   where (p ->> 'nr') = '2';
  if v_txt ~ '[0-9]\s*x|=' then
    raise exception 'F9: der Prompt von Teil 2 enthaelt eine Gleichung: %', v_txt;
  end if;
  raise notice 'F9 ok: Teil 2 setzt die Gleichung aus Teil 1 nicht voraus';

  -- ══ Negativkontrolle des Harnischs selbst ═════════════════════════════════

  v_ctrl := false;
  begin
    if (select count(*) from public.tasks where id = v_task) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'P5: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
