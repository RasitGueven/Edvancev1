# Retro F1: Coach-Sicht aus dem Trockenlauf, Szenario Batu (08./09.10.2026)

## Gebaut
- **Coach-Live-Sicht (A1–A6):**
  - Thema wählen ist immer möglich, auch mitten in der Session; die Schublade zeigt, warum ein Kind wartet.
  - Eingaben sind lesbar; falsche Versuche stehen nur zur aktuellen Aufgabe.
  - Kopf und Kachel zeigen die Phase des Kindes; dazu zwei neue Felder in `coach_raum_live`.
  - Die Abfrage überlappt nicht mehr.
  - „heute n von m“ wird je Skill gezählt; „heute sicher“ steht dabei (neues Feld in `coach_kind_detail`).
- **E2:** Testkonten bekommen in der adaptiven LSA den Testlauf-Pool, auch ohne Testlauf.
- **E3:** neue Warm-up-Reihenfolge (F17).
- **B4:** Platzhalter-Erklärsequenz zu `gleichung_quadr_faktor`.
- **Szenario Batu:**
  - Muster in `docs/szenario/batu.md`/`.json`;
  - Werkzeuge `tools/szenario-lsa.mjs` und `szenario-zuruecksetzen.mjs`;
  - Ablauf in `batu-session.md`.

## Entscheidungen
- **A6:** Die Engine war richtig (F7), falsch war die Anzeige.
- **E1–E3:** Rasit, 08.10.; die Kandidatenmenge des Warm-ups bleibt.

## Gelernt
- Vor dem Auftrag „echte LSA statt Testlauf“ prüfen, ob der Pool ohne Testlauf überhaupt Items hat. Für alle K9-Inhalte gilt das nicht.
- Mitbelegung und Alphabet bestimmen nach einer LSA das Warm-up und das Einmischen. Gleichstände brauchen eine Regel,
  sonst gewinnt `dezimal_*`.

## Offen
- `docs/session/offene-punkte-f1.md`: Kanten zu den quadratischen Gleichungen an die Inhaltspflege, Mischen mit F17?,
  Zurücksetzen und Protokoll.
- Einspielen nach „F1 einspielen“, Szenario anlegen nach „Szenario anlegen“.
- ROADMAP erst nach dem Einspielen.
