# Szenario Batu: die erste Session nach der LSA durchspielen

Stand 09.10.2026 · Paket F1, Umfang B5 · Muster und Erwartung: `batu.md` · Vorbild: `docs/session/trockenlauf.md`

Ein Laptop als Test-Coach, ein Tablet für Batu (= TESTLEAD Zweitmann, `5737b689…`). Ziel: sehen, wie aus der LSA
(Wurzeln sicher, Wurzelgesetze teils, irrationale Zahlen wackelig, Runden fehlt) die erste Session zu Quadratischen
Gleichungen wird. Die Session ist ein **Testlauf** (Entscheidung 27): Sie hinterlässt keine Belege, keine XP, keine
Einheit.

## Vorher

### 1. Voraussetzungen in Prod

- F1 ist eingespielt (Migrationen `20261011140000` bis `…140400`), insbesondere der LSA-Pool für Testkonten (E2), die
  Warm-up-Reihenfolge (E3) und die Platzhalter-Sequenz zu `gleichung_quadr_faktor` (B4).
- Das Szenario ist angelegt (nach „Szenario anlegen“): `tools/szenario-lsa.mjs`. Kontrolle per dbread:

  ```bash
  ~/bin/dbread -tAc "select stand_system, count(*) from lernpfad where student_id = '5737b689-8add-49f5-ac26-89bd40387b0f' group by 1"
  ```

  Erwartet: `noch_nicht_sicher|5` und `sicher|6`.
- Das Szenario **vor** dem Zeitfenster der Session anlegen. Sonst meldet `tools/trockenlauf-pruefen.sh` Punkt 6
  („keine Lernpfad-Zeile entstanden oder geändert“), weil es Lernpfad-Zeilen im Zeitfenster zählt.
- Tablet und Test-Coach wie trockenlauf.md 1 bis 3 (ein Tablet genügt, z. B. Tablet 2).

### 2. Session anlegen

1. `/admin/schedule` (als Admin): Session für heute, Coach „ZZ Test Coach“, **TESTLEAD Zweitmann** buchen. Buchen
   verlangt einen laufenden Vertrag; Zweitmann hat einen (bis 30.04.2027).
2. Session-ID notieren.

### 3. Testlauf setzen (vor dem Start)

Wie trockenlauf.md Schritt 6 (SQL-Editor, `session_testlauf_setzen` mit Admin-Claims), danach die Kontrolle per dbread
(`t|t`). Ohne Testlauf startet das Szenario **nicht**.

Warum Testlauf: Die Aufgaben der quadratischen Gleichungen und die Erklärsequenz sind Entwürfe. Außerhalb eines
Testlaufs stünden sie nicht im Session-Pool (`session_im_pool` verlangt `ready`; E2 gilt nur für die LSA), und die
Sequenz käme nicht (Status `entwurf`).

## Während

Laptop: `/coach` → Session → „Session starten“ → Live-Sicht.

