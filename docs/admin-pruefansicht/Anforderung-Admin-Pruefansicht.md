# Anforderung — Admin-Prüfansicht und Sammelaktionen (ersetzt die Pflege-Strecke)

**Autor:** Rasit (mit Claude) · **Datum:** 05.10.2026 · **Fassung:** 1.1 (Entscheidungen Rasit eingearbeitet) · **Planungsstand:** Edvancev1 `dev` 139da80 · **Anlage:** Klick-Dummy `admin-pruefansicht-dummy.html`

> Grundlage: Lena-Board (PR 208, `docs/lena-board/entscheidungen.md`, `offene-punkte.md`), Admin-Hülle H1–H4b (PR 205–210) und eine Durchsicht des Codes auf `dev`. Dieses Dokument ersetzt die Pflege-Strecke (`/admin/pflege`) für Admins. Lenas Prüfansicht bleibt, wie sie ist.

## Titel

Admins prüfen eine Aufgabe auf demselben Bildschirm wie Lena: links die Kinderansicht, rechts die Prüfkarte. Dazu kommen Lenas Ergebnis und eine eigene Entscheidungsleiste mit **Freigeben**, **Zurück an Lena** und **Zurückweisen**. Was die Prüfkarte nicht kann, öffnet der **Editor**, und danach geht es an dieselbe Stelle zurück. In der Expertenliste lassen sich **mehrere Aufgaben auswählen** und gemeinsam bearbeiten, mit Vorschau. Die Pflege-Strecke entfällt.

## Warum

- **Die Pflege-Strecke ist veraltet.**
  - Fünf Schritte: Lesen, Stoffanker, Bilder, Lösung, Freigabe.
  - Die Lösung ist dort nur lesbar, die Einordnung folgt noch dem alten Modell.
  - Sie schreibt direkt in `tasks` statt über die protokollierten `pruef_*`-Funktionen.
  - Lenas Ergebnis (Änderungen, Gründe, Frage) zeigt sie nicht.
- **Zwei Hüllen um dieselben Teile.** Lena hat seit PR 208 eine Prüfansicht auf einem Bildschirm. Wenn Admins mit einem anderen Werkzeug arbeiten, sehen sie etwas anderes als Lena und pflegen doppelten Code.
- **Menge.** Im Board sind 859 Aufgaben, der Pilot hat 100. Freigeben geht heute nur einzeln oder je Thema (`freigabe_thema`), den Pilot gibt es nur je Aufgabe (`setPruefPilot`), Fertigkeit und Anforderungsbereich nur einzeln. Für Korrekturen über viele Aufgaben fehlt ein Werkzeug.
- **Wege.** Heute springen Admins zwischen Board, Expertenliste, Editor, Strecke und Lenas Ansicht. Künftig gibt es einen Arbeitsplatz für eine Aufgabe und einen für viele.

## Wer macht das

| | Admin (Rasit, Tolunay, Ashkan) | Lena (Coach mit Prüfrecht) | Coach |
|---|---|---|---|
| Admin-Prüfansicht `/admin/pruefen/:taskId` | ja | nein | nein |
| Freigeben, Zurück an Lena, Zurückweisen, Freigabe zurücknehmen | ja | nein | nein |
| Sammelaktionen in der Expertenliste | ja | nein | nein |
| Editor (Expertenmodus) | ja | nein | nein |
| Lenas Prüfansicht `/coach/pruefen/:taskId` | ja (wie heute) | ja | nein |

Die Rechte gelten in der Datenbank, nicht nur in der Oberfläche. Jede neue Funktion prüft `get_my_role() = 'admin'`.

## Wo im System

- **Eine Aufgabe:** `/admin/pruefen/:taskId`. Eine Fokusseite ohne Menüleiste wie bisher die Pflege-Strecke. Admin-Rahmen: `AdminLayout`/`AppShell`.
- **Viele Aufgaben:** Expertenliste `/admin/authoring/liste` mit Mehrfachauswahl und Sammelleiste.
- **Einstiege in die Admin-Prüfansicht** (ersetzen alle Einstiege in `/admin/pflege`):
  - **Expertenliste:**
    - Klick auf eine Zeile öffnet die Aufgabe.
    - „Durchlauf starten“ geht über alle Aufgaben im Filter.
    - „Ausgewählte prüfen“ geht über die Auswahl.
  - **Item-Pflege-Board:** „Durchlauf“ je Thema oder über alles im Filter.
  - **Content-Gesundheit:** Durchlauf über einen Mangel.
  - **Startseite „Heute“:** die Liste „Rückfragen“ öffnet die Rückfrage direkt.
  - **Lenas Prüfansicht** (als Admin): der Link „In Admin-Prüfansicht öffnen“ ersetzt „Im Expertenmodus öffnen“.

## Ist-Zustand (`dev` 139da80)

1. **Pflege-Strecke** `/admin/pflege`:
   - Dateien: `PflegeWizardPage.tsx` (393 Zeilen) und `components/edvance/authoring/wizard/*`.
   - Schritte: `read`, `anchor`, `images` (nur bei Bildbedarf), `solution`, `release`.
   - Speichern: pro Schritt über `updateAuthoringTask` (direkt `tasks`), den Status über `task_status_set`.
   - Reihe in `wizardQueue`. Der Rückweg aus dem Editor läuft über `?pflege=<schritt>` (`usePflegeRueckweg`).
   - Einstiege: Expertenliste, Board (`kontext: 'board'`), Content-Gesundheit.
