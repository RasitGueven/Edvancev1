# Slots S1 — offene Punkte

Stand: 15.10.2026 · Paket S1 (Sofort-Session und Buchbarkeit mit Grund) · Branch `feat/rasit-slots-s1-sofort`
(ab `origin/dev` 8ab4fae)

## Entscheidungen, die beim Bauen fielen

1. **Brückentag gilt als `keine_einheit`.** Zwischen einem beendeten Vertrag und einem verknüpften Folgevertrag
   (`vertrag_bruecke`) sagt `session_platz_zugang` ja, aber `slots_vertrag_am` findet keinen Vertrag. Eine
   Einzelbuchung an so einem Tag würde `slots_fest_belegt` keinem Vertrag anrechnen, die Session wäre gratis.
   Deshalb `keine_einheit` für echte Kinder. Testkinder sind an Brückentagen `ok`. Soll ein Brückentag buchbar sein,
   braucht es eine Regel, welchem Vertrag die Einheit gehört.
2. **`vertrag_beendet` meldet bei Kündigung den Tag vor `gekuendigt_zum`,** nicht `vertrag_ende`. Sonst stünde bei
   einem gekündigten Vertrag ein Ende in der Zukunft da. Ohne Kündigung ist es `vertrag_ende`.
3. **`widerrufen` liefert `widerrufen_am` als Detail.** Der Auftrag nannte kein Detail; die Spalte ist ohnehin da.
4. **Abgeschlossener Vertrag ohne Laufzeit** (Altbestand) fällt unter `kein_vertrag`, damit jede Ablehnung einen Code hat.
5. **Mit `p_session_id` zählt die eigene Buchung auch nicht gegen die Einheiten,** nicht nur nicht als `schon_termin`.
   Sonst stünde ein Kind, das schon in der Session sitzt und dessen letzte Einheit sie ist, als `keine_einheit` da.
   Das gilt auch für einen festgeschriebenen Slot-Termin. Damit das nicht für fremde Tage greift, muss `p_datum` der Tag
   der Session sein (`22023`, Hinweis `datum_session`) — nachgezogen nach der Zweitprüfung.
6. **Unbekanntes oder vorläufiges Kind in `p_student_ids`** bricht mit `22023` und Hinweis `kein_kind` ab (nicht im
   Auftrag benannt).
7. **`sessionRpc` gibt jetzt auch `detail` weiter** (nur wenn die Datenbank eins liefert), damit die Oberfläche das
   abgelehnte Kind benennen kann. Bestehende Ergebnisse ohne Detail bleiben gleich.

## Offene Punkte

8. **Testlauf-Sessions zählen nicht als `schon_termin`.** `slots_einzelbuchungen` lässt Testläufe aus (so verlangt).
   Ein Testkind kann deshalb am selben Tag in mehreren Sofort-Testläufen sitzen. Für Tests eher erwünscht.
9. **Oberfläche fehlt noch.** S1 liefert Datenbank, Wrapper, Typen und Texte (`slots.json`: `fehler.*`, `buchbar.*`).
   Stundenplan-Seite und Dialog „Sofort-Session“ sind ein eigener Schritt; `SchedulePage` nutzt noch `createSession`
   und lädt Coaches selbst. Für die Leitungsauswahl dort künftig `ladeSessionLeitung()`.
10. **`kinder_buchbar` rechnet je Kind mehrere Unterabfragen.** Bei heute rund dreißig Kindern unkritisch; bei
    mehreren Hundert lohnt ein Blick auf die Laufzeit.
11. **Text `fehler.keinCoach`** sagt „kein Coach“; bei der Sofort-Session ist ein Admin auch erlaubt. Für den Dialog
    eventuell eigener Text.
12. **Gruppengröße — erledigt (Nachtrag, Rasit 15.10.2026).** `sofort_session_anlegen` bricht ab, wenn nach dem
    Entfernen doppelter Einträge mehr als 5 Kinder übrig sind: `22023`, Hinweis `zu_viele` (höchstens 5 Kinder pro
    Raum, Live-Sicht hat 5 Tablet-Plätze). Offen bleibt die Grenze im Stundenplan (`addStudentToSession`); sie kommt
    in S2 als Sperre in der Oberfläche.
13. **Raum- und Coach-Doppelbelegung** wird nicht geprüft: zwei Sofort-Sessions mit gleichem Coach und Raum zur selben
    Minute gehen beide durch. Vorschlag: Warnung in der Oberfläche.
14. **`widerrufen` vor `vertrag_ab`.** Ist der Vertrag mit dem spätesten Beginn widerrufen, ein früherer, noch nicht
    begonnener aber nicht, heißt der Grund `widerrufen` statt `vertrag_ab`. Folgt der vorgegebenen Reihenfolge; selten.
15. **Überlappende Verträge (bestehend).** Läuft ein `verlaengert`-Vertrag noch, wenn der Folgevertrag beginnt, zählt
    `slots_fest_belegt` eine Einzelbuchung in beiden. `kinder_buchbar` rechnet gegen `slots_vertrag_am` (den neueren).
    Liegt an `slots_fest_belegt`, nicht an S1.
16. **Andere Buchungswege ohne Sperre und Budget (bestehend).** `createSession` und direkte Inserts in
    `session_students` prüfen keine Einheiten und holen `slots_sperren` nicht. Wird eine Einzelbuchung später
    `cancelled`, ruft `slots_anwesenheit_spiegeln` kein `termine_planen` (kein `kind_termin` dran) — die Planung ist bis
    zum nächsten Abgleich veraltet.
17. **`schema-erwartet.sql` aus der Wegwerf-DB** (Kopf „Dumped from 18.6“), wie vor dem Einspielen üblich. Nach dem
    Einspielen bestätigt `tools/schema-snapshot.sh`, dass Prod gleich ist.
