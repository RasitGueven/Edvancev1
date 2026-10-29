# Zweitprüfung M1 Phase 2 (Migrationen 20261029083054, 20261029083510)

Stand 29.10.2026. Frischer Agent, Wegwerf-DB (PG 18.6, alle Migrationen), nur Lesen und Transaktionen mit rollback.

## Ergebnis der ersten Runde: rot

| # | Schwere | Befund | Umgang |
|---|---|---|---|
| 1 | blockierend | `bauform_plan_standard` kürzte nicht wie `reihe_plan_rechnen` (Entfallbares und Transfer in einem Schritt, kein Streichen der letzten Posten, sonst leerer Plan). Mit Vorgabewerten bei 3–6 Sessions leer. | behoben: Schleife wie `reihe_plan_rechnen` (Schritt 1 entfallbare Kernideen, 2 Transfer, danach letzter Posten; „gesehen knapp“ entfällt, alles ist neu). pgTAP f3: bei vier Sessions identisch mit dem Plan eines Kindes ohne Befund. Abgleich n = 3…12 × Spielraum {0; 0,1; 0,25}: gleich in allen 24 Fällen mit gleich vielen Terminen (6 Fälle mit Ferien haben beim Kind weniger Termine). |
| 2 | sollte | Im Kinderplan bleibt `session_nr` null ohne Grund (sichere Kernideen, vergangene Sessions, keine Planversion). | dokumentiert im Kopf der Migration; Ansicht zeigt solche Muster unter „Nicht im Plan“. |
| 3 | sollte | `bauform_freigeben` ignorierte leere/unbekannte Schlüssel still. | behoben: 22023; pgTAP c7, c8. |
| 4 | sollte | Testlücken. | ergänzt: c7, c8, f1–f4 (31 Zusicherungen). Offen: Kind ohne Planversion. |
| 5 | Hinweis | `bauform_plan_kinder` filterte nicht nach Fach, `bauform_pruef_plan` nimmt die Mathe-Reihe. | behoben: `r.fach = 'mathematik'`. |
| 6 | Hinweis | Datenschutz: jeder Coach mit Prüfrecht sieht Namen der Kinder mit aktiver Reihe und deren Plan, ohne Vertragsbezug. | **Rasit bitte bewusst abnicken** (Bericht, offene Punkte). |
| 7 | Hinweis | Rechte, Namen, Aufrufer in Ordnung (`bauform_freigeben` hat außer sich selbst keine Aufrufer in `pg_proc`). | – |

Nach den Korrekturen: Neuaufbau aus 412 Migrationen, Suite 95 grün, 8 rot = `bekannt-rot.txt`; `m1_bauform_pruef_plan` 31/31.

## Nachprüfung (zweiter frischer Agent): grün

- Kürzung gleich `reihe_plan_rechnen`: Brute-Force über n = 3…16 (KA-Datum je n so gewählt, dass das Kind genau n Termine hat),
  Kapazität {20, 28, 36, 45}, Spielraum {0; 0,1; 0,25}, Transfer {0, 6, 12, 20}, neu {4, 8, 12, 16, 20}:
  **3360 von 3360 gleich**, 152 verschiedene Pläne, nie leer; Extremwerte fällt in 1658 Fällen weg.
- `p_schluessel`: `array[null]`, `array['PAR-1', null]`, `array['par-1']` → 22023; doppelte Schlüssel geben nicht doppelt frei.
- Rollback beider Migrationen und erneutes Einspielen fehlerfrei; Rechte wie erwartet; PG 16 nicht ausführbar,
  keine Sprachmittel ab PG 17 gefunden (CI `neuaufbau` läuft auf 16).
- **sollte** – Rollback scheiterte, wenn die Stellschraube schon protokolliert geändert wurde (FK). Behoben wie Rollback A2
  (`and not exists … session_einstellungen_protokoll`), lokal mit Protokollzeile geprüft.
- Hinweise: `p_reihe`/`p_thema_key` neben `p_schluessel` filtern still (0 statt Fehler); Standardplan nimmt alle
  `reihe_kernideen` (heute nur Reihe 1). Beides im Kopf der Migration dokumentiert.
