# Lena-Board — Maßgebliche Entscheidungen

Wörtlich aus dem Bauauftrag „Aufgaben prüfen (Lena-Board)“ vom 04.10.2026 (Planungsstand dev 93fb3d6).
Abweichungen in der Umsetzung stehen in `offene-punkte.md`.

## A. Zugang und Rechte

 1. Neue Routen /coach/pruefen (Übersicht und Abschluss) und /coach/pruefen/:taskId (Prüfansicht) für admin und
    coach, zusätzlich mit Prüfrecht.
    - ProtectedRoute bekommt dafür eine optionale Prop, die über getDarfPruefen (src/lib/supabase/freigabe.ts)
      prüft. Kein Rollen-Check in Pages.
    - Ohne Prüfrecht geht es zurück auf /coach, mit Hinweis.
 2. Kachel „Aufgaben prüfen“ im CoachDashboard (DashboardTiles), nur mit Prüfrecht sichtbar.
 3. /admin/authoring, /admin/authoring/liste, /admin/authoring/:id und /admin/pflege sind nur noch für admin.
    Korrigiere dazu den veralteten Text authoring.json „readOnly“ (Nur-Lese-Modus …) und den Kommentar in App.tsx.
 4. Lena schreibt nur über die neuen pruef_*-Funktionen. Muster: 20261004001333_lead_thema_setzen.sql, also
    SECURITY DEFINER, set search_path = public, pg_temp, revoke all … from public, anon, authenticated,
    dann grant execute … to authenticated.
    Danach schließt Migration 3 die anderen Wege. Dazu gehört eine Rollback-Datei
    docs/lena-board/rollback_rechte.sql.
    - Policy pruefer_update_tasks entfernen. Direktes UPDATE auf tasks bleibt nur über admin_write_tasks.
    - task_status_set, task_solution_upsert und lena_beanstande: den Zweig „darf_pruefen“ entfernen. Es bleiben nur
      admin und ist_systemaufruf().
      Vorher die Aufruferliste erstellen. Braucht ein Prüfer einen dieser Wege nachweislich: melden, nicht brechen.
      Ausnahme: supabase/checks/20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql verlangt diese Wege für einen
      Coach mit Prüfrecht. Das Skript beschreibt den alten Stand und ist überholt. Du passt es an die neuen Regeln an;
      es ist kein Grund, Migration 3 auszulassen.
    - tasks_pruefer_guard und task_solutions_zahlen_guard greifen nur bei current_user = 'authenticated', also nicht
      in Definer-Funktionen. Den Schutz liefern deshalb die Funktionskörper: pruef_speichern schreibt nur die Felder
      aus 16. Ein pgTAP-Test sichert das ab (TESTS 13).
    Damit kann Lena nicht freigeben und weder Aufgabentext, Typ, MC-Optionen, Teilaufgaben-Struktur, Einheit noch
    Bilder ändern.
    Die Zahlen-Sperre task_solutions_zahlen_guard bleibt. Lenas Änderungen laufen protokolliert über die
    Definer-Funktionen, und geänderte Aufgaben gibt ein Admin einzeln frei.

