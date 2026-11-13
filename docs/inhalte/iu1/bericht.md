# IU-1 · Bericht: Inhalte-Übersicht

**Stand:** 13.11.2026. Protokoll: `fortschritt.md`, offene Punkte: `offen.md`, Ist-Analyse: `ist-analyse.md`,
Dummy: `referenz/`.

## Für die Gründer

1. **Wo:** Admin → Inhalte → **Inhalte-Übersicht** (`/admin/inhalte`). Die Seite hat zwei Reiter, „Lernstandsanalyse“
   und „Session-Reihen“, und einen Filter für Klasse 8, 9 und 10. Die bisherige „LSA-Abdeckung“ hat keinen eigenen
   Menüpunkt mehr. Sie bleibt unter ihrer Adresse erreichbar und ist über die Spalte „Wirkung“ verlinkt.
2. **Die Ampeln:**
   - **Vollständig:** Für jede Kompetenz des Themas sind 2 Texte freigegeben, davon mindestens 1 ohne Multiple
     Choice.
   - **Eingeschränkt:** Einstieg und direkte Voraussetzungen sind so weit, die Tiefe fehlt noch.
   - **Noch nicht:** sonst. Die Zahl darunter sagt, wie viele Pflicht-Kompetenzen fehlen.
   - Bei den Reihen heißt **Bereit:** Alle Bauformen und Videos sind freigegeben.
3. **In Lenas Liste:** Ein Klick auf ein Thema zeigt die Kompetenzen. „In Lenas Liste“ öffnet „Gezielt prüfen“,
   gefiltert auf diese Kompetenz. Ein Klick auf die MSA-Zeile zeigt die vier Bereiche, „Lena prüft …“ öffnet ihre
   Liste mit dem Prüfziel MSA. Lena selbst schaltet oben zwischen „Alle“ und „MSA (ZP10)“ um.

**Stand in Zahlen (Prod, 13.11.2026):**

| | |
|---|---|
| Themen der Pläne Kl. 8–10 | 22: 0 vollständig, 1 eingeschränkt (Flächen von Dreiecken und Vierecken), 21 noch nicht |
| MSA (ZP10), 122 Kompetenzen | 35 bereit, 9 teilweise, 78 offen; 165 Texte fehlen, Lena kann 159 prüfen, für 6 fehlen noch Aufgaben |
| Reihen | 1 (Quadratische Funktionen und Gleichungen): 7 Sessions, 47 Bauformen alle bei Lena, 0 von 9 Videos freigegeben → nicht bereit |
| Themen ohne Reihe | 20; mit Vorarbeit: 13 mit passenden Bauformen, 7 nur mit LSA-Aufgaben |
| Aufgaben für Lena | Gesamtliste: 139 nötig (223 Vorschläge, davon Reserve); Themen-Reiter: 137 (je Kompetenz einmal); MSA: 161 nötig, 231 Vorschläge in 85 Kompetenzen, davon 19 ohne Paket (vorher nicht in ihrer Liste) |

## PRs

| PR | Inhalt | Merge-Commit |
|---|---|---|
| #412 | U0 Ist-Analyse (Doku) | `939682d4` |
| #417 | CI: `pg_attver` im Schema-Vergleich ignorieren (einmalige Freigabe, O4) | `a38fdfda` |
| #416 | U1 Daten: Prüfziele, Funktionen, Zwischenspeicher, Prüfziel in Lenas Liste | `867c8988` |
| #418 | U2 Seite Inhalte-Übersicht | `3db548b1` |
| #419 | U3 Lenas Liste: Prüfziel MSA | `422d1f72` |
| (diese PR) | U4 Abnahme, U5 Bericht | – |

#412 und #416 wurden nach #417 bzw. SF-1 mit `origin/dev` gemischt statt rebased. Ein Rebase hätte einen Force-Push
gebraucht, und der ist für diesen Auftrag ausgeschlossen.

## Migrationen (eingespielt, Skripte `~/einspielen/IU1-<nr>-*.sh`)

| Version | Name | Prüfabfrage (dbread, `abfragen/q_u1_pruefung.sql` → `ergebnisse/u1-pruefung.txt`) |
|---|---|---|
| `20261113082550` | iu1_inhalte | 19 Funktionen, 14 Trigger; FR-2-Speicher löscht und markiert mit WHERE (O1); Prod-Abzug = Neuaufbau bis auf die Kopfzeilen |
| `20261113082906` | iu1_pruefziel_msa | NOTICE 122/122 Kompetenzen, 50/50 Aufgaben (13 zu schwer, 37 zu leicht) |

