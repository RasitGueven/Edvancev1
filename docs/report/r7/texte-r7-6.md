# R7-6 · Texte alt → neu (Entwürfe für Lena)

Stand 20.10.2026. Alle neuen Texte sind Entwürfe (Bauauftrag R7-6, Entscheidung 8). Namespace
`elternbericht`, Datei `src/i18n/locales/de/elternbericht.json`.

## Seite 1

| Schlüssel | alt | neu |
|---|---|---|
| `s1.blick.zeile` | {{untersucht}} von {{katalog}} Bereichen untersucht · {{sicher}} sicher · {{uebung}} Übungsbedarf · {{offen}} nicht untersucht | {{untersucht}} Bereiche geprüft · {{sicher}} sicher · {{uebung}} Übungsbedarf |
| `s1.geprueft.text` | Je nach Antwort hat das System die nächste Aufgabe gewählt. So wurden {{untersucht}} von {{katalog}} Bereichen des Katalogs bis Klasse {{klasse}} untersucht. | Ausgehend vom Thema {{thema}} hat das System je nach Antwort die nächste Aufgabe gewählt. So wurden {{untersucht}} Bereiche gezielt geprüft. |
| `s1.geprueft.textOhneThema` | – (neu) | Je nach Antwort hat das System die nächste Aufgabe gewählt. So wurden {{untersucht}} Bereiche gezielt geprüft. |
| `s1.geprueft.hinweis_one` | Über den nicht untersuchten Bereich enthält dieser Bericht keine Aussage. Mehr dazu auf Seite 2. | entfällt |
| `s1.geprueft.hinweis_other` | Über die {{count}} nicht untersuchten Bereiche enthält dieser Bericht keine Aussage. Mehr dazu auf Seite 2. | entfällt |
| `s1.geprueft.hinweis` | – (neu) | Dieser Bericht sagt nur etwas über die geprüften Bereiche. Weitere Bereiche lernen wir in den ersten Sitzungen kennen. |
| `s1.geprueft.hinweisThema` | – (neu) | Zahlen und Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche. |
| `s1.thema.umfang_one` / `_other` | – (neu) | Zum Thema {{thema}} gehört ein Bereich. / Zum Thema {{thema}} gehören {{count}} Bereiche. |
| `s1.thema.direkt_one` / `_other` | – (neu) | Einen davon haben wir direkt geprüft / {{count}} davon haben wir direkt geprüft |
| `s1.thema.alleDirekt` | – (neu) | Alle davon haben wir direkt geprüft. |
| `s1.thema.abgeleitetRest_one` / `_other` | – (neu) | , der übrige ergibt sich aus diesen Aufgaben. / , die übrigen {{count}} ergeben sich aus diesen Aufgaben. |
| `s1.thema.abgeleitetTeil_one` / `_other` | – (neu) | , ein weiterer ergibt sich aus diesen Aufgaben. / , {{count}} weitere ergeben sich aus diesen Aufgaben. |
| `s1.thema.offen_one` / `_other` | – (neu) | Einen Bereich klären wir in den ersten Sitzungen. / Die übrigen {{count}} klären wir in den ersten Sitzungen. |
| `s1.thema.punkt` | – (neu) | . (Satzende nach `s1.thema.direkt`, wenn nichts abgeleitet ist) |

## Seite 2

