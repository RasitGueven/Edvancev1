# Konzept · Sessionreihe 1 und Bauformen

**Für:** Rasit, Tolunay, Ashkan, Lena und die vier Bauaufträge A–D · **Stand:** 27.10.2026
**Grundlage:** Konzept Session-Ablauf (27.10.), Anforderung Studio (27.10.), Anforderung Themenbaum (21.10.), Schüler-App-Dummy v3 (27.10.), Session-Rahmen A2/E1/E2a, Gespräch Rasit 27.10.

Dieses Dokument ist die gemeinsame Quelle für die vier Bauaufträge. Steht in einem Auftrag etwas anderes, gilt dieses Dokument. Abschnitt 9 (Schnittstellen) ist verbindlich für alle vier.

---

## 1 · Entscheidungen (Rasit, 27.10.2026)

1. **Erste Sessionreihe:** „Quadratische Funktionen und Gleichungen“, Pilotkind Batu (Klasse 9, FWG). Kommt nach „Reelle Zahlen und Wurzeln“.
2. **Takt:** erstmal eine Session pro Woche.
3. **Warm-up ab Session 2:** Abruf aus früheren Sessions der Reihe plus Voraussetzungen des heutigen Ziels.
4. **Pool-Trennung:** Eine Aufgabe gehört entweder zur LSA oder zur Session, nie zu beiden. Die rund 40 Aufgaben mit beiden Markierungen verlieren die Session-Markierung. Nichts wird gelöscht. Eine Datenbankregel verhindert, dass es je wieder vorkommt.
5. **Bauformen statt Einzelaufgaben:** Lena prüft nicht jede Aufgabe, sondern jede Bauform. Ein Generator erzeugt die Aufgaben, eine Prüfmaschine kontrolliert jede einzelne, und die Bewährung im Einsatz fängt auf, was durchrutscht.
6. **Freigaberegel neu:** Lena prüft jede Bauform. Erzeugte Aufgaben übernehmen ihre Prüfung, solange die Prüfmaschine für sie grün ist. Die Endfreigabe machen wie bisher die Admins (Sammelfreigabe). Einzeln geprüft bleiben Erklärvideos, Coach-Prüffragen und frei geschriebene Texte.
7. **Feldmaske** ist ein gemeinsames Format für Punkt, Funktionsgleichung und a√b.

## 2 · Die Reihe

### 2.1 Welche Skills dazugehören

Die Reihe umfasst die Skills der Klassenarbeitsthemen und alles, was diese laut Kompetenzgraph (`skill_kante`) brauchen. Für Batu sind das die Themen `quadratische_funktionen` und `quadratische_gleichungen`. Das zweite steht im hinterlegten FWG-Plan erst in Klasse 10, wird aber über den Graphen ohnehin gebraucht (Nullstellen brauchen die Lösungsformel). Die Reihenplanung zieht solche Skills automatisch hinein, auch wenn nur ein Thema als Klassenarbeit eingetragen ist.

**Kern-Skills und Kernideen**

| Skill | Kernideen (je ein Erklärschritt, ein Mini-Check) |
|---|---|
| `fkt_quadr_parabel` Normalparabel verschieben und strecken | K1 Normalparabel: Wertetabelle, Symmetrie, Scheitel im Ursprung · K2 Streckfaktor a: enger, weiter, nach unten geöffnet · K3 Verschieben: d nach rechts, e nach oben |
| `fkt_quadr_scheitel` Scheitelpunkt aus der Scheitelpunktform | K1 S(d \| e) ablesen, das Vorzeichen in der Klammer · K2 Gleichung aus dem Graphen |
| `fkt_quadr_normalform` Normalform zur Scheitelpunktform | K1 Scheitelpunktform ausmultiplizieren (der Rückweg) · K2 Quadratische Ergänzung mit a = 1 · K3 Mit a ≠ 1: erst ausklammern |
| `gleichung_quadr_wurzel` durch Wurzelziehen | K1 x² = c hat zwei, eine oder keine Lösung · K2 Erst umstellen, dann Wurzel · K3 (x − d)² = c |
| `gleichung_quadr_faktor` Nullprodukt | K1 Ein Produkt ist 0, wenn ein Faktor 0 ist · K2 x ausklammern |
| `gleichung_quadr_formel` p-q-Formel | K1 Normalform herstellen, p und q ablesen · K2 Formel anwenden |
| `gleichung_quadr_anzahl` Diskriminante | K1 Der Ausdruck unter der Wurzel entscheidet |
| `fkt_quadr_nullstellen` Nullstellen | K1 Nullstelle heißt f(x) = 0, Schnitt mit der x-Achse · K2 Den passenden Weg wählen |
| `fkt_quadr_extrem` Extremwertaufgaben | K1 Die Größe als quadratische Funktion, der Scheitel ist das Extremum |

**Voraussetzungen** (nur Übungen, Warm-up und Hinweise, kein Video, kein Transfer): `term_binom_quadrat`, `term_ausklammern`, `term_einsetzen`, `zahl_wurzel_quadrat`, `geo_koordinaten`, `gleichung_zweischrittig`. Weitere zieht der Graph bei Bedarf nach; dafür reicht je Skill eine Bauform.

**Lösungsformel:** Standard ist die p-q-Formel (NRW-üblich). Die abc-Formel kommt als eigene Bauform später, wenn eine Schule sie verlangt.

### 2.2 Fahrplan (Vorschlag des Systems, eine Session pro Woche)

Geplant wird je **Kernidee**, nicht je Skill. Die Reihe hat 19 Kernideen. Rechenbeispiel mit acht Sessions bis zur Arbeit, Kapazität der Kernarbeit 36 Minuten, neue Kernidee 12 Minuten (Erklärung, Lösungsbeispiel, Übung zusammen):

