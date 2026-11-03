# Bauauftrag LR-2 — LSA-Report per Mail an die Eltern

**Repo:** Edvancev1 · **Basis:** `dev` (Stand cf38255, 02.11.2026) · **PR gegen:** `dev`
**Vorgänger:** LR-1 (Menüpunkt LSA-Reports), R7/Bericht v4 (Druckbogen)

## Ziel

Der Knopf „Per E-Mail senden“ auf `/admin/report/:sessionId` verschickt den Eltern-Bericht der LSA als PDF über hello@. Ein Klick öffnet einen Dialog mit Empfänger und Mailtext, ein zweiter Klick verschickt. Danach liegt das versendete PDF eingefroren im Speicher. Jeder Versuch steht im Protokoll, auch ein gescheiterter.

## Ist-Stand (geprüft)

- `src/pages/admin/ReportPage.tsx` ~Z. 290: Der Knopf ist mit `disabled` fest gesperrt. Der Kommentar „keine Mail-Infrastruktur“ ist veraltet, ebenso der Tooltip `report.json → actions.emailTooltip` („kommt mit dem Eltern-Zugang“).
- **Edge Function `mail_senden`:** Sie versendet über Microsoft Graph aus hello@ (`_shared/graph_mail.ts`, Anhänge möglich). Sie kennt vier Anlässe: `bestaetigung`, `unterlagen`, `zugangscode` und `terminbestaetigung`. Die Terminbestätigung (`termin.ts`) ist das Vorbild: Sie hängt am Lead, schickt an `leads.contact_email`, nimmt keine freie Adresse aus dem Request und protokolliert über `lead_mail_protokollieren` in `lead_mail_versand`.
- **PDF:** Der Druckbogen (`ElternberichtBogen`, Seiten `.eb-seite`) entsteht nur im Browser und wird bisher über `window.print()` gespeichert (`reportDruck.ts`). Serverseitig gibt es kein Report-PDF.
- **Lead:** `getReportData` liefert `leadId`, aufgelöst über `students.lead_id` oder `leads.converted_student_id`.
- **Größe:** `graph_mail.ts` schickt Anhänge inline. Graph nimmt so höchstens etwa 3 MB je Anhang an, ein Upload-Session-Weg fehlt.

## Entscheidungen

1. **Das PDF entsteht im Browser aus dem fertigen Bogen.** Jede `.eb-seite` wird in natürlicher A4-Größe gerendert, also nicht in der am Bildschirm eingepassten Größe. Jede Seite wird als Bild auf eine A4-Seite gelegt, zum Beispiel mit `modern-screenshot` oder `html-to-image` plus `jspdf`. Der Agent wählt die Bibliothek, die Schriften (Literata, Schibsted Grotesk) zuverlässig einbettet. Begründung: Der Bogen misst nach dem Schriftladen (Namensregel, Stufen auf Seite 4), und ein Nachbau auf dem Server würde davon abweichen. Folge: Der Text im PDF ist nicht markierbar. Das ist akzeptiert.
2. **Das PDF zeigt genau, was „Drucken“ zeigt:** gleicher Bogen, gleicher Preise-Schalter (`?preise=an`) und gleicher Ausblick. Der Dateiname ist der Drucktitel aus `druckeMitTitel`, mit `.pdf` am Ende.
3. **Grenzen:** höchstens 2,5 MB je PDF und mindestens 200 dpi effektiv. Ist die Datei zu groß, wird zuerst die JPEG-Qualität gesenkt und dann die Auflösung, bis zur Untergrenze. Liegt sie danach noch darüber, kommt eine klare Fehlermeldung und es wird nichts verschickt.
4. **Ablage:** Es gibt einen neuen privaten Bucket `lsa_reports`, Pfad `{session_id}/{yyyyMMdd-HHmmss}.pdf`. Hochladen darf nur ein Admin (RLS) mit `upsert: false`. Jede versendete Fassung bleibt liegen, nichts wird überschrieben. Damit kann die LSA später „Report 1“ in der Schülerakte werden (nicht Teil dieses Auftrags).
5. **Empfänger:** Er ist immer `leads.contact_email` des Leads zur Sitzung. Die Edge Function ermittelt Lead und Adresse selbst aus `lsa_session_id`. Die Oberfläche schickt weder Adresse noch Lead-ID mit.
6. **Neuer Anlass `lsa_report` in `mail_senden`**, in eigener Datei `lsa_report.ts` nach dem Muster von `termin.ts`. Der Request enthält `{ anlass: 'lsa_report', lsa_session_id, pfad }`. Die Funktion prüft:
   - Admin-Rolle (bestehende Prüfung),
   - die Sitzung ist abgeschlossen und auswertbar,
   - `pfad` beginnt mit `{lsa_session_id}/` und die Datei existiert im Bucket,
   - der Lead hat eine Mail-Adresse.
   Danach lädt sie das PDF, versendet es, ermittelt SHA-256 und Bytes und protokolliert.
