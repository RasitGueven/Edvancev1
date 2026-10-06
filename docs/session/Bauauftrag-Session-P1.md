# Bauauftrag Session-Rahmen P1 (Fassung 1)

**Stand:** 06.10.2026 · **Entscheider:** Rasit (Ashkan und Tolunay haben Vision und Bauplan zugestimmt) · **Grundlage:** Vision Session-Rahmen, Bauplan Session-Rahmen, Ist-Analysen P0 (`~/ist-analysen/*.md`, Stand Edvancev1 8e8fd5a, edvance-app 3a1d905), Coach-Live-Dummy (`docs/session/coach-live-dummy.html`)

P1 baut die Datenmodelle und Server-Funktionen für die Session. Oberflächen kommen in P2. Fünf Pakete laufen parallel, jedes in einem eigenen Worktree, jedes mit eigenem PR gegen `dev`.

**Rangfolge bei Widersprüchen:** Maßgebliche Entscheidungen in dieser Datei, dann der Coach-Live-Dummy, dann die Ist-Analysen.

---

## Maßgebliche Entscheidungen

### A. Rahmen

1. Eine Session dauert 60 Minuten, höchstens 5 Kinder pro Raum, ein Coach, jedes Kind am eigenen iPad (edvance-app im Kiosk-Modus). Kein Frontalunterricht.
2. Die Buchung (`session_students`) machen Admin bzw. Slots. Im Check-in weist der Coach jedem gebuchten Kind ein Tablet zu; das setzt die Anwesenheit auf „anwesend“. Das Kind meldet sich vor Ort nicht an. Einen Platz bekommt nur ein Kind mit laufendem Vertrag (bestehender Trigger ZG001).
3. Das System schlägt vor, der Coach entscheidet. Vorschlag und Entscheidung sind getrennte Datenzustände (eigene Spalten oder Zeilen), eine Entscheidung überschreibt nie den Vorschlag.
4. Der Lernpfad rückt nur in der Session vor Ort vor. Zuhause (Home Quests) wird nur „erledigt“ gespeichert: keine Antworten, kein richtig oder falsch, kein Einfluss auf Lernpfad, Mastery oder Report (FernUSG).
5. Kinder sehen nur freigegebene Inhalte: Aufgaben mit Status `ready`, Hinweise und Erklärschritte mit Status „geprüft“ bzw. „freigegeben“. Einzige Ausnahme ist der Testmodus (Entscheidung 27) mit Testkonten.
6. „Gemeistert“ gibt es nur nach Bestätigung durch den Coach am Platz. Das System spricht nie von Meisterschaft. Die Farbe für „gemeistert“ erscheint erst nach dieser Bestätigung.

### B. Ablauf

7. Phasen: Check-in, Warm-up, Kernarbeit, Check-out (Dauern siehe Stellschrauben). Es gibt keinen eigenen Wiederholungsblock: Ältere Aufgaben werden in die Kernarbeit gemischt, der Anteil ist einstellbar.
8. Check-in am Tablet: Stimmung (gut, geht so, angespannt), angekündigte Klassenarbeit (Datum, Thema), „Macht ihr noch dasselbe Thema?“ (noch dran / neues Thema mit Stichwort). Der Coach sieht das live und korrigiert.
9. Fall und Ziel der Stunde. Rangfolge: Klassenarbeit vor Schulthema vor Lernpfad.
   - Klassenarbeit zählt, wenn sie innerhalb der Stellschraube `ka_tage` liegt.
   - Schulthema ist das Thema mit Status „aktuell“ in `lead_themen`. Nennt das Kind ein neues Thema, wählt der Coach es mit derselben Suche wie im Erstgespräch (Name und Schlagworte, Stufe des Kindes zuerst, höchstens 6 Vorschläge, kein Freitext). Das alte Thema wird „behandelt“.
   - Lernpfad ist die nächste Lücke im Lernpfad, in der ersten Session nach der LSA aus dem Report („Wie es weitergeht“).
   - Keine Hausaufgaben in der Session.
   - Ziel heißt: Das Kind durchdringt dieses Thema. Die Auswahl arbeitet wie die LSA vom Einstieg des Themas (`thema_einstieg`) abwärts über `skill_kante` zu fehlenden Voraussetzungen. Das Ziel bleibt über Sessions bestehen, bis sich das Thema ändert.
   - Fall-Vorschlag des Systems und Wahl des Coaches werden getrennt gespeichert.
10. Warm-up: Abruf von Fertigkeiten, die schon sicher waren, bevorzugt Voraussetzungen des Ziels, eine Stufe leichter. Zeigt das Warm-up eine Lücke, schlägt das System „eine Stufe tiefer“ vor; der Coach entscheidet.
11. Kernarbeit: Ein neuer Skill beginnt mit der Erklärsequenz (Abschnitt D). Danach Lösungsbeispiel und Aufgabe im Wechsel, dann geführtes Üben mit Hinweisen (bis zu 3 Stufen, Prinzip der minimalen Hilfe), dann selbstständig. Gesteuert wird auf die Ziel-Erfolgsquote. Produktives Ringen (Stufe 0) gilt erst, wenn die Erklärung durch ist.
12. Check-out: Exit-Aufgaben zum Ziel. Der Coach sagt jedem Kind einen konkreten Satz (Vorschlag aus einem festen Bausteinkatalog, nie freier KI-Text ans Kind). Das Kind wählt den Termin für seine Home Quests. Coach-Notiz intern, Flags „Elternkontakt nötig“ und „Pfad passt nicht“.
13. Abschluss: schreibt Anwesenheit (verbraucht die Einheit), Eingriffe ab Stufe 3 mit Fehlbild, Mastery-Entscheidungen, Notizen und Flags in die Akte und speichert, mit welchen Stellschrauben die Session lief.

### C. Coach

14. Interventionsleiter: 0 nichts tun · 1 Nähe suchen · 2 Nachfragen („Zeig mir, was du bis hier gemacht hast.“) · 3 Mikro-Erklärung an einem anderen Beispiel, höchstens `mikro_erklaerung_min` · 4 Pfad eine Stufe tiefer. Stufe 1 und 2 werden nur gezählt, ab Stufe 3 geht der Eingriff mit Fehlbild in die Akte. Stufe 4 setzt den Pfad sofort tiefer.
15. Signale entstehen nach `signal_fehlversuche` Fehlversuchen in Folge, nach `signal_minuten_ohne_fortschritt` ohne Eingabe und nach `erklaerrunden_bis_signal` Erklärrunden ohne Erfolg. Warteschlange: Mastery-Prüfungen vor Entscheidungen vor Kindern, die hängen, vor Hinweisen; bei gleicher Art das älteste Signal zuerst. Höchstens `mastery_kandidaten_je_raum` Mastery-Prüfungen je Raum und Session.
16. Mastery-Kandidat wird ein Skill erst, wenn er in einer späteren Session (`mastery_abstand_sessions`) mindestens `mastery_richtig_ohne_hinweis` Mal ohne Hinweis gelöst wurde. Bestätigung in vier Schritten: Prüffrage mit anderem Kontext als die geübten Aufgaben (am Skill hinterlegt, mit Erwartung und Kriterium), das Kind erklärt seinen Weg, der Coach entscheidet, der Coach bucht. Vertagen braucht einen Grund.
17. Live-Sicht: Musterlösung und Fehlbild sieht nur der Coach. Live-Daten nur für die eigene Session. Aktualisierung über eine Lesefunktion für den ganzen Raum, alle paar Sekunden abgefragt (kein Realtime).

### D. Erklärsequenz

