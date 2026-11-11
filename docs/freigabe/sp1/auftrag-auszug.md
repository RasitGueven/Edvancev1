# SP-1 · Auszug aus dem Bauauftrag (für Zweitprüfungen)

## Ziel

Lena prüft eine Bauform der Session-Aufgaben in einer Ansicht, die sie ohne Erklärung versteht: Klartext statt Kürzel
und Platzhalter, links Grundgerüst, Stufen, typische Fehler und sechs Beispiele, rechts ihre Kommentare und ein einziger
Entscheidungsknopf. Ohne Kommentar heißt die Entscheidung „Passt“, mit Kommentar ist sie eine Rückfrage. Eine Rückfrage
wird überarbeitet und geht danach ohne zweite Prüfung durch Lena auf „zur Freigabe“.

## Entscheidungen der Gründer (11.11.2026), verbindlich

- Entscheidung in der Oberfläche nur noch: Passt | Rückfrage. „Passt nicht“ wird nicht mehr angeboten; alte Einträge
  bleiben in der Historie lesbar.
- Ein Kommentar macht die Entscheidung zur Rückfrage. „Passt“ ist nur ohne offenen Kommentar möglich.
- Kommentar-Anker: grundgeruest | stufen | fehlbilder | beispiel (mit der konkreten Instanz). Je Anker höchstens ein
  Kommentar je Prüfung.
- Gründe je Anker (Schlüssel in der Datenbank, Texte über die Textdateien):
  beispiel: rechnung_falsch, text_unklar, hinweis_verraet_loesung, rueckmeldung_passt_nicht, loesungsweg_unklar
  grundgeruest: text_unklar, nicht_altersgerecht
  stufen: stufe_passt_nicht, zahlen_anders_waehlen
  fehlbilder: fehlbild_fehlt, fehlbild_unrealistisch, rueckmeldung_passt_nicht
  Ein Kommentar braucht mindestens einen Grund oder einen Text.
- Zeit je Stufe: ein Richtwert in Minuten, Schritte von 0,5, Bereich 0,5 bis 10. Vorbelegt mit dem heutigen Wert der
  Bauform für jede Stufe. Lena ändert direkt; die Änderung wird mit „Passt“ oder mit der Rückfrage gespeichert, erhöht
  NICHT die Version und öffnet die Bauform NICHT neu.
- Nach einer Rückfrage: Die überarbeitete Version geht automatisch auf „zur Freigabe“, wenn (a) jeder Kommentar der
  Rückfrage als erledigt markiert ist, mit kurzer Notiz, was geändert wurde, (b) die Prüfmaschine für die neue Version
  grün ist und (c) der Blindlöser bestanden ist. Sonst bleibt sie in Überarbeitung. Lena sieht sie nicht noch einmal in
  „Zu prüfen“.
- Lena setzt nie ready. Freigabe nur durch Admins über die bestehende Sammelfreigabe. Kein neuer Weg zu ready.
  „Prüfer ≠ Autor“ bleibt in der Datenbank.

## Leitplanken (Auszug)

- Diese Funktionen werden nicht geändert: aufgabe_ziehen, aufgabe_zwilling, aufgabe_werten, aufgabe_payload,
  task_status_set und die Sammelfreigabe der Bauformen (bauform_freigeben). Ausnahme: die eine Stelle, an der ein
  Versionswechsel die Bauform für Lena wieder öffnet.
- DDL nur als Migration mit Rollback; bestehende Migrationen nie ändern; keine löschenden Anweisungen auf Inhalte.
- Jede neue Tabelle sofort mit RLS. Kinder lesen nie.

## S1 · Datenmodell und Funktionen

1. Klartext je Stufe: je Bauform und Stufe ein Feld beschreibung und beispiel.
2. Zeit je Stufe: zeit_min numeric je Bauform und Stufe, vorbelegt mit dem heutigen Wert der Bauform. Funktion
   bauform_zeit_setzen(p_bauform, p_stufe, p_min) für darf_pruefen und Admins, mit Bereichsprüfung, ohne
   Versionswechsel; alter Wert, neuer Wert, wer und wann werden festgehalten. Die Stelle, an der die Session-Planung
   die Zeit liest, liest künftig die Zeit der Stufe (S0: es gibt keine solche Stelle, siehe offen.md O1).
3. Kommentare: bauform_kommentare (id, pruefung_id, bauform, version, anker, task_id nur bei anker = beispiel,
   gruende text[], text, status offen | erledigt, erledigt_notiz, erledigt_am). Gründe gegen die Liste geprüft. RLS:
   schreiben darf_pruefen für eigene Prüfungen, lesen darf_pruefen und Admins, Kinder nie.
4. bauform_pruefen(p_bauform, p_version, p_kommentare jsonb, p_dauer) als ein Aufruf: ohne Kommentar → Entscheidung
   passt, Status „zur Freigabe“; mit Kommentaren → Entscheidung Rückfrage, Kommentare gespeichert. Nutzt die bestehende
   Entscheidungsfunktion, statt sie zu ersetzen. Ein Kommentar ohne Grund und ohne Text wird abgelehnt.
   (Umgesetzt als bauform_pruefung_senden, weil eine Überladung von bauform_pruefen bestehende Aufrufe mehrdeutig
   machen würde.)
5. bauform_rueckfrage_erledigt(p_bauform, p_neue_version) setzt die neue Version auf „zur Freigabe“, wenn alle
   Kommentare der Rückfrage erledigt sind (mit Notiz), die Prüfmaschine grün und der Blindlöser bestanden ist; sonst
   Fehler mit Grund. Der Versionswechsel einer solchen Überarbeitung öffnet die Bauform nicht wieder für Lena; jeder
   andere Versionswechsel verhält sich wie bisher. Nur Admins bzw. der Dienstweg des Bauform-Exports dürfen das
   aufrufen, Lena nicht.
6. Auswertung: Sicht bauform_kommentar_auswertung (Grund, Anker, Bauform, Skill, Anzahl, letzte Texte) für Admins.
7. pgTAP für alle Fälle.
