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

## Runde 2

Siehe unten (nach Korrektur).