7. **Mailtext** in Sie-Form wie die übrigen Elternmails. Er kommt aus `MAIL` (Quelle `de/vertraege.json → mail.lsaReport*`), dieselbe Quelle wie die Vorschau im Dialog:
   - Betreff: `Lernstandsanalyse von {{kind}} – Ihr Bericht`
   - Text:
     ```
     Guten Tag,

     vielen Dank für Ihren Besuch bei Edvance. Anbei finden Sie den Bericht zur Lernstandsanalyse von {{kind}} vom {{datum}}. Er fasst zusammen, was wir gemeinsam besprochen haben: was {{kind}} schon sicher kann, wo es noch hakt und wo wir ansetzen würden.

     Wenn Sie Fragen haben oder etwas nachbesprechen möchten, antworten Sie einfach auf diese Mail.

     Herzliche Grüße
     Ihr Edvance-Team
     ```
   `{{kind}}` ist der Rufname wie im Bogen, `{{datum}}` das LSA-Datum im Format TT.MM.JJJJ (Europe/Berlin). Der Text enthält keine Prognosen und keine Versprechen zum Lernerfolg.
8. **Der Knopf ist nur in diesen Fällen gesperrt**, jeweils mit dem Grund als Tooltip, Muster `<span title>` wie in `AktionenKarte.tsx`:
   - Rolle ist nicht Admin,
   - LSA nicht auswertbar (`nichtAuswertbar`),
   - am Lead ist keine Eltern-Mail hinterlegt,
   - der Ausblick hat ungespeicherte Änderungen („erst speichern“),
   - Bericht oder Pakete laden noch.
9. **Dialog** nach dem Muster von `TerminBestaetigungModal`:
   - Er zeigt „An: …“, die Mail-Vorschau und den Dateinamen mit Größe des Anhangs.
   - Über „Senden“ steht der letzte Versand zu dieser Sitzung, falls es einen gibt („zuletzt am … an …“). Erneutes Senden bleibt möglich.
   - Ablauf: PDF erzeugen, hochladen, `mail_senden` aufrufen, Erfolg mit Empfänger anzeigen.
   - Beim Fehler: Meldung, die Datei bleibt liegen, und „Erneut versuchen“ nutzt dieselbe Datei.
10. **Testlauf-Sitzungen** (`testlauf = true`): Versand ist erlaubt, damit der Weg testbar ist. Der Betreff bekommt `[Test] ` vorangestellt.

## Umfang

