-- Vertragsprozess: Termin und Ablehnungsgrund am Lead, eigene Vertragstabelle
-- mit SEPA-Mandat, Dokument-Haekchen, Unterschriften und Versandprotokoll.
--
-- Ablauf:
--   Lead 'lsa_fertig' --vertrag_starten--> Lead 'vertrag' + Vertrag 'in_vorbereitung'
--   Vertrag --vertrag_versand_protokollieren (Unterlagen)--> 'unterschrift_ausstehend'
--   Vertrag --vertrag_abschliessen (vor Ort / Papier)-->     'abgeschlossen'
--   Vertrag --vertrag_ablehnen-->                            'abgelehnt' + Lead 'rejected'
--
-- Statuswechsel am Vertrag laufen ausschliesslich ueber die RPCs. Ein direktes
-- UPDATE auf vertraege.status weist vertraege_guard ab — sonst liesse sich das
-- Haekchen- und Unterschriften-Gate mit einem einzigen PATCH umgehen.
--
-- Zugriff: nur Admin (Vertrag & Zahlung liegt bei der Verwaltung). Coaches
-- sehen Leads wie bisher, Vertraege nicht. Die volle IBAN liegt in einer
-- eigenen Tabelle; Listen lesen nur vertraege.iban_masked.
--
-- Die Migration traegt kein begin/commit — mit --single-transaction einspielen.

-- ============================================================================
-- 1. Tarife: Preise korrigieren (199,90 / 269,90 / 349,90 EUR)
-- ============================================================================
-- Seit 20260818140000 stehen die Zeilen sicher in der Tabelle — ein update
-- genuegt, der Upsert-Umweg von damals ist hier nicht noetig.

update public.tiers set price_cents = 19990 where name = 'Basic';
update public.tiers set price_cents = 26990 where name = 'Standard';
update public.tiers set price_cents = 34990 where name = 'Premium';

do $$
begin
  if (select count(*) from public.tiers
       where (name, price_cents) in (('Basic', 19990), ('Standard', 26990), ('Premium', 34990))) <> 3 then
    raise exception 'tiers: Preise nicht wie erwartet gesetzt';
  end if;
end $$;

-- ============================================================================
-- 2. Leads: Termin, Ablehnungsgrund, Status 'vertrag'
-- ============================================================================

alter table public.leads
  add column if not exists erstgespraech_at       timestamptz,
  add column if not exists erstgespraech_standort text,
  add column if not exists rejected_at            timestamptz,
  add column if not exists rejection_reason       text,
  add column if not exists rejection_note         text;

alter table public.leads
  add constraint leads_erstgespraech_standort_check
    check (erstgespraech_standort is null or erstgespraech_standort in ('koeln')),
  add constraint leads_rejection_reason_check
    check (rejection_reason is null or rejection_reason in
      ('preis','zeit','anderer_anbieter','kein_bedarf','kein_kontakt','sonstiges')),
  -- "Sonstiges" nur mit Freitext. Bestandsleads mit status 'rejected' haben
  -- keinen Grund — deshalb ist rejection_reason selbst nicht Pflicht.
  add constraint leads_rejection_note_check
    check (rejection_reason is distinct from 'sonstiges'
           or nullif(btrim(rejection_note), '') is not null);

comment on column public.leads.erstgespraech_at is
  'Vereinbarter Termin des Erstgespraechs (UTC).';
comment on column public.leads.rejected_at is
  'Zeitpunkt des Wechsels nach status = rejected. Null bei Leads von vor dieser Migration.';

alter table public.leads drop constraint if exists leads_status_check;
alter table public.leads add constraint leads_status_check check (
  status in ('new','contacted','onboarding_scheduled','converted','rejected',
             'lsa_freigegeben','lsa_fertig','vertrag')
);

