-- P5 Nachtrag — tasks.afb an Item 1 setzen.
--
-- task_status_set verlangt fuer 'ready' ein afb AM ITEM. Am Handytarif-Item
-- steht die Spalte auf null, die Freigabe scheitert mit
--   task_status_set: AFB fehlt   (P0001)
-- obwohl die uebrigen fuenf Pflichtfelder gesetzt sind und lsa_has_answers
-- erfuellt ist. Diese Migration setzt genau diese eine Spalte.
--
-- Zum Wert: 'II' — roemische Ziffer, formatgleich zum Bestand. Nachgesehen,
-- nicht geraten:
--   select distinct afb from tasks where afb is not null;  -> I, II, III
--   CHECK (afb = ANY (ARRAY['I','II','III']))
-- Dieselben drei Werte fuehren auch die Teilaufgaben in parts[].afb.
--
-- Zur Vorgeschichte, damit die Akte stimmt: die P5-Migration
-- (20260814140000) setzt afb sehr wohl auf Item-Ebene — Zeile 153, zusaetzlich
-- zu den beiden Teilaufgaben. Unmittelbar nach dem Apply stand die Spalte auf
-- 'II' (belegt: die PRUEFUNG lief gegen Produktion gruen, und ihr Fall F3
-- bricht bei afb null ab). Der Wert ist danach verloren gegangen; im Code gibt
-- es keinen Pfad, der ihn nullt — weder Trigger noch RPC noch die eine
-- tasks-Update-Stelle im Frontend, die ausschliesslich `{ status }` schreibt.
-- Fuer den Nachtrag macht das keinen Unterschied, fuer die Suche nach der
-- Ursache schon.
--
-- begin/commit in der Datei, wie bei 20260814140000: scripts/db-migrate.sh
-- ruft psql ohne --single-transaction, und die Kontrollzaehlung unten soll den
-- update mitrollen koennen, statt ihn schon committet vorzufinden.

begin;

update public.tasks
   set afb = 'II'
 where source = 'edvance_p5_modellieren'
   and source_ref = 'handytarif-01';


-- ── Kontrolle ───────────────────────────────────────────────────────────────
--
-- Ein update, das keine Zeile trifft, ist still. Auf einer Datenbank ohne das
-- Item (etwa dem leeren Schnappschuss vor der P5-Migration) waere das richtig;
-- steht das Item da, muss danach ein afb dran sein.

do $$
declare
  v_afb text;
begin
  select afb into v_afb from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref = 'handytarif-01';

  if not found then
    raise notice 'P5-Nachtrag: Item 1 nicht vorhanden — nichts zu tun';
    return;
  end if;

  if v_afb is distinct from 'II' then
    raise exception 'P5-Nachtrag: afb ist %, erwartet II', coalesce(v_afb, '<null>');
  end if;

  raise notice 'P5-Nachtrag: afb = II am Item gesetzt';
end $$;

commit;
