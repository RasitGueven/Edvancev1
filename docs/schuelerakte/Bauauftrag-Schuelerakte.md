# Bauauftrag Schülerakte — Arbeitspakete für Claude Code (Fassung 2)

**Stand:** 28.09.2026 · **Entscheider:** Rasit · **Ersetzt:** Fassung 1 vom 25.09.2026
**Grundlage:** Anforderung-Schuelerakte.md, schuelerakte-dummy.html, Ist-Analyse S0 (`docs/schuelerakte/ist-analyse-s0.md`), und die Abschnitte „Auswirkungen auf andere Dokumente“ aus Anforderung-Slots.md und Anforderung-Eltern-Reports.md.

## Was sich gegenüber Fassung 1 geändert hat

| Thema | Fassung 1 | Fassung 2 | Quelle |
|---|---|---|---|
| Anwesenheit | anwesend / entschuldigt / unentschuldigt | **anwesend / abgesagt / unentschuldigt / ausgefallen (durch uns)**, dazu „geplant“ vor dem Termin; in der Session erfasst der Coach nur „anwesend“ oder „nicht erschienen“ (= unentschuldigt) | Slots F 35–40 |
| Einheit verbraucht | nur anwesend | **anwesend + unentschuldigt** | Slots F 40 |
| Betriebstage | Kalendertage ohne Ferien | **Werktage (Mo–Fr) ohne NRW-Ferien, gesetzliche Feiertage NRW und Pfingstferientag** | Slots, Auswirkungen auf Schülerakte |
| Betriebswochen | Betriebstage ÷ 7 | **Betriebstage ÷ 5** (folgt aus Werktagen) | Folgerung |
| Kontrollwerte | 16,7 / 44,6 / 8,3 | **neu gerechnet, siehe S1 Teil B** | Folgerung |
| Reports | „freigebender Coach“, ein Fach | **„freigegeben von“** (bei Zwischenberichten ein Admin), **Kernaussage je Fach** | Eltern-Reports, Auswirkungen |
| Report-Einfrierung | in S1 | **nicht in S1**; S1 baut nur die unveränderliche Tabelle der versendeten Reports, das Feature Eltern-Reports schreibt hinein | Eltern-Reports E 29–33 |
| Coach-Rechte | „Coach sieht keine Vertragsdaten“ | S0 hat gezeigt: Coaches lesen heute alle students, leads (mit Elternkontakt) und parent_student. **S1 schließt das**, als eigene Migration mit Rollback | S0 |
| Badges „gemeistert“ | aus App-Badges | aus **student_competency_mastery.mastered_by/_at** (student_badges hat keinen Bestätigenden) | S0 |

## Pakete

| Paket | Inhalt | Braucht | Stand |
|---|---|---|---|
| S0 | Ist-Analyse | – | **erledigt** (28.09.2026) |
| S1 | Datenmodell, Einheiten-Stand, Notizen, Report-Tabelle, Coach-RLS | Verträge P1–P3a eingespielt (ja) | offen |
| S2 | Menü „Schüler“: Board und Akte | S1 eingespielt | offen |
| S3 | Kachel Fortschritt | S1 eingespielt | offen |

## Ergebnisse S0 (Kurzfassung, Details in ist-analyse-s0.md)

