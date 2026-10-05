# Consensus-Check — Migrationen der Admin-Prüfansicht

Nach CLAUDE.md §8: Eine zweite, unabhängige Instanz hat Rechte und Funktionskörper geprüft, und zwar diese Dateien:
`20261005131059_admin_pruefen_rechte.sql`, `20261005131220_admin_pruefen_funktionen_a.sql` und
`20261005131306_admin_pruefen_funktionen_b.sql`. Grundlage waren die Entscheidungen G1–G7 und die Anforderung.
Sie arbeitete in einer eigenen Kopie der Wegwerf-DB, Produktion nur lesend.

**Ergebnis: kein kritischer Befund.** Rechte und RLS sind dicht. Die beiden wichtigen Befunde sind umgesetzt.

## Wichtig — umgesetzt

| # | Befund | Umsetzung |
|---|---|---|
| W1 | Der Admin-Zweig in `pruef_sperren` wirkte auch auf `pruef_entscheiden` und `pruef_rueckgaengig`. Ein Admin konnte damit eine vom Team beanstandete Aufgabe per „Passt“ auf `review` setzen und dann freigeben. So ließ sich „erst an Lena“ umgehen, und dabei entstand eine Lena-Zeile vom Admin. | Neuer interner Baustein `pruef_lena_sperren(t)`: von Hand herausgenommen, außerhalb des Piloten, vom Team beanstandet. `pruef_sperren` wendet ihn für Nicht-Admins an, `pruef_entscheiden` und `pruef_rueckgaengig` für alle (gleiche Körper, eine Zeile mehr). pgTAP 3: Admin-„Passt“ bei Team-Beanstandung → `team_beanstandet`, außerhalb des Piloten → `ausgeschlossen`. |
| W2 | `task_status_set` sperrte nur `beanstandet → ready`. Der Weg über `review` blieb offen. | `review` und `ready` aus `beanstandet` → ED422 `erst_an_lena`. Kein Aufrufer braucht den Übergang: Die freigabe_*-Schleifen nehmen nur review bzw. draft, `pruef_rueckfrage_klaeren` nur rueckfrage, das Prüfskript 20260922100000 Z. 123 setzt review auf eine review-Aufgabe. pgTAP 3. |

## Gering — umgesetzt bzw. offen

| # | Befund | Stand |
|---|---|---|
| G-a | Eine je geschriebene Admin-Beanstandung lässt eine Aufgabe in der Sammelfreigabe dauerhaft mit „vom Team beanstandet“ aus, auch nachdem Lena sie nach „Zurück an Lena“ wieder mit „Passt“ bewertet hat. | Bewusst wie `pruef_freigabe_erlaubt` bzw. `freigabe_thema` (Lena-Board OP-9, Auftrag G7 „genau wie freigabe_thema“). Offener Punkt OP-8 für Rasit. |
| G-b | `ausschliessen` lehnte jede berechnete Ausschlussart ab. Eine Aufgabe ohne Lösung ließ sich also nicht dauerhaft von Hand herausnehmen. | Umgesetzt. Nur vera8, inaktiv, typ und hand gelten als „schon ausgeschlossen“. pgTAP 6. |
| G-c | `supabase/checks/lena_board.PRUEFUNG.sql` kannte die fünf neuen Client-RPCs nicht. Nach dem Einspielen hätte das Skript deshalb gemeldet: „authenticated-Execute stimmt nicht“. | Umgesetzt (Liste ergänzt). Lokal meldet das Skript nur noch die erwartete Pilot-Zahl der Wegwerf-DB. |
| G-d | Die Sammelaktion an_lena lässt jeden Ausschluss aus. Das einzelne `pruef_an_lena` prüft keinen. | Bewusst. Einzeln ist das „Auf Offen setzen“ für Aufgaben, die nicht bei Lena sind (Auftrag C 8). Gesammelt sollen Aufgaben, die Lena nicht sieht, nicht zu ihr. OP-9. |

## Hinweise

- **H1** Das Protokoll `zurueckweisen` hält die Gründe nicht fest (nur die Notiz). Die Gründe stehen in `task_reviews`. → OP-10.
- **H2** `pruef_admin_freigeben` und `pruef_admin_zurueckweisen` nehmen auch Rückfragen an. Die Oberfläche nutzt für Rückfragen `pruef_rueckfrage_klaeren` (Auftrag C 9).
- **H3** `pruef_freigabe_zuruecknehmen` löscht die Ausgangsfassung nicht, wie `task_status_set` aus `ready`. → OP-11.
- **H4** Die Sammelaktion fertigkeit setzt `sondierrang` wie `pruef_entwurf_anwenden`: leer, außer bei der Rückkehr zur Fertigkeit der Ausgangsfassung. Das ist dieselbe Regel wie bei `pruef_speichern` (Auftrag „keine eigene Logik“).
- **H5** Texte für die durchgereichten HINTs: neu `erst_an_lena`, `nicht_freigegeben`, `wert_fehlt` (`pruefenAdmin.json`). Die übrigen übersetzt `pruefen.json` (Vitest „Übersetzung aller Auslass-Gründe und HINTs“). Im Editor erscheint die Sperre als Tooltip am Knopf (P4).
- **H6** freigabe_thema/cluster/muster fangen nur P0001. Ein Wettlauf, bei dem eine Aufgabe zwischen Auswahl und Freigabe beanstandet wird, bricht die Schleife mit ED422 ab. Das ist sehr unwahrscheinlich und nicht geändert.
- **H7** `task_admin_protokoll` hat keinen Trigger, der nur Anhängen erlaubt. Schreibschutz besteht über fehlende Grants und RLS. Ein BEFORE-DELETE-Trigger würde außerdem das `on delete cascade` beim Löschen einer Aufgabe blockieren.

## Geprüft und in Ordnung (zweite Instanz)

- ACLs lokal und Default-ACL in Prod (lesend): keine Default-Function-Grants in `public`. Alle neuen Funktionen haben `revoke … from public, anon, authenticated`. Die internen Helfer sind für authenticated nicht ausführbar (42501). Ersetzte Funktionen behalten ihre ACL. `pruef_admin_liste` ist nach drop + create neu gegrantet.
- Login ohne Profil (`get_my_role()` NULL), Coach mit Prüfrecht und anon bekommen auf allen neuen RPCs 42501.
- Direkte INSERTs in beide neuen Tabellen werden abgewiesen. Schüler, Eltern und Login ohne Profil lesen 0 Zeilen. Lena liest das Protokoll nicht, `task_pruef_ausschluss` aber schon (G2).
- `pruef_sperren` und `pruef_aufgabe` sind für Nicht-Admins gleichwertig zum alten Stand; neu ist nur `hand`.
- `pruef_ausschluss` hält die Reihenfolge ein.
- `pruef_sammel` verträgt doppelte und NULL-IDs sowie `p_werte` als NULL, `'null'` oder Array; `p_nur_vorschau` NULL gilt als Vorschau.
- Je Aufgabe ein Savepoint. Vorschau und Ausführung sind für freigeben, afb und fertigkeit gleich. fertigkeit/afb schreiben nur `skill_key`, `afb` und `sondierrang` und sichern vorher die Ausgangsfassung.
- `pruef_rueckfrage_klaeren` behält Signatur und Verhalten. `task_status_set` bricht keinen bestehenden Aufrufer.
