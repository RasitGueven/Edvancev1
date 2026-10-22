# LSA-Testkinder (LSA-T)

Fünf erfundene Kinder (Klasse 7, 8, 9) spielen je eine vollständige LSA durch die echte Auswahl und
Wertung, mit festem Antwortprofil von „sehr gut“ bis „sehr, sehr schwach“. Danach liegt für jedes Kind
ein Report unter `/admin/report/<sitzung>?fassung=r7`. Bauauftrag: `docs/lsa/Bauauftrag-LSA-T.md`.

| Kind | Klasse | Schule | Thema | Profil |
| --- | --- | --- | --- | --- |
| Lina Berger | 9 Gymnasium | FWG (Schulplan) | Quadratische Funktionen | alles sicher, ein Ausrutscher (Fläche Dreieck) |
| Emre Kaya | 9 Gymnasium | FWG (Schulplan) | Reelle Zahlen und Wurzeln | sicher bis auf Wurzelgesetze und teilweises Wurzelziehen, Fehlbild „Wurzel einer Summe“ |
| Sophie Wagner | 8 Realschule | ohne Plan | Lineare Funktionen | Klasse 7/8 falsch (Steigung vertauscht), Koordinaten unsicher, bis Klasse 6 sicher |
| Jonas Richter | 8 Gesamtschule | ohne Plan | Terme und Gleichungen | Klasse 7–10 „Weiß ich nicht“, bis Klasse 6 falsch (Vorzeichen) |
| Nele Schmitz | 7 Gymnasium | ohne Plan | Prozent- und Zinsrechnung | Prozentwert sicher, Grundwert und Prozentsatz falsch, Brüche teils |

Die Profile stehen als Daten oben im Skript (`grund` je Klassenstufe, `ausnahmen` je Skill,
bevorzugtes Fehlbild, Antwortdauer).

## Was das Skript tut

`erzeugen.sql` ist reines SQL ohne DDL und läuft in einer Transaktion.

1. Legt je Kind einen Test-Lead mit Erstgespräch an (Phantasiedaten, Eltern-E-Mail
   `<vorname>@example.invalid`, keine Verträge) und den provisorischen Schüler mit fester UUID
   (`a5a7c41d-1ead-…` Leads, `a5a7c41d-5c00-…` Schüler). Ein zweiter Lauf aktualisiert nur die Angaben.
2. Setzt das aktuelle Thema (`lead_thema_setzen`), die behandelten Themen und das Anliegen
   (`lead_assessment_upsert`).
3. Gibt die LSA frei (`lead_lsa_freigeben`), beantwortet jede Aufgabe über `lsa_submit` und schließt mit
   `lsa_finish` ab — als bestehender Admin über `request.jwt.claims`, wie die App. Wertung, Urteile,
   Fehlbilder und `result_summary` entstehen ausschließlich in diesen Funktionen.
4. Simuliert die Uhr: `started_at` der neuen Sitzung wird vor der ersten Antwort um 20 Minuten
   zurückgesetzt, jede Antwort trägt `p_jetzt` = Beginn + bisherige Antwortdauern. Die Auswahl rechnet
   nur mit diesem Abstand, also genau wie bei einem Kind, das so lange braucht.
5. Gibt je Kind eine NOTICE (Profil, Abweichungen vom Profil) und am Ende die Tabelle aus:
   Kind · Klasse · Thema · Sitzung · Status · Aufgaben gesamt · davon ready · sicher · Übungsbedarf ·
   ohne Ansatz · Fehlbilder · Report-Pfad. Gezählt werden direkt geprüfte Bereiche.

Gezogen wird aus dem Testkonto-Pool (`students.ist_test` → Entwürfe ohne Prüfausschluss), weil noch wenig
auf „ready“ steht; „davon ready“ zeigt, wie viele der gezogenen Aufgaben schon freigegeben sind.

## Starten

```bash
dbcheck && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/lsa-testkinder/erzeugen.sql
```

Ohne `-1` läuft jeder Block für sich; dann bleibt bei einem Fehler ein halber Stand stehen.

## Erneut laufen lassen

Jeder Lauf legt je Kind eine **neue** Sitzung an und löscht nichts (Rohdaten bleiben append-only). Die
Tabelle nennt die Sitzung dieses Laufs.

- **Nach LSA-V (neue Auswahl):** einfach erneut starten. Die neuen Sitzungen zeigen die neue Auswahl an
  denselben fünf Kindern; die alten Sitzungen bleiben zum Vergleich stehen.
- **Nach R7-11 (neuer Report):** kein neuer Lauf nötig. Der Report rechnet beim Öffnen neu — dieselben
  Report-Pfade erneut öffnen.
- **Neue Aufgaben im Pool:** erneut starten; „davon ready“ steigt mit jeder Freigabe.

## Test

`supabase/tests/lsa_testkinder.test.sql` lässt das Skript im CI-Neuaufbau zweimal laufen (mit einer
Aufgaben-Fixture je Skill, der Neuaufbau hat keine LSA-Aufgaben) und prüft je Kind Abschluss, Profil,
Uhr, Fehlbild und den zweiten Lauf.
