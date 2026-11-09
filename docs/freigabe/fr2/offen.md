# FR-2 · Offene Punkte

Punkte, die eine Änderung an gesperrten Funktionen oder eine Entscheidung brauchen. Der Auftrag läuft ohne sie weiter.

## O1 · Vorschau-Rand doppelt (F0)

Der Vorschau-Rand steht nur inline in `lsa_select_next_core` (`schema-erwartet.sql:9215–9252`). Die Paket-Funktion
aus F1 baut ihn nach, weil `lsa_select_next_core` laut Auftrag nicht geändert wird. Damit beide nie auseinanderlaufen,
müsste `lsa_select_next_core` den Rand aus einer gemeinsamen Funktion holen. Das ist eine Änderung an einer gesperrten
Funktion und bleibt deshalb offen für Rasit. Bis dahin sichern ein Kommentar mit den Stellen und ein pgTAP-Fall
(gleicher Graph, gleicher Rand) die Kopie ab.

## O2 · Lena sieht nur Aufgaben im Pilot (F1) — entschieden: aus (Rasit, 09.11.)

In Prod steht `pruef_einstellungen.nur_pilot = true`. Lena sieht im Board nur Aufgaben mit `pruef_pilot`
(246 von 717 LSA-Entwürfen, dbread 09.11.2026), und `pruef_entscheiden` lehnt die übrigen ab
(`pruef_lena_sperren` → `ausgeschlossen`). Der Auftrag geht davon aus, dass Lena jeden vorgeschlagenen Entwurf
prüfen kann.

Lösung in F1, ohne gesperrte Funktionen anzufassen: `pruef_ziel_liste` nimmt Entwürfe im Pilot bevorzugt
(nach Nicht-MC) und nennt die übrigen Vorschläge in `pilot_fehlt`. Admins nehmen sie über den bestehenden Weg
`pruef_sammel('pilot_an', ids)` in den Pilot (F2: Knopf auf der Seite LSA-Abdeckung). Offen für Rasit: ob
`nur_pilot` für die LSA bleiben soll.

**Entschieden: aus (Rasit, 09.11.).** Migration `20261109123016_fr2_nur_pilot_aus` (F2) setzt `nur_pilot = false`.
`pilot_fehlt` bleibt in `pruef_ziel_liste` und ist danach immer leer; der Pilot-Knopf auf der Seite entfällt.

## O1 · entschieden (Rasit, 09.11.)

Bleibt wie gebaut: Kopie des Vorschau-Rands mit pgTAP, `lsa_select_next_core` unverändert. Ebenso der Zwischenspeicher
(nur Paket-Struktur, Trigger setzen nur „veraltet“, keine Trigger auf `tasks`).
