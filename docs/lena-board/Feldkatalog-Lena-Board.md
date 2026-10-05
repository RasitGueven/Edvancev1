# Feldkatalog — Lena-Board

**Für:** Rasit, Tolunay, Ashkan · **Datum:** 04.10.2026 · **Ergänzt:** `Bewertung-Lena-Board.md`
**Grundlage:** Edvancev1, Branch `dev` (Stand `93fb3d6`). Die Beispielaufgaben stammen aus den Chargen `k9-kreis`, `k8-lgs` und `k8-flaeche` (Quelle `docs/prefill/*.json`, eingespielt per Migration). Prod-Werte sind nicht abgefragt.

Inhalt:

1. Greift die LSA nach Thema?
2. Drei Beispielaufgaben, ein Format je Aufgabe, mit allen Feldern
3. Jedes Feld erklärt: wozu, warum ein Mensch prüft, wer es nutzt
4. Richtige Antwort: `correct_answers` und `acceptance`
5. Was der Report heute nutzt und was er nutzen könnte
6. Empfehlung für Lenas Prüfkarte

---

## 1 · Greift die LSA nach Thema?

**Ja, aber über die Sitzung, nicht über die Aufgabe.** So läuft die Auswahl heute (`lsa_select_next_core`):

| Schritt | Woher | Beispiel Kreis |
|---|---|---|
| 1. Thema der Sitzung | Erstgespräch: `lead_themen` mit Status „aktuell“ → `lsa_sessions.thema_key` | Kreis: Umfang und Fläche |
| 2. Einstieg | Einstiegsfertigkeiten des Themas (`thema_einstieg`) | Umfang des Kreises, Fläche des Kreises |
| 3. Aufgabe | eine freigegebene Aufgabe dieser Fertigkeit (`skill_key`), die mit dem besten Sondierrang zuerst | „Umfang · Radius 3,6 m“ |
| 4. Tiefe (bis Minute 12) | Bei einer Lücke geht es zu den Voraussetzungen (`skill_kante`) | Werte in Terme einsetzen, Umfang von Rechteck und Dreieck, Runden und Überschlag |
| 5. Breite (Restzeit) | Einstiege früher behandelter Themen (`lead_themen` „behandelt“, Schulplan der Schule) | z. B. Lineare Gleichungssysteme |

**Warum die Aufgabe an der Fertigkeit hängt und nicht am Thema**

- Eine Fertigkeit dient mehreren Themen als Voraussetzung. „Werte in Terme einsetzen“ steht unter Kreis, unter Lineare Gleichungssysteme und unter Flächenterme.
- Hinge eine Aufgabe fest an einem Thema, könnte die LSA sie beim Abstieg aus einem anderen Thema nicht ziehen.
- Der Beleg wird je Fertigkeit gebucht (`lsa_skill_urteil`), und der Report spricht in Fertigkeiten („Umfang des Kreises noch nicht sicher“).
- Das Thema beantwortet „Wo fangen wir an?“. Die Fertigkeit beantwortet „Was genau kann das Kind?“.

**Folge für Lena**

- Ihre wichtigste Prüfung ist: **Prüft diese Aufgabe wirklich diese Fertigkeit, und zwar vor allem diese?**
- Eine Aufgabe zum Kreisumfang, an der Kinder vor allem am Runden scheitern, bucht im Report „Umfang des Kreises: noch nicht sicher“, obwohl die Lücke beim Runden liegt.
- Thema und Klasse zeigt die Prüfkarte als Kontext. Sie folgen aus der Fertigkeit (genau ein Heimat-Thema je Fertigkeit, `skill_thema`).

**Was das Thema zusätzlich leisten könnte:** Der Report nutzt das Heimat-Thema der Fertigkeiten bisher nicht (siehe Abschnitt 5). Darin steckt die Aussage, die ihr für die Eltern wollt: „kann X sicher, Y darauf aufbauend noch nicht“.

---

## 2 · Drei Beispielaufgaben

### A · Zahl, einteilig — „Umfang · Radius 3,6 m“

