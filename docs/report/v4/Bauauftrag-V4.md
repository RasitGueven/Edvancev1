# Bauauftrag V4 · Klassenarbeiten als roter Faden in Bericht und Präsentation

Stand 25.10.2026, Fassung 2 · Grundlage: Gründer-Rollenspiel Erstgespräch vom 24.10. (Rasit als Vater, Ashkan als Kind, Tolunay als Gründer), Durchsprache von Bericht und Präsentation am 24.10. abends, Durchsprache der V4-Dummys durch Ashkan und Rasit am 25.10. mittags (Fassung 2), die zwei Dummys `bericht-v4-dummy.html` und `praesentation-v4-dummy.html` · Code-Stand `Edvancev1` dev @ `c33fa32`, Bericht v3 auf `feat/lsa-report-v3` @ `f8695e3`.

**Worum es geht.** Eltern denken in Klassenarbeiten. Bericht und Präsentation sollen deshalb von Anfang bis Ende an einem Faden laufen: der Reihe der Klassenarbeiten im Schuljahr laut Schulplan. Welche Arbeit ist geschrieben, welche kommt als Nächstes, welche danach? Für welche fehlen noch Voraussetzungen? Und woran arbeiten wir deshalb zuerst? Seite 1 zeigt dazu nur ein Signal je Arbeit. Die Details stehen auf Seite 3. Der Lernpfad richtet sich nach den Arbeiten, die Ziele sind in Elternsprache formuliert. Die Fehlerbilder fallen aus dem Elternteil heraus. Fassung 2 ergänzt die Durchsprache vom 25.10.: Navigation mit Stationsnamen auf jeder Seite, Kästen statt loser Texte, verständlichere Wörter, ein individueller Satz zur geschriebenen Arbeit, Fahrplan über das Schuljahresende hinaus, Note der letzten Arbeit, Preise per Schalter, vier Stationen in der Präsentation.

**Was v3 schon kann (wird genutzt, nicht neu gebaut):**
- `kommtNoch()` in `lernweg.ts`: die Plan-Einträge nach dem aktuellen Thema, aus `schul_themenplan` oder dem Kernlehrplan
- `baueLueckenweg()` in `lueckenweg.ts`: sitzt bzw. fehlt je kommendem Thema über `skill_kante` und `skill_thema`
- `leads.klassenarbeit_status` und die Startlogik in `schwerpunkte.ts`
- `fehlermusterAus()`, das Sorgfalts-Muster
- `stufenBlick.ts`, die Zeilen je Klassenstufe auf Seite 1
- `paketVorschlag.ts`, `ziele_bestaetigt`, `paket_bestaetigt`

## Vor dem Start (Rasit)

1. **v3 mergen** (PR von `feat/lsa-report-v3`) und die drei Migrationen nach CLAUDE.md §10 einspielen:
   - `20261024135226_bericht_v2`
   - `20261024143626_graph_wurzel_faktorisieren`
   - `20261024145154_bericht_v3_ziele`

   Ohne die Graph-Migration fehlt bei Batu der Satz des Pythagoras als eigenes Thema.
2. **Vier Dateien aus dem Projekt herunterladen** (Ordner `claude/`, sie landen im Downloads-Ordner). V4-1 legt sie nach `docs/report/v4/`:
   - `Bauauftrag-Bericht-V4.md`
   - `bericht-v4-dummy.html`
   - `praesentation-v4-dummy.html`
   - `Edvance_Tablet_V7_Gespraech_18-10.html`
3. **Entschieden am 25.10. (Ashkan, Rasit):**
   - **a) Preise per Schalter.** In der Ansicht des Berichts gibt es einen Schalter „Preise einblenden“ (nur am Bildschirm). Gedruckt bzw. als PDF verschickt wird der Zustand, der gerade eingestellt ist. Standard: aus. Die Präsentation zeigt nie Preise.
   - **b) Präsentation mit vier Stationen:** Überblick · Lernstand · Klassenarbeiten · Förderansatz. Die Station „Einordnung“ (Lernweg) wird nur aus der Stationsliste genommen, nicht gelöscht.
   - **c) Eine Klassenarbeit je Plan-Thema.** Die Texte sagen „Klassenarbeit“ zu jedem kommenden Thema im Schulplan. Schreibt eine Schule eine Arbeit über zwei Themen, stimmt das nicht. Die Bezeichnung steht nur in i18n und lässt sich auf „Thema“ umstellen.

| Paket | Inhalt | Worktree · Branch | wartet auf |
|---|---|---|---|
| V4-1 Rechnung (Foundation) | Fahrplan, Signale je Thema, vollständige Blöcke je Thema, gruppierter Lernpfad, Zielbild, Texte, Fixtures, Tests | `../Edvancev1-v4a` · `feat/rasit-bericht-v4-rechnung` | v3 gemergt |
| V4-2 Bericht | Fahrplan-Leiste im Rahmen, Seiten 1–5 | `../Edvancev1-v4b` · `feat/rasit-bericht-v4-seiten` | V4-1 gemergt |
| V4-3 Präsentation | vier Stationen nach Dummy, Förderansatz über die ganze Folie | `../Edvancev1-v4c` · `feat/rasit-praesentation-v4` | V4-1 gemergt |
| V4-E Erstgespräch | Eingabe Klassenarbeits-Status, Datum der nächsten Arbeit und Note der zuletzt geschriebenen Arbeit (eine Migration, nicht eingespielt) | `../Edvancev1-v4e` · `feat/rasit-erstgespraech-klassenarbeit` | v3 gemergt |

- **Parallel laufen** V4-2 und V4-3 nach V4-1. V4-E läuft jederzeit daneben. Das sind höchstens drei Agenten gleichzeitig.
- **Nur V4-1** ändert `src/lib/**`, `src/types/**` und die i18n-Dateien. V4-2 und V4-3 lesen nur. Fehlt ihnen etwas: STOPP und melden.
- **Ports:** Druck-Tests auf `EB_PORT=5193` (V4-2), Ansichtstests auf `TP_PORT=5195` (V4-3). PDFs und Fotos nach `docs/report/v4/abnahme/<paket>/`.
- **Vor dem PR** wird `origin/dev` hineingemergt. Kein Rebase, kein Force-Push.

**Zeitplan (Vorschlag).** Ziel ist der Batu-Durchlauf am Sa 31.10.

| Wann | Was |
|---|---|
| So 25.10. | v3 mergen, Migrationen einspielen, V4-1 und V4-E starten |
| Mo 26.10. | V4-1 gemergt, V4-2 und V4-3 parallel |
| Mi 28.10. | Abnahme der Gründer (PDF und iPad) |
| Do 29.10. – Fr 30.10. | Nachbesserung, Puffer |

**Nicht in diesem Auftrag:**
- Preise auf Papier, außer bei Entscheidung 3a
- Soft-Launch-Angebot im Bericht
- Telefonnummer (bleibt `KONTAKT.telefon` in `berichtKonfig.ts`)
- Halbjahre im FWG-Schulplan nachpflegen (`schul_themenplan.halbjahr` ist dort leer; das ist eine Datenpflege)
- Gesprächsleitfaden
- Elternzugang zur Präsentation
- Layout A von Seite 3 (bleibt, wie es ist)

---

## Entscheidungen (gelten für alle Pakete)

**1. Der Fahrplan.** Eine reine Rechnung `fahrplan.ts` liefert die Stationen für Seite 1, die Leiste der Seiten 2–5 und Station 02 der Präsentation.
- **Erste Station = das aktuelle Thema** (der Plan-Eintrag an der aktuellen Position, dieselbe Quelle wie `kommtNoch`). Ihr Stand kommt aus `leads.klassenarbeit_status`:
  - `'geschrieben'` → „geschrieben“, Haken
  - `'bevorstehend'` → „nächste Arbeit“, gold
  - `null` → „aktuelles Thema“, ohne Haken
- **Die geschriebene Station** steht in hellem Blau mit Haken (nicht dunkelblau, nicht grün: Wir wissen nicht, wie die Arbeit lief). Ist die Note der Arbeit bekannt (`leads.letzte_klassenarbeit_note`, V4-E), steht sie dabei: „geschrieben · Note 4“.
- **Danach die kommenden Themen:** `kommtNoch()` aus `eintraege`, jedes `themaKey` einmal. Gibt es in diesem Schuljahr weniger als vier kommende Themen, wird mit den ersten Einträgen aus `naechsteKlasse` aufgefüllt, bis es vier sind. Vor der ersten Station des nächsten Schuljahrs steht ein Trenner „Klasse {k}“. Beispiel: Ein Kind in der 7. Klasse im 2. Halbjahr sieht die zwei restlichen Arbeiten und die ersten zwei der 8. Klasse. Die Stationen tragen dafür `schuljahr: 'dieses' | 'naechstes'`. Gibt es keinen Plan für die nächste Klasse, bleibt es bei weniger Stationen. Die erste kommende Station heißt „nächste Arbeit“, außer die aktuelle ist schon `'bevorstehend'`. Alle übrigen heißen „voraussichtlich“.
- **Halbjahr:** Liefert der Plan `halbjahr`, steht es an der Station, und zwischen 1. und 2. Halbjahr steht ein Trenner „Halbjahreszeugnis“. Fehlt es, gibt es weder Halbjahr noch Trenner.
- **Höchstens vier kommende Stationen.** Gibt es in diesem Schuljahr mehr: die ersten vier und „+n weitere Themen bis zum Schuljahresende“.
- **Ohne Plan oder ohne aktuelles Thema** gibt es keinen Fahrplan (`null`). Die Seiten fallen dann auf das v3-Verhalten zurück, nichts bricht.
- **Quelle als Fußzeile mit Info-Symbol:**
  - Schulplan: „Die Reihenfolge stammt aus dem Schulplan des {Schule}. Wann genau eine Arbeit geschrieben wird, legt die Lehrkraft fest.“
  - Kernlehrplan: „Die Reihenfolge folgt dem Kernlehrplan NRW. Wann genau eine Arbeit geschrieben wird, legt die Lehrkraft fest.“
  - Ohne Halbjahr steht „voraussichtlich“ an jeder Station außer der nächsten.

