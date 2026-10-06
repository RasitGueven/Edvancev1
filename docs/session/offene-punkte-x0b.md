# Offene Punkte X0b (Rollenprüfungen NULL-sicher)

Stand 06.10.2026 · Branch `feat/rasit-session-x0b-rollen` · Bauauftrag `docs/session/Bauauftrag-Session-P1.md`

## Entscheidungen

1. **Systemaufrufe ohne Profil fallen jetzt durch.** Kein Systemweg ruft eine der elf umgestellten Funktionen:
   kein pg_cron, keine Edge Function, kein Tool und kein Skript (Bestandsaufnahme im PR). Deshalb steht nirgends
   `or public.ist_systemaufruf()`. Folge: Ein Aufruf mit service_role-Key und einer im SQL-Editor als `postgres`
   ohne Claims bekommt jetzt 42501 bzw. P0001. Vorher kam er über die NULL-Lücke durch. Neun der elf Funktionen
   haben `EXECUTE` für `service_role`.
2. **`enforce_mastery_gate` wirft weiter P0001.** Der Auftrag erlaubt nur die Bedingung zu ändern, deshalb kein
   neuer errcode. Für service_role ist der Trigger jetzt zu. Das deckt sich mit `inv1_mastery_gate.test.sql`, das
   den Trigger ausdrücklich als Backstop gegen service_role beschreibt.
3. **Ausnahmeliste des Wächters nach Familien, nicht nach Signaturen.** L5 und A2 bauen parallel. Eine
   Signaturliste würde jede neue Funktion dieser Familien in deren CI rot machen. Die Präfixe stammen wörtlich aus
   dem Auftrag (Abschnitt AUSSCHLUSS). Die Liste darf nur schrumpfen. Der Test gibt die ausgenommenen Treffer
   per `diag` aus.

## Befunde in fremden Familien (nicht geändert)

| Paket | Funktion | Befund | Beleg |
|---|---|---|---|
| A2 | `erklaer_nachlesen(uuid,text)` | **Tor offen.** `if not (coalesce(role,'') = 'admin' or get_my_student_id() = p_student_id or exists …)`: Ohne Schülerzeile ist der mittlere Vergleich NULL, `not (false or NULL or false)` ist NULL. Ein Coach ohne Bezug zum Kind und ein Konto ohne Profil bekommen Zeilen statt 42501. | Prod-Def Z. 8–13; lokale Probe in der Wegwerf-DB: `coach ohne Bezug … zeilen_statt_42501 = 1`, `ohne profil … = 1` |
| A2 | `erklaer_zugang(uuid,uuid)` | Gleiches Muster (`get_my_student_id() = p_student_id` im `not (… or …)`). Danach folgt noch eine `session_students`-Prüfung, das Tor ist also nur halb offen. | Prod-Def Z. 8–13 |
| A2 | `lernpfad_coach_der_session(uuid,uuid)` | SQL-Hilfe `select get_my_role() = 'coach' and exists (…)` liefert ohne Profil NULL, wenn `exists` wahr ist. Praktisch zu, weil `coaching_sessions.coach_id` per FK auf `profiles` zeigt. `exists` ist für ein Konto ohne Profil also immer falsch. Der Wächter führt sie als Ausnahme. | Prod-Def Z. 7; FK `coaching_sessions_coach_id_fkey → profiles` |
| A2 | `mastery_entscheiden`, `lernpfad_beleg`, `pfad_tiefer` | Hängen an `lernpfad_coach_der_session` in `not (… or …)`. Wegen des FK heute zu. | Prod-Def Z. 11–12 bzw. 9–10 bzw. 12–13 |
| L5 | `pruef_*`, `freigabe_*`, `lena_*`, `tasks_pruefer_guard` | Alle mit `is distinct from` / `is not distinct from`, also NULL-sicher. Kein Befund. | Bestandsliste im PR |

Empfehlung an A2: In `erklaer_nachlesen`/`erklaer_zugang` den Vergleich als
`public.get_my_student_id() is not distinct from p_student_id` schreiben oder den ganzen Ausdruck in `coalesce(…, false)`
setzen. `lernpfad_coach_der_session` mit `coalesce(public.get_my_role(), '') = 'coach'`.

## Weiteres

1. **Andere NULL-Quellen als `get_my_role()`** (`get_my_student_id()`, `auth.uid()` in `not (… = …)`) erfasst der
   Wächter nicht. Die Befunde in `erklaer_*` zeigen, dass sich eine eigene Durchsicht lohnt. Nicht im X0b-Umfang.
2. **Policies:** Zwei von 117 Policies mit `get_my_role()` enthalten `not`/`is null`
   (`schueler_notizen_coach_select`, `read_tasks_by_role`). Beide verweigern bei NULL. Kein Handlungsbedarf.
3. **`schema-erwartet.sql`** ist laut Auftrag nicht angefasst. Der CI-Vergleich `neuaufbau` bleibt rot, bis nach dem
   Einspielen `tools/schema-snapshot.sh` gelaufen ist.
