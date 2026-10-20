# R7-7 · Offene Punkte und Messwerte

Stand 20.10.2026, Branch `feat/rasit-report-r7-ansicht`. `/admin/report/:sessionId` zeigt nur noch
den Bogen R7, am Bildschirm eingepasst, mit Seitenleiste und dem Ausblick daneben.

## Abnahme-Material

- Druck-Tests aller Fälle: `EB_PORT=5188 EB_AUSGABE=docs/report/r7/abnahme/r7-7 npx playwright test
  -c playwright.elternbericht.config.ts`: 23 von 23 grün, PDFs unter `docs/report/r7/abnahme/r7-7/<fall>.pdf`.
- Bildschirmfotos der Admin-Seite, Fall `abgestuft`, Fenster 1440 × 900, 1024 × 900, 768 × 900:
  `fotos/ansicht-<breite>.png` (oben) und `fotos/ansicht-<breite>-seite4.png` (nach Klick auf
  „Lernplan“: Leiste und Ausblick bleiben stehen, Kurve liegt auf den Titeln).
- Druck-PDF derselben Seite über den Harness: `admin-druck.pdf`. Fünf Seiten, MediaBox
  594,96 × 841,92 pt (A4), randlos. Unter `media: print` gilt: Leiste und Ausblick `display: none`,
  kein transform, Hüllenhöhe `auto`, jede Seite 793,7 px = 595,28 pt breit.

## Messwerte im Harness (Chromium)

| Fenster | Spalten | Skala s | seitlich scrollbar | Name bleibt | Knoten Seite 4 (pt) |
|---|---|---|---|---|---|
| 1440 | 728 px + 360 px | 0,8766 | nein (0 px) | ja | 200,924 · 280,506 · 360,088 · 439,670 |
| 1024 | eine (880 px) | 1 | nein (0 px) | ja | 200,924 · 280,506 · 360,088 · 439,670 |
| 768 | eine (736 px) | 0,8866 | nein (0 px) | ja | 200,924 · 280,506 · 360,088 · 439,670 |

Die Knotenlagen unterscheiden sich zwischen den Skalen um weniger als 0,0002 pt (Rundung von
`getBoundingClientRect` unter transform). Der Vitest-Test mit Skala 1 und 0,6 zeigt sie gleich, deshalb
bleibt `Kurve.tsx` unverändert (Entscheidung 4).

## Gelöschte Dateien

`src/components/edvance/report/`: `ReportBody.tsx`, `ReportBefund.tsx`, `ReportFehlbilder.tsx`,
`ReportProfil.tsx`, `ReportRueckbezug.tsx`, `ReportSchluss.tsx`, `ReportSkillbefunde.tsx`,
`ReportSuche.tsx`, `ReportBody.test.tsx`. Vorher per grep geprüft: Importiert wurden sie nur von
`ReportPage.tsx`, untereinander und von `inv4-eltern-sprache.test.ts`.

## print.css

Entfernt sind die `.report-sheet`-Regeln und mit ihnen alle Regeln für Klassen, die nur die
gelöschten Komponenten setzten (`.report-block`, `.report-suche*`, `.report-befund-traegt`,
`.report-rueckbezug-marke`, `.report-profil-bild`, `.report-details-*`, `.report-winkel`,
`.report-marke`, `.report-schluss`). `.report-block` steht noch am Ausblick, der ist aber `print-hide`.
Geblieben: globale `@page`, `.print-hide`, weißer Hintergrund, `print-color-adjust`.

## report.json: Schlüssel ohne Nutzer (nicht gelöscht)

Nur noch von den gelöschten Komponenten benutzt (Abgleich gegen den Quelltext vor und nach der
Löschung; vor der Löschung war kein Schlüssel ungenutzt):

- `befund.description`, `befund.offenFuss`, `befund.offenTitel`, `befund.title`, `befund.traegtTitel`
- `fehlbild.description`, `fehlbild.title_one`, `fehlbild.title_other`
- `head.aufgaben_one`, `head.aufgaben_other`, `head.date`, `head.grade`, `head.subject`,
  `head.ueberschrift`, `head.umfang`
- `kontakt.frage`, `kontakt.frageOhneMail`, `kontakt.satz`
- `rueckbezug.art.befund`, `rueckbezug.art.entlastet`, `rueckbezug.art.offen`
- `skillbefunde.count_one`, `skillbefunde.count_other`, `skillbefunde.rest_one`,
  `skillbefunde.rest_other`, `skillbefunde.tiefe`

