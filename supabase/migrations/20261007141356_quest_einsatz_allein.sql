-- Q1 Home Quests — Quest-Aufgaben bleiben unter sich (Entscheidung Rasit 06.10., offener Punkt 13).
--
-- quest_inhalt gibt dem Kind den Loesungsweg. Eine Aufgabe mit 'quest' im Einsatz darf deshalb
-- nie zugleich in LSA oder Session drankommen. quest_aufgaben_waehlen ignoriert solche Aufgaben
-- schon; diese Regel macht die Kombination unmoeglich.
--
-- Eigene Regel neben tasks_einsatz_check (X0, 20261007100300), die unveraendert bleibt.
-- Vor dem Anlegen per dbread geprueft (06.10.): 0 Aufgaben verstossen, alle 1183 stehen auf {lsa,session}.

alter table public.tasks
  add constraint tasks_einsatz_quest_allein
  check (not ('quest' = any (einsatz) and einsatz && array['lsa', 'session']::text[]));

comment on constraint tasks_einsatz_quest_allein on public.tasks is
  'Quest-Aufgaben (Loesungsweg geht nach Hause) nie zusammen mit lsa oder session im Einsatz (Q1).';