**2. Signal je kommender Station.**
- **Ein Bereich betrifft ein Thema,** wenn das Thema in `themenFuer(b)` vorkommt, als erstes oder als „auch“. Es gilt dieselbe Kante wie in `baueLueckenweg`: s setzt b voraus, das Heimat-Thema von s ist das Thema.
- **Gezählt** werden direkt geprüfte Bereiche ohne unsichere Vorgriffe, wie überall im Bericht.

| Signal | Bedingung | Text (i18n) |
|---|---|---|
| `fehlt` | mindestens ein Bereich mit Übungsbedarf betrifft das Thema | „Voraussetzungen fehlen noch“ |
| `erfuellt` | nur sichere Bereiche betreffen es | „Voraussetzungen sitzen“ |
| `ohne` | kein geprüfter Bereich betrifft es | „dazu noch nichts geprüft“ (grau) |

- Die aktuelle Station hat kein Signal.

**3. Seite 1 nennt keine einzelnen Voraussetzungen.** Seite 1 zeigt je Arbeit nur das Signal. Welche Voraussetzungen fehlen, steht ausschließlich auf Seite 3. Der Satz unter dem Fahrplan steht in einem mint Kasten und richtet sich nach den Signalen der kommenden Stationen:
- **mindestens ein `fehlt`:** „Vieles sitzt schon. Für die kommenden Arbeiten fehlen aber noch einige Voraussetzungen, und genau dort setzen wir an. Welche das sind, steht auf Seite 3.“
- **kein `fehlt`, mindestens ein `erfuellt`:** „Für die kommenden Arbeiten sitzen die geprüften Voraussetzungen. Wir festigen sie und schauen auf den Stoff, der danach kommt.“
- **nur `ohne`:** Der Satz entfällt.

**4. Seite 3: vollständige Blöcke je Arbeit.**
- **Neuer Modus `jeThemaVollstaendig`:** Jeder Block einer Station mit Signal `fehlt` oder `erfuellt` listet ALLE Bereiche, die das Thema betreffen. Ein Bereich darf dabei in mehreren Blöcken stehen; die „betrifft auch“-Zeilen entfallen. Die Frage des Blocks ist „Ist {Name} für diese Arbeit vorbereitet?“, nicht „Wo steht jeder Bereich einmal?“.
- **Bisheriger Modus bleibt** für Layout A und alles, was ihn nutzt.
- **„Weitere Stärken“** = sichere Bereiche, die kein Thema dieses Schuljahrs betreffen.
- **„Wird später wichtig“** = Bereiche mit Übungsbedarf ohne Thema dieses Schuljahrs, Gruppierung wie v3 `gruppiere`.
- **Kein geprüfter Bereich geht verloren:** Jeder steht in mindestens einem Block oder in einer der zwei Restgruppen (Test).
- **Ausdünnen** wie v3 `duenneLueckenweg`.
- **Ein Satz zum Einstieg, individuell:** Ist die aktuelle Arbeit `'geschrieben'`: „Die Arbeit zu „{Thema}“ hat {Name} laut Ihren Angaben schon geschrieben. Deshalb beginnt diese Übersicht mit Klassenarbeit {n}.“ Bei `'bevorstehend'` bzw. unbekannt gelten eigene Fassungen (Anhang A). Der Satz steht in einem hellblauen Kasten mit Haken über den Blöcken. So sehen die Eltern, dass der Bericht auf ihre Angaben eingeht.

**5. Lernpfad nach Klassenarbeiten (Seite 4, Präsentation Station 03).**
- Grundlage sind die Schwerpunkte aus `schwerpunkte.ts` in ihrer v3-Reihenfolge und mit ihrer Startlogik. Neu ist je Schwerpunkt das **Ziel**: die Stationen aus dem Fahrplan, die seine Übungsbedarf-Bereiche betreffen, in Plan-Reihenfolge.
- **Gruppieren:** Aufeinanderfolgende Schwerpunkte mit derselben ersten Ziel-Station werden zu einem Punkt.
  - Titel einzeln: das Themenfeld wie bisher
  - Titel als Gruppe: „Grundlagen für {Thema}“
  - Teile: die Übungsbedarf-Bereiche als Chips in einem Kasten „Das üben wir“, höchstens vier, danach „+n weitere“
  - Links neben jedem Punkt eine Marke mit der Nummer der Klassenarbeit und ihrem Kurztitel (navy), beim letzten Punkt „danach · spätere Schuljahre“ (grau). Diese Marken geben der Seite mehr Halt als die bisherige Kurve; die Kurve entfällt auf Seite 4.
- **Zeile über dem Titel:**
  - „Voraussetzung für Klassenarbeit {n}“ bzw. „… für Klassenarbeit {n} und {m}“ (n = Position im Fahrplan)
  - Bei einer Lücke im aktuellen Thema ohne kommende Station gilt v3 „Vorhandene Lücke“.
  - Nie „bis Klassenarbeit …“: Das klänge wie eine Zusage.
- **Begründung:** ein halber Satz wie v3 (`s4.grund.*`). Das Wort „Klassenband“ kommt in keinem Elterntext vor (Invariante); es heißt „Stoff aus Klasse 5/6“.
- **Danach:** ein grauer letzter Punkt „Wenn der Schulstoff sitzt: Themen späterer Schuljahre“ mit den Feldern aus `danach`.

**6. Fehlerbilder nicht für Eltern.**
- Der Block „Fehlermuster“ auf Seite 4 entfällt, ebenso jede Liste einzelner Fehlerbilder in Bericht und Präsentation.
- Es bleibt nur der eine Satz aus `fehlermusterAus().sorgfalt`. Er steht auf Seite 1 im Kasten „Ihr Anliegen“ unter „Was die Analyse dazu zeigt“: „{Name} findet meist den richtigen Weg. Fehler entstehen eher durch fehlende Sorgfalt.“
- Kein Wurzel- oder Rechenbeispiel.
- Die Rechnung `fehlermuster.ts` bleibt für Coach und spätere Zwecke.

**7. Ziele in Elternsprache (Seite 5).** Gilt nur, wenn `ziele_bestaetigt` gesetzt ist. Ein Zielbild des Coachs (`zielbild`) geht weiterhin vor. Der Systemvorschlag wird neu aus Fahrplan und Muster gebaut, ohne Fachbegriffe, ohne Note und ohne Prognose:
1. Erste kommende Station mit `fehlt`: „{Name} geht gut vorbereitet in die Arbeit zu „{Thema}“, weil die Grundlagen dafür vorher sitzen.“
2. Weitere Stationen mit `fehlt`, höchstens zwei: „Wenn in der Schule „{A}“ (und „{B}“) drankommen, fängt {Name} nicht bei null an, sondern baut auf sicherem Stoff auf.“
3. Bei Sorgfalts-Muster: „{Name} kontrolliert die eigenen Rechnungen selbst und verliert weniger Punkte durch Flüchtigkeitsfehler.“
4. Gibt es Übungsbedarf ohne kommende Station dieses Schuljahrs (Gruppe „Wird später wichtig“): „Auch die übrigen Lücken schließen wir nach und nach, damit spätere Themen auf festen Grundlagen aufbauen.“

Darunter immer der Satz „Wir versprechen keine Noten. Uns geht es darum, zu verstehen, woran es hakt, und {Name} Schritt für Schritt voranzubringen.“

Ohne Namen gelten die Fassungen mit „Ihr Kind“. Die bisherigen Sätze `s5.ziele.vorThema` u. ä. entfallen aus dem Systemvorschlag. Höchstens vier Ziele. Ohne eines davon entfällt der Abschnitt wie in v3.

**8. Sprache.**
- Regeln wie R7 und v3: „Sie“-Form, kein Pronomen für das Kind, nie „gemeistert“ oder „trägt“, keine Note, kein Prozentwert, kein Vergleich.
- **Keine Zusage über Ergebnisse:** kein „bis“, kein „sicher bestehen“.
- **Nur über i18n.** Alle neuen Texte stehen wörtlich in Anhang A.

**9. Gestaltung.** Wie der Druckbogen R7 bzw. die Präsentation V7: Tokens `--color-eb-*` und `--color-tp-*`, Maße in pt, keine Hex-Werte. Neue Tokens legt nur V4-1 an, nur wenn nötig, und begründet sie: ein helles Blau für die geschriebene Arbeit (`--color-eb-navy-hell`, Wert im Dummy `#7E9BBF`) und eine helle Blaufläche für Hinweis-Kästen (`--color-eb-navy-wash`, `#EAF0F6`).

