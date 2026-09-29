-- Schuelerakte S1, Teil 2 von 3: Akte, Einheiten-Stand, Notizen, Reports.
--
-- Bauauftrag Schuelerakte (Fassung 2), Paket S1, Lieferumfang A.2. Setzt
-- 20260929100000_schuelerakte_basis.sql voraus. Nummern "Entscheidung n"
-- verweisen auf docs/schuelerakte/entscheidungen.md.
--
-- Inhalt:
--   1. akte_aktiv                      — Zustand, abgeleitet (Entscheidung 2)
--   2. akte_basis + View schuelerakten — die Akte = students-Zeile (Entscheidung 1)
--   3. einheiten_rechnung              — reine Rechnung (Lieferumfang A)
--   4. einheiten_stand                 — laufender Vertrag + Rechnung (Entscheidung 3)
--   5. board_schueler                  — alle sichtbaren Akten in EINER Abfrage
--   6. schueler_notizen + vier RPCs    — nur anhaengen (Entscheidung 8, 9)
--   7. eltern_reports + eltern_report_eintragen (Entscheidung 10)
--   8. vertrag_abschliessen            — Report 1, Faecher, Schule (Entscheidung 10, 11)
--
-- Sicherheit: Alles, was ein Coach sehen darf, laeuft ueber SECURITY-DEFINER-
-- Funktionen mit Rollenpruefung. Der Coach liest vertraege nicht (auch nicht
-- ueber vertraege_aktuell, die security_invoker ist) — Einheiten und Stichtag
-- erreichen ihn nur ueber einheiten_stand / board_schueler.

begin;

-- ============================================================================
-- 1. akte_aktiv (Entscheidung 2)
-- ============================================================================
--
-- aktiv, wenn das Kind einen Vertrag mit wirksamer_status in (aktiv,
-- im_widerruf) hat — auch mit Beginn in der Zukunft. Sonst ruhend. Der Status
-- kommt ausschliesslich aus vertraege_aktuell.wirksamer_status.
--
-- Abweichung zu hat_zugang (gemeldet, nicht angeglichen): hat_zugang gibt in
-- der Luecke vor einem Folgevertrag auch dann Zugang, wenn der Folgevertrag
-- widerrufen ist — es prueft dessen Status nicht. akte_aktiv sagt dort ruhend.

create or replace function public.akte_aktiv(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.vertraege_aktuell v
     where v.student_id = p_student_id
       and v.wirksamer_status in ('aktiv', 'im_widerruf')
  );
$$;

comment on function public.akte_aktiv(uuid) is
  'true, wenn das Kind einen Vertrag mit wirksamer_status aktiv oder im_widerruf hat (auch mit Beginn in der Zukunft). Grundlage der Coach-Sicht.';

revoke all on function public.akte_aktiv(uuid) from public, anon, authenticated;
grant execute on function public.akte_aktiv(uuid) to authenticated;

-- ============================================================================
-- 2. akte_basis + View schuelerakten (Entscheidung 1, 2)
-- ============================================================================
--
-- Eine Akte ist eine students-Zeile mit mindestens einem abgeschlossenen
-- Vertrag. Es gibt keine Tabelle "akten"; Zustand, akte_seit und ruhend_seit
-- werden bei jedem Lesen abgeleitet.
--
--   akte_seit      = abgeschlossen_am des ersten Vertrags
--   ruhend_seit    = Ende des letzten Vertrags (nur wenn ruhend): gekuendigt_zum
--                    bzw. vertrag_ende; widerrufene Vertraege zaehlen nicht
--                    (Consensus-Check: sonst laege "ruhend seit" in der Zukunft)
--   letzte_session = letzte Session mit attendance = 'present'
--
-- Sichtbarkeit: Admin alle Akten, Coach nur aktive, alle anderen keine.