- **Stammdaten:** students + profiles.full_name; vertraege_aktuell (security_invoker) mit wirksamer_status, ist_aktueller_vertrag. Neu: schule_id, Aktenzustand.
- **LSA:** lsa_sessions.student_id bleibt nach vertrag_abschliessen erhalten (dieselbe students-Zeile). lsaReport.ts sucht über students.lead_id und findet nach dem Abschluss nichts mehr; Rückweg über leads.converted_student_id nötig.
- **Anwesenheit:** session_students.attendance mit present / absent / unknown, gesetzt über setAttendance (sessions.ts:118).
- **Fächer:** student_subjects / subjects, nur beim Erstvertrag geschrieben.
- **Reports:** parent_reports hält den Inhalt, es gibt keine feste versendete Fassung. vertrag_versand ist das Muster für Versandprotokolle.
- **Lernpfad/Mastery:** student_focus_areas, student_progress, student_competency_mastery (mastered_by/_at). Gleiches Supabase-Projekt wie die App, keine Schnittstelle nötig.
- **Rollen:** coach existiert, get_my_role(), ProtectedRoute. Lücke: Coaches lesen students, leads und parent_student vollständig.
- **Wortliste:** vertrag_einstellungen ist einzeilig und nur für Admins lesbar, also ungeeignet; eigene Tabelle.
- **Löschen:** kein pg_cron; vertraege.student_id ON DELETE RESTRICT.
- **Routing:** Muster in App.tsx; Kachel „Schülerakte“ im AdminDashboard ist als Platzhalter angelegt.
- **Verträge:** P1, P2, P3a eingespielt; offen: Migration 20260926090000_laufzeit_monat_vor_beginn (untracked) und P3b (UI, unkommittiert).

## Vorbereitung durch Rasit

1. Migration `20260926090000_laufzeit_monat_vor_beginn.sql` prüfen und einspielen, P3b committen und als PR stellen. Erst dann S1 — sonst mischt sich die Arbeit.
2. Einspielen wie gewohnt: `dbcheck && psql … -1 -f … && insert schema_migrations && tools/schema-snapshot.sh`.

---

## S1 — Datenmodell, Einheiten-Stand, Notizen, Reports, Coach-Rechte

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket S1 des Bauauftrags Schülerakte, Fassung 2.
Verträge P1, P2, P3a sind eingespielt.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree, damit andere offene Arbeit unberührt bleibt:
  git fetch && git worktree add ../Edvancev1-s1 -b feat/rasit-schuelerakte-s1-datenmodell origin/dev
  (existiert er schon: weiterverwenden, nicht neu anlegen). Arbeite nur dort.
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Du führst KEIN DDL und KEINE schreibende Abfrage aus. Lesend nur nach `dbcheck` = "PROD OK", sonst abbrechen.
- Migrationen nur als Datei unter supabase/migrations/<YYYYMMDDHHMMSS>_<name>.sql. Rasit spielt ein.
- Vor jeder Änderung an Spalten, Policies oder Funktionen: pg_proc-Scan und Repo-Suche nach allen Aufrufern, im PR auflisten.
- RLS-Änderungen: Consensus-Check nach CLAUDE.md vollständig durchführen und ins PR legen.
- Datumsarithmetik nur über date. Vertragsstatus nur aus vertraege_aktuell.wirksamer_status.
- Jede Aussage im PR mit Beleg (Datei:Zeile oder Abfrage-Ausgabe).

KONTEXT (in dieser Reihenfolge lesen)
1. docs/schuelerakte/Bauauftrag-Schuelerakte.md — Abschnitte "Was sich geändert hat" und "Ergebnisse S0".
2. docs/schuelerakte/ist-analyse-s0.md — vollständig.
3. docs/schuelerakte/Anforderung-Schuelerakte.md.
Wo 2 oder 3 der Liste unten widersprechen, gilt die Liste.

MASSGEBLICHE ENTSCHEIDUNGEN
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

