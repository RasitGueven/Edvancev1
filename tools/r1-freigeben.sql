-- R1 (29.10.2026): Rasits Antworten auf Lenas Rückfragen der Klassen A und B, über pruef_rueckfrage_klaeren.
-- Einordnung: docs/rueckfragen/R1/einordnung.md. Erst nach 20261029091200_r1_lena_rueckfragen.
--
-- Eine Transaktion, als Rasit (Claims: sub = Rasits Profil, role authenticated), damit beantwortet_von, reviewed_by
-- und task_admin_protokoll.von stimmen. Kein direktes UPDATE auf status oder task_pruefungen.
-- Klasse C (a61e8be9, 1bbce78e) bleibt rueckfrage und steht hier nicht.

\set ON_ERROR_STOP on
begin;
-- Vorbedingung noch als Verbindungsrolle: authenticated darf task_solutions nicht lesen.
do $v$
begin
  if not exists (select 1 from public.task_solutions where task_id = 'ffc76634-86ca-4c53-b816-d18d7f868443'
                    and acceptance -> 'known_errors' ? '-18') then
    raise exception 'r1: Migration 20261029091200 fehlt';
  end if;
end $v$;

select set_config('request.jwt.claims',
                  json_build_object('sub', '35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'role', 'authenticated')::text, true);
set local role authenticated;
select public.get_my_role() as rolle;
do $r$ begin if public.get_my_role() is distinct from 'admin' then raise exception 'r1: nicht als admin'; end if; end $r$;

select t.id, public.pruef_rueckfrage_klaeren(t.id, 'freigeben', t.antwort) ->> 'status' as status
  from (values
    (1, '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'::uuid,
     'Danke, übernommen! Da steht jetzt „Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.“ Aus „für x = 100“ haben wir „für x den Wert 100“ gemacht, das liest sich glatter. Außerdem zählt jetzt auch „+1029“ als richtig. Freigegeben.'),
    (2, 'ffc76634-86ca-4c53-b816-d18d7f868443',
     'Danke, guter Punkt! Vertauscht ein Kind x und y bei der Steigung und beim Einsetzen, kommt m = 1/3 und b = 2/3 heraus (A(1 | 1) bleibt beim Vertauschen gleich). Das war schon als Fehler „Steigung auf dem Kopf“ hinterlegt, jetzt auch dezimal (0,67 usw.). Neu dazu: Nur beim Einsetzen von B vertauscht gibt b = −18 (Fehlerbild „x und y vertauscht“), nur bei der Steigung vertauscht und dann B eingesetzt gibt b = 6. Freigegeben.'),
    (3, '158c874c-248c-40ed-b8b5-af3eb627517a',
     'Danke für den Hinweis! Stellt ein Kind nach y um, kommt trotzdem x = 5 und y = 3 heraus, das Gleichungssystem hat nur diese eine Lösung. Getippt wird nur das Ergebnis, das Kind verliert also nichts. An der Aufgabe ändern wir deshalb nichts. Dein AFB I bleibt. Freigegeben.'),
    (4, '6274f6a5-65e5-40f4-be09-36fa8931c424',
     'Danke, guter Punkt! Nimmt ein Kind die Dreiecksformel mit beiden Diagonalen (24 · 10 : 2), kommt genau 120 heraus, denn die Raute besteht aus zwei solchen Dreiecken. Neu hinterlegt haben wir: nur ein Dreieck gerechnet (60, bei einem Viertel 30) und die Dreiecksformel mit der Seite 13 (65 oder 156). Dein AFB I bleibt. Freigegeben.')
  ) t(nr, id, antwort)
 order by t.nr;
commit;
