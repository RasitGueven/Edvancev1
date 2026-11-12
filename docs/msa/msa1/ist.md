# MSA-1 · M0 Ist und Streichliste

**Stand:** 12.11.2026, Prod per `dbread`, Code auf `origin/dev` @ `6aa8490f`. Die Abfragen liegen in `abfragen/`
(`./lauf.sh s01` …). Gemeinsame Blöcke: `msa_basis.sql` (Kopie aus `docs/msa/abfragen/`) und `soll.sql` (Kopie aus `docs/msa/abfragen/`).

## 1 · Streichliste neu gerechnet (`streichliste.csv`, S01/S02)

**Entscheidung Rasit vom 12.11.2026 (ersetzt „die 13 zu schweren archivieren“):** Die 13 für die MSA zu schweren
Aufgaben bleiben aktiv. Sie sind für das Gymnasium reguläre Aufgaben, und „zu schwer“ löst später das Prüfziel MSA.
Die Auswahl folgt deshalb **genau** `docs/msa/abfragen/soll.sql` (Regel 2 Texte, davon 1 ohne MC, plus 1 Reserve), und
archiviert wird nur die Gruppe nicht-notwendig.

| Gruppe | draft | ready | rueckfrage | gesamt | Bericht MSA-0 |
|---|---|---|---|---|---|
| notwendig-regel | 176 | 81 | – | **257** | 257 |
| notwendig-reserve | 97 | 17 | – | **114** | 114 |
| **notwendig** | 273 | 98 | – | **371** | 371 |
| **nicht-notwendig = zu archivieren** | 451 | 70 | 2 | **523** | 523 |

**Abgleich:** Ein Vergleich je `id` mit `docs/msa/anhang/aufgabenliste.csv` (Rolle Variante 2) zeigt **0
Abweichungen** bei 894 Aufgaben. Der Bestand ist seit dem Bericht unverändert: keine neue Prüfung, keine Freigabe,
dieselben Ampeln, derselbe Pool (S03).

**Haltepunkt-Prüfung S02 wiederholt** (`ergebnisse/s02.txt`): **Kein Skill**, der die Regel heute erfüllt, verliert
sie nach dem Archivieren. O1 ist damit erledigt.

**`msa-ausschluss.csv`** hält 50 Aufgaben als Vorgabe für das spätere Prüfziel MSA fest, mit id, Skill, Gruppe,
Begründung aus `anhang/niveau-nicht-passend.csv` und Gruppe in der Streichliste. Geändert wird an ihnen nichts.

| Gruppe | gesamt | davon notwendig (Regel / Reserve) | davon nicht notwendig (wird archiviert) |
|---|---|---|---|
| zu-schwer (13) | 13 | 8 / 4 | 1 |
| zu-leicht (37) | 37 | 16 / 5 | 16 |

Die 17 Aufgaben aus `msa-ausschluss.csv`, die nicht notwendig sind, werden nur wegen der Auswahlregel archiviert,
nicht wegen ihres Niveaus. Die 30 „Rechner-Konflikte“ aus dem Bericht stehen nicht in `msa-ausschluss.csv`; sie bekommen
in M4 das Rechner-Kennzeichen.

**Lücken nach der Auswahl:** `bruch_div` (1 Text) und `geo_kreis_zusammen` (0) erreichen die Regel nicht, dafür ist
M4 da. 14 Skills haben keine Reserve.

## 2 · Stand vorher (S03, S04; `ergebnisse/s03-vorher.txt`, `ergebnisse/s04-vorher.csv`)

| Kennzahl | Wert |
|---|---|
| Ampeln Kl. 8 / 9 / 10 (`lsa_status_roh` 2026/27, wie `lsa_abdeckung`) | 176 / 176 / 149 rot, 0 gelb, 0 grün |
| `pruef_ziel_roh`: Skills / Vorschläge / Freigabe-ids | 94 / 258 / 0 |
| `pruef_ziel_liste` gezielt (nachgebaut: Vorschläge der Skills in Paketen) | 204 Aufgaben |
| `pruef_ziel_liste` nachprüfen (ready ohne letztes „passt“) | 32 Aufgaben |
| ziehbar (`lsa_im_pool`) | 166 |
| Skills mit erfüllter Regel (`lsa_skill_bereit_roh`) | 36 |
| LSA-Aufgaben aktiv / inaktiv | 894 / 0 |

`lsa_abdeckung` und `pruef_ziel_liste` verlangen `darf_pruefen()` und laufen unter `dbread` nicht. Gezählt wurde
deshalb mit den Roh-Funktionen, die sie aufrufen (`lsa_status_roh`, `pruef_ziel_roh`). Die Liste je Skill steht in
`ergebnisse/s04-vorher.csv`.

