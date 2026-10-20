# Bauauftrag W1–W4 · Slots: ein Wochenplan, Stammplatz am Raum

Stand 18.10.2026 · Grundlage: Gründer-Gespräch Rasit/Tolunay vom 18.10.2026 und Klick-Dummy `claude/slots-dummy-v2.html` · Code-Stand `Edvancev1` dev @ `22e23c3` (S1–S3 gemergt).

**Vor dem Start (Rasit):** Den Dummy aus dem Projekt herunterladen und unter `docs/slots/slots-dummy-v2.html` ins Repo legen (eigener kleiner PR oder im W1-PR). Alle vier Prompts verweisen darauf.

| Paket | Worktree · Branch | Inhalt | wartet auf |
|---|---|---|---|
| W1 Foundation | `../Edvancev1-w1` · `feat/rasit-slots-w1-raum` | Stammplatz bekommt einen Raum, Planung je Raum, neue und erweiterte Funktionen | – |
| W2 Wochenplan | `../Edvancev1-w2` · `feat/rasit-slots-w2-wochenplan` | Raster, Kennzahlen, Slot- und Tagespanel, Stundenplan geht im Wochenplan auf | W1 eingespielt |
| W3 Kinder | `../Edvancev1-w3` · `feat/rasit-slots-w3-kinder` | Kinderliste mit Raum und Coach, Stammplatz-Dialog mit Raum und Vorschau | W1 eingespielt |
| W4 Coaches | `../Edvancev1-w4` · `feat/rasit-slots-w4-coaches` | Schichten als Block, Raum einer Schicht ändern | W1 eingespielt |

W2, W3 und W4 laufen parallel (drei Agenten). Jedes Paket legt seine i18n-Schlüssel unter einem eigenen Präfix in `de/slots.json` an (`wochenplan2.*`, `kinder2.*`, `coaches2.*`), damit die PRs nicht kollidieren.

**Nicht in diesem Auftrag:** S4 (Raum zählt für die Planung auch ohne Coach, fehlender Coach nur als Warnung). Bis zur Freigabe durch Tolunay gilt weiter: Ein Raum zählt nur mit Coach. Der Dummy zeigt bei „Stammplatz in Raum ohne Coach“ bereits die Warnung aus S4; im Bau bleibt dort vorerst die Sperre SL002.

---

## Entscheidungen aus dem Gespräch (gelten für alle Pakete)

1. **Der Reiter Stundenplan entfällt.** Der Wochenplan ist die eine Planungsfläche. Einzel- und Sofort-Sessions stehen dort in einer eigenen Zeile „Einzel“ und im Tagespanel an ihrer Uhrzeit. `/admin/slots?reiter=stundenplan` und `/admin/schedule` leiten auf den Wochenplan.
2. **Klick auf eine Zelle (Tag + Uhrzeit) öffnet das Slot-Panel** mit allen Räumen dieser Stunde: Coach, Kinder, Absagen, Session öffnen bzw. Live-Sicht. Es ersetzt die Termin-Seite.
3. **Klick auf den Tag öffnet das Tagespanel:** alle Stunden des Tages mit Räumen, Coach und freien Plätzen je Stunde, dazu die Einzel-Sessions. Zweck: am Telefon sofort sagen können, wo etwas frei ist.
4. **Farbe je Raum nach Belegung:** 1–2 Kinder rot, 3 gelb, 4–5 grün, 0 grau. Ein Raum mit Kindern, aber ohne Coach, ist rot gefüllt mit dem Text „kein Coach“. Rot heißt hier „schwach belegt“, nicht „Fehler“.
5. **„+ Kind“ steht an jedem Raum.** Das Kind landet im gewählten Raum, nicht im ersten freien. Beim Hinzufügen wählt der Admin „Nur an diesem Termin“ (Zusatztermin) oder „Jede Woche“ (Stammplatz ab diesem Termin).
6. **Ein Stammplatz hängt an Tag, Uhrzeit und Raum.** Der Coach ergibt sich aus der Schicht des Raums. Wechselt ein Coach den Raum oder springt ein anderer Coach ein, bleiben die Kinder im Raum. Verschoben wird von Hand.
7. **Kennzahlen zählen Testkonten sichtbar mit**, statt sie still herauszurechnen: „Belegt 73 · 67 Kinder · 6 Testkonten“, „Ohne Stammplatz 2 · dazu 4 Testkonten“.
8. **Schichten werden als Block gepflegt:** „Mo 14–18 Uhr, Raum A1“ ist ein Eintrag. In der Datenbank bleibt es eine Zeile je Stunde.
9. **Uhrzeiten und Pausen** zwischen den Slots bleiben offen und sind unter Einstellungen änderbar wie heute.

