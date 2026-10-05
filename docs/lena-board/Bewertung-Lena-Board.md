# Bewertung — Anforderung „Aufgaben prüfen“ (Lena-Board) gegen Code und Datenmodell

**Für:** Rasit, Tolunay, Ashkan · **Datum:** 04.10.2026
**Geprüft:** `Anforderung-Lena-Board.md` und `lena-board-dummy.html` gegen Edvancev1, Branch `dev` (Stand `93fb3d6`, 04.10.2026), Schema-Abzug `supabase/schema-erwartet.sql`. Ohne Datenbankzugriff: Zahlen zum Bestand stammen aus den Migrationen, nicht aus Prod.

## Kurzfazit

Das Konzept trägt. Für den Piloten reicht der Dummy fast, damit Lena eine Aufgabe ganzheitlich prüfen und auf „zur Freigabe“ setzen kann. An vier Stellen passt er aber nicht zum Datenmodell:

1. **Thema:** Die LSA zieht Aufgaben über die Fertigkeit (`skill_key`), nicht über das Thema. Lena darf die Fertigkeit heute nicht ändern.
2. **Typische Fehler:** Die Diagnose nutzt `acceptance.known_errors` (Wert → Fehlbild) mit gemeinsamen Fehlbild-Texten. Die heutige Pflege zeigt eine andere Liste, die die Engine gar nicht liest.
3. **Richtige Antwort:** Sie steht zweimal in der Datenbank. Heute schreibt der Editor nur eine davon.
4. **Wertungsregeln:** Zahl, Liste und Toleranz kann die Engine. Gleichwertige Terme, asymmetrische Bereiche und Regeln für Teilaufgaben kann sie nicht.

Vieles, was die Anforderung als neu beschreibt, gibt es schon: das Prüfrecht am Coach-Konto, „zur Freigabe“ durch Lena, Beanstanden, das Freigabe-Gate, den VERA-8-Ausschluss und die Sammelfreigabe je Thema.

## Was Lena prüfen und ändern können muss

| Feld im Dummy | Wo es liegt | Nutzt die LSA es? | Bewertung |
|---|---|---|---|
| Richtige Antwort, einteilig | `task_solutions.acceptance` (`canonical` + `equivalents`) **und** `correct_answers` | Ja. Das Urteil kommt aus `acceptance`, die Antwortzeile und das Gate aus `correct_answers`. | Behalten. Beide Listen immer gemeinsam schreiben (siehe Abschnitt „Live-Fehler“). |
| Richtige Antwort je Teilaufgabe | `correct_answers` als `{"1":[…],"2":[…]}` | Ja, aber nur als Textvergleich | Behalten. „Gleicher Zahlenwert“ und Bereich wirken hier nicht. Lena muss jede Schreibweise eintragen, wie im Dummy bei „3“ / „3 °C“. |
| Multiple Choice | `correct_answers` | Ja | Passt. |
| Tabelle | keine Tabellenaufgaben in den Chargen | — | Für den Piloten streichen. |
| Term (Musterantwort) | `correct_answers`, reiner Textvergleich | Ja | Der Satz „Das System erkennt gleichwertige Schreibweisen selbst“ stimmt heute nicht. In den Chargen gibt es keine Term-Aufgaben. |
| Gewertet wird | `acceptance.tolerance`, `notation`, `unit_graded`, `require_reduced` | Ja, bei einteiligen Aufgaben | Teilweise machbar, siehe Frage 1. |
| Lösungsweg | `task_solutions.solution` | Nein. In LSA, Report und Coach-Sicht liest ihn niemand. | Nur als Prüfhilfe für Auffälligkeit 1 sinnvoll. Vorschlag: lesend zeigen, nicht pflegen. |
| Typische Fehler | `acceptance.known_errors` (`{falscher Wert: fehlbild-slug}`) + `fehlbild_labels.klartext` | Ja: Fehlbild-Erfassung, LSA-Auswertung, Eltern-Report | Behalten, aber umbauen (siehe Abschnitt 2 unten). |
| Klasse (Stufe) | folgt aus `skill_key` → `skill_thema` → `themen.stufe` | indirekt | Nicht frei wählbar. Sie ergibt sich aus der Fertigkeit. |
| Thema | folgt aus `skill_key` (genau ein Heimat-Thema je Fertigkeit) | Ja, die Auswahl läuft über `skill_key` | Umbauen (siehe Abschnitt 1 unten). |
| Zeit fürs Kind | `tasks.est_duration_sec` | Nein. Nur der alte Modus „fest“ nutzt sie, Standard ist „adaptiv“. Pflicht ist sie nur bei mehrteiligen Aufgaben (CHECK). | Vorschlag: aus Lenas Ansicht nehmen. Vorbefüllt reicht. |
| Anforderungsbereich | `tasks.afb` | Nur im Gate und in der AFB-Aufstellung von `lsa_finish` | Behalten, kostet Lena wenig. |
| Jahrgang 5–9 (heute) | `tasks.curriculum_grade` | Nein, nur das Gate verlangt ihn | Aus der Fertigkeit ableiten oder aus dem Gate nehmen. Aus Lenas Ansicht fällt er so oder so raus. |
| Leitidee/Cluster (heute) | `cluster_id`, `competency_content` | Nein, nur Modus „fest“. `cluster_id` verlangt das Gate. | Bleibt vorbefüllt, nicht in Lenas Ansicht. |