| Schlüssel | alt | neu |
|---|---|---|
| `s2.intro` | Untersucht: {{untersucht}} von {{katalog}} Bereichen des Katalogs. Davon {{sicher}} sicher, {{uebung}} mit Übungsbedarf. | Geprüft: {{untersucht}} Bereiche. Davon {{sicher}} sicher, {{uebung}} mit Übungsbedarf. |
| `s2.introOffen_one` / `_other` | Ein Bereich wurde nicht untersucht. / {{count}} Bereiche wurden nicht untersucht. | entfällt |
| `s2.zahl.offen` | nicht untersucht | entfällt |
| `s2.zahl.geprueft` | – (neu) | Bereiche geprüft |
| `s2.profil.untersucht` | {{untersucht}} von {{vorhanden}} untersucht | entfällt |
| `s2.profil.geprueft` | – (neu) | {{count}} geprüft |
| `s2.profil.aria` | {{feld}}: {{untersucht}} von {{vorhanden}} untersucht, davon {{sicher}} sicher und {{uebung}} mit Übungsbedarf. | {{feld}}: {{untersucht}} geprüft, davon {{sicher}} sicher und {{uebung}} mit Übungsbedarf. |
| `s2.profil.ariaKeiner` | {{feld}}: 0 von {{vorhanden}} untersucht. | entfällt (Felder ohne geprüften Bereich haben keine Zeile mehr) |
| `s2.profil.legende.offen` | Nicht untersucht | entfällt |
| `s2.fussnote` | Die Streifen zeigen die Verteilung der Katalogbereiche, keine Note und keinen Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. Schraffierte Bereiche wurden nicht untersucht und sagen nichts über {{name}} aus. | Jedes Segment steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts. |

Unverändert (Entscheidung 5): `s2.titel`, `s2.titelOhneName`, `s3.*`, `s4.titelKeiner` mit „untersucht“,
`s2.profil.hinweis` („Jedes Segment steht für eine Kompetenz“, siehe offene-punkte-r7-6.md).

## Zusammengesetzte Sätze der Testfälle

Kasten „So haben wir geprüft“, Seite 1:

**abgestuft** (wie 6220b7e8; 14 / 5 / 9 / 0)
> Ausgehend vom Thema Reelle Zahlen hat das System je nach Antwort die nächste Aufgabe gewählt. So
> wurden 12 Bereiche gezielt geprüft.
> Zum Thema Reelle Zahlen gehören 14 Bereiche. 5 davon haben wir direkt geprüft, die übrigen 9 ergeben
> sich aus diesen Aufgaben.
> Zahlen und Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche.

**abgestuftMitOffen** (wie 09cf8baa; 14 / 6 / 5 / 3)
> Ausgehend vom Thema Reelle Zahlen hat das System je nach Antwort die nächste Aufgabe gewählt. So
> wurden 6 Bereiche gezielt geprüft.
> Zum Thema Reelle Zahlen gehören 14 Bereiche. 6 davon haben wir direkt geprüft, 5 weitere ergeben sich
> aus diesen Aufgaben. Die übrigen 3 klären wir in den ersten Sitzungen.
> Zahlen und Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche.

**ilkay** (fest; kein Thema-Satz)
> Ausgehend vom Thema Terme und Gleichungen hat das System je nach Antwort die nächste Aufgabe gewählt.
> So wurden 27 Bereiche gezielt geprüft.
> Dieser Bericht sagt nur etwas über die geprüften Bereiche. Weitere Bereiche lernen wir in den ersten
> Sitzungen kennen.

**ohne Thema** (Suchweg ohne Label)
> Je nach Antwort hat das System die nächste Aufgabe gewählt. So wurden 12 Bereiche gezielt geprüft.

Weitere Fassungen des Thema-Satzes (Unit-Tests, `Seite1Thema.test.tsx`):

- alle direkt: „Zum Thema Reelle Zahlen gehören 4 Bereiche. Alle davon haben wir direkt geprüft.“
- ein Bereich, direkt: „Zum Thema Reelle Zahlen gehört ein Bereich. Alle davon haben wir direkt geprüft.“
- 2 / 1 / 1 / 0: „… gehören 2 Bereiche. Einen davon haben wir direkt geprüft, der übrige ergibt sich aus
  diesen Aufgaben.“
- 3 / 1 / 1 / 1: „… gehören 3 Bereiche. Einen davon haben wir direkt geprüft, ein weiterer ergibt sich aus
  diesen Aufgaben. Einen Bereich klären wir in den ersten Sitzungen.“
- 14 / 6 / 0 / 8: „… gehören 14 Bereiche. 6 davon haben wir direkt geprüft. Die übrigen 8 klären wir in
  den ersten Sitzungen.“

Seite 2, **abgestuft**: „Geprüft: 12 Bereiche. Davon 4 sicher, 8 mit Übungsbedarf.“ — Zahlen 4 | 8 | 12,
rechts je Zeile z. B. „3 geprüft“ / „2 sicher · 1 Übungsbedarf“.
