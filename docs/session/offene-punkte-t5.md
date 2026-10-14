# Offene Punkte T5 (Coach im Testlauf)

Stand 14.10.2026 · Branch `feat/rasit-session-t5-coach-testlauf` · Anlass: offene-punkte-t4 Punkt 1,
offene-punkte-sl2b Punkt 1 · Entscheidungen Rasit 12.10.
Beweis: `supabase/tests/session_t5.test.sql` (52 Zusicherungen), `src/lib/session/coachLiveT5.test.ts`,
`src/pages/coach/live/MasteryEntwurf.test.tsx`, `src/lib/supabase/sessionPruefung.test.ts`.

## Was T5 ändert

| # | Was | Wo | Wirkung |
|---|---|---|---|
| 1 | Prüffragen der Session | `20261014104355_t5_pruefung_session`: neu `skill_pruefung_session(session, skill)`, Spalten von `skill_pruefung_lesen` plus `freigegeben boolean` (Rasit 14.10.) | Echt genau `freigegeben` wie `skill_pruefung_lesen`; Testlauf jede Prüffrage des Skills in der Reihenfolge von `session_pruefung_frage_sitzung` (erste Zeile = Frage auf dem Tablet) |
| 2 | `skill_pruefung_lesen` | – | unverändert (Prod und Neuaufbau gleich, md5 von `pg_get_functiondef`) |
| 3 | Live-Sicht | `src/lib/session/coachLive.ts` (`ladePruefung`), `src/lib/supabase/sessionPruefung.ts` (`skillPruefungSession`), `MasteryPruefung.tsx`, `de/coachLive.json` `mastery.entwurf` | Schublade liest über die Session; Kennzeichen „Entwurf“ nur bei `freigegeben = false` |
| 4 | Testtermin durch den Coach | `20261014104412_t5_coach_testtermin`: ersetzt `termin_session_anlegen`, `coaching_sessions_testlauf_pruefen` | Systemweg `edvance.testlauf_anlegen` (transaktionslokal, nur um das INSERT) |
| 5 | Übriger Trigger | dieselbe Migration | UPDATE nur Admin (42501), nach dem Start 55000, nur Testkonten 22023, Fehlercodes unverändert |
| 6 | Kein Client-Weg zur Einstellung | Beleg im PR | siehe unten |
| 7 | Hinweis `testlauf_nur_admin` | `de/slots.json` | Text nennt jetzt den eingeteilten Coach und die Verwaltung |

Signatur, `SECURITY DEFINER`, `search_path` und Grants der beiden ersetzten Funktionen sind unverändert (Prod gegen
Neuaufbau: `prosecdef`, `provolatile`, `proconfig`, `proacl` gleich). Der neue RPC: `SECURITY DEFINER`, `STABLE`,
`search_path = public, pg_temp`, EXECUTE nur `authenticated` (wie `skill_pruefung_lesen`).

## Entscheidungen, die den Wortlaut auslegen

1. **„Sichtbar nach `testlauf_inhalt_sichtbar`“ bei Prüffragen.** Prüffragen sind keine Aufgaben und haben keinen
   Ausschluss (T4, offene-punkte-t4 Entscheidung 3, bestätigt 12.10.). Im Testlauf zählt deshalb jede Prüffrage des
   Skills. Die Bedingung in `skill_pruefung_session` ist wortgleich mit `session_pruefung_frage_sitzung`, die
   `pruefung_aufs_tablet` als Vorbedingung nimmt; die Gleichheit belegt Test 2 je Skill (Zeilen genau dann, wenn
   `pruefung_aufs_tablet` auflegt; alle Prüffragen des Skills; erste Zeile = Frage der Hilfe = Frage auf dem Tablet).
2. **Zugriff über `session_coach_pruefen`** wie `coach_raum_live`: Coach der Session oder Admin, sonst 42501. Eine
   unbekannte Session meldet dort P0002 (Test 3), nicht 42501, wie bei allen Coach-Funktionen der Session.
3. **„Entwurf“ kommt vom Server.** Nachtrag Rasit 14.10.: `skill_pruefung_session` liefert zusätzlich
   `freigegeben boolean` (`status = 'freigegeben'`, serverseitig); den Status selbst bekommt der Coach weiter nicht.
   Die Live-Sicht setzt das Kennzeichen nur bei `freigegeben = false`, ohne zweiten Aufruf. Die Abweichung von
   „gleiche Spalten“ (Entscheidung 1) ist damit freigegeben.
