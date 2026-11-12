# MSA-0 · Bestandsaufnahme ZP10 (MSA) und notwendiger LSA-Bestand

**Stand:** 12.11.2026, Prod per `dbread` (nur lesend), Code auf `origin/dev` @ `9241cb48`.
**Für:** Rasit, Tolunay, Ashkan · **Auftrag:** MSA-0.

Jede Zahl trägt eine Abfrage-Nummer `[Qnn]`. Die Abfragen liegen in `abfragen/qNN_*.sql` und laufen mit
`abfragen/lauf.sh NN`; das Skript stellt die gemeinsamen Blöcke (`msa_basis.sql`, `soll.sql`) voran und ruft
`~/bin/dbread -f` auf. Die Ausgaben vom 12.11.2026 liegen in `anhang/ergebnisse/`. Code-Stellen nennen
`supabase/schema-erwartet.sql` (Prod-Abzug auf `origin/dev`) oder `src/…` mit Zeile. Quellen: `quellen/README.md`.

---

## Kurzfassung

1. **Die Vorgaben ZP10 2027 haben keine Themenliste.** Sie verweisen auf die Kernlehrpläne RS/GE **2004**. Erst ab
   2028 gelten die KLP von 2022 (`quellen/README.md` a). Grundlage für 2027 sind deshalb der KLP RS 2004 und die
   amtlichen Beispiele.
2. **Die Prüfungsarbeiten 2024–2026 mit Auswertung liegen hinter dem Schul-Login.** Sie fehlen deshalb. Bitte an
   Rasit: die sechs PDFs in den Windows-Downloads-Ordner legen. Ersatz waren die freien Aufgabenbeispiele für Teil 1
   und die Formelsammlung MSA.
3. **122 der 130 Skills gehören zur MSA.** Nur 8 Skills sind rein gymnasial (bedingte Wahrscheinlichkeit 4,
   Kosinussatz, Einheitskreis, Bogenmaß, a·sin(bx)) [Q02]. Ohne Skill bleiben 5 Kompetenzen: Ordnen/Zahlengerade,
   Netze/Schrägbilder, Konstruktionen, Schätzen, Tabellenkalkulation. Eine Zweitprüfung hat die Zuordnung bestätigt:
   20 richtig, 4 teilweise (korrigiert), 0 falsch.
4. **LSA-Bestand MSA:** 36 Skills sind bereit, 9 teilweise (alle mit genau 1 Text), 77 offen. Bis zur Regel fehlen
   **163 Texte** [Q04]. Lena hat seit dem **28.10.** nichts mehr geprüft, freigegeben wurde zuletzt am 29.10.
   Leylas LSA (04.11.) und FR-2 haben keine Freigabe gebracht; FR-2 brachte 7 neue Entwürfe [Q03, Q11].
5. **Niveau** (frischer Subagent, 402 Aufgaben): 322 passen, 43 sind zu schwer, 37 zu leicht.
   - Von den 43 zu schweren sind **30 nur deshalb zu schwer, weil das Rechner-Kennzeichen fehlt** (Trigonometrie,
     Pythagoras mit krummer Wurzel, Kreis/Kugel).
   - Echt zu schwer sind 13: Sinus im Bogenmaß, Logarithmus, Drachen/Raute über Diagonalen.
   - Die 37 zu leichten sind fast nur freigegebene Aufgaben der Klassen 5–7 (`anhang/niveau-nicht-passend.csv`).
6. **Notwendiger Bestand** (alle 130 Skills = Pakete Kl. 8–10 ∪ MSA, Regel + 1 Reserve) [Q07]:

   | Regel | notwendig | davon schon frei | Lena muss prüfen | nicht notwendig |
   |---|---|---|---|---|
   | 2 Texte | **371** | 98 | 273 (176 ohne Reserve) | 523 von 894 |
   | 3 Texte | 476 | 106 | 370 | 418 |
   | 4 Texte | 565 | 112 | 453 | 329 |

   Mit der Regel 4 fehlen 25 Skills Texte, die es auch unter allen Entwürfen nicht gibt; 44 Texte müssten neu
   geschrieben werden [Q07, Q08].
7. **Lenas Prüfzeit** für Regel 2 ohne Reserve: rund 213 Prüfungen, mit ihrem Median 2,1 h, mit ihrem Mittel
   8,6 h. Regel 4 mit Reserve: 547 Prüfungen, 5,4 h bzw. 22 h [Q11, Abschnitt 3f].
8. **Entfernen: archivieren statt löschen.** `is_active = false` nimmt eine Aufgabe schon heute aus dem Pool
   (`lsa_im_pool`) und aus Lenas Board (`pruef_ausschluss` → „inaktiv“). Ein hartes Löschen würde über Kaskaden
   Kind-Antworten, Lenas Prüfprotokoll und Admin-Protokoll mitnehmen [Q10].
9. **MSA-Reihe:** Bauformen gibt es nur für 15 Skills (quadratische Funktionen/Gleichungen und Voraussetzungen).
   Für die übrigen 107 MSA-Skills braucht es 146 (Wiederholung) bis 241 (voller Maßstab Reihe 1) Bauformen. Das
   sind 12–40 h für Lena [Q13]. Von Januar bis zur ZP10 am **20.05.2027** passen **16 Sessions**.
10. **Schulformen:** Hinterlegt sind nur Gymnasien (43, davon 32 mit Plan). IGS Holweide und Kerpen fehlen in
    `schulen` [Q14]. Die Datenbank kennt die Schulform „Sekundarschule“ nicht (CHECK). Der KLP-Rückfall rechnet
    immer nach G9-Stufen.

---

## 0 · Amtliche Quellen

Siehe `quellen/README.md` (Fundstellen, Abrufdatum 12.11.2026, Zusammenfassungen). Das Wichtigste:

| | Ergebnis |
|---|---|
| a) Vorgaben 2027 MSA, EESA (+ GYM, ARS, 2028 MSA) | **im Repo.** Zwei Teile, Teil 1 ohne Rechner/Formelsammlung, kumulativ. Grundlage KLP RS/GE 2004 |
| b) Prüfungsarbeiten + Auswertungsanleitung MSA 2024, 2025, 2026 | **fehlen** (nur mit Login). Ersatz: 82 amtliche Aufgabenbeispiele Teil 1 (24 davon nur MSA), ein Beispiel-Teil-1 MSA mit Bewertungsbogen, Formelsammlung MSA, Ergebnisbericht 2025, alle lokal unter `~/msa-quellen-lokal/` |
| c) KLP RS, GE/SK, G9 | **im Repo**: RS 2004, GE 2004, RS 2022, GE/SK 2022, G9 2019 |

Ein Nebenbefund aus dem Ergebnisbericht 2025: Die Prüfungsnote Mathematik lag an Realschulen bei 3,5 (22,7 % nicht
ausreichend), im GE-E-Kurs bei 3,3 und am Gymnasium bei 2,9. 2025 gab es 29.465 Prüflinge an Realschulen und 25.857
im GE-E-Kurs.

---

## 1 · ZP10-Themen auf Skills

Die Zuordnung steht in `anhang/zuordnung.csv` (41 MSA-Kompetenzzeilen + 3 Zeilen „nur G9“). Je Skill zeigt Q01
Herkunftsklasse, Thema, Kompetenz-IDs, Teil und MSA ja/nein. In der Datei `msa_basis.sql` ist die Zuordnung als
`values`-Liste eingebettet, alle Abfragen nutzen sie.