create or replace function public.leads_status_zeitstempel()
returns trigger
language plpgsql
as $function$
begin
  if new.status is distinct from old.status then
    if new.status = 'lsa_freigegeben' and new.lsa_freigegeben_at is null then
      new.lsa_freigegeben_at := now();
    elsif new.status = 'lsa_fertig' and new.lsa_fertig_at is null then
      new.lsa_fertig_at := now();
    elsif new.status = 'rejected' then
      -- Anders als die LSA-Zeitstempel immer neu: ein reaktivierter und
      -- erneut abgelehnter Lead zaehlt ab der letzten Ablehnung.
      new.rejected_at := now();
    end if;
  end if;
  return new;
end;
$function$;

-- ============================================================================
-- 3. Konfiguration und Dokumentkatalog
-- ============================================================================

-- Genau eine Zeile. Die Glaeubiger-ID ist bis zur Vergabe durch die
-- Bundesbank leer; das SEPA-Mandat zeigt dann einen Platzhalter.
create table public.vertrag_einstellungen (
  id             boolean primary key default true check (id),
  glaeubiger_id  text,
  updated_at     timestamptz not null default now()
);

insert into public.vertrag_einstellungen (id) values (true);

-- Jede Fassung eines Dokuments ist eine eigene Zeile. Die Datenschutzhinweise
-- zum Vertrag sind bewusst NICHT die LSA-Einwilligung (leads.consent_dsgvo_*)
-- — eigener Schluessel, eigene Datei, eigene Zustimmung.
create table public.vertrag_dokumente (
  schluessel  text not null,
  version     text not null,
  titel       text not null,
  pflicht     boolean not null,
  aktiv       boolean not null default true,
  sort_order  integer not null default 0,
  primary key (schluessel, version)
);

-- Pro Schluessel hoechstens eine aktive Fassung.
create unique index vertrag_dokumente_aktiv_idx
  on public.vertrag_dokumente (schluessel) where aktiv;

insert into public.vertrag_dokumente (schluessel, version, titel, pflicht, sort_order) values
  ('vertrag',             'platzhalter-v1', 'Vertrag',                                    true,  1),
  ('sepa_mandat',         'platzhalter-v1', 'SEPA-Lastschriftmandat',                     true,  2),
  ('agb',                 'platzhalter-v1', 'Allgemeine Geschäftsbedingungen',            true,  3),
  ('widerruf',            'platzhalter-v1', 'Widerrufsbelehrung und Muster-Widerrufsformular', true, 4),
  ('datenschutz_vertrag', 'platzhalter-v1', 'Datenschutzhinweise zum Vertrag',            true,  5),
  ('einwilligung_fotos',  'platzhalter-v1', 'Einwilligung Fotos',                         false, 6);

-- ============================================================================
-- 4. Vertraege
-- ============================================================================

create sequence public.vertrag_mandat_seq;

create table public.vertraege (
  id                          uuid primary key default gen_random_uuid(),
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  created_by                  uuid references public.profiles (id) on delete set null,
  lead_id                     uuid not null references public.leads (id) on delete cascade,

  status                      text not null default 'in_vorbereitung',
  in_vorbereitung_at          timestamptz not null default now(),
  unterschrift_ausstehend_at  timestamptz,
  abgeschlossen_at            timestamptz,
  abgelehnt_at                timestamptz,
  abgelehnt_grund             text,
  abgelehnt_notiz             text,
  -- 'vor_ort' = Canvas-Unterschrift, 'papier' = unterschrieben zurueckerhalten.
  abschluss_weg               text,
  unterschrieben_am           date,

  -- Vertragspartner (Elternteil)
  eltern_vorname              text,
  eltern_nachname             text,
  strasse                     text,
  hausnummer                  text,
  plz                         text,
  ort                         text,
  eltern_telefon              text,
  eltern_email                text,

  -- Kind
  kind_vorname                text,
  kind_nachname               text,
  kind_geburtsdatum           date,
  klasse                      integer,
  fach                        text,
  schule                      text,

  -- Vertragsdaten. preis_cents setzt der Trigger aus tiers — kein Eingabefeld,
  -- und nach dem Abschluss eingefroren, auch wenn sich der Tarif spaeter aendert.
  laufzeit_monate             integer,
  tier_id                     uuid references public.tiers (id),
  preis_cents                 integer,
  vertragsbeginn              date,

  -- SEPA. Die volle IBAN steht in vertrag_bankdaten.
  kontoinhaber                text,
  iban_masked                 text,
  mandatsreferenz             text not null unique
    default ('EDV-' || to_char(now() at time zone 'Europe/Berlin', 'YYYY') || '-'
             || lpad(nextval('public.vertrag_mandat_seq')::text, 6, '0')),
  glaeubiger_id               text,

  constraint vertraege_status_check check (status in
    ('in_vorbereitung','unterschrift_ausstehend','abgeschlossen','abgelehnt')),
  constraint vertraege_abgelehnt_grund_check check (abgelehnt_grund is null or abgelehnt_grund in
    ('preis','zeit','anderer_anbieter','kein_bedarf','kein_kontakt','sonstiges')),
  constraint vertraege_abgelehnt_notiz_check check (abgelehnt_grund is distinct from 'sonstiges'
    or nullif(btrim(abgelehnt_notiz), '') is not null),
  constraint vertraege_abschluss_weg_check check (abschluss_weg is null or abschluss_weg in ('vor_ort','papier')),
  constraint vertraege_laufzeit_check check (laufzeit_monate is null or laufzeit_monate in (6, 12)),
  constraint vertraege_klasse_check check (klasse is null or klasse between 5 and 13)
);

