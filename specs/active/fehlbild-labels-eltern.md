---
id: fehlbild-labels-eltern
type: content
repo: edvancev1
branch: spec/fehlbild-labels-eltern
depends_on: []
gates:
  - bash tools/neuaufbau-test.sh
  - psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/fehlbild_labels_eltern.PRUEFUNG.sql
---

## Ziel

Zu jedem Fehlbild eine Fassung in Elternsprache, damit der LSA-Report einen Denkfehler benennen kann, ohne Fachsprache zu benutzen.

Die Auswertung (AF2) liefert Slugs wie `nenner_addiert`. Im Elternreport steht der Satz:

> In {n} Aufgaben aus {Thema A} und {Thema B} zeigt sich derselbe Denkfehler: **{Label}**.

Was in diese Lücke gehört, gibt es noch nicht. Solange es fehlt, ist der Report nicht schreibbar — das ist der letzte Blocker vor dem Produkt.

**Der Agent schlägt vor, Lena entscheidet.** Ergebnis sind eine Migration und ein Bericht, keine Änderung in Produktion.

## Kontext

- `fehlbild_labels` (A20) hat `slug`, `klartext`, `erklaerung`. Diese Felder sind Coach-Sprache und **bleiben unverändert** — der Coach braucht die fachliche Benennung.
- `known_errors` in `task_solutions.acceptance` bildet ab: `{"<falsche Antwort>": "<slug>"}`. Die **Werte** sind die Slugs, die Schlüssel sind zahlenabhängige Falschantworten. (Beim sondierrang-Lauf am 29.07. war das eine falsche Annahme in der Spec — hier nicht wiederholen.)
- Die Registry ist mit 21 Slugs geseedet.

**Weicht die Wirklichkeit von diesem Kontext ab — Widerspruch benennen und stoppen, nicht überbrücken.**

## Schritt 1 — Bedeutung aus den Daten holen, nicht aus dem Namen

Für jeden Slug: die Aufgaben finden, in deren `known_errors` er als Wert vorkommt. Je Slug mindestens zwei Beispiele sammeln, mit Aufgabentext, richtiger Lösung und der Falschantwort, die den Slug auslöst.

**Daraus ableiten, was das Kind tatsächlich getan hat.** Der Slug-Name ist ein Hinweis, kein Beleg: `nenner_addiert` klingt eindeutig, aber ob die Falschantworten das wirklich hergeben, zeigt erst die Rechnung.

Widerspricht ein Beispiel dem Namen, ist das ein Befund für Lena und gehört in den Bericht — nicht stillschweigend geglättet.

### Zwei Lücken, die dabei auffallen werden

- **Slugs ohne Aufgabe.** Steht in der Registry, kommt in keinem `known_errors` vor — kann nie ausgelöst werden. Elterntext dafür ist verschwendet; im Bericht listen, aber trotzdem verfassen (die Aufgabe kann nachkommen).
- **Slugs ohne Registry-Eintrag.** Kommt in `known_errors` vor, fehlt in `fehlbild_labels`. Diese erscheinen in der Auswertung mit `klartext is null` — im Report also als Leerstelle. **Auflisten, aber nicht selbst ergänzen**: Ein Fehlbild zu benennen, das niemand definiert hat, ist Lenas Entscheidung.

## Schritt 2 — Die Texte

Migration, die zwei Spalten ergänzt und füllt:

| Spalte | Inhalt |
|---|---|
| `eltern_kurz` | Nominalphrase für die Satzlücke oben. Kein ganzer Satz, kein Punkt am Ende. |
| `eltern_lang` | Ein bis zwei Sätze: was das Kind tut, und dass es auflösbar ist. |

**Beispiel für die Form** (nicht für den Inhalt — der kommt aus den Daten):

> `eltern_kurz`: „Nenner werden mitaddiert"
> `eltern_lang`: „Beim Zusammenzählen von Brüchen wird auch die untere Zahl addiert. Das ist ein sehr verbreiteter Schritt — er zeigt, dass die Regel angewendet wird, nur die falsche."

### Regeln für die Sprache

Diese Sätze werden von Eltern über ihr eigenes Kind gelesen, meist in einer Situation, in der sie sich ohnehin Sorgen machen.

- **Der Fehler ist eine Handlung, keine Eigenschaft.** „rechnet X" statt „kann X nicht", nie „Schwäche", „Defizit", „Problem".
- **Kein Fachjargon.** Kein „Hauptnenner", „Term", „Koeffizient", „Distributivgesetz" ohne Umschreibung. Massstab: eine Mutter ohne Mathe-Leistungskurs.
- **Nichts über das Kind als Person.** Keine Aussage über Fleiss, Konzentration, Begabung — das misst die LSA nicht, jeder solche Satz wäre erfunden.
- **`eltern_lang` endet auflösbar**, ohne Versprechen. „lässt sich gezielt auflösen" ja; „ist schnell behoben" nein.
- **Keine Wertung der Häufigkeit erfinden.** „verbreitet" nur, wo es stimmt.
- `eltern_kurz` höchstens 6 Wörter, `eltern_lang` höchstens 40.

## Schritt 3 — Prüfskript

`supabase/checks/fehlbild_labels_eltern.PRUEFUNG.sql`, ohne Zeitstempel im Namen, in `begin; … rollback;`.

| # | Prüfung |
|---|---|
| L1 | jede Zeile in `fehlbild_labels` hat `eltern_kurz` und `eltern_lang`, beide nicht leer |
| L2 | `eltern_kurz` ≤ 6 Wörter, endet nicht auf `.` |
| L3 | `eltern_lang` ≤ 40 Wörter |
| L4 | keiner der Texte enthält `Schwäche`, `Defizit`, `kann nicht`, `Problem` (case-insensitiv) |
| L5 | `klartext` und `erklaerung` unverändert gegenüber A20 |

L5 ist die Negativkontrolle: Sie schlägt an, wenn der Lauf die Coach-Sprache überschrieben hat statt zu ergänzen.

## Akzeptanz

- Migration in `supabase/migrations/` nach dem üblichen Schema, **nicht eingespielt**
- `bash tools/schema-snapshot.sh` gelaufen, `schema-erwartet.sql` mitcommittet
- Alle Slugs der Registry haben beide Felder
- `docs/fehlbild-labels-bericht.md`, je Slug: technischer `klartext`, **zwei Beispiele mit Aufgabentext, richtiger und falscher Antwort**, dann die beiden Vorschläge

Der Bericht ist das Arbeitsdokument. Lena muss neben jedem Vorschlag sehen können, worauf er sich stützt — sonst prüft sie Prosa statt Mathematik.

## Nicht-Ziele

- Keine Änderung an `klartext` oder `erklaerung`
- Keine neuen Slugs, auch nicht für die in `known_errors` gefundenen ohne Registry-Eintrag
- Keine Änderung an `known_errors`, an Aufgaben oder an AF2
- Kein Einspielen in Produktion
- Keine Reporttexte ausserhalb der beiden Spalten — die Bausteine ringsum sind eine eigene Sache
- Kein `src/lib/**`

## Nach dem Lauf (Lena)

`docs/fehlbild-labels-bericht.md` durchsehen: Beschreibt der Text, was die Beispiele zeigen? Danach einspielen:

```bash
bash scripts/db-migrate.sh
```
