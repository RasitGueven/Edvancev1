# Retro: LSA-Taschenrechner (30.10.2026)

## Gebaut

- **Edvancev1:** Spalte `tasks.taschenrechner`, Freigabe für fünf Näherungsaufgaben, `pruef_einstellungen.hilfsmittel`
  = „Stift und Zettel“, Feld in `lsa_question_payload`, Schalter in der Prüfansicht (Lena und Admin) über
  `pruef_taschenrechner_setzen`. Liste der 42 Aufgaben: `docs/lsa/methoden-aufgaben-rechner.md`.
- **edvance-app:** Symbol oben rechts, gedimmt ohne Freigabe, mit Freigabe dreimal goldener Puls, Panel mit eigenem
  Parser (`src/lib/rechner`), `calculator_opened` in der Abgabe.

## Entscheidungen

- **Spaltenname `taschenrechner`**, wie die Nachbarspalte `bruch`.
- **Eigene RPC statt `pruef_speichern`:** `pruef_sperren` lehnt `ready` für alle ab. Die Spalte gehört nicht zur
  Antwort und wirkt sofort, ohne Entwurf. Lena schaltet wie bei jedem Speichern nur vor der Freigabe, Admin auch danach
  (Regel aus `tasks_pruefer_guard`).
- **`lsa_submit` bleibt unverändert:** Der Server speichert das Antwortobjekt wortwörtlich, bei Mehrteilern das Objekt
  je Teil. Die App legt `calculator_opened` deshalb in jedes Teilobjekt. Nur bei Aufgaben mit Rechner: Fehlt das Feld,
  gab es keinen.
- **Panel verschiebbar:** Die Fläche füllt das Fenster, ein Panel ohne Überlappung geht nicht. Es startet unten rechts
  neben dem Ziffernblock, der Griff zieht es, begrenzt auf das Fenster über dem Fuß.
- **`spurRaum` immer an:** Das obere Band trägt das Symbol. Die Fläche springt dadurch nicht mehr.

## Offene Punkte

- Der Schalter schreibt keine Spur: nur `pruef_version` steigt, kein Eintrag in `task_admin_protokoll` (dessen
  `aktion`-CHECK kennt ihn nicht).
- Lena kann das Feld bei `ready` nicht ändern. Bei den fünf Aufgaben entscheidet also ein Admin.
- `{dont_know:true}` über einen ganzen Mehrteiler speichert `calculator_opened` nicht. Keine der fünf Aufgaben ist ein
  Mehrteiler.
- Der Rechner steckt nur im Kiosk-Weg (`platz-task`), nicht im Hub-Weg (`lsa/task.tsx`) und nicht im Tutorial.
- Der Rechner hat kein sin/cos. Die vier Trigonometrie-Entwürfe aus Schritt 1 wären damit nicht lösbar.
- Lenas Liste B (Rechenaufgaben) ist mit „Stift und Zettel“ erledigt, Liste A auch, außer den fünf Ausnahmen.
