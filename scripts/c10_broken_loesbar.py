#!/usr/bin/env python3
"""C10 Teil 2A: ohne_bild_loesbar-Urteil fuer die 17 URL-Items, deren Bilder ALLE
'unbrauchbar' sind (Foto/Grafik im Render verloren ODER nur MC-Optionen als Bild).
Handklassifiziert aus Sichtbefund + Aufgabentext.
Format: Titel -> (ohne_bild_loesbar, begruendung)
"""

BROKEN = {
 "Butter": ("nein", "Die abzuschaetzende Buttermenge ergibt sich nur aus dem (fehlenden) Foto des 250-g-Stuecks."),
 "Der Riese": ("nein", "Ohne die Zeichnung ist das Groessenverhaeltnis Kopfteil↔Riese nicht bestimmbar."),
 "Gewerbezone": ("nein", "Die Flaechenangaben stehen nur auf dem (fehlenden) Plakat, nicht im Text."),
 "Gewitter": ("ja_sicher", "Alle Werte (3 s/km, 4,5 s, 5,5 km) stehen im Text; die Abbildung ist reiner Stimulus."),
 "Honigbiene": ("nein", "Die Bienenlaenge ist nur aus dem (fehlenden) Foto schaetzbar, nicht aus dem Text."),
 "Im Kreis laufen": ("nein", "Die Antwort ist der passende Graph — die vier Graphen sind die Grafik und im Render zerstoert."),
 "Lage der Würfel": ("nein", "Die abgebildeten Augenzahlen fehlen im Render und stehen nicht im Text."),
 "Parfum": ("ja_sicher", "Rechnung nutzt 0,2 ml/Pumpstoss aus dem Text; die Fotos (Flasche/Zerstaeuber) sind dekorativ."),
 "Prozentanteil schätzen": ("nein", "Der graue Anteil ist nur aus der (fehlenden) Kreisgrafik schaetzbar."),
 "Pyramidenbau": ("nein", "Anzahl Staebe/Kugeln muss aus den (fehlenden) Abbildungen von Pyramide und Netz gezaehlt werden."),
 "Schneekristalle": ("nein", "Die Symmetrieachsen sind nur am (fehlenden) Kristallbild zaehlbar."),
 "Streichholzziehen": ("ja_sicher", "P = 1/5 folgt aus dem Text (5 Hoelzer, 1 kurzes); das Foto ist dekorativ."),
 "Tankinhalt": ("nein", "Die Rechnung braucht die auf der (fehlenden) Bordcomputer-Anzeige gezeigten Werte."),
 "Traktor": ("ja_sicher", "Die vier Massstaebe stehen im Text; kein Bild noetig."),
 "Unfertiger Würfel": ("nein", "Welche Wuerfel schon verbaut sind, zeigt nur die (fehlende) Zeichnung."),
 "Wahrscheinlicher": ("ja_sicher", "Beide Ereignisse stehen als Text; keine Grafik noetig."),
 "Zahlenwürfel": ("ja_sicher", "W30 mit Zahlen 1–30 ist im Text beschrieben; das Foto ist dekorativ."),
}