| # | Schritt | Wer tut was | Was man sehen muss |
|---|---|---|---|
| 1 | Tablet zuweisen | Coach: Batu → Tablet 2 | „… sitzt an Tablet 2“; das Tablet wechselt in den Check-in. |
| 2 | Check-in am Tablet | Kind: Stimmung, Klassenarbeit „nein“, Schulthema | Das Tablet fragt nach „Reelle Zahlen und Wurzeln“ (Schulthema aus der LSA). Das Kind antwortet „neu“ und tippt z. B. „quadratische Gleichungen“. Zum Check-in selbst siehe den eigenen Lauf; hier nichts beurteilen. |
| 3 | **Thema wählen (A1)** | Coach in der Check-in-Zeile: „Ändern“ (bzw. „Thema wählen“, wenn kein Thema steht) → Suche „quadr“ → **Quadratische Gleichungen** | Toast „Thema …“. Fall springt auf **Schulthema**, Ziel „Quadratische Gleichungen“. Das alte Thema wird „behandelt“. |
| 4 | Warm-up | Kind löst drei Aufgaben | **Negative Zahlen addieren/subtrahieren** (`vorzeichen_add_sub`), eine Stufe leichter, ohne Hinweise. Warum diese und nicht die Wurzel: `batu.md` 3 (Regel F17, Abstand zum ersten offenen Ziel-Skill `gleichung_quadr_faktor`; die Wurzel ist von dort aus nicht erreichbar). Kopf: „Kinder gerade: Warm-up 1“; Kachel „Warm-up seit …“. |
| 5 | Erklärsequenz | Kind | Kernarbeit beginnt bei **gleichung_quadr_faktor** (erster offener Ziel-Skill; zahl_wurzel_quadrat steht davor, ist aber sicher). Weil der Skill neu ist und im Pool Aufgaben hat, kommt zuerst die **Platzhalter-Sequenz**: Kernidee „Platzhalter: Quadratische Gleichungen durch Ausklammern (Nullprodukt)“, Erklärschritt, Lösungsbeispiel, Check (x · (x − 3) = 0, Antwort 3). Alle Texte beginnen mit „Platzhalter“. |
| 6 | Lösungsbeispiel und Aufgabe | Kind | Nach der Sequenz ein Lösungsbeispiel, dann eine ähnliche Aufgabe (`neu_aehnliche_aufgabe`), danach Kernarbeit. Zwei richtige ohne Hinweis → faktor ist heute sicher, weiter mit `gleichung_quadr_wurzel`. |
| 7 | Hinweis | Kind tippt „Hinweis“ | **Im Testlauf „nicht verfügbar“** (offener Punkt, Paket T3). Nicht als Fehler melden. |
| 8 | Einmischen | – | Etwa jede dritte gezählte Aufgabe ist eingemischt (`mischanteil` 30 %): sichere Voraussetzungen, zuerst dezimal_add_sub, dezimal_mult, vorzeichen_mult_div, dann **zahl_wurzel_quadrat** (`batu.md` 3, Einschränkung F13). |
| 9 | Exit, Check-out, Abschluss | wie trockenlauf.md 9 bis 12 | – |

**Was der Coach in der Schublade sieht** (Kachel antippen, ab Warm-up):

- **Ziel der Stunde:** Quadratische Gleichungen, Fall Schulthema, mit „Ändern“. Zeilen: zahl_wurzel_quadrat
  („Voraussetzung · sicher“), gleichung_quadr_faktor, …_wurzel, …_formel, …_anzahl (offen). Ist faktor heute sicher:
  „heute n von m · heute sicher, weiter zum nächsten Skill“ (A6).
- **Erklärsequenz:** Kernidee 1 mit Platzhalter-Titel, Stand und Runde.
- **Aufgabe** mit Musterlösung, **Letzte Eingabe** als Wert (z. B. „3“, nicht `{"text":"3"}`), **Falsche Antworten**
  nur zur aktuellen Aufgabe (A2/A3). Frühere Fehler stehen unter „Heute“.
- **Heute:** Ankommen, Warm-up (vorzeichen_add_sub n von 3), Erklärsequenz, Kernarbeit je Skill.
- Steht das Kind ohne Ziel oder ohne Aufgabe (`kein_ziel`, `pool_leer`), steht oben der Grund in Klartext mit der
  Themensuche (A1).

**Nicht drücken:** „Eine Stufe tiefer“ und Eingriffe (trockenlauf.md, bis T2).

## Danach

1. `tools/trockenlauf-pruefen.sh <SESSION_ID>`: alle Punkte `ok` (Testlauf, keine Belege, keine XP, kein Lernpfad-
   Protokoll aus der Session).
2. Das Szenario bleibt für weitere Durchläufe stehen. Zurücksetzen (nur auf Zuruf):
   `cd ~/Edvancev1 && node ../Edvancev1-f1/tools/szenario-zuruecksetzen.mjs --dry-run --protokoll ~/szenario/batu-5737b689-8add-49f5-ac26-89bd40387b0f.json`,
   dann ohne `--dry-run`.
3. **Nicht Teil des Zurücksetzens:** das Thema, das der Coach in Schritt 3 gewählt hat (Quadratische Gleichungen
   als aktuelles Schulthema des Leads), und die Session selbst. Beides entsteht über die Oberfläche, nicht über das
   Werkzeug.
