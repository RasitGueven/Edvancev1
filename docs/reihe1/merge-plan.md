# Reihe 1 · Merge-Plan (28.10.2026)

Auftrag Rasit vom 28.10.2026: „Alles mergen.“ Ziel ist `dev` beider Repos, Merge-Art
echter Merge-Commit (`gh pr merge --merge`).

## Sicherung

| Repo | Marke | origin/dev vorher | Production vorher (Vercel) |
|---|---|---|---|
| Edvancev1 | `vor-reihe1-merge-20261028` | `74b5b4b8` | https://edvancev1-9rr6haqe5-rasitguevens-projects.vercel.app (Deployment 7355199427, 27.10. 09:46 UTC) |
| edvance-app | `vor-reihe1-merge-20261028` | `e4cf268d` | https://edvance-ponts9qyp-rasitguevens-projects.vercel.app (Deployment 7277854355, 23.10. 12:11 UTC) |

## Bestand

- Alle Reihe-1-Branches haben schon eine offene PR gegen `dev`. Keine PR neu angelegt.
  A1 = #334, A2 = #338, A3 = #342, A4 = #350, C6 = #349.
- edvance-app `feat/rasit-reihe1-d3-start` hat keine eigene PR; der Branch ist ganz in
  `feat/rasit-reihe1-d4-baum` (#57, „D3 Start und D4 Themenbaum“) enthalten.
- Nicht gemergt: #352 A5 (Entwurf, `feat/rasit-reihe1-a5-board`, Migration
  `20261027143548_reihe1_a5_board` nicht in Prod).
- Migrationen: 29 von 30 Reihe-1-Migrationen haben vor dem Merge einen History-Eintrag in Prod;
  die fehlende ist die von A5.

## Reihenfolge

a) Schnittstellen: edvance-app #51 (A0b), #50 (B0b), #49 (D0b); Edvancev1 #332 (C0b)

b) Edvancev1
- A: #333 A0 → #334 A1 → #338 A2 → #342 A3 → **edvance-app #55 A3-App** → #350 A4
- D: #331 D0 → #339 D1 → #344 D2
- B: #329 B0 → #336 B1 → #337 B2 → #340 B3 → #343 B4 → #346 B5 → #351 B6 → #354 B7 → #355 B8 → #356 B9
- C: #330 C0 → #335 C1 → #341 C2 → #347 C4 → #349 C6
- D Rest: #345 D2-Coach → #348 D4 → #353 D4b

c) edvance-app
- #56 B6-App
- #52 D1 → #57 D3/D4 → #58 D5 → #59 D6 → #60 D7
- #53 C3 → #54 C5

## Abweichungen vom Auftrag (Angabe in der PR maßgeblich)

- #350 (A4) nennt als Reihenfolge „… #342 → edvance-app#55 → diese PR“. Deshalb wird
  edvance-app #55 (A3-App) vor #350 gemergt statt im Block c.
- Alle übrigen „Baut auf“-Angaben stimmen mit der Planfolge überein.

## Protokoll

