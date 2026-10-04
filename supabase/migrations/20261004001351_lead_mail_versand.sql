-- lead_mail_versand — Protokoll der Mails an Eltern VOR dem Vertrag.
--
-- Erster Anlass: die Terminbestaetigung zum Erstgespraech (Edge Function
-- mail_senden, anlass 'terminbestaetigung'). vertrag_versand passt nicht: es
-- haengt an vertraege, und vor dem Erstgespraech gibt es keinen Vertrag.
--
-- Wie beim Vertrag wird JEDER Versuch festgehalten, auch der gescheiterte —
-- fehler null heisst zugestellt. termin_at haelt fest, WELCHER Termin in der
-- Mail stand: wird der Termin danach verschoben, sieht die Oberflaeche, dass
-- die letzte Bestaetigung einen alten Termin nennt.
--
-- Lesen: nur Admin (wie leads). Schreiben: nur ueber lead_mail_protokollieren.

create table public.lead_mail_versand (
  id          uuid primary key default gen_random_uuid(),
  lead_id     uuid not null references public.leads (id) on delete cascade,
  anlass      text not null check (anlass in ('terminbestaetigung')),
  empfaenger  text not null,
  termin_at   timestamptz,
  fehler      text,
  erfolgt_at  timestamptz not null default now(),
  erfolgt_von uuid references public.profiles (id) on delete set null
);

comment on table public.lead_mail_versand is
  'Mails an Eltern eines Leads (vor dem Vertrag), je Versuch eine Zeile — auch gescheiterte.';
comment on column public.lead_mail_versand.termin_at is
  'Der Termin, der in der Mail stand (UTC). Weicht er von leads.erstgespraech_at ab, ist die Bestaetigung veraltet.';
comment on column public.lead_mail_versand.fehler is
  'Null = zugestellt. Sonst die Meldung des Versands — die Zeile bleibt trotzdem stehen.';

create index lead_mail_versand_lead_idx on public.lead_mail_versand (lead_id, erfolgt_at desc);

alter table public.lead_mail_versand enable row level security;

create policy lead_mail_versand_admin_select on public.lead_mail_versand
  for select using (public.get_my_role() = 'admin');

-- ---------------------------------------------------------------------------
-- Einen Versandversuch festhalten — geglueckt oder nicht. Aufgerufen von der
-- Edge Function mit dem JWT des Admins, damit erfolgt_von stimmt.
-- ---------------------------------------------------------------------------
create function public.lead_mail_protokollieren(
  p_lead_id    uuid,
  p_anlass     text,
  p_empfaenger text,
  p_termin_at  timestamptz default null,
  p_fehler     text default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'lead_mail_protokollieren: nur Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from public.leads where id = p_lead_id) then
    raise exception 'lead_mail_protokollieren: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  insert into public.lead_mail_versand
    (lead_id, anlass, empfaenger, termin_at, fehler, erfolgt_von)
  values
    (p_lead_id, p_anlass, p_empfaenger, p_termin_at,
     nullif(btrim(coalesce(p_fehler, '')), ''), auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.lead_mail_protokollieren(uuid, text, text, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.lead_mail_protokollieren(uuid, text, text, timestamptz, text)
  to authenticated;
