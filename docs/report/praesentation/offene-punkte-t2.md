# T2 · Rahmen – Abweichungen und offene Punkte

Stand 19.10.2026, Branch `feat/rasit-praesentation-rahmen`.

## Verträge für T3 und T4

Rahmen, Vorschau, Ansichtstests und Invarianten müssen T3 und T4 nicht ändern, wenn sie Folgendes einhalten:

- **Props:** `StationProps` aus `src/components/edvance/praesentation/stationProps.ts`
  (`{ p, anzeige, satz, sessionId }`). Die `<section class="tp-station">` legt der Rahmen um jede Station;
  die Station rendert nur ihren Inhalt in `.tp-szene .tp-s<n>`.
- **Bewegung:** An der `<section>` hängen `entered` (erster Besuch) und `motion-complete` (einmal verlassen,
  danach still). Selektoren also `.tp-station.entered .tp-s2 …` bzw. `.tp-station.motion-complete …`.
  Zeiten, Kurven und Keyframes (`tp-zeile-ein`, `tp-segment-ein`, `tp-zeichnen`, `tp-blenden`, `tp-pop`,
  `tp-label-ein`) stehen als Variablen unter `.tp` in `rahmen.css`. Elemente mit `tp-reveal` blenden
  nach `--tp-verzoegerung` ein.
- **Bausteine:** `Kicker` (Nummer zweistellig über Intl, Strich, Text), Klassen `tp-titel`, `tp-desc`,
  `tp-fusszeile`, `tp-etikett`.
- **Ansichtstests** (`e2e-praesentation/messen.ts`):
  - `data-tp-pflicht` – muss sichtbar sein (die Karten in 01 nach T3 Entscheidung 1).
  - `data-tp-liste` – wird als Ganzes gemessen und darf in sich scrollen (Zeilenliste in 02).
  - `data-tp-zeile` mit `data-tp-bereiche="<n>"` an jeder Zeile in 02; der Knopf darin trägt
    `aria-expanded`. Daraus wählt der Test die Zeile mit den meisten Bereichen und prüft „höchstens eins offen“.
  - `data-tp-beschriftung` (Beschriftungen und Förderfokus-Karte in 04) und `path[data-tp-kurve]`.
  - Ohne diese Attribute laufen die jeweiligen Prüfungen leer (heute bei den Hüllen der Fall).
- Kopf und Leiste liegen über den Stationen; der Test meldet jedes Element, das darunter rutscht, und
  alles, was links, rechts, oben oder unten (−8 px) aus der Station ragt. Pflichtteile müssen zu mindestens
  95 % zu sehen sein. Verschachtelte `data-tp-beschriftung` (Label in der Karte) zählen nicht als Überlappung.
- **Leere Prüfungen:** Fehlt ein Attribut, prüft der Ansichtstest still nichts. T3 und T4 sichern deshalb in
  ihren Vitest-Tests, dass `data-tp-zeile`, `data-tp-liste`, `path[data-tp-kurve]` und `data-tp-beschriftung`
  dort gesetzt sind, wo es Zeilen bzw. Schwerpunkte gibt.
- **Invarianten** (INV-4.12): Feldschlüssel nur als `key` oder in einer i18n-Vorlage der Form
  `` `feld.${x.feld}` `` / `` `elternbericht:feld.${…}` `` bzw. `` `s3.ebene.${…}` ``; Inline-Styles nur mit
  berechneten Werten; `color-mix` nur als `color-mix(in srgb, var(--color-eb|tp-…) N%, transparent)`.
  Kein `* 100`, kein `toFixed`, kein String mit `%` in .ts/.tsx: Breiten der Pyramide über feste Klassen je
  Position, Lage der Kurvenpunkte als Zahl in eine CSS-Variable (`--x: 30.4`) und im CSS
  `calc(var(--x) * 1%)`; Pfadkoordinaten bei Bedarf mit `Math.round(v * 10) / 10`. Die Hex-Prüfung trifft
  auch `url(#abc)` – SVG-Ids deshalb nicht aus Hex-Buchstaben bilden (z. B. `#tp-punkte`).

## Abweichungen vom Dummy (mit Grund)

- **Schließen statt Einstellungen** (X, 44 px), kein „Konzept · Testdaten“, keine „Gestaltungsstudie“ in der Ecke
  des Intros (Entscheidung 12).
- **Kicker im Intro** „Lernstandsanalyse {Fach}“ (Entscheidung 5).
- **Höhe** über die Ebene (`position: fixed; inset: 0`, Stationen `height: 100%`) statt `100dvh` – gleiche Wirkung,
  die Ebene ist selbst die Bildschirmfläche.
- **Farben** auf eb-Tokens gerundet: Grautöne des Intros und der Leiste (`#72818A`, `#7C8990`, `#6E818B`,
  `#96A4AD`, `#9BAAB1`) → `--color-eb-leise`; Kreise und Striche (`#BDCCD2`, `#BCCBD1`) → `--color-eb-nav-linie`,
  `#9DB0B7` → `--color-eb-nav-punkt`; Intro-Fläche `#F9F8F5` → `--color-eb-papier`; Logo `#334E77` →
  `--color-eb-navy`, `#E6A038` → `--color-eb-gold`. Eddie und Lichtschein mit `--color-tp-kugel-*` /
  `--color-tp-schein` über `color-mix`.
- **Leiste bei ≤ 800 px:** Eddie 3 px höher (`top: 6px`), weil die Einträge dort 46 statt 52 px hoch sind; im
  Dummy saß die Kugel dort 3 px unter der Mitte.
- **Hüllen:** Station 01 trägt schon den Kopfsatz bzw. die Ersatzüberschrift (dieselbe Logik wie `Seite1.tsx`),
  Station 04 noch immer `s4.titel` – den Fall ohne Schwerpunkt (`titelKeiner`) baut T4.

## Offen

1. **WebKit** ließ sich installieren, startet in WSL aber nicht: es fehlen Systembibliotheken (gtk4, graphene,
   gstreamer, flite …), `install --with-deps` braucht sudo. Die Config nimmt WebKit deshalb nur mit
   `TP_WEBKIT=1` dazu. Safari bleibt Teil der iPad-Abnahme (Abnahme 4).
2. **Port 5185** war zwischenzeitlich von einem anderen Worktree (`Edvancev1-r7d`) belegt; Zwischenläufe
   liefen auf 5195, der Schlusslauf (164/164) auf 5185.
3. **Chromium in WSL** braucht `libasound.so.2` (ohne root per `apt-get download libasound2t64` und
   `LD_LIBRARY_PATH`).
4. **Fotos:** je Fall und Station bei 820×1180 und 1180×820 unter `abnahme/t2/`, dazu das Intro von Ilkay. Die
   Stationen zeigen in T2 nur Kicker und Titel.
5. **Ilkay im Intro:** Der Name kommt aus `firstName` (getrimmt); ohne Namen „Ihr Kind“. Ein sehr langer Rufname
   bricht im Intro um (`clamp(70px, 10vw, 118px)`), nicht geprüft.
