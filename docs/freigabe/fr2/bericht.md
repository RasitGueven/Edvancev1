# FR-2 · Bericht

**Stand:** 09.11.2026. Alle Phasen F0–F4 sind gemergt und eingespielt, F5 abgenommen. Protokoll: `fortschritt.md`.

## PRs

| Phase | PR | Merge-Commit | Inhalt |
|---|---|---|---|
| Schritt 0 | #378 | `c6fdf998` | FR-0 Bestandsaufnahme |
| F0 | #379 | `07ec7288` | Ist-Analyse |
| F1 | #380 | `845cede4` | Pakete, Ampel, Prüfliste (Datenmodell, Funktionen, Zwischenspeicher) |
| F2 | #381 | `1ec95e42` | Admin-Seite LSA-Abdeckung, nur_pilot aus |
| F3 | #382 | `3b9875ee` | Reiter „Gezielt prüfen“ im Lena-Board |
| F4.1 | #383 | `5ad6f9a0` | Einstiegsknoten |
| F4.2 | #384 | `2bd0d948` | Zweite Aufgabentexte |
| F5 | dieser PR | – | Abnahme, Bericht, Live-Checkliste |

## Eingespielte Migrationen

| Version | Name | Prüfabfrage (dbread nach dem Einspielen) |
|---|---|---|
| `20261109114850` | fr2_lsa_pakete | 19 Funktionen, 7 Trigger, 3 Stellschrauben, Speicher 2026/27 frisch, 501 Pakete Kl. 8–10, 0 Fokus |
| `20261109123016` | fr2_nur_pilot_aus | nur_pilot = f, 716 LSA-Entwürfe für Lena sichtbar |
| `20261109130447` | fr2_einstiege | 3 neue Einstiege, 0 Themen und 0 Pakete Kl. 8–10 ohne Einstieg |
| `20261109130736` | fr2_zweite_texte | 7 Aufgaben, 7 mit Lösung, 7 draft/lsa, 7 im Board, 7 mit neuem Text |

Jede Migration lief über `~/einspielen/FR2-<nr>-<name>.sh`:

1. Zielprüfung: Datenbank `postgres` und Prod-Ref `ztcppihxqcphlqaguhma`
2. Vorbedingungen per dbread
3. `mig`
4. `tools/schema-snapshot.sh`

Der Schema-Abzug nach F1 entspricht dem Neuaufbau bis auf die Kopfzeilen, die übrigen drei Migrationen ändern nur
Daten. Es gab keinen Rollback.

## Abnahme (F5)

| # | Fall | Wie | Ergebnis |
|---|---|---|---|
| 1 | Regression gegen den Bericht | dbread Prod (`abfragen/f1-regression.sql`) | Nach F1 genau wie im Bericht: 501 Pakete, 0 grün; Kl. 10 49 Skills / 92 Texte; Kl. 8–10 73 / 137; Top-6 wie §2d/§3e (dezimal_add_sub 501 … term_zusammenfassen 138). **Nach F4.1** Kl. 8–10 74 / 139. Grund: Die neuen Einstiege bei `statistik_beurteilen` ziehen `stoch_bedingt_irrefuehrend` in die Pakete der Klasse 9. Kl. 10 bleibt 49 / 92. **Grün** |
| 2 | Gelb (Pflicht ja, Tiefe nein), Grün (alles + Einstieg), sonst Rot | pgTAP `fr2_lsa_pakete` 3a–3g | **Grün** |
| 3 | Bestätigte Folge ersetzt geschätzte Pakete, Übersicht zeigt „bestätigt“ | pgTAP 5a–5d | **Grün** |
| 4 | Fokus bringt die Themen der Schule im Fenster nach oben | pgTAP 6a–6d | **Grün** |
| 5 | Kein Vorschlag mit Pool-Textschlüssel, nie mehr als fehlende_texte + 1 | pgTAP 7a–7f; dbread Prod: 0 von 204 Vorschlägen mit Pool-Schlüssel, 0 von 74 Skills mit zu vielen | **Grün** |
| 6 | Sammelfreigabe nur mit `pruef_freigabe_erlaubt`, Gate greift, Lena darf nicht | pgTAP 8a–8d (Aufgabe ohne Stoffanker scheitert am Gate und bleibt review; Lena 42501); die Seite ruft genau `pruef_sammel('freigeben')` (Vitest) | **Grün** |
| 7 | Lena sieht nach „passt“ die Wirkung, die Prüfansicht springt zur nächsten Aufgabe der Liste | Vitest `PruefansichtPage.test.tsx` · gezielte Liste | **Grün** |
| 8 | Übersicht < 1 s bei allen Filtern | dbread Prod | **Mit Speicher grün:** 0,22–0,23 s (gemessen nach F1, Speicher frisch). **Live 1,6–1,7 s** (gemessen nach F4.1, Speicher veraltet). Der erste Seitenaufruf rechnet neu, danach ist er wieder frisch. Prüfliste 2,9 s. |
| 9 | Auswahl der LSA unverändert | Funktionskörper in `schema-erwartet.sql` vor (`c6fdf998`) und nach FR-2 | `lsa_select_next_core`, `lsa_freie_aufgabe`, `lsa_im_pool`, `pruef_entscheiden`, `task_status_set` byte-gleich (md5), keine FR-2-Migration nennt sie. **Grün** |
| 10 | Eichpunkt Batu: FWG Kl. 9 „Reelle Zahlen“ | dbread Prod (`eichpunkt-batu.md`) | **Rot.** Einziger fehlender Pflicht-Skill: `bruch_dezimal`. Er hat 4 ready-Aufgaben, alle mit demselben Text. Die neue Aufgabe aus F4.2 steht als Vorschlag in der Liste (Rang 8). Nach Lenas „passt“ und der Freigabe wird das Paket Gelb. Stellschrauben nicht geändert. |

