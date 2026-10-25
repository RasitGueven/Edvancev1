# Retro 25.10.2026 – L1: Lenas Rückmeldungen vom 25.10.

## Gebaut
- Auswertung `docs/lsa/lena-rueckmeldungen-2026-10-25.md`: 11 Rückmeldungen mit Art, Vorschlag, Antwort, dazu die
  Zusatzprüfung der 123 freigegebenen Aufgaben (mit Taschenrechner lösbar, ohne known_error).
- Daten-Migration `20261025143853_lena_rueckmeldungen_1025` mit Rollback: known_errors in 2 Aufgaben (7 Werte, vorhandene
  Fehlbilder), typical_errors ohne Slug in 2 TERM-Aufgaben, 4 Aufgabentexte.
- Antworten über `pruef_rueckfrage_klaeren` als Rasit (`tools/l1b-antworten.sql`): 7 freigegeben, 4 an Lena.
- Prüfskript `supabase/checks/l1b_rueckfragen.PRUEFUNG.sql`, Trockenlauf `tools/l1b-wegwerf-db.sh` (Prod-Fixture).

## Entscheidungen
- Die 11 standen auf `rueckfrage`, nicht auf `ready`. „Freigegeben bleibt“ heißt deshalb `freigeben`, „zurück an
  Lena“ heißt `an_lena`.
- Ausgangsfassung diesmal nicht nachgezogen (anders als am 19.10.), damit Lena vorher → nachher sieht. Texte gehören
  nicht zur Fassung, die Antwort nennt sie wörtlich.
- TERM: kein acceptance möglich (`lsa_term_acceptance_guard`), Vergleich zeichengenau. Fehler nur als Hinweis, der Satz
  „in der Form ax + b“ bleibt.
- −14 bei −3 + 4 · 2 unter `plus_minus_vertauscht`: Der Vorrangfehler steckt schon im Wert 2, neu ist der Vorzeichenfehler.

## Offen
- TERM-Bewertung (Reihenfolge, known_errors) im Foundation-Fenster; danach Hinweise in Fehlbilder überführen,
  `vorzeichen_teilweise_verteilt` anlegen, Formulierung „in der Form ax + b“ ersetzen.
- „Gib den Wert für x an.“ in 7 freigegebenen und 15 Entwurfs-Aufgaben.
- Taschenrechner-Liste A (18 Wurzel-Aufgaben plus 49²): Entscheidung Rasit.
- Das Board-Kennzeichen „geändert ↺“ kommt aus Lenas letztem Protokoll. Admin-Änderungen sieht sie nur in der
  Einzelansicht.
