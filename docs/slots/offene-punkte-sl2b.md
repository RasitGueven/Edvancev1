# Slots SL2b — Testkonten in den Slots, offene Punkte

Stand: 12.10.2026 · Paket SL2b · Branch `feat/rasit-slots-sl2b-testkonten` (ab `origin/dev` 0a60904)

## Was gebaut ist

| Entscheidung (Rasit, 12.10.) | Wo |
|---|---|
| 1 Testkonten mit laufendem Vertrag bekommen Stammplätze und Termine | `slots_kind_zugelassen` (die eine Stelle), `slots_kinder_basis` fragt sie statt `ist_test` selbst zu filtern |
| 2 Kennzeichen „Test“ in Wochenplan, Termin, Kinder, Kind | `slots_kind_info.ist_test` (jedes Kind-Objekt), `slots_zelle.test`; Oberfläche `TestKennzeichen` über `KlasseFach`, Wochenzelle, Kind-Seite |
| 3 Kennzahlen ohne Testkonten, Platz bleibt belegt | Kopf von `slots_woche`, `slots_zaehler`; `slot_belegt` unverändert |
| 4 Testkonto und echtes Kind nie im selben Termin (SL013) | `slots_art_konflikt` in `slots_stammplatz_gruende`, `slots_zusatz_code` (Zusatztermin, Umbuchung, Ziele, Kandidaten), `absage_zuruecknehmen`, `slots_plan_rechnen` (überspringt), `slots_frei.art_konflikt` |
| 5 Festschreiben nur mit Testkonten → Testlauf | `termin_session_anlegen` setzt `testlauf` beim Anlegen |
| 6 Werkzeug zum Räumen | `tools/slots-testkonten-raeumen.mjs` (+ `.sql`), Test 5 in `slots_sl2b.test.sql` |

## Offene Punkte

1. **Coach kann einen reinen Testtermin nicht festschreiben.** Der Trigger `coaching_sessions_testlauf_pruefen`
   erlaubt `testlauf = true` beim Anlegen nur dem Admin (auch in der T4-Fassung). Den Trigger fasst SL2b laut
   Leitplanke nicht an. `termin_session_anlegen` fängt seine Ablehnung ab und meldet 42501 mit Hinweis
   `testlauf_nur_admin` (Text in `de/slots.json`: „… Die Session als Testlauf öffnet die Verwaltung.“). Ändert T4 den
   Trigger, folgt die Funktion ohne weitere Änderung (Consensus-Befund 3). Für die
   Abnahme heißt das: Den Testtermin öffnet Rasit im Termin-Bildschirm, danach kann der Coach ihn in der Live-Sicht
   führen. Soll der Coach das selbst können, braucht der Trigger eine Ausnahme (z. B. INSERT mit `testlauf` erlaubt,
   wenn `raum_id`/`slot_zeit_id` gesetzt sind und der Aufrufer der eingeteilte Coach ist). Das gehört zu T4 bzw. ins
   Foundation-Fenster. Ob die Coach-Seiten (SL3) den Hinweis über `src/lib/slots/fehler.ts` übersetzen, entscheidet SL3.
2. **Eine Session gibt dem Termin seine Art, auch leer.** Öffnet jemand einen Raum ohne Kinder, entsteht eine Session
   wie die übrigen Sessions des Termins, sonst eine echte. Danach kommt kein Testkonto mehr in diesen Termin (SL013),
   umgekehrt kommt in einen Termin mit Testlauf-Session kein echtes Kind, auch wenn alle Testkonten abgesagt haben.
   Das ist Absicht: Die Zuteilung legt neue Kinder in die vorhandenen Sessions.
3. **Was die Kennzahlen nicht mehr zählen und was weiter zählt.** Ohne Testkonten: Kopf des Wochenplans (Belegt,
   Auslastung, Kinder ohne Raum, Ohne Stammplatz), der Satz unter „Slots“ und der Zähler in der Leiste. Plätze bleibt
   die Kapazität. Weiter mit Testkonten, weil es um belegte Plätze oder Listen geht: Zelle „belegt / Plätze“, Kopf des
   Termins („3 Kinder · 10 Plätze“), Filter-Chips und Liste „Ohne Stammplatz“ im Reiter Kinder (dort mit Kennzeichen).
   „Belegt“ sagt im Untertitel, wie viele Testkonten nicht mitzählen („ohne 4 Testkonten“).
