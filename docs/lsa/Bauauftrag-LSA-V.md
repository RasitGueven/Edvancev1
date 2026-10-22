# Bauauftrag LSA-V · Auswahl mit Grund: Thema, Grundlage, nächstes Schulthema

Stand 22.10.2026. Anlass: Rasit nach Durchsicht des Testlaufs von Testkonto B (Sitzung 6220b7e8, Klasse 9, Thema
Reelle Zahlen). Von 12 direkt geprüften Bereichen lagen 7 außerhalb des Themas (Flächeninhalte, Satz des
Thales, Gleichungssysteme, Zufall). Im Lernweg gibt es deshalb kaum Linien, und der Report wirkt beliebig.

## Befund (Code auf dev, 21.10.2026)

`lsa_select_next_core` (zuletzt in 20261021083026_lsa_diagnose_ab.sql) wählt mit Thema so:

1. Schritt 2: offener Zweitbeleg, immer zuerst.
2. Phase T: Einstiegsknoten des Themas.
3. Phase Tiefe: Abstieg unter gebrochenen Knoten im Themenraum, bis `c_tiefe_bis` = 12 Minuten.
4. Breite a: Einstiegsknoten der Themen, die im Erstgespräch als „behandelt“ markiert sind, zuletzt
   behandelt zuerst.
5. Breite b: das Blatt, das die meisten offenen Voraussetzungen abdeckt (gierige Deckung), ohne Bezug
   zum Thema.
6. Schritt 5: irgendeine freie Aufgabe bis zur Klasse.

4 bis 6 fragen nicht, ob ein Bereich mit dem Thema oder dem kommenden Stoff zusammenhängt. Dazu
endet die Tiefe sofort, wenn nichts bricht; dann bekommt die Breite fast die ganze Zeit.

## Ziel der Gründer

Jede Aufgabe der LSA hat einen Grund, den Eltern verstehen:
1. **Gehört zum Thema** (Themenraum),
2. **ist Grundlage für das Thema** (Tiefe),
3. **wird für das gebraucht, was als Nächstes kommt** (Voraussetzungen der nächsten Themen im Schulplan,
   ohne Schulplan im Kernlehrplan NRW).

Bereiche ohne einen dieser Gründe kommen mit Thema nur noch, wenn sonst nichts übrig ist.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-V: Die Aufgabenauswahl der LSA mit Thema bekommt eine neue Phase „Vorschau“ (Voraussetzungen der nächsten Schulthemen) und eine Phase „Thema vertiefen“. Breite b und die Restzeit-Füllung entfallen mit Thema. Ohne Thema bleibt alles, wie es ist. Ein Paket, ein PR.

Lies zuerst diesen Bauauftrag ganz (lege ihn als docs/lsa/Bauauftrag-LSA-V.md im PR ab), dann die aktuelle Fassung von lsa_select_next_core (supabase/migrations/20261021083026_lsa_diagnose_ab.sql), lsa_abschluss, lsa_finish_themenraum, supabase/tests/inv10_lsa_thema_auswahl.test.sql und docs/report/r7/Bauauftrag-R7-9.md (Abschnitt A, Schulweg und Plan; Entscheidung 9, aktuelle Position im Plan).

## Entscheidungen der Gründer (22.10.2026, nicht neu verhandeln)

### A. Reihenfolge mit Thema (v_mit_thema = true)
1. Schritt 2 (Zweitbeleg), Phase T und Phase Tiefe bleiben unverändert, auch c_tiefe_bis = 12 Minuten.
2. Danach, in dieser Reihenfolge:
   a. **Vorschau** (neu, Abschnitt B), bis c_vorschau_bis = 16 Minuten nach v_beginn.
   b. **Thema vertiefen** (neu, Abschnitt C), ohne eigene Zeitgrenze.
   c. **Rückblick** = die bisherige Breite a, unverändert.
   d. Nichts mehr: Die Funktion gibt null zurück und die LSA endet. Breite b und Schritt 5 laufen mit Thema NICHT mehr. Eine LSA darf vor Minute 19 enden.
