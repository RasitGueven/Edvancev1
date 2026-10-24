# Prüfung Batus Liste · Inhalte vor Lenas Freigabe (19.10.)

Stand 16.10.2026, alle Zahlen per `~/bin/dbread` gegen Produktion (nur lesend). Nicht committet.

## Grundlage

- Umfang: `tasks.pruef_pilot = true` → **255 Aufgaben** (P2 ist eingespielt: `20261014150100`–`150300`), alle `draft`.
  Davon ist 1 regulär ausgeschlossen (`dezimal_mult` `e8e6eeb7`, `pruef_ausschluss = gate`). Lena sieht also 254.
  Sie wird in Spalte 1 mitgezählt, ist aber nie „tauglich“.
- **„nicht Batu“: 0.** Jede Pilot-Aufgabe fällt in eine der Gruppen.
- Session = die 49 IDs aus `docs/prefill/hinweise-e3-snapshot.json` (PR #244). `vorzeichen_add_sub` (7 Aufgaben) gehört
  zu Stufe 2 **und** zur Session und steht deshalb in beiden Tabellen. Die Stufensummen ergeben zusammen 262 = 255 + 7.
- Spalte 3 / 4: Fehlbilder über `pruef_fehler_gruppen(acceptance)` (dieselbe Funktion wie `pruef_sicht`, also auch Teilaufgaben).
  „Ohne Klartext“ heißt: keine `fehlbild_labels`-Zeile mit nicht-leerem `klartext`.
- Spalte 5: `correct_answers` nicht leer (bei MULTI_PART je Teil), `lsa_answers_valid` und `lsa_acceptance_valid` erfüllt.
- Spalte 6: `pruef_auffaelligkeiten(task, correct_answers, acceptance, solution)`. Genau so ruft `pruef_aufgabe` diese
  Funktion für Lenas Board auf (nicht nachgebaut). `pruef_aufgabe` selbst wurde nicht aufgerufen, weil es beim ersten
  Öffnen die Ausgangsfassung schreibt. Anzahl = Befund-Einträge; bei MC zählt jeder Ablenker einzeln, dazu „in n Aufg.“.
- Spalte 7: Hinweisstufen = verschiedene `level` mit nicht-leerem `text` in `task_solutions.hints`.
- Spalte 8 „tauglich“ = Musterlösung + Fehlbild + gültige Antworten + kein Befund + nicht ausgeschlossen.
  Soll laut Auftrag (= `pruef_soll.batu_lsa`). Für die Session gibt der Auftrag kein Soll vor, verwendet ist
  `pruef_soll.batu_session` (alle Aufgaben je Knoten, ohne Mindestzahl ohne MC).

## Tabelle je Knoten

### Stufe 1

| Knoten | 1 gesamt / ohne MC | 2 Musterlösung | 3 Fehlbild | 4 Slugs ohne Klartext | 5 Antworten gültig | 6 Befunde je Code | 7 < 3 Hinweise | 8 tauglich (ohne MC) / Soll | reicht |
|---|---|---|---|---|---|---|---|---|---|
| zahl_wurzel_irrational | 6 / 6 | 6 | 6 | 1: teilgekuerzt | 6 | – | – | 6 (6) / 6 (1) | ja |
| zahl_wurzel_naeherung | 6 / 6 | 6 | 6 | 0 | 6 | loesungsweg_endet_falsch 2 in 2 Aufg. | – | 4 (4) / 6 (1) | **nein** |
| zahl_wurzel_teilweise | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 6 (1) | ja |
| zahl_wurzel_gesetze | 6 / 6 | 6 | 6 | 0 | 6 | loesungsweg_endet_falsch 2 in 2 Aufg. | – | 4 (4) / 6 (1) | **nein** |
| zahl_wurzel_quadrat | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 6 (1) | ja |
| **Summe Stufe 1** (5 Knoten) | 30 / 30 | 30 | 30 | 1 verschiedene | 30 | loesungsweg_endet_falsch 4 in 4 Aufg. | – | 26 (26) / 30 | 3 von 5 |

### Stufe 2

| Knoten | 1 gesamt / ohne MC | 2 Musterlösung | 3 Fehlbild | 4 Slugs ohne Klartext | 5 Antworten gültig | 6 Befunde je Code | 7 < 3 Hinweise | 8 tauglich (ohne MC) / Soll | reicht |
|---|---|---|---|---|---|---|---|---|---|
| potenzen | 24 / 24 | 8 | 24 | 0 | 24 | loesungsweg_endet_falsch 1 in 1 Aufg. | – | 7 (7) / 3 (1) | ja |
| bruch_dezimal | 6 / 6 | 0 | 6 | 0 | 6 | – | – | 0 (0) / 3 (1) | **nein** |
| dezimal_div | 9 / 9 | 3 | 9 | 0 | 9 | – | – | 3 (3) / 3 (1) | ja |
| dezimal_mult | 9 / 9 (1 gate) | 2 | 9 | 0 | 9 | loesungsweg_endet_falsch 1 in 1 Aufg. | – | 1 (1) / 3 (1) | **nein** |
| vorzeichen_mult_div | 7 / 7 | 0 | 7 | 0 | 7 | – | – | 0 (0) / 3 (1) | **nein** |
| runden_ueberschlag | 13 / 13 | 3 | 13 | 0 | 13 | – | – | 3 (3) / 3 (1) | ja |
| dezimal_add_sub | 11 / 11 | 3 | 11 | 0 | 11 | – | – | 3 (3) / 3 (1) | ja |
| bruch_kuerzen | 7 / 7 | 0 | 7 | 1: teilgekuerzt | 7 | – | – | 0 (0) / 3 (1) | **nein** |
| vorzeichen_add_sub | 7 / 7 | 0 | 7 | 0 | 7 | – | – | 0 (0) / 3 (1) | **nein** |
| **Summe Stufe 2** (9 Knoten) | 93 / 93 | 19 | 93 | 1 verschiedene | 93 | loesungsweg_endet_falsch 2 in 2 Aufg. | – | 17 (17) / 27 | 4 von 9 |

### Stufe 3

| Knoten | 1 gesamt / ohne MC | 2 Musterlösung | 3 Fehlbild | 4 Slugs ohne Klartext | 5 Antworten gültig | 6 Befunde je Code | 7 < 3 Hinweise | 8 tauglich (ohne MC) / Soll | reicht |
|---|---|---|---|---|---|---|---|---|---|
| fkt_linear_gleichung | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| fkt_linear_steigung | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| fkt_linear_yabschnitt | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| term_binom_faktorisieren | 6 / 1 | 6 | 6 | 0 | 6 | mc_ablenker_ohne_fehlbild 8 in 5 Aufg. | – | 1 (1) / 2 (1) | **nein** |
| term_binom_gemischt | 6 / 0 | 6 | 6 | 0 | 6 | mc_ablenker_ohne_fehlbild 10 in 6 Aufg. | – | 0 (0) / 2 (1) | **nein** |
| term_binom_quadrat | 6 / 0 | 6 | 6 | 0 | 6 | mc_ablenker_ohne_fehlbild 10 in 6 Aufg. | – | 0 (0) / 2 (1) | **nein** |
| term_binom_quadratdifferenz | 6 / 1 | 6 | 6 | 0 | 6 | mc_ablenker_ohne_fehlbild 9 in 5 Aufg. | – | 1 (1) / 2 (1) | **nein** |
| gleichung_lgs_addition | 6 / 5 | 6 | 6 | 0 | 6 | – | – | 6 (5) / 2 (1) | ja |
| gleichung_lgs_einsetzen | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| gleichung_lgs_grafisch | 6 / 4 | 6 | 6 | 0 | 6 | – | – | 6 (4) / 2 (1) | ja |
| geo_flaeche_drachen_raute | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| geo_flaeche_term | 6 / 2 | 6 | 6 | 0 | 6 | mc_ablenker_ohne_fehlbild 3 in 2 Aufg. | – | 4 (2) / 2 (1) | ja |
| geo_flaeche_trapez | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| stoch_pfad_summe | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| geo_winkel_thales | 6 / 6 | 6 | 6 | 0 | 6 | – | – | 6 (6) / 2 (1) | ja |
| **Summe Stufe 3** (15 Knoten) | 90 / 61 | 90 | 90 | 0 verschiedene | 90 | mc_ablenker_ohne_fehlbild 40 in 24 Aufg. | – | 66 (61) / 30 | 11 von 15 |

### Session E3

| Knoten | 1 gesamt / ohne MC | 2 Musterlösung | 3 Fehlbild | 4 Slugs ohne Klartext | 5 Antworten gültig | 6 Befunde je Code | 7 < 3 Hinweise | 8 tauglich (ohne MC) / Soll | reicht |
|---|---|---|---|---|---|---|---|---|---|
| vorzeichen_add_sub | 7 / 7 | 0 | 7 | 0 | 7 | – | 0 | 0 (0) / 7 | **nein** |
| term_ausklammern | 6 / 0 | 0 | 0 | 0 | 6 | mc_ablenker_ohne_fehlbild 18 in 6 Aufg. | 0 | 0 (0) / 6 | **nein** |
| gleichung_einschrittig | 6 / 6 | 0 | 6 | 0 | 6 | – | 0 | 0 (0) / 6 | **nein** |
| gleichung_zweischrittig | 6 / 6 | 0 | 6 | 0 | 6 | – | 0 | 0 (0) / 6 | **nein** |
| gleichung_quadr_wurzel | 6 / 6 | 6 | 6 | 0 | 6 | – | 0 | 6 (6) / 6 | ja |
| gleichung_quadr_faktor | 6 / 6 | 6 | 6 | 0 | 6 | – | 0 | 6 (6) / 6 | ja |
| gleichung_quadr_formel | 6 / 6 | 6 | 6 | 0 | 6 | – | 0 | 6 (6) / 6 | ja |
| gleichung_quadr_anzahl | 6 / 6 | 6 | 6 | 0 | 6 | – | 0 | 6 (6) / 6 | ja |
| **Summe Session E3** (8 Knoten) | 49 / 43 | 24 | 43 | 0 verschiedene | 49 | mc_ablenker_ohne_fehlbild 18 in 6 Aufg. | 0 | 24 (24) / 49 | 4 von 8 |


## Knoten, die nicht reichen

- **Stufe 1 · zahl_wurzel_naeherung** – 4 von 6 nötigen tauglich, 4 ohne MC: Befunde: loesungsweg_endet_falsch 2 in 2 Aufg..
- **Stufe 1 · zahl_wurzel_gesetze** – 4 von 6 nötigen tauglich, 4 ohne MC: Befunde: loesungsweg_endet_falsch 2 in 2 Aufg..
- **Stufe 2 · bruch_dezimal** – 0 von 3 nötigen tauglich, 0 ohne MC: nur 0 von 6 Aufgaben haben eine Musterlösung; keine taugliche Aufgabe ohne MC.
- **Stufe 2 · dezimal_mult** – 1 von 3 nötigen tauglich, 1 ohne MC: nur 2 von 9 Aufgaben haben eine Musterlösung; Befunde: loesungsweg_endet_falsch 1 in 1 Aufg..
- **Stufe 2 · vorzeichen_mult_div** – 0 von 3 nötigen tauglich, 0 ohne MC: nur 0 von 7 Aufgaben haben eine Musterlösung; keine taugliche Aufgabe ohne MC.
- **Stufe 2 · bruch_kuerzen** – 0 von 3 nötigen tauglich, 0 ohne MC: nur 0 von 7 Aufgaben haben eine Musterlösung; keine taugliche Aufgabe ohne MC.
- **Stufe 2 · vorzeichen_add_sub** – 0 von 3 nötigen tauglich, 0 ohne MC: nur 0 von 7 Aufgaben haben eine Musterlösung; keine taugliche Aufgabe ohne MC.
- **Stufe 3 · term_binom_faktorisieren** – 1 von 2 nötigen tauglich, 1 ohne MC: Befunde: mc_ablenker_ohne_fehlbild 8 in 5 Aufg..
- **Stufe 3 · term_binom_gemischt** – 0 von 2 nötigen tauglich, 0 ohne MC: Befunde: mc_ablenker_ohne_fehlbild 10 in 6 Aufg.; keine taugliche Aufgabe ohne MC (Knoten hat nur MC).
- **Stufe 3 · term_binom_quadrat** – 0 von 2 nötigen tauglich, 0 ohne MC: Befunde: mc_ablenker_ohne_fehlbild 10 in 6 Aufg.; keine taugliche Aufgabe ohne MC (Knoten hat nur MC).
- **Stufe 3 · term_binom_quadratdifferenz** – 1 von 2 nötigen tauglich, 1 ohne MC: Befunde: mc_ablenker_ohne_fehlbild 9 in 5 Aufg..
- **Session E3 · vorzeichen_add_sub** – 0 von 7 nötigen tauglich, 0 ohne MC: nur 0 von 7 Aufgaben haben eine Musterlösung.
- **Session E3 · term_ausklammern** – 0 von 6 nötigen tauglich, 0 ohne MC: nur 0 von 6 Aufgaben haben eine Musterlösung; nur 0 haben ein Fehlbild; Befunde: mc_ablenker_ohne_fehlbild 18 in 6 Aufg..
- **Session E3 · gleichung_einschrittig** – 0 von 6 nötigen tauglich, 0 ohne MC: nur 0 von 6 Aufgaben haben eine Musterlösung.
- **Session E3 · gleichung_zweischrittig** – 0 von 6 nötigen tauglich, 0 ohne MC: nur 0 von 6 Aufgaben haben eine Musterlösung.


**Hinweis zu `loesungsweg_endet_falsch`:** Alle 6 Treffer sind Fehlalarme der Regel. Sie nimmt die letzte Zahl nach dem
letzten „=“/„≈“, und in diesen Lösungswegen folgt nach dem richtigen Ergebnis noch eine Probe oder Erklärung
(„… = 0,12 m² (3 · 4 = 12 …)“, „Probe: 5² = 25 < 30 < 36 = 6²“). Würden diese 6 nicht zählen, reichten
`zahl_wurzel_naeherung` und `zahl_wurzel_gesetze` (je 6/6), `dezimal_mult` bliebe bei 2/3.

| Knoten | Aufgabe | richtig | Ende des Lösungswegs | Regel liest |
|---|---|---|---|---|
| dezimal_mult | 98441ffc | 0,12 | … = 0,12 m² (3 · 4 = 12, zwei Nachkommastellen). | 12 |
| potenzen | e04a700d | 0,16 | … 0,4 = 0,16. (4 · 4 = 16, und das Ergebnis hat zwei Nachkommastellen.) | 16 |
| zahl_wurzel_gesetze | ce24db36 | 1,5 | … √2,25 = 1,5, denn 1,5 · 1,5 = 2,25. | 2,25 |
| zahl_wurzel_gesetze | 88c99e21 | 5 | … √25 m = 5 m. (Nicht 3 m + 4 m: ein Quadrat mit 7 m Seite hätte 49 m².) | 49 m² |
| zahl_wurzel_naeherung | 0b9229a0 | 5,48 | … √30 ≈ 5,48. Probe: 5² = 25 < 30 < 36 = 6². | 6² |
| zahl_wurzel_naeherung | 9af2a3ce | 0,95 | … Wurzel aus einer Zahl zwischen 0 und 1 ist größer als die Zahl selbst. | 1 ist |

## Fehlbild-Slugs ohne Klartext auf Batus Liste

- `teilgekuerzt` (bruch_kuerzen, zahl_wurzel_irrational)


`fehlbild_labels.teilgekuerzt` existiert, `klartext` ist NULL und nicht freigegeben.

## Abfragen

Hauptabfrage (eine Zeile je Aufgabe und Gruppe; ausgewertet mit `\pset format unaligned`, Tabellen per Skript zusammengezählt):

```sql
with e3(id) as (values ('152bcdcd-897b-452b-9a8f-402375540a3f'::uuid),('fbd28765-b198-4ff6-bdbe-de9ccc5202de'::uuid),('d19c8070-85d9-44cc-b4cc-eac3e06010d0'::uuid),('bfd877b9-cd3e-490c-82ad-0274b4f85a8b'::uuid),('4f6f7cdd-3415-4185-8eae-95083d061b71'::uuid),('6fc6928a-6ae3-4c32-9c2e-b9a20451b97c'::uuid),('0c3d2396-131a-4cba-bd07-4597d92500cf'::uuid),('a549083d-c72d-44d6-9aba-a138ad6d2dc0'::uuid),('95077a87-7e8a-4463-83b0-dbbf6facc879'::uuid),('ef911123-949d-4ea9-a61d-beef95cc8dc0'::uuid),('9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5'::uuid),('56540a88-7b9e-4935-8702-26f9415e9d14'::uuid),('d7d81e80-6776-4308-a690-29675f7882d4'::uuid),('b47ef7d3-1933-416f-8fe8-edcbc8fe8929'::uuid),('1c4a31af-20bc-4348-b8d9-cd83b273ff38'::uuid),('9879542e-bb69-41c6-a77f-3916a26ffad1'::uuid),('c3be2e88-1087-479f-bf95-9dbd732efa56'::uuid),('90635757-ba7c-4bde-bd7c-04bd79bf8c35'::uuid),('1f2a206f-1f63-4866-b446-c8305de6b725'::uuid),('1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee'::uuid),('5b36238f-c64c-4578-bd63-55249f185c78'::uuid),('b6e77404-2577-4e03-b4ce-cb61a5f6a5f9'::uuid),('725448a1-10e2-4e88-beb8-fe57f6e54d06'::uuid),('43f39bc1-e7b4-48e6-8b77-ff8e41e77142'::uuid),('504bbd98-9c80-4124-a66a-9dc7b6651bb9'::uuid),('4d1a2438-3610-4dc9-b5be-8d35cb5199bd'::uuid),('cd6693f5-cc93-4628-baf9-f45436706641'::uuid),('3a42b89c-7f8a-4b64-94ff-d1d4ac576c32'::uuid),('bc0cdfe9-2416-4d02-a623-feb820083f07'::uuid),('9264f90a-1f7b-4170-97da-198c1acc89a3'::uuid),('e8348c89-67cb-4650-be91-235e69321776'::uuid),('7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992'::uuid),('17f3e728-2249-42ba-b5bf-c2a4b344dd00'::uuid),('b01451c0-53e5-4da7-9591-280448264835'::uuid),('9d15a93e-961b-4569-be8b-c4482dc98301'::uuid),('ff5710af-0c0a-47e5-9a57-b2a5bb4ef82d'::uuid),('02b24419-d7e8-40b8-8b74-ef3b4e806b3f'::uuid),('81f97d0e-1e95-4bbd-bc6a-d05149786c58'::uuid),('4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af'::uuid),('65841bd8-ee27-454f-b2a4-ea6f1bb0db33'::uuid),('ea237a07-681d-4680-bcd0-d94316c899e9'::uuid),('b15b6be0-1b87-477d-bd88-23b095501581'::uuid),('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'::uuid),('17674b19-fe14-42ca-98db-6598fa8c5a3a'::uuid),('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid),('c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0'::uuid),('3b44eada-3589-4bdb-a33b-2fb2ca0a1726'::uuid),('3e6fb055-111e-4888-9177-d2b17dd0fc54'::uuid),('738de19f-d3c9-43a0-b5ce-af6e30752c75'::uuid))
, gruppen(skill_key, gruppe, soll, sort) as (values
 ('zahl_wurzel_irrational','1',6,110),('zahl_wurzel_naeherung','1',6,120),('zahl_wurzel_teilweise','1',6,130),('zahl_wurzel_gesetze','1',6,140),('zahl_wurzel_quadrat','1',6,150),
 ('potenzen','2',3,210),('bruch_dezimal','2',3,220),('dezimal_div','2',3,230),('dezimal_mult','2',3,240),('vorzeichen_mult_div','2',3,250),('runden_ueberschlag','2',3,260),('dezimal_add_sub','2',3,270),('bruch_kuerzen','2',3,280),('vorzeichen_add_sub','2',3,290),
 ('fkt_linear_gleichung','3',2,410),('fkt_linear_steigung','3',2,420),('fkt_linear_yabschnitt','3',2,430),('term_binom_faktorisieren','3',2,440),('term_binom_gemischt','3',2,450),('term_binom_quadrat','3',2,460),('term_binom_quadratdifferenz','3',2,470),('gleichung_lgs_addition','3',2,480),('gleichung_lgs_einsetzen','3',2,490),('gleichung_lgs_grafisch','3',2,500),('geo_flaeche_drachen_raute','3',2,510),('geo_flaeche_term','3',2,520),('geo_flaeche_trapez','3',2,530),('stoch_pfad_summe','3',2,540),('geo_winkel_thales','3',2,550)),
pilot as (select t.*, t trow, s.solution, s.correct_answers ca, s.acceptance acc, s.hints sh,
                 public.pruef_ausschluss(t.id) ausschluss
            from public.tasks t left join public.task_solutions s on s.task_id = t.id where t.pruef_pilot),
zuordnung as (
  select p.id, g.gruppe, p.skill_key from pilot p join gruppen g on g.skill_key = p.skill_key
  union all
  select p.id, 'S', p.skill_key from pilot p join e3 on e3.id = p.id
  union all
  select p.id, 'nicht Batu', coalesce(p.skill_key,'(ohne)') from pilot p
   where not exists (select 1 from e3 where e3.id = p.id) and not exists (select 1 from gruppen g where g.skill_key = p.skill_key)),
je as (
  select z.gruppe, z.skill_key, p.id, p.input_type, p.ausschluss,
         p.input_type = 'MC' mc,
         nullif(btrim(coalesce(p.solution,'')), '') is not null loesung,
         exists (select 1 from public.pruef_fehler_gruppen(p.acc)) fehlbild,
         (select array_agg(distinct fg.slug) from public.pruef_fehler_gruppen(p.acc) fg
           where not exists (select 1 from public.fehlbild_labels l where l.slug = fg.slug and nullif(btrim(l.klartext),'') is not null)) slugs_ohne,
         case when p.ca is null then false
              when jsonb_typeof(p.ca) = 'array' then jsonb_array_length(p.ca) > 0
              when jsonb_typeof(p.ca) = 'object' then p.input_type = 'MULTI_PART'
                   and not exists (select 1 from jsonb_array_elements(p.parts) pt
                                    where jsonb_typeof(p.ca -> (pt ->> 'nr')) is distinct from 'array'
                                       or jsonb_array_length(p.ca -> (pt ->> 'nr')) = 0)
              else false end
         and public.lsa_answers_valid(p.ca) and (p.acc is null or public.lsa_acceptance_valid(p.acc)) antworten,
         (select coalesce(array_agg(b ->> 'code' order by b ->> 'code'), '{}')
            from jsonb_array_elements(public.pruef_auffaelligkeiten(p.trow, coalesce(p.ca, '[]'), p.acc, p.solution)) b) befunde,
         (select count(distinct h ->> 'level') from jsonb_array_elements(case when jsonb_typeof(p.sh) = 'array' then p.sh else '[]' end) h
           where nullif(btrim(coalesce(h ->> 'text', '')), '') is not null) hinweise
    from zuordnung z join pilot p on p.id = z.id)
select je.*, (je.loesung and je.fehlbild and je.antworten and cardinality(je.befunde) = 0 and je.ausschluss is null) tauglich
  from je;
```

Einzelbelege (`loesungsweg_endet_falsch`, `teilgekuerzt`, Ausschluss):

```sql
\pset format unaligned
\pset fieldsep ' | '
\pset footer off
select t.skill_key, left(t.id::text,8) id, s.correct_answers::text ca, right(regexp_replace(s.solution, '\s+', ' ', 'g'), 70) loesung_ende, b ->> 'wert' wert, b ->> 'stufe' stufe
  from tasks t join task_solutions s on s.task_id = t.id,
       jsonb_array_elements(public.pruef_auffaelligkeiten(t, coalesce(s.correct_answers,'[]'), s.acceptance, s.solution)) b
 where t.pruef_pilot and b ->> 'code' = 'loesungsweg_endet_falsch' order by 1;
select slug, klartext is null kein_klartext, freigegeben_am is not null freigegeben from fehlbild_labels where slug = 'teilgekuerzt';
select t.skill_key, left(t.id::text,8) id from tasks t where t.pruef_pilot and t.skill_key = 'dezimal_mult' and public.pruef_ausschluss(t.id) is not null;
```
