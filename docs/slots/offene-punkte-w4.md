# Offene Punkte W4 · Coaches: Schichten als Block

Stand 20.10.2026 · Branch `feat/rasit-slots-w4-coaches` · Bauauftrag `Bauauftrag-Slots-Wochenplan-v2.md`, Abschnitt W4 ·
Vorlage `slots-dummy-v2.html` (Reiter Coaches). Reine Oberfläche, keine Migration, nichts unter `src/lib/supabase/**`,
`src/types/**` oder `supabase/**`.

## Abweichungen vom Dummy (mit Grund)

1. **Kinderzahl als Summe je Stunde.** `slots_coaches` liefert `kinder` je Stunde. Der Block zeigt die Summe über
   seine Stunden als „n Kinder mit Stammplatz“, ebenso im Dialog „Raum ändern“ („Ohne Häkchen bleiben die n Kinder in
   Raum Y“, „n Kinder mit in Raum X nehmen“). Das ist die Kinderzahl wie im Dummy, weil ein Kind am selben Wochentag nur
   einen Stammplatz haben kann (SL008, gleicher Wochentag mit überlappendem Takt gesperrt); Ausnahme siehe offene
   Punkte Nr. 1.
2. **Blöcke gelten für die gewählte Woche.** Je Wochentag zählt die Schicht, die am Tag dieser Woche gilt
   (`gueltig_ab ≤ Tag ≤ gueltig_bis`). `slots_coaches` liefert auch künftige Schichten; sie bilden eigene Blöcke mit
   dem Kennzeichen „ab TT.MM.“ (z. B. nach „Raum ändern“ ab nächstem Montag steht der alte Block mit „bis …“ und der
   neue mit „ab …“). Ein Block hat ein gemeinsames Ende: unterschiedliches `gueltig_bis` (bzw. künftiger Beginn) trennt
   ihn, sonst stimmte „bis“ nicht für alle Stunden. „ab“ ist der erste Termin an diesem Wochentag (eine Montag-Schicht
   ab Dienstag 20.10. steht als „ab 26.10.“). Die Wochen-Navigation steht deshalb über den Karten.
   Ein Block, der vor dem Standarddatum endet (z. B. „bis 25.10.“ nach einem Raumwechsel ab nächstem Montag), bietet
   weder „Raum ändern“ noch „Entfernen“, sondern „läuft aus, nichts mehr zu ändern“. In den Dialogen ist ein Datum nach
   dem Ende gesperrt mit Satz (kein Aufruf, kein Erfolgs-Toast). Standarddatum ist der nächste Montag, frühestens das
   späteste `gueltig_ab` der Stunden des Blocks; der Zielraum wird ab diesem Datum geprüft.
3. **Abweichungen der Woche bleiben auf der Karte** (Vertretung, fällt aus), nur zum Lesen, als Verweis ins Slot-Panel
   im selben Reiter (`?slot=…`, Zurück schließt es). Erledigt damit offene-punkte-w2 Nr. 5 für den Reiter Coaches; die
   Umleitung `/admin/slots/termin/…` bleibt („Heute im Betrieb“ verlinkt sie weiter). Schließt sich das Panel, lädt der
   Reiter die Coaches neu.
4. **„Schicht eintragen“ ohne Datumsfeld:** gilt ab heute (`p_gueltig_ab` null), wie der Satz im Dummy („gilt in jeder
   Betriebswoche“). Uhrzeiten und Räume aus `slots_coaches` (aktiv in der gewählten Woche).
5. **Je Block zwei Knöpfe** („Raum ändern“, „Entfernen“) wie im Dummy, beide als ruhige Knöpfe mit 44 px; der einzige
   gefüllte Knopf des Reiters ist „Schicht eintragen“. Eine Karte mit mehreren Blöcken hat damit mehr als zwei Aktionen
   (Admin-Fläche, je Zeile zwei).
6. **„Entfernen“ mit Datum.** Der Dummy entfernt sofort; gebaut ist ein Datumsfeld „entfernen ab“ (Standard nächster
   Montag), wie im Auftrag (Entscheidung 4).
7. **Hinweis-Kästen des Dummys** (gelb, Erklärung fürs Gespräch) sind nicht gebaut.
8. **Gesperrter Zielraum** nennt Wochentag, Uhrzeit und Coach („Raum A1 ist dann schon besetzt: Mi 15:00 Mehmet
   Arslan.“); geprüft wird wie in `stammschicht_raum_wechseln` jede andere Schicht im Zielraum, die am Datum „gültig ab“
   oder später noch gilt, also auch eine künftige.

## Offene Punkte

1. **A-/B-Woche zu zwei Stunden desselben Blocks.** Ein Kind mit Stammplatz in der A-Woche um 14:00 und in der
   B-Woche um 15:00 am selben Wochentag im selben Raum zählt im Block zweimal (die Takte überlappen nicht, SL008 greift
   nicht). Genau wäre eine Zählung je Block mit distinct `student_id` in `slots_coaches` (Foundation).
2. **Entfernen ist nicht atomar.** `stammschicht_beenden` je Stunde nacheinander; scheitert eine, steht „Nicht alle
   Stunden wurden entfernt (k von n) …“ im Dialog und die Liste lädt neu. Erneutes Entfernen ist unschädlich (die
   Funktion kürzt nur). Eine Funktion `stammschicht_block_beenden(p_ids, p_ab)` (alles oder nichts) wäre sauberer.
3. **Konfliktsatz bei `coach:`/`raum:` aus geladenen Daten.** Coach bzw. Raum zur Uhrzeit kommen aus `slots_coaches`
   der gewählten Woche. Liegt die störende Schicht außerhalb (z. B. endet vor Montag der gewählten Woche, aber nach
   heute), steht der Satz ohne Namen („Raum B1 ist Do 16:00 schon besetzt.“). Ein `detail` mit Coach/Raum im Fehler
   von `stammschicht_block_anlegen` würde das schließen (Foundation).
   Der Satz nimmt die am Prüfdatum gültige Schicht (heute beim Eintragen, „gültig ab“ beim Raumwechsel).
4. **`doppelt` (SL009 beim Raumwechsel)** erscheint als allgemeiner SL009-Satz; die Oberfläche übergibt nie zwei Schichten
   derselben Stunde, der Fall tritt nur bei veralteten Daten auf.
5. **Alte Texte `coaches.*`** (Raster, `neuLabel`, `wegFrage` u. a.) sind ungenutzt und stehen geblieben; aufräumen
   zusammen mit offene-punkte-w2 Nr. 6 und w3 Nr. 1. Genutzt bleiben `coaches.leerTitel` und `coaches.leerText`.
6. **Disabled-Knöpfe und `title`:** Der Grund steht als Satz unter dem Knopf und im `title`; `Button` setzt bei
   `disabled` `pointer-events-none`, der Tooltip erscheint deshalb nicht beim Darüberfahren (bestehendes Verhalten).
7. **Server (Foundation): annullierte Schichten zählen als belegt.** `stammschicht_block_anlegen` und
   `stammschicht_raum_wechseln` prüfen jede Zeile mit `gueltig_bis ≥ ab`, also auch vor Beginn annullierte
   (`gueltig_bis = gueltig_ab - 1`). `slots_coaches` filtert diese Zeilen, die Oberfläche findet dann keinen Namen und
   zeigt SL009 als Satz ohne Coach; eintragen lässt sich die Stunde trotzdem nicht. Vorschlag für beide Prüfungen:
   `and y.gueltig_bis is distinct from y.gueltig_ab - 1`. In W4 nicht änderbar (`supabase/**`).
