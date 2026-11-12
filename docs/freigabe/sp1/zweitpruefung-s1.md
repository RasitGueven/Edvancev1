# SP-1 · Zweitprüfung S1 (Migration 20261111191054_sp1_bauform_kommentare)

Frischer Subagent ohne Kontext, nur Migration, Rollback, Auftrag (`auftrag-auszug.md`) und Konzept §6.
Frage: „Was ist falsch, was fehlt, was bricht?“

## Runde 1 · Befunde und Behebung

| # | Art | Befund | Behebung |
|---|---|---|---|
| 1 | bricht | Lena kann über `bauform_pruefen` direkt eine Bauform in Rückfrage auf „passt“ setzen oder eine Rückfrage ohne Kommentare anlegen (Umgehung der Regeln, indirekter Weg zu ready über die Sammelfreigabe). | `revoke execute … bauform_pruefen … from authenticated`; Funktion selbst unverändert, nur noch über `bauform_pruefung_senden` (security definer) erreichbar. Lib `bauformPruefen` ruft schon den neuen Weg. pgTAP: „Lena ruft bauform_pruefen nicht direkt auf“. |
| 2 | falsch | „Geht automatisch auf zur Freigabe“: niemand ruft `bauform_rueckfrage_erledigt` auf. | Trigger `bauform_rueckfrage_automatisch` auf `bauform_kommentare` (offen → erledigt) und auf `bauformen` (Version, Protokoll, Blindlöser, Verdacht bei Status rueckfrage); gemeinsame Prüfung `bauform_rueckfrage_hindernis`. Reihenfolge egal; pgTAP für beide Reihenfolgen. Grün laut Protokoll der Version (`gruen > 0`, `rot_anteil ≤ 0,30`), weil der Export die Bauform vor den Instanzen schreibt. |
| 3 | falsch | Rückfrage + neue Version mit Verdacht bleibt `rueckfrage` statt `entwurf`. | Bewusst so gelassen und im Trigger-Kommentar begründet: die Rückfrage bleibt erhalten, der Übergang ist durch den Verdacht blockiert, die Liste blendet verdächtige Bauformen aus. |
| 4 | falsch | `m1_bauform_pruef_plan.test.sql:56` Aliasliste ohne neue Spalte. | Test um `titel, antwortart` ergänzt (31/31 grün). |
| 5 | fehlt | Versionskonflikt zuerst, Sperre. | `for update`, ED409 vor allen anderen Prüfungen; pgTAP. |
| 6 | fehlt | Insert-Policy erlaubt Nachreichen von Kommentaren. | Policy und Insert-Recht entfernt; Schreiben nur über `bauform_pruefung_senden`. pgTAP: direktes Insert scheitert. |
| 7 | fehlt | Rückfrage + `pausiert` bzw. Export mit Verdacht ohne Versionswechsel. | Randfall in `offen.md` (O3). |
| 8 | fehlt | „Nicht in Zu prüfen“ hängt an der Oberfläche. | Liste filtert nach Status `zur_pruefung`; `rueckfrage` ist ein eigener Filter. |
| 9–17 | Hinweis | ID-Suche, Ausnahme-Text, Rechte im Trigger, Kinder und `aufgabe_zeit_sek`, Notiz-Text, Lesart „je Instanz“, Drop der Lesefunktionen, Rollback, Leer-DB. | `bauform_rueckfrage_pruefung` für authenticated ausführbar (Trigger robust); `aufgabe_zeit_sek` liefert Kindern null (pgTAP); Notiz `kommentare:n` statt Text; je Instanz ein Kommentar beim Anker beispiel (Lesart festgehalten). |

## Runde 2 (korrigierter Stand, Commit 64767807)

Frischer Subagent ohne Kontext. **Keine Befunde „falsch“, keine Befunde „bricht“.** Bestätigt: Direktaufruf von
`bauform_pruefen` zu, kein Aufrufer bricht; Lena kann keine Regel umgehen; automatischer Übergang in beiden
Reihenfolgen, ohne Selbstauslösung; andere Versionswechsel unverändert; leere DB und Prod laufen; Rechte; `plan(57)`.

Offen aus Runde 2 (vor dem Einspielen abzuarbeiten oder bewusst nach `offen.md`):

