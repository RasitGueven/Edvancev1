# MSA-1 · Bericht: LSA-Bestand bereinigen

**Stand:** 12.11.2026. Protokoll: `fortschritt.md`, offene Punkte: `offen.md`, Ist und Streichliste: `ist.md`,
`streichliste.csv`.

## Für die Gründer

Das Archiv liegt in der Item-Pflege (`/admin/authoring`): ganz unten rechts führt der kleine Textlink „Archiv (523)“ zur
Archiv-Seite. In der Navigation taucht es nicht auf, und nur Admins sehen es. Dort filterst du nach Skill oder Grund,
hakst eine oder mehrere Aufgaben an und klickst „Auswahl wiederherstellen“ (oder „Wiederherstellen“ in der Zeile).
Nach der Rückfrage ist die Aufgabe mit ihrem bisherigen Status sofort wieder in Pool, Board und Item-Pflege. Gelöscht
wurde nichts.

## PRs

| PR | Inhalt | Merge-Commit |
|---|---|---|
| #404 | M0 Ist und Streichliste (Doku), Entscheidung O1 | `539937d4` |
| #408 | CI: pgTAP ohne Server-Upgrade (einmalige Freigabe `.github/`) | `65e9445f` |
| #405 | M1 Archiv im Datenmodell | `c79026d9` |
| #406 | M2 523 Aufgaben archivieren | `5ae28ee6` |
| #407 | M3 Archiv-Ansicht, Admin-Listen ohne Archiv | `498d272f` |
| #410 | M4.2 neue Texte `bruch_div` (+2), `geo_kreis_zusammen` (+3) | `78d41f70` |
| #409 | M4.1 Rechner-Kennzeichen für 15 Aufgaben | `4e4306e7` |
| (diese PR) | M5 Abnahme und Bericht | – |

## Migrationen (alle eingespielt, Skripte `~/einspielen/MSA1-<nr>-*.sh`)

| Version | Name | Prüfabfrage (dbread nach dem Einspielen) |
|---|---|---|
| `20261112153053` | msa1_archiv | Funktionen `task_archiv`, `task_archivieren`, `task_wiederherstellen` da; 0 archiviert; Prod-Abzug = Neuaufbau bis auf die Kopfzeile |
| `20261112155221` | msa1_archivieren | 523 mit Grund `nicht_notwendig`, 0 davon aktiv; 523 Zeilen `archivieren` im Admin-Protokoll; kein Status gewechselt (Vergleich mit der Sicherung); dieselben 36 Skills erfüllen die Regel |
| `20261112173103` | msa1_neue_texte | 5 neue Aufgaben, draft, aktiv, Pool lsa, alle mit Lösung |
| `20261112173124` | msa1_taschenrechner | 15 von 15 mit `taschenrechner = true` |

**Sicherung vor M2:** `~/backups/msa1-archiv-2026-11-12.csv`. Sie enthält id, is_active, status, skill_key und
pruef_version der 523 Aufgaben. Kein Rollback war nötig.

## Abnahme (M5)

**1 · Bestand, Vorher und Nachher** (`ergebnisse/s03-vorher.txt`, `s03-nachher.txt`, `s04-vorher.csv`,
`s04-nachher.csv`):

| Kennzahl | vorher | nachher | Erklärung |
|---|---|---|---|
| LSA-Aufgaben aktiv / archiviert | 894 / 0 | 376 / 523 | 371 notwendige + 5 neue aktiv, Streichliste archiviert |
| tasks gesamt / task_solutions | 3412 / 3412 | 3417 / 3417 | +5 neue, **0 gelöscht** |
| lsa_responses / task_pruefungen | 925 / 175 | 925 / 175 | unverändert |
| ziehbar (`lsa_im_pool`) | 166 | 98 | 68 ready-Aufgaben mit gleichem Text oder über Soll archiviert |
| Skills mit erfüllter Regel (`lsa_skill_bereit`) | 36 | 36 | dieselben 36 (Datei-Vergleich S04) |
| Ampeln Kl. 8 / 9 / 10 | 176 / 176 / 149 rot | 176 / 176 / 149 rot | unverändert (es gab keine gelben oder grünen) |
| `pruef_ziel_roh` Skills / Vorschläge | 94 / 258 | 94 / 263 | +5 neue Texte |
| „Gezielt prüfen“ (Liste) | 204 | 204 | gleiche Skills, bei `bruch_div` und `geo_kreis_zusammen` jetzt neue Vorschläge |
| „Nachprüfen“ (ready ohne letztes „passt“) | 32 | 19 | 13 davon archiviert, die Liste blendet sie aus (M1) |

**2 · „Gezielt prüfen“ für Lena, nach Regel und Reserve** (`ergebnisse/s05-gezielt.txt`)

| | Skills | Regel | Reserve | gesamt |
|---|---|---|---|---|
| in der Liste (Skill in einem Paket Kl. 8–10) | 74 | 139 | 65 | 204 |
| nicht in der Liste (nur MSA, kein Paket) | 20 | 40 | 19 | 59 |
| **gesamt** (`pruef_ziel_roh`) | 94 | **179** | **84** | 263 |

