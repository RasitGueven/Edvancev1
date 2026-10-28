# Bauauftrag D · Schüler-App Home light (Anmeldung, Quests, Themenbaum, Profil, Coach sieht Übung, App Store und Play Store)

Stand 27.10.2026 · Repos **edvance-app** (Hauptteil) und **Edvancev1** (Funktionen, Coach-Kachel, Geräte in der Akte) · Grundlage: `docs/reihe1/referenz/schueler-app-dummy.html` (Kontext „Zuhause“), `docs/reihe1/Anforderung-Themenbaum.md`, `docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md` §9

**Vorher (Rasit, 5 Minuten)**
1. `reihe1-pakete.zip` in den Windows-Downloads-Ordner legen.
2. Für die Store-Phase: Apple Developer Program und Google Play Console für die Edvance GmbH (falls noch nicht vorhanden) und einmal `eas login` in WSL. Fehlt das, baut der Agent alles bis zum fertigen Build und hält vor dem Hochladen an.
3. `EINSPIELEN = rasit` stehen lassen oder auf `orchestrator` ändern.
4. Den Block in eine neue Claude-Code-Session in WSL kopieren (eigener Zellij-Tab).

---

```text
Du bist der Orchestrator für Bauauftrag D der Sessionreihe 1 bei Edvance. Du führst alle Phasen D0 bis D8 nacheinander bis zum Ende durch, ohne nach jeder Phase zu fragen. Du stoppst nur an den unten genannten Haltepunkten.

EINSPIELEN = rasit

ZIEL
Kinder mit laufendem Vertrag melden sich zuhause einmal mit ihrem Zugangscode an (Handy und Tablet) und können jederzeit Quests üben, ohne Quest-Tage. Der Themenbaum zeigt, dass zuhause geübt wurde, aber nie Mastery. Der Coach sieht im Check-in, was zuhause geübt wurde, und kann „Zeig's mir“ übernehmen. Die App kommt nativ in App Store und Play Store. Die Tablets vor Ort laufen weiter als Web-App.

SCHRITT 0 · UNTERLAGEN, WORKTREES
1. Repos ~/edvance-app und ~/Edvancev1 (sonst suchen), in beiden git fetch.
2. Worktrees nur für diesen Auftrag:
   git -C ~/edvance-app worktree add ../edvance-app-D -b feat/rasit-reihe1-d0 origin/dev
   git -C ~/Edvancev1 worktree add ../Edvancev1-D -b feat/rasit-reihe1-d1-db origin/dev
   Existieren sie: weiterverwenden. Nur dort arbeiten. npm ci, .env/.env.local aus dem Haupt-Checkout kopieren (nie committen).
3. mkdir -p docs/reihe1 && unzip -o "/mnt/c/Users/$WINUSER/Downloads/reihe1-pakete.zip" -d docs/reihe1 (beide Worktrees). Fehlt die Datei: melden und STOPP.
4. Lies vollständig: CLAUDE.md beider Repos, docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md §9 (verbindlich), docs/reihe1/Anforderung-Themenbaum.md, dieses Dokument. Öffne docs/reihe1/referenz/schueler-app-dummy.html und geh alle Bildschirme der Kontexte „Zuhause“ und „Coach“ durch (h-push ausgenommen, siehe unten). Er ist die Vorlage für Aufbau, Texte und Verhalten.
5. Lege docs/reihe1/D/fortschritt.md an und schreib nach jedem Schritt eine Zeile hinein (Datum, Phase, Ergebnis, PR-Link).

ENTSCHEIDUNGEN (Rasit 27.10.2026, nicht neu verhandeln)
1. Umfang zum Soft Launch: Anmeldung mit Code, Start, Quests, Pfad/XP, Avatar, Themenbaum, Profil, Eddie ohne Sprachmodell (Suche, Vorschläge, „Frage für meinen Coach“). Push-Nachrichten, Spind und Skins gehören nicht dazu.
2. Keine Quest-Tage. Quests sind jederzeit möglich, keine Termin-Wahl, kein Kalender, keine Erinnerung an einen Tag.
3. FernUSG: Zuhause wird nur gespeichert, dass geübt wurde (Skill, Anzahl Aufgaben, Dauer, Zeitpunkt). Keine Antworten, keine Richtig/Falsch-Werte, keine Fehlbilder auf dem Server. Das Kind bekommt Rückmeldung direkt in der App. Kein Befund, keine Stufe, kein Lernpfad ändert sich zuhause.
4. Der Themenbaum zeigt Übung zuhause als türkisen Ring mit „n×“ seit der letzten Session, nie als „sicher“ oder „gemeistert“. Text im Blatt: „Zuhause n× geübt. Ob es sitzt, zeigst du in der Session.“
5. Der Coach sieht vor Ort, was zuhause geübt wurde, und bekommt höchstens einen Vorschlag „Zeig's mir“ je Kind und Session (Skill mit mindestens zwei Übungen seit der letzten Session, noch nicht sicher). Er entscheidet: Übernehmen oder Nicht heute.
6. Verteilung nativ über App Store und Play Store. Die Web-App für die Kiosk-Tablets bleibt und darf nicht brechen.
7. XP misst Verhalten, Abzeichen messen Kompetenz. XP aus Übung zuhause berührt nie Kompetenz.

LEITPLANKEN (nicht verhandelbar)
- CLAUDE.md gilt vollständig. Keine Hex-Werte außerhalb der Tokens, keine Inline-Styles, Texte fürs Kind über die Textdateien. Die Schüler-App behält den helleren Blauverlauf.
- Datenschutz: keine Tracking- oder Werbe-SDKs, keine Analytics mit Personenbezug, nur nötige Berechtigungen. Kinder sehen nie Daten anderer Kinder.
- Datenbank lesen nur über dbread, keine schreibende Abfrage gegen Prod.
- DDL nur als Migration nach supabase/migrations/ mit Rollback nach supabase/rollback/. Keine löschenden Anweisungen auf Inhalte.
- Vor Änderungen an Spalten oder an Funktionen anderer Pakete: pg_proc-Scan (Ergebnis in die PR).
- Zweitprüfung jeder Schemaänderung und der Anmeldung durch einen frischen Subagenten ohne deinen Kontext (nur Diff, Entscheidungen oben, Konzept §9, Frage „Was ist falsch, was fehlt, was bricht, wo leckt etwas?“). Ergebnis an die PR.
- Einspielen:
  - EINSPIELEN = rasit: fertigen Befehl als ~/einspielen/D-<nr>-<name>.sh ablegen (Zielprüfung: `psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres` und ein Test, dass $DATABASE_URL die Projekt-Ref von Prod enthält, die du in der Ist-Analyse aus supabase/config.toml bzw. .env festgestellt hast; dann per dbread die vorausgesetzten Objekte anderer Aufträge prüfen, sonst Abbruch mit klarer Meldung && Migration && History-Eintrag nach Repo-Muster && tools/schema-snapshot.sh, mit && verkettet), in PR und Protokoll schreiben, Jede Migration bekommt eine eigene Prüfabfrage (bei Datenmigrationen eine Zählabfrage), die als Kommentar im Skript steht. Warte, indem du diese Abfrage per dbread wiederholst: je Warteschritt ein Bash-Aufruf `sleep 540 && dbread …` mit timeout 600000 ms, ins Protokoll nur eine kurze Zeile je Stunde. Arbeite in der Wartezeit an allem weiter, was nicht davon abhängt. Nach 48 Stunden ohne Ergebnis: Bericht mit dem Stand schreiben, dann STOPP.
  - EINSPIELEN = orchestrator: nach grüner Zweitprüfung genau diesen Befehl selbst ausführen, per dbread prüfen, protokollieren; bei Fehler Rollback, melden, STOPP für diese Phase.
- Nach jedem Einspielen und nach jedem Rebase: Types in beiden Repos neu generieren (Befehle laut Repo) und committen. Generierte Dateien nie von Hand zusammenführen.
- Je Phase ein Branch auf dem vorherigen (feat/rasit-reihe1-d1-anmeldung usw.), je Phase eine PR gegen dev, nie main, mit „Baut auf PR #… auf“. Nie selbst mergen, nichts unter .github/. Vor jeder PR git fetch && git rebase origin/dev; gemeinsame Dateien so zusammenführen, dass beide Seiten erhalten bleiben.
- Tests: npm run typecheck && npm test nach jeder Änderung; pgTAP wie im Repo üblich; vor jeder PR npm run test:views.
- Abnahme-Umgebung: Schreibende Tests laufen dort, wo das Repo pgTAP heute ausführt (die Ist-Analyse klärt das), sonst in einem lokalen Supabase-Stack (`supabase start`, Docker), falls vorhanden, mit allen Migrationen und einem Seed (Testkind Batu, eine freigegebene Reihe). Die alte Shadow-DB auf 127.0.0.1 nicht verwenden. Gibt es beides nicht, kommen Abnahmefälle, die Schreibrechte brauchen, in die Live-Checkliste nach dem Merge und sind im Bericht so markiert.
- Warten auf andere Aufträge nach Konzept §9 („Schnittstellen-PR zuerst“, „Warten auf eine Datenbank-Funktion“). Fremde Funktionen erkennst du am Namen in pg_proc und am Kommentar 'reihe1 fertig'; die Signatur liest du im DATENVERTRAG im Worktree des Besitzers (../Edvancev1-A, ../Edvancev1-B usw.). Deine eigenen fertigen Funktionen markierst du in der Migration mit `comment on function … is 'reihe1 fertig';`. Fremde Funktionen rufst du nur aus plpgsql auf.
- Höchstens ein Subagent gleichzeitig.
- Schnittstellen (Konzept §9):
  - Du besitzt Anmeldung und Geräte, home_uebung mit home_uebung_melden und home_uebung_kurz, zeigs_mir_offen und zeigs_mir_entscheiden samt Kachel im Coach-Check-in, die Home-Bildschirme, Themenbaum mit Übungsspuren, Profil, Eddie ohne Sprachmodell, Store-Build.
  - Du nutzt von A: aufgabe_ziehen mit Rolle home, aufgabe_payload, aufgabe_werten und die Formate (Komponenten unter src/components/aufgaben/formate/). Von B: ErklaerVideo im Modus „zuhause“, mediathek_kind, mediathek_angesehen und eddie_index. Von C: reihenplan_kind und den Einbaupunkt im Coach-Check-in. Vom Avatar-Paket AV1: die Figur unter src/components/avatar/ (fehlt sie auf origin/dev: Platzhalter mit derselben Schnittstelle, im Bericht nennen).
  - Nicht anfassen: Tabellen und Funktionen von A, B und C, die Session-Bildschirme vor Ort, session_naechster_schritt. Die Begrüßungszeile „n× zuhause geübt“ vor Ort baut C mit deiner Funktion.
  - Fehlt eine Funktion oder Komponente von A, B oder C noch: gegen die Signatur aus §9 bauen, in Tests eine Attrappe nur innerhalb der Testtransaktion, vor der Abnahme warten, bis sie existiert (to_regprocedure per dbread, alle 10 Minuten, höchstens 48 Stunden). Bis dahin zeigt die App einen ruhigen Leerzustand („Deine Quests kommen bald“), keinen Fehler.

HALTEPUNKTE
- Warten auf eingespielte Migrationen und auf Schnittstellen von A und B.
- Fehlende Unterlagen in Schritt 0.
- D0 ergibt, dass die Anmeldung eine Einstellung im Supabase-Dashboard braucht (z. B. anonyme Anmeldung einschalten): Schritt ins Protokoll und in ~/einspielen/D-dashboard.md, weiterbauen, vor der Abnahme von D1 per Test prüfen, ob die Einstellung aktiv ist (warten wie oben).
- Vor jedem EAS-Build (D6 und D7): Fehlen Konten oder `eas whoami` schlägt fehl: Build lokal bzw. als EAS-Build vorbereiten, Schritte für Rasit in docs/reihe1/D/store/rasit.md, dann mit D8 weiter.
- Eine Phase scheitert nach zwei Korrekturrunden an derselben Prüfung: Befund ins Protokoll, mit der nächsten unabhängigen Phase weiter.

D0 · IST-ANALYSE (nur lesen)
docs/reihe1/D/ist-analyse.md mit Belegen (Datei:Zeile auf origin/dev oder dbread samt Ausgabe):
1. App-Aufbau: Router, Kiosk-Modus vor Ort (wie weiß die App heute, dass sie Kiosk ist?), wie ein Home-Modus daneben passt, Plattformweiche web/nativ.
2. Zugangscode aus K1: Tabelle, Erzeugung, Maskierung, Sperre, Versand, Admin-Oberfläche. Was fehlt zum Einlösen?
3. Auth: Supabase-Konfiguration, ob anonyme Anmeldung aktiv ist, Rollen, RLS-Muster für Kinderkonten. Vorschlag für die Anmeldung mit Code (Vorgabe: Code einmal je Gerät, danach bleibt das Kind angemeldet; höchstens drei Geräte je Kind; Admin kann ein Gerät abmelden und einen neuen Code erzeugen; der Code allein gibt nach dem Einlösen keinen Zugriff mehr; Versuche begrenzt, z. B. 5 je 15 Minuten; nur bei laufendem Vertrag). Bevorzugt: anonyme Supabase-Anmeldung plus Verknüpfung per Funktion. Sonst eine Server-Route in Edvancev1. Begründe die Wahl.
   Sicherheitsprüfung vorab, falls anonyme Anmeldung: Anonyme Nutzer haben die Rolle authenticated. Prüfe alle Richtlinien in pg_policies und alle Funktionen mit Rechteprüfung: Wo reicht heute „authenticated“ allein für Zugriff? Liste sie im Dokument und schließe sie in D1 (Prüfung auf verknüpftes Kind bzw. auf is_anonymous), mit pgTAP-Tests als anonymer Nutzer ohne und mit Verknüpfung. Erst danach darf Rasit die Einstellung einschalten.
4. Pfad/XP: gibt es Tabellen oder Funktionen? Abzeichen (badge_family, badge_tier), Coach-Bestätigung?
5. Themenbaum: ist etwas aus der Anforderung gebaut (schueler_kompetenz_offen, Befunde aus LSA und Session, Level)?
6. Avatar AV1: auf origin/dev vorhanden? Schnittstelle der Komponente.
7. Native Bereitschaft: app.json/app.config, eas.json, Bundle-IDs, Icons, Splash, Schriften, react-native-svg und react-native-reanimated nativ, Expo SDK 57, Prebuild-Fähigkeit.
8. Wo kann ein Kind heute Aufgaben zuhause bearbeiten (gibt es eine Prüffunktion, die nichts speichert)?
9. Projekt-Ref von Prod (aus supabase/config.toml bzw. .env) für die Zielprüfung.
Am Ende: Tabelle „Teil des Ziels | vorhanden | fehlt | Phase“.
PR „Reihe 1 · D0 Ist-Analyse“ (nur docs).

D0b · SCHNITTSTELLEN-PR (edvance-app, klein, zuerst zu mergen)
src/components/themenbaum/ThemenbaumAusschnitt.tsx als Platzhalter mit festen Props (Kind, Skills der Stunde), der ohne Daten nichts anzeigt; Props im DATENVERTRAG (Edvancev1). Home-Routen als eigene Gruppe anlegen (leer), damit C und D sich im Router nicht in die Quere kommen. PR „Reihe 1 · D0b Schnittstellen“ mit „Bitte zuerst mergen, C wartet darauf.“ Dann weiter.

D1 · ANMELDUNG MIT CODE UND GERÄTE
1. Edvancev1: Einlösen des Codes nach D0 (Funktion oder Route), Tabelle der Geräte je Kind (Name, angemeldet seit, zuletzt gesehen, abgemeldet), Begrenzungen aus D0.3, Protokoll der Versuche ohne Klartext-Code. In der Schülerakte für Admins: Geräteliste, „Gerät abmelden“, „Neuen Code erzeugen“ (Maskierung wie bisher), Freischalten des Codes, falls er noch gesperrt ist.
2. edvance-app: Bildschirm „Code eingeben“ nach Dummy h-code, danach Start. Abgemeldetes Gerät landet wieder auf h-code mit freundlichem Satz.
3. pgTAP und Tests: falscher Code, abgelaufener Vertrag, viertes Gerät, abgemeldetes Gerät, zu viele Versuche, ein Kind sieht nie Daten eines anderen.
Zwei PRs, Einspielen laut Regel.

D2 · ÜBUNG ZUHAUSE (Daten und Coach)
1. Edvancev1: home_uebung (eine Zeile je erledigter Quest: Kind, Skill, Anzahl Aufgaben, Dauer, Zeitpunkt; keine Spalte für Antworten oder Richtigkeit), home_uebung_melden, home_uebung_kurz, zeigs_mir_offen, zeigs_mir_entscheiden nach Konzept §9 (Zählweise „n×“ = Quests seit der letzten abgeschlossenen Session vor Ort). Vorschlagsregel aus Entscheidung 5 mit dieser Zählweise. Zuhause prüft die App Antworten über aufgabe_werten von A (rein, schreibt nie) und lädt Aufgaben über aufgabe_payload; du speicherst keine Antwort.
1a. kompetenz_offen(p_kind) nach Konzept §9 und Anforderung Themenbaum §3, früh in dieser Phase, weil B (Mediathek) und D4 sie brauchen. Alle fertigen Funktionen bekommen den Kommentar 'reihe1 fertig'.
2. XP: Buchung für erledigte Quests (Startwert 10 XP je Quest, Stellschraube), getrennt von jeder Kompetenz. Fehlt ein XP-Modell (D0.4): kleines eigenes, nur Verhalten.
3. Kachel „Zuhause geübt“ im Coach-Check-in (Edvancev1) nach Dummy c-checkin: je Kind Balken je Skill seit der letzten Session, der eine Vorschlag „Zeig's mir“ mit Übernehmen / Nicht heute, offene „Fragen für meinen Coach“ aus Eddie. Eigene Komponente, kleinstmöglicher Eingriff in die Seite (dort baut auch C).
4. pgTAP: home_uebung_melden speichert nie Antworten; eine Wertung zuhause über aufgabe_werten lässt alle Tabellen unverändert (Zeilenzahlen vorher und nachher); kein Befund, keine Stufe, kein Plan ändert sich; nur das Kind selbst meldet; Coach und Admin lesen; höchstens ein Vorschlag je Kind und Session.
5. Die Kachel kommt in den Einbaupunkt von C (C0b). Liegt er noch nicht auf origin/dev, wartest du nach Konzept §9 und baust in der Zeit die Kachel als eigene Komponente fertig.
Zwei PRs (Backend, Coach), Einspielen laut Regel.

D3 · START UND QUESTS (edvance-app)
Nach Dummy h-start, h-quest, h-fertig:
1. Start: empfohlene Quest (Skill aus der letzten Session bzw. aus reihenplan_kind von C, sonst ein offener Skill aus kompetenz_offen), freie Wahl unter offenen Skills, „Diese Woche geübt“, „Wochen mit Übung“. Keine Quest-Tage, kein Kalender.
2. Quest: fünf Aufgaben über aufgabe_ziehen mit Rolle home, alle Formate von A, Rückmeldung sofort über die Prüffunktion aus D2, Hinweise wie in der Session. Abbrechen ist erlaubt; gemeldet wird, was erledigt ist.
3. Fertig: Avatar jubelt, XP, Satz „Das hilft dir in der nächsten Session.“, Übungsspur sichtbar.
4. Leerzustände, solange A noch nicht in Prod ist.
PR „Reihe 1 · D3 Start und Quests“.

D4 · THEMENBAUM MIT ÜBUNGSSPUREN
Nach der Anforderung Themenbaum (Zustände, Offen-Regeln 1–6, Level 0–5, Aufbau ohne Scrollen auf iPad quer und iPhone) und dem Dummy h-baum:
1. Befunde nur aus LSA und Session, Mastery nur nach Coach-Bestätigung.
2. Übungsspur: türkiser Ring mit „n×“ seit der letzten Session, ohne Zustandswechsel. Text im Blatt wie Entscheidung 4.
3. Detailblatt: „Als Home Quest üben“ startet eine Quest dieses Skills; „Erklärsequenz ansehen“ spielt über mediathek_kind und ErklaerVideo (Modus zuhause), sonst ausgegraut „kommt bald“.
4. Die Offen-Regeln liefert kompetenz_offen aus D2. Die echte Komponente ThemenbaumAusschnitt (Props aus D0b) für den Check-out von C baust du hier mit.
5. Ansichtstests bei 1180 × 820 und 390 × 844 für Batu; kein Text ragt aus einem Knoten; Abnahmefälle der Anforderung §8.
Zwei PRs, falls Backend nötig, sonst eine.

D5 · PROFIL UND EDDIE OHNE SPRACHMODELL
1. Profil nach Dummy h-profil: Avatar mit Posen (AV1), Pfad (XP, Wochen mit Übung) und Kompetenz (nur coach-bestätigte Abzeichen, sonst ruhiger Leerzustand) streng getrennt.
2. Eddie nach Dummy h-eddie: Suche über Skills und freigegebene Sequenzen (eddie_index von B), Vorschlagschips, Verweise in den Baum oder auf eine Sequenz ab einem Beat, „Frage für meinen Coach“ (kurzer Text, landet in der Kachel aus D2.3). Kein Sprachmodell, kein freier Chat.
PR „Reihe 1 · D5 Profil und Eddie“.

D6 · HANDY UND TABLET, WEB UND NATIV
1. Layouts für iPhone (390 × 844), großes Android-Handy (412 × 915), iPad hoch und quer.
2. Kiosk-Web-App vor Ort unverändert: Regressionstest für LSA und Session (vorhandene Ansichtstests grün).
3. Nativer Lauf: In WSL gibt es keinen iOS-Simulator. Android-Emulator, wenn verfügbar; sonst EAS-Development-Build. Jeder EAS-Build braucht `eas login`: Prüfe vorher `eas whoami`. Schlägt es fehl, ist das ein Haltepunkt für alle EAS-Schritte (siehe unten), und du machst ohne nativen Lauf weiter. SVG, Animationen und Schriften nativ prüfen, sobald ein Build läuft.
PR „Reihe 1 · D6 Geräte“.

D7 · APP STORE UND PLAY STORE
1. app.config: Name „Edvance“, Bundle-ID und Package de.edvanceacademy.app (falls in D0 schon anders festgelegt: das Vorhandene), Icons und Splash aus den Marken-Tokens, Hochformat und Querformat, minimale Berechtigungen, iOS Privacy Manifest.
2. eas.json mit development, preview, production. Versionen und Build-Nummern automatisch.
3. Builds iOS und Android über EAS. Wenn Konten und Login vorhanden: Upload in TestFlight (intern) und Play Console (interner Test).
4. Texte und Angaben als Entwurf unter docs/reihe1/D/store/: Beschreibung kurz und lang (Deutsch), Schlüsselwörter, Altersfreigabe laut Fragebogen der Stores (Zielgruppe zum Start Klassen 8–10; nicht die Kinder-Kategorie, weil sie für unter 12-Jährige gedacht ist), App-Datenschutz (Apple) und Datensicherheit (Google) passend zu D1–D5, Hinweis auf die Datenschutzerklärung, Testzugang für die Prüfer der Stores (Testkind mit Testcode, nur Phantasiedaten).
5. Das Einreichen zur Store-Prüfung macht Rasit. Die Schritte stehen in docs/reihe1/D/store/rasit.md, dazu: Testkind mit Testvertrag und Testcode für die Store-Prüfer anlegen (Phantasiedaten; das ist ein Schreibzugriff auf Prod und deshalb Rasits Schritt), Apple-Zugangsdaten beim ersten iOS-Build interaktiv bestätigen. Hinweis in rasit.md: Nutzen später jüngere Kinder die Home-App, müssen Altersangaben in beiden Stores angepasst werden.
PR „Reihe 1 · D7 Store“.

D8 · ABNAHME UND BERICHT
Führe aus und protokolliere:
1. Ein Kind mit laufendem Vertrag löst den Code auf dem Handy ein und bleibt angemeldet; auf dem Tablet ebenso; ein viertes Gerät wird abgelehnt.
2. Ein abgemeldetes Gerät landet auf „Code eingeben“; ein falscher Code nach fünf Versuchen wird für 15 Minuten gesperrt.
3. Der Start hat keine Quest-Tage und keine Termin-Wahl; eine Quest ist jederzeit startbar.
4. Nach einer Quest speichert der Server nur Skill, Anzahl, Dauer und Zeitpunkt; keine Antworten, keine Richtigkeit (pgTAP und Prüfung der Netzwerkaufrufe im Test).
5. Nach drei Quests zum Nullprodukt (gleichung_quadr_faktor) zeigt der Themenbaum am Knoten „3×“ im türkisen Ring, der Zustand bleibt unverändert.
6. Im Coach-Check-in steht „3× geübt“ mit dem Vorschlag „Zeig's mir“; Übernehmen und Nicht heute werden gespeichert; höchstens ein Vorschlag je Kind und Session.
7. Profil trennt Pfad und Kompetenz; ohne Coach-Bestätigung steht nirgends „gemeistert“.
8. Eddie antwortet ohne Sprachmodell, verlinkt nur Freigegebenes, die Frage an den Coach erscheint im Check-in.
9. Die Kiosk-Web-App für LSA und Session läuft unverändert (Ansichtstests grün).
10. iOS- und Android-Build entstehen; Upload in die Testkanäle, sofern Konten vorhanden.
Schluss: docs/reihe1/D/live-checkliste.md (nach dem Merge mit Testkind und echtem Gerät durchspielen) und docs/reihe1/D/bericht.md mit PRs in Merge-Reihenfolge, Migrationen, Abnahme, Store-Status, offenen Punkten. Im Terminal höchstens 20 Zeilen. Dann STOPP.
```
