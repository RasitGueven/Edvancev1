# Bericht Bauauftrag A · Sessionaufgaben (Sessionreihe 1)

Stand 28.10.2026. Protokoll: `fortschritt.md`. Alle Migrationen hat der Orchestrator nach grüner Zweitprüfung und
grüner CI eingespielt (Anweisung Rasit) und per dbread geprüft.

## PRs in Merge-Reihenfolge

| # | Repo | PR | Inhalt | Stand |
|---|---|---|---|---|
| 1 | Edvancev1 | #333 | A0 Ist-Analyse, Doppel-Aufgaben, Entscheidung Rasit | gemergt |
| 2 | edvance-app | #51 | A0b Schnittstellen (Formate, Lösungsbeispiel) | gemergt |
| 3 | Edvancev1 | #334 | A1 Pool-Trennung (1184 → lsa, CHECK, Guard) | gemergt, eingespielt |
| 4 | Edvancev1 | #338 | A2 Datenmodell Bauformen, A-Funktionen §9 | gemergt, eingespielt |
| 5 | Edvancev1 | #342 | A3 Formate Backend, Vorschau | gemergt, eingespielt |
| 6 | edvance-app | #55 | A3 Formate Player | gemergt |
| 7 | Edvancev1 | #350 | A4 Bauform-Motor, Pilot WZ-1, NP-2 | gemergt, eingespielt |
| 8 | Edvancev1 | #352 | A5 Lena-Board Bauformen, Melden | gemergt, eingespielt |
| 9 | Edvancev1 | #360 | RLS: Kinder lesen Instanzen nicht direkt | gemergt, eingespielt |
| 10 | Edvancev1 | #361 | VERA8 entfernen | gemergt, eingespielt |
| 11 | Edvancev1 | #362 | A6 Voraussetzungen (7 Bauformen) | gemergt, eingespielt |
| 12 | Edvancev1 | #363 | A6 Gleichungen (14 Bauformen) | gemergt, eingespielt |
| 13 | Edvancev1 | #364 | A6 Funktionen (24 Bauformen) | gemergt, eingespielt |
| 14 | Edvancev1 | A7 | Abnahme und Bericht (dieser PR) | – |

Auftragspunkt 4 (rote Session-Tests): Einen Merge-Bericht gibt es nicht. Die Session-Auswahl-Tests (session_a2/a2b/a2d,
session_f1/f2, reihe1_d2) sind seit #358 (Auftrag C) grün, eine Korrektur von A war nicht nötig.

## Migrationen

Alle eingespielt, keine wartet. Skripte unter `~/einspielen/A-*.sh`, Prüfabfragen im Protokoll. Rollbacks unter
`supabase/rollback/` (stilllegend, nichts gelöscht; VERA8: Restore aus `~/backups/`).

## Abnahme

| # | Fall | Beleg | Ergebnis |
|---|---|---|---|
| 1 | keine Aufgabe in beiden Pools, Versuch scheitert | pgTAP `reihe1_a1_pool` 1; Prod: `einsatz @> {lsa,session}` = 0 | ✓ |
| 2 | Session-Auswahl nie LSA, LSA-Auswahl nie Session | pgTAP `reihe1_a1_pool` 2–3, `lena_board_lsa_session` | ✓ |
| 3 | WZ-1 x² = 9: {3; −3}, {3} → Fehlbild, „keine Lösung“ falsch, Teilmenge → „Eine Lösung fehlt noch.“ | pgTAP `reihe1_a3_formate` 1 | ✓ |
| 4 | Feldmaske (x + 3)² − 1, Bedeutung statt Eingabe | pgTAP `reihe1_a3_formate` 2 | ✓ |
| 5 | Prüfmaschine verwirft jede Negativkontrolle | `scripts/bauformen/test_pruefmaschine.py` 16/16 (auch gegen die echte Wertung) | ✓ |
| 6 | Lena sieht NP-2 mit sechs Beispielen, „Andere Beispiele“, passt → zur Freigabe, Sammelfreigabe → aufgabe_ziehen | pgTAP `reihe1_a5_board` 6 | ✓ (live: Checkliste 3–5) |
| 7 | Meldung: nicht mehr gezogen; zweite Meldung pausiert die Bauform, „Auffällig“ | pgTAP `reihe1_a5_board` 7, `reihe1_a2_funktionen` 3 | ✓ (live: Checkliste 8) |
| 8 | zehn Antworten, viermal dieselbe unbekannte falsche → auffällig | pgTAP `reihe1_a2_funktionen` 4 | ✓ |
| 9 | home nie Stufe 4/5; Lösungsbeispiel für dasselbe Kind nie wieder | pgTAP `reihe1_a2_funktionen` 2 | ✓ |
| 10 | Textänderung → neue Version, für Lena offen, alte Instanzen nicht mehr gezogen | pgTAP `reihe1_a2_funktionen` 5, `reihe1_a4_motor` | ✓ |
| 11 | alle 47 Bauformen im Board mit grüner Prüfmaschine und bestandenem Blindlöser | Prod: 47 von 47 im Board, 47 Blindlöser bestanden, 0 Instanzen nicht grün; `blindloeser.md`; pgTAP `reihe1_a6_bauformen` | ✓ |
| 12 | alle Formate gleich in Player und Prüf-Vorschau | Fotos `abnahme/formate/` (Player, 56) und `abnahme/board/` (Vorschau) | teilweise: Vorschau-Fotos nur für Lösungsmenge; Rest live (Checkliste 9) |

