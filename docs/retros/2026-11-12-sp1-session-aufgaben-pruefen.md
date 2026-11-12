# Retro 12.11.2026 · SP-1 Session-Aufgaben prüfen

**Gebaut:** Kommentar-Prüfung für Bauformen (S1), Klartext für 47 Bauformen (S2), Liste und Prüfansicht wie im Dummy
(S3, S4), Rückfragen-Werkzeug und Abnahme (S5). PRs #393–#397 und S5; zwei Migrationen eingespielt.

**Entscheidungen:** `bauform_pruefung_senden` statt Überladung von `bauform_pruefen` (mehrdeutige Aufrufe);
`bauform_pruefen` nur noch über den neuen Aufruf; automatischer Übergang per Trigger, nicht per Aufruf im Export;
Klartext und Zeit außerhalb des Steckbriefs (kein Versionswechsel); Entwurf im Browser je Bauform und Version;
Graph-Optionen in der Vorschau auf dunklem Grund wie im Player.

**Gelernt:** Eine Schutzregel im Versionswechsel-Trigger blockierte den eigenen Abschluss im Export (transaktionslokale
Markierung); Trigger-Logik darf nicht von Rechten des Aufrufers abhängen (interne Funktion ohne Rechteprüfung).
`gh pr checks` kennt hier kein `--json`. Die Hülle scrollt im Inhaltsbereich: Fotos per `scrollIntoView`, nicht `fullPage`.

**Offen:** siehe `docs/freigabe/sp1/bericht.md` (O1 Zeit in der Planung, O4 strittige Klartexte).