Erwartet waren rund 176 und 97. **Abweichung erklärt:**

- **Regel:** 179 = die 176 Entwürfe der Streichliste plus 3 neue Texte aus M4.2. `bruch_div` fehlten 1 Text,
  `geo_kreis_zusammen` 2.
- **Reserve:** Von den 97 Reserve-Entwürfen der Streichliste gehören 15 zu Skills, die die Regel schon erfüllen.
  `pruef_ziel_roh` nimmt nur Skills ohne erfüllte Regel und schlägt für sie keine Reserve vor. Es bleiben 82, dazu
  2 aus M4.2, zusammen 84.
- **Nicht in der Liste:** Lena sieht nur 204 der 263 Vorschläge, weil `pruef_ziel_liste` die Skills ohne Paket
  ausblendet (Inner Join, Bericht MSA-0 §6a). Die 59 betreffen die 20 MSA-Skills außerhalb der Gymnasial-Pakete.
  Das gehört zum Folgeauftrag mit dem Prüfziel MSA.

**3 · Geschützte Funktionen:** `lsa_select_next_core`, `lsa_freie_aufgabe`, `lsa_im_pool`, `pruef_entscheiden`,
`task_status_set` und `aufgabe_ziehen` sind in `supabase/schema-erwartet.sql` vor MSA-1 (`6aa8490f`) und auf
`origin/dev` byte-gleich. Keine MSA-1-Migration nennt sie.

**4 · Weitere Belege**

- **pgTAP lokal:** 99 grün; dieselben 8 bekannt-roten Suiten wie auf `dev`. Der neue Test `msa1_archiv` hat 38/38.
- **CI:** In jeder PR waren `neuaufbau` und `quality` grün. `session_a2` wackelte einmal in #404, eine Wiederholung
  war grün.
- **Frontend:** typecheck, lint, Vitest 3380/3380. Ansichtstests 8/8 bei 1180 × 820 und 1440 × 900, Fotos in
  `abnahme/`.
- **Zweitprüfungen** je Migration durch frische Subagenten: M1, M2, M4.1 und M4.2 ohne „bricht“. Die Befunde „falsch“
  und „fehlt“ sind behoben (Bauform-Instanzen, Wächter bei geändertem Prod-Stand, Fehlbilder in Dezimalform).
- **Rauchtest dev:** Das Vercel-Deployment von `498d272f` ist gebaut. Die Abfragen der Seiten liefern per dbread für
  die Item-Pflege 0 archivierte und 371 aktive LSA-Aufgaben und für „Archiv (n)“ 523. Durchgeklickt im eingeloggten
  Admin habe ich nicht, dafür fehlt mir ein Login.

## Aufgaben mit offener Rückfrage unter den archivierten

| id | Skill | Lenas letzte Entscheidung | Notiz (gekürzt) |
|---|---|---|---|
| `1bbce78e-f996-4c03-a78a-09b47f5c7445` | fkt_linear_gleichung | unsicher (27.10.) | „s. meine Anmerkung zu f(x) bei der anderen Aufgabe“ |
| `a61e8be9-b55f-4c43-9971-7b74e3d55a33` | fkt_linear_gleichung | unsicher (27.10.) | „Weil das hier in der 7/8 Klasse angesetzt ist …“ |

Beide hatten den Status `rueckfrage` und sind nicht notwendig, weil `fkt_linear_gleichung` die Regel mit 3 Texten
schon erfüllt. Sie bleiben im Status `rueckfrage` und kommen beim Wiederherstellen so zurück.

## Offene Punkte (`offen.md`)

1. **Prüfziel MSA (Folgeauftrag):** `msa-ausschluss.csv` listet 13 zu schwere und 37 zu leichte Aufgaben.
   `pruef_ziel_liste` soll Skills ohne Paket zeigen, dafür muss der Inner Join gelöst werden.
2. **Rechner-Grenzfälle:** 15 der 30 Konflikte bleiben ohne Kennzeichen (`rechner.md`). Bei strenger Lesart wären
   4 Wurzel-Aufgaben „Rechner nötig“.
3. **Generator Kreis / zusammengesetzte Figur** (O4). Die neuen `geo_kreis_zusammen`-Aufgaben kommen ohne Figur aus.
4. **Hinweise der Zweitprüfung M1** (O3):
   - `read_tasks_by_role` lässt ready-Aufgaben ohne `is_active`-Filter lesen.
   - Admins können eine archivierte Aufgabe per `task_status_set` auf ready setzen.
   - Archivieren und Wiederherstellen zählen `pruef_version` hoch, ein offener Editor bekommt dann einen
     Versionskonflikt.
5. **Lena hat seit dem 28.10. nicht geprüft.** Für die Regel fehlen 179 Prüfungen, mit Reserve 263.
