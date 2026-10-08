# Trockenlauf: eine Session mit drei Tablets in Prod

Stand 08.10.2026 · Paket T1 · Werkzeuge: `tools/platz-konten.mjs`, `tools/trockenlauf-pruefen.sh`

Ein Laptop als Coach, drei Tablets mit je einem Testkind. Danach belegt das Prüfskript, dass nichts Echtes berührt wurde.
Was der Agent nicht weiß, steht als **Frage an Rasit** im Text. Die Antworten gehören hier hinein, bevor es losgeht.

## Vorher

### 1. Tablets

- Platz-Konten 2 bis 5 anlegen (nach „Plätze anlegen“): `node tools/platz-konten.mjs --dry-run 2-5`, dann ohne `--dry-run`.
  Zugänge stehen in `~/platz-konten/zugaenge.txt` (chmod 600), nirgends sonst.
- Tablet 1 gibt es schon (Label „Platz 1“). Für drei Tablets reichen 1 bis 3; 4 und 5 sind Reserve.
- **Frage an Rasit:** Welche drei Tablets nimmst du (Vorschlag: 2, 3, 4, damit „Platz 1“ unangetastet bleibt)?

### 2. Apps und Adressen

| Gerät | App | Adresse | Anmeldung |
|---|---|---|---|
| Laptop | Edvancev1 (Coach-Sicht und Admin) | **Frage an Rasit:** Prod-URL von Edvancev1 auf Vercel? | Admin- oder Coach-Testkonto |
| Tablet n | edvance-app (Web oder Expo-Build) | **Frage an Rasit:** URL bzw. Build der edvance-app für die Tablets? | E-Mail und Passwort aus der Zugangsdatei, Zeile „Tablet n“ |

- Nach der Anmeldung entscheidet die App selbst: Platz-Konto → Warte-Bildschirm mit der Nummer des Geräts
  (`tablet_stand()` liefert `{ zugewiesen: false, tablet_nr }`, Datenvertrag 8.2).
- **Sehen muss man:** auf jedem Tablet den Warte-Bildschirm mit *seiner* Nummer. Falsche Nummer → anhalten.

### 3. Coach

- Bestand (dbread 08.10.): 3 Coach-Konten, davon 1 als Testkonto erkennbar (Name oder Adresse). Admins dürfen die Live-Sicht auch.
- **Frage an Rasit:** Spielst du als Admin oder als Test-Coach? Als Test-Coach muss die Session diesem Coach gehören.

### 4. Testkinder

- Bestand: 26 Schülerzeilen, **alle** `ist_test`, 0 echte Kinder. Klassenstufen: 16 × Klasse 8, 4 × Klasse 9, 6 × Klasse 10.
- Für jedes Testkind ist `fkt_linear_yabschnitt` offen, ebenso `fkt_linear_steigung` (Lernpfad in Prod ist leer).
- Zielliste „Lineare Funktionen“ in Prod (`ziel_fertigkeiten_core`), für alle 26 gleich:
  1. Steigung (einstieg) · 2. y-Achsenabschnitt (einstieg) · 3. Funktionsgleichung (einstieg) · 4. Graph · 5. Nullstelle.
  Ohne Voraussetzungen davor, weil der Lernpfad leer ist. Das ist anders als im Fall aus offene-punkte-a2d 1 a (Wegwerf-DB
  mit vier sicheren Voraussetzungen, dort y-Achsenabschnitt vor Steigung). Mit Prod-Daten beginnt die Liste mit der Steigung.
- Testlauf-Pool: je 6 Aufgaben zu Steigung, y-Achsenabschnitt, Funktionsgleichung (im echten Pool 0).
- **Frage an Rasit:** Welche drei Testkinder? Vorschlag: drei aus Klasse 8 ohne bisherige Buchung.

### 5. Session im Stundenplan

1. `/admin/schedule`: Session für heute anlegen, Raum frei wählen, die drei Testkinder buchen.
2. **Testlauf setzen.** Es gibt dafür **keinen Schalter** in der Oberfläche (offene-punkte-x0, Offen 3). Die RPC
   `session_testlauf_setzen(p_session_id, true)` läuft nur mit Admin-Rolle; der Trigger `coaching_sessions_testlauf_pruefen`
   verlangt `get_my_role() = 'admin'`, auch im Supabase-SQL-Editor.
   **Frage an Rasit:** Wie soll die Session zum Testlauf werden? Möglichkeiten:
   - a) Im SQL-Editor, in einer Transaktion mit Admin-Claims (`set_config('request.jwt.claims', …, true)`), dann die RPC.
   - b) Ein kleines Folgepaket: Schalter „Testlauf“ im Stundenplan (`TestlaufSchalter` gibt es schon für Leads).
   Ohne Testlauf darf der Trockenlauf **nicht** starten: dann bucht der Abschluss XP und Einheiten.
3. **Sehen muss man:** auf `/coach` unter „Heute im Raum“ die Session mit dem Kennzeichen „Testlauf“.
4. Prüfskript einmal vorher: `tools/trockenlauf-pruefen.sh <session_id>` → Punkt 1 „Testlauf“ ok, alles andere ok.

### 6. Stellschrauben (nur ansehen)

| Stellschraube | Prod | Wirkung im Trockenlauf |
|---|---|---|
| `warmup_aufgaben` | 3 | drei Aufgaben im Warm-up |
| `erklaerung_bei_neuem_skill` | vorgeschaltet | ohne freigegebene Kernidee kommt keine Sequenz |
| `exit_aufgaben` | 2 | zwei Exit-Aufgaben |
| `home_quests_aktiv` | aus | **kein** Quest-Termin am Tablet |
| `session_xp_je_aufgabe` | 10 | im Testlauf trotzdem keine Buchung (Entscheidung 30) |

