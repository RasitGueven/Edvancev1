# Anforderung · Tablet-Präsentation der Lernstandsanalyse (T1–T4)

Stand 19.10.2026 · für Rasit zur Umsetzung mit Claude Code · Grundlage: Gründer-Gespräch Ashkan/Rasit/Tolunay vom 18.10.2026 zur Vor-Ort-Fassung, Dummy V7 (`Edvance_Tablet_V7_Gespraech_18-10.html`), Bauauftrag R7 (Druckbogen) · Code-Stand `Edvancev1` dev @ `22e23c3`, R7-1 auf `feat/rasit-report-r7-daten` @ `1041cdf` · gegengeprüft von einer zweiten Instanz.

**Worum es geht.** Nach der LSA sitzt der Gründer mit Eltern und Kind zusammen und geht die Ergebnisse auf dem iPad durch. Zuerst kommt ein Intro mit Logo und Namen, dann vier Stationen: Überblick, Lernstand, Einordnung, Förderansatz. Ganz unten steht eine Zeile mit der Paketempfehlung, ohne Preise. Pakete und Preise sind vorher ohne Kind besprochen. Danach geht es in den Vertragsabschluss. Den ausführlichen Bericht bekommen die Eltern gedruckt und per Mail (R7). Die Präsentation gibt es bisher nur als Dummy mit Musterwerten. Dieser Auftrag baut sie in Edvancev1 mit denselben Daten und derselben Rechnung wie den Druckbogen R7, damit Tablet und Papier dieselben Zahlen zeigen.

## Vorab: Was „übersprungen“ in den Daten ist

Im Gespräch vom 18.10. galt „nicht untersucht“ als die Bereiche, bei denen das Kind „Weiß ich nicht“ gewählt hat. Das trifft nicht zu. Der Code zeigt Folgendes:

- **„Nicht untersucht“** sind Bereiche des Katalogs, die die LSA gar nicht abgefragt hat.
  - Im R6-Profil gilt: vorhanden minus geprüft je Familie (`familienBefunde` in `src/lib/report/familien.ts`).
  - In R7 gilt: Katalog minus untersucht (`zaehle()`).
  - Ilkays „16“ im Muster waren 41 Familienbereiche (Bestand zur Zeit des Musters) minus 25 geprüfte. Mit dem heutigen R6-Bestand wären es 64 von 89, mit dem R7-Nenner sind es 103 von 130.
- **„Weiß ich nicht“** erfasst die LSA je Antwort: `lsa_responses.abgabeart = 'weiss_nicht'`, ein leeres Feld ist `'leer'` (Migration a13). Beides gilt nicht als falsche Antwort und erzeugt kein Fehlbild (af1, af2).
- **Je Bereich gibt es bis zu zwei Proben** (`lsa_urteil_aufloesung`, a15; Mehrteiler af7):
  - zweimal „Weiß ich nicht“ ergibt `nicht_angesetzt`
  - „Weiß ich nicht“ und richtig ergibt `traegt_teilweise`
  - „Weiß ich nicht“ und falsch, ebenso falsch und „Weiß ich nicht“, ergibt `traegt_nicht`
  - richtig im Auswahlformat und dann „Weiß ich nicht“ ergibt `traegt_teilweise`
  - Endet die Analyse nach einer „Weiß ich nicht“-Probe, bleibt `nicht_angesetzt` vorläufig stehen (`offen`).
- **Das R6-Profil und R7 zählen `nicht_angesetzt` zum Übungsbedarf**, also alles außer `traegt`. Nur der R6-Abschnitt „Was wir uns genauer ansehen“ lässt es ganz weg (`lsaReportSkills.ts`). Die LSA steigt bei `nicht_angesetzt` ab wie bei „falsch“ (a16 ff.), die Lernpfad-Übernahme macht daraus „noch nicht sicher“.
- **Ilkays echte Analyse** (6d868c5f): 27 direkt geprüfte Bereiche, 11 `traegt`, 14 `traegt_nicht`, 2 `traegt_teilweise`, **kein** `nicht_angesetzt`.

**Folgen für diesen Auftrag:**
- **Bedeutung:** „Übersprungen“ heißt `nicht_angesetzt`. Diese Bereiche stecken schon heute im Übungsbedarf, die befürchtete Verdopplung („32 statt 16“) entsteht nicht.
- **Darstellung:** Die Präsentation zeigt übersprungene Bereiche mit eigenem Punktmuster innerhalb des Übungsbedarfs und nennt sie im Detail beim Namen. „Nicht untersucht“ erscheint nie als Segment, nur als Zahl im Erklärtext.
- **Häufigkeit:** Weil schon ein einziger Versuch den Bereich zu Übungsbedarf macht, wird „übersprungen“ selten sein. Bei Ilkay gibt es keinen solchen Bereich, der Testfall `uebersprungen` zeigt das Muster. Wie oft einzelne „Weiß ich nicht“-Antworten vorkommen, meldet T1 aus Prod. Damit entscheiden die Gründer, ob auch diese Bereiche ein Zeichen bekommen sollen (Abnahme 8).

## Vor dem Start (Rasit)

1. **R7-1 mergen** (PR von `feat/rasit-report-r7-daten`) und dessen Migration nach CLAUDE.md §10 einspielen. T1 baut auf `baueElternbericht`, den Fixtures und dem Namespace `elternbericht` auf. T2 wartet zusätzlich auf R7-2, weil beide dieselben Stellen in `ReportPage.tsx`, `globals.css` und CLAUDE.md §11 ändern.
2. **Zwei Dateien herunterladen** (sie landen im Downloads-Ordner): `Anforderung-Tablet-Praesentation.md` und `Edvance_Tablet_V7_Gespraech_18-10.html` aus dem Projekt (Ordner `claude/`). T1 legt sie nach `docs/report/praesentation/`.
3. **Zählweise „übersprungen“** (Entscheidung 4): Standard ist „kombiniert“. Übersprungenes zählt dann zum Übungsbedarf, genau wie auf dem Papier. Wer „getrennt“ will, sagt es vor T1; es ist eine einzige Konstante.
4. **Ausnahmen von den Designregeln** (Entscheidung 11): Grün und Rosé wie im Druckbogen, Farbverläufe für die Kugeln und Kurvenpunkte, ruhige Bewegung. Wer das nicht will, sagt es vor T2.
5. **Kopfsätze:** Lena nimmt die R7-Kopfsätze (`docs/report/r7/kopf-texte.md`) möglichst vor der iPad-Abnahme ab. Bis dahin steht in Station 01 die neutrale Ersatzüberschrift statt „{Name} zeigt sichere Ansätze …“.
6. **Schrift und Farben** folgen dem Druckbogen über dieselben Tokens (Fraunces, E7-Farben). Wird R7 auf „Marke“ umgestellt, zieht die Präsentation mit.

| Paket | Inhalt | Worktree · Branch | wartet auf |
|---|---|---|---|
| T1 Daten (Foundation) | Dateien ablegen, Typen, Rechnung für die vier Stationen, Fixtures, Texte, Tokens, Tests | `../Edvancev1-tp1` · `feat/rasit-praesentation-daten` | R7-1 gemergt |
| T2 Rahmen | Vollbild-Ebene (Portal), Kopf, Stationsleiste mit Eddie, Intro, Einrasten, Bewegung, Einstieg im Report, Laden, Vorschauseite, Ansichtstests, leere Hüllen der vier Stationen | `../Edvancev1-tp2` · `feat/rasit-praesentation-rahmen` | T1 und R7-2 gemergt |
| T3 Stationen 01, 02 | Überblick, Lernstand | `../Edvancev1-tp3` · `feat/rasit-praesentation-stationen12` | T2 gemergt |
| T4 Stationen 03, 04 | Pyramide, Kurve mit Förderfokus, Empfehlungszeile | `../Edvancev1-tp4` · `feat/rasit-praesentation-stationen34` | T2 gemergt |

- **Parallel:** T3 und T4 laufen parallel, neben R7-3 und R7-4 sind das höchstens vier Agenten. Beide ändern nur ihre eigenen Stationsdateien. Rahmen, Ansichtstests und Invarianten legt T2 so an, dass T3 und T4 nichts daran ändern müssen.
- **R7-Dateien werden nur gelesen:** `src/lib/report/elternbericht/**`, `src/components/edvance/elternbericht/**`, `src/styles/elternbericht/**`, `elternbericht.json`, `e2e-druck/**`.
- **Stand von dev holen:** Vor dem PR wird `origin/dev` in den eigenen Branch gemergt. Kein Rebase, kein Force-Push; `guard-bash.sh` sperrt ihn.
- **Ports und Bilder:** Ansichtstests laufen auf Port 5185 (T2), 5186 (T3) und 5187 (T4). Bilder gehen nach `docs/report/praesentation/abnahme/t2` bzw. `t3`, `t4`.
- **Retro und ROADMAP:** je Paket eine Retro. Den ROADMAP-Abschnitt „Tablet-Präsentation“ legt T1 an, danach ergänzt ihn nur Rasit.

**Zeitplan (Vorschlag).** Ziel ist der Einsatz bei der Test-LSA am Sa 31.10. Verantwortlich ist Rasit (Claude Code), die Abnahme machen die Gründer gemeinsam.

| Wann | Was |
|---|---|
| Mo 19.10. | R7-1 mergen |
| bis Mi 21.10. | T1 |
| bis Do 22.10. | R7-2 gemergt |
| bis Fr 23.10. | T2 |
| bis Di 27.10. | T3 und T4 parallel |
| bis Mi 28.10. | Lena nimmt die Kopfsätze ab |
| Do 29.10. | iPad-Abnahme auf edvancev1.vercel.app |
| Fr 30.10. | Puffer |

Für die iPad-Abnahme reicht der Merge nach dev: In Vercel ist dev der Production-Branch (Stand 08.10.; vorher prüfen). Für Abnahme 2 sind R7-3 und R7-4 hilfreich; fehlen sie noch, gelten die Zahlen aus `docs/report/r7/offene-punkte-r7-1.md`.

**Nicht in diesem Auftrag:**
- Änderungen am Druckbogen R7 oder am Report R6
- Regel, welches Paket empfohlen wird
- Preise, Laufzeiten und die Vertragsabschluss-Strecke
- Gewichtung von „Weiß ich nicht“ in der LSA-Auswahl
- Kennzeichnung einzelner „Weiß ich nicht“-Antworten
- Versand, PDF oder Elternzugang der Präsentation
- edvance-app und ein Telefon-Layout
- Bearbeiten von Texten in der Präsentation

---

## Entscheidungen (gelten für alle Pakete)