**Grundlage:** die inhaltsbezogenen Kompetenzerwartungen des KLP RS 2004 bis Ende 10 (S. 29–31), Ende 8 (S. 24–26) und
Ende 6 (S. 20–21), soweit die Teil-1-Beispiele sie abfragen. Der KLP GE 2004 ist inhaltlich gleich, mit
Einschränkungen für den G-Kurs (siehe 5b). „Teil 1“ heißt: In den amtlichen Teil-1-Beispielen gibt es eine passende
Aufgabe (Nummer in der Spalte `beleg_teil1`). „Teil 2“ heißt: Die Kompetenz steht im KLP und in der Formelsammlung, ein
Teil-1-Beleg fehlt. Ohne die Prüfungsarbeiten bleibt „typisch in Teil 2“ unbelegt.

| | Skills [Q02] |
|---|---|
| alle | 130 |
| MSA | **122** (Herkunft Kl. 5/6: 20, Kl. 7/8: 53, Kl. 9/10: 49) |
| davon Kompetenz mit Teil-1-Beleg | 109 |
| davon nur Teil 2 | 13 (Trigonometrie 4, `fkt_exp_*` 3, `fkt_quadr_extrem`, `gleichung_lgs_sachaufgabe`, `zahl_wurzel_irrational`, `stoch_bedingt_irrefuehrend`, `fkt_sinus_periodisch`, `geo_massstab`) |
| **nur Gymnasium (G9)** | **8**: `stoch_bedingt_wkeit`, `_vierfeld`, `_umkehr`, `_unabhaengig` (KLP G9 PDF-S. 35); `geo_trigo_kosinussatz` (S. 34); `fkt_sinus_einheitskreis`, `fkt_sinus_bogenmass`, `fkt_sinus_parameter` (S. 33–36). Keiner davon steht im KLP RS/GE 2004 oder in der Formelsammlung MSA |
| teilweise gymnasial | `fkt_exp_gleichung`: Probieren gehört zur MSA, Logarithmieren nur zu G9 (PDF-S. 32) |

**Lücken im Skill-Baum (Kompetenz ohne Skill, alle mit Teil-1-Beleg außer G8-4):**

| ID | Kompetenz | Beleg |
|---|---|---|
| A8-1 | rationale Zahlen ordnen, vergleichen, Zahlengerade | Ari-1, 3, 4, 6, 7 |
| G10-2 | Netze und Schrägbilder von Zylinder, Pyramide, Kegel | Geo-6 |
| G8-4 | Dreiecke konstruieren (Zirkel und Geodreieck sind in Teil 1 zugelassen) | – |
| P-1 | Schätzen in Sachsituationen | Beispiel-Teil 1 A1 (2 von 18 Punkten) |
| P-2 | Tabellenkalkulation (Formeln lesen) | Ari-29, Ari-30 |

Nur teilweise abgedeckt: Symmetrie und Spiegelung (Geo-3) sowie das arithmetische Mittel (Sto-9, Sto-10), das nur
über `stoch_kenngroessen` läuft.

**Zweitprüfung** (frischer Subagent, 20 zufällige Skills per `shuf` + alle 8 G9-Skills): 20 richtig, 4 teilweise,
0 falsch. Alle 8 G9-Skills sind bestätigt. Übernommene Korrekturen:

- `bruch_mult` und `bruch_div` gehören zu Ende 8 (A8-2), nicht zu Ende 6.
- `geo_massstab` läuft nur über G10-3.
- Trigonometrie ist eine eigene Zeile G10-6, nur Teil 2 (Winkel brauchen den Taschenrechner).
- Die Seitenangaben für Ende 6 sind korrigiert.
- Die schwachen Teil-1-Belege bei Trapez und Parallelwinkeln stehen jetzt in der Bemerkung.

---

## 2 · LSA-Bestand für die MSA

Die Regel stammt aus den FR-2-Stellschrauben (`lsa_regel`, `schema-erwartet.sql:9745`): **2 Texte, davon 1 ohne MC**.
Sie gilt im Pool `lsa_im_pool` (`:8699`), Textschlüssel nach `lsa_text_schluessel` (`:11158`), gezählt wie
`lsa_skill_bereit_roh` (`:10620`). Die Tabelle je Skill liefert [Q03] (`anhang/ergebnisse/q03.txt`).

| Gruppe [Q04] | Skills | ready | draft | fehlende Texte | von Lena geprüft (passt) |
|---|---|---|---|---|---|
| **bereit** | 36 | 142 | 132 | 0 | 137 (113) |
| **teilweise** (1 von 2 Texten) | 9 | 26 | 45 | 9 | 26 (22) |
| **offen** (0 im Pool) | 77 | 0 | 499 | 154 | 0 |
| **gesamt** | **122** | 168 | 676 | **163** | 163 (135) |

- **Teilweise** (je 1 Text im Pool): `dezimal_add_sub`, `dezimal_mult`, `dezimal_div`, `bruch_dezimal`,
  `bruch_kuerzen`, `gleichung_beidseitig`, `term_zusammenfassen`, `geo_winkel_dreieck`, `stoch_pfad_summe`.
- **Offen:** Darunter sind alle Skills der Klassen 9/10 außer den Wurzel-Skills: Potenzen, quadratische Funktionen
  und Gleichungen, Pythagoras, Ähnlichkeit, Kreis, Körper, Trigonometrie, Exponential, Sinus. Dazu kommen
  Prozent/Zins, Winkel, Stochastik der Klasse 8 und Größen. Für 75 der 77 offenen Skills gibt es unter den Entwürfen
  mindestens 2 Texte. Nur `geo_kreis_zusammen` (0 Aufgaben) und `bruch_div` (1 Text) bleiben auch dann offen [Q04, Q08].

**Woher kommen die Freigaben?** Alle 168 ready-Aufgaben stammen aus drei Wellen [Q03, Spalten `w1`–`w3`]:

| Welle | Freigegeben | Inhalt |
|---|---|---|
| 19.–21.10. | 74 | Batus LSA, Reelle Zahlen: Wurzeln, Vorzeichen, Potenzen |
| 25.10. | 60 | Batus Freigabeliste P4 (`pruef_soll` Anlass `batu_lsa`): Dezimal, Bruch, Terme, Gleichungen, Größen |
| 29.10. | 34 | lineare Funktionen, LGS, binomische Formeln, Flächen |

Lenas letzte LSA-Prüfung war am 28.10. [Q11]. **Leylas LSA (04.11.) hat keine Prüf- oder Freigabewelle ausgelöst.
FR-2 (09.11.) hat 7 Entwürfe mit zweitem Text angelegt (Migration `20261109130736`), Lena hat davon noch keinen
geprüft.**

### Niveau-Prüfung

Ein frischer Subagent ohne Kontext hat alle 168 freigegebenen und 234 von `pruef_ziel_roh` vorgeschlagenen Aufgaben
der MSA-Skills beurteilt [Q05]. Maßstab waren die Teil-1-Beispiele, die Formelsammlung und der KLP RS 2004, denn die
echten Prüfungen fehlen (Abschnitt 0b). Die Urteile stehen in `anhang/niveau-urteil.json`, die Liste der nicht
passenden mit je einem Satz Begründung in `anhang/niveau-nicht-passend.csv`.

| | passt | zu schwer | davon nur Rechner fehlt | zu leicht |
|---|---|---|---|---|
| freigegeben (168) | 132 | 4 | 0 | 32 |
| vorgeschlagen (234) | 190 | 39 | 30 | 5 |

- **Rechner-Konflikt (30):** Die Inhalte passen zur MSA (Teil 2), aber `taschenrechner = false`. Betroffen sind
  `geo_trigo_*` (10), `geo_pythagoras_*` (7), Kreis/Kugel/Kegel (7), `fkt_exp_*` (5) und `fkt_quadr_nullstellen` (1).
  Abhilfe: das Kennzeichen setzen, nicht streichen.
