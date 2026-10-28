-- Reihe 1 · D1 Anmeldung mit Zugangscode und Geräte (Bauauftrag D, docs/reihe1/D/ist-analyse.md §3).
--
-- Ein Kind meldet sich zuhause einmal je Gerät mit dem Zugangscode seines Vertrags an. Das Einlösen läuft über
-- die Edge Function geraet_anmelden (service_role): Sie ruft geraet_einloesen, meldet danach das EIGENE Konto
-- des Kindes an (kein anonymer Nutzer) und trägt die Auth-Session über geraet_session_setzen am Gerät ein.
--
--   kind_geraete          ein Gerät je Zeile; höchstens drei aktive je Kind; abmelden setzt abgemeldet_am
--   zugangscode_versuche  Protokoll jedes Einlöse-Versuchs ohne Klartext-Code (HMAC von Installation und IP),
--                         Löschfrist 30 Tage
--   geraet_einloesen      service_role: Code prüfen, Sperre (5 Fehlversuche je Installation oder IP in 15 Min.,
--                         systemweite Bremse), gültiger Code DIESES Vertrags, Geräteobergrenze; legt die Zeile an
--   geraet_session_setzen service_role: Auth-Session am Gerät eintragen (oder Abbruch); erst hier gibt dieselbe
--                         Installation ihr altes Gerät frei
--   geraet_status         das Kind selbst: aktiv | abgemeldet | kein_vertrag | ohne_geraet
--   geraet_abgemeldet     intern: Ist die aktuelle Session die eines abgemeldeten Geräts?
--   geraet_session        intern: Ist die aktuelle Session eine Gerätesitzung (zuhause)?
--   kind_geraete_liste, kind_geraet_abmelden, zugangscode_freischalten   nur Admin
--   (Neuer Code: Bestand vertrag_zugangscode_neu, unverändert.)
--
-- Abmelden löscht die Auth-Session; der Refresh scheitert sofort, die App prüft geraet_status beim Start und bei
-- der Rückkehr. Ein schon ausgestellter Access-Token gilt bis zu seinem Ablauf weiter, solange D1c (Freigabe
-- Rasit) nicht eingespielt ist. Geschwister auf demselben Tablet (gleiche Installation) lösen einander ab: Die
-- Anmeldung des einen meldet das andere Kind auf diesem Gerät ab (gewollt, eine Installation = ein Gerät). Rollback: supabase/rollback/20261027130748_reihe1_d1_geraete.sql.

create table public.kind_geraete (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.students(id) on delete cascade,
  vertrag_id        uuid references public.vertraege(id) on delete set null,
  name              text not null check (char_length(btrim(name)) between 1 and 60),
  plattform         text not null check (plattform in ('ios', 'android', 'web')),
  installation_hash text not null check (installation_hash ~ '^[0-9a-f]{64}$'),
  auth_session_id   uuid,
  angemeldet_am     timestamptz not null default now(),
  zuletzt_gesehen   timestamptz not null default now(),
  abgemeldet_am     timestamptz,
  abgemeldet_von    uuid references public.profiles(id) on delete set null,
  abmelde_grund     text check (abmelde_grund in ('admin', 'neu_angemeldet', 'abbruch', 'verwaist', 'selbst')),
  constraint kind_geraete_abmeldung_vollstaendig check ((abgemeldet_am is null) = (abmelde_grund is null))
);

create unique index kind_geraete_session_uniq on public.kind_geraete (auth_session_id) where auth_session_id is not null;
create index kind_geraete_aktiv_idx on public.kind_geraete (student_id) where abgemeldet_am is null;
create index kind_geraete_installation_idx on public.kind_geraete (installation_hash) where abgemeldet_am is null;

comment on table public.kind_geraete is
  'Geräte, auf denen ein Kind zuhause mit dem Zugangscode angemeldet ist (Reihe 1 · D1). Höchstens drei aktive je Kind.';