---

## W1 · Foundation

```
Du arbeitest im Repo Edvancev1 (WSL). Paket W1: Stammplatz am Raum und die Funktionen für den neuen Wochenplan.

## Ziel
Ein Stammplatz hat künftig einen Raum. Termine aus einem Stammplatz entstehen fest in diesem Raum (kind_termine.raum_id + raum_fest = true), die Kapazität wird je Raum geprüft (5 Plätze, Raum nur mit Coach offen). Dazu kommen die Lesefunktionen und Schreibwege, die W2–W4 brauchen. Referenz für das Verhalten: docs/slots/slots-dummy-v2.html (Beispieldaten, kein Code zum Übernehmen).

## Entscheidungen (nicht neu verhandeln)
1. stammplaetze bekommt raum_id uuid null references raeume(id). Bestehende Zeilen behalten null (in Prod nur Testdaten): null bedeutet „System verteilt wie bisher“. Jeder neue oder geänderte Stammplatz braucht einen Raum (Abbruch 22023 hint 'raum_fehlt').
2. Planung (termine_planen / slots_plan_rechnen und alle Stellen, die Stammplatz-Termine anlegen): Hat der Stammplatz einen Raum, entsteht der Termin mit raum_id = Stammplatz-Raum und raum_fest = true. Ein solcher Termin entsteht nur, wenn der Raum an dem Tag offen ist (Coach eingeteilt, slot_raeume.offen) und dort weniger als 5 Kinder planned/present sitzen; sonst 'uebersprungen' wie bisher. Stammplätze ohne Raum: Verhalten unverändert. slot_zuteilung berücksichtigt raum_fest schon; prüfe, dass ein fester Termin in einem vollen oder geschlossenen Raum sauber als „ohne Raum“ erscheint und nicht still woanders landet.
3. stammplatz_vergeben: jede Zeile in p_zeilen bekommt den Schlüssel raum_id (Pflicht). Die Prüfung (slots_stammplatz_gruende) prüft je Raum: SL002 heißt jetzt „dieser Raum hat zu der Zeit keinen Coach“, SL001 „dieser Raum ist voll“. Signatur bleibt.
4. stammplatz_aendern und zusatztermin_buchen bekommen am Ende einen optionalen Parameter p_raum_id uuid default null. Alte Fassung per DROP ersetzen, nicht überladen (Muster vertrag_starten in V5), Grants danach wie vorher. zusatztermin_buchen mit Raum: setzt raum_id + raum_fest, prüft den Raum (offen, < 5). Ohne Raum: wie bisher.
5. Neue Lesefunktion stammplatz_vorschau(p_student_id, p_wochentag, p_slot_zeit_id, p_raum_id, p_takt, p_ab) → die nächsten sechs Wochen ab p_ab an diesem Wochentag, je Zeile: datum, ergebnis ('termin' | 'ferien' | 'feiertag' | 'andere_woche' | 'voll' | 'ohne_coach' | 'ohne_budget'), anlass (Ferien-/Feiertagsname), belegt (Kinder im Raum ohne dieses Kind), coach_id, coach_name. Ersetzt in der Oberfläche die Meldung „übersprungen, weil voll oder ohne Raum“ durch einen Grund je Datum.
6. Neue Lesefunktion slots_kandidaten_alle(p_datum, p_zeit_id, p_raum_id) → alle Kinder mit Vertrag oder Testkonto (nicht is_provisional): student_id, name, klasse, fach, ist_test, stammplatz_kurz (Text oder null), code (null = buchbar, sonst SL-Code oder 'kein_vertrag' / 'vertrag_ab' mit datum). Gleiche Regeln wie slots_zusatz_code, nur mit Grund statt Filter. Die bestehende slots_kandidaten bleibt.
7. slots_woche erweitern, ohne Felder zu entfernen:
   - kopf: belegt_test, ohne_stammplatz_test, auslastung_mit_test, raeume_ohne_coach (Räume mit Kindern ohne Coach in der Woche).
   - zellen[].raeume[]: coach_name; Räume mit Kindern, aber ohne Coach, stehen mit offen = false und belegt > 0 in der Liste.
8. Neue Schreibfunktion stammschicht_block_anlegen(p_coach_id, p_wochentag, p_von_zeit_id, p_bis_zeit_id, p_raum_id, p_gueltig_ab default null) → legt je aktiver Uhrzeit von–bis eine Stammschicht an, alles oder nichts (SL009 bei Konflikt mit Raum oder Coach, hint mit Uhrzeit).
9. Neue Schreibfunktion stammschicht_raum_wechseln(p_ids uuid[], p_raum_id, p_ab, p_kinder_mitnehmen boolean) → beendet die Schichten zum Tag vor p_ab und legt sie im neuen Raum ab p_ab neu an. Mit p_kinder_mitnehmen = true werden die Stammplätze im alten Raum zu genau diesen Zeiten genauso beendet und im neuen Raum neu angelegt (Vorgänger-Kette wie stammplatz_aendern). Ohne bleiben sie im alten Raum. Danach termine_planen für alle betroffenen Kinder.
10. Alles Admin-only (slots_admin_pruefen), SECURITY DEFINER, search_path = public, pg_temp, EXECUTE nur authenticated. Bestehende Trigger und die Testkonto-Regel SL013 bleiben unverändert.

## Umfang
A. Migration(en) nach supabase/migrations/ (Version per date -u, per ls und dbread frei geprüft).
B. src/lib/supabase/slotplan.ts und src/types/slotplan.ts: Wrapper und Typen für 3–9. src/lib/slots/fehler.ts um die neuen hints ('raum_fehlt') ergänzen.
C. docs/api/DATENVERTRAG.md Abschnitt 10 ergänzen, Roadmap, Retro, offene Punkte in docs/slots/offene-punkte-w1.md.

## Tests
- pgTAP slots_w1.test.sql: Stammplatz mit Raum erzeugt feste Termine im Raum; voller Raum → übersprungen, auch wenn der Nachbarraum frei ist; Raum ohne Coach → SL002; Stammplatz ohne Raum verhält sich wie vorher (bestehende slots_*-Tests grün); zusatztermin_buchen mit und ohne Raum; stammplatz_vorschau liefert je Grund mindestens einen Fall (Herbstferien, Allerheiligen, B-Woche bei A-Takt, voll, ohne Coach, ohne Budget); slots_kandidaten_alle gibt jedem Kind genau einen Code und null genau dann, wenn zusatztermin_buchen gelingt; Block anlegen alles oder nichts; Raumwechsel mit und ohne Kinder; Rechte (Coach → 42501).
- Volle Suite in einer Wegwerf-DB wie in der CI, bekannt-rot.txt beachten. Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-w1 auf feat/rasit-slots-w1-raum von origin/dev. PR gegen dev, nie main. ALLOW_MIGRATIONS=1.
- Kein DDL gegen Prod, Prod nur über dbread. Vor jeder Spalten-Migration alle Funktionen per pg_proc auf die Spalte scannen.
- Bestehende Funktionen: Signatur, SECURITY, search_path und Grants nur dort ändern, wo der Auftrag es verlangt; Diff je Funktion in den PR.
- Zweitprüfung durch eine frische Instanz vor dem PR, Schwerpunkt Planung je Raum und Einheiten.
- STOPP nach dem PR. Eingespielt wird erst nach „W1 einspielen“, dann nach CLAUDE.md §10 mit dbread-Kontrolle und Schema-Abzug.

## Melden
PR-Link, was je Entscheidung gebaut ist, Liste der geänderten Funktionen mit Grund, Abweichungen, offene Punkte.
```