**1. Ort und Einstieg.**
- Die Präsentation entsteht in **Edvancev1**, nicht in der edvance-app. Nur Edvancev1 liest Report-Daten, Coach-Notizen und Pakete. Der Gründer öffnet sie auf seinem iPad, angemeldet als Admin.
- **Route:** `/admin/report/:sessionId` bleibt. `?ansicht=praesentation` öffnet die Präsentation als Vollbild, Schließen entfernt nur diesen Parameter. `src/App.tsx` wird nicht angefasst (474 Zeilen; der post-edit-Hook lehnt Änderungen an Dateien über 400 Zeilen ab).
- **Vollbild per Portal:** Die Ebene wird mit `createPortal(…, document.body)` gerendert. Der Inhaltsbereich der AppShell ist ein `@container` (`AppShell.tsx`, `container-type: inline-size`). Darin wäre `position: fixed` an die Inhaltsspalte gebunden und würde mitscrollen.
- **Knopf „Präsentation“** in den Aktionen des Reports. Er ist auch bei laufender Analyse aktiv; dann zeigt die Präsentation im Kopf einen Chip „Analyse läuft noch“ (wie der Hinweis in R6/R7, keine Sperre).
- **Rechte** wie der Report (admin, coach). Keine neue Tabelle, keine Migration, kein DDL.

**2. Eine Rechnung für Tablet und Papier.**
- `baueElternbericht` (R7-1) ist die einzige Quelle für Zahlen, Themenfelder, Profil, Pyramide, Schwerpunkte und „danach“.
- Die Präsentation teilt diese Werte nur weiter auf (übersprungen je Zeile und Ebene, Stufen je Schwerpunkt). Neu rechnet sie nur die Felder für den Überblick, die Empfehlung und die Lage der Kurvenpunkte.
- **Gleichheit mit dem Druckbogen:** Für jeden Testfall sind sicher, Übungsbedarf (mit übersprungen), untersucht und Katalog auf Tablet und Druckbogen gleich. Die Pyramide hat dieselben Ebenen, die Schwerpunkte dieselbe Reihenfolge und dieselben Bereiche.
- Ändert die R7-Abnahme Nenner oder Reihenfolge, zieht die Präsentation ohne eigenen Auftrag mit.

**3. Vier Zustände.** Grundlage sind nur direkt geprüfte Urteile (`belegt_direkt`). Mitbelegte und `ungeprueft` zählen nie, wie in R7.

| Zustand | Daten | Tablet | Druckbogen R7 |
|---|---|---|---|
| sicher | `traegt` (auch vorläufig) | grün | sicher |
| Übungsbedarf | `traegt_nicht`, `traegt_teilweise` | rosé | Übungsbedarf |
| übersprungen | `nicht_angesetzt` (auch vorläufig) | Punktmuster, nach Entscheidung 4 | Übungsbedarf, ohne Kennzeichnung |
| nicht untersucht | Katalog ohne direktes Urteil | nur als Zahl im Erklärtext | nicht untersucht (Streifen) |

Streifen bedeuten im Druckbogen „nicht untersucht“. Das Tablet nutzt deshalb für „übersprungen“ nie Streifen, sondern Punkte. Das Gespräch ist genau an dieser Verwechslung entstanden.

**4. Zählweise „übersprungen“.**
- Konstante `UEBERSPRUNGEN_ANZEIGE` in `src/lib/report/praesentation/einstellungen.ts`, Standard `'kombiniert'`. In der Ansicht gibt es keinen Schalter.
- **kombiniert:** Übungsbedarf wie auf dem Papier, übersprungen zählt mit. Das Punktmuster steht in Rosé, die dritte Zahl heißt „davon übersprungen“.
- **getrennt:** Übungsbedarf ohne übersprungen. Das Punktmuster ist neutral, die dritte Zahl heißt „übersprungen“.
- Beide Fassungen werden gebaut und getestet. Dritte Zahl, Erklärsatz und Legendeneintrag erscheinen nur, wenn es übersprungene Bereiche gibt.

**5. Intro, Kopf und Stationsleiste.**
- **Intro:** Ablauf, Zeiten und Logo exakt wie im Dummy (Logo gleitet ein, alles steht nach etwa 2,2 s, Wischen geht jederzeit).
  - Kicker „Lernstandsanalyse {Fach}“ statt „Lernstand Mathematik“
  - Rufname, ohne Namen „Ihr Kind“
  - Unterzeile
  - Knopf „Gemeinsam ansehen“
  - Kopf und Leiste erscheinen erst nach dem Intro.
- **Das Intro erscheint einmal je Öffnen.** Ist Station 01 erreicht, verlässt es den Fluss, ohne dass die Ansicht springt (wie `retireIntro` im Dummy). Neu erscheint es erst nach Schließen und erneutem Öffnen.
- **Kopf:**
  - Logo (Tippen führt zu 01)
  - Chip „Testdaten“ nur bei `testlauf`
  - Chip „Analyse läuft noch“ bei `status = 'in_progress'`
  - Stationsanzeige „02 / 04 · Lernstand“
  - rechts der Knopf „Schließen“ (X, 44 px) an der Stelle des Einstellungsknopfs
- **Stationsleiste links:** vier Einträge mit Nummer und Namen. Die Kugel (Eddie) wandert zur aktuellen Station, Tippen springt dorthin. Die Pfadlinie bleibt aus.
- **Laden:** Wird die Präsentation direkt mit `?ansicht` aufgerufen, zeigt die Ebene `LoadingPulse`, bis Report, Notizen und Pakete geladen sind. Scheitern die Pakete, entfällt nur die Empfehlungszeile (console.warn). Lädt R7-2 die Pakete schon, nutzt die Präsentation denselben Zustand; die Pakete werden nur einmal geladen.

**6. Station 01 · Überblick.**
- Kicker „01 — Ilkays Ausgangspunkt“ (Genitiv über `genitiv()`, ohne Namen „Ausgangspunkt“).
- **Überschrift:** der Kopfsatz wie auf Seite 1 des Druckbogens (`report_bausteine`, Slot `kopf`, Fall `kopfFall`). Fehlt er, gilt `elternbericht:s1.kopfErsatz` (ohne Namen `s1.kopfErsatzOhneName`). Keine farbige Teilhervorhebung, höchstens vier Zeilen; die Schriftgröße passt sich an.
- **Leitsatz** je Fall (`s1.lead.gemischt`, `.sicher`, `.uebung`). Darunter „Mathematik · Klasse 10“ und, wenn vorhanden, „Im Blick: {nächstes Thema}“.
- **Zwei Karten** „Schon gelungen“ und „Gezielt üben“, im Querformat im Bild rechts wie im Dummy (Kreise, Kugel). Unter 800 px Breite (iPad mini hoch) stehen die Karten unter dem Leitsatz und das Bild entfällt. Die Karten fallen also nie weg, anders als im Dummy.
  - „Schon gelungen“: bis zu zwei Themenfelder mit mehr sicheren Bereichen als Bereichen mit Übungsbedarf.
  - „Gezielt üben“: bis zu zwei der übrigen Themenfelder mit Übungsbedarf.
  - Sortiert absteigend nach Anzahl, bei Gleichstand nach der Reihenfolge der Themenfelder. Kein Feld steht in beiden Karten (dieselbe Regel wie „Was die Grafik zeigt“ in R7-3).
- **Leere Karte:**
  - Gibt es gar nichts Sicheres bzw. keinen Übungsbedarf, gilt `elternbericht:s1.blick.keinSicher` bzw. `keineUebung`.
  - Gibt es Sicheres oder Übungsbedarf, nur in keinem Feld überwiegend, gilt `s1.sicherEinzeln` bzw. `s1.uebungEinzeln`. Die Zahl steuert die Pluralform, als Beispiel dient der erste Bereich aus `bericht.sicherListe` bzw. `uebungListe`.
- **Fußzeile** „Weiterwischen …“.

**7. Station 02 · Lernstand.**
- Kicker „02 — Lernstand“, Titel „Was der Test zeigt.“
- **Zahlen:** sicher eingestuft · Übungsbedarf · übersprungen (nach Entscheidung 4).
- **Erklärtext:** „27 von 130 Bereichen bis Klasse 10 untersucht.“ (Werte aus `zaehlung`). Gibt es übersprungene Bereiche, folgt der Satz „Übersprungen heißt …“.
- **Kompetenzprofil:** Titel „Ilkays Kompetenzprofil“, dazu der Hinweis „Jedes Segment …“.
  - Eine Zeile je Themenfeld mit mindestens einem untersuchten Bereich, in der Reihenfolge der Themenfelder. Felder ohne Untersuchtes entfallen.
  - Je untersuchtem Bereich ein Segment: erst sicher, dann Übungsbedarf, dann übersprungen.
  - Rechts „5 von 8“ (untersucht von vorhanden) und darunter klein „2 sicher · 3 Übungsbedarf“, je nach Zählweise mit „davon 1 übersprungen“ bzw. „1 übersprungen“; nur Teile, die nicht null sind. Danach kommt der Pfeil.
- **Detail:** Antippen öffnet die Details einer Zeile, höchstens eine ist offen. Beim Öffnen wird die Zeile in den sichtbaren Bereich der Liste geholt.
  - Spalten: „Sicher im Test“, „Hier weiterüben“ (nur wenn nicht leer) und „Übersprungen · „Weiß ich nicht““ (nur wenn nicht leer).
  - Jede Spalte zeigt alle Bereiche mit Label, sortiert nach Klasse und Label.
  - Gibt es weder Übungsbedarf noch Übersprungenes, steht `s2.detail.keineUebung`. Ohne Sicheres steht `s2.detail.keinSicher`.
- Legende Sicher · Übungsbedarf · (Übersprungen), dazu der Hinweis zum Antippen.
- **Barrierefreiheit:** Die Spur ist `aria-hidden`, jede Zeile hat einen Vorlesetext.

**8. Station 03 · Einordnung.**
- Kicker „03 — Einordnung“, Titel „Wo im Lernstoff die Themen liegen.“, Untertitel aus Anhang A.
- **Pyramide aus `bericht.pyramide`:** Ebenen von oben nach unten, nur die vorhandenen. Die unterste ist 100 % breit, jede darüber 19 Prozentpunkte schmaler (feste Klassen je Position).
- **Je Ebene:**
  - Name (`elternbericht:s3.ebene.*`)
  - Klassenangabe als Pille (`klassenAngabe` → `elternbericht:stufe.*` bzw. `stufe.spanne`)
  - ein Segment je Bereich: sicher, Übungsbedarf, übersprungen
  - Zählung wie in Station 02, nur Teile, die nicht null sind
- **Keine Namen in der Pyramide;** die stehen im Druckbogen. Lücke zwischen Segmenten: 4 px bis 16 Segmente, 2 px bis 30, darüber 1 px.
- **Lesehilfe** rechts, im Hochformat darunter: Label, Titel, Text (Anhang A) und `elternbericht:s3.lesen.hinweisEineEbene`. Kein Satz behauptet, dass eine Ebene auf einer anderen aufbaut.

**9. Station 04 · Förderansatz und Empfehlung.**
- Kicker „04 — Förderansatz“, Titel „Daran würden wir zuerst arbeiten.“, Untertitel nach der Zahl der Schwerpunkte (Anhang A).
- **Kurve in der Form des Logos:** Pfad aus dem Dummy, Startpunkt navy, Pfeilspitze gold.
  - Darauf ein gelber Kreis je Schwerpunkt aus `bericht.schwerpunkte`, höchstens vier, Reihenfolge wie R7, ohne Zahlen.
  - Beschriftung: Themenfeld und Klassenangabe der Übungsbedarf-Bereiche dieses Felds („Klasse 5/6“, über mehrere Stufen „Klasse 5–8“).
