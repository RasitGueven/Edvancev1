# Slots SL2 — offene Punkte

Stand: 12.10.2026 · Paket SL2 · Branch `feat/rasit-slots-sl2-oberflaeche` (ab `origin/dev` af3998e)

## Was am Datenvertrag fehlte

Nichts, das die Oberfläche nachbauen musste. Alles, was der Server entscheidet (Kapazität, Wochengrenze,
Planbilanz, Zuteilung, gültige Ziele, Kandidaten), kommt aus den Lesefunktionen; die 10-Uhr-Regel steht im
Absage-Dialog nur als Vorschau mit derselben Regel, gesendet wird der Eingang.

## Offene Punkte

1. **`App.tsx` hat 446 Zeilen.** Die Datei hatte auf dev schon 430 (Grenze 400). SL2 darf dort nur die Slots-Routen
   ändern; die zwei neuen Routen (Termin, Kind) bringen 16 Zeilen. Ein Aufteilen der Routen gehört in ein eigenes Paket.
2. **Titel der Einzel-Sessions.** `/admin/schedule` heißt jetzt „Einzel-Sessions und Testläufe“. Geändert ist nur der Wert
   von `admin:schedule.titel`, nicht die Seite (T2 baut dort). Erreichbar über Slots → Einstellungen → „Einzel-Sessions
   öffnen“; in der Leiste ist dann „Slots“ aktiv.
3. **Leisten-Schlüssel umbenannt.** `admin:nav.stundenplan` und `nav.kurz.stundenplan` heißen jetzt `nav.slots` und
   `nav.kurz.slots` („Slots“). Andere Stellen nutzen sie nicht.
4. **Stammschicht entfernen** beendet sie ab heute (`stammschicht_beenden(p_id, heute)`), nach einer Bestätigung inline an
   der Zelle. Ein späteres Enddatum lässt sich in der Oberfläche nicht wählen; für die Planung reicht „ab heute“.
5. **„Diese Woche“** bleibt in der aktuellen Woche bedienbar (gedämpft, `aria-current`), statt gesperrt zu sein.
6. **Bildschirmfotos** stammen aus der echten App mit Fake-Client. Die Daten sind die Ausgabe der Slot-Funktionen in einer
   Wegwerf-DB (erfundene Namen, Uhr auf Mo 13.03.2028, 09:12). Fünf Coaches und 48 Kinder wie im Dummy; die Namen
   unterscheiden sich vom Dummy.
7. **S10-Tabellen** (`slots`, `slot_wishes`, `slot_assignments`) bleiben in der Datenbank, nur ihre Oberfläche und ihr
   Frontend-Code sind entfernt (Entscheidung 25).
8. **Kartentitel in `text-base`.** Die Gestaltungs-Abnahme zählt unter dem Seitenkopf vier Größen (xs, sm, base und die
   Kennzahlen). `text-base font-semibold` ist der Kartentitel nach CLAUDE.md §11 (Typografie-Hierarchie); die Regel
   „höchstens drei Größen“ und die Hierarchie widersprechen sich dort. Bleibt bis zur Klärung so.
9. **Abstand vor dem Punkt in Datumsangaben** („13.03 .“ unter `tabular-nums`). Kommt aus den Ziffernformen der
   Schrift; ein Ausnehmen des Punkts bräuchte ein eigenes Span je Datum. Nachrangig, offen.
10. **Platz-Punkte brechen ab drei Räumen um** (15 Punkte in einer Zelle). `PlatzPunkte` ist ein geteilter Baustein aus
    SL1; eine kleinere Punktform gehört dorthin, nicht in SL2.
