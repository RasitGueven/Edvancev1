# K10-Rest – Einspielen

Aus `~/wt/k10-rest` (oder nach dem Merge aus `~/Edvancev1` auf dev). Reihenfolge einhalten: Substrate
(trigo vor sinus), Aufgaben, thema_einstieg, skill_thema_k10. `mig` spielt jede Datei mit `psql -1` in
einer Transaktion ein. Jede Prüfabfrage ist rein lesend; Erwartung: jede Zeile `ok = t`.

Vor dem Einspielen: `dbread -tAc "select max(version) from supabase_migrations.schema_migrations"` muss
kleiner als `20261003121328` sein (Stand beim Erzeugen: `20261003120051`). Kommt etwas Neueres dazu,
neu versionieren (`docs/k10-rest/befunde.md`, Abschnitt Versionen).

| # | Version | Name | Inhalt | Prüfung danach (dbread-Befehl) |
|---|---|---|---|---|
| 1 | 20261003121328 | substrat_k10_exp | 5 Knoten, 9 Kanten, 6 neue Fehlbilder | `dbread -f supabase/checks/k10_exp_substrat.PRUEFUNG.sql` |
| 2 | 20261003121329 | substrat_k10_trigo | 5 Knoten, 10 Kanten, 6 neue Fehlbilder | `dbread -f supabase/checks/k10_trigo_substrat.PRUEFUNG.sql` |
| 3 | 20261003121331 | substrat_k10_sinus | 5 Knoten, 7 Kanten, 4 neue Fehlbilder (+ `bogenmass_modus` idempotent) | `dbread -f supabase/checks/k10_sinus_substrat.PRUEFUNG.sql` |
| 4 | 20261003121332 | aufgaben_k10_exp | 30 Aufgaben (draft), 2 Figuren | `dbread -f supabase/checks/k10_exp_aufgaben.PRUEFUNG.sql` |
| 5 | 20261003121333 | aufgaben_k10_trigo | 30 Aufgaben (draft) | `dbread -f supabase/checks/k10_trigo_aufgaben.PRUEFUNG.sql` |
| 6 | 20261003121334 | aufgaben_k10_sinus | 30 Aufgaben (draft) | `dbread -f supabase/checks/k10_sinus_aufgaben.PRUEFUNG.sql` |
| 7 | 20261003121335 | thema_einstieg_k10 | 6 Einstiege für 3 Themen | `dbread -f supabase/checks/k10_thema_einstieg.PRUEFUNG.sql` (Zeile „Heimat-Thema" erst nach #8 `t`) |
| 8 | 20261003121336 | skill_thema_k10 | 15 Heimat-Themen | `dbread -f supabase/checks/k10_skill_thema.PRUEFUNG.sql` |

**Kein „erst nach K9"-Schritt:** Eine eigene `kanten_k10_k9.sql` gibt es nicht. K9-Rest ist seit #194 in
Prod; die Kanten auf K9-Knoten stehen direkt in den Substraten (Entscheidung E1).

## Zum Kopieren

```bash
cd ~/wt/k10-rest
mig 20261003121328 substrat_k10_exp && dbread -f supabase/checks/k10_exp_substrat.PRUEFUNG.sql
mig 20261003121329 substrat_k10_trigo && dbread -f supabase/checks/k10_trigo_substrat.PRUEFUNG.sql
mig 20261003121331 substrat_k10_sinus && dbread -f supabase/checks/k10_sinus_substrat.PRUEFUNG.sql
mig 20261003121332 aufgaben_k10_exp && dbread -f supabase/checks/k10_exp_aufgaben.PRUEFUNG.sql
mig 20261003121333 aufgaben_k10_trigo && dbread -f supabase/checks/k10_trigo_aufgaben.PRUEFUNG.sql
mig 20261003121334 aufgaben_k10_sinus && dbread -f supabase/checks/k10_sinus_aufgaben.PRUEFUNG.sql
mig 20261003121335 thema_einstieg_k10 && dbread -f supabase/checks/k10_thema_einstieg.PRUEFUNG.sql
mig 20261003121336 skill_thema_k10 && dbread -f supabase/checks/k10_skill_thema.PRUEFUNG.sql
```

Danach (Teil 6): Figuren-Upload nur für die 2 neuen Aufgaben mit Abbildung (`exp-term-04`, `exp-term-05`),
erst `--dry-run` gegen Prod.
