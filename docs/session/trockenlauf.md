# Trockenlauf: eine Session mit drei Tablets in Prod

Stand 08.10.2026 · Paket T1 · Werkzeuge: `tools/platz-konten.mjs`, `tools/trockenlauf-pruefen.sh`

Ein Laptop als Test-Coach, drei Tablets mit je einem Testkind. Danach belegt das Prüfskript, dass nichts Echtes berührt
wurde. Entscheidungen von Rasit (08.10.) sind eingearbeitet; offen ist nur noch, was mit **OFFEN** markiert ist.

## Vorher

### 1. Tablets

- In Prod angelegt (08.10.): Tablet 2 bis 5, dazu das vorhandene „Platz 1“ (Tablet 1). dbread: 5 Platz-Konten, `tablet_nr` 1–5.
- Zugänge: `~/platz-konten/zugaenge.txt` (chmod 600), eine Zeile je Tablet („Tablet n“, E-Mail, Passwort). Nirgends sonst.
- Für den Trockenlauf: **Tablet 2, 3 und 4**. Tablet 5 ist Reserve, Platz 1 bleibt unangetastet.
- Weitere Tablets später: `cd ~/Edvancev1 && node ../Edvancev1-t1/tools/platz-konten.mjs --dry-run <nummern>`, dann ohne
  `--dry-run`. Das Werkzeug liest die `.env` im Arbeitsverzeichnis; der Key erscheint nie in der Ausgabe.

### 2. Apps und Adressen

| Gerät | App | Adresse | Anmeldung |
|---|---|---|---|
| Laptop | Edvancev1 (Test-Coach) | **OFFEN:** `<URL EINTRAGEN>` | Konto „ZZ Test Coach“ |
| Tablet 2, 3, 4 | edvance-app | **OFFEN:** `<URL EINTRAGEN>` | E-Mail und Passwort aus der Zugangsdatei, Zeile „Tablet n“ |

Die beiden URLs kamen in der Antwort vom 08.10. als Platzhalter an. Bitte hier eintragen.

- Nach der Anmeldung entscheidet die App selbst: Platz-Konto → Warte-Bildschirm mit der Nummer des Geräts
  (`tablet_stand()` liefert `{ zugewiesen: false, tablet_nr }`, Datenvertrag 8.2).
- **Sehen muss man:** auf jedem Tablet den Warte-Bildschirm mit *seiner* Nummer. Falsche Nummer → anhalten.

### 3. Coach

- **Test-Coach „ZZ Test Coach“**, nicht Admin: So werden die Coach-Rechte aus X0 mitgetestet (Live-Daten nur der eigenen
  Session, Akten-Daten nur bei laufendem Vertrag, Entscheidung 26).
- Der Test-Coach ist der Coach der Session (Schritt 5).

### 4. Testkinder

Drei Testkonten aus Klasse 8. Es sind genau die drei Testkinder der Klasse 8, die heute buchbar sind: Buchen verlangt
einen laufenden Vertrag (`session_platz_zugang`). dbread 08.10.:

| Kind | Tablet | `ist_test` | Vertrag bis | `akte_aktiv` | offene Buchungen |
|---|---|---|---|---|---|
| TESTLEAD Drittmann | 2 | ja | 15.05.2027 | ja | 0 |
| Test Test (`964738af…`) | 3 | ja | 30.09.2027 | ja | 1 |
| ZZ_S2B Mia Plan | 4 | ja | 31.05.2027 | ja | 1 |

- Es gibt zwei Testkinder „Test Test“ in Klasse 8; gemeint ist `964738af-2cd8-422a-ad8e-3aa1cbd79277` (das andere hat keinen Vertrag).
- Für alle drei sind `fkt_linear_steigung` und `fkt_linear_yabschnitt` offen; der Lernpfad in Prod ist leer.
- Zielliste „Lineare Funktionen“ in Prod (`ziel_fertigkeiten_core`), für alle gleich:
  1. Steigung (einstieg) · 2. y-Achsenabschnitt (einstieg) · 3. Funktionsgleichung (einstieg) · 4. Graph · 5. Nullstelle.
  Ohne Voraussetzungen davor (anders als der Fall in offene-punkte-a2d 1 a mit vier sicheren Voraussetzungen).
