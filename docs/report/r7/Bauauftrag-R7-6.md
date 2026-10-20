# Bauauftrag R7-6 · Eltern-Bericht ohne Katalog-Nenner, mit Themenabdeckung

Stand 20.10.2026. Anlass: Rasit findet Seite 2 mit „102 Bereiche nicht untersucht“ (Batu, Testlauf)
kritisch. Die LSA wirkt dadurch dünn, obwohl sie eine gezielte Stichprobe ist.

## Befund (Prod, nur lesend, 20.10.)

| Sitzung | Modus | Thema | Themenraum | direkt geprüft | direkt im Raum | Urteile im Raum (direkt + abgeleitet) | direkt außerhalb |
|---|---|---|---|---|---|---|---|
| 6220b7e8 (Batu, Testlauf) | abgestuft | reelle_zahlen | 14 | 12 | 5 | 14 | 7 |
| 09cf8baa | – | reelle_zahlen | 14 | 6 | 6 | 11 | 0 |
| 143215f5 | – | terme_gleichungen | 11 | 12 | 3 | 11 | 9 |
| 6d868c5f (Ilkay) | fest | terme_gleichungen | 11 | 27 | 1 | 11 | 26 |
| c84ba103, 342625f9, e7b63e2d | – | ohne Thema | – | 21 / 12 / 1 | – | – | – |

- Der Katalog-Nenner (alle Skills bis zur Klasse, 73–130) hat mit dem Thema nichts zu tun.
- Ilkays LSA war noch nicht abgestuft. Batu (Testlauf) ist die erste abgestufte LSA mit Thema: Für alle
  14 Bereiche des Themas gibt es ein Urteil, 5 direkt geprüft, 9 aus dem Voraussetzungsgraphen abgeleitet.
- Als Nenner taugt der Themenraum trotzdem nicht: „9 im Thema offen“ wäre falsch, und ältere
  Sitzungen haben kein Thema.

Entscheidungen der Gründer (20.10.):
1. Der Bericht zeigt nur, was direkt geprüft wurde, ohne Quote und ohne „nicht untersucht“. Das Thema
   steht als Ausgangspunkt im Text.
