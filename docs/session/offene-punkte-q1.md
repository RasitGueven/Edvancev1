# Offene Punkte Q1 — Home-Quest-Endpunkte

Stand 06.10.2026, Branch `feat/rasit-session-q1-quests`. Jeder Punkt mit Ort im Code.

## Verdrahtung mit anderen Paketen (P2)

1. **Stellschrauben aus R1.** `quest_einstellung` liest `session_einstellungen.wert` per `schluessel`,
   solange die Tabelle fehlt mit den Startwerten aus Entscheidung 22
   (`20261007141352_quests_tabellen.sql`, Funktion `quest_einstellung`). Die Spaltennamen
   `schluessel`/`wert` sind eine Annahme. Weichen sie in R1 ab, greift still der Startwert
   (`undefined_column` wird abgefangen). Nach dem Einspielen von R1 abgleichen.
2. **XP-Buchung aus X0.** `quest_erledigt` bucht als Definer direkt in `xp_events`
   (`reason = 'home_quest'`, `task_id = null`), weil `xp_buchen` (X0) noch fehlt
   (`20261007141354_quest_kind.sql`, Block „XP fuers Bearbeiten“). Nach X0 auf `xp_buchen` umstellen.
   Der Entzug der Insert-Policy `xp_events_insert_own` (X0) trifft diesen Weg nicht, denn der Definer läuft als Eigentümer.
3. **Aufruf aus dem Check-out.** `quest_erzeugen` ruft noch niemand auf. P2 verdrahtet das aus
   dem Check-out bzw. `session_abschliessen` (R1) und übergibt Stundenziel (`skill_keys`) und die Klassenarbeit
   aus `session_checkin` (`klassenarbeit_thema_key`, `klassenarbeit_datum`).
4. **Coach-Rechte (Entscheidung 26).** Ein Coach darf Quests nur anlegen und Termine nur setzen, wenn das Kind einen
   laufenden Vertrag hat (`hat_zugang`), genau wie beim Lesen (Policy `quests_select_coach`).
   Fehlt der Vertrag, wirft die Funktion 42501, auch wenn das Kind gebucht ist.
5. **Tablet des Kindes.** `quest_termin_setzen` erlaubt heute Coach der Session, Admin und das
   Schülerkonto selbst. Die Zuordnung Tablet → Kind baut R1 (`tablet_zuweisen`). Danach muss
   das Kiosk-Konto des Tablets für sein Kind zugelassen werden.
6. **„Älteres“ aus dem Lernpfad (A1).** Gemischt wird bis dahin mit Skills aus früheren Quests
   des Kindes (`quest_aufgaben_waehlen`). Sobald `lernpfad` steht, soll die Quelle Skills mit
   `stand_system = sicher` sein.
7. **Einsatz `quest` (X0).** Die Auswahl filtert nicht auf `tasks.einsatz`, weil die Spalte noch fehlt.
   Nach X0 bekommen alle bestehenden Aufgaben `{lsa,session}`. Ein Filter auf `'quest' = any(einsatz)`
   ergäbe dann sofort leere Quests. Entscheidung nötig: entweder Quest-Aufgaben eigens markieren oder auf
   `session` filtern. Das ist auch der Hebel gegen Punkt 13.
8. **Testläufe (X0).** Quests aus einem Testlauf (`coaching_sessions.testlauf`) sind noch nicht
   ausgeschlossen, weder aus `eltern_quest_wochenstand` noch aus der Coach-Sicht.

## Anmeldung, Versand

9. **Anmeldung zuhause.** `quest_inhalt` und `quest_erledigt` verlangen das Schülerkonto
   (`get_my_student_id()`). Die Anmeldung mit Zugangscode, mit Gerätebindung und eingeschränkter
   Home-Identität, kommt mit der Schüler-App (Q0 §1). Bis dahin kennt niemand das Passwort des Schülerkontos.
10. **Erinnerung.** `push_tokens` und `quest_erinnerungen_faellig` sind nur Endpunkte. Es gibt keinen
   Scheduler (kein `pg_cron`, kein `pg_net` laut Q0 §3) und kein `expo-notifications` in der App.
   Ob nativ (lokale Notification) oder Web (Server-Push), ist eine Infrastrukturentscheidung.
11. **Eltern-Mail.** `eltern_quest_wochenstand` liefert je Kind erledigt/offen und `eltern_email`
    aus `vertraege_aktuell` (laufender Vertrag). Den Versand über `graph_mail.ts` mit System-Auslöser,
    eigenem Anlass und Protokoll baut P2. Verfallene Quests zählen dort als „offen“.

## Inhalt und Mechanik (zur Prüfung durch die Clinic)

12. **Heute keine passende Aufgabe in Prod.** Laut dbread (06.10.) sind 13 Aufgaben `ready` und aktiv.
    Alle 13 haben einen Lösungsweg, aber keine einen `skill_key`, und nur eine hat `est_duration_sec`. Bliebe
    es so, legte `quest_erzeugen` keine Quest an. Leere Quests werden bewusst nicht angelegt, die Funktion
    meldet dann nur einen NOTICE.