---

## W2 · Wochenplan, Slot-Panel, Tagespanel

```
Du arbeitest im Repo Edvancev1 (WSL). Paket W2: Der Wochenplan wird die eine Planungsfläche. Voraussetzung: W1 gemergt und eingespielt (per dbread prüfen: stammplaetze.raum_id, slots_kandidaten_alle, stammplatz_vorschau, erweitertes slots_woche; sonst STOPP).

## Ziel
Admins planen und steuern den Betrieb aus dem Wochenplan heraus. Der Reiter Stundenplan und die Termin-Seite gehen darin auf. Verbindliche Vorlage für Aufbau, Texte und Verhalten: docs/slots/slots-dummy-v2.html (Reiter Wochenplan, Slot-Panel, Tagespanel, Dialog „Kind in Raum“). Daten und Logik kommen aus den Slot-Funktionen, nicht aus dem Dummy.

## Entscheidungen (nicht neu verhandeln)
1. Reiter: Wochenplan · Kinder · Coaches · Einstellungen. 'stundenplan' fällt aus REITER; ?reiter=stundenplan und /admin/schedule leiten auf den Wochenplan (Woche aus der URL bleibt).
2. Kopf über dem Raster: fünf Kennzahlen wie im Dummy (Plätze in besetzten Räumen · Belegt mit „x Kinder · y Testkonten“ · Auslastung mit Zeile „ohne Testkonten z %“ · Räume mit Kindern ohne Coach · Ohne Stammplatz mit „dazu n Testkonten“). Rot nur, wenn der Wert > 0 und ein Handeln nötig ist. Daneben „A-Woche (ungerade KW)“ bzw. „B-Woche“.
3. Raster: je Zelle eine Zeile pro Raum mit Coach oder Kindern: Raumname, fünf Punkte, „n/5“ bzw. „kein Coach“. Farbe nach Entscheidung 4 des Bauauftrags. Unten in der Zelle „x frei“, bei laufender Session „läuft gerade“. Vergangene Zellen gedämpft. Ohne Raum: „kein Raum besetzt“. Tage ohne Betrieb als eine Fläche mit Anlass.
4. Unterste Zeile „Einzel“: Einzel- und Sofort-Sessions des Tages aus stundenplan_woche (Uhrzeit, Raum, Leitung, Kennzeichen Testlauf). Klick öffnet das Session-Panel mit Kindern zuweisen und Testlauf-Schalter (SessionKarte aus dem bisherigen Stundenplan wiederverwenden).
5. Tageskopf ist ein Knopf und öffnet das Tagespanel: je Stunde die Räume (Punkte, Coach, n/5), groß die Zahl freier Plätze, Knopf „Öffnen“ ins Slot-Panel; Einzel-Sessions an ihrer Uhrzeit; unten „+ Einzel-Session an diesem Tag planen“ (SessionPlanen aus dem Stundenplan, Datum vorbelegt).
6. Slot-Panel (Seitenpanel rechts, auf dem Telefon volle Breite), URL ?slot=YYYY-MM-DD_<zeit_id> bzw. ?tag=YYYY-MM-DD, Zurück schließt es. /admin/slots/termin/:datum/:zeitId leitet auf ?slot=… um. Inhalt aus slots_termin, alle Aktionen der bisherigen Termin-Seite bleiben (Coach je Raum für diesen Termin, Raum öffnen, Absage, Umbuchen, Raum je Kind, Nicht dabei, Termin fällt aus). Neu je Raum:
   - „+ Kind in <Raum>“ (gesperrt mit Grund bei 5/5),
   - rechts Session öffnen / Live-Sicht / Rückblick nach der Logik betriebAktion aus src/pages/admin/heute/betriebModel.ts (dorthin importieren, nicht kopieren; leerer Raum: kein „Session öffnen“).
   - bei laufender Session je Kind ein Link „Live“ in die Live-Sicht des Raums.
7. Dialog „Kind in <Raum>“: Umschalter „Nur an diesem Termin“ / „Jede Woche (Stammplatz)“, Suchfeld, Liste aus slots_kandidaten_alle mit allen Kindern; nicht buchbare ausgegraut mit Grund als Satz (über fehler.ts / slots.json, nie Rohtext). Einmalig → zusatztermin_buchen mit p_raum_id. Jede Woche → stammplatz_vergeben mit einer Zeile (Wochentag und Uhrzeit des Slots, Raum, Takt wöchentlich, gültig ab Termindatum).
8. Der Knopf „Session jetzt starten“ im Kopf bleibt.

## Umfang
src/pages/admin/slots/wochenplan/** (Raster, Zelle, Kopf), neue Panels unter src/pages/admin/slots/panel/ (SlotPanel, TagPanel, EinzelPanel, KindInRaumDialog), Inhalte aus termin/TerminKarten.tsx und stundenplan/* dorthin ziehen; TerminPage und StundenplanReiter entfernen, sobald nichts mehr darauf verweist. SlotsPage.tsx, slots.model.ts, App.tsx (Umleitungen). Texte in de/slots.json unter wochenplan2.*. Keine Änderung an src/lib/supabase/** außer Imports; fehlt dort etwas: STOPP und melden.

## Tests
Vitest: Farbe je Belegung (0, 1, 2, 3, 4, 5, Kinder ohne Coach); Kennzahlen mit Testkonten; Umleitungen (stundenplan, schedule, termin-Route); Panel über URL öffnen und mit Zurück schließen; „+ Kind“ ruft je Modus die richtige Funktion mit dem richtigen Raum; gesperrte Kinder zeigen ihren Satz; voller Raum sperrt „+ Kind“ mit Grund; Live-Link nur bei laufender Session. Bestehende Tests anpassen statt löschen, wo der Inhalt weiter gilt. Typecheck, Lint, Vitest grün. Bildschirmfotos (Fake-Client wie H3) von Wochenplan, Slot-Panel, Tagespanel und Dialog in den PR.

## Leitplanken
- Worktree ../Edvancev1-w2 auf feat/rasit-slots-w2-wochenplan von origin/dev. PR gegen dev, nie main.
- Designregeln CLAUDE.md §11: Tokens, EdvanceCard, EmptyState, LoadingPulse; ein primärer CTA je Bildschirm; Touch-Ziele ≥ 44 px; keine Hex-Werte, keine Inline-Styles außer berechneten Werten. Dateien ≤ 400 Zeilen. Raster seitlich scrollbar auf schmalen Breiten, die Seite selbst nie.
- Zweitprüfung durch eine frische Instanz vor dem PR. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfotos, was je Entscheidung gebaut ist, Abweichungen vom Dummy mit Grund, offene Punkte (docs/slots/offene-punkte-w2.md).
```

