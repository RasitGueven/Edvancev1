# Diagnose LSA-D: Hänger beim „Weiter“ in der LSA

Stand 22.10.2026. Anlass: Tolunays Test. Nach „Weiter“ dauert der Übergang zur nächsten Aufgabe meist
2–3 s, nicht immer. **Nur Diagnose, kein Fix.**

Messgrundlage:

- **Datenbank:** CI-Neuaufbau (`test-grundlage.sql` + alle Migrationen + `seed.sql`) in einem eigenen
  Wegwerf-Cluster (Postgres 18, `jit=off` wie Prod). Der reine Neuaufbau hat keine einzige Aufgabe im
  Pool, deshalb liegt darauf ein read-only Abzug der Inhaltstabellen aus Prod (dbread `\copy`, Muster
  `tools/p1-wegwerf-db.sh`). Ergebnis: 1186 Aufgaben, 85 im echten Pool, 864 im Testlauf-Pool, genau wie
  in Prod. Gegen Prod wurde **nichts** ausgeführt außer lesenden Abfragen.
- **Simulation:** `tools/lsa-weiter-messung.sql`. Ein Testkonto, Klasse 8, Thema `reelle_zahlen` aktuell,
  15 Themen behandelt (wie Tolunays Sitzung `30091a4d`), 10 % richtig (Tolunay: 14 von 147), alle 8 s
  eine Abgabe, `lsa_start`, dann `lsa_submit` bis `next = null`.
- **Prod, nur beobachtet:** `pg_stat_statements` (read-only, seit 30.08.2026).
- **App:** temporäre Zeitmessung in edvance-app PR #45, für reale Werte am iPad.

## 1. Pfad vom Klick bis zur nächsten Aufgabe

Tolunay testet am Kiosk-Platz (`app/(student)/lsa/platz-task.tsx`, Fläche). Der Hub-Weg `task.tsx`
(`lsa_submit` direkt, eine Anfrage) ist am Ende kurz beschrieben.

| # | Wo | Was | Laufzeit |
|---|---|---|---|
| 1 | `useFlaeche.weiter` | Antwort aus dem Entwurf, `onSubmit` | ~0 |
| 2 | `platz-task.handleSubmit` | nur bei der 1. Abgabe: wartet auf `platz_los` (höchstens 3 s) | einmalig |
| 3 | **HTTP 1** `POST /rest/v1/rpc/platz_submit` | Netz hin und zurück | ~75–150 ms |
| 3a | `platz_submit` | `platz_devices` prüfen, `platz_current_assignment()`, `lsa_sessions`, offene Aufgabe (`lsa_ausgegeben` ⨝ `lsa_responses`) | < 1 ms |
| 3b | → `lsa_submit` | `lsa_sessions` ein zweites Mal, `lsa_may_act_for`, Gate `lsa_ausgegeben`, `tasks`, `task_solutions`, `lsa_abgabeart` | < 1 ms |
| 3c | | `insert lsa_responses` (+ Trigger `lsa_fehlbild_capture`, Wertung `lsa_antwort_korrekt`) | ~1 ms |
| 3d | | `lsa_urteil_buchen_core` (Urteil, ggf. `lsa_mitbelegung`) | ~1 ms |
| 3e | | **`lsa_select_next_core`** (Schleife bis 100, `lsa_abschluss` rekursiv) | **1–5 ms oder 150–450 ms** (lokal) |
| 3f | | `insert lsa_ausgegeben`, `lsa_question_payload(next)` | ~0,1 ms |
| — | | Rückgabe `{ok, next}` mit dem fertigen Payload. **Die App wirft ihn weg.** | |
| 4 | **HTTP 2** `POST /rest/v1/rpc/platz_next` | Netz hin und zurück | ~75–150 ms |
| 4a | `platz_next` | `platz_devices`, `platz_current_assignment()`, `lsa_sessions`, offene Aufgabe, **`lsa_question_payload` ein zweites Mal** | Prod Ø 18 ms |
| 5 | `setPhase` → `FlaecheAufgabe` | alter Inhalt blendet aus (`aufgabeAus` 220 ms), **erst danach** steht der neue | 220 ms |
| 6 | `FlaecheInhalt` | neuer Inhalt läuft ein (`aufgabeEin` 480 ms, Staffel bis 200 ms) | ~500–700 ms bis ruhig |
| 7 | `AssetBild` / `useAbbildungSvg` | SVG-Abbildung wird **erst nach dem Rendern** geladen (Storage, eine weitere Anfrage) | ~100–300 ms, nur Aufgaben mit Abbildung |

Daneben läuft `platz_state` alle 3 s (Prod: 12 746 Aufrufe, Ø 2 ms, max. 452 ms). Es teilt sich die
HTTP/2-Verbindung und hält nichts auf.