4. **Einheiten eines Testkontos.** `einheiten_stand_intern` zählt `kind_termine` ohne Blick auf `testlauf`. Für ein
   Testkonto zählen Slot-Termine in Testlauf-Sessions deshalb als verbraucht (eigene Akte und Planbilanz des
   Testkontos). Echte Kinder sind nicht betroffen, sie sitzen nie in einem Testlauf. Die Funktion gehört zur Akte
   (SL3) und bleibt hier unverändert. Vorschlag: dort Kind-Termine mit Testlauf-Session ausnehmen.
5. **„Heute“ und Coach-Seiten (SL3).** `ist_test` kommt dort schon an (`slots_tag.absagen`, `meine_einsaetze`); ein
   Kennzeichen zeigt SL3. `slots_tag.raum_termine[].belegt` zählt Testkonten mit (belegte Plätze, keine Kennzahl).
   `slots_rechte.test.sql` erlaubt in `meine_einsaetze` jetzt das Feld `ist_test`.
6. **Werkzeug.** Zusatztermine und Umbuchungen löscht keine Slot-Funktion (Entscheidung 10); das Werkzeug lässt sie
   deshalb „ausgefallen durch uns“ (`termin_ausgefallen`), die beweglichen Stammplatz-Termine entfernt die Planung nach
   `stammplatz_beenden`. Heute festgeschriebene Termine und ihre Testlauf-Sessions bleiben stehen. Stammplätze enden ab
   heute (`gueltig_bis` = gestern, künftige werden leer). Ein zweiter Lauf ändert nichts mehr. Das Werkzeug setzt die
   Systemrolle transaktionslokal; in Prod liefert `ist_systemaufruf()` über `DATABASE_URL` ohnehin `true` (per dbread
   geprüft). Es läuft erst nach „Testkonten räumen“.
7. **Hinweis `testkonto`.** `stammplatz_vergeben` kennt noch den Abbruch „Testkonten kommen in den Slots nicht vor“
   (22023, `testkonto`). Er greift nicht mehr, weil `slots_kind_zugelassen` jetzt jedes vorhandene Kind zulässt; der
   Text in `de/slots.json` bleibt für eine spätere Rückkehr zu Entscheidung 8.
8. **Länge.** `20261013181427_slots_sl2b_testkonten.sql` hat rund 500 Zeilen, fast alles unveränderte Prod-Fassungen
   der neun ersetzten Funktionen (wie SL1, offene-punkte-sl1 Punkt 5). Das Paket liegt über der 300-Zeilen-Grenze für
   Features aus §4; neu geschrieben sind davon rund 150 Zeilen SQL.
9. **Versionen.** Wie bei SL1 gibt der Auftrag den Bereich `20261013180000`–`185959` vor, `date -u` liefert den
   12.10. Beide Versionen sind per dbread frei (0 Einträge im Bereich).
10. **`ist_test` nachträglich umstellen (Consensus-Befund 1).** `testkonto_setzen` prüft nur die Admin-Rolle. Wird ein
    Kind mit Stammplatz oder künftigen Terminen zum Testkonto (oder zurück), können Testkonto und echtes Kind im
    selben Termin stehen; die Planung prüft vorhandene Zeilen nicht neu, und das Festschreiben legt dann eine echte
    Session an. `testkonto_setzen` gehört nicht zu SL2b. Bis eine Sperre dort kommt (Vorschlag: kein Wechsel, solange
    das Kind einen laufenden Stammplatz oder künftige geplante Termine hat), gilt: erst räumen bzw. Stammplatz beenden,
    dann umstellen.
11. **CI bis zum Einspielen rot (Consensus-Befund 2).** `schema-erwartet.sql` wird laut Leitplanke erst nach dem
    Einspielen neu erzeugt. Bis dahin scheitert der CI-Job `neuaufbau` am Schema-Vergleich (wie bei SL1, Punkt 15);
    die pgTAP-Dateien laufen lokal alle grün (Wegwerf-DB, Postgres 18).
12. **Liste „Ohne Stammplatz“ und Zähler (Consensus-Befund 8).** Die Liste im Reiter Kinder zählt Testkonten mit (mit
    Kennzeichen), Leiste und Kopf nicht. Gewollt nach Entscheidung 3; falls es stört, kann die Liste „davon n Test“
    nennen.
