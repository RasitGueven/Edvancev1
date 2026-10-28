# Live-Checkliste Bauauftrag A (nach dem Merge)

Alle schreibenden Abnahmefälle liefen in der Wegwerf-DB (pgTAP, wie die CI). Was nur in Produktion geht, steht hier.
Reihenfolge von oben nach unten.

## Vor der ersten Freigabe

1. **Figuren hochladen** (Rasit): `python3 scripts/figures/upload_figures.py` (erst `--dry-run`). Betroffen: KO-1 (64),
   SCH-2 (84) mit `task_figures`, PAR-2, PAR-3, NS-4 mit `task_figur_optionen`. Ohne `svg_hash` sind diese Instanzen
   nicht ziehbar (`aufgabe_ziehbar`). Prüfung:
   `select count(*) from task_figures f join tasks t on t.id = f.task_id where t.bauform_id is not null and f.svg_hash is null;` → 0
   und dasselbe für `task_figur_optionen`.
2. **Types der App neu erzeugen** (Windows-CLI, aus `~/edvance-app-A`):
   `cmd.exe /c "supabase gen types typescript --project-id ztcppihxqcphlqaguhma --schema public" | tr -d '\r' > src/types/database.ts && npm run typecheck`.

## Lena (Prüfumfang siehe Bericht)

3. Lena-Board → „Bauformen prüfen“: 47 Bauformen, je Bauform Steckbrief und sechs Beispiele, Entscheidung mit 1/2/3.
   Prüfabfrage: `select status, count(*) from bauformen group by 1;`
4. Reiter „Prüffragen“: 15 Coach-Prüffragen einzeln (passt / passt nicht mit Notiz).

## Admin

5. Sammelfreigabe der Reihe (Board, Knopf „Reihe freigeben“, oder `select bauform_freigeben('quadratische_funktionen_gleichungen');`
   als Admin). Danach sind die grünen Instanzen `ready`. Prüfung: `select count(*) from tasks t join bauformen b on b.id = t.bauform_id where b.status = 'freigegeben' and t.status = 'ready';`
6. Coach-Prüffragen freigeben (Status `geprueft` → `freigegeben`, Admin).

## Erste Session mit einem Kind (Batu)

7. Abnahme 6/9 live: Coach startet die Session, das Tablet bekommt Instanzen der richtigen Rolle und Stufe; home zieht
   nie Stufe 4/5; ein gezeigtes Lösungsbeispiel kommt nicht wieder (`aufgabe_gesehen`).
8. Abnahme 7 live: an einer Aufgabe im Kind-Detail „Aufgabe stimmt nicht“ tippen → die Instanz wird nicht mehr gezogen
   und steht im Board unter „Auffällig“. Danach im Board „Aufgabe wieder aktivieren“.
9. Abnahme 12 live: je Format eine Instanz auf dem Tablet mit Lenas Vorschau vergleichen (Feldmaske, Lösungsmenge,
   Graph-Auswahl, Fehler finden, Bausteine, Schritte ordnen, Zahl, MC, Mehrteiler).

## Nicht vergessen

10. Die LSA am Freitag (31.10., Batu) läuft unverändert: Bauform-Instanzen sind nur Pool `session`, die LSA-Pfade sind
    unberührt (LSA-Tests vor und nach jeder Migration grün). Nach der RLS-Änderung liest ein Kind keine Instanz direkt.
