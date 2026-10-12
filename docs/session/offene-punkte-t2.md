# Offene Punkte T2 (Testlauf-Schalter, kein Lernpfad im Testlauf, drei Härtungen)

Stand 12.10.2026 · Branch `feat/rasit-session-t2-testlauf` · Anlass: offene-punkte-t1 Befunde 1 und 3,
offene-punkte-x0c „Weitere offene Punkte“ 2 und 5

## Was T2 ändert

| Was | Wo | Wirkung |
|---|---|---|
| Testlauf-Schalter | `/admin/schedule`, Karte je Session (`SessionTestlaufSchalter`) | Admin setzt/nimmt „Testlauf“ ohne SQL-Editor; Kennzeichen „Testlauf“ oben in der Karte |
| Nur vor dem Start | `session_testlauf_setzen` (`20261013140830`) | gestartet (`gestartet_am` gesetzt oder Status nicht `upcoming`) → 55000, Hinweis `session_gestartet` |
| Kein Lernpfad im Testlauf | `pfad_tiefer`, `mastery_entscheiden` (`20261013140852`) | im Testlauf keine Zeile in `lernpfad` / `lernpfad_protokoll`; Prüfungen, Rückgabe und Session-Ereignisse wie in einer echten Session |
| Härtungen | `erklaer_status_setzen`, `lsa_uebernahme`, Rechte `authoring_review_meta` (`20261013140911`) | NULL → 22023; anon ohne EXECUTE |

## Entscheidungen, die den Wortlaut auslegen

1. **Nur zwei der vier Funktionen ersetzt.** `pfad_entscheiden` und `eingriff_notieren` schreiben selbst nur in
   `session_ereignisse`; in den Lernpfad kommen sie ausschließlich über `pfad_tiefer`. Die Sperre sitzt deshalb in
   `pfad_tiefer` (und `mastery_entscheiden`), die beiden Aufrufer bleiben unverändert. Beleg: Prod-Definitionen per
   `pg_get_functiondef` (gleich der Wegwerf-DB); pgTAP `session_t2` 2a/2b zeigt dasselbe Ereignis in echt und Testlauf.
2. **Eigener Code nach dem Start: 55000** (`object_not_in_prerequisite_state`) statt 42501, damit die Oberfläche
   „schon gestartet“ von „nur Admin“ unterscheiden kann. Das Admin-Tor kommt weiter zuerst (Coach nach dem Start: 42501).
3. **`erklaer_status_setzen`: auch `p_objekt is null`** wirft jetzt 22023. Gleiche Lücke, gleiche Zeile.
4. **`lsa_uebernahme`: 22023 nach dem Rollen-Tor**, nicht davor. Ein Konto ohne Rolle bekommt weiter 42501.
5. **`authoring_review_meta`: Recht über PUBLIC entzogen.** anon hatte EXECUTE nicht direkt, sondern über PUBLIC
   (`proacl` in Prod: `{=X/postgres,postgres=X/postgres,authenticated=X/postgres}`). Ein `revoke … from anon` allein
   hätte nichts geändert. `service_role` bekommt das Recht ausdrücklich, damit nur anon etwas verliert.
   Aufrufer ohne Anmeldung gibt es nicht: einziger Aufruf `listReviewMeta` in `src/lib/supabase/taskAuthoring.ts`,
   genutzt nur von `AuthoringItemsPage` hinter `ProtectedRoute allowedRoles={['admin']}`; kein Treffer in
   `supabase/functions/`, `tools/`, `scripts/` oder `~/edvance-app`.
6. **Session-Kopf:** Die Coach-Live-Sicht zeigt „Testlauf“ schon im Kopf (`src/pages/coach/live/LiveKopf.tsx`, seit C2),
   ebenso „Heute“ im Admin (`OffeneSessionsListe`). T2 ergänzt das Kennzeichen in der Stundenplan-Karte; Coach-Dateien
   bleiben unberührt (Surface-Freeze).
7. **Buchen im Testlauf:** Lehnt der Trigger `session_students_testlauf_pruefen` ein echtes Kind ab (22023), zeigt die
   Karte „Im Testlauf sind nur Testkonten buchbar.“ statt des Rohtexts.

## Offene Punkte

1. **„Tiefer gehen“ ändert im Testlauf den nächsten Schritt nicht.** Der Planer liest die Entscheidung aus dem
   Lernpfad, nicht aus der Session: `session_zielliste` → `ziel_fertigkeiten_core(p_student_id, …)` liest
   `lernpfad.stand_system`, dazu prüft `session_zielliste` `lernpfad_protokoll` (`aktion = 'pfad_tiefer'` und
   `session_id`). Ohne diese Zeilen bleibt der Plan beim bisherigen Skill. Beleg pgTAP `session_t2` 2a:
   echt `zz_a2_v1`, Testlauf `zz_a2_s1` (Zusicherung „bleibt beim bisherigen Skill (offener Punkt T2-1)“, kippt, sobald der
   Planer umgebaut ist). Laut Auftrag nicht umgebaut; `session_zielliste` und die Planer-Hilfen gehören F1/C3.
   Vorschlag: Im Testlauf die jüngste `entscheidung_pfad` aus `session_ereignisse` als Ersatz für die Lernpfad-Zeile
   lesen. **Bitte entscheiden, wer das baut.**
2. **Sperre nach dem Start gilt nur für den RPC.** Admins dürfen `coaching_sessions` per RLS (`coaching_sessions_admin_all`)
   direkt schreiben; ein `update … set testlauf = …` nach dem Start geht am neuen Check vorbei (der Trigger
   `coaching_sessions_testlauf_pruefen` prüft nur Rolle und Testkonten). Die Oberfläche nutzt nur den RPC. Wer die
   Regel auch dort will: Startprüfung in den Trigger (gehört nicht zu T2; `session_c2.test.sql` setzt `testlauf` heute
   direkt nach dem Start und müsste dann angepasst werden).
3. **`lernpfad_beleg` prüft `testlauf` nicht.** Der Coach-RPC bucht über `lernpfad_beleg_core` Belege und Stand in den
   Lernpfad, auch mit einer Testlauf-Session. Heute ohne Wirkung: Der Wrapper `lernpfadBeleg` (`src/lib/supabase/lernpfad.ts`)
   wird von keiner Seite aufgerufen; `antwort_abgeben` prüft `testlauf` selbst. Nicht in der T2-Liste.
4. **CI-Schemavergleich bis zum Einspielen rot.** Laut Auftrag wird `supabase/schema-erwartet.sql` erst nach dem
   Einspielen angefasst; bis dahin weicht der Neuaufbau in drei Funktionen ab.
