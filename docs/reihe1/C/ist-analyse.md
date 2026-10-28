# Reihe 1 · C0 Ist-Abgleich

Stand 27.10.2026 · Edvancev1 origin/dev `74b5b4b8`, edvance-app origin/dev `e4cf268` · Prod gelesen per `~/bin/dbread` (read-only).
Belege `Datei:Zeile` beziehen sich auf origin/dev. Die gültige Fassung einer Funktion ist die zuletzt definierende Migration; der Prod-Text wurde per `pg_get_functiondef` gegengelesen.

## 1 · Session-Rahmen: was gebaut ist

| Paket | Stand | Beleg |
|---|---|---|
| Platz-Zuweisung für Sessions | gebaut. Tablet ↔ Kind über `session_tablets`, das Tablet kennt nur seinen Platz | `supabase/migrations/20261007110300_session_tablets.sql:27` (Tabelle), `:56` (`session_tablet_platz`) |
| Antworten und Versuche | gebaut. `session_antworten` mit `teil`, `versuch_nr`, `hinweisstufe_max`, `fehlbild_slug`, `phase`; Abgabe über `antwort_abgeben` | `20261007110500_session_antworten.sql:29`; `20261013151305_t3_session_testlauf_inhalte.sql:86` |
| `session_naechster_schritt` | gebaut (A2). Phasen `checkin/warmup/kern/checkout` nach Session-Uhr; Schrittarten `aufgabe, beispiel, erklaerung, erklaerung_angebot, exit, termin, fertig, warten` | `20261009101205_a2b_session_xp.sql:48`; Planer `20261008122232_a2_naechster_schritt.sql:11`; Uhr `20261008121014_a2_grundlagen.sql:84` |
| Fall-Hierarchie | gebaut: Klassenarbeit (Datum ≤ `ka_tage` = 7 Tage) → Schulthema (`lead_themen.status='aktuell'`) → Lernpfad (nächste Lücke) | `20261007110400_session_checkin.sql:53` (`session_fall_berechnen`); `session_fall`, `session_zielliste` `20261013160412_t4_pfad_testlauf.sql:246` |
| Zielquote | gebaut: Fenster der letzten 5 erledigten Aufgaben, ±10 % um `ziel_erfolgsquote` 0,80 → Stufe ±1 | `20261008122230_a2_bausteine.sql:56` (`session_niveau`) |
| Modi geführt / selbstständig | gebaut: selbstständig, sobald je eine Aufgabe des Skills richtig ohne Hinweis | `20261008122230_a2_bausteine.sql:118` (`session_modus`) |
| Mischanteil | gebaut: `mischanteil` 0,30, Kandidaten aus sicheren Skills | `20261011100100_c3_schritte_details.sql:21` (`session_plan_kern`), `20261008122230_a2_bausteine.sql:230` |
| Stellschrauben mit Protokoll und Snapshot je Session | gebaut: `session_einstellungen` (+ `_protokoll`), Snapshot in `coaching_sessions.einstellungen` beim Start, Lesen über `session_wert` | `20261007110100_session_einstellungen.sql:39,101`; `20261007110200_session_ablauf.sql:198` (`session_starten`) |
| Erklärsequenz E1 / Player E2a | gebaut: `erklaer_kernidee`, `erklaer_start`, Mini-Checks mit Rücksprung; Player `SequenzPlayer` | `20261007134931_erklaer_datenmodell.sql`, `20261008124414_a2_erklaer_testlauf.sql:106`; app `src/components/sequenz/SequenzPlayer.tsx:18` |
| Coach-Live C1 | gebaut: `/coach/session/:id/live`, Vorher/Check-in/Live/Check-out/Danach, Poll 4 s | `src/App.tsx:434`, `src/pages/coach/live/CoachLivePage.tsx:29-49`, `src/hooks/useRaumLive.ts:30` |
| Mastery-Vorschlag und Coach-Bestätigung | gebaut: `stand_system` (`kandidat`) getrennt von `stand_coach`; `mastery_vorschlaege`, `mastery_entscheiden` | `20261013162108_t4_beleg_und_schalter.sql:13` (`lernpfad_beleg_core`); `20261008121015_a2_ziel.sql:197`; `20261013140852_t2_lernpfad_testlauf.sql:23` |
| `pfad_tiefer` | gebaut: Signal „eine Stufe tiefer?“ nach `signal_fehlversuche` = 2 im Warm-up | `20261013140852_t2_lernpfad_testlauf.sql:85`; Signal in `session_plan_warmup` `20261011140300_f1_warmup_reihenfolge.sql:13` |
| Exit-Aufgaben | gebaut: `exit_aufgaben` = 2 im Check-out, ohne Hinweise | `20261008123105_a2_checkout.sql:23` |
| Check-in am Tablet | gebaut: Stimmung, Klassenarbeitsdatum, Thema; `checkin_kind_speichern` | `20261007110400_session_checkin.sql:113`; app `src/components/session/CheckIn.tsx:26,65-71,150-170` |

