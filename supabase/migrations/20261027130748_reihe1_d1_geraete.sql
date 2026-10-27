-- Reihe 1 · D1 Anmeldung mit Zugangscode und Geräte (Bauauftrag D, docs/reihe1/D/ist-analyse.md §3).
--
-- Ein Kind meldet sich zuhause einmal je Gerät mit dem Zugangscode seines Vertrags an. Das Einlösen läuft über
-- die Edge Function geraet_anmelden (service_role): Sie ruft geraet_einloesen, meldet danach das EIGENE Konto
-- des Kindes an (kein anonymer Nutzer) und trägt die Auth-Session über geraet_session_setzen am Gerät ein.
--
--   kind_geraete          ein Gerät je Zeile; höchstens drei aktive je Kind; abmelden setzt abgemeldet_am
--   zugangscode_versuche  Protokoll jedes Einlöse-Versuchs, ohne Klartext-Code (nur Hashes von Installation/IP)
--   geraet_einloesen      service_role: Code prüfen, Sperre (5 Fehlversuche je Installation oder IP in 15 Min.),
--                         laufender Vertrag (hat_zugang), Geräteobergrenze; legt die Gerätezeile an
--   geraet_session_setzen service_role: Auth-Session am Gerät eintragen (oder Abbruch)
--   geraet_status         das Kind selbst: aktiv | abgemeldet | kein_vertrag | ohne_geraet
--   geraet_abgemeldet     intern: Ist die aktuelle Session die eines abgemeldeten Geräts? (für D2-Funktionen)
--   kind_geraete_liste, kind_geraet_abmelden, zugangscode_neu, zugangscode_freischalten   nur Admin
--
-- Der Code allein gibt nach dem Einlösen keinen Zugriff: Er tauscht sich nur gegen eine Gerätesitzung.
-- Rollback: supabase/rollback/20261027130748_reihe1_d1_geraete.sql.

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
  abmelde_grund     text check (abmelde_grund in ('admin', 'neu_angemeldet', 'abbruch')),
  constraint kind_geraete_abmeldung_vollstaendig check ((abgemeldet_am is null) = (abmelde_grund is null))
);

create unique index kind_geraete_session_uniq on public.kind_geraete (auth_session_id) where auth_session_id is not null;
create index kind_geraete_aktiv_idx on public.kind_geraete (student_id) where abgemeldet_am is null;

comment on table public.kind_geraete is
  'Geräte, auf denen ein Kind zuhause mit dem Zugangscode angemeldet ist (Reihe 1 · D1). Höchstens drei aktive je Kind.';
comment on column public.kind_geraete.installation_hash is
  'sha256 der Installations-ID der App (Hex). Gleiche Installation meldet sich neu an statt ein viertes Gerät zu belegen.';
comment on column public.kind_geraete.auth_session_id is
  'auth.sessions.id der Gerätesitzung (JWT-Claim session_id). Beim Abmelden wird die Auth-Session gelöscht.';

alter table public.kind_geraete enable row level security;
create policy kind_geraete_admin_lesen on public.kind_geraete
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'admin');

create table public.zugangscode_versuche (
  id                bigint generated always as identity primary key,
  am                timestamptz not null default now(),
  installation_hash text not null check (installation_hash ~ '^[0-9a-f]{64}$'),
  ip_hash           text check (ip_hash ~ '^[0-9a-f]{64}$'),
  ergebnis          text not null check (ergebnis in ('ok', 'falsch', 'kein_vertrag', 'zu_viele_geraete', 'gesperrt')),
  vertrag_id        uuid references public.vertraege(id) on delete set null
);

create index zugangscode_versuche_installation_idx on public.zugangscode_versuche (installation_hash, am desc);
create index zugangscode_versuche_ip_idx on public.zugangscode_versuche (ip_hash, am desc) where ip_hash is not null;

comment on table public.zugangscode_versuche is
  'Jeder Einlöse-Versuch eines Zugangscodes, ohne Klartext-Code. falsch und kein_vertrag zählen für die Sperre.';

alter table public.zugangscode_versuche enable row level security;
create policy zugangscode_versuche_admin_lesen on public.zugangscode_versuche
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'admin');

comment on column public.vertraege.zugangscode is
  'Anzeigeform EDV-XXXX-XXXX. Acht Zeichen aus einem Alphabet ohne 0/O/1/I/L. Seit Reihe 1 · D1 Login-Mittel der '
  'Home-App: einlösbar über geraet_einloesen, solange nicht gesperrt und der Vertrag läuft.';

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

create function public.geraet_einloesen(
  p_code              text,
  p_name              text,
  p_plattform         text,
  p_installation_hash text,
  p_ip_hash           text default null
)
returns table (ergebnis text, warte_sek integer, student_id uuid, auth_user_id uuid, email text, geraet_id uuid)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  c_fenster   constant interval := interval '15 minutes';
  c_versuche  constant integer  := 5;
  c_geraete   constant integer  := 3;
  v_code      text := public.zugangscode_normalisieren(p_code);
  v_sperre_bis timestamptz;
  v_vertrag   public.vertraege%rowtype;
  v_aktiv     integer;
  v_alt       record;
  v_geraet    uuid;
