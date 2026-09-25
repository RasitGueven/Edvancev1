# Bauauftrag Verträge — Arbeitspakete für Claude Code

**Stand:** 25.09.2026 · **Entscheider:** Rasit · **Grundlage:** Anforderung-Vertraege.md, Anforderung-Vertragsabschluss.md, vertraege-gesamt-dummy.html, Dokument „Verträge – Entscheidungen und offene Punkte“

Fünf Pakete, nacheinander. Jedes Paket ist ein eigener Branch und ein eigener PR gegen `dev`. Migrationen schreibt der Agent nur als Datei, Rasit spielt sie ein. Die Prompts sind vollständig und können so in Claude Code eingefügt werden.

| Paket | Inhalt | Braucht | Abnahme |
|---|---|---|---|
| P1 | Datenmodell, Ferientabelle, Berechnung Vertragsende | – | Testabfrage liefert alle Kontrollwerte |
| P2 | Abschlussstrecke: Vertragsprozess, 4 Schritte, Einpflegen, Schülerkonto + Zugangscode beim Abschluss | P1 eingespielt | Abnahmefälle 1–8 aus Dokument 2 |
| P3 | Menü Verträge: 4 Listen, Detailansicht, Statuswechsel | P2 gemergt | Abnahmefälle 1–7 aus Dokument 1 |
| P4 | Vertrags-PDF, Archiv, Versand über hello@ (Microsoft 365) | P2 gemergt, Entra-App eingerichtet | Bestätigung kommt mit 5 Anhängen an |
| P5 | Platzvergabe: Coach in Sessions, Admin in LSA, Zugang nur mit Vertrag | P1 eingespielt | Coach kann Kind ohne Vertrag keinen Session-Platz geben |

## Vorbereitung durch Rasit (einmalig)

1. Die drei Grundlagen-Dateien aus dem Projekt nach `Edvancev1/docs/vertraege/` kopieren: `Anforderung-Vertraege.md`, `Anforderung-Vertragsabschluss.md`, `vertraege-gesamt-dummy.html`.
2. `dbcheck` korrigieren. Die bisherige Funktion gibt auch bei „NICHT PROD“ Erfolg zurück, `dbcheck && …` schützt also nicht. Neue Definition ans Ende der `~/.bashrc` hängen (überschreibt die alte):

```bash
cat >> ~/.bashrc <<'EOF'
dbcheck() {
  if echo "$DATABASE_URL" | grep -q "pooler.supabase.com" && psql "$DATABASE_URL" -tAc "select 1" >/dev/null 2>&1; then
    echo "PROD OK"
  else
    echo "NICHT PROD"; return 1
  fi
}
EOF
source ~/.bashrc && dbcheck
```

3. Einspielen einer Migration (Muster, Rasit führt aus):

```bash
V=<version> N=<name> && dbcheck && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f supabase/migrations/${V}_${N}.sql && \
psql "$DATABASE_URL" -c "insert into supabase_migrations.schema_migrations(version,name) values ('$V','$N')" && \
tools/schema-snapshot.sh
```

---

## P1 — Datenmodell, Ferientabelle, Vertragsende