2. Zusatz für abgestufte LSAs mit Thema: Seite 1 nennt, wie viele Bereiche zum Thema gehören, wie viele
   davon direkt geprüft wurden und wie viele sich daraus ergeben. Abgeleitete Urteile werden dafür nur
   gezählt, nie als sicher/Übungsbedarf gezeigt. Das ändert die frühere Regel „mitbelegte Urteile gehören
   nicht ins Elterngespräch“ genau an dieser einen Stelle.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-6: Der Eltern-Bericht R7 zeigt nur noch, was die LSA direkt geprüft hat — kein Nenner aus dem Katalog, keine Zahl „nicht untersucht“, keine Schraffur. Dazu nennt Seite 1 bei abgestuften LSAs mit Thema, wie das Thema abgedeckt ist. Voraussetzung: R7-1 bis R7-5 gemergt (#273, #277, #278, #279, #283; sonst STOPP).

## Warum
Seite 2 zeigt heute z. B. „13 von 115 Bereichen“ und „102 nicht untersucht“. Der Nenner ist der ganze Katalog bis zur Klasse, unabhängig vom Thema der Sitzung. Für Eltern liest sich das, als hätte die Analyse kaum etwas angesehen. Die LSA ist aber eine gezielte Stichprobe. Bei der abgestuften LSA (lsa_sessions.modus = 'adaptiv') mit Thema gibt es sogar für jeden Bereich des Themenraums (result_summary.themenraum: einstieg + darunter) ein Urteil: einen Teil direkt geprüft, den Rest aus dem Voraussetzungsgraphen abgeleitet (lsa_skill_urteil.belegt_direkt = false). Halte diesen Befund in docs/report/r7/Bauauftrag-R7-6.md fest: 6220b7e8 (Batu, Testlauf, abgestuft) reelle_zahlen Raum 14, direkt 12, direkt im Raum 5, Urteile im Raum 14, direkt außerhalb 7; 09cf8baa reelle_zahlen 14/6/6/11/0; 143215f5 terme_gleichungen 11/12/3/11/9; 6d868c5f (Ilkay, nicht abgestuft) terme_gleichungen 11/27/1/11/26; c84ba103, 342625f9, e7b63e2d ohne Thema, direkt 21/12/1.

## Entscheidungen der Gründer (nicht neu verhandeln)
1. Sicher/Übungsbedarf, Profil, Pyramide, Schwerpunkte und alle Zahlen außer dem Thema-Satz (Entscheidung 7) rechnen weiter nur mit belegt_direkt. zaehle() bleibt unverändert (liefert katalog und offen weiter, sie werden nur nicht mehr angezeigt). Der EmptyState ohne Katalog bleibt.
2. Seite 1:
   - s1.blick.zeile = „{{untersucht}} Bereiche geprüft  ·  {{sicher}} sicher  ·  {{uebung}} Übungsbedarf“
   - s1.geprueft.text mit Thema = „Ausgehend vom Thema {{thema}} hat das System je nach Antwort die nächste Aufgabe gewählt. So wurden {{untersucht}} Bereiche gezielt geprüft.“; ohne Thema s1.geprueft.textOhneThema = „Je nach Antwort hat das System die nächste Aufgabe gewählt. So wurden {{untersucht}} Bereiche gezielt geprüft.“ Thema = Suchweg.themaLabel (dieselbe Quelle wie im R6-Abschnitt „Wie wir gesucht haben“); fehlt es, die Fassung ohne Thema.
   - s1.geprueft.hinweis (ein Schlüssel, ohne Plural, immer sichtbar, außer im Fall von Entscheidung 7) = „Dieser Bericht sagt nur etwas über die geprüften Bereiche. Weitere Bereiche lernen wir in den ersten Sitzungen kennen.“ Die Schlüssel hinweis_one/hinweis_other entfallen.
3. Seite 2:
   - s2.intro = „Geprüft: {{untersucht}} Bereiche. Davon {{sicher}} sicher, {{uebung}} mit Übungsbedarf.“ s2.introOffen entfällt.
   - Drei Zahlen: sicher | Übungsbedarf | geprüft (s2.zahl.geprueft = „Bereiche geprüft“, Farbbalken in --color-eb-navy). s2.zahl.offen entfällt.
   - Profil: nur Felder mit mindestens einem geprüften Bereich, Reihenfolge der Felder wie bisher. Je geprüftem Bereich ein Segment, erst sicher, dann Übungsbedarf; keine Segmente für nicht Geprüftes, keine Schraffur. Segmente linksbündig mit fester Breite: Breite = min(18 pt, (226 − (n − 1) · 4) / n), Lücke 4 pt, Radius wie bisher min(3,5 pt, Breite / 3). So sieht ein Feld mit einem geprüften Bereich nicht „voll“ aus.
   - Rechts s2.profil.geprueft = „{{count}} geprüft“, darunter wie bisher nur die von null verschiedenen Teile. Vorlesetext s2.profil.aria = „{{feld}}: {{untersucht}} geprüft, davon {{sicher}} sicher und {{uebung}} mit Übungsbedarf.“; s2.profil.untersucht, s2.profil.ariaKeiner und s2.profil.legende.offen entfallen. Legende nur Sicher / Übungsbedarf.
   - Zeilenabstände wie bisher nach Zahl der angezeigten Zeilen (40,8 pt bis sechs, 33,4 ab sieben, 30 ab neun).
   - s2.fussnote = „Jedes Segment steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts.“
   - „Was die Grafik zeigt“ bleibt (rechnet nur mit Geprüftem).
4. Das Schraffur-Pattern im Bogen bleibt definiert, wird aber nicht mehr benutzt.
5. Seiten 3, 4 und 5 bleiben unverändert. Die Wörter „untersucht“ in s2.titel, s3.* und s4.titelKeiner bleiben.
6. Daten für den Thema-Satz (Lesepfad, nur lesen, kein DDL):
   - ReportErzaehlung (src/types/report.ts) bekommt zwei Pflichtfelder: modus: 'fest' | 'adaptiv' | null (aus lsa_sessions.modus, in loadThema mitlesen) und abgeleitet: string[] (Skill-Schlüssel aus lsa_skill_urteil mit belegt_direkt = false und zustand in traegt, traegt_teilweise, traegt_nicht; nur Schlüssel, kein Zustand). Alle Stellen, die ReportErzaehlung bauen (lsaReportErzaehlung.ts beide Rückgaben, fixtures/basis.ts, Tests), setzen beide Felder ausdrücklich.
   - Den Kommentar „NUR belegt_direkt …“ an loadUrteile ergänzen: kompetenzen bleiben direkt; abgeleitet wird nur für den Thema-Satz gezählt (Gründer-Entscheidung 20.10.2026).
   - Reine Funktion src/lib/report/elternbericht/themaAbdeckung.ts mit Test: themaAbdeckung({ modus, raum, themaLabel, direkt: Schlüssel aus kompetenzen, abgeleitet }) → { thema, umfang, direkt, abgeleitet, offen } oder null. umfang = |einstieg ∪ darunter|; direkt = direkt geprüfte Schlüssel im Raum; abgeleitet = abgeleitete Schlüssel im Raum, die nicht direkt sind; offen = umfang − direkt − abgeleitet. null, wenn modus ≠ 'adaptiv', kein Raum, umfang = 0, kein themaLabel oder direkt = 0.
7. Thema-Satz auf Seite 1, im Kasten „So haben wir geprüft“ direkt nach s1.geprueft.text, nur wenn themaAbdeckung nicht null ist. Aus Teilsätzen zusammengesetzt, je Zahl mit Plural (i18next count):
   - s1.thema.umfang: „Zum Thema {{thema}} gehört ein Bereich.“ / „Zum Thema {{thema}} gehören {{count}} Bereiche.“
   - s1.thema.direkt: „Einen davon haben wir direkt geprüft“ / „{{count}} davon haben wir direkt geprüft“; ist direkt = umfang: s1.thema.alleDirekt „Alle davon haben wir direkt geprüft.“ und kein weiterer Teilsatz.
   - abgeleitet > 0 und offen = 0: s1.thema.abgeleitetRest „, der übrige ergibt sich aus diesen Aufgaben.“ / „, die übrigen {{count}} ergeben sich aus diesen Aufgaben.“
   - abgeleitet > 0 und offen > 0: s1.thema.abgeleitetTeil „, ein weiterer ergibt sich aus diesen Aufgaben.“ / „, {{count}} weitere ergeben sich aus diesen Aufgaben.“ und danach s1.thema.offen „Einen Bereich klären wir in den ersten Sitzungen.“ / „Die übrigen {{count}} klären wir in den ersten Sitzungen.“
   - abgeleitet = 0 und offen > 0: Punkt nach s1.thema.direkt, dann s1.thema.offen.
   - Statt s1.geprueft.hinweis steht dann s1.geprueft.hinweisThema = „Zahlen und Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche.“
   Beispiel Batu: „Zum Thema Reelle Zahlen gehören 14 Bereiche. 5 davon haben wir direkt geprüft, die übrigen 9 ergeben sich aus diesen Aufgaben.“
8. Alle neuen Texte sind Entwürfe für Lena: in docs/report/r7/texte-r7-6.md alt → neu auflisten, mit den zusammengesetzten Sätzen der Testfälle.

## Neue Testfälle (FAELLE, synthetisch)
- abgestuft: wie Batu — modus adaptiv, Thema „Reelle Zahlen“, Raum 14, direkt 5 im Raum und 7 außerhalb, 9 abgeleitet im Raum (offen 0).
- abgestuftMitOffen: modus adaptiv, Raum 14, direkt 6 im Raum, 5 abgeleitet, 3 offen.
- Alle bestehenden Fälle setzen modus ausdrücklich (ilkay: 'fest'), kein Thema-Satz.

## Umfang
src/components/edvance/elternbericht/Seite1.tsx, Seite2.tsx und ihre Teile (z. B. Profil.tsx, Segmentrechnung als reine Funktion mit Test), src/styles/elternbericht/seite1.css und seite2.css, src/i18n/locales/de/elternbericht.json (nur die genannten Schlüssel unter s1.* und s2.*; entfallende Schlüssel löschen), src/lib/supabase/lsaReportErzaehlung.ts (nur modus und abgeleitet laden, Kommentar), src/types/report.ts (nur die zwei Felder), src/lib/report/elternbericht/themaAbdeckung.ts (neu, mit Test), src/lib/report/elternbericht/fixtures/**, Tests dazu, docs/report/r7/Bauauftrag-R7-6.md, docs/report/r7/texte-r7-6.md, docs/report/r7/offene-punkte-r7-6.md, Retro. Nicht anfassen: übrige Dateien in src/lib/** (zaehlung.ts, bericht.ts, einordnung.ts, schwerpunkte.ts …), Bogen.tsx, Seite.tsx, seitenProps.ts, rahmen.css, Seite3/4/5, R6-Komponenten, e2e-druck/**, playwright.elternbericht.config.ts, supabase/**, ROADMAP. inv4-*.test.ts nur ändern, wenn ein Test einen der entfallenden Schlüssel wörtlich erwartet; keine Regel lockern, Änderung im PR begründen.

## Tests
Vitest: themaAbdeckung für alle Fälle aus Entscheidung 6 (fest, kein Raum, umfang 0, direkt 0, offen 0, offen > 0, abgeleitet 0, alle direkt) und mit einem abgeleiteten Schlüssel außerhalb des Raums (zählt nicht); Seite 1 mit und ohne Thema, mit Thema-Satz (abgestuft, abgestuftMitOffen) und ohne (ilkay); keine Ausgabe von katalog/offen mehr auf Seite 1 und 2 (Text enthält weder „von {{katalog}}“ noch „nicht untersucht“); abgeleitete Schlüssel erscheinen nirgends als Eintrag, Segment oder in einer Liste; Profil nur mit geprüften Feldern (ilkay, allesSicher, weitereBereiche); Segmentbreite für n = 1, 5, 12, 40; Vorlesetexte; Legende ohne „Nicht untersucht“. R6-Tests unverändert grün. Druck-Tests für ALLE Fälle grün: EB_PORT=5187 EB_AUSGABE=docs/report/r7/abnahme/r7-6 npx playwright test -c playwright.elternbericht.config.ts. inv4-elternbericht.test.ts grün. Typecheck, Lint, Vitest grün.
Mit dbread (nur lesend) gegenrechnen: themaAbdeckung für 6220b7e8 ergibt 14/5/9/0; im PR nennen.

## Leitplanken
- Worktree ../Edvancev1-r7f auf feat/rasit-report-r7-ohne-nenner von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, Prod nur lesend über dbread.
- Designregeln CLAUDE.md §11 mit der R7-Ausnahme; keine Hex-Werte, kein style={{…}} (INV-4.11), Dateien ≤ 400 Zeilen.
- Läuft Seite 1 mit dem Thema-Satz über: STOPP, Fall und Messwerte melden, nichts kürzen.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler: im PR vermerken, nichts ändern.
- Zweitprüfung durch eine frische Instanz, Schwerpunkt: Wirkt Seite 2 für Eltern wie eine gezielte Prüfung, nicht wie eine Lücke? Stimmen alle Zahlen zwischen Seite 1 und 2 überein? Taucht ein abgeleitetes Urteil irgendwo anders auf als im Thema-Satz? STOPP nach dem PR.

## Melden
PR-Link, PDFs aus docs/report/r7/abnahme/r7-6/ (ilkay, abgestuft, abgestuftMitOffen, weitereBereiche), Seite 1 und 2 von abgestuft als Bildschirmfoto, Gegenrechnung für 6220b7e8, Texte alt → neu (texte-r7-6.md), offene Punkte (docs/report/r7/offene-punkte-r7-6.md).
```
