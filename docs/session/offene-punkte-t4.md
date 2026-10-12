# Offene Punkte T4 (Testlauf wie echt im Plan, Prüffragen, kein_ziel protokolliert)

Stand 12.10.2026 · Branch `feat/rasit-session-t4-testlauf-rest` · Anlass: offene-punkte-t2 Punkte 1 bis 3,
offene-punkte-t3 Punkte 2 und 3, offene-punkte-f2 Abschnitt 3 Punkt 1 · Entscheidungen Rasit 12.10.
Beweis: `supabase/tests/session_t4.test.sql` (57 Zusicherungen), `docs/session/t4-vergleich.sql` (echt vorher/nachher).

## Was T4 ändert

| # | Was | Migration | Funktionen | Wirkung |
|---|---|---|---|---|
| 1 | „Tiefer gehen“ im Testlauf | `20261013160412_t4_pfad_testlauf` | neu `session_tiefer_entscheidungen`, `lernpfad_sicht`, `ziel_fertigkeiten_sitzung`, `naechste_luecke_sitzung`; ersetzt `session_zielliste`, `ziel_fertigkeiten_core`, `naechste_luecke_core` | Der Plan springt im Testlauf wie echt (z. B. `zz_a2_s1` → `zz_a2_v1`); keine Zeile in `lernpfad`/`lernpfad_protokoll` |
| 2 | Prüffragen im Testlauf | `20261013160957_t4_pruefung_testlauf` | neu `session_pruefung_frage_sitzung`; ersetzt `tablet_stand`, `pruefung_aufs_tablet`, `session_kind_live` | Im Testlauf gilt jede Prüffrage wie freigegeben |
| 3 | Auswahl über die T3-Regel | `20261013161533_t4_pool_regel` | ersetzt `session_im_pool`, `lsa_im_pool`, `erklaer_checks`, `lsa_select_next_core` | Gleiches Ergebnis, Regel nur noch in `testlauf_inhalt_sichtbar` / `lsa_testinhalte` |
| 4 | `lernpfad_beleg` im Testlauf | `20261013162108_t4_beleg_und_schalter` | ersetzt `lernpfad_beleg_core` | Keine Zeile in `lernpfad_belege`/`lernpfad`; Rückgabe ist der unveränderte Stand |
| 5 | `testlauf` nach dem Start | `20261013162108_t4_beleg_und_schalter` | ersetzt `coaching_sessions_testlauf_pruefen` (Trigger) | Direktes UPDATE nach dem Start: 55000, Hinweis `session_gestartet` |
| 6 | kein_ziel als erster Schritt | `20261013162641_t4_kein_ziel_schritt` | ersetzt `session_naechster_schritt` | Erstes Warten ohne vorigen Schritt wird eingetragen, danach kein doppelter Eintrag |

Signatur, `SECURITY DEFINER`, `search_path` und Grants aller 13 ersetzten Funktionen sind unverändert (Diff je Funktion
im PR, aus `pg_get_functiondef` Prod gegen Neuaufbau, inklusive `proacl`). Die fünf neuen Hilfen sind nur intern
(`proacl = {postgres=X/postgres}`, kein Grant an anon/authenticated).

## Entscheidungen, die den Wortlaut auslegen

1. **Wie der Planer „tiefer“ im Testlauf liest.** `lernpfad_sicht(kind, session)` liefert die Zeilen von `lernpfad` und
   legt im Testlauf jede „tiefer“-Entscheidung der Session aus `session_ereignisse` (`entscheidung_pfad`) in zeitlicher
   Reihenfolge darüber, so wie `pfad_tiefer` sie echt schreibt: Voraussetzung → `aktiv` (`stand_system_seit` bleibt,
   wenn sie schon aktiv war), bisheriger Skill `aktiv` → `offen`; fehlt eine Zeile, entsteht sie in der Sicht.
   `session_zielliste` erkennt „in dieser Session tiefer gesetzt“ im Testlauf am Ereignis statt an `lernpfad_protokoll`.
   Ohne Testlauf ist die Sicht genau `lernpfad`. Die beiden Payload-Formen: `pfad_entscheiden` schreibt `skill_key` =
   neues Ziel, `statt` = bisheriger Skill; `eingriff_notieren` schreibt `skill_key` = bisheriger Skill,
   `voraussetzung` = neues Ziel (fehlt, wenn `pfad_tiefer` scheiterte, dann zählt das Ereignis nicht).