| # | Warm-up (3–4 Aufgaben, ohne Hinweise) | Kernarbeit (Kernideen) | Video |
|---|---|---|---|
| 1 | Voraussetzungen: Koordinaten, Einsetzen, Quadratzahlen | parabel K1, K2 | V1, V2 |
| 2 | Abruf parabel, Einsetzen | parabel K3, scheitel K1, K2 | V3 |
| 3 | Abruf parabel/scheitel, binomische Formeln, Ausklammern | normalform K1, K2, K3 | V4 |
| 4 | Abruf, Quadratwurzel, zweischrittige Gleichungen | wurzel K1, K2, K3 | V5 |
| 5 | Abruf, Ausklammern | faktor K1, K2, formel K1 | V6, V7 (Teil 1) |
| 6 | Abruf, Einsetzen | formel K2, anzahl K1, nullstellen K1 | V7 (Teil 2), V8 |
| 7 | Abruf gemischt | nullstellen K2, extrem K1, Transfer gemischt | – |
| 8 | Abruf gemischt | **Generalprobe**, danach Nacharbeit „noch üben“ | – |

Ein Video kann über zwei Sessions verteilt sein. Gezeigt wird immer der Beat-Bereich der Kernidee.

### 2.3 Planungsregeln (Auftrag C baut sie)

1. **Rückwärts vom Datum der Klassenarbeit.** Anzahl Sessions = Termine bis zum Tag vor der Arbeit. Die letzte ist die Generalprobe.
2. **Zeitbedarf je Kernidee** (Stellschrauben): neu 12 Min, schon gesehen, aber noch nicht sicher 6 Min, sicher 0 (nur Abruf). Eine Voraussetzung ohne Befund kostet keine Kernarbeitszeit, sie wird im Warm-up geprüft; fällt sie dort durch, schlägt das System `pfad_tiefer` vor (10–15 Min, geht von der Kernarbeit ab).
3. **Kapazität** der Kernarbeit je Session: 36 Minuten (Stellschraube), 10 % Spielraum.
4. **Reihenfolge:** Kernideen in der Reihenfolge des Katalogs (Spalte „Nr.“ in §2.1 bzw. die Reihenfolge der Tabelle). Bei mehreren Themen gilt die Reihenfolge der Schule (Schulplan), ein Skill aus einem späteren Thema, den der Graph als Voraussetzung hineinzieht, steht direkt vor dem Skill, der ihn braucht. Für Reihe 1 ergibt das genau die Reihenfolge der Tabelle in §2.2.
5. **Passt es nicht:** zuerst fallen die Kernideen weg, deren Skill „kann entfallen“ ist (`fkt_quadr_extrem`). Danach entfällt der eigene Transferblock (Transfer nur noch in der Generalprobe). Reicht das nicht, bekommen Kernideen mit Stand „schon gesehen“ 4 statt 6 Minuten. Der Coach sieht im Check-in: „Die Reihe passt nicht in n Sessions: X fällt weg.“
6. **Nach jeder Session neu planen,** aus den Befunden. Das System schlägt vor, der Coach bestätigt oder verschiebt. Beides wird getrennt gespeichert.
7. **Ohne Datum:** Modus Schulthema, rollierender Plan für die nächsten vier Sessions, ohne Generalprobe.

### 2.4 Warm-up mit Abruf

- 3–4 Aufgaben, **keine Hinweise** (Entscheidung 07.10.), Rückmeldung in Gold und mit dem Fehlbild-Satz.
- **Mischung:** 1–2 fällige Abrufe plus 1–2 Voraussetzungen des heutigen Ziels (laut Tabelle §2.2).
- **Fälligkeit:** Jeder Skill mit Beleg hat einen Abstand von 1, 2 oder 4 Sessions. Fällig ist er in der Session „letzte Session mit Beleg plus Abstand“. Belege aus Warm-up, Kernarbeit und Generalprobe zählen alle. Ein richtiger Abruf im Warm-up hebt den Abstand eine Stufe (1 → 2 → 4), ein Fehler setzt ihn auf 1.
- **Sind mehr Skills fällig als Plätze da sind,** kommt der am längsten überfällige zuerst. Der Rest rückt in die nächste Session.
- **Stufe:** eine unter der zuletzt sicheren Stufe, mindestens 1. Gibt es dort keine Instanz, die nächste vorhandene Stufe darunter, sonst darüber.
- Zwei Fehler auf einer Voraussetzung schicken dem Coach „eine Stufe tiefer?“ (`pfad_tiefer`, wie bisher).

### 2.5 Generalprobe

- In der letzten Session vor der Arbeit. Rund 20–25 Minuten der Kernarbeit, ohne Hinweise, Rückmeldung erst am Ende.
- **Zusammenstellung nach Regeln:** höchstens acht Kern-Skills der Reihe, die schwächsten Befunde zuerst, je eine Aufgabe der Stufe 3 (Stufe 4, wenn der Skill dort schon sicher ist), dazu ein bis zwei Transferaufgaben. Nur Instanzen mit der Rolle Generalprobe, die das Kind noch nicht gesehen hat.
- Danach „sicher / noch üben“ je Skill. Ein Tipp auf „noch üben“ startet eine kurze Übungsrunde. Belege zählen wie normale Session-Arbeit.
- Für die Eltern höchstens „Generalprobe vor der Arbeit gemacht“, keine Note, keine Prognose.

## 3 · Bauformen

### 3.1 Was eine Bauform ist

Eine Bauform beschreibt einen Aufgabentyp mit Platzhaltern. Ein Generator setzt Zahlen ein und erzeugt daraus konkrete Aufgaben (Instanzen). Jede Instanz ist eine ganz normale Zeile in `tasks`: Player, Wertung, Hinweise und Lösungsweg funktionieren unverändert.