| Was | Feld | Wert |
|---|---|---|
| **Das sieht das Kind** | | |
| Aufgabentext | `tasks.question` | „Ein Kreis hat den Radius 3,6 m. Wie groß ist sein Umfang in Metern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.“ |
| Antwortformat | `input_type` | `NUMERIC`, also „Das Kind tippt eine Zahl ein.“ |
| Einheit am Antwortfeld | `unit` | m |
| Bild | `needs_image`, `assets`, `task_figures` | kein Bild nötig |
| **Wertung** | | |
| Richtige Antwort | `acceptance.canonical` + `equivalents`, gleich `correct_answers` | 22,62 (π-Taste) und 22,61 (π ≈ 3,14). Mit Komma/Punkt, mit und ohne „m“: 8 Schreibweisen |
| Wertungsregeln | `acceptance.tolerance` usw. | keine: Zahlen werden mathematisch verglichen, die Einheit ist egal |
| Typische Fehler | `acceptance.known_errors` | 11,31 / 11,30 / 11,3 → Radius und Durchmesser verwechselt · 7,2 / 7,20 → π vergessen · 40,72 / 40,69 → Fläche statt Umfang (28 Schreibweisen) |
| Denkfehler zur Aufgabe | `task_solutions.typical_errors` | „π weggelassen: 2 · 3,6 = 7,2.“, Rückfrage: „Welcher Faktor fehlt in deiner Rechnung?“ (drei Einträge) |
| Lösungsweg | `task_solutions.solution` | „U = 2 · π · 3,6 m ≈ 22,62 m (π-Taste). Mit π ≈ 3,14: … ≈ 22,61 m.“ |
| **Einordnung** | | |
| Fertigkeit | `skill_key` | Umfang des Kreises (`geo_kreis_umfang`) |
| Thema · Klasse | aus `skill_thema` → `themen` | Kreis: Umfang und Fläche · 9/10 · Einstieg des Themas |
| Voraussetzungen | `skill_kante` | Werte in Terme einsetzen · Umfang von Rechteck und Dreieck · Runden und Überschlag |
| Anforderungsbereich | `afb` | II (Vorbefüllung: Sicherheit „mittel“) |
| Zeit | `est_duration_sec` | 60 s (Sicherheit „mittel“) |
| Stoffanker | `curriculum_grade` | 9 |
| Leitidee · Prozess · Cluster | `competency_content` · `competency_process` · `cluster_id` | Geometrie · Operieren · Geometrie & Messen |
| Sondierrang | `sondierrang` | 1: wird in dieser Fertigkeit zuerst gezogen, weil sie drei Fehlbilder unterscheidet |
| **Herkunft** | | |
| Vorbefüllung | `vorbefuellt` | je Feld Art „neu“, Grund, Charge `k9-kreis` |

### B · Mehrteilig — „Einsetzungsverfahren · y steht frei · Klammer“

| Was | Feld | Wert |
|---|---|---|
| Aufgabentext | `question` | „Löse das Gleichungssystem mit dem Einsetzungsverfahren. I: y = x + 1 · II: 3x + 2y = 17“ |
| Antwortformat | `input_type`, `parts[]` | `MULTI_PART`: Teil 1 „x =“ und Teil 2 „y =“ als Eingabefelder. „Das Kind beantwortet zwei Teilfragen.“ |
| Richtige Antwort | `correct_answers` `{"1":[…],"2":[…]}`, dazu je Teil `acceptance` | Teil 1: 3 / +3 · Teil 2: 4 / +4 |
| Wertung | — | **nur Textvergleich je Teil**. Ist ein Teil falsch, zählt die ganze Aufgabe als „nicht“ |
| Typische Fehler | `acceptance."1".known_errors`, `acceptance."2".known_errors` | Teil 1: 3,2 → Klammer vergessen · 15 → Division vergessen. Teil 2: 4,2 → Klammer vergessen · 16 → Division vergessen |
| Denkfehler zur Aufgabe | `typical_errors` | „Ohne Klammer eingesetzt: 3x + 2x + 1 = 17, also 5x = 16 und x = 3,2.“ |
| Fertigkeit · Thema | `skill_key` → `skill_thema` | Einsetzungsverfahren · Lineare Gleichungssysteme · 7/8 |
| Voraussetzungen | `skill_kante` | Minusklammer auflösen · Zweischrittige Gleichungen · Werte in Terme einsetzen |
| AFB | `afb`, dazu `parts[].afb` | I (Aufgabe und beide Teile) |
| Zeit | `est_duration_sec` | 45 s (Teil 1: 30 s, Teil 2: 15 s) |

