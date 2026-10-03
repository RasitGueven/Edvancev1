# K8-Rest – Einspielen

Neun Migrationen, in genau dieser Reihenfolge: alle Substrate, dann alle Aufgaben, dann
thema_einstieg. Jede Datei ohne begin/commit; `mig` spielt sie mit `psql -1` in einer
Transaktion ein und trägt die Version in `schema_migrations` ein. Aus dem Worktree
`~/wt/k8-rest` aufrufen (mig sucht `supabase/migrations/<Version>_<Name>.sql` relativ).

| # | Version | Name | Inhalt | Prüfung danach (dbread-Befehl) |
|---|---|---|---|---|
| 1 | 20261003104943 | substrat_k8_lgs | 5 Knoten `gleichung_lgs_*` + Heimat-Thema, 13 Kanten, 4 Fehlbilder | `~/bin/dbread -f supabase/checks/k8_lgs_substrat.PRUEFUNG.sql` (8 × t) |
| 2 | 20261003104944 | substrat_k8_stoch | 5 Knoten `stoch_*` + Heimat-Thema, 9 Kanten, 7 Fehlbilder | `~/bin/dbread -f supabase/checks/k8_stoch_substrat.PRUEFUNG.sql` (9 × t) |
| 3 | 20261003104945 | substrat_k8_flaeche | 5 Knoten `geo_flaeche_*` + Heimat-Thema, 9 Kanten, 2 Fehlbilder | `~/bin/dbread -f supabase/checks/k8_flaeche_substrat.PRUEFUNG.sql` (6 × t) |
| 4 | 20261003104946 | substrat_k8_winkel | 4 Knoten `geo_winkel_*` + Heimat-Thema, 5 Kanten, 4 Fehlbilder | `~/bin/dbread -f supabase/checks/k8_winkel_substrat.PRUEFUNG.sql` (8 × t) |
| 5 | 20261003104947 | aufgaben_k8_lgs | 30 Aufgaben (draft), Lösungen, 5 Figuren-Zeilen | `~/bin/dbread -f supabase/checks/k8_lgs_aufgaben.PRUEFUNG.sql` (22 × t) |
| 6 | 20261003104948 | aufgaben_k8_stoch | 30 Aufgaben (draft), Lösungen | `~/bin/dbread -f supabase/checks/k8_stoch_aufgaben.PRUEFUNG.sql` (18 × t) |
| 7 | 20261003104949 | aufgaben_k8_flaeche | 30 Aufgaben (draft), Lösungen | `~/bin/dbread -f supabase/checks/k8_flaeche_aufgaben.PRUEFUNG.sql` (19 × t) |
| 8 | 20261003104950 | aufgaben_k8_winkel | 24 Aufgaben (draft), Lösungen, 2 Figuren-Zeilen | `~/bin/dbread -f supabase/checks/k8_winkel_aufgaben.PRUEFUNG.sql` (21 × t) |
| 9 | 20261003104951 | thema_einstieg_k8_rest | 9 Einstiege in 5 Themen (Heimat-Themen stehen schon mit den Substraten) | `~/bin/dbread -f supabase/checks/k8_rest_einstieg.PRUEFUNG.sql` (7 × t) |

Die Zahlen in Klammern sind die Zeilen mit `ok = t`, die lokal (Wegwerf-DB, `-v lokal=true`)
erreicht wurden. Gegen Prod laufen die Skripte ohne Variable und prüfen zusätzlich
`cluster_id` und das Vorhandensein der wiederverwendeten Alt-Slugs.

**Vor dem Einspielen:** `max(version)` in Prod prüfen. Steht dort inzwischen eine Version
> 20261003104943, müssen die Dateien neu versioniert werden (die Aufgaben-Dateien dann mit
`node tools/vorlauf-build.mjs docs/prefill/k8-<thema>.json <neue Version> aufgaben_k8_<thema>`).
Stand beim Schreiben: letzte Prod-Version 20261003104647 (PR #192, skill_thema) — die Substrate setzen die Tabelle skill_thema voraus.

## Zum Kopieren

```
cd ~/wt/k8-rest
mig 20261003104943 substrat_k8_lgs && ~/bin/dbread -f supabase/checks/k8_lgs_substrat.PRUEFUNG.sql
mig 20261003104944 substrat_k8_stoch && ~/bin/dbread -f supabase/checks/k8_stoch_substrat.PRUEFUNG.sql
mig 20261003104945 substrat_k8_flaeche && ~/bin/dbread -f supabase/checks/k8_flaeche_substrat.PRUEFUNG.sql
mig 20261003104946 substrat_k8_winkel && ~/bin/dbread -f supabase/checks/k8_winkel_substrat.PRUEFUNG.sql
mig 20261003104947 aufgaben_k8_lgs && ~/bin/dbread -f supabase/checks/k8_lgs_aufgaben.PRUEFUNG.sql
mig 20261003104948 aufgaben_k8_stoch && ~/bin/dbread -f supabase/checks/k8_stoch_aufgaben.PRUEFUNG.sql
mig 20261003104949 aufgaben_k8_flaeche && ~/bin/dbread -f supabase/checks/k8_flaeche_aufgaben.PRUEFUNG.sql
mig 20261003104950 aufgaben_k8_winkel && ~/bin/dbread -f supabase/checks/k8_winkel_aufgaben.PRUEFUNG.sql
mig 20261003104951 thema_einstieg_k8_rest && ~/bin/dbread -f supabase/checks/k8_rest_einstieg.PRUEFUNG.sql
```

## Danach (Teil 6, macht Claude nach „eingespielt“)

1. Per dbread: alle neun Versionen in `schema_migrations`, alle Prüfabfragen grün.
2. `upload_figures.py --dry-run` gegen Prod (erwartet: 7 offene Zeilen, fehler=0), dann echt —
   nur, wenn ausschließlich die 7 neuen Figuren offen sind. Danach: alle 7 mit `svg_hash`.
3. Schema-Abzug nur, wenn er sich ändert (reine Datenmigrationen: erwartet unverändert).