### Sequenziell, obwohl es nicht sein müsste

- **3 → 4:** `platz_next` wartet auf `platz_submit` und liefert dann genau das, was `platz_submit` schon
  zurückgegeben hat (`lsa_submit` → `next`). Eine ganze Runde Netz plus `lsa_question_payload` doppelt.
  Parallelisieren hilft nicht, die Anfrage ist schlicht überflüssig.
- **4 → 5:** Das Ausblenden (220 ms) beginnt erst, wenn die Daten da sind. Es könnte mit dem Klick
  starten und in der Netzzeit verschwinden.
- **6 → 7:** Die Abbildung der nächsten Aufgabe wird erst geladen, wenn sie gerendert ist. Ihre URL steht
  aber schon im Payload.
- In der DB laufen 3a–3f in einer Transaktion. Die doppelten Lesezugriffe (`lsa_sessions` zweimal, offene
  Aufgabe zweimal) kosten zusammen unter 1 ms und sind nicht die Ursache.

## 2. Messung `lsa_select_next_core` (CI-Neuaufbau + Inhalte)

`tools/lsa-weiter-messung.sql`, Testlauf-Pool, 10 % richtig. Je Zehnerblock:

| ab Abgabe | lsa_submit Ø ms | max ms | davon select_next_core Ø ms | Urteile |
|---|---|---|---|---|
| 1–50 | 5–8 | 25 | 2–6 | 5–38 |
| 51–60 | 209 | 455 | 198 | 46 |
| 61–130 | 168–210 | 442 | 172–205 | 51–78 |

Gesamt (130 Abgaben): Median 6 ms, p90 320 ms, max. 524 ms. `lsa_start` 22 ms. `lsa_question_payload`
Ø 0,1 ms. Zweiter Lauf mit 50 % richtig: dasselbe Bild, der Umschlag kommt schon bei Abgabe ~41.

**Wo die Zeit steckt** (auto_explain, `log_nested_statements`, Schwelle 40 ms): **alle 75** langsamen
Anweisungen des Laufs sind dieselbe, nämlich **Schritt 5 „Restzeit“**:

```sql
select t.id from tasks t join skills s on s.skill_key = t.skill_key
 where s.klasse_herkunft <= v_sess.grade
   and public.lsa_im_pool(t.id, v_pool)          -- ← für ~890 Aufgaben ausgewertet
   and t.id not in (… lsa_ausgegeben … union … lsa_responses …)
   and not exists (select 1 from lsa_skill_urteil u where … u.skill_key = t.skill_key)
 order by t.sondierrang nulls last, md5(…) limit 1
```

Plan: `Bitmap Heap Scan on tasks … Filter: (NOT (hashed SubPlan) AND lsa_im_pool(id, true))`, 394 ms für
887 Zeilen. Danach wirft der Anti-Join gegen `lsa_skill_urteil` 407 von 407 Zeilen wieder weg. Der Planer
hält `lsa_im_pool` für billig und prüft es vor dem billigen Ausschluss über die Urteile.

Warum es im Testlauf-Pool teuer ist (einmal über alle 1186 Aufgaben):

| Prädikat | Zeit |
|---|---|
| `lsa_im_pool(id, false)`, echtes Kind | 9 ms |
| `lsa_im_pool(id, true)`, Testkonto/Testlauf | **383 ms** |
| davon `testlauf_inhalt_sichtbar` → `pruef_ausschluss` | 274 ms |
| davon `freigabe_gate_fehler` | 258 ms |

**Warum „nicht immer“:** Sobald Phase T, Tiefe und Breite nichts mehr finden (hier ab Minute ~5–8), fällt
die Auswahl in die Restzeit. Die Restzeit-Aufgabe öffnet ein Urteil, also bedient der nächste Aufruf
den Zweitbeleg billig aus Schritt 2. Danach kommt wieder die Restzeit. Daher der Wechsel schnell/langsam,
Median klein, p90 hoch.

**Echtes Kind (Pool `ready`, 85 Aufgaben):** `lsa_submit` Ø 10 ms, max. 52 ms. Das Problem betrifft
heute nur Testkonten und Testläufe, also genau das, womit wir testen. Es wächst aber mit, sobald der
echte Pool größer wird, weil die Restzeit jede Aufgabe einzeln prüft.

### Prod (nur beobachtet, `pg_stat_statements`)

| RPC | Aufrufe | Ø ms | min | max | Streuung |
|---|---|---|---|---|---|
| `platz_submit` | 278 | **464** | 5 | **3331** | 931 |
| `platz_next` | 288 | 18 | 1 | 208 | 31 |
| `platz_state` | 12 746 | 2 | 0,3 | 452 | 7 |