18. Ein neuer Skill hat 2 bis 3 Kernideen. Je Kernidee: Erklärschritt (ein Gedanke, ein Bildschirm, Text plus Bild), Lösungsbeispiel, Check mit 1 bis 2 Mini-Aufgaben. Richtig: weiter. Falsch: eine andere Variante, möglichst passend zum Fehlbild der falschen Antwort (`acceptance.known_errors` → Fehlbild → Variante), dann ein neuer Check. Nach `erklaerrunden_bis_signal` Runden geht ein Signal an den Coach. Ein bestandener Check ist kein Mastery-Signal. Die Verzweigung läuft auf dem Server. Alle Teile entstehen als KI-Entwurf; Lena prüft sie auf einer eigenen Prüfseite, ein Admin gibt frei. Zuhause ist die Sequenz nur zum Nachlesen abrufbar, ohne Checks.
19. Formeln werden beim Speichern als SVG erzeugt; die App zeigt nur SVG.
20. Hinweise bekommen den Status Entwurf oder geprüft. `lsa_hint` und jede Session-Funktion liefern nur geprüfte Hinweise (Entscheidung vom 17.09., bisher nicht gebaut).

### E. Home Quests

21. Zwei Quests pro Woche, je etwa 10 Minuten. Quest A 2 bis 3 Tage nach der Session (Abruf des Stundenziels, gemischt mit Älterem), Quest B kurz vor der nächsten Session. Steht eine Klassenarbeit vor der nächsten Session an, gibt es stattdessen ein Paket zum Thema der Klassenarbeit. Selbstkontrolle: lösen, Lösungsweg aufdecken, selbst vergleichen. Gespeichert wird nur „erledigt“. XP gibt es fürs Bearbeiten, nie fürs Richtig-Haben. Wochenserie, die beim Reißen nur pausiert. Den Termin wählt das Kind im Check-out; die Erinnerung kommt über die App; Eltern sehen einmal pro Woche „erledigt“ oder „offen“. In P1 nur Endpunkte im Backend, die Oberfläche kommt mit der Schüler-App. Vor dem Livegang prüft die Clinic die Mechanik (FernUSG).

### F. Stellschrauben

22. Alle pädagogischen Werte sind Einstellungen mit Startwert und Spanne. Admins ändern sie ohne Deployment; jede Änderung landet in einem Protokoll (Muster `task_admin_protokoll`); jede Session speichert beim Start einen Snapshot der Werte.

| Schlüssel | Bedeutung | Startwert | Spanne |
|---|---|---|---|
| `phase_checkin_min` | Dauer Check-in | 5 | 3–8 |
| `phase_warmup_min` | Dauer Warm-up | 10 | 5–15 |
| `phase_checkout_min` | Dauer Check-out | 5 | 3–10 |
| `warmup_aufgaben` | Aufgaben im Warm-up | 3 | 1–5 |
| `warmup_leichter_stufen` | Warm-up leichter als Kernarbeit um | 1 | 0–2 |
| `ziel_erfolgsquote` | Ziel-Erfolgsquote | 0,80 | 0,60–0,90 |
| `mischanteil` | Anteil älterer Aufgaben in der Kernarbeit | 0,30 | 0–0,50 |
| `ka_tage` | Klassenarbeit zählt und Mischen pausiert, wenn sie höchstens so viele Tage entfernt ist (einschließlich) | 7 | 0–14 |
| `hinweisstufen` | Hinweisstufen je Aufgabe | 3 | 0–3 |
| `signal_fehlversuche` | Signal nach Fehlversuchen in Folge | 2 | 1–4 |
| `signal_minuten_ohne_fortschritt` | Signal nach Minuten ohne Eingabe | 3 | 1–10 |
| `mikro_erklaerung_min` | Mikro-Erklärung höchstens (Minuten) | 2 | 1–5 |
| `kernideen_max` | Kernideen pro Skill höchstens | 3 | 1–5 |
| `check_aufgaben_je_kernidee` | Check-Aufgaben je Kernidee | 1 | 1–3 |
| `erklaerrunden_bis_signal` | Erklärrunden bis Coach-Signal | 2 | 1–3 |
| `erklaerung_bei_neuem_skill` | Erklärung bei neuem Skill | vorgeschaltet | vorgeschaltet / angeboten |
| `loesungsbeispiele_vor_aufgabe` | Lösungsbeispiele vor der ersten eigenen Aufgabe | 1 | 0–3 |
| `erklaerung_anbieten_nach_fehlversuchen` | „Nochmal erklären“ anbieten nach Fehlversuchen | 2 | 1–4 |
| `mastery_abstand_sessions` | Mastery-Kandidat frühestens nach Sessions | 1 | 1–3 |
| `mastery_richtig_ohne_hinweis` | dafür richtig ohne Hinweis | 2 | 2–6 |
| `mastery_kandidaten_je_raum` | Mastery-Prüfungen je Raum und Session | 3 | 1–5 |
| `exit_aufgaben` | Exit-Aufgaben | 2 | 1–3 |
| `thema_alt_tage` | Schulthema im Briefing zum Nachfragen markieren nach (Tage) | 21 | 7–42 |
| `quests_pro_woche` | Home Quests pro Woche | 2 | 0–3 |
| `quest_minuten` | Dauer einer Quest (Minuten) | 10 | 5–20 |
| `quest_a_abstand_tage` | Quest A nach der Session (Tage) | 2 | 1–3 |
| `quest_xp` | XP je erledigter Quest | 50 | 10–100 |
| `home_quests_aktiv` | Home Quests eingeschaltet | aus | an / aus |

### G. Lernpfad und Mastery

23. Lernpfad und Mastery hängen an `skill_key`. Die bisherige Microskill-Mastery (`student_competency_mastery` u. a.) wird Altlast und nicht weiter beschrieben. Der Lernpfad führt je Kind und Skill einen Systemzustand und getrennt davon die Entscheidung des Coaches. Ausgangspunkt ist die Übernahme aus der LSA (`student_focus_areas`, Skill-Urteile).

### H. Sicherheit und Testmodus

24. Altlasten aus der Anfangszeit werden stillgelegt: der Web-TaskPlayer in Edvancev1 (schreibt `behavior_snapshots`, `student_task_progress` und XP ohne Coach); eine LSA startet nie ein Schülerkonto, nur Admin oder Coach über einen Platz; XP bucht nie ein Client direkt, nur eine Funktion.
25. Zugangscode: nur für Admins lesbar, in der Oberfläche maskiert wie die IBAN.
26. Coach-Rechte: Ein Coach liest Akten-Daten (LSA-Antworten, Urteile, Reports, Lernpfad, XP, Badges) nur von Kindern mit laufendem Vertrag, wie bei der Akte entschieden (25.09.), nie von Leads ohne Vertrag oder ruhenden Akten. Live-Daten nur für die eigene Session. Das schließt S1b.
27. Testmodus statt Sammelfreigabe: Ein Admin startet eine LSA oder Session als Testlauf, nur mit Testkonten. Im Testlauf kommen zusätzlich nicht freigegebene Aufgaben dran, wenn sie dieselbe Prüfung bestehen wie im Lena-Board (`pruef_ausschluss` ist leer). Testläufe tauchen nie in Akte, Report, Kennzahlen oder im Lernpfad echter Kinder auf und sind sichtbar als „Testlauf“ markiert. Die bestehenden Schüler in Prod sind Testdaten.
28. Aufgaben bekommen einen Einsatz (`lsa`, `session`, `check`, `quest`). Bestehende Aufgaben: `lsa` und `session`. Check-Aufgaben der Erklärsequenz nur `check`. Die LSA-Auswahl filtert zusätzlich auf aktiv, kein Tutorial, Inhaltstyp Übung, vorhandene Lösung und Einsatz `lsa`.