**10. Aus der Durchsprache vom 25.10. (gilt für alle Seiten).**
- **Kopf:** Die Stationsnavigation aus v3 (fünf nummerierte Punkte mit Namen, aktuelle Seite navy) und der Chip „Testdaten“ unter der Wortmarke bleiben auf jeder Seite. Die Klassenarbeits-Leiste kommt zusätzlich unter die Kopflinie.
- **Kein Text steht lose.** Kurze Absätze wie „Was die Grafik zeigt“ oder der Satz unter dem Fahrplan stehen in einem Kasten.
- **Nichts wird abgeschnitten oder läuft über,** auch nicht bei langen Plan-Titeln oder bei mehr Text. Lange Titel brechen um, statt gekürzt zu werden, außer in der schmalen Leiste (dort Ellipse und voller Titel als Vorlesetext).
- **„wirkt auf →“ entfällt.** Auf Seite 2 heißt es „Wichtig für“, dahinter je Station eine kleine Marke mit Nummer und Titel; die nächste Arbeit ist navy hervorgehoben.
- **Ansatz:** Auf Seite 4 stehen zwei Kästen nebeneinander: „Unser Ansatz“ (Abgrenzung zur Hausaufgabenhilfe, an der Wurzel ansetzen) und „Was dazu gehört“ (Lernpfad nach Stärken und Lücken, Aufgaben nach Interessen, sichtbare kleine Erfolge, ein Coach vor Ort, der den Plan prüft und anpasst). Kein „Wir verstehen Ihr Kind“, solange die Brand Foundation das nicht freigibt: Das Modell hat keinen festen Coach.

---

## V4-1 · Rechnung (Foundation)

```
Du arbeitest im Repo Edvancev1 (WSL). Paket V4-1 (Foundation im Sinne der Hard Limits in CLAUDE.md: neue lib-, type- und i18n-Einträge sind hier erlaubt): Rechnung und Texte für „Klassenarbeiten als roter Faden“ in Eltern-Bericht und Präsentation. Voraussetzung: Bericht v3 (feat/lsa-report-v3) ist in dev gemergt und per dbread stehen 20261024135226, 20261024143626 und 20261024145154 in supabase_migrations.schema_migrations. Sonst STOPP und melden.

## Schritt 0
mkdir -p docs/report/v4 && cp "/mnt/c/Users/rasit/Downloads/Bauauftrag-Bericht-V4.md" docs/report/v4/Bauauftrag-V4.md && cp "/mnt/c/Users/rasit/Downloads/bericht-v4-dummy.html" docs/report/v4/ && cp "/mnt/c/Users/rasit/Downloads/praesentation-v4-dummy.html" docs/report/v4/
Fehlt eine Datei: STOPP und Rasit fragen. Dann docs/report/v4/Bauauftrag-V4.md lesen (Entscheidungen 1–9, Anhang A und B), beide Dummys im Browser ansehen und docs/report/v3/offene-punkte.md lesen. Die Zahlen und die Reihenfolge der Arbeiten in den Dummys sind Muster. Es gelten immer Daten und Schulplan.

## Entscheidungen (nicht neu verhandeln)
1. src/lib/report/elternbericht/fahrplan.ts: baueFahrplan({ plan, themaKey, datum, klassenarbeitStatus, signale }) → EbFahrplan | null nach Entscheidung 1. Typ in src/types/elternbericht.ts:
   type EbFahrtStand = 'geschrieben' | 'naechste' | 'aktuell' | 'voraussichtlich'
   type EbSignal = 'fehlt' | 'erfuellt' | 'ohne'
   type EbStation = { nummer: number /* 1 = aktuelles Thema */; themaKey: string; titel: string; halbjahr: 1 | 2 | null; schuljahr: 'dieses' | 'naechstes'; stand: EbFahrtStand; signal: EbSignal | null /* null nur bei der aktuellen */; note: number | null /* nur bei 'geschrieben' */ }
   type EbFahrplan = { stationen: EbStation[]; weitere: number; halbjahrTrenner: boolean; klassenTrenner: number | null /* Klasse des nächsten Schuljahrs, wenn aufgefüllt */; quelle: 'schule' | 'klp'; schulname: string | null; satz: 'fehlt' | 'erfuellt' | null }
   Auffüllen aus plan.naechsteKlasse nach Entscheidung 1. Signale gibt es auch für Stationen des nächsten Schuljahrs (dieselbe Kante). note kommt aus leads.letzte_klassenarbeit_note: eigene Abfrage wie v3 klassenarbeit_status in lsaReportErstgespraech.ts, bei Fehler oder fehlender Spalte null (die Migration aus V4-E ist evtl. noch nicht eingespielt).
   Position, kommtNoch und aktuellePosition aus lernweg.ts wiederverwenden, nicht neu schreiben.
2. lueckenweg.ts erweitern, Bestehendes unverändert lassen:
   - export signaleJeThema(e: LueckenwegEingabe): Map<themaKey, { sitzt: EbBereich[]; fehlt: EbBereich[] }> über themenFuer (erstes + auch), Vorgriffe ausgenommen wie heute.
   - Option { modus: 'einmal' | 'jeThemaVollstaendig' } für baueLueckenweg, Standard 'einmal'. Bei 'jeThemaVollstaendig': ein Block je kommendem Thema mit Signal ≠ 'ohne', alle betreffenden Bereiche, auch = [], weitereStaerken/weitere nur aus Bereichen ohne jedes Thema dieses Schuljahrs. duenneLueckenweg funktioniert für beide Modi.
3. src/lib/report/elternbericht/lernpfadV4.ts: gruppiereSchwerpunkte(schwerpunkte, fahrplan, signale) → EbLernpfadPunkt[] nach Entscheidung 5:
   type EbLernpfadPunkt = { art: 'feld' | 'gruppe' | 'luecke' | 'spaeter'; titelFeld: ThemenfeldKey | null; titelThema: string | null; ziele: number[] /* Stationsnummern */; teile: string[]; rest: number; grund: <wie v3> }
   Reihenfolge und Startlogik bleiben die von schwerpunkte.ts (nicht ändern).
4. src/lib/report/elternbericht/zielbild.ts: zieleV4({ fahrplan, muster, name, spaeterLuecken }) → { schluessel: string; werte: Record<string, string> }[] nach Entscheidung 7, höchstens vier. Nur Schlüssel und Werte, keine fertigen Sätze im Code.
5. bericht.ts: baueElternbericht liefert zusätzlich fahrplan, signale (als serialisierbare Liste), lueckenwegV4 (Modus jeThemaVollstaendig) und lernpfad. klassenarbeitStatus kommt aus dem v3-Lesepfad (lsaReportErstgespraech.ts), keine neue Abfrage. Ohne Plan: alles null bzw. leer, v3-Felder unverändert.
6. Texte: alle Schlüssel aus Anhang A wörtlich in src/i18n/locales/de/elternbericht.json (Abschnitt v4) bzw. praesentation.json (Abschnitt v4). Alte Schlüssel nicht löschen; das machen V4-2/V4-3 nicht, das macht ein späterer Aufräumauftrag.
7. Fixtures: FAELLE um fahrplan* ergänzen (nur Tests und Vorschau, ohne Supabase-Client):
   - batuV4: die echte Analyse des Testlaufs „Rasit Batu“ vom 24.10. (ID über dbread wie in v3), Plan FWG Klasse 9 aus schul_themenplan (per dbread lesen und als Fixture festschreiben), klassenarbeitStatus 'geschrieben'
   - batuBevorstehend: dasselbe mit 'bevorstehend'
   - batuOhneStatus: dasselbe mit null
   - fahrplanKlp: ein Fall ohne Schulplan (Kernlehrplan)
   - fahrplanHalbjahr: Plan mit gesetzten Halbjahren (künstlich), Trenner sichtbar
   - fahrplanLang: mehr als vier kommende Themen
   - fahrplanAuffuellen: Klasse 7, 2. Halbjahr, nur zwei kommende Themen, Plan für Klasse 8 vorhanden → vier Stationen mit Trenner „Klasse 8“
   - batuMitNote: wie batuV4 mit Note 4
   - allesErfuellt: kein Übungsbedarf bei Bereichen, die kommende Themen betreffen
   - ohnePlan: plan null
8. Tokens: --color-eb-navy-hell und --color-eb-navy-wash nach Entscheidung 9 in tokens.css, mit Kommentar. Sonst keine, außer für das Signal „ohne“ fehlt ein Grau; dann einen Token mit Kommentar anlegen und im PR begründen.
9. Invariante: kein „Klassenband“, kein „wirkt auf“, kein „trägt“ in elternbericht.json und praesentation.json (Abschnitt v4 und alle Schlüssel, die V4-2/V4-3 nutzen).

## Umfang
docs/report/v4/ (drei Dateien, offene-punkte-v4-1.md), src/lib/report/elternbericht/{fahrplan,lernpfadV4,zielbild}.ts mit Tests, lueckenweg.ts (+ Test), bericht.ts (+ Test), src/types/elternbericht.ts, src/lib/report/elternbericht/fixtures/**, src/i18n/locales/de/elternbericht.json und praesentation.json (nur Abschnitt v4), ggf. ein Token, Retro, ROADMAP (Abschnitt „Bericht v4“ anlegen). Nicht anfassen: schwerpunkte.ts (Reihenfolge, Startlogik), alle Komponenten unter src/components/**, styles/** außer dem einen Token, supabase/**.

## Tests (Vitest)
- fahrplan: geschrieben / bevorstehend / null an Station 1; „nächste“ wandert korrekt; Halbjahr und Trenner; fahrplanLang mit vier kommenden Stationen und weitere = n − 4; fahrplanAuffuellen mit Klassen-Trenner und schuljahr 'naechstes'; batuMitNote mit note 4, ohne Spalte note null; ohnePlan → null; Satz nach Entscheidung 3 für fehlt, erfuellt und nur ohne.
- signale: Bereich, der über „auch“ ein Thema betrifft, setzt dort fehlt; Vorgriffe zählen nicht; Thema ohne Bereich → ohne.
- lueckenweg jeThemaVollstaendig: Bereich in zwei Blöcken möglich; jeder geprüfte Bereich steht in mindestens einem Block oder einer Restgruppe (Eigenschaftstest über alle FAELLE); Modus 'einmal' liefert für alle FAELLE exakt das Ergebnis von v3 (Snapshot vor der Änderung erzeugen).
- lernpfadV4: Gruppe bei gleicher erster Ziel-Station; einzeln sonst; Zeile „Klassenarbeit n und m“; luecke ohne kommende Station; spaeter als letzter Punkt; Reihenfolge identisch mit schwerpunkte.ts.
- zielbild: batuV4 → vier Ziele (vorbereitet, später mit bis zu zwei Themen, Sorgfalt, übrige Lücken); ohne Sorgfalt → drei; allesErfuellt → nur Sorgfalt bzw. übrige Lücken oder leer; ohne Namen.
- Invarianten (inv4-elternbericht, inv4-praesentation): neue Texte ohne „bis Klassenarbeit“, ohne „trägt“, „gemeistert“, %, Note.
Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-v4a auf feat/rasit-bericht-v4-rechnung von origin/dev. PR gegen dev, nie main. Vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push. Nichts in .github/.
- Kein DDL, keine Migration, Prod nur lesend über dbread.
- Dateien ≤ 400 Zeilen; mehr als 300 neue Zeilen nach CLAUDE.md §4 in Commits aufteilen.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler. Im PR vermerken.
- Zweitprüfung durch eine frische Instanz vor dem PR, Schwerpunkt: kein Bereich geht verloren, Modus 'einmal' unverändert, Fahrplan gegen dbread. STOPP nach dem PR.

## Melden
PR-Link. Für batuV4 als Tabelle: Stationen (Nummer, Titel, Halbjahr, Stand, Signal) in Plan-Reihenfolge; je Station mit Signal die Listen sitzt/fehlt; die Lernpfad-Punkte mit Zeile „Voraussetzung für …“ und Teilen; die drei Ziele als fertige Sätze. Dazu der FWG-Plan Klasse 9 aus dbread (Position, Titel, Halbjahr) und eine unabhängige Gegenprüfung der Signale per SQL über skill_kante/skill_thema als Tabelle „Thema | Signal Code | Signal SQL | ok?“. Offene Punkte in docs/report/v4/offene-punkte-v4-1.md.
```

