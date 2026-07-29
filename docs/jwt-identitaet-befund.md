# JWT-Identität in den Prüfskripten — Befund

Datum: 2026-07-29
Spec: `specs/active/jwt-claim-stub.md`
Datenbank: `postgresql:///edvance_neuaufbau` (lokal, frisch aus `tools/neuaufbau-test.sh`)

## Kurzfassung

Der Verdacht hat sich bestätigt. Der `auth.uid()`-Stub las ausschließlich
`request.jwt.claim.sub` (Einzahl). A17, A16, A20 und A21 setzen
`request.jwt.claims` (Mehrzahl, JSON). Diese Form kam nie an — `auth.uid()`
blieb in allen vier Skripten `null`.

Der Stub wurde repariert (beide Formen, Einzahl hat Vorrang). Danach läuft A17
zum ersten Mal seit der Herauslösung am 23.07. vollständig durch: **alle 14
Prüfungen bestanden**. Es wurde nichts rot.

---

## Schritt 1 — Messung vor jeder Änderung

Gemessen gegen `edvance_neuaufbau` mit dem damaligen Stub. Beobachtete Werte:

| # | gesetzt | `auth.uid()` |
|---|---|---|
| M1 | `request.jwt.claim.sub = 1111…1111` | `1111…1111` |
| M2 | `request.jwt.claims = {"sub":"2222…2222"}` | **`NULL`** |
| M3 | beide, verschiedene Werte | `1111…1111` (Einzahl) |
| M4 | nichts | `NULL` |

M2 ist der Befund: Die Mehrzahlform erreichte `auth.uid()` nicht.

### In A17 selbst

Unmittelbar nach dem ersten `set_config` in Zeile 36 (Nachbau des A17-Blocks):

```
A17 auth.uid()        = <NULL>
A17 get_my_role()     = <NULL>
A17 lsa_may_act_for() = <NULL>
```

### Was eine NULL-Identität mit den Torwächtern macht

Direkt gemessen, ohne gesetzte Identität (exakt der Zustand, in dem A17 lief):

```
auth.uid()                    = <NULL>
get_my_role()                 = <NULL>
get_my_role() <> 'admin'      = <NULL>      -> if-Zweig feuert NICHT
lsa_may_act_for()             = <NULL>
not lsa_may_act_for()         = <NULL>      -> if-Zweig feuert NICHT

lead_lsa_freigeben ohne Admin = DURCHGELASSEN (Session wurde angelegt)
lsa_start ohne Berechtigung   = DURCHGELASSEN
platz_next ohne Identität     = abgewiesen ("platz_next: kein Platz-Konto")
```

Damit zerfallen A17s RPCs in zwei Gruppen:

- **Still durchgelassen** — alles, was mit `if not lsa_may_act_for(…)` oder
  `if get_my_role() <> 'admin'` prüft. Bei `null` ist der Vergleich `null`,
  `not null` ist `null`, der `raise`-Zweig wird nie betreten. Betroffen:
  `lead_lsa_freigeben`, `lsa_start`, `lsa_uebernahme`, `lead_convert`.
- **Laut gescheitert** — `platz_next` prüft mit
  `if not exists (select 1 from platz_devices where profile_id = auth.uid())`.
  Das ist ein echter Boolean, nie `null`. Deshalb bricht A17 ab, statt still
  grün zu leuchten.

## Wie A17 vor der Reparatur endete

Auf einer Datenbank mit Stammdaten (Schema + `seed.sql` + `seeds/*.sql` +
`test-daten.sql`):

```
ERROR:  platz_next: kein Platz-Konto
CONTEXT:  PL/pgSQL function platz_next() line 8 at RAISE
          PL/pgSQL function inline_code_block line 29 at assignment
```

Abbruch in **Zeile 51** (`n := public.platz_next();`) — der ersten Anweisung
nach dem Wechsel auf die Geräte-Identität in Zeile 48.

## Welche Zusicherungen wirkungslos waren

Alle elf Identitätswechsel waren wirkungslos: Zeilen **36, 48, 58, 83, 90,
101, 110, 118, 123, 132, 137**. Nach jedem war `auth.uid()` `null`.

