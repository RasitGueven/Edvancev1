-- Tarife je Laufzeit: Jahrespaket und Halbjahrespaket.
--
--              Jahrespaket (12 Beitraege)     Halbjahrespaket (6 Beitraege)
--   Basic      199,90 EUR · 38 Einheiten      219,90 EUR · 19 Einheiten
--   Standard   269,90 EUR · 57 Einheiten      299,90 EUR · 29 Einheiten
--   Premium    349,90 EUR · 76 Einheiten      389,90 EUR · 38 Einheiten
--
-- Quelle: Vertrags-Clickdummy (vertraege-gesamt-dummy.html) und Preisentscheidung
-- vom 24.09.2026. Ersetzt 20260818140000 (199,99 / 279,99 / 349,99) und den
-- zurueckgenommenen Zwischenstand aus 20260922120000.
--
-- ----------------------------------------------------------------------------
-- Modell
-- ----------------------------------------------------------------------------
-- tier_laufzeiten haelt Monatsbeitrag und Einheiten je (Tarif, Laufzeit). Die
-- Zahl der Beitraege ist die Laufzeit in Monaten (12 bzw. 6) — auch wenn sich
-- ein Halbjahresvertrag wegen der Ferien ueber mehr Kalendermonate streckt.
-- Gesamtpreis = Monatsbeitrag x Laufzeit; er wird nicht gespeichert, sondern
-- abgeleitet, damit er nie von den beiden Faktoren abweichen kann.
--
-- tiers.price_cents bleibt als Referenzpreis bestehen und traegt den
-- Jahrespaket-Beitrag. Verbindlich fuer Vertraege ist allein tier_laufzeiten.
--
-- vertraege bekommt einheiten. Der Guard setzt preis_cents UND einheiten aus
-- tier_laufzeiten, sobald sich Paket ODER Laufzeit aendert (nur in
-- 'in_vorbereitung'); fehlt eins von beiden, bleiben beide leer. Danach sind
-- beide eingefroren.
--
-- Die Datei klammert sich selbst (begin/commit): Preise halb angewendet sind
-- schlimmer als gar nicht.

begin;

-- ============================================================================
-- 1. Preis- und Einheitentabelle
-- ============================================================================

create table public.tier_laufzeiten (
  tier_id          uuid    not null references public.tiers (id) on delete cascade,
  laufzeit_monate  integer not null,
  preis_cents      integer not null,
  einheiten        integer not null,
  primary key (tier_id, laufzeit_monate),
  constraint tier_laufzeiten_laufzeit_check check (laufzeit_monate in (6, 12)),
  constraint tier_laufzeiten_preis_check check (preis_cents > 0),
  constraint tier_laufzeiten_einheiten_check check (einheiten > 0)
);

comment on table public.tier_laufzeiten is
  'Monatsbeitrag (Cent) und Einheiten je Tarif und Laufzeit. Beitraege = Laufzeit in Monaten.';

alter table public.tier_laufzeiten enable row level security;

create policy tier_laufzeiten_authenticated_read on public.tier_laufzeiten
  for select using (auth.role() = 'authenticated');

create policy tier_laufzeiten_admin_write on public.tier_laufzeiten
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- Tarife stehen seit 20260818140000 sicher in der Tabelle (Upsert, auch im
-- Neuaufbau), deshalb genuegt der Join ueber den Namen.
insert into public.tier_laufzeiten (tier_id, laufzeit_monate, preis_cents, einheiten)
select t.id, w.laufzeit, w.preis, w.einheiten
  from (values
    ('Basic',    12, 19990, 38),
    ('Basic',     6, 21990, 19),
    ('Standard', 12, 26990, 57),
    ('Standard',  6, 29990, 29),
    ('Premium',  12, 34990, 76),
    ('Premium',   6, 38990, 38)
  ) as w (name, laufzeit, preis, einheiten)
  join public.tiers t on t.name = w.name
on conflict (tier_id, laufzeit_monate) do update
  set preis_cents = excluded.preis_cents,
      einheiten   = excluded.einheiten;

-- Referenzpreis in tiers = Jahrespaket.
update public.tiers set price_cents = 19990 where name = 'Basic';
update public.tiers set price_cents = 26990 where name = 'Standard';
update public.tiers set price_cents = 34990 where name = 'Premium';

