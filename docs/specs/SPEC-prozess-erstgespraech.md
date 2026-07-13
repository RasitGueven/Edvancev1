# Produktspezifikation: Prozess Erstgespräch

**Stand:** 2026-07-13 · **Adressat:** Gründerrunde (CEO, COO, CMO)
**Quelle der bindenden Entscheidungen:** `prompts/handover-spec-erstgespraech.md`, Abschnitte 3–8
**Verifikationsbasis:** `schema.sql`, `supabase/migrations/*`, `docs/api/DATENVERTRAG.md`,
Live-Abfrage der Supabase-Instanz (`aws-1-eu-central-1.pooler.supabase.com`) am 2026-07-13,
`data/vera8_komplett_enriched.json`

Diese Spec beschreibt den Prozess von der Buchung bis zum Übergang ins laufende Coaching.
Sie trifft keine der in Abschnitt 3–8 des Handovers getroffenen Entscheidungen neu und löst
keinen der offenen Punkte auf.

**Was Kapitel 4 und 5 ergeben — vorweg, weil es die Planung ändert:** Der im Handover
beschriebene Ist-Zustand ist an drei Stellen zu optimistisch. Der LSA-Item-Pool in der
Datenbank besteht aus **14 Aufgaben**, nicht aus 299. Die 299 Items liegen in einer
Content-Datei, nicht in der Datenbank. Und die 86 Multi-Part-Items, deren Ausschluss aus der
LSA in Abschnitt 10.1 zur Diskussion steht, sind noch gar nicht importiert — der Zielkonflikt
ist heute noch kostenlos auflösbar, in drei Monaten nicht mehr.

---

## 1. Zielbild und Leitprinzipien

