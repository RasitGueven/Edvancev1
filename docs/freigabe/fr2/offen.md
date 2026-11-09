# FR-2 · Offene Punkte

Punkte, die eine Änderung an gesperrten Funktionen oder eine Entscheidung brauchen. Der Auftrag läuft ohne sie weiter.

## O1 · Vorschau-Rand doppelt (F0)

Der Vorschau-Rand steht nur inline in `lsa_select_next_core` (`schema-erwartet.sql:9215–9252`). Die Paket-Funktion
aus F1 baut ihn nach, weil `lsa_select_next_core` laut Auftrag nicht geändert wird. Damit beide nie auseinanderlaufen,
müsste `lsa_select_next_core` den Rand aus einer gemeinsamen Funktion holen. Das ist eine Änderung an einer gesperrten
Funktion und bleibt deshalb offen für Rasit. Bis dahin sichern ein Kommentar mit den Stellen und ein pgTAP-Fall
(gleicher Graph, gleicher Rand) die Kopie ab.