-- ============================================================================
-- 2. Vertraege: Einheiten, Guard rechnet mit der Laufzeit
-- ============================================================================

alter table public.vertraege
  add column einheiten integer;

comment on column public.vertraege.einheiten is
  'Zugesagte Einheiten, vom Guard aus tier_laufzeiten gesetzt und nach dem Versand eingefroren.';

create or replace function public.vertraege_guard()
returns trigger
language plpgsql
as $function$
begin
  if new.status is distinct from old.status
     and coalesce(current_setting('edvance.vertrag_rpc', true), '') <> '1' then
    raise exception 'vertraege: Status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;

  -- Preis und Einheiten folgen aus (Paket, Laufzeit) — nie aus dem Formular.
  if new.status = 'in_vorbereitung'
     and (new.tier_id is distinct from old.tier_id
          or new.laufzeit_monate is distinct from old.laufzeit_monate) then
    new.preis_cents := null;
    new.einheiten   := null;
    select tl.preis_cents, tl.einheiten
      into new.preis_cents, new.einheiten
      from public.tier_laufzeiten tl
     where tl.tier_id = new.tier_id
       and tl.laufzeit_monate = new.laufzeit_monate;
  else
    new.preis_cents := old.preis_cents;
    new.einheiten   := old.einheiten;
  end if;

  new.updated_at := now();
  return new;
end;
$function$;

-- Offene Entwuerfe auf die neuen Konditionen ziehen. Nur 'in_vorbereitung':
-- Was schon zur Unterschrift raus ist oder abgeschlossen wurde, behaelt
-- seinen Preis. Der Guard wuerde preis_cents sonst zuruecksetzen, deshalb
-- kurz aus — innerhalb dieser Transaktion.
alter table public.vertraege disable trigger vertraege_guard_trg;

update public.vertraege v
   set preis_cents = tl.preis_cents,
       einheiten   = tl.einheiten
  from public.tier_laufzeiten tl
 where v.status = 'in_vorbereitung'
   and tl.tier_id = v.tier_id
   and tl.laufzeit_monate = v.laufzeit_monate;

alter table public.vertraege enable trigger vertraege_guard_trg;

-- ============================================================================
-- 3. Kontrolle
-- ============================================================================

do $$
declare
  v_soll jsonb := '[
    {"name":"Basic",   "l":12,"preis":19990,"einheiten":38},
    {"name":"Basic",   "l":6, "preis":21990,"einheiten":19},
    {"name":"Standard","l":12,"preis":26990,"einheiten":57},
    {"name":"Standard","l":6, "preis":29990,"einheiten":29},
    {"name":"Premium", "l":12,"preis":34990,"einheiten":76},
    {"name":"Premium", "l":6, "preis":38990,"einheiten":38}
  ]'::jsonb;
  v_zeile jsonb;
  v_preis integer;
  v_einh  integer;
begin
  for v_zeile in select * from jsonb_array_elements(v_soll) loop
    select tl.preis_cents, tl.einheiten into v_preis, v_einh
      from public.tier_laufzeiten tl
      join public.tiers t on t.id = tl.tier_id
     where t.name = v_zeile ->> 'name'
       and tl.laufzeit_monate = (v_zeile ->> 'l')::integer;
    if not found then
      raise exception 'tier_laufzeiten: % / % Monate fehlt', v_zeile ->> 'name', v_zeile ->> 'l';
    end if;
    if v_preis <> (v_zeile ->> 'preis')::integer or v_einh <> (v_zeile ->> 'einheiten')::integer then
      raise exception 'tier_laufzeiten: % / % Monate = % Cent, % Einheiten; erwartet %',
        v_zeile ->> 'name', v_zeile ->> 'l', v_preis, v_einh, v_zeile;
    end if;
  end loop;

  if (select count(*) from public.tiers
       where (name, price_cents) in (('Basic', 19990), ('Standard', 26990), ('Premium', 34990))) <> 3 then
    raise exception 'tiers: Referenzpreise nicht wie erwartet gesetzt';
  end if;
end $$;

commit;