Teil 2 enthält die Folgewerte aus Teil 1: 4,2 = 3,2 + 1 und 16 = 15 + 1. Ein Fehler in a) erzeugt deshalb zwei Fehlbild-Treffer in derselben Aufgabe. Der Report verlangt mindestens zwei verschiedene Aufgaben, dadurch wird nichts doppelt gezählt. Das Urteil bleibt aber „nicht“, obwohl b) folgerichtig ist.

### C · Multiple Choice — „Term · Rechteck x mal 5“

| Was | Feld | Wert |
|---|---|---|
| Aufgabentext | `question` | „Ein Rechteck ist x cm lang und 5 cm breit. Welcher Term beschreibt seinen Flächeninhalt in cm²?“ |
| Optionen | `question_payload.options` | a) x + 5 · b) 5x · c) 2x + 10 · d) x² |
| Richtige Antwort | `correct_answers` = `["b"]`, `acceptance.canonical` = „b“ | b) 5x |
| Typische Fehler | `acceptance.known_errors` | a) → Es wurde addiert, wo malgenommen werden muss · c) → Statt der Fläche wurde der Umfang berechnet · **d) hat kein Fehlbild** |
| Wertung | — | richtig oder falsch. Ein richtiges MC zählt nie sofort als Beleg; die LSA verlangt eine zweite Probe, weil Raten möglich ist. |
| Fertigkeit · Thema | | Terme für Flächeninhalte · Flächen von Dreiecken und Vierecken · 7/8 |

An diesem Beispiel sieht man, was Lena bei MC bringt. Option d) ist ein Ablenker ohne Diagnose. Wählt ein Kind d), lernt das System nichts. Lena kann entscheiden, ob d) einen typischen Denkfehler abbildet (Rechteck mit Quadrat verwechselt) oder ersetzt werden sollte. Ersetzen ist Admin-Sache.

---

## 3 · Jedes Feld erklärt

Je Feld steht: wozu es dient, warum ein Mensch prüft (oder warum das System allein reicht) und wer es heute liest. Die Empfehlung für die Prüfkarte steht in Abschnitt 6.

### Was das Kind sieht

**Aufgabentext** (`question`)
- **Wozu:** Das ist die Aufgabe.
- **Warum ein Mensch prüft:** Die Maschine prüft Zahlen und Lösbarkeit. Ob ein Kind der Klasse 9 „Runde auf zwei Stellen nach dem Komma“ versteht oder ob ein Satz mehrdeutig ist, sieht nur ein Mensch.
- **Nutzung:** Die LSA zeigt den Text an, der Report nutzt ihn nicht.
- **Änderbar:** Lena ändert ihn laut Anforderung nicht. Fehler laufen über „Passt nicht“. Die Zahlen im Text sind zusätzlich technisch gesperrt, damit die maschinelle Gegenprobe gültig bleibt.

**Antwortformat** (`input_type`, bei MC `options`, bei mehrteiligen Aufgaben `parts`)
- **Wozu:** Wie das Kind antwortet.
- **Warum ein Mensch prüft:** Ist die Aufgabe am Tablet so beantwortbar? Fragt der Text nach einer Begründung, das Feld nimmt aber nur eine Zahl?
- **Änderbar:** Lena ändert es nicht, Umbau ist Admin-Sache.

