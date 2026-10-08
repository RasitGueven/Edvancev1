# Retro 07.10.2026 – Session-Rahmen C2: Coach-Live-Sicht mit echten Daten

## Gebaut
- Vier Migrationen `20261010110100`–`110400`: `coach_raum_live` erweitert (Testlauf, Check-out, Quest B,
  Eingriffe, Pfad-Entscheidung, Mastery dieser Session je Kind), `session_briefing`, Bausteinkatalog
  `session_satz_bausteine` mit `satz_vorschlaege`, `sessions_offen`. pgTAP `session_c2` (43).
- `src/lib/session/coachLive.ts` liest und handelt über die echten Funktionen; Abbildung in
  `coachLiveAbbildung.ts`/`coachLiveTeile.ts`, Fehler in `coachLiveFehler.ts`. Detail nur für die offene Schublade.
- Beispieldaten nur noch in Tests (`coachLiveBeispielQuelle.ts`); Beispielleiste weg, Phasen im Kopf antippbar.
- Prüffrage aufs Tablet / vom Tablet in der Mastery-Prüfung; Testlauf-Kennzeichen in Kopf und Raster.
- Coach-Startseite „Heute im Raum“ mit Start; „Offen geblieben“ auf Admin- und Coach-Startseite.
- Stellschrauben-Seite `/admin/stellschrauben` mit Verlauf.
- Vitest-Fixtures aus echten Antworten einer Wegwerf-DB (`docs/session/c2-coach-beispiele.sql`).

## Entscheidungen
- Zeitpunkt der Seite nach der Uhr wie `session_uhr_phase`; der Coach kann eine Phase vorziehen (Ansichtswahl).
- Briefing nur für Kinder mit laufendem Vertrag, auch für Admins (Akten-Lesen, Entscheidung 26).
- Satzvorschläge regelbasiert, zwei verschiedene Anlässe, fester Versatz je Kind; CHECK gegen Quoten im Katalog.

## Offen
- Siehe `docs/session/offene-punkte-c2.md` (Bausteine prüfen, Pfad-Vorschlag mit Zahlen, Altfälle unter
  „Offen geblieben“, Schema-Abzug nach dem Einspielen).
