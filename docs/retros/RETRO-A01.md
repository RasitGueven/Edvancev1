# RETRO A01 — Autoren-Tool für die Item-Pflege

**Datum:** 2026-07-14
**Branch:** `feat/A01-autorentool`
**Ziel:** ~185 Items von Hand prüfen und nachpflegen, statt sie neu zu schreiben.
Später entstehen hier auch die ~35 Fundament-Eigenbauten und die Kontextvarianten.

---

## 1. Was gebaut wurde

Ein internes Werkzeug in der bestehenden Admin-Oberfläche, `/admin/authoring`:

- **Liste** (`AuthoringItemsPage`) — Suche im Titel, Filter über Status, Fach,
  Kompetenz, AFB, Befunde, „hat Asset", „hat Tabelle"; Sortierung (offene Punkte
  zuerst ist der Default, weil das die Arbeit ist, die ansteht).
- **Editor** (`AuthoringEditorPage`) — Stamm (Markdown inkl. GFM-Tabellen und
  KaTeX), Teilaufgaben, Tags inkl. **Stoffanker**, Assets mit Alt-Text,
  Lösung/Hinweise/typische Fehler.
- **Vorschau** — live neben dem Editor, exakt die Whitelist, die
  `lsa_question_payload` ans Kind gibt.
- **Freigabe-Gate** — `draft → review → ready`, mit Prüfer und Zeitstempel.

Zugriff: Route für `coach` + `admin`. Schreiben kann nur `admin` — das ist keine
Design-Entscheidung des Tools, sondern die Realität von RLS `admin_write_tasks`
und `task_solution_upsert` (hart auf `get_my_role() = 'admin'`). Lena bekommt
deshalb `role = 'admin'` (Entscheidung Rasit, 14.07.); die RPC wird nicht
aufgeweicht.

## 2. Die drei Lücken — gemeldet, nicht eigenmächtig migriert

Der Auftrag sagte: fehlt ein Feld für den Stoffanker, dann melden und einen
Vorschlag machen. Es fehlten **drei** Dinge. Alle drei liegen als eine additive
Migration in **`docs/schema/A01-authoring.proposal.sql`** — bewusst *nicht* in
`supabase/migrations/`, weil eine nicht ausgeführte Datei dort bei einem
`supabase db push` still mitlaufen würde. „Nicht ausgeführt" soll man sehen.

### 2.1 Stoffanker (`tasks.curriculum_grade`)

`tasks.class_level` trägt den **Herkunfts**jahrgang — alle VERA-Items haben `8`,
weil der Test aus Klasse 8 stammt. Das ist nicht bloß ein fehlendes UI-Feld,
sondern ein **stiller Pool-Fehler**: `lsa_start` filtert über

```sql
coalesce(t.class_level, p_grade) <= p_grade
```

Die LSA liest `class_level` also bereits *semantisch* als Stoffanker. Solange dort
der Herkunftsjahrgang steht, ist „Berechne 20 % von 80 m" (Klasse-7-Stoff) für eine
Klasse-7-LSA unsichtbar. Deshalb eine **eigene Spalte** statt einer Umdeutung:
`class_level` bleibt die Provenienz, `curriculum_grade` wird die Didaktik.

**Nachlauf (eigener PR, bewusst nicht hier):** Sobald der Pool gepflegt ist, muss
der Filter auf `coalesce(t.curriculum_grade, t.class_level, p_grade)` umgestellt
werden. Nicht vorher — ein halb gepflegter Pool mischt sonst zwei Bedeutungen in
einer Abfrage. Das Gate erzwingt die Reihenfolge von selbst: ohne Stoffanker kommt
kein Item mehr auf `ready`.

### 2.2 Kein Lesepfad zu den Lösungen (`task_solution_get`)

`task_solutions` hat kein Grant für `authenticated` (P01 §4, Absicht). Geschrieben
wird über `task_solution_upsert` — **gelesen gar nicht.** Ein Pflege-Tool, das die
bestehende Lösung nicht anzeigen kann, kann sie nur blind überschreiben. Der
Vorschlag ist das symmetrische Gegenstück: `SECURITY DEFINER`, gegated auf
coach/admin. Die Sicherheitszusage bleibt; sie wird nur um die Rolle erweitert, für
die die Tabelle gedacht war.

### 2.3 Kein Freigabe-Audit (`reviewed_by` / `reviewed_at`)

`tasks.status` gibt es seit P01 und bleibt das einzige Statusfeld (kein zweites
erfunden). Was fehlte: wer wann freigegeben hat. Der Vorschlag stempelt
serverseitig in `task_status_set` aus `auth.uid()` — ein Client, der sich seinen
eigenen Prüfer einträgt, ist kein Audit. Dieselbe RPC prüft die Pflichtfelder noch
einmal in der DB (inkl. `lsa_has_answers`, damit Multi-Part *je Teilaufgabe* eine
Lösung braucht). Das Frontend-Gate ist die höfliche Version, die RPC die
verbindliche.

## 3. Degraded-Modus — das Tool läuft auch ohne die Migration