3. Greift eine Phase nicht (keine Kandidaten, keine freie Aufgabe), geht es mit der nächsten weiter, wie heute.
4. Neue Konstanten oben in der Funktion mit Kommentar: c_vorschau_bis = interval '16 minutes', c_vorschau_themen = 2.

### B. Vorschau
5. Schule der Sitzung, in dieser Reihenfolge wie in R7-9: students.schule_id, leads.schule_id über students.lead_id, schulen.name gleich students.school_name (ohne Groß/Klein, genau ein Treffer). Gibt es dafür schon eine SQL-Funktion, nutze sie; sonst eine kleine STABLE-Funktion lsa_schule_von_sitzung(p_session_id) in derselben Migration. Der bisherige Weg nur über leads.schule_id in Breite a wird auf diese Funktion umgestellt.
6. Kommende Themen U (höchstens c_vorschau_themen, nur Einträge mit thema_key):
   - Mit Schulplan: schul_themenplan dieser Schule, Klasse = lsa_sessions.grade, Fach wie v_fach, die Einträge NACH der aktuellen Position, nach position.
   - Aktuelle Position: der Eintrag mit thema_key = Thema der Sitzung. Fehlt er: nach Datum der Sitzung (Europe/Berlin; August bis Januar erstes Halbjahr, Februar bis Juli zweites) der erste Eintrag dieses Halbjahrs; ohne Halbjahr im Plan der Anfang. Dieselbe Regel wie lernweg.ts (R7-9), sonst passen Report und LSA nicht zusammen.
   - Ohne Schule oder ohne Plan für diese Klasse: themen mit diesem Fach und dieser Klasse nach sort, die nach dem Thema der Sitzung kommen (sort größer); liegt das Thema in einer anderen Klasse, die ersten nach sort.
7. Kandidaten je u in U sind der **Rand** des Themas: alle Voraussetzungen (skill_kante) von Skills des Themas u (skill_thema), die selbst nicht zu u gehören.
   - Gehört eine solche Voraussetzung zu einem Thema, das laut Plan ebenfalls noch kommt (auch in der nächsten Klasse) oder ohne Plan nach Kernlehrplan später liegt, wird sie nicht gezogen; an ihre Stelle tritt ihr eigener Rand (rekursiv). Beispiel Testkonto B: „Lösungsformel“ (Quadratische Gleichungen, Klasse 10 am FWG) ist Voraussetzung von „Nullstellen quadratischer Funktionen“; gezogen werden stattdessen deren Voraussetzungen wie „Werte in Terme einsetzen“.
   - NICHT: Skills mit klasse_herkunft > grade, Skills mit Urteil in dieser Sitzung, Skills ohne freie Aufgabe im Pool.
   - Randknoten sind immer Kandidaten. Tiefere Knoten aus ihrem Abschluss nur, wenn ein Knoten direkt darüber in dieser Sitzung als traegt_nicht oder nicht_angesetzt beurteilt ist (Abstieg in der Vorschau, eine Stufe je Bruch).
   - Ein Randknoten, der zu mehreren kommenden Themen gehört (Testkonto B: „Werte in Terme einsetzen“ für Quadratische Funktionen und für Kreise), kommt zuerst.
8. Reihenfolge: Randknoten mehrerer kommender Themen zuerst, dann u nach Plan-Position (das nächste Thema zuerst), dann Rand vor tieferen Kandidaten, dann neu desc (wie Phase T: 1 + offene Knoten im Abschluss), dann fundament_tiefe desc, dann skill_key. Aufgabe wie überall: sondierrang nulls last, dann md5(session || task).
9. Ein Kandidat, für den es keine freie Aufgabe gibt, bekommt wie heute ein Urteil 'ungeprueft' und wird übersprungen.

### C. Thema vertiefen
10. Kandidaten: Skills im Themenraum (v_themenraum) ohne Urteil in dieser Sitzung und mit freier Aufgabe. Keine Klassengrenze (wie Phase T).
11. Reihenfolge: neu desc, fundament_tiefe desc, skill_key. So werden Bereiche des Themas direkt geprüft, die sonst nur abgeleitet wären (Testkonto B: 9 von 14 abgeleitet).