- **Lage der Punkte** als Anteil der Kurvenlänge:

  | Punkte | Lage | Seite der Beschriftung |
  |---|---|---|
  | 4 | 0,30 · 0,52 · 0,72 · 0,90 (wie Dummy) | unten, links, links oben, links oben |
  | 3 | 0,30 · 0,60 · 0,90 | unten, links, links oben |
  | 2 | 0,30 · 0,85 | unten, links oben |
  | 1 | 0,30 | unten |

  Beschriftungen überdecken weder einander noch die Kurve noch die Karte (Ansichtstest).
- **Auswahl:** Antippen wählt einen Punkt, der erste ist vorgewählt, Pfeiltasten wechseln.
- **Karte „Förderfokus“:**
  - Pille „Stoff aus Klasse 5/6“, Titel = Themenfeld.
  - Zwei Kästen „Sicher im Test“ und „Hier üben wir“ mit je bis zu drei Bereichen, danach „+n weitere“. Gibt es im Feld nichts Sicheres, steht links `s4.keinSicher`.
  - Lage: im Querformat rechts neben der Kurve wie im Dummy, im Hochformat darunter. Bei der Abnahme bestätigen.
- **Unter der Karte:**
  - „Danach nehmen wir … dazu.“ (`elternbericht:s4.danach`), nur wenn `bericht.danach` nicht leer ist
  - der Hinweis zum Arbeitsvorschlag
  - die Empfehlung
- **Empfehlung:**
  - Gleiche Schriftgröße wie der Hinweis, mit kleinem gelbem Punkt.
  - Text „Unsere Empfehlung für Ilkay: **Paket Standard**“. Dahinter steht „· Basic ist ebenfalls möglich.“, außer das Paket ist schon Basic (Beschluss Ashkan/Tolunay vom 17.10.; bei der Abnahme bestätigen).
  - Das Paket kommt aus dem Ausblick des Reports („Passendes Paket“, `lsa_report_notes.paket`, auch ungespeichert). Der Name kommt aus `tiers` wie im Druckbogen Seite 5: aktive Pakete nach `sort_order`, basis → 1., standard → 2., premium → 3.
  - Sind nicht genau drei Pakete aktiv, entfällt die Zeile (console.warn). Ohne gewähltes Paket entfällt sie ebenfalls.
  - Nie ein Preis, keine Laufzeit.
- **Ohne Schwerpunkt** (kein Übungsbedarf): Titel `elternbericht:s4.titelKeiner`, darunter `elternbericht:s1.blick.ansatzKeiner`. Keine Kurve, keine Karte, kein Hinweis zum Arbeitsvorschlag; die Empfehlung bleibt. Der Baustein `fazit`/`keine` wird nicht genutzt; seine Entwürfe sagen noch „tragen“.

**10. Bewegung, Bedienung, Geräte.**
- **Einrasten je Station** (scroll-snap). Jede Station füllt den Bildschirm.
- **Erster Besuch einer Station: Choreografie wie im Dummy.** Erst die Überschrift, dann die Zahlen, dann die Grafik:
  - in 02 erscheinen die Zeilen nacheinander, die Segmente wachsen
  - in 03 bauen sich die Ebenen von unten nach oben auf
  - in 04 zeichnet sich die Linie, die Punkte erscheinen entlang der Linie
  - Zeiten und Kurven aus dem Dummy-CSS (`--v6-ease`, `--v6-soft`, Verzögerungen je Element)
- **Wiederbesuch** zeigt alles sofort und ruhig. Bei `prefers-reduced-motion` erscheint alles sofort, ohne Bewegung.
- **Nur ein Detail gleichzeitig offen**, damit es auf dem iPad flüssig bleibt.
- **Geräte:** Das iPad im Hochformat ist der Hauptfall (der Gründer hält es), das Querformat zählt genauso. Jede Station passt ohne Scrollen auf:

  | Gerät | Hochformat | Querformat |
  |---|---|---|
  | iPad 10./11. Gen., iPad Air 11 | 820×1180 | 1180×820 |
  | mit Safari-Leisten | 820×1100 | 1180×740 |
  | iPad mini | 744×1133 | 1133×744 |
  | iPad mini mit Safari-Leisten | 744×1060 | – |
  | iPad Pro 13 | 1032×1376 | 1376×1032 |

- **Station 02 mit geöffnetem Detail:** Die Zeilenliste darf dann in sich scrollen, die Station nicht.
- **Touch-Ziele mindestens 44 px**, auch auf niedrigen Bildschirmen. Der Dummy geht dort auf 39 px; das gilt nicht. Kein Telefon-Layout.

**11. Gestaltung und Texte.**
- **Farben und Schrift wie der Druckbogen:** `--color-eb-*`, `--font-eb-titel` (Titel, große Zahlen), `--font-body` (alles andere).
- **Dazu die Tokens `--color-tp-*` aus Anhang B.** Jeder andere Farbwert des Dummys wird auf das nächstgelegene eb-Token gerundet. Keine Hex-Werte außerhalb von tokens.css, Inline-Styles nur für berechnete Werte.
- **Fehlende Tokens:** Fehlt T2, T3 oder T4 ein Token, gilt STOPP mit Meldung. Tokens legt nur T1 bzw. Rasit an.
- **Ausnahmen** für `src/components/edvance/praesentation/**` und `src/styles/praesentation/**`. T2 trägt sie in CLAUDE.md §11 ein und ergänzt bei „Hard Limits“ (Design-Invarianten) einen Verweis:
  - eigene Kästen statt EdvanceCard
  - mehr als drei Schriftgrößen
  - Grün und Rosé für sicher/Übungsbedarf wie im Druckbogen (Ausnahme von INV-4.4)
  - Farbverläufe nur für die Kugeln (Eddie, Kugel in Station 01, Kurvenpunkte, Empfehlungspunkt), den Lichtschein im Intro und das Punktmuster „übersprungen“
  - ruhige Bewegung nach Dummy, mit `prefers-reduced-motion`
  - `src/styles/praesentation/**` gehört zur Präsentation, nicht zum Student-Fenster.
- **Texte:** Anhang A (Namespace `praesentation`) wörtlich. Wo der Druckbogen dasselbe sagt, gilt sein Schlüssel aus `elternbericht` (Liste unter Anhang A). `elternbericht.json` ändert dieser Auftrag nicht.
- **Sprachregeln wie R7 Entscheidung 9:**
  - „Sie“-Form
  - kein Pronomen für das Kind (Name, Genitiv, sonst „Ihr Kind“)
  - nie „gemeistert“, kein „trägt“
  - keine Note, kein Prozentwert, keine Prognose, kein Vergleich mit anderen Kindern
  - kein Satz, der behauptet, ein Thema baue auf einem anderen auf
  - kein roher Schlüssel im Text
  - Fehlt ein Datum, entfällt der Satz still.

**12. Bewusste Abweichungen vom Dummy.**
- **Zahlen, Themenfelder, Ebenen, Schwerpunkte und Texte kommen aus den Daten** (Ilkay: Anhang C). Der Dummy zeigt noch die alten Musterwerte: 9/16/16, drei Ebenen, andere Schwerpunkte.
- **Schraffur:** Im Dummy steht sie für nicht untersuchte Bereiche, beschriftet als „übersprungen“. Das war falsch. „Übersprungen“ bekommt ein Punktmuster, nicht Untersuchtes kein Segment.
- **Prototyp-Elemente entfallen:** Statt des Designvergleichs (Zahnrad) steht dort „Schließen“. Es gibt kein „Konzept · Testdaten“, keine „Gestaltungsstudie“ und keinen Satz „Vorläufige Testdaten …“. Der Chip „Testdaten“ erscheint nur im Testlauf.
- **Intro:** Kicker „Lernstandsanalyse {Fach}“ statt „Lernstand Mathematik“.
- **01:** Die Überschrift ist der Kopfsatz wie im Druckbogen, ohne farbige Hervorhebung. Die Karten kommen aus den Daten und bleiben unter 800 px sichtbar.
- **02:** Unter „x von y“ steht die Zählung je Zeile. Die Touch-Ziele haben immer 44 px.
- **03:** Ebenen und Namen wie im Druckbogen („Aktueller Unterrichtsstoff“ statt „Aktueller Stoff“). Die Lesehilfe kommt ohne „baut auf den Stufen darunter auf“ aus.
- **04:** Bereiche als Liste statt Symbolen („cm · kg“ gibt es in den Daten nicht). Kein Fließtext je Schwerpunkt. Der Untertitel kommt ohne „von den Grundlagen aufwärts“ aus, weil die Reihenfolge der R7-Regel folgt.
- **Farben** sind auf eb-Tokens gerundet. Sicher und Übungsbedarf haben dieselben Werte, die Grautöne weichen leicht ab.

**13. Ort im Code.**
- **Rechnung** unter `src/lib/report/praesentation/` (`einstellungen.ts`, `praesentation.ts`, `ueberblick.ts`, `empfehlung.ts`, `kurve.ts`, `fixtures.ts`, je Datei ein Test), Typen in `src/types/praesentation.ts` (Export über `src/types/index.ts`).
- **Ansicht** unter `src/components/edvance/praesentation/`: `Praesentation.tsx`, `Kopf.tsx`, `Leiste.tsx`, `Intro.tsx`, `Station1.tsx` bis `Station4.tsx`, Teile, Hook `useStationen.ts`, `vorschau/main.tsx`.
- **Styles** unter `src/styles/praesentation/`: `index.css` importiert `rahmen.css`, `intro.css` und `station1.css` bis `station4.css`; alles unter `.tp`. Ein Import in `globals.css`.
- **Texte** in `src/i18n/locales/de/praesentation.json`, registriert in `src/i18n/index.ts`. Farben als `--color-tp-*` in `src/styles/tokens.css`.
- **Einstieg:** Knopf, Weiche und Laden in `src/pages/admin/ReportPage.tsx`. Supabase nur über `src/lib/supabase/` (`listTiers`, vorhanden).
- **Vorschau:** `vorschau/praesentation.html`, nur im Dev-Server, ohne Supabase-Client.
- **Ansichtstests:** `playwright.praesentation.config.ts` und `e2e-praesentation/`.
- **Invarianten** in `src/test/invariants/inv4-praesentation.test.ts`. Doku unter `docs/report/praesentation/`.

---

## T1 · Daten (Foundation)

