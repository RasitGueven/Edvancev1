# Reihe 1 · Merge-Bericht (28.10.2026)

Auftrag Rasit vom 28.10.2026: „Alles mergen.“ Nachauftrag am selben Tag: #357, A1–A4, B5–B9 und die
App-PRs #54, #55, #60 mergen; den Fehler der Session-Auswahl A2+C2 klären und beheben. Ziel ist jeweils
`dev`, Merge-Art echter Merge-Commit. Das Protokoll mit Uhrzeit und Merge-Commit je PR steht in
[`../merge-plan.md`](../merge-plan.md).

## Ergebnis

Alle PRs der Reihe 1 sind in beiden Repos gemergt, bis auf **#352 A5** (Entwurf, bleibt offen).
Prod und `dev` stimmen im Schema genau überein. Der Smoke-Test gegen die Live-Bereitstellungen ist grün,
die LSA läuft bis zur Avatar-Wahl.

## Gemergte PRs

**Edvancev1 (31 PRs)**

| Auftrag | PRs |
|---|---|
| A | #333 A0, #334 A1, #338 A2, #342 A3, #350 A4 |
| B | #329 B0, #336 B1, #337 B2, #340 B3, #343 B4, #346 B5, #351 B6, #354 B7, #355 B8, #356 B9 |
| C | #330 C0, #332 C0b, #335 C1, #341 C2, #347 C4, #349 C6 |
| D | #331 D0, #339 D1, #344 D2, #345 D2-Coach, #348 D4, #353 D4b |
| Fixes | #357 ThemenAuswahl-Test, #358 Fix Session-Auswahl A2+C2 |

**edvance-app (12 PRs)**

#51 A0b, #50 B0b, #49 D0b, #56 B6-App, #53 C3, #52 D1, #57 D3/D4, #58 D5, #59 D6, #60 D7, #54 C5, #55 A3-App

## Angelegte PRs

- Keine Reihe-1-PR neu angelegt: Alle Branches hatten schon eine. A1 = #334, A2 = #338, A3 = #342,
  A4 = #350, C6 = #349. edvance-app `feat/rasit-reihe1-d3-start` steckt vollständig in #57.
- **#357** `fix(test): ThemenAuswahl wartet auf den Freigabe-Knopf`. Gemergt mit Freigabe Rasit.
- **#358** „Reihe 1 · Fix Session-Auswahl A2+C2“, mit Migration `20261028125114`. Gemergt.
- **Dieser PR** „Reihe 1 · Merge-Bericht“ bleibt offen.

## Ausgelassen

- **#352 A5 Lena-Board** (Entwurf). Migration `20261027143548_reihe1_a5_board` ist nicht in Prod.

## Reihenfolge, Abweichungen vom Plan

- #350 (A4) verlangt edvance-app #55 davor. Deshalb: #55, dann #350.
- Kein Merge im ersten Lauf, sondern erst im Nachauftrag:
  - A1–A4: Prüfskripte rot, siehe unten.
  - B5–B9: B5 viermal am wackligen Test `ThemenAuswahl` gescheitert. Nach #357 grün.
  - #55, #54, #60: auf Anweisung ans Ende gestellt.
- Unabhängige Ketten (B, C, D, App) liefen verschränkt. Die Abhängigkeit „Baut auf …“ ist eingehalten.

## Gelöste Konflikte und Merge-Folgen

**Dokumente**

- `docs/api/DATENVERTRAG.md` (B0, D0, D1, C0b, C1, C2, B6): Die Abschnitte beider Seiten bleiben
  erhalten. Es gibt zwei Abschnitte mit der Nummer 13 (C0b und A).
- `docs/reihe1/C/fortschritt.md` (C1): Beide Seiten bleiben erhalten. Die beim Vereinigen doppelt
  entstandene C0-Zeile („PR folgt“) ist entfernt.

**Erzeugte Dateien**

- `supabase/schema-erwartet.sql` (C1, D4, D4b, A2, B6): Nicht von Hand zusammengeführt, sondern neu aus
  einer Wegwerf-DB erzeugt (`test-grundlage.sql` + alle Migrationen des Stands). Das Verfahren stimmt
  gefiltert mit dem Stand auf dev überein.
- edvance-app `src/types/database.ts` (C3, D1, D3/D4): Neu erzeugt mit
  `supabase gen types … --project-id ztcppihxqcphlqaguhma`. Das Ergebnis war jeweils gleich der
  Fassung auf dev.

**App-Dateien (beide Seiten erhalten)**