### 1. Migration (Datei schreiben; Einspielen erst in Schritt „Ausrollen“)
- Version sekundengenau per `date -u +%Y%m%d%H%M%S` (CLAUDE.md, Migrationen).
- Die Migration muss rückwärtsverträglich sein. Die heute deployte `mail_senden` ruft `lead_mail_protokollieren` mit benannten Parametern auf. Diese Aufrufe müssen nach dem Einspielen und vor dem Deploy weiter funktionieren, deshalb bekommen alle neuen Parameter einen Default.
`supabase/migrations/<timestamp>_lsa_report_mailversand.sql`:
- Bucket `lsa_reports` (privat, `file_size_limit` 3 MB, nur `application/pdf`). Die Grenzen nur setzen, wo Storage sie kennt; Muster: `20261027132413_studio_stimme.sql`.
- Storage-Policies: Admin darf INSERT und SELECT unter `lsa_reports`. Kein UPDATE, kein DELETE.
- `lead_mail_versand`: Check `anlass` erweitern um `'lsa_report'`. Neue Spalten `lsa_session_id uuid null references lsa_sessions(id) on delete set null`, `anhang_pfad text null` und `anhang_sha256 text null`.
- `lead_mail_protokollieren` um optionale Parameter `p_lsa_session_id`, `p_anhang_pfad` und `p_anhang_sha256` erweitern. Die alte Signatur droppen und neu anlegen, grants wie bisher. Die bestehende Terminbestätigung muss unverändert funktionieren.
- Eine Prüfdatei `supabase/checks/lsa_report_mailversand.PRUEFUNG.sql` nach dem Muster von `vertrag_versand_mail.PRUEFUNG.sql`.

### 2. Edge Function
- `supabase/functions/mail_senden/lsa_report.ts` (neu) mit Tests `lsa_report_test.ts`.
- `index.ts`: Anlass-Weiche und Kopfkommentar ergänzen.
- `_shared/dokumente/texte.ts` bzw. die JSON-Quelle: `lsaReportBetreff` und `lsaReportText`.

### 3. PDF im Browser
- `src/lib/report/bogenPdf.ts` (neu): `bogenZuPdf(container, titel): Promise<Blob>`. Vorher `bogenBereit()`, dann die Seiten in A4-Größe rendern und die Grenzen aus Entscheidung 3 durchsetzen.
- `src/lib/supabase/lsaReportMail.ts` (neu) mit den Funktionen hochladen, `lsaReportSenden` und `listLsaReportVersand(sessionId)`.

### 4. Oberfläche
- `ReportPage.tsx`: Knopf freischalten, Sperrgründe nach Entscheidung 8, veralteten Kommentar entfernen.
- `src/pages/admin/lsaReports/LsaReportMailModal.tsx` (neu) mit Test.
- i18n `report.json`: Tooltip ersetzen und die Texte für Dialog und Sperrgründe ergänzen.
- Optional, wenn klein: In der Liste `/admin/lsa-reports` zeigt eine Spalte oder ein Häkchen „per Mail versendet am …“.

## Nicht im Umfang
- Report in der Schülerakte als „Report 1“ (nutzt später den Bucket aus Entscheidung 4).
- Monatliche Eltern-Reports.
- Upload-Session für Graph-Anhänge über 3 MB.
- Präsentation und Bogen-Rendering selbst. Keine Änderungen an `ElternberichtBogen` und `Praesentation` außer einem `ref` oder `data-*`-Haken, falls der für das Rendern nötig ist.

## Tests / Abnahme
1. **Vitest:**
   - Sperrgründe des Knopfs, je Fall einzeln.
   - Dialog: Vorschau, Senden, Fehler, „Erneut versuchen“ ohne neuen Upload.
   - `lsaReportMail` mit gemocktem `supabase`.
2. **Deno-Tests** für `lsa_report.ts`:
   - fremder `pfad` (andere Session) → 400,
   - nicht auswertbar → 400,
   - Lead ohne Mail → 400,
   - Nicht-Admin → 403,
   - Erfolg → protokolliert mit `anhang_sha256`,
   - Graph-Fehler → 502 und trotzdem protokolliert.
