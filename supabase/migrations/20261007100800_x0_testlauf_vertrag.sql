-- X0.3 Report 1 nie aus einem Testlauf (Entscheidung 27).
--
-- Geltender Stand von vertrag_abschliessen (20260929100100_schuelerakte_akte.sql)
-- mit genau einer Ergaenzung: die LSA fuer Report 1 ist die letzte
-- abgeschlossene LSA, die KEIN Testlauf ist ("and not l.testlauf").

CREATE OR REPLACE FUNCTION public.vertrag_abschliessen(p_vertrag_id uuid, p_weg text, p_zustimmungen jsonb DEFAULT '[]'::jsonb, p_signatur_vertrag text DEFAULT NULL::text, p_signatur_sepa text DEFAULT NULL::text, p_unterschrieben_am date DEFAULT NULL::date, p_eingang_datum date DEFAULT NULL::date, p_scan_pfad text DEFAULT NULL::text, p_abweichung_vermerk text DEFAULT NULL::text, p_tier_id uuid DEFAULT NULL::uuid, p_laufzeit_monate integer DEFAULT NULL::integer, p_vertragsbeginn date DEFAULT NULL::date, p_student_uid uuid DEFAULT NULL::uuid, p_student_email text DEFAULT NULL::text, p_parent_uid uuid DEFAULT NULL::uuid, p_parent_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
       and not l.testlauf
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
$function$;