LIEFERUMFANG
A) Drei Migrationen, in dieser Einspielreihenfolge:
   1. <ts>_schuelerakte_basis.sql: feiertage_nrw, akte_einstellungen, akte_wortliste, students.schule_id (FK schulen),
      Klasse 8|9|10 (vorhandene Spalte nutzen, falls da), attendance-Umstellung, einheit_verbraucht, betriebstag(date),
      betriebstage(von, bis).
   2. <ts>_schuelerakte_akte.sql: View schuelerakten (security_invoker: student_id, name, klasse, schule, akte_seit,
      zustand, ruhend_seit, letzte_session = letzte mit present), einheiten_rechnung, einheiten_stand, board_schueler,
      schueler_notizen + RPCs notiz_anlegen / notiz_ausblenden / notiz_einblenden / notiz_gesundheit_entfernen
      (jeweils audit_log_schreiben), eltern_reports + eltern_report_eintragen, Änderungen an vertrag_abschliessen.
   3. <ts>_coach_rls.sql, dazu Rollback-Datei docs/schuelerakte/rollback_coach_rls.sql.
   Funktionen:
   - einheiten_rechnung(einheiten, beginn, stichtag, verbraucht, heute) — reine Rechnung, IMMUTABLE bzw. STABLE:
     soll = E · betriebstage(beginn, heute−1) / betriebstage(beginn, stichtag)
     rueckstand = soll − verbraucht; offen = greatest(E − verbraucht, 0)
     wochen_rest = betriebstage(heute, stichtag) / 5.0
     noetig = offen / wochen_rest (bei 0 Wochen: offen); gleichmaessig = E / (betriebstage(beginn, stichtag) / 5.0)
     ampel: rueckstand ≤ schwelle_1 → im_plan; ≤ schwelle_2 → leicht_im_rueckstand; sonst deutlich_im_rueckstand
   - einheiten_stand(p_student, p_heute default current_date): SECURITY DEFINER; Admin immer, Coach nur bei aktiver
     Akte, sonst 42501. Liefert art ('laufend'|'vorher'|'keiner'), einheiten, beginn, stichtag, verbraucht, offen,
     soll, rueckstand, ampel, wochen_rest, noetig_pro_woche, gleichmaessig_pro_woche.
     verbraucht = Anzahl session_students mit einheit_verbraucht(attendance) zwischen Beginn und Stichtag des
     laufenden Vertrags.
   - board_schueler(): alle für die Rolle sichtbaren Akten samt Einheiten-Stand in EINER Abfrage (kein N+1,
     Ziel 300 Kinder unter 300 ms; EXPLAIN ANALYZE lesend im PR).
B) tests/sql/einheiten_stand_test.sql — lesend, feste Werte, heute = 2028-03-13, eine Nachkommastelle, OK/FEHLER je Zeile:
   | Einheiten | Beginn | Stichtag | verbraucht | soll | Rückstand | Ampel | Wochen rest | nötig | gleichmäßig |
   | 29 | 2027-11-01 | 2028-06-15 | 14 | 17,2 | 3,2 | leicht_im_rueckstand | 10,8 | 1,4 | 1,1 |
   | 76 | 2027-09-01 | 2028-08-31 | 46 | 45,8 | −0,2 | im_plan | 15,4 | 1,9 | 2,0 |
   | 57 | 2028-02-01 | 2029-01-31 | 4 | 8,6 | 4,6 | deutlich_im_rueckstand | 32,6 | 1,6 | 1,5 |
   | 76 | 2028-04-01 | 2029-03-31 | – | art 'vorher' |
   Betriebstage dazu (zur Fehlersuche mit ausgeben): Fall 1 gesamt 133 / bis gestern 79 / ab heute 54;
   Fall 2 194 / 117 / 77; Fall 3 192 / 29 / 163.
   Plus: einheit_verbraucht('unexcused') = true, ('cancelled') = false, ('cancelled_by_us') = false;
   notiz_anlegen lehnt "Allergie" ab und akzeptiert "Standardaufgaben"; betriebstag('2028-06-06') = false
   (Pfingstferientag), betriebstag('2028-06-15') = false (Fronleichnam), betriebstag('2028-03-13') = true.
C) tests/sql/coach_rls_test.sql: mit gesetzten Coach-Claims in einer Transaktion mit ROLLBACK (lesend):
   0 Zeilen aus leads, parent_student, vertraege; einheiten_stand einer ruhenden Akte → 42501;
   eltern_reports einer aktiven Akte lesbar, einer ruhenden nicht.
D) docs/schuelerakte/entscheidungen.md = die Liste MASSGEBLICHE ENTSCHEIDUNGEN wörtlich.
E) PR: Objektliste, pg_proc-Scan, Aufruferliste Coach (Punkt 12) mit Lösung je Stelle, Consensus-Check,
   Einspielbefehle nach Rasits Muster in der Reihenfolge 1 → 2 → 3, Rollback-Weg für 3, EXPLAIN von board_schueler.

