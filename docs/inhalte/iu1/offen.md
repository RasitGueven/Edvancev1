# IU-1 · Offene Befunde

## O1 · Paket-Speicher aus FR-2 frischt sich in Prod nie auf (U0, 13.11.2026)

`lsa_paket_cache_auffrischen` löscht ohne WHERE. Unter der Rolle `authenticator` greift `safeupdate`, daher Fehler
„DELETE requires a WHERE clause“ (`lsa_paket_cache_stand.fehler` seit 11.11.). Alle FR-2-Funktionen rechnen live.
Behebung in U1 (`where true`), siehe `ist-analyse.md` §6.

## O2 · Sonderreihe MSA im Reiter Session-Reihen (U0)

Der Dummy zeigt „MSA-Vorbereitung (ZP10)“ als Reihe „In Planung“. Dafür gibt es keine Daten (keine Reihen-Tabelle,
keine MSA-Bauformen). Die Seite zeigt nur Reihen mit Bauformen; die Kennzahl „Reihen in Planung“ ist dann 0. Eine
Reihen-Tabelle kommt mit „Reihe anlegen“ (später).

## O3 · Bereich der Größen (U0)

`zuordnung.csv` führt „Größen“ (B6-1) und „Arithmetik“ (B6-2–4) neben den vier Bereichen der Seite. Beide zählen
hier zu „Arithmetik und Algebra“. Bitte bestätigen oder anders zuordnen (eine Zeile in `pruefziel_skills`).