---

## V4-2 · Bericht (Seiten 1–5)

```
Du arbeitest im Repo Edvancev1 (WSL). Paket V4-2: Der Eltern-Bericht R7/v3 bekommt die Klassenarbeiten als roten Faden. Voraussetzung: V4-1 ist in dev gemergt (fahrplan, signale, lueckenwegV4, lernpfad, zieleV4 in baueElternbericht; Texte unter elternbericht v4; Fixtures batuV4 u. a.). Sonst STOPP. Läuft parallel zu V4-3; fasse praesentation/** nicht an.

## Ziel
Fünf Seiten wie bisher, Aufbau nach docs/report/v4/bericht-v4-dummy.html, Maße und Stil nach E7 (docs/report/r7/E7-Masse.md). Die Entscheidungen 1–9 aus docs/report/v4/Bauauftrag-V4.md gelten. Ohne Fahrplan (bericht.fahrplan === null) sieht jede Seite exakt aus wie in v3 (Test).

## Entscheidungen (nicht neu verhandeln)
1. Rahmen (Seite.tsx, rahmen.css): Der Kopf mit Stationsnavigation (Namen unter den Punkten) und Chip „Testdaten“ bleibt auf allen fünf Seiten wie in v3. Auf den Seiten 2–5 steht zusätzlich unter der Kopflinie eine Fahrplan-Leiste (Komponente FahrplanLeiste.tsx):
   - Label v4.leiste.label, dann je Station ein Chip: Nummer bzw. Haken in einem Punkt in Signalfarbe (fehlt = --color-eb-uebung, erfuellt = --color-eb-sicher, ohne = grau, geschrieben = --color-eb-navy-hell), daneben der Titel.
   - Titel mit text-overflow: ellipsis, max. Breite je Chip gleich verteilt. Die volle Bezeichnung steht als Vorlesetext.
   - Hervorhebung je Seite (Prop): Seite 2 und 5 alle, Seite 3 und 4 nur die kommenden.
   - Höhe 16 pt, .eb-inhalt rückt auf diesen Seiten um diese Höhe nach unten. Der Druck-Test prüft weiter, dass nichts überläuft. Seite 3 dünnt dann ggf. eine Stufe früher aus; das ist gewollt.
2. Seite 1:
   - Kopf, Kopfdaten, Kasten „Ihr Anliegen“ und „So gehen wir vor“ bleiben. Im Anliegen-Kasten unter „Was die Analyse dazu zeigt“ zusätzlich der Sorgfalt-Satz v4.s1.sorgfalt, nur bei muster.sorgfalt. Der Muster-Teil des Satzes unter „Auf einen Blick“ entfällt dafür.
   - „Auf einen Blick“ mit den Stufen-Zeilen und der Zählzeile bleibt.
   - Der Kasten „Wir beginnen mit …“ entfällt.
   - Neu darunter der Fahrplan in einem weißen Kasten (Aufbau wie Dummy): Kicker v4.s1.fahrplanKicker; eine geschwungene Linie (--color-eb-weg; geschwungen, weil die Zukunft nicht fest ist) mit den Stationen als Punkte Ø 20 pt, die geschriebene in --color-eb-navy-hell mit Haken, kommende mit Ring in Signalfarbe und Nummer, „ohne“ grau. Die Punkte sitzen über einem Raster mit gleich breiten Spalten; darunter je Spalte Titel (8,2 pt, umbrechen statt kürzen) und Stand mit Signal (6,9 pt), bei der geschriebenen ggf. „· Note n“. Halbjahr- bzw. Klassen-Trenner als schmale senkrechte Linie mit Beschriftung zwischen zwei Spalten. Bei weitere > 0 am Ende „+n weitere Themen bis zum Schuljahresende“.
   - Darunter der Satz nach fahrplan.satz in einem mint Kasten, darunter die Quellenzeile mit Info-Symbol (Entscheidung 1).
   - Keine einzelnen Voraussetzungen auf Seite 1 (Test: kein Label aus lueckenwegV4 im DOM von Seite 1).
3. Seite 2: Je Themenfeld-Zeile im Profil eine zweite Zeile „Wichtig für“ (v4.s2.wichtig) mit einer Marke je Station (Nummer fett + Titel, Fläche --color-eb-navy-wash): die Stationen, die ein geprüfter Bereich dieses Felds betrifft, höchstens zwei in Plan-Reihenfolge; die nächste Arbeit als navy Marke mit Zusatz v4.s2.naechste. Kein Thema, aber Übungsbedarf → v4.s2.spaeter (grau). Kein Thema, alles sicher → keine Zeile. Die Legende bekommt den Eintrag v4.s2.legendeNummer. Rechte Spalte (Zählung) darf nicht überlaufen. Felder aufsteigend nach frühester Klassenstufe (falls v3 das nicht schon tut). „Was die Grafik zeigt“ steht in einem mint Kasten.
4. Seite 3 (Layout B): Blöcke aus bericht.lueckenwegV4.
   - Kopf je Block: v4.s3.blockTitel („Klassenarbeit {n} · {Thema}“), rechts der Stand (nächste Arbeit / voraussichtlich / Halbjahr) und ein Chip mit dem Signal.
   - Über den Blöcken der individuelle Einstiegssatz (Entscheidung 4) in einem Kasten --color-eb-navy-wash mit Haken-Symbol.
   - Kopf je Block links mit einem runden Nummern-Punkt (Fläche --color-eb-uebung-wash bzw. Signalfarbe), Titel und darunter „Klassenarbeit n · Stand“.
   - Zwei Spalten „Sitzt schon“ / „Fehlt noch“ wie im Dummy. Keine „betrifft auch“-Zeilen, kein Pfeil, keine dritte Spalte „Kommt noch“.
   - Darunter zwei Kästen nebeneinander „Weitere Stärken“ (mint, Bereiche als weiße Chips) und „Wird später wichtig“ (weiß, Bereiche als rosé Chips) (v4.s3.*). Ausdünnen wie v3. Die Fußnote zur Quelle bleibt.
5. Seite 4:
   - Der Fehlermuster-Block entfällt (Kicker, Kasten, Satz).
   - Titel v4.s4.titel, Intro nach klassenarbeitStatus (v4.s4.intro.*).
   - Statt der Kurve je Lernpfad-Punkt eine Zeile aus zwei Teilen (Aufbau wie Dummy): links eine navy Marke (62 pt breit) mit „für“, der Nummer der Klassenarbeit groß in --font-eb-titel und dem Kurztitel; rechts eine weiße Karte mit „Schritt n · Voraussetzung für Klassenarbeit n“ (bzw. …Zwei oder v3 „Vorhandene Lücke“), Titel (Feld bzw. v4.s4.gruppe), Begründung wie v3 und dem Kasten „Das üben wir“ (rosé Fläche, Bereiche als weiße Chips, höchstens vier + „+n weitere“).
   - Letzter Punkt „spaeter“ grau (Marke --color-eb-linie, Text v4.s4.spaeter*), falls vorhanden.
   - Darunter die zwei Kästen „Unser Ansatz“ und „Was dazu gehört“ (Entscheidung 10, Texte v4.s4.ansatz*). Die Coach-Fußnote bleibt.
6. Seite 5:
   - Fazit oben. Satz v4.s5.fazit.* aus Stufen, Lückenfeldern, Fahrplan und Start; nur Daten, die vorne schon stehen.
   - Ziele aus zieleV4 (nur bei ziele_bestaetigt, Zielbild des Coachs geht vor) als nummerierte Liste in einem weißen Kasten, darunter v4.s5.keineNoten.
   - Vorschlag, Mitgliedschaften und Kontakt wie v3.
   - Preise: Schalter „Preise einblenden“ in der Ansicht (print-hide, Zustand als URL-Parameter ?preise=an, kein DDL). Eingeblendet: Preis je Paket aus tiers (Intl.NumberFormat, de-DE, EUR) unter dem Rhythmus; der Hinweis „Preise und Konditionen besprechen wir persönlich“ entfällt dann. Ausgeblendet: wie v3. Gedruckt wird der eingestellte Zustand.
7. Keine Hex-Werte, Farben nur aus --color-eb-*, Texte nur über i18n, Maße in pt. Fehlt ein Token oder ein Text: STOPP und melden.

## Umfang
src/components/edvance/elternbericht/** (Seite.tsx, Seite1–5.tsx, neue Teile FahrplanLeiste.tsx, FahrplanSeite1.tsx, LernpfadV4.tsx), src/styles/elternbericht/** (ohne tokens.css), Tests daneben, docs/report/v4/offene-punkte-v4-2.md, Retro. Nicht anfassen: src/lib/**, src/types/**, i18n-Dateien, tokens.css, praesentation/**, supabase/**.

## Tests
- Vitest je Seite mit batuV4, batuBevorstehend, batuOhneStatus, fahrplanKlp, fahrplanHalbjahr, fahrplanLang, allesErfuellt, ohnePlan; ohnePlan rendert wie v3 (Snapshot vor der Änderung).
- Seite 1 ohne einzelne Voraussetzungen; Seite 4 ohne Fehlermuster und ohne das Wort „bis“ vor „Klassenarbeit“; Kopf mit Stationsnamen auf allen Seiten; Preise nur mit ?preise=an; fahrplanAuffuellen mit Klassen-Trenner auf Seite 1; batuMitNote zeigt „Note 4“.
- Kein Element ragt aus seinem Kasten oder aus .eb-inhalt (Druck-Test um diese Prüfung erweitern, für alle Fälle).
- Druck-Tests für ALLE Fälle grün: EB_PORT=5193 EB_AUSGABE=docs/report/v4/abnahme/v4-2 npx playwright test -c playwright.elternbericht.config.ts
- inv4-elternbericht, Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-v4b auf feat/rasit-bericht-v4-seiten von origin/dev. PR gegen dev, nie main; vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push.
- Kein DDL, keine Migration. Dateien ≤ 400 Zeilen, große Änderungen in Commits aufteilen.
- Zweitprüfung durch eine frische Instanz: Sie liest die PDFs von batuV4 und vergleicht jede Zahl und jedes Label mit dbread („Aussage | DB-Wert | ok?“). STOPP nach dem PR.

## Melden
PR-Link, PDFs aus docs/report/v4/abnahme/v4-2/ (batuV4, batuBevorstehend, fahrplanKlp, fahrplanLang, allesErfuellt, ohnePlan), Bildschirmfotos aller fünf Seiten von batuV4 neben dem Dummy, die Prüftabelle der Zweitprüfung, offene Punkte.
```

