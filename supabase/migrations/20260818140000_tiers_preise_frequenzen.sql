-- Tarife: Preise und Session-Frequenzen richtigstellen.
--
-- Befund (2026-08-18): tiers fuehrt seit dem Baseline-Seed Werte, die nie
-- gestimmt haben. Der Eltern-Report liest Paketname und Frequenz aus dieser
-- Tabelle und hat sie deshalb falsch ausgegeben.
--
--            bisher                     richtig
--   Basic    89,00 EUR / 2 Sessions     199,99 EUR / 1 Session pro Woche
--   Standard 129,00 EUR / 3 Sessions    279,99 EUR / 1,5 Sessions pro Woche
--   Premium  169,00 EUR / unbegrenzt    349,99 EUR / 2 Sessions pro Woche
--
-- ----------------------------------------------------------------------------
-- Die Einheit ist Cent — und das ist hier belegbar, nicht bloss der Spaltenname
-- ----------------------------------------------------------------------------
-- Entscheidend ist nicht `price_cents`, sondern dass die Zielwerte gebrochene
-- Cent tragen: 199,99 EUR ist in einer integer-Euro-Spalte gar nicht
-- darstellbar. Dazu die Gegenprobe am Bestand — 8900 als Euro waeren 8.900 EUR
-- im Monat.
--
-- Anzusehen ist das nirgends: Es gibt im Frontend KEINE Preisanzeige.
-- price_cents kommt nur in src/types/domain.ts und im Schreibpfad
-- src/lib/supabase/tiers.ts vor, und der hat keinen Aufrufer. Ein
-- Faktor-100-Fehler waere erst im Verkaufsgespraech aufgefallen.
--
-- ----------------------------------------------------------------------------
-- Warum upsert und nicht update — die CI-Reihenfolge erzwingt es
-- ----------------------------------------------------------------------------
-- .github/workflows/schema.yml faehrt: Grundlage -> Migrationen -> seed.sql.
-- Beim Neuaufbau ist tiers zum Zeitpunkt DIESER Migration also LEER. Ein
-- blosses `update` traefe null Zeilen; danach fuellte supabase/seed.sql die
-- Tabelle mit den alten Werten, weil sein `where not exists`-Waechter eine
-- leere Tabelle sieht. Die Pruefung unten waere in CI rot, obwohl die Migration
-- korrekt ist.
--
-- Der Upsert loest beide Richtungen mit demselben Befehl:
--   leere Datenbank (CI, Schnappschuss) -> insert der RICHTIGEN Werte;
--                                          seed.sql ueberspringt sie danach
--   Produktion                          -> on conflict (name) do update
--
-- supabase/seed.sql bleibt deshalb unberuehrt: sein Waechter macht ihn nach
-- dieser Migration wirkungslos. Er traegt weiter die alten Zahlen — als
-- Fundstelle im PR gelistet, aber keine Aenderung dieses PRs.
--
-- ----------------------------------------------------------------------------
-- Warum nur features[0] angefasst wird
-- ----------------------------------------------------------------------------
-- tiers hat keine Frequenzspalte. Die Frequenz ist das ERSTE Element des
-- features-Arrays, als Freitext — eine reine Positionskonvention, auf die sich
-- genau ein Konsument verlaesst (scripts/report/build-eltern-report.ts:
-- `tier?.features?.[0]`).
--
-- Der Update-Zweig setzt deshalb per jsonb_set gezielt Index 0 und laesst alles
-- dahinter stehen. Ein vollstaendiges Array zu schreiben wuerde ein
-- Leistungsmerkmal loeschen, das jemand ueber updateTier() ergaenzt hat —
-- Lernpfad, Reportfrequenz, Coach-Chat und Fachwechsel gehen diesen PR nichts
-- an.
--
-- ----------------------------------------------------------------------------
-- Warum diese Datei sich selbst klammert
-- ----------------------------------------------------------------------------
-- scripts/db-migrate.sh spielt mit `psql -f` ein und oeffnet KEINE Transaktion.
-- Ohne begin/commit koennte der Upsert durchlaufen und die Kontrolle darunter
-- scheitern — zurueck bliebe eine Preisliste in unbekanntem Zustand. Bei
-- Preisen ist halb angewendet schlimmer als gar nicht: eine gemischte Tabelle
-- geht unbemerkt ins Verkaufsgespraech.

begin;

insert into public.tiers (name, price_cents, features, sort_order, active)
values
  ('Basic',    19999,
   '["1 Session/Woche","Basis-Lernpfad","Monatlicher Eltern-Report"]'::jsonb,
   1, true),
  ('Standard', 27999,
   '["1,5 Sessions/Woche","KI-Lernpfad","2x Eltern-Report/Monat","Coach-Chat"]'::jsonb,
   2, true),
  ('Premium',  34999,
   '["2 Sessions/Woche","Voller KI-Lernpfad","Woechentlicher Report","Prioritaets-Coach","Fachwechsel flexibel"]'::jsonb,
   3, true)
on conflict (name) do update
  set price_cents = excluded.price_cents,
      -- NUR Index 0. Alles dahinter bleibt, wie es in der Zieldatenbank steht.
      features    = jsonb_set(public.tiers.features, '{0}', excluded.features -> 0, true);
      -- sort_order und active bewusst NICHT im Update-Zweig: beide sind im
      -- Bestand richtig, und diese Migration korrigiert Preis und Frequenz.

-- Kontrolle im selben Transaktionsblock. Sie ist der Grund fuer begin/commit:
-- schlaegt sie an, wird der Upsert mit zurueckgerollt.
do $$
declare
  v_name  text;
  v_preis integer;
  v_freq  text;
  v_soll  jsonb := '[
    {"name":"Basic",   "preis":19999,"freq":"1 Session/Woche"},
    {"name":"Standard","preis":27999,"freq":"1,5 Sessions/Woche"},
    {"name":"Premium", "preis":34999,"freq":"2 Sessions/Woche"}
  ]'::jsonb;
  v_zeile jsonb;
begin
  for v_zeile in select * from jsonb_array_elements(v_soll) loop
    v_name := v_zeile ->> 'name';

    select t.price_cents, t.features ->> 0
      into v_preis, v_freq
      from public.tiers t
     where t.name = v_name;

    if not found then
      raise exception 'Tarif % fehlt nach dem Upsert', v_name;
    end if;
    if v_preis is distinct from (v_zeile ->> 'preis')::integer then
      raise exception 'Tarif %: price_cents=% , erwartet %',
        v_name, v_preis, v_zeile ->> 'preis';
    end if;
    if v_freq is distinct from (v_zeile ->> 'freq') then
      raise exception 'Tarif %: features[0]=%, erwartet %',
        v_name, coalesce(v_freq, 'null'), v_zeile ->> 'freq';
    end if;
  end loop;

  raise notice 'tiers: 3 Tarife auf 199,99 / 279,99 / 349,99 EUR und 1 / 1,5 / 2 Sessions pro Woche gesetzt';
end $$;

commit;
