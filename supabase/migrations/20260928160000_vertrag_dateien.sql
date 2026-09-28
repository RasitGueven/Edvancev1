-- P4a-1: Vertrags-PDF und Archiv — Datenmodell.
--
-- Was erzeugt wurde, wird hier festgehalten: ein Datensatz je Datei im Bucket
-- "vertraege", mit Pfad und Pruefsumme. Der Bucket allein reicht dafuer nicht.
-- Er weiss, dass unter <vertrag_id>/vertrag.pdf etwas liegt — nicht, ob es aus
-- diesem Vertragsstand erzeugt wurde, wann, und von wem.
--
-- ABWEICHUNG VOM WORTLAUT DES AUFTRAGS: Dort stand, Pfad und Pruefsumme
-- kaemen an vertrag_dokumente. Das geht nicht. vertrag_dokumente ist ein
-- Katalog: PRIMARY KEY (schluessel, version), sechs Zeilen fuer ALLE Vertraege,
-- Ziel des Fremdschluessels von vertrag_zustimmungen. Ein Pfad je Vertrag hat
-- dort keinen Platz. Deshalb eine eigene Tabelle.

begin;

create table if not exists public.vertrag_dateien (
  id          uuid primary key default gen_random_uuid(),
  -- RESTRICT, nicht CASCADE: Ein Vertrag, zu dem ein Dokument im Archiv liegt,
  -- verschwindet nicht per Zeilenloeschung. Der Storage-Bucket wuerde einem
  -- CASCADE ohnehin nicht folgen — die Datei bliebe als Waise zurueck.
  vertrag_id  uuid not null references public.vertraege (id) on delete restrict,
  art         text not null,
  pfad        text not null,
  sha256      text not null,
  bytes       integer,
  erzeugt_am  timestamptz not null default now(),
  erzeugt_von uuid references public.profiles (id) on delete set null,
  constraint vertrag_dateien_art_check
    check (art in ('vertrag', 'unterschrift', 'unterlagen_versand', 'sepa_mandat')),
  constraint vertrag_dateien_pfad_check
    check (nullif(btrim(pfad), '') is not null),
  -- Hex aus 32 Bytes, kleingeschrieben. Ein leerer oder abgeschnittener Hash
  -- ist keine Pruefsumme, sondern ein falsches Versprechen.
  constraint vertrag_dateien_sha256_check
    check (sha256 ~ '^[0-9a-f]{64}$'),
  constraint vertrag_dateien_bytes_check
    check (bytes is null or bytes > 0),
  -- Je Vertrag genau ein Dokument je Art. Das ist die Regel "nicht
  -- ueberschreiben" als Datenbankbedingung, nicht als Absichtserklaerung.
  constraint vertrag_dateien_art_uniq unique (vertrag_id, art),
  -- Ein Pfad gehoert zu genau einer Zeile.
  constraint vertrag_dateien_pfad_uniq unique (pfad)
);

comment on table public.vertrag_dateien is
  'Erzeugte Dokumente je Vertrag im Bucket "vertraege": Pfad, Pruefsumme, Urheber.';

alter table public.vertrag_dateien enable row level security;

-- Lesen nur Admin — wie bei vertrag_unterschriften. Geschrieben wird
-- ausschliesslich ueber die RPC unten; es gibt bewusst keine INSERT-Policy.
drop policy if exists vertrag_dateien_admin_select on public.vertrag_dateien;
create policy vertrag_dateien_admin_select on public.vertrag_dateien
  for select using (public.get_my_role() = 'admin');

-- ---------------------------------------------------------------------------
-- Eintragen einer erzeugten Datei.
--
-- Aufrufer ist die Edge Function vertrag_pdf mit dem JWT des Admins: damit
-- steht in erzeugt_von ein Mensch und nicht der Service-Key.
-- ---------------------------------------------------------------------------
create or replace function public.vertrag_datei_eintragen(
  p_vertrag_id uuid,
  p_art        text,
  p_pfad       text,
  p_sha256     text,
  p_bytes      integer default null
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
    raise exception 'vertrag_datei_eintragen: nur Admin' using errcode = '42501';
  end if;

  select status into v_status from public.vertraege where id = p_vertrag_id;
  if v_status is null then
    raise exception 'vertrag_datei_eintragen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  -- Ein Vertragsdokument gibt es erst, wenn der Vertrag steht. Vorher waere es
  -- ein Entwurf mit dem Aussehen einer Urkunde.
  if p_art in ('vertrag', 'unterschrift') and v_status <> 'abgeschlossen' then
    raise exception 'vertrag_datei_eintragen: Vertrag ist nicht abgeschlossen (%)', v_status
      using errcode = 'P0001';
  end if;

  -- Der Pfad muss unter dem Vertrag liegen. Sonst koennte ein Eintrag auf ein
  -- fremdes Dokument zeigen und die Zuordnung waere nur noch Behauptung.
  if p_pfad !~ ('^' || p_vertrag_id::text || '/') then
    raise exception 'vertrag_datei_eintragen: Pfad gehoert nicht zu diesem Vertrag (%)', p_pfad
      using errcode = 'P0001';
  end if;

  begin
    insert into public.vertrag_dateien (vertrag_id, art, pfad, sha256, bytes, erzeugt_von)
    values (p_vertrag_id, p_art, p_pfad, lower(p_sha256), p_bytes, auth.uid())
    returning id into v_id;
  exception when unique_violation then
    raise exception 'vertrag_datei_eintragen: fuer diesen Vertrag gibt es "%" schon', p_art
      using errcode = '23505';
  end;

  -- Kein audit_log-Eintrag: Die Zeile selbst ist das Protokoll — sie traegt
  -- erzeugt_von und erzeugt_am, und geloescht wird hier nichts. audit_log ist
  -- fuer Zugriffe gedacht, die sonst spurlos blieben (etwa die volle IBAN).

  return v_id;
end;
$$;

-- Supabase vergibt EXECUTE per Default Privileges direkt an anon und
-- authenticated; "revoke from public" allein entzieht das nicht.
revoke all on function public.vertrag_datei_eintragen(uuid, text, text, text, integer)
  from public, anon, authenticated;
grant execute on function public.vertrag_datei_eintragen(uuid, text, text, text, integer)
  to authenticated;

commit;