comment on column public.kind_geraete.installation_hash is
  'HMAC der Installations-ID der App (Hex). Dieselbe Installation meldet sich neu an statt ein weiteres Gerät zu belegen.';
comment on column public.kind_geraete.auth_session_id is
  'auth.sessions.id der Gerätesitzung (JWT-Claim session_id). null nur in den Sekunden zwischen Einlösen und Anmelden.';

alter table public.kind_geraete enable row level security;
create policy kind_geraete_admin_lesen on public.kind_geraete
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'admin');

create table public.zugangscode_versuche (
  id                bigint generated always as identity primary key,
  am                timestamptz not null default now(),
  installation_hash text not null check (installation_hash ~ '^[0-9a-f]{64}$'),
  ip_hash           text not null check (ip_hash ~ '^[0-9a-f]{64}$'),
  ergebnis          text not null check (ergebnis in ('ok', 'falsch', 'kein_vertrag', 'zu_viele_geraete', 'gesperrt')),
  vertrag_id        uuid references public.vertraege(id) on delete set null
);

create index zugangscode_versuche_installation_idx on public.zugangscode_versuche (installation_hash, am desc);
create index zugangscode_versuche_ip_idx on public.zugangscode_versuche (ip_hash, am desc);
create index zugangscode_versuche_am_idx on public.zugangscode_versuche (am);

comment on table public.zugangscode_versuche is
  'Jeder Einlöse-Versuch eines Zugangscodes, ohne Klartext-Code, IP nur als HMAC. falsch und kein_vertrag zählen für '
  'die Sperre. Zeilen älter als 30 Tage löscht geraet_einloesen.';

alter table public.zugangscode_versuche enable row level security;
create policy zugangscode_versuche_admin_lesen on public.zugangscode_versuche
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'admin');

comment on column public.vertraege.zugangscode is
  'Anzeigeform EDV-XXXX-XXXX. Acht Zeichen aus einem Alphabet ohne 0/O/1/I/L. Seit Reihe 1 · D1 Login-Mittel der '
  'Home-App: einlösbar über geraet_einloesen, solange vertraege_aktuell.zugangscode_gueltig.';

-- Code in die Anzeigeform bringen: Groß, ohne Leer- und Trennzeichen, Präfix EDV optional.
create function public.zugangscode_normalisieren(p_code text)
returns text
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
           when z ~ '^[A-Z0-9]{8}$' then 'EDV-' || substr(z, 1, 4) || '-' || substr(z, 5, 4)
         end
    from (select regexp_replace(regexp_replace(upper(coalesce(p_code, '')), '[^A-Z0-9]', '', 'g'), '^EDV(?=.{8}$)', '') as z) n;
$$;

comment on function public.zugangscode_normalisieren(text) is
  'Eingabe des Kindes → EDV-XXXX-XXXX oder null. Erlaubt Kleinbuchstaben, Leerzeichen, fehlende Bindestriche und fehlendes EDV.';