-- Idempotenz von vertrag_starten: je Lead hoechstens ein nicht abgelehnter Vertrag.
create unique index vertraege_lead_offen_idx
  on public.vertraege (lead_id) where status <> 'abgelehnt';

create index vertraege_status_idx on public.vertraege (status);

comment on table public.vertraege is
  'Vertrag je Lead. Statuswechsel nur ueber die RPCs vertrag_*; Grundlage der spaeteren Schuelerakte.';

-- Guard: Statuswechsel nur aus den RPCs, Preis aus dem Tarif, updated_at.
create or replace function public.vertraege_guard()
returns trigger
language plpgsql
as $function$
begin
  if new.status is distinct from old.status
     and coalesce(current_setting('edvance.vertrag_rpc', true), '') <> '1' then
    raise exception 'vertraege: Status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;

  if new.tier_id is distinct from old.tier_id and new.status = 'in_vorbereitung' then
    select price_cents into new.preis_cents from public.tiers where id = new.tier_id;
  elsif new.preis_cents is distinct from old.preis_cents then
    new.preis_cents := old.preis_cents;
  end if;

  new.updated_at := now();
  return new;
end;
$function$;

create trigger vertraege_guard_trg
  before update on public.vertraege
  for each row execute function public.vertraege_guard();

-- ============================================================================
-- 5. Bankdaten, Zustimmungen, Unterschriften, Versand
-- ============================================================================

create table public.vertrag_bankdaten (
  vertrag_id  uuid primary key references public.vertraege (id) on delete cascade,
  iban        text not null check (iban ~ '^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$'),
  updated_at  timestamptz not null default now()
);

comment on table public.vertrag_bankdaten is
  'Volle IBAN, nur Admin. Die Pruefsumme validiert das Frontend; Listen lesen vertraege.iban_masked.';

-- Maskierte IBAN an den Vertrag spiegeln: DE** **** 1234.
create or replace function public.vertrag_bankdaten_maskieren()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  update vertraege
     set iban_masked = left(new.iban, 2) || '** **** ' || right(new.iban, 4)
   where id = new.vertrag_id;
  return new;
end;
$function$;

create trigger vertrag_bankdaten_maskieren_trg
  after insert or update of iban on public.vertrag_bankdaten
  for each row execute function public.vertrag_bankdaten_maskieren();

-- Append-only: ein Haekchen = eine Zeile. Geschrieben nur von vertrag_abschliessen.
create table public.vertrag_zustimmungen (
  id                 uuid primary key default gen_random_uuid(),
  vertrag_id         uuid not null references public.vertraege (id) on delete cascade,
  dokument_schluessel text not null,
  dokument_version   text not null,
  akzeptiert_at      timestamptz not null,
  erfasst_von        uuid references public.profiles (id) on delete set null,
  foreign key (dokument_schluessel, dokument_version)
    references public.vertrag_dokumente (schluessel, version),
  unique (vertrag_id, dokument_schluessel, dokument_version)
);