```text
Du arbeitest im Repo Edvancev1. Paket P1 des Bauauftrags Verträge.

LEITPLANKEN (nicht verhandelbar)
- Branch: git fetch && git checkout -b feat/rasit-vertraege-p1-datenmodell origin/dev
- PR gegen dev, niemals main. Nichts unter .github/ ändern.
- Du führst KEIN DDL und KEINE schreibende Abfrage gegen eine Datenbank aus. Lesende Abfragen nur nach `dbcheck` (muss "PROD OK" ausgeben, sonst abbrechen).
- Migrationen nur als Datei unter supabase/migrations/<YYYYMMDDHHMMSS>_<name>.sql. Rasit spielt ein.
- Vor jeder Spaltenänderung: lesend alle Funktionen in pg_proc suchen, die die Spalte/Tabelle referenzieren, und im PR auflisten.
- Datumsarithmetik ausschließlich über date (Tage), nie über Millisekunden oder timestamptz.
- Jede Aussage im PR-Text mit Beleg (Datei:Zeile oder Abfrage-Ausgabe).

KONTEXT
- Lies zuerst docs/vertraege/Anforderung-Vertraege.md und docs/vertraege/Anforderung-Vertragsabschluss.md.
  Wo sie der Liste MASSGEBLICHE ENTSCHEIDUNGEN unten widersprechen, gilt die Liste.
- Falls vorhanden: /tmp/ist-vertraege.md und /tmp/ist-zugang.md (Ist-Analyse). Sonst selbst lesend erheben.
- Bestehend in Prod: vertraege (Status in_vorbereitung | unterschrift_ausstehend | abgeschlossen | abgelehnt),
  vertrag_bankdaten, vertrag_dokumente, vertrag_einstellungen, vertrag_unterschriften, vertrag_versand,
  vertrag_zustimmungen, tiers, tier_laufzeiten (tier_id, laufzeit_monate 6|12, preis_cents, einheiten).
  vertraege ist leer. Der Antragsstatus bleibt wie er ist.

MASSGEBLICHE ENTSCHEIDUNGEN
1. Wir erweitern vertraege. Ein Datensatz = ein Vorgang vom Antrag bis zum Vertragsende.
2. Preise kommen aus tier_laufzeiten (Premium Halbjahr 389,90 €). Kein Rabattfeld.
3. Vertragsbeginn immer der 1. eines Monats (Check-Constraint).
4. Jahresvertrag: Ende = Beginn + 12 Monate − 1 Tag, keine Ferienregel.
5. Halbjahresvertrag: Ende nach Ferienregel (unten), beim Abschluss eingefroren.
6. Widerrufsfrist: widerruf_bis = Vertragsbeginn + 29 Tage (erster Tag zählt mit; 01.11. → 30.11.).
   Widerruf ist ab Abschluss möglich. Volle Erstattung.
7. Vertragsstatus nach Abschluss: im_widerruf | aktiv | gekuendigt | ausgelaufen | widerrufen.
   Keine ordentliche Kündigung; "gekuendigt" nur als manueller Sonderfall mit Datum und Grund.
8. Zahlungsstatus: in_ordnung | zahlung_offen | mahnung_1 | mahnung_2 | inkasso, mit Datum der Stufe.
9. Verlängerungsstatus: offen | kontaktiert | gespraech_vereinbart | verlaengert | keine_verlaengerung (+ Grund), Wiedervorlage-Datum.
10. Vorgängervertrag als Verweis. Ein Vertrag pro Kind.
11. Zugang: Hat ein Kind einen unterschriebenen Folgevertrag, bleibt der Zugang zwischen Vertragsende und Beginn des Folgevertrags offen. Sonst endet er am Vertragsende.
12. Zugangscode: beim Abschluss erzeugt, 8 Zeichen aus einem Alphabet ohne 0/O/1/I/L, Anzeige EDV-XXXX-XXXX, eindeutig, neu erzeugbar, bei Vertragsende/Widerruf gesperrt. Kein Login damit in dieser Runde.
13. Ablehnungsgrund bleibt die bestehende feste Auswahl.
14. lead_id darf einen Vertrag nicht mitlöschen: ON DELETE RESTRICT statt CASCADE.
15. Schule ist ein Auswahlfeld aus einer neuen Tabelle schulen, beim Erfassen erweiterbar.
16. Unterlagen liegen in einem privaten Storage-Bucket "vertraege" (Frankfurt), nur Admins.
17. Aufdecken der vollständigen IBAN wird protokolliert (audit_log).
18. Die bestehenden Schüler in Prod sind Testdaten; keine Übernahme, keine Datenmigration für sie.

FERIENREGEL (nur Halbjahr)
- Ferien = Herbst, Weihnachten, Ostern, Sommer NRW. Pfingsten und bewegliche Tage zählen nicht.
- nominal = beginn + 6 Monate − 1 Tag.
- ende := nominal; wiederhole: t = Anzahl Ferientage in [beginn, ende] (angebrochene mitgezählt);
  neu = nominal + t; bis neu = ende.
- Aufrunden: Tag < 15 → 15. des Monats; Tag = 15 → bleibt; Tag > 15 → Monatsletzter.
- Liegt das Ergebnis in Ferien: auf den Tag nach dem Ferienende und erneut aufrunden, bis es nicht in Ferien liegt.
- Liegt das Ergebnis nach dem letzten Ferientag der Tabelle: Fehler werfen, niemals still rechnen.

LIEFERUMFANG
A) Migration supabase/migrations/<ts>_vertraege_erweiterung.sql:
   - Tabelle ferien_nrw (id, art check in herbst|weihnachten|ostern|sommer, name, von date, bis date, check von<=bis),
     befüllt mit exakt diesen Zeiträumen (Quelle: Ferienordnung NRW bis 2029/30, Schulministerium):
     Sommer 2026 2026-07-20..2026-09-01 · Herbst 2026 2026-10-17..2026-10-31 · Weihnachten 2026/27 2026-12-23..2027-01-06
     Ostern 2027 2027-03-22..2027-04-03 · Sommer 2027 2027-07-19..2027-08-31 · Herbst 2027 2027-10-23..2027-11-06
     Weihnachten 2027/28 2027-12-24..2028-01-08 · Ostern 2028 2028-04-10..2028-04-22 · Sommer 2028 2028-07-10..2028-08-22
     Herbst 2028 2028-10-23..2028-11-04 · Weihnachten 2028/29 2028-12-21..2029-01-05 · Ostern 2029 2029-03-26..2029-04-07
     Sommer 2029 2029-07-02..2029-08-14 · Herbst 2029 2029-10-15..2029-10-27 · Weihnachten 2029/30 2029-12-20..2030-01-04
     Ostern 2030 2030-04-15..2030-04-27 · Sommer 2030 2030-06-24..2030-08-06
     RLS: lesen für authenticated, schreiben niemand (nur Migration).
   - Tabelle schulen (id, name, ort, created_at, created_by), unique(lower(name), coalesce(ort,'')). RLS: nur Admin.
   - Tabelle audit_log (id, actor uuid, aktion text, objekt_typ text, objekt_id uuid, created_at). Kein direktes INSERT;
     Schreiben nur über SECURITY DEFINER-Funktion audit_log_schreiben(aktion, objekt_typ, objekt_id). Lesen nur Admin.
   - vertraege um die Spalten für Entscheidungen 3–15 erweitern (nur was nicht schon existiert; prüfe vertrag_* auf
     vorhandene Felder für AGB-/Datenschutz-Fassung, Unterschriftsdatum usw. und nutze die, statt zu duplizieren).
     Mindestens: student_id (FK students, RESTRICT), schule_id, vertrag_status, abgeschlossen_am, unterschrift_datum,
     eingang_datum, vertrag_ende, ferientage, widerruf_bis, widerrufen_am, gekuendigt_zum, kuendigung_grund,
     zahlungsstatus (default in_ordnung), zahlungsstatus_seit, offener_betrag_cents, verlaengerung_status,
     verlaengerung_grund, wiedervorlage_am, rueckmeldung_bis, vorgaenger_id (FK vertraege), abweichung_vermerk,
     zugangscode (unique), zugangscode_erzeugt_am, zugangscode_gesperrt_am.
     Check-Constraints für alle Auswahlfelder und für "beginn ist Monatserster". vertrag_status ist NULL, solange
     status <> 'abgeschlossen', und NOT NULL danach (Check).
   - lead_id-FK auf ON DELETE RESTRICT umstellen.
   - Storage-Bucket "vertraege" (privat) mit Policies nur für Admin (get_my_role()).
   - Funktion vertrag_ende_berechnen(p_beginn date, p_laufzeit_monate int)
     returns table(nominal date, ferientage int, ende date, ferien text[]) — STABLE, rein lesend, Ferienregel oben.
   - Funktion vertrag_widerruf_bis(p_beginn date) returns date.
   - Funktion zugangscode_erzeugen() returns text (Alphabet und Format wie Entscheidung 12, mit Kollisionsschleife).
   - Die bestehenden Trigger/RPCs, die Statuswechsel auf vertraege erzwingen, NICHT ändern; nur im PR auflisten,
     welche in P2 angepasst werden müssen.
B) tests/sql/vertrag_ende_test.sql — eine lesende Abfrage, die für jeden Fall ist = soll vergleicht und OK/FEHLER ausgibt:
     01.11.2027 Halbjahr → nominal 30.04.2028, 35 Ferientage, Ende 15.06.2028
     01.01.2027 Halbjahr → nominal 30.06.2027, 63 Ferientage, Ende 15.09.2027
     01.04.2027 Halbjahr → nominal 30.09.2027, 62 Ferientage, Ende 15.12.2027
     01.09.2027 Halbjahr → nominal 29.02.2028, 31 Ferientage, Ende 31.03.2028
     01.10.2027 Jahr     → Ende 30.09.2028, 0 Ferientage
     plus: jeder Monatserste von 01.10.2026 bis 01.06.2029 als Halbjahr: Ende ist nie in Ferien, Tag ist 15 oder Monatsletzter.
     plus: 01.03.2030 Halbjahr wirft den Tabellen-Fehler.
     plus: vertrag_widerruf_bis('2027-11-01') = '2027-11-30', vertrag_widerruf_bis('2028-02-01') = '2028-03-01'.
C) docs/vertraege/entscheidungen.md — die Liste MASSGEBLICHE ENTSCHEIDUNGEN und die FERIENREGEL wörtlich aus diesem Prompt.
D) PR-Text: Liste der neuen/geänderten Objekte, pg_proc-Scan, Einspielbefehl nach Rasits Muster, und was P2 anpassen muss.

ABNAHME
Nach dem Einspielen durch Rasit liefert tests/sql/vertrag_ende_test.sql ausschließlich OK.
```

