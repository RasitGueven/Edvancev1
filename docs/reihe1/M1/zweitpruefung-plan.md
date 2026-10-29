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
