# Retro 14.10.2026 — Session T5: Coach im Testlauf

**Gebaut:** Neuer RPC `skill_pruefung_session(session, skill)`: echt genau die freigegebenen Prüffragen (wie
`skill_pruefung_lesen`), im Testlauf jede, die `pruefung_aufs_tablet` auflegen darf, in derselben Reihenfolge. Die
Coach-Live-Sicht liest darüber und kennzeichnet im Testlauf eine nicht freigegebene Frage mit „Entwurf“. Der
eingeteilte Coach legt einen reinen Testtermin selbst als Testlauf an: `termin_session_anlegen` setzt um das INSERT
die transaktionslokale Einstellung `edvance.testlauf_anlegen`, der Trigger lässt das nur mit Raum, Zeit und dem Coach
der Zeile durch. Zwei Migrationen (`20261014104355`, `20261014104412`).

**Entscheidungen:** „Entwurf“ kommt aus `freigegeben` vom Server (Nachtrag Rasit 14.10.; den Status selbst liest der
Coach nicht). Die Coach-Fälle im Test laufen an jedem Tag über eine Testuhr (`slots_jetzt` transaktionslokal). Zugriff über `session_coach_pruefen` wie die übrigen Coach-Funktionen der Session. Die
Ausnahme im Trigger steht in einem `coalesce(…, false)`, damit der X0c-Wächter sie als NULL-sicher erkennt.

**Gelernt:** Das Muster „Systemweg über eine `edvance.*`-Einstellung“ gab es schon (`session_rpc`, `vertrag_rpc`,
`hinweis_status`) — für den Beleg, dass ein Client sie nicht setzen kann, reichen PostgREST-Antworten (`PGRST106` nennt
die ausgelieferten Schemas) plus die `set_config`-Aufrufer in `public`. Ein Testrunner, der Tests in eine Kopie legt,
muss `supabase/migrations` mitkopieren (zwei Tests binden Migrationen per `\ir` ein).

**Offen:** `docs/session/offene-punkte-t5.md` (geprüfte Frage trägt auch „Entwurf“, Wächter gegen `set_config` mit
Parameter-Namen). Einspielen erst nach „T5 einspielen“.
