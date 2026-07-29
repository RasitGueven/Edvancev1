---
id: sondierrang-fundament
type: content
repo: edvancev1
branch: spec/sondierrang-fundament
depends_on: []
gates:
  - python3 scripts/content/sondierrang_vorschlag.py
  - psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_probelauf.sql
---

## Ziel

`tasks.sondierrang` für die freigegebenen Fundament-Aufgaben belegen: Rang 1 und 2 je Skill, nach dem Verfahren aus `docs/sondierrang_vorschlag.md`.

Die Spalte steht überall auf `NULL`, also sortiert `lsa_select_next` nur nach Zufallsschlüssel. Bei fünf bis sieben Aufgaben je Skill entscheidet damit der Zufall, woran ein Kind zuerst scheitert — und ob die zweite Sondierung überhaupt etwas Neues zeigt.

**Der Agent schreibt nicht in Produktion.** Er erzeugt ein SQL-Skript und einen Bericht; das Setzen macht Rasit nach Durchsicht. Begründung unten.

## Kontext

**Zuerst `docs/sondierrang_vorschlag.md` lesen.** Dort steht das Verfahren, und es weicht von der naheliegenden Vermutung ab.

Das Kriterium ist nicht Schwierigkeit, sondern **Fehlbildprofil**: welche Denkfehler eine Aufgabe überhaupt sichtbar machen kann. Das Profil einer Aufgabe ist die Menge der Schlüssel in `task_solutions.acceptance -> 'known_errors'`.

- **Rang 1** aus dem breitesten Profil — der Aufgabe, die die meisten Fehlbilder sichtbar machen kann.
- **Rang 2** aus einem *anderen* Profil. Zwei Aufgaben desselben Profils machen dieselben Denkfehler sichtbar; die zweite Sondierung ist dann verschenkt.
- Hat ein Skill nur ein Profil, entscheidet die Zahlenwahl — kleinere Zahlen zuerst.

**Nur Rang 1 und 2.** Alles Weitere bleibt `NULL` und wird zufällig gezogen. Eine vollständige Durchnummerierung ist ausdrücklich nicht gewollt.

Die Vorlage ist veraltet — sie rechnet mit 146 Fundament-Aufgaben, der Bestand liegt bei 245 freigegebenen (A18 ergänzte 38 Geometrie-Aufgaben, dazu weitere). Deshalb `scripts/content/sondierrang_vorschlag.py` zuerst neu laufen lassen.

Betroffen sind ausschliesslich `source = 'edvance_fundament'` mit `status = 'ready'`.

**Weicht die Wirklichkeit von diesem Kontext ab — Widerspruch benennen und stoppen, nicht überbrücken.**

## Warum kein direkter Schreibzugriff

Drei Gründe, die zusammen den Ausschlag geben:

1. **Die Entscheidung ist inhaltlich, nicht technisch.** Der Spaltenkommentar sagt „Handarbeit (Rasit/Lena)". Welche Aufgabe ein Fehlbild am besten sichtbar macht, ist ein fachliches Urteil — der Agent bereitet es vor, er fällt es nicht.
2. **245 Zeilen ohne Rückweg.** Ein falscher Lauf ist nicht mit einem `delete` rückgängig zu machen wie bei neuen Aufgaben; die vorherigen Werte wären weg. (Sie sind alle `NULL`, also wäre der Rückweg hier zufällig einfach — verlassen sollte man sich darauf nicht.)
3. **Prüfen vor Wirken.** Der Probelauf beweist, dass das Skript stimmt, *bevor* es wirkt.

## Zu erzeugen

### 1 · `scripts/sql/sondierrang_setzen.sql`

Die `UPDATE`-Anweisungen, eine je Aufgabe, mit `where id = '…'` — keine Ableitung zur Laufzeit. Was gesetzt wird, muss im Diff lesbar sein.

Idempotent: ein zweiter Lauf ändert nichts. Keine Transaktionsklammer in dieser Datei — die setzt der Aufrufer.

### 2 · `scripts/sql/sondierrang_probelauf.sql`

Die Gate-Datei. Klammert Setzen und Prüfen und verwirft:

```sql
begin;
\i scripts/sql/sondierrang_setzen.sql
\i supabase/checks/sondierrang.PRUEFUNG.sql
rollback;
```

**Vorher prüfen:** Enthält `sondierrang.PRUEFUNG.sql` selbst ein `begin`/`rollback`, bricht die Verschachtelung. Dann die Prüfungen stattdessen hier ausschreiben und das vorhandene Skript nicht einbinden — **ändern darf es nicht werden.**

Das ist der Kern der Konstruktion: Der Probelauf läuft gegen Produktion, wirkt aber nicht. Er beweist, dass die 245 `UPDATE`s durchgehen und die Prüfung danach besteht.

### 3 · `out/sondierrang-bericht.md`

Je Skill die beiden gewählten Aufgaben mit ihrem Fehlbildprofil und einer Zeile, warum diese Kombination. Bei Skills mit nur einem Profil genügt der Hinweis darauf.

Das ist das Dokument, an dem Lena und Rasit entscheiden — es muss ohne Datenbankzugriff lesbar sein.

### 4 · `docs/sondierrang_vorschlag.md`

Neu erzeugt und mitcommittet.

**Falls die Datei bei jedem Lauf ein Erzeugungsdatum trägt**, ändert sie sich ohne inhaltlichen Grund — dasselbe Rauschen, das `schema-erwartet.sql` bis zum 29.07. unbrauchbar machte. Dann das Datum aus dem Erzeuger entfernen und das im Bericht vermerken.

## Akzeptanz

- `docs/sondierrang_vorschlag.md` neu erzeugt, mit 245 Aufgaben gerechnet
- `scripts/sql/sondierrang_setzen.sql`: je Skill genau eine Aufgabe mit `sondierrang = 1` und eine mit `= 2`
- Kein Rang jenseits von 2
- Wo ein Skill mehrere Fehlbildprofile hat, stammen Rang 1 und 2 aus verschiedenen
- Ausschliesslich Aufgaben mit `source = 'edvance_fundament'` und `status = 'ready'`
- Der Probelauf läuft durch und endet mit `ROLLBACK`
- `out/sondierrang-bericht.md` vollständig

## Nicht-Ziele

- **Kein Schreibzugriff auf Produktion.** Der Probelauf endet mit `rollback`; das scharfe Setzen macht Rasit.
- Keine Änderung an `supabase/checks/sondierrang.PRUEFUNG.sql`
- Keine Änderung an Aufgabentext, Status, Lösungen oder Skill-Zuordnung
- Keine Aufgaben anlegen oder löschen
- Kein `sondierrang` für `draft`-Aufgaben
- Keine Änderung an `lsa_select_next` oder am Auswahlverfahren
- Keine Ränge jenseits von 2, auch nicht „der Vollständigkeit halber"
- Keine Migration — `sondierrang` ist Inhalt, keine Schemaänderung

## Nach dem Lauf (Rasit)

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_setzen.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/sondierrang.PRUEFUNG.sql
```

Vorher `out/sondierrang-bericht.md` durchsehen — das ist der Punkt, an dem das fachliche Urteil einsteigt.
