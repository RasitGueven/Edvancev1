-- Vertraege P1 — Datenmodell vom Antrag bis zum Vertragsende.
--
-- Bis hierher war `vertraege` eine Antragstabelle: vier Status von
-- 'in_vorbereitung' bis 'abgeschlossen', danach endete die Zustaendigkeit.
-- Was danach kommt — Laufzeit, Widerruf, Zahlung, Verlaengerung, Zugang —
-- hatte keinen Ort. Diese Migration gibt ihm einen, ohne den Antragsstatus
-- anzufassen: `status` bleibt, wie er ist, und `vertrag_status` beginnt erst
-- dort, wo `status` fertig ist.
--
-- Grundsatzentscheidungen wortgleich in docs/vertraege/entscheidungen.md.
--
-- Datumsarithmetik laeuft ausnahmslos ueber `date` (Tage). Kein timestamptz,
-- keine Millisekunden: Eine Widerrufsfrist, die von der Zeitzone abhaengt, ist
-- keine Frist, sondern eine Fehlerquelle.
--
-- Die Datei klammert sich selbst (begin/commit).

begin;

-- ============================================================================
-- 1. Ferien NRW — die Tabelle, aus der das Halbjahresende faellt
-- ============================================================================
--
-- Quelle: Ferienordnung NRW bis 2029/30 (Schulministerium NRW). Pfingsten und
-- bewegliche Ferientage stehen bewusst NICHT drin (Entscheidung: Ferienregel).
--
-- Die Tabelle ist die einzige Wahrheit ueber Ferien. Laeuft eine Rechnung ueber
-- den letzten hier gepflegten Tag hinaus, wirft vertrag_ende_berechnen() einen
-- Fehler, statt das Ergebnis zu raten.

create table public.ferien_nrw (
  id   uuid primary key default gen_random_uuid(),
  art  text not null,
  name text not null,
  von  date not null,
  bis  date not null,
  constraint ferien_nrw_art_check check (art in ('herbst','weihnachten','ostern','sommer')),
  constraint ferien_nrw_zeitraum_check check (von <= bis)
);

comment on table public.ferien_nrw is
  'Schulferien NRW (Herbst, Weihnachten, Ostern, Sommer). Quelle Ferienordnung NRW. Pfingsten und bewegliche Tage bewusst nicht enthalten.';

create index ferien_nrw_von_idx on public.ferien_nrw (von);
create index ferien_nrw_bis_idx on public.ferien_nrw (bis);

insert into public.ferien_nrw (art, name, von, bis) values
  ('sommer',      'Sommer 2026',       date '2026-07-20', date '2026-09-01'),
  ('herbst',      'Herbst 2026',       date '2026-10-17', date '2026-10-31'),
  ('weihnachten', 'Weihnachten 2026/27', date '2026-12-23', date '2027-01-06'),
  ('ostern',      'Ostern 2027',       date '2027-03-22', date '2027-04-03'),
  ('sommer',      'Sommer 2027',       date '2027-07-19', date '2027-08-31'),
  ('herbst',      'Herbst 2027',       date '2027-10-23', date '2027-11-06'),
  ('weihnachten', 'Weihnachten 2027/28', date '2027-12-24', date '2028-01-08'),
  ('ostern',      'Ostern 2028',       date '2028-04-10', date '2028-04-22'),
  ('sommer',      'Sommer 2028',       date '2028-07-10', date '2028-08-22'),
  ('herbst',      'Herbst 2028',       date '2028-10-23', date '2028-11-04'),
  ('weihnachten', 'Weihnachten 2028/29', date '2028-12-21', date '2029-01-05'),
  ('ostern',      'Ostern 2029',       date '2029-03-26', date '2029-04-07'),
  ('sommer',      'Sommer 2029',       date '2029-07-02', date '2029-08-14'),
  ('herbst',      'Herbst 2029',       date '2029-10-15', date '2029-10-27'),
  ('weihnachten', 'Weihnachten 2029/30', date '2029-12-20', date '2030-01-04'),
  ('ostern',      'Ostern 2030',       date '2030-04-15', date '2030-04-27'),
  ('sommer',      'Sommer 2030',       date '2030-06-24', date '2030-08-06');