**Fehlt im Dummy:**

- **„Teilweise“:** `lsa_grade` kennt drei Stufen. Eine Antwort ist „teilweise“ richtig, wenn die Zahl stimmt, aber die geforderte Einheit fehlt oder ein Bruch nicht gekürzt ist. „Antwort ausprobieren“ braucht diese dritte Anzeige.
- **Einheit:** Ob die Einheit mitgewertet wird (`unit_graded`), ist Teil der Regel. Der Dummy listet „3“ und „3 °C“ als zwei Antworten. Bei einteiligen Aufgaben kann das die Regel übernehmen.

## Live-Fehler, unabhängig vom Lena-Board

Der Editor speichert die Lösung über `task_solution_upsert`, aber nur `correct_answers`, `solution`, `hints`, `coach_hints` und `typical_errors` (`src/lib/supabase/taskAuthoring.ts:267-285`). `acceptance` schreibt er nicht.

Das Urteil der LSA kommt bei einteiligen Aufgaben aber aus `acceptance` (`lsa_grade`). Laut Migrationen haben etwa 430 einteilige Aufgaben aus den Chargen ein `acceptance`. Korrigiert jemand dort im Editor die richtige Antwort, etwa −24 → 24, zählt die Antwortzeile 24 als richtig, das Urteil wertet aber weiter nach −24.

## Antworten auf die technischen Fragen 1–13

**1 · Wertung**

- `lsa_grade` (einteilig) kann:
  - Liste (`canonical` + `equivalents`);
  - mathematischen Zahlvergleich: Bruch = Dezimalzahl, 1,5 = 1,50 = 3/2;
  - Toleranz, absolut oder auf Nachkommastellen. Absolut entspricht einem **symmetrischen** Bereich (65–75 = 70 ± 5);
  - Einheit optional oder mitgewertet;
  - „Bruch muss gekürzt sein“, sonst „teilweise“.
- Sie kann nicht:
  - gleichwertige Terme. TERM ist ein reiner Textvergleich, und ein `acceptance` an TERM-Aufgaben verbietet ein Trigger;
  - asymmetrische Bereiche;
  - Regeln für Teilaufgaben. Dort gilt nur die Textliste aus `lsa_is_correct`.
- Ausprobieren geht ohne zweite Implementierung. `lsa_grade` ist eine reine Funktion und nimmt die Regel als Parameter. Ein dünner RPC kann deshalb auch Lenas **ungespeicherten** Entwurf werten.
- Achtung: Die Antwortzeile (`lsa_responses.correct`) und damit die Fehlbild-Erfassung laufen über `correct_answers`. Das Urteil läuft über `acceptance`. Sind die Listen nicht gleich, widersprechen sich beide.

**2 · Typische Fehler**

- Sie sind hinterlegt, in `acceptance.known_errors`, bei Teilaufgaben je Teil unter „1“, „2“. Die Chargen k8, k9 und k10 tragen sie.
- Die Engine nutzt sie: `lsa_fehlbild_capture` → `lsa_fehlbild_auswertung` / `lsa_fehlbild_report` → Report.
- Die Beschreibung steht einmal je Fehlbild in `fehlbild_labels` (Klartext, Erklärung, Freigabe), nicht je Aufgabe.
- TERM-Aufgaben können keine typischen Fehler haben, weil sie kein `acceptance` tragen dürfen.
- `task_solutions.typical_errors` ist Freitext, und die Engine liest ihn nicht. Genau dieses Feld zeigen heute Editor und Pflege.

**3 · Einordnung**