- **Echt zu schwer (13):**
  - `fkt_sinus_graph` und `fkt_sinus_periodisch` (je 3, Bogenmaß)
  - `fkt_exp_gleichung` (2, Logarithmus) und `fkt_exp_halbwert` (1, Exponent 10/3)
  - `geo_flaeche_drachen_raute` (3 freigegebene, Fläche über die Diagonalen e·f/2, steht nicht in der Formelsammlung)
  - `zahl_wurzel_irrational` (1 freigegebene, periodische Dezimalzahl als Bruch)
- **Zu leicht (37):** vor allem `potenzen` (3², 5², 7²; 6), `runden_ueberschlag` (5), `vorzeichen_*` (6),
  einschrittige Gleichungen und Quader 2·3·4. Für die Klasse-8-LSA können sie bleiben. Für eine MSA-Diagnose sagen sie
  wenig.

### Taschenrechner

- **Heute:** `tasks.taschenrechner` (boolean, `schema-erwartet.sql:13201`) ist bei **17 LSA-Aufgaben** gesetzt, bei
  5 ready (`zahl_wurzel_naeherung`) und 12 Entwürfen (`geo_aehnlich_*`) [Q06]. Der Schalter in der Prüfansicht ruft
  `pruef_taschenrechner_setzen` auf (`:14783`). Lena kann ihn nur vor der Freigabe setzen. Global gilt
  `pruef_einstellungen.hilfsmittel` = „Stift und Zettel“ [Q06]. Der Rechner der App hat kein sin/cos
  (Retro 30.10.).
- **Teil 1 vs. 2 ausdrücken:**
  - **Variante A (kein neues Feld):** `taschenrechner = true` heißt Teil 2, `false` heißt Teil-1-fähig.
    - Vorteil: Das reicht für die LSA.
    - Nachteil: Die Formelsammlung bleibt unberücksichtigt. Eine Kegel-Aufgabe ohne Rechner, aber mit Formel, ist
      weder Teil 1 noch klar Teil 2.
  - **Variante B (neues Feld):** `tasks.pruefungsteil smallint check (pruefungsteil in (1, 2))` oder
    `hilfsmittel text[]` (`{taschenrechner, formelsammlung}`). Teil 1 heißt dann „keins von beiden“.
    - Vorteil: Eine MSA-LSA kann einen Teil-1-Block ohne Hilfsmittel ziehen, wie die echte Prüfung.
    - Kosten: Schema-Änderung, Payload (`lsa_question_payload` gibt `taschenrechner` heute schon aus, `:9694`) und
      Schalter in der Prüfansicht.
  - **Empfehlung:** B als `hilfsmittel text[]`. Bis dahin A und die 30 Rechner-Konflikte über den bestehenden Schalter
    lösen (Admin, weil ready).

---

## 3 · Notwendiger LSA-Bestand und Streichliste

### 3a/3b · Soll in drei Varianten

**Skill-Menge:** Alle Skills der Pakete Kl. 8–10 an allen hinterlegten Schulen (110, `lsa_paket_skills_basis`,
Schuljahr 2026/27) ∪ MSA-Skills (122). Das ergibt **130**, also alle Skills. Die 8 G9-Skills kommen über die
Gymnasial-Pläne dazu, 20 MSA-Skills liegen in keinem Paket [Q07].
**Soll je Skill:** N verschiedene Textschlüssel (N = 2, 3, 4), mindestens einer ohne MC, + 1 Reserve.

| [Q07, Q09] | 2 Texte | 3 Texte | 4 Texte |
|---|---|---|---|
| notwendig gesamt | **371** | **476** | **565** |
| davon für die Regel / Reserve | 257 / 114 | 371 / 105 | 476 / 89 |
| schon freigegeben (im Pool) | 98 | 106 | 112 |
| Lena muss prüfen (Entwürfe) | 273 | 370 | 453 |
| … ohne Reserve | 176 | 273 | 370 |
| nicht notwendig (von 894) | 523 | 418 | 329 |
| … draft / ready / rueckfrage | 451 / 70 / 2 | 354 / 62 / 2 | 271 / 56 / 2 |
| … davon gleicher Text wie eine bessere Aufgabe | 182 | 182 | 182 |
| … davon über Soll | 305 | 200 | 111 |
| … davon ohne gültige Lösung oder inaktiv | 34 | 34 | 34 |
| Skills mit zu wenig Texten (auch mit allen Entwürfen) | **2** | **16** | **25** |
| Skills ohne Reserve | 14 | 9 | 16 |
| Texte neu zu schreiben | 3 | 19 | 44 |

**Zu wenig Texte** [Q08]:

- Regel 2: `geo_kreis_zusammen` (0) und `bruch_div` (1).
- Regel 3 zusätzlich 14 Grundlagen-Skills mit je 2 Texten, alle MSA: `bruch_add`, `bruch_dezimal`, `bruch_kuerzen`,
  `bruch_mult`, `geo_flaeche_rechteck`, `geo_umfang`, `geo_winkel_summe`, `gleichung_beidseitig`,
  `gleichung_lgs_sachaufgabe`, `gleichung_neg_koeffizient`, `gleichung_zweischrittig`, `term_ausklammern`,
  `term_minusklammer`, `term_zusammenfassen`.
- Regel 4 zusätzlich 9 Skills mit je 3 Texten: `geo_flaeche_dreieck`, `geo_volumen_quader`,
  `gleichung_einschrittig`, `stoch_gegenereignis`, `stoch_laplace`, `stoch_pfad_produkt`, `stoch_pfad_summe`,
  `vorzeichen_add_sub`, `zahl_potenz_negativ`.

Selbstprüfung der Auswahl [Q08]: In keiner Variante fehlt im Regel-Satz eine Nicht-MC-Aufgabe, wo es eine gibt, und
kein Textschlüssel ist doppelt gewählt.

### 3c · Auswahlregel „notwendig“ (`abfragen/soll.sql`)

1. Kandidaten sind die LSA-Aufgaben der 130 Skills mit Status draft, review oder ready und gültiger Lösung, also
   alle Bedingungen von `lsa_im_pool` außer dem Status.
2. Rang je Aufgabe:
   - (1) im Pool
   - (2) Lenas letzte Entscheidung „passt“, noch nicht freigegeben
   - (3) Entwurf ohne Lena-Entscheidung
   - (4) Entwurf mit Lenas „unsicher“

   Bei gleichem Rang kommt Nicht-MC vor MC, dann `sondierrang`, dann `id`.
3. Je Skill und Textschlüssel zählt nur der beste Vertreter.
4. Die Schlüssel werden nach dem Rang ihres Vertreters geordnet. Die ersten N bilden die Regel, der N+1-te ist die
   Reserve. Ist unter den ersten N keine Nicht-MC-Aufgabe, tritt der beste Nicht-MC-Schlüssel an die Stelle N.

Die Liste aller 894 LSA-Aufgaben mit Rolle je Variante und Grund (Variante 2) steht in `anhang/aufgabenliste.csv`
[Q17]: `id, skill, msa, status, format, textschluessel (md5), rang, rolle_2, rolle_3, rolle_4, grund_2`.

Hinweis: Die 49 ready-Aufgaben mit „gleichem Text“ kosten Lena keine Zeit. Sie liegen schon im Pool und würden nur
in einer zweiten Sitzung (Wiederholungs-LSA) wieder gezogen.

### 3d · Was hängt an den nicht notwendigen Aufgaben? [Q10]