**Zeilen 36–48 — ausgeführt, aber ohne Identität.** Der einzige Teil von A17,
der vor der Reparatur überhaupt lief:

| Zeile | Aufruf | war ungeprüft |
|---|---|---|
| 37 | `update tasks set status='ready'` | direkt auf der Tabelle, kein Gate |
| 44 | `lead_lsa_freigeben(v_lead, 13, 'Mathematik')` | `get_my_role() <> 'admin'` — lief als Niemand durch |
| 46 | `pg_temp.assign(sA)` | Insert in `platz_assignments`, kein Gate |

**Zeilen 51–243 — seit dem 23.07. nie ausgeführt.** Der Abbruch in Zeile 51
liegt vor jeder einzelnen numerierten Prüfung. Damit hat nie eine davon einen
Wert gesehen:

| Prüfung | Zeilen | Zusicherung |
|---|---|---|
| P1 | 60–70 | adaptiv, `item_ids` leer, Urteile vorhanden, jede Antwort ausgegeben |
| P2 | 73–75 | keine Doppelausgabe |
| P3 | 86–92 | fremde `task_id` an `platz_submit` wird abgewiesen |
| P4 | 100–114 | Zeitende beendet die Sitzung |
| P5 | 118–124 | `platz_next`/`platz_state` tragen keine Aufgabenzahl |
| P6 | 129–140 | fest-Sitzung unverändert |
| P7 | 156–163 | nur die drei Lücken erzeugen Fokus |
| P8 | 166–172 | `belegt_direkt` wandert mit |
| P9 | 175–178 | zweite Übernahme dupliziert nicht |
| P10 | 181–187 | bestätigter Eintrag überlebt |
| P11 | 190–202 | Rohdaten unverändert |
| P12 | 205–213 | Fokus nach `fundament_tiefe` sortiert |
| P13 | 216–232 | Konversionsspur, andere `student_id` scheitert |
| P14 | 235–241 | Negativkontrolle |

Zwei davon wären auch nach dem Abbruchpunkt aus dem falschen Grund grün
geworden, hätte der Lauf sie erreicht:

- **P3, Zeilen 88–91**: fängt jede Exception aus `platz_submit` ab
  (`exception when others then v_ctrl := true`). Ohne Identität hätte
  `platz_submit` schon am Platz-Konto scheitern müssen, nicht an der fremden
  `task_id` — die Zusicherung hätte gehalten, ohne das zu prüfen, was sie
  prüfen soll.
- **P13, Zeilen 229–231**: gleiches Muster. Die Ablehnung stammt hier aus dem
  Datenabgleich (Sitzung gehört zu anderem Schüler), nicht aus dem
  Rollen-Gate `get_my_role() not in ('coach','admin')` — das war offen.

Dieselbe Schwäche haben **A16** (Zeile 27), **A20** (Zeile 12) und **A21**
(Zeilen 25, 118, 123). Sie sind vom Stub-Fix mitrepariert, wurden hier aber
nicht als Gate geprüft.

---

## Schritt 2 — Was geändert wurde

### `supabase/test-grundlage.sql`

`auth.uid()` und `auth.role()` lesen jetzt beide Formen, Einzahl zuerst:

```sql
create or replace function auth.uid() returns uuid language sql stable as $$
  select coalesce(
           nullif(current_setting('request.jwt.claim.sub', true), ''),
           nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
         )::uuid
$$;
```

`auth.role()` analog, mit Rückfall auf `'anon'`. `auth.jwt()` blieb unverändert
— es las schon die Mehrzahlform.

### `tools/neuaufbau-test.sh` — der eigentliche Fallstrick

Die Spec nannte drei Stellen, an denen `test-grundlage.sql` eingebunden ist.
Tatsächlich sind es nur zwei: `tools/schema-snapshot.sh` (Zeile 28) und
`.github/workflows/schema.yml` (Zeile 58).

