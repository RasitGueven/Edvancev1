-- Batu Schritt 2: die beiden alten Leads von Batu Demirel werden Testdaten.
--
-- Entscheidung Rasit 12.10.2026: Die Altleads werden Testdaten, Batu startet am 31.10. mit einem frischen
-- Lead. Damit sie in Listen nicht mit dem neuen Lead verwechselt werden, tragen sie den Monat ihrer
-- Anlage im Namen (created_at, Europe/Berlin; geprüft am 14.10. per dbread):
--   d9c9b82a…  angelegt 18.07.2026  ->  „Batu Demirel (alt 07/2026)“
--   7ab419b1…  angelegt 06.09.2026  ->  „Batu Demirel (alt 09/2026)“
-- Status (rejected) bleibt, damit der Trigger leads_status_zeitstempel nichts neu stempelt.
--
-- Die Schülerzeile c017bf9e… (an d9c9b82a) steht schon auf ist_test = true und bleibt unberührt. Deshalb
-- nicht über testkonto_setzen: die Funktion verlangt eine Admin-Rolle im JWT (eine Migration hat keine)
-- und setzt außerdem die Kinder des Leads mit. Stattdessen direktes UPDATE nur auf leads.
-- Der Trigger ist_test_schuetzen lässt das nur als Systemaufruf oder für den Admin zu: in Prod läuft die
-- Migration als postgres ohne JWT (auth.role() null = Systemaufruf); in der CI-Grundlage fällt auth.role()
-- auf 'anon' zurück, daher die transaktionslokale Systemrolle im selben DO-Block.
--
-- Idempotent: ein zweiter Lauf trifft keine Zeile mehr. Fehlen die Leads (CI-Neuaufbau, fremde DB),
-- passiert nichts. Kein begin/commit: mig klammert mit psql -1.

do $batu$
declare
  v_n integer;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  update public.leads
     set ist_test = true,
         full_name = case when full_name = 'Batu Demirel' then 'Batu Demirel (alt 07/2026)' else full_name end
   where id = 'd9c9b82a-7ab6-4946-8c13-44ed9eda83fc'::uuid
     and (ist_test is distinct from true or full_name = 'Batu Demirel');
  get diagnostics v_n = row_count;
  raise notice 'batu_altleads: d9c9b82a % Zeile(n)', v_n;

  update public.leads
     set ist_test = true,
         full_name = case when full_name = 'Batu Demirel' then 'Batu Demirel (alt 09/2026)' else full_name end
   where id = '7ab419b1-a7e4-440e-829b-2280d50761d6'::uuid
     and (ist_test is distinct from true or full_name = 'Batu Demirel');
  get diagnostics v_n = row_count;
  raise notice 'batu_altleads: 7ab419b1 % Zeile(n)', v_n;
end
$batu$;