| Verweis (Aufgaben mit mindestens einer Zeile) | Regel 2 (523) | Regel 3 (418) | Regel 4 (329) | beim Löschen (FK) |
|---|---|---|---|---|
| `lsa_responses` (Zeilen) | 45 (97) | 41 (87) | 40 (86) | CASCADE, Kind-Antworten weg |
| `lsa_ausgegeben` | 45 | 41 | 40 | NO ACTION, blockiert |
| `lsa_sessions.item_ids` | 0 | 0 | 0 | kein FK |
| `session_ausgegeben` / `session_antworten` | 18 / 17 | 15 / 14 | 14 / 13 | NO ACTION, blockiert |
| `session_schritte` / `bauform_kommentare` | 20 | 17 | 15 | NO ACTION, blockiert |
| `task_pruefungen` (Lenas Protokoll) | 69 | 62 | 56 | CASCADE, Protokoll weg |
| `task_pruefung_ausgang` | 99 | 85 | 73 | CASCADE |
| `task_admin_protokoll` | 270 | 223 | 186 | CASCADE |
| `task_reviews` | 13 | 12 | 11 | CASCADE |
| `task_figures` | 21 | 14 | 8 | CASCADE |
| Fehlbilder (`acceptance.known_errors`) | 459 | 370 | 291 | mit `task_solutions` (CASCADE) |
| Home-Quests (`quest_aufgaben`), Reports, Studio, `behavior_snapshots`, XP | 0 | 0 | 0 | |
| **einem echten Kind gezeigt** | **1** | **1** | **1** | |
| nur in Testdaten gezeigt | 59 | 52 | 50 | |

„Echt“ heißt: `students.ist_test = false` und `lsa_sessions.testlauf = false`. Die FK-Arten stammen aus `pg_constraint`
(Q10-Kopf). Reports verweisen nicht auf Aufgaben. `fehlbild_familien`/`report_bausteine` hängen am Fehlbild-Schlüssel,
nicht an der Aufgabe. Dass 20 LSA-Aufgaben in `session_schritte` stehen, ist ein Nebenbefund aus der Zeit vor der
Pool-Trennung.

### 3e · Wege zum Entfernen (nur beschrieben)

| | (i) Archivieren | (ii) Hart löschen mit Sicherung (wie VERA8) |
|---|---|---|
| Mechanik | **Feld gibt es schon:** `tasks.is_active` (`schema-erwartet.sql:13160`). `lsa_im_pool` verlangt es (`:8699`), `pruef_ausschluss` meldet „inaktiv“ und nimmt die Aufgabe aus Lenas Board (`:13435`, Grund 2). Zusätzlich möglich: Status `beanstandet` (CHECK `:13225`) | Muster `20261028143121_reihe1_vera8_entfernen.sql`: Wächter über alle FKs, Sicherung `~/backups/…` per COPY, dann Löschen in Reihenfolge `lsa_responses` → `task_solutions` → `tasks` |
| betroffene Tabellen | nur `tasks` (1 Spalte) | `tasks`, `task_solutions`, `lsa_responses`, `lsa_ausgegeben`, `session_*`, `task_pruefungen`, `task_pruefung_ausgang`, `task_admin_protokoll`, `task_reviews`, `task_figures` (siehe 3d) |
| Risiken | Aufgaben bleiben in Admin-Listen (Filter nötig). Wer `is_active` später wieder setzt, holt sie zurück | Kind-Antworten (97 Zeilen), Lenas Protokoll (69 Aufgaben) und das Admin-Protokoll gehen verloren. `lsa_ausgegeben` und `session_*` blockieren. `task_pruefungen` ist laut Trigger nur gegen UPDATE geschützt (`:24304`, Trigger `:32942`), die Kaskade löscht es trotzdem. CLAUDE.md §6 (Rohdaten append-only) |
| unwiederbringlich | nichts | alles oben, ohne Sicherung. Mit Sicherung nur über ein Rückspiel-Skript |
| Aufwand | 1 Datenmigration (`update tasks set is_active = false where id in …`), pgTAP, Prüfabfrage, ca. ½ Tag | Wächter, Sicherung, Reihenfolge, Test mit Kinddaten, Consensus (§8), ca. 1–2 Tage |

**Empfehlung: (i) archivieren.** Es gibt das Feld schon, und Pool und Board beachten es heute schon. Eine Aufgabe ist
einem echten Kind gezeigt worden, 59 sind in Testdaten gezeigt worden, und 69 tragen Lenas Prüfprotokoll. Löschen
bringt keinen Gewinn außer einer kürzeren Tabelle. Ausnahme: Die 34 Aufgaben ohne gültige Lösung, die nirgends
gezeigt wurden, können über die VERA8-Mechanik weg, wenn Rasit das will.

### 3f · Lenas Prüfzeit [Q11]

Gemessen in `task_pruefungen.dauer_sek` an LSA-Aufgaben (170 Entscheidungen mit Dauer): **Median 35,5 s, Mittel
144,9 s**. Passt-Quote nach der letzten Entscheidung je Aufgabe: **82,8 %** (135 von 163). FR-0 nannte 80,5 % nach
anderer Zählung.
Rechnung: Prüfungen = zu prüfende Aufgaben ÷ 0,828.

| Regel | zu prüfen | Prüfungen | Median | Mittel | 2 Min je Aufgabe |
|---|---|---|---|---|---|
| 2, ohne Reserve | 176 | 213 | 2,1 h | 8,6 h | 7,1 h |
| 2, mit Reserve | 273 | 330 | 3,3 h | 13,3 h | 11,0 h |
| 3, ohne / mit Reserve | 273 / 370 | 330 / 447 | 3,3 / 4,4 h | 13,3 / 18,0 h | 11,0 / 14,9 h |
| 4, ohne / mit Reserve | 370 / 453 | 447 / 547 | 4,4 / 5,4 h | 18,0 / 22,0 h | 14,9 / 18,2 h |

Das Mittel ist durch wenige lange Prüfungen verzerrt. Realistisch liegt die Zeit zwischen Median und 2 Minuten.
Dazu kommen die 30 Rechner-Konflikte (Admin) und die 13 echt zu schweren Aufgaben aus Abschnitt 2.

---

## 4 · Session: MSA-Reihe

### 4a · Abdeckung durch die 47 Bauformen [Q12, Q13, Q19]

Die 47 Bauformen (alle `zur_pruefung`, 0 Prüfungen) decken **15 Skills** ab:

- **Kern (9 Skills, 40 Bauformen):** quadratische Funktionen (PAR, SCH, NF, NS, EX) und quadratische Gleichungen (WZ,
  NP, PQ, DI).
- **Voraussetzungen (6 Skills, 7 Bauformen):** BIN-1/2, AUS-1, EIN-1, QW-1, KO-1, GL-1.

Abgedeckte ZP10-Kompetenzen: A10-5 (vollständig), F10-2 (quadratischer Teil), F10-3 (Nullstellen), A10-8 (Extremwert).
Teilweise abgedeckt sind A8-3, A8-4, A10-3 und B6-5.

**Nicht abgedeckt: 107 MSA-Skills in 30 Themen** [Q13], darunter alle Themen der Klassen 9/10 außer den
quadratischen: Potenzen, Reelle Zahlen (bis auf QW-1), Pythagoras, Ähnlichkeit, Kreis, Prismen/Zylinder,
Pyramide/Kegel/Kugel, Trigonometrie, Exponentialfunktionen, Sinus, Statistik beurteilen. Dazu kommt der ganze
Grundlagenstoff mit Prozent/Zins, linearen Funktionen, LGS, Flächen, Winkeln und Stochastik.

### 4b · Schätzung für die nicht abgedeckten Themen

Maßstab Reihe 1: 40 Kern-Bauformen für 9 Kern-Skills (≈ 4,4) und 1 Bauform je Voraussetzung (Konzept §4).