3. **Playwright** (analog `e2e-druck`):
   - Für alle `FAELLE` aus `src/lib/report/elternbericht/fixtures` mit `bogenZuPdf` ein PDF erzeugen.
   - Prüfen: Seitenzahl gleich der Druckfassung, Seitenformat A4, Größe ≤ 2,5 MB.
   - Je Seite ein Bild ablegen unter `docs/report/lr-2/abnahme/` zum Sichtvergleich mit dem Druck-PDF.
4. **Manuell (Rasit, nach dem Ausrollen):** eine Testlauf-LSA an die eigene Adresse schicken, das PDF öffnen, den Ausdruck vergleichen und die Zeile in `lead_mail_versand` prüfen.

## Leitplanken
- **Freigabe Rasit (03.11.2026), nur für diesen Auftrag:** Der Agent spielt die Migration selbst in Prod ein, deployt `mail_senden` und merged den PR in `dev`. Alles andere bleibt wie in CLAUDE.md.
- **Schema-Arbeit** nur in einer Session mit `ALLOW_MIGRATIONS=1`. Interaktiv starten, nicht über `claude-auto.sh`, weil der Auftrag `src/lib/**` und die Schema-Zone ändert.
- **DB lesen** nur über `dbread`. Schreibend nur das Einspielmuster aus CLAUDE.md in Schritt A3, keine anderen DDL- oder DML-Befehle gegen Prod.
- **Secrets:** keine ändern, keine anderen Edge Functions deployen.
- **Design:** keine freien Hex-Werte und keine Inline-Styles, nur Tokens. Admin-UI im bestehenden Stil.
- **Keine Mail-Adresse aus dem Request** verwenden.
- **PR gegen `dev`**, nie `main`. Branch `feat/lr-2-report-mail`.

## Ausrollen (Agent, in dieser Reihenfolge, jeder Schritt nur, wenn der vorige grün ist)
1. **A1 – Tests:** `vitest`, `deno test` für `mail_senden`, Playwright aus Abnahme 3, `tsc` und `eslint`, alles grün.
2. **A2 – Unabhängige Prüfung:** Ein frischer Subagent, der den Code nicht geschrieben hat, prüft den Diff gegen diesen Auftrag, besonders die Entscheidungen 5, 6 und 8 und die Rückwärtsverträglichkeit der Migration. Befunde beheben, dann A1 erneut.
3. **A3 – Migration einspielen** nach dem Einspielmuster aus CLAUDE.md:
   ```bash
   V=<version> N=lsa_report_mailversand && dbcheck && \
   [ -z "$(psql "$DATABASE_URL" -tAc "select 1 from supabase_migrations.schema_migrations where version='$V'")" ] && \
   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f supabase/migrations/${V}_${N}.sql && \
   psql "$DATABASE_URL" -c "insert into supabase_migrations.schema_migrations(version,name) values ('$V','$N')" && \
   tools/schema-snapshot.sh
   ```
   Danach `supabase/checks/lsa_report_mailversand.PRUEFUNG.sql` gegen Prod laufen lassen. Den Snapshot committen.
4. **A4 – Deploy:** `npx supabase functions deploy mail_senden --project-ref ztcppihxqcphlqaguhma`
5. **A5 – Merge:** PR gegen `dev` öffnen, CI abwarten und bei grünem CI mergen. `dev` ist in Vercel der Production Branch, der Merge geht also live.
6. **A6 – Bericht:**
   - geänderte Dateien,
   - Testergebnisse,
   - Pfad der Abnahmebilder,
   - eingespielte Version,
   - Ergebnis der Prüfdatei,
   - Deploy-Ausgabe,
   - PR-Link.

**STOPP statt weiter:**
- wenn ein Schritt rot ist,
- wenn `dbcheck` oder die Versionsprüfung anschlägt,
- wenn die Migration nicht rückwärtsverträglich ist,
- wenn eine Entscheidung mit dem Code kollidiert.

Bei STOPP den Befund melden. Nichts halb ausrollen: Nach einer eingespielten Migration ohne Deploy ausdrücklich melden, in welchem Zustand Prod ist.
