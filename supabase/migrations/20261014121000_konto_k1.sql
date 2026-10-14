-- Konto K1: echte Konten fuer Mitarbeitende (Einladung per Mail, Passwort
-- aendern und zuruecksetzen, Auth-Mails ueber hello@).
--
-- Drei Teile, alle ohne Kopie von Auth-Daten in public:
--
--   1. mitarbeiter_konto_stand() — der Stand je Coach-/Admin-Konto fuer die
--      Coach-Liste (eingeladen am …, aktiv seit …). Liest auth.users direkt;
--      nur Admin, sonst 42501. Ohne Profil ist get_my_role() NULL, deshalb
--      coalesce (X0b).
--   2. konto_email_vorhanden(text) — fuer coach_einladen: gibt es die Adresse
--      schon in auth.users? inviteUserByEmail verschickt bei einem
--      unbestaetigten Konto mit derselben Adresse still eine neue Einladung,
--      statt abzulehnen. Ohne diese Vorpruefung koennte "neu" ein fremdes,
--      noch nicht angenommenes Konto (etwa Eltern) zum Coach machen.
--      Nur service_role.
--   3. auth_mail_versand + auth_mail_protokollieren — das Protokoll des Send
--      Email Hooks (Edge Function auth_mail). Je Versuch eine Zeile, auch die
--      gescheiterte. Kein Token, kein Link: nur Zeit, Art, Empfaenger, Fehler.

-- ---------------------------------------------------------------------------
-- 1. Stand der Mitarbeiterkonten
-- ---------------------------------------------------------------------------
create function public.mitarbeiter_konto_stand()
returns table (
  id                     uuid,
  eingeladen_at          timestamptz,
  bestaetigt_at          timestamptz,
  zuletzt_angemeldet_at  timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'mitarbeiter_konto_stand: nur Admin' using errcode = '42501';
  end if;

  return query
    select u.id, u.invited_at, u.email_confirmed_at, u.last_sign_in_at
      from auth.users u
      join public.profiles p on p.id = u.id
     where p.role in ('coach', 'admin');
end;
$$;

comment on function public.mitarbeiter_konto_stand() is
  'Stand je Coach-/Admin-Konto aus auth.users (eingeladen, bestaetigt, zuletzt angemeldet). Nur Admin.';

revoke all on function public.mitarbeiter_konto_stand() from public, anon, authenticated;
grant execute on function public.mitarbeiter_konto_stand() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Ist die Adresse schon vergeben? (nur coach_einladen, service_role)
-- ---------------------------------------------------------------------------
create function public.konto_email_vorhanden(p_email text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from auth.users u where lower(u.email) = lower(btrim(p_email))
  ) or exists (
    select 1 from public.profiles p where lower(p.email) = lower(btrim(p_email))
  );
$$;

comment on function public.konto_email_vorhanden(text) is
  'Gibt es ein Konto (auth.users oder profiles) mit dieser Adresse? Nur service_role (coach_einladen).';

revoke all on function public.konto_email_vorhanden(text) from public, anon, authenticated;
grant execute on function public.konto_email_vorhanden(text) to service_role;

-- ---------------------------------------------------------------------------
-- 3. Protokoll der Auth-Mails
-- ---------------------------------------------------------------------------
create table public.auth_mail_versand (
  id          uuid primary key default gen_random_uuid(),
  art         text not null check (art in (
                'invite', 'recovery', 'signup', 'email_change', 'reauthentication', 'magiclink', 'unbekannt'
              )),
  empfaenger  text not null,
  user_id     uuid,
  fehler      text,
  erfolgt_at  timestamptz not null default now()
);

comment on table public.auth_mail_versand is
  'Mails des Send Email Hooks (auth_mail), je Versuch eine Zeile — auch gescheiterte. Ohne Token und ohne Link.';
comment on column public.auth_mail_versand.user_id is
  'auth.users.id des Kontos. Bewusst ohne Fremdschluessel: das Protokoll bleibt, wenn das Konto geloescht wird.';
comment on column public.auth_mail_versand.fehler is
  'Null = an den Versand uebergeben. Sonst die Meldung — die Zeile bleibt trotzdem stehen.';

create index auth_mail_versand_zeit_idx on public.auth_mail_versand (erfolgt_at desc);

alter table public.auth_mail_versand enable row level security;
revoke all on table public.auth_mail_versand from anon, authenticated;
grant select on table public.auth_mail_versand to authenticated;

create policy auth_mail_versand_admin_select on public.auth_mail_versand
  for select using (coalesce(public.get_my_role(), '') = 'admin');

create function public.auth_mail_protokollieren(
  p_art        text,
  p_empfaenger text,
  p_user_id    uuid default null,
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
  insert into public.auth_mail_versand (art, empfaenger, user_id, fehler)
  values (p_art, p_empfaenger, p_user_id, nullif(btrim(coalesce(p_fehler, '')), ''))
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.auth_mail_protokollieren(text, text, uuid, text) is
  'Einen Versuch des Send Email Hooks festhalten. Nur service_role (Edge Function auth_mail).';

revoke all on function public.auth_mail_protokollieren(text, text, uuid, text) from public, anon, authenticated;
grant execute on function public.auth_mail_protokollieren(text, text, uuid, text) to service_role;