---

## Pakete und Reihenfolge

| Paket | Inhalt | Worktree · Branch | Migrations-Zeitstempel |
|---|---|---|---|
| 0 | Grundlagen ins Repo (diese Datei, Coach-Live-Dummy) | `../Edvancev1-session-docs` · `docs/rasit-session-grundlagen` | – |
| X0 | Altlasten stilllegen, Rechte, Zugangscode, Einsatz, LSA-Pool, Testmodus | `../Edvancev1-x0` · `feat/rasit-session-x0-sicherheit` | `20261007100000` bis `…105959` |
| R1 | Session-Datenmodell: Stellschrauben, Ablauf, Tablets, Check-in, Antworten, Signale, Live-Lesefunktion, Check-out, Abschluss | `../Edvancev1-r1` · `feat/rasit-session-r1-datenmodell` | `20261007110000` bis `…115959` |
| A1 | Lernpfad und Mastery auf `skill_key`, Ziel-Fertigkeiten, Prüffragen | `../Edvancev1-a1` · `feat/rasit-session-a1-lernpfad` | `20261007120000` bis `…125959` |
| E1 | Erklärsequenz: Datenmodell, Ablauf auf dem Server, Hinweis-Status, Formeln als SVG | `../Edvancev1-e1` · `feat/rasit-session-e1-erklaersequenz` | `20261007130000` bis `…135959` |
| Q1 | Home-Quest-Endpunkte | `../Edvancev1-q1` · `feat/rasit-session-q1-quests` | `20261007140000` bis `…145959` |

Paket 0 zuerst und mergen. Danach laufen X0, R1, A1, E1 und Q1 parallel. Die Zeitstempel-Bereiche halten die Migrationen auseinander und ergeben die Einspielreihenfolge X0 → R1 → A1 → E1 → Q1. Querverbindungen zwischen den Paketen (zum Beispiel ruft R1 später den Lernpfad aus A1) werden in P2 verdrahtet; in P1 schreibt jedes Paket sie als offenen Punkt auf.

**Einspielen:** Jedes Paket hält nach dem PR an. Erst wenn Rasit im jeweiligen Chat „<Paket> einspielen“ schreibt, spielt der Agent seine Migrationen nach CLAUDE.md §10 ein.

---

## Prompt 0 — Grundlagen ins Repo

```text
Du arbeitest im Repo Edvancev1 (WSL). Schritt 0 des Bauauftrags Session-Rahmen P1: Grundlagen ins Repo.

LEITPLANKEN
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-session-docs -b docs/rasit-session-grundlagen origin/dev
  Nur dort arbeiten. In ~/Edvancev1 laufen parallel andere Agenten.
- Nur Dateien unter docs/session/. Kein Code, keine Migration, kein Datenbankzugriff. PR gegen dev, niemals main.

SCHRITTE
1. Prüfe, dass in den Windows-Downloads genau je eine dieser Dateien liegt:
   /mnt/c/Users/*/Downloads/Bauauftrag-Session-P1.md (erste Zeile enthält "Fassung 1")
   /mnt/c/Users/*/Downloads/coach-live-dummy.html
   Fehlt eine oder gibt es mehrere: abbrechen und melden.
2. Kopiere beide nach docs/session/.
3. Die Ist-Analysen in ~/ist-analysen/ kommen NICHT ins Repo (das Repo ist öffentlich, sie enthalten Auszüge aus
   Produktionsdaten). Die Pakete lesen sie lokal.
4. Commit "docs: Grundlagen Session-Rahmen P1", Push, PR gegen dev mit Titel "docs: Grundlagen Session-Rahmen P1".
   Im PR-Text nur die Dateiliste.
5. git worktree remove ../Edvancev1-session-docs
Melde den PR-Link und halte an.
```

---

## Gemeinsame Leitplanken für X0, R1, A1, E1, Q1

Stehen wörtlich in jedem Prompt, damit jeder Prompt für sich allein läuft.

---

## Prompt X0 — Sicherheit, Einsatz, LSA-Pool, Testmodus

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket X0 des Bauauftrags Session-Rahmen P1.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-x0 -b feat/rasit-session-x0-sicherheit origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel laufen andere Agenten in ~/Edvancev1 und in
  ../Edvancev1-r1, -a1, -e1, -q1.
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Kein DDL und keine schreibende Abfrage gegen Produktion. Lesen nur über dbread.
- Migrationen nur als Datei unter supabase/migrations/, Zeitstempel nur im Bereich 20261007100000 bis 20261007105959.
- Tests nur in einer Wegwerf-DB: pgTAP lokal ohne Root wie in docs/retros/2026-10-04-report-themenraum.md („Gelernt“),
  mit PGOPTIONS='-c search_path=public,extensions'. Nie edvance_shadow, nie Produktion.
- supabase/schema-erwartet.sql, schema.sql und schema_content.sql nicht anfassen.
- Vor jeder Änderung an Spalten, Policies oder Funktionen: pg_proc-Scan über dbread und Repo-Suche nach allen
  Aufrufern (beide Repos, edvance-app nur lesen). Liste ins PR.
- Dieser Auftrag ist Rasits Bestätigung für genau die hier beschriebenen Auth- und RLS-Änderungen (CLAUDE.md §4).
  Consensus-Check nach CLAUDE.md §8 für alle Rechte-Änderungen, Ergebnis ins PR.
- Schreiben nur über SECURITY DEFINER-Funktionen nach Muster 20261004001333_lead_thema_setzen.sql
  (set search_path = public, pg_temp; revoke all … from public, anon, authenticated; grant execute … to authenticated).
- Höchstens 400 Zeilen je Datei; Frontend nach CLAUDE.md §11/§12 (Tokens, i18n, Supabase nur in src/lib/).
- Nach jeder Phase npm run typecheck, npm run lint, npm run test grün, dann Commit. Melde nie „fertig“ ohne die
  Ausgabe von npm run typecheck.
- Geht etwas nicht oder widerspricht der Code einer Entscheidung: nicht still umgehen, in
  docs/session/offene-punkte-x0.md eintragen, im PR nennen, weiterarbeiten.
- Jede Aussage im PR mit Beleg (Datei:Zeile oder dbread-Ausgabe).
- STOPP nach dem PR. Einspielen erst, wenn Rasit in diesem Chat „X0 einspielen“ schreibt. Dann je Migration nach
  CLAUDE.md §10 (dbcheck && psql … -v ON_ERROR_STOP=1 -1 -f … && insert schema_migrations && tools/schema-snapshot.sh),
  bei Fehler sofort anhalten und melden.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/session/Bauauftrag-Session-P1.md, Entscheidungen 2, 4, 5 und 24 bis 28. Sie sind maßgeblich.
2. ~/ist-analysen/R0-session.md (Altlasten, Kiosk), Q0-home.md (Zugangscode, XP, LSA-Start), C0-coach.md (Rechte),
   A0-auswahl.md und E0-erklaerung.md (LSA-Pool, Tutorial-Inhalte). Lokal, nicht im Repo.
3. docs/lena-board/ (pruef_ausschluss) und docs/schuelerakte/ (hat_zugang, vertraege_aktuell, Akte-Rechte).

UMFANG
Phase X0.1 Altlasten
1. Web-TaskPlayer in Edvancev1 stilllegen: Route aus App.tsx nehmen bzw. auf einen Hinweis „nicht mehr verfügbar“
   umleiten. Schreibrechte von authenticated auf behavior_snapshots und student_task_progress entziehen. Tabellen und
   Code nicht löschen; was weiter darauf zeigt, kommt ins PR.
