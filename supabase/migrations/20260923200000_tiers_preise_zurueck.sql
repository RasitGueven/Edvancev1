-- Tarifpreise zurueck auf den Stand von 20260818140000:
-- 199,99 / 279,99 / 349,99 EUR. Nimmt die Preisaenderung aus
-- 20260922120000_vertraege_prozess zurueck. Nur Daten, kein Schema.
--
-- Bereits abgeschlossene Vertraege behalten ihren eingefrorenen preis_cents
-- (Trigger setzt ihn nur bei Tarifwechsel im Status in_vorbereitung).

update public.tiers set price_cents = 19999 where name = 'Basic';
update public.tiers set price_cents = 27999 where name = 'Standard';
update public.tiers set price_cents = 34999 where name = 'Premium';

do $$
begin
  if (select count(*) from public.tiers
       where (name, price_cents) in (('Basic', 19999), ('Standard', 27999), ('Premium', 34999))) <> 3 then
    raise exception 'tiers: Preise nicht wie erwartet zurueckgesetzt';
  end if;
end $$;
