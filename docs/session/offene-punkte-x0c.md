# Offene Punkte X0c (Zugangsprüfungen NULL-sicher über get_my_role() hinaus)

Stand 08.10.2026 · Branch `feat/rasit-session-x0c-null` · Anlass: `offene-punkte-x0b.md`, „Weiteres“ 1

## Ergebnis

**Keine Funktion und keine Policy lässt bei NULL durch.** Deshalb gibt es keine Migration und nichts einzuspielen.
Die Befunde aus X0b (`erklaer_nachlesen`, `erklaer_zugang`) hat A2 in `20261008124412_a2_verdrahtung_a1_e1.sql`
geschlossen, A2c hat die Fassung übernommen (`20261010100426`). X0c liefert den Wächter, der das festhält
(`supabase/tests/session_x0c.test.sql`), und die Bestandsaufnahme unten.

Grundlage: alle Funktionen in `public` mit Sprache `sql`/`plpgsql` (383) und alle Policies in `public`/`storage`
(202), gelesen per `dbread` am 08.10.2026. Prod und `origin/dev` tragen dieselben Migrationen
(`schema_migrations` gegen `supabase/migrations/` abgeglichen, keine Abweichung). Die Wegwerf-DB aus `dev` hat also
dieselben Funktionstexte.

## Bestand: NULL-Quellen in Funktionen

133 der 383 Funktionen enthalten `get_my_role()`, `get_my_student_id()`, `auth.uid()` oder `is_parent_of_student`.
Je Fund das Muster, ob NULL durchlässt und wer betroffen wäre. „Platz“ = Platz-Konto (Rolle `student`, keine
`students`-Zeile), „ohne“ = Konto ohne Profil, „Coach“ = Coach ohne Bezug zum Kind.

### get_my_student_id() (alle 10 Funktionen)

| Funktion | Muster | NULL lässt durch? | Betroffen, wenn es durchließe |
|---|---|---|---|
| `erklaer_nachlesen` | `if not coalesce(… or get_my_student_id() = p_student_id or exists …, false)` | nein (seit A2) | ohne, Platz, Coach |
| `erklaer_zugang` | wie oben | nein (seit A2) | ohne, Platz, Coach |
| `quest_termin_setzen(uuid,timestamptz)` | wie oben, dazu `v_coach = auth.uid()` im `coalesce` | nein | ohne, Platz, Coach |
| `lsa_may_act_for` | `coalesce(get_my_student_id() = p_student_id, false)` in SQL-Hilfe | nein, liefert nie NULL | ohne, Platz |
| `quest_inhalt`, `quest_erledigt` | `get_my_student_id() is distinct from v_quest.student_id` → raise | nein | ohne, Platz, Coach |
| `push_token_registrieren` | `v_student is null` → raise | nein | Platz |
| `complete_task` | `v_student is null` → return, schreibt nichts | nein | Platz |
| `mein_lernpfad` | `coalesce(get_my_student_id(), Kind der Tablet-Zuweisung)`, danach `is null` → 42501 | nein; gewollt: Platz mit Zuweisung sieht das eigene Kind | — |
| `session_ids_fuer_schueler` | `where ss.student_id = get_my_student_id()` (Filter für Policies) | nein, liefert leer | — |

### auth.uid()

| Muster | Funktionen | NULL lässt durch? |
|---|---|---|
| Vergleich in `exists (…)` oder `where` | `coach_hat_platz`, `darf_pruefen`, `erklaer_nachlesen`, `erklaer_zugang`, `is_parent_of_student`, `lernpfad_coach_der_session`, `mein_lernpfad`, `platz_current_assignment`, `quest_erzeugen`, `quest_termin_setzen`, `session_ids_fuer_coach`, `session_ist_coach`, `session_tablet_platz`, `tablet_stand`, `platz_*` | nein: `exists` ist falsch, der Filter leer |
| `if not exists (… platz_devices where profile_id = auth.uid())` → raise | `platz_avatar_set`, `platz_finish`, `platz_next`, `platz_state`, `platz_submit` | nein |
| `auth.uid() is null` → raise | `audit_log_schreiben`, `notiz_anlegen` | nein |
| Nur Akteur-Spalte (`…_von`, `created_by`, `geprueft_von` …), nach dem Tor | 40 Funktionen, z. B. `antwort_abgeben`, `tablet_zuweisen`, `vertrag_starten`, `pruef_entscheiden` | keine Prüfung; bei Systemaufrufen bleibt die Spalte NULL, das ist gewollt |
| Claims-Tausch auf `platz_assignments.created_by` | `platz_finish`, `platz_submit` | nein: Ist `created_by` NULL, liefert `lsa_may_act_for` false und es kommt 42501 |

### get_my_role() und Hilfen

- 72 Funktionen mit `coalesce(get_my_role(), '')`, 15 mit `get_my_role() is [not] distinct from` (L5-Familie), dazu
  `darf_pruefen` mit `coalesce(…, false)`. Das hält der X0b-Wächter fest. Kein neuer Befund.
- Rollenvariablen in `if … elsif … else raise`-Ketten (`akte_sessions`, `einheiten_stand`, `fortschritt`,
  `session_platz_kandidaten`): NULL fällt in den `else`-Zweig und wirft. NULL-sicher.
