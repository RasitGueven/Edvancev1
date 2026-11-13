# IU-1 · Offene Befunde

## O1 · Paket-Speicher aus FR-2 frischt sich in Prod nie auf (U0, 13.11.2026)

`lsa_paket_cache_auffrischen` löscht ohne WHERE. Unter der Rolle `authenticator` greift `safeupdate`, daher Fehler
„DELETE requires a WHERE clause“ (`lsa_paket_cache_stand.fehler` seit 11.11.). Alle FR-2-Funktionen rechnen live.
Behebung in U1 (`where true`), siehe `ist-analyse.md` §6.
Dieselbe Ursache trifft den Trigger `lsa_paket_cache_trigger` (`update … set veraltet = true` ohne WHERE). Jeder
Schreibzugriff der App auf `schul_themenplan`, `schul_klassenarbeiten`, `thema_einstieg`, `skill_kante`, `skill_thema`,
`skills` oder `themen` scheitert damit. Betroffen ist zum Beispiel das Bestätigen einer Klassenarbeit
(`src/lib/supabase/kaFolge.ts:173–176`); in Prod gibt es 0 Zeilen in `schul_klassenarbeiten`. U1 behebt beides.

## O2 · Sonderreihe MSA im Reiter Session-Reihen (U0)

Der Dummy zeigt „MSA-Vorbereitung (ZP10)“ als Reihe „In Planung“. Dafür gibt es keine Daten (keine Reihen-Tabelle,
keine MSA-Bauformen). Die Seite zeigt nur Reihen mit Bauformen; die Kennzahl „Reihen in Planung“ ist dann 0. Eine
Reihen-Tabelle kommt mit „Reihe anlegen“ (später).

## O3 · Bereich der Größen (U0)

`zuordnung.csv` führt „Größen“ (B6-1) und „Arithmetik“ (B6-2–4) neben den vier Bereichen der Seite. Beide zählen
hier zu „Arithmetik und Algebra“. Bitte bestätigen oder anders zuordnen (eine Zeile in `pruefziel_skills`).

## O4 · CI `neuaufbau` rot, unabhängig von IU-1 (13.11.2026, 08:22 UTC) — HALTEPUNKT

PR #412 (nur Doku) ist im Schritt „Schema gegen erwarteten Stand vergleichen“ rot, dreimal hintereinander (Lauf
43392577530 und zwei Wiederholungen). `pg_dump` liefert für jede Spalte zusätzlich eine Zeile
`ALTER TABLE ONLY public.<tabelle> ALTER COLUMN <spalte> SET (pg_attver=<zahl>);`, die in
`supabase/schema-erwartet.sql` nicht steht. Alle drei Läufe hatten das Runner-Image `ubuntu-26.04` 20261101.186.1 und
haben `postgres:16` frisch gezogen („Downloaded newer image“, 16.16-1.pgdg13+1,
Digest `sha256:63e83b5a…`). Der letzte grüne dev-Lauf (12.11., 17:55 UTC) hatte das Image 20261111.196.1.

Die Abhilfe liegt unter `.github/` und ist für diesen Auftrag gesperrt. Zwei Möglichkeiten:

- `image: postgres:16` auf eine feste Version setzen (die vom 12.11.)
- im Vergleich zusätzlich `pg_attver` herausfiltern (`grep -vE '…|restrict |pg_attver'`)

Laut „Einspielen und Mergen“ ist ohne grüne CI weder Merge noch Einspielen erlaubt. **STOPP für Merge und
Einspielen.** U1 ist fertig vorbereitet (PR, lokal grün, Zweitprüfung), aber nicht eingespielt.

## O5 · Hinweise der Zweitprüfung U1 (bewusst so)

- Die Sitzungszuordnung kommt aus `bauform_plan_standard()`; `reihe_kernideen` ist nicht nach Reihe getrennt. Für eine
  zweite Reihe wären `sessions` 0 und alle Bauformen „ohne Session“. Das klärt „Reihe anlegen“.
- Lenas `pruef_ziel_stand` rechnet live (1–2 s), solange der Speicher nicht frisch ist; auffrischen dürfen nur Admins.
- Ohne Klassenfilter zählen die Schulen eines Themas über alle Klassen 8–10, Klasse und Zeitfenster kommen aus der
  Klasse mit den meisten Schulen.

## O6 · Lauf in der Prüfansicht folgt der Gesamtliste (U3)

„Gezielt prüfen“ mit Prüfziel MSA öffnet die Prüfansicht wie bisher mit `?liste=gezielt`. Nach einer Entscheidung
springt die Prüfansicht zur nächsten Aufgabe der **Gesamtliste** (`pruef_ziel_liste()` ohne Prüfziel), nicht der
MSA-Liste. Die 20 MSA-Kompetenzen ohne Paket kommen dort nicht vor. Lena muss dann über „Zurück zur Liste“ die
nächste MSA-Aufgabe wählen. Der Prüfablauf sollte laut Auftrag unverändert bleiben, deshalb bleibt das so. Die
Abhilfe wäre klein: das Prüfziel in `?liste=gezielt&ziel=msa_zp10` mitgeben und im Lauf
(`src/pages/coach/pruefen/PruefansichtPage.tsx`) an `getPruefZielListe` weiterreichen.
