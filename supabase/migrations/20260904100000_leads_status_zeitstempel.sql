-- Zeitstempel fuer die LSA-Zustaende eines Leads.
--
-- Das Leads-Board zeigt pro Spalte, wie lange ein Lead im aktuellen Zustand
-- steht. Fuer 'new' traegt created_at, fuer 'contacted' contacted_at -- fuer
-- die beiden LSA-Zustaende gab es bisher nichts.
--
-- Gesetzt wird ueber einen before-update-Trigger auf leads statt in
-- lead_lsa_freigeben und lsa_session_lead_fertig. Zwei Gruende: die beiden
-- Funktionen bleiben unangetastet (an ihnen haengt der komplette LSA-Start),
-- und der Zeitstempel stimmt auch dann, wenn der Status auf einem anderen
-- Weg gesetzt wird.
--
-- Der Trigger schreibt nur, wenn das Feld noch leer ist: ein Lead, der aus
-- lsa_fertig zurueck auf lsa_freigegeben faellt, behaelt seinen ersten
-- Zeitpunkt. Bestandsleads bleiben null -- die Spalten werden erst ab hier
-- gefuellt. Das Board muss diesen Fall abfangen.

alter table public.leads
  add column if not exists lsa_freigegeben_at timestamptz,
  add column if not exists lsa_fertig_at      timestamptz;

comment on column public.leads.lsa_freigegeben_at is
  'Zeitpunkt des Wechsels nach status = lsa_freigegeben. Null bei Leads von vor dieser Migration.';
comment on column public.leads.lsa_fertig_at is
  'Zeitpunkt des Wechsels nach status = lsa_fertig. Null bei Leads von vor dieser Migration.';

create or replace function public.leads_status_zeitstempel()
returns trigger
language plpgsql
as $function$
begin
  if new.status is distinct from old.status then
    if new.status = 'lsa_freigegeben' and new.lsa_freigegeben_at is null then
      new.lsa_freigegeben_at := now();
    elsif new.status = 'lsa_fertig' and new.lsa_fertig_at is null then
      new.lsa_fertig_at := now();
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists leads_status_zeitstempel_trg on public.leads;

create trigger leads_status_zeitstempel_trg
  before update on public.leads
  for each row
  execute function public.leads_status_zeitstempel();
