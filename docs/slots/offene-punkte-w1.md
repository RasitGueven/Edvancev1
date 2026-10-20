# Offene Punkte W1 · Stammplatz am Raum

Stand 20.10.2026 · Migration `20261020150943_slots_w1_raum` · Bauauftrag `Bauauftrag-Slots-Wochenplan-v2.md`, Abschnitt W1.

1. **S4 nicht gebaut.** Ein Raum ohne Coach bleibt für neue Stammplätze und Zusatztermine gesperrt (SL002). Erst nach
   Freigabe durch Tolunay: Warnung statt Sperre.
2. **Umbuchen und Rücknahme ohne Raum.** `termin_umbuchen` legt den neuen Termin ohne Raum an (Zuteilung verteilt),
   `absage_zuruecknehmen` prüft den Platz je Slot. Ein zurückgenommener fester Termin in einem inzwischen vollen Raum
   steht deshalb „ohne Raum“ (`raum_voll`), nicht doppelt im Raum. Raumgenau erst, wenn W2 es braucht.
3. **Vorhandene Termine werden nicht neu geprüft.** Bereits geplante Termine bleiben, wenn ein Raum später seinen Coach
   verliert (Raumwechsel ohne Kinder, Schicht entfernt, „fällt aus“); sie erscheinen als „kein Coach“. Neue Termine
   (z. B. nach Verlängerung der Ferientabelle) entstehen in einem Raum ohne Coach nicht.
4. **Altbestand ohne Raum.** In Prod eine Testzeile in `stammplaetze` (raum_id null). Sie wird weiter verteilt wie bisher.
   Ändern verlangt einen Raum („Raum festlegen“ in W3). `stammplaetze_weiterfuehren` übernimmt den Raum des Vorgängers
   und bricht bei Altbestand mit `raum_fehlt` ab.
5. **Vorschau.** Ohne `p_ersetzt` nimmt `stammplatz_vorschau` an, dass Stammplätze am selben Wochentag ab `p_ab`
   ersetzt werden (W3 gibt beim Ändern `p_ersetzt` mit). Ein Datum, an dem das Kind schon einen festen Termin hat,
   erscheint als `termin`; ein Testkonto-Konflikt (SL013) als `voll`.
6. **`stammplatz_kurz` ist deutscher Text** (Wochentag-Kürzel), wie im Auftrag verlangt. Die Oberfläche nimmt zum
   Anzeigen `stammplaetze` (Wochentag, Beginn, Raum, Takt) über i18n.
7. **Coach am Stammplatz** (`slots_kinder`, `slots_kind`) ist der Coach der Schicht am ersten Tag (heute oder gültig ab).
   Wechselt die Schicht später, zeigt die Liste den Coach erst ab dann.
8. **Raumpflicht im Test abschaltbar.** `slots_raum_pflicht()` liefert in Prod immer `true`; die Altbestand-Tests
   (`slots_fixture.sql`) ersetzen sie in ihrer eigenen Transaktion. Es gibt keinen Weg dafür außer DDL.
9. **`p_jetzt`** steht wie bei allen Slot-Funktionen auch an den neuen Lesefunktionen (nur Tests, nie aus der Oberfläche).
