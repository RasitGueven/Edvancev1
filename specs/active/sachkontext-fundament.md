---
id: sachkontext-fundament
type: content
repo: edvancev1
branch: spec/sachkontext-fundament
depends_on: []
gates:
  - node tools/verify-tasks.mjs --source edvance_fundament_kontext --min-pass 1.0
  - psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sachkontext_pruefung.sql
---

## Ziel

Zu ausgewählten Fundament-Skills je drei Aufgaben mit Sachkontext erzeugen.

Der Bestand besteht ausschliesslich aus nackten Rechnungen. Damit lässt sich nicht unterscheiden, ob ein Kind nicht rechnen kann oder eine Situation nicht in eine Rechnung übersetzen kann — zwei Befunde, die zu völlig verschiedenen Empfehlungen führen.

## Kontext

- Die 245 vorhandenen `edvance_fundament`-Aufgaben stehen auf `ready` und werden **nicht angefasst**. Neue Aufgaben entstehen zusätzlich, mit `source = 'edvance_fundament_kontext'` und `status = 'draft'`.
- Sachkontext misst etwas anderes als eine nackte Rechnung: er bringt Lesekompetenz und Modellierung ins Spiel. Das ist erwünscht, aber es ist eine **zusätzliche** Messung, kein Ersatz. Deshalb Ergänzung, nicht Umschreiben.
- Die LSA dauert 20 Minuten. Drei Sätze zum Lesen kosten Zeit, die für Diagnostik fehlt. Kontext so knapp wie möglich.
- `input_type`, `acceptance` und `unit` folgen dem Muster der vorhandenen Aufgaben desselben Skills. **Erst eine bestehende Aufgabe je Skill ansehen, dann bauen.**
- `sondierrang` bleibt `null`. Die Rangvergabe betrifft nur `edvance_fundament` mit `status = 'ready'` und ist eine eigene Aufgabe.

**Weicht die Wirklichkeit von diesem Kontext ab — Widerspruch benennen und stoppen, nicht überbrücken.**

### Warum hier direkt in Produktion geschrieben wird

Anders als bei `sondierrang`, wo eine bestehende Spalte überschrieben würde: Hier entstehen **neue Zeilen** mit eigenem `source` und `status = 'draft'`. Der Rückweg ist eine Zeile:

```sql
delete from tasks where source = 'edvance_fundament_kontext';
```

Nichts Vorhandenes wird verändert, nichts wird freigegeben, und die LSA zieht `draft` nicht. Der Schreibzugriff ist damit vertretbar.

## Auswahl der Skills

Nur Skills, bei denen Modellierung fachlich sinnvoll ist:

    groessen_laengen, groessen_massen, groessen_zeit, groessen_flaechen,
    groessen_volumen, groessen_gemischt, proportionalitaet,
    prozent_prozentwert, prozent_grundwert, prozent_prozentsatz,
    prozent_veraenderung, dezimal_add_sub, dezimal_mult, dezimal_div,
    runden_ueberschlag, geo_massstab

**Die 16 Schlüssel zuerst gegen `skills` prüfen.** Beim sondierrang-Lauf zeigte sich, dass eine zweite Kopie der Skill-Namen im Code die A18-Geometriegruppen nicht kannte. Existiert einer der Schlüssel nicht: benennen und stoppen, nicht stillschweigend überspringen.

**Nicht** für `bruch_*`, `vorzeichen_*`, `term_*`, `gleichung_*`. Dort ist der Kontext aufgesetzt — negative Zahlen als Kontostand oder Temperatur sind das übliche Beispiel und messen dann Kontextkenntnis, nicht Rechnen.

16 Skills × 3 Aufgaben = **48 Aufgaben im Endzustand**.

## Qualität

Der Prüfer (`tools/verify-tasks.mjs`) löst jede Aufgabe unabhängig und muss auf die hinterlegte Lösung kommen. **Die Schwelle ist 1.0, nicht 0.98.**