| Zeit (UTC) | Repo | PR | Phase | Merge-Commit | Bemerkung |
|---|---|---|---|---|---|
| 08:38 | edvance-app | #51 | A0b | `7a37a4e2` |  |
| 08:38 | edvance-app | #50 | B0b | `3f7acbe7` |  |
| 08:39 | edvance-app | #49 | D0b | `6ee6c815` |  |
| 08:42 | Edvancev1 | #333 | A0 | `628ee1a2` |  |
| 09:01 | Edvancev1 | #331 | D0 | `79c51dde` | DATENVERTRAG.md: Konflikt mit A0 gelöst (beide Abschnitte) |
| 09:10 | Edvancev1 | #339 | D1 | `1fab4aee` | DATENVERTRAG.md vereinigt |
| 09:15 | Edvancev1 | #329 | B0 | `da8a7859` | DATENVERTRAG.md vereinigt; neuaufbau 1× neu (session_a2 Laufzeit) |
| 09:15 | edvance-app | #56 | B6-App | `7c1addab` | auf dev gebracht, test:views 81/81 |
| 09:25 | Edvancev1 | #332 | C0b | `cf22ec03` | DATENVERTRAG.md vereinigt |
| 09:26 | Edvancev1 | #344 | D2 | `240be854` | quality 1× neu (ThemenAuswahl) |
| 09:26 | Edvancev1 | #330 | C0 | `2269f12b` |  |
| 09:39 | Edvancev1 | #336 | B1 | `a215afc4` | auf dev gebracht (DATENVERTRAG vereinigt) |
| 09:39 | Edvancev1 | #335 | C1 | `624856bb` | DATENVERTRAG + C/fortschritt vereinigt (Doppelzeile C0 entfernt), schema-erwartet.sql neu aus Wegwerf-DB |
| 09:40 | Edvancev1 | #345 | D2-Coach | `4c5638bf` |  |
| 09:52 | Edvancev1 | #337 | B2 | `6af2fcf0` | auf dev gebracht |
| 09:57 | Edvancev1 | #348 | D4 | `ef3dcf0b` | auf dev gebracht, schema-erwartet.sql neu; neuaufbau 1× neu (session_a2) |
| 09:58 | Edvancev1 | #341 | C2 | `e7510b44` | auf dev gebracht; Test reihe1_c2: zeigs_mir_offen create or replace |
| 10:06 | Edvancev1 | #340 | B3 | `a20e74d4` | auf dev gebracht; quality 1× neu (ThemenAuswahl) |
| 10:06 | Edvancev1 | #347 | C4 | `e6b76dcf` | auf dev gebracht |
| 10:07 | Edvancev1 | #353 | D4b | `3ad0f6f1` | auf dev gebracht, schema-erwartet.sql neu |
| 10:07 | edvance-app | #53 | C3 | `85b5cc58` | auf dev gebracht, database.ts neu erzeugt (identisch mit dev), test:views grün |
| 10:16 | Edvancev1 | #343 | B4 | `2efe7827` | auf dev gebracht |
| 10:29 | Edvancev1 | #349 | C6 | `a1ad313d` | auf dev gebracht (2×, da quality an ThemenAuswahl wackelte) |
| 10:41 | edvance-app | #52 | D1 | `56ca70c1` | auf dev gebracht (2×), database.ts neu erzeugt, test:views grün |
| 11:03 | edvance-app | #57 | D3/D4 | `69e83671` | auf dev gebracht, database.ts neu erzeugt, test:views grün |
| 11:24 | edvance-app | #58 | D5 | `ae8d9995` | auf dev gebracht, test:views grün |
| 11:46 | edvance-app | #59 | D6 | `6d55c5ea` | auf dev gebracht, test:views grün |
| 12:00 | Edvancev1 | #357 | Fix | `99027b1f` | ThemenAuswahl-Test (findByRole), Freigabe Rasit 28.10. |
| 12:18 | Edvancev1 | #334 | A1 | `10c6e4b8` | 5 Prüfskripte setzen einsatz (Freigabe Rasit 28.10.); auf dev gebracht |
| 12:37 | Edvancev1 | #346 | B5 | `c88e0dd0` | auf dev gebracht (nach #357 grün) |
| 12:42 | Edvancev1 | #351 | B6 | `9eb1c8bd` | auf dev gebracht, schema-erwartet.sql neu |
| 12:49 | Edvancev1 | #354 | B7 | `901cd1b6` | auf dev gebracht |
| 12:55 | Edvancev1 | #355 | B8 | `9bd2fcdf` | auf dev gebracht |
| 13:03 | Edvancev1 | #356 | B9 | `055ace26` | auf dev gebracht |
| 13:06 | Edvancev1 | #358 | Fix A2+C2 | `7904134e` | session_ziehen Testlauf-Rückfall; Zweitprüfung (P1 eingearbeitet); in Prod eingespielt 20261028125114, per dbread geprüft |
| 13:07 | edvance-app | #60 | D7 | `78067030` | auf dev gebracht, app.json beide Seiten (Splash D7 + expo-video), test:views grün |
| 13:18 | Edvancev1 | #338 | A2 | `fdf60bb9` | auf dev gebracht; session_r1 59; reihe1_c1/c2 Merge-Folgen; Beispiel-/home-Tests an §3.1 (Entscheidung Rasit) |
| 13:25 | Edvancev1 | #342 | A3 | `e9b17f4a` | auf dev gebracht |
| 13:32 | edvance-app | #54 | C5 | `140c1d01` | auf dev gebracht, test:views grün |
| 13:57 | edvance-app | #55 | A3-App | `d2160b46` | auf dev gebracht, app/_layout.tsx beide Seiten, test:views grün; vor A4 laut #350 |
| 13:57 | Edvancev1 | #350 | A4 | `ef67b07e` | auf dev gebracht; session_f1 Fall 6 Aufgabe ohne Bauform (Merge-Folge A4+C2) |
