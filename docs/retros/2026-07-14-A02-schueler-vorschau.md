# A02 — Schüler-Vorschau im Autoren-Tool: eine Wahrheit, nicht zwei

**Datum:** 2026-07-14
**Branch:** `feat/A02-schueler-vorschau`
**Migration:** `supabase/migrations/20260714150000_a02_vorschau.sql` (**noch nicht
ausgeführt** — Schema-Session mit Rasit)

## Was gebaut wurde

Der Pfleger sieht neben dem Editor, wie die Aufgabe auf dem Schüler-Tablet
aussieht: Stamm, Bild (mit Alt-Text), Tabelle (F01), Multi-Part (P02: Stamm oben,
Teilaufgaben darunter, **ein** Weiter-Button), MC-Optionen, Kurzantwort mit
Einheit. Nicht interaktiv — die Vorschau zeigt, sie bewertet nicht.

## Die eine Entscheidung, um die es ging

Es gab schon eine Vorschau (`AuthoringPreview`). Sie baute den Payload **im
Frontend aus dem `FormState` nach**. Damit zeigte sie, was der *Editor* denkt —
nicht, was das *Kind* sieht. Der Beweis lag im Repo: F01 hat die Aufgaben-Tabelle
in `lsa_question_payload` eingebaut, und die alte Vorschau hat sie **nie**
gerendert. Sie ist still divergiert, monatelang unbemerkt, ohne dass irgendetwas
rot wurde. Genau so verliert man eine Invariante: nicht mit einem Bug, sondern mit
einer zweiten Implementierung derselben Zusage.

Also: **kein Nachbau**. Neue RPC `task_preview_payload(p_task_id, p_draft)` ruft
intern `public.lsa_question_payload(p_task_id)` auf. Nicht „dieselbe Logik",
nicht „dieselbe Whitelist" — **dieselbe Funktion**. `lsa_question_payload` wurde
nicht angefasst. Die pgTAP-Assertion dazu ist eine *Gleichheit*, keine Feldliste:

```sql
select is(
  public.task_preview_payload(:'t_mp'),
  public.lsa_question_payload(:'t_mp'),
  'Die Vorschau IST lsa_question_payload — Byte fuer Byte dasselbe Payload'
);
```

Eine Feldliste hätte F01 wieder durchgewinkt. Diese Assertion bricht.

## Der harte Teil: der ungespeicherte Entwurf

Die Vorschau soll live sein — der Pfleger tippt am Stamm und sieht das Ergebnis.
Der Stand liegt aber im Formular, nicht in der DB. Zwei Wege:

- **(a) den Entwurf im Frontend bauen** → die zweite Wahrheit kommt durch die
  Hintertür zurück, nur diesmal „bloß für Ungespeichertes". Verworfen.
- **(b) den Entwurf serverseitig einspielen, den echten Builder fragen,
  zurückrollen.** Gewählt.

`p_draft` wird in einer PL/pgSQL-Subtransaktion auf die Zeile gespielt,
`lsa_question_payload` baut daraus, und ein `raise ... errcode = 'ED001'` rollt die
Subtransaktion zurück. Die PL/pgSQL-**Variable** überlebt den Abbruch (Variablen
sind Speicher, keine Zeilen — Postgres garantiert das ausdrücklich), die
Zeilenänderung nicht. Übernommen werden nur die sechs Spalten, die der Builder
überhaupt liest: `question`, `input_type`, `unit`, `parts`, `assets`,
`question_payload`.

Das ist ein ungewöhnliches Konstrukt, und es verdient Misstrauen. Deshalb ist der
Rollback nicht kommentiert, sondern **getestet**: nach einem Entwurfs-Aufruf ist
die `tasks`-Zeile nachweislich unverändert. Ohne diese Assertion wäre die Vorschau
ein stiller Schreibpfad.

**Nebenwirkung mit Ansage:** Die CHECKs auf `tasks` feuern auf dem Entwurf mit. Ein
Entwurf, der nicht speicherbar *wäre*, ist damit auch nicht vorschaubar (23514).
Das ist die ehrlichere Antwort als eine Vorschau, die etwas zeigt, das nie
gespeichert werden könnte.

## Härtung

- `security definer`, `set search_path = public`
- Rollen-Check im Body: nur `coach`/`admin` (errcode 42501) — `lsa_question_payload`
  selbst hat **kein** Gate (es läuft in der LSA hinter `lsa_may_act_for`); einzeln
  aufrufbar braucht es eins.
- `revoke execute … from public` → `grant … to authenticated, service_role`
- Das Gate sitzt **vor beiden Pfaden**. Wäre nur der Lesepfad gegatet, hätten wir
  dem Schüler über die Vorschau ein `UPDATE` auf `tasks` geschenkt. Eigene
  Assertion.