**Fehlt (gehört C):**
- Keine Reihe und kein Reihenplan (keine Tabelle, keine Funktion `reihenplan_kind`).
- Warm-up kennt keine Fälligkeit (Abstand 1 → 2 → 4). Es zieht sichere Skills nach Fokus, Voraussetzung, Stand und Graph-Abstand (`20261011140300_f1_warmup_reihenfolge.sql:13`), Stufe = Niveau − `warmup_leichter_stufen`.
- Lösungsbeispiel ist eine normale Aufgabe mit Lösungsweg (`session_aufgabe_waehlen(..., p_mit_loesungsweg)`), keine Rolle `beispiel`. Das „nie wieder“ gilt schon: `benutzt` schließt alle `art='beispiel'` des Kindes aus (`20261008122230_a2_bausteine.sql:133`).
- Kein Transfer, kein Recap, keine Generalprobe, keine Wirkung von „Zeig's mir“ (in DB und App nicht vorhanden).
- Keine Rollen und Stufen auf `tasks`: Auswahl über `skill_key` + `difficulty`/`afb` (`session_schwierigkeit`). Das kommt mit A1/A2.
- Check-out hat den Schritt `termin` (Quest-Tage) in DB (`session_plan_checkout`, nur bei `home_quests_aktiv` = true, derzeit false) und App (`Schritte.tsx:97-153`). Entfällt nach Entscheidung 27.10.

**Halte-Befund (Bauauftrag „C0 zeigt, dass der Rahmen in wesentlichen Teilen nicht gebaut ist“):** trifft **nicht** zu. R1, A2, E1/E2a und C1 sind gebaut; es fehlen nur die Reihe-1-Teile, die dieser Auftrag ohnehin baut.

## 2 · Schulthema und Klassenarbeiten

- `lead_themen (lead_id, fach, thema_key, status aktuell|behandelt, quelle)` — `20261001114732_themen_schulplaene_schema.sql:151`. Das Schulthema der Session ist die jüngste Zeile `aktuell` (`session_schulthema`).
- `lead_klassenarbeiten (lead_id, fach, schuljahr, nr, datum, thema_keys[], status bevorstehend|geschrieben, note, quelle erstgespraech|checkin|admin)` — `20261027081403_ka_folge.sql:67`. Neu seit L5; RLS nur Admin. Es gibt im Repo noch keinen Schreiber mit `quelle='checkin'`.
- `schul_klassenarbeiten` (bestätigte Arbeiten je Schule/Klasse) — `20261027081403_ka_folge.sql:119`; `ka_folge_lead` `20261027092031_ka_folge_vorrang.sql:14`.
- Alt: `leads.next_exam_date`, `next_exam_topic`, `klassenarbeit_status`.
- Check-in: `session_checkin.klassenarbeit_datum` (vom Kind am Tablet), `klassenarbeit_thema_key`, `fall_vorschlag`, `fall_coach`, `ziel_thema_key` — `20261007110400_session_checkin.sql:13`. Der Coach kann das Datum **nirgends** erfassen oder bestätigen; `checkin_coach_setzen` hat keinen Datumsparameter (`src/lib/supabase/sessionCoach.ts:40-48`, `src/pages/coach/live/CheckinZeile.tsx:39-72`, nur Anzeige). Datumseingabe nur im Admin (`src/pages/admin/klassenarbeiten/KaArbeitKarte.tsx:77`).
- `schul_themenplan (schule_id, fach, klasse, position, thema_key, halbjahr)` — `20261001114732_themen_schulplaene_schema.sql:107`.
- `skill_thema` — `20261003104615_skill_thema_schema.sql:26`; Prod: `quadratische_funktionen` = parabel, scheitel, normalform, nullstellen, extrem; `quadratische_gleichungen` = wurzel, faktor, formel, anzahl.
- `skill_kante` — `20260722130000_a14_skill_substrat.sql:51`. Prod (dbread): `fkt_quadr_nullstellen → gleichung_quadr_formel` (zieht Thema 2 hinein), `gleichung_quadr_formel → gleichung_quadr_wurzel`, `fkt_quadr_parabel → geo_koordinaten, term_einsetzen`, `fkt_quadr_normalform → term_binom_quadrat, fkt_quadr_scheitel`, `gleichung_quadr_faktor → term_ausklammern, gleichung_einschrittig`, `gleichung_quadr_wurzel → zahl_wurzel_quadrat, gleichung_zweischrittig`, `fkt_quadr_extrem → gleichung_modellieren`, `fkt_quadr_nullstellen → term_binom_faktorisieren`.
- Batu in Prod: Testleads „Batu Test1“ (`194e35b1…`, Klasse 9, Schüler `a5eb5b0b…`) und „Batu Test2“; Schulthema `reelle_zahlen` aktuell. Keine Zeile in `lead_klassenarbeiten`.
- Ferien und Feiertage: `ferien_nrw` (`20260925120000_vertraege_erweiterung.sql:31`, 17 Zeilen), `feiertage_nrw` (`20260929100000_schuelerakte_basis.sql:43`). Termine: `slot_assignments`, `slot_zeiten`, `slots_naechste_termine_frei` (Slots S1–SL3).
- **Kernideen-Katalog fehlt:** `erklaer_kernidee` hat für die neun Kern-Skills nur einen Platzhalter (`gleichung_quadr_faktor` Nr. 1, entwurf). `tasks.kernidee_key` legt A an (Bauauftrag A, A1.2). C braucht für die Planung den Katalog aus Konzept §2.1 (19 Kernideen) als eigene Tabelle.

