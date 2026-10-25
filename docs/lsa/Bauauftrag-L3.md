Du arbeitest im Repo Edvancev1 (WSL). Paket L3: Die LSA-Auswahl richtet sich nach dem Stand der Klassenarbeit zum aktuellen Thema. Erst simulieren, dann umsetzen, nur wenn die Zahlen passen. Lege diesen Auftrag wörtlich als docs/lsa/Bauauftrag-L3.md in den PR.

FREIGABE RASIT (25.10.2026, gilt nur für diesen Auftrag): Migration selbst einspielen (Muster CLAUDE.md §10, eine &&-Kette, Nachweis per dbread danach) und selbst über PR nach dev mergen (nie Push auf dev oder main, nie Force-Push, nie Rebase).

LEITSATZ RASIT (gilt für alles hier): Kinder bekommen in der LSA nur Stoff, den sie schon hatten. Seit PR #324 gibt es keinen Ausblick mehr (lsa_ausblick_knoten liefert {}). L3 baut darauf auf und führt nichts davon wieder ein.

## Anlass
Heute ignoriert lsa_select_next_core den Klassenarbeits-Status: Jedes Kind bekommt bis Minute 12 das aktuelle Thema mit Tiefe, Minute 12–16 die Vorschau auf die nächsten drei Klassenarbeiten, danach den Rest. Ist die Arbeit zum aktuellen Thema schon geschrieben, gehen so rund 12 von 19 Minuten in ein Thema, das in der Schule vorbei ist, und für die Voraussetzungen der kommenden Arbeiten bleiben etwa 4 Minuten. Der Bericht v4 erzählt aber genau diese kommenden Arbeiten.

## Schritt 0 · Voraussetzung #324, Lesen und Stand
- Zuerst: Ist PR #324 („kein Ausblick mehr“) in origin/dev gemergt und Migration 20261025220449_lsa_ohne_ausblick in Prod eingespielt (dbread auf supabase_migrations.schema_migrations)? Falls nicht: gh pr checks 324 (nur session_a2 rot = bekannt), dann gh pr merge 324 --merge, danach die Migration nach CLAUDE.md §10 einspielen und per dbread nachweisen (Freigabe Rasit). PR #323 ist in #324 enthalten: gh pr close 323 --comment "in #324 enthalten". Erst danach den Worktree anlegen.
- supabase/migrations/20261025220449_lsa_ohne_ausblick.sql und docs/retros/2026-10-25-lsa-ohne-ausblick.md (Schalter lsa.ausblick nur für Tests)
- supabase/migrations/20261025144025_lsa_l2_wiederholung.sql (aktuelle lsa_select_next_core, lsa_freie_aufgabe, lsa_text_schluessel, c_vorschau_themen = 3), 20261022131358_lsa_v2_ausblick.sql (lsa_ist_ausblick, lsa_ausblick_knoten), 20261022065539_lsa_v_vorschau.sql
- docs/lsa/Bauauftrag-LSA-V.md, -V2.md, -L2.md, docs/lsa/l2-simulation.md, tools/lsa-testkinder/ (inkl. Testkind Batu aus L2)
- lsa_start und wie eine Sitzung Schüler → Lead findet (lsa_lead_kontext)
- Per dbread: Gibt es leads.klassenarbeit_status (erwartet ja, Migration 20261024135226) und leads.letzte_klassenarbeit_note (evtl. von der V4-Session als 20261025142134 eingespielt)? Fehlt die Note-Spalte: NICHT selbst anlegen (gehört zu V4-E), sondern sie in der Funktion defensiv behandeln (als null), siehe Entscheidung 2.
- git fetch && git log origin/dev: Ist ein V4-PR (Bericht v4) schon gemergt? Notieren; L3 fasst Report-Code nicht an.

## Entscheidungen (nicht neu verhandeln)
1. Modus der Sitzung, einmal beim Start festgestellt und in der Sitzung gespeichert (lsa_sessions.result_summary.ka_modus oder eine eigene Spalte, was zum bestehenden Muster passt; bei Spalte: Migration):
   - 'thema_zuerst': klassenarbeit_status = 'bevorstehend' oder null (unbekannt) → Verhalten wie heute.
   - 'vorschau_zuerst': klassenarbeit_status = 'geschrieben'.
   - Der Modus ändert sich während der Sitzung nicht, auch wenn jemand das Erstgespräch nachträglich bearbeitet.
   - Ohne Thema (v_mit_thema = false) gilt immer das heutige Verhalten.