| [Q13] | Kern-Skills (Kl. 9/10) | Grundlagen-Skills (Kl. 5–8) | Bauformen voll (4,4 / 1) | Bauformen Wiederholung (2 / 1) |
|---|---|---|---|---|
| ohne Bauform | 39 | 68 | **241** | **146** |

Je Thema (voll / Wiederholung): Pythagoras 22/10, Kreis 22/10, Exponential 22/10, Potenzen 18/8, Reelle Zahlen 18/8,
Ähnlichkeit 18/8, Trigonometrie 18/8, Pyramide/Kegel/Kugel 13/6, Prismen/Zylinder 9/4, Sinus 9/4, Statistik 4/2.
Die Grundlagen brauchen 1 je Skill, das sind 68: Prozent/Zins 8, Terme/Gleichungen 7, Bruch/Dezimal 7, Flächen 6,
Größen 5, lineare Funktionen 5, LGS 5 und weitere.
Für eine Prüfungsvorbereitung genügt die Wiederholung, also 146. Neu gelernt wird dort nichts, es wird gesichert.

**Neue Formate und Figurengeneratoren:**

- **Heute vorhanden:**
  - Formate: `feldmaske`, `loesungsmenge`, `mehrteiler`, `bausteine`, `fehler_finden`, `zahl`, `mc`,
    `graph_auswahl`, `schritte_ordnen`, `tabelle`.
  - Generatoren: `koordinatensystem`, `parabel`, `rechteck(e)`, `thales`, `winkel` (Q19), dazu
    `steigungsdreieck` und `achsenzahlen` in `scripts/figures/`.
- **Neu nötig:**
  - rechtwinkliges Dreieck mit Beschriftung (Pythagoras, Trigonometrie)
  - Körper-Schrägbild für Prisma, Zylinder, Pyramide, Kegel, Kugel (auch für die Netz-Lücke G10-2)
  - Kreis, Kreissektor und zusammengesetzte Figur
  - Strahlensatz-Figur
  - Baumdiagramm zum Ausfüllen (Feldmaske auf Figur)
  - Boxplot und Säulen-/Kreisdiagramm (auch „irreführende Darstellung“)
  - Graph der Exponential- und Sinusfunktion in Grad als Erweiterung von `koordinatensystem`
  - Tabellenkalkulations-Ausschnitt (P-2)
- **Formate:** Schätzen mit Begründung (P-1) ist nicht autogradbar und gehört als Coach-Prüffrage in die Session.
  Ein Rechner-Kennzeichen je Instanz braucht es für Teil-2-Aufgaben in der Session.

**Erklärvideos:** Reihe 1 plant 8 Videos für 9 Kern-Skills. Für eine Wiederholungsreihe reicht 1 Video je Themenblock,
das sind rund 15: 11 Themen der Klassen 9/10 sowie Prozent/Zins, Terme/Gleichungen/LGS, lineare Funktionen und
Stochastik. Im vollen Maßstab wären es rund 35 (≈ 0,9 je Kern-Skill).

### 4c · Zuschnitt einer MSA-Sonderreihe Januar bis ZP10 (Vorschlag, nichts angelegt)

**Termine:**

- ZP10 Mathematik am Do 20.05.2027.
- Weihnachtsferien bis 06.01.2027, Osterferien 22.03.–03.04.2027, Pfingstdienstag 18.05.2027 (Ferienordnung NRW).
- Volle Schulwochen ab 11.01. bis zur Prüfungswoche: 11.01. bis 15.03. (10), 05.04. bis 10.05. (6), zusammen
  **16 Sessions** bei 1 je Woche.
- Puffer: die Woche ab 04.01. (nur Do/Fr) und Mo/Mi der Prüfungswoche. Risiken: Rosenmontag 08.02. (bewegliche
  Ferientage in Köln) und Christi Himmelfahrt 06.05.

**Gewichtung:**

- Die Prüfungen fehlen (0b). Ersatzweise zählen die amtlichen Teil-1-Beispiele: Arithmetik/Algebra 38, Funktionen 18,
  Geometrie 16, Stochastik 10. Im Beispiel-Teil 1 MSA gehen 9 von 18 Punkten an Größen, Prozent und Gleichungen.
- Teil 2 prüft laut Vorgaben „alle Inhaltsbereiche“ in Kontexten. Die Reihenfolge ist neu zu wiegen, sobald die
  Arbeiten 2024–2026 vorliegen.

| # | Woche ab | Kernarbeit | Warm-up (Teil 1, ohne Rechner) |
|---|---|---|---|
| 1 | 11.01. | MSA-LSA (Diagnose Teil 1 + Teil 2) | – |
| 2–3 | 18.01., 25.01. | Prozent, Zins, Zinseszins | Größen, Überschlag |
| 4–5 | 01.02., 08.02. | Terme, lineare Gleichungen, LGS | Brüche/Dezimal, Vorzeichen |
| 6 | 15.02. | lineare Funktionen | Prozent |
| 7–8 | 22.02., 01.03. | quadratische Funktionen und Gleichungen (Bauformen Reihe 1 vorhanden) | binomische Formeln, Wurzeln |
| 9–10 | 08.03., 15.03. | Pythagoras, Trigonometrie (Teil 2, Rechner) | Flächen, Winkel |
| 11–12 | 05.04., 12.04. | Kreis, Körper (Zylinder, Pyramide, Kegel, Kugel) | Volumeneinheiten |
| 13 | 19.04. | exponentielles Wachstum (Zinseszins wieder aufnehmen) | Potenzen, Zehnerpotenzen |
| 14 | 26.04. | Stochastik: Baumdiagramm, Pfadregeln, Boxplot, irreführende Diagramme | Laplace |
| 15 | 03.05. | Ähnlichkeit, Sinusfunktion (kurz), offene Lücken aus der LSA | gemischt |
| 16 | 10.05. | **Generalprobe** (Teil 1 ohne, Teil 2 mit Rechner und Formelsammlung) | – |

### 4d · Lenas Prüfumfang für die MSA-Reihe

SP-1 hat noch keine gemessene Zeit: `bauform_pruefungen` ist leer [Q19]. Maßstab ist daher Konzept §10:
5–10 Minuten je Bauform, 2 Minuten je Coach-Prüffrage, 10 Minuten je Video.

| | Bauformen | Bauformen × 5–10 Min | Prüffragen (≈ 1,7 je Kern-Skill) | Videos | gesamt |
|---|---|---|---|---|---|
| Wiederholung | 146 | 12,2–24,3 h | 66 × 2 Min ≈ 2,2 h | 15 × 10 Min = 2,5 h | **≈ 17–29 h** |
| voll | 241 | 20,1–40,2 h | 66 × 2 Min ≈ 2,2 h | 35 × 10 Min ≈ 5,8 h | **≈ 28–48 h** |

Bei 4 Stunden Lena je Woche dauert die Wiederholung allein 4–7 Wochen. Für einen Start im Januar müsste die Prüfung
der Bauformen spätestens Anfang Dezember beginnen, oder die Reihe startet mit den Themen, deren Bauformen schon
vorhanden sind.

---

## 5 · Schulformen

### 5a · Was ist hinterlegt? [Q14, Q15, Q20]

| Schulform (`schulen.schulform`) | Schulen | mit eigenem Mathe-Plan | Plan Kl. 8–10 vollständig | bestätigte KA-Folge |
|---|---|---|---|---|
| Gymnasium | 43 | 32 | 25 | 0 |
| (leer, Name „Gymnasium“) | 1 | 0 | 0 | 0 |
| Realschule, Gesamtschule, Sekundarschule | **0** | – | – | – |