-- Auth-Session löschen (Refresh-Tokens hängen per on delete cascade daran). Ohne auth.sessions (Neuaufbau in CI) ein No-op.
create function public.geraet_auth_session_loeschen(p_session uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if p_session is null or to_regclass('auth.sessions') is null then
    return;
  end if;
  execute 'delete from auth.sessions where id = $1' using p_session;
end;
$$;

comment on function public.geraet_auth_session_loeschen(uuid) is
  'Intern und service_role: löscht die Auth-Session eines abgemeldeten oder gescheiterten Geräts.';

create function public.geraet_einloesen(
  p_code              text,
  p_name              text,
  p_plattform         text,
  p_installation_hash text,
  p_ip_hash           text
)
returns table (ergebnis text, warte_sek integer, student_id uuid, auth_user_id uuid, email text, geraet_id uuid)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  c_fenster    constant interval := interval '15 minutes';
  c_versuche   constant integer  := 5;
  c_geraete    constant integer  := 3;
  c_bremse     constant integer  := 2000;                -- Fehlversuche systemweit je Fenster (31^8 Codes: kein Treffer)
  c_offen_max  constant interval := interval '2 minutes'; -- so lange darf eine Zeile ohne Session offen sein
  v_code       text := public.zugangscode_normalisieren(p_code);
  v_sperre_bis timestamptz;
  v_vertrag    record;
  v_aktiv      integer;
  v_geraet     uuid;
  v_profil     uuid;
  v_email      text;
begin
  if p_installation_hash is null or p_installation_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'geraet_einloesen: installation_hash fehlt' using errcode = '22023';
  end if;
  if p_ip_hash is null or p_ip_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'geraet_einloesen: ip_hash fehlt' using errcode = '22023';
  end if;
  if p_plattform is null or p_plattform not in ('ios', 'android', 'web') then
    raise exception 'geraet_einloesen: plattform ungültig' using errcode = '22023';
  end if;

  -- Sperren immer in dieser Reihenfolge: IP, dann Installation, dann (unten) Kind.
  perform pg_advisory_xact_lock(hashtext('geraet_einloesen:ip:' || p_ip_hash));
  perform pg_advisory_xact_lock(hashtext('geraet_einloesen:inst:' || p_installation_hash));

  -- Löschfrist 30 Tage.
  delete from public.zugangscode_versuche z where z.am < now() - interval '30 days';

  -- Sperre: der fünftjüngste Fehlversuch der letzten 15 Minuten (je Installation oder je IP) plus 15 Minuten.
  select max(bis) into v_sperre_bis from (
    select (array_agg(z.am order by z.am desc))[c_versuche] + c_fenster as bis
      from public.zugangscode_versuche z
     where z.installation_hash = p_installation_hash and z.am > now() - c_fenster
       and z.ergebnis in ('falsch', 'kein_vertrag')
    union all
    select (array_agg(z.am order by z.am desc))[c_versuche] + c_fenster
      from public.zugangscode_versuche z
     where z.ip_hash = p_ip_hash and z.am > now() - c_fenster
       and z.ergebnis in ('falsch', 'kein_vertrag')
    union all
    -- Systemweite Bremse gegen verteiltes Raten: dann eine Minute Pause für alle.
    select now() + interval '1 minute'
     where (select count(*) from public.zugangscode_versuche z
             where z.am > now() - c_fenster and z.ergebnis in ('falsch', 'kein_vertrag')) >= c_bremse
  ) s;
  if v_sperre_bis is not null and v_sperre_bis > now() then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis)
    values (p_installation_hash, p_ip_hash, 'gesperrt');
    ergebnis := 'gesperrt'; warte_sek := ceil(extract(epoch from v_sperre_bis - now()))::integer;
    return next; return;
  end if;

  -- Gültig ist der Code genau dieses Vertrags (nicht irgendein laufender Vertrag des Kindes).
  select a.id, a.student_id, a.zugangscode_gueltig into v_vertrag
    from public.vertraege_aktuell a
   where v_code is not null and a.zugangscode = v_code;
  if not found then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis)
    values (p_installation_hash, p_ip_hash, 'falsch');
    ergebnis := 'falsch'; return next; return;
  end if;

  if not coalesce(v_vertrag.zugangscode_gueltig, false) or v_vertrag.student_id is null then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis, vertrag_id)
    values (p_installation_hash, p_ip_hash, 'kein_vertrag', v_vertrag.id);
    ergebnis := 'kein_vertrag'; return next; return;
  end if;

  select s.profile_id, u.email into v_profil, v_email
    from public.students s left join auth.users u on u.id = s.profile_id
   where s.id = v_vertrag.student_id;
  if v_profil is null or v_email is null then
    -- Datenfehler (Kind ohne Konto), kein Fehlversuch: Die Edge Function antwortet mit 500.
    raise exception 'geraet_einloesen: Kind ohne Auth-Konto' using errcode = '55000';
  end if;

  -- Geräte eines Kindes nacheinander zählen, nie parallel.
  perform pg_advisory_xact_lock(hashtext('kind_geraete:' || v_vertrag.student_id::text));

  -- Zeilen, deren Anmeldung nie fertig wurde (Function abgebrochen), geben ihren Platz frei.
  update public.kind_geraete g set abgemeldet_am = now(), abmelde_grund = 'abbruch'
   where g.student_id = v_vertrag.student_id and g.abgemeldet_am is null and g.auth_session_id is null
     and g.angemeldet_am < now() - c_offen_max;

  -- Zeilen, deren Auth-Session es nicht mehr gibt (abgelaufen, gelöscht, App neu installiert), geben ihren Platz frei.
  if to_regclass('auth.sessions') is not null then
    execute 'update public.kind_geraete g set abgemeldet_am = now(), abmelde_grund = ''verwaist''
              where g.student_id = $1 and g.abgemeldet_am is null and g.auth_session_id is not null
                and not exists (select 1 from auth.sessions s where s.id = g.auth_session_id)'
      using v_vertrag.student_id;
  end if;

  -- Dieselbe Installation zählt nicht mit: Sie ersetzt ihr altes Gerät (in geraet_session_setzen).
  select count(*) into v_aktiv from public.kind_geraete g
   where g.student_id = v_vertrag.student_id and g.abgemeldet_am is null
     and g.installation_hash <> p_installation_hash;
  if v_aktiv >= c_geraete then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis, vertrag_id)
    values (p_installation_hash, p_ip_hash, 'zu_viele_geraete', v_vertrag.id);
    ergebnis := 'zu_viele_geraete'; return next; return;
  end if;

  insert into public.kind_geraete (student_id, vertrag_id, name, plattform, installation_hash)
  values (v_vertrag.student_id, v_vertrag.id, left(btrim(coalesce(nullif(btrim(p_name), ''), p_plattform)), 60),
          p_plattform, p_installation_hash)
  returning id into v_geraet;
  insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis, vertrag_id)
  values (p_installation_hash, p_ip_hash, 'ok', v_vertrag.id);

  ergebnis := 'ok'; student_id := v_vertrag.student_id; auth_user_id := v_profil; email := v_email; geraet_id := v_geraet;
  return next;
