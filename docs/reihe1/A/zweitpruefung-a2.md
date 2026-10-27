# Zweitprüfung A2 (Migrationen 20261027132306, 132428, 132530, 132653)

Frischer Subagent ohne Kontext: nur die vier Migrationen, Konzept §3–6 und §9, die Frage „Was ist falsch, was fehlt, was bricht?“ (27.10.2026). Alle Befunde sind in den Migrationen abgearbeitet (die Migrationen waren noch nirgends eingespielt).

| # | Befund | Schwere | Abarbeitung |
|---|---|---|---|
| 1 | Bewährungs-Trigger kann eine Antwort zum Scheitern bringen (NULL in `jsonb_set`) | hoch | `coalesce(…, '∅')`; der ganze Rumpf in `begin … exception when others then raise warning`; die Antwort bleibt immer gespeichert |
| 2 | Kind verliert Payload/Wertung, wenn die Instanz während der Session pausiert wird | hoch | `aufgabe_lesbar`: das Tablet liest, was es in seiner aktiven Session schon bekommen hat |
| 3 | Lena könnte eine neue Version ohne Prüfmaschine/Blindlöser abnehmen | hoch | `bauform_pruefen` verlangt `pruefprotokoll.lauf_am`, `rot_anteil ≤ 0,30`, `blindloeser.bestanden` |
| 4 | Race bei zwei gleichzeitigen Meldungen | mittel | `for update` auf die Bauform vor dem Zählen |
| 5 | Meldungen alter Versionen zählen mit | mittel | nur Instanzen der aktuellen Version, nur seit `freigegeben_am` |
| 6 | Kein Weg zurück aus „pausiert“ | mittel | neu `bauform_reaktivieren(p_bauform, p_grund)`, Entscheidung `reaktiviert` |
| 7 | `teilweise` und `__known__` zählten als unbekannte Antwort | mittel | nur `falsch` ohne Fehlbild zählt |
| 8 | Zweitversuche blähen die Zähler | mittel | nur `versuch_nr = 1` (und Teil 1) zählt; pgTAP prüft es |
| 9 | Kind zuhause könnte jede Rolle ziehen und werten (Lösungsorakel); Tablet könnte home ziehen | mittel | `aufgabe_aufrufer`: Kind selbst nur `home`, Tablet alles außer `home`, Coach/Admin/System alles; pgTAP prüft es |
| 10 | Lesbarkeit zu breit (Eltern, fremde Kinder) | mittel | `aufgabe_lesbar` nur Admin/Coach/Lena, Tablet in aktiver Session, Kind selbst für home |
| 11 | „ungesehen“ wog vor der Stufe | mittel | Reihenfolge jetzt Stufe (gleich, darunter, darüber; ohne Stufe die leichteste), dann ungesehen |
| 12 | Rückfall ignorierte Meldungen | mittel | Rückfall filtert pausierte/auffällige Aufgaben |
| 13 | Index passt nicht zu `aufgabe_ziehen` | mittel | `tasks_instanz_ziehen_idx (skill_key, rolle, stufe) where bauform_id is not null` |
| 14 | Lösungsbeispiel aus anderer Quelle konnte wiederkommen | mittel | Rolle `beispiel` (wie `generalprobe`) schließt jede gesehene Instanz aus |
| 15 | Freigabe setzte `is_active` nicht, hob jeden Status | mittel | `is_active = true`, nur aus `draft`/`review`; `aufgabe_ziehbar` verlangt `instanz_gruen` |
| 16 | `format_werten` fehlt bis A3: nackter 42883; `teil` unsauber gelesen | niedrig | eigener Fehler `format_noch_nicht_wertbar`; `teil` nur als Zahl; `eingabe` nur, wenn vorhanden |
| 17 | `aufgabe_gezeigt` ohne aktive Session, Kind selbst durfte | niedrig | nur Tablet/Coach/Admin/System, Session aktiv |
| 18 | Klartext (Coach-Sprache) als Rückmeldung ans Kind; Stufen-Vorschlag mischt Versionen; `kann_entfallen` wirft bei „ja“ | niedrig | Instanzen nur Steckbrief-Satz; Vorschlag nur aktuelle Version; `= 'true'` und ohne Entwürfe |

**Offen, braucht Rasit (Auth/RLS):** Die bestehende Policy `read_tasks_by_role` lässt jede angemeldete Rolle `ready`-Zeilen
aus `tasks` direkt lesen, also auch `params` und `pruefmaschine` einer freigegebenen Instanz. `params` sind die
Generator-Parameter, aus denen sich die Lösung ableiten lässt. Vorschlag: Spaltenrechte für `authenticated` auf
`params`/`pruefmaschine` entziehen oder die Policy für Schüler auf Funktionen umstellen. Nicht umgesetzt, weil
Auth/RLS-Änderungen laut CLAUDE.md nur mit Rasits Bestätigung erfolgen. Die Prüfmaschine schreibt in `grund` keine Lösungswerte.