2. LSA-Start: Jeder Weg, der eine lsa_session anlegt oder startet, lehnt ein Schülerkonto mit 42501 ab. Erlaubt sind
   Admin und Coach (Coach nur über einen Platz).
3. XP: direkte INSERT/UPDATE-Rechte von authenticated auf alle XP-Tabellen entziehen. Buchen nur über eine
   SECURITY DEFINER-Funktion (xp_buchen o. ä.), die bestehenden Aufrufer darauf umstellen.

Phase X0.2 Rechte und Zugangscode
4. Zugangscode nur für Admins lesbar. Entscheide nach pg_proc-Scan zwischen Spalten-Rechten und einer eigenen
   Tabelle mit Admin-RLS; Begründung ins PR. Versand per Mail unverändert. In der Verträge-Oberfläche maskiert wie die
   IBAN (dieselbe Maskierungsfunktion wiederverwenden, nicht neu bauen).
5. Coach-Rechte nach Entscheidung 26: LSA-Antworten, Urteile, Reports, Fortschritt, XP und Badges liest ein Coach nur
   für Kinder mit laufendem Vertrag (Muster der Akte), nie für Leads ohne Vertrag oder ruhende Akten. Coaches schreiben
   davon nichts direkt.

Phase X0.3 Einsatz, LSA-Pool, Testmodus
6. tasks.einsatz text[] not null default '{lsa,session}', CHECK nur Werte aus lsa, session, check, quest.
7. LSA-Auswahl (lsa_select_next_core und alle adaptiven Wege) filtert zusätzlich: is_active, nicht is_tutorial,
   content_type = 'exercise', vorhandene Lösung (lsa_has_answers), 'lsa' = any(einsatz).
8. Testkonten: students.ist_test und leads.ist_test boolean not null default false. Datenmigration: alle bestehenden
   students auf ist_test = true (Entscheidung 27); Leads bleiben false. Admin kann den Haken in Akte und Lead setzen.
9. Testlauf: lsa_sessions.testlauf und coaching_sessions.testlauf boolean not null default false. Nur ein Admin setzt
   ihn, und nur, wenn das Kind ein Testkonto ist. Im Testlauf nimmt die Auswahl zusätzlich Aufgaben mit Status draft,
   review oder rueckfrage, wenn pruef_ausschluss(task_id) leer ist.
10. Testläufe ausschließen aus: Akte, Reports und Report-Versand, Kennzahlen und Zählern der Admin-Startseite,
    Lead-Board-Zählern, Lernpfad-Übernahme. Liste aller Stellen ins PR.
11. Oberfläche (Edvancev1): beim Start einer LSA ein Schalter „Testlauf“, sichtbar nur für Admins bei Testkonten; in
    LSA-Ansichten und Report ein Banner „Testlauf“. Die App (edvance-app) bekommt das Feld testlauf ausgeliefert; den
    Banner dort baut P2 (offener Punkt).

TESTS (supabase/tests/session_x0.test.sql, eigene Fixtures, grün in der Wegwerf-DB, Ausgabe ins PR)
1  Schülerkonto: lsa_start und jeder andere Startweg → 42501.
2  Schülerkonto: INSERT in eine XP-Tabelle, in behavior_snapshots, in student_task_progress → abgelehnt.
3  xp_buchen als Systemaufruf bucht genau einmal.
4  Coach liest LSA-Daten eines Kindes mit laufendem Vertrag, aber keine eines Leads ohne Vertrag und keine einer
   ruhenden Akte.
5  Coach und Kind lesen den Zugangscode nicht, Admin schon.
6  LSA-Auswahl liefert keine Aufgabe mit is_tutorial, ohne Lösung oder ohne 'lsa' im Einsatz.
7  Testlauf mit Nicht-Testkonto → abgelehnt; Testlauf mit Testkonto liefert eine draft-Aufgabe, die pruef_ausschluss
   besteht, aber keine, die ihn nicht besteht.
8  Ein Testlauf erscheint in keiner Kennzahl, keinem Report und keiner Akte.
Dazu Vitest für die Maskierung und den Schalter.

ABNAHME
Alle Tests grün; Web-TaskPlayer nicht mehr erreichbar; Zugangscode in der Verträge-Ansicht maskiert; ein Admin kann
mit einem Testkonto eine LSA als Testlauf mit ungeprüften Aufgaben starten, und sie taucht nirgends in Kennzahlen auf.

