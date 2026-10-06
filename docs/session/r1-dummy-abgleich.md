# Dummy-Abgleich R1

Jedes Datum, das `docs/session/coach-live-dummy.html` anzeigt, mit seiner Quelle. „R1“ heißt: Tabelle oder Funktion
aus den Migrationen `20261007110100`–`110800`. Felder von `coach_raum_live` (Raum) und `coach_kind_detail` (Detail)
sind mit Pfad angegeben. „P2“ heißt: aus R1-Daten in der Oberfläche berechnet, keine neue Quelle nötig.

## Kopf und Phasenleiste (alle Zeitpunkte)

| Datum im Dummy | Quelle |
|---|---|
| Session-Uhrzeit, Raum | `coaching_sessions.scheduled_at`, `room` → Raum `session.scheduled_at`, `session.room` |
| Fach „Mathematik“ | kommt mit C2 (`coaching_sessions` hat kein Fach, offener Punkt 4) |
| „Klasse 8 bis 10“ | P2 aus Raum `kinder[].klasse` (`students.class_level`) |
| Coach „Sara Özdemir“ | Raum `session.coach_name` (`profiles.full_name`) |
| Uhr, „Minute 32 von 60“, „beginnt in …“ | P2 aus `session.gestartet_am` bzw. `scheduled_at` und `stand` |
| Phasendauern 5 / 10 / 40 / 5 Min | `session.einstellungen` (`phase_checkin_min`, `phase_warmup_min`, `phase_checkout_min`; Kernarbeit = Rest der 60 Min) |
| aktuelle Phase, Markierung „jetzt“ | P2 aus `gestartet_am` + Dauern; je Kind `kinder[].phase` (`session_ereignisse` `phase_wechsel`) |

## Vorher (Briefing)

| Datum | Quelle |
|---|---|
| „Wer kommt“, „5 von 5 Plätzen gebucht“ | `session_students` → Raum `kinder[]` (Name `session_kind_name`, Klasse) |
| Thema + „Schulthema seit 15.09.“ | `lead_themen` (aktuell, `angelegt`) → Raum `kinder[].schulthema_key`; Datum „seit“ kommt mit C2 (Briefing-Funktion) |
| Tag „Schulthema 4 Wochen alt“ | Stellschraube `thema_alt_tage` + `lead_themen.angelegt`, Briefing kommt mit C2 |
| Tag „Klassenarbeit Do 08.10.“ | `session_checkin.klassenarbeit_datum` der letzten Session; Briefing kommt mit C2 |
| Tag „Mastery-Prüfung fällig“, „Im Blick: saß am 29.09. ohne Hinweis“ | kommt mit A1 (Kandidat, Belege) |
| Tag „3 Signale am 29.09.“, „zweimal dasselbe Fehlbild“ | `session_antworten.fehlbild_slug`, `session_ereignisse` früherer Sessions; Briefing kommt mit C2 |
| „Plan“ | kommt mit A1 (`ziel_fertigkeiten`, `naechste_luecke`) |
| Tag „erste Session nach der LSA“, LSA-Befund | kommt mit A1 (Übernahme aus LSA) |
| „Notiz … Sara, 29.09.“ | `schueler_notizen` (Abschluss schreibt sie über `notiz_anlegen`) |
| „Quests 2 von 2 erledigt“ | kommt mit Q1 |
| „Heute im Blick“-Liste | wie die Zeilen oben (A1, C2, `session_checkin`) |
| „Check-in starten“, „Ab 16:25 möglich“ | `session_starten` (R1); Zeitfenster kommt mit C2 |

## Check-in