```
Du arbeitest im Repo Edvancev1 (WSL). Paket T1 (Foundation im Sinne der Hard Limits in CLAUDE.md: neue lib-, type- und Token-Dateien sind hier erlaubt): Daten, Rechnung, Texte und Farben für die Tablet-Präsentation der Lernstandsanalyse. Voraussetzung: R7-1 ist gemergt (src/lib/report/elternbericht/ mit baueElternbericht, bereicheAus, klassenAngabe, genitiv, fixtures/ mit FAELLE; Namespace elternbericht; Tokens --color-eb-*). Sonst STOPP.

## Ziel
Alles, was die vier Stationen zeigen, liegt als getestete reine Rechnung, als Text und als Farbtoken bereit, bevor eine Station gebaut wird. Die Präsentation rechnet nichts neu, was der Druckbogen R7 schon rechnet.

## Schritt 0
mkdir -p docs/report/praesentation && cp "/mnt/c/Users/rasit/Downloads/Anforderung-Tablet-Praesentation.md" docs/report/praesentation/Anforderung.md && cp "/mnt/c/Users/rasit/Downloads/Edvance_Tablet_V7_Gespraech_18-10.html" docs/report/praesentation/dummy-v7.html
Fehlt eine Datei: STOPP und Rasit fragen. Dann docs/report/praesentation/Anforderung.md lesen (Vorab, Entscheidungen 1–13, Anhang A–C) und den Dummy im Browser ansehen.

## Entscheidungen (nicht neu verhandeln)
1. Zustände (Anforderung, Entscheidung 3): sicher = zustand 'traegt', übersprungen = 'nicht_angesetzt', Übungsbedarf = alles andere direkt Geprüfte; jeweils auch bei offen = true. Gelesen aus data.erzaehlung.kompetenzen (SucheSkill.zustand). R7-Code (src/lib/report/elternbericht/**, src/types/elternbericht.ts) bleibt unverändert.
2. Typen in src/types/praesentation.ts (Export über src/types/index.ts):
   type TpAnzeige = 'kombiniert' | 'getrennt'
   type TpZahlen = { sicher: number; uebung: number /* OHNE übersprungen */; uebersprungen: number; untersucht: number; katalog: number; bisKlasse: number }
   type TpZeile = { feld: ThemenfeldKey; vorhanden: number; sicher: EbBereich[]; uebung: EbBereich[]; uebersprungen: EbBereich[] } // je Liste nach klasse, dann label (localeCompare 'de')
   type TpEbene = { ebene: EbeneKey; stufen: Stufe[]; sicher: number; uebung: number /* ohne */; uebersprungen: number }
   type TpSchwerpunkt = { feld: ThemenfeldKey; gemischt: boolean; stufen: Stufe[] /* der Übungsbedarf-Bereiche des Felds inkl. übersprungen, aufsteigend */; sicher: string[]; uebung: string[] /* Labels wie R7 */ }
   type TpUeberblick = { gelungen: ThemenfeldKey[]; ueben: ThemenfeldKey[]; beispielSicher: { label: string; anzahl: number } | null; beispielUebung: { label: string; anzahl: number } | null }
   type TpEmpfehlung = { paket: string; basis: string | null }
   type PraesentationDaten = { name: string | null; wessen: string | null; fach: string; klasse: number; naechstesThema: string | null; testlauf: boolean; laeuftNoch: boolean; kopfFall: KopfFall; ueberblick: TpUeberblick; zahlen: TpZahlen; zeilen: TpZeile[]; pyramide: TpEbene[]; schwerpunkte: TpSchwerpunkt[]; danach: ThemenfeldKey[]; empfehlung: TpEmpfehlung | null }
3. Rechnung unter src/lib/report/praesentation/, je Datei eine Testdatei:
   - einstellungen.ts: export const UEBERSPRUNGEN_ANZEIGE: TpAnzeige = 'kombiniert'.
   - praesentation.ts: bauePraesentation({ data, notes, tiers }) → PraesentationDaten | { fehlt: 'kompetenzen' | 'katalog' }. Ruft baueElternbericht({ kompetenzen, katalog, klasse: data.grade }) genau einmal; Zahlen, Zeilen (Felder aus profil mit sicher + uebung > 0, vorhanden aus profil), Ebenen und Schwerpunkte entstehen durch Aufteilen der R7-Werte nach „übersprungen“ (Schlüssel aus den Kompetenzen), nie durch eigene Zählung gegen den Katalog. name = getrimmter Rufname oder null, wessen = genitiv(name), fach = data.subject, laeuftNoch = data.status === 'in_progress'. Dazu anzeigeZahlen(zahlen, anzeige) → { sicher, uebung, dritte: { wert: number; art: 'davon' | 'eigen' } | null } für beide Zählweisen (dritte = null bei 0 übersprungen) und dieselbe Aufteilung für eine Zeile bzw. Ebene.
   - ueberblick.ts: ueberblick(bericht) → TpUeberblick. Ein Feld zählt für gelungen, wenn sicher > uebung (R7-Zählung, übersprungen eingeschlossen), sonst bei uebung > 0 für ueben. Je Liste höchstens zwei, absteigend nach der jeweiligen Anzahl, Gleichstand nach THEMENFELDER. beispielSicher nur, wenn gelungen leer und zaehlung.sicher > 0: erstes Label aus bericht.sicherListe, anzahl = zaehlung.sicher; beispielUebung entsprechend mit uebungListe und zaehlung.uebung. Ist die Regel aus R7-3 („Was die Grafik zeigt“) beim Start schon als reine Funktion auf dev, diese nutzen (melden).
   - empfehlung.ts: empfehlungAus(paket, tiers). Aktive Pakete nach sort_order; genau drei → basis = 1., standard = 2., premium = 3.; paket = Name des gewählten, basis = Name des ersten, außer das gewählte ist das erste (dann null). Ohne Paket oder nicht genau drei aktive → null (bei letzterem console.warn). Preise nie anfassen.
   - kurve.ts: Pfad der Logo-Kurve, Startpunkt und Pfeil aus dem Skript des Dummys (SEGS, viewBox 460 × 340, Bogenlänge wie dort) und kurvenPunkte(n) für n = 0…4: Lage in Prozent der viewBox und Seite der Beschriftung (unten | links | linksOben) nach der Tabelle in Entscheidung 9.
4. Fixtures in src/lib/report/praesentation/fixtures.ts (nur Tests und Vorschau, ohne Supabase-Client): PRAESENTATION_FAELLE = alle Fälle aus FAELLE plus, jeweils aus Ilkays Analyse (ILKAY_ROH, ILKAY_URTEILE, datenAus) mit eigener Platzhalter-Sitzungs-ID, Notizen und Paketen wie FAELLE:
   - uebersprungen: prozent_prozentsatz, term_ausklammern, geo_winkel_summe auf 'nicht_angesetzt' (proben 2, offen false)
   - einSchwerpunkt: nur die groessen_*-Urteile
   - zweiSchwerpunkte: groessen_* und bruch_*
   - dreiSchwerpunkte: groessen_*, bruch_* und prozent_*
   - laeuftNoch: wie Ilkay mit status 'in_progress'
   Zahl der Schwerpunkte per Test sichern (1, 2, 3); liefert die R7-Regel etwas anderes: STOPP und melden.
5. Texte: neuer Namespace praesentation in src/i18n/locales/de/praesentation.json, Inhalt wörtlich aus Anhang A; in src/i18n/index.ts registrieren.
6. Tokens in src/styles/tokens.css, neuer Block mit Kommentar „Tablet-Präsentation LSA, Werte aus dem Dummy V7“: genau die Tokens aus Anhang B. Keine anderen Tokens ändern.
7. Invarianten: src/test/invariants/inv4-praesentation.test.ts (neu, Aufbau wie inv4-elternbericht.test.ts): praesentation.json duzt nicht, enthält kein %, keinen snake_case-Schlüssel (außer _one/_other), kein „trägt“ und kein „gemeistert“.

## Umfang
docs/report/praesentation/ (zwei Dateien, offene-punkte-t1.md), src/types/praesentation.ts, src/types/index.ts, src/lib/report/praesentation/**, src/i18n/locales/de/praesentation.json, src/i18n/index.ts, src/styles/tokens.css (nur der neue Block), src/test/invariants/inv4-praesentation.test.ts, Retro, ROADMAP (Abschnitt „Tablet-Präsentation“ anlegen). Nicht anfassen: src/lib/report/elternbericht/**, src/types/elternbericht.ts, elternbericht.json, R6, src/App.tsx.

## Tests
Vitest:
- Zustände: traegt (auch offen) sicher, nicht_angesetzt (auch offen) übersprungen, traegt_teilweise und traegt_nicht Übungsbedarf.
- Für JEDEN Fall aus PRAESENTATION_FAELLE außer ohneKatalog gegen baueElternbericht: sicher gleich; uebung + uebersprungen = R7-uebung; untersucht, katalog, bisKlasse gleich; Zeilen = Felder aus profil mit Untersuchtem, vorhanden gleich, sicher + uebung + uebersprungen je Zeile = untersucht im Feld; Pyramide mit denselben Ebenen und Stufen, sicher gleich, uebung + uebersprungen = R7-uebung je Ebene; schwerpunkte und danach gleich (Felder, Reihenfolge, Labels).
- ohneKatalog → { fehlt: 'katalog' }, ein Fall ohne Kompetenzen → { fehlt: 'kompetenzen' }; laeuftNoch → laeuftNoch true.
- Kontrollwerte aus Anhang C (ilkay, uebersprungen, alleFelder, klasse10neu).
- ueberblick: ilkay; allesSicher (ueben leer, kein Beispiel); nichtsSicher (gelungen leer, kein Beispiel); alleFelder (gelungen leer, beispielSicher { 'Brüche kürzen', 1 }); ein eigener kleiner Fall, in dem jedes Feld mit Übungsbedarf überwiegend sicher ist (ueben leer, beispielUebung gesetzt); Gleichstand; kein Feld in beiden.
- Stufen je Schwerpunkt für ilkay und die Klassenangabe daraus (Anhang C).
- empfehlungAus: premium, standard, basis, ohne Paket, zwei aktive Pakete, unsortiert, inaktive dazwischen.
- anzeigeZahlen: beide Zählweisen mit 0 und mit 3 übersprungen.
- kurvenPunkte: n = 4 deckt sich mit den Punkten des Dummys (±0,2 Prozentpunkte); Punkte liegen in Laufrichtung; Seiten nach Tabelle; n = 0 leer; Schwerpunkt-Fälle 1–3 ergeben 1–3 Punkte.
- inv4-praesentation.test.ts grün.
Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-tp1 auf feat/rasit-praesentation-daten von origin/dev. PR gegen dev, nie main. Vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push.
- Kein DDL, keine Migration, kein Schreiben gegen Prod; Prod nur lesend über dbread.
- Dateien ≤ 400 Zeilen; mehr als 300 neue Zeilen nach CLAUDE.md §4 in Commits aufteilen.
- Zweitprüfung durch eine frische Instanz vor dem PR, Schwerpunkt: Gleichheit mit R7 und die Zuordnung „übersprungen“. STOPP nach dem PR.

## Melden
PR-Link. Für ilkay und die Analysen c84ba103 und 09cf8baa (nur Zahlen, keine Namen; Auswahl über die ID wie in R7-1): sicher, Übungsbedarf, übersprungen, untersucht, Katalog; die Zeilen; die Ebenen mit übersprungen; die Schwerpunkte mit Klassenangabe; die Felder für den Überblick. Dazu über dbread für alle abgeschlossenen Sitzungen, Testläufe getrennt: (a) Verteilung von zustand bei belegt_direkt; (b) wie viele direkt geprüfte Bereiche mindestens eine Antwort mit abgabeart in ('weiss_nicht','leer') haben (Join lsa_responses → tasks.skill_key), aufgeteilt nach zustand. Das ist die Grundlage für Abnahme 8. Abweichungen und offene Punkte in docs/report/praesentation/offene-punkte-t1.md.
```

