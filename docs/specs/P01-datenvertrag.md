# SPEC P01: Datenvertrag + LSA-Logik (Backend / Edvancev1)

**Ziel:** Das Backend so formen, dass die neue React-Native-App dagegen sprechen kann — und dass Lena die Aufgaben-Metadaten befüllen kann.

**Läuft parallel zum Frontend-Bootstrap.** Die Klammer zwischen beiden ist der `question_payload`-Vertrag in Abschnitt 1. Der muss zuerst stehen.

**Branch:** `feat/P01-datenvertrag` · **Base:** `dev`

---

## 0. Vorbedingungen

- `git branch --show-current` prüfen (muss `dev` sein vor dem Abzweigen)
- `ALLOW_MIGRATIONS=1` gesetzt (Schema-Zone)
- DB-Zugang über Session-Pooler-`DATABASE_URL` in `.env`
- pgTAP-Tests laufen (`supabase/tests/`)

Fehlt etwas: **abbrechen und melden**.

---

## 1. Der `question_payload`-Vertrag (das Herzstück)

Ein einheitlicher, diskriminierter Typ, den **jeder** Task-Typ erfüllt. Der Renderer im Frontend schaltet auf `kind`.

```ts
type QuestionPayload =
  | { kind: 'mc'; prompt: string; assets?: Asset[];
      options: { id: string; label: string }[] }
  | { kind: 'short_input'; prompt: string; assets?: Asset[];
      unit?: string }
  // Spätere Typen (Struktur schon vorsehen, noch nicht implementieren):
  // | { kind: 'cloze'; ... }
  // | { kind: 'multi_part'; parts: QuestionPayload[]; ... }

type Asset = { url: string; alt?: string };
```

### SICHERHEITSREGEL (nicht verhandelbar)
**Die Lösung darf niemals im `question_payload` landen.**

- Ans Frontend geht: `prompt`, `assets`, `options` (nur Labels!), `unit`
- Server-only bleibt: `correct_answers`, `solution`, `typical_errors`, `hints`

Hinweise werden **auf Anfrage einzeln** nachgeliefert (eigener RPC), nie im Voraus mitgeschickt. Sonst liest das Kind sie im Netzwerk-Tab.

**Implementierung:** Eine SQL-View oder RPC baut das Payload aus `tasks` und **lässt die Lösungsfelder weg**. Nicht im Frontend filtern — das ist keine Sicherheit.

---

## 2. Aufgaben-Metadaten (Lenas Felder)

Erweitere `tasks` (Migration) um die Felder, die Lena pro Aufgabe pflegt:

| Feld | Typ | Zweck |
|---|---|---|
| `content_type` | enum | existiert bereits (Diskriminator) |
| `competency_content` | text | inhaltliche Kompetenz (Inhaltsfeld) |
| `competency_process` | text | methodische Kompetenz (Prozesskompetenz) |
| `afb` | enum ('I','II','III') | Anforderungsbereich |
| `est_duration_sec` | int | geschätzte Bearbeitungsdauer |
| `correct_answers` | jsonb | **alle** akzeptierten Varianten, z. B. `["0,3 m", "30 cm", "0.3m"]` |
| `solution` | text | Musterlösung (nur Coach/Report) |
| `hints` | jsonb | gestufte Hinweise: `[{level:1, text:"..."}, ...]` |
| `coach_hints` | jsonb | bis zu 3 Zusatz-Hinweise, die der Coach live nachschicken kann |
| `typical_errors` | jsonb | typische Fehler + zugehörige sokratische Rückfragen (für den späteren Fehler-Dialog) |
| `dialog_enabled` | bool | ob der Fehler-Dialog bei dieser Aufgabe greift (nur wo der Rechenweg zählt) |

**Antwort-Normalisierung:** Beim Vergleich `correct_answers` gegen die Schülerantwort:
- Whitespace trimmen
- Komma/Punkt als Dezimaltrenner beide akzeptieren (`0,3` == `0.3`)
- Case-insensitiv
- Einheiten-Varianten kommen aus `correct_answers` (Lena pflegt sie explizit — **nicht** raten oder umrechnen!)

**Wichtig:** Keine automatische Einheiten-Umrechnung im Code. Wenn Lena „30 cm" als gültig hinterlegt, ist es gültig. Wenn nicht, nicht. Content ist die Wahrheit, nicht Code-Magie.

