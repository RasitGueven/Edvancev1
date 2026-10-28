# Zweitprüfung B2 · Migration 20261027132413_studio_stimme und Route api/studio/stimme.ts

Frischer Subagent ohne Kontext (Migration, Route, Anforderung §5/§12, Konzept §9). Frage: „Was ist falsch, was fehlt, was bricht?“

| # | Befund | Schwere | Umgang |
|---|---|---|---|
| 1 | Route vertont (kostenpflichtig), bevor die Autor-Rolle geprüft ist | kritisch | behoben: `studio_hat_rolle('autor')` vor jeder Vertonung, sonst 403 |
| 2 | `upsert: true` ohne UPDATE-Policy → Satz wird immer wieder bezahlt | kritisch | behoben: Upload ohne upsert, „schon vorhanden“ zählt als Erfolg; Oberfläche bricht bei `erzeugt = 0` ab |
| 3 | `studio_wert`/`studio_sprechfassung` für jeden Angemeldeten aufrufbar | mittel | behoben: `revoke … from authenticated`, Test |
| 4 | Einstellungen ungeprüft (null-Wörterbuch macht jeden Satz null) | mittel | behoben: Typprüfung je Schlüssel, ungültige Einträge übersprungen, Tests |
| 5 | Wörterbuch: Sonderzeichen-Wörter, Groß/Klein, Rückverweise im Ersatz | mittel | behoben: eigene Wortgrenzen, `gi`, Ersatz maskiert, Test |
| 6 | Gesperrte Welten werden vertont | mittel | behoben, Test |
| 7 | `studio_sequenz.stimme_id` ignoriert | mittel | behoben: Stimme = Parameter → Sequenz → Einstellung → platzhalter; Bedarf liefert Stimme und Modell |
| 8 | Kein `maxDuration` | mittel | behoben: `vercel.json` functions 300 s, 8 Sätze je Aufruf |
| 9 | Fingerabdruck ohne Ausgabeformat/Sprache | gering | behoben: `studio_audio_fassung()` im Fingerabdruck |
| 10 | Gleicher Satz, anderer Kontext je Welt | gering | so gewollt (§5), im Kommentar dokumentiert |
| 11 | Beats ohne Skelett-Text fallen heraus | gering | entfällt: B1 verlangt den Skelett-Text |
| 12 | Speicherpfad frei | gering | behoben: nur `audio/%` und `render/%`; Bucket-Grenzen (200 MB, MIME) wo Storage sie kennt |
| 13 | Nicht-UUID gibt 403 | gering | behoben: 400 |
| 14 | `storage` in der CI | gering | geprüft: Grundlage hat `storage.buckets/objects`; Grenzen nur bedingt |
