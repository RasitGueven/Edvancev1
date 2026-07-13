# Handover: Produktspezifikation „Prozess Erstgespräch" (Edvance)

**Zweck dieses Dokuments:** Vollständige, in sich geschlossene Übergabe der ausgearbeiteten Entscheidungen zum Erstgesprächsprozess. Auf dieser Basis soll ein Agenten-Prompt erstellt werden, der eine Produktspezifikation schreibt. Alle Entscheidungen in Abschnitt 3–8 sind getroffen und bindend — der Agent entscheidet sie nicht neu. Abschnitt 2 beschreibt den Ist-Zustand und die Blocker, Abschnitt 9 listet bewusst offene Punkte.

---

## 1. Auftrag & Zielbild der Spezifikation

- **Was:** Produktspezifikation für den Prozess Erstgespräch — von der Buchung bis zum Übergang ins laufende Coaching.
- **Wozu:** Arbeitsgrundlage für die Gründerrunde (CEO, COO, CMO), um daraus abzuleiten: welche Screens, welche Datenobjekte, welche Prozesse implementiert werden müssen.
- **Form der Spec:** Pro Prozessphase: Ablauf, beteiligte Rollen, Screens (funktional beschrieben, keine Pixel-Designs), Datenobjekte mit Zuständen, Akzeptanzkriterien. Zusätzlich verpflichtend: ein Kapitel **„Delta zum Ist-Zustand"**, das das Zielmodell gegen den heutigen Datenbankstand mappt (Abschnitt 2), und ein Kapitel **„Voraussetzungen/Blocker"** mit expliziter Umsetzungsreihenfolge. Offene Punkte explizit als OFFEN markieren, nicht auflösen.
- **Sprache:** Deutsch. Fachbegriffe wie unten verwenden (LSA, Ceiling, Leitidee, AFB, Kompetenz-Tag, Stoffanker).
- **Was der Agent NICHT tun soll:** Keine Implementierung, keine Migrations, kein UI-Design, keine Neuentscheidung bindender Punkte, keine Auflösung offener Punkte.

**Firmenkontext (Minimum):** Edvance ist eine hybride Premium-Lernakademie (Launch Januar 2027, Köln, Klassen 8–10, Mathe/Deutsch/Englisch). Kleingruppen-Coaching vor Ort (max. 5 Kinder) plus KI-gestützte Tablet-Lernplattform. FernUSG-Leitprinzip: Das System wählt aus und schlägt vor, der Coach bestätigt — Mastery wird ausschließlich von einer Person vor Ort bestätigt. Die Lernstandsanalyse (LSA) ist ein kostenloses Diagnostik-Event und das primäre Go-to-Market-Instrument; nur auto-gradbare Aufgabentypen (MC, Short-Input, Bildanzeige). Das LSA-Ergebnis wird dem Kind niemals gezeigt — es ist ein Diagnostikum für Coach und Eltern.

---

## 2. Ist-Zustand & Blocker (Stand Juli 2026) — von der Spec als Voraussetzungen zu führen

Das Zielmodell dieses Dokuments ist mit dem heutigen Datenbankstand **nicht einlösbar**. Die folgenden Punkte sind Blocker, kein Backlog. Die Spec muss sie als Voraussetzungen mit Reihenfolge ausweisen.

**B1 — Stoffanker fehlt am gesamten Item-Bestand (trifft das Kernversprechen).**
Ist: Alle ~299 Items im Pool tragen `klasse: 8`. Es existiert kein `grade_level` als Stoffanker — ein Item weiß, dass es aus VERA-8 stammt, aber nicht, aus welchem Stoffjahrgang die geprüfte Kompetenz kommt („Berechne 20 % von 80 m" ist Prozentrechnung = Klasse-7-Stoff; das steht nirgends). Ohne dieses Tag kann die LSA nicht nach unten absteigen, der Report keine Root-Cause benennen, und die zentrale Verkaufsaussage („scheitert an Klasse 8, weil Bruchrechnung aus Klasse 6 fehlt") ist nicht belegbar.
Konsequenz: Das ist kein Datenbankfeld, das man hinzufügt, sondern ein **Content-Projekt** — Bestandsitems (60+) müssen fachlich nach Stoffjahrgang getaggt werden (menschliches QA-Gate), bevor das Fundament-Prinzip (Abschnitt 5) live gehen kann.

**B2 — Fundament-Items existieren nicht.**
Die Root-Cause-Klassiker Bruchrechnung (6), Dezimalzahlen (6), Prozent (7), negative Zahlen (7), Termumformung (7/8) sind im Pool nicht bzw. ungleichmäßig abgedeckt. Erforderlich: ~30–40 Skeleton-Eigenbauten, mehrere Items pro Thema in verschiedenen Kontexten, QA-Gate vor Datenbankeintrag. B1 (Audit + Tagging) ist Voraussetzung, um die Lücken überhaupt präzise zu benennen.

