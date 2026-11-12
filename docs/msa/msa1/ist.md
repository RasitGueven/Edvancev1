# MSA-1 · M0 Ist und Streichliste

**Stand:** 12.11.2026, Prod per `dbread`, Code auf `origin/dev` @ `6aa8490f`. Die Abfragen liegen in `abfragen/`
(`./lauf.sh s01` …). Gemeinsame Blöcke: `msa_basis.sql` (Kopie aus `docs/msa/abfragen/`) und `soll_msa1.sql`.

## 1 · Streichliste neu gerechnet (`streichliste.csv`, S01/S02)

Regel: 2 Texte, davon 1 ohne MC, plus 1 Reserve. Auswahl wie `docs/msa/abfragen/soll.sql`, mit **einer Änderung**:
Die 13 für die MSA zu schweren Aufgaben (Bericht MSA-0 §2, `anhang/niveau-nicht-passend.csv`, Urteil `zu_schwer`
ohne Rechner-Konflikt) sind nie notwendig. Sie werden laut Gründerentscheidung archiviert.

| Gruppe | draft | ready | rueckfrage | gesamt | Bericht MSA-0 |
|---|---|---|---|---|---|
| notwendig-regel | 177 | 79 | – | **256** | 257 |
| notwendig-reserve | 96 | 17 | – | **113** | 114 |
| nicht-notwendig | 442 | 68 | 2 | **512** | 523 |
| zu-schwer | 9 | 4 | – | **13** | (in den 523 bzw. 371 enthalten) |
| **zu archivieren** (nicht-notwendig + zu-schwer) | 451 | 72 | 2 | **525** | 523 (+0,4 %) |
| **notwendig** | 273 | 96 | – | **369** | 371 (−0,5 %) |

**Abweichungen erklärt.** Ein Vergleich der beiden Listen je `id` (S01 gegen `docs/msa/anhang/aufgabenliste.csv`)
zeigt 26 Wechsel, und alle betreffen genau die 6 Skills der zu schweren Aufgaben: `fkt_exp_gleichung`,
`fkt_exp_halbwert`, `fkt_sinus_graph`, `fkt_sinus_periodisch`, `geo_flaeche_drachen_raute` und
`zahl_wurzel_irrational`.

- 8 der 13 zu schweren Aufgaben waren im Bericht notwendig (Regel oder Reserve). Für sie rücken andere Texte desselben
  Skills nach.
- Sonst hat sich der Bestand seit dem Bericht nicht geändert: keine neue Prüfung, keine Freigabe, 894 LSA-Aufgaben.

**Neue Lücke:** Nach dem Ausschluss hat `fkt_sinus_graph` nur noch 1 Text (vorher 2). Dazu kommen wie im Bericht
`bruch_div` (1) und `geo_kreis_zusammen` (0). Ohne Reserve sind 17 Skills.

### Haltepunkt absehbar: `geo_flaeche_drachen_raute`

S02 prüft: Welcher Skill, der die Regel heute erfüllt, erfüllt sie mit dem Pool ohne die zu archivierenden Aufgaben
nicht mehr? Ergebnis: **genau einer**.

| Skill | heute im Pool | nach dem Archivieren |
|---|---|---|
| `geo_flaeche_drachen_raute` | 2 Texte, 3 ohne MC (3 ready) | 0 Texte |

- Die 3 ready-Aufgaben des Skills gehören zu den 13 zu schweren (Fläche über die Diagonalen e·f/2).
- Die 3 Entwürfe des Skills rücken in Regel und Reserve nach. Sie sind aber nicht freigegeben, und ein Subagent hat sie
  nicht beurteilt.
- Damit stehen zwei Gründer-Entscheidungen gegeneinander:
  - „Auch die 13 zu schweren werden archiviert.“
  - „Nach dem Archivieren darf kein Skill die Regel verlieren.“ (Haltepunkt)
- M2 wird deshalb vorbereitet, aber **nicht eingespielt**. Der Befund steht in `offen.md`.

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
