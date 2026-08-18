-- tiers_preise_frequenzen.PRUEFUNG.sql
--
-- Schreibt die drei Tarife fest: Preis und Session-Frequenz.
--
-- Anlass: tiers fuehrte seit dem Baseline-Seed Werte, die nie gestimmt haben
-- (89/129/169 EUR, 2/3/unbegrenzt Sessions). Der Eltern-Report liest beides von
-- dort und hat es falsch ausgegeben. Gemerkt hat es niemand, weil es im
-- Frontend keine Preisanzeige gibt — price_cents wird nirgends gerendert.
-- Genau deshalb steht die Kontrolle hier und nicht im Kommentar.
--
-- ----------------------------------------------------------------------------
-- Warum diese Pruefung im Neuaufbau ueberhaupt etwas sieht
-- ----------------------------------------------------------------------------
-- .github/workflows/schema.yml faehrt: Grundlage -> Migrationen -> seed.sql ->
-- Pruefskripte. Zum Zeitpunkt der Migration ist tiers leer, deshalb schreibt
-- 20260818140000_tiers_preise_frequenzen.sql per Upsert (Begruendung dort).
-- seed.sql laeuft danach, findet die drei Namen bereits vor und ueberspringt
-- seinen insert — er traegt weiter die ALTEN Zahlen.
--
-- T1/T2 sind damit die eigentliche Kontrolle dieser Datei: Wuerde der Upsert je zu
-- einem blossen `update` zurueckgebaut, traefe er im Neuaufbau null Zeilen,
-- seed.sql fuellte die alten Werte ein — und die Pruefung wird rot.
--
-- Laeuft gegen eine leere Neuaufbau-Datenbank UND gegen Produktion; sie liest
-- nur und rollt zurueck.
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--     -f supabase/checks/tiers_preise_frequenzen.PRUEFUNG.sql

begin;

do $$
declare
  -- Preis in Cent. 199,99 EUR traegt gebrochene Cent und ist in einer
  -- integer-Euro-Spalte gar nicht darstellbar — daran haengt die Einheit,
  -- nicht am Spaltennamen.
  v_soll jsonb := '[
    {"name":"Basic",   "preis":19999,"freq":"1 Session/Woche",   "sort":1,
     "rest":["Basis-Lernpfad","Monatlicher Eltern-Report"]},
    {"name":"Standard","preis":27999,"freq":"1,5 Sessions/Woche","sort":2,
     "rest":["KI-Lernpfad","2x Eltern-Report/Monat","Coach-Chat"]},
    {"name":"Premium", "preis":34999,"freq":"2 Sessions/Woche",  "sort":3,
     "rest":["Voller KI-Lernpfad","Woechentlicher Report","Prioritaets-Coach","Fachwechsel flexibel"]}
  ]'::jsonb;
  v_zeile  jsonb;
  v_name   text;
  v_preis  integer;
  v_freq   text;
  v_sort   integer;
  v_active boolean;
  v_rest   jsonb;
  v_anzahl integer;
begin

  -- ---- T1: Preise ---------------------------------------------------------
  for v_zeile in select * from jsonb_array_elements(v_soll) loop
    v_name := v_zeile ->> 'name';

    select t.price_cents, t.features ->> 0, t.sort_order, t.active
      into v_preis, v_freq, v_sort, v_active
      from public.tiers t
     where t.name = v_name;

    if not found then
      raise exception 'T1 Tarif % fehlt in tiers', v_name;
    end if;
    if v_preis is distinct from (v_zeile ->> 'preis')::integer then
      raise exception 'T1 Tarif %: price_cents=% (% EUR), erwartet % (% EUR)',
        v_name, v_preis, round(v_preis / 100.0, 2),
        v_zeile ->> 'preis', round((v_zeile ->> 'preis')::numeric / 100.0, 2);
    end if;

    -- ---- T2: Session-Frequenz in features[0] ------------------------------
    -- tiers hat keine Frequenzspalte; die Frequenz ist das erste Element des
    -- features-Arrays. Eine Positionskonvention, auf die sich der Eltern-Report
    -- verlaesst (scripts/report/build-eltern-report.ts) — deshalb festgeschrieben.
    if v_freq is distinct from (v_zeile ->> 'freq') then
      raise exception 'T2 Tarif %: features[0]=%, erwartet %',
        v_name, coalesce(v_freq, 'null'), v_zeile ->> 'freq';
    end if;

    -- ---- T3: die uebrigen Leistungsmerkmale unveraendert ------------------
    -- Lernpfad, Reportfrequenz, Coach-Chat und Fachwechsel gehen die
    -- Preiskorrektur nichts an. Faellt eins davon weg, hat jemand das ganze
    -- Array ueberschrieben statt nur Index 0 zu setzen.
    select jsonb_agg(e order by o) into v_rest
      from (
        select e, o from public.tiers t,
             lateral jsonb_array_elements(t.features) with ordinality as x(e, o)
         where t.name = v_name and o > 1
      ) s;
    if coalesce(v_rest, '[]'::jsonb) is distinct from (v_zeile -> 'rest') then
      raise exception 'T3 Tarif %: uebrige Merkmale = %, erwartet %',
        v_name, coalesce(v_rest, '[]'::jsonb)::text, (v_zeile -> 'rest')::text;
    end if;

    if v_sort is distinct from (v_zeile ->> 'sort')::integer then
      raise exception 'T3 Tarif %: sort_order=%, erwartet %',
        v_name, v_sort, v_zeile ->> 'sort';
    end if;
    if not v_active then
      raise exception 'T3 Tarif % ist inaktiv', v_name;
    end if;

    raise notice 'T1-T3 ok: % — % EUR, %',
      v_name, round(v_preis / 100.0, 2), v_freq;
  end loop;

  -- ---- T4: Negativkontrolle ueber ALLE Zeilen, nicht nur die drei ---------
  -- T1/T2 pruefen die drei Tarife namentlich. T4 greift daneben: eine vierte
  -- Zeile, die jemand mit den alten Zahlen anlegt oder ein umbenannter Tarif,
  -- der die Altwerte mitschleppt.
  --
  -- Nur die PREISE, nicht die Frequenztexte. Die alten und neuen Frequenzen
  -- ueberschneiden sich: "2 Sessions/Woche" war der falsche Wert von Basic und
  -- ist jetzt der richtige von Premium. Eine Textliste wuerde hier gegen den
  -- korrigierten Bestand anschlagen. Die drei alten Preise kollidieren mit
  -- keinem neuen.
  select count(*) into v_anzahl
    from public.tiers
   where price_cents in (8900, 12900, 16900);
  if v_anzahl > 0 then
    raise exception
      'T4 % Tarifzeile(n) tragen einen der alten Preise (89,00 / 129,00 / 169,00 EUR)',
      v_anzahl;
  end if;

  -- ---- T5: genau drei aktive Tarife ---------------------------------------
  -- Ein vierter aktiver Tarif waere kein Fehler, aber eine Entscheidung — und
  -- er wuerde hier still an der Preisliste vorbeilaufen.
  select count(*) into v_anzahl from public.tiers where active;
  if v_anzahl <> 3 then
    raise exception 'T5 % aktive Tarife, erwartet 3', v_anzahl;
  end if;

  raise notice 'T4-T5 ok: keine Altwerte, genau 3 aktive Tarife';
end $$;

rollback;