- Die adaptive Auswahl (Standard) nutzt nur `skill_key`, `status` und `sondierrang`.
- Thema und Stufe folgen aus `skill_thema`: genau ein Heimat-Thema je Fertigkeit.
- `afb` steht nur in der Aufstellung von `lsa_finish`.
- `est_duration_sec`, `cluster_id` und `competency_content` nutzt nur der alte Modus „fest“.
- `curriculum_grade` prüft nur das Gate in `task_status_set`.

**4 · Lösungsweg:** In der LSA liest ihn niemand. Er wird nur über `task_solution_get` in der Pflege gelesen.

**5 · Folgefehler:** Nein. Bei mehrteiligen Aufgaben macht ein falscher Teil die ganze Aufgabe zu „nicht“.

**6 · Freitext, Begründen, Zeichnen:** Diese Aufgaben sind nicht wertbar. Die adaptive Auswahl filtert nicht nach Aufgabentyp, der einzige Schutz ist der Status. In den Chargen gibt es keine solchen Aufgaben. Der Vorschlag „nicht im Board“ passt.

**7 · Prüfrecht**

- Es existiert schon als `profiles.darf_pruefen` mit `darf_pruefen()` (Coach + Flag). Damit kann Lena heute:
  - auf `review` setzen;
  - beanstanden;
  - die Lösung schreiben;
  - Aufgaben ändern (RLS `pruefer_update_tasks`).
- „Nur-Lese-Modus“ im Testsystem heißt mit hoher Wahrscheinlichkeit: Das Flag ist am Konto nicht gesetzt. Der Text in `authoring.json` ist veraltet. Bitte per `dbread` prüfen.
- Heute zu weit:
  - Lena darf Aufgabentext (ohne Zahlen), Aufgabentyp, MC-Optionen (`question_payload`), Teilaufgaben und Bilder ändern;
  - jeder Coach kommt per Adresse in `/admin/authoring`, denn die Route prüft nur die Rolle.
- Heute zu eng: `skill_key` sperrt `tasks_pruefer_guard`.
- Eine Kachel im Coach-Dashboard fehlt.

**8 · Status:** `draft` = Offen, `review` = Passt, `ready` = Freigegeben, `beanstandet` = Passt nicht. Eine Rückfrage gibt es nicht. `task_reviews.kategorie` hat sieben andere Kategorien als die neuen Gründe; der CHECK muss erweitert werden. Eine Entscheidung ergibt dann mehrere Zeilen, eine je Grund.

**9 · Vorbefüllung einfrieren:** Ja, das ist nötig.

- `tasks.vorbefuellt` speichert je Feld nur Art und Grund. Werte lehnt `vorbefuellt_valid` ausdrücklich ab (`alt`, `wert`, `neu`).
- Die Vorbefüllungswerte liegen nur im Repo (`docs/prefill/*.json`). Die Snapshots dort zeigen den Stand **vor** der Vorbefüllung.

**10 · Kurztitel:** Aus `title` ableiten. Muster: „AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm“ → Präfix „AFB I ·“ abschneiden. Kein neues Feld nötig.

**11 · Gleichzeitige Bearbeitung:** Es gibt keine Versionsprüfung. `tasks` hat nicht einmal `updated_at`. Eine Versionsspalte mit Trigger ist nötig.

**12 · Auffälligkeiten**

- Sie gehören auf den Server, über `lsa_grade`.
- Billig zu haben:
  - typischer Fehler würde als richtig gewertet;
  - `canonical` steht nicht in `correct_answers` (die Listen laufen auseinander);
  - „Bild nötig“ ohne Bild.
- Der Lösungsweg-Check braucht Textparsing und ist fehleranfällig.
- Für „Ableseaufgabe“ gibt es kein Merkmal. Ableitbar wäre es aus `task_figures.generator = 'koordinatensystem'`.

**13 · Mängel**

- `src/lib/authoring/flags.ts` hat 24 Prüfungen. Blockierend sind unter anderem Stamm, Typ, Cluster, Stoffanker, AFB, Lösung, MC-Optionen, Alt-Text und Teilaufgaben.
- „Bild nötig, aber kein Bild“ gibt es nicht. Die Prüfung muss `assets` **und** `task_figures` ansehen.
- Der Filter ist einfach. Das Board schließt VERA-8 schon heute clientseitig aus.

## Korrekturen für den Bauauftrag

**1 · Thema → Fertigkeit**