---

## T2 · Rahmen

```
Du arbeitest im Repo Edvancev1 (WSL). Paket T2: der Rahmen der Tablet-Präsentation (Vollbild-Ebene, Kopf, Stationsleiste mit Eddie, Intro, Einrasten, Bewegung), der Einstieg im Report mit Laden, die Vorschauseite, die Ansichtstests und leere Hüllen der vier Stationen. Voraussetzung: T1 und R7-2 gemergt (bauePraesentation, PRAESENTATION_FAELLE, Namespace praesentation, Tokens --color-tp-*; R7-Weiche in ReportPage). Sonst STOPP.

## Ziel
/admin/report/:sessionId?ansicht=praesentation zeigt die Präsentation als Vollbild über der App: Intro, Kopf, Leiste und vier einrastende Stationen, die in diesem Paket nur Kicker und Titel tragen. T3 (Stationen 01, 02) und T4 (03, 04) füllen sie parallel, ohne Rahmen, Vorschau, Ansichtstests oder Invarianten anzufassen. Vorlage für Aufbau, Maße, Bewegung und Bedienung: docs/report/praesentation/dummy-v7.html. Texte und Zahlen kommen aus Anhang A und den Daten, nie aus dem Dummy. Die Entscheidungen 1–13 aus docs/report/praesentation/Anforderung.md gelten, besonders 1, 5, 10, 11 und 12.

## Entscheidungen (nicht neu verhandeln)
1. Einstieg in src/pages/admin/ReportPage.tsx: Knopf praesentation:einstieg.knopf (Icon Presentation aus lucide-react) als erster Knopf in den Aktionen, immer aktiv, sobald der Report geladen ist. Klick setzt ?ansicht=praesentation über useSearchParams; andere Parameter (?fassung) bleiben. Mit ?ansicht=praesentation braucht die Seite die Pakete: dieselbe Ladung wie die R7-Weiche (ein listTiers-Aufruf, auch wenn beide Parameter gesetzt sind). Rendert <Praesentation data notes tiers tiersFehler sessionId laden onSchliessen />. notes = der aktuelle Stand im Ausblick, auch ungespeichert. Schließen entfernt nur ?ansicht. Report, Ausblick und R7-Weiche bleiben, wie sie sind. Wird ReportPage dabei zu groß, Laden und Weiche in einen Hook neben der Seite auslagern (≤ 400 Zeilen).
2. Vollbild: Praesentation.tsx rendert mit createPortal(…, document.body) eine Ebene mit position: fixed und inset 0 (z-index über allen Shell-Ebenen), Fläche --color-eb-papier, Wurzelklasse .tp. Grund: der Inhaltsbereich der AppShell ist ein @container, darin wäre fixed an die Inhaltsspalte gebunden. Solange die Ebene offen ist, trägt <html> die Klasse tp-offen (overflow hidden). Escape schließt. Vorlesetext praesentation:aria bzw. ariaOhneName.
3. Laden: Solange Report, Notizen oder Pakete laden, zeigt die Ebene LoadingPulse. Fehler der Pakete → tiersFehler, die Empfehlungszeile entfällt (console.warn). Rechnung einmal per useMemo: bauePraesentation({ data, notes, tiers }) und der Bausteinsatz aus data.erzaehlung.bausteine wie im R7-Bogen (src/lib/report/bausteine.ts). Liefert sie { fehlt }: EmptyState mit praesentation:leer bzw. keinKatalog und Knopf Schließen.
4. Kopf.tsx: Logo (→ 01), Chip kopf.testdaten nur bei testlauf, Chip kopf.laeuftNoch bei laeuftNoch, Stationsanzeige kopf.station mit zweistelliger Nummer (Intl.NumberFormat), Knopf Schließen 44 px mit aria-label kopf.schliessen. Leiste.tsx: vier Einträge, aria-current an der aktuellen Station, Eddie wandert, Tippen springt; ohne Pfadlinie. Davor Intro.tsx (Ablauf, Zeiten und Logo exakt wie im Dummy; Kicker intro.kicker).
5. Intro einmal je Öffnen: Kopf und Leiste erst nach dem Intro; ist Station 01 erreicht und die Bewegung zur Ruhe gekommen, verlässt das Intro den Fluss, ohne dass die Ansicht springt (Logik wie retireIntro im Dummy).
6. Bewegung: Hook useStationen (IntersectionObserver plus scroll) liefert die aktuelle Station und setzt je Station entered (erster Besuch) und motion-complete (beim Verlassen, danach still). Die Stationen bekommen diese Zustände als Klassen an ihrer <section>. Zeiten, Kurven und Verzögerungen aus dem Dummy-CSS als Variablen unter .tp in rahmen.css, damit T3 und T4 sie nutzen. prefers-reduced-motion: alles sofort.
7. Hüllen: Station1.tsx bis Station4.tsx mit Kicker und Titel aus Anhang A, sonst leer, jede mit eigener CSS-Datei station1.css bis station4.css. Feste Props für alle: { p: PraesentationDaten; anzeige: TpAnzeige; satz: Bausteinsatz; sessionId: string }; anzeige kommt aus UEBERSPRUNGEN_ANZEIGE, als Prop, damit Tests beide Zählweisen prüfen.
8. Styles: src/styles/praesentation/index.css (ein Import in globals.css) importiert rahmen.css, intro.css und station1.css bis station4.css. Alles unter .tp. Farben nur aus --color-eb-* und --color-tp-* (übrige Dummy-Farben auf das nächste eb-Token runden; fehlt ein Token: STOPP und melden). Schrift --font-eb-titel für Titel und große Zahlen, sonst --font-body. Keine Hex-Werte, Inline-Styles nur für berechnete Werte.
9. Vorschauseite: vorschau/praesentation.html (nur Dev-Server, nicht im Build) mit den Schrift-Links aus index.html und eigenem Einstieg src/components/edvance/praesentation/vorschau/main.tsx. Importiert @/i18n und die globalen Styles und rendert die Präsentation für ?fall=<Name> aus PRAESENTATION_FAELLE, ohne Router, ohne Anmeldung und ohne ein Modul, das den Supabase-Client lädt. Ohne ?fall eine schlichte Liste der Fälle; Schließen führt zurück zur Liste.
10. Ansichtstests: playwright.praesentation.config.ts mit testDir e2e-praesentation, webServer „npx vite --port $TP_PORT --strictPort“ (Standard 5185), reuseExistingServer: false. Projekt chromium; webkit zusätzlich, wenn „npx playwright install webkit“ in WSL klappt (sonst melden). e2e-praesentation/praesentation.spec.ts ist so allgemein, dass T3 und T4 nichts daran ändern müssen. Es geht ALLE Fälle aus PRAESENTATION_FAELLE und alle Maße aus Entscheidung 10 durch (820×1180, 820×1100, 1180×820, 1180×740, 744×1133, 744×1060, 1133×744, 1032×1376, 1376×1032):
   - Mit reducedMotion 'reduce', je Station 01–04: Ein Element gilt als sichtbar, wenn es nicht display none, visibility hidden oder opacity 0 ist und nicht von einem Vorfahren mit overflow ungleich visible abgeschnitten wird. Kein sichtbares Element liegt tiefer als die Unterkante minus 8 px oder rechts außerhalb. Die Station selbst scrollt nicht. Elemente mit data-tp-liste werden als Ganzes gemessen, nicht ihr Inhalt.
   - Station 02 zusätzlich mit geöffnetem Detail der Zeile mit den meisten Bereichen: Die Liste darf scrollen, die Station nicht.
   - Elemente mit data-tp-beschriftung überlappen einander nicht (Bounding Boxes) und enthalten keinen Punkt des Pfads mit data-tp-kurve (200 Punkte über getPointAtLength).
   - Alle Elemente mit data-tp-pflicht sind sichtbar.
   - Alle Knöpfe und role="tab" in .tp sind mindestens 44 px hoch und breit (Trefferfläche, Pseudo-Elemente zählen).
   - Für ilkay mit Bewegung: Intro erscheint, „Gemeinsam ansehen“ führt zu 01, danach ist das Intro aus dem Fluss; Wiederbesuch von 02 ohne Animation; höchstens ein Detail offen (sobald T3 Zeilen liefert); Tippen in der Leiste springt; Schließen führt zur Liste zurück.
   - Bildschirmfotos aller Fälle und Stationen bei 820×1180 und 1180×820 nach $TP_AUSGABE/<fall>_<maß>_<station>.png (Standard docs/report/praesentation/abnahme/t2).
   Aufruf: TP_PORT=5185 TP_AUSGABE=docs/report/praesentation/abnahme/t2 npx playwright test -c playwright.praesentation.config.ts. Fehlt Chromium: npx playwright install chromium.
11. Invarianten: inv4-praesentation.test.ts (aus T1) erweitern, per Glob über src/components/edvance/praesentation/** und src/styles/praesentation/**: skillKey und Feldschlüssel nur als React-key; in .ts/.tsx keine Prozentrechnung (* 100), kein toFixed und kein % im ausgegebenen Text (CSS ausgenommen); Farben nur aus --color-eb-* und --color-tp-*; keine Hex-Werte.
12. CLAUDE.md: in §11 nach dem R7-Abschnitt der Abschnitt „Tablet-Präsentation (LSA)“ mit den Ausnahmen aus Entscheidung 11 der Anforderung (Gründer-Gespräch vom 18.10.2026), und unter „Hard Limits — Parallele Surface-Entwicklung“ bei den Design-Invarianten ein Satz mit Verweis darauf (Verläufe in der Präsentation nur wie dort festgelegt).

## Umfang
src/pages/admin/ReportPage.tsx (Knopf, Weiche, Laden; ggf. ein Hook daneben), src/components/edvance/praesentation/** (Praesentation, Kopf, Leiste, Intro, Station1–4 als Hüllen, useStationen, vorschau/), src/styles/praesentation/** (rahmen.css, intro.css, leere station1–4.css), src/styles/globals.css (ein Import), vorschau/praesentation.html, playwright.praesentation.config.ts, e2e-praesentation/**, src/test/invariants/inv4-praesentation.test.ts, CLAUDE.md (§11 und ein Satz bei Hard Limits), Retro. Neue Schlüssel in praesentation.json nur unter einstieg, aria, leer, keinKatalog, kopf, leiste, intro. Nicht anfassen: src/App.tsx, src/lib/**, src/types/**, tokens.css, elternbericht.json, alles von R7. Fehlt etwas in lib, types oder tokens: STOPP und melden.

## Tests
Vitest (Testing Library):
- Einstieg: Knopf da und aktiv, auch bei in_progress; ?ansicht=praesentation öffnet; Schließen entfernt nur ?ansicht; ein listTiers-Aufruf bei ?fassung=r7&ansicht=praesentation.
- Vollbild: hängt direkt unter document.body (Portal); <html> trägt tp-offen nur, solange offen.
- Laden: LoadingPulse bis alles geladen ist; Fehler der Pakete → keine Empfehlung, kein Abbruch.
- Kopf: Chip Testdaten nur bei testlauf, Chip „Analyse läuft noch“ nur bei laeuftNoch; Stationsanzeige.
- Leiste: Sprung und aria-current.
- Intro: genau einmal je Öffnen.
- EmptyState bei ohneKatalog.
inv4-praesentation.test.ts grün. Ansichtstests grün für alle Fälle und Maße (Stationen noch leer), Fotos im PR. Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-tp2 auf feat/rasit-praesentation-rahmen von origin/dev. PR gegen dev, nie main. Vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push.
- Designregeln CLAUDE.md §11 mit dem neuen Abschnitt; Texte nur über i18n; Touch-Ziele ≥ 44 px.
- Dateien ≤ 400 Zeilen; mehr als 300 neue Zeilen nach CLAUDE.md §4 in Commits aufteilen.
- Zweitprüfung durch eine frische Instanz vor dem PR, Schwerpunkt: Portal, Einrasten, Intro, Bewegung, Allgemeinheit der Ansichtstests. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfotos aus docs/report/praesentation/abnahme/t2/, ob WebKit lief, Abweichungen vom Dummy mit Grund, offene Punkte (docs/report/praesentation/offene-punkte-t2.md).
```