---

## V4-3 · Präsentation (vier Stationen)

```
Du arbeitest im Repo Edvancev1 (WSL). Paket V4-3: Die Tablet-Präsentation der LSA folgt den Klassenarbeiten. Voraussetzung: V4-1 ist in dev gemergt (fahrplan, signale, lueckenwegV4, lernpfad, zieleV4; Texte unter praesentation v4). Sonst STOPP. Läuft parallel zu V4-2; fasse elternbericht/** nicht an.

## Ziel
Vier Stationen nach docs/report/v4/praesentation-v4-dummy.html, Rahmen, Intro, Leiste mit Eddie, Bewegung und Kopf wie heute (Dummy V7). Die Entscheidungen 1–9 aus docs/report/v4/Bauauftrag-V4.md gelten. Die Zahlen auf Tablet und Papier bleiben gleich, weil beide dieselben Rechnungen aus V4-1 nutzen.

## Entscheidungen (nicht neu verhandeln)
1. STATIONEN in stationProps.ts bleibt bei vier, mit neuer Zuordnung: 1 Überblick, 2 Lernstand, 3 Klassenarbeiten, 4 Förderansatz. Station3.tsx (Einordnung/Lernweg) bleibt im Repo, wird nur nicht mehr eingehängt; ihre Tests laufen weiter gegen die Komponente selbst. Ohne Fahrplan (null) gilt die bisherige Zuordnung (Fallback, Test).
2. Station 01 Überblick:
   - Das Intro davor behält die Animation aus Dummy V7 (Logo gleitet ein und zeichnet sich, dann Kicker, Name, Unterzeile, Knopf); sie war in Fassung 1 des V4-Dummys verloren gegangen.
   - Überschrift wie bisher (Kopfsatz bzw. Ersatz), etwas kleiner als bisher, damit der Fahrplan Platz hat.
   - Leitsatz = v4.s1.lead mit dem Sorgfalt-Satz, wenn muster.sorgfalt, sonst wie bisher.
   - Rechts die Stufen-Pyramide aus stufenBlick (aktueller Stoff oben, Grundlagen unten), je Stufe Name, Klassen-Pille, Punkte (grün / rosé mit reduzierter Deckkraft) und Kurzsatz (dieselben Texte wie Seite 1). Weiße Karten, Farbe nur im Kurzsatz und in den Punkten.
   - Darunter über die volle Breite der Fahrplan der Klassenarbeiten wie auf Seite 1 des Berichts: geschwungene Linie, Punkte (geschrieben hellblau mit Haken, kommende mit Ring in Signalfarbe und Nummer, erscheinen nacheinander), darunter Titel und Stand mit Signal, darunter der Satz nach fahrplan.satz im mint Kasten. Keine einzelnen Voraussetzungen. So sehen die Eltern zuerst, was auf das Kind zukommt und wonach wir uns richten.
   - Die vier Eckdaten stehen NICHT hier, sondern auf Station 02.
3. Station 02 Lernstand: die bestehende Station2.tsx (Kompetenzprofil mit aufklappbaren Zeilen) wird wieder eingehängt und angepasst:
   - Titel „{Name}s Kompetenzprofil.“ (v4.p.s2.titel, Genitiv über genitiv()), Untertitel mit Aufgabenzahl und Dauer (v4.p.s2.desc).
   - Darüber die vier Eckdaten (Aufgaben bearbeitet, Bereiche geprüft, sicher, Übungsbedarf) als Zahlenreihe; sie beschreiben genau diese Station.
   - Felder aufsteigend nach Klassenstufe, Unterzeile mit Klassenangabe.
   - Beim ersten Besuch erscheinen die Kästchen nacheinander („ploppen auf“: Skalierung 0,2 → 1,15 → 1, je Zeile versetzt, Zeiten als Variablen in rahmen.css). Wiederbesuch und prefers-reduced-motion still.
   - Im aufgeklappten Detail eine dritte Spalte „Wichtig für“ mit den Stationen (Nummer + Titel) bzw. v4.s2.spaeter.
4. Station 03 Klassenarbeiten:
   - Titel v4.s2p.titel, Untertitel nach fahrplan.satz.
   - Je Station eine Karte: Stand-Chip, Titel, „Klassenarbeit n“. Kommende Stationen zusätzlich mit bis zu drei Einträgen „sitzt“ (grün) und „fehlt“ (rosé) aus lueckenwegV4, danach „+n weitere“. Die geschriebene Station gestrichelt mit Chip in --color-eb-navy-hell, ggf. mit Note, und einem Satz zu einer offenen Lücke aus dem aktuellen Thema, falls vorhanden (v4.p.s3.offen). „ohne“ grau mit v4.signal.ohne.
   - Querformat: Karten nebeneinander. Hochformat: zwei Spalten.
   - Fußzeile mit der Quelle.
5. Station 04 Förderansatz (Rückmeldung Rasit, 25.10.):
   - Aufbau wie Dummy V7: links die Kurve in der Form des Logos (SEGS aus kurve.ts: kurz nach unten, dann wie ein Nike-Haken nach rechts oben; Startpunkt navy, Pfeilspitze gold), rechts ein fester Detail-Kasten. Im Hochformat steht der Kasten unter der Kurve.
   - Punkte auf der Kurve in Lernpfad-Reihenfolge, so dass sie von links unten nach rechts oben steigen: die Lernpfad-Punkte aus bericht.lernpfad ohne „spaeter“ (höchstens vier) und, bei muster.sorgfalt, ein letzter Punkt „Sorgfalt“ (blaue statt goldene Kugel). Lage für n = 5: 0,27 · 0,47 · 0,62 · 0,76 · 0,90 der Kurvenlänge; für weniger Punkte die Tabelle aus der Anforderung (Entscheidung 9) bzw. gleichmäßig ab 0,27. Beschriftung (Titel + „für Klassenarbeit n“ bzw. „in jeder Session“): erster Punkt darunter, alle weiteren links. Überlappungsprüfung im Ansichtstest.
   - Der erste Punkt ist vorgewählt. Antippen eines Punkts vergrößert ihn (Lichtschein) und wechselt NUR den Inhalt des Kastens rechts; der Kasten bleibt immer an derselben Stelle und in derselben Größe (kein Aufgehen am Punkt).
   - Inhalt des Kastens: Kicker „Förderfokus n von m“, Pille „für Klassenarbeit n“ (rosé) bzw. „in jeder Session“ (blau), Titel, ein Satz Begründung, zwei Spalten „Sitzt schon“ (grün) und „Das gehen wir an“ (rosé) mit den Bereichen als Liste, darunter „Ziel: …“ aus zieleV4 (nur bei ziele_bestaetigt), unten „zurück“ / „n / m“ / „weiter“ (≥ 44 px). Pfeiltasten wechseln den Punkt.
   - Empfehlungszeile unverändert, ohne Preis, darunter der Hinweis zum Arbeitsvorschlag.
6. Keine Fehlerbilder-Liste, kein Rechenbeispiel, kein Preis irgendwo in der Präsentation (Test über das DOM).
7. Farben nur aus --color-eb-* und --color-tp-*, Texte nur über i18n (praesentation, elternbericht), Bewegung über die Variablen aus rahmen.css, prefers-reduced-motion still. Die blaue Kugel für „Sorgfalt“ ist ein Kugel-Verlauf im Sinne von CLAUDE.md §11 (nur aus Tokens; fehlt ein Token: STOPP und melden).

## Umfang
src/components/edvance/praesentation/** (stationProps.ts, Praesentation.tsx nur Zuordnung, Station1.tsx, Station2.tsx, neue StationKlassenarbeiten.tsx, Station4.tsx bzw. StationFoerderansatz.tsx, Teile), src/styles/praesentation/** (ohne tokens.css), Tests daneben, docs/report/v4/offene-punkte-v4-3.md, Retro. Nicht anfassen: src/lib/**, src/types/**, i18n-Dateien, tokens.css, elternbericht/**, ReportPage.tsx, supabase/**.

## Tests
- Vitest: Stationsliste mit und ohne Fahrplan; Station 01 mit Eckdaten, Pyramide und Sorgfalt-Satz; Station 02 mit „Wichtig für“ im Detail; Station 03 mit batuV4 (vier Karten, Signale nach V4-1), fahrplanLang, fahrplanAuffuellen, allesErfuellt; Station 01 mit Fahrplan und ohne Eckdaten; Station 02 mit Eckdaten; Station 04 mit fünf Punkten (batuV4) in steigender Lage, Gruppenpunkt, Sorgfalt-Punkt, fester Kasten wechselt nur den Inhalt (Position und Größe gleich nach jedem Tippen), zurück/weiter und Pfeiltasten, Ziel-Zeile nur bei ziele_bestaetigt; kein „€“ im DOM.
- Ansichtstests auf allen iPad-Maßen der Anforderung (Entscheidung 10 dort), Überlappungsprüfung der Beschriftungen, Touch-Ziele ≥ 44 px: TP_PORT=5195 TP_AUSGABE=docs/report/v4/abnahme/v4-3 npx playwright test -c playwright.praesentation.config.ts
- inv4-praesentation, Typecheck, Lint, Vitest grün.

## Leitplanken
Worktree ../Edvancev1-v4c auf feat/rasit-praesentation-v4 von origin/dev, PR gegen dev, nie main; vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push. Kein DDL. Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz: Zahlen und Labels von Station 02 gegen die Seite 3 des Bericht-PDFs aus V4-2 bzw. gegen dbread. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfotos aller vier Stationen (batuV4, fahrplanLang, allesErfuellt, ohnePlan) bei 820×1180 und 1180×820 neben dem Dummy, Station 04 zusätzlich mit jedem Punkt einmal gewählt, offene Punkte.
```