## B. Daten (Migration 1 „pruefung_basis“)

 5. tasks.status bekommt 'rueckfrage'. Anpassen: CHECK und jede Status-Aufzählung in Code und SQL (Scan nach
    'beanstandet'). task_status_set setzt weiter nur draft, review und ready. 'rueckfrage' entsteht nur über
    pruef_entscheiden, 'beanstandet' nur über pruef_entscheiden, pruef_rueckfrage_klaeren und lena_beanstande (Admin).
    Der LSA-Pool bleibt status = 'ready'.
 6. tasks.pruef_version bigint not null default 1.
    - Ein BEFORE UPDATE-Trigger auf tasks erhöht sie.
    - Ein Trigger auf task_solutions (insert/update) erhöht die Version der zugehörigen Aufgabe.
    - Jede schreibende pruef_*-Funktion nimmt p_version. Weicht sie ab, lehnt die Funktion mit SQLSTATE 'ED409' ab.
      Das Frontend zeigt dann „Die Aufgabe wurde inzwischen geändert. Bitte neu laden.“
 7. Neue Tabelle task_pruefung_ausgang: task_id (PK, FK auf tasks, on delete cascade), ausgang jsonb not null,
    erstellt_am timestamptz default now(). Sie hält die eingefrorene Ausgangsfassung der prüfbaren Felder:
    skill_key, afb, correct_answers, acceptance, typical_errors.
    - NICHT als Spalte auf tasks: read_tasks_by_role lässt jede angemeldete Rolle freigegebene Aufgaben lesen, und
      Lösungen gehören nach dem P01-Datenvertrag nie nach tasks.
    - RLS an. Lesen nur mit darf_pruefen(), kein Grant für anon; schreiben nur über Funktionen.
    - Gesetzt wird sie, wenn sie fehlt: von pruef_aufgabe (nur bei status <> 'ready'), von pruef_speichern und von
      pruef_entscheiden.
    - Setzt ein Admin eine Aufgabe von review, rueckfrage oder beanstandet zurück auf draft, wird die Zeile gelöscht.
      Die neue Ausgangsfassung entsteht beim nächsten Öffnen.
    - tasks.vorbefuellt: Lenas Funktionen ändern es nicht. Nur Datenpunkt 24 ergänzt dort den Schlüssel „sicher“
      (vorbefuellt_valid erlaubt keine Werte, wohl aber diesen Schlüssel).
 8. Neue Tabelle task_pruefungen, nur anhängen.
    - Spalten:
      · id
      · task_id (FK, on delete cascade)
      · entscheidung check in (passt, unsicher, passt_nicht, zurueckgenommen)
      · gruende text[], notiz text
      · aenderungen jsonb: Liste von {feld, teil, vorher, nachher}
      · aenderung_grund text
      · dauer_sek int, check 0..86400
      · geprueft_von uuid, geprueft_am timestamptz default now()
      · antwort text, beantwortet_von uuid, beantwortet_am timestamptz
    - RLS an. Lesen mit darf_pruefen(), kein Grant für anon; schreiben nur über Funktionen.
    - Index auf (task_id, geprueft_am desc).
 9. Neue Tabelle pruef_einstellungen mit genau einer Zeile:
    - hilfsmittel text not null default 'Taschenrechner, Stift und Zettel'
    - nur_pilot boolean not null default false
    - grund_pflicht boolean not null default false
    Lesen: authenticated. Ändern: nur admin.
10. tasks.pruef_pilot boolean not null default false.
11. task_reviews.kategorie: Den CHECK um die Gründe aus „Passt nicht“ erweitern. Die bestehenden Werte bleiben.
    aufgabe_fehlerhaft · aufgabe_unklar · bild_falsch · sprache_zu_schwer · tablet_umbauen · passt_nicht_in_lsa · sonstiges

## C. Funktionen (Migration 2 „pruefung_funktionen“; über 400 Zeilen auf 2a und 2b aufteilen)

12. freigabe_gate_fehler(task_id) → text oder null. Das ist das bisherige Gate aus task_status_set für review und
    ready, ausgelagert. task_status_set wirft bei einem Treffer weiter P0001 mit demselben Text (die
    freigabe_*-Schleifen fangen genau P0001). Die Funktionen unten nutzen dasselbe Gate.
13. pruef_ausschluss(task_id) → text oder null. Gründe in dieser Reihenfolge:
    - vera8: source = 'VERA8_IQB'
    - inaktiv: is_active false, is_tutorial, oder content_type <> 'exercise'
    - typ: input_type nicht in MC, NUMERIC, SHORT_TEXT, MULTI_PART, TERM
    - ohne_fertigkeit: skill_key null oder ohne skill_thema
    - ohne_loesung: lsa_has_answers ist nicht erfüllt
    - gate: freigabe_gate_fehler ist nicht leer
    - bild_fehlt: needs_image true (an der Aufgabe oder an einem Teil), aber weder assets noch task_figures mit
      svg_hash
    Ausgeschlossene Aufgaben erscheinen nicht bei Lena, sondern beim Admin mit Grund.