- Ein Thema hat mehrere Fertigkeiten. Wählt Lena nur ein Thema, weiß das System nicht, welche Fertigkeit gemeint ist.
- Vorschlag: Lena sieht Klasse, Thema **und** Fertigkeit (`skills.label`).
- Passt die Einordnung nicht, wählt sie eine andere Fertigkeit aus derselben Liste. Die Aufgabe geht dann als „Passt · geändert“ an die Admins. Den Guard für `skill_key` nur über die neue Prüf-RPC öffnen, nicht über direktes Update.
- Alternative ohne Rechteänderung: Einordnung falsch → „Unsicher“ mit Vorschlag.

**2 · Typische Fehler**

- Eine Zeile zeigt den falschen Wert und den Klartext des Fehlbilds. Mehrere Schreibweisen desselben Werts werden zusammengefasst, die Chargen tragen etwa „3,2“, „+3,2“ und „3.2“ getrennt.
- Entfernen geht.
- Ergänzen geht nur mit einem bestehenden Fehlbild aus der Liste. Die Beschreibung ist nicht frei je Aufgabe, denn sie ist elternsichtbar und gilt für alle Aufgaben.
- Ein neues Fehlbild läuft über „Unsicher“.

**3 · Richtige Antwort**

- Bei einteiligen Aufgaben schreibt eine Änderung `canonical`/`equivalents` **und** `correct_answers` in einem Schritt.
- Den Editor-Fehler oben gleich mit beheben.

**4 · Wertung im Piloten**

- Im Piloten:
  - „genau diese Werte“;
  - „Bereich“ als Mitte ± Toleranz (Ränder symmetrisch);
  - der automatische Zahlvergleich.
- Term-Regel und Tabelle fallen aus dem Piloten.
- Die ⓘ-Texte zu „Gewertet wird“ und „Thema“ anpassen.
- „Antwort ausprobieren“ zeigt drei Stufen.

**5 · Zeit und Lösungsweg:** Zeit aus Lenas Ansicht. Lösungsweg nur lesend als Prüfhilfe.

**6 · Rechte**

- `tasks_pruefer_guard` für Prüfer schärfen: kein Text, kein Typ, kein `question_payload`, keine `parts`-Struktur, keine `assets`.
- Route und Kachel an `darf_pruefen` binden.
- Den veralteten Nur-Lese-Text ersetzen.

**7 · Neu bauen**

- Status oder Zustand „Rückfrage“.
- Prüfprotokoll: Gründe, Notiz, Dauer, vorher → nachher, Grund.
- Kopie der Ausgangswerte.
- Versionsprüfung.
- Mängel-Ausschluss inklusive Bild.

**8 · Sammelfreigabe:** Gibt es schon (`freigabe_thema`, nimmt alle `review` eines Themas). Sie muss nur „geändert“ und Rückfragen auslassen. Das beantwortet Frage 18 technisch.

## Vorschlag Datenmodell (Paket L1)

- **`tasks.status`** bekommt `'rueckfrage'` (CHECK und `task_status_set`). „Passt nicht“ bleibt `beanstandet`.
- **Neue Tabelle `task_pruefungen`**, eine Zeile je Entscheidung. Lesen dürfen Admins und Lena, schreiben nur die RPC.

  | Spalte | Inhalt |
  |---|---|
  | `task_id` | Aufgabe |
  | `entscheidung` | passt, unsicher, passt_nicht |
  | `gruende` | `text[]` |
  | `notiz` | Text |
  | `dauer_sek` | Prüfdauer |
  | `aenderungen` | `jsonb`: Feld, vorher, nachher |
  | `aenderung_grund` | Text |
  | `geprueft_von`, `geprueft_am` | wer, wann |

- **`tasks.pruefung_ausgang jsonb`:** die eingefrorene Kopie beim ersten Öffnen. Sie bedient ↺ und vorher → nachher.
- **`tasks.version int`** mit Trigger.
- **RPC `pruefung_entscheiden(task_id, version, entscheidung, …, aenderungen)`:** schreibt Felder, Lösung (beide Listen), Status und Protokoll in einer Transaktion. Bei abweichender Version lehnt sie mit „Die Aufgabe wurde inzwischen geändert. Bitte neu laden.“ ab.
- **RPC `wertung_testen(task_id, teil, antwort, regel_entwurf)`:** ruft `lsa_grade` bzw. `lsa_is_correct` mit dem Entwurf auf. Eine Wertung, keine Kopie.

## Hinweis Pilot

Die ersten 100 Aufgaben am besten aus den neuen Chargen ziehen (k8/k9/k10). Sie sind einheitlich: Zahl, mehrteilig und MC, alle mit `acceptance` und typischen Fehlern. Term- und Tabellenaufgaben kommen dort nicht vor.
