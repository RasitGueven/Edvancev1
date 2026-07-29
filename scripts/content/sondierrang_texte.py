"""Textbausteine fuer scripts/content/sondierrang_vorschlag.py.

Nur Vorlagen, keine Logik — hier ausgelagert, damit der Erzeuger unter der
400-Zeilen-Grenze aus CLAUDE.md bleibt. Die @PLATZHALTER@ setzt der Erzeuger.
"""

KOPF = """# Sondierrang — Entscheidungsvorlage

**Erzeugt von `scripts/content/sondierrang_vorschlag.py`. Nicht von Hand pflegen.**

`tasks.sondierrang` steht in der Datenbank **überall auf `NULL`**. Diese Datei
setzt keinen Rang — sie ist die Liste, aus der Rasit und Lena Rang 1 und 2 je
Skill wählen. Der maschinelle Vorschlag ist als Rang **1** / **2** markiert; die
Begründung je Skill steht in `out/sondierrang-bericht.md`, die zugehörigen
`UPDATE`s in `scripts/sql/sondierrang_setzen.sql`.

Grundlage: **@AUFGABEN@ freigegebene Fundament-Aufgaben** (`source =
'edvance_fundament'`, `status = 'ready'`) über **@SKILLS@ Skills**.

## Warum nicht „kontextfrei zuerst"

Der ursprüngliche Auftrag wollte die Aufgaben nach „kontextfrei zuerst"
sortiert. Das trennt die Fundament-Aufgaben kaum — die meisten sind nackte
Rechnungen, und eine Sortierung danach würde eine Auswahl vortäuschen, die
keine ist.

Was unterscheidet, ist das **Fehlbildprofil**: welche Denkfehler eine Aufgabe
überhaupt sichtbar machen kann. Rang 1 und 2 sollen sich darin unterscheiden.
Die Aufgaben stehen deshalb nach Profil gebündelt.

## Wie man das liest

Je Skill sind die Aufgaben nach ihrem Fehlbildprofil gruppiert. Zwei Aufgaben im
selben Profil machen dieselben Denkfehler sichtbar — sie als Rang 1 und 2 zu
wählen verschenkt die zweite Sondierung.

**Faustregel:** Rang 1 aus dem breitesten Profil (die meisten Fehlbilder, steht
oben), Rang 2 aus einem *anderen* Profil.

Wo ein Skill nur ein einziges Profil hat, entscheidet die Zahlenwahl. Innerhalb
eines Profils stehen die Aufgaben nach der Summe ihrer Zahlen — kleinere zuerst.

**Nur Rang 1 und 2.** Alles Weitere bleibt `NULL` und wird von `lsa_select_next`
zufällig gezogen. Eine vollständige Durchnummerierung ist nicht gewollt.
"""

FUSS = """
---

## Offen

**Ohne `known_errors`:** die vier Term-Gruppen (`term_zusammenfassen`,
`term_ausmultiplizieren`, `term_ausklammern`, `term_minusklammer`). Ihre
Fehlbilder sind berechnet und dokumentiert (im Kopf von
`supabase/seeds/20260722_term_fundament_01.sql`), aber **nicht als Daten
speicherbar**: `known_errors` lebt in `acceptance`, und `acceptance` mit
`canonical` kippt bei Termen die Bewertung. Der Weg dorthin steht in
`AUTONOMY_NOTES.md` (Eintrag 3).

Bis dahin lässt sich der Sondierrang für diese vier Skills nicht nach Profil
wählen — nur nach der Zahlenwahl.
"""

SQL_KOPF = """-- sondierrang_setzen.sql
--
-- Setzt tasks.sondierrang auf 1 und 2 — je @SKILLS@ Skills genau eine Aufgabe je
-- Rang, @N@ Anweisungen. Alles Weitere bleibt NULL und wird zufaellig gezogen.
--
-- Erzeugt von scripts/content/sondierrang_vorschlag.py. Die Begruendung je
-- Skill steht in out/sondierrang-bericht.md — vor dem scharfen Lauf lesen.
--
-- Keine Transaktionsklammer hier; die setzt der Aufrufer.
-- Idempotent: 'sondierrang is distinct from N' laesst den zweiten Lauf leer.
-- source/status stehen in jedem where mit, damit die Anweisung auch dann noch
-- das Richtige trifft, wenn eine Aufgabe inzwischen zurueckgezogen wurde.
--
-- Probelauf (schreibt nicht):
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_probelauf.sql
-- Scharf:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_setzen.sql
"""