**Frage an Rasit:** Soll der Quest-Termin mitgetestet werden? Dann vorher `home_quests_aktiv` auf an (`/admin/stellschrauben`,
mit Grund) und danach wieder aus. Die Stellschraube gilt für alle Sessions.

## Während

Laptop: `/coach` → „Briefing ansehen“ → „Session starten“ → Live-Sicht (`/coach/session/<id>/live`).

| # | Schritt | Wer tut was | Was man sehen muss |
|---|---|---|---|
| 1 | Check-in, Tablet zuweisen | Coach wählt je Kind ein Tablet (1–5) | Meldung „… sitzt an Tablet n“. Das Tablet wechselt vom Warte-Bildschirm in den Check-in (Abfragetakt 4 s). Ein doppelt vergebenes Tablet wird abgelehnt („schon vergeben“). |
| 2 | Check-in am Tablet | Kind: Stimmung, Klassenarbeit, Schulthema | Klassenarbeit nur als Auswahl (aktuelles Schulthema, anderes, weiß ich nicht), kein Freitext (**E36**). Danach beim Coach der Fall-Vorschlag. |
| 3 | Fall wählen | Coach wählt Fall „Schulthema“, Thema Lineare Funktionen | Tablet zeigt das Ziel der Stunde: höchstens drei Fertigkeiten, ohne Stand, Prozent oder Farbe (**E35**). |
| 4 | Warm-up | Kind löst drei Aufgaben | Keine Hinweise (**E32**). Richtig in Gold, falsch mit Fehlbild-Satz und Fehler-Rand, kein zweiter Versuch (**E29**). |
| 5 | Kernarbeit | Kind bekommt Lösungsbeispiel, dann Aufgabe zur Steigung | Beispiel mit Lösungsweg, Weiter → Aufgabe. Coach-Kachel füllt sich alle 4 s, Musterlösung nur in der Schublade. |
| 6 | Hinweis | Kind tippt „Hinweis“ vor dem Abgeben | Hinweise nur in der Kernarbeit und nur vor dem Abgeben (**E32**). Im Warm-up und bei Exit fehlt der Knopf. |
| 7 | Prüffrage aufs Tablet | Coach bei einem Mastery-Kandidaten | Frage erscheint über dem aktuellen Schritt; Erwartung und Kriterium nur beim Coach (**E31**). Grün und „gemeistert“ erst nach Bestätigung, kein Abzeichen (**E34**). **Siehe Hinweis unten.** |
| 8 | Erklärsequenz | nur falls E2b eingespielt | In Prod gibt es keine Kernidee (dbread 08.10.: 0), E2b ist nicht eingespielt. Dann entfällt der Schritt. Mit E2b: Kernideen und Checks, danach Beispiel und Aufgabe zum selben Skill (offene-punkte-a2d 1). Freigabe-Regeln: **E37**, **E38**. |
| 9 | Exit | Kind löst zwei Exit-Aufgaben | Ohne Hinweise, nur „Gespeichert“ (**E29**). |
| 10 | Quest-Termin | nur bei `home_quests_aktiv` an | Zwei mögliche Tage, Kind wählt einen. Sonst entfällt der Schritt. |
| 11 | Check-out | Coach | Je Kind zwei Satzvorschläge, „Als gesagt markieren“. Der Satz steht **nicht** auf dem Tablet (**E33**). |
| 12 | Abschluss | Coach: „Abschluss“, dann „Session abschließen“ | Tablet zeigt das Ende. XP: im Testlauf keine Buchung (**E30**); was das Tablet am Ende zeigt, notieren. Tablets gehen zurück auf den Warte-Bildschirm. |

**Hinweis zu Schritt 7:** Eine Prüffrage gibt es nur für einen Skill im Stand `kandidat`. Der Lernpfad in Prod ist leer, und
ein Testlauf schreibt keine Belege (`antwort_abgeben` prüft `testlauf`). In diesem Trockenlauf entsteht also kein Kandidat,
der Prüffrage-Knopf erscheint nicht. **Frage an Rasit:** reicht das als Befund, oder soll die Prüffrage getrennt getestet
werden (z. B. in der Wegwerf-DB wie in C2)?

## Danach

```bash
tools/trockenlauf-pruefen.sh <session_id>
```

Zeigt je Kind (ohne Namen, „Kind n“ mit Tablet-Nummer) Schritte nach Art, Antworten nach Phase und Ergebnis, Ereignisse
nach Typ, Check-in und Abschluss. Dann die Prüfliste, jede Zeile `ok` oder `nicht ok`:

1. Session ist als Testlauf markiert
2. kein echtes Kind beteiligt (nur `ist_test`)
3. keine XP gebucht (Schlüssel `session:<id>` oder im Zeitfenster der Session)
4. keine Lernpfad-Belege
5. kein Lernpfad-Protokoll
6. keine Lernpfad-Zeile entstanden oder geändert
7. keine Mastery-Zeile (`student_competency_mastery`)
8. keine Einheit verbraucht (verbrauchende Anwesenheit zählt nur außerhalb eines Testlaufs)
9. nichts in die Akte übernommen

Exit 0 heißt alles ok. Bei `nicht ok` Ausgabe sichern und melden; nichts von Hand korrigieren.