PR (gegen dev)
Titel: feat(session-x0): Sicherheit, Einsatz, LSA-Pool und Testmodus
Inhalt: Kurzfassung, Objektliste (Tabellen, Spalten, Funktionen, Policies), Aufruferliste und pg_proc-Scan,
Consensus-Check, Einspielreihenfolge mit Befehlen nach CLAUDE.md §10, pgTAP-Ausgabe, Testanleitung für Rasit (als
Admin, als Coach, als Testkind), offene Punkte. Hinweis: Gemergt wird erst nach grünem CI mit neuem Schema-Abzug.
Dann STOPP.
```

---

## Prompt R1 — Session-Datenmodell

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket R1 des Bauauftrags Session-Rahmen P1: Datenmodell und Server-Funktionen
der Session. Keine Oberfläche.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-r1 -b feat/rasit-session-r1-datenmodell origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel laufen andere Agenten in ~/Edvancev1 und in
  ../Edvancev1-x0, -a1, -e1, -q1.
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Kein DDL und keine schreibende Abfrage gegen Produktion. Lesen nur über dbread.
- Migrationen nur als Datei unter supabase/migrations/, Zeitstempel nur im Bereich 20261007110000 bis 20261007115959.
- Tests nur in einer Wegwerf-DB: pgTAP lokal ohne Root wie in docs/retros/2026-10-04-report-themenraum.md („Gelernt“),
  mit PGOPTIONS='-c search_path=public,extensions'. Nie edvance_shadow, nie Produktion.
- supabase/schema-erwartet.sql, schema.sql und schema_content.sql nicht anfassen.
- Vor jeder Änderung an bestehenden Spalten, Policies oder Funktionen: pg_proc-Scan über dbread und Repo-Suche nach
  allen Aufrufern (beide Repos, edvance-app nur lesen). Liste ins PR.
- Dieser Auftrag ist Rasits Bestätigung für genau die hier beschriebenen Auth- und RLS-Regeln (CLAUDE.md §4).
  Consensus-Check nach CLAUDE.md §8, Ergebnis ins PR.
- Schreiben nur über SECURITY DEFINER-Funktionen nach Muster 20261004001333_lead_thema_setzen.sql.
- Typen und Aufrufe für das spätere Frontend nur unter src/lib/ und src/types/, höchstens 400 Zeilen je Datei.
- Nach jeder Phase npm run typecheck, npm run lint, npm run test grün, dann Commit.
- Geht etwas nicht oder widerspricht der Code einer Entscheidung: in docs/session/offene-punkte-r1.md eintragen, im
  PR nennen, weiterarbeiten.
- Jede Aussage im PR mit Beleg (Datei:Zeile oder dbread-Ausgabe).
- STOPP nach dem PR. Einspielen erst, wenn Rasit in diesem Chat „R1 einspielen“ schreibt; dann je Migration nach
  CLAUDE.md §10, bei Fehler sofort anhalten und melden.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/session/Bauauftrag-Session-P1.md, Entscheidungen 1 bis 17 und 22 mit der Stellschrauben-Tabelle. Maßgeblich.
2. docs/session/coach-live-dummy.html vollständig, mit den Schaltern „Hinweise“ und „Stellschrauben“, in allen
   Zeitpunkten (Vorher, Check-in, Warm-up, Kernarbeit, Check-out, Danach) und mit geöffneter Schublade je Kind.
   Der Dummy zeigt, welche Daten der Coach wann braucht.
3. ~/ist-analysen/R0-session.md vollständig, dazu C0-coach.md (Rechte, Live) und A0-auswahl.md (Verlauf, Engine).
4. docs/schuelerakte/ (Anwesenheit, einheit_verbraucht, Notizen) und die LSA-Engine (lsa_is_correct, lsa_grade,
   lsa_fehlbild_match).

UMFANG
Phase R1.1 Stellschrauben und Ablauf
1. session_einstellungen: je Schlüssel aus der Tabelle des Bauauftrags Wert, Startwert, erlaubte Spanne oder Werte,
   Einheit, Beschreibung. Mit allen Startwerten befüllen. Lesen: authenticated. Ändern nur Admin über
   einstellung_setzen(schluessel, wert, grund), Spanne geprüft.
2. session_einstellungen_protokoll nach Muster task_admin_protokoll (wer, wann, alt, neu, grund).
3. coaching_sessions: Status geplant, laeuft, abgeschlossen (bestehende Werte vorher per dbread prüfen und erhalten),
   gestartet_am, beendet_am, einstellungen jsonb (Snapshot). session_starten(session) durch den Coach der Session oder
   einen Admin setzt Status und Snapshot.

Phase R1.2 Tablets und Check-in
4. Tablet-Zuweisung für coaching_sessions: tablet_zuweisen(session, student, tablet_nr) und tablet_loesen. Nur Coach der
   Session oder Admin, nur Kinder aus session_students dieser Session, höchstens 5. Setzt die Anwesenheit auf anwesend.
   Entscheide nach R0, ob platz_assignments erweitert wird oder eine eigene Tabelle entsteht; Begründung ins PR. Die
   LSA-Wege bleiben unverändert. Antworten werden über das Tablet dem Kind zugeordnet; das angemeldete Konto steht
   getrennt daneben (R0: Identitätstausch am Kiosk).
5. session_checkin je Kind: stimmung (gut, geht_so, angespannt), klassenarbeit_datum, klassenarbeit_thema_key,
   thema_antwort (noch_dran, neu), thema_stichwort, fall_vorschlag, fall_coach, ziel_thema_key.
   - checkin_kind_speichern (vom Tablet), checkin_coach_setzen (Fall, Thema).
   - fall_vorschlag(session, student) nach Entscheidung 9 mit ka_tage.
   - Wählt der Coach ein neues Schulthema, schreibt das lead_themen (aktuell, das alte behandelt) über denselben Weg wie
     das Erstgespräch. Für Kinder mit Vertrag den Weg Kind → Lead über die bestehende Verknüpfung prüfen (S0-Befund
     leads.converted_student_id).

Phase R1.3 Antworten, Ereignisse, Signale
6. session_antworten: session, student, task_id, teil, versuch_nr, eingabe, ergebnis (richtig, teilweise, falsch),
   fehlbild_slug, hinweisstufe_max, dauer_ms, phase, eingemischt boolean, zeit. Bewertung auf dem Server mit derselben
   Engine wie die LSA. antwort_abgeben(session, task_id, teil, eingabe) gibt nur Ergebnis und Fehlbild-Klartext zurück,
   nie die Lösung. hinweis_abrufen(session, task_id, stufe) liefert nur geprüfte Hinweise (Entscheidung 20; bis E1
   gelten Hinweise ohne Status als nicht geprüft) und protokolliert die Stufe.
7. session_ereignisse, nur anhängen: typ (phase_wechsel, hinweis, erklaerschritt, check, signal, signal_erledigt,
   eingriff, entscheidung_pfad), session, student, payload jsonb, zeit.
8. raum_signale(session): offene Signale aus Antworten, Ereignissen und Stellschrauben (Entscheidung 15), sortiert wie
   die Warteschlange im Dummy. signal_erledigen(session, student, art). eingriff_notieren(session, student, stufe,
   fehlbild_slug): ab Stufe 3 Fehlbild Pflicht; Stufe 4 schreibt das Ereignis entscheidung_pfad (das Umsetzen im
   Lernpfad verdrahtet P2 mit A1).

Phase R1.4 Live-Lesefunktion, Check-out, Abschluss
9. coach_raum_live(session) für den Coach der Session oder Admin, eine Abfrage für den ganzen Raum: je Kind Tablet, Name,
   Klasse, Phase, Fall und Ziel, aktuelle Aufgabe (ohne Lösung), Ergebnisfolge heute, genutzte Hinweise, Status
   (läuft, hängt, Entscheidung, Kandidat, Hinweis), Signale. Felder für Mastery-Kandidat und Erklärsequenz als
   Platzhalter, gefüllt in P2 aus A1 und E1.
10. coach_kind_detail(session, student): aktuelle Aufgabe mit Musterlösung, Versuche mit Fehlbild, genutzte Hinweise,
    Eingriffe. Nur für den Coach der Session oder Admin; Schülerkonten bekommen 42501.
11. session_kind_abschluss: satz_text, satz_gesagt, notiz, flag_eltern, flag_pfad, quest_termin, exit_ergebnis.
    Funktionen zum Setzen durch den Coach; quest_termin auch vom Tablet des Kindes.
12. session_abschliessen(session): Anwesenheit final (verbraucht die Einheit nach einheit_verbraucht), Notizen und
    Flags in die Akte (bestehende Notizen der Schülerakte nutzen), Status abgeschlossen. Lesefunktion für offene Flags,
    damit die Admin-Startseite sie später zeigen kann.
13. RLS: alles nur über Funktionen. Coach nur eigene Session, Tablet bzw. Kind nur eigener Platz. Testläufe (X0) später
    ausschließen: offener Punkt, bis X0 eingespielt ist.

DUMMY-ABGLEICH (Pflicht im PR)
Tabelle: je Ansicht des Coach-Live-Dummys jedes angezeigte Datum → Quelle (Tabelle oder Funktion aus R1) oder
„kommt mit A1/E1/Q1/C2“. Kein Datum ohne Eintrag.

TESTS (supabase/tests/session_r1.test.sql, eigene Fixtures, grün in der Wegwerf-DB, Ausgabe ins PR)
1  einstellung_setzen außerhalb der Spanne → abgelehnt; innerhalb → Protokollzeile.
2  session_starten speichert den Snapshot; spätere Änderungen an den Einstellungen ändern ihn nicht.
3  tablet_zuweisen: Kind ohne Buchung, sechstes Kind, fremder Coach → abgelehnt; gültig → anwesend.
4  fall_vorschlag: Klassenarbeit in 2 Tagen → klassenarbeit; in 21 Tagen mit aktuellem Thema → schulthema;
   ohne Thema → lernpfad.
5  Neues Schulthema über den Coach → altes Thema behandelt, neues aktuell.
6  antwort_abgeben wertet wie die LSA-Engine und liefert ein Fehlbild aus known_errors; die Lösung ist nicht enthalten.
7  hinweis_abrufen liefert keinen Hinweis ohne Prüfstatus.
8  Zwei Fehlversuche in Folge → Signal; nach signal_erledigen weg; Reihenfolge Kandidat vor Entscheidung vor hängt.
9  eingriff_notieren Stufe 3 ohne Fehlbild → abgelehnt.
10 coach_raum_live und coach_kind_detail: Coach einer anderen Session und Schülerkonto → 42501.
11 session_abschliessen setzt Anwesenheit und schreibt Notiz und Flags in die Akte.

ABNAHME
Alle Tests grün; Dummy-Abgleich vollständig; mit den Funktionen lässt sich eine Session in der Wegwerf-DB von
session_starten bis session_abschliessen durchspielen (Skript docs/session/r1-durchlauf.sql, Ausgabe ins PR).

PR (gegen dev)
Titel: feat(session-r1): Datenmodell und Server-Funktionen der Session
Inhalt: Kurzfassung, Objektliste, Aufruferliste und pg_proc-Scan, Consensus-Check, Dummy-Abgleich,
Einspielreihenfolge mit Befehlen nach CLAUDE.md §10, pgTAP-Ausgabe, Durchlauf-Skript, offene Punkte (insbesondere die
Verdrahtung mit A1, E1, Q1 und X0). Hinweis: Gemergt wird erst nach grünem CI mit neuem Schema-Abzug. Dann STOPP.
```

