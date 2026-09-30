-- VORSCHLAG — NICHT EINSPIELEN. Liegt bewusst nicht in supabase/migrations/.
--
-- Zweck: "vorbefuellt" von "von Lena geprueft" unterscheiden (Luecke L4 in
-- docs/prefill/bestandsaufnahme.md). Heute gibt es dafuer kein Merkmal — ein
-- vorbefuellter Wert sieht in der Item-Pflege aus wie ein von Hand gepflegter.
--
-- Entwurf: ein Protokoll je vorbefuelltem Feld (auch je Teilaufgabe), append-only
-- bis auf die Bestaetigung. Die Prefill-Migrationen schreiben je gesetztem Wert eine
-- Zeile; die Item-Pflege zeigt an offenen Zeilen ein "vorbefuellt"-Badge und
-- bestaetigt beim Speichern bzw. bei "zur Freigabe" alle offenen Zeilen der Aufgabe.
--
-- Auth/RLS-Aenderung: braucht laut CLAUDE.md Rasits ausdrueckliche Bestaetigung
-- und eine zweite unabhaengige Pruefung (Consensus-Trigger).

create table public.task_prefill (
  id             bigint generated always as identity primary key,
  task_id        uuid not null references public.tasks (id) on delete cascade,
  teil           integer,                         -- null = Aufgabenebene
  feld           text not null,                   -- z. B. 'afb', 'correct_answers', 'hints'
  wert           jsonb not null,                  -- der vorbefuellte Wert zum Zeitpunkt des Setzens
  charge         text not null,                   -- z. B. 'mathe8-pilot'
  sicherheit     text not null check (sicherheit in ('hoch', 'mittel', 'niedrig')),
  grund          text not null check (btrim(grund) <> ''),
  gesetzt_am     timestamptz not null default now(),
  bestaetigt_von uuid references public.profiles (id),
  bestaetigt_am  timestamptz,
  check ((bestaetigt_von is null) = (bestaetigt_am is null))
);
create unique index task_prefill_eindeutig on public.task_prefill (task_id, coalesce(teil, 0), feld, charge);
create index task_prefill_offen on public.task_prefill (task_id) where bestaetigt_am is null;

alter table public.task_prefill enable row level security;

-- Lesen: wer pruefen darf (Admin oder Coach mit darf_pruefen). Kein direktes Schreiben.
create policy task_prefill_select on public.task_prefill
  for select to authenticated
  using (public.get_my_role() = 'admin' or public.darf_pruefen());

-- Bestaetigen nur ueber die RPC; setzt ausschliesslich die Bestaetigungsspalten.
create function public.task_prefill_bestaetigen(p_task_id uuid) returns integer
  language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if not (public.get_my_role() = 'admin' or public.darf_pruefen()) then
    raise exception 'Vorbefuellung bestaetigen: keine Berechtigung' using errcode = '42501';
  end if;
  update public.task_prefill
     set bestaetigt_von = auth.uid(), bestaetigt_am = now()
   where task_id = p_task_id and bestaetigt_am is null;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.task_prefill_bestaetigen(uuid) from public;
grant execute on function public.task_prefill_bestaetigen(uuid) to authenticated;
