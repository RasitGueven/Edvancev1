# Bauauftrag R7-8 · Seite 2: Klassenstufen, abgeleitete Bereiche, vollere Karte

Stand 20.10.2026. Rückmeldung Rasit zu Seite 2 (Batu Test1): Je Bereich soll stehen, aus welchen
Klassen die Kompetenzen stammen, und die Karte wirkt wegen der kleinen Kästchen leer.
Entscheidungen Rasit: abgeleitete Bereiche als Umriss-Kästchen (nur abgestufte LSA), Klassen als
Spanne je Zeile. Läuft parallel zu R7-7; die beiden Pakete berühren keine gemeinsamen Dateien.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-8: Das Kompetenzprofil auf Seite 2 des Eltern-Berichts R7 zeigt je Themenfeld die Klassenstufen, bei abgestuften LSAs zusätzlich die abgeleiteten Bereiche als Umriss-Kästchen, und die Kästchen werden größer. Voraussetzung: R7-1 bis R7-6 gemergt (#273, #277, #278, #279, #283, #285; sonst STOPP). Läuft parallel zu R7-7 (App-Ansicht): ReportPage, src/components/edvance/report/**, namensMessung.ts, Kurve.tsx, rahmen.css, print.css fasst du nicht an.

## Ausgangslage
- Seite 2: Profil.tsx, seite2Rechnung.ts (SPUR 226 pt, SEGMENT_MAX 18 pt, LUECKE 4 pt, segmentBreite je Zeile), seite2.css. Jede Zeile rechnet ihre Kästchenbreite selbst; bei wenigen geprüften Bereichen bleiben die Kästchen 18 pt schmal und die Karte wirkt leer.
- themaAbdeckung (src/lib/report/elternbericht/themaAbdeckung.ts) zählt bei abgestufter LSA (modus 'adaptiv', raum.herkunft 'abschluss', abgeleitete Urteile geladen) die abgeleiteten Bereiche im Themenraum; Seite 1 nennt sie im Thema-Satz. Ihre Schlüssel liegen in data.erzaehlung.abgeleitet, Feld über feldVon(), Klasse über data.erzaehlung.katalog (KatalogSkill.klasse). Direkt geprüfte Bereiche (EbBereich) tragen klasse.

## Entscheidungen (nicht neu verhandeln)
1. Abgeleitete Bereiche im Profil:
   - Nur wenn themaAbdeckung nicht null ist, und genau dieselben Bereiche, die der Thema-Satz als abgeleitet zählt (im Themenraum, nicht direkt geprüft). Summe der Umriss-Kästchen über alle Zeilen = themaAbdeckung.abgeleitet (Test).
   - themaAbdeckung gibt dafür zusätzlich die Schlüssel zurück (abgeleiteteSchluessel: string[], sortiert). Sonst bleibt die Funktion unverändert; bestehende Tests grün.
   - Je abgeleitetem Bereich ein Umriss-Kästchen hinter den farbigen: Fläche --color-eb-papier, Rand 0,7 pt in --color-eb-schraffur-rand (oder dem vorhandenen Linien-Token), gleiche Größe und Lücke wie die farbigen. Keine Farbe für sicher/Übungsbedarf, kein Zustand, kein Label.
   - Ein Feld, das nur abgeleitete Bereiche hat, bekommt eine Zeile (nur Umrisse).
   - Rechts erste Zeile: „{{count}} geprüft“, bei abgeleiteten zusätzlich „ · {{count}} abgeleitet“ (s2.profil.abgeleitet); nur abgeleitete: nur „{{count}} abgeleitet“. Zweite Zeile wie bisher (sicher · Übungsbedarf, nur direkt).
   - Vorlesetext: s2.profil.aria wie bisher, bei abgeleiteten dahinter s2.profil.ariaAbgeleitet „{{count}} weitere ergeben sich aus den Aufgaben.“
   - Legende: dritter Eintrag „Aus den Aufgaben abgeleitet“ (s2.profil.legende.abgeleitet) mit Umriss-Kästchen, nur wenn es abgeleitete gibt.
   - Fußnote: bei abgeleiteten zusätzlich s2.fussnoteAbgeleitet „Umrandete Kästchen sind Bereiche des Themas, die sich aus den geprüften Aufgaben ergeben. Sie wurden nicht einzeln geprüft und tragen deshalb keine Farbe.“
   - Seite 1: s1.geprueft.hinweisThema wird „Die Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche.“ (Seite 2 nennt jetzt auch Zahlen für Abgeleitetes.)
2. Klassenstufe je Zeile:
   - Unter dem Feldnamen eine leise Zeile: „Klasse {{k}}“ bei einer Stufe, „Klasse {{von}}–{{bis}}“ bei mehreren (s2.profil.klasse, s2.profil.klasseSpanne). Gerechnet aus min und max der Klassen aller Kästchen der Zeile (direkt geprüfte und, falls angezeigt, abgeleitete). Fehlt für einen abgeleiteten Schlüssel die Klasse im Katalog, zählt er für die Spanne nicht (Kästchen bleibt).
   - Schrift und Farbe wie die zweite Zeile rechts; die Zeile ändert die Zeilenabstände nicht (40,8 / 33,4 / 30 pt bleiben, die Klassenzeile sitzt im vorhandenen Raum; nachmessen).
3. Größere Kästchen mit einem Maßstab für alle Zeilen:
   - n_max = größte Kästchenzahl einer Zeile (farbig + Umriss). Breite für ALLE Zeilen = min(28 pt, (226 − (n_max − 1) · Lücke) / n_max). Lücke 4 pt bis 16 Kästchen, 2 pt bis 30, darüber 1 pt (wie R7-3). Radius min(3,5 pt, Breite / 3). Höhe wie bisher.
   - So sind Zeilen untereinander vergleichbar (gleiche Kästchengröße), und die längste Zeile füllt die Spur weitgehend.
   - Kopf rechts der Karte: s2.profil.hinweis = „Jedes Kästchen steht für einen Bereich“ (statt „Segment … Kompetenz“).
   - s2.fussnote: „Jedes Segment“ → „Jedes Kästchen“, sonst unverändert.
4. Seiten 1 (außer hinweisThema), 3, 4 und 5 bleiben unverändert. Die Zählung (zaehle) bleibt unverändert.
5. Alle neuen und geänderten Texte sind Entwürfe für Lena: in docs/report/r7/texte-r7-8.md alt → neu.

## Umfang
src/components/edvance/elternbericht/Seite2.tsx, Profil.tsx, seite2Rechnung.ts (+ Tests), src/styles/elternbericht/seite2.css, src/lib/report/elternbericht/themaAbdeckung.ts (+ Test, nur abgeleiteteSchluessel), src/lib/report/elternbericht/fixtures/** (nur wenn ein Fall Klassen oder Katalog für abgeleitete braucht), src/i18n/locales/de/elternbericht.json (nur die genannten Schlüssel unter s1.geprueft.hinweisThema und s2.*), src/test/invariants/inv4-elternbericht.test.ts nur, wenn INV-4.9 einen geänderten Schlüssel wörtlich erwartet (wie in R7-6: einzeln auflisten, nichts lockern), docs/report/r7/texte-r7-8.md, docs/report/r7/offene-punkte-r7-8.md, Retro. Nicht anfassen: ReportPage, src/components/edvance/report/**, Bogen.tsx, Seite.tsx, seitenProps.ts, namensMessung.ts, Kurve.tsx, Seite1/3/4/5.tsx, rahmen.css, seite1/3/4/5.css, print.css, übrige src/lib/**, src/types/** (außer der Rückgabetyp von themaAbdeckung liegt dort; dann nur dieses Feld), praesentation/**, e2e-druck/**, playwright.elternbericht.config.ts, supabase/**.

## Tests
Vitest: Breite mit gemeinsamem Maßstab (n_max 1, 4, 7, 17, 31, 40; alle Zeilen gleich breit); Umrisse nur bei abgestuft und abgestuftMitOffen, nicht bei ilkay; Summe der Umrisse = themaAbdeckung.abgeleitet (9 bzw. 5); Zeile nur mit abgeleiteten; Klassenspanne (eine Stufe, Spanne, abgeleiteter ohne Katalog-Klasse); rechte Zeile mit und ohne „abgeleitet“; Vorlesetexte; Legende mit und ohne dritten Eintrag; Fußnote mit und ohne Zusatz. Druck-Tests für ALLE Fälle grün: EB_PORT=5189 EB_AUSGABE=docs/report/r7/abnahme/r7-8 npx playwright test -c playwright.elternbericht.config.ts. inv4-elternbericht grün. Typecheck, Lint, Vitest grün.
Mit dbread (nur lesend) für 6220b7e8 (Batu Test1) die Zeilen von Seite 2 gegenrechnen (Feld, geprüft, abgeleitet, Klassenspanne) und im PR als Tabelle nennen.

## Leitplanken
- Worktree ../Edvancev1-r7h auf feat/rasit-report-r7-seite2-klassen von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, Prod nur lesend über dbread.
- Designregeln CLAUDE.md §11 mit der R7-Ausnahme; keine Hex-Werte, kein style={{…}} (INV-4.11), Dateien ≤ 400 Zeilen.
- Läuft Seite 2 in einem Fall über: STOPP, Fall und Messwerte melden, nichts kürzen.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler: im PR vermerken, nichts ändern.
- Zweitprüfung durch eine frische Instanz, Schwerpunkt: Ist auf Seite 2 klar, was geprüft und was abgeleitet ist? Stimmen die Zahlen mit dem Thema-Satz auf Seite 1 überein? Taucht ein abgeleiteter Bereich mit Farbe, Zustand oder Label auf? STOPP nach dem PR.

## Melden
PR-Link, PDFs aus docs/report/r7/abnahme/r7-8/ (abgestuft, abgestuftMitOffen, ilkay, weitereBereiche), Bildschirmfoto Seite 2 von abgestuft, Gegenrechnung Batu als Tabelle, Texte alt → neu (texte-r7-8.md), offene Punkte (docs/report/r7/offene-punkte-r7-8.md).
```
