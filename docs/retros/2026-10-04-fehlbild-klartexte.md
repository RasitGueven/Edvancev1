# Retro 2026-10-04 — Fehlbild-Klartexte (W5-a)

**Gebaut:** Migration `20261004002101_fehlbild_klartexte_entwuerfe.sql` (52
Klartext-/Erklärungs-Entwürfe, nicht freigegeben), Prüfskript
`supabase/checks/fehlbild_klartexte.PRUEFUNG.sql`, Abnahmeliste und
Entscheidungen unter `docs/fehlbilder/`.

**Entscheidungen:** keine Familie gesetzt (würde den Slug am Slug-Freigabe
vorbei in den Elternbericht schalten), keine Erklärung unter alter Abnahme,
`teilgekuerzt` ausgenommen (CI F14). Details: `docs/fehlbilder/klartexte-entscheidungen.md`.

**Offen:**
- Lenas Abnahme der Tabellen 1, 1b und 2.
- Neue Familien für Brüche/Kommazahlen/Potenzen/Runden — ohne sie erscheinen
  22 LSA-relevante Fehlbilder nie im Elternbericht.
- `teilgekuerzt` umbenennen; Slug-Befunde (Abschnitt 3 der Abnahmeliste)
  bei den Aufgaben-Schlüsseln nachziehen.

## Nachtrag (nach dem Einspielen von 20261004002101)

Migration `20261004003939_fehlbild_familien_entwuerfe.sql`: fünf Entwurfs-Familien
(brueche_anteile, kommazahlen, potenzen_wurzeln, runden, rechenart_formel), 33 Slugs
zugeordnet, darunter alle 21 LSA-Slugs ohne Familie. Elternschranke per Funktionstest
`fehlbild_familien_entwurf.PRUEFUNG.sql` belegt. Offen: Lenas Abnahme der Familien
(Abschnitt 0 der Abnahmeliste).