Eine Aufgabe, die der Prüfer nicht lösen kann, ist entweder mehrdeutig formuliert oder hat eine falsche Lösung. Beides ist ein Defekt. In einem Instrument, das Kinder misst, zwei defekte Aufgaben zu dulden, wäre die falsche Sparsamkeit — und eine Schwelle von 0,98 bei 48 Aufgaben ist ohnehin faktisch Nulltoleranz, nur unehrlich formuliert.

**Der Weg zur vollen Quote:** mehr erzeugen als nötig, prüfen, Durchfaller löschen, Lücken nachziehen. Der Endzustand sind genau 3 geprüfte Aufgaben je Skill. Wie viele Anläufe das braucht, ist Sache des Agenten.

## Inhaltliche Regeln

Diese Aufgaben werden von 10- bis 13-Jährigen gelesen, oft in einer Situation, in der sie sich ohnehin schon unsicher fühlen.

- **Zahlen realistisch.** Mengen, Preise, Massen und Zeiten, die in Deutschland 2026 plausibel sind. Keine 47,3 Brötchen, kein Auto mit 3 kg.
- **Kontext maximal zwei Sätze**, die Frage selbst eine Zeile.
- **Keine Markennamen, kein Konsumdruck.**
- **Niemand kann sich etwas nicht leisten**, niemand hat zu wenig, niemand vergleicht sich mit anderen. Ein Kind, das gerade in einer Diagnostik sitzt, braucht keine Aufgabe über Knappheit.
- **Namen und Situationen unaufdringlich und ohne Klischee.** Vornamen aus verschiedenen Herkünften, ohne dass die Herkunft Thema wird; keine Rollenbilder entlang von Geschlecht.
- **Der Kontext trägt die Rechnung, nicht umgekehrt.** Wenn sich die Situation weglassen lässt, ohne dass die Aufgabe sich ändert, ist sie Dekoration und kostet nur Lesezeit.

## Zu erzeugen

### 1 · Die Aufgaben

Je Skill 3 Zeilen in `tasks` mit `source = 'edvance_fundament_kontext'`, `status = 'draft'`, gesetztem `skill_key`, `class_level` wie beim Vorbild. Zu jeder eine Zeile in `task_solutions` mit korrekter Lösung.

### 2 · `scripts/sql/sachkontext_pruefung.sql`

Eine Datei, kein Bash-Einzeiler — sie soll lesbar und wiederholbar sein. Prüft und meldet mit klarer Fehlermeldung:

| # | Prüfung |
|---|---|
| S1 | genau 3 Aufgaben je Skill, genau die 16 Skills, keine anderen |
| S2 | alle mit `status = 'draft'` |
| S3 | alle mit gesetztem `skill_key` |
| S4 | zu jeder Aufgabe eine Zeile in `task_solutions` |
| S5 | `sondierrang` überall `null` |
| S6 | keine Aufgabe mit `source = 'edvance_fundament'` verändert (Anzahl weiterhin 245, davon 76 mit Rang) |

S6 ist die Negativkontrolle: Sie schlägt an, wenn der Lauf am bestehenden Bestand gerührt hat.

### 3 · `docs/sachkontext-bericht.md`

Je Skill die drei Aufgaben mit Lösung, zum Durchsehen durch Lena.

**Nach `docs/`, nicht nach `out/`** — `out/` steht in `.gitignore`, und ein Bericht, den Lena öffnen soll, muss im Repo liegen.

## Nicht-Ziele

- Keine Änderung an bestehenden Aufgaben, an ihrem Text, Status oder ihren Lösungen
- Keine neuen Skills, keine Änderung an `skills` oder `skill_kante`
- **Keine Freigabe** — alles bleibt `draft`. Die Freigabe ist Lenas Entscheidung.
- Kein `sondierrang`
- Keine Aufgaben zu Skills ausserhalb der Liste
- Keine Migration — das hier ist Inhalt, keine Schemaänderung
- Kein `src/lib/**`

## Nach dem Lauf (Rasit / Lena)

`docs/sachkontext-bericht.md` durchsehen. Freigabe einzeln oder in Gruppen:

```sql
update tasks set status = 'ready'
 where source = 'edvance_fundament_kontext' and skill_key = '…';
```

Rückweg, solange nichts freigegeben ist:

```sql
delete from tasks where source = 'edvance_fundament_kontext';
```