Prod ist für dieselbe Arbeit grob **4–6× langsamer** als der lokale Cluster (Ø 464 ms gegenüber ~100 ms
lokal, max. 3,3 s gegenüber 0,5 s; geschätzt, kleine Supabase-Compute). 150–450 ms lokal entsprechen
damit **~1–3 s in Prod**. Das deckt sich mit Tolunays Befund.

## 3. Region

| | Ergebnis |
|---|---|
| Supabase | Pooler `aws-1-eu-central-1` = **Frankfurt**. Edge `cf-ray …-DUS` (Düsseldorf). |
| Vercel edvance-app | `vercel.json`: nur `buildCommand` (Expo-Web-Export), `outputDirectory`, SPA-Rewrite. **Keine Funktionen**, kein `api/`. |
| Vercel Edvancev1 | `vercel.json`: nur SPA-Rewrite. **Keine Funktionen**. |
| Pfad | Browser → Supabase direkt (supabase-js `rpc`). Vercel liefert nur statische Dateien und liegt **nicht** im Pfad eines „Weiter“. |

`fra1` ist damit für dieses Problem bedeutungslos, es gibt keine Funktion, die eine Region hätte. Die
Projekt-Settings im Vercel-Dashboard konnte ich nicht einsehen (keine Vercel-CLI, kein `.vercel/`). Für
das Ergebnis spielt das keine Rolle. Netz von hier (WSL, Köln) zu Supabase, warm: TTFB 73–77 ms je
Anfrage, kalt mit DNS, TCP und TLS 190 ms.

## 4. Cold Start

- **Vercel:** keine Serverless- oder Edge-Funktionen, also kein Cold Start. Die Größe des Web-Bundles wirkt
  nur auf den ersten Seitenaufruf, nicht auf „Weiter“.
- **Supabase:** PostgREST und Postgres laufen dauerhaft. Pläne der PL/pgSQL-Funktionen werden je
  Verbindung gecacht. Der Pooler kann eine frische Verbindung zuteilen, die erste Ausführung kostet dann
  ein paar ms Planung, keine Sekunden.
- **TLS:** Das Polling von `platz_state` alle 3 s hält die Verbindung warm. Der kalte Aufbau (~190 ms)
  trifft höchstens den ersten Klick.

Cold Start ist **keine** Ursache.

## 5. Anteile je Schritt bei einem langsamen „Weiter“ (Prod, geschätzt)

| Schritt | Anteil |
|---|---|
| Netz `platz_submit` | 0,1–0,15 s |
| **`lsa_select_next_core` (Restzeit, Testlauf-Pool)** | **1–3 s** |
| Rest von `platz_submit` in der DB | < 0,05 s |
| Netz und DB `platz_next` (überflüssig) | 0,1–0,2 s |
| Ausblenden, bis der neue Inhalt steht | 0,22 s |
| Abbildung nachladen (falls vorhanden) | 0,1–0,3 s |
| **Summe** | **~1,6–3,9 s** |

Bei einem schnellen „Weiter“ bleiben ~0,5–0,7 s: zwei Runden Netz, 220 ms Ausblenden, ggf. die Abbildung.

## 6. Top-3-Ursachen

1. **Restzeit-Abfrage in `lsa_select_next_core` prüft `lsa_im_pool` für jede Aufgabe**, vor dem billigen
   Ausschluss. Im Testlauf-Pool kostet die Prüfung je Aufgabe ~0,3 ms (`freigabe_gate_fehler`), zusammen
   lokal ~400 ms, in Prod 1–3 s. Trifft jeden zweiten Klick ab Minute ~5–8.
2. **Doppelte Runde `platz_next`** nach `platz_submit`, obwohl `platz_submit` den nächsten Payload schon
   liefert. Kostet je Klick eine Runde Netz und den Payload ein zweites Mal (~0,1–0,2 s).
3. **Übergang strikt nacheinander:** Ausblenden erst nach den Daten (220 ms), Abbildung erst nach dem
   Rendern (0,1–0,3 s).

## 7. Fix-Vorschläge mit Aufwand

