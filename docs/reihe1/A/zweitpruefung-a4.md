# Zweitprüfung A4 (Migration 20261027142701_reihe1_a4_versionswechsel und erzeugte Datenmigration NP-2)

Frischer Subagent ohne Kontext (27.10.2026). Er hat fünf Instanzen von Hand nachgerechnet und alle 82 per Skript mit
exakten Brüchen geprüft: ohne Fehler. Kindersicht ohne Lösung, Schreibweise sauber, Fehlbild-Stufen richtig,
zweimal einspielen ändert nichts.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | `source_ref` ohne Inhaltsbezug: ein korrigierter Generator würde still verworfen | Suffix enthält einen Hash aus Text, Payload und Parametern; der Steckbrief trägt `generator_hash` (neuer Generator ⇒ neue Version) |
| 2 | Zweites Einspielen setzt `beanstandet`/`rueckfrage` zurück | Upsert lässt Lenas Status stehen; nur eine neue Version öffnet die Bauform (Trigger) |
| 3 | Trigger erkennt „gleicher Wert“ nicht als „neu gesetzt“ | Schalter `edvance.bauform_export` (transaktionslokal): mit Schalter gelten die Werte des Exports, ohne wird zurückgesetzt; pgTAP `reihe1_a4_motor` |
| 4 | NP-2-Rückmeldung nannte die fehlende Lösung | „Ein Faktor ist x selbst. Wann wird dieser Faktor null?“ |
| 5 | NP-2-Hinweis 3 machte die Lösung bei a = 1 ablesbar | „Klammere x aus: x · (…) = 0. Was bleibt in der Klammer?“ |
| 6 | Status hängt nur an `verdacht` | `verdacht` entsteht aus Prüfmaschine (> 30 % rot) und Blindlöser (nicht bestanden oder fehlt); beides fließt schon ein |
| 7 | Äquivalente Gleichungen in Stufe 4 (4x² + 10x und 2x² + 5x) | Stufe 4 verlangt ggT(a, b) = 1 |
| 8 | Stufe 1/2 nur 4–5 Instanzen je Rolle | Zahlenraum (p bis 20) begrenzt; ein Kind sieht dieselbe Aufgabe nie in zwei Rollen. Im Bericht vermerkt |
| 9 | ASCII-Minus in der Lösung | `format_bruch` normalisiert „−“ und „-“ (pgTAP `reihe1_a3_formate`) |
| 10 | Kopfkommentar mit falschem Pfad | korrigiert |
| 11 | Neue Instanzen einer freigegebenen Bauform ohne neue Version blieben draft | nach Befund 1 entstehen neue Instanzen nur mit neuem Generator ⇒ neue Version ⇒ neue Prüfung und Freigabe |
