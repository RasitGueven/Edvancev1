# Zweitprüfung B6 · Migration 20261027141453_studio_ausspielung

Frischer Subagent ohne Kontext (Migration, Anforderung §9/§14, Konzept §9, DATENVERTRAG §8). Bestätigt ohne Befund: Kernideen ohne Video verhalten sich wie vorher (nur `"video": null` neu), Runde 1 Hauptfrage, Signal vor Rücksprung, Welt-Rückfall mit Versionsabgleich, zuhause nur „angesehen“, Grants dicht.

| # | Befund | Schwere | Umgang |
|---|---|---|---|
| 1 | Video-Entscheidung aus dem Entwurf (`studio_bereich`) statt aus der Ausgabe | kritisch | Bereiche und Kernideen nur noch aus `studio_ausgabe.inhalt`; Test „Entwurf ändert die Fassung nicht“ |
| 2 | Bereich ohne Mini-Check → P0002 statt Karten | kritisch | Video-Kernidee nur mit auslieferbarem Check; sonst Kartenweg |
| 3 | Video-Checks ohne Freigabe-Filter (gemeldete Aufgaben) | mittel | `studio_video_aufgaben` filtert wie `erklaer_checks`; Abgabe prüft Zugehörigkeit; Test |
| 4 | Kernidee-Status ignoriert | mittel | entfällt: E1 kennt nur entwurf/geprueft/freigegeben, kein Zurückziehen |
| 5 | Video mitten in der Sequenz zurückgezogen → Kind hängt | mittel | Wiederaufnahme zeigt eine neue Runde, wenn die Kernidee weiter auslieferbar ist |
| 6 | Jeder Coach setzt jede Welt | mittel | nur der Coach mit dem Kind in einer Session (und Kind, Admin) |
| 7 | Prüfer lesen „angesehen“ und Welt der Kinder | mittel | nur das Kind selbst und Admin |
| 8 | `p_kind` NULL in `mediathek_angesehen` | gering | ausdrücklich abgelehnt |
| 9 | „offen“ und NULL | gering | `coalesce(zustand, 'gesperrt') <> 'gesperrt'` (Themenbaum §3: auch „sicher“ ist offen) |
| 10 | Eddie: Zugriff per Nebeneffekt, alle Skills, alte Fassung nach Edit | gering | bewusst: kompetenz_offen wirft 42501; freigegebene Fassung bleibt verlinkbar (Fall 8), nie ein Entwurf (Fall 10); dokumentiert |
| 11 | Freigegebene Dateien für alle Angemeldeten | gering | bewusst (Lerninhalt ohne Personenbezug), dokumentiert, Test |
| 12 | Rücksprung mit nur einer Fassung | gering | Importprüfung gibt Hinweis; Skripte V1–V8 bekommen Zwillinge (B8) |
| 13 | DATENVERTRAG unvollständig, *_url sind Pfade | gering | R1-B.2 ergänzt |