### D. Ohne Thema
12. Unverändert: Abstieg unter jedem gebrochenen Knoten mit Klassengrenze, Breite b, Schritt 5. Ein Test hält das fest.

### E. Was nicht passiert
13. Keine neue Tabelle, keine neue Spalte. Den Grund einer Aufgabe (Thema, Grundlage, nächstes Thema) leitet später der Report aus Themenraum, Plan und Kanten ab (eigener Auftrag R7-12, nicht hier).
14. lsa_finish_themenraum, Wertung, Zweitbeleg-Regel, Pool-Regel und die 19-Minuten-Grenze bleiben unverändert.

## Simulation vorher/nachher (Pflicht, der Kern der Abnahme)
15. Neuer pgTAP- bzw. SQL-Test supabase/tests/lsa_v_simulation.test.sql mit Fixture nach dem Muster von lsa_l1_fixture.sql:
   - Ein Testkind Klasse 9, Thema reelle_zahlen, Schule mit dem FWG-Plan Klasse 9 (Positionen und thema_keys aus Prod über dbread, nur lesend, keine Personendaten).
   - Antwortprofil wie Testkonto B: je Skill der Zustand aus lsa_skill_urteil der Sitzung 6220b7e8 (nur Schlüssel und Zustand). Skills, die Testkonto B nicht hatte: Annahme „sicher“, im Test als Annahme benannt.
   - Die Sitzung wird durchgespielt: Aufgabe holen, Antwort nach Profil buchen (über dieselbe Funktion wie die App), Uhr über p_jetzt je Aufgabe um 75 Sekunden weiter, bis null kommt.
   - Ausgabe: Liste Minute · Phase · Skill · Thema des Skills.
16. Lauf vorher (Funktion aus dev) und nachher (neue Funktion), beide Listen als Tabelle in docs/lsa/lsa-v-simulation.md und im PR. Dazu je Lauf: Anteil der Aufgaben im Themenraum, in der Vorschau, im Rückblick, sonst.
   - Jeden Lauf zweimal: mit dem Pool eines echten Kindes (nur status 'ready', so wie Lena und die Admins freigegeben haben) und mit dem Testpool (lsa_testinhalte = true). Der Unterschied zeigt, was an Freigaben fehlt.
   - Zusätzlich eine Liste aus Prod (dbread, nur lesend): je Kandidat der Vorschau bei Testkonto B die Zahl der Aufgaben auf 'ready', davon ohne Multiple Choice, und die Zahl im Entwurf. Ein Knoten braucht mindestens 2 freigegebene Aufgaben, eine davon ohne Multiple Choice (Regel aus der Freigabeliste für Lena). Diese Liste ist die neue Freigabeliste für Lena.
17. Erwartung nachher (prüft der Test):
   - Keine Aufgabe aus Breite b oder Schritt 5.
   - Jede Aufgabe außerhalb des Themenraums ist Voraussetzung eines der zwei nächsten Plan-Themen (Quadratische Funktionen; Kreise, Prismen und Zylinder) oder kommt aus dem Rückblick nach Minute 16.
   - Flächeninhalte nur, wenn sie über „Kreise, Prismen und Zylinder“ begründet sind.
   - Der Themenraum hat mehr direkt geprüfte Bereiche als vorher (Testkonto B vorher: 5 von 14).

## Weitere Tests
- inv10_lsa_thema_auswahl: bestehende Fälle grün; wo ein Fall Breite b mit Thema erwartet, auf die neue Erwartung umstellen und im PR einzeln nennen.
- Neu: Vorschau mit Plan (nächstes Thema zuerst), Position nach Halbjahr, ohne Plan nach Kernlehrplan, Skills des kommenden Themas selbst werden nie gezogen, Klassengrenze, Abstieg in der Vorschau nur unter Brüchen, Zeitgrenze 16 Minuten, Thema vertiefen, Rückblick erst danach, Ende mit null statt Füllaufgabe.
- Ohne Thema: Auswahl Aufgabe für Aufgabe identisch mit vorher (gleiche Fixture, gleiche Antworten).
- session_x0 und die übrigen LSA-Tests grün; CI schema/neuaufbau: Ist NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler. Im PR vermerken, nichts ändern.

