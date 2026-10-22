# Bauauftrag LR-1 · Menüpunkt „LSA-Reports“ (Präsentation + PDF)

Stand 22.10.2026 (Fassung 2; Fassung 1 vom 21.10.). Ein kleines Paket in Edvancev1, ohne Migration.
Neu in Fassung 2: Kennzeichen auch für Testkonten (die fünf Testkinder aus LSA-T sind Testkonten, keine
Testläufe) und eine Spalte „Thema“.

## Befund (dev, Stand 1013913: R7-11, LSA-V und LSA-T sind gemergt)

- Den Report gibt es schon im neuen Design: `/admin/report/:sessionId` (ReportPage) zeigt nur noch
  den Druckbogen R7. Mit `?ansicht=praesentation` liegt die Tablet-Präsentation als Vollbild darüber.
  „Drucken“ ruft `window.print()` und druckt den Bogen.
- Erreichbar ist ein Report heute nur über die Lead-Karte und „Heute“. Eine Übersicht fehlt.
- In der Admin-Leiste steht unter Verwaltung schon der Platzhalter `lsaErgebnisse` („LSA-Ergebnisse“,
  `bald: true`, ohne Route).
- `/admin/report/*` markiert in der Leiste heute „Item-Pflege“ als aktiv. Das ist falsch.
- Die alte Report-Seite `/coach/reports` (ReportsPage, alter Rahmen) bleibt außen vor und wird
  nirgends verlinkt.
- Einen serverseitigen PDF-Weg für den Bogen gibt es nicht. Das PDF entsteht über den Druckdialog
  („Als PDF sichern“).

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket LR-1: Menüpunkt „LSA-Reports“ in der Admin-Leiste mit einer Liste aller abgeschlossenen LSAs. Je Zeile lässt sich der Report im neuen Design als Präsentation öffnen oder als PDF sichern. Lies zuerst CLAUDE.md, src/pages/admin/ReportPage.tsx, src/components/edvance/admin/adminNav.ts, src/lib/supabase/lsaReport.ts und src/components/edvance/EdvanceTable.tsx. Lege diesen Bauauftrag als docs/admin/Bauauftrag-LR-1.md im PR ab.

## Entscheidungen (nicht neu verhandeln)
1. Leiste: Aus dem Platzhalter lsaErgebnisse wird ein echter Eintrag.
   - id lsaReports, route /admin/lsa-reports, kein bald mehr.
   - aktivBei ['/admin/lsa-reports', '/admin/report/*'].
   - '/admin/report/*' fliegt aus aktivBei von itemPflege.
   - Name „LSA-Reports“, kurz „LSA“ (Keys nav.lsaReports / nav.kurz.lsaReports in de/admin.json; die alten lsaErgebnisse-Keys entfernen, wenn sie sonst niemand nutzt).
   - Icon und Gruppe (Verwaltung) bleiben. Eltern-Reports bleibt „bald“.
   - coachNav bleibt unverändert.
2. Route /admin/lsa-reports in App.tsx innerhalb der AdminLayout-Route, ProtectedRoute allowedRoles={['admin']}, umleitungFuer={{ coach: '/coach' }}.
3. Daten: neue Datei src/lib/supabase/lsaReportListe.ts mit listLsaReports(): SupabaseResult<LsaReportListItem[]>.
   - Nur lsa_sessions mit status = 'completed'. Abgebrochene und laufende LSAs erscheinen nicht.
   - Testläufe und Testkonten erscheinen, mit Kennzeichnung (heute gibt es nur Test- und Phantasiedaten).
   - Spalten aus lsa_sessions: id, student_id, subject, grade, completed_at, testlauf, modus, thema_key. Dazu students.ist_test des Kindes und das Themen-Label (themen.label über thema_key; fehlt es, leer).
   - Rufname über loadNames aus lsaReport.ts. Exportiere dafür loadNames; das ist die einzige Änderung in lsaReport.ts. Kein Kind ohne Namen fällt heraus; die Liste zeigt dann „Ohne Namen“ (eigener Key in admin.json, nicht das elterngerichtete „Ihr Kind“ aus report.json).
   - Sortierung: completed_at absteigend (neueste oben).
   - try/catch wie in lsaReport.ts. Typ LsaReportListItem in src/types/report.ts.
   - Kein neues RPC, keine Migration. Die RLS lässt den Admin lsa_sessions, students und themen bereits lesen; prüf das mit dbread. Fehlt ein Leserecht: STOPP und melden.
