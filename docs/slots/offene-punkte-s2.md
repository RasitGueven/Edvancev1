# Slots S2 — offene Punkte

Stand: 15.10.2026 · Paket S2 (Stundenplan aufräumen und Sofort-Dialog) · Branch `feat/rasit-slots-s2-stundenplan`
(ab `origin/dev` 2d5d405, S1 gemergt und eingespielt)

## Entscheidungen, die beim Bauen fielen

1. **Ein primärer Knopf je Bildschirm.** „Session jetzt starten“ steht im Kopf der Slots auf jedem Reiter. Im Reiter
   Stundenplan erscheint er zusätzlich nur dann, wenn die Woche leer ist (im leeren Zustand, als Umriss-Knopf). Zwei gleiche
   primäre Knöpfe auf einem Bildschirm verbietet CLAUDE.md §11. „Session planen“ ist ein Umriss-Knopf, das Formular klappt
   darunter auf.
2. **Höchstens 5 Kinder auch in der Session-Karte** (Nachtrag S1, Punkt 12): Bei 5 Kindern ist „Kinder zuweisen“ gesperrt,
   mit Satz darunter. In der Wahl sperrt die Liste weitere Kinder, sobald die freien Plätze gewählt sind. Die Datenbank
   (`addStudentToSession`) prüft das weiterhin nicht (siehe Punkt 8). Mehrere Kinder werden nacheinander gebucht; lehnt die
   Datenbank eins ab, bleiben die schon gebuchten gebucht und verlassen die Wahl, das abgelehnte bleibt gewählt.
3. **Coach-Filter als Auswahlfeld** aus `session_leitung` (Coaches und Admins), Standard „Alle“. Er steht nicht in der URL;
   die Woche schon.
4. **Text `buchbar.vertrag_ab`** heißt jetzt „Vertrag beginnt am {{datum}}“ (Beispiel aus dem Auftrag), vorher „Vertrag läuft
   ab {{datum}}“.
5. **Kind aus der Akte** ist nur vorgewählt, wenn es heute buchbar ist. Sonst steht es ausgegraut mit Grund in der Liste.
6. **Nach einer Ablehnung** lädt der Dialog die Kinder neu. Wer jetzt nicht mehr buchbar ist, fällt aus der Wahl, denn ein
   gesperrtes Kind ließe sich nicht mehr abwählen. Gleiches gilt in der Session-Karte nach dem Umschalten des Testlaufs.
7. **Testlauf-Schalter in der Karte unverändert.** Er stand vorher unter `src/pages/admin/schedule/` und liegt jetzt unter
   `src/pages/admin/slots/stundenplan/`. Seine Texte sind von `admin.json` (`schedule.testlauf.*`) nach `slots.json`
   (`stundenplan.testlauf.*`) gezogen; `schedule.*` in `admin.json` ist gelöscht.
   `stundenplan_woche` liefert nur `gestartet`, nicht `gestartet_am`. Der Schalter bekommt deshalb ersatzweise den
   Beginn der Session als `gestartet_am`, wenn sie gestartet ist.

## Offene Punkte

8. **Grenze 5 nur in der Oberfläche.** `addStudentToSession` schreibt direkt in `session_students`; eine sechste Buchung
   über einen anderen Weg geht durch. Vorschlag: Trigger oder RPC mit `zu_viele` (Schema-Paket, Rasit entscheidet).
9. **`createSession` prüft nichts** (bestehend): kein Budget, keine Raum- oder Coach-Doppelbelegung, keine Vergangenheit.
   Fehler zeigt „Session planen“ nur allgemein („Das hat nicht geklappt …“), weil `createSession` keinen Code liefert.
10. **Links auf `/admin/schedule`** in „Heute“ (`OffeneSessionsListe`) bleiben; die Umleitung führt in den Reiter. Direkt
    verlinken wäre eine Zeile, ändert aber `HeutePage.test`; nicht im Umfang.
11. **Doppelbelegung im Dialog** (S1 Punkt 13): Der Sofort-Dialog warnt nicht, wenn Raum oder Leitung gerade belegt sind.
12. **Kinderliste lädt je Karte** erst beim Aufklappen (`kinder_buchbar` mit Session). Bei vielen offenen Karten mehrere
    Aufrufe; heute unkritisch.
13. **Live-Sicht-Link auch bei erledigten Sessions** (Auftrag: „je Session“). Ob die Live-Sicht danach etwas Sinnvolles
    zeigt, entscheidet die Live-Sicht.
14. **`App.tsx` hat 474 Zeilen** (schon vor S2 über 400). S2 ändert dort nur Import und Umleitung (netto 0 Zeilen).
15. **„Test“ neben dem Namen in der Karte** steht als eigenes Kennzeichen neben dem Namens-Chip (wie in den übrigen
    Slots-Ansichten). Auf dem Bildschirmfoto wirkt es fast wie ein weiteres Kind; ggf. in S3 im Chip zusammenfassen.
