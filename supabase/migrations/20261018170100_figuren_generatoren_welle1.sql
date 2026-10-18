-- Figuren Welle 1 (F2, PR 1): drei Generatoren fuer task_figures zulassen.
--
--   thales     scripts/figures/thales.py     Kreis/Halbkreis mit Dreieck ABC und Winkelboegen
--   rechtecke  scripts/figures/rechtecke.py  zusammengesetzte Rechtecke, Masse als Text
--   rechteck   scripts/figures/rechteck.ts   ein Rechteck, Masse als Zahl oder Term
--                                            (Python-Adapter figures/rechteck.py, ruft tsx)
--
-- Die Positivliste muss mit GENERATOREN in scripts/figures/upload_figures.py
-- uebereinstimmen; test_upload_figures.py vergleicht beide.
-- Nur der CHECK aendert sich, keine Daten. Die Figuren selbst kommen mit PR 2.

alter table public.task_figures drop constraint if exists task_figures_generator_check;
alter table public.task_figures add constraint task_figures_generator_check
  check (generator = any (array['koordinatensystem', 'winkel', 'thales', 'rechtecke', 'rechteck']));