---

## 3. LSA-Logik (Screening)

Prüfe zuerst, was von `screening_items` / `screening_tests` / `deriveScreeningRecommendation` schon existiert und **wiederverwendbar** ist. Nichts doppelt bauen.

### RPCs (server-seitig, `SECURITY DEFINER` wo nötig)

**`lsa_start(student_id, grade, subject)`**
→ legt eine Session an, wählt Items aus dem Lena-freigegebenen Pool
→ Auswahl: nur Items mit `content_type IN ('mc','short_input')` und `status = 'ready'`
→ Zielumfang: ~20 Minuten (über `est_duration_sec` summieren)
→ Mischung über AFB I/II/III und Kompetenzfelder
→ returns: `session_id`, erstes Item als `question_payload`

**`lsa_submit(session_id, item_id, response)`**
→ **bewertet server-seitig** gegen `correct_answers` (mit Normalisierung aus §2)
→ speichert Antwort + Korrektheit + Bearbeitungsdauer
→ returns: nur `{ ok: true, next: question_payload | null }` — **kein** Richtig/Falsch ans Kind!
→ (Die LSA ist eine Diagnose, kein Übungsmodus. Das Kind bekommt kein Feedback.)

**`lsa_finish(session_id)`**
→ wertet aus: pro Kompetenz Trefferquote, Bearbeitungsdauern, AFB-Verteilung
→ erzeugt einen **Vorschlag** für den Lernhorizont
→ returns: strukturierte Auswertung für Coach/Eltern

### FernUSG-Leitplanke (in Code UND Tests festhalten)
- `lsa_finish` liefert einen **Vorschlag**, keine Zuweisung
- Der Lernpfad wird erst aktiv, wenn ein **Coach** ihn bestätigt (eigener Schritt, eigener Endpoint)
- Kein Pfad wird automatisch gesetzt. Kein `mastered` wird je automatisch gesetzt (das Gate existiert bereits — nicht anfassen).

---

## 4. RLS / Sicherheit

- Schüler sieht **nur seine eigene** Session und nur die aktuelle Frage (ohne Lösung)
- `correct_answers`, `solution`, `hints`, `typical_errors` sind für die `anon`/`authenticated`-Rolle **nicht** lesbar — nur über die RPCs, die sie server-seitig nutzen
- pgTAP-Test, der genau das beweist: „authenticated kann `tasks.correct_answers` nicht selektieren"

Das ist die wichtigste Sicherheitszusage. Wenn die Lösungen leakbar sind, ist die LSA wertlos.

---

## 5. Loses Ende zuerst abräumen

Der **Eltern-Report-Bugfix** steht noch aus (`fix_parent_report.sh`):
- `supabase/functions/generate_parent_report/index.ts` Zeile ~305: `streak_days` aus dem Select entfernen (Spalte existiert nicht mehr)
- Zeile ~327: `from('clusters')` → `from('skill_clusters')`
- Danach: `npx supabase functions deploy generate_parent_report`

Das ist ein Zweizeiler und blockiert sonst den Eltern-Report — „das Produkt, das Eltern kaufen".

---

## 6. Definition of Done

- [ ] Eltern-Report-Bugfix eingespielt und deployed
- [ ] Migration mit den Lena-Metadaten-Feldern (§2), `supabase db lint` sauber
- [ ] `question_payload`-Builder (View/RPC), der **beweisbar keine Lösung** ausliefert
- [ ] `lsa_start` / `lsa_submit` / `lsa_finish` implementiert
- [ ] pgTAP: (a) Lösungsfelder nicht lesbar für `authenticated`, (b) `lsa_finish` setzt keinen Pfad automatisch, (c) bestehende Mastery-Gate-Tests weiter grün
- [ ] `npx tsc --noEmit` grün, bestehende Tests grün
- [ ] `docs/api/DATENVERTRAG.md` — der Vertrag dokumentiert, damit das Frontend-Repo ihn kennt
- [ ] PR gegen `dev`

---

## 7. Explizit NICHT in diesem Lauf

Session-Schleife · Check-in-Logik · Fehler-Dialog (nur `typical_errors`-Feld anlegen, keine Logik) · Coach-Live-View · Multi-Part-Renderer · Handwriting/Foto · Avatar

Scope halten. Wenn eine Voraussetzung fehlt: **stoppen und melden**, nicht improvisieren.
