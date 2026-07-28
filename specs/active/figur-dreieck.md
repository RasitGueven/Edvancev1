---
id: figur-dreieck
type: code
repo: edvancev1
branch: spec/figur-dreieck
depends_on: []
gates:
  - python3 -m pytest scripts/figures/test_dreieck.py -q
  - python3 -c "import sys; sys.path.insert(0,'scripts/figures'); import dreieck, pruefe_dreieck"
  - bash -c 'test $(grep -c "^def pruefe_" scripts/figures/pruefe_dreieck.py) -ge 3'
  - bash -c 'grep -q "negativkontrolle\|Negativkontrolle" scripts/figures/test_dreieck.py'
  - bash tools/neuaufbau-test.sh
  - bash -c 'psql "$DBURL" -tAc "select pg_get_constraintdef(oid) from pg_constraint where conrelid = ''public.task_figures''::regclass and contype = ''c''" | grep -q "dreieck"'
---

## Ziel

Ein parametrischer SVG-Generator für **ein Dreieck**, nach dem Muster von
`scripts/figures/koordinatensystem.py`.

## Kontext

**Erst `koordinatensystem.py` und `pruefe_koordinatensystem.py` lesen.** Das Muster
steht dort vollständig; es wird übernommen, nicht neu erfunden.

Der Aufbau ist zweiteilig:

- **`scripts/figures/dreieck.py`** mit `zeichne(params: dict, theme: str) -> str`
- **`scripts/figures/pruefe_dreieck.py`** mit `pruefe(svg: str, params: dict) -> tuple[bool, str]`

`pruefe` ist der wichtigere Teil. Es **liest das erzeugte SVG zurück und misst nach** —
Koordinaten aus dem SVG parsen, gegen das rechnen, was die Parameter verlangen, und
Abweichungen als Befunde melden. `bestanden == True` nur bei leerer Befundliste.
`upload_figures.py` lädt nichts hoch, was `pruefe` nicht besteht.

Der Grund steht im Docstring der Vorlage: *„Ein falsches Bild ist schlimmer als kein
Bild. Bei Text fällt ein Fehler in der fachlichen Prüfung auf; einen Zahlendreher in
der Skalierung sieht niemand."*

Weiteres:

- `svg_basis.py` liefert Zahlformatierung, Escaping, Element-Bau. Importieren, nicht nachbauen.
- `tokens.py` ist die **einzige** Quelle für Farbwerte. Keine Hex-Codes im Generator.
- `pruefungen.py` enthält die gemeinsamen Eingabeprüfungen. Parameter werden **vor**
  dem Zeichnen geprüft. Unbekannte Schlüssel sind ein Fehler, kein stiller Verzicht —
  `'labl'` statt `'label'` würde sonst die Beschriftung verschlucken.
- `upload_figures.py` hat in `_lade_generator` eine Positivliste, die derzeit nur
  `koordinatensystem` kennt. Der neue Generator muss dort eingetragen werden.
  **Der Kommentar dort verweist auf eine „Positivliste in der Migration"** — prüfen,
  ob `task_figures.generator` einen CHECK trägt. Wenn ja, braucht es zusätzlich eine
  Migration nach dem üblichen Schema, und `tools/schema-snapshot.sh` muss neu laufen.
- Gerendert wird über react-native-svg: kein CSS, keine externen Schriften,
  kein `<foreignObject>`.
- **alt-Text:** wird nicht vom Generator erzeugt. `upload_figures.py` liest ihn aus
  `task_figures`; er wird beim Anlegen der Zeile gesetzt. `task_figures` trägt den
  CHECK `alt_text !~ '[0-9]'` — ein Screenreader, der die Masse vorliest, löst die
  Aufgabe. Nicht Teil dieser Spec.

## Geometrie

Grundseite waagerecht. Höhe als gestrichelte Linie mit rechtem Winkel zur Grundseite.
Bei `rechtwinklig` der rechte Winkel markiert. Masse aussen. Über 1:4 wird auf den
Bandrand gekappt; die gekappten Seiten tragen dann ein Zickzack, und der alt-Text sagt
es. Eine stille Stauchung wäre der Fehler, den niemand nachsieht.

## Was `pruefe` messen muss

- Massstäblichkeit: solange das Verhältnis innerhalb 1:4 liegt, entspricht
  Pixelhöhe/Pixelgrundseite dem Verhältnis hoehe/grundseite.
- Ist gekappt worden, existiert das Zickzack-Element — kein stilles Stauchen.
- Die Höhenlinie steht senkrecht auf der Grundseite (Skalarprodukt nahe null).
- Bei `rechtwinklig` sitzt das Winkelzeichen an der richtigen Ecke.

Dazu, wie im Vorbild: eine **Negativkontrolle** im Test. Ein absichtlich verfälschtes
SVG (eine Koordinate verschoben) muss von `pruefe` abgelehnt werden. Ohne sie ist
nicht belegt, dass die Prüfung überhaupt greifen kann.

## Akzeptanz

- `scripts/figures/dreieck.py` mit `zeichne(params, theme)`, Signatur wie im Vorbild
- Parameter: `grundseite: float`, `hoehe: float`, `art: str` (beliebig / rechtwinklig / gleichschenklig), `einheit: str`
- `scripts/figures/pruefe_dreieck.py` mit `pruefe(svg, params) -> (bestanden, meldung)`
  und mindestens drei `pruefe_*`-Einzelprüfungen
- Gültiges SVG mit fester `viewBox`, unabhängig von den Parameterwerten
- Gleiche Parameter → byteweise gleiches SVG, damit `svg_hash` trägt
- Ungültige Parameter lösen vor dem Zeichnen einen klaren Fehler aus
- `scripts/figures/test_dreieck.py`: gültige Parameter, Randwerte je Parameter,
  ungültige Parameter, Reproduzierbarkeit, beide Themes, **Negativkontrolle**
- In `upload_figures.py` in `_lade_generator` eingetragen
- **Migration**, die den CHECK auf `task_figures.generator` um `'dreieck'` erweitert.
  Die Historie ist append-only: neue Datei in `supabase/migrations/`, nicht die
  A19-Migration ändern. Danach `bash tools/schema-snapshot.sh` und
  `supabase/schema-erwartet.sql` mitcommitten.

## Nicht-Ziele

- **Keine TypeScript-Fassung.** `scripts/figures/rechteck.ts` und `svgBasis.ts` sind
  ein Irrläufer aus einer fehlerhaften Spec. Nicht als Vorlage nehmen, nicht erweitern.
- Keine Farbwerte ausserhalb von `tokens.py`
- Keine Änderung an `koordinatensystem.py`, `pruefe_koordinatensystem.py`,
  `svg_basis.py`, `tokens.py` oder `pruefungen.py`
- Keine Anbindung an konkrete Aufgaben
- Keine Interaktivität, keine Animation
