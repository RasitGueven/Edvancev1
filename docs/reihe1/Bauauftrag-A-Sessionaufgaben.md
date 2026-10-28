# Bauauftrag A · Sessionaufgaben (Pool-Trennung, Bauformen, Formate, Lena-Board, Inhalte Reihe 1)

Stand 27.10.2026 · Repos **Edvancev1** (Hauptteil) und **edvance-app** (Formate im Player) · Grundlage: `docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md`

**Vorher (Rasit, 2 Minuten)**
1. `reihe1-pakete.zip` in den Windows-Downloads-Ordner legen.
2. Im Prompt unten die Zeile `EINSPIELEN = rasit` stehen lassen (du spielst Migrationen ein, der Agent wartet darauf) oder auf `EINSPIELEN = orchestrator` ändern (der Agent spielt nach der Zweitprüfung selbst ein).
3. Den Block in eine neue Claude-Code-Session in WSL kopieren (eigener Zellij-Tab). Die Aufträge A–D können gleichzeitig laufen.

---

```text
Du bist der Orchestrator für Bauauftrag A der Sessionreihe 1 bei Edvance. Du führst alle Phasen A0 bis A7 nacheinander bis zum Ende durch, ohne nach jeder Phase zu fragen. Du stoppst nur an den unten genannten Haltepunkten.

EINSPIELEN = rasit

ZIEL
Session-Aufgaben entstehen ab jetzt aus Bauformen: Ein Generator erzeugt Instanzen, eine Prüfmaschine kontrolliert jede, Lena prüft je Bauform statt je Aufgabe, und die Bewährung im Einsatz fängt Fehler auf. Dazu: Pool-Trennung LSA/Session, sechs neue Antwortformate, die Bauform-Prüfung im Lena-Board und alle 47 Bauformen der Reihe „Quadratische Funktionen und Gleichungen“, fertig zur Prüfung durch Lena.

SCHRITT 0 · UNTERLAGEN, WORKTREES
1. Repos: ~/Edvancev1 und ~/edvance-app (sonst suchen: ls -d ~/*/Edvancev1 ~/*/edvance-app). In beiden git fetch.
2. Worktrees nur für diesen Auftrag (andere Aufträge laufen parallel in denselben Repos):
   git -C ~/Edvancev1 worktree add ../Edvancev1-A -b feat/rasit-reihe1-a0 origin/dev
   git -C ~/edvance-app worktree add ../edvance-app-A -b feat/rasit-reihe1-a3-app origin/dev
   Existieren sie schon: weiterverwenden. Arbeite nur in diesen Worktrees. npm ci, .env bzw. .env.local aus dem Haupt-Checkout kopieren (nie committen).
3. mkdir -p docs/reihe1 && unzip -o "/mnt/c/Users/$WINUSER/Downloads/reihe1-pakete.zip" -d docs/reihe1 (in beiden Worktrees; $WINUSER bestimmst du selbst). Fehlt die Datei: melden und STOPP.
4. Lies vollständig: CLAUDE.md beider Repos, docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md (verbindlich, besonders §3–7 und §9), docs/reihe1/Konzept-Session-Ablauf-und-Aufgaben.md (§3, §5, §6), dieses Dokument. Öffne docs/reihe1/referenz/schueler-app-dummy.html (Bildschirme Üben, Transfer, Lösungsbeispiel) im Browser.
5. Lege docs/reihe1/A/fortschritt.md an und schreib nach jedem Schritt eine Zeile hinein (Datum, Phase, Ergebnis, PR-Link). Diese Datei ist das Protokoll für Rasit.

LEITPLANKEN (gelten für alle Phasen, nicht verhandelbar)
- CLAUDE.md gilt vollständig. Keine Hex-Werte außerhalb der Tokens, keine Inline-Styles, Texte fürs Kind nur über die Textdateien.
- Datenbank lesen nur über dbread. Keine schreibende Abfrage gegen Prod.
- DDL und Datenänderungen nur als Migrationsdatei nach supabase/migrations/ (nicht pending/), mit Rollback nach supabase/rollback/<name>.sql. Keine DROP TABLE/COLUMN, kein TRUNCATE, kein DELETE von Inhalten.
- Vor jeder Änderung an einer Spalte: alle Funktionen in pg_proc scannen, die sie referenzieren (Ergebnis in die PR).
- Jede Schemaänderung bekommt eine Zweitprüfung durch einen frischen Subagenten ohne deinen Kontext: Er bekommt nur die Migration, das Konzept §3–6 und §9 und die Frage „Was ist falsch, was fehlt, was bricht?“. Sein Ergebnis hängt an der PR. Befunde arbeitest du ab oder begründest sie.
- Einspielen:
  - EINSPIELEN = rasit: Lege den fertigen Befehl als ~/einspielen/A-<nr>-<name>.sh ab (Zielprüfung: `psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres` und ein Test, dass $DATABASE_URL die Projekt-Ref von Prod enthält, die du in der Ist-Analyse aus supabase/config.toml bzw. .env festgestellt hast; dann per dbread die vorausgesetzten Objekte anderer Aufträge prüfen, sonst Abbruch mit klarer Meldung && Migration && History-Eintrag nach dem im Repo üblichen Muster && tools/schema-snapshot.sh, alles mit && verkettet). Schreib ihn auch in die PR und ins Protokoll. Jede Migration bekommt eine eigene Prüfabfrage (bei Datenmigrationen eine Zählabfrage), die als Kommentar im Skript steht. Warte, indem du diese Abfrage per dbread wiederholst: je Warteschritt ein Bash-Aufruf `sleep 540 && dbread …` mit timeout 600000 ms, ins Protokoll nur eine kurze Zeile je Stunde. Arbeite in der Wartezeit an allem weiter, was nicht davon abhängt. Nach 48 Stunden ohne Ergebnis: Bericht mit dem Stand schreiben, dann STOPP.
  - EINSPIELEN = orchestrator: Erst nach grüner Zweitprüfung führst du genau diesen Befehl selbst aus, prüfst per dbread das Ergebnis und protokollierst es. Schlägt etwas fehl: Rollback ausführen, melden, STOPP für diese Phase.
- Nach jedem Einspielen und nach jedem Rebase: Types in beiden Repos neu generieren (Befehle laut Repo) und committen. Generierte Dateien nie von Hand zusammenführen.
- Branches: je Phase ein eigener Branch, der auf dem vorherigen aufsetzt (feat/rasit-reihe1-a1-pool, …-a2-modell usw.). Je Phase eine PR gegen dev, niemals main. In jede PR-Beschreibung: „Baut auf PR #… auf, Merge-Reihenfolge …“. Du mergst nie selbst. Nichts unter .github/.
- Vor jeder PR: git fetch && git rebase origin/dev. Konflikte in gemeinsamen Dateien (DATENVERTRAG.md, schema.sql, Types, Tokens) löst du, indem beide Seiten erhalten bleiben.
- Tests: nach jeder Änderung npm run typecheck && npm test grün; pgTAP so, wie das Repo es heute ausführt; in edvance-app vor jeder PR zusätzlich npm run test:views.
- Inhalte prüft nie der Agent, der sie erzeugt hat: Prüfmaschine und Blindlöser (frischer Subagent) sind Pflicht.
- Abnahme-Umgebung: Schreibende Tests laufen dort, wo das Repo pgTAP heute ausführt (die Ist-Analyse klärt das), sonst in einem lokalen Supabase-Stack (`supabase start`, Docker), falls vorhanden, mit allen Migrationen und einem Seed (Testkind Batu, eine freigegebene Reihe). Die alte Shadow-DB auf 127.0.0.1 nicht verwenden. Gibt es beides nicht, kommen Abnahmefälle, die Schreibrechte brauchen, in die Live-Checkliste nach dem Merge und sind im Bericht so markiert.
- Warten auf andere Aufträge nach Konzept §9 („Schnittstellen-PR zuerst“, „Warten auf eine Datenbank-Funktion“). Fremde Funktionen erkennst du am Namen in pg_proc und am Kommentar 'reihe1 fertig'; die Signatur liest du im DATENVERTRAG im Worktree des Besitzers (../Edvancev1-A, ../Edvancev1-B usw.). Deine eigenen fertigen Funktionen markierst du in der Migration mit `comment on function … is 'reihe1 fertig';`. Fremde Funktionen rufst du nur aus plpgsql auf.
- Höchstens ein Subagent gleichzeitig.
- Schnittstellen: Du besitzt alles, was im Konzept §9 bei A steht. Tabellen und Funktionen der Aufträge B, C und D fasst du nicht an, auch nicht session_naechster_schritt (gehört C). Alle A-Funktionen aus §9 lieferst du genau mit der dortigen Bedeutung; abweichende Namen oder Typen stehen im DATENVERTRAG.
- Widerspricht der Code dem Konzept: im Protokoll unter „Abweichungen“ festhalten und die Lösung wählen, die das Konzept am besten erfüllt. Nicht stillschweigend übergehen.

HALTEPUNKTE (nur hier wartest du oder stoppst)
- Warten auf eingespielte Migrationen (siehe oben).
- Fehlende Unterlagen in Schritt 0.
- Die Zahl der Doppel-Aufgaben in A0 ist größer als 80 oder kleiner als 10: Liste ins Protokoll und STOPP, bis Rasit antwortet (die Zahl „rund 40“ wäre dann falsch).
- Eine Phase scheitert nach zwei Korrekturrunden an derselben Prüfung: Befund ins Protokoll, mit der nächsten unabhängigen Phase weitermachen.

A0 · IST-ANALYSE (nur lesen)
Ergebnis: docs/reihe1/A/ist-analyse.md, jede Aussage mit Beleg (Datei:Zeile auf origin/dev oder dbread-Abfrage samt Ausgabe).
1. Wie ist heute markiert, ob eine Aufgabe für LSA, Session oder beides taugt (Spalten, Werte, Tabellen)? Wie viele Aufgaben haben beide Markierungen, nach Skill und Status? Die Abfrage steht im Dokument.
2. Wie wählen LSA und Session heute Aufgaben aus (lsa_select_next_core, session_naechster_schritt und Umfeld)? Wo genau greift der Filter auf die Markierung?
3. Aufgabenmodell: tasks, task_solutions (Lösungsweg, hints, Status), correct_answers, acceptance, Teile/MULTI_PART, task_figures, known_errors (Fehlbild-Katalog), Zuordnung „falsche Antwort → Fehlbild“.
4. Wertung: lsa_grade, lsa_is_correct, wertung_testen, Normalisierung (Bruch, Term). Wie lässt sich eine neue Antwortart anschließen?
5. Lena-Board und Item-Pflege: Status (draft, review, rueckfrage, beanstandet, ready …), task_pruefungen, pruefung_entscheiden, freigabe_thema, Prüf-Vorschau „wie Tablet“ (#263): wie gerendert?
6. Werkzeuge: tools/verify-tasks.mjs, scripts/figures/ mit pruefe_-Modulen, tools/spec-figuren.sh, upload_figures.py. Python-Umgebung (venv?), ist sympy installierbar?
7. Player in edvance-app: Eingabetypen, Komponenten, Antwortkodierung, Datenfluss beim Abschicken, Anzeige von Hinweisen und Rückmeldungen.
8. Einstellungen (Stellschrauben-Tabelle mit Protokoll) und ob es pg_cron oder einen Cron-Weg über Vercel gibt (für die Bewährung).
9. Wo speichert die Session Antworten, Versuche, Hinweisnutzung (für Bewährung und „schon gesehen“)?
10. Gibt es einen Ort für Coach-Prüffragen am Skill (Prüffrage, Erwartung, Kriterium)?
11. Projekt-Ref von Prod (aus supabase/config.toml bzw. .env) für die Zielprüfung.
Am Ende: Tabelle „Konzept-Feld → Spalte/Tabelle/Funktion (vorhanden | neu)“ und die Liste der Fehlbild-Schlüssel aus Konzept §4 und §8, die im Katalog fehlen.
Commit, PR „Reihe 1 · A0 Ist-Analyse“ (nur docs).

A0b · SCHNITTSTELLEN-PR (edvance-app, klein, zuerst zu mergen)
Nach Konzept §9: src/components/aufgaben/formate/ mit der gemeinsamen Schnittstelle AufgabeFormatProps (Payload, Antwort, onAntwort, Rückmeldung, Hinweise, nurLesen) und je Format einem Platzhalter, der „Format kommt bald“ zeigt; src/components/aufgaben/Loesungsbeispiel.tsx als Platzhalter mit festen Props. Props auch in docs/api/DATENVERTRAG.md (Edvancev1) beschreiben. PR „Reihe 1 · A0b Schnittstellen“, im Protokoll und in der PR: „Bitte zuerst mergen, C und D warten darauf.“ Dann weiter.

A1 · POOL-TRENNUNG
1. Migration: eine eindeutige Pool-Angabe je Aufgabe (lsa | session, not null), vorhandene Markierung wiederverwenden, wenn sie sich dafür eignet. Datenteil: Alle Aufgaben mit beiden Markierungen werden lsa. Nichts wird gelöscht.
2. Regel in der Datenbank, die beide Markierungen zugleich unmöglich macht (CHECK oder Trigger), mit pgTAP-Test, der eine solche Zeile ablehnt.
3. Die LSA-Auswahl zieht nur Pool lsa (pgTAP). session_naechster_schritt fasst du nicht an (gehört C). Prüfe per pgTAP, dass die heutige Session-Auswahl nach der Datenänderung keine LSA-Aufgabe mehr liefert. Reicht die Datenänderung dafür nicht, schreib in docs/reihe1/A/an-C.md genau, was C ändern muss.
4. Item-Pflege und Lena-Board zeigen den Pool an; Ändern nur durch Admins.
5. Bericht in der PR und im Protokoll: Zahl vorher/nachher, Liste der Skills, die danach keine Session-Aufgabe mehr haben.
PR „Reihe 1 · A1 Pool-Trennung“. Einspielen laut Regel.

A2 · DATENMODELL BAUFORMEN UND FUNKTIONEN
1. Tabelle bauformen: Schlüssel, Skill, Kernidee, Format, Rollen, Steckbrief (jsonb: Text, Stufen, Fehlbilder, Hinweise, Lösungsweg, Warum-Bausteine, Kontext, Figur, Zeit, kann_entfallen), Generator-Pfad, Version, Status (entwurf | zur_pruefung | rueckfrage | beanstandet | zur_freigabe | freigegeben | pausiert), Prüfprotokoll-Bezug, Blindlöser-Ergebnis.
2. An tasks: bauform_id, bauform_version, params (jsonb), stufe (1–5), rolle (genau eine: warmup, uebung, transfer, recap, beispiel, home, generalprobe), kernidee_key, pruefmaschine (jsonb: je Prüfung grün/rot und Grund).
2a. Fehlbild-Schlüssel früh: alle neuen qf_-Schlüssel aus Konzept §4 und die acht aus §8 per Migration in den Katalog, mit kurzem Klartext und Kommentar 'reihe1 fertig' am Katalogeintrag bzw. einer Prüfabfrage im Skript (Auftrag B wartet darauf).
3. Bauform-Prüfung: Entscheidungen von Lena mit Gründen, Notiz, Dauer, Version (Muster task_pruefungen); Sammelfreigabe durch Admins je Reihe (Kern-Skills und Voraussetzungen zusammen) oder je Thema, die alle grünen Instanzen der freigegebenen Version auf ready setzt; Versionswechsel öffnet die Bauform wieder und nimmt alte Instanzen aus der Ziehung.
4. Bewährung: je Instanz Bearbeitungen, richtig, Fehlbild-Zähler, häufigste unbekannte Antwort, Status (in_bewaehrung | bewaehrt | auffaellig | pausiert); Auswertung nach Konzept §6 mit Stellschrauben (Startwerte dort) im vorhandenen Einstellungsmuster. Auslöser: Trigger nach dem Speichern einer Session-Antwort oder ein Cron-Lauf, je nach A0. Die Wertungsfunktionen selbst schreiben nie (pgTAP: eine Wertung lässt alle Tabellen unverändert).
5. Meldungen durch Coaches: Tabelle plus aufgabe_melden(p_task, p_grund), pausiert sofort; zwei gemeldete Instanzen pausieren die Bauform.
6. Alle A-Funktionen aus Konzept §9: aufgabe_ziehen, aufgabe_zwilling (mit p_rolle), aufgabe_payload, aufgabe_werten (rein, schreibt nie), aufgabe_meta, aufgabe_gezeigt (nur Session vor Ort), skill_kann_entfallen. Regeln wie dort: nur Pool session, Bauform freigegeben, Instanz ready, nicht pausiert, genau die Rolle, bevorzugt in der Session ungesehen, Rolle home nur Stufe 1–3. Nur für die Rollen uebung und warmup darf aufgabe_ziehen auf vorhandene, freigegebene Session-Aufgaben ohne Bauform zurückfallen (Stufe aus der Schwierigkeit). Jede fertige Funktion bekommt den Kommentar 'reihe1 fertig'.
7. RLS: Kinder lesen nur über Funktionen und nur Freigegebenes; Bauform-Steckbriefe lesen Admins und Lena; Meldungen schreiben Coaches und Admins.
8. Coach-Prüffragen: falls A0 keinen Ort findet, eine kleine Tabelle am Skill (Prüffrage, Erwartung, Kriterium, Status, geprüft_von).
9. pgTAP für alles, besonders Abnahmefälle 6–10 unten und: Instanzen der Rolle home kommen über keine andere Rolle; aufgabe_werten schreibt nichts. DATENVERTRAG.md um alle Funktionen ergänzen.
PR „Reihe 1 · A2 Datenmodell Bauformen“. Einspielen laut Regel.

A3 · FORMATE (beide Repos)
Nach Konzept §7: Feldmaske (Feldtypen zahl, bruch, vorzeichen; „leer heißt 1“; Wertung über die Bedeutung), Lösungsmenge (1–3 Felder, „keine Lösung“, Mengengleichheit, eigene Rückmeldung für eine echte Teilmenge), Graph-Auswahl, Fehler finden, Begründungsbausteine, Schritte ordnen.
1. Edvancev1: Payload je Format (wie lsa_question_payload und Session-Gegenstück), Antwortkodierung, Wertung als gekapselte Funktionen, die lsa_grade und wertung_testen nutzen, Fehlbild-Treffer je Format. pgTAP mit Grenzfällen (Reihenfolge, doppelte Werte, Vorzeichen, Bruch/Dezimal, leer heißt 1, Teilmenge).
2. Figurengenerator parabel unter scripts/figures/ nach tools/spec-figuren.sh: Parameter a, d, e, Bereich, Punkte, optional Gerade y = c und Nullstellen-Marken; pruefe_parabel.py mit mindestens drei pruefe_-Funktionen (Scheitel, Nullstellen, Achsenbeschriftung) und Negativkontrolle; CHECK von task_figures.generator erweitern.
3. edvance-app: je Format eine Komponente unter src/components/aufgaben/formate/ (jede Datei unter 400 Zeilen), Bedienung mit Finger und Tastatur, mindestens 44 pt Ziele, Barrierefreiheit (Rollen, Beschriftungen), reduzierte Bewegung. Vorlage: Schüler-App-Dummy (Üben, Transfer, Lösungsbeispiel). Dazu die Lösungsbeispiel-Ansicht (Schritte aufdecken, ein „Warum?“ mit drei Bausteinen).
4. Lenas Prüf-Vorschau zeigt alle Formate genauso wie das Tablet.
5. Ansichtstests bei 1180 × 820, 1024 × 768, 820 × 1180 und 390 × 844 je Format, leer und beantwortet; Bildschirmfotos nach docs/reihe1/A/abnahme/.
Zwei PRs: „Reihe 1 · A3 Formate Backend“ (Edvancev1) und „Reihe 1 · A3 Formate Player“ (edvance-app). Einspielen laut Regel.

A4 · BAUFORM-MOTOR UND PRÜFMASCHINE
1. scripts/bauformen/: gemeinsame Basis (Stufen, erzeugen, darstellen, loesen_unabhaengig mit sympy aus dem angezeigten Text bzw. den angezeigten Koeffizienten, fehlbilder, hinweise, loesungsweg, warum, figur) und je Bauform eine Datei.
2. Prüfmaschine mit den sieben Prüfungen aus Konzept §5. Prüfung 4 (Wertung) läuft gegen die echte Wertungslogik: Portiere sie dafür nicht nach Python, sondern prüfe über wertung_testen per dbread, sofern sie lesend aufrufbar ist; sonst über eine 1:1 getestete Nachbildung, deren Gleichheit ein pgTAP-Test absichert.
3. Negativkontrollen als Tests: falsche Lösung, kollidierende Fehlbilder, „+ −3x“, „1x²“, leerer Platzhalter, Dublette, LSA-Zwilling werden erkannt.
4. Export: Je Bauform und Version eine Datenmigration (Steckbrief, Instanzen, Lösungswege, Hinweise, Fehlbild-Zuordnungen, Figuren-Zeilen) und eine JSON-Vorschau unter docs/reihe1/A/bauformen/<KEY>.json. Instanzen starten mit Status draft, die Bauform mit zur_pruefung.
5. Befehl tools/bauform.sh <KEY> | --skill <skill> | --alle erzeugt, prüft, startet den Blindlöser und schreibt die Migration.
6. Blindlöser: Den startest du als Orchestrator (das Skript kann keinen Subagenten starten; es legt die Kindertexte unter docs/reihe1/A/blindloeser/<KEY>/ ab). Je Bauform löst ein frischer Subagent zehn zufällige Instanzen, oder alle, wenn es weniger sind, nur aus dem Kindertext (ohne Lösung, ohne Steckbrief). Mehr als 10 % Abweichung (mindestens eine): Bauform verdächtig, Grund in den Steckbrief, nicht ins Board.
6a. Prüfung 1 je Format und die Stufenregeln für Prüfung 2 und 3 genau nach Konzept §5 (Fehlbilder nur in den Stufen, für die sie gelten).
7. Pilot durchgängig: WZ-1 und NP-2 bis zur eingespielten Datenmigration.
PR „Reihe 1 · A4 Bauform-Motor“ samt Pilot-Migration. Einspielen laut Regel.

A5 · LENA-BOARD UND MELDEN
1. Bauform-Prüfansicht im Lena-Board, im Stil des bestehenden Boards und der Admin-Hülle: Steckbrief, sechs Beispiele wie auf dem Tablet (je Stufe mindestens eines), „Andere Beispiele“ (zieht andere vorhandene Instanzen), Fehlbilder mit Rückmeldungen, drei Hinweisstufen, Lösungsbeispiel mit Warum-Bausteinen, Prüfmaschine und Blindlöser als Befund. Entscheidung passt | unsicher | passt nicht mit Gründen, Tasten 1/2/3 wie im Board. Lena setzt „zur Freigabe“, Admins geben frei.
2. Reiter „Auffällig“: gemeldete und von der Bewährung markierte Instanzen mit Antworthäufigkeiten; Aktionen: Instanz wieder aktivieren, Bauform zur Überarbeitung.
3. Coach-Prüffragen im Board prüfbar (einzeln, kurzer Text).
4. Melde-Knopf „Aufgabe stimmt nicht“ in der Coach-Live-Sicht an der Aufgabe im Kind-Detail, als eigene Komponente, mit kleinstmöglichem Eingriff in die Seite (dort arbeitet auch Auftrag C).
5. Ansichtstests und Bildschirmfotos.
PR „Reihe 1 · A5 Lena-Board Bauformen“.

A6 · BAUFORMEN DER REIHE
1. Alle 47 Bauformen aus Konzept §4 mit vollständigem Steckbrief, je Fehlbild mit „gilt für Stufen“. Sprache: kurze Sätze, ein Gedanke je Satz, Fachwörter wie in der Schule, Rückmeldung nennt den Denkfehler, Hinweise verraten nie die Lösung (Konzept Session-Ablauf §5).
2. Fehlbild-Schlüssel, die beim Schreiben noch dazukommen, per Migration nachziehen (die Grundliste kam in A2).
3. Je Bauform, Rolle und Stufe rund 8 grüne Instanzen; für die Rolle generalprobe so viele, dass mindestens zehn Kinder je eine ungesehene bekommen.
4. Coach-Prüffragen: 1–2 je Kern-Skill (Prüffrage in neuem Kontext, Erwartung, Kriterium), Status zur Prüfung.
5. Blindlöser für jede Bauform. Ergebnisse gesammelt in docs/reihe1/A/blindloeser.md.
6. Drei Daten-PRs: „A6 Funktionen“ (PAR, SCH, NF, NS, EX inklusive EX-0), „A6 Gleichungen“ (WZ, NP, PQ, DI), „A6 Voraussetzungen“ (BIN, AUS, EIN, QW, KO, GL). Einspielen laut Regel.

A7 · ABNAHME UND BERICHT
Führe jeden Abnahmefall aus (pgTAP, Ansichtstest oder dbread) und trag das Ergebnis ins Protokoll ein.
1. Keine Aufgabe ist in beiden Pools; der Versuch, eine anzulegen, scheitert.
2. Die Session-Auswahl liefert nie eine LSA-Aufgabe, die LSA-Auswahl nie eine Session-Aufgabe.
3. WZ-1 mit x² = 9: {3; −3} in jeder Reihenfolge ist richtig; {3} zeigt die Rückmeldung des Fehlbilds „nur die positive Lösung“ und zählt als falsch; „keine Lösung“ ist falsch. Eine Teilmenge ohne passendes Fehlbild zeigt „Eine Lösung fehlt noch.“
4. Feldmaske zu f(x) = (x + 3)² − 1: [+][3] und [−][1] ist richtig; dieselbe Bedeutung in anderer Eingabe ist auch richtig.
5. Die Prüfmaschine verwirft jede Negativkontrolle aus A4.3.
6. Lena sieht NP-2 mit sechs Beispielen, je Stufe eines; „Andere Beispiele“ zeigt andere; „passt“ setzt zur Freigabe; nach der Sammelfreigabe liefert aufgabe_ziehen eine Instanz.
7. Meldet ein Coach eine Instanz, wird sie nicht mehr gezogen; nach der zweiten Meldung ist die Bauform pausiert und steht unter „Auffällig“.
8. Zehn simulierte Antworten mit viermal derselben unbekannten falschen Antwort machen die Instanz auffällig.
9. aufgabe_ziehen mit Rolle home liefert nie Stufe 4 oder 5; ein gezeigtes Lösungsbeispiel kommt für dasselbe Kind nie wieder.
10. Eine Textänderung an einer freigegebenen Bauform erhöht die Version, öffnet sie für Lena und nimmt alte Instanzen aus der Ziehung.
11. Alle 47 Bauformen stehen im Board mit grüner Prüfmaschine und bestandenem Blindlöser, oder mit dokumentiertem Grund.
12. Alle Formate sehen in Player und Prüf-Vorschau gleich aus (Bildschirmfotos).
Schluss: docs/reihe1/A/bericht.md mit allen PRs in Merge-Reihenfolge, eingespielten bzw. wartenden Migrationen, Abnahme-Ergebnissen, Lenas Prüfumfang (Anzahl Bauformen, Prüffragen, geschätzte Minuten) und offenen Punkten. Im Terminal höchstens 20 Zeilen Zusammenfassung. Dann STOPP.
```
