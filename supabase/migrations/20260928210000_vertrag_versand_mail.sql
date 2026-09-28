-- P4b: Mailversand ueber hello@ — das Protokoll.
--
-- vertrag_versand hielt bisher fest, DASS etwas rausging. Sobald eine Maschine
-- verschickt, reicht das nicht: es muss auch drinstehen, WAS im Umschlag war
-- und OB es angekommen ist. Ein Protokoll, das nur die geglueckten Versuche
-- kennt, beantwortet die eine Frage nicht, wegen der man hineinschaut —
-- "warum haben die Eltern nichts bekommen?".

begin;

alter table public.vertrag_versand
  add column if not exists anhaenge jsonb,
  add column if not exists fehler   text;

comment on column public.vertrag_versand.anhaenge is
  'Die Dateinamen im Umschlag, als JSON-Array. Null beim Druckweg.';
comment on column public.vertrag_versand.fehler is
  'Null = zugestellt. Sonst die Meldung des Versands — die Zeile bleibt trotzdem stehen.';

-- Der Zugangscode ist ein dritter Anlass: keine Unterlagen, keine Bestaetigung,
-- sondern der Code allein, wenn er neu erzeugt wurde.
alter table public.vertrag_versand drop constraint if exists vertrag_versand_anlass_check;
alter table public.vertrag_versand add constraint vertrag_versand_anlass_check
  check (anlass in ('unterlagen', 'bestaetigung', 'zugangscode'));

-- ---------------------------------------------------------------------------
-- Einen Versandversuch festhalten — geglueckt oder nicht.
--
-- Es gibt vertrag_versand_protokollieren schon seit P0, mit vier Parametern.
-- Sie wird benutzt: der Druckweg in VertragPage ruft sie. Eine zweite
-- Fassung mit sechs Parametern daneben zu stellen waere eine Ueberladung —
-- und jeder Aufruf mit drei Argumenten damit mehrdeutig ("could not choose a
-- best candidate function"). Deshalb ERSETZT diese Migration die alte:
-- gleicher Name, gleiche Vorgabewerte, zwei Spalten mehr. Der Druckweg ruft
-- sie unveraendert weiter, der Statuswechsel bleibt drin.
--
-- Der Rueckgabetyp aendert sich von void auf uuid; "create or replace" kann
-- das nicht, deshalb erst drop.
-- ---------------------------------------------------------------------------
drop function if exists public.vertrag_versand_protokollieren(uuid, text, text, text);

create function public.vertrag_versand_protokollieren(
  p_vertrag_id uuid,
  p_weg        text,
  p_anlass     text,
  p_empfaenger text default null,
  p_anhaenge   jsonb default null,
  p_fehler     text default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
  v_id     uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_versand_protokollieren: nur Admin' using errcode = '42501';
  end if;

  select status into v_status from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versand_protokollieren: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_status = 'abgelehnt' then
    raise exception 'vertrag_versand_protokollieren: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  insert into public.vertrag_versand
    (vertrag_id, weg, anlass, empfaenger, anhaenge, fehler, erfolgt_von)
  values
    (p_vertrag_id, p_weg, p_anlass, p_empfaenger, p_anhaenge,
     nullif(btrim(coalesce(p_fehler, '')), ''), auth.uid())
  returning id into v_id;

  -- Unveraendert aus der alten Fassung: wer die Unterlagen rausgibt, wartet
  -- ab da auf Post. Beim Mailweg hat vertrag_versenden das schon getan, dann
  -- greift die Bedingung nicht.
  if p_anlass = 'unterlagen' and v_status = 'in_vorbereitung' then
    perform set_config('edvance.vertrag_rpc', '1', true);
    update public.vertraege
       set status = 'unterschrift_ausstehend',
           unterschrift_ausstehend_at = now(),
           glaeubiger_id = coalesce(glaeubiger_id,
             (select glaeubiger_id from public.vertrag_einstellungen))
     where id = p_vertrag_id;
    perform set_config('edvance.vertrag_rpc', '', true);
  end if;

  return v_id;
end;
$$;

revoke all on function public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)
  from public, anon, authenticated;
grant execute on function public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- vertrag_versenden protokolliert den Mailweg nicht mehr selbst.
--
-- Bisher schrieb sie fuer weg='email' eine Zeile "unterlagen verschickt" — zu
-- einer Zeit, als der Empfang die Mail von Hand tippte und die Zeile nur eine
-- Notiz war. Jetzt verschickt mail_senden wirklich, kennt die Anhaenge und
-- merkt, wenn es schiefgeht. Zwei Zeilen fuer einen Vorgang waeren eine zu
-- viel, und die falsche von beiden wuerde behaupten, es habe geklappt.
--
-- Der Druckweg bleibt unveraendert: dort IST das Auslegen der Vorgang.
-- ---------------------------------------------------------------------------
create or replace function public.vertrag_versenden(
  p_vertrag_id      uuid,
  p_weg             text,
  p_empfaenger      text default null,
  p_rueckmeldung_bis date default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v     vertraege%rowtype;
  v_bis date;
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

  if p_weg = 'druck' then
    insert into public.vertrag_versand (vertrag_id, weg, anlass, empfaenger, erfolgt_von)
    values (p_vertrag_id, p_weg, 'unterlagen', p_empfaenger, auth.uid());
  end if;

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

revoke all on function public.vertrag_versenden(uuid, text, text, date)
  from public, anon, authenticated;
grant execute on function public.vertrag_versenden(uuid, text, text, date) to authenticated;

commit;
