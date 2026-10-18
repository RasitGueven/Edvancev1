-- falsche_richtung aufteilen: dezimal_div bekommt eigene Fehlbilder, der Slug behält nur die Prozentfälle.
--
-- Der Slug stand für zwei verschiedene Fehler (docs/themen/fehlerfamilien-batu.md, Nebenbefund zu sachaufgaben):
--   * dezimal_div (9 Pilot-Aufgaben): Kehrwert (4,8 : 0,6 → 0,125) oder Komma zwei Stellen zu weit links (→ 0,08).
--   * prozent_veraenderung (10 Aufgaben, nicht im Pilot): Zu- und Abnahme vertauscht (60 € − 25 % → 75 €).
-- Sein Klartext beschrieb nur dezimal_div, seine Familie (sachaufgaben) passt nur auf die Prozentfälle.
--
-- 1. Neues Fehlbild kommaregel_mal_beim_teilen (Familie kommazahlen) mit Klartext, Erklärung und Freigabe,
--    per on conflict do nothing.
-- 2. known_errors der 9 dezimal_div-Aufgaben, nur wo der Schlüssel noch falsche_richtung trägt:
--    Kehrwert (0,125 / 0,167 / 0,333) → umgekehrt_geteilt, Komma-Fälle (0,0x) → kommaregel_mal_beim_teilen.
-- 3. falsche_richtung: Klartext auf die Prozentfälle, Erklärung neu (bisher leer), jeweils nur wo der Vorher-Stand
--    steht. Familie und Freigabe bleiben.
--
-- lsa_responses enthält falsche_richtung bisher nicht; es gibt nichts nachzuziehen. Idempotent; in der CI ohne die
-- Aufgaben nur Schritt 1 und 3. Kein begin/commit: mig klammert mit psql -1.

do $frt$
declare
  v_n integer;
begin
  insert into public.fehlbild_labels (slug, klartext, erklaerung, familie, freigegeben_am)
  values ('kommaregel_mal_beim_teilen',
          'Setzt beim Teilen das Komma nach der Regel vom Malnehmen und zählt die Stellen nach dem Komma zusammen: 4,8 : 0,6 = 0,08 statt 8.',
          'Beim Malnehmen zählt man die Stellen nach dem Komma zusammen: 0,6 · 0,4 hat zwei. Beim Teilen gilt diese Regel nicht; dort verschiebt man das Komma bei beiden Zahlen gleich weit, aus 4,8 : 0,6 wird 48 : 6 = 8. Wer die Regel vom Malnehmen überträgt, erhält ein Ergebnis, das hundertmal zu klein ist. Geübt wird, vorher zu überschlagen: 4,8 : 0,6 muss größer als 1 sein.',
          'kommazahlen',
          now())
  on conflict (slug) do nothing;
  get diagnostics v_n = row_count;
  raise notice 'falsche_richtung_aufteilen: % neues Fehlbild', v_n;

  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, array['known_errors', v.schluessel], to_jsonb(v.slug))
    from (values ('1debff4f-af14-4dec-89a8-4344d6966fb0'::uuid, '0,125', 'umgekehrt_geteilt'),
                 ('730dae3f-afb6-49c8-baa9-53a5169a6a90'::uuid, '0,167', 'umgekehrt_geteilt'),
                 ('fa305352-7dcc-4e25-85dd-0cc9e201fca6'::uuid, '0,333', 'umgekehrt_geteilt'),
                 ('400b8905-8ad7-4fd8-8a15-7fb6d0e37b14'::uuid, '0,08',  'kommaregel_mal_beim_teilen'),
                 ('6b531762-47e8-4b29-aeee-ce70b560486a'::uuid, '0,04',  'kommaregel_mal_beim_teilen'),
                 ('6fc6f305-160c-4c63-8371-de05eda0d520'::uuid, '0,07',  'kommaregel_mal_beim_teilen'),
                 ('865b6e60-271a-483b-afe2-63cdfe266e1b'::uuid, '0,06',  'kommaregel_mal_beim_teilen'),
                 ('91390c63-7a79-43a0-bf60-4abc0316bc52'::uuid, '0,09',  'kommaregel_mal_beim_teilen'),
                 ('bdf4d10a-9cf2-4ed5-a59b-54fec4b3851f'::uuid, '0,06',  'kommaregel_mal_beim_teilen')) v(task_id, schluessel, slug),
         public.tasks t
   where s.task_id = v.task_id and t.id = v.task_id
     and t.skill_key = 'dezimal_div'
     and s.acceptance -> 'known_errors' ->> v.schluessel = 'falsche_richtung';
  get diagnostics v_n = row_count;
  raise notice 'falsche_richtung_aufteilen: % Aufgabe(n) geändert', v_n;

  update public.fehlbild_labels
     set klartext = 'Verwechselt Zunahme und Abnahme: Bei „Der Preis sinkt um 25 %“ wird aus 60 € der Wert 75 € statt 45 €.'
   where slug = 'falsche_richtung'
     and klartext = 'Rechnet den Kehrwert oder verschiebt das Komma um zwei Stellen.';
  get diagnostics v_n = row_count;
  raise notice 'falsche_richtung_aufteilen: falsche_richtung Klartext, % Zeile(n)', v_n;

  update public.fehlbild_labels
     set erklaerung = 'Der Prozentwert ist richtig ausgerechnet, wird aber in die falsche Richtung angewendet: abgezogen statt dazugezählt oder umgekehrt. Sinkt ein Preis um 25 %, bleiben 75 % übrig, also 60 € · 0,75 = 45 €. Geübt wird, vor dem Rechnen zu entscheiden, ob das Ergebnis größer oder kleiner werden muss.'
   where slug = 'falsche_richtung'
     and nullif(btrim(coalesce(erklaerung, '')), '') is null;
  get diagnostics v_n = row_count;
  raise notice 'falsche_richtung_aufteilen: falsche_richtung Erklärung, % Zeile(n)', v_n;
end $frt$;
