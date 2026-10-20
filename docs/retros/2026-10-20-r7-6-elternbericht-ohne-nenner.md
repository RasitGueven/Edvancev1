# Retro 20.10.2026 – R7-6 · Eltern-Bericht ohne Katalog-Nenner, mit Themenabdeckung

## Gebaut
- Seite 1: Zeile „Auf einen Blick“ und Prüftext ohne Katalog-Nenner; Prüftext mit und ohne Thema
  (Thema aus `Suchweg.themaLabel`); ein Hinweis ohne Plural. Neu der Thema-Satz bei abgestufter LSA
  mit Thema (`themaSatz.ts`, Teilsätze mit Plural) und dazu `s1.geprueft.hinweisThema`.
- Seite 2: Einleitung und drei Zahlen mit „Bereiche geprüft“ (Navy-Balken). Profil nur mit Feldern,
  in denen etwas geprüft wurde. Ein Segment fester Breite je geprüftem Bereich, linksbündig, ohne
  Schraffur. Legende nur Sicher und Übungsbedarf, Fußnote neu.
- `themaAbdeckung.ts` (reine Funktion + Test). `ReportErzaehlung.modus` und `.abgeleitet`, gelesen in
  `lsaReportErzaehlung.ts` (nur lesend, kein DDL).
- Fixtures `abgestuft` (wie 6220b7e8) und `abgestuftMitOffen` (wie 09cf8baa) mit echten Urteilen.
  `ilkay` setzt `modus: 'fest'` und die echten abgeleiteten Schlüssel.

## Entscheidungen
- Prod widersprach dem Befund: Alle sieben Sitzungen stehen auf `modus = 'adaptiv'`, auch Ilkay.
  Rasit hat entschieden, dass zusätzlich `raum.herkunft = 'abschluss'` gelten muss, sonst kein
  Thema-Satz (siehe offene-punkte-r7-6.md).
- INV-4.9 listet die von R7-6 geänderten und entfallenen Anhang-A-Schlüssel einzeln auf und prüft sie
  wörtlich; nichts gelockert.
- INV-4.3: Das Mapping auf `skillKey` liegt in `themaAbdeckungAus` (lib), nicht in der Komponente.
- Zweitprüfung: Schlägt das Lesen der abgeleiteten Urteile fehl, entfällt der Thema-Satz, statt sie
  als offen zu zählen.

## Ergebnis
- Typecheck, Lint und Vitest grün; Druck-Tests 23/23 grün (Port 5187), PDFs und Fotos in
  `docs/report/r7/abnahme/r7-6/`.
- Gegenrechnung 6220b7e8 auf Prod-Daten: 14/5/9/0.

## Offen
- Siehe `docs/report/r7/offene-punkte-r7-6.md`: Batu hat in Prod 13 geprüfte Bereiche
  (`nicht_angesetzt`), Wortlaut 12 gegen 5 für Lena, `s2.profil.hinweis`, ungenutzte Schraffur-Tokens.
