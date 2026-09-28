-- P4a-2: Die Unterlagen, die fuer alle gleich sind.
--
-- AGB, Widerrufsbelehrung, Datenschutzhinweise und die Foto-Einwilligung
-- enthalten keinen einzigen Platzhalter — sie sind fuer jeden Vertrag
-- derselbe Text. Sie je Vertrag zu erzeugen hiesse, dieselbe Datei hundertmal
-- abzulegen und dabei die Frage zu verlieren, die wirklich zaehlt: WELCHE
-- Fassung hat dieses Elternteil zugestimmt. Die steht schon in
-- vertrag_zustimmungen.
--
-- Also eine Datei je (Art, Fassung), abgelegt unter
-- vertraege/fassungen/<art>/<fassung>.pdf, und vertrag_zustimmungen zeigt
-- darauf. Was sich je Vertrag unterscheidet — Vertrag und SEPA-Mandat —
-- bleibt in vertrag_dateien.

begin;

create table if not exists public.dokument_fassungen (
  art         text not null,
  fassung     text not null,
  pfad        text not null,
  sha256      text not null,
  bytes       integer,
  erzeugt_am  timestamptz not null default now(),
  erzeugt_von uuid references public.profiles (id) on delete set null,
  constraint dokument_fassungen_pkey primary key (art, fassung),
  -- Dieselben Arten wie im Katalog vertrag_dokumente. Vertrag und SEPA-Mandat
  -- gehoeren NICHT dazu: die tragen Werte und liegen je Vertrag.
  constraint dokument_fassungen_art_check
    check (art in ('agb', 'widerruf', 'datenschutz_vertrag', 'einwilligung_fotos')),
  constraint dokument_fassungen_pfad_check
    check (nullif(btrim(pfad), '') is not null),
  constraint dokument_fassungen_sha256_check
    check (sha256 ~ '^[0-9a-f]{64}$'),
  constraint dokument_fassungen_bytes_check
    check (bytes is null or bytes > 0),
  constraint dokument_fassungen_pfad_uniq unique (pfad)
);

comment on table public.dokument_fassungen is
  'Erzeugte PDFs der vertragsunabhaengigen Unterlagen: eine Datei je Art und Fassung.';

alter table public.dokument_fassungen enable row level security;

-- Lesen darf jede angemeldete Person. Das ist der Unterschied zu
-- vertrag_dateien: dort stehen die Daten einer Familie, hier steht, welche
-- AGB-Fassung es gibt. Ein Elternteil, das seine Unterlagen spaeter noch
-- einmal sehen will, braucht diese Zeile — die Datei selbst liegt weiterhin
-- im privaten Bucket und geht nur ueber eine signierte Adresse heraus.
drop policy if exists dokument_fassungen_select on public.dokument_fassungen;
create policy dokument_fassungen_select on public.dokument_fassungen
  for select using (auth.uid() is not null);

-- ---------------------------------------------------------------------------
-- Eintragen einer erzeugten Fassung.
-- ---------------------------------------------------------------------------
create or replace function public.dokument_fassung_eintragen(
  p_art     text,
  p_fassung text,
  p_pfad    text,
  p_sha256  text,
  p_bytes   integer default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_erwartet text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'dokument_fassung_eintragen: nur Admin' using errcode = '42501';
  end if;

  -- Die Fassung muss im Katalog stehen. Sonst entstuende eine Datei zu einer
  -- Fassung, der niemand zustimmen kann — vertrag_zustimmungen zeigt per
  -- Fremdschluessel auf genau diesen Katalog.
  perform 1 from public.vertrag_dokumente
   where schluessel = p_art and version = p_fassung;
  if not found then
    raise exception 'dokument_fassung_eintragen: % in Fassung % steht nicht im Katalog', p_art, p_fassung
      using errcode = 'P0002';
  end if;

  v_erwartet := 'fassungen/' || p_art || '/' || p_fassung || '.pdf';
  if p_pfad <> v_erwartet then
    raise exception 'dokument_fassung_eintragen: Pfad muss % sein, nicht %', v_erwartet, p_pfad
      using errcode = 'P0001';
  end if;

  -- Einmal erzeugt, bleibt es. Eine Fassung ist der Text zu einem Zeitpunkt;
  -- aendert er sich, bekommt er eine neue Fassungskennung, keine neue Datei
  -- unter altem Namen.
  insert into public.dokument_fassungen (art, fassung, pfad, sha256, bytes, erzeugt_von)
  values (p_art, p_fassung, p_pfad, lower(p_sha256), p_bytes, auth.uid())
  on conflict (art, fassung) do nothing;
end;
$$;

-- Supabase vergibt EXECUTE per Default Privileges direkt an anon und
-- authenticated; "revoke from public" allein entzieht das nicht.
revoke all on function public.dokument_fassung_eintragen(text, text, text, text, integer)
  from public, anon, authenticated;
grant execute on function public.dokument_fassung_eintragen(text, text, text, text, integer)
  to authenticated;

commit;
