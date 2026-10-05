# Ist-Analyse P0 — Admin-Prüfansicht

Stand: Branch `feat/rasit-admin-pruefansicht` = `origin/dev` 7083abf (05.10.2026). Nur lesend: Repo-Suche, lokale
Wegwerf-DB `apruef_a` (alle 162 getrackten Migrationen) und Produktion über `~/bin/dbread`.
Abweichungen vom Auftrag stehen in `offene-punkte.md`.

## 1 · RPC-Bindung

Kein Fix nötig. dev steht auf 7083abf („fix(lib): supabase.rpc/from gebunden aufrufen (this-Verlust) (#211)“), also
schon nach dem Fix:

- `src/lib/supabase/freigabe.ts:34, 55, 88, 107, 132` — `supabase.rpc.bind(supabase)`.
- `src/lib/supabase/taskAuthoring.ts:142` — `supabase.rpc.bind(supabase)`; Z. 78, 81, 233, 302 rufen `supabase.rpc(…)` direkt.
- `src/lib/supabase/pruefung.ts:29` — `supabase.rpc.bind(supabase)`; `tabelle()` bindet `supabase.from` (Z. 121–122).
- Vitest mit echtem supabase-js-Client und `this`-Prüfung: `src/lib/supabase/freigabe.test.ts:1–46`.

Suche nach `supabase.rpc as` in `src/`: keine Fundstelle. Der Commit „fix: supabase.rpc-Bindung“ entfällt deshalb.

## 2 · Produktion = Repo (pg_proc-Scan)

`dbread` über `pg_proc` für alle Funktionen `pruef%`, `freigabe%`, `task_status_set`, `lena_beanstande`,
`task_solution_upsert`, `darf_pruefen`, `get_my_role`, `ist_systemaufruf`: 48 Funktionen. Dieselbe Abfrage auf der
Wegwerf-DB liefert für **jede** Funktion denselben `md5(pg_get_functiondef)`, dieselbe SECURITY-DEFINER-Markierung
und dieselben Grants (nur der Eigentümer heißt lokal `edvance` statt `postgres`).

- `max(version)` in `supabase_migrations.schema_migrations` (Prod): `20261005082412` = jüngste Datei im Repo.
- Die neuen Namen gibt es noch nicht: keine Funktion `pruef_an_lena`, `pruef_admin_freigeben`,
  `pruef_freigabe_zuruecknehmen`, `pruef_admin_zurueckweisen`, `pruef_sammel`; keine Tabelle
  `task_pruef_ausschluss`, `task_admin_protokoll` (dbread, `pg_tables`).

Ausgewählte Prüfsummen (Prod = lokal):

| Funktion | md5 | definer |
|---|---|---|
| `pruef_sperren(uuid,bigint)` | 07f7297569285aea397f77e3912b4374 | nein |
| `pruef_aufgabe(uuid)` | 3cfe08cbdfd4cdc992b9c57f284e8c64 | ja |
| `pruef_speichern(uuid,bigint,jsonb)` | 842936a29dd06090289874b5927ebf43 | ja |
| `pruef_wertung_testen(uuid,integer,text,jsonb)` | 99882cd418d13ecc48bd9cc95c852ba2 | ja |
| `pruef_rueckfrage_klaeren(uuid,text,text,text[])` | 6f992b1bdf767b42661548ea69842742 | ja |
| `pruef_admin_liste()` | 293d921da4145525dca11967d4fca292 | ja |
| `pruef_ausschluss(uuid)` | c91e1434c1f25fcb3d720060b1334732 | nein |
| `task_status_set(uuid,text)` | cbfe42347e530a565013dc06d21a0999 | ja |
| `freigabe_thema(text,integer)` | 247c03d6ca48de7859ddc5289ed56435 | ja |

Bestand in Prod (dbread): 1.183 Aufgaben — draft 1.156, beanstandet 13, ready 13, review 1. Im Board 859, `vera8` 299,
`ohne_fertigkeit` 24, `gate` 1. Pilot: 100 Aufgaben, `nur_pilot = true`. Ein Profil mit `darf_pruefen`.
Eine Zeile in `task_pruefungen`.

## 3 · Verhalten der pruef_*-Funktionen für admin (Pilot, Team)

| Funktion | Sperre heute | Für admin |
|---|---|---|
| `pruef_sperren` (`…082412_pruefung_team_beanstandet.sql:30–55`) | `freigegeben`; `vera8/inaktiv/typ`; `not pruef_im_pilot(t)` → `ausgeschlossen`; `pruef_team_beanstandet` → `team_beanstandet` | **gesperrt wie Lena**. Kein Rollenzweig. |
| `pruef_aufgabe` (`…082412:57–122`) | liest immer (nur `darf_pruefen`) | legt die Ausgangsfassung nur an, wenn `status <> ready`, kein `vera8/inaktiv/typ`, **im Pilot und nicht vom Team beanstandet** (Z. 71–73). Admin bekommt außerhalb des Piloten/bei Team also `ausgang = null`. |
| `pruef_speichern` (`…071648_pruefung_funktionen_d.sql:157–188`) | über `pruef_sperren` | gesperrt wie Lena. Kommt ein Aufruf durch, legt `pruef_ausgang_sichern` (Z. 162) eine **fehlende Ausgangsfassung an** — nach G1 also auch für admin außerhalb des Piloten/bei Team. |
| `pruef_wertung_testen` (`…071648:273–323`) | nur `darf_pruefen()` (Z. 280) | **keine** Pilot- oder Team-Sperre; nichts anzupassen. |
| `pruef_entscheiden`, `pruef_rueckgaengig` | über `pruef_sperren` | werden durch G1 für admin ebenfalls freier. Lenas Oberfläche macht die Karte bei Team-Beanstandung trotzdem nur lesbar (`PruefansichtPage.tsx:62–63`). |

Folge für G1: `pruef_sperren` bekommt den Admin-Zweig; `pruef_aufgabe` legt die Ausgangsfassung für admin unabhängig
von Pilot und Team an (sonst zeigt die Admin-Prüfansicht keine „geändert ↺“-Marken). `pruef_wertung_testen` bleibt.

## 4 · Aufrufer

### task_status_set

- SQL (prosrc-Scan Prod): `freigabe_cluster(uuid)`, `freigabe_muster(text,uuid[])`, `freigabe_thema(text,integer)`,
  `pruef_rueckfrage_klaeren(uuid,text,text,text[])`.
  - `freigabe_thema`/`freigabe_cluster` nehmen nur `status = 'review'` (`…071649_pruefung_funktionen_e.sql:113, 139`),
    `freigabe_muster` nur `draft` (Z. 168), `pruef_rueckfrage_klaeren` nur `rueckfrage`. **Keine Schleife nimmt
    `beanstandet`**; die neue ED422 `erst_an_lena` kann dort nicht entstehen. Kein Vorfiltern nötig.
- Frontend: `setTaskStatus` (`src/lib/supabase/taskAuthoring.ts:295–316`) ← `AuthoringEditorPage.tsx:198`
  (ReleaseGate) und `wizard/useReleaseActions.ts:68` (entfällt mit der Strecke). `probeAuthoringSchema`
  (`taskAuthoring.ts:81`) ruft mit Nil-UUID nur zur Erkennung.
- Prüfskripte/Tests: `supabase/checks/20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql:81, 100, 102, 123, 137, 173`
  (Z. 173 auf eine `ready`-Aufgabe, Z. 137 `draft`), `supabase/tests/lena_board.test.sql:148` (Lena → 42501), `:362`
  (Admin `draft` nach Beanstandung). Keiner setzt `beanstandet → ready`.
- ReleaseGate im Editor bietet bei `beanstandet` heute „Freigeben“ an (`ReleaseGate.tsx:130–131`). Nach G2 lehnt der
  Server ab; die Oberfläche sperrt den Knopf mit Sperrgrund (P4).

### pruef_admin_liste

- SQL: kein Aufrufer.
- Frontend: `getPruefAdminListe` (`src/lib/supabase/pruefung.ts:170–172`) ← `AuthoringItemsPage.tsx:116`,
  `ItemBoardPage.tsx` (→ `Arbeitsbereich`, `ThemaZeile`). Typ `PruefAdminZeile` (`src/types/pruefung.ts:212–229`).
- Prüfskripte: `supabase/checks/lena_board.PRUEFUNG.sql:17` (Name), `…20260922100000…PRUEFUNG.sql:70`
  (Signatur `public.pruef_admin_liste()` für die Rechteprüfung). Name und Argumente bleiben; nur der Rückgabetyp wächst.

### Strecke, Rückweg, Vorbefüllt, Pilot

| Symbol | Aufrufer außerhalb `wizard/` |
|---|---|
| `PflegeWizardPage` | `src/App.tsx:13, 331` |
| `/admin/pflege` | `App.tsx:328`, `ContentHealthPage.tsx:194`, `AuthoringItemsPage.tsx:272`, `board/Arbeitsbereich.tsx:75`, `admin/adminNav.ts:79` |
| `wizardQueue` | nur `PflegeWizardPage.tsx:43` und Dateien in `wizard/` |
| `usePflegeRueckweg` | `EditorKopf.tsx:7, 11`, `AuthoringEditorPage.tsx:28, 67` |
| `wizard/ChoiceChip` | `board/Arbeitsbereich.tsx:29` (bleibt in Gebrauch) |
| übrige `wizard/*` | nur `PflegeWizardPage.tsx` bzw. untereinander |
| `setPruefPilot` | `board/LenaInfo.tsx:10, 29`; Mocks in `ItemBoardPage.test.tsx:24`, `AuthoringItemsPage.test.tsx:32` |
| `VorbefuelltContext` | `PflegeWizardPage.tsx:261` **und** `AuthoringEditorPage.tsx:231` |
| `beanstandeAufgabe`, `BEANSTANDUNGS_KATEGORIEN` | nur `wizard/useReleaseActions.ts:79`, `wizard/RejectPanel.tsx:32` |

**Wer setzt „bestätigt“?** Nicht nur die Strecke. `patchFuerSpeichern` (`editorState.ts:291–305`) entfernt die
Kennzeichen der gespeicherten Spalten — im Editor alle (`AuthoringEditorPage.tsx:173–174`, ohne `baseline`), in der
Strecke nur die geänderten (mit `baseline`). Dazu `bestaetigeLoesungsKennzeichen` (`src/lib/supabase/vorbefuellt.ts:13–19`)
nach dem Lösungs-Speichern im Editor (`AuthoringEditorPage.tsx:187`). `VorbefuelltContext` bleibt also; nur der
`baseline`-Zweig von `patchFuerSpeichern` hat nach dem Entfernen der Strecke keinen Aufrufer mehr (offene-punkte OP-3).
Die `pruef_*`-Funktionen ändern `tasks.vorbefuellt` nicht (Lena-Board, Entscheidung 7).

i18n: Die Strecke nutzt `authoring.json` → `wizard.*` (31 Schlüssel). Außerhalb der Strecke nur `wizard.start`,
`wizard.sourceList`, `wizard.sourceHealth` (Expertenliste, Content-Gesundheit) — beide Einstiege werden umgehängt.
`wizard.*` in `admin.json` und `vertraege.json` gehören zu anderen Abläufen und bleiben.

## 5 · Sprungziele im Editor

`AuthoringEditorPage.tsx` (390 Zeilen) baut die Abschnitte aus `Section` (`authoring/ui.tsx:24–75`). Heute ist kein
Abschnitt adressierbar: keine `id`, Auf/Zu ist lokaler State, `defaultOpen` nur beim Mount.

| Abschnitt (Anforderung D 24) | Section heute | Zustand |
|---|---|---|
| Aufgabe | `sections.stem` (Titel, Aufgabentext), `sections.type` | offen |
| Antwort & Lösung | `sections.answer` bzw. `sections.parts`; Lösungsweg und typische Fehler in `sections.pedagogy` | offen / pedagogy zu |
| Einordnung | `sections.tags` (Stoffanker, Cluster, AFB, Kompetenzen) | zu |
| Bilder | `AssetsBlock` → `sections.assets` | zu |
| Stoffanker | Feld `curriculum_grade` in `TagsSection.tsx:44–60` | (in tags) |

Vorschlag P4: `Section` bekommt `anker` (setzt `id="abschnitt-<anker>"`) und `defaultOpen` aus dem Parameter
`?abschnitt=`; das Stoffanker-Feld bekommt einen eigenen Anker. Nach dem Laden scrollt der Editor dorthin.

## 6 · Weitere Befunde für den Bau

- Lenas Bausteine (`components/edvance/pruefen/*`) sind wiederverwendbar. Lena-spezifisch sind `PruefKopf` (Pause,
  Thema als Titel, Fortschritt im Thema) und `Entscheidungsleiste` (Passt/Unsicher/Passt nicht). Die Admin-Prüfansicht
  bekommt dafür eigene Hüllen; `Kinderansicht`, `RichtigeAntwort`, `RegelBlock`, `AntwortTesten`, `Loesungsweg`,
  `TypischeFehler`, `Einordnung`, `AenderungenBox`, `Auffaelligkeiten`, `EntscheidungsMeldung` werden geteilt.
- `usePruefSitzung` (`src/pages/coach/pruefen/usePruefSitzung.ts`) erledigt Laden, entprelltes Speichern, Version und
  ED409. Die Admin-Seite nutzt ihn mit.
- `freigabe_gate_fehler` ist für Clients nicht freigegeben (`…071059_pruefung_funktionen_a.sql:273`). Die
  sperrenden Befunde kommen im Frontend aus `computeFlags`, dessen blockierende Regeln laut Kopfkommentar ein Spiegel
  des Gates sind (`src/lib/authoring/flags.ts:1–9`); den Gate-Text selbst liefert `pruef_sammel` (Grund `befund`).
- Daten für „Lenas Ergebnis“ und „Verlauf“ sind über RLS lesbar: `task_pruefungen` (`darf_pruefen`), `task_reviews`
  (admin, coach), `profiles` (admin), neu `task_admin_protokoll` (admin), `task_pruef_ausschluss` (`darf_pruefen`).
- Die Expertenliste ist eine Kartenliste (`ItemRow`), keine Tabelle; `ItemRow` verlinkt heute auf den Editor.
- Die Hülle scrollt nicht das Fenster, sondern den Inhaltsbereich (`AppShell.tsx:82`, `overflow-y-auto`).
- Startseite „Heute“ kennt nur die Zahl der Rückfragen (`heute/heuteModel.ts:103–105`), keine IDs.
