Du arbeitest im Repo Edvancev1 (WSL). Paket L5: Klassenarbeiten statt Themen-Nummern. Der Bericht v4 und die Präsentation nummerieren heute jedes Plan-Thema als „Klassenarbeit n“ (Batu, Klasse 9, FWG: „Klassenarbeit 1–5“ plus „+1 weiteres Thema“, also sechs). In NRW schreibt Klasse 9 am Gymnasium in Mathe aber 4–5 Arbeiten (VV zu § 6 APO-S I: Kl. 5–7: 6, Kl. 8: 5, Kl. 9: 4–5, Kl. 10: 3–5; eine pro Jahr ersetzbar). Welche Themen in welche Arbeit kommen, steht in keinem öffentlichen Dokument der Schulen (FWG-Curriculum Jgst. 9: sechs Vorhaben, Spalte „Schulinterne Absprachen“ leer). L5 zeigt deshalb nur, was wir wissen, und lernt die echten Arbeiten aus Erstgespräch und Session-Check-ins. Arbeite alles von Schritt 0 bis zum Melden in einem Rutsch ab. Lege diesen Auftrag wörtlich als docs/report/Bauauftrag-L5.md in den PR.

FREIGABE RASIT (26.10.2026, gilt nur für diesen Auftrag): Migrationen selbst einspielen (Muster CLAUDE.md §10, eine &&-Kette, Nachweis per dbread danach) und selbst über PRs nach dev mergen, auch mehrmals (nie Push auf dev oder main, nie Force-Push, nie Rebase, nichts in .github/).