**Einheit am Antwortfeld** (`unit`)
- **Wozu:** Steht hinter dem Eingabefeld („m“).
- **Warum ein Mensch prüft:** Die Einheit entscheidet, was Kinder eintippen. Steht „m“ am Feld, tippt kaum ein Kind „22,62 m“. Fehlt sie, braucht die Liste die Schreibweisen mit Einheit.
- **Nutzung:** Die LSA liefert sie an die App.
- **Lücke:** Fehlt heute im Dummy.

**Bild** (`needs_image`, `assets`, `task_figures`)
- **Wozu:** Abbildung, falls nötig.
- **Warum ein Mensch prüft:** Ob der Text ohne Bild reicht und ob das Bild stimmt (Skala, Beschriftung), kann die Maschine nicht beurteilen.
- **Nutzung:** Die LSA liefert das Bild. Fehlt es trotz `needs_image`, sollte die Aufgabe gar nicht erst zu Lena kommen.

### Wertung

**Richtige Antwort** (`correct_answers` und `acceptance.canonical` + `equivalents`)
- **Wozu:** Was als richtig zählt.
- **Warum ein Mensch prüft:** Die Werte sind maschinell nachgerechnet und blind gegengeprüft. Offen bleibt die didaktische Frage: Zählt 22,6, obwohl zwei Stellen verlangt sind? Zählt die π ≈ 3,14-Variante? Das ist eine Bewertungsentscheidung, keine Rechenfrage.
- **Nutzung:** Antwortzeile, Urteil und Gate. Die beiden Felder erklärt Abschnitt 4.

**Wertungsregeln** (`acceptance.tolerance`, `notation`, `unit_graded`, `require_reduced`)
- **Wozu:**
  - Toleranz, zum Beispiel ±5 beim Ablesen;
  - Einheit Pflicht oder egal;
  - Bruch muss gekürzt sein.
- **Warum ein Mensch prüft:** Wie streng gewertet wird, ist eine pädagogische Entscheidung.
- **Nutzung:** nur bei einteiligen Aufgaben. In den Chargen ist keine Regel gesetzt.
- **Report-Option:** Ist „Einheit Pflicht“ gesetzt und fehlt sie, gibt es „teilweise“: „rechnet richtig, vergisst die Einheit“. Diese Aussage ist für Eltern greifbar (siehe Abschnitt 5).

**Typische Fehler** (`acceptance.known_errors`)
- **Wozu:** falscher Wert → Fehlbild.
- **Warum ein Mensch prüft:** Die Maschine hat die falschen Werte aus angenommenen Denkfehlern berechnet. Ob Kinder diesen Fehler wirklich machen und ob der Wert eindeutig zu diesem Denkfehler gehört, weiß jemand aus der Nachhilfe besser.
- **Nutzung:** Fehlbild-Erfassung in der LSA, Abschnitt „Muster“ im Report (über die Fehlbild-Familie, ab 2 Treffern in 2 Aufgaben) und Berechnung des Sondierrangs.

**Denkfehler zur Aufgabe** (`task_solutions.typical_errors`)
- **Wozu:** Freitext je Aufgabe mit sokratischer Rückfrage, in den Chargen aus `known_errors` abgeleitet.
- **Warum ein Mensch prüft:** Ob der Satz stimmt und kindgerecht ist.
- **Nutzung:** In LSA und Report **nicht genutzt**.
- **Report- und Session-Option:** Sie konkretisieren den Befund an der Antwort des Kindes (Abschnitt 5) und dienen in Sessions als Coach-Hinweis. Dafür fehlt die Verbindung zum Fehlbild: Der Eintrag nennt keinen Slug.

**Fehlbild-Text** (`fehlbild_labels.klartext`, `familie` → `fehlbild_familien.elterntext`)
- **Wozu:** der allgemeine Text je Fehlbild.
- **Warum ein Mensch prüft:** Eltern lesen ihn.
- **Änderbar:** einmal je Fehlbild, nicht je Aufgabe, also nicht auf der Prüfkarte.
- **Achtung:** Ein Fehlbild ohne freigegebene Familie fällt still aus dem Report. Für `pi_vergessen` steht in den Migrationen keine Familie. Bitte per `dbread` prüfen, welche Slugs in Prod ohne Familie sind.