**`neuaufbau-test.sh` band die Datei nicht ein — es trug eine eigene, wörtliche
Kopie der Grundlage in einem Heredoc**, inklusive einer zweiten Definition von
`auth.uid()`. Ein Fix nur in `test-grundlage.sql` hätte die Datenbank, gegen
die alle drei Gates laufen, nicht erreicht.

Das Heredoc ist ersetzt durch:

```bash
psql -q "$LOCAL" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql
```

Eine Grundlage, eine Datei. Der Inhalt war bis auf ein doppeltes
`create schema if not exists extensions` identisch; der Schema-Vergleich in
demselben Skript (`pg_dump --schema public`) bestätigt, dass sich am erzeugten
Schema nichts ändert.

### `supabase/checks/jwt_identitaet.PRUEFUNG.sql` (neu)

Negativkontrolle nach Spec, in `begin; … rollback;`. J1 Einzahl, J2 Mehrzahl,
J3 nichts gesetzt → `null`, J4 beides → Einzahl gewinnt. Dazu J5 für
`auth.role()` (beide Formen, Rückfall `anon`) und eine Selbstkontrolle, dass
eine falsche Erwartung den Lauf abbricht.

J3 ist die Kontrolle gegen einen fest verdrahteten Wert im Stub.

### `supabase/test-daten.sql` (neu)

Nicht in der Spec vorgesehen, aber ohne sie ist Gate 3 nicht ausführbar.
`neuaufbau-test.sh` legt die Datenbank jedes Mal neu an; danach gibt es weder
Admin noch Platz-Gerät noch Schüler. A17 scheiterte deshalb schon in Zeile 44
an `LSA: kein freigegebener Item-Pool` — also vor dem Punkt, an dem der
JWT-Befund überhaupt sichtbar wird.

`test-daten.sql` legt idempotent vier Identitäten an (Admin, Platz-Gerät, zwei
Schüler) mit festen UUIDs. Testgerüst wie `test-grundlage.sql`, keine
Migration, kein Schema.

---

## Schritt 3 — Gates

Reihenfolge, in der die Gates laufen müssen (Gate 1 legt die Datenbank neu an,
darum kommt die Bestückung danach):

```bash
bash tools/neuaufbau-test.sh
psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
  -f supabase/seed.sql -f supabase/seeds/*.sql -f supabase/test-daten.sql
psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/jwt_identitaet.PRUEFUNG.sql
psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/fehlbild_auswertung.PRUEFUNG.sql
psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/20260723120000_a17_platz_adaptiv_uebernahme.E2E.sql
```

Ergebnis:

| Gate | Stand |
|---|---|
| `tools/neuaufbau-test.sh` | grün — 35 Migrationen, Schema entspricht dem Schnappschuss |
| `jwt_identitaet.PRUEFUNG.sql` | grün — J1–J5 + Kontrolle |
| `fehlbild_auswertung.PRUEFUNG.sql` | grün — unverändert, nutzt weiter die Einzahlform |
| A17 `…_platz_adaptiv_uebernahme.E2E.sql` | grün — `ALLE 14 PRUEFUNGEN BESTANDEN` |

A17 ist **nicht** rot geworden. Der in der Spec vorweggenommene Fall ist nicht
eingetreten: A17s Zusicherungen halten auch dann, wenn die Identität wirklich
ankommt.

## Offene Punkte

- **`platz_next` prüft anders als der Rest.** Sein `if not exists (…)` fällt
  bei fehlender Identität auf, das Muster `if not lsa_may_act_for(…)` nicht.
  Dass A17 überhaupt aufflog, verdankt sich diesem einen Unterschied. Die
  Vereinheitlichung der `raise`-Muster ist laut Spec ein eigener Punkt.
- **A16, A20, A21** setzen dieselbe Mehrzahlform und liefen bisher mit
  `null`-Identität. Sie sind vom Fix mitbetroffen, wurden hier aber nicht
  ausgeführt. Sie sollten einmal gegen eine bestückte Datenbank laufen.
- **Kein Runner.** `specs/active/checks-runner.md` ist offen; bis dahin ist die
  Reihenfolge oben von Hand einzuhalten.