Suite in der Wegwerf-DB (alle 410 Migrationen): 94 grün, 8 rot = genau `bekannt-rot.txt`. LSA-Tests vor und nach jeder
Migration grün. Web-Gate (A5): typecheck, lint, 3224 Tests grün.

## Bauformen

47 Bauformen, alle `zur_pruefung`, alle Blindlöser bestanden (`blindloeser.md`), Prüfmaschine: nur LSA-Zwillinge
verworfen. Instanzen gesamt: 2429, alle Pool session; LSA-Bestand unverändert (134 ready). Zweitprüfungen: `zweitpruefung-a5.md`, `-rls-instanzen.md`, `-vera8.md`,
`-a6-voraussetzungen.md`, `-a6-gleichungen.md`, `-a6-funktionen.md`.

## Lenas Prüfumfang

- **47 Bauformen**: je Steckbrief, sechs Beispiele wie auf dem Tablet, Fehlbilder, Hinweise, Lösungsweg. Schätzung
  4 Minuten je Bauform → rund **190 Minuten**.
- **15 Coach-Prüffragen** (je Kern-Skill 1–2), einzeln mit kurzem Text: rund 1 Minute je Frage → **15 Minuten**.
- Zusammen rund **3½ Stunden**, sinnvoll in zwei oder drei Sitzungen (z. B. Voraussetzungen und Gleichungen, dann
  Funktionen).

## Offene Punkte

1. **Figuren hochladen** (Rasit) vor der Freigabe: KO-1, SCH-2, PAR-2, PAR-3, NS-4 sind sonst nicht ziehbar.
2. **App-Types** `src/types/database.ts` neu erzeugen (Windows-CLI, Befehl in der Live-Checkliste); Schreiben der Datei
   war im Agentenlauf gesperrt.
3. **VERA8-Reste:** 10 LSA-Sitzungen (9 `completed`) mit VERA8 in `item_ids`, `result_summary` aus gelöschten
   Antworten; VERA8-Daten und Import-Skripte im Repo (`vera8-entfernen.md`). 13 der gelöschten Aufgaben waren `ready`
   (Klasse 8, ohne Skill) und fehlen im LSA-Bestand; Batu (Kl. 9, adaptive LSA nach Skill) ist nicht betroffen.
4. **Kleine Zahlenräume:** wenige Zwillinge bei BIN-2, QW-1 (Stufe 1–2), PAR-2, PAR-3 (Stufe 1–2), WZ-5, EX-3.
   Einige Katalog-Fehlbilder sind selten eingebbar (Antwort irrational), dann greift die allgemeine Rückmeldung.
5. **Player-Schrift:** Fraunces hat kein ₁, ₂, √ (Fallback-Schrift in PQ-3, WZ-5).
6. **Generator `koordinatensystem`:** an Nullstellen fehlt manchmal die Achsenzahl (NS-4).
7. **Testlauf-Rückfall** in `session_ziehen` (Auftrag C, #358) prüft die Figur-Bedingung nicht.
8. **`generator_hash`** deckt nur die Bauform-Klasse ab, nicht `formen.py`; nach Änderungen dort neu erzeugen.
9. **Vercel-Preview** war am 28.10. im Rate-Limit (kein Code-Fehler); CI `quality` und `neuaufbau` grün.
