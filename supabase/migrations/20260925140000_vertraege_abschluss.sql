-- Vertraege P2 — die Abschlussstrecke.
--
-- P1 hat die Spalten gebaut. Hier kommt der Vorgang dazu, der sie fuellt:
-- Unterlagen versenden, vor Ort unterschreiben, einen Ruecklauf einpflegen.
-- Alles drei endet in EINER RPC, damit es keinen halben Vertrag geben kann.
--
-- Drei Dinge, die hier zusammenlaufen und vorher auseinanderlagen:
--
-- 1. Der provisorische Schueler aus lead_lsa_freigeben wird UEBERNOMMEN, nicht
--    ein zweiter danebengestellt. Genau das tat der bisherige Weg ueber die
--    Edge Function: app_provision_student legte eine neue students-Zeile an,
--    waehrend die provisorische mit der ganzen LSA-Historie liegen blieb. Ab
--    hier bekommt dieselbe Zeile ihr Konto.
-- 2. lead_convert faellt weg. Sein einziger Zweck — den provisorischen
--    Schueler zu flippen — ist jetzt Teil des Abschlusses. Zwei Wege zum
--    selben Flip waeren zwei Wahrheiten.
-- 3. vertraege_guard laesst die vertrag_*-RPCs durch, statt sie zu umschiffen.
--    Vorher setzte jede RPC preis_cents und einheiten neu, weil der Guard sie
--    sonst ueberschrieb; jetzt ist die RPC die Autoritaet und der Guard
--    schuetzt nur noch den Weg am Formular vorbei.
--
-- Datumsarithmetik ausschliesslich ueber date. Vertragsende und Widerrufsfrist
-- kommen aus vertrag_ende_berechnen() / vertrag_widerruf_bis() — es gibt keine
-- zweite Rechnung, weder hier noch im Frontend.

begin;

-- ============================================================================
-- 1. Nachweis des Ruecklaufs
-- ============================================================================
--
-- Ohne Scan kein Abschluss auf dem Papierweg (Anforderung F.18). Der Pfad zeigt
-- in den privaten Bucket "vertraege" aus P1.

alter table public.vertraege add column scan_pfad text;

comment on column public.vertraege.scan_pfad is
  'Pfad des eingescannten, unterschriebenen Exemplars im Bucket "vertraege". Pflicht beim Papierweg.';

alter table public.vertraege
  add constraint vertraege_scan_bei_papier
    check (status <> 'abgeschlossen'
           or abschluss_weg is distinct from 'papier'
           or nullif(btrim(scan_pfad), '') is not null);

-- ============================================================================
-- 2. vertraege_guard — die RPCs duerfen durch
-- ============================================================================
--
-- Unveraendert bleibt der Zweck: Am Formular vorbei aendert niemand den Status
-- und niemand den Preis. Neu ist, dass vertrag_status genauso geschuetzt ist
-- wie status, und dass eine RPC (edvance.vertrag_rpc = '1') die Zeile setzen
-- darf, wie sie sie berechnet hat — sie ist die Stelle, die es weiss.

create or replace function public.vertraege_guard()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();

  -- Innerhalb einer vertrag_*-RPC gilt, was die RPC schreibt.
  if coalesce(current_setting('edvance.vertrag_rpc', true), '') = '1' then
    return new;
  end if;

  if new.status is distinct from old.status then
    raise exception 'vertraege: Status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;
  if new.vertrag_status is distinct from old.vertrag_status then
    raise exception 'vertraege: vertrag_status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
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

  return new;
end;
$$;

-- ============================================================================
-- 3. lead_convert faellt weg
-- ============================================================================
--
-- Belegt vor dem Loeschen (siehe PR): im Frontend nur ein Wrapper ohne
-- Aufrufer, in pg_proc kein Aufruf aus einer anderen Funktion. Die beiden
-- SQL-Prueflinge, die ihn benutzten, sind in diesem Commit mit umgestellt.

drop function if exists public.lead_convert(uuid);