4. **Ausnahme im Trigger NULL-sicher.** Die drei Bedingungen stehen in einem `coalesce(…, false)`: Ist ein Teil
   unbekannt (z. B. `auth.uid()` leer), gilt die Ausnahme nicht. Bedingung (c) verlangt die Rolle `coach` und
   `auth.uid() = new.coach_id`; der Admin geht wie bisher ohne Ausnahme durch. Der X0c-Wächter (R2) ist grün.
5. **Zurücknehmen auch im Fehlerfall.** `set_config(…, '1', true)` steht im inneren Block um das INSERT; scheitert es,
   nimmt der Abbruch des Blocks (Subtransaktion) die Einstellung mit zurück. Test 7 prüft beides (nach Erfolg, nach
   Abbruch) und dass ein direktes INSERT danach in derselben Transaktion 42501 bekommt.

## Beleg zu Entscheidung 6 (kein Client-Weg zur Einstellung)

Per dbread (Prod, 14.10.) und per Aufruf der Prod-API mit dem anon-Key (nur lesend, Probe-Name `edvance.t5_probe`):

- PostgREST liefert nur `public` und `graphql_public` aus: `Content-Profile: pg_catalog` → 406 `PGRST106`, „Only the
  following schemas are exposed: public, graphql_public“.
- `set_config` liegt in `pg_catalog`; `POST /rest/v1/rpc/set_config` → 404 `PGRST202` („Searched for the function
  public.set_config … no matches“). In `public` gibt es keine Funktion `set_config`/`current_setting` (0 Treffer).
- `graphql_public` enthält nur `graphql(text,text,jsonb,jsonb)` (pg_graphql spiegelt Tabellen und Funktionen aus
  `public`, keine aus `pg_catalog`).
- Jede `public`-Funktion mit `set_config` setzt einen festen Namen (`edvance.session_rpc`, `edvance.vertrag_rpc`,
  `edvance.hinweis_status`, `edvance.allow_provisional`, `request.jwt.claims`), keine einen Namen aus Parametern.
  `edvance.testlauf_anlegen` setzt nur `termin_session_anlegen`.
- Dynamisches SQL (`execute`) in `public`: nur `quest_einstellung(text,uuid)`, ohne Grant an anon/authenticated.
- Rollen-Einstellungen (`pg_db_role_setting`) setzen nur `statement_timeout`, `search_path` u. ä., kein `edvance.*`;
  kein `pgrst.db_pre_request`.
- Ein Präfix `request.` wäre angreifbar (PostgREST setzt `request.*` aus der Anfrage); `edvance.` setzt PostgREST nie.

## Zweitprüfung (CLAUDE.md §8)

Unabhängige Instanz, nur lesend (Code, Prod per dbread, Wegwerf-DB nur in `begin … rollback`): **freigeben**, kein
Befund hoch oder mittel. Geprüft: Rücknahme der Einstellung nach Erfolg und Fehler (lokal belegt), kein fremder Code
zwischen `set_config` und Rücknahme (Trigger auf `coaching_sessions`: nur `laufzustand_trg` BEFORE ohne INSERT, kein
AFTER-Trigger, keine Rules; einziges `INSERT INTO coaching_sessions` in `public` ist `termin_session_anlegen`),
Ausnahme exakt (a)+(b)+(c) und NULL-sicher, Beleg zu Entscheidung 6. Niedrige Befunde: Punkte 2, 4 und 10 unten;
pgTAP konnte die Prüfinstanz nicht laden, die Läufe stehen im PR.

## Offene Punkte

1. **Eine geprüfte Prüffrage trägt im Testlauf auch „Entwurf“** (`freigegeben = false`). So gewollt: Kennzeichen nur
   nach `freigegeben`. Prod hat derzeit gar keine Prüffragen (`skill_pruefung` 0 Zeilen, dbread 14.10.).
2. **Leerer Raum im Testtermin.** Sitzt im Raum kein Kind, richtet sich `v_test` nach den übrigen Sessions des Termins
   (SL2b, Entscheidung 5). Ist dort ein Testlauf, legt jetzt auch der eingeteilte Coach den leeren Raum als Testlauf an.
   **Bestätigt (Rasit, 14.10.):** so lassen.
