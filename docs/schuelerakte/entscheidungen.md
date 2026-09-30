# Schülerakte — maßgebliche Entscheidungen (Paket S1)

Wörtlich aus `docs/schuelerakte/Bauauftrag-Schuelerakte.md` (Fassung 2, Stand 28.09.2026),
Abschnitt S1, Liste „MASSGEBLICHE ENTSCHEIDUNGEN“. Wo die Anforderung oder die Ist-Analyse
davon abweichen, gilt diese Liste. Die Migrationen verweisen mit „Entscheidung n“ hierher.

```text
1. Akte = students-Zeile. Keine Tabelle "akten". Sie besitzt nur Stammdaten und Notizen, alles andere zeigt sie an.
2. Zustand abgeleitet, nie gespeichert: aktiv, wenn das Kind einen Vertrag mit wirksamer_status in (aktiv, im_widerruf)
   hat (auch mit Beginn in der Zukunft), sonst ruhend. ruhend_seit = vertrag_ende des letzten Vertrags,
   akte_seit = abgeschlossen_am des ersten. Testfall im PR: in der Lücke vor einem unterschriebenen Folgevertrag
   dasselbe Ergebnis wie hat_zugang; weicht es ab, melden, nicht still angleichen.
3. Laufender Vertrag = Vertrag in (aktiv, im_widerruf), dessen Zeitraum heute enthält; sonst der mit dem nächsten
   Beginn (→ art 'vorher').
4. Anwesenheit: session_students.attendance bekommt genau diese Werte:
   planned | present | cancelled | unexcused | cancelled_by_us
   (geplant | anwesend | abgesagt | unentschuldigt | ausgefallen durch uns).
   Umstellung: present → present, absent → unexcused, unknown → planned (Prod enthält nur Testdaten).
   In der Session setzt der Coach nur present oder unexcused ("nicht erschienen"). cancelled und cancelled_by_us
   setzt später das Slots-Feature; jetzt nur als erlaubte Werte anlegen. setAttendance (sessions.ts) und jeden
   Aufrufer anpassen; das Session-UI bekommt zwei Knöpfe "anwesend" / "nicht erschienen".
5. Verbraucht: Funktion einheit_verbraucht(attendance text) → true genau für present und unexcused. Nirgends sonst entscheiden.
6. Betriebstag = Mo–Fr, nicht in ferien_nrw (bestehende Tabelle, Namen prüfen), nicht in feiertage_nrw.
   Neue Tabelle feiertage_nrw (datum date primary key, art check in feiertag|pfingstferien, name), befüllt 2026–2030:
   je Jahr Neujahr, Karfreitag, Ostermontag, 1. Mai, Christi Himmelfahrt, Pfingstmontag, Fronleichnam, 3. Oktober,
   Allerheiligen, 25. und 26. Dezember (Oster-abhängige aus dem Osterdatum), und je Jahr der Pfingstferientag
   (Dienstag nach Pfingstmontag): 2026-05-26, 2027-05-18, 2028-06-06, 2029-05-22, 2030-06-11.
   Im PR die Liste gegen die Ferienordnung des Schulministeriums NRW abgleichen und die Quelle nennen.
   RLS: lesen authenticated, schreiben niemand. Das Slots-Feature nutzt dieselbe Tabelle später mit.
7. Ampelschwellen 1.5 / 3.5 in einer eigenen Tabelle akte_einstellungen (vertrag_einstellungen taugt nicht).
8. Notizen: nur anhängen, kein UPDATE am Text. Admin: ausblenden (Pflicht-Grund), einblenden, Gesundheitsangabe
   endgültig entfernen (text NULL, entfernt_von/_am/_grund bleiben). Coach: nur anlegen, nur in aktiven Akten, sieht
   keine ausgeblendeten und keine entfernten Texte.
9. Wortliste akte_wortliste (wort, nur_ganzes_wort, liste check in gesundheit|report_verbot). Startinhalt Liste
   gesundheit: adhs*, ads*, allergi, diagnos, medikament, krank, therapie, therapeut, legasthen, lrs*, dyskalkul,
   autis, depress, asthma, epilep, arzt, ärzt, attest, tabletten, psych (* = nur ganzes Wort).
   Liste report_verbot bleibt leer (füllt das Feature Eltern-Reports). Prüfung serverseitig in notiz_anlegen,
   Fehlertext verständlich. Frontend liest die Liste (S2).
10. Reports: Tabelle eltern_reports = nur VERSENDETE Reports, unveränderlich. Das spätere Feature Eltern-Reports
    führt seine Entwürfe in einer eigenen Arbeitstabelle und schreibt beim Versand hier hinein.
    Spalten: id, student_id, nr (je Kind fortlaufend über alle Verträge, vergeben beim Einfügen, unique(student_id, nr)),
    art (lernstandsanalyse | zwischenbericht), berichtsmonat date null, kernaussagen jsonb (Fach → Satz),
    freigegeben_von uuid null, freigegeben_am null, versendet_am null, versendet_an null, pdf_pfad null,
    parent_report_id null (FK parent_reports), lsa_session_id null.
    Nach dem Einfügen unveränderlich (Trigger), einzige Ausnahme: pdf_pfad einmalig von NULL auf einen Wert.
    Einfügen nur über SECURITY DEFINER-Funktion eltern_report_eintragen(...) (Admin), die nr atomar vergibt.
    KEINE Freigabe-, PDF- oder Versandlogik bauen.
    Report 1: vertrag_abschliessen ruft beim ersten Vertrag eines Kindes eltern_report_eintragen für die LSA auf
    (über lsa_sessions.student_id); Felder, die es heute nicht gibt (freigegeben_von, versendet_am, pdf_pfad), bleiben NULL.
    lsaReport.ts: Rückweg Lead ↔ Schüler über leads.converted_student_id reparieren.
11. Fächer: vertrag_abschliessen zieht student_subjects auch bei Folgeverträgen nach.
12. Coach-Rechte (RLS + SECURITY DEFINER), gilt auch für direkte Adressen:
    - Zuerst jede Stelle in Frontend und Datenbank auflisten, die als Coach students, profiles, leads, parent_student,
      vertraege oder vertrag_* liest. Für jede Stelle festlegen, wie sie danach funktioniert (meist schmale RPC).
    - Danach: Coaches lesen leads, parent_student, vertraege, vertrag_* nicht mehr direkt. students nur für Kinder mit
      aktiver Akte, plus das, was der LSA-Kiosk nachweislich braucht.
    - Einheiten und Stichtag erreichen Coaches nur über einheiten_stand, nie über SELECT auf vertraege.
    - Admin unverändert.
13. Nicht in diesem Paket: Löschfrist, Klassenwechsel, Freigabe/PDF/Versand von Reports, Slots-Logik (Absagen,
    10-Uhr-Regel, Stammplätze), Oberfläche der Akte.
```