pgTAP lokal auf dem Stand von `dev` nach F4.2: 39/39. CI (`neuaufbau`) war in allen PRs grün. Vitest gesamt war bei F3
3348/3348.

## Offene Punkte

1. **Eichpunkt Batu** ist Rot (Fall 10). Gründerfrage: Reicht bei Pflicht-Skills ein Text, wenn die erste Aufgabe
   ohne MC ist (Bericht FR-0 §9, Frage 5)?
2. **F4.1 strittig:** `rationale_zahlen → potenzen` als zweiter Einstieg, offen für Rasit (`einstiege-vorschlag.md`).
   Dazu zwei Hinweise des Prüfers zum Skill-Graphen:
   - Für Ordnen, Betrag und negative Brüche gibt es keinen Skill.
   - Eine Kante `stoch_kenngroessen` → `stoch_bedingt_irrefuehrend` fehlt.
3. **O1 entschieden (Rasit):** Die Kopie des Vorschau-Rands bleibt. Ändert jemand den Rand in
   `lsa_select_next_core`, muss `lsa_paket_skills_roh` nachgezogen werden (pgTAP 2b sichert ab).
4. **Laufzeit live:** Ohne frischen Speicher dauert die Übersicht 1,6 s. Neu gerechnet wird beim Laden der
   Seiten, nicht sofort beim Schreiben (bewusst, Zweitprüfung F1).
5. **Lena und „Nachprüfen“:** Die 32 Aufgaben sind ready und öffnen sich für Lena nur lesend. Eine Entscheidung darauf
   geht über den bestehenden Weg „Freigabe zurücknehmen“ (Admin), nicht über FR-2.
6. **Hinweise der Zweitprüfung F1** (bewusst so):
   - Lage bestätigter Arbeiten aus dem Datum
   - Planzeilen ohne Thema zählen nicht zur Lage
   - Die Regel 2/1 steht zusätzlich in `pruef_soll` (altes Board)
   - Die Stand-Zeile serialisiert Schreiber der sieben Tabellen bis zum Commit
7. **Unruhiger Test:** `ReportPage.pdf.test.tsx` war einmal in der CI rot (F3) und lokal 3× grün. Er gehört nicht
   zu FR-2.

## Die ersten 20 Aufgaben in `pruef_ziel_liste` (Prod, 09.11.2026, nach F4.2)

