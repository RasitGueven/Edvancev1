# R5 — Profil zurück, Verteilung geprüft, jeder Elternpunkt beantwortet

**Datum:** 2026-08-18
**Branch:** `feature/r5-radar-und-bausteine` (von `dev`)
**Anlass:** Durchsicht der v2-Reports. Fünf Befunde, vier davon inhaltliche
Fehler im Text, einer eine Gestaltungsentscheidung, die zurückgenommen wurde.

---

## 1. Das Profil ist zurück, Variante B bleibt weg

R4 hatte beide Diagramme gestrichen. Für Variante B (Balken nach Tiefe) war das
richtig — sie zeigte exakt die Zahlen der Ebenenspur. Für Variante A nicht: Sie
ordnet nach **Thema**, die Spur nach **Tiefe**. Zwei Achsen, dieselben Urteile,
keine Dopplung. Und sie ist das Bild, auf das der Coach zeigt; sechs Zeilen Text
sind präzise, aber man zeigt nicht darauf.

Was sich gegenüber der alten Fassung geändert hat — die drei Gründe, an denen sie
gescheitert war:

- **Feste Achsenmenge.** Sechs Familien, immer dieselben. Vorher zeichnete das
  Diagramm nur die geprüften: fünf Achsen bei der einen Sitzung, sechs bei der
  anderen — dieselbe Form bedeutete zweimal etwas anderes.
- **Nicht geprüft ≠ nichts gekonnt.** Ungeprüfte Familien bekommen keinen
  Vertexpunkt, die Kanten dorthin sind gestrichelt, die Beschriftung sagt „nicht
  geprüft". Ein echter Anteil von 0 bekommt dagegen einen sichtbaren Punkt neben
  dem Mittelpunkt (`NULL_RADIUS`).
- **Der Nenner steht darunter.** „Brüche: 3 von 3 · … · Vorzeichen: nicht
  geprüft". Ohne diese Zeile verschweigt ein Anteilsdiagramm seine Grundlage.

Achsen unter zwei geprüften Skills tragen keine Fläche und heißen „zu wenig
geprüft" — eine volle Achse aus einem Skill liest sich wie eine Bestnote.

## 2. „Am deutlichsten zeigt es sich…" ist verstummt

Zwei Bedingungen, beide müssen halten: die Ebene trägt **mindestens drei**
geprüfte Bereiche, und ihr Anteil liegt **mindestens 0,25** unter dem der
nächstschlechteren tragfähigen Ebene.

Begründung für 0,25: Eine Ebene trägt drei bis fünf Bereiche, ein einzelner ist
dort 20–33 Prozentpunkte wert. Ein kleinerer Abstand lässt sich durch ein
einziges Skill-Urteil erzeugen — und genau ein Urteil ist das, was zwei Proben
danebenliegen können. Der Satz behauptet eine Rangordnung; sie muss größer sein
als die Unschärfe, aus der sie entsteht.

**Folge, die im PR ausdrücklich steht:** Der Satz entfällt in **beiden** echten
Sitzungen. Der Abstand beträgt dort jeweils 0,083.

## 3. Vier Richtungen statt zwei

Bis R5 fielen nicht belegbare Punkte still weg — bei einem Kind nannte Abschnitt
01 vier Punkte, der Schluss behandelte zwei. Ein unbeantworteter Punkt liest sich
wie ein stillschweigendes „unauffällig".

| Richtung | wann |
|---|---|
| `bestaetigend` | die Analyse hat den Punkt gefunden |
| `entlastend` | positive Skill-Evidenz spricht dagegen |
| `offen` | messbar, aber diese Sitzung gibt nichts her |
| `nicht_messbar` | eine LSA kann dazu grundsätzlich nichts sagen |

`offen` ist der Fall, den die Asymmetrie aus R4 erzwingt: Eine leere
Fehlbild-Familie beweist nichts, also darf sie nicht entlasten — aber sie darf
auch nicht zu Schweigen führen.

`report_anlass_zuordnung` ist damit die vollständige Registry aller sechs
`PARENT_WEAK_TOPICS`, nicht mehr eine Zuordnung für drei.

## 4. Fazit und Empfehlung zählen jetzt

Der Empfehlungstext sagte „Die Bereiche liegen dicht beieinander" — bei Lücken in
zwei Themenfamilien. Derselbe Fehlertyp wie zuvor bei „gebündelt in der
Geometrie": eine Aussage über die Verteilung, ohne sie zu prüfen. Der Text hing
allein am Paket.

Jetzt trägt der Fall die Zahl der betroffenen Familien (`keine` / `eine` /
`zwei` / `mehrere`), gezählt mit **derselben Taxonomie**, die das Profil daneben
zeichnet. Wer die Verteilung behauptet, muss sie mit dem Maßstab zählen, den das
Diagramm benutzt.

FAZIT und WARUM wandern dabei aus `scripts/report/paketTexte.ts` in
`report_bausteine` — der letzte Rest hartkodierter Elternsprache im Generator.

## 5. Die Aufzählung in Abschnitt 01

`weak_topics` mischt einen Teilsatz („Grundlagen fehlen") mit Substantiven. Neue
Spalte `anzeigename` glättet das („fehlende Grundlagen"), ohne den DB-Wert
anzufassen, an dem die Zuordnung hängt.

---

## Wo die Vorgabe und die Daten auseinandergingen

Der Auftrag zählte für ein Kind **drei** betroffene Familien („Maßstab ist
Größen, Fläche Dreieck ist Geometrie"). Die Achsenmenge desselben Auftrags führt
Geometrie und Größen aber als **eine** Familie. Unter der einheitlichen Taxonomie
sind es zwei.

Zwei Zählweisen nebeneinander wären der sichere Weg zurück in genau diesen
Fehler, deshalb: eine Taxonomie für Diagramm und Fazit. An der Sache ändert es
nichts — „dicht beieinander" war bei zwei Familien so falsch wie bei drei.

---

## Beweis

- `npm ci && typecheck && lint && test` — **369 Tests grün** (30 Dateien),
  darunter 9 neue für die Familien-Taxonomie und die überarbeiteten
  Einbruch-/Rückbezug-Suiten.
- **INV-4.5** deckt jetzt beide Baustein-Migrationen ab: **58 Sätze**, geprüft
  auf Siezen, Note, Kohortenvergleich, Erfolgszusage, Gamification,
  Klassenstufe, rohe Schlüssel, unbekannte Platzhalter — und neu auf
  Terminzahlen.
- `tools/schema-snapshot.sh`: +2 Spalten, sonst nichts.
- Live-Datenbank **unberührt**: 30 Bausteine, 3 Zuordnungen, keine
  `anzeigename`-Spalte. Die R5-Migration ist nicht eingespielt.

## Offen

1. **Migration einspielen:** `scripts/db-migrate.sh
   supabase/migrations/20260818160000_r5_bausteine_verteilung.sql`.
2. **`ReportBody.tsx` ist weiterhin unverändert** — die React-Fläche kennt weder
   Profil noch die vier Rückbezug-Richtungen.
3. **Lint-Altlast in `scripts/`**: 83 Fehler in `bildbedarf.mjs`, `c07/*.cjs`,
   `generate-assets.ts`, `mark-diagnostic.ts`. Liegt schon auf `dev`, `npm run
   lint` deckt nur `src`. Nicht Teil dieses PRs.