create or replace function public.akte_basis()
returns table (
  student_id     uuid,
  name           text,
  klasse         integer,
  schule_id      uuid,
  schule         text,
  akte_seit      date,
  zustand        text,
  ruhend_seit    date,
  letzte_session timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with ich as (
    select public.get_my_role() as rolle
  ),
  vertrag as (
    select v.student_id,
           min(v.abgeschlossen_am) as akte_seit,
           bool_or(v.wirksamer_status in ('aktiv', 'im_widerruf')) as aktiv,
           -- Ende des letzten Vertrags, der gelaufen ist: gekuendigt_zum vor
           -- vertrag_ende; ein widerrufener Vertrag ist nie gelaufen und zaehlt
           -- nur, wenn es keinen anderen gibt (dann ab dem Widerruf).
           coalesce(max(coalesce(v.gekuendigt_zum, v.vertrag_ende)) filter (where v.widerrufen_am is null),
                    max(v.widerrufen_am)) as letztes_ende,
           (array_agg(nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
                      order by v.vertragsbeginn desc nulls last))[1] as kindname
      from public.vertraege_aktuell v
     where v.student_id is not null
     group by v.student_id
  ),
  anwesend as (
    select ss.student_id, max(cs.scheduled_at) as letzte_session
      from public.session_students ss
      join public.coaching_sessions cs on cs.id = ss.session_id
     where ss.attendance = 'present'
     group by ss.student_id
  )
  select s.id,
         coalesce(nullif(btrim(p.full_name), ''), vt.kindname),
         s.class_level,
         s.schule_id,
         coalesce(sch.name, s.school_name),
         vt.akte_seit,
         case when vt.aktiv then 'aktiv' else 'ruhend' end,
         case when vt.aktiv then null else vt.letztes_ende end,
         a.letzte_session
    from vertrag vt
    join public.students s   on s.id = vt.student_id
    left join public.profiles p   on p.id = s.profile_id
    left join public.schulen  sch on sch.id = s.schule_id
    left join anwesend a on a.student_id = s.id
    cross join ich
   where ich.rolle = 'admin'
      or (ich.rolle = 'coach' and vt.aktiv);
$$;

comment on function public.akte_basis() is
  'Alle fuer die Rolle sichtbaren Akten (Admin: alle, Coach: aktive). Quelle der View schuelerakten und von board_schueler.';

revoke all on function public.akte_basis() from public, anon, authenticated;
grant execute on function public.akte_basis() to authenticated;

create view public.schuelerakten
with (security_invoker = true) as
  select student_id, name, klasse, schule_id, schule, akte_seit, zustand, ruhend_seit, letzte_session
    from public.akte_basis();

comment on view public.schuelerakten is
  'Die Akte je Kind (security_invoker). Sichtbarkeit regelt akte_basis(): Admin alle, Coach nur aktive Akten.';

revoke all on public.schuelerakten from public, anon, authenticated;
grant select on public.schuelerakten to authenticated;

-- ============================================================================
-- 3. einheiten_rechnung
-- ============================================================================
--
-- Reine Rechnung, keine Rechte, kein Vertragszugriff. STABLE, weil sie
-- Betriebstage und Schwellen liest. Formeln (Bauauftrag S1, Lieferumfang A):
--   soll        = E * betriebstage(beginn, heute-1) / betriebstage(beginn, stichtag)
--   rueckstand  = soll - verbraucht
--   offen       = greatest(E - verbraucht, 0)
--   wochen_rest = betriebstage(heute, stichtag) / 5
--   noetig      = offen / wochen_rest (bei 0 Wochen: offen)
--   gleichmaessig = E / (betriebstage(beginn, stichtag) / 5)
--   ampel       = rueckstand <= schwelle_1 im_plan, <= schwelle_2 leicht, sonst deutlich
-- heute vor beginn: art 'vorher', nur gleichmaessig und betriebstage_gesamt.
-- Fehlt eine Eingabe (kein Vertrag): keine Zeile.
-- "bis gestern" endet spaetestens am Stichtag, damit soll nie ueber E steigt.
-- Die Werte sind ungerundet; gerundet wird bei der Anzeige.

create or replace function public.einheiten_rechnung(
  p_einheiten  integer,
  p_beginn     date,
  p_stichtag   date,
  p_verbraucht integer,
  p_heute      date
)
returns table (
  art                      text,
  soll                     numeric,
  rueckstand               numeric,
  offen                    integer,
  wochen_rest              numeric,
  noetig_pro_woche         numeric,
  gleichmaessig_pro_woche  numeric,
  ampel                    text,
  betriebstage_gesamt      integer,
  betriebstage_bis_gestern integer,
  betriebstage_ab_heute    integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_verbraucht integer := coalesce(p_verbraucht, 0);
  v_s1         numeric;
  v_s2         numeric;
begin
  -- Ohne Vertrag keine Rechnung: keine Zeile statt Fehler. einheiten_stand_intern
  -- ruft die Funktion per LEFT JOIN LATERAL auch fuer Kinder ohne laufenden
  -- Vertrag auf (ruhende Akte); ein Fehler braeche dort Board und Akte.
  if p_einheiten is null or p_beginn is null or p_stichtag is null or p_heute is null then
    return;
  end if;

  betriebstage_gesamt := public.betriebstage(p_beginn, p_stichtag);
  gleichmaessig_pro_woche := case when betriebstage_gesamt > 0
                                  then p_einheiten / (betriebstage_gesamt / 5.0) end;

  if p_heute < p_beginn then
    art := 'vorher';
    return next;
    return;
  end if;

  art := 'laufend';
  betriebstage_bis_gestern := public.betriebstage(p_beginn, least(p_heute - 1, p_stichtag));
  betriebstage_ab_heute    := public.betriebstage(p_heute, p_stichtag);

  soll := case when betriebstage_gesamt > 0
               then p_einheiten * betriebstage_bis_gestern::numeric / betriebstage_gesamt
               else 0 end;
  rueckstand := soll - v_verbraucht;
  offen := greatest(p_einheiten - v_verbraucht, 0);
  wochen_rest := betriebstage_ab_heute / 5.0;
  noetig_pro_woche := case when wochen_rest > 0 then offen / wochen_rest else offen end;

  select e.schwelle_1, e.schwelle_2 into v_s1, v_s2 from public.akte_einstellungen e;
  ampel := case when rueckstand <= v_s1 then 'im_plan'
                when rueckstand <= v_s2 then 'leicht_im_rueckstand'
                else 'deutlich_im_rueckstand' end;

  return next;
end;
$$;

comment on function public.einheiten_rechnung(integer, date, date, integer, date) is
  'Reine Rechnung des Einheiten-Stands (Soll, Rueckstand, Ampel, Wochen). Keine Rechte, kein Vertragszugriff. Werte ungerundet.';

revoke all on function public.einheiten_rechnung(integer, date, date, integer, date) from public, anon, authenticated;
grant execute on function public.einheiten_rechnung(integer, date, date, integer, date) to authenticated;

-- ============================================================================
-- 4. einheiten_stand (Entscheidung 3, 5)
-- ============================================================================
--
-- Laufender Vertrag = wirksamer_status in (aktiv, im_widerruf) und Zeitraum
-- enthaelt heute. Sonst der mit dem naechsten Beginn (art 'vorher'). Sonst
-- art 'keiner'. Der Status kommt aus vertraege_aktuell.wirksamer_status und
-- gilt damit zum current_date; p_heute steuert Zeitraum und Rechnung.
--
-- verbraucht = Anzahl session_students mit einheit_verbraucht(attendance),
-- deren Session (Datum Europe/Berlin) zwischen Beginn und Stichtag liegt.
--
-- einheiten_stand_intern hat keine Rechtepruefung und ist nicht freigegeben;
-- einheiten_stand und board_schueler pruefen vorher.

create or replace function public.einheiten_stand_intern(p_student_id uuid, p_heute date)
returns table (
  art                     text,
  einheiten               integer,
  beginn                  date,
  stichtag                date,
  verbraucht              integer,
  offen                   integer,
  soll                    numeric,
  rueckstand              numeric,
  ampel                   text,
  wochen_rest             numeric,
  noetig_pro_woche        numeric,
  gleichmaessig_pro_woche numeric
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with vertrag as (
    select v.einheiten, v.vertragsbeginn, v.vertrag_ende
      from public.vertraege_aktuell v
     where v.student_id = p_student_id
       and v.wirksamer_status in ('aktiv', 'im_widerruf')
       and v.einheiten is not null
       and v.vertragsbeginn is not null
       and v.vertrag_ende is not null
       and v.vertrag_ende >= p_heute
     order by (v.vertragsbeginn <= p_heute) desc,
              case when v.vertragsbeginn <= p_heute then v.vertragsbeginn end desc nulls last,
              v.vertragsbeginn asc
     limit 1
  ),
  zaehlung as (
    select count(*)::integer as verbraucht
      from vertrag vt
      join public.session_students ss on ss.student_id = p_student_id
      join public.coaching_sessions cs on cs.id = ss.session_id
     where public.einheit_verbraucht(ss.attendance)
       and (cs.scheduled_at at time zone 'Europe/Berlin')::date
           between vt.vertragsbeginn and vt.vertrag_ende
  )
  select coalesce(r.art, 'keiner'),
         vt.einheiten,
         vt.vertragsbeginn,
         vt.vertrag_ende,
         case when r.art = 'laufend' then z.verbraucht end,
         r.offen,
         r.soll,
         r.rueckstand,
         r.ampel,
         r.wochen_rest,
         r.noetig_pro_woche,
         r.gleichmaessig_pro_woche
    from (select 1) eins
    left join vertrag vt on true
    left join zaehlung z on true
    left join lateral public.einheiten_rechnung(
      vt.einheiten, vt.vertragsbeginn, vt.vertrag_ende, z.verbraucht, p_heute
    ) r on true;
$$;

comment on function public.einheiten_stand_intern(uuid, date) is
  'Einheiten-Stand ohne Rechtepruefung. Nur fuer einheiten_stand und board_schueler; nicht an authenticated freigegeben.';

revoke all on function public.einheiten_stand_intern(uuid, date) from public, anon, authenticated;

create or replace function public.einheiten_stand(p_student_id uuid, p_heute date default current_date)
returns table (
  art                     text,
  einheiten               integer,
  beginn                  date,
  stichtag                date,
  verbraucht              integer,
  offen                   integer,
  soll                    numeric,
  rueckstand              numeric,
  ampel                   text,
  wochen_rest             numeric,
  noetig_pro_woche        numeric,
  gleichmaessig_pro_woche numeric
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle text := public.get_my_role();
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'einheiten_stand: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  return query select * from public.einheiten_stand_intern(p_student_id, coalesce(p_heute, current_date));
end;
$$;

comment on function public.einheiten_stand(uuid, date) is
  'Einheiten-Stand des laufenden Vertrags (art laufend | vorher | keiner). Admin immer, Coach nur bei aktiver Akte, sonst 42501. Einziger Weg fuer Coaches zu Einheiten und Stichtag.';

revoke all on function public.einheiten_stand(uuid, date) from public, anon, authenticated;
grant execute on function public.einheiten_stand(uuid, date) to authenticated;

-- ============================================================================
-- 5. board_schueler
-- ============================================================================
--
-- Alle fuer die Rolle sichtbaren Akten samt Einheiten-Stand in EINER Abfrage
-- (kein N+1 aus dem Frontend). Sichtbarkeit aus akte_basis(). Ruhende Akten
-- haben keinen laufenden Vertrag und damit art 'keiner'.

create or replace function public.board_schueler()
returns table (
  student_id     uuid,
  name           text,
  klasse         integer,
  schule         text,
  zustand        text,
  ruhend_seit    date,
  letzte_session timestamptz,
  art            text,
  einheiten      integer,
  beginn         date,
  stichtag       date,
  verbraucht     integer,
  offen          integer,
  soll           numeric,
  rueckstand     numeric,
  ampel          text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select a.student_id, a.name, a.klasse, a.schule, a.zustand, a.ruhend_seit, a.letzte_session,
         e.art, e.einheiten, e.beginn, e.stichtag, e.verbraucht, e.offen, e.soll, e.rueckstand, e.ampel
    from public.akte_basis() a
    cross join lateral public.einheiten_stand_intern(a.student_id, current_date) e;
$$;

comment on function public.board_schueler() is
  'Board "Schueler": alle fuer die Rolle sichtbaren Akten mit Einheiten-Stand in einer Abfrage.';

revoke all on function public.board_schueler() from public, anon, authenticated;
grant execute on function public.board_schueler() to authenticated;

-- ============================================================================
-- 6. schueler_notizen (Entscheidung 8, 9)
-- ============================================================================
--
-- Nur anhaengen. Den Text aendert niemand; die einzige Aenderung am Text ist
-- das endgueltige Entfernen einer Gesundheitsangabe (text -> NULL). Geschrieben
-- wird ausschliesslich ueber die vier RPCs; es gibt keine INSERT-/UPDATE-/
-- DELETE-Policy. Ein Trigger haelt die Regeln auch gegen direkte Updates.

create table public.schueler_notizen (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.students(id) on delete cascade,
  kategorie          text not null,
  text               text,
  autor_id           uuid references public.profiles(id) on delete set null,
  autor_rolle        text not null,
  created_at         timestamptz not null default now(),
  ausgeblendet_am    timestamptz,
  ausgeblendet_von   uuid references public.profiles(id) on delete set null,
  ausgeblendet_grund text,
  entfernt_am        timestamptz,
  entfernt_von       uuid references public.profiles(id) on delete set null,
  entfernt_grund     text,
  constraint schueler_notizen_kategorie_check check (kategorie in ('lernen', 'verhalten', 'organisatorisch')),
  constraint schueler_notizen_autor_rolle_check check (autor_rolle in ('admin', 'coach')),
  constraint schueler_notizen_text_oder_entfernt check ((entfernt_am is null) = (text is not null)),
  constraint schueler_notizen_text_nicht_leer check (text is null or nullif(btrim(text), '') is not null),
  constraint schueler_notizen_ausgeblendet_mit_grund check (
    (ausgeblendet_am is null and ausgeblendet_grund is null)
    or (ausgeblendet_am is not null and nullif(btrim(ausgeblendet_grund), '') is not null)
  ),
  constraint schueler_notizen_entfernt_grund check (
    (entfernt_am is null and entfernt_grund is null)
    or (entfernt_am is not null and entfernt_grund = 'gesundheitsangabe')
  )
);

comment on table public.schueler_notizen is
  'Notizen zur Akte, nur anhaengen. Schreiben nur ueber notiz_anlegen / notiz_ausblenden / notiz_einblenden / notiz_gesundheit_entfernen.';

create index schueler_notizen_student_idx on public.schueler_notizen (student_id, created_at desc);

create or replace function public.schueler_notizen_guard()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.id <> old.id
     or new.student_id  <> old.student_id
     or new.kategorie   <> old.kategorie
     or new.autor_rolle <> old.autor_rolle
     or new.created_at  <> old.created_at then
    raise exception 'schueler_notizen: Notizen werden nicht bearbeitet' using errcode = '42501';
  end if;

  -- Verweise auf Profile duerfen nur durch das Loeschen des Profils leer werden.
  if new.autor_id is distinct from old.autor_id and new.autor_id is not null then
    raise exception 'schueler_notizen: Autor ist unveraenderlich' using errcode = '42501';
  end if;

  -- Text: unveraendert, oder einmalig endgueltig entfernt.
  if new.text is distinct from old.text
     and not (old.text is not null and new.text is null
              and old.entfernt_am is null and new.entfernt_am is not null) then
    raise exception 'schueler_notizen: Notizen werden nicht bearbeitet' using errcode = '42501';
  end if;

  -- Entfernt bleibt entfernt.
  if old.entfernt_am is not null
     and (new.entfernt_am is distinct from old.entfernt_am
          or new.entfernt_grund is distinct from old.entfernt_grund
          or (new.entfernt_von is distinct from old.entfernt_von and new.entfernt_von is not null)) then
    raise exception 'schueler_notizen: eine entfernte Notiz bleibt entfernt' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger schueler_notizen_guard_trg
  before update on public.schueler_notizen
  for each row execute function public.schueler_notizen_guard();

alter table public.schueler_notizen enable row level security;

-- Admin sieht alles (auch ausgeblendet und entfernt). Coach nur in aktiven
-- Akten und nur, was weder ausgeblendet noch entfernt ist.
create policy schueler_notizen_admin_select on public.schueler_notizen
  for select using (public.get_my_role() = 'admin');
create policy schueler_notizen_coach_select on public.schueler_notizen
  for select using (
    public.get_my_role() = 'coach'
    and public.akte_aktiv(student_id)
    and ausgeblendet_am is null
    and entfernt_am is null
  );

revoke all on public.schueler_notizen from public, anon, authenticated;
grant select on public.schueler_notizen to authenticated;

-- notiz_anlegen: Admin in jede Akte, Coach nur in aktive. Die Wortliste
-- (gesundheit) wird hier geprueft, damit die Sperre nicht umgehbar ist.
-- Protokoll: direkt in audit_log, weil audit_log_schreiben nur Admins zulaesst
-- und hier auch Coaches schreiben.
create or replace function public.notiz_anlegen(p_student_id uuid, p_kategorie text, p_text text)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle  text := public.get_my_role();
  v_text   text := nullif(btrim(coalesce(p_text, '')), '');
  v_treffer text;
  v_id     uuid;
begin
  if auth.uid() is null or v_rolle not in ('admin', 'coach') then
    raise exception 'notiz_anlegen: nur Admin oder Coach' using errcode = '42501';
  end if;
  if not exists (select 1 from public.vertraege_aktuell v where v.student_id = p_student_id) then
    raise exception 'notiz_anlegen: keine Akte zu diesem Kind' using errcode = 'P0002';
  end if;
  if v_rolle = 'coach' and not public.akte_aktiv(p_student_id) then
    raise exception 'notiz_anlegen: Coaches schreiben nur in aktive Akten' using errcode = '42501';
  end if;
  if p_kategorie is null or p_kategorie not in ('lernen', 'verhalten', 'organisatorisch') then
    raise exception 'notiz_anlegen: unbekannte Kategorie %', p_kategorie using errcode = '22023';
  end if;
  if v_text is null then
    raise exception 'notiz_anlegen: die Notiz ist leer' using errcode = '22023';
  end if;

  v_treffer := public.akte_wortliste_treffer('gesundheit', v_text);
  if v_treffer is not null then
    raise exception 'notiz_anlegen: Die Notiz enthaelt "%". Das deutet auf eine Gesundheitsangabe hin, und die gehoert nicht in die Akte. Bitte umformulieren.', v_treffer
      using errcode = '22023',
            hint = 'gesundheitsbegriff:' || v_treffer;
  end if;

  insert into public.schueler_notizen (student_id, kategorie, text, autor_id, autor_rolle)
  values (p_student_id, p_kategorie, v_text, auth.uid(), v_rolle)
  returning id into v_id;

  insert into public.audit_log (actor, aktion, objekt_typ, objekt_id)
  values (auth.uid(), 'notiz_anlegen', 'schueler_notiz', v_id);

  return v_id;
end;
$$;

create or replace function public.notiz_ausblenden(p_notiz_id uuid, p_grund text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_grund text := nullif(btrim(coalesce(p_grund, '')), '');
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'notiz_ausblenden: nur Admin' using errcode = '42501';
  end if;
  if v_grund is null then
    raise exception 'notiz_ausblenden: ein Grund ist Pflicht' using errcode = '22023';
  end if;

  update public.schueler_notizen
     set ausgeblendet_am = now(), ausgeblendet_von = auth.uid(), ausgeblendet_grund = v_grund
   where id = p_notiz_id and entfernt_am is null;
  if not found then
    raise exception 'notiz_ausblenden: Notiz nicht gefunden oder schon entfernt' using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('notiz_ausblenden', 'schueler_notiz', p_notiz_id);
end;
$$;

create or replace function public.notiz_einblenden(p_notiz_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'notiz_einblenden: nur Admin' using errcode = '42501';
  end if;

  update public.schueler_notizen
     set ausgeblendet_am = null, ausgeblendet_von = null, ausgeblendet_grund = null
   where id = p_notiz_id and entfernt_am is null;
  if not found then
    raise exception 'notiz_einblenden: Notiz nicht gefunden oder schon entfernt' using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('notiz_einblenden', 'schueler_notiz', p_notiz_id);
end;
$$;

-- Endgueltig: der Text ist danach weg. Stehen bleiben Autor, Datum und
-- "entfernt von ... am ..., Grund: Gesundheitsangabe".
create or replace function public.notiz_gesundheit_entfernen(p_notiz_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'notiz_gesundheit_entfernen: nur Admin' using errcode = '42501';
  end if;

  update public.schueler_notizen
     set text = null, entfernt_am = now(), entfernt_von = auth.uid(), entfernt_grund = 'gesundheitsangabe'
   where id = p_notiz_id and entfernt_am is null;
  if not found then
    raise exception 'notiz_gesundheit_entfernen: Notiz nicht gefunden oder schon entfernt' using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('notiz_gesundheit_entfernen', 'schueler_notiz', p_notiz_id);
end;
$$;

revoke all on function public.notiz_anlegen(uuid, text, text)       from public, anon, authenticated;
revoke all on function public.notiz_ausblenden(uuid, text)          from public, anon, authenticated;
revoke all on function public.notiz_einblenden(uuid)                from public, anon, authenticated;
revoke all on function public.notiz_gesundheit_entfernen(uuid)      from public, anon, authenticated;
revoke all on function public.schueler_notizen_guard()              from public, anon, authenticated;
grant execute on function public.notiz_anlegen(uuid, text, text)    to authenticated;
grant execute on function public.notiz_ausblenden(uuid, text)       to authenticated;
grant execute on function public.notiz_einblenden(uuid)             to authenticated;
grant execute on function public.notiz_gesundheit_entfernen(uuid)   to authenticated;

-- ============================================================================
-- 7. eltern_reports (Entscheidung 10)
-- ============================================================================
--
-- Nur VERSENDETE Reports, unveraenderlich. Entwuerfe, Freigabe, PDF und Versand
-- baut das Feature Eltern-Reports in einer eigenen Arbeitstabelle und schreibt
-- beim Versand hier hinein — ausschliesslich ueber eltern_report_eintragen.
-- Einzige erlaubte Aenderung: pdf_pfad einmalig von NULL auf einen Wert.
--
-- parent_report_id / lsa_session_id ohne ON-DELETE-Aktion: ein Verweis auf
-- einen versendeten Report soll nicht still verschwinden. Beim Loeschen des
-- Kindes gehen beide Seiten per Kaskade im selben Statement.

create table public.eltern_reports (
  id               uuid primary key default gen_random_uuid(),
  student_id       uuid not null references public.students(id) on delete cascade,
  nr               integer not null,
  art              text not null,
  berichtsmonat    date,
  kernaussagen     jsonb,
  freigegeben_von  uuid references public.profiles(id) on delete set null,
  freigegeben_am   timestamptz,
  versendet_am     timestamptz,
  versendet_an     text,
  pdf_pfad         text,
  parent_report_id uuid references public.parent_reports(id),
  lsa_session_id   uuid references public.lsa_sessions(id),
  created_at       timestamptz not null default now(),
  constraint eltern_reports_nr_je_kind unique (student_id, nr),
  constraint eltern_reports_nr_positiv check (nr >= 1),
  constraint eltern_reports_art_check check (art in ('lernstandsanalyse', 'zwischenbericht')),
  constraint eltern_reports_berichtsmonat_erster check (berichtsmonat is null or extract(day from berichtsmonat) = 1),
  constraint eltern_reports_kernaussagen_objekt check (kernaussagen is null or jsonb_typeof(kernaussagen) = 'object'),
  constraint eltern_reports_pdf_pfad_nicht_leer check (pdf_pfad is null or nullif(btrim(pdf_pfad), '') is not null)
);

comment on table public.eltern_reports is
  'Versendete Eltern-Reports je Kind, fortlaufend nummeriert (nr) ueber alle Vertraege. Unveraenderlich; einfuegen nur ueber eltern_report_eintragen. Report 1 ist die Lernstandsanalyse, sofern es eine gab.';
comment on column public.eltern_reports.kernaussagen is
  'Kernaussage je Fach: {"<Fach>": "<Satz>"}.';

create unique index eltern_reports_lsa_einmal on public.eltern_reports (lsa_session_id)
  where lsa_session_id is not null;

create or replace function public.eltern_reports_guard()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if (new.id, new.student_id, new.nr, new.art, new.berichtsmonat, new.kernaussagen,
      new.freigegeben_am, new.versendet_am, new.versendet_an, new.parent_report_id,
      new.lsa_session_id, new.created_at)
     is distinct from
     (old.id, old.student_id, old.nr, old.art, old.berichtsmonat, old.kernaussagen,
      old.freigegeben_am, old.versendet_am, old.versendet_an, old.parent_report_id,
      old.lsa_session_id, old.created_at)
  then
    raise exception 'eltern_reports: ein versendeter Report ist unveraenderlich' using errcode = '42501';
  end if;

  -- freigegeben_von darf nur durch das Loeschen des Profils leer werden.
  if new.freigegeben_von is distinct from old.freigegeben_von and new.freigegeben_von is not null then
    raise exception 'eltern_reports: ein versendeter Report ist unveraenderlich' using errcode = '42501';
  end if;

  if new.pdf_pfad is distinct from old.pdf_pfad and old.pdf_pfad is not null then
    raise exception 'eltern_reports: pdf_pfad ist schon gesetzt' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger eltern_reports_guard_trg
  before update on public.eltern_reports
  for each row execute function public.eltern_reports_guard();

alter table public.eltern_reports enable row level security;

create policy eltern_reports_admin_select on public.eltern_reports
  for select using (public.get_my_role() = 'admin');
create policy eltern_reports_coach_select on public.eltern_reports
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));
-- Nur fuer das einmalige Setzen von pdf_pfad; alles andere haelt der Trigger.
create policy eltern_reports_admin_update on public.eltern_reports
  for update using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');

revoke all on public.eltern_reports from public, anon, authenticated;
grant select, update on public.eltern_reports to authenticated;

-- Nummer atomar: die students-Zeile wird gesperrt, danach max(nr) + 1. Der
-- Unique-Index (student_id, nr) ist die zweite Sicherung.
create or replace function public.eltern_report_eintragen(
  p_student_id       uuid,
  p_art              text,
  p_berichtsmonat    date        default null,
  p_kernaussagen     jsonb       default null,
  p_freigegeben_von  uuid        default null,
  p_freigegeben_am   timestamptz default null,
  p_versendet_am     timestamptz default null,
  p_versendet_an     text        default null,
  p_pdf_pfad         text        default null,
  p_parent_report_id uuid        default null,
  p_lsa_session_id   uuid        default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_nr integer;
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'eltern_report_eintragen: nur Admin' using errcode = '42501';
  end if;

  perform 1 from public.students where id = p_student_id for update;
  if not found then
    raise exception 'eltern_report_eintragen: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  if p_lsa_session_id is not null and not exists (
    select 1 from public.lsa_sessions where id = p_lsa_session_id and student_id = p_student_id
  ) then
    raise exception 'eltern_report_eintragen: die LSA gehoert nicht zu diesem Kind' using errcode = '22023';
  end if;

  select coalesce(max(nr), 0) + 1 into v_nr from public.eltern_reports where student_id = p_student_id;

  insert into public.eltern_reports
    (student_id, nr, art, berichtsmonat, kernaussagen, freigegeben_von, freigegeben_am,
     versendet_am, versendet_an, pdf_pfad, parent_report_id, lsa_session_id)
  values
    (p_student_id, v_nr, p_art, p_berichtsmonat, p_kernaussagen, p_freigegeben_von, p_freigegeben_am,
     p_versendet_am, nullif(btrim(coalesce(p_versendet_an, '')), ''), p_pdf_pfad, p_parent_report_id,
     p_lsa_session_id)
  returning id into v_id;

  perform public.audit_log_schreiben('eltern_report_eintragen', 'eltern_report', v_id);

  return jsonb_build_object('id', v_id, 'nr', v_nr);
end;
$$;

comment on function public.eltern_report_eintragen(uuid, text, date, jsonb, uuid, timestamptz, timestamptz, text, text, uuid, uuid) is
  'Traegt einen versendeten Report ein und vergibt die naechste Nummer des Kindes. Nur Admin. Keine Freigabe-, PDF- oder Versandlogik.';

revoke all on function public.eltern_report_eintragen(uuid, text, date, jsonb, uuid, timestamptz, timestamptz, text, text, uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.eltern_reports_guard() from public, anon, authenticated;
grant execute on function public.eltern_report_eintragen(uuid, text, date, jsonb, uuid, timestamptz, timestamptz, text, text, uuid, uuid)
  to authenticated;

-- Bestand: Kinder, die schon eine Akte und eine abgeschlossene LSA haben,
-- bekommen ihre LSA als Report 1 — wie es vertrag_abschliessen ab jetzt tut.
-- Direktes Insert, weil die Migration ohne angemeldeten Admin laeuft.
insert into public.eltern_reports (student_id, nr, art, lsa_session_id)
select x.student_id, 1, 'lernstandsanalyse', x.lsa_id
  from (
    select distinct on (l.student_id) l.student_id, l.id as lsa_id
      from public.lsa_sessions l
     where l.status = 'completed'
       and exists (select 1 from public.vertraege v
                    where v.student_id = l.student_id and v.status = 'abgeschlossen')
     order by l.student_id, l.completed_at desc nulls last
  ) x
 where not exists (select 1 from public.eltern_reports r where r.student_id = x.student_id);

-- ============================================================================
-- 7b. lsa_lead_kontext — Rueckweg Lead <-> Schueler, ohne Kontaktdaten
-- ============================================================================
--
-- Der LSA-Report (lsaReport.ts) fand den Lead nur ueber students.lead_id. Das
-- ist nach vertrag_abschliessen NULL; der Rueckweg laeuft ueber
-- leads.converted_student_id (S0, Abschnitt 1). Die Funktion loest beide Wege
-- auf und gibt nur, was der Report braucht: Rufname, naechstes Thema,
-- Eltern-Einschaetzung. Keine Kontaktdaten.
--
-- Sie ist zugleich der schmale Weg fuer Coaches, die nach
-- 20260929100200_coach_rls.sql leads nicht mehr direkt lesen. Coach: nur fuer
-- Kinder mit aktiver Akte oder provisorische Kinder (LSA vor dem Vertrag).

create or replace function public.lsa_lead_kontext(p_student_ids uuid[])
returns table (
  student_id               uuid,
  lead_id                  uuid,
  rufname                  text,
  next_exam_topic          text,
  current_topic_cluster_id uuid,
  eltern_note              text,
  eltern_weak_topics       text[]
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle text := public.get_my_role();
begin
  if coalesce(v_rolle, '') not in ('admin', 'coach') then
    raise exception 'lsa_lead_kontext: nur Admin oder Coach' using errcode = '42501';
  end if;

  return query
  select s.id,
         l.id,
         coalesce(l.first_name, l.full_name),
         l.next_exam_topic,
         l.current_topic_cluster_id,
         la.note,
         coalesce(la.weak_topics, '{}'::text[])
    from public.students s
    join lateral (
      select l2.*
        from public.leads l2
       where l2.id = s.lead_id
          or (s.lead_id is null and l2.converted_student_id = s.id)
       order by (l2.id = s.lead_id) desc nulls last, l2.created_at desc
       limit 1
    ) l on true
    left join public.lead_assessments la on la.lead_id = l.id and la.source = 'parent'
   where s.id = any(coalesce(p_student_ids, '{}'::uuid[]))
     and (v_rolle = 'admin' or s.is_provisional or public.akte_aktiv(s.id));
end;
$$;

comment on function public.lsa_lead_kontext(uuid[]) is
  'Lead-Daten fuer den LSA-Report je Kind (Rufname, naechstes Thema, Eltern-Einschaetzung), ueber students.lead_id oder leads.converted_student_id. Keine Kontaktdaten. Admin; Coach nur fuer aktive Akten und provisorische Kinder.';

revoke all on function public.lsa_lead_kontext(uuid[]) from public, anon, authenticated;
grant execute on function public.lsa_lead_kontext(uuid[]) to authenticated;

-- ============================================================================
-- 8. vertrag_abschliessen (Entscheidung 10, 11)
-- ============================================================================
--
-- Gegenueber 20260925140000_vertraege_abschluss.sql drei Aenderungen, sonst
-- wortgleich (Stand schema-erwartet.sql):
--   a) Faecher: student_subjects wird auch beim Folgevertrag nachgezogen.
--   b) students.schule_id wird aus dem Vertrag gesetzt, wenn noch leer.
--   c) Report 1: beim ersten Vertrag eines Kindes traegt die Funktion dessen
--      letzte abgeschlossene LSA als Report 1 in eltern_reports ein.
--      freigegeben_von, versendet_am und pdf_pfad bleiben NULL — die gibt es
--      heute nicht.

create or replace function public.vertrag_abschliessen(p_vertrag_id uuid, p_weg text, p_zustimmungen jsonb DEFAULT '[]'::jsonb, p_signatur_vertrag text DEFAULT NULL::text, p_signatur_sepa text DEFAULT NULL::text, p_unterschrieben_am date DEFAULT NULL::date, p_eingang_datum date DEFAULT NULL::date, p_scan_pfad text DEFAULT NULL::text, p_abweichung_vermerk text DEFAULT NULL::text, p_tier_id uuid DEFAULT NULL::uuid, p_laufzeit_monate integer DEFAULT NULL::integer, p_vertragsbeginn date DEFAULT NULL::date, p_student_uid uuid DEFAULT NULL::uuid, p_student_email text DEFAULT NULL::text, p_parent_uid uuid DEFAULT NULL::uuid, p_parent_email text DEFAULT NULL::text) RETURNS jsonb
language plpgsql
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
  v_erstvertrag boolean;
  v_lsa        uuid;
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
  v_erstvertrag := v.student_id is null;

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

    update public.leads
       set status = 'converted', converted_student_id = v_student
     where id = v.lead_id;
  end if;

  -- S1 (Entscheidung 11): Faecher auch beim Folgevertrag nachziehen.
  if v.fach is not null then
    select id into v_subject from public.subjects where name = v.fach;
    if v_subject is not null
       and not exists (select 1 from public.student_subjects
                        where student_id = v_student and subject_id = v_subject) then
      insert into public.student_subjects (student_id, subject_id) values (v_student, v_subject);
    end if;
  end if;

  -- S1: Schule der Akte aus dem Vertrag, solange die Akte keine hat. Eine in der
  -- Akte gepflegte Schule wird nicht ueberschrieben.
  if v.schule_id is not null then
    update public.students set schule_id = v.schule_id
     where id = v_student and schule_id is null;
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

  -- Zuerst der Vorgaenger: er ist verlaengert und faellt damit aus dem
  -- Partial-Unique-Index. Andersherum schluegen beide Vertraege gleichzeitig
  -- als "laufend" auf und der Index wuerde den Abschluss abweisen.
  if v_vorgaenger is not null then
    update public.vertraege
       set verlaengerung_status = 'verlaengert'
     where id = v_vorgaenger;
  end if;

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

  perform set_config('edvance.vertrag_rpc', '', true);

  -- S1 (Entscheidung 10): Report 1 = die LSA, beim ersten Vertrag des Kindes.
  -- Die letzte abgeschlossene LSA; ohne LSA kein Report 1.
  if v_erstvertrag then
    select l.id into v_lsa
      from public.lsa_sessions l
     where l.student_id = v_student and l.status = 'completed'
     order by l.completed_at desc nulls last
     limit 1;
    if v_lsa is not null
       and not exists (select 1 from public.eltern_reports where lsa_session_id = v_lsa) then
      perform public.eltern_report_eintragen(
        p_student_id     => v_student,
        p_art            => 'lernstandsanalyse',
        p_lsa_session_id => v_lsa);
    end if;
  end if;

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

commit;
