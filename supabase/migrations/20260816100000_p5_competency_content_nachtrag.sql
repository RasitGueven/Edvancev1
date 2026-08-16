-- P5 Nachtrag — tasks.competency_content an den zehn Modellier-Items setzen.
--
-- BEFUND
--   Die zehn Aufgaben am Skill gleichung_modellieren
--   (source = 'edvance_p5_modellieren') tragen competency_content = null AM
--   ITEM. Nur die Teilaufgaben in parts[] tragen 'arithmetik_algebra' — das
--   verlangte das Autorentool ueber den blockierenden Flag
--   partCompetencyMissing, die Spalte am Item blieb leer.
--
--   Dasselbe Muster wie zuvor beim AFB (20260814160000): ein Feld, das die
--   Teilaufgabe fuehrt und das Item auch braucht, nur ohne Gate, das es
--   gemeldet haette. task_status_set prueft competency_content NICHT — die
--   zehn Items sind deshalb sauber auf 'ready' gegangen.
--
--   Belegt gegen Produktion (2026-08-16):
--     ready-Aufgaben ohne competency_content            10
--     davon ausserhalb von edvance_p5_modellieren        0
--     P5-Items gesamt / davon ohne competency_content   10 / 10
--   Es sind also GENAU diese zehn und keine weiteren.
--
-- FOLGE
--   Der Eltern-Report baut die Themengliederung aus tasks.competency_content.
--   Die einzigen Klasse-8-Aufgaben im Bestand erscheinen dort als "ohne
--   Zuordnung" — ausgerechnet die Items, die das Leitthema tragen sollen. In
--   der simulierten Sitzung waren das 4 Antworten aus 2 Aufgaben.
--
-- ZUM WERT
--   'arithmetik_algebra', formatgleich zum Bestand. Nachgesehen, nicht geraten:
--     select competency_content, count(*) from tasks where … is not null
--       -> arithmetik_algebra 291, geometrie 113, funktionen 42, stochastik 28
--   Und die Teilaufgaben derselben zehn Items fuehren bereits genau diesen
--   Wert — die Migration hebt ihn nur eine Ebene hoch, sie erfindet ihn nicht.
--
-- begin/commit steht IN der Datei: scripts/db-migrate.sh ruft psql ohne
-- --single-transaction. Ein einzelnes update waere fuer sich atomar, die
-- Kontrolle unten soll aber mit ihm zusammen fallen koennen. Beim Apply
-- deshalb KEIN --single-transaction.

begin;

update public.tasks
   set competency_content = 'arithmetik_algebra'
 where source = 'edvance_p5_modellieren'
   and competency_content is null;


-- ── Kontrolle ───────────────────────────────────────────────────────────────
--
-- Ein update, das keine Zeile trifft, ist still. Auf einer Datenbank ohne die
-- Items (etwa dem leeren Schnappschuss vor der P5-Migration) waere das richtig;
-- stehen sie da, muss danach an jeder ein Wert haengen.

do $$
declare
  v_gesamt integer;
  v_ohne   integer;
begin
  select count(*), count(*) filter (where competency_content is null)
    into v_gesamt, v_ohne
    from public.tasks where source = 'edvance_p5_modellieren';

  if v_gesamt = 0 then
    raise notice 'P5-Nachtrag: keine Items der Quelle vorhanden — nichts zu tun';
    return;
  end if;

  if v_ohne <> 0 then
    raise exception 'P5-Nachtrag: % von % Items ohne competency_content', v_ohne, v_gesamt;
  end if;

  -- Und wo eine Teilaufgabe einen Bereich fuehrt, muss er derselbe sein.
  --
  -- Nur wo sie einen fuehrt: Item 1 (handytarif-01) hat in BEIDEN Teilaufgaben
  -- kein competency_content — ein Altbestand aus dem Item-1-PR, dort als
  -- offener Punkt benannt. Ihn hier mitzureparieren waere ein zweiter Eingriff
  -- in einer Migration, die eine Spalte am Item nachtraegt. Die Pruefung deckt
  -- deshalb den Widerspruch ab (zwei verschiedene Bereiche), nicht die Luecke.
  if exists (
    select 1 from public.tasks t, jsonb_array_elements(t.parts) e(p)
     where t.source = 'edvance_p5_modellieren'
       and coalesce(btrim(p ->> 'competency_content'), '') <> ''
       and p ->> 'competency_content' is distinct from t.competency_content
  ) then
    raise exception 'P5-Nachtrag: Item und Teilaufgabe fuehren verschiedene '
                    'Kompetenzbereiche';
  end if;

  raise notice 'P5-Nachtrag: competency_content an % Items gesetzt', v_gesamt;
end $$;

commit;
