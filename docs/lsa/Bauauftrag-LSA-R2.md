Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-R2: Wir erkennen eine LSA, die ein Kind durchgeklickt hat. Sie wird markiert, der Report sagt das ehrlich, statt Ergebnisse zu behaupten, und die App bekommt ein Signal für einen ruhigen Hinweis an das Kind. Speichere diesen Prompt wörtlich als docs/lsa/Bauauftrag-LSA-R2.md im PR. Lies docs/lsa/durchklicken-auswertung.md (Abschnitt 6, Zählweise, Abfragen), CLAUDE.md §8 und §10, die aktuelle Fassung von lsa_finish und platz_submit in supabase/schema-erwartet.sql, src/pages/admin/ReportPage.tsx, src/lib/supabase/lsaReport.ts, lsaReportListe.ts, src/pages/admin/heute/HeuteImBetrieb.tsx und tools/lsa-testkinder/.

FESTGELEGT (Rasit 22.10.2026):
- schnell = Abgabe mit duration_ms < 5000
- schnell falsch = schnell UND correct = false; „Weiß ich nicht“ zählt nicht als falsch und unterbricht eine Folge
- nicht auswertbar = ≥ 5 schnell falsch in Folge ODER (≥ 10 Antworten UND ≥ 40 % schnell falsch)
- Hinweis an das Kind = 3 schnelle Abgaben in Folge (richtig oder falsch, ohne „Weiß ich nicht“), höchstens einmal je LSA
- Die LSA läuft weiter; den Deckel von 40 Aufgaben baut LSA-V2, nicht dieser Auftrag
- Coach-Markierung = Badge in Admin „Heute“; kein Aufheben, der Weg ist „LSA wiederholen“
- Zählweise: eine Aufgabe = eine Abgabe, Multi-Part zählt einmal

ENTSCHEIDUNGEN (nicht neu verhandeln)

A. Datenbank (eine Migration, Version = date -u +%Y%m%d%H%M%S)
1. Neue Funktion public.lsa_durchklick_stand(p_session_id uuid) returns jsonb, stable, security definer, search_path public, pg_temp.
   - Liefert: antworten, schnell_falsch, anteil_schnell_falsch, folge_schnell_falsch_max, folge_schnell_aktuell (für den Hinweis, ohne WN), nicht_auswertbar (bool), grund ('folge'|'anteil'|null).
   - Die Schwellen stehen nur hier, als Konstanten oben in der Funktion: c_schnell_ms 5000, c_folge 5, c_anteil 0.40, c_min_antworten 10, c_hinweis_folge 3.
   - Execute für admin und coach (wie die übrigen LSA-Lesefunktionen) und intern, nicht für anon/student.
2. lsa_sessions bekommt:
   - auswertbar boolean not null default true
   - nicht_auswertbar_grund jsonb
   - hinweis_tempo_am timestamptz
   Kein Backfill. Prüf, ob die bestehenden RLS-Policies die neuen Spalten abdecken. Ist eine Policy-Änderung nötig: STOPP und melden.
3. lsa_finish schreibt vor dem Setzen von completed auswertbar und nicht_auswertbar_grund aus lsa_durchklick_stand. result_summary bekommt zusätzlich den Schlüssel durchklick mit denselben Kennzahlen.
4. platz_submit gibt zusätzlich hinweis_tempo boolean zurück: true genau dann, wenn folge_schnell_aktuell >= 3 ist und hinweis_tempo_am noch null war. Im selben Aufruf wird hinweis_tempo_am gesetzt. Sonst false. ok und next bleiben unverändert.
5. NICHT anfassen: lsa_select_next_core, lsa_urteil_buchen_core, die Auswahl in lsa_submit (LSA-V2 arbeitet parallel daran; zwei Migrationen dürfen nie dieselbe Funktion ersetzen). Brauchst du dort etwas: STOPP und melden.
6. pgTAP supabase/tests/lsa_durchklicken.test.sql:
   - Eine Klickfolge (2–3 s, falsch) wird ab Aufgabe 10 nicht auswertbar, Grund 'folge'.
   - Ein langsames, schwaches Profil mit viel WN bleibt auswertbar.
   - Die Anteilsregel greift erst ab 10 Antworten.
   - hinweis_tempo kommt genau einmal.
   - WN unterbricht eine Folge.
   - Multi-Part zählt einmal.
   - Alte Sitzungen bleiben auswertbar.
7. Zweitprüfung durch eine unabhängige Instanz (CLAUDE.md §8), Ergebnis im PR.

