-- LR-2 · Der Eltern-Bericht der LSA per Mail (Bauauftrag LR-2, Entscheidungen 4–6).
--
-- 1. Bucket lsa_reports (privat): je Versand das PDF unter {session_id}/{yyyyMMdd-HHmmss}.pdf.
--    Hochladen und Lesen nur Admin, kein UPDATE, kein DELETE: jede versendete Fassung
--    bleibt eingefroren liegen (später „Report 1“ in der Schülerakte).
-- 2. lead_mail_versand kennt den Anlass 'lsa_report' mit Sitzung, Pfad und SHA-256 des
--    Anhangs. ort ist nur noch bei der Terminbestaetigung Pflicht.
-- 3. lead_mail_protokollieren bekommt p_lsa_session_id, p_anhang_pfad, p_anhang_sha256.
--
-- Rückwärtsverträglich: Die heute deployte mail_senden ruft lead_mail_protokollieren mit
-- benannten Parametern (p_lead_id, p_anlass, p_empfaenger, p_ort, p_termin_at, p_fehler)
-- auf. Alle neuen Parameter haben einen Default, die Terminbestaetigung läuft zwischen
-- Einspielen und Deploy unverändert weiter. Drop + create statt einer Überladung daneben:
-- zwei Fassungen machten den benannten Aufruf mehrdeutig.

-- ---------------------------------------------------------------------------
-- 1. Bucket und Storage-Policies
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('lsa_reports', 'lsa_reports', false)
  on conflict (id) do nothing;
-- Grenzen nur, wo Storage sie kennt (Prod; die CI-Grundlage hat eine schlanke storage.buckets).
do $$
begin
  if exists (select 1 from information_schema.columns
              where table_schema = 'storage' and table_name = 'buckets' and column_name = 'allowed_mime_types') then
    execute $q$update storage.buckets set file_size_limit = 3145728,
      allowed_mime_types = array['application/pdf']
      where id = 'lsa_reports'$q$;
  end if;
end $$;

create policy lsa_reports_storage_lesen on storage.objects for select to authenticated
  using (bucket_id = 'lsa_reports' and public.get_my_role() = 'admin');
create policy lsa_reports_storage_hochladen on storage.objects for insert to authenticated
  with check (bucket_id = 'lsa_reports' and public.get_my_role() = 'admin'
              and name ~ '^[0-9a-f-]{36}/[0-9]{8}-[0-9]{6}\.pdf$');

-- ---------------------------------------------------------------------------
-- 2. Protokoll
-- ---------------------------------------------------------------------------
alter table public.lead_mail_versand drop constraint lead_mail_versand_anlass_check;
alter table public.lead_mail_versand add constraint lead_mail_versand_anlass_check
  check (anlass in ('terminbestaetigung', 'lsa_report'));

-- Der Ort gehört zur Terminbestaetigung; die bestehende Längenprüfung bleibt (null besteht sie).
alter table public.lead_mail_versand alter column ort drop not null;
alter table public.lead_mail_versand add constraint lead_mail_versand_ort_pflicht
  check (anlass <> 'terminbestaetigung' or ort is not null);

alter table public.lead_mail_versand
  add column lsa_session_id uuid references public.lsa_sessions (id) on delete set null,
  add column anhang_pfad    text,
  add column anhang_sha256  text
    constraint lead_mail_versand_anhang_sha256_check check (anhang_sha256 ~ '^[0-9a-f]{64}$');

-- Ohne Pfad wüsste niemand, welche Fassung rausging. Die Sitzung darf später fehlen (on delete set null).
alter table public.lead_mail_versand add constraint lead_mail_versand_lsa_report_pfad
  check (anlass <> 'lsa_report' or anhang_pfad is not null);

comment on column public.lead_mail_versand.lsa_session_id is
  'Anlass lsa_report: die LSA-Sitzung, deren Bericht verschickt wurde.';
comment on column public.lead_mail_versand.anhang_pfad is
  'Anlass lsa_report: das PDF im Bucket lsa_reports, genau die Datei, die angehängt war.';
comment on column public.lead_mail_versand.anhang_sha256 is
  'Anlass lsa_report: SHA-256 (hex) des angehängten PDFs, auch bei gescheitertem Versand.';

create index lead_mail_versand_lsa_session_idx
  on public.lead_mail_versand (lsa_session_id, erfolgt_at desc)
  where lsa_session_id is not null;

-- ---------------------------------------------------------------------------
-- 3. lead_mail_protokollieren
-- ---------------------------------------------------------------------------
drop function public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text);

create function public.lead_mail_protokollieren(
  p_lead_id        uuid,
  p_anlass         text,
  p_empfaenger     text,
  p_ort            text default null,
  p_termin_at      timestamptz default null,
  p_fehler         text default null,
  p_lsa_session_id uuid default null,
  p_anhang_pfad    text default null,
  p_anhang_sha256  text default null
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
    (lead_id, anlass, empfaenger, ort, termin_at, fehler, erfolgt_von,
     lsa_session_id, anhang_pfad, anhang_sha256)
  values
    (p_lead_id, p_anlass, p_empfaenger, btrim(p_ort), p_termin_at,
     nullif(btrim(coalesce(p_fehler, '')), ''), auth.uid(),
     p_lsa_session_id, p_anhang_pfad, p_anhang_sha256)
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text, uuid, text, text)
  to authenticated;
