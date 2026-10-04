-- report_bausteine: Entwurf neben dem abgenommenen Text (W5-d, Nachtrag 2).
-- Begruendung: docs/report/rueckbezug-texte.md.
--
-- Bisher hiess "einen Satz aendern": text ueberschreiben und freigegeben_am
-- zuruecksetzen (Kommentar in 20260818120000_r4_report_bausteine). Bis zur
-- neuen Abnahme faellt der Satz dann aus jedem Report — beim Rueckbezug
-- "Grundlagen fehlen" stuende ein von den Eltern genannter Punkt ohne Antwort
-- da (R5 verbietet genau das).
--
-- Neu: Spalte entwurf. Der Lesepfad (src/lib/supabase/reportBausteine.ts) liest
-- sie nicht; Eltern sehen weiter den abgenommenen text, bis Lena den Entwurf
-- uebernimmt. Abnahme eines Entwurfs, in EINER Anweisung:
--
--   update report_bausteine
--      set text = entwurf, entwurf = null,
--          freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
--    where slot = 'rueckbezug' and fall = '<fall>' and entwurf is not null;
--
-- (je Fall, damit Variante a und b zusammen wechseln)
--
-- Keine Aenderung an RLS (Lesen admin/coach), keine neue Rolle, kein RPC.
-- Wiederholbar (if not exists / drop if exists). Ohne begin/commit: der Runner klammert.

alter table public.report_bausteine add column if not exists entwurf text;

alter table public.report_bausteine drop constraint if exists report_bausteine_entwurf_check;
alter table public.report_bausteine add constraint report_bausteine_entwurf_check
  check (entwurf is null or (btrim(entwurf) <> '' and entwurf <> text));

comment on column public.report_bausteine.entwurf is
  'W5-d: unabgenommene Neufassung von text. Wird nie ausgeliefert. Abnahme: '
  'update report_bausteine set text = entwurf, entwurf = null, freigegeben_am = now(), '
  'freigegeben_von = ''<profil-uuid>'' where slot = ''rueckbezug'' and fall = ''<fall>'' and entwurf is not null;';