4. Seite src/pages/admin/lsaReports/LsaReportsPage.tsx:
   - PageHeader „LSA-Reports“, darunter EdvanceTable (Admin-Ausnahme aus CLAUDE.md).
   - Spalten: Kind · Klasse · Fach · Thema · LSA vom (Datum über Intl.DateTimeFormat, Europe/Berlin) · Kennzeichen · Aktionen.
   - Kennzeichen (EdvanceBadge): „Testlauf“, wenn testlauf; sonst „Testkonto“, wenn ist_test; sonst nichts.
   - Aktionen je Zeile:
     - Präsentation (primär, Icon Presentation) → /admin/report/:id?ansicht=praesentation
     - PDF (sekundär, Icon FileDown) → /admin/report/:id?aktion=pdf
     - Klick auf den Namen → /admin/report/:id (Bogen wie bisher)
   - Eine Suchzeile über dem Tisch filtert clientseitig nach Rufname. Kein weiterer Filter.
   - LoadingPulse beim Laden, EmptyState ohne Treffer, Fehler als Hinweis wie in ReportPage.
   - Alle Texte über i18n (Namespace admin, Block lsaReports.*). Touch-Ziele min. 44 px; die Seite muss auf dem iPad quer und hoch bedienbar sein.
5. PDF in ReportPage: ?aktion=pdf öffnet den Druckdialog automatisch, genau einmal.
   - Erst drucken, wenn der Bericht geladen ist, die Pakete nicht mehr „laedt“ sind und document.fonts.ready erfüllt ist. Danach zwei requestAnimationFrame, damit der Bogen steht.
   - Vor dem Druck document.title auf „Edvance LSA-Report {Name} {TT.MM.JJJJ}“ setzen (i18n-Key, Datum = analysedAt). Chrome und Safari nehmen das als Dateinamen.
   - Nach afterprint den alten Titel zurücksetzen und aktion aus der URL entfernen (replace). Andere Parameter bleiben.
   - Kein Druck, wenn der Bericht einen Fehler hat. Im Testlauf erscheint der bestehende Hinweis; gedruckt wird trotzdem.
   - Der bestehende Knopf „Drucken“ bekommt denselben Titel-Mechanismus (gemeinsame Funktion).
   - Kein serverseitiges PDF, keine neue Bibliothek.
6. Kein Eingriff in Bericht und Präsentation selbst: src/components/edvance/elternbericht/**, praesentation/**, src/styles/** bleiben unberührt.

## Umfang
- src/components/edvance/admin/adminNav.ts, src/App.tsx
- src/lib/supabase/lsaReportListe.ts (neu), src/lib/supabase/lsaReport.ts (nur export loadNames), src/types/report.ts (nur LsaReportListItem)
- src/pages/admin/lsaReports/** (neu), src/pages/admin/ReportPage.tsx (nur Entscheidung 5, ggf. Hilfsfunktion in eigener Datei daneben)
- src/i18n/locales/de/admin.json (und report.json nur für den Titel-Key)
- Tests, docs/admin/Bauauftrag-LR-1.md, Retro
- Nicht anfassen: supabase/**, schema*.sql, elternbericht/**, praesentation/**, src/styles/**, /coach/reports, coachNav, src/pages/coach/pruefen/** (dort arbeitet parallel ein anderer Agent).

## Tests
- Vitest listLsaReports (gemockter Client): nur completed, Sortierung, Testlauf- und Testkonto-Kennzeichen, Thema-Label, Kind ohne Rufname bleibt drin.
- Vitest LsaReportsPage: drei Aktionen zeigen auf die richtigen URLs; Suche filtert; EmptyState; beide Kennzeichen.
- Vitest ReportPage: ?aktion=pdf ruft window.print genau einmal, erst nach dem Laden. Titel ist während des Drucks gesetzt und danach zurück. aktion ist danach weg. Bei Fehler kein Druck. Die bestehenden Tests in ReportPage.praesentation.test.tsx bleiben grün.
- shell.test.tsx: /admin/report/x markiert lsaReports, nicht itemPflege.
- Typecheck, Lint, Vitest, Invarianten grün. Dateien ≤ 400 Zeilen, Feature ≤ 300 Zeilen ohne Tests.

## Leitplanken
- Worktree ../Edvancev1-lr1 auf feat/rasit-lsa-reports-menue von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, keine Auth-/RLS-Änderung. Prod nur lesend über dbread.
- Keine Hex-Werte, keine Inline-Styles, keine hardcodierten Texte.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler. Im PR vermerken, nichts ändern.
- Keine Zweitprüfung nötig (kleines Paket). STOPP nach dem PR.

## Melden
- PR-Link
- Bildschirmfotos: Leiste mit aktivem „LSA-Reports“, die Liste (iPad quer 1180×820 und hoch 820×1180), leere Liste
- Bestätigung, dass PDF den Druckdialog mit dem neuen Titel öffnet (Bildschirmfoto des Dialogs aus Chromium)
- offene Punkte
```
