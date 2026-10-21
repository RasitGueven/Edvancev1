# LSA-Erlebnis L1 · Befunde vor der Schemaänderung

**Stand:** 21.10.2026, Live-DB über `dbread` (nur lesend), Edvancev1 dev @ `ccd9147`. Gehört zu den Migrationen
`20261021082756` bis `20261021083033`.

## 1. pg_proc-Scan

Vor jeder Änderung an Spalten wurden alle Funktionen im Schema `public` gesucht, die die betroffenen Spalten
bzw. Zeilentypen referenzieren (`prosrc`-Suche, Ergebnis wörtlich):

| Suche | Funktionen | Folge für L1 |
|---|---|---|
| `bruch` (neue Spalte `tasks.bruch`, Schlüssel `parts[i].bruch`) | `lsa_parse_fraction` (nur Kommentar „gemischter Bruch“) | keine Kollision |
| `diagnose_ab`, `platz_los`, `input_hint` | – | neu |
| `avatar_choice` | `platz_avatar_set` | nur geschrieben; `platz_state` liest es jetzt |
| `started_at` (lsa_sessions) | `lsa_select_next_core`, `lsa_start` | `lsa_start` setzt es wie bisher; nur `lsa_select_next_core` rechnet jetzt ab `coalesce(diagnose_ab, started_at, created_at)` |
| `parts` | `erklaer_bewerten`, `freigabe_gate_fehler`, `lsa_fehlbild_capture`, `lsa_finish`, `lsa_im_pool`, `lsa_question_payload`, `lsa_start`, `lsa_submit`, `lsa_urteil_buchen_core`, `pruef_auffaelligkeiten`, `pruef_aufgabe`, `pruef_ausschluss`, `pruef_entscheiden`, `pruef_entwurf_anwenden`, `pruef_sicht`, `pruef_wertung_testen`, `session_aufgabe_stand`, `session_bewerten`, `session_im_pool`, `task_preview_payload` | alle lesen `parts` nur (`set parts =` kommt nur in `task_preview_payload` vor, in einer zurückgerollten Subtransaktion); ein zusätzlicher Schlüssel `bruch` stört keinen. `lsa_parts_valid` erlaubt ihn. |
| Zeilentyp `tasks` (`tasks;`/`%rowtype`/Argument) | `erklaer_bewerten`, `freigabe_gate_fehler`, `hinweise_bestaetigen`, `lsa_submit`, `lsa_urteil_buchen_core`, `pruef_*` (20), `session_bewerten`, `task_status_set` | eine weitere Spalte im Zeilentyp ist für plpgsql unschädlich |
| Zeilentyp `lsa_sessions` | `lsa_confirm_focus`, `lsa_finish`, `lsa_hint`, `lsa_select_next_core`, `lsa_submit`, `lsa_uebernahme`, `platz_assign`, `platz_avatar_set`, `platz_finish`, `platz_next`, `platz_state`, `platz_submit` | dito |
| `insert into tasks/lsa_sessions` ohne Spaltenliste, `to_jsonb(t)` u. ä. | – | keine positionsabhängigen Zugriffe |
| `task_figures` | `lsa_task_assets`, `pruef_aufgabe`, `pruef_ausschluss` | nur `lsa_task_assets` baut URLs |
| `-dunkel.svg` | `lsa_task_assets` | umgestellt auf `-hell.svg`, dunkel als `url_dunkel` |
| Aufrufer `lsa_question_payload` | `lsa_start`, `platz_next`, `erklaer_start`, `lsa_submit`, `tablet_stand`, `coach_kind_detail`, `session_kind_live`, `quest_inhalt`, `task_preview_payload`, `session_schritt_oeffentlich`, `erklaer_zeigen` | bekommen `input_hint` additiv (auch die Session, siehe PR) |
| Aufrufer `lsa_is_correct` | `lsa_grade`, `erklaer_bewerten`, `pruef_auffaelligkeiten`, `lsa_submit`, `session_bewerten`, `pruef_wertung_testen` | nur `lsa_submit` wechselt auf `lsa_antwort_korrekt`; die übrigen bleiben unverändert |
| Aufrufer `lsa_im_pool` | `lsa_select_next_core`, `lsa_start` | Gate wirkt auf beide Modi |

