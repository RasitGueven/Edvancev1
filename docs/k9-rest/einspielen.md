# K9-Rest – Einspielen

Aus `~/wt/k9-rest` (oder nach dem Merge aus `~/Edvancev1` auf dev), Reihenfolge einhalten: Substrate in
Abhängigkeitsreihenfolge, dann Aufgaben, dann thema_einstieg. `mig` spielt jede Datei mit `psql -1` ein.
Jede Prüfabfrage ist rein lesend; Erwartung: jede Zeile `ok = t`.

| # | Version | Name | Inhalt | Prüfung danach (dbread-Befehl) |
|---|---|---|---|---|
| 1 | 20261003105852 | substrat_k9_wurzel | 5 Knoten, 7 Kanten, 3 Fehlbilder | `dbread -f supabase/checks/k9_wurzel_substrat.PRUEFUNG.sql` |
| 2 | 20261003105853 | substrat_k9_potenz | 4 Knoten, 5 Kanten, 3 Fehlbilder | `dbread -f supabase/checks/k9_potenz_substrat.PRUEFUNG.sql` |
| 3 | 20261003105854 | substrat_k9_quadrgl | 4 Knoten, 7 Kanten, 5 Fehlbilder | `dbread -f supabase/checks/k9_quadrgl_substrat.PRUEFUNG.sql` |
| 4 | 20261003105856 | substrat_k9_quadrfkt | 5 Knoten, 9 Kanten, 3 Fehlbilder | `dbread -f supabase/checks/k9_quadrfkt_substrat.PRUEFUNG.sql` |
| 5 | 20261003105857 | substrat_k9_pythagoras | 5 Knoten, 6 Kanten, 3 Fehlbilder | `dbread -f supabase/checks/k9_pythagoras_substrat.PRUEFUNG.sql` |
| 6 | 20261003105858 | substrat_k9_koerper | 5 Knoten, 10 Kanten, 3 Fehlbilder | `dbread -f supabase/checks/k9_koerper_substrat.PRUEFUNG.sql` |
| 7 | 20261003105859 | substrat_k9_bedingt | 5 Knoten, 7 Kanten, 5 Fehlbilder | `dbread -f supabase/checks/k9_bedingt_substrat.PRUEFUNG.sql` |
| 8 | 20261003105900 | substrat_k9_aehnlich | 4 Knoten, 6 Kanten, 3 Fehlbilder | `dbread -f supabase/checks/k9_aehnlich_substrat.PRUEFUNG.sql` |
| 9 | 20261003105901 | aufgaben_k9_wurzel | 30 Aufgaben (draft) | `dbread -f supabase/checks/k9_wurzel_aufgaben.PRUEFUNG.sql` |
| 10 | 20261003105902 | aufgaben_k9_potenz | 24 Aufgaben (draft) | `dbread -f supabase/checks/k9_potenz_aufgaben.PRUEFUNG.sql` |
| 11 | 20261003105903 | aufgaben_k9_quadrgl | 24 Aufgaben (draft) | `dbread -f supabase/checks/k9_quadrgl_aufgaben.PRUEFUNG.sql` |
| 12 | 20261003105904 | aufgaben_k9_quadrfkt | 30 Aufgaben (draft), 4 Figuren | `dbread -f supabase/checks/k9_quadrfkt_aufgaben.PRUEFUNG.sql` |
| 13 | 20261003105905 | aufgaben_k9_pythagoras | 30 Aufgaben (draft), 3 Figuren | `dbread -f supabase/checks/k9_pythagoras_aufgaben.PRUEFUNG.sql` |
| 14 | 20261003105906 | aufgaben_k9_koerper | 30 Aufgaben (draft) | `dbread -f supabase/checks/k9_koerper_aufgaben.PRUEFUNG.sql` |
| 15 | 20261003105907 | aufgaben_k9_bedingt | 30 Aufgaben (draft) | `dbread -f supabase/checks/k9_bedingt_aufgaben.PRUEFUNG.sql` |
| 16 | 20261003105909 | aufgaben_k9_aehnlich | 24 Aufgaben (draft) | `dbread -f supabase/checks/k9_aehnlich_aufgaben.PRUEFUNG.sql` |
| 17 | 20261003105910 | thema_einstieg_k9_rest | 18 Einstiege für 9 Themen | `dbread -f supabase/checks/k9_thema_einstieg.PRUEFUNG.sql` |

## Zum Kopieren

```bash
cd ~/wt/k9-rest
mig 20261003105852 substrat_k9_wurzel && dbread -f supabase/checks/k9_wurzel_substrat.PRUEFUNG.sql
mig 20261003105853 substrat_k9_potenz && dbread -f supabase/checks/k9_potenz_substrat.PRUEFUNG.sql
mig 20261003105854 substrat_k9_quadrgl && dbread -f supabase/checks/k9_quadrgl_substrat.PRUEFUNG.sql
mig 20261003105856 substrat_k9_quadrfkt && dbread -f supabase/checks/k9_quadrfkt_substrat.PRUEFUNG.sql
mig 20261003105857 substrat_k9_pythagoras && dbread -f supabase/checks/k9_pythagoras_substrat.PRUEFUNG.sql
mig 20261003105858 substrat_k9_koerper && dbread -f supabase/checks/k9_koerper_substrat.PRUEFUNG.sql
mig 20261003105859 substrat_k9_bedingt && dbread -f supabase/checks/k9_bedingt_substrat.PRUEFUNG.sql
mig 20261003105900 substrat_k9_aehnlich && dbread -f supabase/checks/k9_aehnlich_substrat.PRUEFUNG.sql
mig 20261003105901 aufgaben_k9_wurzel && dbread -f supabase/checks/k9_wurzel_aufgaben.PRUEFUNG.sql
mig 20261003105902 aufgaben_k9_potenz && dbread -f supabase/checks/k9_potenz_aufgaben.PRUEFUNG.sql
mig 20261003105903 aufgaben_k9_quadrgl && dbread -f supabase/checks/k9_quadrgl_aufgaben.PRUEFUNG.sql
mig 20261003105904 aufgaben_k9_quadrfkt && dbread -f supabase/checks/k9_quadrfkt_aufgaben.PRUEFUNG.sql
mig 20261003105905 aufgaben_k9_pythagoras && dbread -f supabase/checks/k9_pythagoras_aufgaben.PRUEFUNG.sql
mig 20261003105906 aufgaben_k9_koerper && dbread -f supabase/checks/k9_koerper_aufgaben.PRUEFUNG.sql
mig 20261003105907 aufgaben_k9_bedingt && dbread -f supabase/checks/k9_bedingt_aufgaben.PRUEFUNG.sql
mig 20261003105909 aufgaben_k9_aehnlich && dbread -f supabase/checks/k9_aehnlich_aufgaben.PRUEFUNG.sql
mig 20261003105910 thema_einstieg_k9_rest && dbread -f supabase/checks/k9_thema_einstieg.PRUEFUNG.sql
```

Danach (Teil 6): Figuren-Upload nur für die 7 neuen Aufgaben mit Abbildung, erst `--dry-run` gegen Prod.