`probeAuthoringSchema()` fragt die DB, statt zu raten: Gibt es die Spalten? Gibt es
die RPCs? Fehlt etwas, blendet das Tool die betroffenen Felder aus und zeigt ein
Banner. Wichtig ist der Umkehrschluss, der im Code steht: solange
`curriculum_grade` nicht existiert, ist der fehlende Stoffanker **kein
blockierender Befund** — ein Gate, das eine Eingabe verlangt, die es nicht gibt,
wäre kaputt.

## 4. Entscheidungen, die Erklärung brauchen

- **Der Quellenbeleg kommt aus einer Datei, nicht aus der DB.** `_grounding` lebt in
  `data/vera8_komplett_enriched.json` (1,5 MB) und ist Read-Only-Kontext für den
  Pfleger, kein Produktivdatum — es gehört nicht in `tasks`.
  `scripts/build-grounding-index.ts` destilliert daraus
  `public/authoring/grounding-vera8.json` (600 KB, nach `source_ref` gekeyt), das
  der Editor **lazy fetcht** statt es ins Bundle zu backen. Join:
  `tasks.source_ref` → JSON-`id`.
- **Die Liste lädt keine Lösungen.** Das wären 185 RPC-Aufrufe. Sie zählt deshalb
  ausdrücklich nur *strukturelle* Befunde und filtert die lösungsbezogenen heraus —
  sonst stünde an jedem Item „keine Lösung", nur weil niemand nachgesehen hat. Ein
  Item mit „Vollständig" in der Liste kann im Editor trotzdem eine Lücke haben.
  Diese Ehrlichkeit ist mir lieber als ein Haken, der nichts bedeutet.
- **Speichern ist zweistufig.** Ein Item wohnt in zwei Tabellen ohne gemeinsame
  Transaktion: erst `tasks` (dort greifen die CHECKs), dann `task_solution_upsert`.
  Scheitert Schritt 2, sagt das Tool es. Ein „gespeichert", das die Lösung verloren
  hat, wäre die schlimmste Lüge, die dieses Werkzeug erzählen könnte.
- **Vorschau und Flags laufen über den ungespeicherten Entwurf**, nicht über den
  Server-Stand — sonst prüft der Pfleger gegen etwas, das er gerade geändert hat.
- **AFB/Kompetenz stehen bei Multi-Part an der Teilaufgabe**, nicht am Item (P02).
  Die Teilaufgabe ist der diagnostische Datenpunkt. Beides gleichzeitig zu verlangen
  wäre eine zweite, konkurrierende Wahrheit.

## 5. Gefundener Bug im geteilten Button (nicht gefixt)

`src/components/ui/button.tsx` rendert immer `{loading && <Spinner/>}{children}`.
Mit `asChild` sieht Radix' `Slot` darin **zwei** Kinder und wirft
`React.Children.only expected to receive a single React element child` — d. h.
`<Button asChild>` ist aktuell **immer** kaputt, nicht nur beim Laden. Gefunden vom
Smoke-Test der Liste.

Nicht hier gefixt: `src/components/ui/**` ist geteilter Baustein, und der Fix
(`asChild` → children direkt durchreichen) berührt jeden künftigen Aufrufer.
Umschifft mit `buttonVariants()` auf dem `<Link>` (shadcn-idiomatisch). **Offen für
das Foundation-Fenster**, siehe AUTONOMY_NOTES.

## 6. Verifikation

- `npm run typecheck` — grün
- `npm run lint` — grün (`--max-warnings=0`)
- `npm run test` — **85 Tests, 12 Dateien, grün**, davon neu:
  - `src/lib/authoring/flags.test.ts` (20) — die Pflichtfeld-Logik, inkl.
    Multi-Part („eine fehlende Teillösung blockiert"), Stoffanker-Sonderfall
    (Spalte fehlt ⇒ nicht blockierend), GFM-Tabellenerkennung.
  - `src/components/edvance/authoring/AuthoringPreview.test.tsx` (6) — **die
    Invariante:** jedes Geheimfeld (Lösung, Teillösung, Hinweise, Coach-Hinweise,
    typische Fehler) bekommt einen eindeutigen Marker, und der Test behauptet, dass
    keiner davon im DOM landet. Auch AFB/Kompetenz/Stoffanker nicht.
  - `src/pages/admin/AuthoringItemsPage.test.tsx` (6) — mountet, zählt, filtert,
    warnt bei fehlender Migration.
- `npm run build` — grün.
- **Nicht** gegen die Live-DB gefahren: kein Import, kein Deploy, keine Migration
  ausgeführt (wie beauftragt). Das Tool ist gegen die *heutige* DB im
  Degraded-Modus lauffähig; den vollen Funktionsumfang schaltet erst die Migration
  frei.

## 7. Offene Punkte

1. **Rasit:** `docs/schema/A01-authoring.proposal.sql` prüfen und ausführen; danach
   nach `supabase/migrations/` verschieben und in `schema.sql` dokumentieren
   (CLAUDE §10). Erst danach ist der Stoffanker speicherbar.
2. **Rasit:** Lena auf `role = 'admin'` setzen.
3. `lsa_start`-Filter auf `curriculum_grade` umstellen — **nach** der Pflege.
4. `Button asChild` fixen (siehe §5).
5. Die 86 MULTI_PART-Items sind noch nicht importiert (C07 hat nur gesichtet). Das
   Tool kann sie pflegen, sobald sie in `tasks` stehen.