---

## V4-E · Erstgespräch: Klassenarbeit erfassen

```
Du arbeitest im Repo Edvancev1 (WSL). Paket V4-E: Im Erstgespräch (Aufnahme unter src/pages/admin/intake/) werden der Stand der Klassenarbeit zum aktuellen Thema, das Datum der nächsten Arbeit und, falls bekannt, die Note der zuletzt geschriebenen Arbeit erfasst. Voraussetzung: Migration 20261024135226_bericht_v2 ist eingespielt (leads.klassenarbeit_status existiert; per dbread prüfen). Sonst STOPP.

## Entscheidungen (nicht neu verhandeln)
1. Beim Feld „aktuelles Thema“ zwei neue Eingaben:
   - Auswahl „Klassenarbeit zu diesem Thema“ mit drei Optionen: „steht noch an“ → 'bevorstehend', „schon geschrieben“ → 'geschrieben', „weiß nicht“ → null. Standard: nichts gewählt (= null).
   - Datum „Nächste Klassenarbeit“ → leads.next_exam_date (vorhanden), optional, nur sichtbar bei „steht noch an“. Weiß das Kind kein Datum, bleibt es leer; das ist der Normalfall, kein Fehler.
2. Hilfetext unter der Auswahl (i18n): „Wenn das Kind es nicht weiß: ‚weiß nicht‘ wählen. Der Bericht richtet sich dann nach dem Schulplan.“
3. Speichern über die bestehende Lead-Schicht (src/lib/supabase/leads.ts). Ist es nötig, die Spalte dort zu ergänzen: erlaubt, nur dieser eine Feldname.
4. Note der zuletzt geschriebenen Arbeit: optionale Auswahl 1–6, nur sichtbar bei „schon geschrieben“, Hilfetext „Nur eintragen, wenn die Familie sie nennen möchte.“ Dafür eine neue Spalte leads.letzte_klassenarbeit_note smallint null check (letzte_klassenarbeit_note between 1 and 6) mit Kommentar. Migration als Datei nach supabase/migrations/ mit sekundengenauer Version (date -u +%Y%m%d%H%M%S) und Rollback unter supabase/rollback/, NICHT einspielen (ALLOW_MIGRATIONS=1 nur für diese Datei). Im PR die &&-verkettete Einspielkette nach CLAUDE.md §10 vorbereiten. RLS: die Spalte fällt unter die bestehende leads-Policy (nur Admin), keine Rechteänderung. Die Eingabe speichert nur, wenn die Spalte existiert; sonst bleibt das Feld ausgeblendet (Prüfung beim Laden, console.warn).
5. Keine Pflichtfelder, sonst keine neue Spalte. Touch-Ziele ≥ 44 px, Texte über i18n (Namespace der Aufnahme).

## Umfang
src/pages/admin/intake/** (formState.ts und die Eingabe), src/lib/supabase/leads.ts (nur klassenarbeit_status und letzte_klassenarbeit_note), i18n der Aufnahme, die Migration mit Rollback, supabase/schema-erwartet.sql nur falls das Repo das für neue Spalten verlangt, Tests, Retro. Nichts sonst.

## Tests
Vitest: drei Optionen speichern korrekt ('bevorstehend', 'geschrieben', null); Datum nur bei 'bevorstehend' sichtbar und gespeichert; Note nur bei 'geschrieben' sichtbar, 1–6, leer = null; ohne Spalte bleibt das Notenfeld aus; ohne Auswahl bleibt null. Typecheck, Lint, Vitest grün. Die Migration läuft in der Wegwerf-DB (neuaufbau) durch.

## Leitplanken
Worktree ../Edvancev1-v4e auf feat/rasit-erstgespraech-klassenarbeit von origin/dev, PR gegen dev, nie main. Kein DDL gegen Prod; die Migration nur als Datei. Wegen der Schema-Änderung Zweitprüfung durch eine frische Instanz (CLAUDE.md §8, Consensus-Trigger). STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfoto der Aufnahme mit beiden Feldern, offene Punkte.
```

---

## Abnahme (Gründer gemeinsam, Mi 28.10.)

