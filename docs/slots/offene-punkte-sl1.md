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
2. **F1 liegt in Prod, aber nicht in dev.** Prod trägt `20261011140000`–`140400` (F1, PR #234 offen), darunter
   `coach_raum_live`. SL1 ändert in `coach_raum_live` nur die Suche nach dem nächsten Termin und nimmt laut
   Leitplanke den Prod-Stand als Ausgangspunkt. Mergt SL1 vor F1, bringt die SL1-Migration den F1-Stand von
   `coach_raum_live` mit; die spätere F1-Migration (kleinere Version) läuft im Neuaufbau davor und wird von SL1
   überschrieben, das Ergebnis ist gleich. Siehe Diff im PR.
3. **`vertraege.fach` ist in 5 von 10 Verträgen leer.** Die Raumzuteilung (Entscheidung 15) gruppiert leere Fächer
   als eigene Gruppe „ohne Fach“; die Oberfläche zeigt dann kein Kürzel.