## Umfang
- supabase/migrations/<Version>_lsa_v_vorschau.sql: CREATE OR REPLACE FUNCTION lsa_select_next_core (ganze Funktion, ausgehend von 20261021083026), ggf. lsa_schule_von_sitzung. Version = date -u +%Y%m%d%H%M%S beim Anlegen, nie ausgedacht.
- supabase/rollback/<Version>_lsa_v_vorschau.sql: stellt die Fassung aus 20261021083026 wieder her.
- supabase/tests/lsa_v_simulation.test.sql, Fixture dazu, inv10 nur wie oben.
- docs/lsa/Bauauftrag-LSA-V.md, docs/lsa/lsa-v-simulation.md, docs/lsa/offene-punkte-lsa-v.md, Retro.
- Nicht anfassen: src/**, Report und Präsentation, lsa_finish_themenraum, Wertung, schema-erwartet.sql (das macht Rasit mit tools/schema-snapshot.sh nach dem Einspielen).

## Leitplanken
- Worktree ../Edvancev1-lsav auf feat/rasit-lsa-vorschau von origin/dev. PR gegen dev, nie main.
- Du schreibst die Migration (ALLOW_MIGRATIONS=1), führst aber KEIN DDL gegen Prod aus. Prod nur lesend über dbread. Tests laufen lokal bzw. in CI gegen den Neuaufbau.
- Migrationen nach supabase/migrations/, nicht pending/.
- Im PR steht der Einspielbefehl für Rasit, &&-verkettet nach CLAUDE.md §10:
  V=... N=lsa_v_vorschau && dbcheck && [ -z "$(psql "$DATABASE_URL" -tAc "select 1 from supabase_migrations.schema_migrations where version='$V'")" ] && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f supabase/migrations/${V}_${N}.sql && psql "$DATABASE_URL" -c "insert into supabase_migrations.schema_migrations(version,name) values ('$V','$N')" && tools/schema-snapshot.sh
- Vor der Migration: alle Funktionen prüfen, die lsa_select_next_core aufrufen oder dieselben Spalten lesen (pg_proc über dbread), und im PR auflisten.
- Zweitprüfung durch eine frische Instanz. Schwerpunkt: Kann jede Aufgabe der Simulation nachher einem der drei Gründe zugeordnet werden? Stimmt die Position im Plan mit lernweg.ts überein? Bleibt die Auswahl ohne Thema exakt gleich?
- STOPP nach dem PR.

## Melden
- PR-Link und Einspielbefehl
- Simulation vorher/nachher als Tabelle, mit den Anteilen je Phase
- Welche Plan-Themen die Vorschau bei Testkonto B nimmt und welche Skills daraus gezogen wurden
- Liste der geänderten Erwartungen in inv10
- offene Punkte (docs/lsa/offene-punkte-lsa-v.md)
```

## Abnahme (Gründer)
1. Simulation Testkonto B nachher: Jede Aufgabe lässt sich einem Grund zuordnen (Thema, Grundlage, nächstes Thema).
2. Danach den Testlauf von Testkonto B auf einem Testkonto echt wiederholen und den Report ansehen: Der Lernweg hat Linien
   von sicheren Grundlagen zu „Kommt noch“.
3. Konstanten bestätigen: Tiefe bis 12, Vorschau bis 16 Minuten, zwei kommende Themen.

## Offen für die Gründer
- Zeitaufteilung: Reichen 4 Minuten für die Vorschau, oder soll sie bis 17 laufen?
- Endet eine LSA öfter deutlich vor Minute 19, weil nichts mehr passt: c_vorschau_themen auf 3 erhöhen?
- Aufgabenbestand: Die Vorschau braucht freigegebene Aufgaben für die Voraussetzungen der kommenden Themen.
  Die Simulation zeigt, wo welche fehlen; das wird eine Liste für Rasit und Lena.
- Der Report soll später je Bereich zeigen, warum er geprüft wurde (R7-12).
