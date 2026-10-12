# Slots SL1 — Ist-Abgleich und offene Punkte

Stand: 10.10.2026 · Paket SL1 · Branch `feat/rasit-slots-sl1-datenmodell` (ab `origin/dev` 242b660)

## P0 — Ist-Abgleich (dbread, nur Anzahlen)

Jede Aussage aus „Was es schon gibt“ (Bauauftrag) gegen Produktion geprüft, Stand 10.10.2026.

| Aussage | Befund Prod | passt |
|---|---|---|
| `session_students.attendance` mit `planned \| present \| cancelled \| unexcused \| cancelled_by_us` | Check genau so; Werte: planned 6, present 5, unexcused 1 | ja |
| `einheit_verbraucht()` true für present, unexcused | present t, unexcused t, cancelled f | ja |
| `ferien_nrw` bis Sommerferien 2030 (Ende 06.08.2030) | 17 Zeilen, 20.07.2026 bis 06.08.2030 | ja |
| `feiertage_nrw` 2026–2030 mit Pfingstferientag | 60 Zeilen, 01.01.2026 bis 26.12.2030, davon 5 `pfingstferien` | ja |
| `betriebstag`, `betriebstage` | vorhanden | ja |
| `einheiten_stand(_intern)` zählt über `session_students` × `coaching_sessions` ohne Testläufe | so im Funktionskörper | ja |
| `session_platz_zugang`, Trigger ZG001 | vorhanden (`session_students_zugang_trg`) | ja |
| `tier_laufzeiten` 19/38, 29/57, 38/76 | Basic 19/38, Standard 29/57, Premium 38/76 | ja |
| `tiers` Basic, Standard, Premium | 3 Zeilen, alle aktiv | ja |
| `coaching_sessions` = Raum zu einer Zeit | 13 Sessions (2 Testlauf), `room` in allen 13 gesetzt (2 verschiedene Werte), `slot_id` in keiner, keine in der Zukunft | ja |
| `session_students` | 12 Buchungen, davon 2 in Testläufen; alle 12 Kinder sind Testkonten | ja |
| S10 `slots`, `slot_wishes`, `slot_assignments` | je 0 Zeilen | ja |
| `session_series` gibt es nicht | `to_regclass` leer | ja |
| Stellschrauben | 29 Zeilen (`session_r1.test.sql` erwartet 29, nach SL1 30) | ja |
| Namen der neuen Tabellen und Funktionen frei | keine der 7 Tabellen, keine der geplanten Funktionen vorhanden | ja |
| Versionen 20261013100000–135959 frei | 0 Einträge in `schema_migrations` | ja |

Weitere Zahlen:

- Kinder mit laufendem Vertrag (`aktiv`, `im_widerruf`), **echt (nicht `ist_test`): 0**, Testkonten: 9.
- Abgeschlossene Verträge: 10 (alle mit `vertrag_ende`), Beginn ab 01.09.2025, letzter Stichtag 30.09.2027.
- Coaches (Rolle coach): 3, Admins: 2.
- `vertraege.fach`: 5 × Mathematik, 5 × leer.

## Offene Punkte

1. **Nur Testkonten in Prod — Abnahme gesamt.** Entscheidung 8 nimmt Testkonten aus den Slots heraus. In Prod
   gibt es heute kein echtes Kind mit laufendem Vertrag, nur 9 Testkonten. Die Abnahme „eine Woche durchklicken,
   Stammplatz vergeben …“ hat damit in Prod kein einziges Kind. Gebaut ist die Regel genau an einer Stelle
   (`slots_kind_zugelassen`), damit sie sich mit einer Migration umstellen lässt, falls Rasit für die Abnahme
   Testkonten zulassen will. Entscheidung offen.