---

## Prompt A1 — Lernpfad und Mastery

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket A1 des Bauauftrags Session-Rahmen P1: Lernpfad und Mastery auf skill_key.
Keine Oberfläche.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-a1 -b feat/rasit-session-a1-lernpfad origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel laufen andere Agenten in ~/Edvancev1 und in
  ../Edvancev1-x0, -r1, -e1, -q1.
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Kein DDL und keine schreibende Abfrage gegen Produktion. Lesen nur über dbread.
- Migrationen nur als Datei unter supabase/migrations/, Zeitstempel nur im Bereich 20261007120000 bis 20261007125959.
- Tests nur in einer Wegwerf-DB: pgTAP lokal ohne Root wie in docs/retros/2026-10-04-report-themenraum.md („Gelernt“),
  mit PGOPTIONS='-c search_path=public,extensions'. Nie edvance_shadow, nie Produktion.
- supabase/schema-erwartet.sql, schema.sql und schema_content.sql nicht anfassen.
- Vor jeder Änderung an bestehenden Spalten, Policies oder Funktionen: pg_proc-Scan über dbread und Repo-Suche nach
  allen Aufrufern (beide Repos, edvance-app nur lesen). Liste ins PR.
- Dieser Auftrag ist Rasits Bestätigung für genau die hier beschriebenen Auth- und RLS-Regeln (CLAUDE.md §4).
  Consensus-Check nach CLAUDE.md §8, Ergebnis ins PR.
- Schreiben nur über SECURITY DEFINER-Funktionen nach Muster 20261004001333_lead_thema_setzen.sql.
- Typen und Aufrufe für das spätere Frontend nur unter src/lib/ und src/types/, höchstens 400 Zeilen je Datei.
- Nach jeder Phase npm run typecheck, npm run lint, npm run test grün, dann Commit.
- Geht etwas nicht oder widerspricht der Code einer Entscheidung: in docs/session/offene-punkte-a1.md eintragen, im
  PR nennen, weiterarbeiten.
- Jede Aussage im PR mit Beleg (Datei:Zeile oder dbread-Ausgabe).
- STOPP nach dem PR. Einspielen erst, wenn Rasit in diesem Chat „A1 einspielen“ schreibt; dann je Migration nach
  CLAUDE.md §10, bei Fehler sofort anhalten und melden.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/session/Bauauftrag-Session-P1.md, Entscheidungen 3, 4, 6, 9, 10, 11, 16 und 23. Maßgeblich.
2. docs/session/coach-live-dummy.html: Schublade je Kind (Block „Ziel der Stunde“, Mastery-Prüfung bei Mila,
   Pfad-Entscheidung bei Emir im Warm-up), Schalter „Hinweise“.
3. ~/ist-analysen/A0-auswahl.md vollständig, dazu R0-session.md und E0-erklaerung.md (Fehlbilder). Lokal.
4. LSA-Report und Übernahme: lsa_skill_urteil, student_focus_areas, Report-Bausteine („Wie es weitergeht“).

UMFANG
1. lernpfad je Kind und skill_key: stand_system (offen, aktiv, sicher, noch_nicht_sicher, kandidat), stand_coach (null,
   gemeistert, vertagt) mit grund, von, am, quelle (lsa, session, coach), belege (letzte Übung, Session, richtig ohne
   Hinweis je Session). Systemzustand und Coach-Entscheidung strikt getrennt. Unique (student, skill_key).
2. lernpfad_aus_lsa(student): Übernahme aus Skill-Urteilen und student_focus_areas. Die bestehende Microskill-Mastery
   bleibt unangetastet und wird als Altlast dokumentiert (keine Löschung, Liste ins PR).
3. lernpfad_beleg(student, skill_key, session, ergebnis, hinweis_genutzt): bucht einen Beleg aus einer Session und
   setzt stand_system. Kandidat nach Entscheidung 16 mit mastery_abstand_sessions und mastery_richtig_ohne_hinweis.
   Liest Stellschrauben aus session_einstellungen, solange die Tabelle fehlt (R1), mit den Startwerten als Rückfall
   (offener Punkt). Diese Funktion ruft P2 aus der Session auf.
4. ziel_fertigkeiten(student, thema_key): Fertigkeiten des Themas (skill_thema, thema_einstieg) und ihre fehlenden
   Voraussetzungen über skill_kante, mit Stand aus dem Lernpfad. Liefert genau die Liste „Ziel der Stunde“ im Dummy.
5. naechste_luecke(student): Ziel für den Fall Lernpfad; in der ersten Session aus dem LSA-Report.
6. pfad_tiefer(student, skill_key): setzt die passende Voraussetzung auf aktiv (Warm-up-Entscheidung, Stufe 4).
7. skill_pruefung je skill_key: frage, erwartung, kriterium, status (entwurf, geprueft, freigegeben), quelle (ki,
   mensch). Inhalte kommen in P2; liefern nur freigegebene.
8. mastery_entscheiden(student, skill_key, entscheidung, grund, session): nur der Coach einer Session, in der das Kind
   gebucht ist, oder Admin; nur bei stand_system = kandidat; vertagt braucht einen Grund. Protokoll in
   lernpfad_protokoll. Badges koppelt P2 an (offener Punkt).
9. RLS: Coach liest den Lernpfad von Kindern mit laufendem Vertrag (wie die Akte), schreibt nur über Funktionen. Kind
   liest den eigenen Stand über eine Funktion, „gemeistert“ nur mit stand_coach.

TESTS (supabase/tests/session_a1.test.sql, eigene Fixtures, grün in der Wegwerf-DB, Ausgabe ins PR)
1  lernpfad_aus_lsa legt Zeilen aus den Urteilen an, ohne Microskill-Tabellen zu ändern.
2  Zwei Belege ohne Hinweis in derselben Session → kein Kandidat; in einer späteren Session → kandidat.
3  Belege mit Hinweis zählen nicht.
4  mastery_entscheiden durch fremden Coach oder Schülerkonto → 42501; ohne kandidat → abgelehnt; vertagt ohne Grund →
   abgelehnt; gemeistert → stand_coach gesetzt, stand_system unverändert.
5  ziel_fertigkeiten liefert für ein Thema Einstieg plus fehlende Voraussetzungen in Graph-Reihenfolge.
6  pfad_tiefer aktiviert eine Voraussetzung.
7  skill_pruefung liefert keine Entwürfe.

ABNAHME
Alle Tests grün; für ein Testkind mit LSA lässt sich in der Wegwerf-DB der Weg LSA → Lernpfad → Belege aus zwei
Sessions → Kandidat → gemeistert durchspielen (Skript docs/session/a1-durchlauf.sql, Ausgabe ins PR).

