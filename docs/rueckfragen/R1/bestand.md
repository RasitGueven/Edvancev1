# R1 · Bestand der Rückfragen (29.10.2026)

Read-only aus Prod (`~/bin/dbread`), Stand 29.10.2026. `tasks.status = 'rueckfrage'`: **6 Aufgaben**, wie erwartet.
Notiz = letzte Zeile in `task_pruefungen` (Entscheidung jeweils „unsicher“, noch keine Antwort).
Alle sechs: `einsatz = {lsa}`, `curriculum_grade = 8`, `freigabe_gate_fehler` ist heute schon null.

| # | id | Titel | skill_key | Kl. | Frage (Kern) | Lösung | Lenas Notiz | Datum |
|---|---|---|---|---|---|---|---|---|
| 1 | `8c4a2d71` | Binomische Formeln gemischt · vereinfachen und einsetzen · x = 100 | term_binom_gemischt | 8 | „Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein. (x + 5)² - (x + 2)(x - 2) = ?“ | 1029 | „Ich würde hier in der Aufgabenstellung formulieren "Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für  x = 100 ein."“ | 27.10. 15:27 |
| 2 | `a61e8be9` | Funktionsgleichung · aus m und b · Funktionswert | fkt_linear_gleichung | 8 | „… Steigung 3 und den y-Achsenabschnitt -2. Stelle die Funktionsgleichung auf und berechne damit f(4).“ | 10 | „Weil das hier in der 7/8 Klasse angesetzt ist, kann ich mir vorstellen, dass den SuS der Begriff f(x) noch nicht bekannt ist. Eventuell hier besser: an der Stelle x=4“ | 27.10. 15:58 |
| 3 | `ffc76634` | Funktionsgleichung · aus zwei Punkten · Achsenabschnitt | fkt_linear_gleichung | 8 | „Eine Gerade geht durch A(1 \| 1) und B(3 \| 7) … y = mx + b. Welchen Wert hat b?“ | −2 | „Es könnte auch passieren, dass die SuS sowohl beim Berechnen der Steigung und beim Einsetzten in die Gleichung hinterher den X-Wert und den Y-Wert vertauschen und das Ergebnis dann gänzlich falsch ist“ | 27.10. 16:02 |
| 4 | `1bbce78e` | Funktionsgleichung · fallend · Funktionswert | fkt_linear_gleichung | 8 | „… Steigung -2 und schneidet die y-Achse bei y = 5. Stelle die Funktionsgleichung auf und berechne damit f(3).“ | −1 | „s. meine Anmerkung zu f(x) bei der anderen Aufgabe“ | 27.10. 16:03 |
| 5 | `158c874c` | Einsetzungsverfahren · erst umstellen | gleichung_lgs_einsetzen | 8 | „Löse das Gleichungssystem mit dem Einsetzungsverfahren. Stelle dazu zuerst Gleichung I nach x um. I: x + 2y = 11, II: 3x - 4y = 3“ (MULTI_PART x =, y =) | x = 5, y = 3 | „Es kann auch passieren, dass das Kind die Aufgabe missversteht und nach y umformt, weil das "normal" ist“ (außerdem AFB II → I) | 28.10. 12:14 |
| 6 | `6274f6a5` | Raute · Seitenlänge als Ablenker | geo_flaeche_drachen_raute | 8 | „Eine Raute hat die Seitenlänge 13 cm. Ihre Diagonalen sind e = 24 cm und f = 10 cm lang. Wie groß ist ihr Flächeninhalt?“ (Einheit cm²) | 120 | „Es kann auch sein, dass die SuS hier die falsche Formel zur Berechnung nehmen, wie etwa die eines Dreiecks“ (außerdem AFB II → I) | 28.10. 12:26 |

Volle ids: `8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24`, `a61e8be9-b55f-4c43-9971-7b74e3d55a33`,
`ffc76634-86ca-4c53-b816-d18d7f868443`, `1bbce78e-f996-4c03-a78a-09b47f5c7445`,
`158c874c-248c-40ed-b8b5-af3eb627517a`, `6274f6a5-65e5-40f4-be09-36fa8931c424`.

`tasks.class_level` ist bei 2–4 leer; die Klasse oben ist `curriculum_grade` (bei allen 8).

Lenas AFB-Änderung (II → I) bei 5 und 6 steht schon in `tasks.afb` (I). Bei 5 tragen die beiden Teile in
`tasks.parts` weiter `afb: II`. Das gehört nicht zu Lenas Frage und bleibt in R1 unberührt (Hinweis im Bericht).

## Bauformen mit Status rueckfrage

`select … from public.bauformen where status = 'rueckfrage'`: **keine**. Nichts aufzulisten.
