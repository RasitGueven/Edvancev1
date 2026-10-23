# Bauauftrag LSA-A1 · Themenfeld im Aufgaben-Payload

Prompt A aus „Bauauftrag LSA-A · Ansage des Themenbereichs in der LSA“ (Stand 23.10.2026), wörtlich.


```
Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-A1: lsa_question_payload liefert zusätzlich das Themenfeld der Aufgabe, damit die App beim Wechsel den Bereich ansagen kann. Speichere diesen Prompt als docs/lsa/Bauauftrag-LSA-A1.md im PR. Lies src/lib/report/inhaltsbereiche.ts (PRAEFIX, AUSNAHMEN, inhaltsbereich), src/lib/report/elternbericht/themenfelder.ts (THEMENFELDER, feldVon) und die aktuelle lsa_question_payload in supabase/schema-erwartet.sql.

ENTSCHEIDUNGEN (nicht neu verhandeln)
1. Neue Funktion public.lsa_themenfeld(p_skill_key text) returns text, immutable. Sie bildet genau feldVon aus themenfelder.ts nach: AUSNAHMEN zuerst, dann der längste passende Präfix nach ganzen Segmenten, dann Inhaltsbereich → Themenfeld. Unbekannt → 'weitere'. Rückgabe ist der Schlüssel (brueche, prozent, terme, geometrie, groessen, zahlen, funktionen, zufall, weitere), nie ein Text.
2. lsa_question_payload bekommt für alle drei Arten (mc, short_input, multi_part) das Feld 'themenfeld' = lsa_themenfeld(tasks.skill_key). Sonst ändert sich nichts. Da platz_next und lsa_submit den Payload über diese Funktion bauen, kommt das Feld überall an.
3. Gleichlauf-Test, damit SQL und TS nie auseinanderlaufen:
   - Ein Skript tools/themenfeld-fixture.ts erzeugt aus feldVon für alle skill_keys aus src/lib/report/... skillBestand (oder der Liste, die inhaltsbereiche.test.ts nutzt) die Datei supabase/tests/fixtures/themenfeld.sql (Paare skill_key, feld).
   - Ein Vitest prüft, dass die Datei aktuell ist.
   - pgTAP supabase/tests/lsa_themenfeld.test.sql prüft lsa_themenfeld gegen diese Paare und dass lsa_question_payload das Feld für alle drei Arten liefert.
4. Datenvertrag docs/api/DATENVERTRAG.md um 'themenfeld' ergänzen.
5. Rechte: lsa_themenfeld ist eine Hilfsfunktion; execute nicht für anon (wie die übrigen lsa_-Helfer). lsa_question_payload behält seine Rechte.

LEITPLANKEN
- Worktree ../Edvancev1-lsaa1 auf feat/rasit-lsa-themenfeld von origin/dev, PR gegen dev, nie main.
- Migration nur schreiben, nicht einspielen. Version = date -u +%Y%m%d%H%M%S. Im PR der Einspielbefehl mit der sicheren Kette (nicht dbcheck):
  cd ~/Edvancev1-lsaa1 && V=<V> N=lsa_themenfeld && [[ "$DATABASE_URL" == *pooler.supabase.com* ]] && psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && [ -z "$(psql "$DATABASE_URL" -tAc "select 1 from supabase_migrations.schema_migrations where version='$V'")" ] && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f supabase/migrations/${V}_${N}.sql && psql "$DATABASE_URL" -c "insert into supabase_migrations.schema_migrations (version,name) values ('$V','$N')" && tools/schema-snapshot.sh
- Prod nur lesend über dbread: melde, wie viele Skills im LSA-Pool auf 'weitere' fallen (sollte 0 sein).
- npm run typecheck && npm run lint && npm run test grün, pgTAP im Neuaufbau grün.
- STOPP nach dem PR. Melde PR-Link, Einspielbefehl und die Zahl aus „weitere“.
```