- Testlauf-Pool: je 6 Aufgaben zu Steigung, y-Achsenabschnitt und Funktionsgleichung (im echten Pool 0).

### 5. Session im Stundenplan

1. `/admin/schedule` (als Admin): Session für den Tag des Trockenlaufs anlegen, Coach „ZZ Test Coach“, die drei Kinder buchen.
2. Session-ID notieren (Stundenplan bzw. Adresse der Live-Sicht).

### 6. Testlauf setzen (vor dem Start)

Einen Schalter gibt es noch nicht (kommt mit T2). Im Supabase-SQL-Editor, `<SESSION_ID>` ersetzen, alles auf einmal ausführen:

```sql
begin;
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from public.profiles where role = 'admin' and full_name = 'Rasit Güven'),
                    'role', 'authenticated')::text, true);
select public.session_testlauf_setzen('<SESSION_ID>'::uuid, true);
commit;
```

- `set_config(…, true)` gilt nur in dieser Transaktion. Danach ist der SQL-Editor wieder ohne Claims.
- Der Trigger `coaching_sessions_testlauf_pruefen` lehnt ab, wenn ein gebuchtes Kind kein Testkonto ist (22023). Dann
  anhalten.
- Gegen Prod read-only geprüft (08.10.): Mit diesen Claims liefert `get_my_role()` `admin`, und der Aufruf kommt an der Admin-Prüfung vorbei.
  Ohne Claims kommt „session_testlauf_setzen: nur Admin“.

**Kontrolle per dbread** (muss `t|t` zeigen: Testlauf an, nur Testkonten gebucht):

```bash
~/bin/dbread -tAc "select cs.testlauf, bool_and(s.ist_test) from coaching_sessions cs join session_students ss on ss.session_id = cs.id join students s on s.id = ss.student_id where cs.id = '<SESSION_ID>' group by cs.testlauf"
```

Ohne `t|t` startet der Trockenlauf **nicht**: Ohne Testlauf bucht der Abschluss XP und verbraucht Einheiten.

- **Sehen muss man:** auf `/coach` (Test-Coach) unter „Heute im Raum“ die Session mit dem Kennzeichen „Testlauf“.
- Prüfskript einmal vorher: `tools/trockenlauf-pruefen.sh <SESSION_ID>`. Erwartet sind Punkt 1 ok und Punkt 10 noch ok
  (Quests sind noch aus).

### 7. Home Quests an

`/admin/stellschrauben` (als Admin): `home_quests_aktiv` auf **an**, Grund „Trockenlauf T1“. Die Stellschraube gilt für
alle Sessions; als letzter Schritt kommt sie wieder aus (Abschnitt „Danach“).

Weitere Stellschrauben in Prod (nur ansehen):

| Stellschraube | Prod | Wirkung im Trockenlauf |
|---|---|---|
| `warmup_aufgaben` | 3 | drei Aufgaben im Warm-up |
| `erklaerung_bei_neuem_skill` | vorgeschaltet | ohne freigegebene Kernidee kommt keine Sequenz |
| `exit_aufgaben` | 2 | zwei Exit-Aufgaben |
| `session_xp_je_aufgabe` | 10 | im Testlauf trotzdem keine Buchung (Entscheidung 30) |

## Während

Laptop als Test-Coach: `/coach` → „Briefing ansehen“ → „Session starten“ → Live-Sicht (`/coach/session/<id>/live`).