| Datum | Quelle |
|---|---|
| Tablet 1–5, frei / belegt, Name, Kl. | `session_tablets` → Raum `kinder[].tablet_nr`; `tablet_zuweisen` / `tablet_loesen` |
| „x von 5 belegt“ | P2 aus Raum `kinder[].tablet_nr` |
| Ankommen: „ist da“ / „erwartet“ | Raum `kinder[].anwesenheit` (`session_students.attendance`, `present` setzt `tablet_zuweisen`); „ist da, noch ohne Platz“ ist reiner UI-Zustand (C2) |
| Stimmung | `session_checkin.stimmung` → Raum `kinder[].stimmung` |
| Klassenarbeit (Datum, Thema) | `session_checkin.klassenarbeit_datum`, `klassenarbeit_thema_key` → Raum `klassenarbeit_datum` |
| „Kind sagt: noch dran / neues Thema: Steigung“ | `session_checkin.thema_antwort`, `thema_stichwort` → Raum `thema_antwort`, `thema_stichwort` |
| gespeichertes Schulthema | `lead_themen` aktuell → Raum `schulthema_key` |
| Schulthema-Suche (Name, Schlagworte, Stufe zuerst, höchstens 6) | `themen` (wie Erstgespräch, `src/lib/supabase/themen.ts`), Suche in der Oberfläche (C2); Speichern `checkin_coach_setzen(p_thema_key)` |
| Fall mit goldenem Vorschlag, „von dir geändert“ | `session_checkin.fall_vorschlag` / `fall_coach` → Raum `fall_vorschlag`, `fall_coach`, `fall`; `fall_vorschlag()`, `checkin_coach_setzen(p_fall)` |
| Ziel der Stunde (Text) | `session_checkin.ziel_thema_key` → Raum `ziel_thema_key`, `ziel_thema_label`; bei Lernpfad kommt mit A1 |
| „fertig · Warm-up“ / „füllt aus am Tablet“ | Raum `checkin_fertig`, `phase` |
| „kurz ansprechen“ (angespannt) | Signal `hinweis/stimmung` aus `raum_signale` |

## Warm-up und Kernarbeit: Kacheln

| Datum | Quelle |
|---|---|
| Statusband (läuft, hängt, Entscheidung, Mastery-Prüfung, angespannt) | Raum `kinder[].status` (höchstes offenes Signal aus `session_signale_intern`) |
| Platz-Nr., Vorname, Kl. | Raum `tablet_nr`, `name`, `klasse` |
| „Warm-up · Abruf 2 von 3“ | Raum `aufgabe.phase`, `aufgabe.nr_in_phase` + Stellschraube `warmup_aufgaben` |
| „Schulthema · Üben“, „Klassenarbeit Do · Üben“ | Raum `fall` + `phase`; „Üben“/„Erklärsequenz“ kommt mit E1 |
| Skill-Name („Klammern ausmultiplizieren“) | Raum `aufgabe.skill_key`; Klartext kommt mit A1 (`skills`) |
| Punkte richtig / falsch / mit Hinweis / aktuell | Raum `ergebnisfolge[]` (`ergebnis`, `hinweisstufe_max`) + `aufgabe` |
| „Aufgabe 6“ | Raum `aufgabe.nr_in_phase` |
| „5 von 5 richtig“, „1 von 3 richtig“ | P2 aus `ergebnisfolge` |
| „über Ziel 80 %“ | P2 aus `ergebnisfolge` + `session.einstellungen.ziel_erfolgsquote` |
| „2 Hinweise genutzt“, „keine Hinweise“ | Raum `hinweise_genutzt` |
| „hängt · 2 Fehlversuche“ | Signal `haengt/fehlversuche`, `details.anzahl` |
| „4 Min ohne Eingabe“ | Signal `haengt/ohne_eingabe`, `details.minuten` |
| „kam 16:36, sechs Minuten später“ | Raum `kinder[].tablet_seit` (`session_tablets.zugewiesen_am`); Differenz zu `gestartet_am` in P2 |
| „Vorschlag: eine Stufe tiefer“ | Signal `entscheidung` (gemeldet über `signal_melden`, Auslöser kommt mit A1) |
| „Mastery-Prüfung möglich / fällig“ | Signal `kandidat` (`signal_melden`, kommt mit A1); Raum `mastery_kandidat` Platzhalter |
| Erklärsequenz-Balken, „Kernidee 2 von 3“, „Extrarunde Variante B“ | kommt mit E1 (Raum `erklaersequenz` Platzhalter) |
| „Pfad tiefer gesetzt von Sara“ | `session_ereignisse` `entscheidung_pfad` → Detail `entscheidungen[]` |
| „ältere Themen pausiert bis Donnerstag“ | Fall `klassenarbeit` + Stellschraube `ka_tage`; Mischen kommt mit A1 |
| Legende | statisch |