## 3 · Befunde je Skill

- Beleg: `lernpfad_beleg_core` bucht je bewerteter Session-Aufgabe eine Zeile `lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt, zeit)` und setzt `lernpfad.stand_system` (`aktiv`, `sicher` bei ≥ `mastery_richtig_ohne_hinweis` = 2 richtig ohne Hinweis in der Session, `noch_nicht_sicher`, `kandidat`) — `20261013162108_t4_beleg_und_schalter.sql:13`. Aufrufer: `antwort_abgeben` (`20261013151305_t3_session_testlauf_inhalte.sql:86`). Testläufe schreiben keine Belege.
- LSA-Befunde: `lernpfad_lsa_urteile` / `lernpfad_aus_lsa` (`20261007120414_lernpfad_uebernahme.sql:21,42`), Zustand `traegt` u. a.
- „Stufe“: es gibt keine gespeicherte „sichere Stufe“. `session_niveau.start` = Schwierigkeit der zuletzt richtig gelösten Aufgabe außerhalb der Session (auch LSA), sonst 2.
- Themenbaum: in edvance-app gibt es keinen (`src/components/themenbaum/` fehlt). Offen-Regeln baut D (`kompetenz_offen`).

## 4 · Session-Bildschirme in edvance-app

- Routen `app/(student)/session/`: `warten.tsx:16` (LsaWarten), `index.tsx:23-29` → `SessionAblauf`, `vorschau.tsx` (Entwicklung). Ein Bildschirm für alle Phasen: `src/components/session/SessionAblauf.tsx`. Weiche `KioskGate` `app/_layout.tsx:112-120`, `src/components/session/ablauf.ts:29-93`.
- Navigation: der Server entscheidet (`naechsterSchritt` → `session_naechster_schritt`, `src/lib/queries/session.ts:106-111`), ausgelöst durch „weiter“; nur bei `warten` Poll 4 s (`ablauf.ts:141-143`).
- Vorhanden: Begrüßung als Teil des Check-ins (`CheckIn.tsx:26`), Warm-up/Kern über `AufgabeSchritt` (`SessionAblauf.tsx:227-246`), Erklärung `SequenzPlayer` (`:209-223`), Lösungsbeispiel `BeispielSchritt` (`:247-248`), Erklärangebot (`:253-262`), Check-out exit → `TerminSchritt` → `FertigSchritt` (`:263-280`).
- Fehlt: Video-Player, Transfer, Recap, Generalprobe, Zeile „n× zuhause geübt“.
- Phasenleiste: `SessionKopf` `src/components/session/SessionRahmen.tsx:85-124`, aktiv in Gold.
- Rückmeldung: richtig Gold, falsch `akademie.fehler*` (`AufgabeSchritt.tsx:191-196`, `ablauf.ts:152-179`); Mastery-Grün nur bei bestätigtem „gemeistert“ (`Ueberlagerungen.tsx:71-84`).
- **Termin-Wahl im Check-out: ja**, `TerminSchritt` `src/components/session/Schritte.tsx:97-153`, Speichern `quest_termin_setzen` (`SessionAblauf.tsx:155-166`). Wird in C3 entfernt.
- Ansichtstests: `npm run test:views` (Playwright nach Web-Export); Session-Vorschau nur 1180 × 820 (`tests/views/session-vorschau.spec.ts:27`); kein Hochformat-Test.

## 5 · Coach-Sicht (Edvancev1)

