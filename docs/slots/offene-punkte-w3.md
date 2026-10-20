# Offene Punkte W3 · Kinder und Stammplatz-Dialog

Stand 20.10.2026 · Branch `feat/rasit-slots-w3-kinder` · Bauauftrag `Bauauftrag-Slots-Wochenplan-v2.md`, Abschnitt W3 ·
Vorlage `slots-dummy-v2.html` (Reiter Kinder, Dialog „Stammplatz vergeben“). Reine Oberfläche, keine Migration, nichts
unter `src/lib/supabase/**`, `src/types/**` oder `supabase/**`.

## Abweichungen vom Dummy (mit Grund)

1. **Raum ohne Coach ist gesperrt, keine Warnung.** Der Dummy zeigt S4 (Warnung, Speichern geht). S4 ist nicht
   freigegeben: Die Karte ist nicht wählbar und sagt „… hat am … um … keinen Coach. Ohne Coach-Schicht ist der Raum
   nicht wählbar.“
2. **Gesperrt wird nach dem ersten Termin der Vorschau des Raums** (erste Zeile, die nicht Ferien, Feiertag oder andere
   Woche ist), wie die Karte „n von 5 frei“ am ersten Termin zeigt. Ist ein Raum erst an einem späteren Datum voll
   oder ohne Coach, steht das in „Die nächsten Termine“ als „entfällt“, und die Gründe der Planbilanz-Vorschau
   (SL001/SL002 je Raum, W1) sperren Speichern mit Satz.
3. **„voll“ mit weniger als fünf Kindern** (Testkonto-Konflikt, offene-punkte-w1 Nr. 5) heißt in der Vorschau „In … sitzen
   an diesem Tag Kinder der anderen Art (Testkonto oder echt), kein Termin“, nicht „voll (5 von 5)“.
4. **Mehrere Zeilen bleiben.** Der Dummy hat eine Zeile; der Dialog legt wie bisher je Rhythmus-Einheit eine Zeile an
   (z. B. 1× pro Woche + 14-täglich) und zeigt Raum-Karten und Vorschau für die gewählte Zeile. Jede Zeile braucht
   einen Raum. Bei einer einzigen Zeile entfällt der Vorsatz „Zeile 1:“ in den Gründen.
5. **Raster „freie Plätze“ entfällt** (`dialoge/FreiRaster.tsx` gelöscht). Es zeigte freie Plätze je Slot über alle
   Räume; die Raum-Karten ersetzen es wie im Dummy. Uhrzeiten und Räume kommen jetzt aus `slots_einstellungen`
   (aktiv am Datum „gültig ab“), `slots_frei` ruft der Dialog nicht mehr auf.
6. **Spalten Einheiten und Stichtag entfallen** in der Liste (Entscheidung 1 nennt sie nicht). Einheiten und Stichtag
   stehen weiter auf der Kind-Seite; beginnt ein Vertrag später, steht „ab TT.MM.“ unter dem Paket.
7. **Karte „Ohne Stammplatz“ über der Liste entfällt**; Kinder ohne Stammplatz stehen oben in der Liste (Entscheidung 2).
   „Wie bisher weiterführen (…)“ bei einem Folgevertrag ist dort der Knopf der Aktion-Spalte, „Stammplatz vergeben“
   steht im „…“-Menü daneben.
8. **Aktion bei mehreren Stammplätzen:** Statt eines „Ändern“ (Dummy: immer der erste) ein „…“-Menü mit „<Stammplatz>
   ändern“ je Stammplatz. Altbestand ohne Raum hat Vorrang: „Raum festlegen“.
9. **Zeile nicht mehr klickbar.** Der Name ist der Link zur Kind-Seite; die ganze Zeile als Knopf vertrüge sich nicht
   mit den Knöpfen der Aktion-Spalte.
10. **Filter in der Adresse:** `?filter=ohne` und `?test=aus` (Standard: Testkonten an). Der Link der Wochenplan-Kennzahl
    `?filter=kein_stammplatz` (W2) gilt als „Ohne Stammplatz“; die alten Planbilanz-Filter fallen auf „Alle“.
11. **Coach-Spalte beim Altbestand „–“** statt „keine Schicht“: Ohne Raum gibt es keine Schicht, an der der Coach hinge.

## Offene Punkte

1. **Nicht mehr benutzte Filter-Logik** in `slots.model.ts` (`KINDER_FILTER`, `kinderGefiltert`, `anzahlJeFilter`,
   `filterAusSuche`) und ihre Texte (`kinder.filter.*`, `kinder.spalte.einheiten/stichtag`, `kinder.ohne.titel` u. a.,
   `dialog.stamm.frei/rasterLabel/keinRaum/voll/freiLabel*/uebersprungen/zeitOhneRaum/artKonflikt*`) sind stehen
   geblieben (Datei außerhalb des W3-Umfangs, Test `slots.model.test.ts` hängt daran). Aufräumen zusammen mit
   offene-punkte-w2 Nr. 6 nach dem Merge von W2–W4. `ladeFrei` hat keinen Aufrufer mehr in der Oberfläche.
2. **Je Raum ein Aufruf von `stammplatz_vorschau`.** Bei vier Räumen vier Aufrufe je Änderung von Tag, Uhrzeit, Takt
   oder Datum. Für die Raum-Karten würde eine Lesefunktion „Stand aller Räume am ersten Termin“ einen Aufruf sparen
   (Foundation, nicht nötig für den Betrieb).
3. **Coach im Stammplatz** (Liste, Kind-Seite) ist der Coach der Schicht am ersten Tag (offene-punkte-w1 Nr. 7).
4. **Erledigt aus offene-punkte-w2 Nr. 4:** `kind/KindKarten.tsx` importiert `ZustandBadge` aus `../panel/TerminKarten`,
   `termin/TerminKarten.tsx` ist gelöscht.
5. **„Raum festlegen“ beim Altbestand** ändert ab nächstem Montag (Standard von „Ändern ab …“); früher geht über das
   Datum im Dialog. Ein Stammplatz ohne Raum bleibt bis dahin „automatisch“ verteilt.
