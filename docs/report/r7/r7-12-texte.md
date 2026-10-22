# R7-12 · Texte neu (Entwürfe für Lena)

Stand 22.10.2026, Branch `feat/rasit-r7-12-lernweg-grenzen`. Bestehende Texte sind unverändert.
Seite 3 und Station 03 nehmen die Schlüssel aus `elternbericht` (Station 03 über `tb`), dazu kommt
ein neuer Schlüssel in `praesentation`.

## Neue Schlüssel

| Key | neu |
|---|---|
| `elternbericht:s3.weg.gekuerzt` | Nicht alle Bereiche passen auf diese Seite. Wie viele es je Themenfeld sind, steht auf Seite 2. |
| `elternbericht:s3.weg.weitere.erste_one` | + {{count}} weiterer {{stand}} |
| `elternbericht:s3.weg.weitere.erste_other` | + {{count}} weitere {{stand}} |
| `elternbericht:s3.weg.weitere.folge` | {{count}} {{stand}} |
| `elternbericht:s3.weg.weitere.trenner` | `, ` (Komma, Leerzeichen) |
| `elternbericht:s3.weg.weitere.stand.uebung` | mit Übungsbedarf |
| `elternbericht:s3.weg.weitere.stand.sicher` | sicher |
| `elternbericht:s3.weg.weitere.stand.offen` | noch nicht geprüft |
| `elternbericht:s3.weg.zusammen.zeile` | {{feld}}: {{teile}} |
| `elternbericht:s3.weg.zusammen.sicher` | {{count}} sicher |
| `elternbericht:s3.weg.zusammen.uebung` | {{count}} Übungsbedarf |
| `elternbericht:s3.weg.zusammen.trenner` | ` · ` (Mittelpunkt mit Leerzeichen) |
| `praesentation:s3.weg.info.weitere` | Weitere Bereiche: |

## So setzen sich die Zeilen zusammen

**„+ n weitere“** (letzte Zeile einer gekürzten Insel, kein Punkt, keine Linie): Die erste Gruppe ist
`erste`, jede weitere `folge`, getrennt mit `trenner`. Reihenfolge: Übungsbedarf, sicher, noch nicht
geprüft; nur Gruppen mit Zahl > 0.

- + 3 weitere mit Übungsbedarf, 2 sicher
- + 1 weiterer mit Übungsbedarf, 1 sicher, 1 noch nicht geprüft
- + 4 weitere sicher
- + 1 weiterer noch nicht geprüft

**Zählzeile** (eine je Themenfeld in einer zusammengefassten Zone, nur Zahlen > 0):

- Geometrie: 2 sicher · 7 Übungsbedarf
- Größen: 3 Übungsbedarf

**Infofeld in Station 03** nach Antippen von „+ n weitere“: fett „Weitere Bereiche:“, dahinter die
weggelassenen Bereiche als Aufzählung („A, B und C“, `Intl.ListFormat`).

**Fußnote Seite 3:** `gekuerzt` steht hinter dem bisherigen Hinweis, nur wenn Seite 3 ab Stufe 4 kürzt
(dann fehlen geprüfte Bereiche).

## Fragen an Lena
- „+ 4 weitere sicher“ und „+ 1 weiterer noch nicht geprüft“ lesen sich holprig. Der Bauauftrag nennt nur
  „+ n weitere“ und das Beispiel mit Übungsbedarf. Ein Vorschlag wäre z. B. „+ 4 weitere, sicher“.
- `erste_one` sagt „weiterer“ (der Bereich). Passt das, oder lieber immer „weitere“?