2. **F1 und `coach_raum_live` — erledigt.** Beim Ist-Abgleich trug Prod schon F1 (`20261011140000`–`140400`), dev
   noch nicht. Inzwischen ist F1 (#234) in dev; nach dem Einmischen von `origin/dev` sind die Ausgangsfassungen aller
   fünf umgestellten Funktionen in dev und Prod gleich (`pg_get_functiondef` verglichen). Der Diff im PR gilt für beide.
3. **`vertraege.fach` ist in 5 von 10 Verträgen leer.** Die Raumzuteilung (Entscheidung 15) gruppiert leere Fächer
   als eigene Gruppe „ohne Fach“; die Oberfläche zeigt dann kein Kürzel.
4. **Versionen der Migrationen.** Der Bauauftrag gibt den Bereich `20261013100000`–`135959` vor; CLAUDE.md §10 verlangt
   `date -u` beim Anlegen. Am 10.10. liegt der 13.10. in der Zukunft. Gefolgt ist SL1 dem Bauauftrag (zehn nicht runde
   Versionen im Bereich, vorher per dbread geprüft: alle frei). Spätere Migrationen anderer Pakete mit `date -u` vor dem
   13.10. sortieren im Neuaufbau davor; für SL1 ist das unschädlich, weil keine fremde Migration auf SL1 aufbaut.
5. **Länge der Migrationen.** Vier SL1-Migrationen haben mehr als 400 Zeilen (`schreiben_termin` 649, `schreiben_stamm`
   549, `planung` 510, `lesen_plan` 437). Die 400-Zeilen-Grenze des Prompts gilt den Frontend-Dateien; im Repo haben 49
   Migrationen mehr als 400 Zeilen. Alle `src`-Dateien von SL1 liegen darunter.
6. **„Session öffnen“ nur am Tag** hat keinen eigenen SL-Code in Entscheidung 23. Gebaut als `22023` mit Hinweis
   `nur_am_tag` (Text in `de/slots.json`).
7. **Widerruf.** Entscheidung 22: Stammplätze enden „am Widerrufstag“, künftige Termine „ab diesem Tag“ fallen weg.
   Gebaut: `gueltig_bis = widerrufen_am`, Termine ab `widerrufen_am` entfallen (Planende = Vortag, weil `hat_zugang` ab dem
   Widerruf ohnehin falsch ist).
8. **Absage nach Beginn.** Entscheidung 14 erlaubt eine Absage auch nach `gestartet_am`. Gesperrt (SL011) ist sie nur für
   vergangene Tage; am Tag selbst geht sie bis Mitternacht.
9. **Rhythmus beim Vergeben** wird nicht erzwungen: `stammplatz_vergeben` nimmt so viele Zeilen, wie die Oberfläche schickt.
   Der Rhythmus aus `slot_rhythmus` steht in `slots_kinder`/`slots_kind`; SL2 schlägt danach die Zeilen vor.
10. **Erweiterungen am Datenvertrag** (rückwärtsverträglich, Default `null`): `slots_frei(…, p_student_id)` zählt die eigenen
    Termine des Kindes nicht als belegt; `slots_planbilanz_vorschau(…, p_ersetzt)` nennt beim Ändern die Stammplätze, die
    mit `p_ab` enden.
11. **`naechster_termin`** vereinheitlicht die vier Suchen: Bisher verlangten drei `attendance = 'planned'`, `quest_erzeugen`
    „nicht abgesagt“. Jetzt gilt überall „nicht abgesagt“ (bei künftigen Buchungen gibt es nur `planned`, der Unterschied
    ist theoretisch). Testläufe zählen wie bisher mit.
12. **`naechste_termine`** rechnet immer ab `now()` (Eltern), hat also keinen Testzeitpunkt; die Beispiele in
    `docs/slots/datenvertrag-beispiele.md` zeigen deshalb Termine ab heute.
13. **Vertrags-Trigger** (`vertraege_slots_trg`) plant mit `now()`. Eine Kündigung oder ein Widerruf, die rückwirkend
    erfasst werden, räumen nur künftige Termine ab heute auf; vergangene bleiben, wie sie sind.
14. **Leistung** (Wegwerf-DB, 260 Kinder mit Stammplatz, 10 000 Termine): Wochenplan 127 ms, Kinder-Liste 141 ms, Zähler
    90 ms, Termin 11 ms, Ziele (4 Wochen) 317 ms, Kandidaten 1,2 s (prüft jedes Kind einzeln mit denselben Regeln wie das
    Speichern). Für den Dialog „Kind hinzufügen“ reicht das; sonst lässt sich die Prüfung später bündeln.
15. **CI vor dem Einspielen rot.** `schema-erwartet.sql` darf laut Leitplanke erst nach dem Einspielen neu erzeugt werden.
    Bis dahin bricht der CI-Job `neuaufbau` im Schema-Vergleich ab, die pgTAP-Schritte laufen dort erst danach. Lokal
    laufen alle pgTAP-Dateien in der Wegwerf-DB (Postgres 18); CI nutzt Postgres 16.
16. **Coach am Vortag** (Entscheidung 14): `coach_hat_platz` bleibt unverändert; vor dem Festschreiben liest ein Coach die
    Akte seiner Kinder nicht. Bewusst so belassen.
17. **Consensus-Check** (zweite Instanz, 10.10.): Befunde 1–9 und 12 sind in `20261013125413_slots_nachbesserung.sql`
    behoben und in `slots_nachbesserung.test.sql` abgesichert. Bewusst offen:
    - **Befund 10:** „künftig“ heißt in der Planung `datum >= heute`. Ein heutiger Termin ohne Session gilt bis
      Mitternacht als beweglich. Der Abgleich löscht ihn nur, wenn er nicht mehr im Plan steht (z. B. Stammplatz am selben
      Tag geändert). Eine Umstellung auf `Beginn > jetzt` beträfe sieben Funktionen; Entscheidung bei Rasit.
    - **Befund 11:** wie Punkt 11 oben (Quest-B-Stellen zählen jetzt alles außer abgesagt).