PR (gegen dev)
Titel: feat(session-a1): Lernpfad und Mastery auf skill_key
Inhalt: Kurzfassung, Objektliste, Altlasten-Liste, Aufruferliste und pg_proc-Scan, Consensus-Check,
Einspielreihenfolge mit Befehlen nach CLAUDE.md §10, pgTAP-Ausgabe, Durchlauf-Skript, offene Punkte. Hinweis: Gemergt
wird erst nach grünem CI mit neuem Schema-Abzug. Dann STOPP.
```

---

## Prompt E1 — Erklärsequenz

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket E1 des Bauauftrags Session-Rahmen P1: Erklärsequenz (Datenmodell, Ablauf
auf dem Server, Hinweis-Status, Formeln als SVG). Keine Oberfläche.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-e1 -b feat/rasit-session-e1-erklaersequenz origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel laufen andere Agenten in ~/Edvancev1 und in
  ../Edvancev1-x0, -r1, -a1, -q1.
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Kein DDL und keine schreibende Abfrage gegen Produktion. Lesen nur über dbread.
- Migrationen nur als Datei unter supabase/migrations/, Zeitstempel nur im Bereich 20261007130000 bis 20261007135959.
- Tests nur in einer Wegwerf-DB: pgTAP lokal ohne Root wie in docs/retros/2026-10-04-report-themenraum.md („Gelernt“),
  mit PGOPTIONS='-c search_path=public,extensions'. Nie edvance_shadow, nie Produktion.
- supabase/schema-erwartet.sql, schema.sql und schema_content.sql nicht anfassen.
- Vor jeder Änderung an bestehenden Spalten, Policies oder Funktionen (insbesondere task_solutions.hints und lsa_hint):
  pg_proc-Scan über dbread und Repo-Suche nach allen Aufrufern (beide Repos, edvance-app nur lesen). Liste ins PR.
- Dieser Auftrag ist Rasits Bestätigung für genau die hier beschriebenen Auth- und RLS-Regeln (CLAUDE.md §4).
  Consensus-Check nach CLAUDE.md §8, Ergebnis ins PR.
- Schreiben nur über SECURITY DEFINER-Funktionen nach Muster 20261004001333_lead_thema_setzen.sql.
- Eine neue Abhängigkeit ist erlaubt, nur für tools/: mathjax-full (Formeln als SVG). Sonst keine.
- Höchstens 400 Zeilen je Datei. Nach jeder Phase npm run typecheck, npm run lint, npm run test grün, dann Commit.
- Geht etwas nicht oder widerspricht der Code einer Entscheidung: in docs/session/offene-punkte-e1.md eintragen, im
  PR nennen, weiterarbeiten.
- Jede Aussage im PR mit Beleg (Datei:Zeile oder dbread-Ausgabe).
- STOPP nach dem PR. Einspielen erst, wenn Rasit in diesem Chat „E1 einspielen“ schreibt; dann je Migration nach
  CLAUDE.md §10, bei Fehler sofort anhalten und melden.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/session/Bauauftrag-Session-P1.md, Entscheidungen 5, 15, 18, 19, 20 und 28. Maßgeblich.
2. docs/session/coach-live-dummy.html: Schublade von Jonas in der Kernarbeit (Erklärsequenz, Variante B, Runden).
3. ~/ist-analysen/E0-erklaerung.md vollständig. Lokal.
4. docs/lena-board/ (Prüfablauf, pruef_ausschluss, Status), die Bild-Pipeline (task_figures, upload_figures) und
   tools/verify-tasks.mjs.

UMFANG
Phase E1.1 Datenmodell
1. erklaer_kernidee: skill_key, nr, titel, status (entwurf, geprueft, freigegeben), quelle (ki, mensch), pruef_version.
2. erklaer_schritt: kernidee_id, variante (A, B, C), art (erklaerung, beispiel), inhalt (Markdown, Formeln in $…$),
   formeln (Liste der erzeugten SVG-Hashes), bild (Asset bzw. svg_hash wie task_figures), fehlbild_slugs text[] (für
   welche Fehlbilder die Variante gedacht ist), status wie oben.
3. erklaer_check: kernidee_id, task_id, reihenfolge. Check-Aufgaben sind normale tasks; ihr Einsatz 'check' (X0) wird
   beim Anlegen der Inhalte in P2 gesetzt (offener Punkt, bis X0 eingespielt ist).
4. erklaer_fortschritt: session, student, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug, zeit.

Phase E1.2 Hinweis-Status
5. Hinweis-Objekte in task_solutions.hints bekommen status (entwurf, geprueft); vorhandene ohne Status gelten als
   entwurf. lsa_hint liefert nur geprüfte. hinweis_status_setzen nur für Prüfer (darf_pruefen) und Admin. Die
   Prüfoberfläche kommt in P2 (eigene Prüfseite, offener Punkt).

Phase E1.3 Ablauf auf dem Server
6. erklaer_start(session, student, skill_key) → erster Schritt der ersten Kernidee (nur freigegeben).
7. erklaer_check_abgeben(session, student, check_task_id, eingabe): bewertet mit der LSA-Engine, ermittelt das
   Fehlbild über known_errors und antwortet mit genau einem von: weiter (nächste Kernidee bzw. Übergang ins Üben),
   variante X (die Variante, deren fehlbild_slugs das Fehlbild enthält, sonst die nächste ungezeigte), signal (nach
   erklaerrunden_bis_signal Runden; Stellschraube aus session_einstellungen, solange sie fehlt mit Startwert 2, offener
   Punkt). Keine Lösung in der Antwort. Fortschritt in erklaer_fortschritt.
8. erklaer_nachlesen(student, skill_key): nur freigegebene Erklärschritte und Beispiele der Variante A, ohne Checks
   (für zuhause).
9. RLS: Kinder lesen nur über Funktionen und nur freigegebene Inhalte; Prüfer lesen alles; schreiben nur Admin und
   Prüfer über Funktionen.

Phase E1.4 Formeln als SVG
10. tools/formeln-svg.mjs: erzeugt aus $…$ in einem Erklärschritt SVG mit mathjax-full, lädt sie wie die Bild-Pipeline
    hoch und trägt die Hashes in formeln ein. Erst --dry-run. Test mit drei Formeln: Bruch, Wurzel, Potenz.

TESTS (supabase/tests/session_e1.test.sql, eigene Fixtures, grün in der Wegwerf-DB, Ausgabe ins PR)
1  erklaer_start liefert keinen Entwurf.
2  Richtiger Check → weiter.
3  Falscher Check mit Fehlbild x → die Variante, deren fehlbild_slugs x enthält.
4  Falscher Check ohne passende Variante → nächste ungezeigte Variante.
5  Zweimal falsch in derselben Kernidee → signal.
6  Antworten enthalten nie die Lösung.
7  lsa_hint liefert keinen Hinweis im Status entwurf.
8  erklaer_nachlesen liefert keine Checks.
9  Schülerkonto kann weder Kernideen noch Schritte noch Hinweis-Status schreiben.
Dazu Vitest für tools/formeln-svg.mjs.

ABNAHME
Alle Tests grün; in der Wegwerf-DB läuft eine Beispiel-Sequenz (Fixture „Steigung aus dem Graphen“ mit drei Kernideen
und je zwei Varianten wie im Dummy) mit einem falschen und einem richtigen Check durch (Skript
docs/session/e1-durchlauf.sql, Ausgabe ins PR).

PR (gegen dev)
Titel: feat(session-e1): Erklärsequenz, Hinweis-Status und Formeln als SVG
Inhalt: Kurzfassung, Objektliste, Aufruferliste und pg_proc-Scan, Consensus-Check, Einspielreihenfolge mit Befehlen
nach CLAUDE.md §10, pgTAP- und Vitest-Ausgabe, Durchlauf-Skript, offene Punkte. Hinweis: Gemergt wird erst nach grünem
CI mit neuem Schema-Abzug. Dann STOPP.
```

---

