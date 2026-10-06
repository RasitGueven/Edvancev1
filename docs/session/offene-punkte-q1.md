# Offene Punkte Q1 — Home-Quest-Endpunkte

Stand 06.10.2026 (nach dem Merge von X0 #218 und A1 #214), Branch `feat/rasit-session-q1-quests`.
Jeder Punkt mit Ort im Code. **Erledigt** markierte Punkte bleiben zur Nachvollziehbarkeit stehen.

## Verdrahtung mit anderen Paketen (P2)

1. **Stellschrauben aus R1.** `quest_einstellung` liest `session_einstellungen.wert` per `schluessel`,
   solange die Tabelle fehlt mit den Startwerten aus Entscheidung 22
   (`20261007141352_quests_tabellen.sql`, Funktion `quest_einstellung`). Die Spaltennamen
   `schluessel`/`wert` sind eine Annahme. Weichen sie in R1 ab, greift still der Startwert
   (`undefined_column` wird abgefangen). Nach dem Einspielen von R1 abgleichen.
2. **Erledigt: XP über `xp_buchen` (X0).** `quest_erledigt` bucht über `xp_buchen_intern`
   (`reason = 'home_quest'`, Schlüssel `quest:<id>`). Das ist der Kern von `xp_buchen`, ohne
   Rechteprüfung. `xp_buchen` selbst lässt nur Admin oder System zu, und das Kind ruft
   `quest_erledigt` auf. Denselben Kern nutzt X0 für `complete_task`
   (`20261007100100_x0_xp_buchen.sql`).
3. **Aufruf aus dem Check-out.** `quest_erzeugen` ruft noch niemand auf. P2 verdrahtet das aus
   dem Check-out bzw. `session_abschliessen` (R1) und übergibt Stundenziel (`skill_keys`) und die Klassenarbeit
   aus `session_checkin` (`klassenarbeit_thema_key`, `klassenarbeit_datum`).
4. **Coach-Rechte (Entscheidung 26).** Ein Coach darf Quests nur anlegen und Termine nur setzen, wenn das Kind einen
   laufenden Vertrag hat (`hat_zugang`), genau wie beim Lesen (Policy `quests_select_coach`).
   Fehlt der Vertrag, wirft die Funktion 42501, auch wenn das Kind gebucht ist.
5. **Tablet des Kindes.** `quest_termin_setzen` erlaubt heute Coach der Session, Admin und das
   Schülerkonto selbst. Die Zuordnung Tablet → Kind baut R1 (`tablet_zuweisen`). Danach muss
   das Kiosk-Konto des Tablets für sein Kind zugelassen werden.
6. **„Älteres“ aus dem Lernpfad (A1).** Gemischt wird weiter mit Skills aus früheren Quests
   des Kindes (`quest_aufgaben_waehlen`). `lernpfad` ist seit A1 (#214) in `dev`. Die Umstellung
   auf Skills mit `stand_system = sicher` war nicht Teil dieses Nachtrags und bleibt für P2.
7. **Erledigt: eigener Quest-Pool (Entscheidung Rasit 06.10.).** `quest_aufgaben_waehlen` nimmt nur
   Aufgaben mit `'quest' = any(einsatz)`, die weder `lsa` noch `session` im Einsatz haben
   (`20261007141353_quest_erzeugen.sql`, Pool-CTE). **Folge:** In Prod stehen alle 1183 Aufgaben auf
   `{lsa,session}` (dbread 06.10.). Bis Quest-Aufgaben angelegt sind, entsteht keine Quest (Punkt 12).
8. **Erledigt: Testläufe (X0).** Quests aus einer Session mit `coaching_sessions.testlauf` werden angelegt,
   damit sich der Ablauf mit Testkonten durchspielen lässt. Sie erscheinen aber weder in
   `quest_erinnerungen_faellig` noch in `eltern_quest_wochenstand` (`20261007141355_quest_benachrichtigung.sql`).
   **Offen:** Die Coach-Policy `quests_select_coach` filtert Testläufe nicht. Das Briefing in C2 muss
   das selbst tun, wie die Akte.

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

12. **Heute keine passende Aufgabe in Prod.** Laut dbread (06.10., nach X0) passt keine Aufgabe in den Quest-Pool
    (0 Treffer). Keine hat `quest` im Einsatz, und von den 13 freigegebenen hat keine einen `skill_key`.
    Gebraucht werden eigene Quest-Aufgaben mit `einsatz = {quest}`, freigegeben, mit Lösungsweg,
    `skill_key` und `est_duration_sec` (Inhalte, P2). Leere Quests werden bewusst nicht angelegt,
    die Funktion meldet dann nur einen NOTICE.
13. **Lösungsweg an das Kind.** `quest_inhalt` gibt `task_solutions.solution` heraus (Selbstkontrolle,
    Entscheidung 21). Das ist eine bewusste Ausnahme zur Invariante INV-6. Die Aufgaben stammen aus demselben
    Pool wie LSA und Session, also sieht ein Kind zuhause Lösungen von Aufgaben, die vor Ort wiederkommen
    können. **Entschieden (Rasit 06.10.): eigener Quest-Pool** (Punkt 7). Quest-Aufgaben haben weder `lsa`
    noch `session` im Einsatz und kommen deshalb vor Ort nie dran. Die Abmilderung bleibt zusätzlich:
    nur eigene Quests, erst ab `faellig_ab`, nur solange die Quest offen ist, nur Lösungsweg
    (kein `correct_answers`). Wer Aufgaben anlegt, darf `quest` nicht mit `lsa`/`session` kombinieren.
    Die Auswahl ignoriert solche Aufgaben, ein CHECK verbietet die Kombination aber nicht.
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
    **Entschieden (Rasit 06.10.):** Es bleibt ein Termin je Quest. Für die Oberfläche (P2/Q2): Quest A wählt
    das Kind im Check-out; Quest B ist auf den Tag vor der nächsten Session vorbelegt und änderbar.
    Die Vorbelegung setzt die Oberfläche über `quest_termin_setzen`. Die Uhrzeit ist noch offen, denn
    `faellig_ab` ist ein Tag.
20. **Wochenserie.** `home_streak_sessions` zählt jetzt Kalenderwochen (Europe/Berlin) mit mindestens
    einer erledigten Quest. Eine Woche ohne Quest lässt die Serie stehen (Pause), sie wird nie
    zurückgesetzt. Die Spalte heißt weiter `…_sessions`, und die App zeigt sie heute als „N Einheiten zuhause“
    (edvance-app `app/(student)/index.tsx:155-157`). Als Wochenzähler bestätigt (Rasit 06.10.); die
    Beschriftung in der App stellt Q2 auf Wochen um.
    In Prod steht bei einem Testkind der Seed-Wert 12 (dbread).
21. **Schalter `home_quests_aktiv` = aus.** Solange er aus ist, legt nur ein Systemaufruf Quests an
    (Test, Durchlauf), weder Coach noch Admin. Die übrigen Endpunkte prüfen den Schalter nicht: ohne Quests haben sie
    nichts zu liefern.

22. **Rollenprüfungen** laufen durchgehend über `coalesce(public.get_my_role(), '')` (Vorgabe Rasit), auch in den
    Policies von `quests`/`quest_aufgaben`. Die äußere Absicherung `coalesce(…, false)` bleibt, weil
    `get_my_student_id()` und `hat_zugang` ebenfalls null liefern können.

## Migrationsversionen

23. Der Bauauftrag gibt den Bereich `20261007140000–145959` vor, also den 07.10.2026. Erstellt wurden
    die Dateien am 06.10. Das widerspricht CLAUDE.md §10 (Version = `date -u`). Gewählt wurden
    `20261007141352`–`…355`, nicht rund und im vorgegebenen Bereich. Bestätigt (Rasit 06.10.).

## Datenschutz (für Windweiss)

24. Neue personenbezogene Daten durch Q1, Löschung bei Vertragsende ist noch nicht geregelt:
    - `push_tokens`: Gerätetoken, Gerätename (frei), Plattform, Zeitpunkt der Anmeldung.
    - `quests`: welche Quest an welchem Tag fällig ist, vom Kind gewählter Termin, Zeitpunkt
      „erledigt“, gebuchte XP, Thema einer angekündigten Klassenarbeit (`ka_thema_key`).
    - `quest_aufgaben`: welche Aufgaben ein Kind zuhause bekam.
    - `xp_events` (`reason = 'home_quest'`) und `student_progress.home_streak_*`.
    - `eltern_quest_wochenstand` liest `vertraege_aktuell.eltern_email` (keine neue Speicherung).

    Heute löscht nur `on delete cascade` am Kind (`students`). Ein Vertragsende löscht nichts.
    Vorschlag: bei Vertragsende Push-Tokens sofort löschen, Quests nach einer Frist. Das legt Windweiss fest.
