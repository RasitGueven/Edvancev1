# Offene Punkte L5 (Kinder-Hinweise prüfen und freigeben)

Stand 06.10.2026, Branch `feat/rasit-session-l5-hinweise`.

## Fachlich zu entscheiden

1. **Erledigt (Entscheidung Rasit 06.10.):** Beanstandung oder Zurücksetzen einer freigegebenen Aufgabe setzt ihre
   Hinweise auf entwurf. Umgesetzt als Trigger `tasks_hinweise_bei_ruecknahme` (Migration `20261008110500`), der beim
   Verlassen von `ready` `pruef_hinweise_setzen(id, 'entwurf')` ruft: `lena_beanstande`, `lena_beanstande_muster`,
   `task_status_set` aus dem Editor, direktes Admin-UPDATE und die beiden Rücknahmen. pgTAP Abschnitt 9.
2. **Weitere Freigabewege setzen die Hinweise nicht auf geprüft** (Entscheidung Rasit 06.10.: so lassen, Nachholen über
   „Hinweise bestätigen“ und den Filter „Hinweise ungeprüft“). Repo-Suche 06.10. (nach Merge von H6/X0b), in der
   Oberfläche noch erreichbar:
   - **Editor**: `/admin/authoring/:id`, `ReleaseGate` → `setTaskStatus` → `task_status_set(…, 'ready')`
     (`src/pages/admin/AuthoringEditorPage.tsx:196`).
   - **Thema**: Item-Pflege `/admin/authoring`, Themenzeile „Freigeben“ (nur Admin) → `freigabe_thema`
     (`src/components/edvance/authoring/board/Arbeitsbereich.tsx:82`, `ThemaZeile.tsx:86`).
   - **Muster**: Expertenliste `/admin/authoring/liste`, Sortierung nach Fertigkeit, Gruppenknopf „Freigeben“ →
     `freigabe_muster` (`src/pages/admin/AuthoringItemsPage.tsx:232`, Knopf `:337`).
   - **Cluster**: nicht mehr erreichbar. `freigabe_cluster` hat keinen Aufrufer in `src/` (nur ein Kommentar in
     `src/lib/authoring/vera8.ts:8`).
3. **Protokoll der Freigabe**: `pruef_admin_freigeben` und die Sammelfreigabe schreiben wie bisher `aenderungen = []`.
   Die Statuswechsel der Hinweise stehen nur bei `hinweise_bestaetigen` im Protokoll (`feld: 'hinweis_status'`).
   Falls gewünscht, kann die Freigabe die Liste aus `pruef_hinweise_setzen` mitschreiben.

## Technisch

4. **Migrationsversionen 20261008110100–110500** liegen in der Zukunft und sind rund. Das widerspricht CLAUDE.md §10,
   ist aber der Bereich aus dem Auftrag (nach E1/Q1, höchste Prod-Version 20261007141356). In Prod und
   `git log --all` frei (dbread 06.10.).
5. **Alle fünf Migrationen in einem Zug einspielen.** Einzeln geht es auch; der Nachtrag der Ausgangsfassungen steht
   deshalb in Teil 2 hinter `pruef_fassung` (Consensus-Check, Befund 4).
6. **Kinder-Oberfläche für Hinweise gibt es noch nicht** (Entscheidung Rasit 06.10.: reiner Text in Ordnung, die
   Kinderansicht kommt mit E2a) (weder in diesem Repo noch in `edvance-app`). Die Prüfansicht
   zeigt die Hinweise so, wie `lsa_hint` / `hinweis_abrufen` sie liefern: Stufe für Stufe als reiner Text. In Prod
   enthält kein Hinweis Formel- oder Markdown-Zeichen (dbread 06.10.); kommen Formeln dazu, muss die Darstellung
   mitziehen.
7. **`hinweis_status_setzen` gibt kein `geprueft` mehr her**, auch nicht für Admins. Einziger Aufrufer mit `geprueft`
   war die E1-Fixture; sie setzt den Status jetzt über den Schalter wie R1. Zurück auf `entwurf` geht weiter.
8. **`src/types/database.ts`** kennt `hinweise_bestaetigen` und die neuen Spalten von `pruef_admin_liste` erst nach
   einer Neugenerierung (wie bisher über die Casts in `pruefung.ts` / `pruefungAdmin.ts`).
9. **Prüfskripte** `supabase/checks/lena_board.PRUEFUNG.sql`, `20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql`
   und `20260723160000_a21_freigabe_muster.PRUEFUNG.sql` hängen an Prod-Bestand (Pilotanzahl, Coach-Konto,
   Hilfsdatei) und laufen in einer leeren Wegwerf-DB nicht. Nach dem Einspielen gegen Prod laufen lassen.