## 2. Prüfliste Eingabeformat (nach dem Einspielen, Abfrage `supabase/checks/lsa_eingabeformat_pruefliste.sql`)

Ermittelt auf einer lokalen Kopie der Inhaltstabellen aus Prod (21.10.2026) mit allen fünf Migrationen. Pool ohne
das neue Gate gezählt, damit die herausfallenden Fälle sichtbar sind.

| Hinweis | Pool echt: Aufgaben | Pool echt: Teile | Pool Testlauf: Aufgaben | Pool Testlauf: Teile |
|---|---:|---:|---:|---:|
| `number` | 84 | 2 | 681 | 190 |
| `fraction` | 0 | 0 | 38 | 0 |
| `term` | 0 | 0 | 20 | 0 |
| kein Hinweis (Prüfliste) | 2 | 0 | 24 | 3 |

Pool mit Gate (`lsa_im_pool`): echt 87 → **85**, Testlauf 898 → **872** (24 Aufgaben und die 2 Mehrteiler
`3b59c4a1…`, `785c92ab…` mit Teilen ohne Hinweis). Gleich der Zählung aus L0.

Prüfliste (27 Einheiten): ready `939baa76-0207-496c-a768-4df2988f7f12`, `afc3b977-389b-4e8d-a157-9952b087c8e2`;
draft `03c74739`, `15164236`, `15c3975c`, `2b7059d7`, `305c5063`, `356c43e5`, `3b3119d4`, `3b59c4a1` (Teil 1 und 2),
`3cb3aa9d`, `46f1792e`, `54f5e1df`, `5bcca7e7`, `5d143147`, `785c92ab` (Teil 1), `7e7ce00a`, `8bc01e5b`, `9a48fec6`,
`b0fd871b`, `d1f84813`, `d24bac46` (nur „1/3“, „+1/3“ — Regel wörtlich, Orchestrator a), `d38afe88`, `ddaa4ecd`,
`df337432`, `ffc758dc`.

Bruch-Treffer zur Handprüfung (Vorbefüllt-Kennzeichen `bruch`): 38 Aufgaben, alle draft, 0 Teile; IDs wie in
L0 (`ist-analyse-daten.md`, Abschnitt 2).

Vorbefüllung gesamt (alle Aufgaben, nicht nur Pool): 749 Aufgaben bekommen `bruch` (38 true, 711 false),
150 Mehrteiler bekommen `bruch` an 270 Teilen (alle false). Ein zweiter Lauf ändert nichts.

## 3. Helle Abbildungen auf Creme `#F8F5EE`

Gerendert mit Chromium (Playwright) auf `#F8F5EE`, Radius 30 pt wie die Arbeitsfläche; Bilder in
`helle-abbildungen/`. Alle 41 hellen Dateien liegen im Storage (HEAD 200).

| Generator | Aufgabe | Ergebnis |
|---|---|---|
| koordinatensystem | `0315634a-9c1d-4961-b214-07617add2874` | trägt: Graphen Navy, Achsen/Zahlen #4A4A47, Gitter #E8E8E5 dezent aber sichtbar |
| thales | `11aebc7c-d30e-4577-89d5-52efed7d379f` | trägt: Dreieck Navy, Bogen und Punktnamen #4A4A47, Winkelmarken Gold |
| rechtecke | `11390e1a-2fc1-4cf1-93da-890ac936b56a` | trägt: Flächen Navy, Maßlinien und Maße #4A4A47 |
| winkel | `a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd` | trägt: Schenkel Navy, Winkelbogen und „50°“ Gold |

Kontrast auf `#F8F5EE`: Navy `#102038` 15,0 : 1, Beschriftung `#4A4A47` 8,2 : 1, Gold `#DA9721` 2,3 : 1
(fette, große Winkelangaben, gut lesbar, aber unter 3 : 1), Gitter `#E8E8E5` 1,1 : 1 (Hilfslinien).