## Schritt 0 · Lesen und Stand
- git fetch; Worktree ../Edvancev1-l5 auf feat/rasit-ka-folge von origin/dev (L4 ist gemergt: #326, #327).
- Lesen: src/lib/report/elternbericht/fahrplan.ts (baueFahrplan, KOMMENDE_MAX, Stationen = Plan-Themen), plan.ts, lernweg.ts (kommtNoch), lueckenweg.ts (signaleJeThema), kaSatz.ts und src/lib/report/kaStand.ts (L4 Teil D), Seite1–5 V4, Seite3V4.tsx, praesentation/StationKlassenarbeiten.tsx, v4Daten.ts; i18n elternbericht.json / praesentation.json (alle Stellen mit „Klassenarbeit {{n}}“, „{{k}}“, „voraussetzung“, „voraussetzungZwei“, „blockTitel“, „aria“, „karte“, „wieder_*“, „geschrieben“); src/pages/admin/intake/KlassenarbeitFelder.tsx und KlassenarbeitHinweis.tsx; supabase/migrations/20261007110400_session_checkin.sql (session_checkin.klassenarbeit_datum, klassenarbeit_thema_key) und 20261007110700_session_live.sql; schul_themenplan (20261001114732); docs/report/v4/offene-punkte.md, docs/lsa/l4-offen.md.
- Per dbread: Wie viele session_checkin-Zeilen haben klassenarbeit_datum/klassenarbeit_thema_key? Welche Leads haben schule_id und Klasse? Nur zählen, nichts ins Repo.

## Entscheidungen (nicht neu verhandeln)

### Teil A · Daten
1. Neue Tabelle lead_klassenarbeiten (eine Zeile je Mathe-Klassenarbeit eines Kindes in einem Schuljahr): lead_id, fach (default 'mathematik'), schuljahr (text '2026/27'), nr (int ≥ 1, Nummer im Schuljahr, nullable wenn unbekannt), datum (date, nullable), thema_keys (text[], Themen aus schul_themenplan bzw. themen, mindestens eins), status ('bevorstehend' | 'geschrieben'), note (1–6, nullable, nur bei geschrieben), quelle ('erstgespraech' | 'checkin' | 'admin'), erfasst_am. RLS wie leads (Admin schreibt, Coach liest die eigenen Schüler wie heute bei lead_themen). Rechte und Grants nach bestehendem Muster.
2. Neue Spalte leads.ka_anzahl_schuljahr (int 1–8, nullable = unbekannt) für „Wie viele Mathearbeiten schreibt ihr dieses Schuljahr?“.
3. Check-ins speisen ein: Trägt ein Coach im Check-in klassenarbeit_datum und klassenarbeit_thema_key ein, entsteht bzw. aktualisiert sich (gleiches Kind, gleiches Datum) eine Zeile mit quelle 'checkin', status 'bevorstehend'. Umsetzung in der bestehenden Check-in-RPC oder per Trigger, was zum Muster passt. Ist das Datum vorbei, gilt die Arbeit als geschrieben (berechnet, nicht gespeichert).
4. Schulwert: Eine Funktion ka_folge_schule(schule_id, klasse, schuljahr) leitet aus lead_klassenarbeiten aller Kinder derselben Schule, Klasse und desselben Schuljahrs die Folge der Arbeiten ab (Themen je Arbeit, Datum). Ein Schulwert gilt erst, wenn mindestens zwei Kinder übereinstimmen oder ein Admin ihn bestätigt (Spalte bestaetigt in einer kleinen Tabelle schul_klassenarbeiten oder gleichwertig). Lehrkräfte einer Schule können abweichen: Die Angaben des eigenen Kindes gehen immer vor. Keine Daten eines anderen Kindes werden je im Bericht oder für Eltern sichtbar, nur die abgeleitete Folge.
5. Nichts erfinden: Keine Arbeiten oder Zuordnungen für irgendeine Schule vorbelegen (auch nicht FWG), keine Schätzung aus Stundenzahlen. Unbekannt bleibt unbekannt.

### Teil B · Erstgespräch
6. Im Block „Klassenarbeit“ (KlassenarbeitFelder) zusätzlich, alles optional:
   - „Wie viele Mathearbeiten schreibt ihr dieses Schuljahr?“ Chips 4 · 5 · 6 · weiß nicht (Vorauswahl keine).
   - „Was kommt in der nächsten Arbeit dran?“ Mehrfachauswahl aus den Plan-Themen der Klasse (schul_themenplan), Freitext nicht nötig; dazu das schon vorhandene Datum.
   - Bei „schon geschrieben“: „Was kam in dieser Arbeit dran?“ Mehrfachauswahl wie oben (Vorauswahl: das aktuelle Thema).
   - Gespeichert wird in lead_klassenarbeiten (quelle 'erstgespraech') und leads.ka_anzahl_schuljahr. Bestehende Felder (klassenarbeit_status, letzte_klassenarbeit_note) bleiben und werden weiter geschrieben.
   - Hilfetext: „Die Termine stehen oft im Klassenarbeitsplan oder in WebUntis.“
7. Admin-Ansicht je Schule und Klasse (unter /admin, bestehendes Layout): Liste der abgeleiteten Arbeiten mit Anzahl übereinstimmender Kinder, Button „bestätigen“ bzw. „korrigieren“. Klein halten, keine neue Navigation außer einem Eintrag.

### Teil C · Bericht v4 und Präsentation
8. Folge der Arbeiten, Vorrang: (1) lead_klassenarbeiten des Kindes, (2) gültiger Schulwert, (3) unbekannt.
9. Unbekannt (heute der Normalfall): Die Stationen bleiben die Plan-Themen, aber OHNE Klassenarbeits-Nummern.
   - Station 1 = aktuelles Thema mit dem Stand aus dem Erstgespräch („Geschrieben · Note 4“, „Steht an“, ohne Stand „Aktuell“); Bezeichnung „Klassenarbeit zu {Thema}“ nur, wenn ein Stand bekannt ist.
   - Kommende Stationen: Kopfzeile „Als Nächstes im Unterricht“ (erste), danach „Danach“; Unterzeile „Thema im Schulplan“ statt „Klassenarbeit n“.
   - Alle Texte, die heute eine Nummer nennen, nennen das Thema: „{Y} wird bei „{Thema}“ wieder gebraucht.“, „Voraussetzung für „{Thema}““, „Voraussetzung für „{Thema}“ und „{Thema2}““, Blocktitel „{Thema}“, aria „{Thema}, {Stand}“, Seite 1 „Diese Übersicht beginnt mit dem aktuellen Thema „{Thema}“.“ (bzw. „mit der Arbeit zu „{Thema}““, wenn Stand bekannt).
   - Quellenzeile: „Die Reihenfolge stammt aus dem Schulplan des {Schule}. Welche Themen in welche Klassenarbeit kommen, legt die Lehrkraft fest.“
   - Kopf von Station 03 bzw. Seite 3: „Was das für die nächsten Themen heißt.“ statt „… Arbeiten …“, wo der Text Arbeiten zählt. Der Name der Station „Klassenarbeiten“ bleibt.
   - Seite 1 und Station 01, Überschrift des Fahrplans: „{Vorname}s Klassenarbeiten in diesem Schuljahr“ wird zu „Was in Mathe dieses Schuljahr noch kommt“.
   - Die Kreise des Fahrplans tragen keine Ziffern. Der Kreis des aktuellen Themas zeigt den Stand (Haken bei geschrieben, Ring bei steht an), die kommenden zeigen nur das Signal. Unter jedem Kreis der Themenname, darunter „Als Nächstes im Unterricht“ bzw. „Danach“ statt „nächste Arbeit / voraussichtlich“.
   - „+1 weiteres Thema bis zum Schuljahresende“ bleibt (bei Themen ist das richtig).
   - Satz im Mint-Kasten (Seite 1, Station 01, Station 03): „Für die kommenden Themen fehlen …“ statt „Für die kommenden Arbeiten fehlen …“.
   - Im Fall „Folge bekannt“ (Entscheidung 10) bleiben Überschrift mit „Klassenarbeiten“, Ziffern und „nächste Arbeit“, dann mit den echten Nummern.
10. Bekannt (eigene Angaben oder Schulwert): Stationen = Klassenarbeiten mit echter Nummer im Schuljahr („Klassenarbeit 3“), Datum falls bekannt, darunter ihre Themen (1–3). Signal einer Arbeit = schlechtestes Signal ihrer Themen (fehlt vor erfuellt vor ohne). Höchstens vier kommende Arbeiten; Themen danach wie in 9 ohne Nummer. Bei Schulwert Zusatz in der Quellenzeile: „Zuordnung nach Angaben aus der Klasse, ohne Gewähr.“ Bei eigenen Angaben: „Zuordnung laut Ihren Angaben.“ Ist ka_anzahl_schuljahr bekannt und die Folge unvollständig, keine Arbeiten erfinden: fehlende Zuordnungen bleiben Themen ohne Nummer.
11. Die LSA-Auswahl bleibt unverändert (Vorschau = Voraussetzungen der nächsten drei Plan-Themen). Kein SQL an lsa_select_next_core.
12. Leitplanken wie V4/L4: keine Noten- oder Ergebnisprognose, kein „weil“, kein „trägt/tragen“; Invariantentest auf alle neuen Texte. Keine Zahl „Klassenarbeit n“ irgendwo, wenn die Folge unbekannt ist (Test über alle Fixtures, auch Präsentation). Zusätzlich: Kein Fixture mit unbekannter Folge zeigt auf Seite 1 oder in Station 01 eine Ziffer im Fahrplan oder das Wort „Klassenarbeiten“ in dessen Überschrift.

## Schritt 1 · Umsetzen
- Eine Migration <V>_ka_folge.sql mit Rollback (Teil A), pgTAP supabase/tests/ka_folge.test.sql: RLS, Check-in erzeugt Zeile, Schulwert erst ab zwei übereinstimmenden Kindern oder Bestätigung, eigene Angaben vor Schulwert, nichts vorbelegt.
- Frontend Teil B und C, i18n nur in de-Dateien der bestehenden Namespaces, Tokens --color-eb-*/--color-tp-*, Dateien ≤ 400 Zeilen.
- Fixtures: Batu V4 in drei Varianten (Folge unbekannt · eigene Angaben: 4 Arbeiten, Arbeit 2 = Quadratische Funktionen, Arbeit 3 = Kreise + Potenzen, Arbeit 4 = Pythagoras + Daten · Schulwert mit zwei Kindern). Diese Zuordnung ist nur Testdaten, nicht für Prod.
- Druck-/Überlaufprüfung wie V4 (Seite 1, 3, 4 und Station 01, 03 bei 744×1060 bis 1180×820), Ansichtstests grün.

## Schritt 2 · Prüfen, einspielen, mergen
1. Zweitprüfung durch einen frischen Subagenten: Migration gegen 1–5, Texte und Fälle gegen 8–12, Test „keine Nummer ohne Folge“.
2. Einspielen nach CLAUDE.md §10, per dbread nachweisen, Schema-Snapshot committen.
3. PR gegen dev, gh pr checks --watch (bekannte rote Tests vermerken), gh pr merge --merge. Darf in zwei PRs (Teil A+B, dann C). Retro.

## Leitplanken
- Keine echten Namen, IDs oder Zeitstempel ins Repo. Prod nur lesend außer dem Einspielen.
- Keine Stammdaten erfinden, keine Arbeiten für echte Schulen oder Kinder anlegen.
- Nicht anfassen: lsa_select_next_core, lsa_urteil_buchen_core, Slots, .github/.

## Melden
PR-Link(s); Screenshots Seite 1, Seite 3 und Station 03 für die drei Batu-Varianten; Zahl der Check-ins mit Klassenarbeit in Prod (nur Anzahl); eingespielte Migration mit Version; Ergebnis der Zweitprüfung; offene Punkte (z. B. Monatsbericht, Coach-Sicht, ob Check-in mehrere Themen je Arbeit erfassen soll).

---

Nachtrag Rasit zu L5 (27.10.2026), Teil D · Ziele für die nächsten 6 Monate. Gilt zusätzlich, gleiche Freigaben. Darf mit Teil C in denselben PR oder als eigener PR danach.

Anlass: Die vier Ziele aus dem Dummy (nie auf Noten ausgerichtet) sind gebaut (src/lib/report/elternbericht/zielbild.ts, zieleV4; Texte v4.s5.ziele.*), erscheinen in echten Berichten aber nie. Seite5.tsx und praesentation/v4Daten.ts zeigen sie nur bei notes.zieleBestaetigt, und nichts in der App setzt lsa_report_notes.ziele_bestaetigt (saveReportNotes schreibt nur zielbild, empfehlung, paket; paket_bestaetigt ebenso nie). Ein Freitext-Zielbild ersetzt außerdem alle Systemziele.

13. Die Systemziele erscheinen IMMER (Seite 5 und Station 04), auch ohne Bestätigung. Ohne Bestätigung Kicker „Unser Vorschlag: Ziele für die nächsten 6 Monate“, mit Bestätigung „Ziele für die nächsten 6 Monate · im Gespräch vereinbart“. „Wir versprechen keine Noten …“ steht immer darunter.
14. Schalter „Ziele im Gespräch bestätigt“ und „Paket im Gespräch bestätigt“ auf der Report-Seite im Admin (neben den Notizen) und dezent in der Präsentation (nur Admin, nicht im Druck). saveReportNotes schreibt ziele_bestaetigt und paket_bestaetigt mit; fehlen die Spalten, Schalter ausblenden.
15. Das Zielbild des Coachs (Freitext) ersetzt die Systemziele nicht mehr, sondern kommt als letztes Ziel dazu, nur wenn bestätigt. Höchstens fünf Ziele.
16. Ziel 1 nach L5: Folge unbekannt → „{Name} geht gut vorbereitet in das Thema „{Thema}“, weil die Grundlagen dafür vorher sitzen.“ Folge bekannt → „… in Klassenarbeit {n} zu „{Thema}“ …“. Ziele 2–4 unverändert.
17. Kein Übungsbedarf vor einem kommenden Thema: neues Ziel „{Name} baut auf dem auf, was schon sicher ist, und geht den neuen Stoff Schritt für Schritt mit.“ (Lena-Abnahme vermerken). Auch ohne Fahrplan (v3-Weg, zieleSaetze) erscheinen Ziele immer.
18. Leitplanken: keine Note, keine Prognose, kein „trägt/tragen“, keine Fachbegriffe außer Themennamen. Invariantentest erweitern, Zweitprüfung deckt Teil D mit ab.
19. Nachweis: Bericht und Präsentation der letzten 5–7 echten LSA-Sitzungen (Prod nur lesend) rendern und zeigen, dass überall Ziele stehen. In der Meldung: Screenshots Seite 5 und Station 04, unbestätigt und bestätigt, ohne echte Namen.