2. **Lenas Prüfansicht** `/coach/pruefen/:taskId`:
   - Admins kommen hinein, weil `darf_pruefen()` für admin wahr ist. Sie sehen aber Lenas Leiste mit Passt, Unsicher und Passt nicht.
   - Für admin gibt es den Link zum Editor (`PruefansichtPage.tsx` Z. 225).
3. **Speichern in der Prüfkarte** läuft über `pruef_speichern` → `pruef_sperren`. Das sperrt heute **auch für Admins**:
   - freigegebene Aufgaben (`freigegeben`),
   - die Ausschlüsse `vera8`, `inaktiv` und `typ`,
   - Aufgaben außerhalb des Piloten, solange `nur_pilot` an ist,
   - vom Team beanstandete Aufgaben (`team_beanstandet`).
4. **Expertenliste:**
   - Lädt alle Aufgaben und filtert im Client (`itemFilter.ts`). Es gibt Filter für Status (inkl. `rueckfrage`) und „Nicht bei Lena“.
   - `LenaInfo` unter der Zeile zeigt Lenas Ergebnis und die Rückfrage-Klärung (`pruef_rueckfrage_klaeren`: freigeben, zurueckweisen, an_lena).
   - Eine Mehrfachauswahl gibt es nicht.
5. **Freigabe:**
   - Einzeln über `task_status_set(…, 'ready')`, mit Gate `freigabe_gate_fehler`.
   - Je Thema über `freigabe_thema`. Das nimmt nur Aufgaben, bei denen `pruef_freigabe_erlaubt` gilt: Lena „Passt“, keine Änderungen, keine Admin-Beanstandung, Fassung gleich Ausgangsfassung.
6. **Zurück an Lena** gibt es nur aus der Rückfrage (`an_lena`: Status `draft`, Ausgangsfassung gelöscht).
7. **„Nicht bei Lena“** wird nur berechnet (`pruef_ausschluss`: vera8, inaktiv, typ, ohne_fertigkeit, ohne_loesung, gate, bild_fehlt). Von Hand ausschließen geht nicht.
8. **Pilot** wird je Aufgabe über `setPruefPilot` gesetzt (Karte `PruefEinstellungenKarte`). `nur_pilot` ist global an (100 Aufgaben).
9. **Bekannter Fehler:** In `freigabe.ts` und `taskAuthoring.ts` verliert `supabase.rpc` sein `this`. Ohne Fix scheitern `getDarfPruefen` und damit alle Seiten mit Prüfrecht. Laut Rasit ist der Fix auf `dev`; auf GitHub stand `dev` am 05.10. 14:40 noch auf 139da80. Der Bauauftrag prüft das zuerst.

## Soll-Zustand

### A — Leitsätze

1. **Eine Prüfansicht für alle.** Kinderansicht und Prüfkarte sind dieselben Bausteine wie bei Lena (`components/edvance/pruefen/*`). Admins bekommen den Block „Lenas Ergebnis“, die Befunde vor der Freigabe und eine eigene Entscheidungsleiste.
2. **Lenas Arbeit bleibt sichtbar.** Status, Änderungen (vorher → nachher), Gründe oder Frage, Dauer, Antwort vom Team. Nichts davon wird beim Öffnen überschrieben.
3. **Was die Prüfkarte nicht kann, macht der Editor.** Das sind Aufgabentext, Typ, MC-Optionen, Teilaufgaben, Einheit, Bilder und Stoffanker. Vom Editor geht es immer zurück an dieselbe Aufgabe in derselben Reihe.
4. **Sammelaktionen nur für Felder, die man ohne Blick auf die einzelne Aufgabe verantworten kann.** Jede Sammelaktion zeigt vorher, was sie trifft und was sie warum auslässt. Danach ist jede Aufgabe genau so protokolliert wie bei einer Einzeländerung.
5. **Eine Regel, ein Ort.** Was eine Aktion auslässt, entscheidet der Server. Vorschau und Ausführung laufen durch denselben Code.
6. **Laptop und iPad.** Alles geht mit Antippen, Tastenkürzel sind Komfort.

### B — Admin-Prüfansicht: Aufbau

7. **Route** `/admin/pruefen/:taskId`, nur admin (`ProtectedRoute` mit Rolle, kein Rollen-Check in der Page). Die Fokusseite füllt die ganze Breite, ohne Menüleiste.
8. **Kopf** (Bausteine von `PruefKopf`):
   - Kopfzeile wie bei Lena: Stufe · Lernstandsanalyse Mathe · Erlaubt: ⟨Hilfsmittel⟩ ⓘ.
   - Überschrift: Kurztitel der Aufgabe, darunter Thema · Fertigkeit.
   - **Reihe:** woher sie kommt und die Position, zum Beispiel „Expertenliste · Filter: Rückfrage · 3 von 12“ oder „Lineare Funktionen · 4 von 30“. Ohne Reihe (direkter Link) entfällt die Position.
   - **Knöpfe:** „‹ Zurück“, „Überspringen ›“, „Im Editor öffnen“, „Schließen“.
     - „Schließen“ führt an die Stelle zurück, von der die Reihe kam: Expertenliste mit Filter, Auswahl und Scrollposition, Board mit offenem Thema, Content-Gesundheit oder Heute.
   - **Pilot-Schalter:** „Im Pilot“ an/aus über `setPruefPilot`. Er erscheint nur, wenn die Aufgabe bei Lena erscheinen kann.