## Warteschlange „Als Nächstes“

| Datum | Quelle |
|---|---|
| Reihenfolge Mastery-Prüfung → Entscheidung → hängt → Hinweis, älteste zuerst | `raum_signale` / Raum `signale[]` (`rang`, `seit`) |
| Titel, Untertitel („2 Fehlversuche bei Aufgabe 5“, „Signal ab 3 Min“) | `signale[].art`, `grund`, `details` + `session.einstellungen` |
| Alter („gerade“, „1 Min“, „seit 16:42“) | P2 aus `signale[].seit` und `stand` |
| „x offen“ | P2 aus `signale[]` |
| „Mastery-Prüfungen in dieser Session: 0 von 3“ | Deckel `mastery_kandidaten_je_raum` (R1); Zähler `session.mastery_bestaetigt` Platzhalter, kommt mit A1 |
| „Nichts offen. Alle arbeiten.“ | leere `signale[]` |

## Schublade je Kind

| Datum | Quelle |
|---|---|
| Kopf: Name, Platz, Kl., Phase | Detail `name`, `tablet_nr`, `klasse`, `phase` |
| Mastery-Prüfung: Skill, Belege, Prüffrage, Erwartung, Kriterium, Vertagen-Gründe, Bestätigen | kommt mit A1 (`skill_pruefung`, `mastery_entscheiden`) |
| Entscheidung „eine Stufe tiefer?“ mit Belegen | Signal `entscheidung` (`details`), Belege aus Detail `versuche[]`; Buchen `pfad_entscheiden` (R1), Umsetzen kommt mit A1 |
| „entschieden von Sara um …“ | Detail `entscheidungen[].von`, `zeit` |
| Info-Block (angespannt, Klassenarbeit), „Angesprochen“ | Detail `stimmung`, `klassenarbeit_datum`; `signal_erledigen(…, 'hinweis')` |
| Ziel der Stunde: Liste der Fertigkeiten mit Stand | kommt mit A1 (`ziel_fertigkeiten`); Fall-Pille aus Detail `fall` |
| Erklärsequenz (Kernideen, Variante, „Jonas sieht gerade“) | kommt mit E1 |
| Aufgabe: Titel, Text | Detail `aufgabe_detail.payload` (`lsa_question_payload`) |
| Musterlösung „nur auf deinem Gerät“ | Detail `aufgabe_detail.musterloesung` (`task_solutions.solution`), `correct_answers` |
| „Letzte Eingabe“ | Detail `aufgabe_detail.letzte_eingabe`, Ergebnis aus `versuche[]` |
| Falsche Antworten: Versuch, Eingabe, Fehlbild | Detail `versuche[]` (`eingabe`, `ergebnis`, `fehlbild_slug`, `fehlbild_klartext`) |
| Genutzte Hinweise mit Stufe und Text | Detail `hinweise[]` |
| Eingreifen-Leiter 1–4, „passt jetzt“ | Notieren `eingriff_notieren` (R1); Empfehlung „passt jetzt“ kommt mit C2 (aus Signalen) |
| „Fehlbild für Stufe 3 und 4 … vorbelegt aus dem letzten Versuch“ | Detail `versuche[]` letzter `fehlbild_slug` |
| „Notiert: Stufe n“ | Detail `eingriffe[]` |
| „Signal erledigt“ | `signal_erledigen` |
| „Heute“: Warm-up / Kernarbeit / Eingemischt je Zeile | P2 aus Detail `versuche[]` (`phase`, `eingemischt`, `ergebnis`) + `session.einstellungen.mischanteil` |
| Hinweis auf Mischanteil | Stellschraube `mischanteil` |

