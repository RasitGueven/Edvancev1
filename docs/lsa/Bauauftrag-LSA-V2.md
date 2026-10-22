# Bauauftrag LSA-V2 · Ausblick, „Weiß ich nicht“ ohne Zweitbeleg, Deckel 40

Stand 22.10.2026. Der Prompt steht unten wörtlich.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-V2: drei Änderungen an der LSA-Auswahl in EINER Migration. (1) Ausblick: Starke Kinder gehen in den Stoff, der als Nächstes kommt. (2) „Weiß ich nicht“ als erste Probe ist sofort final, ohne Zweitbeleg. (3) Deckel von 40 Aufgaben. Dazu kommt die Darstellung im Report: Vorgriffe sind nie Übungsbedarf. Speichere diesen Prompt wörtlich als docs/lsa/Bauauftrag-LSA-V2.md im PR. Lies supabase/migrations/20261022065539_lsa_v_vorschau.sql (aktuelle lsa_select_next_core), 20261021083001_lsa_urteil_eingabeformat.sql (lsa_urteil_buchen_core), docs/lsa/Bauauftrag-LSA-V.md, docs/lsa/durchklicken-auswertung.md (Abschnitte 5 und 6), tools/lsa-testkinder/README.md sowie src/lib/report/elternbericht/bereiche.ts, zaehlung.ts, schwerpunkte.ts und lernweg.ts.

ANLASS: Max (nichts falsch) war nach 5:20 Minuten fertig, Lina nach 12. Jonas (sehr schwach, oft „Weiß ich nicht“) kommt nicht bis Klasse 5/6, weil jede erste Probe ohne „voll“ einen Zweitbeleg auslöst. Die Klick-LSA hatte 135 Aufgaben.

ENTSCHEIDUNGEN (nicht neu verhandeln)

A. Ausblick (neue Phase in lsa_select_next_core, nur mit Thema)
1. Neue Reihenfolge: Zweitbeleg → T → Tiefe → Vorschau → Thema vertiefen → AUSBLICK → Rückblick → Ende.
2. Nur für starke Kinder. Bei jedem Aufruf geprüft: mindestens 6 direkt belegte Urteile (belegt_direkt, offen = false), davon mindestens 75 % traegt. Konstanten c_ausblick_min_urteile 6 und c_ausblick_anteil 0.75 oben in der Funktion.
3. Kandidaten:
   - die Einstiegsknoten (thema_einstieg) der nächsten c_ausblick_themen = 3 Plan-Themen nach der aktuellen Position, also dieselbe Liste wie v_kommend, nur länger;
   - reicht der Plan der Klasse nicht, geht es im Plan der Klasse + 1 weiter; ohne Plan dieselbe KLP-Folge wie die Vorschau;
   - Klassengrenze: klasse_herkunft <= grade + 1;
   - Reihenfolge: nächstes Thema zuerst, im Thema kleinster fundament_tiefe zuerst, dann skill_key;
   - nur Knoten ohne Urteil in der Sitzung und mit freier Aufgabe im Pool.
4. Stopp: Haben zwei Ausblick-Knoten hintereinander nicht traegt ergeben, endet der Ausblick für diese Sitzung. Weiter mit dem Rückblick.
5. Ausblick-Knoten bekommen keinen Abstieg; die Tiefe ignoriert sie. Einen Zweitbeleg gibt es nur, wenn die erste Probe „voll“ war und die Aufgabe MC ist. Eine falsche erste Probe wird final ohne Zweitbeleg. Definition in EINER Hilfsfunktion lsa_ist_ausblick(session, skill), die lsa_select_next_core und lsa_urteil_buchen_core benutzen.
6. Keine eigene Zeitgrenze; es gilt die 19-Minuten-Grenze. Die Vorschau aus LSA-V bleibt, wie sie ist.

B. „Weiß ich nicht“ ohne Zweitbeleg
7. In lsa_urteil_buchen_core ist eine erste Probe mit Ergebnis weiss_nicht oder leer sofort final: nicht_angesetzt, offen = false, proben_anzahl 1. Das gilt überall, auch im Thema.
8. Falsch, teilweise und MC richtig behalten ihren Zweitbeleg.
9. Der Report bleibt unverändert: nicht_angesetzt mit einer Probe zeigt er schon als „übersprungen“. Mit Test absichern.

C. Deckel
10. In lsa_select_next_core direkt neben der 19-Minuten-Prüfung: return null, sobald die Sitzung 40 Aufgaben ausgegeben hat (lsa_ausgegeben, nicht Antwortzeilen). Konstante c_max_aufgaben 40. Gilt für alle Modi.

D. Report: Vorgriffe sind nie Übungsbedarf
11. Ein direkt geprüfter Bereich ist ein Vorgriff, wenn
    - sein Heimatthema in „Kommt noch“ liegt (kommtNoch aus lernweg.ts, Klasse oder Klasse + 1),
    - er nicht im Themenraum liegt
    - und er kein Randknoten der Vorschau ist.
    Die Ableitung steht als reine Funktion in src/lib/report/elternbericht/vorgriff.ts, ohne DB-Änderung.