9. **Block „Lenas Ergebnis“** über der Prüfkarte. Er hält immer die gleiche Reihenfolge:
   - **Status als Marke:**
     - Offen · Passt · Passt · geändert · Unsicher (Rückfrage) · Passt nicht · Vom Team beanstandet · Freigegeben.
     - Wenn Lena die Aufgabe nicht sieht: „Nicht bei Lena: ⟨Grund⟩“ (Texte aus `lena.ausschluss.*`).
   - Geprüft von, am, Dauer.
   - **Je nach Status:**
     - Rückfrage: Lenas Frage im Wortlaut.
     - Passt nicht: Gründe und „Was genau?“.
     - Mit Antwort vom Team: die Antwort, von wem, wann.
   - **Lenas Änderungen** (aus `task_pruefungen.aenderungen`): Liste vorher → nachher mit „Kurz warum?“. Ab drei Einträgen ist sie zugeklappt.
   - **Noch nicht geprüft:** „Lena hat diese Aufgabe noch nicht geprüft.“
10. **Kinderansicht links:** unverändert (`Kinderansicht`, `task_preview_payload`, „Bild vergrößern“, Satz zum Antworttyp). Ab Laptop-Breite bleibt sie beim Scrollen stehen.
11. **Prüfkarte rechts:** dieselben Abschnitte wie bei Lena (Auffälligkeiten, Richtige Antwort, Gewertet wird, Antwort ausprobieren, Lösungsweg, Typische Fehler, Einordnung, Änderungen).
    - **Admins dürfen hier alles, was Lena darf.** Gespeichert wird über `pruef_speichern`, mit derselben Versionsprüfung (ED409) und demselben Protokoll.
    - **Neben jedem Abschnitt** steht rechts der kleine Link „im Editor“. Er öffnet den Editor an der passenden Stelle (siehe D).
    - **„geändert ↺“** zeigt wie bei Lena die Abweichung von der Ausgangsfassung. Darin stecken Lenas und eigene Änderungen.
    - **Herkunft je Änderung:** Die Liste unter „Änderungen“ markiert einen Eintrag mit „Lena“, wenn derselbe Eintrag (Feld, Teil, nachher) in Lenas letzter Entscheidung steht (`task_pruefungen.aenderungen`), sonst mit „Team“. Dafür braucht es keine neue Spalte.
    - **Verlauf:** Unter der Prüfkarte steht zugeklappt der „Verlauf“ der Admin-Aktionen an dieser Aufgabe (wann, wer, Aktion, Grund, „Sammelaktion“), aus dem Admin-Protokoll (Daten, Punkt 7).
12. **Wann die Prüfkarte nur lesbar ist.** Sie zeigt dann oben einen Hinweis mit dem Weg:
    - **Freigegeben:** „Freigegeben am ⟨Datum⟩ von ⟨Name⟩. Zum Ändern erst die Freigabe zurücknehmen oder im Editor öffnen.“
    - **Ausschluss `vera8`, `typ`, `inaktiv`:** „Diese Aufgabe lässt sich hier nicht bearbeiten (⟨Grund⟩). Im Editor öffnen.“ Die Kinderansicht und die Entscheidungsleiste bleiben.
    - **Außerhalb des Piloten und bei „Vom Team beanstandet“ ist die Karte für Admins nicht gesperrt.** Dafür braucht `pruef_sperren` einen Admin-Zweig (siehe Daten, Punkt 1).
13. **Befunde vor der Freigabe** (übernimmt die Prüfungen der Pflege-Strecke):
    - **Inhalt:** ein eigener Kasten über Lenas Auffälligkeiten, nur für Admins, Überschrift „Vor der Freigabe klären“.
      - Er listet die sperrenden Befunde aus `freigabe_gate_fehler` und die blockierenden Flags aus `computeFlags`: Stoffanker fehlt, Bild fehlt, toter Bildpfad, Pflichtfeld leer.
      - Jeder Befund hat den Link „im Editor beheben“, der an die passende Stelle springt.
    - **Nur Hinweise:** Nicht blockierende Flags stehen zugeklappt darunter („2 Hinweise“).
    - **Leer:** Ohne Befunde erscheint der Kasten nicht.

### C — Admin-Prüfansicht: Entscheidungsleiste

14. **Leiste unten, immer sichtbar.** Links steht ein Infotext, rechts stehen höchstens zwei Knöpfe und ein „…“-Menü. Das ist dasselbe Muster wie die Rückfrage-Karte (OP-11).
15. **Knöpfe nach Status:**

| Status | Primär | Sekundär | Im „…“-Menü |
|---|---|---|---|
| Offen, Passt, Passt · geändert | **✓ Freigeben** | Zurück an Lena | Zurückweisen · Im Editor öffnen |
| Passt nicht, Vom Team beanstandet | **Zurück an Lena** | Im Editor öffnen | Zurückweisen (nur bei „Passt nicht“) |
| Rückfrage | **✓ Freigeben** | Zurück an Lena | Zurückweisen · Im Editor öffnen |
| Freigegeben | — | Im Editor öffnen | Freigabe zurücknehmen |