- `app.json` (D7): Splash-Konfiguration aus D7 und `expo-video` aus B6-App.
- `app/_layout.tsx` (A3-App): Format-Vorschau aus A3-App und `zielOhneSession` aus D1.

**Tests, die erst in der Kombination brachen**

- `reihe1_c2`: Platzhalter für `zeigs_mir_offen` (D2) und die A2-Funktionen jetzt mit
  `create or replace`. Signaturen gleich.
- `session_r1`: 59 Stellschrauben (A2 elf, C1 sieben, C2 elf), in der Wegwerf-DB nachgezählt.
- `reihe1_c1` b3: Mit A2 fragt C1 `skill_kann_entfallen` statt der Rückfall-Liste. Solange keine
  Bauform `kann_entfallen` trägt, entfällt zuerst der Transfer. Geprüft wird jetzt die erste entfallene
  Kernidee. **In Prod schon so** (`reihe_kann_entfallen_pruefen('fkt_quadr_extrem')` = false).
- `session_f1` Fall 6 (A4): Seit A4 gibt es Bauform-Instanzen für `gleichung_quadr_faktor`. Der Test
  macht jetzt eine Aufgabe ohne Bauform ready.

## A1–A4 und die Session-Auswahl

**A1:** Fünf Prüfskripte unter `supabase/checks/` (`fehlbild_auswertung`, `fehlbild_klartext_abnahme`,
`fehlbild_familien`, `fehlbild_capture_formen`, `urteil_multipart`) legten `tasks` ohne die neue
Pflichtspalte `einsatz` an. Sie setzen jetzt `einsatz = '{lsa}'`. Die acht Tests in `bekannt-rot.txt`
waren nicht die Ursache.

**A2 + C2:** C2 bindet A spät über `to_regprocedure` ein. Mit A2 läuft die Session-Auswahl über
`aufgabe_ziehen`. Read-only-Analyse (Prod-Fassungen per md5 von `prosrc` verglichen):

| Test | Funktion | Fassung in Prod | Konzept | Prod falsch? |
|---|---|---|---|---|
| session_a2d (Testlauf), session_f1 24, session_f2_phasen 23 | `session_ziehen` (C2) → `aufgabe_ziehen` (A2), `p_testlauf` geht verloren | = C2 `20261027133007` | §9 kennt keinen Testlauf. Testlauf-Entwürfe sind ein bestehendes Merkmal (T3, A2d) | **ja**, Lücke an der Naht A/C |
| session_a2 41–46/116, session_a2b 46/54, session_a2d F | `session_plan_kern` → `session_ziehen(…, 'beispiel')` | = C2 / A2 | §3.1: Beispiel = Instanz der Rolle `beispiel` | nein, Testerwartung überholt |
| reihe1_d2_home_uebung | `aufgabe_werten` → `aufgabe_lesbar` | = A2 | §3.1/§9: Wertung zuhause nur für ziehbare `home`-Instanzen | nein, Test nahm eine Attrappe an |

**Korrektur #358** (eine Funktion, Migration `20261028125114_reihe1_fix_session_ziehen_testlauf`):

- Liefert der A-Weg nichts und läuft ein Testlauf, fällt `session_ziehen` auf
  `session_aufgabe_waehlen(…, true, …)` zurück.
- Angenommen werden nur Aufgaben ohne Bauform oder Instanzen genau dieser Rolle (Zweitprüfung P1, §3.1).
- Echte Sessions und der Weg ohne A bleiben unverändert.
- Die LSA-Auswahl ist nicht berührt: `lsa_start`, `platz_next` und `lsa_im_pool` rufen
  `session_ziehen` nicht auf. Ihre Prod-Fassung ist gleich der aus den Migrationen.

**Ablauf bis zum Merge**

1. Zweitprüfung durch einen frischen Subagenten.
2. pgTAP grün in Kombination mit dev und mit dev + A2.
3. CI grün.
4. Eingespielt per `~/bin/mig` (Versions-Check, eine Transaktion).
5. Per `dbread` geprüft: History-Eintrag, Rumpf, `stable`, `security definer`, ACL unverändert.
6. Gemergt.

**Tests an §3.1 angepasst** (Entscheidung Rasit):

- `session_a2_fixture` bekommt `pg_temp.als_beispiel`. Der Helfer macht eine Testaufgabe zur ziehbaren
  `beispiel`-Instanz einer freigegebenen Test-Bauform.
- session_a2 (Fall 5, N), session_a2b (Fall 7) und session_a2d (F) legen die Instanz dort an, wo ein
  Beispiel erwartet wird.