ABNAHME
Nach dem Einspielen liefern beide Testdateien nur OK. Als Coach eingeloggt funktionieren Sessionplan, Anwesenheit
setzen und LSA-Kiosk weiterhin (Screenshots im PR).
```

---

## S2 — Menü „Schüler“, Board und Akte

```text
Du arbeitest im Repo Edvancev1. Paket S2 des Bauauftrags Schülerakte, Fassung 2. S1 ist eingespielt und gemergt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-schuelerakte-s2-ui origin/dev · PR gegen dev, nie main · nichts unter .github/.
- Kein DDL, keine schreibenden Abfragen. Migrationen nur als Datei. Lesend nur nach `dbcheck` = "PROD OK".
- Design: nur bestehende Design-Tokens und Komponenten, keine freien Hex-Werte, keine Inline-Styles.
  Der Dummy zeigt Ablauf und Inhalt, nicht das Design.
- Keine Rechenlogik im Frontend: Board aus board_schueler, Einheiten-Stand aus einheiten_stand, Zustand aus schuelerakten.
- Notizen nur über die RPCs aus S1.

KONTEXT
docs/schuelerakte/entscheidungen.md (maßgeblich), docs/schuelerakte/Bauauftrag-Schuelerakte.md (Tabelle
"Was sich geändert hat"), docs/schuelerakte/Anforderung-Schuelerakte.md (B–H, Rechte, Abnahme),
docs/schuelerakte/schuelerakte-dummy.html (Ablauf).

UMFANG
1. Hauptmenüpunkt "Schüler" für Admin und Coach (Kachel-Platzhalter im AdminDashboard ersetzen, Kachel im
   CoachDashboard). Routen /admin/akten und /admin/akten/:id nach dem Muster in App.tsx, mit Rollenprüfung.
   Coach ruft ruhende Akte direkt auf → zurück aufs Board mit "Ruhende Akten sind für Coaches nicht sichtbar."
2. Board (Anforderung B 4–10): Spalte je vorhandener Klassenstufe, seitlich scrollbar; Karte mit Name, Schule,
   Ampel + "x von y verbraucht" bzw. "startet am …", letzte Session, bei ruhend der Zustand. Suche je Spalte
   (Anzahl "x von y"), Suche über alle Klassen mit Gesamttreffern, beide wirken zusammen. Sortierung Nachname /
   größter Rückstand zuerst. Filter Zustand nur Admin (aktiv Standard, ruhend, alle). Spalten scrollen einzeln,
   leere Spalte/Suche mit Hinweis.
3. Akte: Kopf (C), Einheiten-Stand (D) mit Balken, Soll-Markierung, Ampel und dem Satz "Um alle offenen Einheiten
   bis zum Stichtag zu nutzen, braucht es ab jetzt x Einheiten pro Betriebswoche — gleichmäßig verteilt wären es y.",
   Sessions (E) mit Zuständen anwesend / abgesagt / unentschuldigt / ausgefallen (durch uns) und Summe je Zustand,
   letzte 8, Rest aufklappbar; Notizen (F); Stammdaten (G: Admin bearbeitet Name, Klasse, Schule aus schulen mit
   "neu anlegen"; Coach liest; Fächer nur anzeigen); Reports (H) aus eltern_reports: Nummer, Art, je Fach die
   Kernaussage, "freigegeben von" (leer lassen, wenn NULL), Versanddatum, Link auf pdf_pfad (signierte URL; ohne
   Datei: "keine gespeicherte Fassung").
   Kachel Fortschritt als Platzhalter, kommt in S3.
4. Notizfeld: Live-Prüfung gegen akte_wortliste (Liste gesundheit), Hinweis und gesperrtes Speichern; dauerhafter
   Hinweistext wie im Dummy; Kategorie Pflicht. Admin: ausblenden (Pflicht-Grund), einblenden, "Gesundheitsangabe
   entfernen" (Bestätigung, endgültig). Anzeige ausgeblendet: durchgestrichen mit Grund, Name, Datum (nur Admin).
   Anzeige entfernt: nur "entfernt von … am …, Grund: Gesundheitsangabe".
