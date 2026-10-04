-- lead_mail_versand.ort — der Ort des Erstgespraechs als Pflichtangabe je Versand.
--
-- Edvance hat keinen festen Standort: das Gespraech findet bei der Familie, im
-- Coworking oder anderswo statt. Der Ort kommt deshalb nicht aus einer Vorlage,
-- sondern wird im Versand-Dialog eingetragen und hier zusammen mit dem Termin
-- festgehalten — beides zusammen ist, was die Eltern bekommen haben.
--
-- Die Tabelle ist beim Einspielen leer (Versand noch nicht deployt), deshalb
-- gleich not null.
--
-- lead_mail_protokollieren bekommt p_ort. Die Signatur aendert sich, also
-- drop + create statt einer Ueberladung daneben. Einziger Aufrufer ist die
-- Edge Function mail_senden, die erst mit dieser Fassung deployt wird.

alter table public.lead_mail_versand
  add column ort text not null
    constraint lead_mail_versand_ort_check
    check (btrim(ort) <> '' and char_length(ort) <= 300);

comment on column public.lead_mail_versand.ort is
  'Ort des Gespraechs, wie er in der Mail stand (Freitext aus dem Versand-Dialog).';

drop function public.lead_mail_protokollieren(uuid, text, text, timestamptz, text);

create function public.lead_mail_protokollieren(
  p_lead_id    uuid,
  p_anlass     text,
  p_empfaenger text,
  p_ort        text,
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
    (lead_id, anlass, empfaenger, ort, termin_at, fehler, erfolgt_von)
  values
    (p_lead_id, p_anlass, p_empfaenger, btrim(p_ort), p_termin_at,
     nullif(btrim(coalesce(p_fehler, '')), ''), auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text)
  to authenticated;
