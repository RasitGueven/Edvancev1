# Offene Punkte W4 · Coaches: Schichten als Block

Stand 20.10.2026 · Branch `feat/rasit-slots-w4-coaches` · Bauauftrag `Bauauftrag-Slots-Wochenplan-v2.md`, Abschnitt W4 ·
Vorlage `slots-dummy-v2.html` (Reiter Coaches). Reine Oberfläche, keine Migration, nichts unter `src/lib/supabase/**`,
`src/types/**` oder `supabase/**`.

## Abweichungen vom Dummy (mit Grund)

1. **„Stammplätze“ statt „Kinder“.** `slots_coaches` liefert `kinder` je Stunde (distinct je Stunde, nicht je Block).
   Der Block zeigt die Summe je Stunde und nennt sie korrekt „n Stammplätze in diesem Raum“; ein Kind mit Stammplatz in
   zwei Stunden des Blocks zählt zweimal. Ebenso im Dialog „Raum ändern“: „Ohne Häkchen bleiben die n Stammplätze in
   Raum Y“ und „n Stammplätze mit in Raum X nehmen“ (das passt zu `stammschicht_raum_wechseln.kinder`, das ebenfalls
   Stammplatz-Zeilen zählt). Für die Kinderzahl wie im Dummy (distinct im Block) siehe offene Punkte Nr. 1.
2. **Blöcke gelten für die gewählte Woche.** Je Wochentag zählt die Schicht, die am Tag dieser Woche gilt
   (`gueltig_ab ≤ Tag ≤ gueltig_bis`). `slots_coaches` liefert auch künftige Schichten; sie bilden eigene Blöcke mit
   dem Kennzeichen „ab TT.MM.“ (z. B. nach „Raum ändern“ ab nächstem Montag steht der alte Block mit „bis …“ und der
   neue mit „ab …“). Ein Block hat ein gemeinsames Ende: unterschiedliches `gueltig_bis` (bzw. künftiger Beginn) trennt
   ihn, sonst stimmte „bis“ nicht für alle Stunden. Die Wochen-Navigation steht deshalb über den Karten.
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

1. **Kinder distinct je Block fehlen.** Für „n Kinder“ wie im Dummy bräuchte `slots_coaches` je Stammschicht die
   `student_id`s (oder je Block eine Zählung). Erweiterung im Foundation-Fenster; bis dahin „Stammplätze“ (siehe oben).
2. **Entfernen ist nicht atomar.** `stammschicht_beenden` je Stunde nacheinander; scheitert eine, steht „Nicht alle
   Stunden wurden entfernt (k von n) …“ im Dialog und die Liste lädt neu. Erneutes Entfernen ist unschädlich (die
   Funktion kürzt nur). Eine Funktion `stammschicht_block_beenden(p_ids, p_ab)` (alles oder nichts) wäre sauberer.
3. **Konfliktsatz bei `coach:`/`raum:` aus geladenen Daten.** Coach bzw. Raum zur Uhrzeit kommen aus `slots_coaches`
   der gewählten Woche. Liegt die störende Schicht außerhalb (z. B. endet vor Montag der gewählten Woche, aber nach
   heute), steht der Satz ohne Namen („Raum B1 ist Do 16:00 schon besetzt.“). Ein `detail` mit Coach/Raum im Fehler
   von `stammschicht_block_anlegen` würde das schließen (Foundation).
4. **`doppelt` (SL009 beim Raumwechsel)** erscheint als allgemeiner SL009-Satz; die Oberfläche übergibt nie zwei Schichten
   derselben Stunde, der Fall tritt nur bei veralteten Daten auf.
5. **Alte Texte `coaches.*`** (Raster, `neuLabel`, `wegFrage` u. a.) sind ungenutzt und stehen geblieben; aufräumen
   zusammen mit offene-punkte-w2 Nr. 6 und w3 Nr. 1. Genutzt bleiben `coaches.leerTitel` und `coaches.leerText`.
6. **Disabled-Knöpfe und `title`:** Der Grund steht als Satz unter dem Knopf und im `title`; `Button` setzt bei
   `disabled` `pointer-events-none`, der Tooltip erscheint deshalb nicht beim Darüberfahren (bestehendes Verhalten).