2. **Auch Fall „Lernpfad“.** Die Entscheidung nennt `ziel_fertigkeiten_core`. Ohne Thema plant `session_zielliste` über
   `naechste_luecke_core`, das ebenfalls `lernpfad` liest. Damit „tiefer“ im Testlauf in beiden Fällen wie echt wirkt,
   liest auch dieser Zweig die Sicht (Test 1c). `ziel_fertigkeiten_core` und `naechste_luecke_core` behalten Signatur
   und Ergebnis; ihr Rumpf steht jetzt in den `*_sitzung`-Varianten, die sie mit `p_session_id = null` rufen.
   `session_ziel_kind` (Tablet) und `coach_kind_detail` lesen `session_zielliste` und folgen damit automatisch.
3. **Prüffragen sind keine Aufgaben.** `skill_pruefung` hat keinen Bezug zu `tasks` und keinen Ausschluss (Status nur
   `entwurf`, `geprueft`, `freigegeben`; das Lena-Board prüft sie nicht). `testlauf_inhalt_sichtbar(task)` lässt sich
   deshalb nicht wörtlich anwenden. Übertragen heißt: Im Testlauf zählt jede Prüffrage des Skills (nichts ist
   ausgeschlossen). Reihenfolge: freigegeben vor geprüft vor Entwurf, dann die älteste (wie bei Hinweisen in T3).
   Ohne Testlauf bleibt es bei `freigegeben` in der bisherigen Reihenfolge (`angelegt`, `id`). `session_pruefung_frage`
   selbst bleibt unverändert; die drei Aufrufer nutzen die neue Hilfe mit der Session.
   „Ungeprüft, aber sichtbar“ aus dem Auftrag (Test 2) ist hier eine Prüffrage im Status `entwurf`.
4. **`lernpfad_beleg`: Sperre im Kern.** Die Prüfung sitzt in `lernpfad_beleg_core` nach den bisherigen Prüfungen
   (Ergebnis, Hinweis, Skill, anwesend), damit Fehlercodes gleich bleiben und jeder Aufrufer geschützt ist.
   `antwort_abgeben` ruft den Kern im Testlauf ohnehin nicht. Rückgabe im Testlauf: der unveränderte
   `stand_system`, ohne Zeile `offen` (wie `ziel_fertigkeiten`).
5. **Trigger: „gestartet“ vorher oder nachher.** 55000, wenn sich `testlauf` ändert und die Session vorher oder nachher
   gestartet ist (`gestartet_am` gesetzt oder Status nicht `upcoming`), also auch, wenn ein UPDATE Start und Testlauf
   zugleich setzt. Reihenfolge wie im RPC: Admin-Tor (42501), Start (55000), Testkonten (22023). Denselben Wert erneut
   setzen ist keine Änderung und bleibt erlaubt. `session_c2.test.sql` setzte `testlauf` nach dem Start und setzt ihn
   jetzt davor (sonst unverändert).
6. **Engine: jedes erste Warten.** Der Vorschlag aus F2 (`if v_letzt.id is null or not (…)`) trägt nicht nur `kein_ziel`
   ein, sondern jedes erste Warten ohne Skill, praktisch `checkin_laeuft`, wenn das Tablet vor dem Check-in fragt
   (Test 6, letzte Zusicherung). Das ist die Absicht „jedes Warten eine Zeile“. Gelesen wird `session_schritte` vom
   Planer (`v_letzt`: nur `art`/`phase` für offene Aufgaben und Check-out, ein Warten mit Phase `checkin` ändert dort
   nichts), von der Coach-Sicht (`schritt`, `wartet` nur bei `kein_ziel`/`pool_leer`) und von Analysen.
