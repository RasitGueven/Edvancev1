# Verträge — maßgebliche Entscheidungen

Diese Datei ist die Quelle für das Datenmodell in
`supabase/migrations/20260925120000_vertraege_erweiterung.sql`. Die beiden
folgenden Listen sind wörtlich aus dem Bauauftrag übernommen und werden nicht
umformuliert — wo Code und Liste auseinandergehen, hat die Liste recht.

## MASSGEBLICHE ENTSCHEIDUNGEN

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

## FERIENREGEL (nur Halbjahr)

- Ferien = Herbst, Weihnachten, Ostern, Sommer NRW. Pfingsten und bewegliche Tage zählen nicht.
- nominal = beginn + 6 Monate − 1 Tag.
- ende := nominal; wiederhole: t = Anzahl Ferientage in [beginn, ende] (angebrochene mitgezählt);
  neu = nominal + t; bis neu = ende.
- Aufrunden: Tag < 15 → 15. des Monats; Tag = 15 → bleibt; Tag > 15 → Monatsletzter.
- Liegt das Ergebnis in Ferien: auf den Tag nach dem Ferienende und erneut aufrunden, bis es nicht in Ferien liegt.
- Liegt das Ergebnis nach dem letzten Ferientag der Tabelle: Fehler werfen, niemals still rechnen.

---

## Umsetzung in P1 — was wo liegt

| Entscheidung | Ort |
|---|---|
| 1 | `vertraege` erweitert; `status` (Antrag) unverändert, `vertrag_status` beginnt nach dem Abschluss |
| 2 | `tier_laufzeiten` unverändert; Preis und Einheiten setzt weiterhin der Trigger `vertraege_guard()` |
| 3 | `vertraege_beginn_monatserster` |
| 4 | `vertrag_ende_berechnen(beginn, 12)` |
| 5 | `vertrag_ende_berechnen(beginn, 6)`; eingefroren in `vertrag_ende` + `ferientage` (P2 schreibt sie) |
| 6 | `vertrag_widerruf_bis(beginn)`; Spalten `widerruf_bis`, `widerrufen_am` |
| 7 | `vertraege_vertrag_status_check`, `vertraege_vertrag_status_nach_abschluss`, `vertraege_gekuendigt_braucht_datum_und_grund` |
| 8 | `zahlungsstatus`, `zahlungsstatus_seit`, `offener_betrag_cents` + Checks |
| 9 | `verlaengerung_status`, `verlaengerung_grund`, `wiedervorlage_am`, `rueckmeldung_bis` + Checks |
| 10 | `vorgaenger_id`; Partial-Unique-Index `vertraege_student_laufend_uniq` |
| 11 | Datenmodell trägt es (`vorgaenger_id` + `vertrag_ende` + `vertragsbeginn`); die Ableitung selbst ist P2 |
| 12 | `zugangscode_erzeugen()`, Spalten `zugangscode`, `zugangscode_erzeugt_am`, `zugangscode_gesperrt_am` + Formatcheck |
| 13 | unverändert (`vertraege_abgelehnt_grund_check`) |
| 14 | `vertraege_lead_id_fkey` neu mit `on delete restrict` |
| 15 | Tabelle `schulen`, Spalte `vertraege.schule_id` |
| 16 | Bucket `vertraege` (privat) + vier Admin-Policies auf `storage.objects` |
| 17 | Tabelle `audit_log` + `audit_log_schreiben()`; der Aufruf beim IBAN-Aufdecken ist P2 |
| 18 | keine Datenmigration; `vertraege` ist leer |

Die Ferienzeiträume selbst stehen in `ferien_nrw` (Quelle: Ferienordnung NRW bis
2029/30, Schulministerium). Reicht eine Rechnung über den letzten gepflegten
Ferientag hinaus, wirft `vertrag_ende_berechnen()` — die Tabelle wird gepflegt,
nicht die Rechnung geraten.