## Check-out

| Datum | Quelle |
|---|---|
| „Exit 2 von 2“ | `session_kind_abschluss.exit_ergebnis` (`abschluss_setzen`, sonst beim Abschluss aus Antworten der Phase `checkout`); vorher P2 aus `ergebnisfolge` |
| „8 Aufgaben, 7 ohne Hilfe richtig · …“ | P2 aus `ergebnisfolge`; nach dem Abschluss `zusammenfassung` |
| Satz (Vorschlag, „Anderer Vorschlag“) | Text `satz_text` (R1); Bausteinkatalog kommt mit C2 |
| „Als gesagt markieren“ | `session_kind_abschluss.satz_gesagt` |
| Quest-Termin „von Mila gewählt“ | `session_kind_abschluss.quest_termin`, `quest_termin_von` (`quest_termin_setzen` vom Tablet); Quests selbst kommen mit Q1 |
| Notiz für die Akte | `session_kind_abschluss.notiz` (`abschluss_setzen`, Wortliste geprüft) |
| Flags „Elternkontakt nötig“, „Pfad passt nicht“ | `session_kind_abschluss.flag_eltern`, `flag_pfad` |

## Danach

| Datum | Quelle |
|---|---|
| „Notiz fehlt: …“ | P2 aus `session_kind_abschluss.notiz` (über eine Lesefunktion, kommt mit C2) |
| „Mastery-Prüfung offen / vertagt / gemeistert“ | kommt mit A1 |
| „Pfad geändert: Emir eine Stufe tiefer“ | `session_ereignisse` `entscheidung_pfad` → Detail `entscheidungen[]`, nach Abschluss `zusammenfassung.entscheidungen_pfad` |
| „Elternkontakt: …“, „Pfad passt nicht: …“ | `session_kind_abschluss.flag_*` → `session_flags_offen()` |
| Anwesend 5 von 5 | `session_abschliessen` → `anwesend`; `session_students.attendance` |
| Einheit verbraucht 5 | `session_abschliessen` → `einheit_verbraucht` (`einheit_verbraucht()`) |
| Aufgaben bearbeitet 36 | `zusammenfassung.aufgaben` je Kind |
| Eingriffe ab Stufe 3 | `zusammenfassung.eingriffe_ab_3` |
| Mastery bestätigt / vertagt | kommt mit A1 (`zusammenfassung.mastery_entscheidungen` Platzhalter) |
| Erklärsequenzen abgeschlossen | kommt mit E1 |
| Satz gesagt x von 5 | `session_kind_abschluss.satz_gesagt` |
| Notizen x von 5 | `session_kind_abschluss.notiz`, `notiz_id` |
| Quest-Termine x von 5 | `session_kind_abschluss.quest_termin` |
| „Session abschließen“, „Abgeschlossen um 17:35“ | `session_abschliessen`, `coaching_sessions.beendet_am` |
| Stellschrauben, mit denen die Session lief | `coaching_sessions.einstellungen` (Snapshot) |

## Schalter „Stellschrauben“

| Datum | Quelle |
|---|---|
| Name, Startwert, Spanne je Stellschraube | `session_einstellungen` (`beschreibung`, `startwert`, `min`/`max`/`werte`, `einheit`) |
| aktueller Wert in der Session | `coaching_sessions.einstellungen` |
| Änderung durch Admins, Protokoll | `einstellung_setzen`, `session_einstellungen_protokoll` |
