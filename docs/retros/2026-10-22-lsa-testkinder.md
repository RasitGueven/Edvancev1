# Retro 22.10.2026 · LSA-T Testkinder

## Gebaut

- `tools/lsa-testkinder/erzeugen.sql`: fünf Testkinder (Lina, Emre, Sophie, Jonas, Nele) mit Lead,
  Erstgespräch, Themen, Anliegen und einer vollständigen LSA über `lead_lsa_freigeben` → `lsa_submit` →
  `lsa_finish`. Reines SQL ohne DDL, eine Transaktion, wiederholbar (neue Sitzungen, nichts gelöscht).
- `supabase/tests/lsa_testkinder.test.sql`: das Skript zweimal im Neuaufbau, 32 Zusicherungen.
- README, offene Punkte, Bauauftrag unter `docs/lsa/`.

## Entscheidungen

- **Uhr:** `started_at` der neuen Sitzung einmal um 20 Minuten zurück, dann `p_jetzt` je Antwort. Die
  Auswahl kennt Zeit nur als Abstand zum Beginn; `platz_los`/`diagnose_ab` braucht ein Platz-Konto und
  bleibt ungenutzt (Hub-Weg).
- **Fester Schüler:** die Zeile, die `lead_lsa_freigeben` sonst selbst anlegt, legt das Skript mit fester
  UUID über dieselbe Schleuse (`edvance.allow_provisional`) an; die Freigabe findet sie und nutzt sie.
- **Falsche Antworten:** aus `acceptance.known_errors` (flach oder je Teil), gereiht nach Slug des
  Kindes, Familie, beschriftet, unbeschriftet; nie ein Wert, den `lsa_antwort_korrekt` oder `lsa_grade`
  als richtig nimmt. Sonst MC eine andere Option, Zahl + 1.
- **„teilweise Wurzel ziehen“** bei Emre als Skill gelesen (`zahl_wurzel_teilweise`, Profil uebung).
- **Sitzung des Laufs** über `lsat.sitzungen` statt Zeitstempel: in einer Transaktion haben zwei Läufe
  dasselbe `now()` — der Test hat das gefunden.

## Befunde

- Die heutige Auswahl zieht bei Lina und Emre nach dem Thema Bereiche ohne Bezug (Kegel, Thales,
  Stochastik) — das Bild, das LSA-V beheben soll. Gut als Vorher-Stand.
- Jonas erreicht Klasse 5/6 in 12 Minuten Tiefe nicht; Details in `docs/lsa/offene-punkte-lsa-t.md`.

## Offen

- Prod-Lauf durch Rasit nach LSA-V.
- Interessenswelt nur über Platz speicherbar.