1. **PDF Batu neben dem Dummy:** Kopf mit Stationsnamen auf jeder Seite. Auf Seite 1 steht der Fahrplan mit Signalen, aber keine einzelne Voraussetzung. Die Leiste steht auf den Seiten 2–5. Seite 3 hat einen Block je Arbeit. Seite 4 zeigt keine Fehlerbilder und kein „bis“. Seite 5 hat die Ziele in Elternsprache.
2. **Reihenfolge der Arbeiten** wie im FWG-Plan. Der Dummy hatte Pythagoras vor Kreise, laut v3 kommt Kreise vor Pythagoras.
3. **Status umschalten** (bevorstehend / geschrieben / weiß nicht) im Erstgespräch. Fahrplan, Start auf Seite 4 und „nächste Arbeit“ ändern sich mit.
4. **iPad in Safari,** Hoch- und Querformat, mit vier Stationen, Karten im Förderansatz antippen. Die Zahlen sind gleich wie auf Papier, nirgends steht ein Preis.
5. **Verständnis von außen:** Lena liest PDF und Präsentation mit der Frage „Verstehe ich als Elternteil alles?“ (Memo von Ashkan liegt ihr vor). Danach eine echte Familie fragen, voraussichtlich Familie Demirel nach dem Termin am 31.10.
6. **Bestätigen oder ändern:**
   - Entscheidung 3c aus „Vor dem Start“
   - Wortlaut der Ziele und des Satzes unter dem Fahrplan
   - graue Stationen „dazu noch nichts geprüft“ zeigen oder weglassen

## Offen, nicht blockierend

- **Halbjahre:** `schul_themenplan.halbjahr` beim FWG und bei den übrigen Schulen pflegen. Dann erscheinen Halbjahr und „Halbjahreszeugnis“ ohne Code-Änderung.
- **Frage im Erstgespräch** „Wie viele Arbeiten schreibt ihr noch in diesem Halbjahr?“ als Gegenprobe zum Plan. Ein eigenes Feld kommt erst, wenn sich Plan und Antwort oft widersprechen.
- **Aufräumen:** alte Texte (`s4.muster.*`, `s5.ziele.vorThema` …) und Layout A nach der Abnahme in einem eigenen Auftrag entfernen.
- **Soft-Launch-Angebot und Telefonnummer** in Bericht und Präsentation, sobald beides feststeht.
- **Gestaltung Seite 1 und Station 01:** Ashkan überarbeitet beide gestalterisch. Seite 4 braucht laut Ashkan noch mehr „Pep“; die Marken je Klassenarbeit sind ein erster Schritt.
- **CI-Grundlage:** Ashkans Ausarbeitung (wer wir sind, Auftreten gegenüber Eltern, Markenbotschaft) wird als Dokument im Projekt abgelegt und mit der Brand Foundation v1.2 abgeglichen. Danach Texte wie „Unser Ansatz“ daran ausrichten.
- **These „Die LSA sagt die Fehler der nächsten Arbeit voraus“:** erste Tests deuten darauf hin, belegt ist es nicht. Nicht als Versprechen verwenden; nach den ersten echten Familien prüfen.

---

## Anhang A · Texte

`{{name}}` ist der Rufname, `{{wessen}}` ist `genitiv(name)`. Ohne Namen gilt jeweils die Fassung `…OhneName`. `{{thema}}` und `{{a}}`/`{{b}}` sind Plan-Titel, `{{n}}`/`{{m}}` Stationsnummern.

**`elternbericht.json`, Abschnitt `v4`:**

```json
{
  "v4": {
    "signal": {
      "fehlt": "Voraussetzungen fehlen noch",
      "erfuellt": "Voraussetzungen sitzen",
      "ohne": "dazu noch nichts geprüft"
    },
    "stand": {
      "geschrieben": "geschrieben",
      "naechste": "nächste Arbeit",
      "aktuell": "aktuelles Thema",
      "voraussichtlich": "voraussichtlich",
      "halbjahr": "{{halbjahr}}. Halbjahr",
      "zeugnis": "Halbjahreszeugnis",
      "weitere_one": "+{{count}} weiteres Thema bis zum Schuljahresende",
      "weitere_other": "+{{count}} weitere Themen bis zum Schuljahresende",
      "note": "Note {{note}}",
      "klasse": "Klasse {{klasse}}"
    },
    "quelle": {
      "schule": "Die Reihenfolge stammt aus dem Schulplan des {{schule}}. Wann genau eine Arbeit geschrieben wird, legt die Lehrkraft fest.",
      "klp": "Die Reihenfolge folgt dem Kernlehrplan NRW. Wann genau eine Arbeit geschrieben wird, legt die Lehrkraft fest."
    },
    "leiste": {
      "label": "Klassenarbeiten",
      "aria": "Klassenarbeit {{n}}: {{thema}}, {{stand}}"
    },
    "s1": {
      "fahrplanKicker": "{{wessen}} Klassenarbeiten in diesem Schuljahr",
      "fahrplanKickerOhneName": "Die Klassenarbeiten in diesem Schuljahr",
      "sorgfalt": "{{name}} findet meist den richtigen Weg. Fehler entstehen eher durch fehlende Sorgfalt.",
      "sorgfaltOhneName": "Ihr Kind findet meist den richtigen Weg. Fehler entstehen eher durch fehlende Sorgfalt.",
      "satzFehlt": "Vieles sitzt schon. Für die kommenden Arbeiten fehlen aber noch einige Voraussetzungen, und genau dort setzen wir an. Welche das sind, steht auf Seite 3.",
      "satzErfuellt": "Für die kommenden Arbeiten sitzen die geprüften Voraussetzungen. Wir festigen sie und schauen auf den Stoff, der danach kommt."
    },
    "s2": {
      "wichtig": "Wichtig für",
      "naechste": "nächste Arbeit",
      "spaeter": "wird in späteren Schuljahren wichtig",
      "legendeNummer": "Nummer der Klassenarbeit",
      "intro": "Ausgehend vom aktuellen Thema hat das System auch Stoff aus Klasse 5 bis 8 geprüft. Dort entstehen Lücken oft, bevor sie in den Noten sichtbar werden. Bei jedem Themenfeld steht, für welche Klassenarbeit es wichtig ist."
    },
    "s3": {
      "kicker": "Einordnung nach Klassenarbeiten",
      "titel": "Was für die nächsten Arbeiten schon sitzt und was noch fehlt.",
      "individuell": {
        "geschrieben": "Die Arbeit zu <b>{{thema}}</b> hat {{name}} laut Ihren Angaben schon geschrieben. Deshalb beginnt diese Übersicht mit Klassenarbeit {{n}}. Für jede kommende Arbeit steht hier, welche Voraussetzungen sitzen und welche wir vorher festigen.",
        "geschriebenOhneName": "Die Arbeit zu <b>{{thema}}</b> ist laut Ihren Angaben schon geschrieben. Deshalb beginnt diese Übersicht mit Klassenarbeit {{n}}. Für jede kommende Arbeit steht hier, welche Voraussetzungen sitzen und welche wir vorher festigen.",
        "bevorstehend": "Die Arbeit zu <b>{{thema}}</b> steht laut Ihren Angaben noch an. Darauf bereiten wir zuerst vor. Für die Arbeiten danach steht hier, welche Voraussetzungen sitzen und welche wir vorher festigen.",
        "unbekannt": "Für jede kommende Arbeit steht hier, welche Voraussetzungen sitzen und welche wir vorher festigen. Die Reihenfolge stammt aus dem Schulplan."
      },
      "blockTitel": "Klassenarbeit {{n}} · {{thema}}",
      "sitzt": "Sitzt schon",
      "fehlt": "Fehlt noch",
      "weitereStaerken": "Weitere Stärken",
      "spaeter": "Wird später wichtig",
      "spaeterIntro": "Diese Bereiche kommen in späteren Themen und Schuljahren dran. Wir nehmen sie dazu, sobald sie anstehen."
    },
    "s4": {
      "kicker": "Lernpfad",
      "titel": "Die Reihenfolge folgt den nächsten Klassenarbeiten.",
      "intro": {
        "geschrieben": "Die Arbeit zu „{{thema}}“ ist geschrieben. Deshalb beginnen wir mit den Voraussetzungen für die nächste Arbeit und arbeiten uns dann zu den folgenden vor.",
        "bevorstehend": "Die Arbeit zu „{{thema}}“ steht noch an. Deshalb bereiten wir zuerst darauf vor und nehmen danach die Voraussetzungen für die folgenden Arbeiten.",
        "unbekannt": "Wir beginnen mit dem aktuellen Thema und nehmen danach die Voraussetzungen für die folgenden Arbeiten."
      },
      "voraussetzung": "Voraussetzung für Klassenarbeit {{n}}",
      "voraussetzungZwei": "Voraussetzung für Klassenarbeit {{n}} und {{m}}",
      "gruppe": "Grundlagen für „{{thema}}“",
      "spaeter": "Wenn der Schulstoff sitzt",
      "spaeterTitel": "Themen späterer Schuljahre",
      "ansatzTitel": "Unser Ansatz",
      "ansatz": "Hausaufgabenhilfe arbeitet am Thema von heute. Wir setzen an der Wurzel an: dort, wo eine Lücke entstanden ist, und bei den Grundlagen für die nächste Arbeit, bevor sie gebraucht werden.",
      "dazuTitel": "Was dazu gehört",
      "dazu1": "ein Lernpfad, der auf {{wessen}} Stärken und Lücken zugeschnitten ist",
      "dazu1OhneName": "ein Lernpfad, der auf die Stärken und Lücken Ihres Kindes zugeschnitten ist",
      "dazu2": "Aufgaben, die zu den eigenen Interessen passen",
      "dazu3": "kleine Erfolge, die sichtbar werden und motivieren",
      "dazu4": "ein Coach vor Ort, der den Plan prüft und anpasst",
      "fuer": "für",
      "danach": "danach",
      "schritt": "Schritt {{n}}",
      "uebt": "Das üben wir",
      "spaeterText": "So baut {{name}} schon jetzt für die nächsten Schuljahre vor.",
      "spaeterTextOhneName": "So baut Ihr Kind schon jetzt für die nächsten Schuljahre vor."
    },
    "s5": {
      "fazit": {
        "grundlagen": "{{wessen}} Grundlagen aus {{stufe}} sitzen weitgehend.",
        "luecken": "Die Lücken stammen vor allem aus {{stufe}}, besonders bei {{felder}}.",
        "fahrplan_one": "Sie werden in der nächsten Klassenarbeit wieder gebraucht.",
        "fahrplan_other": "Sie werden in den nächsten {{count}} Klassenarbeiten wieder gebraucht.",
        "sorgfalt": "Die Fehler deuten eher auf fehlende Sorgfalt als auf fehlendes Verständnis.",
        "start": "Wir beginnen mit den Voraussetzungen für „{{thema}}“."
      },
      "ziele": {
        "vorbereitet": "{{name}} geht gut vorbereitet in die Arbeit zu „{{thema}}“, weil die Grundlagen dafür vorher sitzen.",
        "vorbereitetOhneName": "Ihr Kind geht gut vorbereitet in die Arbeit zu „{{thema}}“, weil die Grundlagen dafür vorher sitzen.",
        "spaeterEins": "Wenn in der Schule „{{a}}“ drankommt, fängt {{name}} nicht bei null an, sondern baut auf sicherem Stoff auf.",
        "spaeterEinsOhneName": "Wenn in der Schule „{{a}}“ drankommt, fängt Ihr Kind nicht bei null an, sondern baut auf sicherem Stoff auf.",
        "spaeterZwei": "Wenn in der Schule „{{a}}“ und „{{b}}“ drankommen, fängt {{name}} nicht bei null an, sondern baut auf sicherem Stoff auf.",
        "spaeterZweiOhneName": "Wenn in der Schule „{{a}}“ und „{{b}}“ drankommen, fängt Ihr Kind nicht bei null an, sondern baut auf sicherem Stoff auf.",
        "sorgfalt": "{{name}} kontrolliert die eigenen Rechnungen selbst und verliert weniger Punkte durch Flüchtigkeitsfehler.",
        "sorgfaltOhneName": "Ihr Kind kontrolliert die eigenen Rechnungen selbst und verliert weniger Punkte durch Flüchtigkeitsfehler.",
        "weitere": "Auch die übrigen Lücken schließen wir nach und nach, damit spätere Themen auf festen Grundlagen aufbauen."
      },
      "keineNoten": "Wir versprechen keine Noten. Uns geht es darum, zu verstehen, woran es hakt, und {{name}} Schritt für Schritt voranzubringen.",
      "keineNotenOhneName": "Wir versprechen keine Noten. Uns geht es darum, zu verstehen, woran es hakt, und Ihr Kind Schritt für Schritt voranzubringen.",
      "preise": {
        "einblenden": "Preise einblenden",
        "ausblenden": "Preise ausblenden",
        "proMonat": "{{preis}} im Monat"
      }
    }
  }
}
```