---

## P2 — Abschlussstrecke

```text
Du arbeitest im Repo Edvancev1. Paket P2 des Bauauftrags Verträge. P1 ist eingespielt und gemergt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-vertraege-p2-abschluss origin/dev · PR gegen dev, nie main · nichts unter .github/.
- Kein DDL, keine schreibenden Abfragen. Migrationen nur als Datei unter supabase/migrations/. Rasit spielt ein.
- Lesende Abfragen nur nach `dbcheck` = "PROD OK".
- Vor Änderungen an Funktionen/Spalten: pg_proc-Scan, im PR auflisten.
- Design: nur bestehende Design-Tokens, keine freien Hex-Werte, keine Inline-Styles.
- Datumsarithmetik nur über date. Vertragsende und Widerrufsfrist kommen ausschließlich aus
  vertrag_ende_berechnen / vertrag_widerruf_bis (keine zweite Implementierung im Frontend).

KONTEXT
- docs/vertraege/entscheidungen.md ist maßgeblich. Danach docs/vertraege/Anforderung-Vertragsabschluss.md
  (Soll-Zustand A–G, Abnahmefälle) und docs/vertraege/vertraege-gesamt-dummy.html (Ablauf, nicht Design).
- Bestehende Vertragsseiten, Unterschriftspads und Druckansicht (/admin/vertraege/:id/unterlagen) wiederverwenden.

UMFANG
1. Lead-Board: Knopf "In Schüler konvertieren" wird "Vertragsprozess". Klick legt sofort einen Antrag
   (status in_vorbereitung) mit allen Lead-Daten an; der Lead verlässt das Board und kehrt nie zurück.
   Der Aufruf von provision_student aus LeadsPage/LeadCard entfällt dort. Den ungenutzten Pfad lead_convert
   per Migration entfernen (vorher pg_proc-Scan und Repo-Suche belegen, dass nichts ihn aufruft).
2. Schritt 1 Vertragsdaten: vorausgefüllt, Paket + Laufzeit aus tier_laufzeiten, Beginn als Auswahl der
   Monatsersten ab kommendem Monat (18 Monate), Ende + Ferientage + Ferien-Namen per RPC-Vorschau,
   Hinweis zu 6 Beiträgen im Halbjahr. Schule als Auswahl aus schulen mit "neu anlegen".
   Stammdatenänderungen werden in die Lead-/Elterndaten zurückgeschrieben.
3. Schritt 2 Vertragsdokument (bestehende Druckansicht, mit Ferienklausel beim Halbjahr).
4. Schritt 3 Abschlussweg: vor Ort | per Mail | ausdrucken (abschluss_weg vor_ort | papier; Mail/Druck in vertrag_versand).
5. Schritt 4 Weg A (vor Ort): vier Bestätigungen mit Fassung, Unterschrift, "Vertrag abschließen" erst wenn alles da.
   Abschluss in EINER SECURITY DEFINER-RPC (Admin-only), atomar:
   status abgeschlossen, vertrag_status im_widerruf, abgeschlossen_am, unterschrift_datum = heute,
   vertrag_ende/ferientage eingefroren, widerruf_bis aus Beginn, zugangscode erzeugt,
   Schülerkonto anlegen (bestehende app_provision_student-Logik wiederverwenden, jetzt MIT tier_id), student_id setzen,
   bei Folgevertrag: vorgaenger_id setzen und Vorgänger auf verlaengerung_status verlaengert.
   Der Mailversand selbst kommt in P4; hier nur "Bestätigung drucken" aktiv, "per Mail" sichtbar aber deaktiviert.
6. Wege B/C: kein Vertrag, kein Konto, kein Code. status unterschrift_ausstehend, rueckmeldung_bis (Standard heute+14),
   AGB-/Datenschutz-Fassung beim Erzeugen der Unterlagen festhalten.
7. Einpflegen (aus Offene Anträge, nur status unterschrift_ausstehend): Scan-Upload in Bucket "vertraege"
   (Pflicht), Abgleich Soll/Ist (Paket, Laufzeit, Beginn), bei Abweichung Pflicht-Vermerk, es gilt das Papier;
   Unterschriftsdatum und Eingangsdatum. Abschluss über dieselbe RPC wie Weg A (Vertragsende aus dem Papier-Beginn).
   Alternativ "nicht zustande gekommen" mit bestehender Grund-Auswahl.
8. Eine vorläufige Liste "Offene Anträge" genügt als Einstieg; die vollständigen Listen kommen in P3.

ABNAHME
Abnahmefälle 1–8 aus Anforderung-Vertragsabschluss.md, mit diesen Abweichungen: Widerruf bis = Beginn + 29 Tage;
Premium Halbjahr 389,90 €. Zusätzlich: Ein Antrag, bei dem Schritt 1 abgebrochen wird, steht unter Offene Anträge
als in_vorbereitung. Im PR: Screenshots jedes Schritts und die Abfrage-Ausgabe eines abgeschlossenen Testvertrags.
```

