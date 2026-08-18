// Eltern-Report — Fazit und Begründung der Paketempfehlung (R4).
//
// Eigene Datei, damit ein Test sie importieren kann, ohne main() des Generators
// auszulösen — build-eltern-report.ts ruft main() beim Laden auf.
//
// ----------------------------------------------------------------------------
// Warum hier KEINE Terminzahl steht
// ----------------------------------------------------------------------------
// Bis zur Preiskorrektur vom 18.08. nannte die Begründung die Frequenz ein
// zweites Mal: „Zwei Termine pro Woche reichen…" (Basic) und „Drei Termine geben
// dafür genug Raum…" (Standard). Die Zahl stand damit an zwei Stellen — einmal
// als `.freq` aus tiers.features[0], einmal als Prosa daneben.
//
// Als die echten Frequenzen (1 / 1,5 / 2 pro Woche) in tiers landeten, war die
// Prosa still falsch: Das Dokument nannte für Basic zwei Termine, während die
// Zeile darüber einen auswies. Aufgefallen ist es nur, weil jemand die
// Preistabelle gegengelesen hat.
//
// Deshalb trägt die Zahl jetzt genau eine Stelle: die `.freq`-Zeile, direkt aus
// der Datenbank. Die Begründung verweist mit „dieser Rhythmus" darauf, statt
// ihn zu wiederholen. Ein Test (paketTexte.test.ts) hält das fest.
//
// Nebeneffekt, der die Reihenfolge entschärft: Die Texte sind dadurch sowohl
// mit dem alten als auch mit dem korrigierten Tarifbestand richtig.

/** Der Schlusssatz je Paket — was aus dem Befund folgt. */
export const FAZIT: Record<string, string> = {
  Premium:
    'Die Schwierigkeiten liegen nicht im aktuellen Thema selbst — die Grundlagen darunter tragen noch nicht durchgehend. Wir beginnen deshalb dort und arbeiten uns zum aktuellen Thema vor. Da die Bereiche über mehrere Themen verteilt sind, nehmen wir sie nacheinander vor, nicht gleichzeitig.',
  Standard:
    'Das aktuelle Thema steht. Was darunter noch nicht sicher ist, lässt sich benennen und der Reihe nach aufarbeiten — wir beginnen unten und halten das übrige Niveau parallel.',
  Basic:
    'Der Lernstand trägt weitgehend. Die wenigen Bereiche, die noch nicht sicher sind, nehmen wir im laufenden Unterricht mit.',
}

/** Warum dieses Paket zum Befund passt. Nennt bewusst keine Terminzahl. */
export const WARUM: Record<string, string> = {
  Premium:
    'Es sind mehrere Bereiche, und ein Teil davon liegt unter dem aktuellen Stoff — das braucht Wiederholung in kurzen Abständen.',
  Standard:
    'Die Bereiche liegen dicht beieinander und lassen sich zügig aufarbeiten. Dieser Rhythmus gibt dafür genug Raum, ohne dass der übrige Stoff liegen bleibt.',
  Basic:
    'Es geht um wenige Bereiche. Dieser Rhythmus reicht, um sie aufzuarbeiten und den laufenden Stoff mitzunehmen.',
}