- **Pakete:** Alle 501 Pakete der Klassen 8–10 an 30 Schulen sind geschätzt, keines ist bestätigt [Q20].
- **Schulen ohne eigenen Plan** (12) haben **gar keine Pakete**, denn `lsa_pakete_roh` liest nur `schul_themenplan`
  und `schul_klassenarbeiten` (`schema-erwartet.sql:9384`).
- **Wie heute geschätzt wird:** In der LSA selbst greift für ein Kind ohne Plan der Rückfall `lsa_klp_themen`
  (`:8866`, aufgerufen in `lsa_select_next_core` `:9975`, `:10049–10058`). Er ordnet die Klasse einer **G9-Stufe**
  zu (≤ 6 erprobung, ≤ 8 erste, sonst zweite). Die Themen trägt `themen.stufe`/`themen.klp`, die Kürzel kommen aus
  dem KLP G9 (`:29273`).
- **Leads und Kinder:** Gesamtschule 6 Leads / 5 Kinder, Realschule 1 / 1, Hauptschule 1 Lead. Alle sind
  Testdaten [Q15]. Einziger echter Lead bzw. einziges echtes Kind: Gymnasium (FWG).

### 5b · Kernlehrpläne RS/GE 2004 vs. G9 in Klasse 8–10

Die KLP RS/GE 2004 legen nur Doppeljahrgänge fest (Ende 8, Ende 10). Der KLP G9 legt nur „Ende Sek I“ fest. Die
Klasse im G9 stammt deshalb aus den hinterlegten Gymnasial-Plänen [Q18], die Klasse in RS/GE ist der Doppeljahrgang
des KLP.

| Thema | RS 2004 | GE 2004 (E / G) | G9 (Klasse in den Plänen, Schulen) | Unterschied |
|---|---|---|---|---|
| Prozent, Zins | 7/8 | 7/8 / 7/8 | 7 (31) | – |
| Terme, binomische Formeln | 7/8 | 7/8; G: „kein Produkt von Summen“ | 7–8 (27–31) | G-Kurs kleiner |
| lineare Funktionen | 7/8 | 7/8 | 8 (30) | – |
| **LGS** | **9/10** | **9/10** | **8 (30)** | RS/GE ein bis zwei Jahre später |
| Zufall, Laplace, Boxplot | 7/8 | 7/8 | 7–8 (27/24); Boxplot im G9 schon 5/6 | – |
| Prismen | 7/8 | 7/8 | 9 (7) | RS/GE früher |
| Thales | 9/10 | 9/10 | 8 (25) | G9 früher |
| Reelle Zahlen, Wurzeln | 9/10 | 9/10 (+ Intervallschachtelung E) | 9 (26) | – |
| Potenzen, Zehnerpotenzen | 9/10 | 9/10 | 9 (27) | G9 zusätzlich Logarithmus |
| quadratische Funktionen | 9/10 | 9/10; **G: nur f(x) = ax²** | 9 (27) | G-Kurs stark reduziert |
| quadratische Gleichungen | 9/10 | 9/10; **G: nur rein-quadratisch** | 10 (19), 9 (4) | G-Kurs ohne p-q-Formel |
| Pythagoras | 9/10 | 9/10 | 9 (26) | – |
| Ähnlichkeit | 9/10 (maßstäblich, Ähnlichkeitsbeziehungen) | 9/10 | 10 (17), 9 (8) | – |
| Kreis | 9/10 | 9/10 | 9 (26) | – |
| Zylinder, Pyramide, Kegel, Kugel | 9/10 | 9/10 | 9–10 (7–8 Schulen haben das Thema im Plan) | – |
| Trigonometrie | 9/10, rechtwinklig | 9/10 | 10 (25) | **G9: Kosinussatz** |
| Exponentialfunktionen | 9/10 (b^x = c durch Probieren) | 9/10; G: nur Eigenschaften exp. Wachstums | 10 (25) | **G9: Logarithmus** |
| Sinusfunktion | 9/10, „Sinusfunktion“ | 9/10 | 10 (25) | **G9: Bogenmaß, Einheitskreis, a·sin(bx)** |
| bedingte Wahrscheinlichkeit | – (nur zweistufig, Pfadregeln) | – | 9 (20), 10 (19) | **nur G9** |
| Statistik beurteilen | 9/10 | 9/10 | 9 (5) | – |

- **Reihenfolge:** RS/GE legen innerhalb des Doppeljahrgangs nichts fest. Die Folge bestimmt der schulinterne
  Lehrplan, wie beim Gymnasium.
- **E- und G-Kurs (GE) / Grund- und Erweiterungsebene (SK):** Die G-Einschränkungen stehen wörtlich im KLP GE 2004
  (S. 24, 29, 30). Der MSA wird in der Regel über den E-Kurs erreicht. Der Ergebnisbericht führt GE-G und GE-E
  getrennt.

### 5c · Was müsste sich ändern (nur beschrieben)?

1. **Schulform „Sekundarschule“ zulassen** (und ggf. „Primusschule“): CHECKs `schulen_schulform_check` (`:28158`),
   `leads_school_type_check` (`:27538`) und `students_school_type_check` (`:28839`).
2. **KLP-Plan je Schulform als Daten:** eine neue Tabelle `klp_themenplan` (fach, schulform, klp_fassung 2004|2022,
   doppeljahrgang bzw. klasse, kurs E|G|alle, position, thema_key, nur_teil text). Die Tabelle braucht RLS. Der Schalter
   2004/2022 hängt am Prüfungsjahrgang: Klasse 5 im Schuljahr ≥ 2022/23.
3. **`lsa_klp_themen(p_fach, p_klasse)` erweitern** um `p_schulform` und `p_kurs`, mit Rückfall auf G9 wie heute.
   Aufrufer: `lsa_select_next_core` (`:9975`, `:10049–10058`) und `lsa_pakete_roh` (Klasse + 1).
4. **Pakete für Schulen ohne eigenen Plan:** `lsa_pakete_roh` erzeugt für eine Schule mit `schulform`, aber ohne
   `schul_themenplan`, Pakete aus `klp_themenplan`. Lage im Schuljahr: Doppeljahrgang linear über zwei Jahre; Quelle
   `'klp'` neben `'geschaetzt'` und `'bestaetigt'`. FR-2 (`lsa_paket_skills_roh`) muss dieselbe Hülle nutzen.
5. **Skill-Grenzen je Schulform und Kurs:** `skill_thema` um eine Sicht `skill_schulform` (skill_key, schulform, kurs,
   zulässig) ergänzen. Beispiele: 8 G9-Skills für RS/GE gesperrt, `fkt_quadr_normalform`/`gleichung_quadr_formel` im
   G-Kurs gesperrt. Die LSA zieht dann im G-Kurs keine p-q-Aufgaben, und die Pakete enthalten sie nicht.
6. **Klassenarbeiten:** Die geschätzte Lage aus dem KLP ist grob, weil es nur Doppeljahrgänge gibt. Die bestätigte
   Folge über Elternangaben (`ka_folge_schule`, `:6145`) wird für RS/GE wichtiger als am Gymnasium.
7. **E-/G-Kurs am Kind:** eine Spalte `students.kurs_mathe text check (kurs_mathe in ('E', 'G'))`, dazu dasselbe an
   `leads` für die Erfassung. Weil die Einstufung je Halbjahr wechseln kann, besser eine Verlaufstabelle `kind_kurs`
   (student_id, fach, kurs, ab_datum). Dazu das **Abschlussziel** (EESA | MSA | MSA-Q | GYM), denn es bestimmt die
   ZP10-Variante.

### 5d · IGS Holweide und Gesamtschulen in Kerpen

