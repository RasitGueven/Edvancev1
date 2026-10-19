# Bauauftrag R7 · Eltern-Bericht als Druckbogen nach Muster E7

Stand 18.10.2026 · Grundlage: Gründer-Gespräch Ashkan/Rasit/Tolunay vom 18.10.2026 zum Musterbericht E6 und das daraus entstandene Muster E7 (`Edvance_Elternreport_E7.pdf`: Seite 3 als Pyramide, Seite 4 als Kurve, Seiten 1, 2 und 5 wie E6) · Code-Stand `Edvancev1` dev @ `22e23c3`.

**Ausgangslage.** Im Repo steht der Report R6 (`/admin/report/:sessionId`, sechs Erzählschritte, Navy/Gold/Creme). Das Layout E6 wurde nie eingebaut. Der Auftrag kann deshalb nicht nur Seite 3 und 4 ändern: R7 baut den ganzen Bericht in der Form von E7 als fünf A4-Seiten, gespeist aus den Daten, die R6 schon liest, plus drei kleine Ergänzungen im Lesepfad. R6 bleibt unverändert erreichbar, bis die Gründer R7 abnehmen.

**Vor dem Start (Rasit):**

1. **Drei Dateien herunterladen** (sie landen im Downloads-Ordner): `Edvance_Elternreport_E7.pdf` aus dem Chat, `E7-Masse.md` und `Bauauftrag-Elternreport-R7.md` aus dem Projekt (Ordner `claude/`). R7-1 legt sie als ersten Schritt nach `docs/report/r7/`.
2. **Ampelfarben (INV-4.4).** Die Invariante verbietet Ampelfarben auf Elternflächen (R6 bewusst Navy/Gold/Creme, geprüft in `src/test/invariants/inv4-eltern-sprache.test.ts`). E6/E7 zeigt „sicher“ grün und „Übungsbedarf“ rosé, im Gespräch ausdrücklich so gewählt („wieder rot statt braun“). Der Auftrag baut mit den E7-Farben und gibt INV-4.4 für den Druckbogen eine dokumentierte Ausnahme. Wer das nicht will, sagt es vor R7-1: Dann bekommen nur die vier Tokens `--color-eb-sicher`, `--color-eb-sicher-text`, `--color-eb-uebung` und `--color-eb-uebung-text` andere Werte.
3. **Muster oder Marke.** E7 setzt Überschriften und Wortmarke in Fraunces und hat eigene Farben (Navy #304969, Gold #E4A132, Papier #F8F7F2). Laut Markenentscheidung vom 14.10. gelten Literata für Überschriften, Space Grotesk für die Wortmarke und Navy #102038, Gold #DA9721, Creme #F8F5EE. Der Auftrag baut nach dem abgenommenen Muster, legt Schriften und Farben aber nur über eigene Variablen an (`--font-eb-titel`, `--font-eb-marke`, `--color-eb-*`). Soll der Bericht der Marke folgen: vor R7-2 sagen. Dann setzt R7-2 die Werte um, lädt Literata nach und prüft die Umbrüche.

| Paket | Inhalt | Worktree · Branch | wartet auf |
|---|---|---|---|
| R7-1 Foundation | Dateien ablegen, Lesepfad ergänzt (Kompetenzen, Katalog mit Klasse, Schulform), Rechnung (Themenfelder, Pyramide, Zählung, Schwerpunkte, Genitiv), alle Texte, Tokens, Entwürfe der Kopfsätze, Fixtures, Tests | `../Edvancev1-r7a` · `feat/rasit-report-r7-daten` | – |
| R7-2 Bogen | Seitenrahmen mit Kopf und Fuß, Druck randlos, Umschalter `?fassung=r7`, Vorschauseite, Druck-Tests für alle Fälle, Seite 1 | `../Edvancev1-r7b` · `feat/rasit-report-r7-bogen` | R7-1 gemergt |
| R7-3 Seiten 2 und 5 | Lernstand mit Kompetenzprofil; Einschätzung, Mitgliedschaften, Ansprechpartner | `../Edvancev1-r7c` · `feat/rasit-report-r7-seiten25` | R7-2 gemergt |
| R7-4 Seiten 3 und 4 | Pyramide mit Lesehilfe; Fazit, Schwerpunkte als Kurve, Lernziel | `../Edvancev1-r7d` · `feat/rasit-report-r7-seiten34` | R7-2 gemergt |

R7-3 und R7-4 laufen parallel (zwei Agenten). Damit sie sich nicht in die Quere kommen:
- Beide ändern nur ihre eigenen Seitendateien (`Seite2.tsx` … `Seite5.tsx`, `seite2.css` … `seite5.css`), die R7-2 als leere Hüllen anlegt. Bogen, Rahmen, Druck-Test und Invarianten-Test legt R7-2 so an, dass sie nichts daran ändern müssen.
- Alle Texte legt R7-1 an (Anhang A). Fehlt einem Paket ein Schlüssel, ergänzt es ihn nur unter dem eigenen Seitenpräfix (`s2.*`, `s5.*` bzw. `s3.*`, `s4.*`).
- Jedes Paket startet seinen Vite-Server für die Druck-Tests auf einem eigenen Port (R7-2: 5182, R7-3: 5183, R7-4: 5184) und legt seine PDFs in einen eigenen Ordner (`docs/report/r7/abnahme/r7-2/` usw.).
- Je Paket eine Retro; die ROADMAP legt R7-1 an, danach ergänzt sie nur Rasit nach der Abnahme.

Die Migration aus R7-1 (Entwürfe der Kopfsätze) blockiert nichts: Solange Lena die Sätze nicht abgenommen hat, steht auf Seite 1 die neutrale Überschrift.

**Nicht in diesem Auftrag:** PDF-Ablage und Versand an die Eltern (der Mailweg aus Verträge P4b wäre vorhanden), Eltern-Zugang, Tablet-Präsentation, der Entwurfs-Generator `scripts/report/` (bleibt R6), Einordnung nach dem schulinternen Lehrplan (`schul_themenplan`), Löschen von R6.

---

## Entscheidungen (gelten für alle Pakete)

**1. Ganzer Bericht neu, R6 bleibt.** R7 baut alle fünf Seiten nach `docs/report/r7/Edvance_Elternreport_E7.pdf` mit den Maßen aus `docs/report/r7/E7-Masse.md` (bei Abweichungen gilt dort Teil 2). Die Route bleibt `/admin/report/:sessionId`: `?fassung=r7` zeigt R7, ohne Parameter oder mit `?fassung=r6` bleibt R6. Umgestellt wird erst nach der Abnahme (kleiner eigener PR).

**2. Ein Bogen, fünf A4-Seiten, gedruckt über den bestehenden Knopf.** Jede Seite hat Kopf (Chevron und Wortmarke, Chip „Testdaten“ nur bei `testlauf`, Mikro-Navigation mit der aktuellen Seite) und Fuß („edvance · Köln · Lernstandsanalyse {Name}“, „n / 5“). Seitenrand 0 über eine benannte Druckseite, Farben exakt, keine Skalierung am Bildschirm.

**3. „Bereich“ heißt im Bericht ein Skill.** Gezählt und gelistet werden alle direkt geprüften Skills (`lsa_skill_urteil.belegt_direkt`, mit Label), auch die ohne Themenfamilie (Funktionen, Zufall, Potenzen, Wurzeln, Runden). Mitbelegte Urteile nie. `zustand = 'traegt'` ist „sicher“, alles andere „Übungsbedarf“ (wie R6 seit #189). Ohne direkt geprüften Skill gibt es keinen R7-Bogen, nur einen Hinweis am Bildschirm. Dasselbe gilt, wenn der Katalog nicht geladen werden konnte: Eine falsche Zahl auf Papier für Eltern wäre schlimmer als kein Bogen.

**4. Nenner „von Y Bereichen des Katalogs“.** Katalog = alle Skills in `skills` mit `klasse_herkunft` ≤ k, vereinigt mit allen direkt geprüften Skills. k = die kleinere Zahl aus der Klasse der Sitzung (`lsa_sessions.grade`) und der höchsten `klasse_herkunft` im Katalog. Text: „… des Katalogs bis Klasse {k}“.
*Warum nicht wie im R6-Profil:* Der Katalog hat laut `skillBestand.ts` (Stand 04.10.) 130 Skills, 41 davon ohne Themenfamilie. Die Familienzählung aus `familien.ts` sähe sie nie, obwohl die LSA sie prüft.
*Folge:* Für Klasse 10 steht dort etwa „25 von 130“ statt „25 von 41“ wie im Muster. R7-1 meldet die echten Zahlen. Die Gründer entscheiden in der Abnahme, ob der Nenner so bleibt; er hängt an einer einzigen Funktion.

**5. Eine Gliederung für Seite 2, 3 und 4: acht Themenfelder**, gebildet aus den Inhaltsbereichen in `src/lib/report/inhaltsbereiche.ts`:

| Schlüssel | Anzeige | Inhaltsbereiche |
|---|---|---|
| brueche | Brüche & Dezimalzahlen | brueche, dezimalzahlen |
| prozent | Prozent & Dreisatz | prozent, zuordnungen |
| terme | Terme & Gleichungen | terme, gleichungen |
| geometrie | Geometrie | geometrie |
| groessen | Größen | groessen |
| zahlen | Zahlen & Rechnen | zahlen, negative_zahlen, potenzen, wurzeln |
| funktionen | Funktionen | funktionen |
| zufall | Daten & Zufall | stochastik |
| weitere | Weitere Bereiche | weitere (nur, falls belegt) |

Reihenfolge wie in der Tabelle. Seite 2 zeigt je Themenfeld eine Zeile, Seite 3 gruppiert die Pyramide danach, Seite 4 wählt die Schwerpunkte danach. Die sechs Familien aus R5 (`familien.ts`) und der Verteilungsfall bleiben für R6. R7 nutzt deshalb auch die Fazit- und Empfehlungsbausteine aus R5 nicht: Sie zählen nach Familien und sagen „wir beginnen unten“, R7 beginnt dort, wo Sicheres und Unsicheres nebeneinander liegen. Einzige Ausnahme ist `fazit`/`keine` für den Fall ohne Übungsbedarf auf Seite 4.

**6. Pyramide nach Lehrplanstufe, bezogen auf die Klasse des Kindes.** Stufe eines Skills = `stufeAusKlasse(klasse_herkunft)` (Kernlehrplan G9 NRW), Stufe des Kindes = `stufeAusKlasse(grade)`. Nie `fundament_tiefe`.

| Stufe des Skills | Ebene |
|---|---|
| über der Stufe des Kindes (möglich, wenn das Thema über der Klasse liegt) | **Stoff späterer Klassen** (eigene Ebene ganz oben, nur wenn belegt) |
| gleich der Stufe des Kindes | **Aktueller Unterrichtsstoff** |
| Erprobungsstufe (5/6) unter der Stufe des Kindes | **Grundlagen** |
| dazwischen | **Weiterführende Themen** |

Klasse 9/10 ergibt bis zu drei Ebenen (9/10 · 7/8 · 5/6), Klasse 7/8 zwei (7/8 · 5/6), Klasse 5/6 eine. Ab Klasse 11 hat der Katalog keine eigene Stufe: 7–10 sind „Weiterführende Themen“, 5/6 „Grundlagen“. Leere Ebenen entfallen. Die unterste Ebene ist 507 pt breit, jede darüber 56 pt schmaler. Neben dem Ebenentitel steht die Klassenangabe aus den Daten („Klasse 9/10“, über mehrere Stufen „Klasse 7–10“), nicht „darauf aufbauend“ wie im Muster. Die Pyramide behauptet keine Voraussetzung; das sagt der Hinweis darunter.
*Folge für Ilkay:* Nach den Daten im Muster liegen alle Bereiche seiner Analyse vom 20.09. in Klasse 5 bis 8 (die alte LSA begann für alle bei den Gleichungen). Seine Pyramide hat deshalb zwei Ebenen, oben „Weiterführende Themen · Klasse 7/8“, und nicht drei wie das Muster. Analysen nach dem Katalogausbau im Oktober erreichen auch 9/10.

**7. Schwerpunkte.** Seite 1 „Unser erster Ansatz“ ist Schwerpunkt 1, Seite 4 zeigt bis zu vier. Kandidaten sind Themenfelder mit mindestens einem Bereich mit Übungsbedarf. Reihenfolge:

1. gemischt zuerst (im Themenfeld gibt es Sicheres und Übungsbedarf); das trägt „Auf vorhandenen Stärken aufbauen“ und „Wir beginnen bei dem, was schon klappt“,
2. dann die tiefste Stufe unter den Übungsbedarf-Bereichen (5/6 vor 7/8 vor 9/10),
3. dann mehr Übungsbedarf vor weniger,
4. dann die Reihenfolge der Themenfelder.

Höchstens vier; die übrigen nennt Seite 4 in derselben Reihenfolge in einem Satz („Danach nehmen wir … dazu.“). Titel ist der Name des Themenfelds, der Text listet die Bereiche („Sicher: … Noch nicht sicher: …“). Für die Daten des Musters ergibt die Regel Geometrie, Brüche & Dezimalzahlen, Größen, Prozent & Dreisatz; das Muster hatte Größen, Prozent, Brüche, Terme. Die Regel ist ein Vorschlag: R7-1 meldet das Ergebnis für Ilkays echte Sitzung, die Gründer bestätigen es in der Abnahme.

**8. Texte.** Alle festen Sätze stehen im neuen Namespace `elternbericht` (Anhang A) und werden wörtlich übernommen. Sätze aus der Datenbank bleiben, wo sie heute schon gelten, und zwar so, wie Lena sie abgenommen hat: Rückbezüge (`rueckbezug`, Seite 1), Elterntexte der Fehlbild-Familien (Seite 4), `fazit`/`keine` (Seite 4). Neu ist der Slot `kopf` für die Überschrift (Anhang B, als Entwurf); ohne abgenommenen Kopfsatz steht „Was wir bei {Name} gesehen haben“. Elf abgenommene Rückbezüge und `fazit.keine.a` sagen heute noch „tragen“ oder „Ebenen“; ihre Entwürfe (W5-d, `docs/report/rueckbezug-texte.md`) warten auf Lenas Abnahme (Abnahme 8).

**9. Sprachregeln für die eigenen Texte** (INV-4 gilt auch hier): „Sie“-Form; kein Pronomen für das Kind (Name, Genitiv „Ilkays“, ohne Namen „Ihr Kind“); nie „gemeistert“, kein „trägt“, keine Note, kein Prozentwert, keine Prognose, kein Vergleich mit anderen Kindern; kein roher Schlüssel (`skill_key`, Slug, Familienschlüssel) im Text. Fehlt ein Datum, entfällt der Satz oder der Abschnitt still, nie ein erfundener Ersatz.

**10. Was woher kommt:**

| Seite · Element | Quelle | wenn es fehlt |
|---|---|---|
| 1 · Überschrift | Baustein `kopf`, Fall `gemischt` / `sicher` / `uebung` | Ersatzüberschrift |
| 1 · Kopfdaten | Klasse und `students.school_type`, Fach, Aufgaben, Datum | Schulform weglassen |
| 1 · Anliegen | `anlassNamen` und `naechstesThema` wie R6, alle Rückbezüge | der jeweilige Satz entfällt |
| 1 · Weg durch den Bericht | fest | entfällt bei mehr als einem Rückbezug (Platz) |
| 2 · „Was die Grafik zeigt“ | Satz aus den Daten: Themenfelder mit überwiegend Sicherem bzw. überwiegend Übungsbedarf; jedes Feld steht in höchstens einem der beiden Sätze | Teilsatz entfällt |
| 4 · Fazit | Elterntexte aus `gruppiereFehlbilderNachFamilie`, höchstens zwei, dazu ein fester Satz | Kasten entfällt |
| 4 · Lernziel | `lsa_report_notes.zielbild` | Kasten entfällt, Kurve endet am letzten Knoten ohne Spitze |
| 5 · Vorschlag | `lsa_report_notes.paket` und `tiers` (aktive nach `sort_order`; basis → 1., standard → 2., premium → 3.; erstes Merkmal aus `features`), dazu `lsa_report_notes.empfehlung` | Zeile entfällt, keine Karte hervorgehoben |
| 5 · Mitgliedschaften | `listTiers()` | Abschnitt entfällt |
| 5 · Ansprechpartner | `erzaehlung.ansprechpartner` | „Das Edvance-Team“ und hello@edvanceacademy.de |

**11. Bewusste Abweichungen vom Muster:** Klassenangaben aus den Daten; bei Ilkay zwei Ebenen statt drei (siehe 6); Gruppen sind Themenfelder; Titel der Schwerpunkte ist das Themenfeld; Texte ohne Pronomen; „NRW-Lehrplan“ statt „Lehrplan seiner Schule“ (der schulinterne Plan ist ein eigener Auftrag); kein Satz behauptet, ein Thema baue auf einem anderen auf; Chip „Vorschlag“ statt „Vorschlag, noch nicht freigegeben“; keine Rolle „Mitgründer“ (steht nicht in den Daten); Seite 2 und Seite 4 wiederholen nicht denselben Absatz (Seite 2 beschreibt die Grafik, Seite 4 die Fehlbilder); Überschriften in einer Schriftgröße statt in drei.

**12. Ort im Code.**
- Reine Rechnung unter `src/lib/report/elternbericht/`, Fixtures unter `src/lib/report/elternbericht/fixtures/` (mehrere Dateien, je ≤ 400 Zeilen), Typen in `src/types/elternbericht.ts`.
- Komponenten unter `src/components/edvance/elternbericht/`, Styles unter `src/styles/elternbericht/` (Bereich `.eb-bogen`).
- Texte in `src/i18n/locales/de/elternbericht.json`, Farben und Schriften als `--color-eb-*` und `--font-eb-*` in `src/styles/tokens.css`.
- Vorschau als eigene Vite-Seite `vorschau/elternbericht.html` (nur im Dev-Server, nicht im Build, ohne Supabase-Client). `src/App.tsx` (474 Zeilen) wird nicht angefasst: Der post-edit-Hook lehnt jede Änderung an Dateien über 400 Zeilen ab.
- Druck-Tests unter `e2e-druck/` mit eigener Konfiguration `playwright.elternbericht.config.ts`, getrennt vom bestehenden `e2e/`.
- Neue Invarianten in `src/test/invariants/inv4-elternbericht.test.ts`. `inv4-eltern-sprache.test.ts` hat schon 412 Zeilen und bleibt unberührt.
- Supabase-Aufrufe nur in `src/lib/supabase/`.

---

## R7-1 · Foundation

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-1: Daten, Rechnung und Texte für den Eltern-Bericht R7.

## Ziel
Alles, was die fünf Seiten brauchen, liegt als getestete reine Rechnung und als Text bereit, bevor eine Seite gebaut wird.

## Schritt 0
Lege die drei Dateien aus dem Downloads-Ordner ins Repo:
mkdir -p docs/report/r7 && cp "/mnt/c/Users/rasit/Downloads/Edvance_Elternreport_E7.pdf" docs/report/r7/ && cp "/mnt/c/Users/rasit/Downloads/E7-Masse.md" docs/report/r7/E7-Masse.md && cp "/mnt/c/Users/rasit/Downloads/Bauauftrag-Elternreport-R7.md" docs/report/r7/Bauauftrag-R7.md
Fehlt eine davon: STOPP und Rasit fragen. Dann docs/report/r7/Bauauftrag-R7.md lesen (Entscheidungen 1–12, Anhang A und B) und das PDF ansehen.

## Entscheidungen (nicht neu verhandeln)
1. Lesepfad (src/lib/supabase/lsaReportErzaehlung.ts, lsaReport.ts; Typen in src/types/report.ts):
   - ReportErzaehlung bekommt kompetenzen: SucheSkill[] (die Liste, die loadUrteile schon liefert, unverändert) und katalog: { skillKey: string; klasse: number }[]. loadBestand liest dafür skill_key und klasse_herkunft; R6 bekommt weiter nur die Schlüssel.
   - ReportData bekommt schulform: string | null aus students.school_type der Sitzung. Eine Abfrage; Fehler oder RLS ergeben null, kein Abbruch.
   - Sonst ändert sich am R6-Lesepfad nichts. R6-Tests anpassen, nicht löschen.
2. Typen in src/types/elternbericht.ts (Export über src/types/index.ts), Rechnung unter src/lib/report/elternbericht/, je Datei eine Testdatei:
   - themenfelder.ts: THEMENFELDER (Schlüssel, Reihenfolge, Zuordnung aus Entscheidung 5) und feldVon(skillKey) über inhaltsbereich().
   - einordnung.ts: ebeneFuer(skillKlasse, kindKlasse) mit den Ebenen spaeter | aktuell | weiterfuehrend | grundlagen nach Entscheidung 6, und bauePyramide(). Ebenen von oben nach unten, nur nicht leere; je Ebene die enthaltenen Stufen, die Zählung sicher/Übungsbedarf und die Gruppen je Themenfeld (Reihenfolge der Felder; in der Gruppe erst sicher, dann Übungsbedarf, je nach Label mit localeCompare 'de').
   - zaehlung.ts: untersucht, sicher, uebung, katalog, offen = katalog − untersucht, bisKlasse (Entscheidung 4, Katalog als Vereinigung, damit offen nie negativ wird); profil je Themenfeld mit vorhanden > 0 (vorhanden, sicher, uebung). Summe der Profilzeilen = katalog, sicher + uebung = untersucht.
   - schwerpunkte.ts: Regel aus Entscheidung 7. Je Schwerpunkt feld, gemischt, sicher (Labels), uebung (Labels); danach = die übrigen Themenfelder mit Übungsbedarf in derselben Reihenfolge.
   - sicherListe und uebungListe für Seite 1: sortiert nach Themenfeld, dann klasse_herkunft, dann Label.
   - kopfFall: 'gemischt' (sicher > 0 und uebung > 0), 'sicher' (uebung = 0), 'uebung' (sicher = 0).
   - genitiv.ts: genitiv(name). Endet der Name auf s, ß, x oder z (auch tz): Apostroph ’ (Max’, Moritz’, Hans’), sonst „s“ (Ilkays, Lenas, Emils).
   - bericht.ts: baueElternbericht({ kompetenzen, katalog, klasse }) fasst alles zusammen; null, wenn kompetenzen oder katalog leer sind.
3. Texte: neuer Namespace elternbericht in src/i18n/locales/de/elternbericht.json, Inhalt wörtlich aus Anhang A; in src/i18n/index.ts registrieren.
4. Tokens in src/styles/tokens.css, mit dem Kommentar „Druckbogen Eltern-Bericht R7, Werte aus dem Muster E7“: die Farben aus docs/report/r7/E7-Masse.md (Teil 1, Tabelle „Farben“) als --color-eb-<name>; dazu --font-eb-titel ('Fraunces' mit Rückfall wie --font-serif) und --font-eb-marke ('Fraunces'). Hat Rasit vor dem Start „Marke“ gewählt, gelten die Markenwerte aus dem Bauauftrag (Vor dem Start, Punkt 3). Keine anderen Tokens ändern.
5. Migration supabase/migrations/<V>_r7_kopf_entwuerfe.sql (V per date -u, frei geprüft; eine neue Datei braucht kein ALLOW_MIGRATIONS): die sechs Kopfsätze aus Anhang B als neue Zeilen in report_bausteine, slot 'kopf', text = Entwurf, freigegeben_am bleibt null, on conflict (schluessel) do nothing. Muster: 20261004093449_report_ausgangspunkt_entwuerfe.sql (ohne begin/commit, der Runner klammert). Abnahmeliste in docs/report/r7/kopf-texte.md: Satz, Fall, Platzhalter {name}, Abnahme-SQL wie im Spaltenkommentar von report_bausteine.entwurf.
6. Fixtures unter src/lib/report/elternbericht/fixtures/ (mehrere Dateien, je ≤ 400 Zeilen), nur von Tests und der Vorschau importiert, ohne Import des Supabase-Clients:
   - ilkay: Ilkays echte Analyse, Sitzung 6d868c5f… (20.09.2026, Klasse 10, nachgetragener Themenraum terme_gleichungen, testlauf = false). Über dbread lesen, Auswahl über die ID (where id::text like '6d868c5f%', genau eine Zeile, sonst STOPP), nicht über testlauf. Abfragemuster: scripts/report/sitzungSql.ts. Als vollständige ReportData samt erzaehlung und katalog. IDs durch feste Platzhalter ersetzen, Rufname „Ilkay“ wie im Muster, keine weiteren personenbezogenen Daten (keine Mail, keine Schule). Urteile, Probenzahl und offen wörtlich (wie suche.fixtures.ts).
   - Synthetische Fälle, klein und aus ilkay abgeleitet: testlauf (wie ilkay, testlauf = true), klasse10neu (mit Bereichen aus 9/10, drei Ebenen), klasse7 (zwei Ebenen), spaeter (Klasse 7 mit einem Bereich aus 9/10), allesSicher, nichtsSicher, sechsFelderMitUebung, alleFelder (alle acht Felder mit Übungsbedarf), ohneName, vieleRueckbezuege (vier), ohneNotizen, ohneKatalog.
   - notizen (zielbild, empfehlung, paket 'premium') und tiers (drei aktive Pakete wie im Muster) als eigene Fixtures.
   - Ein Verzeichnis FAELLE: Name → { data, notes, tiers }, damit Vorschau und Druck-Test alle Fälle durchgehen können.

## Umfang
docs/report/r7/ (drei Dateien, kopf-texte.md), src/lib/supabase/lsaReportErzaehlung.ts, src/lib/supabase/lsaReport.ts, src/types/report.ts, src/types/elternbericht.ts, src/types/index.ts, src/lib/report/elternbericht/**, src/i18n/locales/de/elternbericht.json, src/i18n/index.ts, src/styles/tokens.css, die eine Migration, src/test/invariants/inv4-elternbericht.test.ts (neu), Retro, ROADMAP (Abschnitt R7 anlegen).

## Tests
Vitest:
- feldVon über SKILL_BESTAND: jeder Schlüssel landet in einem der acht Felder, keiner in 'weitere'.
- ebeneFuer für Klasse 5, 6, 7, 8, 9, 10, 11 mit Skills aus 5/6, 7/8 und 9/10, auch „spaeter“.
- Pyramide für ilkay (Zahl der Ebenen aus den Daten, nicht fest erwartet), klasse10neu (drei), klasse7 (zwei), spaeter (oberste Ebene „Stoff späterer Klassen“): Ebenen, Klassenangabe, Gruppen, Reihenfolge in der Gruppe.
- Zählung: Profil = Katalog, sicher + uebung = untersucht; Skills ohne Familie zählen mit; ein geprüfter Skill über der Klasse erhöht den Katalog; ohneKatalog ergibt null.
- Schwerpunkte: jede der vier Sortierstufen an einem eigenen Fall, höchstens vier, danach-Liste in Reihenfolge.
- genitiv: Ilkay, Lena, Max, Moritz, Hans, Felix, Liz. kopfFall für alle drei Fälle.
- inv4-elternbericht.test.ts (neu, Aufbau wie inv4-entwuerfe.test.ts): elternbericht.json duzt nicht, enthält kein %, keinen snake_case-Schlüssel, kein „trägt“ und kein „gemeistert“; die Sätze der neuen Migration nach denselben Regeln wie INV-4.5, mit eigener Platzhalterliste (nur {name}).
Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-r7a auf feat/rasit-report-r7-daten von origin/dev. PR gegen dev, nie main.
- Kein DDL, kein Schreiben gegen Prod; Prod nur lesend über dbread. Eingespielt wird nach dem Merge von Rasit nach CLAUDE.md §10.
- R6-Komponenten nicht ändern (außer Typ-Anpassungen in Tests). fundament_tiefe nirgends für die Pyramide.
- Dateien ≤ 400 Zeilen; mehr als 300 neue Zeilen nach CLAUDE.md §4 in Commits aufteilen.
- Zweitprüfung durch eine frische Instanz vor dem PR, Schwerpunkt Zählung, Nenner und Ebenen. STOPP nach dem PR.

## Melden
PR-Link. Für ilkay und zwei weitere abgeschlossene Analysen (nur Zahlen, keine Namen): untersucht, sicher, Übungsbedarf, Katalog, nicht untersucht; dieselben Zahlen mit dem R6-Nenner (Summe der sechs Familien) zum Vergleich; die Profilzeilen; die Ebenen der Pyramide mit Zahl der Bereiche; die Schwerpunkte in Reihenfolge. Abweichungen, offene Punkte (docs/report/r7/offene-punkte-r7-1.md).
```

---

## R7-2 · Bogen, Druck und Seite 1

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-2: Druckbogen mit Kopf und Fuß, Umschalter auf R7, Vorschauseite, Druck-Tests und Seite 1. Voraussetzung: R7-1 gemergt (baueElternbericht, Fixtures mit FAELLE, Namespace elternbericht, Tokens --color-eb-* und --font-eb-*; sonst STOPP).

## Ziel
/admin/report/:sessionId?fassung=r7 zeigt den Bericht als fünf A4-Seiten und druckt sie randlos über den bestehenden Knopf. Seite 1 ist fertig; die Seiten 2–5 stehen als Seiten mit Kopf und Fuß bereit, damit R7-3 und R7-4 parallel bauen können, ohne Bogen, Rahmen, Druck-Test oder Invarianten-Test anzufassen. Vorlage: docs/report/r7/Edvance_Elternreport_E7.pdf. Maße: docs/report/r7/E7-Masse.md (Teil 1 „Alle Seiten“ und „Seite 1“; bei Abweichungen gilt Teil 2). Die Entscheidungen 1–12 aus docs/report/r7/Bauauftrag-R7.md gelten.

## Entscheidungen (nicht neu verhandeln)
1. Umschalter: ReportPage liest ?fassung (r7, sonst r6). Bei r7 zusätzlich listTiers() laden. In den Aktionen der Seite ein Knopf „Neue Fassung (Druck)“ bzw. „Bisherige Fassung“ (elternbericht:fassung.*). Die R6-Ansicht bleibt unverändert.
2. Ansicht R7 in einem eigenen Wrapper .eb-ansicht (nicht .report-sheet): Hinweis „läuft noch“ wie R6 und TestlaufBanner nur am Bildschirm (print-hide); dann <ElternberichtBogen data notes tiers />; darunter ReportOutlook in einem print-hide-Wrapper, damit Admins Lernziel, Empfehlung und Paket weiter pflegen. Statt des Bogens ein EmptyState, wenn baueElternbericht null liefert: ohne Kompetenzen elternbericht:fassung.leer, ohne Katalog elternbericht:fassung.keinKatalog.
3. Bogen: src/components/edvance/elternbericht/Bogen.tsx rechnet einmal (useMemo) baueElternbericht({ kompetenzen, katalog, klasse: data.grade }) und den Bausteinsatz aus erzaehlung.bausteine und rendert fünf <Seite nummer={n}>. Seite.tsx setzt Kopf und Fuß absolut (Werte aus dem Maßblatt, „Alle Seiten“). Der Inhalt läuft im Fluss in einem Kasten .eb-inhalt, der unter der Kopflinie beginnt und bei y 800 pt endet. Seite1.tsx bis Seite5.tsx sind eigene Dateien mit denselben Props { data, bericht, satz, notes, tiers, name, wessen } (name = Rufname oder null, wessen = genitiv(name) oder null). Seite2 bis Seite5 bleiben in diesem Paket leer (nur Rahmen), jede mit eigener leerer CSS-Datei. Das Schraffur-Pattern für Seite 2 (SVG, patternUnits userSpaceOnUse, 45°, Abstand 7 pt, Linie 1,3 pt, --color-eb-schraffur) definiert der Bogen schon jetzt einmal, versteckt.
4. Styles: src/styles/elternbericht/index.css (ein Import in globals.css) importiert rahmen.css und seite1.css bis seite5.css. Alles unter .eb-bogen, Maße und Radien in pt aus dem Maßblatt. Seite 595,28 × 841,89 pt, overflow hidden, Fläche --color-eb-papier. Am Bildschirm Seiten untereinander mit 24 px Abstand und shadow-card, mittig; der Wrapper scrollt seitlich unter 800 px Breite. Keine Skalierung (kein zoom, kein transform), sonst stimmen die Messungen der Kurve auf Seite 4 nicht.
5. Druck: @page eb { size: A4; margin: 0 } und .eb-seite { page: eb; break-after: page } (letzte Seite ohne Umbruch); Schatten weg; print-color-adjust: exact. Falls im Druck nötig: Vorfahren des Bogens display: block über :has(.eb-bogen), AppShell nicht ändern. Die globale @page-Regel aus print.css bleibt für R6. Entsteht eine leere Seite am Ende: Seitenhöhe minimal kürzen und melden.
6. Schrift wie im Maßblatt über --font-eb-titel (Gewicht 500, font-variation-settings 'opsz' 48) und Schibsted Grotesk 400; Wortmarke über --font-eb-marke. Am Bogen font-kerning: none, font-feature-settings 'kern' 0, font-synthesis: none. Kicker 8,3 pt navy, Versalien per CSS, Sperrung 0,95 pt. Hat Rasit „Marke“ gewählt: Literata in index.html und in der Vorschauseite nachladen und die Umbrüche aller Seiten prüfen.
7. Seite 1 von oben nach unten, im Fluss mit den Abständen aus dem Maßblatt:
   - Kicker s1.kicker mit dem Fach. Überschrift: satz.waehle('kopf', bericht.kopfFall, sessionId, { name: name ?? t('kind') }), sonst s1.kopfErsatz (ohne Namen s1.kopfErsatzOhneName). Größe 26 pt, Zeilenabstand 32, höchstens drei Zeilen, text-wrap: balance.
   - Kopfdaten-Kasten: Klasse („10, Gymnasium“ über s1.meta.klasseSchulform, ohne Schulform nur die Zahl), Fach, Umfang (Plural über count), Datum (Intl.DateTimeFormat, dateStyle long, Europe/Berlin).
   - „Auf einen Blick“: Zeile aus der Zählung (white-space: pre-wrap für die doppelten Abstände). Drei Karten: die ersten vier aus sicherListe bzw. uebungListe, darunter „+n weitere“ bei mehr als vier; leer → s1.blick.keinSicher bzw. s1.blick.keineUebung. Dritte Karte: Schwerpunkt 1 mit Kreis „1“, Titel = Themenfeld, Text s1.blick.ansatzGemischt bzw. s1.blick.ansatzUebung; ohne Schwerpunkt ohne Kreis und Titel, Text s1.blick.ansatzKeiner.
   - Zwei Kästen nebeneinander, gleich hoch, sie wachsen gemeinsam. Links Anliegen: s1.anliegen.genannt mit genitiv(name) und den Anzeigenamen (Intl.ListFormat 'de', conjunction), ohne Namen s1.anliegen.genanntOhneName (Plural); dann s1.anliegen.thema; dann alle Rückbezüge, ausgewählt wie in ReportRueckbezug: satz.waehle('rueckbezug', r.fall, `${sessionId} ${r.thema}`, { belege: r.belege }), ohne Marken. Gibt es weder Anlass noch Thema noch Rückbezug, entfällt der linke Kasten und „So haben wir geprüft“ steht in voller Breite. Rechts „So haben wir geprüft“: s1.geprueft.text, Hinweis s1.geprueft.hinweis nur bei offen > 0 (Plural).
   - „Ihr Weg durch diesen Bericht“: Pfad, Stationen, Beschriftungen und „Sie sind hier“ als ein SVG, Pfaddaten und Lage aus dem Maßblatt. Entfällt, wenn mehr als ein Rückbezug angezeigt wird.
8. Vorschauseite: vorschau/elternbericht.html (Vite-Mehrseiten im Dev-Server, nicht im Build) mit den Schrift-Links aus index.html und einem eigenen Einstieg src/components/edvance/elternbericht/vorschau/main.tsx: importiert @/i18n und die globalen Styles, rendert den Bogen für ?fall=<Name> aus FAELLE, ohne Router, ohne Anmeldung und ohne irgendein Modul, das den Supabase-Client lädt (sonst braucht der Worktree eine .env). Ohne ?fall eine schlichte Liste der Fälle.
9. Druck-Tests: playwright.elternbericht.config.ts mit testDir e2e-druck, webServer „npx vite --port $EB_PORT --strictPort“ (Standard 5182), reuseExistingServer: false, baseURL passend. e2e-druck/elternbericht.spec.ts geht ALLE Fälle aus FAELLE durch, damit R7-3 und R7-4 die Datei nicht ändern müssen. Je Fall: auf document.fonts.ready warten; je Seite darf .eb-inhalt nicht überlaufen (scrollHeight ≤ clientHeight, Unterkante ≤ 800 pt); Kopf- und Fußlinie, Chip und Navigationspunkte liegen ±1 pt an den Maßblatt-Werten (über getBoundingClientRect der gezeichneten Teile, nicht über Textgrundlinien); page.pdf({ preferCSSPageSize: true, printBackground: true }) nach $EB_AUSGABE/<fall>.pdf (Standard docs/report/r7/abnahme/r7-2) und das PDF hat genau fünf Seiten. Aufruf: EB_PORT=5182 EB_AUSGABE=docs/report/r7/abnahme/r7-2 npx playwright test -c playwright.elternbericht.config.ts. Fehlt Chromium: npx playwright install chromium.
10. Invarianten: inv4-elternbericht.test.ts (aus R7-1) erweitern, per Glob über alle Dateien unter src/components/edvance/elternbericht/ und src/styles/elternbericht/: skillKey und Familienschlüssel nur als React-key; in .ts/.tsx keine Prozentrechnung (* 100), kein toFixed und kein % im ausgegebenen Text (CSS ausgenommen); Farben nur aus --color-eb-*; keine Hex-Werte.
11. CLAUDE.md §11 bekommt nach „Tabellen im Admin“ den Abschnitt „Druckbogen Eltern-Bericht (R7)“: Für src/components/edvance/elternbericht/** und src/styles/elternbericht/** gelten Maße und Radien in pt aus dem Maßblatt, mehr als drei Schriftgrößen, eigene Kästen statt EdvanceCard, absolute Lage für Kopf, Fuß und die Kurve; Farben nur aus --color-eb-*, Texte nur über i18n. src/styles/elternbericht/** gehört zum Bericht, nicht zum Student-Fenster. Dazu die Ausnahme von INV-4.4: Grün/Rosé für sicher/Übungsbedarf, beschlossen im Gründer-Gespräch vom 18.10.2026.

## Umfang
src/pages/admin/ReportPage.tsx, src/components/edvance/elternbericht/** (Bogen, Seite, Seite1–5, vorschau/), src/styles/elternbericht/**, src/styles/globals.css (ein Import), vorschau/elternbericht.html, playwright.elternbericht.config.ts, e2e-druck/**, src/test/invariants/inv4-elternbericht.test.ts, CLAUDE.md §11, Retro. Nicht anfassen: src/App.tsx, src/lib/supabase/**, src/types/**, tokens.css (außer bei „Marke“), inv4-eltern-sprache.test.ts. Neue Schlüssel in elternbericht.json nur unter s1.* und fassung.*. Fehlt etwas in lib oder types: STOPP und melden.

## Tests
Vitest (Testing Library): Umschalter (r6 ohne Parameter, r7 mit); Chip nur bei testlauf (Fall testlauf); Mikro-Navigation markiert die richtige Seite; Fuß mit und ohne Namen; Seite 1 für ilkay, allesSicher, nichtsSicher, ohneName (Überschrift aus Baustein und Ersatz, Listen mit „+n weitere“, Anliegen mit Genitiv und ohne Namen, Weg entfällt bei vier Rückbezügen); EmptyState ohne Kompetenzen und ohne Katalog. inv4-elternbericht.test.ts grün. Druck-Tests grün für alle Fälle (Seiten 2–5 noch leer), PDFs im PR. Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-r7b auf feat/rasit-report-r7-bogen von origin/dev. PR gegen dev, nie main.
- Designregeln CLAUDE.md §11 mit der neuen Ausnahme; keine Hex-Werte außerhalb tokens.css; Inline-Styles nur für berechnete Werte. Dateien ≤ 400 Zeilen.
- Zweitprüfung durch eine frische Instanz vor dem PR, Schwerpunkt Druck (Ränder, Seitenumbrüche, Schrift). STOPP nach dem PR.

## Melden
PR-Link, PDFs aus docs/report/r7/abnahme/r7-2/, Bildschirmfoto der Ansicht mit Umschalter, Abweichungen vom Muster mit Grund, offene Punkte (docs/report/r7/offene-punkte-r7-2.md).
```

---

## R7-3 · Seiten 2 und 5

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-3: Seite 2 (Lernstand) und Seite 5 (Nächste Schritte). Voraussetzung: R7-2 gemergt (Bogen, Seite, Hüllen Seite2.tsx und Seite5.tsx, Schraffur-Pattern, Vorschauseite, Druck-Tests; sonst STOPP). Läuft parallel zu R7-4.

## Ziel
Seite 2 zeigt den Lernstand in Zahlen und als Kompetenzprofil je Themenfeld, Seite 5 Einschätzung, Mitgliedschaften und Ansprechpartner. Vorlage: Seiten 2 und 5 von docs/report/r7/Edvance_Elternreport_E7.pdf, Maße: docs/report/r7/E7-Masse.md (Teil 1 „Seite 2“ und „Seite 5“; bei Abweichungen gilt Teil 2). Die Entscheidungen 1–12 aus docs/report/r7/Bauauftrag-R7.md gelten.

## Entscheidungen (nicht neu verhandeln)
1. Seite 2:
   - Kicker, Titel s2.titel mit wessen (ohne Namen s2.titelOhneName), Intro s2.intro, dahinter s2.introOffen (Plural) nur bei offen > 0.
   - Drei Zahlen sicher / Übungsbedarf / nicht untersucht mit Farbbalken darüber.
   - Profil-Karte: eine Zeile je Eintrag in bericht.profil (vorhanden > 0, Reihenfolge der Felder). Je Kompetenz ein Segment: erst sicher, dann Übungsbedarf, dann nicht untersucht (weiß, Rand schraffur-rand 0,7, Füllung mit dem Schraffur-Pattern aus dem Bogen). Spur 226 pt; Lücke 4 pt bis 16 Segmente, 2 pt bis 30, darüber 1 pt; Radius min(3,5 pt, Segmentbreite / 3).
   - Die Segmente sind Anzahlen, keine Quote: beide Zahlen stehen als Text daneben, die Spur ist aria-hidden, jede Zeile hat s2.profil.aria als Vorlesetext. Keine Prozentrechnung im Renderpfad.
   - Rechts „x von y untersucht“, darunter nur die von null verschiedenen Teile („s sicher“, „u Übungsbedarf“) mit „ · “ verbunden; bei x = 0 nur die erste Zeile.
   - Zeilenabstand 40,8 pt bis sechs Zeilen, ab sieben Zeilen 33,4 pt (Trennlinien entsprechend). Mit acht Zeilen (ab etwa Klasse 8 der Normalfall) läuft die Seite nicht über.
   - Legende Sicher / Übungsbedarf / Nicht untersucht wie im Maßblatt.
   - „Was die Grafik zeigt“: Ein Feld zählt für s2.deutung.sicher, wenn es dort mehr sichere als Übungsbedarf-Bereiche gibt, sonst (bei Übungsbedarf > 0) für s2.deutung.uebung. Je Satz höchstens zwei Felder, nach der jeweiligen Anzahl absteigend, Gleichstand nach Reihenfolge der Felder; Plural über die Zahl der Felder; Aufzählung mit Intl.ListFormat 'de', conjunction. Danach s2.deutung.coach, nur wenn es Übungsbedarf gibt. Ein Satz ohne Feld entfällt.
   - Fußnote s2.fussnote.
2. Seite 5:
   - Kicker, Titel s5.titel, Intro.
   - Navy-Kasten: Chip s5.vorschlag.chip; Titel s5.vorschlag.titel (ohne Namen titelOhneName); Zeile s5.vorschlag.zeile mit Paketname und erstem Merkmal, danach notes.empfehlung. Ohne Paket nur notes.empfehlung, ohne beides entfällt die Zeile.
   - Mitgliedschaften: aktive Pakete aus tiers nach sort_order, je Karte Kopf „Mitgliedschaft“, Name, Merkmal 1 und 2 aus features (fehlende entfallen), „Konditionen im Gespräch“. Hervorgehoben (Fläche mint-karte, Rand sicher, Chip „Coach-Vorschlag“ statt Kopf) wird die Karte zu notes.paket: basis → 1., standard → 2., premium → 3. Sind nicht genau drei Pakete aktiv: keine Hervorhebung, console.warn, im PR melden. Ohne Pakete entfällt der Abschnitt samt Hinweis.
   - Kontakt-Kasten: links Ansprechpartner (Name, s5.kontakt.rolle, Mail als mailto-Link), ohne Zuordnung s5.kontakt.team und s5.kontakt.mail; rechts s5.fragen.
   - Kein Preis, keine Laufzeit, keine Vertragsangabe.

## Umfang
src/components/edvance/elternbericht/Seite2.tsx und Seite5.tsx (plus Teile, z. B. Profil.tsx; die Segmentrechnung als reine Funktion mit Test), src/styles/elternbericht/seite2.css und seite5.css, neue Schlüssel nur unter s2.* und s5.*, Retro. Nicht anfassen: Bogen.tsx, Seite.tsx, rahmen.css, Seite1/3/4, e2e-druck/**, playwright.elternbericht.config.ts, inv4-*.test.ts, src/App.tsx, src/lib/**, src/types/**, ROADMAP. Fehlt etwas: STOPP und melden.

## Tests
Vitest: Profilzeilen und Segmentzahl je Feld für ilkay; Lückenregel (16, 17, 30, 31 Segmente); rechte Zeile (nur sicher, nur Übungsbedarf, beides, nichts untersucht); „Was die Grafik zeigt“ für ilkay, allesSicher, nichtsSicher (kein Feld in beiden Sätzen); Seite 5 mit und ohne Paket, ohneNotizen, mit zwei und mit vier aktiven Paketen (keine Hervorhebung), ohne Ansprechpartner. Druck-Tests mit EB_PORT=5183 EB_AUSGABE=docs/report/r7/abnahme/r7-3 für alle Fälle grün. inv4-elternbericht.test.ts grün. Typecheck, Lint, Vitest grün.

## Leitplanken
Worktree ../Edvancev1-r7c auf feat/rasit-report-r7-seiten25 von origin/dev, PR gegen dev, nie main. Designregeln mit der R7-Ausnahme aus CLAUDE.md §11, keine Hex-Werte außerhalb tokens.css. Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz. STOPP nach dem PR.

## Melden
PR-Link, PDFs aus docs/report/r7/abnahme/r7-3/ (Seiten 2 und 5), Abweichungen vom Muster mit Grund, offene Punkte (docs/report/r7/offene-punkte-r7-3.md).
```

---

## R7-4 · Seiten 3 und 4

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-4: Seite 3 (Einordnung als Pyramide) und Seite 4 (Lernplan als Kurve). Voraussetzung: R7-2 gemergt (Bogen, Seite, Hüllen Seite3.tsx und Seite4.tsx, Vorschauseite, Druck-Tests; sonst STOPP). Läuft parallel zu R7-3.

## Ziel
Seite 3 ordnet jeden untersuchten Bereich in eine Pyramide nach Lehrplanstufe (unten Grundlagen, oben aktueller Stoff), gruppiert nach Themenfeld, mit Lesehilfe. Seite 4 zeigt das Fazit, die Schwerpunkte auf einer Kurve wie im Logo und das gemeinsame Lernziel. Vorlage: Seiten 3 und 4 von docs/report/r7/Edvance_Elternreport_E7.pdf, Maße: docs/report/r7/E7-Masse.md (Teil 1 „Seite 3“ und „Seite 4“ mit den CSS-Werten und den Kurvenformeln; bei Abweichungen gilt Teil 2). Die Entscheidungen 1–12 aus docs/report/r7/Bauauftrag-R7.md gelten.

## Entscheidungen (nicht neu verhandeln)
1. Seite 3:
   - Titel s3.titel, ohne sicheren Bereich s3.titelOhneSicher. Intro s3.intro, wenn genau die Ebenen aktuell, weiterführend und grundlagen vorkommen, sonst s3.introKurz. Zwischenzeile und Legende auf einer Grundlinie.
   - Pyramide aus bericht.pyramide, Ebenen von oben nach unten (spaeter, aktuell, weiterfuehrend, grundlagen; nur vorhandene). Die unterste ist 507 pt breit, jede darüber 56 pt schmaler (feste Klassen je Position, keine Breite im Inline-Style). Kopfzeile: Name der Ebene (s3.ebene.*), Klassenangabe (elternbericht:stufe.*, über mehrere Stufen stufe.spanne), Zählung (nur die von null verschiedenen Teile, „ · “).
   - Gruppen je Themenfeld nebeneinander, höchstens vier je Reihe, dann neue Reihe; je Gruppe höchstens sechs Einträge, danach „+n weitere“ in leise. Punkt vor jedem Eintrag in sicher bzw. uebung; jeder Eintrag hat s3.eintragAria als Vorlesetext (Zustand aus elternbericht:zustand.*).
   - Lesehilfe: eine Zeile je vorhandener Ebene, von oben nach unten, mit Mini-Pyramide (so viele Balken wie Ebenen, Breiten von unten 16 / 12,2 / 8,4 / 4,6 pt, der eigene navy, die anderen linie) und Text: spaeter und aktuell mit {klassen}; weiterführend und grundlagen mit {beispiele} = die ersten zwei Themenfelder dieser Ebene, mit „oder“ verbunden (Intl.ListFormat 'de', disjunction), ohne Feld die Fassung ...OhneBeispiel. Dann s3.lesen.nurFuer mit name und wessen (ohne Namen nurFuerOhneName) und s3.lesen.hinweis (bei einer Ebene hinweisEineEbene).
2. Seite 4:
   - Fazit-Kasten: die Elterntexte aus gruppiereFehlbilderNachFamilie(data.fehlbilder), höchstens die ersten zwei, wörtlich, danach s4.fazit.coach. Familienschlüssel nur als React-key (INV-4.3). Ohne Elterntext entfallen Kicker und Kasten, der Rest rückt nach oben.
   - Titel s4.titel.1 bis s4.titel.4 nach der Zahl der Schwerpunkte, s4.reihenfolge ab zwei Schwerpunkten.
   - Je Schwerpunkt: Titel = Themenfeld, Text s4.punkt.sicher (nur wenn es Sicheres gibt) und s4.punkt.uebung. Listen: bis drei Labels mit Intl.ListFormat ('de', conjunction); bei mehr die ersten drei mit Komma verbunden, dann elternbericht:liste.weitere („A, B, C und 2 weitere“). Trennlinie zwischen zwei Schwerpunkten bei max(Titel-Grundlinie + 55,8 pt; letzte Textzeile + 22,8 pt), nächster Titel 23,8 pt darunter. Gibt es mehr als vier Felder mit Übungsbedarf: s4.danach mit bericht.danach unter dem letzten.
   - Kein Schwerpunkt: Titel s4.titelKeiner, darunter der Baustein satz.waehle('fazit', 'keine', sessionId); keine Kurve.
   - Kurve: SVG über der Liste, aria-hidden. Knoten r 6 in der Höhe jedes Titels, keine Nummern darin. Kurvenstücke und Auslauf mit goldener Pfeilspitze nach den Formeln im Maßblatt. Positionen nach dem Layout messen (useLayoutEffect, document.fonts.ready, ResizeObserver), im Druck dieselben. Die Pfadrechnung ist eine reine Funktion (Knoten-y, Lernziel-y oder null → d-Attribute). Ohne Lernziel endet die Kurve am letzten Knoten ohne Auslauf und Spitze; bei einem Schwerpunkt nur der Knoten und gegebenenfalls der Auslauf.
   - Lernziel-Kasten mit notes.zielbild (Zeilenumbrüche erhalten); fehlt es, entfällt der Kasten. Fußnote s4.stand.
   - Farben: Kurve und Knoten navy, Spitze gold, sonst nichts Neues.

## Umfang
src/components/edvance/elternbericht/Seite3.tsx und Seite4.tsx (plus Teile, z. B. Pyramide.tsx, Kurve.tsx, kurve.ts mit Test), src/styles/elternbericht/seite3.css und seite4.css, neue Schlüssel nur unter s3.* und s4.*, Retro. Nicht anfassen: Bogen.tsx, Seite.tsx, rahmen.css, Seite1/2/5, e2e-druck/**, playwright.elternbericht.config.ts, inv4-*.test.ts, src/App.tsx, src/lib/**, src/types/**, ROADMAP. Fehlt etwas: STOPP und melden.

## Tests
Vitest: Pyramide für ilkay (Zahl der Ebenen aus bericht.pyramide, nicht fest), klasse10neu (drei Ebenen), klasse7 (zwei), spaeter (oberste Ebene „Stoff späterer Klassen“); Breitenklassen; Gruppenumbruch nach vier, „+n weitere“ nach sechs; Lesehilfe mit und ohne Beispiel, mit und ohne Namen; Pfadrechnung für 1, 2, 3 und 4 Knoten, mit und ohne Lernziel, Richtung der Spitze; Fazit mit 0, 1 und 3 Elterntexten; Titel je Anzahl; Listen mit drei und fünf Labels; ohne Schwerpunkt mit Baustein. Druck-Tests mit EB_PORT=5184 EB_AUSGABE=docs/report/r7/abnahme/r7-4 für alle Fälle grün. inv4-elternbericht.test.ts grün. Typecheck, Lint, Vitest grün.

## Leitplanken
Worktree ../Edvancev1-r7d auf feat/rasit-report-r7-seiten34 von origin/dev, PR gegen dev, nie main. Designregeln mit der R7-Ausnahme aus CLAUDE.md §11, keine Hex-Werte außerhalb tokens.css. Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz, Schwerpunkt Kurve im Druck. STOPP nach dem PR.

## Melden
PR-Link, PDFs aus docs/report/r7/abnahme/r7-4/ (Seiten 3 und 4) neben dem Muster, Abweichungen mit Grund, offene Punkte (docs/report/r7/offene-punkte-r7-4.md).
```

---

## Abnahme nach R7-4 (Gründer gemeinsam, Texte zusätzlich Lena)

1. Ilkay-Vorschau als PDF neben E7: Kopf und Fuß deckungsgleich; Aufbau, Schrift, Farben und Abstände wie im Muster; Inhalte aus den Daten.
2. Ilkays echte Sitzung (6d868c5f…) unter `/admin/report/<id>?fassung=r7` in Chrome drucken („Als PDF speichern“, Skalierung Standard): fünf Seiten, nichts abgeschnitten, Flächen und Farben da.
3. Zahlen: Seite 1 und 2 nennen dieselben Werte; die Profilzeilen auf Seite 2 ergeben zusammen den Katalog; die Pyramide zeigt dieselben Bereiche wie die Listen auf Seite 1.
4. **Nenner entscheiden** (Entscheidung 4) anhand der Zahlen aus R7-1: „bis Klasse“ behalten oder ändern.
5. **Reihenfolge der Schwerpunkte bestätigen** (Entscheidung 7) am Ergebnis für Ilkay.
6. Pyramide: Ilkay mit zwei Ebenen (Analyse vor dem Katalogausbau), eine neuere Analyse aus Klasse 9 oder 10 mit drei Ebenen, eine aus Klasse 7 oder 8 mit zwei; Klassenangaben stimmen.
7. Fälle ohne Übungsbedarf, ohne Sicheres, ohne Coach-Notizen, ohne Namen: Texte passen, nirgends steht ein leerer Kasten.
8. Lena liest Anhang A gegen und nimmt die sechs Kopfsätze ab. Vor dem ersten Bericht an Eltern nimmt sie außerdem die offenen W5-d-Entwürfe ab (elf Rückbezüge, `fazit.keine.a` und die übrigen aus `docs/report/rueckbezug-texte.md`); sonst steht auf Seite 1 oder 4 noch „tragen“.
9. Danach: Standard von `?fassung` auf r7 umstellen (kleiner PR) und die ROADMAP nachziehen. R6 bleibt über `?fassung=r6` erreichbar.

## Offen, nicht blockierend

- **Logo im Kopf:** Der Bogen nutzt Chevron und Wortmarke aus E6. Ob stattdessen das Pfad-Logo (Kurve mit Kreisen) in den Kopf gehört, entscheiden die Gründer; dann ändert sich nur `Seite.tsx`.
- **Die „1“ auf Seite 1:** Seite 4 zeigt die Knoten ohne Zahlen, der erste Ansatz auf Seite 1 behält die „1“ wie im Muster.
- **Satz zur Bewertungsregel** auf Seite 2 („die Bewertungsregel ist noch nicht abschließend festgelegt“): vor dem ersten echten Elterngespräch prüfen.
- **Nenner und Aufgaben:** Der Katalog zählt alle Skills bis zur Klasse, auch solche, zu denen es noch keine LSA-Aufgabe gibt.
- **Sicher aus einer Aufgabe:** Ein Bereich gilt als sicher, auch wenn die Zweitprobe noch offen war. R6 markiert das in der Suche („nur eine Aufgabe“), E7 nicht. Ob der Bogen es kennzeichnet, entscheiden die Gründer.
- **Schulinterner Lehrplan:** `schul_themenplan` und `students.schule_id` geben die Klasse je Thema an der Schule des Kindes an. Für die Pyramide müsste jeder Skill eindeutig einem Thema zugeordnet sein; das ist er heute nicht. Eigener Auftrag.
- **Reihenfolge durch den Coach:** Heute ergibt sie sich aus der Regel. Eine Übersteuerung bräuchte ein Feld in `lsa_report_notes`.
- **PDF und Mail:** Bericht als PDF ablegen und an die Eltern schicken (Mailweg aus Verträge P4b), Eltern-Zugang, Tablet-Fassung.

---

## Anhang A · Texte (`src/i18n/locales/de/elternbericht.json`)

Wörtlich übernehmen. `{{name}}` ist der Rufname, sonst `kind` („Ihr Kind“); `{{wessen}}` ist `genitiv(name)`. Wo ein Satz mit „Ihr Kind“ grammatisch kippen würde, gibt es eine eigene Fassung `…OhneName`.

```json
{
  "fassung": {
    "zuR7": "Neue Fassung (Druck)",
    "zuR6": "Bisherige Fassung",
    "leer": "Für diese Analyse gibt es keine direkt geprüften Bereiche. Die neue Fassung braucht sie; die bisherige Fassung zeigt, was vorhanden ist.",
    "keinKatalog": "Der Aufgabenkatalog konnte nicht geladen werden. Ohne ihn stimmen die Zahlen im Bericht nicht. Bitte die Seite neu laden."
  },
  "kind": "Ihr Kind",
  "rahmen": {
    "testdaten": "Testdaten",
    "fuss": "edvance  ·  Köln  ·  Lernstandsanalyse {{name}}",
    "fussOhneName": "edvance  ·  Köln  ·  Lernstandsanalyse",
    "seite": "{{seite}} / {{gesamt}}"
  },
  "stufe": {
    "erprobung": "Klasse 5/6",
    "erste": "Klasse 7/8",
    "zweite": "Klasse 9/10",
    "spanne": "Klasse {{von}}–{{bis}}"
  },
  "feld": {
    "brueche": "Brüche & Dezimalzahlen",
    "prozent": "Prozent & Dreisatz",
    "terme": "Terme & Gleichungen",
    "geometrie": "Geometrie",
    "groessen": "Größen",
    "zahlen": "Zahlen & Rechnen",
    "funktionen": "Funktionen",
    "zufall": "Daten & Zufall",
    "weitere": "Weitere Bereiche"
  },
  "zustand": {
    "sicher": "sicher",
    "uebung": "Übungsbedarf"
  },
  "liste": {
    "weitere_one": "{{liste}} und ein weiterer",
    "weitere_other": "{{liste}} und {{count}} weitere"
  },
  "s1": {
    "kicker": "Lernstandsanalyse {{fach}}",
    "kopfErsatz": "Was wir bei {{name}} gesehen haben",
    "kopfErsatzOhneName": "Was wir bei Ihrem Kind gesehen haben",
    "meta": {
      "klasse": "Klasse",
      "fach": "Fach",
      "umfang": "Umfang",
      "datum": "Datum",
      "klasseSchulform": "{{klasse}}, {{schulform}}",
      "aufgaben_one": "{{count}} Aufgabe",
      "aufgaben_other": "{{count}} Aufgaben"
    },
    "blick": {
      "kicker": "Auf einen Blick",
      "zeile": "{{untersucht}} von {{katalog}} Bereichen untersucht  ·  {{sicher}} sicher  ·  {{uebung}} Übungsbedarf  ·  {{offen}} nicht untersucht",
      "sicher": "Das klappte bereits",
      "uebung": "Hier braucht es noch Übung",
      "ansatz": "Unser erster Ansatz",
      "weitere": "+{{count}} weitere",
      "keinSicher": "Noch kein Bereich sicher.",
      "keineUebung": "Kein Bereich mit Übungsbedarf.",
      "ansatzGemischt": "Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.",
      "ansatzUebung": "In diesem Themenfeld war noch nichts sicher. Hier setzen wir zuerst an.",
      "ansatzKeiner": "In den untersuchten Bereichen gibt es keinen Übungsbedarf. Wir arbeiten am aktuellen Stoff weiter."
    },
    "anliegen": {
      "kicker": "Ihr Anliegen",
      "genannt": "Sie machen sich Sorgen um {{wessen}} {{punkte}}.",
      "genanntOhneName_one": "Sie sind zu uns gekommen, weil Sie {{punkte}} als Schwierigkeit sehen.",
      "genanntOhneName_other": "Sie sind zu uns gekommen, weil Sie {{punkte}} als Schwierigkeiten sehen.",
      "thema": "Als nächstes Thema steht {{thema}} an."
    },
    "geprueft": {
      "kicker": "So haben wir geprüft",
      "text": "Je nach Antwort hat das System die nächste Aufgabe gewählt. So wurden {{untersucht}} von {{katalog}} Bereichen des Katalogs bis Klasse {{klasse}} untersucht.",
      "hinweis_one": "Über den nicht untersuchten Bereich enthält dieser Bericht keine Aussage. Mehr dazu auf Seite 2.",
      "hinweis_other": "Über die {{count}} nicht untersuchten Bereiche enthält dieser Bericht keine Aussage. Mehr dazu auf Seite 2."
    },
    "weg": {
      "kicker": "Ihr Weg durch diesen Bericht",
      "hier": "Sie sind hier",
      "station": {
        "1": "Überblick",
        "2": "Lernstand",
        "3": "Einordnung",
        "4": "Lernplan",
        "5": "Nächste Schritte"
      }
    }
  },
  "s2": {
    "kicker": "Lernstand im Überblick",
    "titel": "{{wessen}} Lernstand in den untersuchten Bereichen.",
    "titelOhneName": "Der Lernstand in den untersuchten Bereichen.",
    "intro": "Untersucht: {{untersucht}} von {{katalog}} Bereichen des Katalogs. Davon {{sicher}} sicher, {{uebung}} mit Übungsbedarf.",
    "introOffen_one": "Ein Bereich wurde nicht untersucht.",
    "introOffen_other": "{{count}} Bereiche wurden nicht untersucht.",
    "zahl": {
      "sicher": "sicher eingestuft",
      "uebung": "Übungsbedarf",
      "offen": "nicht untersucht"
    },
    "profil": {
      "titel": "{{wessen}} Kompetenzprofil",
      "titelOhneName": "Kompetenzprofil",
      "hinweis": "Jedes Segment steht für eine Kompetenz",
      "untersucht": "{{untersucht}} von {{vorhanden}} untersucht",
      "sicher": "{{count}} sicher",
      "uebung": "{{count}} Übungsbedarf",
      "aria": "{{feld}}: {{untersucht}} von {{vorhanden}} untersucht, davon {{sicher}} sicher und {{uebung}} mit Übungsbedarf.",
      "legende": {
        "sicher": "Sicher",
        "uebung": "Übungsbedarf",
        "offen": "Nicht untersucht"
      }
    },
    "deutung": {
      "kicker": "Was die Grafik zeigt",
      "sicher_one": "Überwiegend sicher war das Themenfeld {{felder}}.",
      "sicher_other": "Überwiegend sicher waren die Themenfelder {{felder}}.",
      "uebung_one": "Den meisten Übungsbedarf zeigte das Themenfeld {{felder}}.",
      "uebung_other": "Den meisten Übungsbedarf zeigten die Themenfelder {{felder}}.",
      "coach": "Ob dahinter ein gemeinsames Muster liegt, prüft der Coach in den ersten Sitzungen."
    },
    "fussnote": "Die Streifen zeigen die Verteilung der Katalogbereiche, keine Note und keinen Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. Schraffierte Bereiche wurden nicht untersucht und sagen nichts über {{name}} aus."
  },
  "s3": {
    "kicker": "Einordnung im Lernstoff",
    "titel": "Auf vorhandenen Stärken aufbauen.",
    "titelOhneSicher": "Wo wir ansetzen.",
    "intro": "Jeder untersuchte Bereich steht dort, wo er im Lernstoff liegt: unten die Grundlagen aus früheren Klassen, darüber der weiterführende Stoff, oben der aktuelle Stoff. So sehen Sie, wo es gut läuft und wo noch nicht.",
    "introKurz": "Jeder untersuchte Bereich steht dort, wo er im Lernstoff liegt. So sehen Sie, wo es gut läuft und wo noch nicht.",
    "zwischenzeile": "Wo die untersuchten Bereiche im Lernstoff liegen",
    "legende": {
      "sicher": "sicher",
      "uebung": "Übungsbedarf"
    },
    "ebene": {
      "spaeter": "Stoff späterer Klassen",
      "aktuell": "Aktueller Unterrichtsstoff",
      "weiterfuehrend": "Weiterführende Themen",
      "grundlagen": "Grundlagen"
    },
    "zaehlung": {
      "sicher": "{{count}} sicher",
      "uebung": "{{count}} Übungsbedarf"
    },
    "weitere": "+{{count}} weitere",
    "eintragAria": "{{label}}: {{zustand}}",
    "lesen": {
      "kicker": "So lesen Sie die Pyramide",
      "spaeter": "was laut Lehrplan erst in {{klassen}} kommt.",
      "aktuell": "was laut Lehrplan in {{klassen}} dran ist.",
      "weiterfuehrend": "der Stoff nach den Grundlagen, zum Beispiel {{beispiele}}.",
      "weiterfuehrendOhneBeispiel": "der Stoff nach den Grundlagen.",
      "grundlagen": "Stoff aus früheren Klassenstufen, zum Beispiel {{beispiele}}.",
      "grundlagenOhneBeispiel": "Stoff aus früheren Klassenstufen.",
      "nurFuer": "Die Pyramide gilt nur für {{name}}. Was oben steht, richtet sich nach {{wessen}} Klasse; was darunter liegt, nach dem NRW-Lehrplan, an dem sich unser Katalog orientiert. Bei einem anderen Kind sieht sie anders aus.",
      "nurFuerOhneName": "Die Pyramide gilt nur für Ihr Kind. Was oben steht, richtet sich nach der Klasse Ihres Kindes; was darunter liegt, nach dem NRW-Lehrplan, an dem sich unser Katalog orientiert. Bei einem anderen Kind sieht sie anders aus.",
      "hinweis": "Die Pyramide zeigt, wo ein Bereich im Lernstoff liegt, keine feste Voraussetzung. Ob Übungsbedarf weiter unten etwas weiter oben erklärt, prüft der Coach im Unterricht.",
      "hinweisEineEbene": "Die Pyramide zeigt, wo ein Bereich im Lernstoff liegt, keine feste Voraussetzung."
    }
  },
  "s4": {
    "fazit": {
      "kicker": "Unser Fazit",
      "coach": "Der Coach prüft in den ersten Sitzungen, ob sich das bestätigt."
    },
    "titel": {
      "1": "Ein Schwerpunkt.",
      "2": "Zwei Schwerpunkte, in dieser Reihenfolge.",
      "3": "Drei Schwerpunkte, in dieser Reihenfolge.",
      "4": "Vier Schwerpunkte, in dieser Reihenfolge."
    },
    "titelKeiner": "Kein Übungsbedarf in den untersuchten Bereichen.",
    "reihenfolge": "In dieser Reihenfolge beginnen wir. Die Reihenfolge ist eine Planung, keine Aussage darüber, dass ein Thema das andere voraussetzt.",
    "punkt": {
      "sicher": "Sicher: {{liste}}.",
      "uebung": "Noch nicht sicher: {{liste}}."
    },
    "danach": "Danach nehmen wir {{liste}} dazu.",
    "lernziel": "Unser gemeinsames Lernziel",
    "stand": "Das ist der Stand nach dieser Analyse. Der Coach überprüft ihn in den ersten Sitzungen und passt den Plan an, wenn nötig."
  },
  "s5": {
    "kicker": "Wie es weitergeht",
    "titel": "Unsere Einschätzung für {{name}}.",
    "intro": "Der Bericht endet nicht mit einer Zahl, sondern mit einem Vorschlag. Was er bedeutet und ob er passt, besprechen wir mit Ihnen.",
    "vorschlag": {
      "chip": "Vorschlag",
      "titel": "Welcher Rhythmus zu {{name}} passt, legen wir gemeinsam im Gespräch fest.",
      "titelOhneName": "Welcher Rhythmus passt, legen wir gemeinsam im Gespräch fest.",
      "zeile": "Vorschlag des Coachs: {{paket}}, {{merkmal}}.",
      "zeileOhneMerkmal": "Vorschlag des Coachs: {{paket}}."
    },
    "pakete": {
      "kicker": "Unsere Mitgliedschaften",
      "karte": "Mitgliedschaft",
      "vorschlag": "Coach-Vorschlag",
      "konditionen": "Konditionen im Gespräch",
      "hinweis": "Preise, Laufzeiten und Konditionen besprechen wir persönlich. Dieser Bericht enthält keine Vertragsangaben."
    },
    "kontakt": {
      "kicker": "Ihr persönlicher Ansprechpartner",
      "rolle": "hat die Analyse begleitet",
      "team": "Das Edvance-Team",
      "mail": "hello@edvanceacademy.de"
    },
    "fragen": {
      "kicker": "Fragen oder Entscheidung",
      "text": "Sie können sich direkt entscheiden oder sich später mit Fragen melden. Wir antworten persönlich, ohne Termin und ohne Frist."
    }
  }
}
```

## Anhang B · Kopfsätze (`report_bausteine`, Slot `kopf`, als Entwurf)

Fall aus `kopfFall`: `gemischt` = es gibt Sicheres und Übungsbedarf, `sicher` = kein Übungsbedarf, `uebung` = nichts sicher. `{name}` ist der Rufname, sonst „Ihr Kind“; alle Sätze sind so gebaut, dass beides passt, und keiner nutzt ein „es“, das man auf das Kind beziehen könnte. Die Sätze sagen bewusst nicht „weiterführende Rechenschritte“ wie das Muster: Ob der Übungsbedarf über den Grundlagen liegt, hängt vom Kind ab.

| schluessel | fall | variante | text |
|---|---|---|---|
| kopf.gemischt.a | gemischt | a | {name} zeigt sichere Ansätze. Bei einigen Rechenschritten ist noch Übung nötig. |
| kopf.gemischt.b | gemischt | b | {name} löst vieles schon sicher. An einigen Stellen ist noch Übung nötig. |
| kopf.sicher.a | sicher | a | {name} war in den untersuchten Bereichen sicher. |
| kopf.sicher.b | sicher | b | In allen untersuchten Bereichen war {name} sicher. |
| kopf.uebung.a | uebung | a | In den untersuchten Bereichen braucht {name} noch Übung. |
| kopf.uebung.b | uebung | b | {name} braucht in den untersuchten Bereichen noch Übung. Genau dort setzen wir an. |