| # | Schritt | Wer tut was | Was man sehen muss |
|---|---|---|---|
| 1 | Check-in, Tablet zuweisen | Coach: Drittmann → 2, Test Test → 3, Mia Plan → 4 | Meldung „… sitzt an Tablet n“. Das Tablet wechselt vom Warte-Bildschirm in den Check-in (Abfragetakt 4 s). Ein doppelt vergebenes Tablet wird abgelehnt („schon vergeben“). |
| 2 | Check-in am Tablet | Kind: Stimmung, Klassenarbeit, Schulthema | Klassenarbeit nur als Auswahl (aktuelles Schulthema, anderes, weiß ich nicht), kein Freitext (**E36**). Danach beim Coach der Fall-Vorschlag. |
| 3 | Fall wählen | Coach wählt Fall „Schulthema“, Thema Lineare Funktionen | Tablet zeigt das Ziel der Stunde: höchstens drei Fertigkeiten, ohne Stand, Prozent oder Farbe (**E35**). |
| 4 | Warm-up | Kind löst drei Aufgaben | Keine Hinweise (**E32**). Richtig in Gold, falsch mit Fehlbild-Satz und Fehler-Rand, kein zweiter Versuch (**E29**). |
| 5 | Kernarbeit | Kind bekommt Lösungsbeispiel, dann Aufgabe | Beispiel mit Lösungsweg, Weiter → Aufgabe. Coach-Kachel füllt sich alle 4 s, Musterlösung nur in der Schublade. Notieren, mit welchem Skill die Kernarbeit beginnt (Steigung erwartet). |
| 6 | Hinweis | Kind tippt „Hinweis“ vor dem Abgeben | Hinweise nur in der Kernarbeit und nur vor dem Abgeben (**E32**). Im Warm-up und bei Exit fehlt der Knopf. |
| 7 | Prüffrage | – | **Erscheint im Trockenlauf nicht** (siehe unten). |
| 8 | Erklärsequenz | nur falls E2b eingespielt | In Prod gibt es keine Kernidee (dbread 08.10.: 0), E2b ist nicht eingespielt. Dann entfällt der Schritt. Mit E2b: Kernideen und Checks, danach Beispiel und Aufgabe zum selben Skill (offene-punkte-a2d 1). Freigabe-Regeln: **E37**, **E38**. |
| 9 | Exit | Kind löst zwei Exit-Aufgaben | Ohne Hinweise, nur „Gespeichert“ (**E29**). |
| 10 | Quest-Termin | Kind wählt einen von zwei Tagen | Zwei mögliche Tage nach `quest_a_abstand_tage` (Entscheidung 21). Erscheint nur, weil `home_quests_aktiv` an ist. |
| 11 | Check-out | Coach | Je Kind zwei Satzvorschläge, „Als gesagt markieren“. Der Satz steht **nicht** auf dem Tablet (**E33**). |
| 12 | Abschluss | Coach: „Abschluss“, dann „Session abschließen“ | Tablet zeigt das Ende. XP: im Testlauf keine Buchung (**E30**); was das Tablet am Ende zeigt, notieren. Danach sollten die Tablets wieder den Warte-Bildschirm zeigen. |

**Nicht drücken:** „Eine Stufe tiefer“ und Eingriffe schreiben auch im Testlauf in den Lernpfad (offene-punkte-t1, Befund 3;
Ausschluss kommt mit T2). Wer es trotzdem ausprobiert: Das Prüfskript meldet es als „nicht ok“ (Punkte 5 und 6).

**Prüffrage (Schritt 7):** Sie gibt es nur für einen Skill im Stand `kandidat`. Der Lernpfad in Prod ist leer, und ein
Testlauf schreibt keine Belege (`antwort_abgeben` prüft `testlauf`). Im Trockenlauf entsteht also kein Kandidat, der Knopf
„Prüffrage aufs Tablet“ erscheint nicht (**E31**, **E34** bleiben hier ungetestet). Abgedeckt ist der Ablauf über die
App-Vorschau (`/session/vorschau` in edvance-app) und pgTAP `supabase/tests/session_a2b.test.sql` (Teil 2 und 3:
`pruefung_aufs_tablet`, `tablet_stand.pruefung`).

## Danach

1. **Home Quests wieder aus:** `/admin/stellschrauben`, `home_quests_aktiv` auf **aus**, Grund „Trockenlauf T1 Ende“.
2. **Prüfen:**

   ```bash
   tools/trockenlauf-pruefen.sh <SESSION_ID>
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
   10. `home_quests_aktiv` ist wieder aus

   Exit 0 heißt alles ok. Bei `nicht ok` Ausgabe sichern und melden; nichts von Hand korrigieren.