| # | Art | Befund |
|---|---|---|
| 1 | fehlt | Re-Export **ohne** Steckbrief-Änderung, aber mit Verdacht, setzt eine kommentierte Rückfrage über den Upsert auf `entwurf`; der nächste saubere Export auf `zur_pruefung` (gleiche Version). Randfall (Blindlöser kippt bei gleichem Generator). |
| 2 | Hinweis | `bauform_zur_ueberarbeitung` / `bauform_reaktivieren` (bestehend) lösen eine kommentierte Rückfrage auf; Oberfläche bietet es Lena heute nicht an. |
| 3 | Hinweis | Zwei Admins erledigen die letzten Kommentare gleichzeitig → kein Auto-Übergang; Abhilfe `for update` auf `bauformen` im Trigger oder manuell `bauform_rueckfrage_erledigt`. |
| 4 | Hinweis | `bauform_rueckfrage_pruefung` für alle `authenticated` ausführbar (gibt nur eine Prüfungs-ID heraus); mit `darf_pruefen()` absichern. |
| 5 | Hinweis | Alte Oberfläche zeigt Bauformen in Rückfrage noch mit Knöpfen → Fehler `nicht_zu_pruefen`; Prod hat 0 Prüfungen. |
| 6 | Hinweis | Übergangs-Mapping in `bauformPruefung.ts`: ohne Notiz landet der Enum-Schlüssel als Kommentartext. |
| 7 | Hinweis | Kopfkommentar der Migration nennt `antwortart` nicht; m1-Test schlägt nach einem Rollback fehl. |
| 8 | fehlt | pgTAP: `senden` auf Bauform in Rückfrage → P0001; Coach ohne Prüfrecht → 42501; Überarbeitung mit Verdacht bleibt `rueckfrage`; Versionswechsel außerhalb des Exports während der Überarbeitung; `throws_ok(…, null, null)` in Z. 134 zu unscharf. |
| 9 | Hinweis | Prüfungs-ID per Suche statt `returning` (korrekt, solange eine Prüfung je Transaktion). |
| 10 | Hinweis | Rollback braucht auch das Frontend zurück; danach kann Lena kommentierte Rückfragen wieder direkt entscheiden. |

### Behebung Runde 2

- 1 (fehlt): `bauform_versionswechsel` hält eine kommentierte Rückfrage auch bei Export **ohne** Versionswechsel in
  `rueckfrage`; der eigene Abschluss (`edvance.rueckfrage_abschluss`, transaktionslokal) ist ausgenommen. pgTAP.
- 3: Trigger sperrt die Bauform (`for update`), `bauform_rueckfrage_hindernis` ist volatile (frischer Stand).
- 4: `bauform_rueckfrage_pruefung` liefert nur mit Prüfrecht oder als Systemaufruf; `bauform_kommentar_gruende`,
  `bauform_zeit_vorbelegung` nicht für anon. pgTAP (Coach ohne Prüfrecht bekommt null).
- 7: Kopfkommentar nennt `antwortart`.
- 8 (fehlt): pgTAP ergänzt: senden auf Rückfrage → P0001; Coach ohne Prüfrecht → 42501 (senden, Zeit, Detail);
  Überarbeitung mit Verdacht bleibt Rückfrage; Export ohne Versionswechsel; Versionswechsel außerhalb des Exports;
  `task_status_set` → 42501. 65/65 grün.
- 2, 5, 6, 9, 10: Hinweise, bewusst gelassen (Oberfläche bietet die Wege Lena nicht an; S4 ersetzt die Entscheidung).

## Runde 3 (nur der Diff der Behebung Runde 2)

Frischer Subagent. **Keine Befunde „falsch“, keine Befunde „bricht“.** Behoben: Hinweis 1 (Trigger-Logik hing vom
Aufrufer ab → `bauform_rueckfrage_pruefung_intern` ohne Rechteprüfung für Trigger und `hindernis`, geprüfte Hülle für
Aufrufer); fehlt 4 und 5 (pgTAP: Re-Export ohne Versionswechsel entfernt den Verdacht → zur Freigabe; echter Upsert-Weg
wie `export.py`); Hinweis 6 (Kopfkommentar). Hinweise 2 (nur READ COMMITTED, Standard bei PostgREST) und 3 (Markierung
auf leer statt Vorwert, keine Verschachtelung) bewusst gelassen. pgTAP 67/67.