create table public.vertrag_unterschriften (
  id                uuid primary key default gen_random_uuid(),
  vertrag_id        uuid not null references public.vertraege (id) on delete cascade,
  art               text not null check (art in ('vertrag','sepa_mandat')),
  -- PNG-Data-URL aus dem SignaturePad, wie leads.consent_dsgvo_signature.
  signatur          text not null,
  unterschrieben_at timestamptz not null default now(),
  unique (vertrag_id, art)
);

-- Append-only: wann, an wen, welcher Weg, wozu.
create table public.vertrag_versand (
  id          uuid primary key default gen_random_uuid(),
  vertrag_id  uuid not null references public.vertraege (id) on delete cascade,
  weg         text not null check (weg in ('email','druck')),
  anlass      text not null check (anlass in ('unterlagen','bestaetigung')),
  empfaenger  text,
  erfolgt_at  timestamptz not null default now(),
  erfolgt_von uuid references public.profiles (id) on delete set null
);

create index vertrag_versand_vertrag_idx on public.vertrag_versand (vertrag_id);

-- ============================================================================
-- 6. RLS — nur Admin
-- ============================================================================

alter table public.vertrag_einstellungen  enable row level security;
alter table public.vertrag_dokumente      enable row level security;
alter table public.vertraege              enable row level security;
alter table public.vertrag_bankdaten      enable row level security;
alter table public.vertrag_zustimmungen   enable row level security;
alter table public.vertrag_unterschriften enable row level security;
alter table public.vertrag_versand        enable row level security;

create policy "vertrag_einstellungen_admin_select" on public.vertrag_einstellungen
  for select using (public.get_my_role() = 'admin');
create policy "vertrag_einstellungen_admin_update" on public.vertrag_einstellungen
  for update using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');

create policy "vertrag_dokumente_admin_select" on public.vertrag_dokumente
  for select using (public.get_my_role() = 'admin');

-- Anlegen nur ueber vertrag_starten; bearbeiten nur, solange er in Vorbereitung ist.
create policy "vertraege_admin_select" on public.vertraege
  for select using (public.get_my_role() = 'admin');
create policy "vertraege_admin_update_vorbereitung" on public.vertraege
  for update
  using (public.get_my_role() = 'admin' and status = 'in_vorbereitung')
  with check (public.get_my_role() = 'admin' and status = 'in_vorbereitung');

create policy "vertrag_bankdaten_admin_select" on public.vertrag_bankdaten
  for select using (public.get_my_role() = 'admin');
create policy "vertrag_bankdaten_admin_write" on public.vertrag_bankdaten
  for insert with check (
    public.get_my_role() = 'admin'
    and exists (select 1 from public.vertraege v
                 where v.id = vertrag_id and v.status = 'in_vorbereitung'));
create policy "vertrag_bankdaten_admin_update" on public.vertrag_bankdaten
  for update
  using (public.get_my_role() = 'admin'
         and exists (select 1 from public.vertraege v
                      where v.id = vertrag_id and v.status = 'in_vorbereitung'))
  with check (public.get_my_role() = 'admin');

create policy "vertrag_zustimmungen_admin_select" on public.vertrag_zustimmungen
  for select using (public.get_my_role() = 'admin');
create policy "vertrag_unterschriften_admin_select" on public.vertrag_unterschriften
  for select using (public.get_my_role() = 'admin');
create policy "vertrag_versand_admin_select" on public.vertrag_versand
  for select using (public.get_my_role() = 'admin');

-- ============================================================================
-- 7. RPCs
-- ============================================================================

