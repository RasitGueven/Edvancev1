# Offene Punkte E1 (Erklärsequenz, Hinweis-Status, Formeln als SVG)

Stand 06.10.2026, Branch `feat/rasit-session-e1-erklaersequenz`. Verdrahtung mit anderen Paketen erfolgt in P2.

## Verdrahtung mit X0, R1, A1 (P2)

1. **`erklaerrunden_bis_signal`**: `session_einstellungen` kommt mit R1. Bis dahin liefert
   `erklaer_runden_bis_signal()` den Startwert 2 (`20261007135151_erklaer_ablauf.sql`). In P2 auf die Einstellung
   bzw. den Session-Snapshot umstellen.
2. **Einsatz `check` (X0)**: `tasks.einsatz` gibt es seit X0. `erklaer_checks` filtert noch nicht auf `'check'`. In P2
   beim Anlegen der Inhalte `einsatz = '{check}'` setzen und den Filter ergänzen.
3. **Testmodus (Entscheidung 27)**: `erklaer_*` und `lsa_hint` kennen `coaching_sessions.testlauf` noch nicht (kommt mit
   X0). Bis dahin gilt auch im Testlauf: nur freigegeben bzw. geprüft.
4. **Signal an den Coach**: E1 schreibt das Signal nur als Zeile `ergebnis = 'signal'` in `erklaer_fortschritt`.
   `session_ereignisse` und `raum_signale` (R1) gibt es noch nicht. In P2 einhängen.
5. **Nach dem Signal**: Die Sequenz steht dann; `erklaer_start` antwortet mit `{"aktion":"signal"}`. Wie es weitergeht
   (der Coach erklärt, setzt fort oder setzt eine Stufe tiefer), entscheidet P2 zusammen mit R1/A1.
6. **Zugang über das Tablet**: `erklaer_zugang` lässt Admin, den Coach der Session und das Kind selbst zu (gebucht,
   `attendance` planned oder present). Den Kiosk-Weg über die Tablet-Zuweisung (R1, `tablet_zuweisen`) gibt es noch
   nicht. Ebenso fehlt die Prüfung „Session läuft“, weil R1 die Statuswerte von `coaching_sessions` umstellt.
7. **Live-Sicht des Coaches**: Ein Coach ohne Prüfrecht liest per RLS nur `erklaer_fortschritt` seiner Session, nicht
   die Inhalte (`erklaer_kernidee`, `erklaer_schritt`). Kernidee, Variante und das, was das Kind sieht, kommen in P2 über
   `coach_raum_live` (R1, SECURITY DEFINER).

## Prüfung und Freigabe (P2)

8. **Prüfseite**: Für Erklärbausteine und Hinweise gibt es noch keine Oberfläche (eigene Prüfseite, P2). Ein
   Prüfprotokoll nach Muster `task_pruefungen` (wer, wann, alt, neu) hat E1 nicht angelegt, weil der Bauauftrag es nicht
   nennt. Die E0-Analyse empfiehlt es (Frage 5).
9. **`hinweis_status_setzen` erhöht `tasks.pruef_version`**: Das kommt über den bestehenden Trigger
   `task_solutions_pruef_version` (`schema-erwartet.sql:11428`). Eine in Lenas Prüfansicht offene Aufgabe meldet danach
   „veraltet“. In P2 entscheiden, ob ein reiner Statuswechsel das darf.
10. **Status-Flag `edvance.hinweis_status`**: Den Status übernimmt der Trigger nur, wenn `hinweis_status_setzen` das Flag
    transaktionslokal setzt. Sonst gilt: neuer Hinweis heißt entwurf, gleicher Text behält den alten Status
    (Auflage 2 der Zweitprüfung). Eine Migration, die geprüfte Hinweise einspielen soll, muss das Flag ausdrücklich
    setzen (so auch die Fixtures von `inv2` und `inv6`).
11. **`pruef_version`** liegt nach Bauauftrag nur an der Kernidee. Änderungen an Schritten und Checks erhöhen die Version
    der Kernidee; `erklaer_status_setzen` prüft gegen sie.

## Formeln und Bilder

12. **Farbe der Formeln**: Die SVGs zeichnen in `currentColor`. Für dunkle Hintergründe muss die App die Farbe setzen
    (E2a). Anders als `task_figures` gibt es keine getrennten Dateien für dunkel und hell.
13. **Bilder mit `svg_hash`** werden unter `task-assets/erklaer/bilder/<hash>.svg` erwartet. Einen Generator dafür gibt es
    noch nicht; bisher gibt es nur die Pfadregel in `erklaer_schritt_json`.
14. **`tools/formeln-svg.mjs` beim ersten echten Inhalt (E2b)**: Entscheidung Rasit 06.10.: keine eigene
    Systemaufruf-Markierung; in Prod läuft das Werkzeug als `postgres` ohne JWT (`ist_systemaufruf`). Lokal sind
    Trockenlauf und Uploads gegen einen Schein-Storage belegt. Den Eintrag lehnt die Wegwerf-DB mit 42501 ab, weil
    `auth.role()` dort `'anon'` liefert (`supabase/test-grundlage.sql:61`). Beim ersten echten Inhalt in E2b: einmal
    `--dry-run`, dann echt, und das Ergebnis per dbread prüfen (`formeln` gefüllt, SVGs im Bucket).
## Sonstiges

15. **Das Kind sieht „noch nicht“**: `aktion = 'variante'` sagt dem Kind, dass es noch nicht stimmt. Rasit hat das
    am 06.10. bestätigt: so gewollt, nur ohne Lösung, Urteil und Fehlbild.
16. **Löschen**: Rasit hat am 06.10. entschieden:
    - Wird ein Kind gelöscht (DSGVO), geht der Fortschritt per Kaskade mit (`pg_trigger_depth() > 1`, Test 5e).
    - Eine Session mit Lernverlauf ist nicht löschbar (`on delete restrict`, Test 5d).
17. **Freigabe nach Änderung**: Ändern sich die Checks einer Kernidee, fällt sie auf entwurf. Ändern sich die
    Formel-Hashes eines freigegebenen Schritts, fällt er auf geprueft und braucht eine neue Freigabe.
18. **`bild.url`** muss mit `https://` beginnen (`erklaer_bild_gueltig`).
19. **`erklaer_nachlesen`** ist nicht auf Skills beschränkt, die das Kind in einer Session schon begonnen hat.
20. **Schema-Abzug**: erledigt. E1 ist am 06.10. eingespielt; `supabase/schema-erwartet.sql` kommt aus Prod und stimmt
    mit dem Neuaufbau aus allen Migrationen überein.
