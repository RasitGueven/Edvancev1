# Retro 12.10.2026 — Session E3: Hinweise als Entwurf für das Szenario Batu, LSA ohne Hinweise

## Gebaut
- **Hinweise (KI-Entwurf):** 49 Session-Aufgaben der acht Skills aus dem Szenario Batu (`gleichung_quadr_faktor`,
  `…_wurzel`, `…_formel`, `…_anzahl`, `gleichung_einschrittig`, `…_zweischrittig`, `term_ausklammern`,
  `vorzeichen_add_sub`) je drei Stufen, 147 Hinweise, alle `entwurf`. Quelle `tools/hinweise-e3/<skill>.mjs`.
- **Nachrechnung ohne DB und LLM** (`tools/hinweise-e3-lib.mjs`): jede Zahl belegt (Aufgabe, exakte Term- und
  Gleichungsumformung über `prefill-rechnen.mjs`, Rechnung, Wurzel, ggT, begründeter Wert), nie ein Ergebnis oder eine
  MC-Option, Stufe 1 nur Zahlen aus der Aufgabe, Fehlbilder nur aus `known_errors`, kein Slug im Text, Rundung wie in
  der Aufgabe, „kleinere Lösung zuerst“ bei MULTI_PART. Gate `tests/hinweise-e3.test.ts` mit Negativkontrollen.
- **Zweitprüfung** je Skill-Gruppe durch frische Subagenten (nur lesend): 4 Muss-Befunde, alle behoben; Protokolle in
  `docs/prefill/hinweise-e3-zweitpruefung-*.md`.
- **Riegel** `20261013173601_lsa_ohne_hinweise`: `lsa_hint` liefert nie einen Hinweis (Entscheidung Rasit), Tests von
  T3, L5, E1, inv2, inv6 umgestellt. Konsensprüfung: freigeben mit Hinweisen.
- **Daten-Migration** `20261013175427_hinweise_e3_batu`: Hinweise nur bei `hints = []`, Kennzeichen
  `vorbefuellt.hints` der 24 quadr-Aufgaben „leer“ → „neu“. Beide eingespielt, per dbread kontrolliert.

## Entscheidungen
- Muster ok mit „kleinere Lösung zuerst“ in Stufe 3 und ohne Fehlbild-Slugs im Text (Rasit).
- Formeln als Unicode wie in den Lösungen, nicht `$…$` (keine Lösung in Prod nutzt `$`).
- Die LSA läuft ohne Hinweise, auch für Testkonten; Hinweise nur in der Session (Rasit). Der LSA-Player in edvance-app
  ruft `lsa_hint` ohnehin nicht auf.
- Fundament-Aufgaben stehen nur in Prod; die CI-Migration greift für sie ins Leere, der volle Abgleich läuft in der
  Wegwerf-DB über eine Fixture aus dem Snapshot.

## Gelernt
- `jsonb` sortiert Schlüssel um: Ein Textvergleich der Hinweise gegen die Quelle meldet 49 von 49 Abweichungen, ein
  Vergleich je Feld 0. Immer feldweise vergleichen.
- Die Fixture muss `where not exists` nutzen: CHECK-Constraints greifen vor `on conflict`.
- Eine Zweitprüfung je Skill-Gruppe parallel zum Schreiben der nächsten Gruppe hält den Durchlauf schnell.

## Offen
`docs/prefill/befunde-hinweise-e3.md` (Liste für Lena, offene Punkte, veraltete Beschreibungen von `lsa_hint`).