begin
  if p_installation_hash is null or p_installation_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'geraet_einloesen: installation_hash fehlt' using errcode = '22023';
  end if;
  if p_ip_hash is not null and p_ip_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'geraet_einloesen: ip_hash ungültig' using errcode = '22023';
  end if;
  if p_plattform is null or p_plattform not in ('ios', 'android', 'web') then
    raise exception 'geraet_einloesen: plattform ungültig' using errcode = '22023';
  end if;

  -- Sperre: der fünftjüngste Fehlversuch der letzten 15 Minuten (je Installation oder je IP) plus 15 Minuten.
  perform pg_advisory_xact_lock(hashtext('geraet_einloesen:' || p_installation_hash));
  select max(bis) into v_sperre_bis from (
    select (array_agg(z.am order by z.am desc))[c_versuche] + c_fenster as bis
      from public.zugangscode_versuche z
     where z.installation_hash = p_installation_hash and z.am > now() - c_fenster
       and z.ergebnis in ('falsch', 'kein_vertrag')
    union all
    select (array_agg(z.am order by z.am desc))[c_versuche] + c_fenster
      from public.zugangscode_versuche z
     where p_ip_hash is not null and z.ip_hash = p_ip_hash and z.am > now() - c_fenster
       and z.ergebnis in ('falsch', 'kein_vertrag')
  ) s;
  if v_sperre_bis is not null and v_sperre_bis > now() then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis)
    values (p_installation_hash, p_ip_hash, 'gesperrt');
    ergebnis := 'gesperrt'; warte_sek := ceil(extract(epoch from v_sperre_bis - now()))::integer;
    return next; return;
  end if;

  select v.* into v_vertrag from public.vertraege v
   where v_code is not null and v.zugangscode = v_code and v.status = 'abgeschlossen';
  if not found then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis)
    values (p_installation_hash, p_ip_hash, 'falsch');
    ergebnis := 'falsch'; return next; return;
  end if;

  if v_vertrag.zugangscode_gesperrt_am is not null or v_vertrag.student_id is null
     or not public.hat_zugang(v_vertrag.student_id) then
    insert into public.zugangscode_versuche (installation_hash, ip_hash, ergebnis, vertrag_id)
    values (p_installation_hash, p_ip_hash, 'kein_vertrag', v_vertrag.id);
    ergebnis := 'kein_vertrag'; return next; return;
  end if;

  -- Geräte eines Kindes nacheinander zählen, nie parallel.
  perform pg_advisory_xact_lock(hashtext('kind_geraete:' || v_vertrag.student_id::text));

  -- Dieselbe Installation meldet sich neu an: das alte Gerät gibt seinen Platz frei.
  for v_alt in
    select g.id, g.auth_session_id from public.kind_geraete g
     where g.student_id = v_vertrag.student_id and g.installation_hash = p_installation_hash and g.abgemeldet_am is null
  loop
    update public.kind_geraete set abgemeldet_am = now(), abmelde_grund = 'neu_angemeldet' where id = v_alt.id;
    perform public.geraet_auth_session_loeschen(v_alt.auth_session_id);
  end loop;

  select count(*) into v_aktiv from public.kind_geraete g
   where g.student_id = v_vertrag.student_id and g.abgemeldet_am is null;
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

  select 'ok', null::integer, s.id, s.profile_id, u.email, v_geraet
    into ergebnis, warte_sek, student_id, auth_user_id, email, geraet_id
    from public.students s left join auth.users u on u.id = s.profile_id
   where s.id = v_vertrag.student_id;
  if auth_user_id is null or email is null then
    -- Kind ohne Konto: Gerät sofort wieder freigeben, das ist ein Datenfehler, kein Fehlversuch.
    update public.kind_geraete set abgemeldet_am = now(), abmelde_grund = 'abbruch' where id = v_geraet;
    raise exception 'geraet_einloesen: Kind ohne Auth-Konto' using errcode = '55000';
  end if;
  return next;
end;
$$;

comment on function public.geraet_einloesen(text, text, text, text, text) is
  'Nur service_role (Edge Function geraet_anmelden). Löst einen Zugangscode für ein Gerät ein. reihe1 fertig';

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

comment on function public.geraet_auth_session_loeschen(uuid) is 'Intern: löscht die Auth-Session eines abgemeldeten Geräts.';