---

## T3 · Station 01 und 02

```
Du arbeitest im Repo Edvancev1 (WSL). Paket T3: Station 01 Überblick und Station 02 Lernstand der Tablet-Präsentation. Voraussetzung: T2 gemergt (Rahmen, Hüllen Station1.tsx und Station2.tsx, Bewegungsvariablen, Vorschauseite, Ansichtstests). Sonst STOPP. Läuft parallel zu T4.

## Ziel
Station 01 bringt Überschrift, Leitsatz und die zwei Karten „Schon gelungen“ / „Gezielt üben“, Station 02 die Zahlen und das Kompetenzprofil mit aufklappbaren Details. Vorlage: docs/report/praesentation/dummy-v7.html (Stationen 01 und 02). Die Entscheidungen 1–13 aus docs/report/praesentation/Anforderung.md gelten, besonders 4, 6, 7, 10, 11 und 12.

## Entscheidungen (nicht neu verhandeln)
1. Station1.tsx nach Entscheidung 6: Überschrift satz.waehle('kopf', p.kopfFall, sessionId, { name }) sonst elternbericht:s1.kopfErsatz bzw. kopfErsatzOhneName; Leitsatz s1.lead.<kopfFall>; Zeile s1.fachKlasse und s1.imBlick (nur mit Thema); Karten aus p.ueberblick (Felder mit Intl.ListFormat 'de', conjunction, Namen aus elternbericht:feld.*; leer nach Entscheidung 6 mit s1.sicherEinzeln / s1.uebungEinzeln und count); beide Karten tragen data-tp-pflicht. Ab 800 px Breite Bild mit Kreisen und Kugel wie im Dummy, darunter die Karten unter dem Leitsatz ohne Bild. Fußzeile s1.weiter bzw. weiterOhneName.
2. Station2.tsx nach Entscheidung 7: Zahlen über anzeigeZahlen(p.zahlen, anzeige); Erklärtext s2.untersucht und bei übersprungen s2.uebersprungenHeisst (ohne Namen …OhneName); Zeilenliste mit data-tp-liste, je Zeile Segmente, rechts s2.zeileZahl und darunter die Zählung (praesentation:zaehlung.*, nur Teile ≠ 0, Aufteilung je Zählweise), Vorlesetext s2.zeileAria bzw. …Kombiniert / …Getrennt, Pfeil; Detail nach Entscheidung 7, höchstens eins offen; Legende mit elternbericht:s2.profil.legende.* und s2.legende.uebersprungen (nur wenn vorhanden); Hinweis s2.tippen.
3. Punktmuster „übersprungen“: radial-gradient-Punkte aus --color-tp-ueber-* (kombiniert) bzw. --color-tp-ueber-neutral-* (getrennt), Rand wie dort; nie Streifen.
4. Bewegung beim ersten Besuch wie im Dummy (Überschrift, Zahlen, Zeilen nacheinander, Segmente wachsen) über die Variablen aus rahmen.css und die Klassen entered / motion-complete; Wiederbesuch und prefers-reduced-motion still.

## Umfang
src/components/edvance/praesentation/Station1.tsx und Station2.tsx plus Teile (z. B. UeberblickKarten.tsx, Profilzeile.tsx, Detail.tsx, Zaehlung.tsx), src/styles/praesentation/station1.css und station2.css, neue Schlüssel nur unter praesentation.s1, praesentation.s2 und praesentation.zaehlung, Retro. Nicht anfassen: Praesentation.tsx, Kopf, Leiste, Intro, Station3/4, rahmen.css, intro.css, station3.css, station4.css, e2e-praesentation/**, playwright.praesentation.config.ts, inv4-*.test.ts, ReportPage.tsx, src/lib/**, src/types/**, tokens.css, CLAUDE.md, ROADMAP. Fehlt etwas: STOPP und melden.

## Tests
Vitest (Testing Library):
- Station 01: ilkay (Ersatzüberschrift, solange kein Kopfsatz freigegeben ist; Karten nach Anhang C); mit freigegebenem Kopfsatz in der Bausteine-Fixture; allesSicher, nichtsSicher, alleFelder (Satz „Ein Bereich ist schon sicher: Brüche kürzen.“), ohneName; Leitsatz je kopfFall; Karten bei 744 px Breite sichtbar.
- Station 02: ilkay (11 und 16, keine dritte Zahl, sechs Zeilen, „5 von 8“ und „2 sicher · 3 Übungsbedarf“ bei Brüche & Dezimalzahlen); uebersprungen kombiniert (16, „davon 3 übersprungen“, Punktmuster in drei Zeilen) und getrennt über die Prop (13 und 3); alleFelder (acht Zeilen); ohneName.
- Details: höchstens eins offen; Spalten nur, wenn nicht leer; keineUebung nur ohne Übungsbedarf und ohne Übersprungenes.
Ansichtstests: TP_PORT=5186 TP_AUSGABE=docs/report/praesentation/abnahme/t3 npx playwright test -c playwright.praesentation.config.ts für alle Fälle und Maße grün. Typecheck, Lint, Vitest grün.

## Leitplanken
Worktree ../Edvancev1-tp3 auf feat/rasit-praesentation-stationen12 von origin/dev, PR gegen dev, nie main; vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push. Designregeln mit dem Abschnitt „Tablet-Präsentation (LSA)“ aus CLAUDE.md §11, keine Hex-Werte, Texte nur über i18n. Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz, Schwerpunkt: Zahlen gegen Anhang C und Passform von 02 mit acht Zeilen. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfotos der Stationen 01 und 02 (ilkay, uebersprungen, alleFelder, nichtsSicher, ohneName) bei 820×1180 und 1180×820 neben dem Dummy, Abweichungen mit Grund, offene Punkte (docs/report/praesentation/offene-punkte-t3.md).
```

---

## T4 · Station 03 und 04

```
Du arbeitest im Repo Edvancev1 (WSL). Paket T4: Station 03 Einordnung (Pyramide) und Station 04 Förderansatz (Kurve, Förderfokus, Empfehlung) der Tablet-Präsentation. Voraussetzung: T2 gemergt (Rahmen, Hüllen Station3.tsx und Station4.tsx, Bewegungsvariablen, Vorschauseite, Ansichtstests). Sonst STOPP. Läuft parallel zu T3.

## Ziel
Station 03 ordnet die untersuchten Bereiche in eine Pyramide nach Lehrplanstufe, Station 04 zeigt die Schwerpunkte auf der Kurve des Logos mit Förderfokus und darunter die Paketempfehlung. Vorlage: docs/report/praesentation/dummy-v7.html (Stationen 03 und 04). Die Entscheidungen 1–13 aus docs/report/praesentation/Anforderung.md gelten, besonders 4, 8, 9, 10, 11 und 12.

## Entscheidungen (nicht neu verhandeln)
1. Station3.tsx nach Entscheidung 8. Pyramide.tsx rendert p.pyramide: Breite über feste Klassen je Position (unterste 100 %, je Ebene darüber 19 Punkte schmaler), keine Breite im Inline-Style. Klassenangabe über klassenAngabe(stufen) und elternbericht:stufe.* bzw. stufe.spanne. Zählung mit praesentation:zaehlung.* je Zählweise (nur Teile ≠ 0), Vorlesetext s3.ebeneAria bzw. …Kombiniert / …Getrennt. Punktmuster „übersprungen“ wie in T3 (Entscheidung 3 dort; nie Streifen). Lesehilfe s3.lesen.* und elternbericht:s3.lesen.hinweisEineEbene. Aufbau von unten nach oben.
2. Station4.tsx nach Entscheidung 9:
   - Kurve.tsx: Pfad (mit data-tp-kurve), Startpunkt und Pfeil aus kurve.ts, Punkte aus kurvenPunkte(p.schwerpunkte.length). Jeder Punkt ist ein Knopf (role tab, aria-label s4.punktAria, Trefferfläche ≥ 44 px). Beschriftungen und die Förderfokus-Karte tragen data-tp-beschriftung. Gewählter Punkt größer, mit Lichtschein (--color-tp-schein). Pfeiltasten wechseln.
   - Foerderfokus.tsx: Pille s4.stoffAus mit klassenAngabe(schwerpunkt.stufen), Titel elternbericht:feld.*, zwei Kästen mit je bis zu drei Labels und elternbericht:s1.blick.weitere; ohne Sicheres s4.keinSicher. Im Querformat rechts neben der Kurve, im Hochformat darunter.
   - Danach-Zeile mit elternbericht:s4.danach (Intl.ListFormat 'de', conjunction), nur wenn p.danach nicht leer ist; dann s4.hinweis.
   - Empfehlung.tsx: s4.empfehlung bzw. empfehlungOhneName mit fettem Paketnamen (Trans), dahinter s4.basisMoeglich, wenn basis gesetzt ist. Ohne p.empfehlung keine Zeile. Kein Preis, keine Laufzeit.
   - Ohne Schwerpunkt: Titel elternbericht:s4.titelKeiner, darunter elternbericht:s1.blick.ansatzKeiner; keine Kurve, keine Karte, kein Hinweis; die Empfehlung bleibt.
3. Bewegung beim ersten Besuch wie im Dummy: in 03 die Ebenen von unten nach oben, dann die Lesehilfe; in 04 zeichnet sich die Linie, die Punkte erscheinen entlang der Linie, dann Karte, Hinweis und Empfehlung. Wiederbesuch und prefers-reduced-motion still.
4. Farben nur aus --color-eb-* und --color-tp-* (Kugel-Verlauf für Punkte und Empfehlungspunkt, Pille, Punktmuster).

## Umfang
src/components/edvance/praesentation/Station3.tsx und Station4.tsx plus Teile (Pyramide.tsx, Kurve.tsx, Foerderfokus.tsx, Empfehlung.tsx), src/styles/praesentation/station3.css und station4.css, neue Schlüssel nur unter praesentation.s3 und praesentation.s4, Retro. Nicht anfassen: Praesentation.tsx, Kopf, Leiste, Intro, Station1/2, rahmen.css, intro.css, station1.css, station2.css, e2e-praesentation/**, playwright.praesentation.config.ts, inv4-*.test.ts, ReportPage.tsx, src/lib/**, src/types/**, tokens.css, CLAUDE.md, ROADMAP. Fehlt etwas: STOPP und melden.

## Tests
Vitest (Testing Library):
- Pyramide: ilkay (zwei Ebenen nach Anhang C), klasse10neu (drei), klasse7 (zwei), spaeter (oben „Stoff späterer Klassen“), uebersprungen in beiden Zählweisen.
- Breitenklassen; Lücke bei 16, 17, 30 und 31 Segmenten.
- Kurve mit einSchwerpunkt, zweiSchwerpunkte, dreiSchwerpunkte und ilkay (vier): keine Zahlen; der erste ist vorgewählt; Tippen und Pfeiltasten wechseln; die Karte zeigt Feld, Klasse und Listen. Ilkay Geometrie mit „+2 weitere“ und „Stoff aus Klasse 5–8“.
- keinSicher.
- Danach-Zeile bei sechsFelderMitUebung und alleFelder.
- Empfehlung: premium mit Basic-Satz; basis ohne Basic-Satz; ohne Paket keine Zeile; zwei aktive Pakete keine Zeile; kein „€“ und kein Preis im DOM.
- allesSicher ohne Kurve, ohne Hinweis, mit ansatzKeiner.
Ansichtstests: TP_PORT=5187 TP_AUSGABE=docs/report/praesentation/abnahme/t4 npx playwright test -c playwright.praesentation.config.ts für alle Fälle und Maße grün, auch die Überlappungsprüfung (Beschriftungen, Kurve, Karte). Typecheck, Lint, Vitest grün.

## Leitplanken
Worktree ../Edvancev1-tp4 auf feat/rasit-praesentation-stationen34 von origin/dev, PR gegen dev, nie main; vor dem PR origin/dev hineinmergen, kein Rebase, kein Force-Push. Designregeln mit dem Abschnitt „Tablet-Präsentation (LSA)“ aus CLAUDE.md §11, keine Hex-Werte, Texte nur über i18n. Dateien ≤ 400 Zeilen. Zweitprüfung durch eine frische Instanz, Schwerpunkt: Kurve und Beschriftungen mit 1–4 Punkten auf allen Maßen. STOPP nach dem PR.

## Melden
PR-Link, Bildschirmfotos der Stationen 03 und 04 (ilkay, klasse10neu, spaeter, allesSicher, uebersprungen, einSchwerpunkt, zweiSchwerpunkte, dreiSchwerpunkte) bei 820×1180 und 1180×820 neben dem Dummy, Abweichungen mit Grund, offene Punkte (docs/report/praesentation/offene-punkte-t4.md).
```