13. **Lösungsweg an das Kind.** `quest_inhalt` gibt `task_solutions.solution` heraus (Selbstkontrolle,
    Entscheidung 21). Das ist eine bewusste Ausnahme zur Invariante INV-6. Die Aufgaben stammen aus demselben
    Pool wie LSA und Session, also sieht ein Kind zuhause Lösungen von Aufgaben, die vor Ort wiederkommen
    können. Abgemildert, aber nicht gelöst: nur eigene Quests, erst ab `faellig_ab`, nur solange die
    Quest offen ist (nach „erledigt“ nicht mehr), nur Lösungsweg (kein `correct_answers`).
    Der Consensus-Check hält das für nicht ausreichend. **Entscheidung Rasit nötig**, zwei Wege:
    (a) eigener Quest-Pool über `einsatz = 'quest'` (Punkt 7), getrennt von LSA und Session; oder
    (b) die Auswahl in LSA, Session und Diagnostik (X0/A2) schließt für ein Kind jede Aufgabe aus,
    die schon in seinen `quest_aufgaben` stand. Beides ändert Funktionen außerhalb von Q1.
14. **Dauer.** Aufgaben ohne `est_duration_sec` werden nicht gewählt, damit die Summe garantiert
    `quest_minuten` einhält. Einen Rückfall auf `estimated_minutes` gibt es nicht.
15. **`quests_pro_woche`.** 0 heißt keine Quest, 1 nur Quest A, 2 A plus B bzw. KA-Paket. Den Wert 3
    (Spanne 0–3) behandelt die Funktion wie 2; ein dritter Quest-Typ ist nicht beschrieben.
16. **KA-Paket.** Das Paket ersetzt nur Quest B; Quest A bleibt bestehen. Es ist fällig am Tag vor der Klassenarbeit. Es mischt
    nicht mit Älterem (wie `ka_tage` in der Session). Ergänzung zur Signatur des Bauauftrags: der
    optionale Parameter `p_ka_datum`. Ohne Datum gilt die Klassenarbeit als „vor der nächsten Session“.
17. **Ohne nächste Buchung** ist Quest B sechs Tage nach der Session fällig (Wochenrhythmus).
    Liegt die nächste Session so nah, dass B nicht nach A läge, entfällt B.
18. **Verfallen.** Neue Quests aus einer Session setzen die offenen Quests früherer Sessions
    auf `verfallen`. Verfallene Quests lassen sich weder abrufen noch erledigen.
19. **Termin.** Ein Termin liegt frühestens auf `faellig_ab`. Der Coach-Live-Dummy zeigt dagegen *einen*
    Termin je Kind am Tag nach der Session (z. B. Emir „Mi 07.10.“ bei Quest A frühestens am 08.10.).
    Der Bauauftrag (Termin je Quest) hat Vorrang, die Oberfläche in P2 muss das auflösen.
20. **Wochenserie.** `home_streak_sessions` zählt jetzt Kalenderwochen (Europe/Berlin) mit mindestens
    einer erledigten Quest. Eine Woche ohne Quest lässt die Serie stehen (Pause), sie wird nie
    zurückgesetzt. Die Spalte heißt weiter `…_sessions`, und die App zeigt sie heute als „N Einheiten zuhause“
    (edvance-app `app/(student)/index.tsx:155-157`). Das Label muss in Q2 auf Wochen umgestellt werden.
    In Prod steht bei einem Testkind der Seed-Wert 12 (dbread).
21. **Schalter `home_quests_aktiv` = aus.** Solange er aus ist, legt nur ein Systemaufruf Quests an
    (Test, Durchlauf), weder Coach noch Admin. Die übrigen Endpunkte prüfen den Schalter nicht: ohne Quests haben sie
    nichts zu liefern.

## Migrationsversionen

22. Der Bauauftrag gibt den Bereich `20261007140000–145959` vor, also den 07.10.2026. Erstellt wurden
    die Dateien am 06.10. Das widerspricht CLAUDE.md §10 (Version = `date -u`). Gewählt wurden
    `20261007141352`–`…355`, nicht rund und im vorgegebenen Bereich.

## Datenschutz (für Windweiss)

23. Neue personenbezogene Daten durch Q1, Löschung bei Vertragsende ist noch nicht geregelt:
    - `push_tokens`: Gerätetoken, Gerätename (frei), Plattform, Zeitpunkt der Anmeldung.
    - `quests`: welche Quest an welchem Tag fällig ist, vom Kind gewählter Termin, Zeitpunkt
      „erledigt“, gebuchte XP, Thema einer angekündigten Klassenarbeit (`ka_thema_key`).
    - `quest_aufgaben`: welche Aufgaben ein Kind zuhause bekam.
    - `xp_events` (`reason = 'home_quest'`) und `student_progress.home_streak_*`.
    - `eltern_quest_wochenstand` liest `vertraege_aktuell.eltern_email` (keine neue Speicherung).

    Heute löscht nur `on delete cascade` am Kind (`students`). Ein Vertragsende löscht nichts.
    Vorschlag: bei Vertragsende Push-Tokens sofort löschen, Quests nach einer Frist. Das legt Windweiss fest.