**B3 — RPC und Tag-Schema kennen weder Schulform noch Ceiling.**
Ist: `lsa_start(p_student_id, p_grade, p_subject)`. Das Zielmodell verlangt vier Inputs (Fach, Stufe, Schulform, Ceiling). Weder existiert die Signatur-Erweiterung noch die Item-Tags `school_form`/Niveau (EESA/MSA/GYM). Die Spec definiert den Ziel-Kontrakt (Signatur + Tag-Schema); die Umsetzung läuft über den bestehenden Datenvertrags-Prozess.

**B4 — Zeitbudget vs. Breadth-Prinzip ist unentschieden (Produktentscheidung).**
20 Minuten LSA, Breadth-Prinzip (mehrere Items pro Thema in verschiedenen Kontexten) und Fundament-Abstieg über zwei Jahrgänge gehen mit Multi-Part-Items (Kostenfaktor 3–5×) rechnerisch nicht auf. Das gehört als Produktentscheidung in die Spec, nicht in die Implementierung. Details und Empfehlung: Abschnitt 9, Punkt 1.

---

## 3. Prozessphasen (Gliederung der Spec)

| Phase | Inhalt | Dauer |
|---|---|---|
| P0 Buchung | Landingpage/Telefon; beraten am Telefon, verkaufen im Termin | — |
| P1 Intake | Coach-geführte Datenaufnahme (siehe Abschnitt 5) | ~10 min |
| P2 LSA | Kind am Tablet im Kiosk-Modus; parallel Elterngespräch (Pain Discovery) | 20 min |
| P3 Auswertung | Report wird generiert; Coach sichtet allein, vor dem Gespräch | 2–3 min |
| P4 Ergebnisgespräch | Reframe Hypothese vs. Befund; System schlägt Lernziel vor, Coach schärft mit Eltern und Kind nach | — |
| P5 Abschluss | Angebot; 30 Tage in Ruhe testen | — |
| P6 Übergang | Zugangscodes mit Vertragsbestätigung, LSA-Ergebnis sofort synchronisiert, kein separates Onboarding | — |

---

## 4. Grundsatzentscheidungen (bindend)

1. **Standardisierte LSA.** Die LSA wird pro Stufe × Fach × Schulform standardisiert zusammengestellt — NICHT um die Problemhypothesen von Eltern/Kind herum konfiguriert. Hypothesen werden erhoben, fließen aber ausschließlich als Kontrastanker in den Report (Vorher-Nachher-Reframe im Ergebnisgespräch), nie in die Item-Auswahl.
2. **Kein Live-KPI-Dashboard für Eltern.** Während der LSA sieht nur der Coach einen Fortschrittsindikator (Aufgabe x/y) zum Timen des Gesprächs. Die volle Analyse kommt erst im Report — ein Reveal-Moment. Das Ergebnis erreicht das Kind nie.
3. **FernUSG-Muster als Datenzustand.** Lernziel-Entwurf (Systemoutput) und Coach-Bestätigung sind zwei getrennte Zustände im Datenmodell. Bestätigung ist ein expliziter Akt, kein impliziter Systemoutput.

---

## 5. Intake (P1) — Inhalte & Form