5. Ruhende Akte: Hinweisbox (C 12), kein Einheiten-Stand, Notizfeld nur für Admin.
6. Wortwahl: "verbraucht" statt "genutzt"; "gemeistert" nirgends außer bei coach-bestätigter Mastery (S3);
   Ampeltexte "im Plan", "leicht im Rückstand", "deutlich im Rückstand".

ABNAHME
Abnahmefälle 1–13 aus Anforderung-Schuelerakte.md, mit den Änderungen aus der Tabelle "Was sich geändert hat"
(Fall 7: Kontrollwerte aus S1 Teil B; Fall 11: "freigebende Person"; Fall 12 ohne Lernpfad-Teil).
Im PR Screenshots: Board Admin und Coach, Akte im Plan / leicht / deutlich / startet noch / ruhend, Notiz mit
Gesundheitshinweis, ausgeblendete und entfernte Notiz in der Admin-Sicht.
```

---

## S3 — Kachel Fortschritt

```text
Du arbeitest im Repo Edvancev1 und liest edvance-app mit. Paket S3 des Bauauftrags Schülerakte, Fassung 2. S1 ist eingespielt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-schuelerakte-s3-fortschritt origin/dev · PR gegen dev, nie main · nichts unter .github/.
- Kein DDL, keine schreibenden Abfragen. Migrationen nur als Datei. Lesend nur nach `dbcheck` = "PROD OK".
- Keine Änderung an edvance-app. Keine XP, keine Streaks, keine Home Quests in der Akte.

KONTEXT
docs/schuelerakte/ist-analyse-s0.md (Lernpfad und Mastery), docs/schuelerakte/Anforderung-Schuelerakte.md I 37–40.

UMFANG
1. Lesende Funktion fortschritt(p_student) (SECURITY DEFINER, gleiche Rechteprüfung wie einheiten_stand):
   je Fach aktuelles Thema und Station "x von y" aus student_focus_areas / student_progress;
   zuletzt bestätigte Kompetenzen aus student_competency_mastery mit mastered_by (Name des Coaches) und mastered_at.
   Nur Einträge mit gesetztem mastered_by zählen als "gemeistert". System-Evidenz ohne Bestätigung erscheint nicht.
2. Kachel Fortschritt in der Akte (ersetzt den Platzhalter aus S2), höchstens 4 Einträge je Fach, "und n weitere".
3. student_badges wird hier nicht angefasst (kein Bestätigender). Im PR vermerken, falls die App "gemeistert" aus
   student_badges statt aus der Mastery-Tabelle zeigt.

ABNAHME
Ein Kind mit zwei coach-bestätigten und einer nur vom System erkannten Kompetenz zeigt genau zwei Einträge mit
"gemeistert". Eine ruhende Akte behält ihren Lernpfad-Stand (Admin-Sicht).
```

---

## Außerhalb der Pakete

- **Offen, fachlich:** Löschfrist ruhender Akten und Frist nach Widerruf (Anforderung Frage 13), Klassenwechsel und Klasse 11 (Frage 14), Übertrag offener Einheiten beim Folgevertrag (Frage 12, bis dahin: kein Übertrag), Ampelschwellen (Frage 11, bis dahin 1,5 / 3,5).
- **Später, andere Features:** Absagen, 10-Uhr-Regel, Stammplätze und „ausgefallen (durch uns)“ (Slots); Entwurf, Freigabe, PDF und Versand der Zwischenberichte (Eltern-Reports); Einfrieren und Versandprotokoll der LSA als Report 1 (Eltern-Reports, technische Frage 1).
- **Anforderung und Dummy Schülerakte** sind noch nicht auf Slots und Eltern-Reports nachgezogen (Tolunay). Bis dahin gilt die Tabelle „Was sich geändert hat“.
