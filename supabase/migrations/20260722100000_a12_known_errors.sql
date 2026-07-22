-- ============================================================================
-- A12: `known_errors` im Akzeptanz-Set — die bekannten Fehlbilder einer Aufgabe
--
-- SETZT A10 + A11 VORAUS. Ersetzt lsa_acceptance_rule_valid ein zweites Mal.
--
-- ----------------------------------------------------------------------------
-- BEFUND: DER CHECK WEIST known_errors GAR NICHT AB
-- ----------------------------------------------------------------------------
--   Der Auftrag ging davon aus, dass der acceptance-CHECK ein neues Feld
--   blockiert — so wie es bei `require_reduced` beinahe passiert waere. Das
--   stimmt fuer diese Ebene NICHT, und der Unterschied ist wichtig genug, um
--   ihn hier festzuhalten:
--
--     lsa_acceptance_rule_valid prueft die BEKANNTEN Schluessel einzeln
--     (canonical Pflicht, equivalents als String-Array, notation gegen vier
--     erlaubte Flags, tolerance, unit, unit_graded, require_reduced) — aber es
--     gibt KEINE Pruefung, die unbekannte TOP-LEVEL-Schluessel verbietet. Kein
--     jsonb_object_keys, kein jsonb_each ueber p_rule selbst.
--
--   Ein acceptance mit `known_errors` waere also schon vor dieser Migration
--   durchgegangen — mit beliebigem Inhalt, auch als Zahl oder als Zeichenkette.
--   Whitelistet wird ausschliesslich INNERHALB von `notation`; genau daran
--   waere `notation.require_reduced` gescheitert, und genau deshalb liegt
--   `require_reduced` oben. Dieselbe Ueberlegung gilt hier: `known_errors`
--   gehoert nach oben, neben die anderen Regel-Felder.
--
--   WAS ALSO FEHLT ist nicht die Erlaubnis, sondern die ZUSAGE: dass das Feld
--   gemeint ist, dass es einen Typ hat und dass jemand es findet. Ein Feld, das
--   nur geduldet wird, ist kein Vertrag — es ist ein Zufall, der beim naechsten
--   Validator-Umbau verschwindet.
--
-- ----------------------------------------------------------------------------
-- WAS known_errors IST
-- ----------------------------------------------------------------------------
--   Die bekannten FEHLBILDER einer Aufgabe: welcher Wert entsteht, wenn ein
--   Kind einen bestimmten Denkfehler macht. Der Brueche-Seed (Charge 01)
--   rechnet sie bereits aus — additiv gekuerzt (18/24 → 17/23),
--   Zaehler+Zaehler/Nenner+Nenner (1/4+2/3 → 3/7), ueber Kreuz, nicht
--   gestuerzt, falsch gestuerzt — und legt sie heute NUR im Bericht ab
--   (data/brueche_fundament_01_report.json). In der Datenbank landen sie
--   nirgends, weil es kein Feld gab.
--
--   Damit kann der Eltern-/Coach-Report bis heute nur „falsch" sagen. Mit
--   known_errors kann er sagen, WELCHER Fehler es war — und das ist der
--   Unterschied zwischen einer Note und einer Diagnose.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 1: die innere Struktur wird NICHT erzwungen
-- ----------------------------------------------------------------------------
--   Erlaubt sind Objekt UND Array:
--     {"17/23": "additiv", "3/7": "zaehler_plus_nenner"}   ← Wert → Fehlertyp
--     ["17/23", "3/7"]                                      ← nur die Werte
--
--   Warum nicht enger: Wie ein Fehlbild benannt wird, ist eine didaktische
--   Frage, die noch nicht entschieden ist — freie Labels, ein Vokabular, oder
--   Verweise auf eine spaetere Fehlbild-Tabelle. Ein CHECK, der heute eine
--   Form festschreibt, waere eine Entscheidung, die niemand getroffen hat, und
--   sie stuende in der Datenbank statt im Gespraech. Geprueft wird deshalb nur,
--   dass es eines von beiden IST — nicht was drinsteht.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 2: unbekannte Schluessel bleiben geduldet
-- ----------------------------------------------------------------------------
--   Der Validator koennte bei dieser Gelegenheit unbekannte Top-Level-Keys
--   verbieten. Er tut es NICHT, und das ist Absicht:
--     * Es waere eine VERSCHAERFUNG an Bestandsdaten vorbei. Welche acceptance-
--       Objekte in der Produktionsdatenbank stehen, ist von hier aus nicht
--       einsehbar (diese Migration wird geschrieben, nicht eingespielt). Ein
--       CHECK, der beim Einspielen an einer Altzeile scheitert, nimmt den
--       ganzen Lauf mit.
--     * Es ist eine eigene Entscheidung mit eigenem Risiko und gehoert nicht
--       als Beifang in eine Migration, die ein Feld dokumentieren soll.
--   Folge mit Ansage: ein Tippfehler wie `know_errors` faellt weiterhin NICHT
--   auf. Siehe NACHLAUF.
--
-- ----------------------------------------------------------------------------
-- KEIN LEAK, KEINE BEWERTUNGSAENDERUNG
-- ----------------------------------------------------------------------------
--   known_errors erbt den Schutz von task_solutions, ohne dass hier etwas
--   getan werden muss: `revoke all on table task_solutions from anon,
--   authenticated` (P01 §2), Zugriff nur ueber die SECURITY-DEFINER-RPCs.
--   Verifiziert, nicht angenommen.
--
--   lsa_grade liest ausschliesslich benannte Schluessel (canonical,
--   equivalents, notation, tolerance, unit, unit_graded, require_reduced) und
--   ignoriert alles andere; lsa_is_correct liest acceptance ueberhaupt nicht.
--   Beide bleiben BYTE-IDENTISCH. known_errors ist reine Speicherung —
--   deklarativ, wie acceptance es bei A10 auch war.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Der Validator kennt known_errors
--
--    Ein einziger neuer Zweig. Additiv fuer alles, was das Feld nicht traegt
--    (`is null` → true), und eine Typzusage fuer alles, was es traegt.
-- ============================================================================

