# Offene Punkte L6 (Erklärsequenzen prüfen und freigeben)

Stand 07.10.2026, Branch `feat/rasit-session-l6-erklaer-pruefen`.

## Fachlich zu entscheiden

1. **Pflege nimmt eine Freigabe offline (Consensus-Check, „sollte“).** Nach der Regel aus E1
   (offene-punkte-e1 17) setzen `erklaer_check_setzen` und `erklaer_kernidee_speichern` auch eine
   freigegebene Kernidee auf entwurf; `erklaer_schritt_speichern` setzt den geänderten Schritt auf entwurf,
   `erklaer_formeln_setzen` einen freigegebenen Schritt auf geprueft. Das darf jeder Prüfer, also auch Lena,
   ohne Grund. Die Oberfläche sperrt das Bearbeiten freigegebener Kernideen (`editor.gesperrtFreigegeben`),
   die Datenbank nicht. Entscheiden: so lassen (jede Änderung steht im Protokoll) oder Pflege an freigegebenen
   Objekten nur für Admins.
2. **Neue Regel in L6:** Ändert sich ein Schritt einer geprüften (noch nicht freigegebenen) Kernidee, fällt die
   Kernidee auf entwurf (`20261010121015`, `erklaer_schritt_speichern`). Lenas „Passt“ galt dem alten Stand.
3. **„Freigegeben“ verlassen nur Admin.** `erklaer_status_setzen` lässt Lena eine Freigabe nicht mehr über den
   Status zurücknehmen (bisher ging das für jeden Prüfer). Ein Admin kann es dort ohne Grund; mit Grund geht es
   über `erklaer_freigabe_zuruecknehmen`.
4. **Gründe für „Passt nicht“:** fachlich falsch, unklar, zu lang für einen Bildschirm, Sprache nicht passend für
   die Klassenstufe, Formel oder Bild fehlerhaft, Variante passt nicht zum Fehlbild, Mini-Check passt nicht zur
   Kernidee, Sonstiges. „Unklar“ und „Mini-Check passt nicht“ sind nach dem Muster des Lena-Boards ergänzt.
5. **Rückfrage auf einer freigegebenen Kernidee** bleibt freigegeben (Kinder sehen sie weiter), steht aber im
   Admin-Filter „Rückfragen“. „Passt nicht“ geht dort erst nach der Rücknahme.

## Verdrahtung

6. **E2b-Entwürfe ohne Anlage-Zeile im Protokoll.** `20261010132750_erklaer_k8_linfkt.sql` (E2b) schreibt direkt
   in die Tabellen, nicht über `erklaer_*_speichern`. Die Liste rechnet den Stand aus Status und Protokoll und
   zeigt die Kernideen trotzdem als offen; das Protokoll beginnt mit Lenas erster Aktion.
7. **E2b-Checks** zählen für die Freigabe nur mit Status ready, aktiv und Einsatz `check`
   (`erklaer_checks(…, false)`). Die Check-Aufgaben prüft Lena wie jede Aufgabe; der Link „Diese Aufgabe prüfen“
   führt dorthin.
8. **A2c** ersetzt `erklaer_start`, `erklaer_check_abgeben`, `erklaer_nachlesen` (`20261010100426`), L6 keine davon.
   Beim Einspielen nach dem Merge von dev pgTAP erneut laufen lassen (Test 4 und 6 rufen `erklaer_start`).
9. **Bilder mit `svg_hash`** zeigt die Kinderansicht über die URL aus `erklaer_schritt_json`
   (`task-assets/erklaer/bilder/<hash>.svg`, E1-13). Die Bildschirmfotos haben keine Bilder.
10. **Kinderansicht** folgt dem Klick-Dummy (Dachzeile, Text, Bild daneben), nicht dem Renderer der App (E2a).
    Formeln sind `currentColor` (offene-punkte-e1 12) und hier auf hellem Grund.
11. **Fehlbilder** in der Detailansicht: alle Slugs aus `known_errors` der Aufgaben des Skills und der Checks,
    dazu die schon zugeordneten. Bei Skills mit vielen Aufgaben wird die Liste lang.

## Technisch

12. **Migrationsversionen 20261010121014–121017** liegen in der Zukunft (Bereich aus dem Auftrag, widerspricht
    CLAUDE.md §10 wie bei L5). In Prod frei (dbread 07.10.), in `git log --all` nur auf diesem Branch.
13. **Protokoll ohne DELETE-Sperre** (Consensus-Check, Hinweis): Zeilen gehen per Kaskade mit der Kernidee
    (wie `task_pruefungen` mit der Aufgabe); eine Löschfunktion für Kernideen gibt es nicht. `service_role`
    behält über die Default-Privilegien EXECUTE auf `erklaer_protokollieren` (bestehendes Muster).
14. **`erklaer_check_setzen` protokolliert jeden Aufruf**, auch ohne Änderung (wie bisher erhöht er auch immer
    die Version).
15. **`erklaer_rueckfrage_beantworten` und `erklaer_formeln_setzen` erhöhen die Version nicht** (kein Inhalt
    geändert bzw. abgeleitete Daten, wie in E1).
16. **`src/types/database.ts`** kennt die neuen Funktionen erst nach einer Neugenerierung (Cast in
    `src/lib/supabase/erklaerPruefung.ts`, Muster `pruefung.ts`).
17. **Vitest unter Last:** Im ersten vollen Lauf liefen `tests/prefill.test.ts` und
    `AdminPruefansichtPage.test.tsx` in das 5-s-Limit (einzeln grün, zweiter voller Lauf 941/941 grün). Nicht von L6.
18. **Migration 1 nach dem ersten Commit geändert** (Reihenfolge in `erklaer_freigabe_fehlt`: Erklärschritt vor
    Beispiel), vor dem Push, nicht eingespielt.