-- Der Hinweistext des Abo-Guards zeigte auf lead_convert. Jetzt zeigt er auf
-- die Stelle, die den Flip wirklich macht.
create or replace function public.subscriptions_guard_provisional()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.students where id = new.student_id and is_provisional) then
    raise exception
      'student_subscriptions: provisorischer Schueler traegt kein Abo (erst der Vertragsabschluss)'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

-- ============================================================================
-- 4. vertrag_starten — Schule als Verweis
-- ============================================================================
--
-- Der Lead traegt die Schule als Freitext (leads.school_name). Findet sich der
-- Name in schulen, haengt der Antrag gleich am Datensatz; sonst bleibt
-- schule_id leer und Schritt 1 laesst den Admin waehlen oder anlegen.
-- schule (Freitext) wird weiter mitgefuehrt, damit die Druckansicht auch fuer
-- Altfaelle etwas anzuzeigen hat.

create or replace function public.vertrag_starten(p_lead_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_lead     leads%rowtype;
  v_id       uuid;
  v_schule   uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_starten: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from public.leads where id = p_lead_id for update;
  if not found then
    raise exception 'vertrag_starten: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  select id into v_id from public.vertraege
   where lead_id = p_lead_id and status <> 'abgelehnt';
  if v_id is not null then
    return v_id;   -- idempotent: der Knopf darf zweimal gedrueckt werden
  end if;

  if v_lead.status <> 'lsa_fertig' then
    raise exception 'vertrag_starten: Lead steht nicht auf "Analyse abgeschlossen"'
      using errcode = 'P0001';
  end if;

  select s.id into v_schule
    from public.schulen s
   where lower(s.name) = lower(btrim(coalesce(v_lead.school_name, '')))
   limit 1;

  insert into public.vertraege (
    created_by, lead_id, eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach, schule, schule_id
  ) values (
    auth.uid(), p_lead_id, v_lead.contact_phone, v_lead.contact_email,
    coalesce(v_lead.first_name, split_part(v_lead.full_name, ' ', 1)),
    nullif(regexp_replace(v_lead.full_name, '^\S+\s*', ''), ''),
    v_lead.birth_date, v_lead.class_level, v_lead.subjects[1], v_lead.school_name, v_schule
  )
  returning id into v_id;

  update public.leads set status = 'vertrag' where id = p_lead_id;
  return v_id;
end;
$$;

-- ============================================================================
-- 5. vertrag_versenden — Wege B und C
-- ============================================================================
--
-- Hier entsteht KEIN Vertrag: kein Konto, kein Zugangscode, kein vertrag_status.
-- Was entsteht, ist ein Beleg darueber, welche Fassungen im Buendel lagen.
-- Dass dieser Beleg in vertrag_zustimmungen liegt, ist Absicht und braucht
-- einen Satz: akzeptiert_at heisst auf dem Papierweg "lag bei", nicht
-- "zugestimmt". Zugestimmt wird auf dem Papier, und das kommt erst zurueck.
-- Ein Antrag, der drei Wochen unterwegs war, muss die Fassung belegen koennen,
-- die die Eltern in der Hand hatten — dafuer ist es da.

create or replace function public.vertrag_versenden(
  p_vertrag_id       uuid,
  p_weg              text,                      -- 'email' | 'druck'
  p_empfaenger       text default null,
  p_rueckmeldung_bis date default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v         vertraege%rowtype;
  v_bis     date;
  v_fehlt   text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_versenden: nur Admin' using errcode = '42501';
  end if;
  if p_weg not in ('email', 'druck') then
    raise exception 'vertrag_versenden: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versenden: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status = 'abgelehnt' then
    raise exception 'vertrag_versenden: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;
  if v.status = 'abgeschlossen' then
    raise exception 'vertrag_versenden: Vertrag ist bereits abgeschlossen' using errcode = 'P0001';
  end if;
  if v.tier_id is null or v.laufzeit_monate is null or v.vertragsbeginn is null then
    raise exception 'vertrag_versenden: Paket, Laufzeit oder Vertragsbeginn fehlt'
      using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.vertrag_bankdaten where vertrag_id = p_vertrag_id) then
    raise exception 'vertrag_versenden: IBAN fehlt' using errcode = 'P0001';
  end if;

  -- Fassungen festhalten: ALLE aktiven Dokumente, nicht nur die Pflichtstuecke.
  -- Rechtlich notwendig ist das Buendel, nicht die Auswahl daraus.
  insert into public.vertrag_zustimmungen
    (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
  select p_vertrag_id, d.schluessel, d.version, now(), auth.uid()
    from public.vertrag_dokumente d
   where d.aktiv
  on conflict (vertrag_id, dokument_schluessel, dokument_version) do nothing;

  insert into public.vertrag_versand (vertrag_id, weg, anlass, empfaenger, erfolgt_von)
  values (p_vertrag_id, p_weg, 'unterlagen', p_empfaenger, auth.uid());

  v_bis := coalesce(p_rueckmeldung_bis,
                    v.rueckmeldung_bis,
                    (now() at time zone 'Europe/Berlin')::date + 14);

  perform set_config('edvance.vertrag_rpc', '1', true);
  update public.vertraege
     set status = 'unterschrift_ausstehend',
         unterschrift_ausstehend_at = coalesce(unterschrift_ausstehend_at, now()),
         abschluss_weg   = 'papier',
         rueckmeldung_bis = v_bis,
         glaeubiger_id   = coalesce(glaeubiger_id,
                             (select glaeubiger_id from public.vertrag_einstellungen))
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);

  return jsonb_build_object('ok', true, 'rueckmeldung_bis', v_bis);
end;
$$;

comment on function public.vertrag_versenden(uuid, text, text, date) is
  'Weg B/C: Unterlagen raus, Fassungen festhalten, Antrag auf "unterschrift_ausstehend". Erzeugt KEINEN Vertrag.';

-- ============================================================================
-- 6. vertrag_abschliessen — der eine Weg zum Vertrag
-- ============================================================================
--
-- Zwei Eingaenge, ein Ausgang:
--   'vor_ort'  aus Schritt 4 der Strecke — Haekchen, Unterschrift, fertig.
--   'papier'   aus dem Einpflegen — Scan, Abgleich, zwei Daten.
--
-- Beide enden in derselben Zeile Arbeit, und zwar in EINER Transaktion:
-- Status, vertrag_status, eingefrorenes Ende, Widerrufsfrist, Zugangscode,
-- Schuelerkonto, Abo, Vorgaengerkette. Ein Vertrag mit Zugangscode, aber ohne
-- Konto waere schlimmer als gar keiner.
--
-- Das Auth-Konto selbst kann eine Datenbankfunktion nicht anlegen. Die Edge
-- Function vertrag_abschluss legt es vorher an, reicht die UID hier herein und
-- raeumt es wieder weg, wenn diese Funktion wirft — dasselbe Muster, das
-- provision_student schon benutzt.

drop function if exists public.vertrag_abschliessen(uuid, text, jsonb, text, text, date);

create or replace function public.vertrag_abschliessen(
  p_vertrag_id         uuid,
  p_weg                text,
  p_zustimmungen       jsonb   default '[]'::jsonb,
  p_signatur_vertrag   text    default null,
  p_signatur_sepa      text    default null,
  p_unterschrieben_am  date    default null,
  p_eingang_datum      date    default null,
  p_scan_pfad          text    default null,
  p_abweichung_vermerk text    default null,
  p_tier_id            uuid    default null,
  p_laufzeit_monate    integer default null,
  p_vertragsbeginn     date    default null,
  p_student_uid        uuid    default null,
  p_student_email      text    default null,
  p_parent_uid         uuid    default null,
  p_parent_email       text    default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v            vertraege%rowtype;
  v_heute      date := (now() at time zone 'Europe/Berlin')::date;
  v_tier       uuid;
  v_laufzeit   integer;
  v_beginn     date;
  v_preis      integer;
  v_einheiten  integer;
  v_ende       record;
  v_widerruf   date;
  v_code       text;
  v_student    uuid;
  v_vorgaenger uuid;
  v_fehlt      text;
  v_abweichung boolean;
  v_kindname   text;
  v_subject    uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_abschliessen: nur Admin' using errcode = '42501';
  end if;
  if p_weg not in ('vor_ort', 'papier') then
    raise exception 'vertrag_abschliessen: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_abschliessen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  -- Idempotent: ein zweiter Aufruf liefert dasselbe Ergebnis, ohne etwas zu tun.
  if v.status = 'abgeschlossen' then
    return jsonb_build_object(
      'ok', true, 'bereits_abgeschlossen', true,
      'student_id', v.student_id, 'zugangscode', v.zugangscode,
      'vertrag_ende', v.vertrag_ende, 'widerruf_bis', v.widerruf_bis,
      'ferientage', v.ferientage);
  end if;
  if v.status = 'abgelehnt' then
    raise exception 'vertrag_abschliessen: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  -- -------------------------------------------------------- Konditionen
  -- Auf dem Papierweg gilt, was unterschrieben wurde, nicht was versendet war.
  v_tier     := coalesce(p_tier_id,         v.tier_id);
  v_laufzeit := coalesce(p_laufzeit_monate, v.laufzeit_monate);
  v_beginn   := coalesce(p_vertragsbeginn,  v.vertragsbeginn);

  if v_tier is null or v_laufzeit is null or v_beginn is null then
    raise exception 'vertrag_abschliessen: Paket, Laufzeit oder Vertragsbeginn fehlt'
      using errcode = 'P0001';
  end if;

  select tl.preis_cents, tl.einheiten into v_preis, v_einheiten
    from public.tier_laufzeiten tl
   where tl.tier_id = v_tier and tl.laufzeit_monate = v_laufzeit;
  if v_preis is null then
    raise exception 'vertrag_abschliessen: kein Tarif fuer Paket und Laufzeit %', v_laufzeit
      using errcode = 'P0001';
  end if;

  -- -------------------------------------------------------- Weg A: vor Ort
  if p_weg = 'vor_ort' then
    if v.status <> 'in_vorbereitung' then
      raise exception 'vertrag_abschliessen: vor Ort geht nur aus der Vorbereitung (status=%)', v.status
        using errcode = 'P0001';
    end if;
    if not exists (select 1 from public.vertrag_bankdaten where vertrag_id = p_vertrag_id) then
      raise exception 'vertrag_abschliessen: IBAN fehlt' using errcode = 'P0001';
    end if;
    if nullif(p_signatur_vertrag, '') is null or nullif(p_signatur_sepa, '') is null then
      raise exception 'vertrag_abschliessen: Unterschrift fehlt' using errcode = 'P0001';
    end if;

    select string_agg(d.schluessel, ', ') into v_fehlt
      from public.vertrag_dokumente d
     where d.aktiv and d.pflicht
       and not exists (
         select 1 from jsonb_array_elements(p_zustimmungen) z
          where z ->> 'schluessel' = d.schluessel and z ->> 'version' = d.version);
    if v_fehlt is not null then
      raise exception 'vertrag_abschliessen: Zustimmung fehlt fuer %', v_fehlt
        using errcode = 'P0001';
    end if;

    insert into public.vertrag_zustimmungen
      (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
    select p_vertrag_id, z ->> 'schluessel', z ->> 'version',
           coalesce((z ->> 'akzeptiert_at')::timestamptz, now()), auth.uid()
      from jsonb_array_elements(p_zustimmungen) z
    on conflict (vertrag_id, dokument_schluessel, dokument_version) do nothing;

    insert into public.vertrag_unterschriften (vertrag_id, art, signatur) values
      (p_vertrag_id, 'vertrag',     p_signatur_vertrag),
      (p_vertrag_id, 'sepa_mandat', p_signatur_sepa)
    on conflict (vertrag_id, art) do nothing;

    p_unterschrieben_am := v_heute;
    v_abweichung := false;

  -- -------------------------------------------------------- Weg B/C: Papier
  else
    if v.status <> 'unterschrift_ausstehend' then
      raise exception 'vertrag_abschliessen: Einpflegen geht nur bei versendeten Unterlagen (status=%)', v.status
        using errcode = 'P0001';
    end if;
    if nullif(btrim(coalesce(p_scan_pfad, '')), '') is null then
      raise exception 'vertrag_abschliessen: ohne hochgeladenen Scan kein Abschluss'
        using errcode = 'P0001';
    end if;
    if p_unterschrieben_am is null or p_eingang_datum is null then
      raise exception 'vertrag_abschliessen: Unterschriftsdatum und Eingangsdatum sind Pflicht'
        using errcode = 'P0001';
    end if;

    -- Abgleich Soll/Ist. Weicht etwas ab, ist der Vermerk Pflicht — es gilt das
    -- Papier, der Vermerk haelt fest, was die Eltern geaendert haben.
    v_abweichung := (v_tier     is distinct from v.tier_id)
                 or (v_laufzeit is distinct from v.laufzeit_monate)
                 or (v_beginn   is distinct from v.vertragsbeginn);
    if v_abweichung and nullif(btrim(coalesce(p_abweichung_vermerk, '')), '') is null then
      raise exception 'vertrag_abschliessen: Abweichung zum versendeten Stand braucht einen Vermerk'
        using errcode = 'P0001';
    end if;
  end if;

  -- -------------------------------------------------------- Ende und Frist
  -- Einzige Quelle. Wirft, wenn die Rechnung ueber ferien_nrw hinauslaeuft.
  select * into v_ende from public.vertrag_ende_berechnen(v_beginn, v_laufzeit);
  v_widerruf := public.vertrag_widerruf_bis(v_beginn);

  -- -------------------------------------------------------- Schuelerkonto
  if v.student_id is not null then
    -- Folgevertrag: das Kind gibt es schon, es bekommt kein zweites Konto.
    v_student := v.student_id;

    select id into v_vorgaenger
      from public.vertraege
     where student_id = v_student
       and id <> p_vertrag_id
       and vertrag_status is not null
     order by vertrag_ende desc nulls last, abgeschlossen_am desc nulls last
     limit 1;
  else
    v_kindname := nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '');

    -- Der provisorische Schueler aus lead_lsa_freigeben traegt die LSA-Historie.
    select id into v_student from public.students where lead_id = v.lead_id;

    if p_student_uid is null then
      raise exception 'vertrag_abschliessen: p_student_uid fehlt — das Auth-Konto legt die Edge Function an'
        using errcode = '22023';
    end if;

    insert into public.profiles (id, email, role, full_name)
    values (p_student_uid, p_student_email, 'student', v_kindname)
    on conflict (id) do update
      set email = excluded.email, role = 'student', full_name = excluded.full_name;

    if p_parent_uid is not null then
      insert into public.profiles (id, email, role, full_name)
      values (p_parent_uid, p_parent_email, 'parent', null)
      on conflict (id) do update set email = excluded.email, role = 'parent';
      insert into public.parent_student (parent_id, student_id)
      values (p_parent_uid, p_student_uid)
      on conflict do nothing;
    end if;

    if v_student is null then
      -- Kein Lead-Schueler (Antrag ohne LSA): neue Zeile wie bisher.
      insert into public.students (profile_id, class_level, school_name)
      values (p_student_uid, v.klasse, v.schule)
      returning id into v_student;
    else
      -- Uebernahme: dieselbe Zeile, jetzt mit Konto. lead_id wird genullt,
      -- damit eine spaetere Lead-Loeschung den Schueler nicht mitreisst.
      update public.students
         set profile_id     = p_student_uid,
             is_provisional = false,
             lead_id        = null,
             class_level    = coalesce(v.klasse, class_level),
             school_name    = coalesce(v.schule, school_name)
       where id = v_student;
    end if;

    if v.fach is not null then
      select id into v_subject from public.subjects where name = v.fach;
      if v_subject is not null
         and not exists (select 1 from public.student_subjects
                          where student_id = v_student and subject_id = v_subject) then
        insert into public.student_subjects (student_id, subject_id) values (v_student, v_subject);
      end if;
    end if;

    update public.leads
       set status = 'converted', converted_student_id = v_student
     where id = v.lead_id;
  end if;

  -- Abo: eins je laufendem Vertrag. Der Guard verlangt, dass der Schueler
  -- vorher nicht mehr provisorisch ist — deshalb steht es hier unten.
  if not exists (select 1 from public.student_subscriptions
                  where student_id = v_student and tier_id = v_tier and status = 'active') then
    insert into public.student_subscriptions (student_id, tier_id) values (v_student, v_tier);
  end if;

  -- -------------------------------------------------------- Zugangscode
  v_code := coalesce(v.zugangscode, public.zugangscode_erzeugen());

  -- -------------------------------------------------------- Der Vertrag
  perform set_config('edvance.vertrag_rpc', '1', true);

  update public.vertraege
     set status                 = 'abgeschlossen',
         vertrag_status         = 'im_widerruf',
         abgeschlossen_at       = now(),
         abgeschlossen_am       = coalesce(p_unterschrieben_am, v_heute),
         abschluss_weg          = p_weg,
         unterschrieben_am      = p_unterschrieben_am,
         eingang_datum          = p_eingang_datum,
         scan_pfad              = coalesce(p_scan_pfad, scan_pfad),
         abweichung_vermerk     = coalesce(nullif(btrim(coalesce(p_abweichung_vermerk, '')), ''),
                                           abweichung_vermerk),
         tier_id                = v_tier,
         laufzeit_monate        = v_laufzeit,
         vertragsbeginn         = v_beginn,
         preis_cents            = v_preis,
         einheiten              = v_einheiten,
         vertrag_ende           = v_ende.ende,
         ferientage             = v_ende.ferientage,
         widerruf_bis           = v_widerruf,
         zugangscode            = v_code,
         zugangscode_erzeugt_am = coalesce(zugangscode_erzeugt_am, v_heute),
         student_id             = v_student,
         vorgaenger_id          = coalesce(vorgaenger_id, v_vorgaenger),
         glaeubiger_id          = coalesce(glaeubiger_id,
                                    (select glaeubiger_id from public.vertrag_einstellungen))
   where id = p_vertrag_id;

  -- Der Vorgaenger ist verlaengert. Er bleibt stehen — er ist die Historie.
  if v_vorgaenger is not null then
    update public.vertraege
       set verlaengerung_status = 'verlaengert'
     where id = v_vorgaenger;
  end if;

  perform set_config('edvance.vertrag_rpc', '', true);

  return jsonb_build_object(
    'ok', true,
    'student_id',   v_student,
    'zugangscode',  v_code,
    'vertrag_ende', v_ende.ende,
    'ferientage',   v_ende.ferientage,
    'ferien',       to_jsonb(v_ende.ferien),
    'widerruf_bis', v_widerruf,
    'abweichung',   coalesce(v_abweichung, false));
end;
$$;

comment on function public.vertrag_abschliessen(uuid, text, jsonb, text, text, date, date, text, text, uuid, integer, date, uuid, text, uuid, text) is
  'Der einzige Weg zu einem Vertrag. Atomar: Status, eingefrorenes Ende, Widerrufsfrist, Zugangscode, Schuelerkonto, Abo, Vorgaengerkette.';

-- ============================================================================
-- 7. Rechte
-- ============================================================================
--
-- Supabase vergibt EXECUTE per Default Privileges direkt an anon und
-- authenticated; "from public" allein entzieht das nicht (siehe P1).

revoke all on function public.vertrag_versenden(uuid, text, text, date)
  from public, anon, authenticated;
grant execute on function public.vertrag_versenden(uuid, text, text, date)
  to authenticated;

revoke all on function public.vertrag_abschliessen(uuid, text, jsonb, text, text, date, date, text, text, uuid, integer, date, uuid, text, uuid, text)
  from public, anon, authenticated;
grant execute on function public.vertrag_abschliessen(uuid, text, jsonb, text, text, date, date, text, text, uuid, integer, date, uuid, text, uuid, text)
  to authenticated, service_role;

revoke all on function public.vertrag_starten(uuid) from public, anon, authenticated;
grant execute on function public.vertrag_starten(uuid) to authenticated;

commit;