3. **Hinweis `testlauf_nur_admin` praktisch nur noch für Systemaufrufe.** Ein Coach eines fremden Raums scheitert schon
   vorher („nur der eingeteilte Coach dieses Raums“, ohne Hinweis); der Admin und der eingeteilte Coach kommen durch.
   Der Pfad bleibt (Entscheidung 7), der Text in `de/slots.json` nennt jetzt beide.
4. ~~**Coach-Fälle hängen an „heute“.**~~ Erledigt (Rasit 14.10.): `session_t5` bestimmt den nächsten Betriebstag ab
   heute (`tagc`) und stellt `slots_jetzt` in der Testtransaktion für Coaches auf `tagc` 12:00 (Admin/System weiter
   über `p_jetzt`; Muster wie `betriebstag` in `slots_festschreiben`). Kein skip mehr. Gegenprobe: mit heute bis +3 als
   Feiertag springt `tagc` auf den 02.11. (Herbstferien dazwischen), alle 52 Zusicherungen grün.
5. **`slots_sl2b` Zusicherung 58 umgestellt.** Sie erwartete für den eingeteilten Coach 42501 `testlauf_nur_admin` und
   erwartet jetzt Erfolg (gewollte Änderung nach Entscheidung 4); Anzahl unverändert (67).
6. ~~**CI-Schemavergleich bis zum Einspielen rot.**~~ Erledigt mit dem Einspielen am 14.10. (siehe unten).
7. **Abweichungen Prod gegen Neuaufbau, nicht von T5.** `lsa_hint` kommt aus E3 (#244, in Prod, nach dem Abzweig dieses
   Branches in dev); nach dem Einmischen von `origin/dev` gleich (dbread 14.10.). `lsa_fehlbild_match` unterscheidet sich nur im
   ACL (Prod mit ausdrücklichen Grants an authenticated/service_role, Neuaufbau ohne). Altbestand, nicht angefasst.
8. ~~**Ein Aufruf mehr im Testlauf.**~~ Entfällt mit `freigegeben` vom Server (ein RPC je Takt, auch im Testlauf).
9. **„Keine freigegebene Prüffrage“.** Der Text `mastery.keineFrage` passt im Testlauf nur halb (dort fehlt jede
   Prüffrage). Nicht geändert.
10. **Regel gegen künftige Lücken (Zweitprüfung Befund 3).** Entscheidung 6 hängt daran, dass PostgREST nur `public`
    und `graphql_public` ausliefert und keine `public`-Funktion einen Einstellungsnamen aus Parametern setzt. Vorschlag:
    ein Wächter-Test, der `set_config(` mit nicht konstantem ersten Argument in `public` meldet. Nicht Teil von T5.

## Eingespielt (14.10.2026)

Vorher `origin/dev` eingemischt (E3 #244, Batu #245; konfliktfrei), Wegwerf-DB neu aus allen 274 Migrationen: alle
pgTAP-Dateien grün außer den 8 aus `bekannt-rot.txt` (`session_t5` 52, `slots_sl2b` 67, `session_x0b` 28,
`session_x0c` 39, `session_e3_hinweise` 22); Frontend typecheck, lint, test grün (135 Dateien, 1142 Tests).
Je Migration `~/bin/mig` (CLAUDE.md §10: DB-Check, Versionscheck, eine Transaktion, History-Eintrag), in dieser
Reihenfolge: `20261014104355`, `20261014104412`, beide `OK`.
Prüfung per dbread:
- Beide Versionen stehen in `supabase_migrations.schema_migrations`.
- `skill_pruefung_session`, `skill_pruefung_lesen`, `termin_session_anlegen`, `coaching_sessions_testlauf_pruefen`:
  md5 von `pg_get_functiondef`, `prosecdef`, `proconfig`, `proacl` gleich dem Neuaufbau; Trigger
  `coaching_sessions_testlauf_trg` aktiv.
- Alle `public`-Funktionen gegen den Neuaufbau: einzige Abweichung `lsa_fehlbild_match` (nur ACL, Punkt 7).
`supabase/schema-erwartet.sql` per `tools/schema-snapshot.sh` neu erzeugt (nur die drei T5-Objekte geändert); gegen
den lokalen Neuaufbau mit dem CI-Filter ohne Unterschied.