| # | Thema (Lenas Sprache) | Fertigkeit | Aufgabe | Reserve |
|---|---|---|---|---|
| 1 | Rechnen mit Brüchen und Dezimalzahlen | Dezimalzahlen addieren/subtrahieren | Sachkontext · Dezimal · Rucksackinhalt (`20321d30`) | |
| 2 | Rechnen mit Brüchen und Dezimalzahlen | Dezimalzahlen addieren/subtrahieren | Sachkontext · Dezimal · Kanne (`5699500a`) | ja |
| 3 | Rechnen mit Brüchen und Dezimalzahlen | Dezimalzahlen multiplizieren | Sachkontext · Dezimal · Wasserhahn (`21f1c9f4`) | |
| 4 | Rechnen mit Brüchen und Dezimalzahlen | Dezimalzahlen multiplizieren | Sachkontext · Dezimal · Fliese (`98441ffc`) | ja |
| 5 | Rechnen mit Brüchen und Dezimalzahlen | Dezimalzahlen dividieren | Sachkontext · Dezimal · Schnur teilen (`1debff4f`) | |
| 6 | Rechnen mit Brüchen und Dezimalzahlen | Dezimalzahlen dividieren | Sachkontext · Dezimal · Saft verteilen (`730dae3f`) | ja |
| 7 | Brüche und Anteile | Brüche kürzen | Brüche · Kürzen · Sachaufgabe Fahrrad (`3b64f242`, neu F4.2) | |
| 8 | Rechnen mit Brüchen und Dezimalzahlen | Bruch in Dezimalzahl | Dezimalzahlen · Bruch umwandeln · Sachaufgabe Glas (`b65bad4b`, neu F4.2) | |
| 9 | Terme und Gleichungen | Terme zusammenfassen | Terme · Zusammenfassen · 7x + 4 − 2x + 6 (`16d690c9`) | |
| 10 | Prozent- und Zinsrechnung | Prozentwert berechnen | Prozent · Prozentwert · 25 % von 60 (`4d9e1f4d`) | |
| 11 | Prozent- und Zinsrechnung | Prozentwert berechnen | Prozent · Prozentwert · 15 % von 80 (`8337d39e`) | |
| 12 | Prozent- und Zinsrechnung | Prozentwert berechnen | Sachkontext · Prozentwert · Chorstimmen (`0452250a`) | ja |
| 13 | Terme und Gleichungen | Beidseitige Gleichungen | Gleichungen · Variable beidseitig · Zahlenrätsel (`300b2a89`, neu F4.2) | |
| 14 | Rechnen mit Brüchen und Dezimalzahlen | Brüche multiplizieren | Brüche · Multiplizieren · 2/3 · 3/4 (`590b9c87`) | |
| 15 | Rechnen mit Brüchen und Dezimalzahlen | Brüche multiplizieren | Brüche · Multiplizieren · Sachaufgabe Holzleiste (`fa8c52a4`, neu F4.2) | |
| 16 | Prozent- und Zinsrechnung | Grundwert berechnen | Prozent · Grundwert · 12 sind 15 % (`7875948d`) | |
| 17 | Prozent- und Zinsrechnung | Grundwert berechnen | Prozent · Grundwert · 12 sind 25 % (`7eba6b75`) | |
| 18 | Prozent- und Zinsrechnung | Grundwert berechnen | Prozent · Grundwert · 15 sind 50 % (`592eefb1`) | ja |
| 19 | Prozent- und Zinsrechnung | Prozentuale Veränderung | Prozent · Veränderung · 60 € −25 % (`2155cd07`) | |
| 20 | Prozent- und Zinsrechnung | Prozentuale Veränderung | Prozent · Veränderung · 80 € −25 % (`be903a02`) | |

**Geschätzte Prüfzeit:**

- **Erste 20 Aufgaben:** 15 sind nötig, 5 Reserve.
  - Mit Lenas Median von 35,5 s je Aufgabe sind die 15 nötigen in rund 9 Minuten geprüft.
  - Mit 2 Minuten je Aufgabe (wie FR-0 §8) sind es 30 Minuten, mit allen 20 rund 40 Minuten.
- **Ganze Liste:** 134 nötige Aufgaben. Bei der Passt-Quote von 80,5 % sind das rund 166 Prüfungen, mit 2 Minuten
  je Aufgabe rund 5,5 Stunden.
- **Wirkung danach** (`lsa_wirkung`): An 31 weiteren Schulen ist eine LSA möglich.