16. **Bei einer Rückfrage** steht über der Leiste das Feld „Antwort an Lena“ (optional). Die Aktionen laufen über `pruef_rueckfrage_klaeren`, wie heute in `RueckfrageKlaeren`.
17. **Freigeben:**
    - Läuft über `task_status_set(…, 'ready')`. Die Freigabe stempelt `reviewed_by`/`reviewed_at`.
    - **Gesperrt**, solange „Vor der Freigabe klären“ einen sperrenden Befund hat. Der Infotext nennt dann in Gelb den ersten Befund.
    - **Nicht bei „Passt nicht“ und „Vom Team beanstandet“** (Entscheidung Rasit, 05.10.). Diese Aufgaben gehen nach der Überarbeitung erst zurück an Lena und kommen über ihr „Passt“ in die Freigabe. Der Knopf erscheint dort nicht, und der Infotext sagt: „Erst überarbeiten, dann zurück an Lena.“ Auch der Server lehnt ab (Daten, Punkt 6).
    - **Sonderfall „nicht bei Lena“** (zum Beispiel VERA-8): Hier heißt der Primärknopf „Auf Offen setzen“ statt „Zurück an Lena“ (gleiche Funktion, ohne Nachricht). Danach kann der Admin freigeben.
    - **Ungespeicherte Änderungen** in der Prüfkarte werden vorher gespeichert, wie bei Lena vor jeder Entscheidung.
18. **Zurück an Lena:**
    - **Wirkung:** Status `draft` (für Lena „Offen“), die Ausgangsfassung wird gelöscht. Beim nächsten Öffnen durch Lena wird der jetzige Stand die neue Ausgangsfassung. Lena sieht also keine „geändert“-Marken für Änderungen des Teams.
    - **Nachricht:** Ein optionales Feld „Nachricht an Lena“ öffnet sich über der Leiste. Lena sieht die Nachricht als „Antwort vom Team“ (Entscheidung 34).
    - **Für alle Status außer „Freigegeben“.** Heute geht das nur aus der Rückfrage, dafür braucht es eine Funktion (siehe Daten, Punkt 2).
19. **Zurückweisen:**
    - Öffnet über der Leiste die Gründe. Es sind dieselben Kategorien wie heute in `RueckfrageKlaeren`, mindestens einer, dazu „Was genau?“.
    - Ergebnis: Status `beanstandet` und je Grund eine Zeile `task_reviews`. Bei einer Rückfrage über `pruef_rueckfrage_klaeren`, sonst über den bestehenden Admin-Weg (`lena_beanstande`, Admin-Zweig).
20. **Freigabe zurücknehmen:** `task_status_set(…, 'draft')` mit Bestätigung „Die Aufgabe verlässt den LSA-Pool. Zurücknehmen?“
21. **Nach jeder Entscheidung** öffnet sich die nächste Aufgabe der Reihe. Eine Meldung bestätigt die Aktion für 5 Sekunden, zum Beispiel „Freigegeben: ⟨Kurztitel⟩“, mit dem Knopf „Öffnen“, der zurück zur Aufgabe führt.
    - **Kein „Rückgängig“** (Entscheidung Rasit, 05.10.). Freigaben lassen sich in der Aufgabe zurücknehmen.
22. **Tastenkürzel:**
    - **Enter:** Freigeben, außer wenn ein Feld oder Knopf den Fokus hat.
    - **← / →:** Zurück / Überspringen.
    - **E:** Im Editor öffnen.
    - **Esc,** der Reihe nach: Erklärung oder Bild schließen → Feld verlassen → offenes Feld über der Leiste schließen → Schließen.
    - **Am iPad** werden die Tastenhinweise ausgeblendet.
23. **Ende der Reihe:** eine Abschlussseite mit „Reihe durch“ und den Zahlen freigegeben, an Lena, zurückgewiesen, übersprungen, unverändert geöffnet. Darunter „Übersprungene prüfen“ (wenn es welche gibt) und „Zurück zur ⟨Herkunft⟩“.

### D — Editor und Rückweg

24. **„Im Editor öffnen“** öffnet `/admin/authoring/:id`.
    - **Mit Abschnitt:** Aus einem „im Editor“-Link oder einem Befund springt der Editor an die passende Stelle.
      - Richtige Antwort und Typische Fehler → „Antwort & Lösung“.
      - Einordnung → Einordnung.
      - Bild → Bilder.
      - Stoffanker → Stoffanker.
    - **Ohne Abschnitt:** Aus dem Kopf öffnet er sich oben.
25. **Vor dem Wechsel** speichert die Prüfansicht offene Änderungen der Prüfkarte (`pruef_speichern`). Scheitert das, bleibt sie offen und zeigt den Fehler.
26. **Rückweg:**
    - **Zurück-Link:** Kommt der Editor aus der Prüfansicht (`?zurueck=pruefen`), heißt der Zurück-Link „Zurück zur Prüfansicht“.
    - **Nach dem Speichern** steht oben die Meldung „Gespeichert.“ mit dem Knopf „Zurück zur Prüfansicht“. Es gibt keine automatische Weiterleitung, damit man mehrere Abschnitte nacheinander ändern kann.
    - **Rückkehr:** Die Prüfansicht öffnet dieselbe Aufgabe in derselben Reihe an derselben Position und lädt sie neu (neue Version).
    - **Ersatz:** `usePflegeRueckweg` und `?pflege=` entfallen und werden durch diesen Rückweg ersetzt.

### E — Expertenliste: Auswahl

27. **Auswahlfeld je Zeile** (Trefferfläche mindestens 44 px). Ein Klick auf die übrige Zeile öffnet weiter die Admin-Prüfansicht.
28. **Kopf der Liste:**
    - Ein Auswahlfeld „Alle im Filter (n)“. Es wählt alle gefilterten Aufgaben, auch die nicht sichtbaren.
    - Bei Teilauswahl ist es halb markiert.