**Form:**
- Der Coach füllt aus — Formular im Coach-Cockpit, Sektionen in Gesprächsreihenfolge, Checkboxen statt Freitext, genau ein Freitextfeld „Coach-Notizen". Kein Selbstausfüll-Formular für Eltern.
- Die Kind-Hypothese wird getrennt erhoben: beim Tablet-Setup, ohne Eltern daneben, kindgerecht formuliert („Was findest du gerade am schwersten?"), in Du-Form. Gleiche Themen-Checkliste wie bei den Eltern.

**Blöcke & Felder:**

| Block | Felder | Zweck |
|---|---|---|
| Lead | Name Elternteil, Telefon, E-Mail, Herkunftskanal | Follow-up, Kanal-Attribution |
| Kind | Vorname, Stufe, Schulform, Fach; Schule OPTIONAL | LSA-Konfiguration |
| Schulkontext | Zeugnisnote, letzte KA-Note, Buchreihe + Kapitelposition | Ceiling + Baseline |
| Hypothesen | Themen-Checkliste (max. 3), getrennt Eltern/Kind, plus 1 Frage Arbeitsverhalten (Motivation/Prüfungsangst/Konzentration) | Kontrastanker im Report |
| Elternziel | Einfachauswahl: Note X→Y, Versetzung, ZP10, Kurs-Aufstieg G→E, Selbstvertrauen | Verkauf + Referenz fürs Lernziel |
| Einwilligung | DSGVO-Consent Diagnostik-Verarbeitung Kindsdaten, mit Timestamp | Rechtsgrundlage der LSA |

**Ausschlüsse:**
- Keine Felder für Gesundheitsdaten (AD(H)S, Diagnosen, Förderbedarf) — Art. 9 DSGVO, bewusst ausgeschlossen. Spontan mitgeteilte Infos werden vorerst nirgends erfasst (offener Rechtspunkt, s. Abschnitt 9).
- Datenminimierung pre-contract: Jedes Feld muss entweder die LSA konfigurieren, den Verkauf führen oder den Report-Kontrast liefern.

**Buchfrage (ersetzt abstrakte Themenfrage):**
- Physische Schulbücher vor Ort im Regal; das Kind zeigt im echten Buch, wo die Klasse steht (Premium-Moment, präziser als abstrakte Themenbenennung).
- Relevante Reihen Gymnasium NRW: Lambacher Schweizer (Klett), Fundamente der Mathematik (Cornelsen), Elemente der Mathematik und Neue Wege (Westermann). Bei Schulform-Erweiterung wächst die Liste (z. B. Schnittpunkt, Sekundo).
- Im Cockpit: Textliste zur Auswahl. KEINE Buchcover-Bilder in der App (Marken-/Urheberrecht).
- Bücher sind ausschließlich Sequenz-Referenz für das Ceiling — niemals Content-Quelle (No-Derivative-Regel für Verlagsinhalte gilt unverändert).

---

## 6. Ceiling-Logik (LSA-Konfiguration) — abhängig von B1 und B3

- Nur 4 Inputs konfigurieren die LSA maschinell: **Fach, Stufe, Schulform, Ceiling.** (Ziel-Kontrakt; heutige RPC-Signatur siehe B3.)
- **Default mit Override:** `ceiling_default = f(Stufe, Kalenderdatum)`. August bis ~Oktober automatisch „Ende Vorstufe" (Schuljahresbeginn = sauberster Messzeitpunkt, kein Buch nötig). Danach Verfeinerung über Buchreihe + Kapitelposition via Mapping-Tabelle `Buchreihe → Kapitel → Kompetenz-Tags`. Coach sieht den Vorschlag und bestätigt oder überschreibt (Muster: System schlägt vor, Coach bestätigt).
- Kapitelposition ist starkes Proxy, nicht Wahrheit (Lehrer springen) — der Blätter-Moment mit dem Kind fängt das ab.
- **Filter wirkt nur nach oben:** Das Fundament aus Stufe 6/7 wird IMMER getestet, unabhängig vom Ceiling (Root-Cause-Prinzip — Kernversprechen ist der Befund, den das Zeugnis nicht liefert). Voraussetzung dafür: B1 (Stoffanker) und B2 (Fundament-Items).
- **Launch-Relevanz:** Januar 2027 = NRW-Halbjahreswechsel. Die allererste Kohorte ist der komplizierte Fall — Buchfrage ist Day-1-relevant.
- Randfälle (Backlog, in Spec als solche führen): Sitzenbleiber (Ceiling höher setzen), Schulformwechsler von der Realschule (Ceiling formal gleich, Niveau-Kalibrierung anders).

---

## 7. Item-Pool & Tagging

**Quellen pro Stufe:**

| Stufe | Rückgrat | Decke |
|---|---|---|
| 8 | VERA-8/IQB (CC BY 4.0) | Stufe 8, einstiegszeitpunktabhängig |
| 9 | VERA-8 + eigene Extension-Items | KMK-Bildungsstandards MSA |
| 10 | VERA-8/9er-Items + eigene Items im ZP10-Format | ZP10 GYM-Niveau |

**Lizenz-Regeln (bindend):**
- VERA-8/IQB: CC BY 4.0 — Attribution verpflichtend; `source` muss in die lsa_question_payload-Whitelist (bestehender offener Backend-Punkt).
- ZP10-Originalaufgaben werden NIE kopiert (keine CC-Lizenz). Nur Format-/Kompetenzreferenz nach Skeleton-Prinzip: Aufgabenformate sind nicht schutzfähig, konkrete Aufgaben schon.
- Verifizierter Stand: Die ZP10 gilt am G9-Gymnasium in NRW wieder (mit eigenem GYM-Anforderungsniveau neben EESA/MSA). Verkäuferisch relevant, weil Eltern die Prüfung kennen.

**Item-Pflichttags (Zielschema — Ist-Stand siehe B1/B3):**
- Kompetenzstrang (Leitidee), `grade_level` (Stoffanker — Stoffjahrgang der geprüften Kompetenz, NICHT Herkunftsjahrgang des Tests), `afb` (I–III), Niveau-Tag (EESA/MSA/GYM), `school_form`-Eignung.
- **Kritisch: AFB ≠ Klassenstufe.** AFB misst kognitiven Anspruch, nicht Stoffjahrgang. Die LSA steigt beim Fundament-Abstieg über `grade_level` ab, bei konstant niedrigem AFB I–II. AFB darf nie als Absteige-Achse dienen.

**Content-Projekt (= B1 + B2, Blocker vor Go-Live der LSA):**
1. Audit des Bestands (~299 Items) nach Stoffjahrgang × Leitidee, fachliches Tagging mit menschlichem QA-Gate.
2. ~30–40 Skeleton-Eigenbauten für die Root-Cause-Klassiker: Bruchrechnung (6), Dezimalzahlen (6), Prozent (7), negative Zahlen (7), Termumformung (7/8). Mehrere Items pro Thema in verschiedenen Kontexten (Breadth-Prinzip). QA-Gate vor Datenbankeintrag (bestehende Pipeline).

---

## 8. Schulform als First-Class-Dimension

- Der Prozess ist schulform-agnostisch. Go-to-Market bleibt Gymnasium-fokussiert; das Datenmodell wird aber JETZT schulform-fähig gebaut (nachträglich teuer). Hauptschule ist ausgeschlossen (in Köln kaum vorhanden).
- `school_form` als Dimension an Ceiling-Logik und Item-Schwierigkeitsband.
- **Gesamtschule:** Fachleistungsdifferenzierung — `course_level` (G-Kurs/E-Kurs) PRO FACH als Pflichtfeld im Intake (ein Kind kann Mathe G / Englisch E sitzen). Der Kurs bestimmt das ZP10-Niveau (EESA oder MSA, nie GYM) und die halbe Kalibrierung. Kurs-Aufstieg G→E ist ein eigener Eintrag in der Elternziel-Auswahl (Oberstufen-Qualifikation FOR-Q hängt an E-Kursen).
- Report-Benchmark-Formulierung pro Schulform („gemessen am MSA-Niveau").

---

## 9. Datenmodell (Grobschnitt für die Spec)

- Objekte: `lead`, `intake_session` (inkl. `textbook_series`, `chapter_position`, `course_level`), `hypotheses` (mit `source: parent|child`), `consents` (mit Timestamp), LSA-Session, Report, Lernziel-Entwurf + Coach-Bestätigung (getrennte Zustände).
- Buch-Metadaten leben an der `intake_session`, NICHT am Item. Items tragen nur ihre Tags (Abschnitt 7). Ein Item „weiß" nie, aus welchem Buch gefiltert wurde.
- Alles pre-contract strikt getrennt vom späteren Schülerkonto → triviale Löschung bei Nicht-Abschluss (auch Verkaufsargument: „Wenn Sie sich dagegen entscheiden, löschen wir alles").
- Bestehende Backend-Realität, an der sich Naming orientieren soll: LSA-RPCs `lsa_start` / `lsa_submit` / `lsa_finish`; `lsa_question_payload` enthält keine Lösungen; `lsa_submit` gibt keine Per-Item-Korrektheit zurück.
- **Ziel-Kontrakt** (Spec definiert, Umsetzung via Datenvertrag): `lsa_start` erweitert um Schulform + Ceiling (Signaturdetails in der Spec festlegen — Einzelparameter oder Konfigurationsobjekt), Item-Tag-Schema gemäß Abschnitt 7.

---

## 10. Offene Punkte (in der Spec als OFFEN markieren)

1. **Zeitbudget vs. Breadth (B4, Produktentscheidung Gründerrunde).** Optionen: (a) LSA auf 25–30 min verlängern, (b) Diagnose flacher, (c) zweistufig-adaptives Design. **Empfehlung (nicht entschieden):** Option c — Phase 1 Screening mit 1 Item pro Thema in kurzen Single-Part-Formaten, Phase 2 Drill-down nur auf auffällige Themen mit 2–3 Items in verschiedenen Kontexten; Multi-Part-Items aus der LSA ausgeschlossen (nur Lernpfad). Überschlag: ~45–60 s/Item → 20–25 Items in 20 min → ~10 Screening + ~12 Drill-down auf 3–4 Themen. Breadth entsteht damit genau dort, wo der Befund behauptet wird. Falls Pilotphase zeigt, dass es nicht reicht: verlängern statt verflachen.
2. Aufsicht des Kindes während der 20-min-LSA, wenn der Coach bei den Eltern sitzt; Kiosk-Modus als harte Tablet-Anforderung.
3. Vertragslaufzeit 6 vs. 12 Monate (Entscheidung ausstehend).
4. Rechtsfragen (extern zu klären): zulässiger Datenumfang pre-contract; ob die Einwilligung eines Elternteils für die Kind-Diagnostik ausreicht; Umgang mit spontan mitgeteilten Gesundheitsinfos.
5. Realtime vs. Batch bei den LSA-Verlaufs-KPIs für den Coach (nur Fortschrittsindikator ist entschieden; Granularität der späteren Report-KPIs offen).