alter table public.ferien_nrw enable row level security;

-- Lesen darf jeder Angemeldete (die Vertragsvorschau im Frontend rechnet damit).
-- Schreiben darf niemand: Ferien kommen per Migration, nicht per Formular.
create policy ferien_nrw_authenticated_read on public.ferien_nrw
  for select using (auth.role() = 'authenticated');

-- ============================================================================
-- 2. Schulen — Auswahlfeld statt Freitext
-- ============================================================================
--
-- `vertraege.schule` (text) bleibt als Altbestand stehen und wird in P2 aus
-- dem Formular genommen. Neue Vertraege zeigen auf schulen.id.

create table public.schulen (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  ort        text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles (id) on delete set null,
  constraint schulen_name_nicht_leer check (nullif(btrim(name), '') is not null)
);

comment on table public.schulen is
  'Schulen als Auswahlliste. Beim Erfassen eines Vertrags erweiterbar (nur Admin).';

-- Eindeutig ohne Ruecksicht auf Gross-/Kleinschreibung; Schulen ohne Ort
-- kollidieren miteinander, nicht mit gleichnamigen Schulen anderswo.
create unique index schulen_name_ort_uniq
  on public.schulen (lower(name), coalesce(ort, ''));

alter table public.schulen enable row level security;

create policy schulen_admin_all on public.schulen
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 3. Audit-Log — wer hat die volle IBAN aufgedeckt
-- ============================================================================
--
-- Die Tabelle hat KEINE Insert-Policy. Geschrieben wird ausschliesslich ueber
-- audit_log_schreiben(); ein direkter Insert aus dem Client ist damit nicht
-- moeglich, auch nicht fuer einen Admin. Ein Protokoll, das der Protokollierte
-- selbst schreiben darf, protokolliert nichts.

create table public.audit_log (
  id         uuid primary key default gen_random_uuid(),
  actor      uuid references public.profiles (id) on delete set null,
  aktion     text not null,
  objekt_typ text not null,
  objekt_id  uuid,
  created_at timestamptz not null default now(),
  constraint audit_log_aktion_nicht_leer check (nullif(btrim(aktion), '') is not null),
  constraint audit_log_objekt_typ_nicht_leer check (nullif(btrim(objekt_typ), '') is not null)
);

comment on table public.audit_log is
  'Append-only Protokoll sicherheitsrelevanter Zugriffe (u.a. Aufdecken der vollen IBAN). Schreiben nur ueber audit_log_schreiben().';

create index audit_log_objekt_idx on public.audit_log (objekt_typ, objekt_id, created_at desc);
create index audit_log_actor_idx  on public.audit_log (actor, created_at desc);

alter table public.audit_log enable row level security;

create policy audit_log_admin_read on public.audit_log
  for select using (public.get_my_role() = 'admin');

revoke insert, update, delete on public.audit_log from anon, authenticated;