29. **Ändert sich der Filter,** wird die Auswahl aufgehoben. Dazu erscheint der Hinweis „Auswahl aufgehoben, weil der Filter geändert wurde.“ So wirkt eine Aktion nie auf Aufgaben, die man nicht mehr sieht.
30. **Sammelleiste:** Ab einer ausgewählten Aufgabe erscheint sie unten, immer sichtbar.
    - Links: „n ausgewählt“ und „Auswahl aufheben“.
    - **Rechts drei Knöpfe:** „Ausgewählte prüfen“ (öffnet die Admin-Prüfansicht mit der Auswahl als Reihe), „Freigeben“ und „Zurück an Lena“.
    - **Menü „Mehr“:** Pilot an · Pilot aus · Aus Lenas Liste nehmen · Wieder in Lenas Liste · Fertigkeit ändern · Anforderungsbereich setzen.
    - **Am iPad hoch** und schmaler stehen nur „Ausgewählte prüfen“ und „Mehr“ sichtbar, der Rest liegt im Menü.

### F — Sammelaktionen

31. **Ablauf jeder Sammelaktion:**
    1. **Vorschau-Dialog.**
       - Titel: „⟨n⟩ Aufgaben freigeben?“ und entsprechend für die anderen Aktionen.
       - **„Betrifft ⟨k⟩“:** die Aufgaben, die geändert werden.
       - **„Ausgelassen ⟨m⟩“:** nach Grund gruppiert, je Grund die Zahl. Aufklappbar zur Liste mit Kurztitel und Thema.
       - **Eingaben**, wo nötig: Grund, Fertigkeit, Anforderungsbereich, Nachricht.
    2. **Bestätigen.** Der Knopf nennt die Zahl, zum Beispiel „9 freigeben“, und ist bei 0 gesperrt.
    3. **Ergebnis-Meldung:** „9 freigegeben, 3 ausgelassen.“ mit dem Knopf „Ausgelassene anzeigen“. Er setzt die Auswahl auf genau diese Aufgaben.
32. **Vorschau und Ausführung sind derselbe Serveraufruf**, einmal mit `nur_vorschau = true`.
    - **Ablauf auf dem Server:** Er prüft jede Aufgabe einzeln. Scheitert eine Aufgabe, wird sie mit Grund ausgelassen, die anderen laufen weiter.
    - **Wenn sich zwischen Vorschau und Ausführung etwas ändert,** zählt das Ergebnis der Ausführung. Die Meldung nennt dann die tatsächlichen Zahlen.
33. **Protokoll:** Je Aufgabe entsteht genau das, was bei der Einzelaktion entsteht (Status-Stempel, `task_reviews`, Ausgangsfassung). Dazu schreibt jede Admin-Aktion, einzeln wie gesammelt, eine Zeile ins Admin-Protokoll mit Aktion, Grund, vorher → nachher und der Marke „Sammelaktion“ (Daten, Punkt 7).

**Die Aktionen**

| Aktion | Wirkung je Aufgabe | Eingabe | Ausgelassen (Grund im Dialog) |
|---|---|---|---|
| **Freigeben** | `ready` wie Einzelfreigabe | — | schon freigegeben · noch nicht von Lena bewertet · geändert, einzeln prüfen · Rückfrage offen · Lena: Passt nicht · vom Team beanstandet · Befund vor der Freigabe ⟨Text⟩ · VERA-8, einzeln freigeben |
| **Zurück an Lena** | `draft`, Ausgangsfassung gelöscht, Nachricht als Antwort vom Team | Nachricht (optional) | freigegeben, erst Freigabe zurücknehmen · schon offen und unbewertet · nicht bei Lena ⟨Grund⟩ |
| **Pilot an / aus** | `pruef_pilot` setzen | — | schon im Pilot / nicht im Pilot · nicht bei Lena ⟨Grund⟩ |
| **Aus Lenas Liste nehmen** | von Hand ausgeschlossen, mit Grund | Grund (Pflicht) | schon nicht bei Lena ⟨Grund⟩ · freigegeben |
| **Wieder in Lenas Liste** | Hand-Ausschluss aufheben | — | nicht von Hand ausgeschlossen (berechneter Grund bleibt) |
| **Fertigkeit ändern** | `skill_key` wie Lenas Änderung, `sondierrang` leer (Entscheidung 16) | Fertigkeit, Grund (optional) | freigegeben · Fertigkeit passt nicht zum Thema der Aufgabe · hat diese Fertigkeit schon |
| **Anforderungsbereich setzen** | `afb` wie Lenas Änderung | I / II / III, Grund (optional) | freigegeben · hat diesen Bereich schon |

34. **Freigeben** nimmt genau die Aufgaben, die `freigabe_thema` heute auch nehmen würde (`pruef_freigabe_erlaubt` und Gate). Alles andere geht einzeln über die Prüfansicht. So bleibt Entscheidung 4 bestehen: Geänderte Aufgaben gibt ein Admin einzeln frei.
35. **Fertigkeit ändern:**
    - Die Auswahl zeigt wie bei Lena „Im Thema …“ und „Voraussetzungen“ (`pruef_fertigkeit_optionen`). Bei Aufgaben aus mehreren Themen stehen nur Fertigkeiten zur Wahl, die für mindestens eine Aufgabe erlaubt sind. Der Server lässt die übrigen mit Grund aus.
    - **Folge:** Eine Aufgabe, die Lena unverändert mit „Passt“ bewertet hat, gilt danach als geändert und muss einzeln freigegeben werden. Der Vorschau-Dialog sagt das: „⟨x⟩ davon hat Lena schon bewertet. Sie müssen danach einzeln freigegeben werden.“