---

## Abnahme nach T3 und T4 (Gründer gemeinsam)

1. **Vorschau Ilkay neben dem Dummy** (820×1180 und 1180×820): Aufbau, Bewegung und Farben wie im Dummy, Zahlen und Texte aus den Daten (Anhang C).
2. **Gleiche Zahlen wie der Druckbogen:**
   - 11 sicher, 16 Übungsbedarf, 27 von 130 untersucht
   - dieselben zwei Ebenen
   - dieselben Schwerpunkte in derselben Reihenfolge
   - Vergleich mit der R7-Vorschau oder, falls R7-3/R7-4 noch fehlen, mit `docs/report/r7/offene-punkte-r7-1.md`
3. **Fall `uebersprungen`:** Punktmuster in drei Zeilen, „davon 3 übersprungen“, Namen im Detail. Mit der Konstante auf „getrennt“ (einmal lokal) erscheinen 11 · 13 · 3.
4. **Echtes iPad in Safari** auf edvancev1.vercel.app, Hoch- und Querformat, mit einer Testlauf-Sitzung:
   - Knopf im Report, Intro einmal
   - Einrasten, Antippen, Eddie
   - Schließen führt zurück zum Report
   - nichts abgeschnitten, Karten in 01 auch auf dem iPad mini sichtbar
5. **Paket im Ausblick wählen:** Die Zeile erscheint. Ohne Paket gibt es keine Zeile, nirgends steht ein Preis.
6. **Fälle ohne Übungsbedarf, ohne Sicheres, ohne Namen, mit 1–3 Schwerpunkten:** Die Texte passen, nirgends steht ein leerer Kasten.
7. **Bestätigen oder ändern:**
   - Zählweise (kombiniert oder getrennt)
   - Begriff „übersprungen“
   - Zeile „Basic ist ebenfalls möglich“
   - Lage des Förderfokus im Hochformat (unter der Kurve)
   - Kopfsätze: Lena nimmt sie ab; sonst steht in 01 „Was wir bei {Name} gesehen haben“.
8. **Einzelne „Weiß ich nicht“-Antworten:** Mit den Zahlen aus T1 (Melden b) entscheiden, ob Bereiche mit einzelnen „Weiß ich nicht“-Antworten in einem Folgeauftrag ein Zeichen bekommen.

## Offen, nicht blockierend

- **Begriff:** Ob „übersprungen“ bleibt, ist offen. Er steht nur in `praesentation.json`.
- **Druckbogen:** R7 zählt `nicht_angesetzt` zum Übungsbedarf, ohne es zu kennzeichnen. Soll das Papier dasselbe zeigen (Punktmuster, „davon x übersprungen“), braucht es einen kleinen Folgeauftrag für R7-2/R7-3; Punkte statt Streifen gleich mitplanen.
- **Antwort-Ebene:** Bereiche mit einem Fehlversuch und einem „Weiß ich nicht“ zeigt die Präsentation als Übungsbedarf ohne Zeichen. Eine Kennzeichnung bräuchte einen Lesepfad auf `lsa_responses.abgabeart`; Grant und RLS sind zu prüfen.
- **Gewichtung:** Die LSA steigt bei `nicht_angesetzt` ab wie bei „falsch“, der Lernpfad übernimmt beides als „noch nicht sicher“. Ob „Weiß ich nicht“ schwächer zählen soll, gehört in einen eigenen Auftrag zur Auswahl-Logik.
- **Nenner:** „von 130“ entscheidet die R7-Abnahme. Die Präsentation zieht mit.
- **Bausteine `fazit`/`keine`:** Die Entwürfe sagen noch „tragen“. Die Präsentation nutzt sie deshalb nicht. Nach Lenas Abnahme (W5-d) könnten sie den Satz in Station 04 ersetzen.
- **Symbole im Förderfokus** wie „cm · kg“ gibt es in den Daten nicht. Später ginge das über ein Kurzsymbol je Skill in der Inhaltspflege.
- **Logo:** Chevron oder Pfad-Logo? Vereinheitlichen, wie im R7-Offen.
- **Pyramide antippbar:** Namen je Stufe, später.
- **Paketregel:** Heute wählt der Gründer das Paket von Hand im Ausblick.
- **Doppelte Regel:** Die Regel für die Überblickskarten und „Was die Grafik zeigt“ (R7-3) sollte an einer Stelle leben, falls T1 sie neu schreiben musste.

---

## Anhang A · Texte (`src/i18n/locales/de/praesentation.json`)

Wörtlich übernehmen. `{{name}}` ist der Rufname, `{{wessen}}` ist `genitiv(name)`. Ohne Namen gelten die Fassungen `…OhneName`. `{{klassen}}` ist die fertige Klassenangabe aus `elternbericht:stufe.*` bzw. `stufe.spanne` („Klasse 5/6“, „Klasse 5–8“).