**Steckbrief einer Bauform** (das prüft Lena)

| Feld | Inhalt |
|---|---|
| Schlüssel | z. B. `NP-2` |
| Skill, Kernidee | aus dem Katalog |
| Format | eines aus Abschnitt 7 |
| Rollen | warmup, uebung, transfer, recap, beispiel, home, generalprobe |
| Aufgabentext | mit Platzhaltern, z. B. „Löse {a}x² + {b}x = 0.“ |
| Stufen | je Stufe 1–5 die Zahlenbereiche und Merkmale (z. B. Stufe 3: a ≠ 1, Lösung ganzzahlig) |
| Fehlbilder | je Fehlbild: Schlüssel aus dem Katalog, Rechenregel (wie entsteht die falsche Antwort), Rückmeldung ans Kind, **gilt für Stufen** (ein Fehlbild, das in einer Stufe dieselbe Antwort wie die richtige ergäbe, z. B. „a übersehen“ bei a = 1, gilt dort nicht) |
| Hinweise | drei Stufen mit Platzhaltern (Frage, Strategie, erster Schritt, nie die Lösung) |
| Lösungsweg | Schritte mit Platzhaltern, dazu je Bauform ein „Warum?“ mit drei Begründungsbausteinen für das Lösungsbeispiel |
| Kontext | optional ein fester Sachtext mit Zahlen-Platzhaltern. Kontexte der Interessenswelten tauschen nur Wörter, nie Zahlen. |
| Figur | optional: Generator und Parameter |
| Zeit | erwartete Bearbeitungszeit |
| Kann entfallen | ja/nein (für die Reihenplanung) |

**Eine Rolle je Instanz.** Eine Bauform kann mehrere Rollen haben, jede Instanz hat genau eine. Der Generator erzeugt je Rolle und Stufe eigene Instanzen. So landet keine Aufgabe, die zuhause geübt wurde, in der Generalprobe, und Übung verbraucht keine Generalprobe-Aufgaben. Instanzen der Rolle home kommen vor Ort nie vor.

**Abgeleitet, nicht eigens angelegt**
- **Zwilling:** eine andere Instanz derselben Bauform, Rolle und Stufe.
- **Lösungsbeispiel:** eine Instanz der Rolle beispiel, Stufe 1–2, als Schritte zum Aufdecken aus dem Lösungsweg. Jedes Kern-Skill hat mindestens eine Bauform mit dieser Rolle.
- **Home-Quest, Abruf, Generalprobe:** Instanzen derselben Bauformen in der passenden Rolle und Stufe.
- **Gesehen** heißt: in einer Session vor Ort gezeigt (als Aufgabe oder Lösungsbeispiel). Das hält nur die Session fest. Zuhause wird nichts je Aufgabe gespeichert (FernUSG); dafür gibt es die eigene Rolle home.

### 3.2 Wo Bauformen leben

- **Generator und Prüfmaschine:** Python im Repo Edvancev1 unter `scripts/bauformen/`, nach dem Muster der Figuren (`scripts/figures/`, `tools/spec-figuren.sh`). Je Bauform eine Datei; dazu eine gemeinsame Prüfmaschine.
- **Steckbrief:** in der Datenbank (Tabelle `bauformen`), damit Lena ihn im Board sieht und die Version zählt.
- **Instanzen:** werden vorab erzeugt (je Bauform, Rolle und Stufe rund 8, für die Generalprobe so viele, dass jedes Kind der Reihe ungesehene bekommt) und als Datenmigration eingespielt. Zur Laufzeit wird nichts generiert.
- **Ändert sich eine Bauform,** steigt ihre Version. Die alten Instanzen bleiben für die Historie, werden aber nicht mehr gezogen. Die Bauform ist für Lena wieder offen.

## 4 · Bauform-Katalog für Reihe 1

Stufen: S1 leicht bis S5 schwer. Rollen: W Warm-up/Abruf, Ü Übung, T Transfer, R Recap, B Lösungsbeispiel, H Home, G Generalprobe. „Entf.“ = kann in der Reihenplanung entfallen.