Regression: `pruef_ziel_liste()` ohne neue Parameter liefert in Prod vor und nach IU-1 dieselbe Ausgabe (md5
`fb85…4b49`, 91 Zeilen). Vorher auf Prod-Daten in der Wegwerf-DB belegt, danach in Prod. Es war kein Rollback nötig.

## Abnahme (U4, `ergebnisse/u4-abnahme.txt`)

| Fall | Wie | Ergebnis |
|---|---|---|
| a) Ampel vollständig / eingeschränkt / noch nicht | pgTAP `iu1_inhalte` 2a–2g (Fixtures), CI dev 54/54 | **grün** |
| b) MSA-Zeile = `inhalte_lsa_pruefziel`; Archiv und Ausschluss ändern sie nicht | Ansichtstest (Seite liest genau diese Funktion), pgTAP 3a/3b, 4a/4b; dbread 35/9/78 | **grün** |
| c) „In Lenas Liste“ öffnet gefiltert, Lena sieht genau die offenen Aufgaben | Vitest Link `/coach/pruefen?skill=…`; Ansichtstest U3 gefiltert; dbread: 73 von 73 Kompetenzen mit offenen Aufgaben haben in der Liste genau dieselben Aufgaben | **grün** |
| d) Lena sieht unter MSA die Kompetenzen ohne Paket | dbread: 19 Kompetenzen, 56 Aufgaben (U0: 20 / 59) | **grün, Abweichung erklärt:** `fkt_sinus_periodisch` hat nur 3 Entwürfe, alle „zu schwer“ |
| e) `pruef_ziel_liste` ohne neue Parameter unverändert | md5 vor/nach in Prod und in der Wegwerf-DB; pgTAP 5a–5f | **grün** |
| f) Reihe 1 mit echten Zahlen, 7 Sessions | dbread: 47 Bauformen = Tabelle, 0 von 9 Videos (0 Sequenzen freigegeben), 7 Sessions | **grün** |
| g) Themen ohne Reihe ohne Thema einer Reihe | dbread: 0 Treffer (Kernideen-Bauformen) | **grün** |
| h) Beide Reiter < 1 s | Prod-Fixture mit Speicher: LSA ≈ 10 ms, Reihen ≈ 90 ms. **Prod live:** LSA 1,4 s + MSA 1,0 s, Reihen 0,4 s + ohne Reihe 1,6 s | **nur mit Speicher grün** (O7) |
| i) Geschützte Funktionen unverändert | Funktionskörper in `schema-erwartet.sql` 75489322 vs. dev md5-gleich (11 Funktionen), keine IU-1-Migration nennt sie | **grün** |

Weitere Belege:
- **Zweitprüfungen:** Die erste fand zweimal „falsch“ und einmal „fehlt“, alles behoben. Die zweite, auf dem
  Fix-Commit, fand nichts der Art „falsch“ oder „bricht“.
- **Vitest:** 3407/3407.
- **Ansichtstests:** U2 10/10, U3 6/6, je bei 1180 × 820 und 1440 × 900. Fotos in `abnahme/`.
- **CI** war in jeder PR grün.

## Offene Punkte (`offen.md`)

- **O2:** Die Sonderreihe MSA aus dem Dummy fehlt, es gibt keine Daten dafür. Sie kommt mit „Reihe anlegen“.
- **O5:** Hinweise der Zweitprüfung, bewusst so gelassen:
  - Die Sessions kommen aus dem Standardplan, und der ist nicht nach Reihe getrennt.
  - Lenas `pruef_ziel_stand` rechnet live.
- **O6:** Nach einer Entscheidung springt die Prüfansicht zur nächsten Aufgabe der Gesamtliste, nicht der MSA-Liste.
  Die Abhilfe ist klein und beschrieben.
- **O7:** Laufzeit in Prod live über 1 s.
  - Der Speicher wird beim ersten Seitenaufruf eines Admins gerechnet (`inhalte_auffrischen`). Per dbread geht das
    nicht, weil dbread nur liest.
  - Bis dahin rechnen die Funktionen live (1,0–1,6 s je Abfrage).
  - Jede Schreiboperation auf Aufgaben macht den Speicher veraltet. Dann rechnet der nächste Seitenaufruf neu (≈ 1,6 s).
- **O1, Nachweis:** Der Test mit `safeupdate` in der Wegwerf-DB wurde von der Rechteprüfung abgelehnt.
  - Belegt sind der Funktionskörper mit WHERE (dbread), der Quelltext von `safeupdate` (prüft nur „WHERE vorhanden“)
    und pgTAP ohne `safeupdate`.
  - Den letzten Beweis liefert der erste Seitenaufruf: Danach muss `lsa_paket_cache_stand.fehler` leer sein.