**Lösungsweg** (`solution`)
- **Wozu:** Musterlösung für uns.
- **Warum ein Mensch prüft:** Er macht Lenas Prüfung schneller: Sie liest den Weg statt selbst zu rechnen.
- **Nutzung:** In LSA und Report nicht genutzt.
- **Option:** Anzeige für den Coach in Sessions.

### Einordnung

**Fertigkeit** (`skill_key`)
- **Wozu:** Wofür die Aufgabe ein Beleg ist.
- **Warum ein Mensch prüft:** Das ist die folgenreichste Prüfung (siehe Abschnitt 1). Die Zuordnung ist heuristisch: Die Charge baut Aufgaben zu einer Fertigkeit, aber ob eine Sachaufgabe vor allem die Fertigkeit oder das Textverständnis prüft, entscheidet ein Mensch.
- **Nutzung:** Auswahl, Urteil und Report (Fertigkeitsname in „Wie gesucht“, „Gefunden“, „Genauer ansehen“).
- **Änderbar:** Heute nur für Admins.

**Thema · Klasse** (abgeleitet über `skill_thema` → `themen`)
- **Wozu:** Kontext und Gruppierung im Board.
- **Warum ein Mensch prüft:** Es braucht keine eigene Prüfung, beides folgt aus der Fertigkeit.

**Anforderungsbereich** (`afb`)
- **Wozu:** Art der Denkleistung.
- **Warum ein Mensch prüft:** AFB ist eine Einschätzung (Vorbefüllung „mittel“ sicher) und genau Lenas Fach.
- **Nutzung:** Gate und eine AFB-Aufstellung in `lsa_finish`, die niemand liest.
- **Report-Option:** siehe Abschnitt 5, mit Vorsicht.

**Zeit fürs Kind** (`est_duration_sec`)
- **Wozu:** geschätzte Bearbeitungszeit.
- **Warum ein Mensch prüft:** Es braucht keinen Menschen. Die LSA misst die echte Dauer je Antwort (`lsa_responses.duration_ms`). Nach einigen LSAs kann das System die Schätzung selbst nachziehen.
- **Nutzung:** nur im alten Modus „fest“, in der adaptiven LSA nicht. Bei mehrteiligen Aufgaben ist das Feld Pflicht.

**Stoffanker** (`curriculum_grade`)
- **Wozu:** Jahrgang, in dem der Stoff drankommt.
- **Warum ein Mensch prüft:** Es braucht keinen Menschen, es folgt aus der Fertigkeit (`skills.klasse_herkunft`).
- **Nutzung:** nur im Gate.

**Leitidee, Prozess, Cluster** (`competency_content`, `competency_process`, `cluster_id`)
- **Wozu:** alte Ordnungsmerkmale.
- **Warum ein Mensch prüft:** Es braucht keinen Menschen für die LSA.
- **Nutzung:**
  - `cluster_id` verlangt das Gate;
  - `competency_content` steht in einer `lsa_finish`-Aufstellung, die niemand liest;
  - `competency_process` liest gar nichts.
- **Report-Option:** Die Prozesskompetenz (Operieren gegenüber Modellieren bei Sachaufgaben) wäre auswertbar (Abschnitt 5).

**Sondierrang** (`sondierrang`)
- **Wozu:** welche Aufgabe einer Fertigkeit zuerst gezogen wird, nämlich die, die die meisten Fehlbilder unterscheidet.
- **Warum ein Mensch prüft:** Es braucht keinen Menschen, das System rechnet ihn aus `known_errors`.
- **Hinweis:** Entfernt Lena typische Fehler, kann der Rang veralten. Er sollte nach der Prüfung neu berechnet werden.