36. **Anforderungsbereich setzen:** dieselbe Folge wie bei 35.
37. **Nicht als Sammelaktion:**
    - Richtige Antwort, Wertungsregel, Typische Fehler, Lösungsweg.
    - Aufgabentext, Bilder, Typ/Format.
    - Zurückweisen (braucht den Grund je Aufgabe), Löschen.

### G — Pflege-Strecke entfällt

38. **Code:**
    - **Löschen:** Route `/admin/pflege` und `PflegeWizardPage.tsx`, dazu alles unter `components/edvance/authoring/wizard/`, was danach niemand mehr importiert, samt Tests und i18n-Schlüsseln `wizard.*`.
    - **Weiterleitung:** `/admin/pflege` führt auf `/admin/authoring/liste`, mit dem Hinweis „Die Pflege-Strecke ist durch die Prüfansicht ersetzt.“
39. **Was aus den Schritten wird:**

| Schritt der Strecke | Künftig |
|---|---|
| Lesen | Kinderansicht links |
| Stoffanker | Befund „Vor der Freigabe klären“ + Editor |
| Bilder | Befund (Bild fehlt, toter Pfad) + Editor |
| Lösung (nur lesbar) | Prüfkarte, jetzt änderbar |
| Freigabe | Entscheidungsleiste |

40. **Einstiege umhängen:**
    - Expertenliste: „Pflege-Strecke starten“ wird zu „Durchlauf starten“.
    - Board: „Durchlauf“.
    - Content-Gesundheit: Mangel-Durchlauf.
    - `adminNav.ts`: Pfad `/admin/pflege` aus `itemPflege` entfernen.
    - Alle Einstiege führen in die Admin-Prüfansicht mit Reihe.
41. **Vorbefüllt-Kennzeichen** (`VorbefuelltContext`, „bestätigt“): Wenn nur die Strecke sie schreibt, siehe offene Frage 5.

### H — Lenas Seite

42. Für Lena ändert sich nichts.
43. Für Admins in Lenas Prüfansicht heißt der Link „In Admin-Prüfansicht öffnen“ und führt auf `/admin/pruefen/:taskId`.

## Daten und Backend

Das Frontend darf nichts davon nachbauen. Die Migrationen spielt Rasit ein, Agenten führen kein DDL aus.

1. **Admin-Zweig in `pruef_sperren`:**
   - Für admin entfallen die Sperren „außerhalb des Piloten“ und `team_beanstandet`.
   - `freigegeben` und die Ausschlüsse `vera8`, `typ` und `inaktiv` bleiben für alle.
   - Lenas Verhalten bleibt unverändert, ein pgTAP-Test sichert beides.
   - Ob `pruef_aufgabe` die Ausgangsfassung auch für admin anlegen soll, ist Prüfpunkt P0.
2. **Zurück an Lena für alle Status außer `ready`:**
   - Neue Funktion oder Erweiterung, admin only.
   - Wirkung wie `an_lena`: `draft`, Ausgangsfassung löschen, Antwort an die jüngste `task_pruefungen`-Zeile.
   - `pruef_rueckfrage_klaeren` bleibt für die Rückfrage.
3. **Sammelaktionen:**
   - Eine Funktion je Aktion oder eine mit Parameter `p_aktion`. Die Entscheidung trifft der Bauauftrag.
   - **Pflichteigenschaften:**
     - admin only (42501).
     - Muster SECURITY DEFINER, `set search_path = public, pg_temp`, revoke/grant wie `20261004001333_lead_thema_setzen.sql`.
     - `p_task_ids uuid[]`, `p_werte jsonb`, `p_nur_vorschau boolean`.
     - Rückgabe `{ betrifft: uuid[], ausgelassen: [{ task_id, grund, text? }] }`.
     - Je Aufgabe ein eigener Savepoint.
     - Die Auslass-Gründe sind feste Schlüssel, die das Frontend übersetzt (`ED422`-Muster wie `pruef_fehler`).
   - **Fertigkeit und AFB** laufen durch denselben Code wie `pruef_speichern` (Änderungsprotokoll, `sondierrang`), nicht an ihm vorbei.
4. **Von Hand aus Lenas Liste nehmen** (Entscheidung Rasit, 05.10.: ja, mit Pflichtgrund):
   - Neues Feld bzw. neue Tabelle mit Grund, wer, wann.
   - `pruef_ausschluss` liefert dafür den Grund `hand`, und `pruef_admin_liste` gibt den Text mit aus.
5. **Types neu generieren** nach dem Einspielen. Nicht von Hand anpassen.
6. **Freigabe-Sperre bei „Passt nicht“ und „Vom Team beanstandet“:** `task_status_set(…, 'ready')` lehnt für Aufgaben mit status `beanstandet` ab (ED422, HINT `erst_an_lena`). Davor Aufruferliste: Die Sammelfreigaben nehmen `beanstandet` heute schon nicht.
7. **Admin-Protokoll** (neu, nur anhängen): `task_admin_protokoll` mit id, task_id (FK, on delete cascade), aktion (freigeben, an_lena, zurueckweisen, freigabe_zurueck, ausschliessen, aufnehmen, pilot_an, pilot_aus, fertigkeit, afb), aenderungen jsonb (Format wie `task_pruefungen.aenderungen`), grund text, sammel boolean, von uuid, am timestamptz default now(). RLS an, lesen nur admin, schreiben nur über Funktionen, Index (task_id, am desc). `audit_log` reicht nicht: Es hat weder Grund noch vorher → nachher.