## 3 · Wo tauchen LSA-Aufgaben auf, und beachtet die Stelle `is_active`?

`SQL` = `supabase/schema-erwartet.sql`. Die Suche hat ein frischer Such-Agent gemacht, die Stellen sind hier
übernommen und stichprobenweise nachgelesen.

| Oberfläche | Datenweg | SQL | `is_active` beachtet? |
|---|---|---|---|
| Item-Board `src/pages/admin/ItemBoardPage.tsx:72` | `src/lib/supabase/taskAuthoring.ts:90–103` (Tabelle `tasks`, nur `content_type`, `bauform_id`) | – | **nein** |
| Item-Board `ItemBoardPage.tsx:76`, Item-Pflege `AuthoringItemsPage.tsx:129` | `pruefung.ts:209` → `pruef_admin_liste` | `:12951` (alle Zeilen, Ausschluss nur als Spalte) | **nein** |
| Item-Pflege-Liste `src/pages/admin/AuthoringItemsPage.tsx:123` | `taskAuthoring.ts:90` `listAuthoringTasks` | – | **nein** |
| Item-Pflege Metadaten `AuthoringItemsPage.tsx:127` | `authoring_review_meta` | `:1117` | nein (nur Labels) |
| Editor `src/pages/admin/AuthoringEditorPage.tsx:99`, `pruefen/useAdminPruefung.ts:55` | `getAuthoringTask` per id | – | nein (Einzelaufruf) |
| Content-Gesundheit `src/pages/admin/ContentHealthPage.tsx:86` | `listAuthoringTasks` | – | **nein** (zählt im Frontend) |
| Heute, Freigabeliste Admin `src/pages/admin/heute/useHeuteDaten.ts:79` | `src/lib/supabase/heute.ts:84–96` (Tabelle `tasks`, status review/rueckfrage) | – | **nein** |
| Zähler Leiste „Item-Pflege“ `src/components/edvance/admin/useAdminZaehler.ts:26` | `heute.ts:100–109` `countAufgabenFuerAdmin` | – | **nein** |
| Batus Freigabeliste `src/pages/admin/heute/FreigabelisteListe.tsx:26` | `pruef_board`, `pruef_board_soll` | `:13464`, `:13508` | indirekt (`pruef_ausschluss`, `:13479`) |
| Lena-Board `src/pages/coach/pruefen/PruefenUebersichtPage.tsx:52`, `PruefansichtPage.tsx:72`, Zähler `useCoachZaehler.ts:31` | `pruefung.ts:54` `pruef_board` | `:13464` | indirekt (`pruef_ausschluss` → „inaktiv“, `:13441`) |
| „Gezielt prüfen“ `GezieltPruefen.tsx:25`, `PruefansichtPage.tsx:79`, `admin/lsaAbdeckung/FreigabeLeiste.tsx:24` | `lsaAbdeckung.ts:42` `pruef_ziel_liste` | `:14930` → `pruef_ziel_roh` `:15003`, `:15011` | **Abschnitt gezielt ja, Abschnitt `nachpruefen` nein** (`:14960–14964`: ready ohne letztes „passt“, ohne `is_active`) |
| LSA-Abdeckung `LsaAbdeckungPage.tsx:43`, `PaketDetail.tsx:36`, Wirkung `GezieltPruefen.tsx:29` | `lsa_abdeckung`, `lsa_paket_skills`, `lsa_wirkung` | `:7353`, `:9170`, `:11639` → `lsa_skill_bereit_roh` → `lsa_im_pool` (`:8707`) | indirekt ja |
| Kennzahlen Admin (`adminStats.ts`) | – | – | zählt keine Aufgaben |

**Kennzeichen „archiviert“:** Es gibt keins. Die Spalten von `tasks` (`SQL:13147–13226`) enthalten nur
`is_active boolean default true` (`:13160`). Der Status-CHECK (`:13225`) kennt kein `archiviert`. `beanstandet`
bedeutet „wird überarbeitet“. `pruef_ausschluss` fasst `is_active = false`, Tutorial und Nicht-exercise zu
„inaktiv“ zusammen (`:13441`). Archiviert lässt sich also heute nicht von „aus anderem Grund inaktiv“
unterscheiden. → M1 legt Spalten an.

**Folgerung für M1/M3:**

- Lena-Board, gezielte Liste, Pool und Abdeckung schließen ein archiviertes `is_active = false` von selbst aus.
- Nachzuziehen sind:
  - `pruef_ziel_liste` (Abschnitt `nachpruefen`) und `pruef_admin_liste`: in SQL, M1
  - die Admin-Seiten, die `tasks` direkt lesen: Item-Board, Item-Pflege, Content-Gesundheit, Heute, Zähler; im
    Frontend, M3