create or replace function public.lsa_acceptance_rule_valid(p_rule jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_rule) = 'object'
     and jsonb_typeof(p_rule -> 'canonical') = 'string'
     and btrim(p_rule ->> 'canonical') <> ''
     and (p_rule -> 'equivalents' is null
          or (jsonb_typeof(p_rule -> 'equivalents') = 'array'
              and not exists (
                select 1 from jsonb_array_elements(p_rule -> 'equivalents') as e(v)
                 where jsonb_typeof(v) <> 'string' or btrim(v #>> '{}') = ''
              )))
     and (p_rule -> 'notation' is null
          or (jsonb_typeof(p_rule -> 'notation') = 'object'
              and not exists (
                select 1 from jsonb_each(p_rule -> 'notation') as e(k, v)
                 where k not in ('decimal_comma', 'unit_optional',
                                 'ignore_case', 'ignore_space')
                    or jsonb_typeof(v) <> 'boolean'
              )))
     and (p_rule -> 'tolerance' is null
          or (jsonb_typeof(p_rule -> 'tolerance') = 'object'
              and (p_rule #>> '{tolerance,mode}') in ('exact', 'absolute', 'decimals')
              and case p_rule #>> '{tolerance,mode}'
                    when 'exact' then p_rule -> 'tolerance' -> 'value' is null
                    when 'absolute' then
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}')::numeric > 0
                    else
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}') ~ '^[0-6]$'
                  end))
     and (p_rule -> 'unit' is null or jsonb_typeof(p_rule -> 'unit') = 'string')
     and (p_rule -> 'unit_graded' is null
          or jsonb_typeof(p_rule -> 'unit_graded') = 'boolean')
     and (p_rule -> 'require_reduced' is null
          or jsonb_typeof(p_rule -> 'require_reduced') = 'boolean')
     -- NEU (A12): die bekannten Fehlbilder. Objekt (Wert → Fehlertyp) ODER
     -- Array (nur die Werte) — die Wahl der Form ist noch nicht getroffen und
     -- wird hier bewusst nicht erzwungen. Fehlt das Feld, ist alles wie vorher.
     and (p_rule -> 'known_errors' is null
          or jsonb_typeof(p_rule -> 'known_errors') in ('object', 'array'))
     and not (coalesce((p_rule ->> 'unit_graded')::boolean, false)
              and coalesce((p_rule #>> '{notation,unit_optional}')::boolean, false))
$$;

comment on function public.lsa_acceptance_rule_valid(jsonb) is
  'Strukturvertrag EINER Akzeptanzregel: canonical (Pflicht), equivalents[], '
  'notation-Flags (decimal_comma|unit_optional|ignore_case|ignore_space), '
  'tolerance (exact|absolute+value|decimals+0..6), unit, unit_graded, '
  'require_reduced (A11), known_errors (A12, Objekt oder Array). Verbietet '
  'unit_graded=true zusammen mit notation.unit_optional=true. Unbekannte '
  'TOP-LEVEL-Schluessel werden bewusst NICHT abgewiesen — nur innerhalb von '
  'notation gilt eine Whitelist.';

-- ============================================================================
-- 2. Der Spalten-Kommentar nennt das Feld
-- ============================================================================

comment on column task_solutions.acceptance is
  'AKZEPTANZ-SET (Loesungsdatum!). Warum eine Antwort zaehlt, maschinenlesbar: '
  '{canonical, equivalents[], notation{decimal_comma,unit_optional,ignore_case,'
  'ignore_space}, tolerance{mode:exact|absolute|decimals,value}, unit, '
  'unit_graded, require_reduced, known_errors}. Flach eine Regel, bei '
  'MULTI_PART {"<nr>": Regel} — dieselbe Doppelform wie correct_answers. '
  'NULL = nicht gepflegt. Relevant fuer Zahleneingabe/Freitext; reine MC '
  'braucht es nicht. unit_graded=true heisst: die geforderte Einheit ist Teil '
  'der Kompetenz, eine andere Einheit zaehlt NICHT. require_reduced=true: ein '
  'ungekuerzter Bruch ist nur ''teilweise'' (A11). '
  'known_errors (optional, A12): bekannte Fehlbild-Werte dieser Aufgabe, zur '
  'Report-Feindiagnostik. Objekt wert->fehlertyp-label ODER Array von Werten. '
  'REIN DEKLARATIV — aendert die Bewertung (lsa_grade) NICHT. Server-only '
  '(liegt in task_solutions, kein anon/auth-Grant).';

-- ============================================================================
-- 3. Proben
--
--    Geprueft wird die FUNKTION, nicht eine eingefuegte Zeile: der CHECK auf
--    task_solutions ist `acceptance is null or lsa_acceptance_valid(acceptance)`
--    — wer die Funktion prueft, prueft den CHECK, ohne Daten anzufassen.
--
--    Weicht eine Probe ab, bricht die Transaktion ab und der Validator bleibt,
--    wie er war.
-- ============================================================================

do $$
declare
  v_fehler int := 0;

  -- (a) Bestand: die Form der 28 Brueche-Aufgaben, ohne known_errors.
  v_ohne  jsonb := '{"canonical":"3/4","require_reduced":true}'::jsonb;
  -- (b) known_errors als Objekt: Wert → Fehlertyp.
  v_obj   jsonb := '{"canonical":"3/4","require_reduced":true,
                     "known_errors":{"17/23":"additiv","6/8":"teilgekuerzt"}}'::jsonb;
  -- (c) known_errors als Array: nur die Werte.
  v_arr   jsonb := '{"canonical":"11/12","known_errors":["3/7","22/24"]}'::jsonb;
  -- (d) known_errors mit falschem TYP — das muss fallen.
  v_kaputt jsonb := '{"canonical":"3/4","known_errors":"additiv"}'::jsonb;
  -- (e) Multi-Part-Form: die Doppelform muss weiter tragen.
  v_multi jsonb := '{"1":{"canonical":"3/4","known_errors":["17/23"]},
                     "2":{"canonical":"1/2"}}'::jsonb;
begin
  if not public.lsa_acceptance_valid(v_ohne) then
    raise warning 'Probe (a): acceptance OHNE known_errors wird abgewiesen';
    v_fehler := v_fehler + 1;
  end if;

  if not public.lsa_acceptance_valid(v_obj) then
    raise warning 'Probe (b): known_errors als Objekt wird abgewiesen';
    v_fehler := v_fehler + 1;
  end if;

  if not public.lsa_acceptance_valid(v_arr) then
    raise warning 'Probe (c): known_errors als Array wird abgewiesen';
    v_fehler := v_fehler + 1;
  end if;

  if public.lsa_acceptance_valid(v_kaputt) then
    raise warning 'Probe (d): known_errors als Zeichenkette geht durch, der Typvertrag greift nicht';
    v_fehler := v_fehler + 1;
  end if;

  if not public.lsa_acceptance_valid(v_multi) then
    raise warning 'Probe (e): Multi-Part-Form mit known_errors wird abgewiesen';
    v_fehler := v_fehler + 1;
  end if;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — Validator nicht geaendert.', v_fehler;
  end if;

  raise notice 'A12: alle Proben bestanden.';
end $$;

commit;

-- ============================================================================
-- NACHLAUF (bewusst NICHT hier):
--
--   1. Der Brueche-Seed (Charge 01) rechnet die Fehlbilder bereits aus und legt
--      sie nur im Bericht ab. Ein Folgelauf kann sie in acceptance.known_errors
--      schreiben — der Generator hat die Werte, es fehlte nur das Feld.
--   2. Report-Feindiagnostik: lsa_responses.response traegt die gegebene
--      Antwort wortwoertlich. Ein Auswertungsschritt kann sie gegen
--      known_errors halten und im Eltern-/Coach-Report den FEHLERTYP benennen
--      statt nur „falsch". Das ist der eigentliche Zweck des Feldes.
--   3. Unbekannte Top-Level-Schluessel abweisen (siehe Kopf, Entscheidung 2).
--      Ein Tippfehler wie `know_errors` faellt heute nicht auf. Das ist eine
--      Verschaerfung an Bestandsdaten vorbei und braucht einen eigenen Lauf
--      mit Blick in die echte Tabelle.
-- ============================================================================