| # | Vorschlag | Wirkung | Aufwand | Wo |
|---|---|---|---|---|
| A | **Restzeit (und alle `… and lsa_im_pool(t.id, v_pool)`-Stellen) umstellen:** erst nach Urteil und Ausgabe filtern und sortieren, `lsa_im_pool` zuletzt und nur bis zum ersten Treffer prüfen (z. B. `for v_task in select … order by … loop exit when lsa_im_pool(v_task, v_pool); end loop;` oder CTE `materialized` vor dem Pool-Filter) | Restzeit lokal ~400 ms → wenige ms, Prod 1–3 s → < 0,1 s | **S** (eine Migration, Verhalten gleich, Test: gleiche Auswahl wie vorher auf der Fixture) | Edvancev1, Schema-Session |
| B | Pool je Aufruf **einmal** bestimmen (`v_pool_ids uuid[]` am Anfang) statt in jeder Abfrage der Schleife | weniger Streuung, auch Phase T, Breite a und Tiefe | S–M | Edvancev1 |
| C | `freigabe_gate_fehler` / `pruef_ausschluss` billiger machen oder das Ergebnis je Aufgabe mitführen (Spalte, beim Speichern gepflegt) | macht den Testlauf-Pool grundsätzlich so billig wie `ready` | M (DDL, Trigger) | Edvancev1 |
| D | **`platz_next` nach `platz_submit` weglassen:** `platzSubmit` gibt `next` (schon im Vertrag: `{ok, next}`) zurück, `weiter()` nimmt ihn. `platz_next` bleibt für Neuladen und Start. `next: null` heißt durch. | −1 Runde Netz je Klick (~0,1–0,2 s) | **S** (nur App) | edvance-app |
| E | **Optimistischer Übergang:** Ausblenden beim Klick starten statt beim Eintreffen der Daten | −220 ms gefühlt | S | edvance-app `FlaecheAufgabe` |
| F | Abbildung der nächsten Aufgabe vorladen (`queryClient.prefetchQuery(['abbildung','svg',url])`, sobald der Payload da ist, vor dem Rendern) | −0,1–0,3 s bei Aufgaben mit Abbildung | S | edvance-app |
| G | Folgeaufgabe für richtig/falsch vorab berechnen | Die Auswahl hängt vom ganzen Urteilszustand ab (Zweitbeleg, Abstieg, ungeprüft-Einträge), nicht nur von richtig/falsch. Zwei Zweige je Aufgabe vorrechnen hieße zwei Simulationen je Klick. Nach A nicht nötig. | L, **nicht empfohlen** | — |
| H | Themenwechsel-Karte als Überbrückung | überdeckt nur, behebt nichts. Nach A nicht nötig. | M | — |
| I | Vercel-Region `fra1` | **keine Wirkung**, es gibt keine Funktionen | — | — |

Empfohlene Reihenfolge: **A** (die eigentliche Ursache), dann **D + E + F** in einem App-PR. B und C
nur, falls nach A die Messung in Prod noch Ausreißer zeigt.

## 8. Reale Werte messen

edvance-app PR #45 (`feat/rasit-lsa-weiter-diagnose`) loggt je Klick `[lsa-weiter #n]`: `platz_submit`,
`platz_next`, `gesamt` (Klick bis zum ersten Frame mit der neuen Aufgabe) und das Nachladen der
Abbildungen. `globalThis.__lsaWeiter` hält die Gesamtzeiten. Am iPad über den Safari-Webinspektor lesen.
Supabase sendet kein `Timing-Allow-Origin`, deshalb gibt es nur die Gesamtdauer je Anfrage, ohne
Teilzeiten. Die Server-Zeit steht in `pg_stat_statements`. Nach der Messung wieder ausbauen.

## Nebenbefund

Mit dem echten Pool (`ready`, 85 Aufgaben) endete die simulierte Sitzung für Klasse 8 / `reelle_zahlen`
schon nach **10 Aufgaben** (`next = null`). Das ist nicht Teil dieses Auftrags und nicht weiter geprüft.
Für den Launch lohnt aber ein Blick, wie viele `ready`-Aufgaben je Thema da sind.

## Nachbauen

```bash
# eigener Cluster (nie edvance_shadow, nie Prod)
initdb -D ~/wegwerf-db-diag -U postgres --auth=trust
pg_ctl -D ~/wegwerf-db-diag -o "-p 55520 -k /tmp/claude-1000/diag -c listen_addresses=''" start
export PGHOST=/tmp/claude-1000/diag PGPORT=55520 PGUSER=postgres; unset PGDATABASE DATABASE_URL
createdb diag; psql postgresql:///diag -f supabase/test-grundlage.sql
for f in $(ls supabase/migrations/*.sql | sort); do psql -q postgresql:///diag -v ON_ERROR_STOP=1 -f "$f"; done
psql postgresql:///diag -f supabase/seed.sql
# Inhalts-Fixture (read-only aus Prod per dbread \copy, wie tools/p1-wegwerf-db.sh): skills skill_kante themen
# skill_thema thema_einstieg skill_voraussetzung skill_clusters process_competencies microskills tasks
# task_solutions task_figures task_pruef_ausschluss — laden mit session_replication_role = replica
psql postgresql:///diag -c "alter database diag set search_path = public, extensions"
psql postgresql:///diag -v pool=true -v richtig=0.1 -f tools/lsa-weiter-messung.sql
```