## Prompt Q1 — Home-Quest-Endpunkte

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket Q1 des Bauauftrags Session-Rahmen P1: Endpunkte für die Home Quests im
Backend. Keine Oberfläche, kein Versand, nichts wird eingeschaltet.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-q1 -b feat/rasit-session-q1-quests origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel laufen andere Agenten in ~/Edvancev1 und in
  ../Edvancev1-x0, -r1, -a1, -e1.
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Kein DDL und keine schreibende Abfrage gegen Produktion. Lesen nur über dbread.
- Migrationen nur als Datei unter supabase/migrations/, Zeitstempel nur im Bereich 20261007140000 bis 20261007145959.
- Tests nur in einer Wegwerf-DB: pgTAP lokal ohne Root wie in docs/retros/2026-10-04-report-themenraum.md („Gelernt“),
  mit PGOPTIONS='-c search_path=public,extensions'. Nie edvance_shadow, nie Produktion.
- supabase/schema-erwartet.sql, schema.sql und schema_content.sql nicht anfassen.
- Vor jeder Änderung an bestehenden Spalten, Policies oder Funktionen: pg_proc-Scan über dbread und Repo-Suche nach
  allen Aufrufern (beide Repos, edvance-app nur lesen). Liste ins PR.
- Dieser Auftrag ist Rasits Bestätigung für genau die hier beschriebenen Auth- und RLS-Regeln (CLAUDE.md §4).
  Consensus-Check nach CLAUDE.md §8, Ergebnis ins PR.
- Schreiben nur über SECURITY DEFINER-Funktionen nach Muster 20261004001333_lead_thema_setzen.sql.
- Höchstens 400 Zeilen je Datei. Nach jeder Phase npm run typecheck, npm run lint, npm run test grün, dann Commit.
- Geht etwas nicht oder widerspricht der Code einer Entscheidung: in docs/session/offene-punkte-q1.md eintragen, im
  PR nennen, weiterarbeiten.
- Jede Aussage im PR mit Beleg (Datei:Zeile oder dbread-Ausgabe).
- Hinweis FernUSG: Die Clinic prüft die Mechanik noch. Die Stellschraube home_quests_aktiv bleibt aus.
- STOPP nach dem PR. Einspielen erst, wenn Rasit in diesem Chat „Q1 einspielen“ schreibt; dann je Migration nach
  CLAUDE.md §10, bei Fehler sofort anhalten und melden.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/session/Bauauftrag-Session-P1.md, Entscheidungen 4, 21, 22 (Quest-Stellschrauben) und 24. Maßgeblich.
2. docs/session/coach-live-dummy.html: Check-out (Quest-Termin je Kind) und Vorher (Quests erledigt).
3. ~/ist-analysen/Q0-home.md vollständig. Lokal.
4. Bestehend: home_streak_*-Spalten, XP-Tabellen, graph_mail.ts, vertraege.eltern_email.

UMFANG
1. quests: student_id, session_id (Ursprung), art (A, B, KA), faellig_ab, termin (vom Kind gewählt), status (offen,
   erledigt, verfallen), erledigt_am, xp_gebucht. quest_aufgaben: quest_id, task_id, reihenfolge.
2. quest_erzeugen(session, student, skill_keys text[], ka_thema_key default null): Quest A quest_a_abstand_tage nach
   der Session, Quest B am Tag vor der nächsten gebuchten Session, bei einer Klassenarbeit vor der nächsten Session
   stattdessen ein Paket zum Thema der Klassenarbeit. Aufgaben: freigegeben, aktiv, mit Lösungsweg, aus skill_keys
   gemischt mit Älterem, Summe est_duration_sec höchstens quest_minuten. Stellschrauben aus session_einstellungen,
   solange die Tabelle fehlt (R1) mit den Startwerten (offener Punkt). Aufruf aus dem Check-out verdrahtet P2.
3. quest_termin_setzen(quest, termin): Coach der Session oder das Tablet des Kindes im Check-out.
4. quest_inhalt(quest): Aufgaben mit Lösungsweg zur Selbstkontrolle, nur für das Konto des Kindes. Die Anmeldung mit
   Zugangscode kommt mit der Schüler-App (offener Punkt).
5. quest_erledigt(quest): Status erledigt, XP (quest_xp) über die XP-Buchungsfunktion als Definer, Wochenserie in
   home_streak_* (pausiert beim Reißen, setzt nie zurück). Speichert keine Antworten und kein richtig oder falsch.
6. Benachrichtigung als Endpunkt: push_tokens (student, geraet, plattform, token, angelegt_am) mit
   push_token_registrieren(token, plattform); quest_erinnerungen_faellig(bis) liefert student, quest und termin für den
   späteren Versand. Kein Versand in P1.
7. eltern_quest_wochenstand(woche): je Kind erledigt und offen, nur Admin oder Systemaufruf. Versand über graph_mail.ts
   baut P2.
8. FernUSG-Garantie: Keine Quest-Funktion schreibt in lsa_*, session_antworten, lernpfad, student_task_progress,
   behavior_snapshots oder Reports.
9. Datenschutz: neue personenbezogene Daten (Push-Token, Termine, Zeitpunkte) mit Löschung bei Vertragsende als
   offener Punkt für Windweiss aufschreiben.

TESTS (supabase/tests/session_q1.test.sql, eigene Fixtures, grün in der Wegwerf-DB, Ausgabe ins PR)
1  quest_erzeugen legt A und B mit den richtigen Daten an; mit Klassenarbeit vor der nächsten Session ein KA-Paket.
2  Aufgaben nur freigegeben, mit Lösungsweg, Summe höchstens quest_minuten.
3  quest_inhalt für ein fremdes Kind → 42501.
4  quest_erledigt bucht XP genau einmal; zweiter Aufruf bucht nichts.
5  Zeilenzahlen in lsa_*, session_antworten (falls vorhanden), lernpfad (falls vorhanden), student_task_progress,
   behavior_snapshots und Report-Tabellen sind vor und nach quest_erledigt gleich.
6  quest_erinnerungen_faellig liefert nur offene Quests mit Termin im Fenster.
7  eltern_quest_wochenstand für Schülerkonto oder Coach → 42501.

ABNAHME
Alle Tests grün; in der Wegwerf-DB lässt sich für ein Testkind der Weg Session → quest_erzeugen → Termin → Inhalt →
erledigt → Wochenstand durchspielen (Skript docs/session/q1-durchlauf.sql, Ausgabe ins PR).

PR (gegen dev)
Titel: feat(session-q1): Endpunkte für Home Quests
Inhalt: Kurzfassung, Objektliste, Aufruferliste und pg_proc-Scan, Consensus-Check, Einspielreihenfolge mit Befehlen
nach CLAUDE.md §10, pgTAP-Ausgabe, Durchlauf-Skript, offene Punkte (Anmeldung, Versand, Löschfristen, Verdrahtung).
Hinweis: Gemergt wird erst nach grünem CI mit neuem Schema-Abzug. Dann STOPP.
```

---

## Nach P1

1. PRs lesen: Dummy-Abgleich in R1, Altlasten-Liste in A1, Stellen-Liste der Testläufe in X0, offene Punkte aller fünf.
2. Einspielen in der Reihenfolge X0 → R1 → A1 → E1 → Q1, je mit „<Paket> einspielen“ im jeweiligen Chat.
3. Dann P2: Auswahlfunktion (A2), Session-Ablauf in der Schüler-App (R2), Sequenz-Player und Prüfseite (E2a), Inhalte
   (E2b), Coach-Live-Sicht nach dem Dummy (C2), Home-App (Q2). Dabei werden die offenen Punkte zwischen den Paketen
   verdrahtet.
