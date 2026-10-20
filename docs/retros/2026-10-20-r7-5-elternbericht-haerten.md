# Retro 20.10.2026 – R7-5 · Eltern-Bericht härten (Grenzfälle im Druck)

## Gebaut
- Sieben neue Fälle in `FAELLE` (`fixtures/grenzfaelle.ts`): `mitFazit`, `fazitLang`, `langerName`,
  `zuLangerName`, `weitereBereiche`, `vieleAnliegen`, `keinSchwerpunktMitZiel`. Elterntexte wörtlich
  aus Prod (dbread, die drei längsten freigegebenen: 221/208/194 Zeichen). Sitzungs-IDs so gewählt,
  dass die Rückbezüge die längere Fassung ziehen. `NOTIZEN_LANG` mit siebenzeiligem Lernziel.
- Seite 4: `useStufe` statt `useDicht` — Stufe 1 verdichtet, 2 ohne Coach-Satz, 3 nur erster
  Elterntext (Entscheidung 2); `data-stufe` am `.eb-s4`.
- Lernziel ohne Schwerpunkt bündig links (`.eb-s4-lernziel-voll`, Entscheidung 3).
- Bogen: Rufname über 24 Zeichen → `name`/`wessen` null (Entscheidung 4).
- Tests: Stufen mit gemockter Höhe, Namensgrenze 24/25 im Bogen, Lernziel-Klasse, Fixture-Tests.

## Entscheidungen
- „Mehrere Anliegen, ein Rückbezug“ ist mit den Intake-Werten unmöglich (jeder Wert hat eine
  Zuordnung); die Fälle nutzen synthetische Anliegen außerhalb der Zuordnung.
- „Weitere Bereiche“ braucht einen synthetischen Skill; in Prod hat jeder Skill ein Themenfeld.
- Stufen eskalieren erst nach `document.fonts.ready` (Zweitprüfung): sonst blieb eine Stufe stehen,
  die nur die Ersatzschrift brauchte.

## Ergebnis
- Typecheck, Lint, Vitest (1588) grün; Druck-Tests 20/20 grün (Port 5186), PDFs in
  `docs/report/r7/abnahme/r7-5/`.
- **STOPP vor dem PR:** Die Zweitprüfung fand realistische Namen mit 24 Zeichen („Mohammed-Mustafa
  Wilhelm“), bei denen der Titel auf Seite 2 dreizeilig wird und der Inhalt 13,7 pt überläuft.
  Die Grenze aus Entscheidung 4 reicht damit nicht; Entscheidung liegt bei den Gründern.

## Offen
- Siehe `docs/report/r7/offene-punkte-r7-5.md` (Namensgrenze, Seite 5 mit 0,9 pt Rest, Fußnote ohne
  Schwerpunkt bei x 93, synthetische Anliegen/Skill).

## Gelernt
- Grenzen in Zeichen sind für Druck keine Garantie: Breite hängt an den Buchstaben. Gegenprobe mit
  breiten, realistischen Namen gehört in jede Namensgrenze.