- reihe1_d2_home_uebung wertet eine echte `home`-Instanz.

**Prod-Lage laut Analyse (nur lesend):**

- Zwei Bauformen, beide `zur_pruefung`. 109 Instanzen, alle `draft`.
- Session-Aufgaben ohne Bauform im Pool: 0.
- Folge: Eine echte Session läuft in Prod derzeit in `pool_leer`/`warten`, bis Bauformen freigegeben
  sind. Das war vor dem Merge schon so und betrifft die LSA nicht.

## Wacklige Tests (bekannt, keine Ursache im PR)

- `ThemenAuswahl.test.tsx` „Deutsch (kein Katalog)“: synchrones `getByRole` nach `findByText`. Behoben
  mit #357.
- `session_a2` Test 15 (Median unter 200 ms) auf dem CI-Runner: je einmal neu gestartet.
- Lokal zusätzlich rot, auch auf dev, in der CI grün: `lsa_testkinder`, `lsa_themenfeld`, `slots_sl2b`
  (lokale Umgebung).

## Testergebnisse

| Prüfung | Ergebnis |
|---|---|
| Edvancev1 dev `ef67b07e`: `npm ci`, typecheck, test | grün, 270 Dateien, 3220 Tests |
| edvance-app dev `d2160b46`: `npm ci`, typecheck, test, test:views | grün, 37 Dateien, 394 Tests; test:views 173 bestanden, 19 übersprungen |
| CI (quality, neuaufbau) je PR vor dem Merge | grün |
| `tools/schema-snapshot.sh` (Prod, nur lesend) gegen `schema-erwartet.sql` auf dev | **0 Abweichungen** (gefiltert) |
| Migrationen: Reihe-1-Dateien auf dev ↔ History in Prod | alle vorhanden; keine History ohne Datei ab 27.10. |
| Altbestand ohne History | `20261010132749`, `20261010132750` (Erklär-Checks vom 08.10., nicht Reihe 1) |
| Vercel Production | Edvancev1 `ef67b07e` und edvance-app `d2160b46`: success |

## Smoke-Test (Live, nur lesend)

- Gegen https://edvance-app.vercel.app und https://edvancev1.vercel.app, mit Playwright und Chromium.
- Aufrufe an `*.supabase.co` beantwortet eine Attrappe im Browser. Es gibt keine Anmeldung mit echten
  Daten, und nichts erreicht die Live-DB.

| Schritt | Ergebnis | Foto |
|---|---|---|
| Kiosk-Start der LSA bis zum Avatar-Schritt | OK | `lsa-1-hi.png`, `lsa-2-avatar.png` |
| App ohne Sitzung zeigt Login | OK | `app-login.png` |
| Admin-Login-Seite | OK | `admin-login.png` |
| `/admin/studio` ohne Anmeldung → `/login` | OK | `admin-studio-umleitung.png` |

## Rückweg

- **Vercel:** Im Dashboard die alte Bereitstellung wählen und „Promote to Production“.
  - Edvancev1: `edvancev1-9rr6haqe5-rasitguevens-projects.vercel.app` (Deployment 7355199427, `74b5b4b8`).
  - edvance-app: `edvance-ponts9qyp-rasitguevens-projects.vercel.app` (Deployment 7277854355, `e4cf268d`).
- **Git:** Marke `vor-reihe1-merge-20261028` in beiden Repos, gesetzt auf `origin/dev` vor dem ersten
  Merge. Zurück per Revert-PR der Merge-Commits (`git revert -m 1 …`), nicht per Force-Push.
- **DB:** Die einzige neue Migration ist `20261028125114`. Rollback:
  `supabase/rollback/20261028125114_reihe1_fix_session_ziehen_testlauf.sql` stellt die C2-Fassung von
  `session_ziehen` wieder her. Alle anderen Migrationen waren schon vor dem Merge in Prod.

## Offene Punkte

- #352 A5 (Entwurf, Migration nicht in Prod).
- Echte Sessions bleiben `pool_leer`, bis Bauformen freigegeben sind.
- `DATENVERTRAG.md` hat zwei Abschnitte mit der Nummer 13. Die Nummerierung sollte bei Gelegenheit
  bereinigt werden.
- `session_pool_anzahl` zählt den alten Pool und kann vom A-Weg abweichen (Hinweis aus der Analyse,
  ohne Testfehler, durch „Zweitprüfung C2-9“ abgefangen).
- Branches: Die gemergten `feat/rasit-reihe1-*` sind gelöscht, außer `feat/rasit-reihe1-a5-board`.