-- Legt den Vertrag an (vorbelegt aus dem Lead) und nimmt den Lead vom Board.
-- Idempotent: gibt es schon einen offenen Vertrag, kommt dessen id zurueck.
create or replace function public.vertrag_starten(p_lead_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead leads%rowtype;
  v_id   uuid;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'vertrag_starten: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id for update;
  if not found then
    raise exception 'vertrag_starten: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  select id into v_id from vertraege where lead_id = p_lead_id and status <> 'abgelehnt';
  if v_id is not null then
    return v_id;
  end if;

  if v_lead.status <> 'lsa_fertig' then
    raise exception 'vertrag_starten: Lead steht nicht auf "Analyse abgeschlossen"'
      using errcode = 'P0001';
  end if;

  insert into vertraege (
    created_by, lead_id, eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach, schule
  ) values (
    auth.uid(), p_lead_id, v_lead.contact_phone, v_lead.contact_email,
    coalesce(v_lead.first_name, split_part(v_lead.full_name, ' ', 1)),
    nullif(regexp_replace(v_lead.full_name, '^\S+\s*', ''), ''),
    v_lead.birth_date, v_lead.class_level, v_lead.subjects[1], v_lead.school_name
  )
  returning id into v_id;

  update leads set status = 'vertrag' where id = p_lead_id;
  return v_id;
end;
$$;

-- Protokolliert einen Versand. Unterlagen (Druck/E-Mail) schieben einen
-- Vertrag in Vorbereitung auf 'unterschrift_ausstehend'.
create or replace function public.vertrag_versand_protokollieren(
  p_vertrag_id uuid,
  p_weg        text,
  p_anlass     text,
  p_empfaenger text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'vertrag_versand_protokollieren: nur Admin' using errcode = '42501';
  end if;

  select status into v_status from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versand_protokollieren: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_status = 'abgelehnt' then
    raise exception 'vertrag_versand_protokollieren: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  insert into vertrag_versand (vertrag_id, weg, anlass, empfaenger, erfolgt_von)
  values (p_vertrag_id, p_weg, p_anlass, p_empfaenger, auth.uid());

  if p_anlass = 'unterlagen' and v_status = 'in_vorbereitung' then
    perform set_config('edvance.vertrag_rpc', '1', true);
    update vertraege
       set status = 'unterschrift_ausstehend',
           unterschrift_ausstehend_at = now(),
           glaeubiger_id = coalesce(glaeubiger_id,
             (select glaeubiger_id from vertrag_einstellungen))
     where id = p_vertrag_id;
    perform set_config('edvance.vertrag_rpc', '', true);
  end if;
end;
$$;

-- Abschluss. 'vor_ort': alle aktiven Pflicht-Dokumente in ihrer aktuellen
-- Fassung angehakt, beide Unterschriften, IBAN hinterlegt. 'papier': nur das
-- Datum, an dem der unterschriebene Vertrag zurueckkam.
-- Idempotent: ein bereits abgeschlossener Vertrag bleibt unveraendert.
--
-- p_zustimmungen: [{"schluessel":"agb","version":"platzhalter-v1","akzeptiert_at":"<iso>"}, ...]
create or replace function public.vertrag_abschliessen(
  p_vertrag_id          uuid,
  p_weg                 text,
  p_zustimmungen        jsonb default '[]'::jsonb,
  p_signatur_vertrag    text  default null,
  p_signatur_sepa       text  default null,
  p_unterschrieben_am   date  default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vertrag vertraege%rowtype;
  v_fehlt   text;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'vertrag_abschliessen: nur Admin' using errcode = '42501';
  end if;

  select * into v_vertrag from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_abschliessen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_vertrag.status = 'abgeschlossen' then
    return;
  end if;
  if v_vertrag.status = 'abgelehnt' then
    raise exception 'vertrag_abschliessen: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;
  if v_vertrag.tier_id is null or v_vertrag.laufzeit_monate is null
     or v_vertrag.vertragsbeginn is null then
    raise exception 'vertrag_abschliessen: Paket, Laufzeit oder Vertragsbeginn fehlt'
      using errcode = 'P0001';
  end if;

  if p_weg = 'vor_ort' then
    if not exists (select 1 from vertrag_bankdaten where vertrag_id = p_vertrag_id) then
      raise exception 'vertrag_abschliessen: IBAN fehlt' using errcode = 'P0001';
    end if;
    if nullif(p_signatur_vertrag, '') is null or nullif(p_signatur_sepa, '') is null then
      raise exception 'vertrag_abschliessen: Unterschrift fehlt' using errcode = 'P0001';
    end if;

    select string_agg(d.schluessel, ', ') into v_fehlt
      from vertrag_dokumente d
     where d.aktiv and d.pflicht
       and not exists (
         select 1 from jsonb_array_elements(p_zustimmungen) z
          where z ->> 'schluessel' = d.schluessel and z ->> 'version' = d.version);
    if v_fehlt is not null then
      raise exception 'vertrag_abschliessen: Zustimmung fehlt fuer %', v_fehlt
        using errcode = 'P0001';
    end if;

    insert into vertrag_zustimmungen
      (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
    select p_vertrag_id, z ->> 'schluessel', z ->> 'version',
           coalesce((z ->> 'akzeptiert_at')::timestamptz, now()), auth.uid()
      from jsonb_array_elements(p_zustimmungen) z
    on conflict do nothing;

    insert into vertrag_unterschriften (vertrag_id, art, signatur) values
      (p_vertrag_id, 'vertrag',     p_signatur_vertrag),
      (p_vertrag_id, 'sepa_mandat', p_signatur_sepa)
    on conflict (vertrag_id, art) do nothing;
  elsif p_weg = 'papier' then
    if p_unterschrieben_am is null then
      raise exception 'vertrag_abschliessen: Abschlussdatum fehlt' using errcode = 'P0001';
    end if;
  else
    raise exception 'vertrag_abschliessen: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  perform set_config('edvance.vertrag_rpc', '1', true);
  update vertraege
     set status = 'abgeschlossen',
         abgeschlossen_at = now(),
         abschluss_weg = p_weg,
         unterschrieben_am = coalesce(p_unterschrieben_am,
                                      (now() at time zone 'Europe/Berlin')::date),
         glaeubiger_id = coalesce(glaeubiger_id,
           (select glaeubiger_id from vertrag_einstellungen))
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);
end;
$$;

-- "Doch abgelehnt": Vertrag und Lead gehen mit demselben Grund ins Archiv.
create or replace function public.vertrag_ablehnen(
  p_vertrag_id uuid,
  p_grund      text,
  p_notiz      text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vertrag vertraege%rowtype;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'vertrag_ablehnen: nur Admin' using errcode = '42501';
  end if;

  select * into v_vertrag from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_ablehnen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_vertrag.status = 'abgelehnt' then
    return;
  end if;
  if v_vertrag.status = 'abgeschlossen' then
    raise exception 'vertrag_ablehnen: Vertrag ist bereits abgeschlossen' using errcode = 'P0001';
  end if;

  perform set_config('edvance.vertrag_rpc', '1', true);
  update vertraege
     set status = 'abgelehnt', abgelehnt_at = now(),
         abgelehnt_grund = p_grund, abgelehnt_notiz = p_notiz
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);

  update leads
     set status = 'rejected', rejection_reason = p_grund, rejection_note = p_notiz
   where id = v_vertrag.lead_id;
end;
$$;

revoke execute on function public.vertrag_starten(uuid) from public;
revoke execute on function public.vertrag_versand_protokollieren(uuid, text, text, text) from public;
revoke execute on function public.vertrag_abschliessen(uuid, text, jsonb, text, text, date) from public;
revoke execute on function public.vertrag_ablehnen(uuid, text, text) from public;
revoke execute on function public.vertrag_bankdaten_maskieren() from public;
revoke execute on function public.vertraege_guard() from public;

grant execute on function public.vertrag_starten(uuid) to authenticated, service_role;
grant execute on function public.vertrag_versand_protokollieren(uuid, text, text, text) to authenticated, service_role;
grant execute on function public.vertrag_abschliessen(uuid, text, jsonb, text, text, date) to authenticated, service_role;
grant execute on function public.vertrag_ablehnen(uuid, text, text) to authenticated, service_role;