7. **Laufzeit.** Die neuen Hilfen tragen `ROWS`-Schätzungen (5 bzw. 30). Mit der Standardschätzung 1000 lag der Plan von
   `ziel_fertigkeiten_sitzung` lokal über `jit_above_cost`; die JIT-Übersetzung kostete rund 50 ms je Aufruf (Prod hat
   `jit = off`, dbread 12.10.). Danach je 1000 Aufrufe lokal: `session_zielliste` 773 → 839 ms, `ziel_fertigkeiten_core`
   630 → 723 ms; 300 Vorschauen `session_naechster_schritt` 583 → 542 ms (Rauschen in derselben Größenordnung).

## Zweitprüfung (CLAUDE.md §8)

Unabhängige Instanz, nur lesend (Code, Prod-Definitionen per dbread): **freigeben**, kein Befund hoch oder mittel.
Geprüft: Treue von `lernpfad_sicht` zu `pfad_tiefer`, gleiches Ergebnis ohne Testlauf (NULL-Semantik, Sortierung,
Spalten), Äquivalenz der Pool-Regel, Rechte (alle Aufrufer der owner-only Hilfen sind Definer, kein Default-ACL),
weitere Schreiber auf `coaching_sessions.testlauf` (nur der RPC), Leser von `session_schritte`. Übernommen: Tests für
einen gescheiterten Eingriff (Plan bleibt) und für `lernpfad_sicht` ohne Session (alle Spalten gleich `lernpfad`);
niedrige Befunde stehen unten (3 bis 5).

## Offene Punkte

1. **Coach sieht Erwartung und Kriterium einer Prüffrage im Entwurf nicht.** `skill_pruefung_lesen(skill)` (Coach-Sicht,
   `src/lib/supabase/lernpfad.ts`) kennt keine Session und liefert weiter nur `freigegeben`. Im Testlauf steht dann eine
   Entwurfsfrage auf dem Tablet, die Schublade zeigt aber keine Erwartung. Signatur durfte sich nicht ändern; eine
   Session-Variante bräuchte einen neuen RPC und eine Änderung in `src/pages/coach/**` (Coach-Fenster).
   **Wer:** Rasit, ob gewünscht; dann Foundation (RPC) und Coach-Fenster.
2. **Nur „tiefer“ wird nachgebildet, keine Belege.** Ein Testlauf schreibt keine Belege (T2), also ändert sich der
   Lernpfad im Testlauf nicht durch Antworten. Vor „tiefer“ kann die Zielliste deshalb anders aussehen als echt (im Test
   1a ist `zz_a2_v1` echt nach vier falschen Warm-up-Antworten `aktiv`, im Testlauf `sicher`). Nach „tiefer“ ist sie
   gleich, und der nächste Schritt auch. Wer auch Belege im Testlauf nachbilden will: eigene Entscheidung.
3. **`pfad_tiefer` wählt die Voraussetzung aus dem echten Lernpfad.** Ohne ausdrückliche Voraussetzung sortiert
   `pfad_tiefer` die offenen Voraussetzungen nach `lernpfad.stand_system`. Bei zwei „tiefer“ hintereinander in
   derselben Testlauf-Session kann die zweite Wahl deshalb von einer echten Session abweichen (die Sicht wird dort nicht
   gelesen). `pfad_tiefer` war nicht Teil der Entscheidung. Aus der Oberfläche kommt „tiefer“ nur über `pfad_entscheiden`
   und `eingriff_notieren`; der Wrapper `pfadTiefer` wird von keiner Seite gerufen.
4. **`session_plan_warmup` und `session_sichere_skills` lesen `lernpfad` direkt** (Warm-up-Kandidaten, Sortierung
   „bekannter Skill zuerst“). Im Testlauf zählt dort eine nur in der Sicht vorhandene Zeile nicht. Wirkung nur, wenn ein
   Coach ausdrücklich eine schon sichere Voraussetzung wählt (die Standardwahl nimmt nur nicht sichere). Nicht geändert.
5. **Trigger nur bei UPDATE.** Ein INSERT mit `testlauf = true` und schon gestartetem Status geht wie vorher durch
   (Admin-Tor und Testkonten greifen weiter). Nicht Teil der Entscheidung 5.
6. **CI-Schemavergleich bis zum Einspielen rot.** Laut Auftrag wird `supabase/schema-erwartet.sql` erst nach dem
   Einspielen angefasst (wie T2 Punkt 4).
