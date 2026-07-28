---
id: sondierrang-fundament
type: content
repo: edvancev1
branch: spec/sondierrang-fundament
depends_on: []
gates:
  - python3 scripts/content/sondierrang_vorschlag.py
  - bash -c 'git diff --quiet docs/sondierrang_vorschlag.md || (echo "Vorlage veraltet — neu erzeugt, bitte pruefen und mitcommitten" && exit 1)'
  - psql "$DBURL" -v ON_ERROR_STOP=1 -f supabase/checks/sondierrang.PRUEFUNG.sql
---

## Ziel

`tasks.sondierrang` für die freigegebenen Fundament-Aufgaben setzen: Rang 1 und 2
je Skill, nach dem Verfahren aus `docs/sondierrang_vorschlag.md`.

Derzeit steht die Spalte überall auf `NULL`, also sortiert `lsa_select_next` nur
nach Zufallsschlüssel. Bei fünf bis sieben Aufgaben je Skill entscheidet damit der
Zufall, woran ein Kind zuerst scheitert — und ob die zweite Sondierung überhaupt
etwas Neues zeigt.

## Kontext

**Zuerst `docs/sondierrang_vorschlag.md` lesen.** Dort steht das Verfahren, und es
weicht von der naheliegenden Vermutung ab.

Das Kriterium ist nicht Schwierigkeit, sondern **Fehlbildprofil**: welche Denkfehler
eine Aufgabe überhaupt sichtbar machen kann. Das Profil einer Aufgabe ist die Menge
der Schlüssel in `task_solutions.acceptance -> 'known_errors'`.

Die Faustregel aus dem Dokument:
- **Rang 1** aus dem breitesten Profil — der Aufgabe, die die meisten Fehlbilder
  sichtbar machen kann
- **Rang 2** aus einem *anderen* Profil. Zwei Aufgaben desselben Profils machen
  dieselben Denkfehler sichtbar; die zweite Sondierung ist dann verschenkt.
- Hat ein Skill nur ein Profil, ist die Wahl innerhalb des Skills gleichgültig —
  dann entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

**Nur Rang 1 und 2 werden vergeben.** Alles Weitere bleibt `NULL` und wird zufällig
gezogen. Eine vollständige Durchnummerierung ist ausdrücklich nicht gewollt.

Die Vorlage ist veraltet: sie rechnet mit 146 Fundament-Aufgaben, der Bestand liegt
inzwischen bei 245 freigegebenen (A18 hat 38 Geometrie-Aufgaben ergänzt, dazu
weitere). `scripts/content/sondierrang_vorschlag.py` deshalb zuerst neu laufen
lassen und mit dem aktuellen Stand arbeiten.

Betroffen sind ausschliesslich `source = 'edvance_fundament'` mit `status = 'ready'`.
VERA8-Aufgaben haben keinen `skill_key` und werden nie gezogen.

## Akzeptanz

- `docs/sondierrang_vorschlag.md` neu erzeugt und mitcommittet
- Je Skill genau eine Aufgabe mit `sondierrang = 1` und eine mit `sondierrang = 2`
- Kein Rang jenseits von 2
- Wo ein Skill mehrere Fehlbildprofile hat, stammen Rang 1 und 2 aus verschiedenen
- `supabase/checks/sondierrang.PRUEFUNG.sql` läuft durch (liegt bereits vor,
  nicht ändern)
- Ein Bericht `out/sondierrang-bericht.md`: je Skill die beiden gewählten Aufgaben
  mit ihrem Profil und einer Zeile, warum diese Kombination. Bei Skills mit nur
  einem Profil genügt der Hinweis darauf.

## Nicht-Ziele

- Keine Änderung an `supabase/checks/sondierrang.PRUEFUNG.sql`
- Keine Änderung an Aufgabentext, Status, Lösungen oder Skill-Zuordnung
- Keine Aufgaben anlegen oder löschen
- Kein `sondierrang` für VERA8 oder für `draft`-Aufgaben
- Keine Änderung an `lsa_select_next` oder am Auswahlverfahren
- Keine Ränge jenseits von 2, auch nicht „der Vollständigkeit halber"