end;
$$;

comment on function public.geraet_einloesen(text, text, text, text, text) is
  'Nur service_role (Edge Function geraet_anmelden). Löst einen Zugangscode für ein Gerät ein. reihe1 fertig';

create function public.geraet_session_setzen(p_geraet uuid, p_session uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_installation text;
  v_alt          record;
begin
  if p_session is null then
    update public.kind_geraete set abgemeldet_am = now(), abmelde_grund = 'abbruch'
     where id = p_geraet and abgemeldet_am is null and auth_session_id is null;
    return;
  end if;
  update public.kind_geraete set auth_session_id = p_session
   where id = p_geraet and abgemeldet_am is null and auth_session_id is null
  returning installation_hash into v_installation;
  if not found then
    raise exception 'geraet_session_setzen: Gerät nicht offen' using errcode = '55000';
  end if;
  -- Erst jetzt, mit neuer Session, gibt dieselbe Installation ihr altes Gerät frei (für jedes Kind).
  for v_alt in
    select g.id, g.auth_session_id from public.kind_geraete g
     where g.installation_hash = v_installation and g.id <> p_geraet and g.abgemeldet_am is null
  loop
    update public.kind_geraete set abgemeldet_am = now(), abmelde_grund = 'neu_angemeldet' where id = v_alt.id;
    perform public.geraet_auth_session_loeschen(v_alt.auth_session_id);
  end loop;
end;
$$;

comment on function public.geraet_session_setzen(uuid, uuid) is
  'Nur service_role: trägt die Auth-Session am frisch eingelösten Gerät ein; null heißt Abbruch. reihe1 fertig';

-- Session-ID des Aufrufers aus dem JWT, sonst null. Reines SQL ohne Exception-Block (läuft in get_my_student_id, D1c).
create function public.geraet_jwt_session()
returns uuid
language sql
stable
set search_path = public, pg_temp
as $$
  select case when s ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then s::uuid end
    from (select auth.jwt() ->> 'session_id' as s) j;
$$;

comment on function public.geraet_jwt_session() is 'Intern: session_id aus dem JWT des Aufrufers oder null.';

-- Ist die aktuelle Session die eines abgemeldeten Geräts? Sessions ohne Gerätezeile (Passwort-Login) gelten nicht als abgemeldet.
create function public.geraet_abgemeldet()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.kind_geraete g
     where g.auth_session_id = public.geraet_jwt_session() and g.abgemeldet_am is not null
  );