14. pruef_board() liefert eine Zeile je Aufgabe im Board, also nicht ausgeschlossen und bei nur_pilot nur mit
    pruef_pilot. Eine Abfrage, kein N+1.
    - Spalten: task_id, stufe, thema_key, thema_label, thema_sort, skill_key, skill_label, kurztitel, reihenfolge,
      lena_status, geaendert, letzte_dauer_sek.
    - geaendert: Die Änderungsliste der letzten Entscheidung ist nicht leer.
    - Kurztitel: title ohne führendes „AFB I · “, „AFB II · “ oder „AFB III · “.
    - Reihenfolge, nacheinander:
      · Stufe in der Folge 7/8, 9/10, 5/6
      · themen.sort nulls last
      · skills.fundament_tiefe, dann skill_key
      · sondierrang nulls last
      · source_ref, dann id
15. pruef_aufgabe(task_id) liefert alles für die Prüfkarte als ein jsonb. Nur mit darf_pruefen(), sonst 42501.
    Freigegebene Aufgaben liest Lena, ändert sie aber nicht. Die Funktion ist VOLATILE, weil sie die Ausgangsfassung
    anlegt (Punkt 7).
    Inhalt:
    - Kopf: kurztitel, stufe, thema, Position im Thema, hilfsmittel.
    - Aufgabe: input_type, unit, parts (nr, kind, prompt), MC-Optionen (id, label), bild_vorhanden, status,
      pruef_version.
    - werte:
      · Flach mit Regel: zusammengefasst. Einträge aus correct_answers, die nach lsa_values_equal (exact) gleich
        sind, bilden eine Gruppe; gezeigt wird der erste.
      · Sonst (Teile, TERM, ohne Regel): jeder Eintrag einzeln, denn dort vergleicht die Engine Text.
    - regel, nur bei „flach mit Regel“, wenn input_type NUMERIC ist oder SHORT_TEXT mit lauter Zahlwerten:
      · art: wert oder bereich. bereich heißt tolerance.mode absolute, mit mitte = canonical und toleranz = value.
      · einheit_pflicht: unit_graded ist gesetzt.
      · einheit: aus acceptance.unit, sonst die Einheit im canonical oder in correct_answers. Ohne erkennbare
        Einheit gibt es den Schalter nicht.
      · einheit_am_feld: tasks.unit ist gesetzt. Der Schalter ist dann gesperrt, mit Hinweis.
    - fehler: je Fehlbild-Slug eine Gruppe.
      · Inhalt: slug, klartext aus fehlbild_labels, werte [{teil, wert}] und text.
      · werte: nach Zahlenwert bzw. lsa_normalize_answer zusammengefasst.
      · text: der typical_errors-Eintrag mit fehlbild = slug, sonst null.
      · Dazu typical_errors ohne Zuordnung als weitere_hinweise.
      · Bei TERM: leer, mit Kennzeichen ohne_erkennung (TERM darf kein acceptance tragen).
    - loesungsweg: solution, nur zum Lesen.
    - fertigkeit: key, label, thema, stufe, voraussetzungen (Labels).
    - fertigkeit_optionen: Fertigkeiten des Ausgangs-Themas plus direkte Voraussetzungen der Ausgangs-Fertigkeit
      (skill_kante).
    - afb und afb_sicher (vorbefuellt.afb.sicher, falls vorhanden).
    - ausgang (aus task_pruefung_ausgang).
    - aenderungen: Vergleich Ausgangsfassung ↔ jetzt, im Format von task_pruefungen.aenderungen.
    - letzte_pruefung: entscheidung, gruende, notiz, antwort, beantwortet_am.
    - auffaelligkeiten (siehe 19).
