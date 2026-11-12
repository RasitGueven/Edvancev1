# Retro: MSA-0 Bestandsaufnahme ZP10 (12.11.2026)

## Gebaut

- `docs/msa/bestandsaufnahme.md` mit 20 Abfragen (`docs/msa/abfragen/`, read-only, `lauf.sh`), Zuordnung
  ZP10-Kompetenz → Skill (`anhang/zuordnung.csv`), Soll-Rechnung für die Regeln 2, 3 und 4, Aufgabenliste (894),
  Niveau-Urteile (402 Aufgaben) und Quellen (`docs/msa/quellen/`).
- Keine Änderung an Prod und kein Code.

## Entscheidungen

- **Grundlage 2027 ist der KLP RS/GE 2004.** Die Vorgaben haben keine Themenliste. Die KLP 2022 gelten erst ab 2028.
- **Prüfungsarbeiten 2024–2026 fehlen** (Login). Als Ersatz dienten die freien Teil-1-Beispiele und die
  Formelsammlung. Die Spalte „Teil 2“ und die Gewichtung sind daher geschätzt.
- **QUA-LiS-Aufgabenbeispiele, Formelsammlung und Ergebnisbericht nicht ins Repo** (Urheberrecht ungeklärt, Linie
  VERA8). Die Kopien liegen lokal in `~/msa-quellen-lokal/`, im Repo stehen nur Fundstelle und Zusammenfassung.
- **Soll über alle 130 Skills.** Grund: Die Pakete der Klassen 8–10 und die MSA zusammen ergeben alle Skills.
- Fachliche Urteile haben frische Subagenten geprüft: die Zuordnung (20 richtig, 4 teilweise, korrigiert) und das
  Niveau.

## Offene Punkte

- Rasit: Prüfungsarbeiten und Auswertungsanleitungen MSA 2024–2026 besorgen (Windows-Downloads).
- Gründerfragen in Bericht §7: Regel 2/3/4, archivieren oder löschen, Lenas Selbstkorrektur, Umfang der MSA-Reihe,
  Zielgruppe RS/GE.
- Nebenbefunde:
  - 20 LSA-Aufgaben stehen in `session_schritte` (aus der Zeit vor der Pool-Trennung).
  - In `schulen` gibt es einen Eintrag „Gymnasium“ ohne Schulform.
  - Die Schulform „Sekundarschule“ ist per CHECK nicht erlaubt.
  - `pruef_ziel_liste` verliert Skills ohne Paket (Inner Join).