---

## W3 · Kinder und Stammplatz-Dialog

```
Du arbeitest im Repo Edvancev1 (WSL). Paket W3: Kinderliste und Stammplatz-Dialog mit Raum. Voraussetzung: W1 gemergt und eingespielt (per dbread prüfen; sonst STOPP).

## Ziel
Beim Vergeben oder Ändern eines Stammplatzes wählt der Admin Tag, Uhrzeit, Takt, gültig ab und den Raum; er sieht den Coach aus der Schicht und für die nächsten sechs Wochen, ob und warum ein Termin entsteht. Vorlage: docs/slots/slots-dummy-v2.html, Reiter Kinder und Dialog „Stammplatz vergeben“.

## Entscheidungen (nicht neu verhandeln)
1. Kinderliste: Spalten Kind (mit Kennzeichen Test) · Paket · Stammplatz („Mo 14:00 · A1“, bei 14-täglich „(A-Woche)“) · Coach (aus der Schicht; ohne Schicht Kennzeichen „keine Schicht“) · Planbilanz · Aktion. Stammplätze ohne Raum (Altbestand) zeigen „Raum: automatisch“ und die Aktion „Raum festlegen“.
2. Filter: Alle · Ohne Stammplatz · Testkonten zeigen (an/aus, Standard an). Kinder ohne Stammplatz stehen oben.
3. Dialog: Wochentag, Uhrzeit, Takt (jede Woche / 14-täglich A-Woche / 14-täglich B-Woche), gültig ab. Darunter je aktivem Raum eine Karte: Raumname, Coach der Schicht oder „kein Coach eingeteilt“, „n von 5 frei“ am ersten Termin. Volle Räume und Räume ohne Coach sind nicht wählbar und sagen warum (S4 ist nicht freigegeben).
4. Bei 14-täglich steht „A-Woche = ungerade KW, B-Woche = gerade. KW xx ist eine A-Woche.“ unter den Feldern.
5. „Die nächsten Termine“ aus stammplatz_vorschau, je Zeile Datum, Kennzeichen (geplant / entfällt / kein Betrieb / andere Woche) und Grund in einem Satz. Die bisherige Planbilanz-Vorschau (slots_planbilanz_vorschau) bleibt darunter.
6. Speichern über stammplatz_vergeben (neu) bzw. stammplatz_aendern mit p_raum_id (ändern ab Datum, Vorgänger-Kette wie bisher). Fehler als Satz, nie Rohtext.
7. Die Kind-Seite (/admin/slots/kind/:studentId) zeigt Raum und Coach je Stammplatz und nutzt denselben Dialog.

## Umfang
src/pages/admin/slots/kinder/**, src/pages/admin/slots/dialoge/StammplatzDialog.tsx (plus Unterteile, falls > 400 Zeilen), src/pages/admin/slots/kind/**. Texte unter kinder2.* in de/slots.json. Keine Änderung an src/lib/supabase/**; fehlt dort etwas: STOPP und melden.

## Tests
Vitest: Liste zeigt Raum und Coach, „keine Schicht“, „Raum: automatisch“; Filter; Raum-Karten gesperrt bei voll und ohne Coach mit Grund; Vorschau zeigt jeden Grund als Satz; Speichern übergibt raum_id; A/B-Hinweis mit richtiger KW. Typecheck, Lint, Vitest grün. Bildschirmfotos von Liste und Dialog.

## Leitplanken
Worktree ../Edvancev1-w3 auf feat/rasit-slots-w3-kinder von origin/dev, PR gegen dev. Designregeln CLAUDE.md §11, Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfotos, Abweichungen vom Dummy mit Grund, offene Punkte (docs/slots/offene-punkte-w3.md).
```