16. pruef_speichern(task_id, p_version, p_entwurf jsonb) → {pruef_version, auffaelligkeiten, aenderungen}.
    - Entwurf:
      · werte: Liste je Teil
      · mc: Option-ID
      · regel {art, mitte, toleranz, einheit_pflicht}
      · fehler [{slug, werte [{teil, wert}], text}]
      · skill_key, afb
    - Nicht erlaubt bei status 'ready'.
    - Prüfungen:
      · skill_key liegt in fertigkeit_optionen.
      · Jeder Slug steht in fehlbild_labels.
      · Die MC-ID existiert. Bei gesetzten option_scores wechselt die richtige Option nicht
        (ED422, HINT options_bewertet).
      · Bereich nur, wo regel erlaubt ist, und toleranz > 0.
      · TERM bekommt nie acceptance.
    - Schreibt correct_answers:
      · Flach mit Regel: Unveränderte Gruppen behalten ihre Original-Schreibweisen. Neue oder geänderte Werte erweitert
        pruef_schreibweisen(wert, einheit): Komma und Punkt, „+“ bei positiven Zahlen, Unicode-Minus, mit und ohne
        Einheit, jeweils mit und ohne Leerzeichen.
      · Teile, TERM, ohne Regel: genau Lenas Liste.
      · MC: die Option-ID.
    - Schreibt acceptance, flach bzw. je Teil "1", "2" …:
      · canonical = erster Eintrag, equivalents = übrige Einträge.
      · known_errors aus fehler. Werte immer mit pruef_schreibweisen erweitert; bei MC sind es Option-IDs.
      · tolerance aus regel.
      · Einheit Pflicht: lsa_grade verlangt die Einheit aus acceptance.unit, sonst aus dem canonical, und überspringt
        jeden Kandidaten mit anderer Einheit. Deshalb: unit_graded = true, acceptance.unit = einheit, und canonical,
        equivalents bzw. mitte werden als „Wert Einheit“ geschrieben (z. B. „22,62 m“); notation.unit_optional
        entfällt. Ohne Pflicht: unit_graded entfernen, Werte wie bisher.
      · Übrige Schlüssel bleiben unverändert. Das Ergebnis muss lsa_acceptance_valid bestehen.
      · Bereich: canonical = mitte (mit Einheit, falls Pflicht), equivalents leer,
        tolerance {mode: absolute, value: toleranz}.
    - Schreibt typical_errors: Einträge {error, socratic_question, fehlbild}. fehler.text wird error;
      socratic_question bleibt erhalten. Ein gelöschtes Fehlbild entfernt seine Einträge.
    - Schreibt tasks.skill_key und tasks.afb. Ändert sich skill_key, wird sondierrang null.
    - Kein Statuswechsel.
    - Gemeinsame Bausteine als eigene SQL-Funktionen, damit 20 und 23 sie wiederverwenden: Werte zusammenfassen,
      Schreibweisen erweitern, acceptance angleichen.
17. pruef_entscheiden(task_id, p_version, p_entscheidung, p_gruende text[], p_notiz, p_aenderung_grund, p_dauer_sek)
    → {pruef_version, lena_status}.
    - passt: freigabe_gate_fehler ist null und jeder Teil hat eine richtige Antwort. → status review;
      reviewed_by/at bleiben leer.
    - unsicher: Notiz ist Pflicht. → status rueckfrage.
    - passt_nicht: mindestens ein Grund aus der Liste in 11, bei sonstiges ist die Notiz Pflicht. → status beanstandet,
      dazu je Grund eine task_reviews-Zeile (kategorie = Grund, notiz).
    - aenderung_grund ist nur Pflicht, wenn pruef_einstellungen.grund_pflicht gilt und es Änderungen gibt.
    - Schreibt eine Zeile in task_pruefungen. aenderungen = Vergleich Ausgangsfassung ↔ jetzt, serverseitig berechnet.
    - Neu bewerten geht, solange status <> 'ready'.
    - Validierungsfehler: SQLSTATE 'ED422', HINT = Schlüssel (grund_fehlt, notiz_fehlt, antwort_fehlt,
      bereich_ungueltig, fertigkeit_unzulaessig …). Das Frontend übersetzt den Schlüssel.
18. pruef_rueckgaengig(task_id, p_version): setzt status auf draft und schreibt task_pruefungen mit
    entscheidung zurueckgenommen. Lenas inhaltliche Änderungen bleiben.
