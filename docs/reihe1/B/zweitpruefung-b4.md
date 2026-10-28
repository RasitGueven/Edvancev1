# Zweitprüfung B4 · Migration 20261027134813_studio_render, api/studio/render.ts, tools/studio-render.ts

Frischer Subagent ohne Kontext. Frage: „Was ist falsch, was fehlt, was bricht?“ Command-Injection: keine (UUID, Welt-Liste, Auftrag aus der DB).

| # | Befund | Schwere | Umgang |
|---|---|---|---|
| 1 | JWT läuft in der Sandbox ab, Auftrag hängt | kritisch | Route verlangt ≥ 50 Min Restlaufzeit (Oberfläche frischt vorher auf), Aufträge > 60 Min gelten als abgebrochen |
| 2 | Kein Weg aus wartet/laeuft bei Abbruch | kritisch | curl meldet Fehler bei Installation/Abbruch; `studio_render_anlegen` räumt alte Aufträge; `studio_render_stand` zeigt sie als Fehler |
| 3 | Inhalt nicht an den Fingerabdruck gebunden | mittel | `studio_render_melden` prüft bei laeuft und fertig den aktuellen Fingerabdruck → sonst Fehler `inhalt_geaendert` |
| 4 | Renderer-Fassung als Konstante | mittel | Stolperdraht-Test `src/studio/remotion/fassung.test.ts` (Hash der Quellen) |
| 5 | „exists“ geschluckt, Pfade ohne Auftrag | mittel | Pfad mit Auftrags-ID, Upload-Fehler brechen ab |
| 6 | Melden vertraut dem Aufrufer | mittel | nur Anleger/Admin, nur wartet→laeuft→fertig, Dateien müssen in storage.objects liegen, Tests |
| 7 | Secrets in der ganzen Kette | mittel | `npm ci` ohne Token (`env -u`), Remote-URL ohne Token; Netz bleibt offen (npm, Chrome, Supabase nötig) |
| 8 | Parallele Aufträge | mittel | partieller Unique-Index, 23505 → 409, Test |
| 9 | Sandbox wird nicht gestoppt | gering | `stop()` im Fehlerfall, Timeout 40 Min; nach Erfolg endet sie mit dem Timeout (offen) |
| 10 | `--auftrag` ohne `--welt` | gering | abgelehnt, Welt aus der Auftragszeile geprüft |
| 11 | Ergebnisse ungeprüft | gering | Fehler von melden/select brechen ab, Status nach melden geprüft |
| 12 | Fehlercodes | gering | dauer_ms als Zahl geprüft (22023), Route unterscheidet 400/403/409/502 |
