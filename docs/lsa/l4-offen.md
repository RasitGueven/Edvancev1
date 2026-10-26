# LSA-L4 · Offene Punkte

Stand 26.10.2026. Bauauftrag `docs/lsa/Bauauftrag-L4.md`, Simulation `docs/lsa/l4-simulation.md`.

## Auswahl (Teil A–C, eingespielt, #326)

- **Abstieg unter einen falschen ★-Knoten** (Zweitprüfung): Die Regel ist unverändert; sie verlangt Knoten ohne Urteil.
  Unter einem ★ sind die Voraussetzungen meist von derselben Wurzel schon mitbelegt. Dann gibt es faktisch keinen
  Abstieg. Kein Test deckt diesen Fall ab.
- **Rückblick ohne Thema** filtert nicht nach Skills kommender Themen (`v_neu_sk`). Das gilt mit Thema genauso, denn
  der Rückblick nimmt nur Einstiege behandelter Themen.
- **Früh leer ohne Thema:** Max (Prod-Pool) bei 7:42, Nele bei 16:55. Nicht aufgefüllt (Entscheidung 9).
- **Prod-Pool:** Batus LSA ist auch mit L4 nach rund 14 Minuten leer. Mit Lenas 36 Freigaben trägt sie bis Minute 19
  (`l4-lena-fixture.sql`).

## Berichtstexte (Teil D)

- **Startdialog:** Der Hinweis erscheint, wenn kein Klassenarbeits-Stand gewählt ist oder „weiß nicht“. Für
  „geschrieben ohne Note“ gibt es keinen eigenen Hinweis: Der vorgegebene Wortlaut („startet mit dem aktuellen Thema“)
  stimmt dann nicht. Die Analyse läuft `vorschau_zuerst` mit 4 Minuten Thema, der Bericht nimmt den Fall „Note offen“.
- **Fall „geschrieben, Note offen, kein Bereich im Thema direkt geprüft“:** Er ist im Auftrag nicht vorgesehen. Dann
  steht „Die Arbeit zu {Thema} ist geschrieben.“ und der Abgleich. Rasit möge den Wortlaut bestätigen.
- **Mehrzahl:** Bei zwei Bereichen steht „sicher waren …“, „… waren noch unsicher“, „… werden bei Klassenarbeit {k}
  wieder gebraucht“ (i18n `count`).
- **Coach-Ansicht:** Ohne Lesezugriff auf den Lead bleibt das Erstgespräch null, der Satz zeigt dann den Fall
  „steht an/unbekannt“. Das ist schon heute so; der Stand der Sitzung liegt zwar in `lsa_sessions`, wird aber nur
  zusammen mit dem Erstgespräch verwendet.
- **Monatsbericht:** Die Anzeige einer nachträglich gemeldeten Note (L3-offen) ist nicht Teil von L4.

## Zweitprüfung Teil D (frischer Subagent, nur lesend)

- **Wortlaut, Weglassregeln, Quelle, Leitplanken, i18n und Tokens:** ok.
- **Umgesetzt nach der Prüfung:**
  - „Deshalb beginnt diese Übersicht …“ heißt jetzt „Diese Übersicht beginnt …“. Hinter den neuen Sätzen las sich
    „Deshalb“ wie eine Ursache.
  - Bereichsnamen stehen in Anführungszeichen (`v4.s3.ka.bereich`). Namen mit „und“ verschwimmen sonst in der
    Aufzählung.
- **Bewusst offen:**
  - Kein Hinweis bei „geschrieben ohne Note“ (siehe oben).
  - Ohne Erstgespräch (Coach) wird der Modus der Sitzung nicht genutzt.
  - Im Badge „GESCHRIEBEN · NOTE 4“ in Station 03 rutscht die Note bei schmaler Karte in die zweite Zeile. Das ist
    V4-Bestand und nicht Teil dieser Änderung.