19. Auffälligkeiten, Teil von pruef_aufgabe und pruef_speichern. Sie sperren nichts. Die Funktion liefert Code und
    Parameter, den Text holt das Frontend über i18n.
    - fehler_als_richtig: Ein typischer Fehler würde als voll gewertet.
    - werte_widersprechen: Ein Wert aus correct_answers würde von lsa_grade nicht als voll gewertet.
    - mc_richtig_ist_fehler: Die richtige Option steht auch bei den typischen Fehlern.
    - mc_ablenker_ohne_fehlbild: Eine Option ist weder richtig noch steht sie in known_errors.
    - teil_fehler_ist_richtig: Ein typischer Fehler einer Teilaufgabe steht auch in deren Antwortliste.
    - loesungsweg_endet_falsch: nur flach NUMERIC. Die letzte Zahl nach dem letzten „=“ oder „≈“ in solution würde
      nicht als voll gewertet.
20. pruef_wertung_testen(task_id, p_teil int null, p_antwort text, p_entwurf jsonb)
    → {stufe voll|teilweise|nicht, fehlbild_slug, fehlbild_klartext}.
    Baut correct_answers und acceptance mit denselben Bausteinen wie 16 aus dem Entwurf, ohne zu schreiben, und ruft
    die Engine:
    - flach, außer MC und TERM: lsa_grade
    - TERM: lsa_is_correct
    - Teilaufgabe: lsa_is_correct('MC' oder 'SHORT_TEXT', Teil-Liste, lsa_part_answer(kind, …))
    - Fehlbild: genau wie die Engine. lsa_fehlbild_capture sucht ein Fehlbild, wenn lsa_responses.correct = false
      ist, und correct kommt aus lsa_is_correct, nicht aus lsa_grade. Also: lsa_fehlbild_match, wenn
      lsa_is_correct auf die gebauten correct_answers false liefert; kind wird bestimmt wie in lsa_fehlbild_capture.
    Keine eigene Wertung.
21. Admin-Funktion pruef_rueckfrage_klaeren(task_id, p_aktion, p_antwort text, p_gruende text[] null).
    - p_aktion freigeben: über task_status_set('ready').
    - p_aktion zurueckweisen: status beanstandet, dazu task_reviews.
    - p_aktion an_lena: status draft, Ausgangsfassung gelöscht.
    antwort, beantwortet_von und beantwortet_am gehen in die letzte task_pruefungen-Zeile.
    Auch task_status_set löscht die Ausgangsfassung, wenn ein Admin von review, rueckfrage oder beanstandet auf draft
    setzt.
22. Sammelfreigaben (vorher nach weiteren suchen):
    - freigabe_thema und freigabe_cluster (beide nehmen review): nur Aufgaben, deren letzte Entscheidung „passt“
      ohne Änderungen ist.
    - freigabe_muster (nimmt draft): nur Aufgaben ohne jede Lena-Entscheidung. Es bleibt ein Admin-Werkzeug
      außerhalb von Lenas Ablauf; im PR vermerken.
23. Sicherheitsnetz für den Editor (der Fehler aus der Bewertung):
    - task_solution_upsert gleicht acceptance an, wenn p_correct_answers kommt, p_acceptance nicht, und die
      bestehende acceptance canonical hat (flach oder je Teil). Dann gilt canonical = erster Eintrag,
      equivalents = übrige Einträge, alles andere bleibt. Nicht für TERM.
    - Der Expertenmodus muss den Schlüssel fehlbild in typical_errors erhalten. Heute baut editorState.ts die Liste
      nur aus {error, socratic_question} neu, und jedes Speichern löscht die Zuordnung. Dazu src/types/authoring.ts
      und editorState.ts anpassen, mit Vitest.

## D. Daten (Migration 4 „pruefung_daten“)

    Erzeugt von tools/lena-board-daten.mjs. Idempotent, Compare-and-set wie tools/prefill-build.mjs,
    nur status draft, nie VERA8.
24. vorbefuellt.<feld>.sicher aus den Chargen nachtragen. Quelle: docs/prefill/*.json und docs/prefill/*/*.json, nur
    Dateien mit dem Schlüssel „aufgaben“ (nicht -blind, -ids, -snapshot). Abschnitte felder, loesung und teile; bei
    teile die Schlüssel parts.<nr>.<feld> bzw. correct_answers.<nr>, wie im vorbefuellt-Bestand. Nur wo der Eintrag
    existiert. Daraus entsteht die Marke „mittel sicher“.