2. Note: Keine eigene Auswahl-Logik für „geschrieben ohne Note“ vs. „geschrieben mit Note“. Einzige Ausnahme: Note 1 oder 2 → Phase „Thema kurz“ endet schon nach c_thema_kurz_gut (Startwert 2 Minuten) statt c_thema_kurz (Startwert 4 Minuten). Note null oder 3–6 → c_thema_kurz. Fehlt die Spalte: wie null.
3. Ablauf 'vorschau_zuerst' (Startwerte, alle als Konstanten oben in der Funktion):
   a. Zweitbeleg wie heute, immer zuerst.
   b. Thema kurz bis c_thema_kurz: nur Einstiegsknoten des Themas (Phase T), keine Tiefe, kein Thema vertiefen.
   c. Vorschau bis c_vorschau_bis_vz (Startwert 13 Minuten): Voraussetzungen der nächsten c_vorschau_themen = 3 Klassenarbeiten, mit dem Abstieg unter Brüchen wie heute (eine Stufe je Bruch, Klassengrenze wie heute).
   d. Tiefe unter gebrochenen Themenknoten bis c_tiefe_bis_vz (Startwert 16 Minuten), bevorzugt Knoten, die zugleich Voraussetzung einer kommenden Arbeit sind.
   e. Rückblick. Kein Ausblick (seit #324), auch nicht für starke Kinder.
   f. Ende wie heute: 19 Minuten oder 40 Aufgaben.
4. Kommende Arbeiten über das Schuljahresende hinaus: Hat der Plan der Klasse nach der aktuellen Position weniger als c_vorschau_themen Themen, füllt die Vorschau mit den ersten Themen aus dem Plan der Klasse + 1 auf (Quelle: Schulplan der Klasse + 1, ohne Schulplan Kernlehrplan-Folge). Das gilt in BEIDEN Modi und entspricht dem Fahrplan des Berichts v4 (Entscheidung 1 dort). Die Klasse-8-Themen sind dabei nur Ziel: Geprüft werden ausschließlich ihre Voraussetzungen, und die Klassengrenze der Vorschau-Knoten bleibt die eigene Klasse (grade, NICHT grade + 1). Skills, die selbst zu einem Thema der Klasse + 1 gehören, sind ausgeschlossen (wie heute v_kommend/v_spaeter).
5. 'thema_zuerst' bleibt bis auf Entscheidung 4 unverändert.
6. Keine Änderung an lsa_urteil_buchen_core, lsa_finish, lsa_durchklick_stand, lsa_ausblick_knoten, lsa_ist_ausblick, Report- oder Präsentationscode.
7. Nichts Neues: In keinem Modus und keiner Phase eine Aufgabe über der eigenen Klasse oder zu einem Thema, das laut Plan noch kommt. Wird die Sitzung dadurch vor Minute 19 leer, endet sie früher (Ende „leer“). Nicht mit neuem Stoff auffüllen, sondern in der Simulation ausweisen.

## Schritt 1 · Simulation vorher (CI-Neuaufbau, nie gegen Prod)
1. Testkind Batu aus L2 in drei Varianten: bevorstehend · geschrieben ohne Note · geschrieben mit Note 4. Dazu eine Variante „Batu stark“ (gleiches Profil, aber Terme & Gleichungen sicher) mit Note 2. Alle Läufe ohne den Schalter lsa.ausblick.
2. Ein zusätzliches Testkind „Klasse 7, 2. Halbjahr“ mit Schulplan, nach dessen aktuellem Thema nur noch ein Thema im Schuljahr kommt (für Entscheidung 4), Status geschrieben.
3. Ausgabe je Lauf wie in L2 (Nr · Minute · Phase · Skill · Feld · Klasse · Gruppe Thema / Voraussetzung KA2 / KA3 / KA4 / Grundlage / Ausblick / Rückblick · Ergebnis) und je Lauf die Kennzahlen: Minuten bzw. Aufgaben je Gruppe; Anteil der Voraussetzungen von KA2, KA3, KA4, die direkt geprüft wurden; Anteil Themenraum direkt geprüft; Ende (Zeit, Deckel, leer); Wiederholungsbefunde aus L2.

## Schritt 2 · Umsetzen
EINE Migration supabase/migrations/<V>_lsa_l3_ka_modus.sql mit Rollback: Modus beim Start (lsa_start oder an der Stelle, an der heute v_kommend/Themenraum festgelegt wird), lsa_select_next_core nach Entscheidung 1–5. lsa_select_next_core bleibt unter 20 ms je Aufruf (Messung vorher/nachher wie in LSA-D).

## Schritt 3 · Simulation nachher und Abnahmekriterien
Alle Testkinder aus L2 plus die Varianten aus Schritt 1, vorher/nachher, Tabellen in docs/lsa/l3-simulation.md. Abnahmekriterien (alle müssen gelten, sonst Konstanten anpassen und erneut simulieren, höchstens drei Runden; danach mit Befund melden):
- 'thema_zuerst'-Kinder: Kennzahlen gleich wie vorher (bis auf Entscheidung 4 bei Kindern am Schuljahresende).
- Batu „geschrieben“: Voraussetzungen von KA2, KA3 und KA4 zusammen mindestens 80 % direkt geprüft (vorher-Wert nennen); Thema mit mindestens 3 direkt geprüften Bereichen, damit die Einschätzung zum Thema trägt.
- Batu „stark“, Note 2: Thema kürzer als bei Note 4, dafür mindestens so viele direkt geprüfte Voraussetzungen der kommenden Arbeiten wie bei Note 4.
- Klasse-7-Kind: Die Vorschau enthält Voraussetzungen der ersten Klasse-8-Themen, keine Aufgabe über Klasse 7, keinen Skill, der selbst zu einem Klasse-8-Thema gehört.
- In keinem Lauf eine Aufgabe mit Klasse über der des Kindes oder mit Phase Ausblick (eigene Spalte in der Kennzahlentabelle, muss überall 0 sein).
- Kein Kind über 40 Aufgaben oder 19 Minuten, keine Wiederholung nach L2-Regeln. Endet ein Lauf „leer“ vor Minute 15, mit Befund melden (nicht mit neuem Stoff füllen).

## Schritt 4 · Prüfen, einspielen, mergen
1. pgTAP supabase/tests/lsa_l3_ka_modus.test.sql: Modus je Status, Modus bleibt in der Sitzung fest, Note 1–2 verkürzt, fehlende Note-Spalte bzw. null wie Note offen, Auffüllen aus Klasse + 1 ohne Knoten über der eigenen Klasse, kein Ausblick ohne Schalter, 'thema_zuerst' unverändert. Alle bestehenden LSA-Tests grün.
2. Zweitprüfung durch einen frischen Subagenten (Kernlogik): prüft Migration gegen Entscheidungen 1–7 und den Leitsatz und die Simulation gegen die Abnahmekriterien.
3. Vor dem Einspielen pg_proc auf alle geänderten Funktionen prüfen. Einspielen nach CLAUDE.md §10, per dbread nachweisen, Schema-Snapshot committen.
4. PR gegen dev, gh pr checks --watch (nur session_a2 rot = bekannt, vermerken), gh pr merge --merge. Retro.

## Für später (nicht in L3, nur in docs/lsa/l3-offen.md festhalten)
Texte im Bericht nach Klassenarbeits-Stand (gehören in einen Nachtrag zu Bericht v4, sobald V4 gemergt ist):
- steht an: „Die Arbeit zu {Thema} steht noch an. Darauf bereiten wir zuerst vor.“
- geschrieben, Note offen: „Die Analyse zeigt für {Thema}: sicher war {X}, noch unsicher {Y}. Sobald Sie die Note kennen, gleichen wir das gemeinsam ab.“ (Keine erwartete Note nennen.)
- geschrieben, Note bekannt: „Die Arbeit zu {Thema} ist mit Note {n} zurückgekommen. Dazu passt, was die Analyse zeigt: {Y} war noch unsicher. {Y} wird bei Klassenarbeit {k} wieder gebraucht.“ („dazu passt“, keine Ursachenbehauptung.)
- Erstgespräch: Die Frage nach Status und Note muss vor dem LSA-Start beantwortet sein; Hinweis im Startdialog, wenn sie fehlt (dann läuft 'thema_zuerst').
- Abgleich, wenn die Note nachträglich kommt: Eintrag im Erstgespräch, Anzeige im Monatsbericht.

## Leitplanken
- Worktree ../Edvancev1-l3 auf feat/rasit-lsa-l3-ka-modus von origin/dev, erst nachdem #324 dort gemergt ist.
- Simulationen nur im CI-Neuaufbau bzw. in der Wegwerf-DB. Prod nur lesend, außer dem Einspielen der einen Migration.
- Keine echten Namen, IDs oder Zeitstempel ins Repo. Dateien ≤ 400 Zeilen.
- Läuft parallel zur V4-Session: keine Dateien unter src/components/edvance/elternbericht/**, praesentation/**, src/lib/report/** anfassen.

## Melden
PR-Link; Simulationstabelle vorher/nachher mit den Kennzahlen je Kind; welche Konstanten am Ende gelten und warum; Laufzeit; Ergebnis der Zweitprüfung; eingespielte Migration mit Version; offene Punkte.