**Vorbefüllung** (`vorbefuellt`)
- **Wozu:** Herkunft je Feld (Art, Grund, Charge).
- **Lücke:** Die Quelle jeder Charge hat je Feld eine **Sicherheit** (hoch, mittel, niedrig), etwa AFB „mittel“ und Lösung „hoch“. Die Sicherheit landet nicht in der Datenbank. Mit ihr ließe sich Lenas Aufmerksamkeit steuern: Felder mit „mittel“ markieren, Felder mit „hoch“ einklappen.

---

## 4 · Richtige Antwort: `correct_answers` und `acceptance`

Beide Felder sagen, was richtig ist, aber auf zwei Arten:

| | `correct_answers` (Lösungsliste) | `acceptance` (Wertungsregel) |
|---|---|---|
| Was drin steht | alle Eingaben, die als richtig zählen | eine Musterantwort (`canonical`), gleichwertige Schreibweisen (`equivalents`), Regeln (Toleranz, Einheit, gekürzt) und die typischen Fehler (`known_errors`) |
| Wie verglichen wird | als Text: Kleinschreibung, Komma = Punkt, Leerzeichen zusammengefasst | als Zahl: 22,620 = 22,62 = 2262/100, Einheit getrennt betrachtet |
| Wofür die LSA es nutzt | Antwortzeile richtig/falsch (nur bei „falsch“ wird ein Fehlbild gesucht) · Gate „Lösung vorhanden“ · **einzige** Wertung bei Teilaufgaben, MC und Termen | **Urteil über die Fertigkeit** bei einteiligen Aufgaben (voll / teilweise / nicht) · Fehlbild-Erkennung bei allen Formaten |
| Seit wann | von Anfang an | später ergänzt, für Teilwertung und Fehlbilder |

In den Chargen steht in beiden dieselbe Liste. Auseinander laufen sie, wenn nur eines geändert wird. Genau das tut der Editor heute: Er schreibt `correct_answers`, aber nicht `acceptance`.

**Beispiel Kreis:** Ein Kind tippt „22,620“.

- `correct_answers`: „22,620“ steht nicht in der Liste, also ist die Antwortzeile **falsch**.
- `acceptance`: 22,620 ist mathematisch gleich 22,62, also lautet das Urteil **voll**.

Beides gleichzeitig ist verwirrend, schadet hier aber nicht, weil das Urteil zählt. Gefährlich wird es, wenn jemand die Lösung korrigiert und nur eine der beiden Listen ändert.

**Empfehlung:**

- Lena sieht **eine** Liste „Richtige Antwort“, das System schreibt beide.
- Mittelfristig `correct_answers` aus `acceptance` ableiten, damit es nur noch eine Quelle gibt.
- Die Wertung bei Teilaufgaben auf `acceptance` umstellen, dann gilt der Zahlvergleich auch dort.

---

## 5 · Was der Report heute nutzt und was er nutzen könnte

**Heute** nutzt der Report von den Aufgabenfeldern nur zwei direkt:

- die **Fertigkeit**, mit Namen, Tiefe und Herkunftsklasse;
- die **typischen Fehler**, über Fehlbild → Familie → Elterntext.

Dazu kommt das **Thema der Sitzung**. Alles andere, was Lena prüft, landet heute in keinem Report.

**Optionen**, sortiert nach Nutzen für Eltern und Aufwand:

