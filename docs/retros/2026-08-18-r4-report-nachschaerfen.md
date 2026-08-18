# R4 — Eltern-Report inhaltlich nachschärfen

**Datum:** 2026-08-18
**Branch:** `feature/r4-report-nachschaerfen` (von `dev`)
**Anlass:** Durchsicht der beiden echten Reports vom 16.08. — sie sind richtig
gerechnet, erzählten aber an mehreren Stellen etwas anderes, als die Zahlen
daneben hergaben.

Sitzungen:

| Sitzung | Kind | geprüft | trägt | Spur |
|---|---|---|---|---|
| `d8b0d885-b72d-4b68-a17b-6b35db301103` | Tolunay | 17 | 9 | 2/2 · 2/3 · 0/2 · 1/3 · 1/4 · 3/3 |
| `920d00ae-22ed-4eac-88a4-2f7ea719d45d` | Rasit | 20 | 16 | 2/2 · 2/3 · 1/2 · 1/2 · 3/4 · 5/5 · 2/2 |

---

## Was gebaut wurde

**Migration `20260818120000_r4_report_bausteine.sql` — nicht eingespielt.**
Zwei Tabellen nach dem `fehlbild_familien`-Muster (AF4):

- `report_bausteine` — 30 Sätze über fünf Slots, mit Abnahme-Schranke
  (`freigegeben_am`). Was nicht abgenommen ist, erreicht die Elternfläche nicht,
  auch nicht als Platzhalter.
- `report_anlass_zuordnung` — 3 Zeilen, Zuordnung `weak_topics` → Belege. Keine
  Abnahme-Schranke: dort stehen Schlüssel, keine Sätze.

**Neue Lib-Module** (rein, ohne Datenbank, testbar):

- `src/lib/report/fundament.ts` — Schichtung, Einstiegszustand, Einbruch-Ebene,
  tragende Sohle, Ebenen-Untertitel.
- `src/lib/report/rueckbezug.ts` — Zuordnung der Eltern-Einschätzung auf Belege.
- `src/lib/report/bausteine.ts` — Slot-/Fall-/Variantenwahl, Platzhalter,
  Ebenenbeschriftung.
- `src/lib/supabase/reportBausteine.ts` — der einzige Lesepfad, trägt den Filter
  auf `freigegeben_am`.

**Generator** `scripts/report/build-eltern-report.ts` (+ `reportHtml.ts`,
`reportCss.ts`, `sitzungSql.ts`) erzeugt die HTML-Entwürfe aus denselben
Funktionen wie die App.

---

## Entscheidungen, die im Prompt offen waren

### Der Einstieg trägt — vier Fälle statt einem

Abschnitt 02 sagte fest verdrahtet „Als sich zeigte, dass sie noch nicht sicher
sitzen…". Bei **beiden** Sitzungen trägt das Einstiegsthema (2 von 2), und
`gleichung_modellieren` steht einen Abschnitt weiter unter „Das trägt".

Dem Renderer fehlte der Begriff: Er kannte `Ltief`, nicht den Zustand des
Einstiegs. `sucheFall()` unterscheidet jetzt vier Fälle, je zwei Fassungen. Ein
fünfter Zustand kam beim Bauen dazu: **nichts unterhalb geprüft**. Er bekommt
keinen der vier Sätze, sondern gar keinen — jeder der vier würde etwas über ein
Fundament behaupten, das die Sitzung nicht angesehen hat.

### Rückbezug: Skills können entlasten, Fehlbilder nicht

Der schärfste Befund der Recherche: **Abwesenheit eines Fehlbilds beweist
nichts.** In Sitzung `920d00ae` tragen fünf falsche Antworten *null*
`fehlbild_slug`; dieselben Aufgaben liefern bei `d8b0d885` teils einen. Ein Slug
entsteht nur, wenn die gegebene Antwort auf ein katalogisiertes Muster passt.

Daraus die Asymmetrie in `report_anlass_zuordnung`:

- `skill_keys` → können bestätigen **und** entlasten
- `fehlbild_familien` → können **nur** bestätigen

„Rechenwege" hat keine Skills (die Skills heißen nach dem Verfahren, nicht nach
dessen Durchführung) und bekommt deshalb nie einen entlastenden Satz. In beiden
Reports fällt es still weg — richtig so.

### Die schmale Grundlage

`gleichung_modellieren` — der einzige Skill mit Sachkontext — wurde in beiden
Sitzungen mit **einer** Aufgabe geprüft (ein MULTI_PART-Item mit zwei
Teilaufgaben ist eine Aufgabe). Ein Freispruch auf einer Aufgabe ist keiner.

