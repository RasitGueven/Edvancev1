# Retro · LSA ohne Ausblick (25.10.2026)

Entscheidung Rasit: „Kinder sollen nichts in der LSA haben, was sie noch nicht hatten.“ Anlass: Auf Batus
Freigabeliste standen quadratische Funktionen, Kreis und Potenzen (Klasse 9, noch nicht behandelt) und die
p-q-Formel (Plan Klasse 10).

## Gebaut

- **Migration `20261025220449_lsa_ohne_ausblick`:**
  - `lsa_ausblick_knoten` liefert immer `{}`. Damit fällt die Ausblick-Phase in `lsa_select_next_core` weg
    (Bedingung `cardinality(v_ausblick) > 0`), und `lsa_ist_ausblick` ist immer false. Den Kern selbst ändert die
    Migration nicht. Der Rollback stellt die Funktion textgleich wieder her (lokal geprüft).
  - Lenas Liste: Die `batu_lsa`-Zeilen der fünf Ausblick-Bereiche und von `gleichung_quadr_formel` ruhen. Damit
    bleiben 36 statt 48 Freigaben.
- **Schalter `set local lsa.ausblick = 'an'`**, nur für die Tests:
  - `lsa_v2_ausblick` und `lsa_v_vorschau` prüfen den Mechanismus damit weiter.
  - In `lsa_v2_ausblick` ist neu: Ohne Schalter gibt es keinen Knoten.
  - `lsa_testkinder` (11): Max und Lina, die starken Kinder, bekommen keinen Ausblick-Knoten. Vorher galt hier:
    Ausblick mit Stopp.
- `p3_vorschau_pruefen` und `p4_batu_freigabeliste` sind an die ruhenden Zeilen angepasst. `schema-erwartet.sql`
  enthält den neuen Funktionstext.

## Geprüft: keine andere Phase zieht neuen Stoff

- Thema und Tiefe: der Themenraum (Einstiege und deren Voraussetzungen).
- Vorschau: nur Voraussetzungen der kommenden Themen. Skills kommender oder späterer Themen schließt sie aus
  (`v_kommend`, `v_spaeter`).
- Rückblick: nur Einstiege von Themen mit `lead_themen.status = 'behandelt'`.

## Offen

- Migration einspielen (Rasit).
- Der Bericht (`vorgriff.ts`) kennt Vorgriffe weiter. Ohne Ausblick-Knoten entstehen keine, eine Änderung ist
  nicht nötig.
- Ohne Thema (Breite b) ist nicht eigens geprüft; dort gilt weiter die Klassengrenze der alten Auswahl.