---

## W4 · Coaches: Schichten als Block

```
Du arbeitest im Repo Edvancev1 (WSL). Paket W4: Schichten im Reiter Coaches als Blöcke. Voraussetzung: W1 gemergt und eingespielt (per dbread prüfen: stammschicht_block_anlegen, stammschicht_raum_wechseln; sonst STOPP).

## Ziel
„Coach hat Montag Raum A1 von 14 bis 18 Uhr“ ist ein Eintrag. Wechselt ein Coach den Raum, entscheidet der Admin, ob die Kinder mitziehen. Vorlage: docs/slots/slots-dummy-v2.html, Reiter Coaches.

## Entscheidungen (nicht neu verhandeln)
1. Je Coach eine Karte: Name, Stunden pro Woche, darunter die Blöcke. Ein Block = aufeinanderfolgende Stammschichten desselben Coaches am selben Wochentag im selben Raum. Je Block: „Mo 14:00–18:00“, Raum, Zahl der Kinder mit Stammplatz in diesem Raum zu diesen Zeiten, Aktionen „Raum ändern“ und „Entfernen“.
2. „Schicht eintragen“: Coach, Wochentag, Raum, von, bis → stammschicht_block_anlegen. Konflikte als Satz mit Uhrzeit („Raum B1 ist Do 16:00 schon mit … besetzt“).
3. „Raum ändern“: neuer Raum, gültig ab (Standard: nächster Montag), Kästchen „n Kinder mit in Raum X nehmen“, Standard aus. Darüber der Satz „Kinder hängen am Raum, nicht am Coach. Ohne Häkchen bleiben die n Kinder in Raum Y.“ Ist der Zielraum zu einer der Zeiten besetzt: gesperrt mit Grund. → stammschicht_raum_wechseln.
4. „Entfernen“: Bestätigung im Dialog (kein confirm()), Satz: „Raum Y hat zu diesen Zeiten dann keinen Coach. Kinder mit Stammplatz dort bleiben eingeplant und erscheinen im Wochenplan als ‚kein Coach‘.“ → stammschicht_beenden je Zeile ab dem gewählten Datum.
5. Abweichungen für einzelne Termine (Vertretung, fällt aus) bleiben im Slot-Panel (W2), nicht hier.

## Umfang
src/pages/admin/slots/coaches/** (Blockbildung als reine Funktion in einer model-Datei, testbar). Texte unter coaches2.* in de/slots.json. Keine Änderung an src/lib/supabase/**; fehlt etwas: STOPP und melden.

## Tests
Vitest: Blockbildung (Lücke trennt Blöcke, anderer Raum trennt Blöcke); Block anlegen ruft die Funktion mit von/bis; Konfliktsatz; Raum ändern mit und ohne Kinder; gesperrter Zielraum mit Grund; Entfernen über Dialog. Typecheck, Lint, Vitest grün. Ein Bildschirmfoto.

## Leitplanken
Worktree ../Edvancev1-w4 auf feat/rasit-slots-w4-coaches von origin/dev, PR gegen dev. Designregeln CLAUDE.md §11, Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfoto, Abweichungen vom Dummy mit Grund, offene Punkte (docs/slots/offene-punkte-w4.md).
```