**Normalparabel verschieben und strecken (`fkt_quadr_parabel`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder (Auswahl) |
|---|---|---|---|---|---|
| PAR-1 | Wertetabelle zu f(x) = a·x² | Tabelle | S1 a = 1 · S2 a ganzzahlig · S3 a negativ · S4 a als Bruch | W Ü B H | (−x)² negativ gerechnet · a·x statt a·x² · (a·x)² statt a·x² |
| PAR-2 | Welcher Graph gehört zu f(x) = a·x²? | Graph-Auswahl | S1 a > 1 · S2 0 < a < 1 · S3 a < 0 | Ü R H | gestaucht statt gestreckt · Öffnung vertauscht |
| PAR-3 | Welcher Graph gehört zu f(x) = (x − d)² + e? | Graph-Auswahl | S1 nur e · S2 nur d · S3 beides | Ü H G | nach links statt rechts · d und e vertauscht |
| PAR-4 | Gleichung zu „um d nach rechts, e nach oben“ | Feldmaske | S2–S4 mit Vorzeichen | Ü T | Vorzeichen in der Klammer |
| PAR-5 | Aussagen zu a (wahr/falsch, Bausteine) | MC | S2–S3 | R T | „größeres a heißt weiter“ |

**Scheitelpunkt aus der Scheitelpunktform (`fkt_quadr_scheitel`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| SCH-1 | Scheitelpunkt von f(x) = a(x − d)² + e | Feldmaske Punkt | S1 d, e > 0 · S2 Vorzeichen gemischt · S3 Form (x + d) · S4 a ≠ 1 | W Ü B H G | (−d \| e) · (e \| d) · a als Koordinate |
| SCH-2 | Gleichung aus dem Graphen | Graph + Feldmaske | S2 a = 1 · S3 a = −1 · S4 a = 2 oder ½ | Ü T G | Vorzeichen von d · a vergessen |
| SCH-3 | Hoch- oder Tiefpunkt, und wo? | MC mit Bausteinen | S2–S3 | R T | Öffnung aus e statt aus a gelesen |
| SCH-4 | Fehler finden: „S(3 \| −2)“ bei (x + 3)² − 2 | Fehler finden | S3 | T R | – |

**Normalform zur Scheitelpunktform (`fkt_quadr_normalform`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| NF-1 | Scheitelpunktform in Normalform | Feldmaske x² + [b]x + [c] | S1–S3 | W Ü H | (x − d)² = x² − d² · 2dx fehlt · Vorzeichen |
| NF-2 | Quadratische Ergänzung, a = 1 | Feldmaske (x ± [d])² ± [e] | S2 b gerade · S3 c beliebig · S4 b ungerade (Brüche) | Ü B H G | (b/2)² nicht abgezogen · b statt b/2 · Vorzeichen |
| NF-3 | Quadratische Ergänzung, a ≠ 1 | Feldmaske | S4–S5 | Ü T G | a beim Ausklammern verloren · Ergänzung nicht mit a multipliziert |
| NF-4 | Schritte der quadratischen Ergänzung ordnen | Schritte ordnen | S2–S3 | Ü R | – |
| NF-5 | Fehler finden in der Ergänzung | Fehler finden | S3–S4 | T | Ergänzung nur addiert |
| NF-6 | Scheitelpunkt aus der Normalform | Feldmaske Punkt | S3–S4 | Ü G | wie NF-2 |

**Durch Wurzelziehen (`gleichung_quadr_wurzel`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| WZ-1 | x² = c | Lösungsmenge | S1 c Quadratzahl · S2 c = 0 oder c < 0 | W Ü B H | nur die positive Lösung · c/2 · „±“ bei c < 0 |
| WZ-2 | a·x² + b = c | Lösungsmenge | S2–S3 | Ü H G | b nicht zuerst abgezogen · durch a vergessen |
| WZ-3 | (x − d)² = c | Lösungsmenge | S3–S4 | Ü T G | nur d + √c · Vorzeichen von d |
| WZ-4 | Warum hat x² = −4 keine Lösung? | Bausteine | S2 | R T | – |
| WZ-5 | Lösungen mit Wurzel, z. B. x² = 7 | MC | S4 | Ü | nur +√7 · 3,5 |

**Nullprodukt (`gleichung_quadr_faktor`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| NP-1 | (x − p)(x − q) = 0 | Lösungsmenge | S1–S2 | W Ü B H | Vorzeichen ({−p; −q}) |
| NP-2 | a·x² + b·x = 0 | Lösungsmenge | S1 a = 1, Lösung > 0 · S2 Lösung < 0 · S3 a ≠ 1 · S4 Bruch | Ü B H G | 0 vergessen · Vorzeichen · a übersehen |
| NP-3 | Fehler finden: durch x geteilt | Fehler finden | S3 | T R | – |
| NP-4 | x² = p·x (erst umstellen) | Lösungsmenge | S4 | Ü T G | durch x geteilt (0 fehlt) |

**p-q-Formel (`gleichung_quadr_formel`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| PQ-1 | p und q ablesen, Normalform herstellen | Mehrteiler | S1 Normalform · S2 Vorzeichen · S3 a ≠ 1 · S4 umstellen | W Ü H | Vorzeichen von p · nicht durch a geteilt |
| PQ-2 | Mit der p-q-Formel lösen | Lösungsmenge | S1 p, q > 0 · S2 negativ · S3 a ≠ 1 · S4 nicht in Normalform | Ü B H G | −p/2 mit falschem Vorzeichen · (p/2)² nicht quadriert · nur eine Lösung · q mit falschem Vorzeichen |
| PQ-3 | Fehler finden im Lösungsweg | Fehler finden | S3–S4 | T R | – |
| PQ-4 | Schritte ordnen | Schritte ordnen | S2 | Ü R | – |

**Diskriminante (`gleichung_quadr_anzahl`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| DI-1 | Wie viele Lösungen? | MC (0, 1, 2) | S1 p, q klein · S2–S4 | W Ü B R H G | D mit falschem q · (p/2)² vergessen |
| DI-2 | Warum keine Lösung? | Bausteine | S3 | R T | – |
| DI-3 | Für welches q gibt es genau eine Lösung? | Zahl | S4–S5 | T G | q = p/2 statt (p/2)² |

**Nullstellen (`fkt_quadr_nullstellen`)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| NS-1 | Nullstellen aus der Scheitelpunktform | Lösungsmenge | S2–S4 | Ü H G | wie WZ-3 · e mit falschem Vorzeichen |
| NS-2 | Nullstellen aus der Normalform | Lösungsmenge | S3–S4 | Ü B G | wie PQ-2 |
| NS-3 | Nullstellen aus der faktorisierten Form | Lösungsmenge | S1–S2 | W Ü B H | Vorzeichen |
| NS-4 | Welche Parabel hat die Nullstellen p und q? | Graph-Auswahl | S2–S3 | Ü R | Scheitel statt Nullstelle |
| NS-5 | Scheitel über der x-Achse, nach oben offen: Nullstellen? | Bausteine | S3 | R T | – |

**Extremwertaufgaben (`fkt_quadr_extrem`, kann entfallen)**

| Schlüssel | Aufgabe | Format | Stufen | Rollen | Fehlbilder |
|---|---|---|---|---|---|
| EX-0 | Größter oder kleinster Wert einer gegebenen Kontextfunktion (Scheitel bestimmen, Bedeutung nennen) | Mehrteiler mit Kontext | S1–S3 | W Ü B H | x-Wert statt Funktionswert angegeben · Hoch- und Tiefpunkt verwechselt |
| EX-1 | Zaun mit fester Länge, größte Fläche | Mehrteiler mit Kontext | S4–S5 | T G | Umfang statt Fläche maximiert · x statt Fläche angegeben |
| EX-2 | Wurf h(t) gegeben: größte Höhe, wann | Mehrteiler mit Kontext | S3–S4 | T G | t statt h angegeben |
| EX-3 | Gewinn G(x) maximal | Mehrteiler mit Kontext | S4 | T | – |

**Voraussetzungen**

Alle Voraussetzungs-Bauformen haben die Stufen S1–S3 und die Rollen W Ü H (Ü, damit `pfad_tiefer` die Voraussetzung auch üben kann).

| Schlüssel | Skill | Aufgabe | Format |
|---|---|---|---|
| BIN-1 | `term_binom_quadrat` | (x ± d)² ausmultiplizieren | Feldmaske |
| BIN-2 | `term_binom_quadrat` | x² + 6x + 9 als Quadrat schreiben | Feldmaske |
| AUS-1 | `term_ausklammern` | gemeinsamen Faktor ausklammern | Feldmaske |
| EIN-1 | `term_einsetzen` | Wert in einen quadratischen Term einsetzen, auch negativ | Zahl |
| QW-1 | `zahl_wurzel_quadrat` | Quadratzahlen und Wurzeln bis 20² | Zahl |
| KO-1 | `geo_koordinaten` | Punkt ablesen | Feldmaske Punkt |
| GL-1 | `gleichung_zweischrittig` | a·x + b = c | Zahl oder Bruch |

**Summe:** 40 Kern-Bauformen und 7 für Voraussetzungen, zusammen 47. Dazu kommen rund 15 Coach-Prüffragen (1–2 je Kern-Skill) als freier Text, den Lena einzeln prüft.

**Fehlbild-Schlüssel:** Neue Schlüssel beginnen mit `qf_` und beschreiben den Denkfehler, z. B. `qf_null_vergessen`. Auftrag A legt alle Schlüssel dieses Katalogs früh an (Phase A2). Die Schlüssel, die die Videos brauchen, stehen in §8.

## 5 · Prüfmaschine

Läuft für jede Instanz beim Erzeugen. Eine Instanz mit einem roten Punkt wird verworfen und gar nicht erst gespeichert. Ist eine Bauform zu mehr als 30 % rot, ist die Bauform selbst fehlerhaft und geht nicht ins Board.

1. **Unabhängig nachgerechnet.** Ein zweiter Rechenweg (sympy) prüft die angezeigte Aufgabe aus dem fertigen Text bzw. den angezeigten Koeffizienten, nicht aus den Generator-Parametern. Je Format:
   - Zahl, Bruch, Feldmaske, Lösungsmenge, Mehrteiler, Tabelle: Lösung neu berechnen, muss gleich sein.
   - Graph-Auswahl: Aus den Figur-Parametern jeder Option die Funktion zurückrechnen; genau eine Option passt zur Aufgabe, jede andere passt zu genau einem Fehlbild.
   - Fehler finden: Jede Zeile gegen die vorige auf Gleichwertigkeit prüfen; genau eine Zeile ist falsch, und es ist die markierte.
   - Schritte ordnen: Die Schritte in der richtigen Reihenfolge angewandt ergeben die Lösung; jede andere zulässige Reihenfolge steht ausdrücklich im Steckbrief.
   - Begründungsbausteine, Multiple Choice ohne Rechnung: keine Rechenprüfung; hier zählen Blindlöser und Lena.
2. **Angenehme Zahlen je Stufe:** Die Regeln stehen je Stufe im Steckbrief (ganzzahlig, Betragsgrenzen, Diskriminante Quadratzahl, ausdrücklich auch „keine Lösung“, wo die Stufe sie verlangt). Keine Lösung, die nur durch Rundung stimmt.
3. **Fehlbilder durchgespielt:** Jedes Fehlbild, das für die Stufe gilt, erzeugt eine Antwort, die sich von der richtigen und von allen anderen Fehlbildern unterscheidet. Sonst ist die Rückmeldung nicht eindeutig.
4. **Wertung getestet:** Die richtige Antwort trifft in allen zulässigen Schreibweisen (Reihenfolge, Bruch, Dezimal, gekürzt, ungekürzt), und zwar über die echte Wertungsfunktion (`lsa_grade` bzw. `wertung_testen`). Keine Fehlbild-Antwort trifft.
5. **Schreibweise:** kein „+ −3x“, kein „1x²“, kein „0x“, keine leeren Platzhalter, Minuszeichen typografisch richtig.
6. **Figur nachgemessen:** über die `pruefe_`-Module (Scheitel, Nullstellen, Achsen, Beschriftung stimmen mit dem Text überein, nichts verrät die Lösung, wo Ablesen nicht die Fertigkeit ist).
7. **Keine Dubletten:** keine zwei gleichen Instanzen und keine, die einer LSA-Aufgabe gleicht (gleiche Zahlen bei gleichem Skill).

**Dazu je Bauform ein Blindlöser:** Ein frischer Claude-Code-Subagent ohne Kontext löst zufällige Instanzen nur aus dem Kindertext, zehn oder alle, wenn es weniger sind. Weicht er bei mehr als 10 % ab (mindestens einer), ist die Bauform verdächtig: Der Text ist unklar oder die Lösung falsch. Ergebnis kommt in den Steckbrief. Den Blindlöser startet der Orchestrator, nicht das Skript.

**Wertung bleibt rein:** Die Wertungsfunktionen schreiben nie. Zähler für die Bewährung entstehen nur aus gespeicherten Session-Antworten. So landet keine Antwort von zuhause in einer Tabelle.

## 6 · Freigabe und Bewährung

| Schritt | Wer | Was |
|---|---|---|
| Entwurf | Agent | schreibt Bauform und Generator nach dem Katalog |
| Prüfmaschine | automatisch | alle Instanzen grün, Blindlöser bestanden; sonst sieht Lena die Bauform nicht |
| Bauform prüfen | Lena | Steckbrief und 6 Beispiele wie auf dem Tablet (je Stufe mindestens eines), Knopf „Andere Beispiele“; dazu Fehlbilder mit Rückmeldungen, Hinweise, Lösungsbeispiel. Entscheidung wie gewohnt: passt (zur Freigabe), unsicher (Rückfrage), passt nicht (mit Gründen). |
| Freigabe | Admins | Sammelfreigabe je Reihe (Kern-Skills und Voraussetzungen zusammen) oder je Thema für alle Bauformen „zur Freigabe“; damit werden ihre grünen Instanzen `ready` |
| Bewährung | System und Coaches | siehe unten |

**Bewährung im Einsatz**
- **Melden:** In der Coach-Sicht gibt es an jeder Aufgabe „Aufgabe stimmt nicht“. Ein Tipp pausiert die Instanz sofort für alle. Zwei gemeldete Instanzen einer Bauform pausieren die Bauform. Gemeldetes erscheint in Lenas Board unter „Auffällig“.
- **Auswertung** (Stellschrauben, Startwerte):
  - Nach 10 Bearbeitungen: Taucht eine falsche Antwort in mindestens 30 % der Fälle auf, die zu keinem Fehlbild gehört, besteht Verdacht auf eine falsche Lösung. Die Instanz wird pausiert und erscheint als „Auffällig“.
  - Liegt die Erfolgsquote einer Stufe außerhalb des Erwartungsbands (S1 ≥ 85 %, S2 70–95 %, S3 55–90 %, S4 40–85 %, S5 25–75 %), schlägt das System eine andere Stufe vor. Lena entscheidet.
  - Nach 10 Bearbeitungen ohne Auffälligkeit gilt die Instanz als bewährt.
- Pausiert heißt: wird nicht mehr gezogen, bleibt aber in der Historie.

## 7 · Formate

| Format | Stand | Antwort | Wertung |
|---|---|---|---|
| Multiple Choice, wahr/falsch | gibt es | Option | Fehlbild je Option |
| Zahl, Bruch | gibt es | Wert | nach Wert |
| Mehrteiler, Tabelle, Bereich | gibt es | je Teil bzw. Zelle | je Teil |
| **Feldmaske** | neu | je Feld ein Wert | siehe unten |
| **Lösungsmenge** | neu | Menge | siehe unten |
| **Graph-Auswahl** | neu | Option | Fehlbild je Option |
| **Fehler finden** | neu | Zeile plus Begründung | beides richtig |
| **Begründungsbausteine** | neu | 1–2 Bausteine | genau die richtige Kombination |
| **Schritte ordnen** | neu | Reihenfolge | eine oder mehrere zulässige Reihenfolgen |

**Feldmaske**
- Eine Schablone mit Feldern, z. B. `f(x) = [a] · (x [±] [d])² [±] [e]`, `S([x] | [y])`, `[a]√[b]`, `x² + [b]x + [c]`.
- Feldtypen: `zahl`, `bruch`, `vorzeichen` (Umschalter + / −, Start „+“). So muss das Kind nie „x − (−3)“ tippen.
- Ein Feld kann „leer heißt 1“ erlauben (für a = 1), festgelegt je Bauform und Stufe.
- Wertung über die Bedeutung: Aus den Feldern wird der Term bzw. Punkt gebildet und mit der Lösung verglichen. „x + 3“ mit [+][3] und „x − (−3)“ sind gleich.
- Fehlbild-Treffer ebenfalls über die Bedeutung.

**Lösungsmenge**
- 1–3 Felder, das Kind fügt Felder selbst hinzu oder entfernt sie, dazu der Knopf „keine Lösung“.
- Reihenfolge egal, doppelte Werte zählen einmal. Elementtypen `zahl`, `bruch`, später `wurzel` (Feldmaske a√b).
- Wertung: Mengengleichheit.
- Fehlbilder als Mengen (z. B. {5} statt {0; 5}). Passt eine Antwort zu einem Fehlbild, gilt dessen Rückmeldung. Nur wenn kein Fehlbild passt und die Antwort eine echte Teilmenge der Lösung ist, kommt die allgemeine Rückmeldung „Eine Lösung fehlt noch.“ Beides zählt als falsch.

**Graph-Auswahl**
- 2–4 Optionen, jede eine Figur (neuer Generator `parabel`), 2 × 2 angeordnet, je Option ein Fehlbild, Alternativtext ohne Ziffern.
- Für Ablesen ist ein Raster erlaubt, weil Ablesen hier die Fertigkeit ist.

**Fehler finden, Begründungsbausteine, Schritte ordnen** wie im Konzept Session-Ablauf §6 und im Schüler-App-Dummy (Bildschirme Transfer und Lösungsbeispiel).

Alle Formate gibt es im Tablet-Player (edvance-app) und in Lenas Prüf-Vorschau. Die Antwortkodierung steht im Datenvertrag.

## 8 · Erklärvideos der Reihe

Je Video 6–12 Beats, 2–3 Mini-Checks mit Rücksprung, Skelett zuerst, Welten später.

| # | Titel | Skill, Kernideen | Bausteine | Mini-Checks (Fehlbild-Schlüssel → Rücksprung) |
|---|---|---|---|---|
| V1 | Die Normalparabel | parabel K1 | Titelkarte, Koordinatensystem, Term-Zeile, Merksatz | `qf_quadrat_negativ` ((−2)² = −4) → Beat „Ein Quadrat ist nie negativ“ |
| V2 | Strecken, stauchen, spiegeln | parabel K2 | Koordinatensystem | `qf_streckfaktor_umgekehrt` → Beat „a = 2 im Vergleich“ |
| V3 | Verschieben und Scheitelpunktform | parabel K3, scheitel K1 | Koordinatensystem, Term-Zeile | `qf_verschiebung_vorzeichen` → Beat „Wo wird die Klammer null?“ |
| V4 | Quadratische Ergänzung | normalform K1–K3 | Raster als Flächenmodell, Term-Zeile, Merksatz | `qf_ergaenzung_nicht_abgezogen` → Beat „Was wir dazugeben, ziehen wir ab“ |
| V5 | x² = c hat zwei Lösungen | wurzel K1–K3 | Koordinatensystem (Parabel schneidet y = c), Term-Zeile | `qf_nur_positive_loesung` → Beat „Auch (−3)² = 9“ |
| V6 | Das Nullprodukt | faktor K1–K2 | Term-Zeile, Merksatz | `qf_null_vergessen` → Beat „Ein Faktor ist x selbst“ |
| V7 | Woher die p-q-Formel kommt | formel K1–K2, anzahl K1 | Term-Zeile, Merksatz | `qf_halbes_p_nicht_quadriert` → Beat „Die Ergänzung“ |
| V8 | Nullstellen sind Schnittpunkte | nullstellen K1–K2 | Koordinatensystem, Term-Zeile | `qf_scheitel_statt_nullstelle` → Beat „f(x) = 0“ |

Weitere Fehlbilder der Mini-Checks nimmt das Skript nur aus dem Katalog, den Auftrag A anlegt. Diese acht Schlüssel legt A in Phase A2 an, damit B sie früh nutzen kann.

**Neue Bausteine** über den Startsatz des Studios hinaus: Koordinatensystem mit Parabel (zeichnen, strecken, verschieben, Schnittpunkte markieren, Gerade y = c) und Raster als Flächenmodell (Quadrat x · x plus Streifen). Auftrag B baut sie.

## 9 · Schnittstellen zwischen den Aufträgen (verbindlich)

Jeder Auftrag besitzt seine Tabellen, Funktionen und Komponenten allein. Die anderen nutzen sie nur über das, was hier steht. Namen und Typen passen die Besitzer an das bestehende Schema an (z. B. heißt die Kind-ID im Schema vielleicht anders). Die Bedeutung bleibt, und die endgültige Signatur steht im `docs/api/DATENVERTRAG.md` von Edvancev1.

| Besitzer | Was | Für wen |
|---|---|---|
| **A** Sessionaufgaben | `tasks`: Pool, Bauform, Stufe, Rolle, Kernidee; Tabellen `bauformen`, Prüfungen, Bewährung, Meldungen; Wertung und Payload; Formate (Player-Komponenten, Lösungsbeispiel-Ansicht, Prüf-Vorschau); Figurengenerator `parabel`; Fehlbild-Schlüssel; Instanzen der Reihe; LSA-Auswahl (nur der Pool-Filter) | B, C, D |
| **B** Studio | `studio_*`, Remotion-Paket, `/admin/studio`, Video in `erklaer_start`, Antwortart `ruecksprung`, Mediathek, Eddie-Index, Komponente `ErklaerVideo` | C, D |
| **C** Session-Workflow | Reihenplanung, `session_naechster_schritt` (Phasen, Auswahl, Warm-up-Abruf, Lösungsbeispiel, Transfer, Recap, Generalprobe, Wirkung von „Zeig's mir“), Session-Bildschirme vor Ort, Check-out ohne Termin-Wahl, Coach-Sicht samt **Einbaupunkten** für A und D | D |
| **D** Home light | Anmeldung mit Code und Geräte, `home_uebung`, „Zeig's mir“-Vorschlag mit Coach-Entscheidung und Kachel im Check-in, Offen-Regeln des Themenbaums (`kompetenz_offen`), Themenbaum-Komponenten, Home-Bildschirme, Profil, Eddie ohne Sprachmodell, Store-Build | B, C |

**`session_naechster_schritt` ändert nur C.** A setzt den Pool-Filter in `aufgabe_ziehen` und in der LSA-Auswahl, nicht in `session_naechster_schritt`. Reicht die Datenänderung aus A1 nicht, damit die heutige Session-Auswahl keine LSA-Aufgabe mehr zieht, schreibt A das in `docs/reihe1/A/an-C.md`, und C löst es in C2.

**Datenbank-Funktionen (Mindestumfang)**

```text
A  aufgabe_ziehen(p_kind, p_skill, p_rolle, p_stufe default null, p_ausschluss uuid[] default '{}') → task_id | null
     nur Pool session, Bauform freigegeben, Instanz ready und nicht pausiert, genau diese Rolle; bevorzugt in der Session
     ungesehene Instanzen; Rolle home nur Stufe 1–3 und nur Instanzen der Rolle home.
A  aufgabe_zwilling(p_kind, p_task, p_rolle default null) → task_id | null    andere Instanz derselben Bauform, Rolle, Stufe
A  aufgabe_payload(p_task) → jsonb                Kindersicht ohne Lösung, für alle Formate
A  aufgabe_werten(p_task, p_antwort jsonb) → (richtig, fehlbild_key, rueckmeldung)   rein: schreibt nie
A  aufgabe_meta(p_task) → (skill_key, kernidee_key, bauform_key, rolle, stufe)
A  aufgabe_gezeigt(p_kind, p_task, p_session) → void     nur Session vor Ort; merkt „gesehen“, auch für Lösungsbeispiele
A  aufgabe_melden(p_task, p_grund) → void                nur Coach und Admin; pausiert sofort
A  skill_kann_entfallen(p_skill) → boolean
B  mediathek_kind(p_kind) → (skill_key, kernidee_key, sequenz_id, titel, welt, mp4_url, kapitel)   nur Freigegebenes, nur offene Kompetenzen
B  mediathek_angesehen(p_kind, p_sequenz) → void           speichert höchstens „angesehen“
B  eddie_index(p_kind) → (skill_key, sequenz_id, beat_key, titel)   nur Freigegebenes
C  reihenplan_kind(p_kind) → (session_nr, datum, kernideen, skills, art)
D  kompetenz_offen(p_kind) → (skill_key, zustand, grund)    Offen-Regeln der Anforderung Themenbaum §3; D baut sie früh (D2)
D  home_uebung_melden(p_skill, p_anzahl, p_dauer_sek) → void   nur das Kind selbst; eine Zeile je erledigter Quest
D  home_uebung_kurz(p_kind, p_seit default null) → (skill_key, quests, aufgaben, dauer_sek, zuletzt)
     p_seit null heißt: seit der letzten abgeschlossenen Session vor Ort
D  zeigs_mir_offen(p_kind, p_session) → (skill_key, vorschlag_am, entscheidung, entschieden_von)
D  zeigs_mir_entscheiden(p_kind, p_session, p_skill, p_entscheidung) → void   übernehmen | nicht_heute; nur Coach, Admin
```

**Zählweise „n× geübt“:** n ist die Zahl der erledigten Quests (Zeilen in `home_uebung`) seit der letzten abgeschlossenen Session vor Ort. Das gilt gleich für die Begrüßung vor Ort (C), den Ring im Themenbaum (D) und die Coach-Kachel (D).

**Wirkung von „Zeig's mir“ (Auftrag C liest `zeigs_mir_offen`):** Hat der Coach übernommen, zieht die Kernarbeit als Erstes eine Aufgabe dieses Skills, Rolle uebung, auf der zuletzt sicheren Stufe (ohne sichere Stufe: Stufe 1), ohne Hinweis-Knopf. Richtig beim ersten Versuch ist ein Beleg wie jeder andere. Es gibt keinen Sonderstatus und keine Bewertung der Übung zuhause.

**App-Komponenten und Einbaupunkte**
- A: `src/components/aufgaben/formate/` (eine Komponente je Format mit gemeinsamer Schnittstelle `AufgabeFormatProps`) und `src/components/aufgaben/Loesungsbeispiel.tsx`.
- B: `src/components/video/ErklaerVideo.tsx` (Props: Video, Kapitel, Beat-Bereich, Mini-Checks, Modus session | zuhause).
- D: `src/components/themenbaum/ThemenbaumAusschnitt.tsx` (für den Check-out von C).
- C: Einbaupunkte in der Coach-Sicht (Check-in: Platz für die Kachel „Zuhause geübt“ von D; Kind-Detail: Platz für den Melde-Knopf von A).
- **Schnittstellen-PR zuerst:** A, B, C und D liefern in ihrer ersten Phase eine kleine PR nur mit Typen, Props und Platzhaltern (A und B die Komponenten, D die Themenbaum-Komponente, C die Einbaupunkte). Rasit merged diese vier PRs zuerst. Wer eine fremde Komponente braucht, wartet, bis sie auf origin/dev liegt (`git fetch` und Datei prüfen, alle 10 Minuten), und baut bis dahin an Unabhängigem weiter.
- Routen: D legt die Home-Routen in einer eigenen Gruppe an, C bleibt bei den Session-Routen. Generierte Types werden nach jedem Rebase neu erzeugt, nie von Hand zusammengeführt.

**Warten auf eine Datenbank-Funktion**
- Besitzer markieren eine Funktion als fertig mit `comment on function … is 'reihe1 fertig';` in der Migration.
- Wer sie braucht, prüft per `dbread` über den Namen in `pg_proc` und diesen Kommentar (nicht über die genaue Signatur) und liest die endgültige Signatur aus dem DATENVERTRAG im Worktree des Besitzers (`../Edvancev1-A/docs/api/DATENVERTRAG.md` usw.).
- Fehlt sie: gegen die Signatur hier bauen, in Tests eine Attrappe nur innerhalb der Testtransaktion, und warten (Warteregel im Auftrag).
- Aufrufe von Funktionen anderer Aufträge nur aus plpgsql (späte Bindung), nie aus `language sql` und nie als Fremdschlüssel auf fremde Tabellen.
- Jedes Einspiel-Skript prüft vor der Migration per `dbread`, dass die Objekte, die es voraussetzt, in Prod existieren, und bricht sonst mit einer klaren Meldung ab.

## 10 · Mengen und Aufwand

| | Bisher (Einzelaufgaben) | Mit Bauformen |
|---|---|---|
| Lena prüft für Reihe 1 | rund 320–400 Aufgaben | 47 Bauformen, rund 15 Coach-Prüffragen, 8 Videos |
| Zeit für Lena, geschätzt | 15–20 Stunden | 6–9 Stunden (Bauform 5–10 Min, Prüffrage 2 Min, Video 10 Min) |
| Instanzen | jede einzeln | rund 1.000–1.500 erzeugt (je Rolle und Stufe rund 8), beliebig nachlieferbar |
| Nächste Reihe | von vorn | Voraussetzungen, Abruf und Formate sind schon da |

## 11 · Offene Punkte

1. **Welten:** Die Videos und Kontexte starten als Skelett. Welche Welten zum Soft Launch dazukommen, ist offen (Anforderung Studio §15.2).
2. **Erwartungsbänder** der Stufen sind Startwerte; Fatih und Lena justieren nach den ersten Sessions.
3. **abc-Formel:** erst bei Bedarf einer Schule.
4. **Klassenarbeitsdatum Batu:** bestimmt, wie viele Sessions die Reihe hat. Ohne Datum plant das System im Modus Schulthema.