create or replace function public.audit_log_schreiben(
  p_aktion     text,
  p_objekt_typ text,
  p_objekt_id  uuid default null
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
  if auth.uid() is null then
    raise exception 'audit_log_schreiben: kein angemeldeter Aufrufer' using errcode = '42501';
  end if;
  -- SECURITY DEFINER haengt an dieser Zeile: ohne sie duerfte jeder Angemeldete
  -- beliebige Eintraege ins Protokoll schreiben und es damit unbrauchbar machen.
  if public.get_my_role() <> 'admin' then
    raise exception 'audit_log_schreiben: nur Admin' using errcode = '42501';
  end if;

  insert into public.audit_log (actor, aktion, objekt_typ, objekt_id)
  values (auth.uid(), p_aktion, p_objekt_typ, p_objekt_id)
  returning id into v_id;

  return v_id;
end;
$$;

comment on function public.audit_log_schreiben(text, text, uuid) is
  'Einziger Schreibweg in audit_log, nur fuer Admins. Der Actor kommt aus auth.uid() und wird nicht uebergeben — sonst koennte der Aufrufer sich als jemand anderes eintragen.';

-- Supabase vergibt EXECUTE auf neue Funktionen per Default Privileges DIREKT an
-- anon und authenticated. Ein "revoke ... from public" entzieht das nicht: es
-- raeumt nur die PUBLIC-Zeile ab, die Rollenzeilen bleiben stehen. Deshalb
-- werden hier und bei jeder weiteren Funktion beide Rollen ausdruecklich
-- genannt, bevor das gewollte Recht zurueckkommt.
revoke all on function public.audit_log_schreiben(text, text, uuid) from public, anon, authenticated;
grant execute on function public.audit_log_schreiben(text, text, uuid) to authenticated;

-- ============================================================================
-- 4. vertraege — die Spalten fuer den Vorgang nach dem Abschluss
-- ============================================================================
--
-- NICHT neu angelegt, weil es sie schon gibt (kein Duplikat):
--   unterschrieben_am  (date)        — das Unterschriftsdatum. Kein zweites
--                                      Feld `unterschrift_datum`.
--   abgelehnt_grund / _notiz         — die feste Auswahl bleibt unveraendert.
--   vertrag_zustimmungen             — AGB-/Datenschutz-/Widerrufs-Fassung je
--                                      Vertrag (dokument_schluessel + version
--                                      + akzeptiert_at). Keine Fassungsspalten
--                                      auf vertraege.
--   vertrag_unterschriften           — Unterschriftsbild je Art.
--   vertrag_bankdaten / iban_masked  — IBAN und Maske.
--   tier_id + laufzeit_monate        — Preis und Einheiten setzt der bestehende
--                                      Trigger vertraege_guard() aus
--                                      tier_laufzeiten. Kein Rabattfeld.
--
-- `abgeschlossen_am` ist KEIN Duplikat von `abgeschlossen_at`: letzteres ist der
-- Systemzeitpunkt der RPC, ersteres der fachliche Tag. Beim Papierweg liegen sie
-- auseinander — der Vertrag ist am Tag der Unterschrift geschlossen, nicht am Tag
-- der Nacherfassung. Fristen rechnen auf dem Tag.

alter table public.vertraege
  -- Bezug --------------------------------------------------------------------
  add column student_id  uuid references public.students (id) on delete restrict,
  add column schule_id   uuid references public.schulen  (id) on delete restrict,
  add column vorgaenger_id uuid references public.vertraege (id) on delete restrict,

  -- Vertragsleben ------------------------------------------------------------
  add column vertrag_status    text,
  add column abgeschlossen_am  date,
  add column eingang_datum     date,
  add column vertrag_ende      date,
  add column ferientage        integer,
  add column widerruf_bis      date,
  add column widerrufen_am     date,
  add column gekuendigt_zum    date,
  add column kuendigung_grund  text,

  -- Zahlung ------------------------------------------------------------------
  add column zahlungsstatus       text not null default 'in_ordnung',
  add column zahlungsstatus_seit  date,
  add column offener_betrag_cents integer,

  -- Verlaengerung ------------------------------------------------------------
  add column verlaengerung_status text,
  add column verlaengerung_grund  text,
  add column wiedervorlage_am     date,
  add column rueckmeldung_bis     date,

  -- Sonstiges ----------------------------------------------------------------
  add column abweichung_vermerk text,

  -- Zugang -------------------------------------------------------------------
  add column zugangscode             text,
  add column zugangscode_erzeugt_am  date,
  add column zugangscode_gesperrt_am date;

comment on column public.vertraege.student_id is
  'Das Kind, auf das der Vertrag laeuft. RESTRICT: ein Kind mit Vertrag wird nicht weggeloescht.';
comment on column public.vertraege.vorgaenger_id is
  'Der Vertrag, den dieser ersetzt. Traegt die Kette ueber die Jahre und haelt den Zugang zwischen Vertragsende und Folgebeginn offen.';
comment on column public.vertraege.vertrag_status is
  'Lebenslauf NACH dem Abschluss. NULL, solange status <> abgeschlossen. Keine ordentliche Kuendigung — gekuendigt ist ein manueller Sonderfall.';
comment on column public.vertraege.abgeschlossen_am is
  'Fachlicher Abschlusstag (Europe/Berlin). Nicht zu verwechseln mit abgeschlossen_at, dem Systemzeitpunkt der RPC.';
comment on column public.vertraege.eingang_datum is
  'Tag, an dem der unterschriebene Vertrag eingegangen ist (Papierweg).';
comment on column public.vertraege.ferientage is
  'Beim Abschluss eingefrorene Zahl der Ferientage, die das Halbjahresende geschoben haben. Nachweis, nicht Rechengroesse.';
comment on column public.vertraege.zugangscode is
  'Anzeigeform EDV-XXXX-XXXX. Acht Zeichen aus einem Alphabet ohne 0/O/1/I/L. Kein Login-Mittel in dieser Runde.';

alter table public.vertraege
  -- Entscheidung 3: Vertragsbeginn ist immer der Monatserste.
  add constraint vertraege_beginn_monatserster
    check (vertragsbeginn is null or extract(day from vertragsbeginn) = 1),

  -- Entscheidung 7: vertrag_status genau dann, wenn der Antrag durch ist.
  add constraint vertraege_vertrag_status_check
    check (vertrag_status is null
           or vertrag_status in ('im_widerruf','aktiv','gekuendigt','ausgelaufen','widerrufen')),
  add constraint vertraege_vertrag_status_nach_abschluss
    check ((status = 'abgeschlossen') = (vertrag_status is not null)),
  add constraint vertraege_gekuendigt_braucht_datum_und_grund
    check (vertrag_status is distinct from 'gekuendigt'
           or (gekuendigt_zum is not null
               and nullif(btrim(kuendigung_grund), '') is not null)),
  add constraint vertraege_widerrufen_braucht_datum
    check (vertrag_status is distinct from 'widerrufen' or widerrufen_am is not null),

  -- Entscheidungen 4/5/6: Ende und Frist liegen hinter dem Beginn.
  add constraint vertraege_ende_nach_beginn
    check (vertrag_ende is null or vertragsbeginn is null or vertrag_ende > vertragsbeginn),
  add constraint vertraege_widerruf_nach_beginn
    check (widerruf_bis is null or vertragsbeginn is null or widerruf_bis >= vertragsbeginn),
  add constraint vertraege_ferientage_nicht_negativ
    check (ferientage is null or ferientage >= 0),

  -- Entscheidung 8: Zahlungsstufe traegt ihr Datum.
  add constraint vertraege_zahlungsstatus_check
    check (zahlungsstatus in ('in_ordnung','zahlung_offen','mahnung_1','mahnung_2','inkasso')),
  add constraint vertraege_zahlungsstatus_braucht_datum
    check (zahlungsstatus = 'in_ordnung' or zahlungsstatus_seit is not null),
  add constraint vertraege_offener_betrag_nicht_negativ
    check (offener_betrag_cents is null or offener_betrag_cents >= 0),

  -- Entscheidung 9: keine Verlaengerung braucht einen Grund.
  add constraint vertraege_verlaengerung_status_check
    check (verlaengerung_status is null
           or verlaengerung_status in ('offen','kontaktiert','gespraech_vereinbart','verlaengert','keine_verlaengerung')),
  add constraint vertraege_keine_verlaengerung_braucht_grund
    check (verlaengerung_status is distinct from 'keine_verlaengerung'
           or nullif(btrim(verlaengerung_grund), '') is not null),

  -- Entscheidung 10: ein Vertrag verweist nicht auf sich selbst.
  add constraint vertraege_vorgaenger_nicht_selbst
    check (vorgaenger_id is null or vorgaenger_id <> id),

  -- Entscheidung 12: Form des Zugangscodes.
  add constraint vertraege_zugangscode_form
    check (zugangscode is null
           or zugangscode ~ '^EDV-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}$'),
  add constraint vertraege_zugangscode_sperre_braucht_code
    check (zugangscode_gesperrt_am is null or zugangscode is not null),

  add constraint vertraege_zugangscode_uniq unique (zugangscode);

-- Entscheidung 10: ein laufender Vertrag pro Kind. Abgelaufene, widerrufene und
-- gekuendigte Vertraege bleiben liegen — sie sind die Historie und der
-- Vorgaenger des naechsten.
create unique index vertraege_student_laufend_uniq
  on public.vertraege (student_id)
  where student_id is not null and vertrag_status in ('im_widerruf','aktiv');

create index vertraege_student_idx    on public.vertraege (student_id);
create index vertraege_vorgaenger_idx on public.vertraege (vorgaenger_id);
create index vertraege_schule_idx     on public.vertraege (schule_id);
create index vertraege_wiedervorlage_idx
  on public.vertraege (wiedervorlage_am)
  where wiedervorlage_am is not null;

-- Entscheidung 14: Ein Lead reisst seinen Vertrag nicht mit ins Grab.
-- lead_delete() loescht heute ueber die Kaskade; ab hier scheitert das mit
-- 23503, sobald ein Vertrag haengt. Das ist gewollt — P2 gibt dem Fehler
-- einen lesbaren Satz.
alter table public.vertraege drop constraint vertraege_lead_id_fkey;
alter table public.vertraege
  add constraint vertraege_lead_id_fkey
  foreign key (lead_id) references public.leads (id) on delete restrict;

-- ============================================================================
-- 5. Storage-Bucket "vertraege" — privat, nur Admin
-- ============================================================================
--
-- Die Region (Frankfurt / eu-central-1) ist eine Eigenschaft des Supabase-
-- Projekts, nicht des Buckets; storage.buckets hat keine Regionsspalte.

insert into storage.buckets (id, name, public)
values ('vertraege', 'vertraege', false)
on conflict (id) do nothing;

create policy vertraege_storage_select on storage.objects
  for select using (bucket_id = 'vertraege' and public.get_my_role() = 'admin');

create policy vertraege_storage_insert on storage.objects
  for insert with check (bucket_id = 'vertraege' and public.get_my_role() = 'admin');

create policy vertraege_storage_update on storage.objects
  for update using (bucket_id = 'vertraege' and public.get_my_role() = 'admin')
  with check (bucket_id = 'vertraege' and public.get_my_role() = 'admin');

create policy vertraege_storage_delete on storage.objects
  for delete using (bucket_id = 'vertraege' and public.get_my_role() = 'admin');

-- ============================================================================
-- 6. Widerrufsfrist
-- ============================================================================
--
-- Entscheidung 6: Beginn + 29 Tage, weil der erste Tag mitzaehlt.
-- 01.11. -> 30.11.  ·  01.02.2028 -> 01.03.2028 (Schaltjahr, und genau deshalb
-- rechnet das date und nicht ein Kalendermonat).

create or replace function public.vertrag_widerruf_bis(p_beginn date)
returns date
language sql
immutable
as $$
  select p_beginn + 29;
$$;

comment on function public.vertrag_widerruf_bis(date) is
  'Letzter Tag der Widerrufsfrist: Vertragsbeginn + 29 Tage (erster Tag zaehlt mit).';

revoke all on function public.vertrag_widerruf_bis(date) from public, anon, authenticated;
grant execute on function public.vertrag_widerruf_bis(date) to authenticated;

-- ============================================================================
-- 7. Vertragsende
-- ============================================================================
--
-- Jahresvertrag: Beginn + 12 Monate - 1 Tag. Fertig, keine Ferienregel.
--
-- Halbjahresvertrag: Die sechs Monate sind sechs UNTERRICHTS-Monate. Jeder
-- Ferientag im Vertragszeitraum schiebt das Ende um einen Tag nach hinten —
-- und weil das Schieben neue Ferien in den Zeitraum holt, wird bis zum Fixpunkt
-- gerechnet:
--
--   nominal = beginn + 6 Monate - 1 Tag
--   ende   := nominal
--   wiederhole: t = Ferientage in [beginn, ende]; neu = nominal + t; bis neu = ende
--
-- "Ferientage in [beginn, ende]" zaehlt die TAGE der Ueberschneidung, nicht die
-- ganze Ferienperiode: Beginnt der Vertrag am 01.11.2027, mitten in den
-- Herbstferien (23.10.-06.11.), zaehlen sechs Tage, nicht fuenfzehn. Genau
-- dieses Lesen reproduziert die Referenzwerte in tests/sql/vertrag_ende_test.sql
-- (01.11.2027 -> 35 Ferientage; die Periode ganz gezaehlt gaebe 44).
--
-- Danach wird auf einen von zwei Tagen im Monat gerundet — ein Vertragsende am
-- 3. oder 26. ist im Betrieb nicht planbar:
--   Tag < 15 -> 15.  ·  Tag = 15 -> bleibt  ·  Tag > 15 -> Monatsletzter
--
-- Landet das Ergebnis selbst in Ferien, geht es auf den Tag nach dem Ferienende
-- und wird erneut gerundet, bis es draussen liegt. (Tritt real auf, z.B.
-- Halbjahr ab 01.08.2027: gerundet 15.04.2028, mitten in Ostern 2028 ->
-- 30.04.2028.)
--
-- Reicht die Rechnung ueber den letzten gepflegten Ferientag hinaus, wirft die
-- Funktion. Ein still gerechnetes Ende waere ein Vertragsende, das niemand
-- nachrechnen kann.
--
-- SECURITY DEFINER, obwohl rein lesend: ferien_nrw traegt RLS. Ein Aufrufer
-- ohne die Leserechte saehe sonst null Ferientage und bekaeme ein falsches
-- Ende statt eines Fehlers.

create or replace function public.vertrag_ende_berechnen(
  p_beginn          date,
  p_laufzeit_monate integer
)
returns table (nominal date, ferientage integer, ende date, ferien text[])
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  c_max_runden constant integer := 500;
  v_nominal  date;
  v_fix      date;
  v_neu      date;
  v_ende     date;
  v_tage     integer;
  v_runde    integer;
  v_bis      date;
  v_erster   date;
  v_letzter  date;
  v_namen    text[];
begin
  if p_beginn is null or p_laufzeit_monate is null then
    raise exception 'vertrag_ende_berechnen: p_beginn und p_laufzeit_monate sind Pflicht'
      using errcode = '22023';
  end if;
  if p_laufzeit_monate not in (6, 12) then
    raise exception 'vertrag_ende_berechnen: Laufzeit ist 6 oder 12 Monate, nicht %', p_laufzeit_monate
      using errcode = '22023';
  end if;
  if extract(day from p_beginn) <> 1 then
    raise exception 'vertrag_ende_berechnen: Vertragsbeginn ist immer der Monatserste (% ist es nicht)', p_beginn
      using errcode = '22023';
  end if;

  v_nominal := (p_beginn + make_interval(months => p_laufzeit_monate))::date - 1;

  -- ------------------------------------------------------------- Jahresvertrag
  if p_laufzeit_monate = 12 then
    nominal    := v_nominal;
    ferientage := 0;
    ende       := v_nominal;
    ferien     := array[]::text[];
    return next;
    return;
  end if;

  -- ---------------------------------------------------------- Halbjahresvertrag
  select min(f.von), max(f.bis) into v_erster, v_letzter from public.ferien_nrw f;

  if v_letzter is null then
    raise exception 'vertrag_ende_berechnen: ferien_nrw ist leer — ohne Ferien gibt es kein Halbjahresende'
      using errcode = 'P0001';
  end if;
  if p_beginn < v_erster then
    raise exception 'vertrag_ende_berechnen: Beginn % liegt vor dem ersten gepflegten Ferientag (%) — die Rechnung waere unvollstaendig', p_beginn, v_erster
      using errcode = 'P0001';
  end if;

  -- Fixpunkt: schieben, bis das Schieben nichts Neues mehr findet.
  v_fix   := v_nominal;
  v_runde := 0;
  loop
    v_runde := v_runde + 1;
    if v_runde > c_max_runden then
      raise exception 'vertrag_ende_berechnen: kein Fixpunkt nach % Runden (Beginn %)', c_max_runden, p_beginn
        using errcode = 'P0001';
    end if;

    select coalesce(sum((least(f.bis, v_fix) - greatest(f.von, p_beginn)) + 1), 0)::integer
      into v_tage
      from public.ferien_nrw f
     where f.von <= v_fix and f.bis >= p_beginn;

    v_neu := v_nominal + v_tage;
    exit when v_neu = v_fix;
    v_fix := v_neu;
  end loop;

  -- Aufrunden und, falls noetig, aus den Ferien heraus — bis beides stimmt.
  v_ende  := v_fix;
  v_runde := 0;
  loop
    v_runde := v_runde + 1;
    if v_runde > 50 then
      raise exception 'vertrag_ende_berechnen: Aufrunden findet keinen ferienfreien Tag (Beginn %)', p_beginn
        using errcode = 'P0001';
    end if;

    v_ende := case
                when extract(day from v_ende) < 15 then date_trunc('month', v_ende)::date + 14
                when extract(day from v_ende) = 15 then v_ende
                else (date_trunc('month', v_ende) + interval '1 month')::date - 1
              end;

    v_bis := null;
    select f.bis into v_bis
      from public.ferien_nrw f
     where v_ende between f.von and f.bis
     limit 1;

    exit when v_bis is null;
    v_ende := v_bis + 1;
  end loop;

  if v_ende > v_letzter then
    raise exception 'vertrag_ende_berechnen: Ende % liegt nach dem letzten gepflegten Ferientag (%). Ferien in ferien_nrw ergaenzen — hier wird nicht still gerechnet.', v_ende, v_letzter
      using errcode = 'P0001';
  end if;

  -- Die Ferien, die gezaehlt haben (Fenster des Fixpunkts, nicht des gerundeten
  -- Endes) — als Nachweis fuer die Vertragsunterlage.
  select coalesce(array_agg(f.name order by f.von), array[]::text[])
    into v_namen
    from public.ferien_nrw f
   where f.von <= v_fix and f.bis >= p_beginn;

  nominal    := v_nominal;
  ferientage := v_tage;
  ende       := v_ende;
  ferien     := v_namen;
  return next;
end;
$$;

comment on function public.vertrag_ende_berechnen(date, integer) is
  'Vertragsende. 12 Monate: Beginn + 12 Monate - 1 Tag. 6 Monate: Ferienregel NRW mit Fixpunkt, Aufrunden auf 15. oder Monatsletzten, Ausweichen aus Ferien. Wirft, wenn die Rechnung ueber ferien_nrw hinauslaeuft.';

revoke all on function public.vertrag_ende_berechnen(date, integer) from public, anon, authenticated;
grant execute on function public.vertrag_ende_berechnen(date, integer) to authenticated;

-- ============================================================================
-- 8. Zugangscode
-- ============================================================================
--
-- Entscheidung 12: acht Zeichen aus einem Alphabet ohne 0/O/1/I/L, damit
-- niemand am Telefon buchstabieren muss, was er sieht. Anzeige EDV-XXXX-XXXX;
-- genau diese Form wird gespeichert, damit es nicht zwei Schreibweisen desselben
-- Codes gibt. 31^8 ~ 8.5e11 Moeglichkeiten — die Kollisionsschleife ist
-- Vorsorge, kein Normalfall.
--
-- Kein GRANT: Der Code entsteht beim Abschluss, nicht auf Zuruf. Aufrufbar ist
-- die Funktion damit nur aus SECURITY-DEFINER-Funktionen desselben Eigentuemers
-- (P2: vertrag_abschliessen und das Neu-Erzeugen).

create or replace function public.zugangscode_erzeugen()
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  c_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_roh   text;
  v_code  text;
  v_runde integer := 0;
begin
  loop
    v_runde := v_runde + 1;
    if v_runde > 100 then
      raise exception 'zugangscode_erzeugen: 100 Kollisionen in Folge — Alphabet oder Laenge pruefen'
        using errcode = 'P0001';
    end if;

    v_roh := '';
    for i in 1..8 loop
      v_roh := v_roh || substr(c_alphabet, 1 + floor(random() * length(c_alphabet))::integer, 1);
    end loop;

    v_code := 'EDV-' || substr(v_roh, 1, 4) || '-' || substr(v_roh, 5, 4);

    exit when not exists (select 1 from public.vertraege t where t.zugangscode = v_code);
  end loop;

  return v_code;
end;
$$;

comment on function public.zugangscode_erzeugen() is
  'Neuer, noch freier Zugangscode in der Form EDV-XXXX-XXXX. Alphabet ohne 0/O/1/I/L.';

revoke all on function public.zugangscode_erzeugen() from public, anon, authenticated;

commit;