```json
{
  "aria": "Lernstandspräsentation {{name}}",
  "ariaOhneName": "Lernstandspräsentation",
  "einstieg": {
    "knopf": "Präsentation"
  },
  "leer": "Für diese Analyse gibt es keine direkt geprüften Bereiche. Eine Präsentation ist deshalb nicht möglich.",
  "keinKatalog": "Der Aufgabenkatalog konnte nicht geladen werden. Ohne ihn stimmen die Zahlen nicht. Bitte die Seite neu laden.",
  "kopf": {
    "zumUeberblick": "Zum Überblick",
    "testdaten": "Testdaten",
    "laeuftNoch": "Analyse läuft noch",
    "station": "{{nummer}} / {{gesamt}} · {{name}}",
    "schliessen": "Präsentation schließen"
  },
  "leiste": {
    "aria": "Stationen direkt anwählen",
    "station": {
      "1": "Überblick",
      "2": "Lernstand",
      "3": "Einordnung",
      "4": "Förderansatz"
    }
  },
  "intro": {
    "aria": "Einführung",
    "kicker": "Lernstandsanalyse {{fach}}",
    "unterzeile": "Ein persönlicher Blick auf die Ergebnisse",
    "los": "Gemeinsam ansehen"
  },
  "zaehlung": {
    "sicher": "{{count}} sicher",
    "uebung": "{{count}} Übungsbedarf",
    "davonUebersprungen": "davon {{count}} übersprungen",
    "uebersprungen": "{{count}} übersprungen"
  },
  "s1": {
    "kicker": "{{wessen}} Ausgangspunkt",
    "kickerOhneName": "Ausgangspunkt",
    "lead": {
      "gemischt": "Was schon gelingt und wo noch Übung nötig ist, sehen wir uns jetzt gemeinsam an.",
      "sicher": "Was schon gelingt, sehen wir uns jetzt gemeinsam an.",
      "uebung": "Wo noch Übung nötig ist und wo wir ansetzen, sehen wir uns jetzt gemeinsam an."
    },
    "fachKlasse": "{{fach}} · Klasse {{klasse}}",
    "imBlick": "Im Blick: {{thema}}",
    "gelungen": "Schon gelungen",
    "ueben": "Gezielt üben",
    "sicherEinzeln_one": "Ein Bereich ist schon sicher: {{bereich}}.",
    "sicherEinzeln_other": "Einzelne Bereiche sind schon sicher, zum Beispiel {{bereich}}.",
    "uebungEinzeln_one": "Ein Bereich braucht noch Übung: {{bereich}}.",
    "uebungEinzeln_other": "Einzelne Bereiche brauchen noch Übung, zum Beispiel {{bereich}}.",
    "weiter": "Weiterwischen, um {{wessen}} Kompetenzprofil zu sehen",
    "weiterOhneName": "Weiterwischen zum Kompetenzprofil"
  },
  "s2": {
    "kicker": "Lernstand",
    "titel": "Was der Test zeigt.",
    "zahl": {
      "uebersprungen": "übersprungen",
      "davonUebersprungen": "davon übersprungen"
    },
    "untersucht": "{{untersucht}} von {{katalog}} Bereichen bis Klasse {{klasse}} untersucht.",
    "uebersprungenHeisst": "Übersprungen heißt: Bei allen Aufgaben zu diesem Bereich hat {{name}} „Weiß ich nicht“ gewählt oder nichts eingetragen. Das ist kein Fehler, zeigt aber, wo noch Sicherheit fehlt.",
    "uebersprungenHeisstOhneName": "Übersprungen heißt: Bei allen Aufgaben zu diesem Bereich wurde „Weiß ich nicht“ gewählt oder nichts eingetragen. Das ist kein Fehler, zeigt aber, wo noch Sicherheit fehlt.",
    "profilHinweis": "Jedes Segment steht für eine Kompetenz · Antippen für Details",
    "zeileZahl": "{{untersucht}} von {{vorhanden}}",
    "zeileAria": "{{feld}}: {{untersucht}} von {{vorhanden}} untersucht, {{sicher}} sicher, {{uebung}} mit Übungsbedarf.",
    "zeileAriaKombiniert": "{{feld}}: {{untersucht}} von {{vorhanden}} untersucht, {{sicher}} sicher, {{uebung}} mit Übungsbedarf, davon {{uebersprungen}} übersprungen.",
    "zeileAriaGetrennt": "{{feld}}: {{untersucht}} von {{vorhanden}} untersucht, {{sicher}} sicher, {{uebung}} mit Übungsbedarf, {{uebersprungen}} übersprungen.",
    "detailsZeigen": "Details anzeigen",
    "detailsSchliessen": "Details schließen",
    "detail": {
      "sicher": "Sicher im Test",
      "uebung": "Hier weiterüben",
      "uebersprungen": "Übersprungen",
      "weissNicht": "„Weiß ich nicht“",
      "keinSicher": "In diesem Themenfeld war noch nichts sicher.",
      "keineUebung": "Kein Übungsbedarf in diesem Themenfeld."
    },
    "legende": {
      "uebersprungen": "Übersprungen („Weiß ich nicht“)"
    },
    "tippen": "Die Details öffnen sich durch Antippen eines Themenfelds."
  },
  "s3": {
    "kicker": "Einordnung",
    "titel": "Wo im Lernstoff die Themen liegen.",
    "desc": "Dieselben Ergebnisse, jetzt danach geordnet, wo sie im Lernstoff liegen. Keine Note.",
    "ebeneAria": "{{ebene}}, {{klassen}}: {{sicher}} sicher, {{uebung}} mit Übungsbedarf.",
    "ebeneAriaKombiniert": "{{ebene}}, {{klassen}}: {{sicher}} sicher, {{uebung}} mit Übungsbedarf, davon {{uebersprungen}} übersprungen.",
    "ebeneAriaGetrennt": "{{ebene}}, {{klassen}}: {{sicher}} sicher, {{uebung}} mit Übungsbedarf, {{uebersprungen}} übersprungen.",
    "lesen": {
      "label": "So ist die Pyramide aufgebaut",
      "titel": "Geordnet nach Klassenstufen im NRW-Lehrplan.",
      "text": "Jede Stufe fasst Stoff aus bestimmten Klassen zusammen; die Klassen stehen daneben. Welche Stufen es gibt, richtet sich nach {{wessen}} Klasse.",
      "textOhneName": "Jede Stufe fasst Stoff aus bestimmten Klassen zusammen; die Klassen stehen daneben. Welche Stufen es gibt, richtet sich nach der Klasse Ihres Kindes."
    }
  },
  "s4": {
    "kicker": "Förderansatz",
    "titel": "Daran würden wir zuerst arbeiten.",
    "desc_one": "Ein Ansatzpunkt aus dem Test.",
    "desc_other": "{{count}} Ansatzpunkte aus dem Test, in dieser Reihenfolge.",
    "punktAria": "{{feld}}, Stoff aus {{klassen}}",
    "fokus": "Förderfokus",
    "stoffAus": "Stoff aus {{klassen}}",
    "sicher": "Sicher im Test",
    "ueben": "Hier üben wir",
    "keinSicher": "In diesem Themenfeld war noch nichts sicher.",
    "hinweis": "Die Auswahl ist ein pädagogischer Arbeitsvorschlag. Der Coach prüft sie mit Blick auf Unterricht und anstehende Klausuren.",
    "empfehlung": "Unsere Empfehlung für {{name}}: <b>Paket {{paket}}</b>",
    "empfehlungOhneName": "Unsere Empfehlung: <b>Paket {{paket}}</b>",
    "basisMoeglich": "{{basis}} ist ebenfalls möglich."
  }
}
```

Aus `elternbericht` (unverändert, Stand R7-1): `kind`, `feld.*`, `stufe.*`, `s1.kopfErsatz`, `s1.kopfErsatzOhneName`, `s1.blick.keinSicher`, `s1.blick.keineUebung`, `s1.blick.weitere`, `s1.blick.ansatzKeiner`, `s2.zahl.sicher`, `s2.zahl.uebung`, `s2.profil.titel`, `s2.profil.titelOhneName`, `s2.profil.legende.sicher`, `s2.profil.legende.uebung`, `s3.ebene.*`, `s3.lesen.hinweisEineEbene`, `s4.danach`, `s4.titelKeiner`.

## Anhang B · Farben (`--color-tp-*` in `src/styles/tokens.css`)

Alles andere nimmt das nächstgelegene `--color-eb-*`:
- Fläche: `papier`
- Karten: `weiss`, auch der Lichtschein im Intro mit Transparenz über color-mix
- Navy, auch im Logo: `navy`
- Logo-Pfeil und Pfeilspitze der Kurve: `gold`
- Text: `tinte`, `text`, `leise`
- Linien: `linie`, `linie-zart`
- Zustände: `sicher`, `sicher-text`, `uebung`, `uebung-text`
- Grünflächen: `mint`

| Token | Wert | Verwendung |
|---|---|---|
| `--color-tp-kugel-hell` | #FFF2C7 | Verlauf der Kugeln: Eddie, Kugel in 01, Kurvenpunkte, Empfehlungspunkt (hell) |
| `--color-tp-kugel-mitte` | #F9C16D | dito |
| `--color-tp-kugel-warm` | #F5A64A | dito |
| `--color-tp-kugel-tief` | #D87B2F | dito (dunkel) |
| `--color-tp-schein` | #F3A84C | Lichtschein um Eddie, die Kugel in 01 und den gewählten Punkt, nur mit Transparenz (color-mix) |
| `--color-tp-pille` | #EEF2F5 | Fläche der Klassenangaben |
| `--color-tp-fokus` | #79A6C0 | Fokusring (Tastatur) |
| `--color-tp-ueber-punkt` | #D9988B | Punktmuster „übersprungen“, kombiniert |
| `--color-tp-ueber-grund` | #FCF4F1 | dito, Grund |
| `--color-tp-ueber-rand` | #DDB2A8 | dito, Rand |
| `--color-tp-ueber-neutral-punkt` | #B3A49B | Punktmuster „übersprungen“, getrennt |
| `--color-tp-ueber-neutral-grund` | #FBF9F7 | dito, Grund |
| `--color-tp-ueber-neutral-rand` | #D8CDC5 | dito, Rand |
| `--color-tp-ueber-neutral-text` | #7C6E66 | Zahl und Etikett „übersprungen“, getrennt |

## Anhang C · Kontrollwerte

Nachgerechnet mit `baueElternbericht` aus R7-1 (Ilkays Analyse 6d868c5f, Katalog vom 19.10., 130 Skills). Weicht eine Rechnung davon ab: STOPP und melden, nicht die Erwartung anpassen.

**Ilkay**
- Zahlen: 11 sicher · 16 Übungsbedarf · 0 übersprungen · 27 von 130 untersucht · bis Klasse 10
- Überblick: Schon gelungen = Größen, Zahlen & Rechnen · Gezielt üben = Geometrie, Brüche & Dezimalzahlen
- Kopfsatz: solange keiner freigegeben ist, „Was wir bei Ilkay gesehen haben“
- Empfehlung (Fixture `premium`): „Unsere Empfehlung für Ilkay: Paket Premium · Basic ist ebenfalls möglich.“

| Zeile (Station 02) | sicher | Übungsbedarf | übersprungen | rechts |
|---|---|---|---|---|
| Brüche & Dezimalzahlen | 2 | 3 | 0 | 5 von 8 |
| Prozent & Dreisatz | 1 | 3 | 0 | 4 von 9 |
| Terme & Gleichungen | 2 | 2 | 0 | 4 von 23 |
| Geometrie | 1 | 5 | 0 | 6 von 40 |
| Größen | 3 | 2 | 0 | 5 von 6 |
| Zahlen & Rechnen | 2 | 1 | 0 | 3 von 14 |

Funktionen (0 von 20) und Daten & Zufall (0 von 10) haben keine Zeile.

| Ebene (Station 03) | Klassenangabe | sicher | Übungsbedarf |
|---|---|---|---|
| Weiterführende Themen | Klasse 7/8 | 4 | 8 |
| Grundlagen | Klasse 5/6 | 7 | 8 |

| Schwerpunkt (Station 04) | Stoff aus | Sicher im Test | Hier üben wir |
|---|---|---|---|
| Geometrie | Klasse 5–8 | Fläche von Rechteck und Quadrat | Umfang von Rechteck und Dreieck, Maßstab, Volumen und Oberfläche des Quaders, +2 weitere |
| Brüche & Dezimalzahlen | Klasse 5/6 | Bruch in Dezimalzahl, Brüche kürzen | Brüche addieren, Brüche dividieren, Brüche multiplizieren |
| Größen | Klasse 5/6 | Längen umrechnen, Massen umrechnen, Gemischte Schreibweise | Flächeneinheiten, Volumeneinheiten |
| Prozent & Dreisatz | Klasse 7/8 | Prozentwert berechnen | Grundwert berechnen, Prozentsatz berechnen, Prozentuale Veränderung |

Danach: Terme & Gleichungen, Zahlen & Rechnen.

**Fall `alleFelder`:** acht Zeilen. „Schon gelungen“ zeigt „Ein Bereich ist schon sicher: Brüche kürzen.“, „Gezielt üben“ = Brüche & Dezimalzahlen, Prozent & Dreisatz.

**Fall `klasse10neu`:** drei Ebenen (Aktueller Unterrichtsstoff · Klasse 9/10; Weiterführende Themen · Klasse 7/8; Grundlagen · Klasse 5/6). Schwerpunkt Terme & Gleichungen mit „Stoff aus Klasse 7–10“.

**Fall `uebersprungen`** (Ilkay; Prozentsatz berechnen, Ausklammern und Winkelsummen im Dreieck und Viereck auf `nicht_angesetzt`):
- Zahlen kombiniert: 11 sicher · 16 Übungsbedarf · davon 3 übersprungen. Getrennt: 11 · 13 · 3.
- Zeilen:
  - Prozent & Dreisatz: 1 · 2 · 1
  - Terme & Gleichungen: 2 · 1 · 1
  - Geometrie: 1 · 4 · 1
  - übrige Zeilen wie bei Ilkay
- Ebene Weiterführende Themen: 4 sicher · 8 Übungsbedarf, davon 3 übersprungen; getrennt 4 · 5 · 3. Grundlagen wie bei Ilkay.
- Überblick, Schwerpunkte und „danach“ wie bei Ilkay. Der Druckbogen zeigt für diesen Fall dieselben Zahlen wie für Ilkay.