25. typical_errors-Einträgen den Schlüssel fehlbild geben.
    - Nennt grund in der Charge „Aus acceptance.known_errors (a, b, …)“ und stimmt die Anzahl, in dieser Reihenfolge
      zuordnen.
    - Nur, wenn typical_errors in Prod noch dem Chargenwert entspricht.
    - Der Rest bleibt ohne Zuordnung. Die Zahlen (zugeordnet / ohne) kommen ins PR.
26. Pilot: Vorschlag mit 100 Aufgaben aus dem Board, auf Basis eines dbread-Abzugs.
    - Über alle Themen mit Aufgaben verteilt.
    - Je Thema zuerst MULTI_PART, dann AFB II/III, dann MC, sonst in der Reihenfolge aus 14.
    - Die Liste geht nach docs/lena-board/pilot.csv (Thema, Kurztitel, Typ, AFB, ID).
    - In der Migration: pruef_pilot = true für diese Aufgaben, dazu nur_pilot = true.
27. supabase/checks/lena_board.PRUEFUNG.sql: lesende Prüfung nach dem Einspielen. Sie prüft:
    - Zahlen je Status und Ausschlussgrund;
    - keine ready-Aufgabe verändert;
    - VERA8 unberührt;
    - jede acceptance besteht lsa_acceptance_valid;
    - Pilot = 100;
    - keine review-Aufgabe ohne task_pruefungen-Zeile (siehe 28).
28. Alte Stände „zur Freigabe“: Aufgaben mit status review (nicht VERA8), die noch keine task_pruefungen-Zeile haben,
    gehen zurück auf draft. Sie hat niemand im neuen Ablauf geprüft. beanstandet bleibt beim Admin. Zahl ins PR.

## E. Oberfläche Lena (Vorlage für Ablauf, Texte und Verhalten: Dummy v2)

29. Übersicht:
    - Kopf.
    - Karte „Als Nächstes“ mit Kennzahlen und „Weiter prüfen“ (Enter).
    - Reiter 7/8 · 9/10 · 5/6, nur Stufen mit Aufgaben.
    - Themenliste mit Balken (grün/gelb/rot) und „x / y“. Ein Thema klappt auf und zeigt seine Aufgaben mit Kurztitel,
      Fertigkeit und Status, dazu „Prüfen“ je Thema.
    - Abschluss wie Anforderung G 52. Die Durchschnittszeit kommt aus task_pruefungen des Nutzers.
30. „Weiter prüfen“ und jede Entscheidung führen zur nächsten offenen Aufgabe nach der aktuellen, in der Reihenfolge
    aus 14. Übersprungene Aufgaben kommen ans Ende; die Liste liegt im sessionStorage, das ist nur Komfort.
31. Prüfansicht, Kopf: Stufe · Lernstandsanalyse Mathe · Erlaubt: ⟨hilfsmittel⟩ ⓘ. Dazu Thema, „Aufgabe x von y“,
    Zurück, Überspringen, Pause und der Fortschritt im Thema.
    Links die Kinderansicht:
    - AuthoringPreview über task_preview_payload.
    - Läuft ab Laptop-Breite beim Scrollen mit.
    - „Bild vergrößern“, wenn die Aufgabe ein Bild hat.
    - Darunter der Satz zum Antworttyp per i18n (aus input_type, Anzahl der Teile oder Optionen, unit) und
      „In der Lernstandsanalyse bekommt es keine Rückmeldung und keine Lösung.“
