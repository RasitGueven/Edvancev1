# Retro R7-7 · Nur noch der Bogen R7, eingepasst am Bildschirm (20.10.2026)

## Gebaut
- `ReportPage` zeigt immer den Bogen. `?fassung` fällt beim Laden aus der URL (replace), der
  Umschalter entfällt, die Pakete werden einmal je Seite geladen.
- R6 gelöscht: acht Komponenten und `ReportBody.test.tsx`. Die R6-Regeln in `print.css` sind raus.
- Neu `BerichtAnsicht`: zwei Spalten ab Containerbreite 1152 px (`@6xl`), daneben der Ausblick
  (360 px, sticky, eigene Scrollfläche). Der Bogen wird per `transform: scale(var(--eb-skala))`
  eingepasst, die Hüllenhöhe ist Bogen × s, beides per `style.setProperty`.
- Neu `Seitenleiste`: fünf Stationen, sticky, weiches Scrollen (bei reduzierter Bewegung sofort),
  `aria-current` per IntersectionObserver.
- `namensMessung` misst den Titel über `offsetHeight`. `Kurve.tsx` bleibt, der Test zeigt dieselben
  Knotenlagen bei Skala 1 und 0,6.
- Der Bogen bekommt einen key aus Session, Lernziel, Empfehlung und Paket, 400 ms entprellt.

## Entscheidungen
- Der key hängt am Bogen, nicht an der ganzen Ansicht. Sonst verlöre das Textfeld im Ausblick bei
  jedem Neueinhängen den Fokus.
- Die Hinweise („läuft noch“, Testlauf) bleiben in `ReportPage`, damit `components/` nichts aus
  `pages/` importiert.
- Beim Laden bekommt der Bogen die Notizen sofort, nur Eingaben werden entprellt. Sonst hinge er sich
  400 ms nach jedem Seitenaufruf ein zweites Mal ein.

## Gelernt
- Die Hülle mit fester Höhe ist ein Flex-Container. Ohne `self-start` streckt sie den inneren Kasten
  auf ihre Höhe, und jede ResizeObserver-Runde schrumpft die Höhe um einen weiteren Faktor s. Der
  Vitest-Test mit gemockten Maßen fand das nicht, erst das Bildschirmfoto im Harness.

## Offen
Siehe `docs/report/r7/offene-punkte-r7-7.md` (gekürzte Invarianten-Prüfungen, verwaiste
report.json-Schlüssel, Lib-Funktionen ohne Aufrufer).