BERICHT_KOPF = """# Sondierrang — Bericht zur Auswahl

**Erzeugt von `scripts/content/sondierrang_vorschlag.py`. Nicht von Hand pflegen.**

Vorschlag für `tasks.sondierrang` über **@AUFGABEN@ freigegebene
Fundament-Aufgaben** in **@SKILLS@ Skills**: je Skill eine Aufgabe auf Rang 1
und eine auf Rang 2, zusammen **@N@ `UPDATE`s** in
`scripts/sql/sondierrang_setzen.sql`. Alles Weitere bleibt `NULL`.

Das hier ist das Dokument, an dem das fachliche Urteil einsteigt. Der Agent hat
**nichts in die Datenbank geschrieben**; der Probelauf
(`scripts/sql/sondierrang_probelauf.sql`) setzt und verwirft wieder.

## Das Verfahren

Rang 1 kommt aus dem **breitesten Fehlbildprofil** — der Aufgabe, die die
meisten Denkfehler sichtbar machen kann. Rang 2 aus einem *anderen* Profil, denn
zwei Aufgaben desselben Profils zeigen dieselben Denkfehler; die zweite
Sondierung wäre verschenkt. Hat ein Skill nur ein Profil, entscheidet die
Zahlenwahl — kleinere Zahlen zuerst, gemessen als Summe der Zahlen im Fragetext.

Unter den übrigen Profilen wird für Rang 2 dasjenige gewählt, das **am meisten
Neues** beiträgt — nicht einfach das zweitbreiteste. Ein Profil, das ganz in
Rang 1 enthalten ist, zeigt nichts, was Rang 1 nicht schon zeigt.

## Überblick — was die zweite Sondierung einbringt

| | Skills |
|---|---|
| Rang 2 zeigt zusätzliche Fehlbilder | @NEU@ |
| Rang 2 ist Teilmenge von Rang 1 — nichts Neues | @TEILMENGE@ |
| nur ein Fehlbildprofil, Auswahl über die Zahlen | @EINZELN@ |

Bei **@TEILMENGE@ Skills** ist das breiteste Profil eine Obermenge aller
übrigen: @TEILMENGE_LISTE@. Dort *kann* keine zweite Aufgabe ein neues Fehlbild
beitragen — das liegt am Bestand, nicht an der Auswahl. Wenn die zweite
Sondierung dort etwas zeigen soll, müssten die `known_errors` dieser Skills
ergänzt werden; das ist ein inhaltlicher Auftrag, kein technischer.

## Ein Befund, der die Durchsicht betrifft

Die Spec beschreibt das Fehlbildprofil als „die Menge der **Schlüssel** in
`task_solutions.acceptance -> 'known_errors'`". Die Daten sagen etwas anderes.
`known_errors` ist ein Objekt `{"<falsche Antwort>": "<Fehlbild>"}`:

```json
{"3/7": "nenner_addiert", "11/7": "nenner_addiert_zaehler_ok", "3/12": "zaehler_nicht_erweitert"}
```

Die **Schlüssel** sind die konkreten falschen Antworten. Sie hängen an den
Zahlen der jeweiligen Aufgabe und sind deshalb fast überall verschieden — nach
Schlüsseln gruppiert hätten 245 Aufgaben 231 „Profile", also praktisch je eines
pro Aufgabe. Das Kriterium könnte dann nichts bündeln, und „Rang 2 aus einem
anderen Profil" wäre für jedes beliebige Paar erfüllt.

Die **Werte** sind die Fehlbilder. Nach ihnen gruppiert hat jeder Skill ein bis
vier Profile — das ist die Achse, die die Spec inhaltlich meint („welche
Denkfehler eine Aufgabe sichtbar machen kann").

**Gewählt wurde nach den Werten.** `supabase/checks/sondierrang.PRUEFUNG.sql`
prüft in P4 nach Schlüsseln und bleibt unverändert; die Auswahl erzwingt
zusätzlich verschiedene Schlüsselprofile, wo ein Skill mehr als eines hat. Beide
Lesarten sind damit erfüllt. Sollte die Schlüssel-Lesart die gemeinte sein, ist
die Auswahl trotzdem gültig — nur die Begründungen unten wären dann hinfällig.

Zwei weitere Punkte fürs Protokoll:

- Die Spec spricht von „245 `UPDATE`s". Es sind **@N@** — 245 ist der Bestand,
  gesetzt werden nur Rang 1 und 2 je Skill. Eine vollständige Durchnummerierung
  schließen die Nicht-Ziele ausdrücklich aus, und P3 der Prüfung würde sie
  ablehnen.
- Die Vorlage trägt **kein Erzeugungsdatum** — weder vorher noch jetzt. Der
  befürchtete Datums-Lärm tritt hier nicht auf.

---
"""