$$;

comment on function public.geraet_abgemeldet() is 'Intern: true, wenn die Session des Aufrufers einem abgemeldeten Gerät gehört. reihe1 fertig';

-- Ist die aktuelle Session eine Gerätesitzung (zuhause)? Gilt auch für abgemeldete Geräte.
create function public.geraet_session()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.kind_geraete g where g.auth_session_id = public.geraet_jwt_session());
$$;

comment on function public.geraet_session() is 'Intern: true, wenn der Aufrufer über ein Gerät zuhause angemeldet ist. reihe1 fertig';

create function public.geraet_status()
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind    uuid := public.get_my_student_id();
  v_session uuid := public.geraet_jwt_session();
  v_geraet  public.kind_geraete%rowtype;
begin
  -- Ohne Kinderkonto (oder abgemeldet, sobald D1c gilt) ist das Gerät für die App abgemeldet.
  if v_kind is null then
    if public.geraet_abgemeldet() then
      return 'abgemeldet';
    end if;
    raise exception 'geraet_status: nur für ein Kinderkonto' using errcode = '42501';
  end if;
  select g.* into v_geraet from public.kind_geraete g where v_session is not null and g.auth_session_id = v_session;
  if not found then
    return 'ohne_geraet';
  end if;
  if v_geraet.student_id is distinct from v_kind or v_geraet.abgemeldet_am is not null then
    return 'abgemeldet';
  end if;
  if not public.hat_zugang(v_kind) then
    return 'kein_vertrag';
  end if;
  update public.kind_geraete set zuletzt_gesehen = now()
   where id = v_geraet.id and zuletzt_gesehen < now() - interval '5 minutes';
  return 'aktiv';
end;
$$;

comment on function public.geraet_status() is
  'Das Kind selbst: aktiv | abgemeldet | kein_vertrag | ohne_geraet (Passwort-Session). Merkt zuletzt_gesehen. reihe1 fertig';

-- Das Kind meldet das eigene Gerät ab (Abmelden in der App); danach löscht die App die Session lokal.
create function public.geraet_abmelden_selbst()
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_session uuid := public.geraet_jwt_session();
begin
  update public.kind_geraete set abgemeldet_am = now(), abmelde_grund = 'selbst'
   where v_session is not null and auth_session_id = v_session and abgemeldet_am is null;
  perform public.geraet_auth_session_loeschen(case when found then v_session end);
end;
$$;

comment on function public.geraet_abmelden_selbst() is 'Das Kind: meldet das eigene Gerät ab und löscht dessen Auth-Session. reihe1 fertig';

