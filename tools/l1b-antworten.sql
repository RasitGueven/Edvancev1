-- L1 (25.10.2026): Rasits Antworten auf Lenas elf Rückfragen, über pruef_rueckfrage_klaeren.
-- Texte und Aktion: docs/lsa/lena-rueckmeldungen-2026-10-25.md. Erst nach 20261025143853_lena_rueckmeldungen_1025.
--
-- Eine Transaktion, als Rasit (Claims wie in den Tests: sub = Rasits Profil, role authenticated), damit
-- beantwortet_von, reviewed_by und task_admin_protokoll.von stimmen. Kein direktes UPDATE auf task_pruefungen.
-- freigeben: nur known_errors/Hinweise ergänzt oder nichts geändert. an_lena: der Aufgabentext hat sich geändert.

\set ON_ERROR_STOP on
begin;
select set_config('request.jwt.claims',
                  json_build_object('sub', '35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'role', 'authenticated')::text, true);
set local role authenticated;
select public.get_my_role() as rolle;

select t.id, public.pruef_rueckfrage_klaeren(t.id, t.aktion, t.antwort) ->> 'status' as status
  from (values
    (1, 'a394b2eb-df58-4b57-9c79-ae8ff0c62b24'::uuid, 'freigeben',
     'Danke, guter Punkt! −14 ist jetzt als Fehler hinterlegt (Fehlerbild „Plus und Minus vertauscht“): −3 + 4 als −7 gerechnet und dann mal 2. Mitgenommen haben wir auch −11 (derselbe Vorzeichenfehler, aber Punkt vor Strich richtig) und 11 (Minus ganz weggelassen), wie bei den anderen Vorrang-Aufgaben. Dein AFB I bleibt. Freigegeben.'),
    (2, '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', 'an_lena',
     'Danke! Der Text lautet jetzt „Berechne geschickt mit Hilfe einer binomischen Formel.“ (vorher „… mit einer binomischen Formel.“). Weil sich der Text geändert hat, liegt die Aufgabe noch einmal bei dir. Offen ist bei uns noch, dass man 49² mit dem Taschenrechner auch direkt ausrechnen kann. Das klären wir.'),
    (3, '4f0b933d-3ead-4042-adb9-a1369ba28f39', 'an_lena',
     'Danke, übernommen! Teilaufgabe b lautet jetzt „Wenn die Rechnung 45 € beträgt, wie viele Gigabyte wurden in diesem Monat verbraucht?“ (vorher „Wie viele Gigabyte wurden genutzt?“). Der Satz mit den 45 € bleibt oben stehen, weil Teil a ihn für die Gleichung braucht. Die Aufgabe liegt noch einmal bei dir.'),
    (4, 'e8348c89-67cb-4650-be91-235e69321776', 'an_lena',
     'Danke, übernommen! Da steht jetzt nur noch „Löse die Gleichung.“, ohne „Gib den Wert für x an.“ Die Aufgabe liegt noch einmal bei dir.'),
    (5, '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992', 'an_lena',
     'Danke, übernommen! Wie bei 2x + 4 = 20 steht jetzt nur noch „Löse die Gleichung.“ Die Aufgabe liegt noch einmal bei dir.'),
    (6, '19ba5f42-6cd4-4191-afe0-fd8a09c4ac35', 'freigeben',
     'Danke für die Einordnung! Bleibt ein Kind hier hängen und überspringt die Aufgabe, steht sie in der Auswertung als „übersprungen“. Auch das sagt uns etwas. An der Aufgabe ändern wir deshalb nichts. Dein AFB I bleibt. Freigegeben.'),
    (7, '1527a939-6199-4d8c-9163-6f34b0cd0e13', 'freigeben',
     'Danke, guter Hinweis! 3x + 2 ist genau der Fehler „Klammer nur teilweise ausmultipliziert“. Bei Term-Eingaben kann das Tablet Fehler leider noch nicht automatisch erkennen, es prüft nur, ob der Term stimmt. Wir haben den Fehler deshalb als Hinweis an der Aufgabe hinterlegt, die Erkennung kommt später. Freigegeben.'),
    (8, '10a764bc-9657-4a5a-b11d-64b2a0014b05', 'freigeben',
     'Danke! Die beiden Fehler (−3x + 2 und −3x + 6) haben wir als Hinweise an der Aufgabe hinterlegt. Automatisch erkennen kann das Tablet sie bei Termen noch nicht. Den Satz „Gib das Ergebnis in der Form ax + b an.“ lassen wir vorerst stehen: Das Tablet vergleicht den Term Zeichen für Zeichen, ohne den Satz würde zum Beispiel −6 − 3x als falsch gewertet. Sobald die Reihenfolge egal ist, ändern wir das bei allen Term-Aufgaben. Wäre dann „Multipliziere aus und fasse so weit wie möglich zusammen.“ für dich gut? Freigegeben.'),
    (9, 'df219b8c-887d-43c2-b544-ca2df4f32e66', 'freigeben',
     'Danke für die Einordnung! Ist ein Kind unsicher und überspringt die Aufgabe, steht sie in der Auswertung als „übersprungen“. Auch das sagt uns etwas. An der Aufgabe ändern wir deshalb nichts. Freigegeben.'),
    (10, '6ef85b4a-1f14-49b4-acf6-05aa01567e4f', 'freigeben',
     'Danke, übernommen! 4 : 3 = 1,3 (auch 1,33, 1,333 oder 4/3) ist jetzt als Fehler hinterlegt, Fehlerbild „Beim Teilen wurde die Reihenfolge umgedreht“, so wie schon bei 1/2, 1/4 und 1/5. Freigegeben.'),
    (11, '650eed2a-79e5-4a6f-9ed2-a51053fe75c8', 'freigeben',
     'Danke, freut uns! Genau dafür sind die Teilaufgaben da. Wir ändern nichts. Freigegeben.')
  ) t(nr, id, aktion, antwort)
 order by t.nr;
commit;