---

## P3 — Menü Verträge

```text
Du arbeitest im Repo Edvancev1. Paket P3 des Bauauftrags Verträge. P1 und P2 sind gemergt und eingespielt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-vertraege-p3-menue origin/dev · PR gegen dev, nie main · nichts unter .github/.
- Kein DDL, keine schreibenden Abfragen. Migrationen nur als Datei. Lesend nur nach `dbcheck` = "PROD OK".
- pg_proc-Scan vor Änderungen. Nur Design-Tokens. Datumsarithmetik nur über date.
- Nur Admins sehen den Menüpunkt; Coaches weder im Menü noch über die direkte Adresse (Route + RLS).

KONTEXT
docs/vertraege/entscheidungen.md (maßgeblich), docs/vertraege/Anforderung-Vertraege.md (Soll A–E, Abnahmefälle),
docs/vertraege/vertraege-gesamt-dummy.html (Ablauf).

UMFANG
1. Wirksamer Vertragsstatus ohne Cronjob: eine View (security_invoker) oder Funktion, die aus gespeicherten Daten
   ableitet: widerrufen (widerrufen_am gesetzt) > gekuendigt (gekuendigt_zum <= heute) > ausgelaufen (vertrag_ende < heute)
   > im_widerruf (heute <= widerruf_bis) > aktiv. Alle Listen lesen diese View.
2. Funktion hat_zugang(student_id, datum) nach Entscheidung 11 (Folgevertrag überbrückt die Lücke). Sie wird in P5 genutzt.
3. Offene Anträge: in_vorbereitung und unterschrift_ausstehend; überfällige rueckmeldung_bis hervorgehoben;
   abgelehnte per Filter sichtbar.
4. Vertragsübersicht: aktueller Vertrag je Kind, Filter je Spalte, Suche Vertragspartner/Kind.
   Summenzeile: Anzahl laufender Verträge (aktiv + im_widerruf), Anzahl im Widerruf, und "Abbuchung diesen Monat":
   Summe nur der Verträge, deren Beitrag in diesem Monat tatsächlich fällig ist (Halbjahr: nur Monate 1–6 ab Beginn).
5. Detailansicht wie Dokument 1 Punkt 14: IBAN maskiert, "vollständig anzeigen" schreibt audit_log;
   Zugangscode mit "neu erzeugen" (alter wird ungültig) und "drucken"; "per Mail" deaktiviert bis P4;
   Historie über vorgaenger_id; "Neuer Vertrag" startet die P2-Strecke vorausgefüllt;
   "Widerruf erfassen" (nur bis widerruf_bis) setzt widerrufen_am und sperrt den Zugangscode;
   "Sonderkündigung erfassen" mit Datum und Pflicht-Grund.
6. Auslaufende Verträge: Ende innerhalb von 8 Wochen, Verlängerungsstatus + Wiedervorlage pflegbar,
   "keine Verlängerung" mit Pflicht-Grund blendet aus.
7. Zahlungsverzüge: Stufen nur eine vorwärts oder zurück auf in_ordnung, Datum je Stufe, offener Betrag.
8. Leere Zustände je Liste mit Hinweistext.
9. Zugangscode automatisch als gesperrt behandeln, sobald der wirksame Status ausgelaufen/widerrufen/gekuendigt ist
   (in der View bzw. beim Prüfen, nicht per Cron).

ABNAHME
Abnahmefälle 1–7 aus Anforderung-Vertraege.md. Zusätzlich: Ein Halbjahresvertrag im 8. Laufzeitmonat zählt als
laufend, trägt aber 0 € zur Summe "Abbuchung diesen Monat" bei.
```