| Teil | Komponente | Daten |
|---|---|---|
| Vorher-Briefing | `src/pages/coach/live/VorherAnsicht.tsx` (Klassenarbeit nur Anzeige, `:12-29`) | `session_briefing` |
| Check-in | `CheckinAnsicht.tsx:21`, je Kind `CheckinZeile.tsx:23` (Fall `:111`) | `checkin_coach_setzen`, `tablet_zuweisen` |
| Live-Kacheln | `LiveRaster.tsx:40-82` (`KindKachel`) | `coach_raum_live` |
| Kind-Detail | `Schublade.tsx:14,65-76`, Aufgabe `SchubladeBloecke.tsx:114-150` | `coach_kind_detail` |
| Check-out | `CheckoutAnsicht.tsx:14,128` (Quest-Termin `:81-90`) | `abschluss_setzen`, `quest_termin_setzen` |
| Danach | `DanachAnsicht.tsx:35` | `session_abschliessen` |

Einbaupunkte (C0b): Check-in je Kind nach `CheckinZeile.tsx:101` (eigene volle Zeile); Kind-Detail an der Aufgabe in `Schublade.tsx:71` hinter `<AufgabeBlock>` (dort sind Kind und Aufgabe bekannt).

## 6 · Projekt-Ref von Prod

`ztcppihxqcphlqaguhma` (aus `VITE_SUPABASE_URL` in `.env`; `supabase/config.toml:5` trägt nur `project_id = "Edvancev1"`). `select current_database()` per dbread: `postgres`. Die Zielprüfung der Einspiel-Skripte prüft beides.

## 7 · Abnahme-Umgebung

pgTAP läuft in der CI (`.github/workflows/schema.yml`, Job `neuaufbau`: alle Migrationen, `seed.sql`, dann `supabase/tests/*.test.sql`, Postgres 16). Lokal: eigener Wegwerf-Cluster (Port 55443, `~/wegwerf-db-c`) aus allen Migrationen + Seed. Die Shadow-DB wird nicht benutzt. Schreibende Abnahmefälle laufen dort in der Testtransaktion.

## 8 · Stand der anderen Aufträge (27.10., 14 Uhr)

Keine Funktion von A, B oder D in Prod (`pg_proc`: kein `aufgabe_ziehen`, `home_uebung_kurz`, `zeigs_mir_offen`, `erklaer_start` mit Video). A hält an A0 (Doppel-Aufgaben, wartet auf Rasit). `../Edvancev1-A/docs/reihe1/A/an-C.md` gibt es noch nicht.

## Tabelle

| Konzept (Abschnitt) | gebaut | fehlt | gehört zu |
|---|---|---|---|
| Reihe §2.1 Skills über Graph | `skill_thema`, `skill_kante` | Kernideen-Katalog, Hüllenbildung | C |
| Reihe §2.2–2.3 Fahrplan, Planungsregeln | Slots, Ferien | Reihe, Plan mit Versionen, Planungsfunktion, `reihenplan_kind` | C |
| Reihe §2.3.5 „kann entfallen“ | – | `skill_kann_entfallen` | A (C: Rückfall-Liste) |
| Reihe §2.4 Warm-up mit Abruf | Warm-up 3 Aufgaben, Stufe −1, `pfad_tiefer` | Fälligkeit 1/2/4, Voraussetzungen des heutigen Plans, keine Hinweise erzwingen | C |
| Reihe §2.5 Generalprobe | – | alles | C |
| Ablauf §3 Erklärsequenz | E1, E2a Karten | Video | B (`ErklaerVideo`, `erklaer_start` mit Video) |
| Ablauf §3 Geführt / Lösungsbeispiel | Beispiel aus Aufgabe mit Lösungsweg | Rolle `beispiel`, Ansicht | A (Rolle, Ansicht), C (Auswahl) |
| Ablauf §3 Selbstständig, Zielquote, Mischen | gebaut | Rollen/Stufen über `aufgabe_ziehen` | A (Funktion), C (Aufruf) |
| Ablauf §3 Transfer ab Stufe 3 | – | alles | C (Formate: A) |
| Ablauf §3 Recap | – | alles | C |
| Ablauf §1 Check-out ohne Quest-Tage | Exit, Termin-Wahl | Termin-Wahl entfernen, Themenbaum-Ausschnitt | C (Ausschnitt: D) |
| §9 „Zeig's mir“ Wirkung | – | Kernarbeit-Start | C (`zeigs_mir_offen`: D) |
| §9 Begrüßung „n× zuhause geübt“ | – | Zeile | C (`home_uebung_kurz`: D) |
| Coach: Klassenarbeitsdatum im Check-in | Anzeige | Erfassen/Bestätigen | C |
| Coach: Reihe im Briefing / Kind-Detail | – | Karte „Reihe“, Warnung, Verschieben | C |
| Coach: Einbaupunkte | – | Check-in, Kind-Detail | C (C0b) |
| Formate, Pool-Trennung, Bauformen | – | alles | A |