**`praesentation.json`, Abschnitt `v4`:**

```json
{
  "v4": {
    "leiste": {
      "1": "Überblick",
      "2": "Lernstand",
      "3": "Klassenarbeiten",
      "4": "Förderansatz"
    },
    "s1": {
      "lead": "{{name}} findet meist den richtigen Weg. Fehler entstehen eher durch fehlende Sorgfalt als durch fehlendes Verständnis.",
      "leadOhneName": "Ihr Kind findet meist den richtigen Weg. Fehler entstehen eher durch fehlende Sorgfalt als durch fehlendes Verständnis.",
      "weiter": "Weiterwischen zu {{wessen}} Lernstand",
      "weiterOhneName": "Weiterwischen zum Lernstand",
      "fahrplanKicker": "{{wessen}} Klassenarbeiten in diesem Schuljahr",
      "fahrplanKickerOhneName": "Die Klassenarbeiten in diesem Schuljahr",
      "eckdaten": {
        "aufgaben": "Aufgaben bearbeitet",
        "bereiche": "Bereiche geprüft",
        "sicher": "sicher",
        "uebung": "Übungsbedarf",
        "zeile": "{{fach}} · Klasse {{klasse}} · {{schule}} · rund {{minuten}} Minuten"
      }
    },
    "s2": {
      "titel": "{{wessen}} Kompetenzprofil.",
      "titelOhneName": "Das Kompetenzprofil.",
      "desc": "In rund {{minuten}} Minuten hat {{name}} {{aufgaben}} Aufgaben bearbeitet. Jedes Kästchen ist ein geprüfter Bereich. Antippen zeigt, was dahintersteckt und für welche Klassenarbeit es wichtig ist.",
      "descOhneName": "In rund {{minuten}} Minuten wurden {{aufgaben}} Aufgaben bearbeitet. Jedes Kästchen ist ein geprüfter Bereich. Antippen zeigt, was dahintersteckt und für welche Klassenarbeit es wichtig ist.",
      "wichtig": "Wichtig für"
    },
    "s3": {
      "kicker": "Klassenarbeiten",
      "titel": "Was das für die nächsten Arbeiten heißt.",
      "karte": "Klassenarbeit {{n}}",
      "offen": "{{bereich}} war noch unsicher. Das wird bei „{{thema}}“ wieder gebraucht."
    },
    "s4": {
      "titel": "Daran würden wir zuerst arbeiten.",
      "desc": "In der Reihenfolge der nächsten Klassenarbeiten. Einen Punkt antippen, um zu sehen, was wir dort angehen.",
      "fokusVon": "Förderfokus {{n}} von {{m}}",
      "sitzt": "Sitzt schon",
      "angehen": "Das gehen wir an",
      "zurueck": "zurück",
      "weiter": "weiter",
      "schliessen": "Schließen",
      "fokus": "Förderfokus {{n}}",
      "ziel": "Ziel: {{ziel}}",
      "sorgfalt": {
        "titel": "Sorgfalt",
        "zeile": "in jeder Session",
        "text": "{{name}} versteht viel. Wir üben, die eigene Rechnung zu kontrollieren.",
        "textOhneName": "Ihr Kind versteht viel. Wir üben, die eigene Rechnung zu kontrollieren."
      }
    }
  }
}
```

Die Signale, Stände, Quellen, Blocktitel und die Zeile „Voraussetzung für …“ nutzt die Präsentation aus `elternbericht:v4.*`.

## Anhang B · Kontrollwerte Batu (Testlauf 24.10.2026, mit den Kanten aus v3)

Aus dem PDF v3 (Variante B, Seite 3) abgeleitet. V4-1 rechnet sie gegen dbread nach. Weicht eine Rechnung ab: STOPP und melden, nicht die Erwartung anpassen.

- **Station 1:** Reelle Zahlen und Wurzeln, „geschrieben“ (Override bzw. Erstgespräch).
- **Kommende Stationen in Plan-Reihenfolge:** Quadratische Funktionen (`fehlt`, nächste Arbeit) · Kreise, Prismen und Zylinder (`fehlt`) · Der Satz des Pythagoras und Berechnungen in Körpern (`fehlt`). Weitere Plan-Themen ohne geprüften Bereich stehen dahinter mit `ohne`.
- **Fehlt mindestens, je Block:**
  - Quadratische Funktionen: Binomische Formeln, Faktorisieren mit binomischer Formel
  - Kreise: Flächeneinheiten, Fläche von Dreieck und Parallelogramm, Werte in Terme einsetzen
  - Pythagoras: Teilweise die Wurzel ziehen
- **Sitzt mindestens:**
  - Quadratische Funktionen: Gleichungen aufstellen (Sachkontext)
  - Pythagoras: Punkte im Koordinatensystem
- **Lernpfad:** Terme & Gleichungen (Voraussetzung für Klassenarbeit 2) → Gruppe „Grundlagen für „Kreise, Prismen und Zylinder““ aus Größen und Geometrie (Klassenarbeit 3) → Teilweise die Wurzel ziehen (Klassenarbeit 4) → später: Daten & Zufall.
- **Ziele:**
  1. vorbereitet (Quadratische Funktionen)
  2. später mit Kreise und Pythagoras
  3. Sorgfalt (das Muster liegt laut v3 vor: 6 von 11 eingeordneten Fehlern)
  4. übrige Lücken (Additionsverfahren, Gleichungssysteme grafisch, Trapez, Drachen und Raute, Summenregel stehen unter „Wird später wichtig“)
- **Seite 3, Einstiegssatz:** „Die Arbeit zu Reelle Zahlen und Wurzeln hat {Rufname} laut Ihren Angaben schon geschrieben. Deshalb beginnt diese Übersicht mit Klassenarbeit 2.“