---

## P4 — PDF, Archiv, Versand über hello@

**Vorher durch Rasit:** In Microsoft Entra eine App-Registrierung „Edvance Plattform Mailversand“ anlegen, Anwendungsberechtigung `Mail.Send`, Administratorzustimmung erteilen und per Exchange-Richtlinie (RBAC for Applications) auf das Postfach hello@edvanceacademy.de beschränken. Tenant-ID, Client-ID und Secret als Secrets in Supabase hinterlegen.

```text
Du arbeitest im Repo Edvancev1. Paket P4 des Bauauftrags Verträge. P1–P3 sind gemergt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-vertraege-p4-pdf-mail origin/dev · PR gegen dev, nie main · nichts unter .github/.
- Kein DDL, keine schreibenden Abfragen. Migrationen nur als Datei. Lesend nur nach `dbcheck` = "PROD OK".
- Secrets nie ins Repo, nie in Logs. Zugriff nur über Supabase-Secrets MS_TENANT_ID, MS_CLIENT_ID, MS_CLIENT_SECRET.

UMFANG
1. Serverseitige PDF-Erzeugung des Vertrags (inkl. Unterschriftsbild, eingesetzter Werte, Ferienklausel) als
   unveränderliche Datei im Bucket "vertraege" unter <vertrag_id>/vertrag.pdf. Bibliothek wählen und im PR begründen
   (Kriterium: läuft in der bestehenden Laufzeitumgebung ohne Headless-Browser).
2. Unterschrift aus vertrag_unterschriften.signatur (Base64) zusätzlich als PNG im Bucket ablegen; Datensatz verweist darauf.
3. Archivbündel je Vertrag: Vertrag-PDF, AGB- und Datenschutz-Fassung (als Datei), Widerrufsbelehrung, SEPA-Mandat,
   ggf. Scan. Die Detailansicht aus P3 öffnet diese Dateien über signierte URLs.
4. Edge Function mail_senden: Microsoft Graph, Client-Credentials-Flow, POST /users/hello@edvanceacademy.de/sendMail.
   Nur Admin darf aufrufen. Jeder Versand wird in vertrag_versand protokolliert (Zeitpunkt, Empfänger, Anhänge, Ergebnis).
5. Die "per Mail"-Knöpfe aus P2 und P3 aktivieren: Vertragsbestätigung mit allen fünf Unterlagen, Unterlagen für
   Weg B, Zugangscode erneut senden.
6. Im SEPA-Mandat in der Mail die vollständige IBAN beibehalten (sind die eigenen Daten der Eltern).

ABNAHME
Ein Testabschluss an eine Admin-Adresse: Mail kommt von hello@edvanceacademy.de mit Vertrag, AGB, Datenschutzerklärung,
Widerrufsbelehrung und SEPA-Mandat; das PDF im Archiv ist byte-gleich mit dem Anhang; vertrag_versand hat den Eintrag.
```

