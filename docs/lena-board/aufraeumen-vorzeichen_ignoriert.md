# Aufräumen: Werte unter vorzeichen_ignoriert, die nicht zur Beschreibung passen

Stand 19.10.2026, nach L1 (PR #274). Klartext seit `20261019100100_l1_lena_fehlbilder`:
„Rechnet nur mit den Beträgen und lässt Minuszeichen weg (z. B. −4 + 9 als 4 + 9, −6 − 2 als 6 − 2).“

Nur Vorschlag, keine Datenänderung. Vor einer Umstellung `task_pruefung_ausgang` mitziehen (wie in L1) und bei
Aufgaben mit Status `ready` kurz mit Lena abstimmen.

| task_id | Aufgabe | Status | Wert | warum es nicht passt | besser (Familie vorzeichen) |
|---|---|---|---|---|---|
| 2e8ce53f-1357-48b2-8d76-0633ae836980 | −4 · (−6) = 24 | ready | `-24` | Mit Beträgen kommt 24 heraus. −24 ist der richtige Betrag mit gekipptem Vorzeichen. | `betrag_fehler` |
| e58cb290-db86-40df-b60b-03aee393107b | −8 · (−3) = 24 | ready | `-24` | ebenso | `betrag_fehler` |
| 7db70449-d6fa-47dd-9423-1e8c75ce8c8f | −36 : (−6) = 6 | ready | `-6` | ebenso (Beträge ergeben 6) | `betrag_fehler` |
| a368a0d0-25fd-4cc9-a873-541afbb9e864 | x · (x − 3) = 0, größere Lösung (Platzhalter) | draft | `−3`, `-3` | Ein Minus kommt hinzu, statt wegzufallen: Die Lösung wird aus (x − 3) mit falschem Vorzeichen abgelesen. | `vorzeichen_aus_klammer` |
| 07f970aa-ff64-4158-a713-9943054621a0 | Kerze 24 cm, 1,5 cm/h kürzer, nach 6 h | draft | `33`, `+33`, `33 cm`, `33cm`, `+33 cm`, `+33cm` | Im Text steht keine negative Zahl; die Abnahme wird als Zunahme gerechnet (24 + 9). | keiner passt sauber; außerhalb der Familie `falsche_richtung` (sachaufgaben) |
| 8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24 | (x + 5)² − (x + 2)(x − 2) für x = 100 | draft | `21021` | Das Minus vor der Klammer wird übersehen (Rechenzeichen, kein Betrag): (x + 5)² + (x² − 4). | keiner passt sauber; außerhalb der Familie `klammer_vergessen` (klammern), besser ein eigener Slug „Minus vor der Klammer übersehen“ |
| b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261 | (x + 5)² − (x + 2)(x − 2), MC | draft | `d` (2x² + 10x + 21) | ebenso | wie 8c4a2d71 |
| c31fdbb1-9a48-4cd8-9b0c-35393af84330 | (x + 3)² − (x − 3)², MC | draft | `d` (2x² + 18) | ebenso: (x + 3)² + (x − 3)² | wie 8c4a2d71 |

Kollisionen beim Umhängen: Für keinen der Werte steht in derselben Aufgabe schon ein Schlüssel unter dem
vorgeschlagenen Slug. Bei 2e8ce53f, e58cb290 und 7db70449 trägt bisher kein Wert `betrag_fehler`.