Das Erstgespräch ist kein Verkaufsgespräch mit angehängtem Test. Es ist ein Diagnostik-Event,
dessen Ergebnis den Verkauf trägt. Der Elternteil kommt mit einer Hypothese („er ist faul",
„Mathe liegt ihr nicht") und geht mit einem Befund („sie scheitert an Klasse 8, weil die
Bruchrechnung aus Klasse 6 nicht sitzt"). Diese Differenz — Hypothese gegen Befund — ist das
Produkt.

### Leitprinzip 1: FernUSG — das System schlägt vor, der Coach bestätigt

Jeder Systemoutput, der pädagogische Wirkung entfaltet, ist ein **Vorschlag**. Wirksam wird er
erst durch einen expliziten menschlichen Akt. Das ist keine Compliance-Kosmetik, sondern die
Bedingung, unter der wir kein zulassungspflichtiger Fernlehrgang sind.

Konkret heißt das: Lernziel-Entwurf (System) und Lernziel-Bestätigung (Coach) sind **zwei
getrennte Zustände im Datenmodell**, nicht ein Feld mit einem Flag. Dasselbe gilt für Mastery.

Dieses Muster ist im Backend bereits implementiert und durch Tests abgesichert: `lsa_finish`
liefert einen Vorschlag mit `is_proposal: true, applied: false`; erst `lsa_confirm_focus`
(nur Coach/Admin) schreibt ihn scharf. Der Prozess Erstgespräch erbt dieses Muster, er erfindet
es nicht neu.

### Leitprinzip 2: Standardisierte LSA

Die LSA wird pro **Stufe × Fach × Schulform** standardisiert zusammengestellt — nicht um die
Problemhypothesen von Eltern und Kind herum konfiguriert.

Der Grund ist diagnostisch, nicht organisatorisch: Eine LSA, die dort sucht, wo die Eltern ein
Problem vermuten, kann den Befund nicht liefern, der die Eltern überrascht. Sie würde die
Hypothese bestätigen statt sie zu widerlegen. Hypothesen werden erhoben — aber sie fließen
**ausschließlich als Kontrastanker in den Report**, nie in die Item-Auswahl.

Maschinell konfigurieren die LSA genau vier Inputs: **Fach, Stufe, Schulform, Ceiling.**

### Leitprinzip 3: Der Reveal-Moment

Das LSA-Ergebnis erreicht das Kind **nie** — weder während der Bearbeitung noch danach. Kein
Richtig/Falsch, keine Häkchen, keine Farben, kein Score, kein XP, keine Streak. Die LSA ist eine
Diagnose, kein Übungsmodus.

Während der LSA sieht auch der Elternteil **kein** Live-Dashboard. Nur der Coach sieht einen
Fortschrittsindikator (Aufgabe x von y) — und zwar zu einem einzigen Zweck: um das parallel
laufende Elterngespräch zu timen.

Die volle Analyse kommt erst im Report, im Ergebnisgespräch, aus dem Mund des Coaches. Das ist
eine Produktentscheidung mit Verkaufslogik: Ein Live-Ticker, der zeigt, wie das Kind gerade
scheitert, zerstört den Moment, in dem der Coach den Befund einordnet.

Diese Regel ist im Backend bereits hart verdrahtet: `lsa_submit` gibt keine Korrektheit zurück,
und der Schüler hat auf `lsa_responses` und `lsa_sessions` kein Leserecht. Das Frontend kann
nichts über Richtigkeit anzeigen, weil es nichts darüber erfährt.

### Leitprinzip 4: Root-Cause statt Symptom

Das Zeugnis sagt „Note 4 in Mathe". Die LSA sagt, warum. Dafür muss sie **unter** die aktuelle
Klassenstufe greifen können: Das Fundament aus Stufe 6/7 wird immer getestet, unabhängig davon,
wie weit die Klasse im Stoff ist.

Das ist die zentrale Verkaufsaussage — und der heute **am wenigsten eingelöste** Teil des
Systems (siehe Kapitel 4, B1/B2).

### Leitprinzip 5: Datenminimierung vor Vertragsschluss

Alles, was vor Vertragsabschluss erhoben wird, ist strikt vom späteren Schülerkonto getrennt.
Jedes Feld muss eine von drei Fragen mit Ja beantworten: Konfiguriert es die LSA? Führt es den
Verkauf? Liefert es den Report-Kontrast? Wenn nein, wird es nicht erhoben.

Das ist zugleich ein Verkaufsargument: „Wenn Sie sich dagegen entscheiden, löschen wir alles."
Diese Zusage muss technisch trivial einlösbar sein — ein Löschvorgang, keine Migration.

Gesundheitsdaten (AD(H)S, Diagnosen, Förderbedarf) werden **nicht** erhoben — Art. 9 DSGVO,
bewusste Entscheidung. Spontan mitgeteilte Informationen werden vorerst nirgends erfasst (offener
Rechtspunkt, siehe Kapitel 6).

---

## 2. Prozessphasen P0–P6

| Phase | Inhalt | Dauer |
|---|---|---|
| P0 Buchung | Landingpage/Telefon; beraten am Telefon, verkaufen im Termin | — |
| P1 Intake | Coach-geführte Datenaufnahme | ~10 min |
| P2 LSA | Kind am Tablet im Kiosk-Modus; parallel Elterngespräch | 20 min |
| P3 Auswertung | Report wird generiert; Coach sichtet allein | 2–3 min |
| P4 Ergebnisgespräch | Reframe Hypothese vs. Befund; Lernziel-Vorschlag → Coach-Bestätigung | — |
| P5 Abschluss | Angebot; 30 Tage in Ruhe testen | — |
| P6 Übergang | Zugangscodes mit Vertragsbestätigung; kein separates Onboarding | — |

---

### P0 — Buchung

**Ablauf.** Der Lead entsteht über Landingpage oder Telefon. Grundsatz: **am Telefon wird
beraten, im Termin wird verkauft.** Das Telefonat qualifiziert und terminiert, es verkauft nicht.

**Rollen.** Interessent (Elternteil) · Lead-Verantwortlicher (Ashkan)

**Screens.**
- *Öffentlich:* Buchungsformular auf der Landingpage. Minimal: Name, Kontakt, Klasse, Fach,
  Terminwunsch. Kein Diagnostik-Fragebogen, keine Themenabfrage — die Erhebung gehört in P1, wo
  ein Coach sie führt.
- *Intern:* Lead-Liste im Cockpit, mit Status und Herkunftskanal.

**Datenobjekte.** `Lead` — Zustände: `neu → kontaktiert → termin_vereinbart → erschienen |
nicht_erschienen`.

**Akzeptanzkriterien.**
- A0.1 — Ein über die Landingpage angelegter Lead trägt einen Herkunftskanal, der eine
  Kanal-Attribution erlaubt (CMO-Anforderung).
- A0.2 — Ein Lead kann ohne Kind-Datensatz existieren. Vor dem Termin entstehen keine
  Diagnostikdaten über ein Kind.
- A0.3 — Ein Lead im Status `nicht_erschienen` ist ohne Nebenwirkung löschbar.

---

### P1 — Intake (~10 min)

**Ablauf.** Der Coach führt das Gespräch und füllt das Formular selbst aus — Sektionen in
Gesprächsreihenfolge, Checkboxen statt Freitext, genau **ein** Freitextfeld („Coach-Notizen").
Es gibt **kein** Selbstausfüll-Formular für Eltern. Ein Formular, das der Elternteil im Wartezimmer
ausfüllt, produziert Daten, aber kein Gespräch.

**Die Kind-Hypothese wird getrennt erhoben** — beim Tablet-Setup, ohne Eltern daneben, kindgerecht
und in Du-Form („Was findest du gerade am schwersten?"), gegen dieselbe Themen-Checkliste wie bei
den Eltern. Die Differenz zwischen Eltern- und Kind-Hypothese ist selbst ein diagnostischer
Befund und gehört in den Report.

**Der Buch-Moment.** Statt einer abstrakten Themenfrage stehen die physischen Schulbücher im
Regal. Das Kind zeigt im echten Buch, wo die Klasse steht. Das ist präziser als jede
Themenbenennung und ein Premium-Moment.

- Relevante Reihen Gymnasium NRW: Lambacher Schweizer (Klett), Fundamente der Mathematik
  (Cornelsen), Elemente der Mathematik und Neue Wege (Westermann). Bei Schulform-Erweiterung
  wächst die Liste (z. B. Schnittpunkt, Sekundo).
- Im Cockpit erscheint eine **Textliste** zur Auswahl. **Keine Buchcover-Bilder in der App**
  (Marken-/Urheberrecht).
- Bücher sind **ausschließlich Sequenz-Referenz für das Ceiling** — niemals Content-Quelle. Die
  No-Derivative-Regel für Verlagsinhalte gilt unverändert.

**Rollen.** Coach (führt, füllt aus) · Elternteil (antwortet) · Kind (antwortet separat)

**Screens.**

*S1.1 Intake-Formular (Coach-Cockpit)* — Sektionen in Gesprächsreihenfolge:

| Block | Felder | Zweck |
|---|---|---|
| Lead | Name Elternteil, Telefon, E-Mail, Herkunftskanal | Follow-up, Kanal-Attribution |
| Kind | Vorname, Stufe, Schulform, Fach; Schule OPTIONAL | LSA-Konfiguration |
| Schulkontext | Zeugnisnote, letzte KA-Note, Buchreihe + Kapitelposition | Ceiling + Baseline |
| Hypothesen | Themen-Checkliste (max. 3), getrennt Eltern/Kind, plus 1 Frage Arbeitsverhalten (Motivation/Prüfungsangst/Konzentration) | Kontrastanker im Report |
| Elternziel | Einfachauswahl: Note X→Y, Versetzung, ZP10, Kurs-Aufstieg G→E, Selbstvertrauen | Verkauf + Referenz fürs Lernziel |
| Einwilligung | DSGVO-Consent Diagnostik-Verarbeitung Kindsdaten, mit Timestamp | Rechtsgrundlage der LSA |

Bei Schulform *Gesamtschule* erscheint zusätzlich **`course_level` (G-Kurs / E-Kurs) pro Fach als
Pflichtfeld** — ein Kind kann Mathe G und Englisch E sitzen (siehe P1-Sonderfall unten).

*S1.2 Kind-Hypothese (Tablet, Setup-Screen)* — dieselbe Themen-Checkliste, kindgerechte
Formulierung, Du-Form. Läuft ohne Eltern.

*S1.3 Ceiling-Vorschlag (Coach-Cockpit)* — das System schlägt ein Ceiling vor, der Coach
bestätigt oder überschreibt. Details siehe unten.

**Ceiling-Logik.**
- **Default mit Override:** `ceiling_default = f(Stufe, Kalenderdatum)`. August bis ca. Oktober
  automatisch „Ende Vorstufe" — der Schuljahresbeginn ist der sauberste Messzeitpunkt, da braucht
  es kein Buch. Danach Verfeinerung über Buchreihe + Kapitelposition via Mapping-Tabelle
  `Buchreihe → Kapitel → Kompetenz-Tags`.
- Die Kapitelposition ist ein **starkes Proxy, nicht die Wahrheit** — Lehrer springen im Buch.
  Der Blätter-Moment mit dem Kind fängt das ab.
- **Der Ceiling-Filter wirkt nur nach oben.** Nach unten wird nicht gefiltert: Das Fundament aus
  Stufe 6/7 wird **immer** getestet, unabhängig vom Ceiling. Das ist Leitprinzip 4 — und es ist
  heute nicht einlösbar (Kapitel 5, B1/B2).
- **Launch-Relevanz:** Januar 2027 ist NRW-Halbjahreswechsel. Die allererste Kohorte ist damit
  ausgerechnet der komplizierte Fall — mitten im Schuljahr, Default-Regel greift nicht, das Buch
  entscheidet. **Die Buchfrage ist Day-1-relevant, nicht Backlog.**

**Sonderfall Gesamtschule (Schulform als First-Class-Dimension).** Der Prozess ist
schulform-agnostisch gebaut, auch wenn Go-to-Market Gymnasium-fokussiert bleibt — nachträglich ist
das teuer. Hauptschule ist ausgeschlossen (in Köln kaum vorhanden). An der Gesamtschule bestimmt
der Kurs (G/E) das ZP10-Niveau (EESA oder MSA, nie GYM) und die halbe Kalibrierung. Kurs-Aufstieg
G→E ist deshalb ein eigener Eintrag in der Elternziel-Auswahl (die Oberstufen-Qualifikation FOR-Q
hängt an den E-Kursen).

**Randfälle (Backlog, bewusst nicht in V1).**
- Sitzenbleiber: Ceiling höher setzen.
- Schulformwechsler von der Realschule: Ceiling formal gleich, Niveau-Kalibrierung anders.

**Datenobjekte.** `IntakeSession` (Zustände: `entwurf → vollstaendig → lsa_gestartet`) ·
`Hypothese` (n×, mit `source: parent | child`) · `Consent` (mit Timestamp)

**Akzeptanzkriterien.**
- A1.1 — Die LSA lässt sich nicht starten, bevor ein gültiger Consent mit Timestamp vorliegt.
  Der Consent ist die Rechtsgrundlage der Diagnostik, nicht eine Formalie danach.
- A1.2 — Eltern- und Kind-Hypothese sind getrennt gespeichert und im Report getrennt darstellbar.
  Eine zusammengeführte Hypothese ist kein gültiger Zustand.
- A1.3 — Das Intake-Formular enthält **kein** Feld für Gesundheitsdaten.
- A1.4 — Der Coach kann das vorgeschlagene Ceiling überschreiben; die Überschreibung ist als
  solche erkennbar (System-Vorschlag und Coach-Entscheidung sind zwei Werte, nicht einer).
- A1.5 — Bei Schulform *Gesamtschule* ist `course_level` pro Fach ein Pflichtfeld.
- A1.6 — Buchreihen erscheinen als Textliste. Keine Cover-Bilder.
- A1.7 — Genau ein Freitextfeld im gesamten Formular.

---

### P2 — LSA (20 min)

**Ablauf.** Das Kind bearbeitet die LSA am Tablet im **Kiosk-Modus**. Parallel führt der Coach das
Elterngespräch (Pain Discovery). Die LSA ist ein **kostenloses Diagnostik-Event** und das primäre
Go-to-Market-Instrument.

Es werden ausschließlich **auto-gradbare Aufgabentypen** eingesetzt: Multiple Choice, Short-Input,
Bildanzeige. Kein Freitext — was ein Mensch korrigieren muss, kann in 20 Minuten kein Ergebnis
liefern.

**Rollen.** Kind (bearbeitet) · Coach (führt parallel das Elterngespräch, sieht nur den
Fortschrittsindikator) · Elternteil (im Gespräch, sieht nichts)

**Screens.**
- *S2.1 LSA-Tablet (Kind):* Eine Aufgabe pro Screen. Kein Richtig/Falsch, keine Farben, kein XP,
  keine Streak, kein Score, kein Zwischenfeedback — auf keiner Ebene. Hinweise nur einzeln auf
  Anfrage.
- *S2.2 Fortschrittsindikator (Coach):* „Aufgabe 7 von 14". Mehr nicht. Kein KPI, keine
  Trefferquote, keine Live-Auswertung. Zweck ist das Timing des Elterngesprächs, nichts sonst.

**Datenobjekte.** `LSA-Session` (Zustände: `in_progress → completed | abandoned`) · `LSA-Response`
(append-only, eine Zeile pro Antwort; bei Multi-Part eine Zeile pro Teilaufgabe)

**Akzeptanzkriterien.**
- A2.1 — Das Kind erhält zu keinem Zeitpunkt eine Rückmeldung über Korrektheit — weder pro
  Teilaufgabe noch pro Item noch aggregiert noch als Zähler.
- A2.2 — Der Elternteil sieht während der LSA keine Ergebnisdaten.
- A2.3 — Der Coach sieht ausschließlich den Fortschritt (x von y), keine Korrektheit.
- A2.4 — Antworten sind append-only. Kein Update, kein Delete.
- A2.5 — Die LSA-Zusammenstellung hängt **nicht** von den erhobenen Hypothesen ab. Zwei Kinder mit
  gleicher Konfiguration (Fach, Stufe, Schulform, Ceiling) und unterschiedlichen Hypothesen
  erhalten denselben Test.
- A2.6 — Die Bearbeitungszeit liegt im Zielkorridor 20 Minuten (siehe OFFEN-1).
- A2.7 — Pro (Kind, Fach) läuft höchstens eine LSA-Session gleichzeitig.

---

### P3 — Auswertung (2–3 min)

**Ablauf.** Der Report wird generiert. **Der Coach sichtet ihn allein, vor dem Gespräch.** Er
betritt das Ergebnisgespräch nicht als Vorleser eines Systemoutputs, sondern als jemand, der den
Befund verstanden hat. Diese 2–3 Minuten sind Teil des Prozesses, kein Puffer.

**Rollen.** System (generiert) · Coach (sichtet, allein)

**Screens.** *S3.1 Coach-Report (intern):* Aggregation **pro Kompetenz**, nicht pro Aufgabe.
Trefferquote je Kompetenzstrang, AFB-Verteilung, Bearbeitungsdauern. Dazu die Hypothesen von
Eltern und Kind als Kontrast — nebeneinander, nicht vermischt. Dazu der **Lernziel-Entwurf** des
Systems, klar als Vorschlag markiert.

**Datenobjekte.** `Report` (Zustände: `generiert → gesichtet → im_gespraech_verwendet`) ·
`Lernziel-Entwurf` (Zustand: `vorschlag`)

**Akzeptanzkriterien.**
- A3.1 — Der Report ist ohne Coach-Bestätigung nicht wirksam: Er schreibt keinen Lernpfad, kein
  `mastered`, keinen Fokus. Er schlägt vor.
- A3.2 — Der Lernziel-Entwurf ist im Datenmodell als Vorschlag erkennbar (nicht als Zielzustand
  mit Flag).
- A3.3 — Der Report benennt den Befund auf Kompetenz-Ebene und nennt — sofern die Datenlage es
  hergibt — den **Stoffjahrgang** der ausgefallenen Kompetenz. Genau das ist heute nicht möglich
  (Kapitel 5, B1).
- A3.4 — Die Benchmark-Formulierung im Report ist schulformabhängig („gemessen am MSA-Niveau").
- A3.5 — Der Report ist für das Kind nicht abrufbar.

---

### P4 — Ergebnisgespräch

**Ablauf.** Das Herzstück. Der Coach stellt die **Hypothese dem Befund gegenüber** („Sie sagten,
er sei faul — was wir sehen, ist etwas anderes"). Der Reframe ist der Verkauf; das Angebot ist nur
noch die Konsequenz.

Danach schlägt das System ein Lernziel vor. Der Coach **schärft es mit Eltern und Kind nach** und
bestätigt es. Die Bestätigung ist ein expliziter Akt — ein Klick, den ein Mensch tut, nicht ein
Zustand, der aus dem Systemoutput folgt.

**Rollen.** Coach (führt, bestätigt) · Elternteil (versteht, entscheidet) · Kind (anwesend,
beteiligt am Lernziel)

**Screens.** *S4.1 Ergebnisgespräch (Coach-geführt, für Eltern sichtbar):* Hypothese und Befund
nebeneinander. Der Befund verständlich formuliert, nicht als KPI-Tabelle. Der Lernziel-Vorschlag
mit der Möglichkeit, ihn im Gespräch anzupassen. Der Bestätigungs-Akt ist ein eigener,
unmissverständlicher Schritt.

**Datenobjekte.** `Lernziel-Entwurf` (`vorschlag`) → `Lernziel-Bestätigung` (`bestaetigt`, mit
Coach-ID und Timestamp) — **zwei getrennte Zustände.**

**Akzeptanzkriterien.**
- A4.1 — Ein Lernziel wird ausschließlich durch einen expliziten Coach-Akt wirksam. Es gibt keinen
  Pfad, auf dem ein Systemoutput allein einen Lernpfad aktiviert.
- A4.2 — Die Bestätigung trägt Coach-Identität und Zeitpunkt.
- A4.3 — Ein bestätigtes Lernziel ist vom Vorschlag unterscheidbar — auch rückwirkend, auch in der
  Historie.
- A4.4 — Ein bestätigtes Lernziel kann von den vorgeschlagenen Kompetenzen abweichen (der Coach
  schärft nach; er darf nicht nur „ja" sagen können).
- A4.5 — Kein visuelles „Mastered"-Label ohne Backend-Bestätigung durch die Coach-Rolle.

---

### P5 — Abschluss

**Ablauf.** Angebot. **30 Tage in Ruhe testen.** Vertragslaufzeit 6 oder 12 Monate — siehe OFFEN-3.

**Rollen.** Coach/Vertrieb · Elternteil

**Screens.** *S5.1 Angebot & Vertrag.*

**Datenobjekte.** `Vertrag` (Zustände: `angeboten → abgeschlossen | abgelehnt`)

**Akzeptanzkriterien.**
- A5.1 — Bei `abgelehnt` sind alle pre-contract erhobenen Daten des Kindes in einem Vorgang
  löschbar, ohne Reste im Schülerkonto-Bereich. Diese Löschbarkeit ist zugleich Verkaufsargument
  („Wenn Sie sich dagegen entscheiden, löschen wir alles") und muss deshalb demonstrierbar sein.
- A5.2 — Der Vertragsabschluss ist die einzige Bedingung für die Konto-Erstellung.

---

### P6 — Übergang

**Ablauf.** Zugangscodes werden **mit der Vertragsbestätigung** ausgegeben. Das LSA-Ergebnis ist
sofort synchronisiert. **Es gibt kein separates Onboarding** — das Kind loggt sich ein und findet
seinen Lernpfad vor, der auf der LSA basiert, die es bereits bearbeitet hat.

**Rollen.** System (übernimmt) · Coach (begleitet ersten Termin)

**Screens.** *S6.1 Erster Login des Kindes:* Der Lernpfad steht. Kein Fragebogen, kein
Einstiegstest, keine Wiederholung dessen, was im Erstgespräch schon passiert ist.

**Datenobjekte.** `Lead`/`IntakeSession` → Schülerkonto (`Student`, `Lernpfad`/Fokus-Bereiche
aus der bestätigten LSA)

**Akzeptanzkriterien.**
- A6.1 — Der Lernpfad beim Erstlogin entspricht dem in P4 **bestätigten** Lernziel — nicht dem
  Systemvorschlag.
- A6.2 — Kein separater Onboarding-Test.
- A6.3 — Die LSA-Rohdaten bleiben nach der Konto-Erstellung erhalten und bilden die Baseline für
  den späteren Vorher-Nachher-Vergleich im Eltern-Report.
- A6.4 — Das Kind sieht sein LSA-Ergebnis auch nach dem Übergang nicht.

---

## 3. Datenmodell (Zielbild)

Grobschnitt gemäß Handover Abschnitt 9. Feldnamen sind Zielbild, keine Migration.

### `lead`
Kontaktdaten Elternteil, Herkunftskanal, Status.
**Zustände:** `neu → kontaktiert → termin_vereinbart → erschienen | nicht_erschienen`

### `intake_session`
Der Kern der Datenaufnahme. Trägt: Kind-Stammdaten (Vorname, Stufe, Schulform, Fach, Schule
optional), Schulkontext (Zeugnisnote, letzte KA-Note), **`textbook_series`**,
**`chapter_position`**, **`course_level`** (pro Fach, Pflicht bei Gesamtschule), Elternziel,
Ceiling-Vorschlag und Ceiling-Bestätigung (getrennt), genau ein Freitextfeld „Coach-Notizen".
**Zustände:** `entwurf → vollstaendig → lsa_gestartet`

**Wichtig:** Die Buch-Metadaten leben an der `intake_session`, **nicht am Item**. Ein Item „weiß"
nie, aus welchem Buch gefiltert wurde. Das Buch ist eine Eigenschaft der Situation des Kindes,
nicht der Aufgabe.

### `hypotheses`
n Einträge pro Intake, jeder mit **`source: parent | child`**. Themen-Checkliste (max. 3 je
Quelle) plus eine Frage zum Arbeitsverhalten (Motivation / Prüfungsangst / Konzentration).
**Zweck:** ausschließlich Kontrastanker im Report. Fließt **nie** in die Item-Auswahl.

### `consents`
DSGVO-Einwilligung zur Diagnostik-Verarbeitung der Kindsdaten, **mit Timestamp**.
**Zustände:** `erteilt` (→ `widerrufen`)
**Invariante:** Ohne gültigen Consent startet keine LSA.

### `LSA-Session` + `LSA-Response`
Naming folgt der bestehenden Backend-Realität: RPCs `lsa_start` / `lsa_submit` / `lsa_hint` /
`lsa_finish` / `lsa_confirm_focus`.
**Zustände Session:** `in_progress → completed | abandoned`
**Responses:** append-only, keine Korrektheit an den Client.

### `Report`
**Zustände:** `generiert → gesichtet → im_gespraech_verwendet`

### `Lernziel-Entwurf` und `Lernziel-Bestätigung` — zwei Objekte, nicht eins

Das ist die datenmodell-gewordene FernUSG-Regel:

| | Entwurf | Bestätigung |
|---|---|---|
| Erzeuger | System (`lsa_finish`) | Coach (`lsa_confirm_focus`) |
| Zustand | `vorschlag`, `applied: false` | `bestaetigt`, mit Coach-ID + Timestamp |
| Wirkung | keine | schreibt den Fokus / Lernpfad |

**Ein Zustandsübergang `vorschlag → bestaetigt` ohne menschlichen Akteur ist kein gültiger
Übergang.**

### Item-Tag-Schema (Zielbild, siehe Kapitel 5 / B1)

Pflichttags pro Item:
- **Kompetenzstrang (Leitidee)**
- **`grade_level` — Stoffanker:** der Stoffjahrgang der *geprüften Kompetenz*, **nicht** der
  Herkunftsjahrgang des Tests. „Berechne 20 % von 80 m" ist Prozentrechnung = Klasse-7-Stoff,
  auch wenn die Aufgabe aus VERA-8 stammt.
- **`afb`** (I–III)
- **Niveau-Tag** (EESA / MSA / GYM)
- **`school_form`-Eignung**

**Kritisch: AFB ≠ Klassenstufe.** AFB misst den *kognitiven Anspruch*, nicht den Stoffjahrgang.
Der Fundament-Abstieg läuft über **`grade_level`** bei konstant niedrigem AFB (I–II). **AFB darf
nie als Absteige-Achse dienen** — eine leichte Klasse-8-Aufgabe ist keine Klasse-6-Aufgabe.

### Trennung pre-contract / post-contract

Alles aus P0–P5 ist strikt vom späteren Schülerkonto getrennt. Bei Nicht-Abschluss: ein
Löschvorgang, keine Migration.

---

## 4. Delta zum Ist-Zustand

**Methodik:** Nicht gegen das Handover geprüft, sondern gegen den Code und die laufende Datenbank
(Live-Abfrage der Supabase-Instanz am 2026-07-13). Wo Handover und Code sich widersprechen, gilt
der Code.

### 4.0 Drei Korrekturen am Handover — vorab

**Korrektur 1: Der Item-Pool in der Datenbank hat 14 Aufgaben, nicht 299.**

Das Handover spricht von „~299 Items im Pool". Das ist die Zahl in der Content-Datei
`data/vera8_komplett_enriched.json`. In der Datenbank stehen **14 Items**. Der Unterschied ist
nicht akademisch: `lsa_start` zieht aus der Tabelle `tasks`, nicht aus einer JSON-Datei.

| | Content-Datei | Datenbank (`tasks`) |
|---|---|---|
| Items gesamt | 299 | **14** |
| davon `ready` | 144 | 14 |
| Fach | Mathematik | Mathematik |
| Deutsch / Englisch | 0 | **0** |

Von den 144 `ready`-Items der Content-Datei sind also **14 importiert**. Der Rest wartet auf
C07 (Multi-Part-Import) und die `.doc`→`.docx`-Konvertierung.

**Korrektur 2: Die 86 Multi-Part-Items sind noch nicht in der Datenbank.**

Der Auftrag an diese Spec nennt „die 86 MULTI_PART-Items im Bestand". Sie sind **im
Content-Bestand**, nicht im Datenbank-Bestand. `docs/ROADMAP.md` führt „C07: Import der 86
MULTI_PART-Items" als **offenen nächsten Schritt**. Das hat eine erfreuliche Konsequenz — siehe
Kapitel 5, Zielkonflikt.

**Korrektur 3: P02 ist in `dev` gemerged, aber nicht auf der Datenbank angewendet.**

Angewendete Migrationen laut `supabase_migrations.schema_migrations`:

```
20250101000000  baseline
20260711120000  api_role_grants
20260712100000  p01_datenvertrag
```

`20260713100000_p02_multipart.sql` fehlt. Entsprechend existieren auf der Datenbank **nicht**:
`tasks.parts`, `lsa_responses.part_nr`, `lsa_public_parts`, `lsa_parts_valid`, `lsa_has_answers`.
Der `input_type`-CHECK kennt `MULTI_PART` nicht. `docs/ROADMAP.md` bestätigt das explizit:
„P02-Migration deployen — bisher nur lokal verifiziert". Auch `docs/api/DATENVERTRAG.md`
beschreibt damit einen Vertrag, der so noch nicht läuft.

**Für die Gründerrunde heißt das:** Der Multi-Part-Vertrag ist entworfen und getestet
(48/48 pgTAP), aber weder deployt noch mit Inhalten gefüllt. Die Entscheidung aus OFFEN-1
(Multi-Part in der LSA: ja oder nein) fällt damit **vor** dem Deployment — nicht danach.

---

### 4.1 Prozessobjekte

| Zielobjekt | Status | Befund |
|---|---|---|
| `lead` | **existiert teilweise** | Tabelle `leads` da (0 Zeilen). Hat `full_name`, `contact_email`, `contact_phone`, `class_level`, `school_type`, `school_name`, `subjects`, `goal`, `known_weak_topics`, `source`, `status`, `converted_student_id`. Deckt P0 im Kern ab. **Fehlt:** nichts Kritisches. |
| `intake_session` | **existiert, aber falsch geschnitten** | Tabelle `intake_sessions` da (0 Zeilen), aber **freitextlastig**: `goals`, `motivation`, `learning_history`, `parent_expectations`, `notes`, `agreed_next_steps` — sechs Freitextfelder. Das Zielbild verlangt Checkboxen und **genau ein** Freitextfeld. **Fehlt vollständig:** `textbook_series`, `chapter_position`, `course_level`, Zeugnisnote, letzte KA-Note, Ceiling-Vorschlag/-Bestätigung, Schulform. Diese Tabelle ist für einen anderen Prozess gebaut worden und muss neu geschnitten werden. |
| `hypotheses` mit `source: parent\|child` | **fehlt** | Es gibt `leads.known_weak_topics` und `intake_sessions.known_weak_topics` (je ein Array). **Kein Feld trennt Eltern- von Kind-Hypothese.** Die Trennung ist der diagnostische Kern (A1.2) — sie existiert nicht. |
| `consents` mit Timestamp | **fehlt** | Keine Tabelle, kein Feld, kein Timestamp. **Die Rechtsgrundlage der LSA ist heute nicht dokumentiert.** |
| LSA-Session | **existiert** | `lsa_sessions` (1 Zeile), `lsa_responses` (7 Zeilen, append-only). |
| Report | **existiert teilweise** | `lsa_finish` liefert `result_summary` (Kompetenzen, AFB, Vorschlag). Es gibt `parent_reports` / `generate_parent_report` — die lesen aber `screening_tests`, **nicht** die LSA (bewusst getrennt, siehe DATENVERTRAG §5). Ein LSA-Report-Objekt für P3 gibt es nicht. |
| Lernziel-Entwurf / -Bestätigung | **existiert** ✅ | Sauber getrennt: `lsa_finish` → `is_proposal: true, applied: false`; `lsa_confirm_focus` (nur Coach/Admin) → schreibt `student_focus_areas` mit `source='lsa'`. Das Mastery-Gate (`trg_enforce_mastery_gate`) ist aktiv. **Das FernUSG-Muster ist das am besten eingelöste Stück des Zielbilds.** |
| Trennung pre/post-contract | **existiert teilweise** | `leads` und `intake_sessions` sind vom Schülerkonto getrennt. Aber `intake_sessions.student_id` zeigt bereits auf `students` — die LSA läuft heute gegen einen **existierenden Schüler** (`lsa_start(p_student_id …)`), nicht gegen einen Lead. Für P2 vor Vertragsabschluss ist das ein Bruch: Ein Interessentenkind bräuchte heute schon ein Schülerkonto. **Siehe B5.** |

### 4.2 Item-Tags

| Zielfeld | Status | Befund |
|---|---|---|
| Kompetenzstrang (Leitidee) | **existiert** | `tasks.competency_content` (4 Werte: `arithmetik_algebra`, `geometrie`, `funktionen`, `stochastik`) + `skill_clusters` (5) + `tasks.competency_process` / `process_competencies` (6). |
| **`grade_level` (Stoffanker)** | **fehlt** ⚠️ | Siehe 4.3 — der zentrale Befund. |
| `afb` (I–III) | **existiert** | `tasks.afb`. Bei den 14 Items: 13× AFB I, 1× AFB III. Sehr flach. |
| Niveau-Tag (EESA/MSA/GYM) | **fehlt** | Keine Spalte, kein Enum, nirgends. |
| `school_form`-Eignung | **fehlt** | Keine Spalte an `tasks`. (An `leads` gibt es `school_type` — das ist die Schulform des *Kindes*, nicht die Eignung des *Items*.) |
| `est_duration_sec` | **existiert, unbefüllt** | Spalte da, aber bei allen 14 Items **NULL**. `lsa_start` fällt deshalb auf `estimated_minutes × 60` zurück = **180 s pro Item** für alle 14. ROADMAP führt „`est_duration_sec` für die 14 LSA-Bestandsitems pflegen (Lena)" als offenen Punkt. |

### 4.3 B1 im Detail — gibt es irgendwo einen Stoffanker?

**Die Frage war: Gibt es ein Feld, das den Stoffjahrgang der geprüften Kompetenz hält — nicht den
Herkunftsjahrgang des Tests?**

**Antwort: Nein. Aber es gibt zwei Felder, die so aussehen, als täten sie es — und beide tun es
nicht.**

**Kandidat 1: `tasks.class_level`** (integer, CHECK 5–13)
- Bei allen 14 Items: **8**. In der Content-Datei bei allen 299: `klasse: 8`.
- Semantik: **Herkunftsjahrgang.** Die Items stammen aus VERA-8, also steht 8 drin. Über den
  Stoffjahrgang der geprüften Kompetenz sagt das Feld nichts.
- **Und es ist bereits tragend:** `lsa_start` filtert darüber —
  `coalesce(t.class_level, p_grade) <= p_grade`. Das Feld ist heute die einzige Jahrgangs-Achse
  der Item-Auswahl. Man kann es also nicht einfach umdeuten; es hängt Logik daran.

**Kandidat 2: `microskills.class_level`** (integer) — **der eigentliche Fund**
- Der `microskills`-Katalog ist die **Themen-Achse**, die dem Zielbild fehlt: „Bruchrechnung sicher
  anwenden", „Prozentwert, Grundwert, Prozentsatz", „Terme aufstellen und vereinfachen",
  „Rationale Zahlen: Vorzeichenregeln" — 17 Einträge, jeder mit einer `class_level`-Spalte.
- Das ist **strukturell genau der richtige Ort für den Stoffanker.** Ein Thema *hat* einen
  Stoffjahrgang, unabhängig davon, in welchem Test es auftaucht. „Bruchrechnung" ist Klasse 6 —
  immer, in jedem Test.
- **Nur: Alle 17 Microskills tragen `class_level = 8`.** Auch „Bruchrechnung sicher anwenden"
  (Klasse-6-Stoff). Auch „Prozentwert, Grundwert, Prozentsatz" (Klasse-7-Stoff). Die Codes sind
  konsequenterweise alle `M8.*` benannt. Dieselbe Pathologie wie bei den Items, eine Ebene höher.
- **Und die Verbindung ist tot:** `tasks.microskill_id` ist bei **0 von 14** Items gesetzt.
  `lsa_start` fasst `microskills` überhaupt nicht an — es gruppiert über
  `competency_content` (die 4 groben Inhaltsfelder).

**Was das für B1 bedeutet — und warum es besser ist als im Handover angenommen:**

B1 ist **kein reines Content-Projekt** (wie das Handover schreibt), sondern zerfällt in drei
Teilprobleme, von denen zwei billig sind:

1. **Struktur (billig, existiert fast):** Der Ort für den Stoffanker ist da —
   `microskills.class_level`, plus `tasks.microskill_id` als Verbindung. Es braucht keine neue
   Tabelle. Ob der Anker am Item (`tasks.grade_level`) oder am Thema (`microskills.class_level`)
   hängt, ist eine Architekturfrage; der Katalog-Weg ist der sauberere, weil er 17 Entscheidungen
   verlangt statt 299.
2. **Befüllung (das eigentliche Content-Projekt, teuer):** Jedes Item braucht die Zuordnung zu
   einem Thema, und jedes Thema den korrekten Stoffjahrgang. Bei 17 Themen ist das
   fachliche Arbeit von Stunden, nicht Wochen — **aber der Themen-Katalog selbst deckt heute nur
   Klasse-8-Stoff ab und muss um die Fundament-Themen erweitert werden** (das ist B2).
3. **Konsum (mittel):** `lsa_start` müsste über den Stoffanker ziehen statt über
   `tasks.class_level`. Das ist eine Änderung an einer Funktion, die bereits im Datenvertrag
   dokumentiert ist — also der etablierte Weg, kein Neuland.

**Was daran hängt (was blockiert B1?):** Der Fundament-Abstieg (P1/Ceiling-Logik), die
Root-Cause-Aussage im Report (A3.3), das zweistufige LSA-Design (OFFEN-1, dessen Drill-down eine
Themen-Achse braucht) und die zentrale Verkaufsaussage. **B1 blockiert das Kernversprechen — das
bestätigt sich.**

### 4.4 B3 im Detail — die RPC-Signatur

**Aktuelle Signatur (exakt, aus `pg_proc` der laufenden Datenbank):**

```sql
lsa_start(p_student_id uuid, p_grade integer, p_subject text) returns jsonb
```

**Der Pool-Filter, exakt (aus `20260712100000_p01_datenvertrag.sql`):**

```sql
from tasks t
join task_solutions s on s.task_id = t.id
join skill_clusters c on c.id = t.cluster_id
join subjects sub     on sub.id = c.subject_id
where t.status = 'ready'
  and coalesce(t.is_active, true)
  and t.input_type in ('MC','SHORT_TEXT','NUMERIC')      -- P02 ergänzt 'MULTI_PART'
  and jsonb_array_length(s.correct_answers) > 0
  and sub.name = p_subject
  and coalesce(t.class_level, p_grade) <= p_grade        -- die einzige Jahrgangs-Achse
```

Gezogen wird **gegen ein Zeitbudget (~1200 s), nicht gegen eine Item-Anzahl**, gemischt per
Round-Robin über AFB × Kompetenzfeld.

**Drei der vier Ziel-Inputs fehlen in der Signatur:** Schulform, Ceiling — und die Stufe (`p_grade`)
ist da, meint aber den Herkunftsjahrgang-Filter, nicht das Ceiling.

**Ziel-Kontrakt (Vorschlag, Umsetzung über den bestehenden Datenvertrags-Prozess):**

```sql
lsa_start(
  p_student_id  uuid,
  p_config      jsonb      -- { subject, grade, school_form, ceiling }
) returns jsonb
```

Ein **Konfigurationsobjekt statt vier Einzelparametern** — Begründung: Die LSA-Konfiguration wird
wachsen (Niveau-Tag, `course_level` bei Gesamtschule, später Fach-spezifische Parameter). Jede
Erweiterung als neuer Positionsparameter ist eine Signaturänderung mit Frontend-Bruch; ein
`jsonb`-Objekt ist additiv erweiterbar. Der Datenvertrag beschreibt dann die Felder des Objekts,
nicht die Reihenfolge der Argumente.

Zugesichert werden müsste:

| Feld | Typ | Wirkung im Pool-Filter |
|---|---|---|
| `subject` | text | wie heute (`sub.name`) |
| `grade` | int | Stufe des Kindes — für Report-Benchmark und Ceiling-Default |
| `school_form` | text (`GYM`\|`GE`\|`RS`) | filtert gegen Item-Tag `school_form`-Eignung / Niveau |
| `ceiling` | Kompetenz-Tag-Menge oder Stoffjahrgang | **filtert nur nach oben.** Nach unten wird nicht gefiltert — das Fundament (Stoffjahrgang 6/7) kommt immer in den Pool. |

Und — der eigentliche Punkt — die **Absteige-Achse wechselt von `tasks.class_level` auf den
Stoffanker**. Ohne B1 ist dieser Kontrakt nicht erfüllbar: Ein `ceiling`-Parameter, der auf ein
Feld filtert, in dem überall 8 steht, ist ein No-op.

**Abhängigkeit: B3 ist ohne B1 wertlos.** Man kann die Signatur erweitern — sie hätte nichts, worauf
sie filtern könnte.

### 4.5 Zusammenfassung des Deltas

| Zielbild-Baustein | Status |
|---|---|
| FernUSG-Muster (Vorschlag/Bestätigung getrennt) | ✅ **existiert, getestet** |
| Reveal-Moment (kein Feedback ans Kind) | ✅ **existiert, im Backend erzwungen** |
| LSA-Session, append-only Responses | ✅ **existiert** |
| Standardisierte Zusammenstellung (Fach + Stufe) | 🟡 **existiert teilweise** (Fach + Herkunftsjahrgang; keine Schulform, kein Ceiling) |
| Multi-Part-Vertrag | 🟡 **entworfen + getestet, nicht deployt, nicht befüllt** |
| `lead` | 🟡 **existiert, brauchbar** |
| `intake_session` | 🟡 **existiert, falsch geschnitten** (freitextlastig, Zielfelder fehlen) |
| Themen-Achse (`microskills`) | 🟡 **existiert, unverbunden** (0/14 Items verknüpft, alle Themen auf Klasse 8) |
| `hypotheses` (Eltern/Kind getrennt) | ❌ **fehlt** |
| `consents` (mit Timestamp) | ❌ **fehlt** |
| **Stoffanker (`grade_level`)** | ❌ **fehlt** |
| Fundament-Items (Klasse 6/7) | ❌ **fehlt — 0 Items unter Klasse 8** |
| Niveau-Tag (EESA/MSA/GYM), `school_form` am Item | ❌ **fehlt** |
| Ceiling-Logik, Buch-Mapping | ❌ **fehlt** |
| LSA-Report für P3 | ❌ **fehlt** (`result_summary` ist die Rohaggregation, kein Report) |
| Items für Deutsch / Englisch | ❌ **fehlt — 0 Items** |

---

## 5. Voraussetzungen und Blocker

### 5.1 Die Blocker, verifiziert

**B1 — Stoffanker fehlt. BESTÄTIGT, mit Korrektur.**
Bestätigt: Kein Feld hält den Stoffjahrgang der geprüften Kompetenz. `tasks.class_level` = 8 bei
allen Items (Herkunftsjahrgang, und bereits tragend in `lsa_start`).
**Korrektur zum Handover:** Es ist nicht nur ein Content-Projekt. Der strukturelle Ort existiert
bereits (`microskills.class_level` + `tasks.microskill_id`), ist aber unbefüllt (0/14 verknüpft)
und selbst falsch getaggt (alle 17 Themen auf Klasse 8). Das senkt den Aufwand auf der
Struktur-Seite und verschiebt ihn auf die Katalog-Seite: **Der Themen-Katalog muss um die
Fundament-Themen erweitert und mit korrekten Stoffjahrgängen versehen werden** — das sind
Größenordnung 25–30 Katalog-Einträge, nicht 299 Item-Entscheidungen.
**Korrektur 2:** Das Handover spricht von „~299 Items im Pool". In der Datenbank sind es **14**.

**B2 — Fundament-Items existieren nicht. BESTÄTIGT, härter als beschrieben.**
Es sind **null** Items unterhalb Klasse 8 — nicht „ungleichmäßig abgedeckt", sondern gar nicht.
Der gesamte Bestand (299 in der Content-Datei, 14 in der Datenbank) trägt `klasse: 8`. Auch der
Themen-Katalog (`microskills`) kennt nur Klasse-8-Themen. Bruchrechnung (6), Dezimalzahlen (6),
Prozent (7), negative Zahlen (7), Termumformung (7/8) — für den Fundament-Abstieg gibt es weder
Items noch Themen-Einträge.
Erforderlich: ~30–40 Skeleton-Eigenbauten, mehrere Items pro Thema in verschiedenen Kontexten,
QA-Gate vor Datenbankeintrag.

**B3 — RPC kennt weder Schulform noch Ceiling. BESTÄTIGT.**
Signatur und Ziel-Kontrakt: siehe 4.4. Zusätzlich fehlen die Item-Tags, auf die der Ziel-Kontrakt
filtern müsste (`school_form`, Niveau EESA/MSA/GYM).

**B4 — Zeitbudget vs. Breadth. BESTÄTIGT als Produktentscheidung. Siehe 5.3 und OFFEN-1.**

**B5 — NEU: Die LSA läuft heute gegen ein Schülerkonto, nicht gegen einen Lead.**
Nicht im Handover. `lsa_start(p_student_id …)` verlangt eine Zeile in `students`; `lsa_may_act_for`
prüft die Berechtigung gegen die Schüler-Beziehung. Für P2 heißt das: **Ein Interessentenkind
bräuchte heute bereits ein Schülerkonto, um die LSA zu bearbeiten.** Das kollidiert mit
Leitprinzip 5 (Trennung pre-contract) und mit A5.1 („wir löschen alles"). Das ist keine große
Änderung, aber eine, die *jetzt* entschieden werden muss — sie betrifft den Zuschnitt jeder
Tabelle in P0–P5.

**B6 — NEU: `est_duration_sec` ist bei allen 14 Items NULL.**
`lsa_start` zieht gegen ein Zeitbudget von ~1200 s. Ohne `est_duration_sec` fällt es auf
`estimated_minutes × 60` = 180 s zurück — und alle 14 Items tragen `estimated_minutes = 3`. **Die
LSA zieht heute also 7 Items und hält sie für 21 Minuten.** Ob 180 s realistisch sind, weiß
niemand; die Zahl ist ein Default, kein Messwert. Solange sie nicht gepflegt ist, ist **jede
Aussage über „wie viele Items passen in 20 Minuten" — auch die in OFFEN-1 — eine Schätzung ohne
Datenbasis.** ROADMAP führt das bereits als Aufgabe (Lena).

### 5.2 Der Zielkonflikt: Multi-Part in der LSA

**Die Lage.**
- **OFFEN-1** (Handover §10.1) empfiehlt — ausdrücklich unentschieden —, **Multi-Part-Items aus der
  LSA auszuschließen** (nur Lernpfad), weil sie mit Kostenfaktor 3–5× das 20-Minuten-Budget sprengen.
- **P02** (gerade in `dev` gemerged) hat das Gegenteil ermöglicht: `MULTI_PART` ist im
  `lsa_start`-Pool zugelassen, `lsa_responses` bekommt eine Zeile **pro Teilaufgabe**, `lsa_finish`
  aggregiert **pro Teilaufgabe nach Kompetenz**. Der Datenvertrag argumentiert explizit: ein
  Multi-Part-Item ist „diagnostisch *wertvoller* als ein flaches Item, nicht nur zusätzlich".
- **Beide Aussagen sind richtig.** Sie widersprechen sich trotzdem.

**Was auf dem Spiel steht — mit echten Zahlen:**

| | Items | Kompetenz-Datenpunkte |
|---|---|---|
| Single-Part `ready` (SHORT_INPUT 38 + MC 20) | 58 | 58 |
| Multi-Part `ready` | 86 | **196** (67× 2 Teile, 15× 3, 3× 4, 1× 5) |
| **Summe** | 144 | 254 |

Ein Ausschluss von Multi-Part aus der LSA kostet **196 der 254 verfügbaren Kompetenz-Datenpunkte —
77 %.** Der diagnostische Bestand schrumpft auf 58 Items. Das ist der Preis, und er ist höher, als
die Formulierung „Multi-Part-Items aus der LSA ausgeschlossen (nur Lernpfad)" vermuten lässt.

**Die gute Nachricht — und der Grund, warum das jetzt entschieden werden muss:**

**Die 86 Multi-Part-Items sind noch nicht importiert** (C07 steht offen), und **P02 ist noch nicht
deployt.** Der Zielkonflikt ist damit heute **kostenlos** auflösbar:

- Entscheidet die Gründerrunde **gegen** Multi-Part in der LSA, ist nichts zurückzurollen. Kein
  Datenbestand muss entwirrt werden. P02 bleibt als Vertrag für den **Lernpfad** bestehen (dort
  ist Multi-Part unstrittig sinnvoll), und C07 wird zum Lernpfad-Content-Projekt statt zum
  LSA-Content-Projekt. Der LSA-Pool bleibt bei 58 Single-Part-Items — **und B2 wird dadurch
  dringender, nicht weniger dringend.**
- Entscheidet sie **für** Multi-Part in der LSA, ist P02 bereits gebaut und getestet; es fehlt nur
  das Deployment und C07.
- Nach C07 und dem Deployment wird jede Umkehr teuer: Dann hängen Items, Responses und
  Report-Aggregationen daran.

**Reihenfolge-Konsequenz: OFFEN-1 muss vor dem P02-Deployment und vor C07 entschieden werden.**
Das ist die einzige Reihenfolge-Aussage in dieser Spec, die eine Deadline hat.

*(Diese Spec entscheidet OFFEN-1 nicht. Sie benennt, was die Entscheidung kostet und wann sie
fällig ist.)*

### 5.3 Reicht der Pool für das zweistufige Design (OFFEN-1, Option c)?

**Das skizzierte Design:** Phase 1 Screening mit 1 Item pro Thema (~10 Items), Phase 2 Drill-down
auf 3–4 auffällige Themen mit je 2–3 Items in verschiedenen Kontexten (~12 Items). Summe ~22
Single-Part-Items in 20 Minuten (Annahme: 45–60 s/Item).

**Überschlag gegen die echten Zahlen — nicht geschätzt:**

| Anforderung | Bestand | Urteil |
|---|---|---|
| ~22 Single-Part-Items, Mathe, Stufe 8 | **58** in der Content-Datei | ✅ **rechnerisch ausreichend** — für *einen* Test |
| dieselben, **in der Datenbank** | **14** (alle NUMERIC) | ❌ **reicht nicht.** Bei 180 s/Item zieht `lsa_start` heute **7 Items**. |
| „1 Item pro **Thema**" → braucht ~10 Themen | Items tragen **kein Thema** (`microskill_id` 0/14). Nur 4 grobe Inhaltsfelder. | ❌ **Die Achse existiert nicht.** Ein Screening über 4 Inhaltsfelder ist kein Screening über 10 Themen. |
| Drill-down „2–3 Items pro Thema in verschiedenen Kontexten" | Single-Part je Inhaltsfeld: Geometrie 23, Arithmetik/Algebra 18, Funktionen 13, **Stochastik 4** | 🟡 **knapp bis unmöglich.** Bei Stochastik gibt es 4 Single-Part-Items insgesamt — „verschiedene Kontexte" ist damit nicht darstellbar. |
| Fundament-Abstieg auf Klasse 6/7 | **0 Items** | ❌ **unmöglich** (B2) |
| Stufe 9 und Stufe 10 | **0 Items** | ❌ **unmöglich** |
| Deutsch, Englisch | **0 Items** | ❌ **unmöglich** |
| Zeitannahme 45–60 s/Item | Alle Items: 180 s (Default, ungemessen) | ⚠️ **unbelegt** (B6). Bei 180 s passen 7 Items in 20 min, nicht 22. |

**Antwort auf die Frage „Reicht der Pool?": Für Mathe Stufe 8 Gymnasium, ohne Fundament-Abstieg,
mit grober Inhaltsfeld-Granularität statt Themen — knapp ja (58 Items), aber nur in der
Content-Datei, nicht in der Datenbank. Für alles, was die LSA laut Zielbild leisten soll —
Fundament-Abstieg, Themen-Granularität, drei Stufen, drei Fächer — nein, und zwar nicht knapp.**

Und die Zeitrechnung in OFFEN-1 („~45–60 s/Item → 20–25 Items in 20 min") steht auf keiner
Datenbasis: Solange `est_duration_sec` nicht gemessen ist, ist der Faktor zwischen der Annahme
(45–60 s) und dem im System hinterlegten Default (180 s) ein Faktor 3–4. **Das ist derselbe
Kostenfaktor, den B4 den Multi-Part-Items vorwirft** — er könnte bereits in den flachen Items
stecken. **Empfehlung zur Entscheidungsvorbereitung (keine Produktentscheidung): B6 vor OFFEN-1
klären.** Eine Handvoll gemessener Bearbeitungszeiten macht aus OFFEN-1 eine Rechnung statt einer
Schätzung.

### 5.4 Umsetzungsreihenfolge — was blockiert was

```
                    ┌─────────────────────────────────────────┐
   ENTSCHEIDUNGEN   │ OFFEN-1: Multi-Part in der LSA?         │ ◄── FÄLLIG ZUERST
   (Gründerrunde)   │ (fällig VOR P02-Deploy und VOR C07)     │
                    └───────────────────┬─────────────────────┘
                                        │
                    ┌───────────────────▼─────────────────────┐
   MESSUNG          │ B6: est_duration_sec pflegen/messen     │ ◄── billig, entscheidungsrelevant
                    │ (macht OFFEN-1 rechenbar)               │
                    └───────────────────┬─────────────────────┘
                                        │
   ┌────────────────────────────────────▼─────────────────────┐
   │ B1  STOFFANKER                                            │
   │  1. Struktur: Anker an microskills.class_level ODER       │
   │     tasks.grade_level (Architekturentscheidung)           │
   │  2. Katalog: Themen um Fundament erweitern +              │
   │     korrekte Stoffjahrgänge (~25–30 Einträge)             │
   │  3. Items an Themen hängen (microskill_id befüllen)       │
   └───────┬───────────────────────────────────┬───────────────┘
           │                                   │
   ┌───────▼─────────────────┐     ┌───────────▼───────────────┐
   │ B2  FUNDAMENT-ITEMS     │     │ B3  RPC-KONTRAKT          │
   │  ~30–40 Skeletons für   │     │  lsa_start + Schulform    │
   │  Klasse 6/7, QA-Gate    │     │  + Ceiling; Item-Tags     │
   │  (B1 sagt, WO die       │     │  school_form / Niveau;    │
   │   Lücken sind)          │     │  Absteige-Achse wechseln  │
   └───────┬─────────────────┘     └───────────┬───────────────┘
           │                                   │
           └─────────────┬─────────────────────┘
                         │
              ┌──────────▼──────────────┐
              │  LSA GO-LIVE-FÄHIG      │
              │  (Fundament-Abstieg,    │
              │   Root-Cause-Report)    │
              └─────────────────────────┘

   PARALLEL, unabhängig von B1–B3 (blockiert nichts, wird von nichts blockiert):
   ├── B5  LSA gegen Lead statt gegen Schülerkonto (Zuschnitt-Entscheidung, jetzt)
   ├── P1  intake_session neu schneiden (Buch, Ceiling, course_level, Noten)
   ├── P1  hypotheses (parent|child getrennt)  ─── fehlt vollständig
   ├── P1  consents mit Timestamp              ─── RECHTLICHE VORAUSSETZUNG der LSA
   └── P3  LSA-Report-Objekt
```

**Die harten Abhängigkeiten in Worten:**

1. **OFFEN-1 blockiert P02-Deployment und C07.** Nicht technisch, sondern wirtschaftlich: Nach dem
   Import der 86 Items ist die Entscheidung teuer. Davor ist sie gratis.
2. **B1 blockiert B2.** Man kann die Fundament-Lücken nicht präzise benennen, bevor der Bestand
   nach Stoffjahrgang getaggt ist. Ein Skeleton-Auftrag ohne Audit produziert Items, die man
   vielleicht schon hat — oder nicht die, die fehlen.
3. **B1 blockiert B3.** Ein `ceiling`-Parameter ohne Stoffanker filtert auf eine Spalte, in der
   überall 8 steht. Die Signaturerweiterung wäre ein No-op.
4. **B1 + B2 blockieren das Kernversprechen.** Ohne beide gibt es keinen Fundament-Abstieg, keinen
   Root-Cause-Befund und damit **keinen Reframe im Ergebnisgespräch (P4) — also kein Produkt.**
5. **`consents` blockiert P2 rechtlich.** Ohne dokumentierte Einwilligung mit Timestamp darf die
   LSA nicht laufen (A1.1). Das ist die billigste Voraussetzung auf dieser Liste und die einzige,
   deren Fehlen ein rechtliches Risiko ist.
6. **Nicht blockierend, aber Launch-relevant:** Deutsch und Englisch haben **null** Items. Das
   Zielbild verspricht drei Fächer. Der Prozess Erstgespräch ist für Mathematik beschreibbar und
   für Deutsch/Englisch heute nicht durchführbar.

---

## 6. Offene Punkte

Unverändert aus Handover Abschnitt 10. Diese Spec löst sie **nicht** auf.

### OFFEN-1 — Zeitbudget vs. Breadth (B4, Produktentscheidung Gründerrunde)

20 Minuten LSA, Breadth-Prinzip (mehrere Items pro Thema in verschiedenen Kontexten) und
Fundament-Abstieg über zwei Jahrgänge gehen mit Multi-Part-Items (Kostenfaktor 3–5×) rechnerisch
nicht auf.

**Optionen:**
- (a) LSA auf 25–30 min verlängern
- (b) Diagnose flacher
- (c) zweistufig-adaptives Design

**Empfehlung aus dem Handover (nicht entschieden):** Option (c) — Phase 1 Screening mit 1 Item pro
Thema in kurzen Single-Part-Formaten, Phase 2 Drill-down nur auf auffällige Themen mit 2–3 Items in
verschiedenen Kontexten; **Multi-Part-Items aus der LSA ausgeschlossen (nur Lernpfad)**. Überschlag:
~45–60 s/Item → 20–25 Items in 20 min → ~10 Screening + ~12 Drill-down auf 3–4 Themen. Breadth
entsteht damit genau dort, wo der Befund behauptet wird. Falls die Pilotphase zeigt, dass es nicht
reicht: **verlängern statt verflachen.**

> **Ergänzung dieser Spec (keine Auflösung):** Die Entscheidung ist **vor** dem P02-Deployment und
> **vor** C07 fällig (5.2). Der Ausschluss von Multi-Part kostet 196 von 254 Kompetenz-Datenpunkten
> (77 %). Der Pool-Überschlag steht in 5.3; die Zeitannahme von 45–60 s/Item ist unbelegt (B6).

### OFFEN-2 — Aufsicht des Kindes während der LSA

Wer beaufsichtigt das Kind während der 20-minütigen LSA, wenn der Coach beim Elterngespräch sitzt?
Kiosk-Modus ist als harte Tablet-Anforderung gesetzt — die Aufsichtsfrage ist damit nicht
beantwortet.

### OFFEN-3 — Vertragslaufzeit

6 oder 12 Monate. Entscheidung ausstehend.

### OFFEN-4 — Rechtsfragen (extern zu klären)

- Zulässiger Datenumfang vor Vertragsschluss.
- Reicht die Einwilligung **eines** Elternteils für die Kind-Diagnostik?
- Umgang mit spontan mitgeteilten Gesundheitsinformationen (heute bewusst nirgends erfasst).

> **Hinweis dieser Spec (keine Auflösung):** Unabhängig vom Ausgang fehlt das `consents`-Objekt
> heute vollständig (4.1). Die Rechtsfrage betrifft den *Inhalt* der Einwilligung; das *Fehlen der
> Erfassung* ist davon unabhängig und in 5.4 als Voraussetzung geführt.

### OFFEN-5 — Realtime vs. Batch bei den LSA-Verlaufs-KPIs

Entschieden ist: Der Coach sieht während der LSA **nur** einen Fortschrittsindikator. Offen ist die
Granularität der späteren Report-KPIs und ob sie in Echtzeit oder als Batch entstehen.

---

## Anhang: Verifikationsbasis

Alle Zahlen dieser Spec stammen aus einer Live-Abfrage der Supabase-Instanz
(`aws-1-eu-central-1.pooler.supabase.com`) und der Content-Datei, beides am 2026-07-13.

**Datenbank:**
- Angewendete Migrationen: `baseline`, `api_role_grants`, `p01_datenvertrag`. **`p02_multipart`
  fehlt.**
- `tasks`: 14 Zeilen — alle `status='ready'`, `source='VERA8_IQB'`, `input_type='NUMERIC'`,
  `class_level=8`, `estimated_minutes=3`, `est_duration_sec=NULL`.
- `competency_content` der 14: `arithmetik_algebra` 7, `funktionen` 5, `geometrie` 1,
  `stochastik` 1. `afb`: 13× I, 1× III.
- `tasks.microskill_id`: 0 von 14 gesetzt. `tasks.cluster_id`: 14 von 14.
- `microskills`: 17 Zeilen, **alle `class_level=8`**, Codes `M8.*`.
- `skill_clusters`: 5. `process_competencies`: 6. `subjects`: Mathematik, Deutsch, Englisch.
- `task_solutions`: 14. `lsa_sessions`: 1. `lsa_responses`: 7. `leads`: 0. `intake_sessions`: 0.
- Keine Spalten `parts`, `part_nr`, `grade_level`, `school_form`, `course_level`, `ceiling`
  irgendwo im Schema.
- `lsa_start(p_student_id uuid, p_grade integer, p_subject text) → jsonb`.

**Content-Datei `data/vera8_komplett_enriched.json`:**
- 299 Items, **alle `klasse: 8`**.
- Status: `ready` 144, `partial` 74, `doc_pending` 74, `quarantined` 4, `interaktiv_extern` 2,
  `keine_quelle` 1.
- `ready` × Typ: `MULTI_PART` 86, `SHORT_INPUT` 38, `MULTIPLE_CHOICE` 20.
- Multi-Part-Teilaufgaben: 67× 2, 15× 3, 3× 4, 1× 5 → **196 Datenpunkte**.
- Single-Part `ready` × Inhaltsfeld: Geometrie 23, Arithmetik/Algebra 18, Funktionen 13,
  Stochastik 4.
- Tag-Struktur (`edvance_matrix`): `inhaltsfelder`, `prozesskompetenzen`, `afb_max`,
  `schwierigkeit`. **Kein Feld für den Stoffjahrgang.**
