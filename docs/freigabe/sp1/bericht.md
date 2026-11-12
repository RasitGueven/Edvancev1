# Bericht Bauauftrag SP-1 · Session-Aufgaben prüfen

Stand 12.11.2026. Protokoll: `fortschritt.md`, offene Befunde: `offen.md`, Abnahme: `abnahme.md`.
Alle Migrationen hat der Orchestrator nach grünen Tests, grüner Zweitprüfung und grüner CI selbst eingespielt
(Freigabe Rasit vom 11.11.2026, nur SP-1) und per dbread geprüft.

## PRs in Merge-Reihenfolge

| # | PR | Inhalt | Stand |
|---|---|---|---|
| 1 | #393 | S0 Ist-Analyse | gemergt |
| 2 | #394 | S1 Datenmodell: Kommentare, Zeit je Stufe, Rückfrage-Abschluss, Klartext-Felder | gemergt, eingespielt |
| 3 | #395 | S2 Klartext (Datenmigration, Textdateien) | gemergt, eingespielt |
| 4 | #396 | S3 Liste „Session-Aufgaben prüfen“, Vorschau und Ansichtstests | gemergt |
| 5 | #397 | S4 Prüfansicht, Graph-Optionen wie im Player (S4.14) | gemergt |
| 6 | – | S5 Rückfragen-Werkzeug, Abnahme, Bericht (diese PR) | – |

## Migrationen

| Version | Name | Stand | Prüfabfrage (dbread) |
|---|---|---|---|
| 20261111191054 | sp1_bauform_kommentare | eingespielt | `stufen 112, abweichend 0, kommentare t, senden t, erledigt t`; `bauform_pruefen` für authenticated gesperrt |
| 20261112083401 | sp1_klartext | eingespielt | `titel 47, stufen 100, verschieden 47, status zur_pruefung, version 1` |

Keine Migration wartet. Rollbacks unter `supabase/rollback/` (stilllegend, Tabellen und Texte bleiben). Skripte:
`~/einspielen/SP1-1-bauform-kommentare.sh`, `~/einspielen/SP1-2-klartext.sh`. Zweitprüfung S1 in drei Runden
(`zweitpruefung-s1.md`): Runde 1 fand eine Umgehung über `bauform_pruefen` und den fehlenden automatischen Übergang,
beides behoben; Runden 2 und 3 ohne „falsch“ oder „bricht“.

## Was gebaut ist

- **Datenbank:** `bauform_stufen` (Klartext, Zeit je Stufe 0,5–10 Min, ohne Versionswechsel, Protokoll in
  `bauform_zeit_aenderungen`), `bauform_kommentare` (Anker, Gründe je Anker, offen | erledigt mit Notiz),
  `bauform_pruefung_senden` (ein Aufruf, nutzt `bauform_pruefen`), automatischer Übergang zur Freigabe nach
  erledigten Kommentaren, grüner Prüfmaschine und bestandenem Blindlöser, Sicht `bauform_kommentar_auswertung`.
  Lena erreicht `bauform_pruefen` nur noch über den neuen Aufruf; kein neuer Weg zu ready.
- **Liste und Prüfansicht** wie im Dummy, alle Texte über `bauformPruefen.json`, Kürzel nur als Etikett.
- **Werkzeuge:** `tools/bauform-rueckfragen.sh`, `docs/freigabe/sp1/rueckfragen-ablauf.md`,
  `tools/sp1-vorschau-daten.sh` mit `playwright.sessionpruefung.config.ts` für Ansichtstests.

## Abnahme

a–d, f–k erfüllt; e teilweise (Zeit gespeichert und je Aufgabe lesbar, aber kein Leser in der Session-Planung, O1).
Einzelheiten und Belege in `abnahme.md`.

## Offene Punkte

1. **O1 · Zeit in der Planung:** Die Session-Planung liest keine Aufgabenzeit (Kapazität über Kernidee-Minuten).
   `aufgabe_zeit_sek(task)` liefert die Stufenzeit; wer sie wo nutzt, entscheiden die Gründer (Auftrag C).
2. **O4 · Strittige Klartexte:** EIN-1, EX-2, KO-1, NP-4, NS-4, NS-5 ohne Stufen-Klartext (Ansicht zeigt dort die
   Generator-Regel); fünf Fehlbild-Kurznamen offen; Vorschläge in `klartext-pruefung.md`. Eine kleine
   Datenmigration nach erneuter Prüfung reicht.
3. **O3 · Rückfrage und Pausieren:** Pausieren oder `bauform_zur_ueberarbeitung` während einer Rückfrage lösen sie auf.
4. **Generator-Befunde aus S2:** PQ-2 Stufe 2 erzeugt im Sonderzweig p, q > 0 (verworfen, ohne Wirkung); DI-1 q bis 100.
5. **App-Types** `src/types/database.ts` nicht neu erzeugt (Windows-CLI); die Bauform-Typen sind handgeschrieben.
6. **Gleichzeitigkeit:** Der automatische Übergang ist unter READ COMMITTED (PostgREST-Standard) dicht.

## Anleitung für Lena

Öffne „Aufgaben prüfen“ und dort „Session-Aufgaben prüfen“: Jede Karte ist eine Bauform, oben siehst du, wie viele
du schon geprüft hast. In einer Bauform liest du links das Grundgerüst, die typischen Fehler, die Stufen mit der Zeit
je Aufgabe und sechs Beispiele so, wie das Kind sie auf dem Tablet sieht. Stimmt etwas nicht, klickst du an der Stelle
auf „Kommentar“, wählst rechts einen Grund oder schreibst kurz, was geändert werden soll. Stimmt alles, drückst du
„Passt“; die Zeit je Stufe kannst du mit Minus und Plus direkt anpassen, das ist keine Rückfrage. Nach dem Senden
öffnet sich die nächste Bauform, und eine Rückfrage wird überarbeitet und geht danach ohne dich zur Freigabe.