---

## P5 — Platzvergabe und Zugang vor Ort

```text
Du arbeitest im Repo Edvancev1 (und liest edvance-app mit). Paket P5 des Bauauftrags Verträge. P1 und P3 sind eingespielt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-vertraege-p5-platz origin/dev · PR gegen dev, nie main · nichts unter .github/.
- Kein DDL, keine schreibenden Abfragen. Migrationen nur als Datei. Lesend nur nach `dbcheck` = "PROD OK".
- pg_proc-Scan für platz_assign, platz_release, platz_submit, platz_finish und alle Aufrufer, im PR auflisten.
- NICHT anfassen: den Identitätstausch (set_config request.jwt.claims) in platz_submit/platz_finish. Der ist bewusst
  zurückgestellt und wird separat behoben. Im PR nur vermerken, falls deine Änderung davon berührt wird.

KONTEXT
docs/vertraege/entscheidungen.md; /tmp/ist-zugang.md falls vorhanden.
Heute: platz_assign und platz_release werfen 42501 'nur Admin'. UI "Platz vergeben" auf der Lead-Karte → PlatzPanel.

ENTSCHEIDUNGEN
- Platz für eine Lernstandsanalyse: nur Admin (wie heute), auch für Leads ohne Vertrag.
- Platz in einer regulären Session: der Coach (und Admin). Nur für Kinder, für die hat_zugang(student_id, heute) wahr ist.
- Lehnt das System ab, sieht der Coach einen verständlichen Grund ("kein laufender Vertrag").

UMFANG
1. Belegen, woran platz_assign heute LSA von regulärer Session unterscheidet. Gibt es keine Unterscheidung,
   einen Parameter/Kontext einführen und im PR begründen.
2. Rollenprüfung und Vertragsprüfung in platz_assign (Migration), platz_release entsprechend.
3. UI-Einstieg für Coaches in regulären Sessions (wo heute Sessions/Slots angezeigt werden), bestehende PlatzPanel-Logik wiederverwenden.

ABNAHME
Coach vergibt Session-Platz an Kind mit aktivem Vertrag: klappt. An Kind ohne laufenden Vertrag: abgelehnt mit Grund.
Coach versucht LSA-Platz: abgelehnt. Admin vergibt LSA-Platz an Lead ohne Vertrag: klappt.
```

---

## Außerhalb der Pakete

- **Zurückgestellt:** Identitätstausch am Kiosk (`platz_submit`/`platz_finish` schreiben unter der Identität des Admins). Eigene Aufgabe vor der ersten echten Session.
- **Später, mit den Home Quests:** Anmeldung zuhause mit dem Zugangscode (ein Gerät, Sperre nach Fehlversuchen, nur Home-Quest-Funktionen).
- **Vor dem ersten echten Vertrag:** IBAN in `vertrag_bankdaten` verschlüsseln; Gläubiger-ID eintragen (Tolunay beantragt).