## Beweis — `supabase/tests/inv8_vorschau_ohne_loesung.test.sql` (16 Assertions)

- Schüler-Kontext → `permission denied` (Lese- **und** Entwurfspfad)
- `anon` hat nicht einmal das Execute-Grant
- Identität mit `lsa_question_payload` (s.o.)
- **Rekursiv keine Lösung:** `pg_temp.all_keys()` steigt in jedes Objekt und jedes
  Array hinab — auch in `parts[]` und `table` — und sucht nach Lösungsschlüsseln.
  Eine Assertion gegen die oberste Ebene hätte eine Teilaufgabe mit Lösung
  durchgewunken. Der Sentinel liegt dabei (wie in inv5) als `accepted` **direkt
  neben der Tabelle im selben `question_payload`** — die Nachbarschaft, aus der
  nichts durchsickern darf.
- **Anti-Vakuum:** eine Assertion pinnt fest, dass der Payload überhaupt Stamm,
  Bild, Tabelle und beide Teilaufgaben *trägt*. Sonst wäre „keine Lösung drin"
  trivial wahr, sobald der Builder eines Tages nichts mehr ausliefert.
- Entwurfspfad: Stamm/Einheit/Typwechsel werden gezeigt, die Zeile bleibt
  unverändert, die Whitelist greift auch hier (afb/competency einer Teilaufgabe
  kommen nicht mit).

Lauf: `npx supabase test db` → **8 Dateien, 110 Assertions, alle grün** (lokal
gegen `supabase start` verifiziert, kein Deploy).
Frontend: `npx tsc --noEmit` sauber, `npm run lint` sauber, `npm run test` 91/91.

## Frontend

- `src/lib/supabase/taskPreview.ts` — holt das Payload. Baut keins. **Kein
  Fallback:** fehlt die RPC, sagt die Vorschau das (`rpcMissing`) — ein
  Client-Notnagel wäre exakt die zweite Wahrheit, die A02 abschafft.
- `src/types/preview.ts` — der Payload-Vertrag. Die Lösung ist hier nicht
  „weggelassen"; sie kam in diesem Vertrag nie vor.
- `PreviewStage.tsx` — das Tablet: dieselben Bausteine wie der echte
  `TaskPlayer` (`MathContent`, `AssetList`), dunkle Bühne, solide Karten. Die
  F01-Tabelle bekommt exakt die Klassen, die `MathContent` einer Markdown-Tabelle
  gibt — beide Wege sehen für das Kind gleich aus.
- `AuthoringPreview.tsx` — Shell: 400 ms Debounce, Sequenz-Guard gegen überholende
  Antworten, letzter Payload bleibt beim Aktualisieren stehen (kein Flackern).
  Zwei Stände, sichtbar unterschieden: **„Gespeicherter Stand"** vs.
  **„Ungespeichert"**. Niemand soll einen Entwurf für den echten Payload halten.
- `.preview-stage` (session.css): `.session-stage` ließ sich **nicht**
  wiederverwenden — sein Basis-Gradient ist `background-attachment: fixed`, seine
  Texturebene `position: fixed`; beide beziehen sich auf den Viewport und hätten
  das Admin-Fenster hinter dem Panel eingefärbt. Gleiche Tokens, lokal gebunden.

## Offene Punkte

1. **Blockiert auf Rasit:** Migration `20260714150000_a02_vorschau.sql` im SQL-Editor
   ausführen. Bis dahin läuft das Tool im Degraded-Modus (Vorschau zeigt den
   `rpcMissing`-Hinweis statt eines Payloads) — es bricht nicht.
2. **`design-reference/Edvance-Prototyp.dc.html` existiert im Repo nicht.** Die
   Optik folgt deshalb dem echten Schüler-Player (`src/pages/student/TaskPlayer.tsx`)
   + Stage-Tokens. Falls der Prototyp doch existiert, sollte die Vorschau gegen ihn
   abgeglichen werden.
3. **Der Schüler-Player rendert `parts` und `table` bis heute nicht.** Die Vorschau
   ist damit der *erste* Renderer des Payload-Vertrags — sie zeigt, was das Kind
   sehen *wird*, sobald `TaskPlayer` auf `lsa_question_payload` umgestellt ist. Das
   ist die nächste ehrliche Lücke: aktuell liest `TaskPlayer` die `tasks`-Zeile
   direkt, nicht das Payload. Solange das so ist, gibt es die zwei Wahrheiten
   weiterhin — nur an einer anderen Stelle.