| # | Option | Daten | Aufwand | Einschätzung |
|---|---|---|---|---|
| 1 | **Fehlbilder ohne Familie sichtbar machen** | `fehlbild_labels.familie` | klein, Datenpflege | Sofort prüfen. Sonst verschwinden Befunde wie „π vergessen“ still. |
| 2 | **„X sicher, Y darauf aufbauend noch nicht“** | Urteile + `skill_kante` + `skills.label` + Heimat-Thema (`skill_thema`) | mittel, Report-Logik | Genau eure Vorgabe für den Eltern-Report. Die Daten liegen vor. Heute gruppiert der Report nach dem Präfix des `skill_key`, nicht nach Lehrplan-Themen. Mit dem Heimat-Thema passen Board, Erstgespräch und Report zusammen. |
| 3 | **Beleg an der Antwort des Kindes** | `known_errors` + Denkfehler zur Aufgabe + Kurztitel | mittel. Die Denkfehler brauchen ein Fehlbild-Feld, damit klar ist, welcher Satz zu welchem Wert gehört. | Stärkster Hebel für Glaubwürdigkeit: „Beim Kreis mit Radius 3,6 m kam 11,31 heraus, also π · 3,6. Der Radius wurde wie ein Durchmesser behandelt.“ Eher für das Elterngespräch und den Coach als für das PDF. |
| 4 | **„Teilweise“ auswerten** | `unit_graded`, `require_reduced` + Urteil | mittel. Heute behandelt die LSA „teilweise“ wie „nicht“. | „Rechnet richtig, vergisst aber Einheiten“ verstehen Eltern sofort. Voraussetzung: Die Regel ist je Aufgabe gesetzt, also Pflege durch Lena. |
| 5 | **Rechnen gegenüber Sachaufgabe** | `competency_process` oder ein Merkmal „Sachkontext“ (die Chargen haben je Fertigkeit vier reine und zwei Sachaufgaben) | mittel | Gute Elternaussage („Rechnen sitzt, Übertragen auf Sachsituationen noch nicht“). Je Fertigkeit gibt es aber höchstens zwei Proben, die Aussage geht deshalb nur über alle Fertigkeiten, mit Schwelle wie bei den Fehlbildern. |
| 6 | **Anforderungsbereich** | `afb` | klein. Die Aufstellung entsteht in `lsa_finish` schon. | Für Eltern schwach und leicht missverständlich. Eher Coach-Information. |
| 7 | **Zeit** | `duration_ms` gegen `est_duration_sec` | klein | Im Elternreport bewusst gestrichen (R6). Intern sinnvoll: die Zeitschätzung je Aufgabe aus echten Daten nachziehen. Dann muss Lena keine Zeit schätzen. |
| 8 | **„Weiß nicht“ einheitlich darstellen** | `abgabeart` | klein | Nebenbefund: Abschnitt 02/03 zählt „nicht angesetzt“ als Lücke, der Aufklappbereich nicht. Das sollte einheitlich sein. |

**Weitere Nebenbefunde aus der Prüfung:**

- Die Coach-Funktion mit Klartext je Fertigkeit (`lsa_fehlbild_report`) ruft im Frontend niemand auf.
- Die Aufstellungen in `result_summary` (AFB, Kompetenzen, Dauer) liest niemand.

---

## 6 · Empfehlung für Lenas Prüfkarte

| Bereich | Feld | Lena |
|---|---|---|
| Kinderansicht | Text, Antwortformat, Einheit, Bild | prüft, ändert nicht. Fehler laufen über „Passt nicht“ mit Grund. |
| Richtige Antwort | eine Liste; das System schreibt `correct_answers` und `acceptance` | prüft und ändert |
| Wertungsregel | Toleranz bzw. Bereich, Einheit Pflicht ja/nein (nur einteilig) | prüft und ändert, wo sinnvoll. Die Einheit ist die Voraussetzung für „teilweise“ im Report. |
| Typische Fehler | Zeilen je Fehlbild: Werte zusammengefasst, Fehlbild-Text und Denkfehler zur Aufgabe | prüft, entfernt, ergänzt nur mit bestehendem Fehlbild |
| Fertigkeit | Name, dazu Thema · Klasse · Voraussetzungen als Kontext | prüft, ändert über die Auswahl einer Fertigkeit (Admin bestätigt) |
| Anforderungsbereich | I / II / III | prüft und ändert |
| Lösungsweg | Text | liest, als Prüfhilfe |
| Nicht auf der Karte | Zeit, Stoffanker, Leitidee, Prozess, Cluster, Sondierrang | setzt oder misst das System |

Damit bleiben auf der Karte nur Felder, die die LSA oder der Report wirklich nutzen. Nur dort ist Lenas Urteil durch nichts zu ersetzen.