**Nicht hinterlegt.** In `schulen` gibt es keinen Eintrag mit „Holweide“ oder „Kerpen“ und keine Gesamtschule
[Q14]. „Gesamtschule Holweide“ steht nur als Freitext an einem Test-Lead (`school_type` Gesamtschule) und an einem
Test-Kind (`school_type` leer) [Q15]. Kerpen kommt nirgends vor. Für beide müssten Schule, Schulform und, falls
vorhanden, der schulinterne Lehrplan angelegt werden. Ohne Plan greift heute der G9-Rückfall (5a).

---

## 6 · LSA-Prüfung neu (nur beschrieben)

### 6a · „Gezielt prüfen“ heute

- **Daten:** `pruef_ziel_liste` (`schema-erwartet.sql:14930`) liefert zwei Abschnitte:
  - `gezielt` aus `pruef_ziel_roh` (`:14990`)
  - `nachpruefen`: ready-Aufgaben, deren letzte Entscheidung nicht „passt“ ist (`:14971–14975`)
- **`pruef_ziel_roh`:**
  - nimmt **nur Skills, die die Regel nicht erfüllen** (`fehlt … where not r.erfuellt`, `:14995`)
  - wählt je neuem Textschlüssel einen Vertreter: geprüft vor Entwurf, Nicht-MC, Pilot, `sondierrang`
  - schlägt `rest + 1` Entwürfe vor
- **Hebel:** Die Liste verbindet die Vorschläge **per Inner Join** mit den Paketen der Schulen (`join hebel h`,
  `:14969`). **Skills, die in keinem Paket liegen, fallen also heraus.** Das trifft die 20 MSA-Skills außerhalb der
  Gymnasial-Pakete [Q07], z. B. `stoch_kenngroessen`, `geo_pythagoras_anwendung` und `fkt_exp_anwendung`.
- **Sortierung:** Fokus-Treffer, dann Schulen, dann Pakete, dann `skill_key` (`:14976`).
- **Oberfläche:** `src/pages/coach/pruefen/GezieltPruefen.tsx` gruppiert nach Thema (`zielGruppen`,
  `src/lib/pruefung/gezielt.ts:44–55`). Der Stand ist nur „offen = Σ rest, geprüft = Σ freigabe_ids“ (`:36–39`).
  Der Lauf in der Prüfansicht folgt `zielReihe` (`:7–12`).

**Was fehlt:**

1. **„n von m geprüft“ je Kompetenz:** Erfüllte Skills verschwinden aus `pruef_ziel_roh`. Die Liste bräuchte alle
   Skills des Ziels mit Soll (m = Regel N, + Reserve), Ist (n = Texte im Pool + Lenas „passt“) und Status. Der Wechsel
   wäre von „fehlt“ auf „Ziel-Menge“ mit `erfuellt` als Spalte, gruppiert nach Kompetenz (Spalte `kompetenzen` aus
   der MSA-Zuordnung bzw. Thema).
2. **Erledigtes mitführen:** Erledigt sind Skills mit `erfuellt = true` bzw. Aufgaben mit Lenas „passt“. Sie bleiben
   in der Gruppe, eingeklappt oder grau. Die Oberfläche filtert heute `rest > 0` (`GezieltPruefen.tsx:28`).
3. **Prüfziel „MSA (ZP10)“:**
   - Heute kennt die Liste nur Pakete (Schule × Klasse × Klassenarbeit). Dazu kommen `pruef_soll`-Anlässe aus dem
     alten Board (`batu_lsa`, `lsa_vorschau`, `batu_session`).
   - Vorschlag: ein Parameter `p_ziel` (`pakete` | `msa` | Anlass). Die Skill-Menge für `msa` kommt aus einer
     Tabelle `pruef_ziel_skill` (ziel, skill_key, kompetenz_id, soll_texte, teil). Die Daten aus
     `anhang/zuordnung.csv` passen genau in diese Form.
   - Der Hebel (Schulen, Pakete) entfällt für MSA. Sortiert wird dann nach Gewicht in der Prüfung bzw. nach Teil 1
     vor Teil 2.

### 6b · Was aus SP-1 wiederverwendbar ist

| SP-1 (Session-Prüfansicht) | wiederverwendbar für LSA? |
|---|---|
| zweigeteilte Ansicht: links Inhalt, rechts `RueckmeldungSpalte` (`src/components/edvance/pruefen/bauform/pruefansicht/RueckmeldungSpalte.tsx`), Bausteine `Abschnitt`/`Etikett` (`Bausteine.tsx`) | **ja**, die Spalte ist inhaltsneutral |
| Kommentar je Stelle: `src/lib/pruefung/bauformKommentar.ts` (Anker `grundgeruest`, `stufen`, `fehlbilder`, `beispiel`; Gründe je Anker) | **die Logik ja, die Anker nicht.** Eine LSA-Aufgabe hat die Anker Aufgabentext, richtige Antwort/Wertung, typische Fehler, Hinweise, Einordnung (Skill/AFB) und Rechner |
| Tabelle `bauform_kommentare` (`schema-erwartet.sql:26970`, CHECKs auf Anker und Bauform) | **nein, so nicht.** Sie hängt an `bauform_id`/`version`. Nötig ist ein Gegenstück `task_kommentare` (task_id, pruef_version, anker, gruende, text, status offen/erledigt, erledigt_notiz) oder eine Verallgemeinerung mit Zieltyp |
| ein Knopf: `bauform_pruefung_senden` (`:1593`) mit Kommentaren und Zeiten | **das Muster ja:** `pruef_entscheiden` (`:13580`) bekäme Kommentare statt Freitext/Gründe |
| Rückfrage → Überarbeitung → ohne zweite Prüfung zur Freigabe (automatischer Übergang nach erledigten Kommentaren, grüner Prüfmaschine und Blindlöser) | **teilweise:** Für LSA-Aufgaben gibt es keine gespeicherte Prüfmaschine (FR-0 §4, `tasks.pruefmaschine` leer). Der Übergang müsste sich auf „Kommentare erledigt + Gate `freigabe_gate_fehler`“ stützen. Den Status `rueckfrage` gibt es (2 LSA-Aufgaben) |
| Liste mit „n von m geprüft“ (`BauformListePage.tsx`, `bauformStand.ts`) | **ja**, als Vorbild für 6a |

**LSA-spezifisch** bleiben die Wertung je Schreibweise (`RegelUndTesten.tsx`, `pruef_wertung_testen`), die
Kinderansicht des einzelnen Items (`Kinderansicht.tsx`), der Rechner-Schalter (`TaschenrechnerSchalter.tsx`),
die Einordnung in Skill/AFB (`Einordnung.tsx`) und der Textschlüssel.

**Lena korrigiert LSA-Aufgaben heute selbst:**

- **Code:**
  - Sie bearbeitet den Entwurf in der Prüfansicht (`src/lib/pruefung/entwurf.ts`: `geaenderteFelder` `:118`,
    `lokaleAenderungen` `:133–164`).
  - Gespeichert wird über `pruef_speichern` (`schema-erwartet.sql:14705`). Die Funktion schreibt richtige Antworten,
    Wertung, typische Fehler, Hinweise, Skill, AFB und `sondierrang` direkt in `task_solutions` bzw. `tasks`.
  - Die Änderungen landen beim Entscheiden in `task_pruefungen.aenderungen`.
- **Nutzung [Q16]:** 38 von 174 LSA-Entscheidungen enthalten Änderungen (36 Aufgaben).
  - In 38 Fällen hat Lena den **Anforderungsbereich** geändert, in 6 die typischen Fehler.
  - Antworten, Wertung, Hinweise und Skill hat sie bisher nie selbst geändert.

---

## 7 · Empfehlung

**Reihenfolge der nächsten Bauaufträge**