## Begriffe in der Admin-Oberfläche

| Intern | Admins sehen |
|---|---|
| `draft` / `review` / `rueckfrage` / `beanstandet` / `ready` | Offen / Zur Freigabe / Rückfrage / Zurückgewiesen / Freigegeben |
| Lena-Status | Lena: Offen / Passt / Passt · geändert / Unsicher / Passt nicht |
| `pruef_ausschluss` | Nicht bei Lena: ⟨Grund⟩ |
| Gate, blockierende Flags | Vor der Freigabe klären |
| `an_lena` | Zurück an Lena |
| Pflege-Strecke, Durchlauf | Durchlauf (öffnet die Prüfansicht) |

## Regeln und Grenzfälle

- **Gleichzeitige Bearbeitung:** Ändert Lena eine Aufgabe, während ein Admin sie offen hat (oder umgekehrt), lehnt `pruef_speichern` mit ED409 ab: „Die Aufgabe wurde inzwischen geändert. Bitte neu laden.“ Sammelaktionen prüfen den Stand je Aufgabe zum Zeitpunkt der Ausführung.
- **Reihe:** Sie liegt im `sessionStorage`, das ist nur Komfort. Ein direkter Link ohne Reihe öffnet die einzelne Aufgabe, und „Schließen“ führt dann zur Expertenliste.
- **Aufgabe verlässt die Reihe:** Wird eine Aufgabe der Reihe anderswo freigegeben, bleibt sie in der Reihe und zeigt ihren neuen Status.
- **Große Auswahl:** „Alle im Filter“ kann alle 859 Aufgaben treffen. Ab 100 betroffenen Aufgaben verlangt der Dialog ein zweites Bestätigen („Ich habe die Vorschau geprüft“).
- **VERA-8:** erscheint nie bei Lena. Admins prüfen und geben VERA-8-Aufgaben einzeln in der Admin-Prüfansicht frei. Die Prüfkarte ist dort nur lesbar, Änderungen gehen über den Editor.

## Abnahmefälle

1. Wenn ein Admin in der Expertenliste auf eine Zeile klickt, dann öffnet sich `/admin/pruefen/:taskId` mit Kinderansicht, „Lenas Ergebnis“, Prüfkarte und Admin-Leiste.
2. Wenn Lena eine Aufgabe mit „Unsicher“ und der Frage „Ist 22,61 auch richtig?“ bewertet hat, dann steht die Frage im Block „Lenas Ergebnis“, über der Leiste steht „Antwort an Lena“, und die Knöpfe lauten „Freigeben“ und „Zurück an Lena“, dazu „Zurückweisen“ im „…“-Menü.
3. Wenn der Admin bei dieser Rückfrage eine Antwort schreibt und „Zurück an Lena“ wählt, dann ist die Aufgabe für Lena „Offen“, sie sieht die Antwort als „Antwort vom Team“, und beim Öffnen gibt es keine „geändert“-Marken.
4. Wenn eine Aufgabe ohne Stoffanker geöffnet wird, dann zeigt „Vor der Freigabe klären“ den Befund mit „im Editor beheben“, und „Freigeben“ ist gesperrt mit dem Befund als Grund.
5. Wenn der Admin „im Editor“ neben „Richtige Antwort“ klickt, eine Teilaufgabe im Editor ändert und speichert, dann bringt „Zurück zur Prüfansicht“ ihn an dieselbe Aufgabe an derselben Position der Reihe, mit dem neuen Stand.
6. Wenn der Admin in der Prüfkarte eine richtige Antwort ändert und Enter drückt, dann wird zuerst gespeichert, dann freigegeben, und die nächste Aufgabe der Reihe öffnet sich.
7. Wenn eine Aufgabe außerhalb des Piloten liegt oder vom Team beanstandet ist, dann kann der Admin die Prüfkarte trotzdem ändern. Lena kann es weiterhin nicht (pgTAP).
8. Wenn der Admin in der Expertenliste 12 Aufgaben auswählt und „Freigeben“ klickt, dann zeigt der Dialog zum Beispiel „Betrifft 9 · Ausgelassen 3: 2 geändert, einzeln prüfen · 1 Rückfrage offen“, und erst „9 freigeben“ führt aus.
9. Wenn nach der Sammelfreigabe „Ausgelassene anzeigen“ geklickt wird, dann sind genau die 3 ausgelassenen Aufgaben ausgewählt, und „Ausgewählte prüfen“ öffnet sie als Reihe.
10. Wenn der Admin den Filter ändert, während Aufgaben ausgewählt sind, dann ist die Auswahl leer, und der Hinweis erscheint.
11. Wenn der Admin für 20 Aufgaben aus zwei Themen „Fertigkeit ändern“ wählt, dann stehen nur erlaubte Fertigkeiten zur Wahl, der Dialog nennt die Aufgaben, für die sie nicht passt, und nach der Ausführung zeigt jede geänderte Aufgabe die Änderung vorher → nachher mit „Sammeländerung“.
12. Wenn eine von Lena unverändert mit „Passt“ bewertete Aufgabe per Sammelaktion einen anderen Anforderungsbereich bekommt, dann lässt die Sammelfreigabe sie danach mit „geändert, einzeln prüfen“ aus.
13. Wenn „Pilot an“ für 30 Aufgaben ausgeführt wird, dann sieht Lena bei `nur_pilot` genau diese Aufgaben zusätzlich, und schon markierte werden mit Grund ausgelassen.
14. Wenn jemand `/admin/pflege` aufruft, dann landet er in der Expertenliste mit dem Hinweis. Im Code gibt es keinen Import von `PflegeWizardPage` mehr.
15. Wenn ein Coach (auch mit Prüfrecht) `/admin/pruefen/:taskId` aufruft oder eine Sammelfunktion direkt in der Datenbank ausführt, dann wird er abgewiesen (Weiterleitung bzw. 42501).
16. Wenn eine Aufgabe auf „Passt nicht“ oder „Vom Team beanstandet“ steht, dann gibt es in der Leiste kein „Freigeben“, und ein direkter Aufruf von `task_status_set(…, 'ready')` wird mit `erst_an_lena` abgelehnt.
17. Am iPad (quer und hoch) lässt sich jede Aufgabe ohne Tastatur prüfen und entscheiden, und jede Sammelaktion lässt sich ausführen. Es gibt keinen waagerechten Scroll.