---

## Abnahme nach W2–W4 (Gründer, gemeinsam)

1. Wochenplan KW 45: Jede Zelle zeigt die Räume in der richtigen Farbe; Kennzahlen nennen Kinder und Testkonten getrennt.
2. Klick auf Mo 15:00 öffnet das Slot-Panel; „+ Kind in B1“ setzt das Kind in B1, nicht in A1.
3. „Jede Woche“ im selben Dialog legt einen Stammplatz an; in der Folgewoche sitzt das Kind wieder in B1.
4. Klick auf „Dienstag“ zeigt freie Plätze je Stunde.
5. Einzel-Session in der Zeile „Einzel“ öffnen, Kind zuweisen, Testlauf schalten.
6. Stammplatz mit 14-täglich A-Woche: Vorschau zeigt jede zweite Woche „andere Woche“ und die Herbstferien als „kein Betrieb“.
7. Schicht „Do 16–18, Raum B1“ als ein Eintrag anlegen; Raum der Schicht auf A1 ändern, einmal ohne, einmal mit Kindern.
8. Coach im Slot-Panel auf „fällt aus“ setzen: Raum wird rot gefüllt mit „kein Coach“, Kennzahl „Räume mit Kindern ohne Coach“ steigt.

## Offen, nicht blockierend

- **S4** (Tolunay): Raum zählt für die Planung auch ohne Coach, fehlender Coach nur als Warnung. Danach dürfen Stammplätze in Räume ohne Schicht, wie im Dummy gezeigt.
- **Pausen zwischen den Slots** (z. B. 14:00 · 15:15 · 16:30 · 17:45): unter Einstellungen änderbar, sobald entschieden.
- **Farbe für leere Räume** ist mit Grau angenommen.