1. **MSA-1 · LSA-Bestand bereinigen (Daten, klein).**
   - Rechner-Kennzeichen für die 30 Konflikte setzen.
   - Die 13 echt zu schweren Aufgaben archivieren (`is_active = false`), ebenso die nicht notwendigen nach der
     gewählten Regel (Liste aus `anhang/aufgabenliste.csv`).
   - `geo_kreis_zusammen` und `bruch_div` je 1–2 Texte schreiben.
   - Hängt nur an Gründerfrage 1 und 2.
2. **MSA-2 · LSA-Prüfung neu mit Prüfziel MSA.**
   - `pruef_ziel_skill` aus `zuordnung.csv`, `pruef_ziel_liste(p_ziel)` mit „n von m“ und Erledigtem.
   - Den Inner Join auf die Pakete lösen.
   - `task_kommentare` nach SP-1-Muster, Feld `hilfsmittel`.
   - Hängt an MSA-1 (Soll steht) und Gründerfrage 3. Schema-Änderung, also Consensus (§8).
3. **MSA-3 · Lena prüft das LSA-Soll.** Für Regel 2 sind es 213–330 Prüfungen, rund 2–11 h. Danach ist eine MSA-LSA
   für alle 122 Skills möglich. Das ist keine Bauarbeit, nur Prüfzeit.
4. **MSA-4 · MSA-Reihe.**
   - Zuerst die 4 neuen Figurengeneratoren mit dem größten Hebel: Dreieck, Körper, Kreis, Baumdiagramm.
   - Dann die Bauformen „Wiederholung“ in der Reihenfolge von 4c.
   - Hängt an Gründerfrage 4 und daran, dass Lena die 47 Bauformen der Reihe 1 geprüft hat (der Ablauf muss stehen).
   - Für Januar ist das knapp (4d).
5. **MSA-5 · Schulformen** (5c): Sekundarschule zulassen, `klp_themenplan` mit RS/GE 2004 und 2022, E-/G-Kurs am Kind,
   Pakete für Schulen ohne Plan. Das ist unabhängig von 1–4 und Voraussetzung für Kunden an Realschulen und
   Gesamtschulen. Auch hier Schema-Änderung, also Consensus.

**Fragen, die nur die Gründer entscheiden**

1. **Regel 2, 3 oder 4 Texte** je Skill, und gilt die Reserve? Regel 2 heißt 371 notwendige Aufgaben. Regel 4 (für die
   Wiederholungs-LSA) heißt 565, und 44 Texte müssten neu geschrieben werden.
2. **Archivieren oder löschen?** Die Empfehlung ist archivieren (3e).
3. **Darf Lena LSA-Aufgaben weiter selbst korrigieren?** Bisher hat sie fast nur den AFB geändert (38). Bleibt das
   erlaubt, oder geht alles als Kommentar an den Autor wie bei SP-1?
4. **Umfang der MSA-Reihe:** Wiederholung (146 Bauformen, ca. 17–29 h Lena) oder voll (241, ca. 28–48 h)? Start im
   Januar mit 16 Sessions, oder später mit weniger?
5. **Zielgruppe:** Bleibt die externe Kommunikation „Gymnasium Klasse 8–10“, oder kommen Realschule und
   Gesamtschule dazu? Das entscheidet, ob MSA-5 vor MSA-4 kommt.
6. **Prüfungsarbeiten 2024–2026 beschaffen** (Schulzugang oder Verlagsband)? Ohne sie bleiben die Gewichtung (4c)
   und die Spalte „Teil 2“ geschätzt.
7. **„Zu leichte“ freigegebene Aufgaben** (32): bleiben sie für Klasse 8, oder sollen sie in der MSA-LSA nicht
   gezogen werden? Das ginge über das Prüfziel, nicht über Archivieren.

---

## 8 · Nachprüfung durch einen frischen Subagenten

Ein frischer Subagent ohne Kontext hat 45 Zahlen mit [Qnn] aus den Abschnitten 2–4 gesammelt und 5 davon mit
`shuf -n 5` gezogen. Alle fünf hat er per `dbread` mit der Anhang-Abfrage nachgerechnet, drei davon zusätzlich mit
einer eigenen Abfrage direkt auf den Tabellen. **Keine Abweichung.**

| Nr. | Fundstelle | Bericht | Anhang-Abfrage | eigene Abfrage | Ergebnis |
|---|---|---|---|---|---|
| 1 | 3d, `task_admin_protokoll` | 270 / 223 / 186 | Q10: gleich | Plausibilität: 458 LSA-Aufgaben mit Protokoll | gleich |
| 2 | 2, Freigabewellen | 74 / 60 / 34 | Q03/Q04: gleich | `reviewed_at` je Tag (Berlin): 39+34+1, 60, 34 | gleich |
| 3 | 3d, `task_reviews` | 13 / 12 / 11 | Q10: gleich | genau 13 LSA-Aufgaben haben ein Review | gleich |
| 4 | 3a, notwendig bei Regel 3 | 476 | Q07: 371 + 105 | Kontrolle 894 − 418 = 476 | gleich |
| 5 | 2, von Lena geprüft (passt) | 163 (135) | Q04: gleich | letzte Lena-Entscheidung: 135 passt + 28 unsicher | gleich |

Hinweise des Prüfers:

- „Lena“ ist `profiles.full_name = 'Lena Klever'`. Mit Prüfungen irgendeines Prüfers sind es 164 LSA-Aufgaben;
  dazu kommt eine Entscheidung eines Testkontos (wie FR-0 Q03).
- 163 steht zweimal im Bericht, als „fehlende Texte“ und als „von Lena geprüft“. Die Gleichheit ist Zufall.
- Die Freigabewellen in Q03 schneiden nach `reviewed_at::date` in UTC. Bei den heutigen Daten macht das keinen
  Unterschied, Freigaben nach 22 Uhr Berliner Zeit würden aber auf den Folgetag fallen.
- Eine Aufgabe, deren letzte Lena-Entscheidung `zurueckgenommen` ist, zählt in `lena_letzte` als eigener Wert, nicht
  als „passt“. In Q03/Q04 ändert das nichts.

---

## Anhang

| Datei | Inhalt |
|---|---|
| `abfragen/msa_basis.sql` | Zuordnung als `values`, Pool, Regel, LSA-Aufgaben mit Lenas letzter Entscheidung |
| `abfragen/soll.sql` | Auswahlregel „notwendig“ (Abschnitt 3c) |
| `abfragen/lauf.sh` | Ausführen: `./lauf.sh 07` (read-only über `~/bin/dbread`) |
| `abfragen/q01` … `q20` | Q01 Skills · Q02 Zählung · Q03 LSA je Skill · Q04 Gruppen · Q05 Niveau-Export · Q06 Taschenrechner · Q07 Soll · Q08 Selbstprüfung · Q09 nicht notwendig · Q10 Verweise · Q11 Lenas Zeit · Q12 Bauformen je Skill · Q13 Themen ohne Bauform · Q14 Schulen · Q15 Schulform Leads/Kinder · Q16 Lenas Korrekturen · Q17 Aufgabenliste · Q18 Thema × Klasse · Q19 Bauform-Stand · Q20 Pakete nach Quelle |
| `anhang/ergebnisse/qNN.txt` | Ausgaben vom 12.11.2026 |
| `anhang/zuordnung.csv` | Kompetenz → Skills, Teil, Belege |
| `anhang/aufgabenliste.csv` | 894 LSA-Aufgaben: notwendig je Variante, Grund |
| `anhang/niveau-eingabe.json`, `niveau-urteil.json`, `niveau-nicht-passend.csv` | Niveau-Prüfung |
| `quellen/` | amtliche Vorgaben und KLP, `README.md` mit Fundstellen |
