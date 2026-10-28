# Bauauftrag C · Session-Workflow (Reihenplanung, Phasen, Warm-up mit Abruf, Generalprobe)

Stand 27.10.2026 · Repos **Edvancev1** (Planung, Auswahl, Coach-Sicht) und **edvance-app** (Session-Bildschirme vor Ort) · Grundlage: `docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md` §2 und §9, `docs/reihe1/Konzept-Session-Ablauf-und-Aufgaben.md`

**Vorher (Rasit, 1 Minute)**
1. `reihe1-pakete.zip` in den Windows-Downloads-Ordner legen.
2. `EINSPIELEN = rasit` stehen lassen oder auf `orchestrator` ändern.
3. Den Block in eine neue Claude-Code-Session in WSL kopieren (eigener Zellij-Tab). Dieser Auftrag braucht Funktionen aus A (Aufgaben ziehen) und D (Übung zuhause). Er baut dagegen und wartet vor der Abnahme, bis sie in Prod sind.

---

```text
Du bist der Orchestrator für Bauauftrag C der Sessionreihe 1 bei Edvance. Du führst alle Phasen C0 bis C6 nacheinander bis zum Ende durch, ohne nach jeder Phase zu fragen. Du stoppst nur an den unten genannten Haltepunkten.

EINSPIELEN = rasit

ZIEL
Eine Session läuft nach dem Konzept: Das System plant die Reihe rückwärts von der Klassenarbeit, das Warm-up holt fällige Skills und Voraussetzungen ab, die Kernarbeit führt neue Skills über Erklärsequenz, Lösungsbeispiel, geführtes und selbstständiges Üben bis zum Transfer, der Recap schließt ab, und vor der Arbeit gibt es die Generalprobe. Der Coach sieht den Reihenplan und entscheidet. Grundlage für die erste Reihe ist Batu mit „Quadratische Funktionen und Gleichungen“, eine Session pro Woche.

SCHRITT 0 · UNTERLAGEN, WORKTREES
1. Repos ~/Edvancev1 und ~/edvance-app (sonst suchen), in beiden git fetch.
2. Worktrees nur für diesen Auftrag:
   git -C ~/Edvancev1 worktree add ../Edvancev1-C -b feat/rasit-reihe1-c0 origin/dev
   git -C ~/edvance-app worktree add ../edvance-app-C -b feat/rasit-reihe1-c3-app origin/dev
   Existieren sie: weiterverwenden. Nur dort arbeiten. npm ci, .env/.env.local aus dem Haupt-Checkout kopieren (nie committen).
3. mkdir -p docs/reihe1 && unzip -o "/mnt/c/Users/$WINUSER/Downloads/reihe1-pakete.zip" -d docs/reihe1 (beide Worktrees). Fehlt die Datei: melden und STOPP.
4. Lies vollständig: CLAUDE.md beider Repos, docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md (verbindlich, besonders §2, §3.1 und §9), docs/reihe1/Konzept-Session-Ablauf-und-Aufgaben.md, dieses Dokument. Öffne docs/reihe1/referenz/schueler-app-dummy.html (Kontext „Vor Ort“: alle Bildschirme o-…) und docs/reihe1/referenz/session-flow-dummy.html. Liegt coach-live-dummy.html im Repo oder in Downloads, öffne ihn als Vorlage der Coach-Sicht.
5. Lege docs/reihe1/C/fortschritt.md an und schreib nach jedem Schritt eine Zeile hinein (Datum, Phase, Ergebnis, PR-Link).

LEITPLANKEN (nicht verhandelbar)
- CLAUDE.md gilt vollständig. Keine Hex-Werte außerhalb der Tokens, keine Inline-Styles, Texte fürs Kind über die Textdateien.
- Das System schlägt vor, der Coach entscheidet. Systemvorschlag und Coach-Entscheidung sind getrennte Datenzustände. „Gemeistert“ nur nach Coach-Bestätigung. Der Lernpfad bewegt sich nur vor Ort. Übung zuhause verändert keinen Befund (FernUSG).
- Datenbank lesen nur über dbread, keine schreibende Abfrage gegen Prod.
- DDL nur als Migration nach supabase/migrations/ mit Rollback nach supabase/rollback/. Keine löschenden Anweisungen auf Inhalte.
- Vor jeder Änderung an session_naechster_schritt, an Spalten oder an Funktionen anderer Pakete: pg_proc-Scan aller Funktionen, die sie nutzen (Ergebnis in die PR).
- Zweitprüfung jeder Schemaänderung und jeder Änderung an session_naechster_schritt durch einen frischen Subagenten ohne deinen Kontext (nur Diff, Konzept §2 und §9, Konzept Session-Ablauf §1–4, Frage „Was ist falsch, was fehlt, was bricht?“). Ergebnis an die PR.
- Einspielen:
  - EINSPIELEN = rasit: fertigen Befehl als ~/einspielen/C-<nr>-<name>.sh ablegen (Zielprüfung: `psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres` und ein Test, dass $DATABASE_URL die Projekt-Ref von Prod enthält, die du in der Ist-Analyse aus supabase/config.toml bzw. .env festgestellt hast; dann per dbread die vorausgesetzten Objekte anderer Aufträge prüfen, sonst Abbruch mit klarer Meldung && Migration && History-Eintrag nach Repo-Muster && tools/schema-snapshot.sh, mit && verkettet), in PR und Protokoll schreiben, Jede Migration bekommt eine eigene Prüfabfrage (bei Datenmigrationen eine Zählabfrage), die als Kommentar im Skript steht. Warte, indem du diese Abfrage per dbread wiederholst: je Warteschritt ein Bash-Aufruf `sleep 540 && dbread …` mit timeout 600000 ms, ins Protokoll nur eine kurze Zeile je Stunde. Arbeite in der Wartezeit an allem weiter, was nicht davon abhängt. Nach 48 Stunden ohne Ergebnis: Bericht mit dem Stand schreiben, dann STOPP.
  - EINSPIELEN = orchestrator: nach grüner Zweitprüfung genau diesen Befehl selbst ausführen, per dbread prüfen, protokollieren; bei Fehler Rollback, melden, STOPP für diese Phase.
- Nach jedem Einspielen und nach jedem Rebase: Types in beiden Repos neu generieren (Befehle laut Repo) und committen. Generierte Dateien nie von Hand zusammenführen.
- Je Phase ein Branch auf dem vorherigen (feat/rasit-reihe1-c1-reihe usw.), je Phase eine PR gegen dev, nie main, mit „Baut auf PR #… auf“. Nie selbst mergen, nichts unter .github/. Vor jeder PR git fetch && git rebase origin/dev; gemeinsame Dateien (DATENVERTRAG.md, schema.sql, Types, Tokens, Textdateien) so zusammenführen, dass beide Seiten erhalten bleiben.
- Tests: npm run typecheck && npm test nach jeder Änderung; pgTAP wie im Repo üblich; edvance-app vor jeder PR npm run test:views.
- Abnahme-Umgebung: Schreibende Tests laufen dort, wo das Repo pgTAP heute ausführt (die Ist-Analyse klärt das), sonst in einem lokalen Supabase-Stack (`supabase start`, Docker), falls vorhanden, mit allen Migrationen und einem Seed (Testkind Batu, eine freigegebene Reihe). Die alte Shadow-DB auf 127.0.0.1 nicht verwenden. Gibt es beides nicht, kommen Abnahmefälle, die Schreibrechte brauchen, in die Live-Checkliste nach dem Merge und sind im Bericht so markiert.
- Warten auf andere Aufträge nach Konzept §9 („Schnittstellen-PR zuerst“, „Warten auf eine Datenbank-Funktion“). Fremde Funktionen erkennst du am Namen in pg_proc und am Kommentar 'reihe1 fertig'; die Signatur liest du im DATENVERTRAG im Worktree des Besitzers (../Edvancev1-A, ../Edvancev1-B usw.). Deine eigenen fertigen Funktionen markierst du in der Migration mit `comment on function … is 'reihe1 fertig';`. Fremde Funktionen rufst du nur aus plpgsql auf.
- Höchstens ein Subagent gleichzeitig.
- Schnittstellen (Konzept §9):
  - Du besitzt Reihenplanung, Phasen und Auswahl in session_naechster_schritt, Warm-up-Abruf, Lösungsbeispiel, Transfer, Recap, Generalprobe, die Wirkung von „Zeig's mir“, die Session-Bildschirme vor Ort, den Check-out und den Reihenplan in der Coach-Sicht.
  - Du nutzt von A: aufgabe_ziehen, aufgabe_zwilling, aufgabe_payload, aufgabe_werten, aufgabe_meta, aufgabe_gezeigt, skill_kann_entfallen, die Formate (Komponenten unter src/components/aufgaben/formate/) und die Lösungsbeispiel-Ansicht. Von B: die Komponente ErklaerVideo und erklaer_start mit Video. Von D: home_uebung_kurz, zeigs_mir_offen und die Komponente ThemenbaumAusschnitt. Diese Teile baust du nicht selbst nach.
  - Nicht anfassen: Tabellen und Funktionen von A, B und D, Lena-Board, Home-Bildschirme, die Kachel „Zuhause geübt“ im Check-in (gehört D), den Melde-Knopf (gehört A). Wo du in dieselbe Seite einbaust (Coach-Check-in, Kind-Detail), nur eigene Komponenten mit kleinstmöglichem Eingriff.
  - Fehlt eine Funktion von A, B oder D noch in Prod: gegen die Signatur aus §9 bauen; in Tests eine Attrappe nur innerhalb der Testtransaktion; vor der Abnahme warten, bis sie existiert (to_regprocedure per dbread, alle 10 Minuten, höchstens 48 Stunden).

HALTEPUNKTE
- Warten auf eingespielte Migrationen und auf Schnittstellen von A, B, D.
- Fehlende Unterlagen in Schritt 0.
- C0 zeigt, dass der Session-Rahmen (R1, A2, E1/E2a, C1) in wesentlichen Teilen nicht gebaut ist: Liste ins Protokoll, dann trotzdem weiter. Was fehlt und zum Konzept gehört, baust du in C2 mit, sofern es nicht einem anderen Auftrag gehört.
- Eine Phase scheitert nach zwei Korrekturrunden an derselben Prüfung: Befund ins Protokoll, mit der nächsten unabhängigen Phase weiter.

C0 · IST-ABGLEICH (nur lesen)
docs/reihe1/C/ist-analyse.md mit Belegen (Datei:Zeile auf origin/dev oder dbread samt Ausgabe):
1. Welche Pakete des Session-Rahmens sind gebaut: Platz-Zuweisung für Sessions, Antworten und Versuche, session_naechster_schritt (Phasen, Fall-Hierarchie, Zielquote, Modi gefuehrt/selbststaendig, Mischanteil), Stellschrauben mit Protokoll und Snapshot je Session, Erklärsequenz E1/E2a, Coach-Live C1, Mastery-Vorschlag und Coach-Bestätigung, pfad_tiefer, Exit-Aufgaben, Check-in am Tablet?
2. Wo stehen Schulthema und Klassenarbeiten (lead_themen, Angaben aus Erstgespräch und LSA wie „geschrieben/bevorstehend“, Datum), schul_themenplan, skill_thema, skill_kante?
3. Wo entstehen Befunde je Skill in der Session (Belege, „sicher“, Stufe)? Wo liest der Themenbaum sie?
4. Welche Bildschirme der Session gibt es in edvance-app (Wartebildschirm, Begrüßung, Warm-up, Erklärung, Üben, Check-out), und wie ist die Navigation gebaut? Gibt es im Check-out eine Termin-Wahl für Home Quests?
5. Coach-Sicht: Vorher-Briefing, Check-in, Live-Kacheln, Kind-Detail, Check-out, Danach.
6. Projekt-Ref von Prod (aus supabase/config.toml bzw. .env) für die Zielprüfung.
Am Ende: Tabelle „Konzept (Abschnitt) | gebaut | fehlt | gehört zu C, A, B oder D“.
PR „Reihe 1 · C0 Ist-Abgleich“ (nur docs).

C0b · EINBAUPUNKTE (Edvancev1, klein, zuerst zu mergen)
Nach Konzept §9: in der Coach-Sicht ein leerer Einbaupunkt im Check-in je Kind (für die Kachel „Zuhause geübt“ von D) und einer im Kind-Detail an der Aufgabe (für den Melde-Knopf von A), jeweils als kleine Komponente mit festen Props (Kind, Session bzw. Aufgabe), die ohne Inhalt nichts anzeigt. PR „Reihe 1 · C0b Einbaupunkte“ mit „Bitte zuerst mergen, A und D bauen dort ein.“ Dann weiter.

C1 · REIHENPLANUNG
1. Datenmodell: Reihe je Kind und Fach (Themen, Klassenarbeitsdatum oder leer, Takt pro Woche, Start, Status) und Plan mit Versionen (je Session Nummer, Datum, Skills, Kernideen, Art normal | generalprobe, Systemvorschlag und Coach-Änderung getrennt, Änderungsgrund).
2. Planungsfunktion genau nach Konzept §2.1 und §2.3: geplant wird je Kernidee; Skills der Klassenarbeitsthemen plus Graph-Abschluss über skill_kante (zieht z. B. gleichung_quadr_formel bei Nullstellen hinein); Zeitbedarf je Kernidee aus Stellschrauben (neu 12, schon gesehen 6, sicher 0; Voraussetzungen ohne Befund nur im Warm-up); Kapazität 36 Minuten mit 10 % Spielraum; Reihenfolge nach §2.3 Regel 4; letzte Session Generalprobe; Kürzen nach §2.3 Regel 5 („kann entfallen“ über skill_kann_entfallen von A, bis dahin aus einer kleinen Liste in den Stellschrauben mit fkt_quadr_extrem); ohne Datum rollierend vier Sessions. Termine aus Slots und Ferienkalender, so wie er im Repo schon genutzt wird. Lesefunktion reihenplan_kind nach Konzept §9 (für D), mit Kommentar 'reihe1 fertig'.
3. Neu planen nach jeder Session (beim Abschluss der Session) aus den Befunden. Coach-Änderungen bleiben erhalten, solange sie gültig sind.
4. Coach-Sicht (Edvancev1): Klassenarbeitsdatum im Check-in erfassen bzw. bestätigen, falls es noch keinen Ort dafür gibt. Karte „Reihe“ im Vorher-Briefing und im Kind-Detail: Sessions bis zur Arbeit, heutige Skills, Warnung „Die Reihe passt nicht in n Sessions: X fällt weg.“ Der Coach kann einen Skill verschieben oder bestätigen.
5. pgTAP mit Batu als Testfall (Daten nur in der Testtransaktion, alle Skills ohne Befund außer den LSA-Befunden): acht Sessions ergeben Daten und Kernideen-Reihenfolge der Tabelle in Konzept §2.2 (je Session höchstens 36 Minuten plus 10 %); bei sechs Sessions fällt Extremwerte weg und der Coach sieht die Warnung; ohne Datum entsteht ein rollierender Plan für vier Sessions ohne Generalprobe.
PR „Reihe 1 · C1 Reihenplanung“, Einspielen laut Regel.

C2 · PHASEN UND AUSWAHL
In session_naechster_schritt bzw. den Funktionen dahinter, nach Konzept Session-Ablauf §1–4 und Konzept Reihe §2.4–2.5:
1. Warm-up genau nach Konzept §2.4: 3–4 Aufgaben ohne Hinweise, 1–2 fällige Abrufe plus 1–2 Voraussetzungen des heutigen Ziels; Fälligkeit „letzte Session mit Beleg plus Abstand“ (Abstand 1 → 2 → 4 nach richtigem Abruf, Fehler setzt auf 1; Belege aus allen Phasen zählen); mehr Fällige als Plätze: der am längsten überfällige zuerst, der Rest rückt nach; Stufe eine unter der zuletzt sicheren, mindestens 1, sonst die nächste vorhandene. Zwei Fehler auf einer Voraussetzung: Vorschlag „eine Stufe tiefer?“ an den Coach wie bisher. Lies vorher ../Edvancev1-A/docs/reihe1/A/an-C.md: Steht dort, dass die heutige Session-Auswahl noch LSA-Aufgaben ziehen kann, behebst du das hier.
2. Kernarbeit nach Reihenplan: neuer Skill beginnt mit der Erklärsequenz (Video, wenn freigegeben, sonst Karten), dann ein Lösungsbeispiel (Rolle beispiel), dann geführte Übung mit Zwilling und Hinweisstufen, dann selbstständig mit Zielquote und Mischanteil älterer Skills, ab sicherer Stufe 3 Transfer. Sitzt ein Skill, folgt der nächste aus dem Plan. Aufgaben kommen über aufgabe_ziehen mit Rolle und Stufe, nach einer falschen Antwort über aufgabe_zwilling mit derselben Rolle. Jede gezeigte Aufgabe und jedes Lösungsbeispiel meldest du über aufgabe_gezeigt. Payload und Wertung kommen über aufgabe_payload und aufgabe_werten.
3. Recap in den letzten Minuten vor dem Check-out: 2–3 Recap-Aufgaben zu den Skills der Stunde, ohne Hinweise, Ergebnis als Hinweis an den Coach, kein Beleg.
4. Generalprobe in der Session mit Art generalprobe genau nach Konzept §2.5: rund 20–25 Minuten, höchstens acht Kern-Skills (schwächste Befunde zuerst), je eine ungesehene Instanz der Rolle generalprobe auf Stufe 3 (4, wenn dort schon sicher), dazu ein bis zwei Transferaufgaben, ohne Hinweise, Rückmeldung erst am Ende, danach „sicher / noch üben“ je Skill; „noch üben“ startet eine kurze Übungsrunde. Belege zählen normal.
5. „Zeig's mir“ nach Konzept §9: Hat der Coach im Check-in übernommen (zeigs_mir_offen), ist die erste Aufgabe der Kernarbeit eine Aufgabe dieses Skills, Rolle uebung, auf der zuletzt sicheren Stufe (ohne sichere Stufe: 1), ohne Hinweis-Knopf. Kein Sonderstatus, keine Bewertung der Übung zuhause.
6. Alle Schwellen und Zeiten als Stellschrauben mit Startwert; jede Session speichert, mit welchen Werten sie lief.
7. pgTAP für jede Regel, besonders: Warm-up ohne Hinweise; Abruf nach 1, 2, 4 Sessions; Lösungsbeispiel-Instanz kommt nie wieder; Transfer erst ab Stufe 3; Generalprobe nur ungesehene Aufgaben; Zeig's mir nur nach Coach-Übernahme.
PR „Reihe 1 · C2 Phasen und Auswahl“, Einspielen laut Regel.

C3 · BILDSCHIRME VOR ORT (edvance-app)
Nach dem Schüler-App-Dummy, Kontext „Vor Ort“, mit vorhandenen Komponenten und Tokens:
1. Warten, Begrüßung (mit der Zeile „n× zuhause geübt: Skill“ aus home_uebung_kurz, n = Quests seit der letzten abgeschlossenen Session, nur wenn vorhanden), Warm-up ohne Hinweis-Knopf, Erklärung (ruft ErklaerVideo von B auf; Karten wie bisher als Rückfall), Lösungsbeispiel (Komponente von A), Üben und Transfer mit allen Formaten von A, Recap, Generalprobe mit Ergebnisansicht, Check-out.
2. Check-out: was heute geschafft, Themenbaum-Ausschnitt (Komponente ThemenbaumAusschnitt von D; bis sie auf origin/dev liegt, ohne diesen Teil), „Zuhause weiterüben“ mit den Skills der Stunde. Keine Termin-Wahl und keine Quest-Tage (Entscheidung 27.10.). Eine vorhandene Termin-Wahl entfernen.
3. Phasenleiste und Rückmeldungen wie im Dummy: richtig in Gold, nie im Mastery-Grün; falsch mit Fehlbild-Satz.
4. Ansichtstests bei 1180 × 820, 1024 × 768, 820 × 1180 je Bildschirm; Vergleichsbilder neben dem Dummy nach docs/reihe1/C/abnahme/.
PR „Reihe 1 · C3 Session-Bildschirme“.

C4 · COACH-SICHT
1. Live-Kachel und Kind-Detail zeigen Phase, Reihen-Session (z. B. „Session 3 von 8“), heutigen Skill, Generalprobe-Ergebnis je Skill.
2. Danach-Ansicht: neuer Reihenplan nach dem Abschluss, mit Änderungen gegenüber vorher.
3. Nur eigene Komponenten, kleinstmöglicher Eingriff; die Kachel „Zuhause geübt“ (D) und der Melde-Knopf (A) bleiben unberührt.
PR „Reihe 1 · C4 Coach-Sicht“.

C5 · DURCHLAUF MIT TESTDATEN
1. Ende-zu-Ende in der Web-Ausgabe (Playwright gegen npx expo export --platform web, statisch ausgeliefert) mit einem Datenvertrags-Mock auf Basis echter Funktionsantworten: zwei Sessions für Batu (Session 1 und 2 der Reihe), danach eine Generalprobe. Kein Schreibzugriff auf Prod.
2. Bildschirmfotos jeder Phase nach docs/reihe1/C/abnahme/durchlauf/.
PR „Reihe 1 · C5 Durchlauf“.

C6 · ABNAHME UND BERICHT
Führe aus und protokolliere:
1. Ein Kind mit Klassenarbeit in acht Wochen bekommt acht geplante Sessions, die letzte als Generalprobe.
2. Passt die Reihe nicht, fällt zuerst Extremwerte weg, und der Coach sieht die Warnung.
3. Ein Skill, der nur in Session 1 einen Beleg hat, ist in Session 2 fällig; nach richtigem Abruf in Session 2 wieder in Session 4, nach richtigem Abruf dort in Session 8. Ein Fehler setzt den Abstand auf 1. Sind mehr Skills fällig als Plätze, kommt der am längsten überfällige zuerst, der Rest rückt nach.
4. Das Warm-up zeigt nie einen Hinweis-Knopf.
5. Ein neuer Skill beginnt mit der Erklärsequenz, danach kommt ein Lösungsbeispiel, das dasselbe Kind nie als Aufgabe bekommt.
6. Nach einer falschen Antwort kommt der Zwilling derselben Bauform und Stufe.
7. Transfer erscheint erst ab sicherer Stufe 3.
8. Die Generalprobe enthält nur ungesehene Instanzen der Rolle generalprobe, höchstens acht Skills, zeigt keine Rückmeldung bis zum Ende und dann „sicher / noch üben“ je Skill.
9. Hat der Coach „Zeig's mir“ übernommen, ist die erste Aufgabe der Kernarbeit eine Aufgabe dieses Skills ohne Hinweis-Knopf; bei „Nicht heute“ nicht.
10. Der Check-out hat keine Termin-Wahl.
11. Eine Home Quest ändert keinen Befund und keinen Plan.
12. Der Coach ändert den Plan; der Systemvorschlag bleibt getrennt gespeichert.
Schluss: docs/reihe1/C/live-checkliste.md (nach dem Merge mit einem Testkind vor Ort durchspielen) und docs/reihe1/C/bericht.md mit PRs in Merge-Reihenfolge, Migrationen, Abnahme, offenen Punkten. Im Terminal höchstens 20 Zeilen. Dann STOPP.
```