12. Vorgriff sicher: Er zählt als sicher, steht im Lernweg in „Kommt noch“ mit grünem Punkt und darf auf Seite 1 bei „Schon gelungen“ stehen.
13. Vorgriff nicht sicher: Er zählt NICHT als Übungsbedarf, nicht in den Zahlen (Seite 1, 2, Präsentation), nicht in den Schwerpunkten (Seite 4, Station 04) und nicht in der Kette. Im Lernweg steht er in „Kommt noch“ als „noch nicht behandelt“ (leerer Kreis).
14. Druckbogen und Präsentation benutzen dieselbe Ableitung. Neue Texte nur über i18n, Tabelle für Lena in docs/lsa/lsa-v2-texte.md.

SIMULATION (Pflicht, vorher/nachher)
15. tools/lsa-testkinder (alle Kinder) einmal mit altem und einmal mit neuem Stand im CI-Neuaufbau laufen lassen. Je Kind melden:
    - Aufgaben gesamt
    - Dauer und Ende (Zeit, leere Auswahl oder Deckel)
    - Ausblick-Knoten und davon sicher
    - tiefste erreichte Klassenstufe
    - Zahl der Zweitbelege
    Erwartet: Max und Lina deutlich länger und mit Ausblick; Jonas erreicht Klasse 5/6; Emre, Sophie und Nele ändern sich wenig; kein Kind über 40.
16. Gibt es Testkind „Tim“ (Durchklicker aus LSA-R2) schon auf dev, gehört es dazu, und der Deckel muss bei ihm greifen.
17. Profile erweitern: Max und Lina können Klasse + 1 „sicher“ bis zum ersten Thema danach, dann „uebung“, damit der Stopp aus 4 sichtbar wird. Hat LSA-R2 die Kinderdaten schon nach tools/lsa-testkinder/kinder.sql ausgelagert, erweitere dort. Sonst lagere selbst aus (JSON aus lsat.kinder nach kinder.sql, Einbindung mit \ir), weil erzeugen.sql bei 400 Zeilen steht.

UMFANG:
- EINE Migration supabase/migrations/<V>_lsa_v2_ausblick.sql (lsa_select_next_core, lsa_urteil_buchen_core, neu lsa_ist_ausblick), Rollback unter supabase/rollback/ wie bei LSA-V, schema-erwartet.sql (Abzug)
- supabase/tests/lsa_v2_ausblick.test.sql, lsa_testkinder.test.sql
- tools/lsa-testkinder/**
- src/lib/report/elternbericht/vorgriff.ts (neu) und die Stellen, die zählen, auswählen und zeichnen; src/lib/report/praesentation/** nur, wo Zahlen oder Kette Vorgriffe ausschließen
- Tests, Retro, docs/lsa/lsa-v2-simulation.md
- NICHT: lsa_finish, platz_submit, lsa_durchklick_stand (LSA-R2 arbeitet parallel daran; zwei Migrationen dürfen nie dieselbe Funktion ersetzen), ReportPage, Admin-Listen

LEITPLANKEN:
- Worktree ../Edvancev1-lsav2 auf feat/rasit-lsa-v2-ausblick von origin/dev, PR gegen dev, nie main.
- Migration nur schreiben, NICHT einspielen. Im PR steht der Einspielbefehl mit der sicheren Kette, nicht dbcheck:
  cd ~/Edvancev1-lsav2 && V=<V> N=lsa_v2_ausblick && [[ "$DATABASE_URL" == *pooler.supabase.com* ]] && psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && [ -z "$(psql "$DATABASE_URL" -tAc "select 1 from supabase_migrations.schema_migrations where version='$V'")" ] && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f supabase/migrations/${V}_${N}.sql && psql "$DATABASE_URL" -c "insert into supabase_migrations.schema_migrations (version,name) values ('$V','$N')" && tools/schema-snapshot.sh
- Zweitprüfung durch eine unabhängige Instanz (Kernlogik), Ergebnis im PR.
- lsa_select_next_core bleibt unter 20 ms je Aufruf; Messung wie in LSA-D, vorher und nachher.
- Prod nur lesend über dbread. Keine echten Namen, IDs oder Zeitstempel ins Repo.
- Dateien ≤ 400 Zeilen. npm run typecheck && npm run lint && npm run test grün, pgTAP im Neuaufbau grün.
- STOPP nach dem PR.

MELDEN:
- PR-Link und Einspielbefehl
- Simulationstabelle vorher/nachher
- Laufzeit vorher/nachher
- Ergebnis der Zweitprüfung
- Per dbread: Wie viele Aufgaben im ready- und im Testkonto-Pool haben die Ausblick-Kandidaten je Klasse?
- Offene Punkte
```