B. Testkinder
8. tools/lsa-testkinder/erzeugen.sql steht bei 400 Zeilen. Lagere die Kinderdaten (das JSON in lsat.kinder) nach tools/lsa-testkinder/kinder.sql aus und binde sie mit \ir ein. Das Verhalten bleibt gleich, die bestehenden Zusicherungen bleiben grün.
9. Siebtes Testkind:
   - kind "Tim", name "Tim Schuster", lead a5a7c41d-1ead-4000-8000-000000000007, schueler a5a7c41d-5c00-4000-8000-000000000007
   - Klasse 8, ohne Schule, Thema terme_gleichungen
   - antwortet in 2–4 s, fast immer falsch; ein eigenes Zeitmuster ohne die Untergrenze von 26 s ist erlaubt
   Zusicherungen: Tim ist nicht auswertbar; Lina, Emre, Sophie, Jonas, Nele und Max sind auswertbar.

C. Frontend
10. auswertbar und nicht_auswertbar_grund in die Report-Daten (lsaReport.ts) und in LsaReportListItem (lsaReportListe.ts).
11. LSA-Reports-Liste: Kennzeichen „Nicht auswertbar“ (EdvanceBadge, Warnfarbe aus Tokens). „Präsentation“ ist dort deaktiviert, mit Tooltip zum Grund.
12. ReportPage bei nicht auswertbarer LSA:
    - Kein ?ansicht=praesentation; ein solcher Aufruf leitet auf den Bogen um.
    - Der Bogen besteht nur aus dem Kopf von Seite 1 und einem sachlichen Kasten (i18n elternbericht). Vorschlag: „Diese Lernstandsanalyse können wir nicht auswerten. Viele Aufgaben wurden in sehr kurzer Zeit beantwortet. So kurze Antwortzeiten zeigen nicht, was {{name}} kann. Wir wiederholen die Analyse in Ruhe.“ Keine Zahlen, kein Profil, kein Lernweg, kein Förderansatz, keine Paketempfehlung.
    - Darüber steht für Admin und Coach ein Hinweisbalken mit den Kennzahlen und dem Knopf „LSA wiederholen“. Der Knopf führt in den bestehenden Weg zur Freigabe einer neuen LSA für den Lead (Lead-Karte / lead_lsa_freigeben). Gibt es keinen solchen Weg: STOPP und melden.
    - Druck bzw. PDF zeigt genau diese eine Seite.
13. Admin „Heute“: Laufende LSAs bekommen das Badge „schnell“, wenn lsa_durchklick_stand nicht_auswertbar = true oder folge_schnell_aktuell >= 3 meldet. Abgefragt wird über eine lib-Funktion beim Laden und beim bestehenden Aktualisieren, ohne eigenes Polling.
14. Texte nur über i18n (admin, elternbericht). Tabelle der neuen Texte für Lena in docs/lsa/lsa-r2-texte.md.

UMFANG: die Migration, schema-erwartet.sql (Abzug), die pgTAP-Tests, tools/lsa-testkinder/**, src/lib/supabase/lsaReport.ts, lsaReportListe.ts, die lib-Funktion für „Heute“, src/types/**, ReportPage.tsx, src/pages/admin/lsaReports/**, src/pages/admin/heute/**, elternbericht nur Bogen.tsx bzw. eine neue Komponente für die Seite „nicht auswertbar“, i18n, Tests, Retro. NICHT: lsa_select_next_core, lsa_urteil_buchen_core, Präsentation (außer dass sie nicht öffnet), Lernweg, src/lib/report/**.

LEITPLANKEN:
- Worktree ../Edvancev1-lsar2 auf feat/rasit-lsa-durchklicken von origin/dev, PR gegen dev, nie main.
- Migration nur schreiben, NICHT einspielen. Im PR steht der Einspielbefehl mit der sicheren Kette, nicht dbcheck:
  cd ~/Edvancev1-lsar2 && V=<V> N=lsa_durchklicken && [[ "$DATABASE_URL" == *pooler.supabase.com* ]] && psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && [ -z "$(psql "$DATABASE_URL" -tAc "select 1 from supabase_migrations.schema_migrations where version='$V'")" ] && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f supabase/migrations/${V}_${N}.sql && psql "$DATABASE_URL" -c "insert into supabase_migrations.schema_migrations (version,name) values ('$V','$N')" && tools/schema-snapshot.sh
- Baue das Frontend so, dass es ohne die neuen Spalten nicht bricht. Dann ist die Reihenfolge von Merge und Migration egal.
- Prod nur lesend über dbread. Keine echten Namen, IDs oder Zeitstempel ins Repo (das Repo ist öffentlich).
- Dateien ≤ 400 Zeilen. npm run typecheck && npm run lint && npm run test grün, pgTAP im Neuaufbau grün.
- STOPP nach dem PR.

MELDEN:
- PR-Link und Einspielbefehl
- Ergebnis der Zweitprüfung
- Per dbread vorgerechnet: Welche bisherigen Prod-Sitzungen wären nicht auswertbar? Erwartet: nur die Klick-LSA.
- Bildschirmfotos: Liste mit Kennzeichen, Bogen „nicht auswertbar“, „Heute“ mit Badge
- Der genaue Vertrag von hinweis_tempo für die App
- Offene Punkte