create function public.kind_geraete_liste(p_student uuid)
returns table (id uuid, name text, plattform text, angemeldet_am timestamptz, zuletzt_gesehen timestamptz,
               abgemeldet_am timestamptz, abmelde_grund text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'kind_geraete_liste: nur Admin' using errcode = '42501';
  end if;
  -- Offene Zeilen ohne Session (laufende Anmeldung) zählen nicht als Gerät.
  return query
    select g.id, g.name, g.plattform, g.angemeldet_am, g.zuletzt_gesehen, g.abgemeldet_am, g.abmelde_grund
      from public.kind_geraete g
     where g.student_id = p_student and g.auth_session_id is not null
     order by (g.abgemeldet_am is null) desc, g.angemeldet_am desc;
end;
$$;

comment on function public.kind_geraete_liste(uuid) is 'Admin: Geräte eines Kindes (Schülerakte), aktive zuerst. reihe1 fertig';

create function public.kind_geraet_abmelden(p_geraet uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_session uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'kind_geraet_abmelden: nur Admin' using errcode = '42501';
  end if;
  update public.kind_geraete set abgemeldet_am = now(), abgemeldet_von = auth.uid(), abmelde_grund = 'admin'
   where id = p_geraet and abgemeldet_am is null
  returning auth_session_id into v_session;
  if not found then
    raise exception 'kind_geraet_abmelden: Gerät nicht angemeldet' using errcode = '55000';
  end if;
  perform public.geraet_auth_session_loeschen(v_session);
end;
$$;

comment on function public.kind_geraet_abmelden(uuid) is 'Admin: meldet ein Gerät ab und löscht seine Auth-Session. reihe1 fertig';

create function public.zugangscode_freischalten(p_vertrag uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'zugangscode_freischalten: nur Admin' using errcode = '42501';
  end if;
  select a.wirksamer_status into v_status from public.vertraege_aktuell a
   where a.id = p_vertrag and a.zugangscode is not null and a.zugangscode_gesperrt_am is not null;
  if not found then
    raise exception 'zugangscode_freischalten: Code ist nicht gesperrt' using errcode = '55000';
  end if;
  -- Nur der eigene Vertrag zählt, nicht ein anderer laufender Vertrag des Kindes.
  if v_status is null or v_status not in ('im_widerruf', 'aktiv') then
    raise exception 'zugangscode_freischalten: Vertrag läuft nicht' using errcode = '55000';
  end if;
  update public.vertraege set zugangscode_gesperrt_am = null where id = p_vertrag;
end;
$$;

comment on function public.zugangscode_freischalten(uuid) is
  'Admin: hebt die Sperre eines Zugangscodes auf, nur wenn dieser Vertrag läuft. reihe1 fertig';

revoke all on function public.zugangscode_normalisieren(text) from public, anon;
revoke all on function public.geraet_einloesen(text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.geraet_session_setzen(uuid, uuid) from public, anon, authenticated;
revoke all on function public.geraet_auth_session_loeschen(uuid) from public, anon, authenticated;
revoke all on function public.geraet_jwt_session() from public, anon;
revoke all on function public.geraet_abgemeldet() from public, anon;
revoke all on function public.geraet_session() from public, anon;
revoke all on function public.geraet_status() from public, anon;
revoke all on function public.geraet_abmelden_selbst() from public, anon;
revoke all on function public.kind_geraete_liste(uuid) from public, anon;
revoke all on function public.kind_geraet_abmelden(uuid) from public, anon;
revoke all on function public.zugangscode_freischalten(uuid) from public, anon;

grant execute on function public.geraet_einloesen(text, text, text, text, text) to service_role;
grant execute on function public.geraet_session_setzen(uuid, uuid) to service_role;
grant execute on function public.geraet_auth_session_loeschen(uuid) to service_role;
grant execute on function public.zugangscode_normalisieren(text) to authenticated, service_role;
grant execute on function public.geraet_jwt_session() to authenticated;
grant execute on function public.geraet_abgemeldet() to authenticated;
grant execute on function public.geraet_session() to authenticated;
grant execute on function public.geraet_status() to authenticated;
grant execute on function public.geraet_abmelden_selbst() to authenticated;
grant execute on function public.kind_geraete_liste(uuid) to authenticated;
grant execute on function public.kind_geraet_abmelden(uuid) to authenticated;
grant execute on function public.zugangscode_freischalten(uuid) to authenticated;

revoke all on table public.kind_geraete, public.zugangscode_versuche from anon;
revoke insert, update, delete, truncate on table public.kind_geraete, public.zugangscode_versuche from authenticated;
grant select on table public.kind_geraete, public.zugangscode_versuche to authenticated;