32. Prüfkarte rechts, in dieser Reihenfolge:
    1. Auffälligkeiten, nur wenn vorhanden.
    2. Richtige Antwort.
       · Liste je Teil.
       · MC: alle Optionen, ein Klick setzt die richtige.
       · „Andere Schreibweisen zählen automatisch …“ nur bei flach mit Regel.
       · Bei Teilen: „Hier zählt nur, was in der Liste steht.“
    3. Gewertet wird: nur wo regel. Wahl zwischen genau dieser Wert und Bereich (Wert ± Toleranz), dazu
       „Einheit (⟨einheit⟩) muss dabei sein“.
    4. Antwort ausprobieren: nicht bei MC. Bei Teilen mit Auswahl des Teils. Zeigt drei Stufen und den erkannten
       typischen Fehler.
    5. Lösungsweg zum Nachlesen.
    6. Typische Fehler: Gruppen je Fehlbild mit Klartext, Werten und dem Satz zur Aufgabe.
       · Entfernen / Wieder rein.
       · Ergänzen nur mit einem bestehenden Fehlbild aus einer Auswahl; Wert Pflicht, Satz optional.
       · Bei TERM: Hinweis, dass das System hier keine typischen Fehler erkennt.
    7. Einordnung:
       · Fertigkeit als Auswahl mit den Gruppen „Im Thema …“ und „Voraussetzungen“.
       · Darunter Thema · Klasse und „Baut auf: …“.
       · Anforderungsbereich I/II/III mit Namen und der Marke „mittel sicher“.
    8. Änderungen: vorher → nachher, dazu „Kurz warum?“.
    Jedes geänderte Feld trägt die Marke „geändert ↺“. ↺ setzt das Feld auf die Ausgangsfassung zurück.
33. Speichern:
    - Änderungen gehen gesammelt an pruef_speichern: entprellt (rund 600 ms), vor jeder Entscheidung und bei Pause.
    - Die Version aus der Antwort wird weitergeführt.
    - Bei ED409: Meldung und „Neu laden“.
34. Entscheidungsleiste unten, immer sichtbar.
    - Infotext mit ⓘ: der Sperrgrund in Gelb, oder „n Änderungen werden gespeichert“, oder „Alles ist vorbefüllt …“.
    - Knöpfe: Passt nicht (1), Unsicher (2), ✓ Passt (3, oder Enter, außer bei Fokus in einem Feld oder auf einem
      Knopf).
    - Passt ist gesperrt, wenn keine richtige Antwort da ist (je Teil) oder der Bereich ungültig ist.
    - Gründe und Frage öffnen sich über der Leiste wie im Dummy.
    - Nach jeder Entscheidung öffnet sich sofort die nächste Aufgabe. Eine Meldung bietet 5 s lang „Rückgängig“
      (pruef_rueckgaengig).
    - Hinweis „Schon bewertet …“, mit der Antwort vom Team, wenn es eine gibt.
35. Tastenkürzel wie Anforderung F 50. Am Touchgerät die Tastenhinweise ausblenden. Alles muss am iPad ohne Tastatur
    gehen.
36. ⓘ-Erklärungen: Wortlaut aus dem Objekt INFO in docs/lena-board/lena-board-dummy-v2.html, nicht aus Anhang A der
    Anforderung. Öffnen bei Hover, Fokus oder Antippen; schließen mit Esc oder Antippen daneben.
37. Zeitmessung: vom Öffnen bis zur Entscheidung in Sekunden, übergeben an pruef_entscheiden.
38. Texte im neuen Namespace src/i18n/locales/de/pruefen.json, registriert in src/i18n/index.ts.
    Lenas Sprache nach der Tabelle „Begriffe“ der Anforderung. In ihrer Oberfläche kommen weder Item, Stamm, NUMERIC,
    Mängel noch Fehlbild vor.

## F. Oberfläche Admin

39. Item-Pflege-Board (board/Arbeitsbereich, ThemaZeile) und Expertenliste:
    - Reiter bzw. Filter „Rückfrage“.
    - Je Aufgabe: Lena-Status mit „geändert“, Gründe oder Frage, geprüft von/am, Dauer.
    - Aufklappbar: die Änderungsliste mit Grund.
40. Bei einer Rückfrage: Antwort an Lena als Text und die Aktionen Freigeben, Zurückweisen und Zurück an Lena
    (pruef_rueckfrage_klaeren).
41. „Alle geprüften freigeben“ zeigt, wie viele geänderte Aufgaben und Rückfragen ausgelassen werden.
42. Expertenliste: Filter „Nicht bei Lena“ mit Ausschlussgrund (pruef_ausschluss).
43. Für Admins in der Item-Pflege der Link „In Prüfansicht öffnen“, in der Prüfansicht der Link
    „Im Expertenmodus öffnen“.
44. Eine kleine Karte in der Item-Pflege, mit der Admins hilfsmittel, nur_pilot, grund_pflicht und die Pilotmarke je
    Aufgabe ändern.
