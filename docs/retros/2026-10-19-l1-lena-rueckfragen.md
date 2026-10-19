# Retro 19.10.2026 – L1: Lenas Rückfragen umsetzen und freigeben

## Gebaut
- M1 `20261019100100_l1_lena_fehlbilder`: zwei neue Fehlbilder mit eigener, freigegebener Familie
  (`plus_minus_vertauscht`, `merksatz_als_addition`), known_errors in 7 Aufgaben von vorzeichen_add_sub /
  vorzeichen_mult_div (Ausgangsfassung mitgezogen), Aufgabentext und Lösungstext 0b7e781c ohne „n“.
- M2 `20261019100200_l1_lena_rueckfragen_freigeben`: acht Rückfragen beantwortet und freigegeben, die Logik von
  pruef_rueckfrage_klaeren('freigeben') ausgeschrieben, statt auth.uid() Rasits Profil-ID.
- `supabase/checks/l1_rueckfragen.PRUEFUNG.sql`, `tools/l1-wegwerf-db.sh`, `tools/l1-wertung.sql`.

## Entscheidungen
- Der Wunsch-Slug `richtung_vertauscht` war schon belegt (Maßstab, 49 Schlüssel), deshalb heißt der neue
  `plus_minus_vertauscht`.
- Eine eigene Familie je Fehlbild, weil der Report nur Familien-Elterntexte zeigt.
- Ausgelassen wegen Kollision mit vorzeichen_ignoriert: 3e6fb055 (2 − 9 → 11) und 738de19f (3 − 8 → 11).

## Offen
- `vorzeichen_ignoriert` hat jetzt zwei Bedeutungen: Klartext „Beträge addiert“, aber −2 (e96cd37d) und
  4 (27f51c08) bedeuten „Vorzeichen der ersten Zahl übersehen“. Eigener Slug oder Klartext erweitern.
- Hinweise der Zweitprüfung (siehe PR): Elterntext „addiert die Zahlen“, −24 bei (−a)·(−b) fehlt usw.
