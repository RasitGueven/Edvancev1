# Retro 16.10.2026 · Binomische Formeln (A) und Session-Musterlösungen (B)

## Gebaut
- **A (PR #258, `20261016130100_binom_fehlbilder_offen`):** 37 MC-Ablenker in den vier `term_binom_*`-Knoten bekommen
  ein Fehlbild (`acceptance.known_errors` mit Options-id als Schlüssel). Dazu drei neue Slugs und je eine offene
  NUMERIC-Aufgabe für `term_binom_quadrat` und `term_binom_gemischt`.
- **B (`20261016130200_session_e3_musterloesungen`):** Musterlösungen für `gleichung_einschrittig`/`_zweischrittig`
  (Stil wie `gleichung_quadr_*`, endet bei `x = …`, keine Probe). `term_ausklammern` bekommt Musterlösungen und eine
  acceptance mit einem Fehlbild je Ablenker. Dazu drei neue Slugs.

## Entscheidungen
- Rechen-Check und Migration kommen aus demselben Skript (`tools/binom-rechencheck.py`,
  `tools/session-e3-rechencheck.py`). Jeder Ablenker trägt den falschen Rechenweg, der ihn erzeugt, und sympy prüft
  diesen Weg. Eine Zuordnung, die nur ungefähr passt, ist im Skript als `UNSCHARF` markiert.
- Die Migrationen schreiben nur, wenn die Optionen noch den nachgerechneten Text tragen. Sie füllen nur leere Felder.
- Für die Wegwerf-DB braucht die Fixture zusätzlich `skill_clusters`, sonst greift bei neuen Aufgaben das Gate
  „Cluster fehlt“. B braucht außerdem `process_competencies`: Der Trigger `task_solutions_pruef_version`
  aktualisiert `tasks` und prüft dabei den FK. Der Seed bringt keinen Prüfer mehr mit, deshalb legt das Skript einen
  Admin an.

## Offen
- Rasit bestätigt die sechs neuen Slugs (Klartext) und die drei unscharfen Zuordnungen in A.
- Einspielen: zuerst A, dann B.