## Auswirkungen auf Bestehendes

- **Pflege-Strecke:** entfällt (G).
- **`LenaInfo` und `RueckfrageKlaeren` in der Expertenliste:** Sie bleiben als Kurzansicht unter der Zeile. Die Rückfrage-Klärung gibt es künftig auch in der Prüfansicht, mit denselben Funktionen.
- **Board „Alle geprüften freigeben“:** bleibt. Die Sammelfreigabe der Expertenliste nimmt dieselben Aufgaben, nur über eine freie Auswahl.
- **Editor:** bekommt Sprungziele je Abschnitt und den neuen Rückweg.
- **`adminNav.ts`, Startseite „Heute“:** Pfade und Links anpassen.
- **Coach-Sicht** (nächster Auftrag): Die Admin-Prüfansicht ist ihr Vorbild für Fokusseiten.

## Nicht Teil davon

- Lenas Übersicht und Prüfansicht (außer dem Link in H 43).
- Neue Wertungsregeln, typische Fehler anlegen, Fehlbild-Familien (OP-4, OP-14).
- Sammel-Zurückweisen, Löschen, Sammeländerung von Antworten.
- QS-Seite, Diagnostik und Content-Gesundheit, außer dem neuen Einstieg.
- Suche ⌘K (H5).

## Entscheidungen (Rasit, 05.10.2026)

1. **Von Hand aus Lenas Liste nehmen:** ja, mit Pflichtgrund.
2. **Rückgängig nach einer Admin-Entscheidung:** entfällt. Die Meldung bietet „Öffnen“.
3. **Freigeben trotz „Passt nicht“ oder „Vom Team beanstandet“:** nein. Erst zurück an Lena.

## Offene Fragen an Rasit

4. **Fertigkeit oder AFB bei freigegebenen Aufgaben:** Der Bauauftrag lässt sie aus (Vorschlag). Automatisch die Freigabe zurückzunehmen wäre die Alternative.
5. **Vorbefüllt-Kennzeichen:** Der Bauauftrag klärt in P0, wer „bestätigt“ heute setzt. Setzt es nur die Pflege-Strecke, bleibt das Feld unverändert stehen, und die Frage kommt als offener Punkt ins PR.

## Voraussetzungen

- Der Fix für die RPC-Bindung ist auf `dev`. Fehlt er, holt der Bauauftrag ihn als ersten Commit nach.
- Admin-Hülle H1–H4b ist auf `dev` (erledigt).

## Dringlichkeit

Vor der Coach-Sicht. Lenas Pilot läuft (100 Aufgaben). Sobald sie durch ist, brauchen die Admins Freigabe, Rückfragen und Korrekturen über viele Aufgaben, und die Pflege-Strecke zeigt Lenas Ergebnis nicht.

## Vorschlag für Arbeitspakete

| Paket | Inhalt |
|---|---|
| P0 | Ist-Analyse: Aufrufer von `wizard/*` und `VorbefuelltContext`, Verhalten von `pruef_aufgabe`/`pruef_sperren` für admin, Admin-Weg für Zurückweisen außerhalb der Rückfrage, Sprungziele im Editor. Ergebnis in `docs/admin-pruefansicht/ist-analyse.md`. |
| P1 | Backend: Admin-Zweig `pruef_sperren`, Zurück an Lena, Sammelfunktionen mit Vorschau, ggf. Hand-Ausschluss. pgTAP. Migrationen als Dateien, Rasit spielt ein. |
| P2 | Admin-Prüfansicht: Route, Kopf mit Reihe, „Lenas Ergebnis“, „Vor der Freigabe klären“, Leiste, Abschluss der Reihe. |
| P3 | Editor: Sprungziele und Rückweg zur Prüfansicht. |
| P4 | Expertenliste: Auswahl, Sammelleiste, Vorschau-Dialog, Ergebnis-Meldung. |
| P5 | Pflege-Strecke entfernen, Einstiege umhängen, Weiterleitung, Aufräumen der i18n. |

## Anlage

Der Klick-Dummy `admin-pruefansicht-dummy.html` zeigt:

- die Expertenliste mit Auswahl, Sammelleiste und Vorschau-Dialog;
- die Admin-Prüfansicht für drei Fälle: Rückfrage, Lena „Passt · geändert“, Befund vor der Freigabe;
- den Rückweg aus dem Editor (angedeutet).

Der Schalter „Hinweise“ blendet Notizen mit Verweisen auf dieses Dokument ein. Alle Daten sind Beispielwerte, die Aufgaben stammen aus Lenas Dummy v2. Farben und Abstände folgen der Admin-Hülle.