- Boolesche Hilfen, die in `if not hilfe(…)` stehen, liefern nie NULL: `akte_aktiv`, `coach_hat_platz`, `darf_pruefen`,
  `home_quests_aktiv`, `lernpfad_coach_der_session`, `lernpfad_darf_lesen`, `lsa_darf_starten`, `lsa_may_act_for`,
  `session_ist_coach`, `session_im_pool` (alle mit `exists`, `coalesce` oder `case … else false`).
- Nullbare Spalte in einer Prüfung: `coaching_sessions.coach_id` ist nullbar. Verglichen wird sie nur in
  `exists (…)` oder innerhalb von `coalesce(…, false)` (`quest_erzeugen`, `quest_termin_setzen`). Die übrigen Spalten
  in Toren (`session_tablets.student_id`, `quests.student_id`, `lsa_sessions.student_id`, `…status`) sind `not null`.

## Bestand: Policies

202 Policies. 118 nutzen `get_my_role()`, 19 `get_my_student_id()`, 17 `auth.uid()`. In einer Policy heißt NULL
„verweigert“. Durchlassen könnte NULL nur über `is [not] distinct from`, `is null` oder `coalesce(…, true)` an einer
NULL-Quelle. Keine Policy hat eines dieser Muster. Die beiden Policies mit `IS NOT NULL` (`dokument_fassungen_select`
mit `auth.uid() is not null`, `read_tasks_by_role` mit `get_my_role() is not null`) verweigern bei NULL. **Keine
Änderung.**

## Wächter (`session_x0c.test.sql`)

Sucht in allen Funktionen in `public` die Bedingungen, die direkt ein `raise` (oder `pruef_fehler`) auslösen. NULL-Quellen
sind `get_my_*()`, `auth.uid()` und Variablen, die direkt daraus gesetzt werden. `coalesce(…)` und `exists (…)` gelten
als sicher und werden vorher herausgeschnitten.

| Regel | Muster |
|---|---|
| R1 | Quelle in `<>`, `!=` oder `not in` |
| R2 | Quelle in `=` oder `in` innerhalb von `not (…)` |
| R3 | SQL-Hilfe vom Typ `boolean`, deren `select` nackt vergleicht |
| P | Policy: Quelle in `is [not] distinct from`, `is null` oder `coalesce(…, true)` |

Ausnahmen (namentlich, bis C3 sie übernimmt): `coach_raum_live`, `coach_kind_detail`, `raum_signale`,
`session_briefing`, `satz_vorschlaege`, `session_naechster_schritt`, `session_schritt_planen`, `session_schritt`,
`session_schritt_oeffentlich`, `session_plan_warmup`, `session_plan_kern`, `session_plan_checkout`,
`session_zielliste`. Heute trifft keine davon ein Muster; der Test gibt die ausgenommenen Treffer per `diag` aus.

## Für C3

1. **Keine Befunde in den C3-Funktionen.** `coach_raum_live`, `coach_kind_detail`, `raum_signale`, `session_briefing`,
   `satz_vorschlaege` gehen über `session_coach_pruefen` → `session_ist_coach` (`case … else false`).
   `session_naechster_schritt` nimmt `coalesce(session_ist_coach(…), false)`, sonst `session_tablet_platz`
   (`if not found` → 42501). Dessen `p_student_id <> t.student_id` ist sicher, weil `session_tablets.student_id`
   `not null` ist und `p_student_id is not null` davor steht.
2. **Ausnahmeliste übernehmen:** Sobald C3 gemergt ist, die Einträge in `pg_temp.c3_ausnahme` streichen. Die Liste
   darf nur schrumpfen.
3. Neue Tore bitte in einer der sicheren Formen schreiben: `coalesce(…, false)` um das ganze `not (…)`, `is distinct
   from` statt `<>`, oder `exists (…)`.

## Weitere offene Punkte

1. **`lsa_may_act_for` lässt jeden Coach bei aktiver Akte zu**, auch ohne Session-Bezug. Das ist die X0-Matrix
   (Coach-Zugriff über `akte_aktiv`) und hat mit NULL nichts zu tun. Der Test hält das als `true` fest, damit eine
   Änderung auffällt.
2. **`authoring_review_meta()`** ist `SECURITY DEFINER` und hat `EXECUTE` für `anon`. NULL-sicher, weil der Filter
   `get_my_role() = any (…)` für anon leer bleibt. Ob `anon` das Recht braucht, ist eine Rechte-Frage und kein
   NULL-Befund. Nicht geändert.
3. **`ist_systemaufruf()`** wertet fehlende Claims als Systemaufruf (`coalesce(auth.role(), 'service_role')`). Das ist
   gewollt (SQL-Editor als `postgres`). Über PostgREST ist `auth.role()` nie NULL.
4. **Grenzen des Wächters:** Er findet keine Vergleiche zwischen zwei nullbaren Spalten ohne Identitäts-Helfer, keine
   `return`-Ausdrücke in booleschen plpgsql-Funktionen und keine Tore in `case`. Diese Formen kommen in Prod nicht in
   einer Prüfung vor (Durchsicht oben). Die Muster sind Textmuster; wer eine sichere Form außerhalb von `coalesce`/
   `exists` schreibt (z. B. eigene Hilfe), kann ein falsches Rot bekommen. Dann die Form umstellen, nicht die Regel lockern.
5. **Rechte der Konten nicht geprüft:** X0c prüft nur NULL-Durchlass, nicht, ob die Rechte selbst richtig gesetzt sind
   (z. B. `dokument_fassungen` für jedes angemeldete Konto lesbar).