Weitere Schlüssel unter `suche.*`, `profil.*`, `schluss.*` usw. nutzt `src/lib/report/**` weiter
(Erzählung, Präsentation). Ob die Lib-Funktionen dahinter noch einen Aufrufer haben, ist nicht
geprüft; `src/lib/**` war für dieses Paket gesperrt.

Neu: `ansicht.seitenleiste` („Seiten des Berichts“, aria-Label der Leiste).

`elternbericht:fassung.zuR6` ist ungenutzt und bleibt stehen (INV-4.9 prüft Anhang A wörtlich).
`fassung.zuR7` ist weiter in Gebrauch: Titel des EmptyState in `Bogen.tsx`.

## Entfernte Prüfungen in inv4-eltern-sprache.test.ts

Ganz entfallen, weil sie nur gelöschte Dateien lasen:

1. INV-4.3 „ReportBody rendert den Fehlbild-Abschnitt nicht mehr selbst“
2. INV-4.3 „die Fehlbild-Komponente rendert weder Slug noch Familienschlüssel“
3. INV-4.3 „der angezeigte Satz kommt wörtlich aus der Datenbank“
4. INV-4.3 „der Skill-Abschnitt rendert das Label, niemals den skill_key“
5. INV-4.3 „der Skill-Abschnitt entfaellt, statt Leere zu behaupten“
6. INV-4.3 „der Skill-Abschnitt zeigt keine Fundamenttiefe als Zahl“
7. INV-4.4 „keine Ampelfarben auf den Eltern-Flaechen“
8. INV-4.4 „das Profil schreibt keine Zahl an die Achsen“
9. INV-4.4 „der Schluss rendert nichts ohne Daten“
10. INV-4.4 „der aufklappbare Befund steht im Druck offen“ (las `print.css`, prüfte aber die
    `.report-sheet`-Regel für `ReportBefund`, die nach Entscheidung 1 entfällt)

Gekürzt, weil sie gelöschte Dateien **und** bleibende Dateien lasen. Der Teil zu den bleibenden
Dateien läuft unverändert weiter. **Bitte prüfen**, ob das so gewollt ist. Der Auftrag sah nur
„entfallen“ oder „unverändert“ vor.

11. INV-4.3 „die Fehlbild-Komponente rendert keinen Coach-Klartext“ → „die Fehlbild-Gruppierung kennt
    keinen Coach-Klartext“: nur noch `lib/reportFehlbilder.ts`.
12. INV-4.3 „ohne abgenommenen Elterntext entfällt der Befund …“: ohne die Zeile zu
    `ReportFehlbilder` (`return null`), die Lib-Zeile bleibt.
13. INV-4.4 „keine Quote und keine Prozentzahl als Aussage“ → „keine Prozentzahl in report.json“:
    die Schleife über die R6-Komponenten entfällt, die Prüfung von report.json bleibt.
14. INV-4.4 „die Suche nennt beide Summanden im Klartext, ohne Balken“ → „… im Klartext“: nur noch
    der Wortlaut von `suche.zaehlung`.

Für den Bogen R7 decken INV-4.11 (`inv4-elternbericht.test.ts`) Quoten, Prozente, Schlüssel und
freie Farben ab.

## Weitere Testanpassungen außerhalb des Umfangs

- `src/components/edvance/elternbericht/Bogen.test.tsx`: Die Namensmessung wird über `offsetHeight`
  gemockt statt über `getBoundingClientRect` (Folge von Entscheidung 4, Erwartungen unverändert).
- `src/pages/admin/ReportPage.praesentation.test.tsx`: Die Pakete werden jetzt immer einmal geladen,
  vorher nie ohne Parameter. Nach dem Schließen der Präsentation ist die URL leer, weil `?fassung`
  schon beim Laden entfällt. Die Präsentation selbst ist unverändert.

## Offen

- Der Bogen hängt sich 400 ms nach der letzten Eingabe im Ausblick neu ein. Dabei sollte die
  Scrollposition nicht verloren gehen (die Hülle behält ihre Höhe; nicht eigens im Browser geprüft).
  Seite 4 misst ihre Stufen neu.
- `vorschau/main.tsx` (Druck-Vorschau) trägt weiter `.eb-ansicht`. Ohne `overflow-x: auto` scrollt die
  Vorschau bei schmalem Fenster über die Seite statt über den Kasten. Sie ist nur Testseite,
  unverändert gelassen.
- `src/lib/reportFehlbilder.ts` und Teile von `src/lib/report/**` haben nach der Löschung womöglich
  keinen Aufrufer mehr. Prüfen im Foundation-Fenster.
