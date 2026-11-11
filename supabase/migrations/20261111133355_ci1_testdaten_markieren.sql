-- CI-1 Teil D: fehlende Testmarkierungen setzen (reine Datenänderung, kein Schema, nichts gelöscht).
--
-- Entscheidung Rasit 11.11.2026 auf Grundlage von docs/marke/ci1-bestand.md Abschnitt 5 (dbread-Abzug
-- vom selben Tag): Echt sind nur die Leads/Schüler von Kind A (060b316e…, f9e42014…) und Kind B; alle
-- übrigen Leads mit ist_test = false sowie der Schüler 5d03e892… sind Testdaten. Nur false -> true,
-- keine Zeile wird zurückgesetzt oder gelöscht.
--
-- Der Trigger ist_test_schuetzen lässt die Änderung nur als Systemaufruf oder für den Admin zu: in Prod
-- läuft die Migration als postgres ohne JWT (auth.role() null = Systemaufruf); in der CI-Grundlage fällt
-- auth.role() auf 'anon' zurück, daher die transaktionslokale Systemrolle (wie 20261014064047).
-- Status und Namen bleiben, damit leads_status_zeitstempel nichts neu stempelt.
--
-- Idempotent: ein zweiter Lauf trifft keine Zeile mehr. Fehlen die Zeilen (CI-Neuaufbau), passiert nichts.
-- Kein begin/commit: mig klammert mit psql -1.

do $ci1$
declare
  v_n integer;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  update public.leads
     set ist_test = true
   where ist_test = false
     and id = any (array[
       '4080fefe-2ead-40e4-871f-35e48c2dc239', 'dde9f9d0-3ad6-45e7-8d99-4af4e21f9193',
       '8169556f-3a64-4a20-b524-a73b5f9392d4', '2ded60a7-9230-4cab-a529-ed16231d6980',
       '5f236f5f-2e59-4cca-bc7e-d9c3658221a7', 'e2ca04a6-efc6-4596-9ee5-6a5182f0d0de',
       'c4a542f1-f81f-4313-adf0-c2681e6f9851', '875ee8ad-c281-4475-a0b3-d8c33ada74b8',
       'f63564ac-3f11-48e5-9d5c-6c8fc553f4b5', '1c9f68c9-31a7-4c52-9b42-00d6e15d520f',
       'd9e54bcb-21b8-4e73-b724-b4dff5451b2e', '613a825c-89ed-4b03-8583-8bdcca7094f4',
       '57919102-77fd-43a4-b525-c6a777cbb697', '17914091-62c7-42d5-ab4b-29b089bb6379',
       'ec0ae5d3-e687-429b-b7e8-c54008b56759', '8d9cb9b9-a1b1-42a9-a3ef-5885ed1d6c2c',
       '5cccc8ca-51b3-4557-a7b1-392cfbb4d14a', '1ebcd18f-6973-493a-be43-dad93b431205',
       'd01b50b7-59b8-422c-b4d4-4c4d51bca956', 'd35f9a72-594f-4b29-9be1-03587b8f1db7',
       '75adb56f-69ca-494c-a10c-d0000e9e489a', 'c7760dd0-ed58-4673-a08a-4af6084417f2',
       '8f2b7c14-0b3b-45b6-812a-0f548ade26c8', 'bb2362c1-608a-4334-853e-d3c9de1397c7',
       '429c3a5b-9ec2-461e-978e-0ed4b266260d', '1f1828d9-4582-4ff7-8055-7c323175096e',
       'fccc3c01-04a8-4c31-8213-8660ab1d1bfd', '61e36cda-031e-493c-b7dc-51e1e51e6e18',
       '8cbee0cf-233d-4294-b86c-bcdf918984ea'
     ]::uuid[]);
  get diagnostics v_n = row_count;
  raise notice 'ci1_testdaten: leads % Zeile(n)', v_n;

  update public.students
     set ist_test = true
   where ist_test = false
     and id = '5d03e892-7d50-4d1b-90c2-49aa9f254dba'::uuid;
  get diagnostics v_n = row_count;
  raise notice 'ci1_testdaten: students % Zeile(n)', v_n;
end
$ci1$;