create function public.geraet_session_setzen(p_geraet uuid, p_session uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if p_session is null then
    update public.kind_geraete set abgemeldet_am = now(), abmelde_grund = 'abbruch'
     where id = p_geraet and abgemeldet_am is null and auth_session_id is null;
    return;
  end if;
  update public.kind_geraete set auth_session_id = p_session
   where id = p_geraet and abgemeldet_am is null and auth_session_id is null;
  if not found then
    raise exception 'geraet_session_setzen: Gerät nicht offen' using errcode = '55000';
  end if;
end;
$$;

comment on function public.geraet_session_setzen(uuid, uuid) is
  'Nur service_role: trägt die Auth-Session am frisch eingelösten Gerät ein; null heißt Abbruch. reihe1 fertig';

-- Ist die aktuelle Session die eines abgemeldeten Geräts? Sessions ohne Gerätezeile (Passwort-Login) gelten nicht als abgemeldet.
create function public.geraet_abgemeldet()
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_session uuid;
begin
  begin
    v_session := nullif(auth.jwt() ->> 'session_id', '')::uuid;
  exception when invalid_text_representation then
    return false;
  end;
  return v_session is not null and exists (
    select 1 from public.kind_geraete g where g.auth_session_id = v_session and g.abgemeldet_am is not null
  );
end;
$$;

comment on function public.geraet_abgemeldet() is 'Intern: true, wenn die Session des Aufrufers einem abgemeldeten Gerät gehört. reihe1 fertig';

create function public.geraet_status()
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind    uuid := public.get_my_student_id();
  v_session uuid;
  v_geraet  public.kind_geraete%rowtype;
begin
  if v_kind is null then
    raise exception 'geraet_status: nur für ein Kinderkonto' using errcode = '42501';
  end if;
  begin
    v_session := nullif(auth.jwt() ->> 'session_id', '')::uuid;
  exception when invalid_text_representation then
    v_session := null;
  end;
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

create function public.zugangscode_neu(p_vertrag uuid)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_code text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'zugangscode_neu: nur Admin' using errcode = '42501';
  end if;
  v_code := public.zugangscode_erzeugen();
  update public.vertraege
     set zugangscode = v_code, zugangscode_erzeugt_am = (now() at time zone 'Europe/Berlin')::date
   where id = p_vertrag and status = 'abgeschlossen';
  if not found then
    raise exception 'zugangscode_neu: kein abgeschlossener Vertrag' using errcode = '55000';
  end if;
  return v_code;
end;
$$;

comment on function public.zugangscode_neu(uuid) is
  'Admin: neuer Zugangscode, der alte ist sofort ungültig. Angemeldete Geräte bleiben angemeldet. reihe1 fertig';

create function public.zugangscode_freischalten(p_vertrag uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_student uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'zugangscode_freischalten: nur Admin' using errcode = '42501';
  end if;
  select v.student_id into v_student from public.vertraege v
   where v.id = p_vertrag and v.zugangscode is not null and v.zugangscode_gesperrt_am is not null;
  if not found then
    raise exception 'zugangscode_freischalten: Code ist nicht gesperrt' using errcode = '55000';
  end if;
  if v_student is null or not public.hat_zugang(v_student) then
    raise exception 'zugangscode_freischalten: Vertrag läuft nicht' using errcode = '55000';
  end if;
  update public.vertraege set zugangscode_gesperrt_am = null where id = p_vertrag;
end;
$$;

comment on function public.zugangscode_freischalten(uuid) is
  'Admin: hebt die Sperre eines Zugangscodes auf, nur bei laufendem Vertrag. reihe1 fertig';

revoke all on function public.zugangscode_normalisieren(text) from public, anon;
revoke all on function public.geraet_einloesen(text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.geraet_session_setzen(uuid, uuid) from public, anon, authenticated;
revoke all on function public.geraet_auth_session_loeschen(uuid) from public, anon, authenticated;
revoke all on function public.geraet_abgemeldet() from public, anon;
revoke all on function public.geraet_status() from public, anon;
revoke all on function public.kind_geraete_liste(uuid) from public, anon;
revoke all on function public.kind_geraet_abmelden(uuid) from public, anon;
revoke all on function public.zugangscode_neu(uuid) from public, anon;
revoke all on function public.zugangscode_freischalten(uuid) from public, anon;

grant execute on function public.geraet_einloesen(text, text, text, text, text) to service_role;
grant execute on function public.geraet_session_setzen(uuid, uuid) to service_role;
grant execute on function public.zugangscode_normalisieren(text) to authenticated, service_role;
grant execute on function public.geraet_abgemeldet() to authenticated;
grant execute on function public.geraet_status() to authenticated;
grant execute on function public.kind_geraete_liste(uuid) to authenticated;
grant execute on function public.kind_geraet_abmelden(uuid) to authenticated;
grant execute on function public.zugangscode_neu(uuid) to authenticated;
grant execute on function public.zugangscode_freischalten(uuid) to authenticated;

revoke all on table public.kind_geraete, public.zugangscode_versuche from anon;
grant select on table public.kind_geraete, public.zugangscode_versuche to authenticated;