Statt den Rückbezug wegzulassen (dann hätte der Report auf die genannte Sorge
wieder nicht geantwortet) wechselt er unter zwei Aufgaben in eine Fassung, die
den Ausschnitt selbst benennt und auf die Nachprüfung verweist
(`MIN_BELEGE_ENTLASTUNG`, Fall-Suffix `_schmal`). Gegen die echten Sitzungen ist
das der Regelfall, nicht die Ausnahme.

### Beide Diagramme entfallen

- **Variante B** zeigte exakt die Zahlen der Ebenenspur — dieselben Daten,
  zweimal auf einer Seite. Von beiden ist die Spur die tragfähigere: Sie lässt
  sich beschriften, ein Balken nicht.
- **Variante A** (Radar) scheiterte an der Grundgesamtheit. Bei einer Mindestzahl
  von **drei** geprüften Skills je Achse bleibt übrig: `d8b0d885` **eine** Achse,
  `920d00ae` **zwei**. Ein Radar mit ein bis zwei Achsen ist keiner, und eine
  feste Achsenmenge mit vier ausgegrauten Achsen erzählt nichts, was die
  Skill-Listen nicht genauer sagen.

Die Ebenenspur ist damit die eine Grafik des Dokuments — und die einzige, deren
Nenner in jeder Zeile steht.

### A3 bleibt unberührt

Die A3-Invariante verbietet genau einen Pfad: `lead_assessments` darf
`lsa_start` nicht erreichen. Als Reveal-Metadatum beim Auswerten ist die
Einschätzung ausdrücklich vorgesehen — der Report zeigt `weakTopics` seit R1 an.
`report_anlass_zuordnung` wird nur gelesen, und erst nach Abschluss der Sitzung.

---

## Was sich als falsch erwiesen hat

**Die Sortierung des Aufklappbereichs war nicht kaputt.** Sie war bereits von
unten nach oben (`fundament_tiefe` aufsteigend) — nur sah man das nicht, weil
nichts die Ebenen markierte. Die Gruppierung je Ebene macht die Reihenfolge
sichtbar, statt sie zu behaupten. Kein Sortierfehler, ein Lesbarkeitsfehler.

---

## Offene Punkte

1. **Migration ist nicht eingespielt.** `scripts/db-migrate.sh
   supabase/migrations/20260818120000_r4_report_bausteine.sql` (braucht `DBURL`).
   Bis dahin stellt der Generator sie in einer Transaktion nach und rollt zurück.
2. **Die App rendert die neuen Bausteine noch nicht.** `ReportBody.tsx` ist
   unverändert; der Lesepfad (`reportBausteine.ts`) und die Logik stehen bereit.
   Der Umbau der React-Fläche gehört in einen eigenen PR, sonst wären es zwei
   Themen in einem Diff.
3. **`leads.leitthema` existiert nicht.** Ersatz ist `next_exam_topic`, und der
   Satz sagt entsprechend „steht als nächstes Thema an", nicht „fällt schwer".
4. **Drei `weak_topics` ohne Beleg:** Konzentration, Prüfungsangst,
   Zeiteinteilung. Weder Skill noch Fehlbild-Familie. Sie aus ausgelassenen
   Aufgaben abzuleiten wäre eine Verhaltensdeutung auf ein bis zwei Datenpunkten.
5. **Geschlecht des Kindes** ist nirgends gespeichert. Die Überschrift trägt
   jetzt den Vornamen, damit erübrigt sich „Sohn/Tochter" an dieser Stelle.
6. **Stray auf `feature/r3-report-gestaltung`:** Commit `cca635b` (8 Zeilen tote
   Druckregeln in `print.css`) ist nie in `dev` gelandet. Gehört nicht zu R4,
   sollte aber nachgezogen werden.

---

## Beweis

- `npm ci && npm run typecheck && npm run lint && npm test` — **351 Tests grün**
  (28 Dateien), darunter 46 neue für `fundament`/`rueckbezug`/`bausteine`.
- **INV-4.5** neu in `inv4-eltern-sprache.test.ts`: prüft alle 30 Bausteine der
  Migration auf Siezen, keine Note, keinen Kohortenvergleich, keine
  Erfolgszusage, keine Gamification, keine Klassenstufe an einer Ebene, keinen
  rohen Registry-Schlüssel und nur bekannte Platzhalter.
- `tools/schema-snapshot.sh` — 45 Migrationen, `schema-erwartet.sql` +86 Zeilen.
- Live-Datenbank **unverändert**: `to_regclass` auf beide neuen Tabellen liefert
  nach dem Generatorlauf `NULL`.
