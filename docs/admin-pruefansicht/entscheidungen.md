# Admin-Prüfansicht — Maßgebliche Entscheidungen

Wörtlich aus dem Bauauftrag „Admin-Prüfansicht mit Editor-Rückweg und Sammelaktionen“ vom 05.10.2026
(Planungsstand dev 139da80). Abweichungen in der Umsetzung stehen in `offene-punkte.md`.

```
A. Zugang
 1. Neue Route /admin/pruefen/:taskId, nur admin über ProtectedRoute. Fokusseite ohne Menüleiste, im selben Zweig von
    App.tsx, in dem heute /admin/pflege steht.
 2. In Lenas PruefansichtPage heißt der Admin-Link künftig „In Admin-Prüfansicht öffnen“ und führt auf
    /admin/pruefen/:taskId. Sonst ändert sich dort nichts.

B. Admin-Prüfansicht (Anforderung B 8–13, Dummy)
 3. Bausteine aus src/components/edvance/pruefen/* wiederverwenden (Kinderansicht, Prüfkarte, Kopfteile). Keine Kopien.
    Wo Lena-spezifisches Verhalten drinsteckt, trennst du es über Props oder kleine Wrapper.
 4. Kopf: Kopfzeile wie bei Lena, Kurztitel, Thema · Fertigkeit, Reihe mit Herkunft und „x von y“, Zurück,
    Überspringen, Im Editor öffnen, Schließen.
    - „Schließen“ führt zur Herkunft zurück, mit Filter, Auswahl und Scrollposition.
    - Der Pilot-Schalter erscheint nur, wenn die Aufgabe bei Lena erscheinen kann.
 5. Block „Lenas Ergebnis“ über der Prüfkarte. Feste Reihenfolge:
    - Status-Marke;
    - geprüft von/am, Dauer;
    - Frage bzw. Gründe und „Was genau?“;
    - Antwort vom Team;
    - Lenas Änderungen aus ihrer letzten task_pruefungen-Zeile, ab drei Einträgen zugeklappt.
    Ohne Lena-Bewertung: „Lena hat diese Aufgabe noch nicht geprüft.“
    Bei Ausschluss: „Nicht bei Lena: ⟨Grund⟩“, bei Hand-Ausschluss mit Grund, wer, wann.
 6. Prüfkarte wie bei Lena.
    - Admins dürfen darin alles, was Lena darf. Gespeichert wird über pruef_speichern: entprellt, vor jeder
      Entscheidung, vor dem Wechsel in den Editor. ED409 → Meldung und „Neu laden“.
    - Neben jedem Abschnitt der Link „im Editor“.
    - Änderungsliste: Ein Eintrag trägt „Lena“, wenn (feld, teil, nachher) in Lenas letzter Entscheidung steht,
      sonst „Team“.
    - Darunter zugeklappt der „Verlauf“ aus task_admin_protokoll (die letzten 20 Einträge).
    - Nur lesbar bei ready (Hinweis mit „Freigabe zurücknehmen“ und Editor) und bei Ausschluss vera8/typ/inaktiv
      (Hinweis mit Editor).
 7. Kasten „Vor der Freigabe klären“ über Lenas Auffälligkeiten, nur wenn nötig.
    - Inhalt: sperrende Befunde aus freigabe_gate_fehler und die blockierenden Flags aus computeFlags
      (src/lib/authoring/flags).
    - Jeder Befund mit „im Editor beheben“, das an die passende Stelle springt. Nicht blockierende Flags zugeklappt
      als „n Hinweise“.

C. Entscheidungsleiste
 8. Unten, immer sichtbar. Infotext links, rechts höchstens zwei Knöpfe und ein „…“-Menü:
    | Status | Primär | Sekundär | „…“ |
    | offen, passt, passt·geändert | ✓ Freigeben | Zurück an Lena | Zurückweisen, Im Editor öffnen |
    | rueckfrage | ✓ Freigeben | Zurück an Lena | Zurückweisen, Im Editor öffnen |
    | beanstandet (Lena oder Team) | Zurück an Lena | Im Editor öffnen | Zurückweisen (nur bei Lenas „Passt nicht“) |
    | ready | — | Im Editor öffnen | Freigabe zurücknehmen |
    - Bei Ausschluss (nicht bei Lena) heißt „Zurück an Lena“ „Auf Offen setzen“ (ohne Nachricht). Bei draft mit
      Ausschluss entfällt der Knopf.
    - Bei beanstandet gibt es kein Freigeben. Der Infotext sagt „Erst überarbeiten, dann zurück an Lena.“
 9. Rückfrage: über der Leiste das Feld „Antwort an Lena“ (optional). Die Aktionen laufen über
    pruef_rueckfrage_klaeren.
10. Freigeben: über pruef_admin_freigeben (G4). Gesperrt mit Sperrgrund, solange Kasten aus 7 einen sperrenden Befund
    hat.
11. Zurück an Lena: Feld „Nachricht an Lena“ (optional) über der Leiste, dann pruef_an_lena (G3).
    Hat Lena die Aufgabe nie bewertet, ist das Feld gesperrt, mit Sperrgrund „Lena hat diese Aufgabe noch nicht
    bewertet.“
12. Zurückweisen: Gründe wie heute in RueckfrageKlaeren (mindestens einer), dazu „Was genau?“, dann
    pruef_admin_zurueckweisen (G5).
13. Nach jeder Entscheidung öffnet sich die nächste Aufgabe der Reihe. Die Meldung bestätigt 5 s lang, mit dem Knopf
    „Öffnen“. Kein Rückgängig.
14. Tasten:
    - Enter: Freigeben, nicht bei Fokus in Feld oder Knopf.
    - ← / →: Zurück / Überspringen.
    - E: Editor.
    - Esc, der Reihe nach: Erklärung → Feld → Feld über der Leiste → Schließen.
    - Am Touchgerät keine Tastenhinweise.
15. Ende der Reihe: Abschlussseite mit freigegeben, an Lena, zurückgewiesen, übersprungen. Darunter
    „Übersprungene prüfen“ und „Zurück zur ⟨Herkunft⟩“.
16. Die Reihe liegt im sessionStorage (nur Komfort). Ersetzt wizardQueue. Ein direkter Link ohne Reihe öffnet die
    einzelne Aufgabe.

D. Editor und Rückweg
17. Der Editor (/admin/authoring/:id) bekommt Sprungziele je Abschnitt (Aufgabe, Antwort & Lösung, Einordnung, Bilder,
    Stoffanker) und den Parameter ?zurueck=pruefen.
    - Dann heißt der Zurück-Link „Zurück zur Prüfansicht“.
    - Nach dem Speichern erscheint „Gespeichert.“ mit dem Knopf „Zurück zur Prüfansicht“, ohne automatische
      Weiterleitung.
    - Die Prüfansicht öffnet danach dieselbe Aufgabe an derselben Position der Reihe und lädt sie neu.
    - usePflegeRueckweg und ?pflege= entfallen.

E. Expertenliste (Anforderung E 27–30, F 31–37, Dummy)
18. Auswahl und Sammelleiste:
    - Auswahlfeld je Zeile. Ein Klick auf die übrige Zeile öffnet die Admin-Prüfansicht, mit dem Filter als Reihe.
    - Kopf: „Alle im Filter (n)“, auch nicht sichtbare, halb markiert bei Teilauswahl.
    - Ein Filterwechsel leert die Auswahl, mit Hinweis.
    - Sammelleiste ab einer Auswahl: n ausgewählt, Auswahl aufheben, Ausgewählte prüfen, Zurück an Lena, Freigeben,
      Mehr (Pilot an, Pilot aus, Aus Lenas Liste nehmen, Wieder in Lenas Liste, Fertigkeit ändern,
      Anforderungsbereich setzen). Schmal: nur Ausgewählte prüfen und Mehr.
    - Vorschau-Dialog: Betrifft k, Ausgelassen m gruppiert nach Grund (aufklappbar), Eingaben, Bestätigen mit Zahl.
      Ab 100 Betroffenen ein zweites Bestätigen.
    - Ergebnis-Meldung mit „Ausgelassene anzeigen“: setzt den Filter zurück und wählt genau die Ausgelassenen aus.
    - Fertigkeit/AFB: Hinweis, wie viele davon Lena schon unverändert mit „Passt“ bewertet hat (sie müssen danach
      einzeln freigegeben werden).
    „Pflege-Strecke starten“ wird zu „Durchlauf starten · n“.

F. Pflege-Strecke entfernen
19. Zu entfernen:
    - Route /admin/pflege und PflegeWizardPage.tsx;
    - alles unter src/components/edvance/authoring/wizard/, was danach niemand mehr importiert, samt Tests und
      i18n-Schlüsseln;
    - der Pfad /admin/pflege in adminNav.ts.
    /admin/pflege leitet auf /admin/authoring/liste um, mit dem Hinweis „Die Pflege-Strecke ist durch die
    Prüfansicht ersetzt.“
    Einstiege umhängen auf die Admin-Prüfansicht mit Reihe: Expertenliste, Board (Durchlauf je Thema),
    Content-Gesundheit (Mangel), Heute (Rückfragen).
    VorbefuelltContext: Setzt nur die Strecke „bestätigt“, bleibt das Feld stehen, und es kommt ein offener Punkt ins
    PR. Nichts löschen, was andere nutzen.

G. Backend (Migrationen; Muster 20261004001333_lead_thema_setzen.sql: SECURITY DEFINER, set search_path = public,
   pg_temp, revoke all from public, anon, authenticated, grant execute to authenticated; Fehler über pruef_fehler mit
   ED422 und HINT-Schlüssel)
Migration 1 „admin_pruefen_rechte“
G1. pruef_sperren: Für get_my_role() = 'admin' entfallen die Sperren „nicht im Pilot“ und team_beanstandet.
    freigegeben und die Ausschlüsse vera8, typ, inaktiv bleiben für alle. Lena unverändert.
    Prüfe auch pruef_aufgabe, pruef_speichern und pruef_wertung_testen auf Pilot- und Team-Sperren und gleiche sie für
    admin genauso an. Legt pruef_speichern für admin eine fehlende Ausgangsfassung an? Das Ergebnis kommt ins PR.
G2. task_status_set(…, 'ready') lehnt bei status = 'beanstandet' ab: pruef_fehler('erst_an_lena'). Vorher
    Aufruferliste. Die freigabe_*-Schleifen fangen P0001, nicht ED422: Prüfe, dass sie beanstandet ohnehin nicht
    nehmen, sonst dort vorher filtern.
    Neue Tabelle task_pruef_ausschluss:
    - Spalten: task_id (PK, FK auf tasks, on delete cascade), grund text not null (nicht leer), von uuid,
      am timestamptz default now().
    - RLS an. Lesen mit darf_pruefen(), schreiben nur über Funktionen.
    pruef_ausschluss liefert 'hand', wenn eine Zeile existiert, in dieser Reihenfolge: vera8, inaktiv, typ, hand,
    ohne_fertigkeit, …
    pruef_admin_liste gibt zusätzlich ausschluss_grund, ausschluss_von und ausschluss_am zurück (Rückgabetyp ändert sich:
    drop und create, Aufrufer anpassen).
    Neue Tabelle task_admin_protokoll:
    - Spalten: id, task_id (FK, on delete cascade), aktion text mit CHECK, aenderungen jsonb (Format wie
      task_pruefungen.aenderungen), grund text, sammel boolean not null default false, von uuid,
      am timestamptz default now().
    - aktion: freigeben, an_lena, zurueckweisen, freigabe_zurueck, ausschliessen, aufnehmen, pilot_an, pilot_aus,
      fertigkeit, afb, rueckfrage_freigeben, rueckfrage_an_lena, rueckfrage_zurueckweisen.
    - RLS an, lesen nur admin, schreiben nur über Funktionen. Index (task_id, am desc).
Migration 2 „admin_pruefen_funktionen“ (über 400 Zeilen auf 2a/2b aufteilen)
G3. pruef_an_lena(p_task_id, p_nachricht text default null), nur admin.
    - Nicht bei ready (pruef_fehler('freigegeben')).
    - Wirkung: status draft, reviewed_by/at leer, task_pruefung_ausgang löschen. Nachricht an die jüngste
      task_pruefungen-Zeile (antwort, beantwortet_von, beantwortet_am), wenn es eine gibt.
    - Protokoll an_lena.
    - Bei rueckfrage ruft das Frontend weiter pruef_rueckfrage_klaeren.
G4. pruef_admin_freigeben(p_task_id), nur admin: task_status_set(…, 'ready') plus Protokoll freigeben.
    pruef_freigabe_zuruecknehmen(p_task_id), nur admin: ready → draft plus Protokoll freigabe_zurueck.
G5. pruef_admin_zurueckweisen(p_task_id, p_gruende text[], p_notiz text), nur admin.
    - Mindestens ein Grund aus der Liste in pruef_rueckfrage_klaeren.
    - Wirkung: status beanstandet, je Grund eine task_reviews-Zeile, Protokoll zurueckweisen.
    - Nicht bei ready.
G6. pruef_rueckfrage_klaeren schreibt zusätzlich Protokoll (rueckfrage_*). Signatur und Verhalten bleiben.
G7. pruef_sammel(p_aktion text, p_task_ids uuid[], p_werte jsonb, p_nur_vorschau boolean) → jsonb
    {betrifft: uuid[], ausgelassen: [{task_id, grund, text}]}. Nur admin.
    Je Aufgabe ein eigener BEGIN … EXCEPTION-Block. Schlägt eine fehl, landet sie mit Grund in ausgelassen, der Rest
    läuft weiter. Bei p_nur_vorschau wird nichts geschrieben. Vorschau und Ausführung nutzen dieselben Prüfungen.
    Protokoll mit sammel = true; grund aus p_werte.grund, sonst null.
    Aktionen und Auslass-Gründe (feste Schlüssel, Texte übersetzt das Frontend):
    - freigeben: genau die Aufgaben mit status review, pruef_freigabe_erlaubt und ohne freigabe_gate_fehler, nicht
      VERA8.
      Gründe: schon_freigegeben, vera8, rueckfrage_offen, team_beanstandet, lena_passt_nicht, noch_nicht_bewertet,
      geaendert, befund (text = Gate-Text).
    - an_lena: wie G3, mit p_werte.nachricht.
      Gründe: freigegeben, nicht_bei_lena (text = Grund), schon_offen (draft ohne task_pruefungen-Zeile seit dem
      letzten Zurücksetzen).
    - pilot_an / pilot_aus: tasks.pruef_pilot.
      Gründe: nicht_bei_lena, schon_im_pilot, nicht_im_pilot.
    - ausschliessen: Zeile in task_pruef_ausschluss, p_werte.grund Pflicht (sonst ED422 grund_fehlt für den ganzen
      Aufruf).
      Gründe: schon_ausgeschlossen (text = Grund), freigegeben.
    - aufnehmen: Zeile löschen.
      Gründe: nicht_von_hand (text = berechneter Grund), schon_drin.
    - fertigkeit: p_werte.skill_key. Erlaubt ist, was pruef_fertigkeit_optionen für die Aufgabe liefert.
      Schreiben über dieselben Bausteine wie pruef_speichern (skill_key, sondierrang null, Ausgangsfassung vorher
      sichern), keine eigene Logik. aenderungen im Protokoll.
      Gründe: freigegeben, schon_gesetzt, nicht_erlaubt.
    - afb: p_werte.afb in (I, II, III), sonst wie fertigkeit.
      Gründe: freigegeben, schon_gesetzt.
    Pilot an/aus einzeln aus der Prüfansicht laufen ebenfalls über pruef_sammel mit einer ID. setPruefPilot entfällt,
    wenn nichts anderes es nutzt.
G8. pgTAP supabase/tests/admin_pruefansicht.test.sql mit eigenen Fixtures. Grün in der Wegwerf-DB (Ausgabe ins PR).
    Mindestens:
    1  Coach mit Prüfrecht ruft pruef_sammel, pruef_an_lena, pruef_admin_freigeben, pruef_admin_zurueckweisen
       → 42501.
    2  Admin speichert über pruef_speichern eine Aufgabe außerhalb des Piloten (nur_pilot an) und eine vom Team
       beanstandete → geht. Lena bei denselben → ED422 wie bisher.
    3  task_status_set(…, 'ready') bei beanstandet → ED422 erst_an_lena.
    4  pruef_sammel freigeben, Vorschau: 1 freigebbar, 1 geändert, 1 Rückfrage, 1 VERA8 → betrifft 1, Gründe stimmen;
       danach ist nichts geschrieben. Ausführung → genau 1 ready, Protokoll sammel = true.
    5  pruef_sammel fertigkeit mit einer nicht erlaubten Fertigkeit → nicht_erlaubt. Mit einer erlaubten →
       skill_key gesetzt, sondierrang null, danach lässt freigeben sie mit geaendert aus.
    6  ausschliessen ohne Grund → ED422 grund_fehlt. Mit Grund → pruef_ausschluss = 'hand', Aufgabe fehlt in
       pruef_board, Lena-pruef_sperren → ausgeschlossen. aufnehmen → wieder im Board.
    7  pruef_an_lena aus beanstandet → draft, Ausgangsfassung gelöscht, Nachricht in der jüngsten task_pruefungen-Zeile,
       Protokoll an_lena.
    8  Schüler und Eltern lesen keine Zeile aus task_admin_protokoll und task_pruef_ausschluss.
    9  Eine Aufgabe, deren Bearbeitung in pruef_sammel einen Fehler wirft, landet in ausgelassen; die anderen sind
       geschrieben.
```
