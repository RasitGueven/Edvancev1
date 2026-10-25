-- L1 Nachtrag (25.10.2026): Rasit hat die vier Text-Aufgaben direkt freigegeben (pruef_admin_freigeben), statt sie an
-- Lena zurückzugeben. Der Satz „… liegt noch einmal bei dir.“ in den Antworten stimmt deshalb nicht mehr.
--
-- Freigabe Rasit (25.10.2026) für ein direktes UPDATE, denn pruef_rueckfrage_klaeren nimmt nur Aufgaben in
-- 'rueckfrage'. Der Trigger task_pruefungen_nur_anhaengen lässt antwort/beantwortet_* zu. Nur die letzte Zeile je
-- Aufgabe, nur wo der alte Text steht; beantwortet_von bleibt Rasit, beantwortet_am wird neu gesetzt.

\set ON_ERROR_STOP on
begin;
with neu(task_id, alt, neu) as (values
  ('3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'::uuid,
   'Weil sich der Text geändert hat, liegt die Aufgabe noch einmal bei dir.', 'Wir haben die Aufgabe direkt freigegeben.'),
  ('4f0b933d-3ead-4042-adb9-a1369ba28f39', 'Die Aufgabe liegt noch einmal bei dir.', 'Wir haben die Aufgabe direkt freigegeben.'),
  ('e8348c89-67cb-4650-be91-235e69321776', 'Die Aufgabe liegt noch einmal bei dir.', 'Wir haben die Aufgabe direkt freigegeben.'),
  ('7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992', 'Die Aufgabe liegt noch einmal bei dir.', 'Wir haben die Aufgabe direkt freigegeben.')),
letzte as (
  select distinct on (p.task_id) p.id, p.task_id from public.task_pruefungen p
   where p.task_id in (select task_id from neu) order by p.task_id, p.geprueft_am desc)
update public.task_pruefungen p
   set antwort = replace(p.antwort, n.alt, n.neu), beantwortet_am = now()
  from letzte l join neu n on n.task_id = l.task_id
 where p.id = l.id and p.antwort like '%' || n.alt || '%'
   and p.beantwortet_von = '35e4f9ac-d9aa-421c-8ba8-3948b1575f41'
returning left(p.task_id::text, 8) as aufgabe, p.antwort;
commit;
