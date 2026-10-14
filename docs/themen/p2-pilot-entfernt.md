# P2 · Pilot-Flag entzogen (Rücksetzliste)

Stand 14.10.2026, per `dbread` gegen Produktion (nur lesend). Migration `20261014150100_p2_pilot_aus`.

## Was und warum

Nach P1 trugen 331 Aufgaben `pruef_pilot = true`: die 255 Aufgaben aus P1s Zielmenge (LSA-Aufgaben der 29 Knoten
aus Batus Freigabeliste plus die 49 E3-Session-Aufgaben) und **76 weitere**. Die 76 sind der Rest des ersten
Lena-Board-Piloten (PR #208, Migration `20261005080222_pruefung_daten.sql`, Abschnitt 26 „100 Aufgaben aus 33
Themen“, Liste `docs/lena-board/pilot.csv`); 24 der damals 100 liegen in Batus Knoten und bleiben. Gesetzt wurden sie
per Migration, nicht über die Admin-Aktion `pilot_an`, deshalb hat keine der 76 eine `task_admin_protokoll`-Zeile.
Zweck damals: ein Querschnitt (rund 3 Aufgaben je Thema) zum Kennenlernen des Boards.

Entscheidung Rasit (14.10.2026): Lenas Board zeigt nur Batus Liste. Die 76 verlieren das Flag über denselben Weg wie
die Admin-Aktion `pilot_aus` (`pruef_sammel_schreiben`, je Aufgabe eine Protokollzeile `pilot_aus`). Status, Texte,
Lösungen und Prüfungen bleiben unverändert.

**Hinweis:** `573dd0b7-…` (vorzeichen_vorrang) steht auf `review`, Lena hat sie schon mit „Passt“ bewertet. Die
Bewertung bleibt erhalten, die Aufgabe ist nur nicht mehr im Board.

## Zurücksetzen nach Batu

Als Admin in der Prüfansicht: die IDs unten auswählen → Sammelaktion „In den Pilot“ (`pilot_an`). Oder per SQL
(als Systemaufruf, eine Transaktion):

```sql
select set_config('request.jwt.claim.role', 'service_role', true);
select public.pruef_sammel('pilot_an', array['<id>', …]::uuid[], '{"grund":"P2 zurück"}', false);
```

`pruef_sammel` verlangt Admin; als Systemaufruf stattdessen je ID `pruef_sammel_schreiben('pilot_an', t, …)` wie in
`20261014140200_p1_batu_pilot.sql`.

## Die 76 Aufgaben

| ID | Knoten | Thema | Status | Typ | Kurztitel |
|---|---|---|---|---|---|
| `0644e069-c106-4cb4-8faa-bbad5edddb70` | geo_aehnlich_streckfaktor | aehnlichkeit | draft | NUMERIC | Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm |
| `75cb4657-94a9-4348-b6b1-807f241f4914` | geo_aehnlich_streckfaktor | aehnlichkeit | draft | NUMERIC | Rückrichtung · Original aus 7 cm Bild und k = 2,5 |
| `a1d203d7-0d30-42ae-8c54-d3e7dc04a7d6` | geo_aehnlich_streckfaktor | aehnlichkeit | draft | NUMERIC | Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert |
| `28ee89d3-0cdc-4842-869e-423c2bf78f8d` | stoch_bedingt_vierfeld | bedingte_wahrscheinlichkeit | draft | MULTI_PART | Vierfeldertafel · Haustier, zwei Felder |
| `52f02da3-efb0-4667-8387-506d491e74c5` | stoch_bedingt_vierfeld | bedingte_wahrscheinlichkeit | draft | MULTI_PART | Vierfeldertafel · aus Prozentangaben, Werkstücke |
| `e61dfd20-5b7c-4f12-94f9-f38a51ab64c5` | stoch_bedingt_vierfeld | bedingte_wahrscheinlichkeit | draft | MULTI_PART | Vierfeldertafel · Feld und relative Häufigkeit |
| `4615926e-2f06-4780-9b12-d153117c045e` | stoch_kenngroessen | daten_streumasse | draft | NUMERIC | Unteres Quartil · acht Werte |
| `ae38bcca-7313-4863-95a6-8117a7b524d1` | stoch_kenngroessen | daten_streumasse | draft | NUMERIC | Spannweite · Sachkontext · Morgentemperaturen |
| `f91e5425-b56b-434f-9ae1-814649f9aba3` | stoch_kenngroessen | daten_streumasse | draft | NUMERIC | Oberes Quartil · neun Werte |
| `785c92ab-e234-469f-bb6a-59c0c11db8fd` | fkt_exp_term | exponentialfunktionen | draft | MULTI_PART | Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 |
| `a30145c7-5bc0-4f21-80ee-5237c1df2756` | fkt_exp_term | exponentialfunktionen | draft | MULTI_PART | Term aufstellen · Anfangswert 200, Abnahme 10 % |
| `f52ef418-8b90-4c8f-903f-975f8bd8da41` | fkt_exp_term | exponentialfunktionen | draft | MULTI_PART | Term lesen · f(x) = 250 · 1,08ˣ |
| `b7b814a6-d2c9-4988-855c-3d51b5148da0` | groessen_flaechen | flaeche_umfang | draft | NUMERIC | Größen · Flächen · 3 dm² |
| `d09b4715-e18d-4588-a00e-fbadaea189e1` | groessen_flaechen | flaeche_umfang | draft | NUMERIC | Größen · Flächen · 250 cm² |
| `f531dcee-04cf-4e14-ad5e-9032f72f0668` | groessen_flaechen | flaeche_umfang | draft | NUMERIC | Größen · Flächen · 3000000 mm² |
| `d602bc49-3ee0-48fb-8cd3-467b2ae0abc2` | geo_flaeche_dreieck | flaechen_vielecke | draft | NUMERIC | Geometrie · Fläche Parallelogramm · 7×6 |
| `ea14696a-c3ae-40e4-938a-051a13fdbbd4` | geo_flaeche_dreieck | flaechen_vielecke | draft | NUMERIC | Geometrie · Fläche Dreieck · 8×6 |
| `ecb3d12b-a21e-4031-b562-a1596deeb815` | geo_flaeche_dreieck | flaechen_vielecke | draft | NUMERIC | Geometrie · Fläche Dreieck · 6×8 |
| `8e1dd449-25bb-4fc1-9d60-d38609216ba5` | geo_massstab | ganze_zahlen_groessen | draft | NUMERIC | Geometrie · Maßstab · 1:50000, 6 cm |
| `ceb26573-de3f-488a-9956-6a8cf7eb81cf` | geo_massstab | ganze_zahlen_groessen | draft | NUMERIC | Geometrie · Maßstab · 1:100, 25 cm |
| `fe3a88b0-7d72-4896-929c-b7f0c379cfa3` | geo_massstab | ganze_zahlen_groessen | draft | NUMERIC | Geometrie · Maßstab · 1:25000, 4 cm |
| `650eed2a-79e5-4a6f-9ed2-a51053fe75c8` | geo_koordinaten | geometrische_grundbegriffe | draft | MULTI_PART | Koordinaten · Punkt ablesen · 1. Quadrant |
| `a1fa4311-c631-47ba-a4a7-15e12149db4c` | geo_koordinaten | geometrische_grundbegriffe | draft | MULTI_PART | Koordinaten · Punkt ablesen · 2. Quadrant |
| `d8195933-ba82-4768-ac40-064da27497a6` | geo_koordinaten | geometrische_grundbegriffe | draft | MULTI_PART | Koordinaten · Punkt ablesen · 3. Quadrant |
| `0d01fa82-d4fb-4fc4-ba47-62d7175763ee` | geo_koerper_pyramide | koerper_pyramide_kegel_kugel | draft | NUMERIC | Pyramide · Volumen mit rechteckiger Grundfläche |
| `5beb71a7-cbef-4392-bcca-446b1bc97354` | geo_koerper_pyramide | koerper_pyramide_kegel_kugel | draft | NUMERIC | Pyramide · Dachfläche eines Pyramidendachs |
| `5cad7848-0d28-4198-93a0-6232e6f988b1` | geo_koerper_pyramide | koerper_pyramide_kegel_kugel | draft | NUMERIC | Pyramide · Grundkante aus Volumen und Höhe |
| `6a448f69-d164-4cf6-82ca-461a8bae980f` | geo_volumen_quader | koerper_quader | draft | NUMERIC | Geometrie · Volumen Quader · 2×3×4 |
| `7d305269-159f-40cc-9965-c343c2bb4c15` | geo_volumen_quader | koerper_quader | draft | NUMERIC | Geometrie · Oberfläche Quader · 2×3×5 |
| `8e82be72-f8e3-480f-bdef-a4e78ddd060f` | geo_volumen_quader | koerper_quader | draft | NUMERIC | Geometrie · Volumen Quader · 3×4×5 |
| `7223ee1a-3043-487e-850c-e9da8501d935` | geo_kreis_flaeche | kreis | draft | NUMERIC | Fläche · Radius 2,4 m |
| `9ef4de2a-1a55-49a3-ac80-2a03594006b8` | geo_kreis_flaeche | kreis | draft | NUMERIC | Fläche · eine große Pizza gegen zwei kleine |
| `e0cfc702-9b40-450e-b530-1b6bb53976a8` | geo_kreis_flaeche | kreis | draft | NUMERIC | Fläche · Radius 80 cm, Ergebnis in m² |
| `20cdce1e-0e9d-478d-820e-b77ff90c94bc` | groessen_gemischt | natuerliche_zahlen | draft | NUMERIC | Größen · Gemischt · 2,5 h |
| `57246a98-fef1-4beb-b288-24a676d2eeb2` | groessen_zeit | natuerliche_zahlen | draft | NUMERIC | Größen · Zeit · 225 min |
| `9f7f0cd7-128b-4a4d-9281-16c78804a1b4` | groessen_zeit | natuerliche_zahlen | draft | NUMERIC | Größen · Zeit · 75 min |
| `3510e4f2-f006-4d20-bdf8-8d8520ed09e1` | zahl_potenz_rechnen | potenzen | draft | MULTI_PART | Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) |
| `a35d5827-c2d4-48a9-87b8-6c69c1078abe` | zahl_potenz_rechnen | potenzen | draft | MULTI_PART | Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) |
| `d7f1416b-ee9c-408c-8dd3-7e2bfc623a27` | zahl_potenz_rechnen | potenzen | draft | MULTI_PART | Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren |
| `807dd2a7-18a0-4ff1-93e4-d2d26052cd12` | geo_koerper_prisma | prismen_zylinder | draft | NUMERIC | Prisma · Höhe aus Volumen und Dreiecksgrundfläche |
| `9de789c5-cdc1-45c4-b38f-d809926410f5` | geo_koerper_prisma | prismen_zylinder | draft | NUMERIC | Prisma · Wassertrog mit dreieckigem Querschnitt |
| `e958eb79-345a-4079-867b-46ecb652b478` | geo_koerper_prisma | prismen_zylinder | draft | NUMERIC | Prisma · Volumen mit Trapez als Grundfläche |
| `5875fe3f-394d-4a2b-8977-bf825b5f9518` | geo_pythagoras_hypotenuse | pythagoras | draft | NUMERIC | Hypotenuse · Katheten 12 cm und 0,35 m |
| `e63c2e2e-396f-46f6-91d1-c34595a88dbc` | geo_pythagoras_hypotenuse | pythagoras | draft | NUMERIC | Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten |
| `ee07674f-0846-4f38-a0c7-247fd351b729` | geo_pythagoras_hypotenuse | pythagoras | draft | NUMERIC | Hypotenuse · Katheten 4,5 cm und 6 cm |
| `1d8a70aa-9010-4259-9278-5cbc6425d3c0` | fkt_quadr_scheitel | quadratische_funktionen | draft | MULTI_PART | Scheitelpunkt · y = −2(x + 4)² − 5 |
| `f70e9312-b530-4b4b-9c7a-087ef87fbba9` | fkt_quadr_scheitel | quadratische_funktionen | draft | MULTI_PART | Scheitelpunkt · y = 4 − 2(x − 6)² |
| `f96d3513-0ae9-4316-a871-4bf72aff96c3` | fkt_quadr_scheitel | quadratische_funktionen | draft | MULTI_PART | Scheitelpunkt · y = (x − 3)² + 1 |
| `573dd0b7-5fd2-4b4e-9263-3630affba5da` | vorzeichen_vorrang | rationale_zahlen | review | NUMERIC | Vorzeichen · Vorrang · 4 + (-2) · 3 |
| `90b93e1f-091c-4bbb-a6a7-5d48c9d5b6c1` | vorzeichen_vorrang | rationale_zahlen | draft | NUMERIC | Vorzeichen · Vorrang · 6 + (-3) · 4 |
| `a394b2eb-df58-4b57-9c79-ae8ff0c62b24` | vorzeichen_vorrang | rationale_zahlen | draft | NUMERIC | Vorzeichen · Vorrang · -3 + 4 · 2 |
| `f66a50d0-7de9-4cad-89c5-a92028eecf1d` | vorzeichen_vorrang | rationale_zahlen | draft | NUMERIC | Vorzeichen · Vorrang · 5 - 2 · (-3) |
| `0b3bf2b5-29bc-4b79-9fa5-2e1016d65e97` | fkt_sinus_einheitskreis | sinusfunktion | draft | MULTI_PART | Rückrichtung · Punkt mit y = −0,6 im vierten Viertel |
| `82cb7f14-5213-4aea-a297-c480c557463c` | fkt_sinus_einheitskreis | sinusfunktion | draft | MULTI_PART | Punkt auf dem Einheitskreis · α = 240° |
| `3b59c4a1-2216-48a5-9462-64c03187acd9` | fkt_sinus_graph | sinusfunktion | draft | MULTI_PART | Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π |
| `2708a240-7d4b-42bb-a028-d106ebe60765` | stoch_bedingt_irrefuehrend | statistik_beurteilen | draft | NUMERIC | Schlagzeile mit vertauschter Bedingung · Kettenriss |
| `982be3c3-2d1f-4d59-817a-b7bd45ade1d6` | stoch_bedingt_irrefuehrend | statistik_beurteilen | draft | NUMERIC | Absolut oder relativ · Diebstähle je 1000 Einwohner |
| `a1c6838a-e550-4ed2-92cf-55244acded67` | stoch_bedingt_irrefuehrend | statistik_beurteilen | draft | NUMERIC | Absolut oder relativ · Radfahrer an zwei Schulen |
| `4f0b933d-3ead-4042-adb9-a1369ba28f39` | gleichung_modellieren | terme_gleichungen | draft | MULTI_PART | Modellieren · Gleichung · Handytarif |
| `d393d7c6-e5ff-43bb-b049-e8ba63aa1cdf` | gleichung_modellieren | terme_gleichungen | draft | MULTI_PART | Modellieren · Gleichung · Alter |
| `d986ca37-4dc0-43c6-a148-153aa8605838` | gleichung_modellieren | terme_gleichungen | draft | MULTI_PART | Modellieren · Gleichung · Trikot |
| `1b979a6a-de0f-434e-96c3-c5859a536a36` | geo_trigo_verhaeltnis | trigonometrie | draft | NUMERIC | Ähnliche Dreiecke · gleicher Sinus, c' = 12 cm |
| `3ba007ed-a9f6-44fd-9800-07b92ffdbb65` | geo_trigo_verhaeltnis | trigonometrie | draft | NUMERIC | Tangens · erst die fehlende Kathete, a = 9 cm, c = 15 cm |
| `0c5d8ee8-fed2-4022-9d27-23860d1d7cc7` | geo_trigo_winkel | trigonometrie | draft | MULTI_PART | Beide spitzen Winkel · a = 5 cm, c = 8 cm |
| `9e26a451-8496-4a05-9f4d-752d05fcddf9` | geo_winkel_neben_scheitel | winkel_dreiecke | draft | NUMERIC | Nebenwinkel · Leiter auf dem Boden |
| `c0b1c3c5-0c12-4815-bce5-377fca8504c4` | geo_winkel_neben_scheitel | winkel_dreiecke | draft | NUMERIC | Nebenwinkel · Schnitt zweier Geraden |
| `e04364d3-e946-4be1-8aca-0b3b1c52353d` | geo_winkel_neben_scheitel | winkel_dreiecke | draft | NUMERIC | Neben- und Scheitelwinkel · Summe zweier Gegenwinkel |
| `7875948d-3789-43cb-8e1a-861de7167ece` | prozent_grundwert | zinsrechnung | draft | NUMERIC | Prozent · Grundwert · 12 sind 15 % |
| `7eba6b75-1852-4713-8f6b-bf0e626fa52b` | prozent_grundwert | zinsrechnung | draft | NUMERIC | Prozent · Grundwert · 12 sind 25 % |
| `dda4b621-05d8-4390-bf6a-078a4a7bd19b` | prozent_grundwert | zinsrechnung | draft | NUMERIC | Prozent · Grundwert · 20 sind 25 % |
| `743dc783-c0c1-4b97-957c-e8dfff38e3b6` | stoch_laplace | zufallsexperimente | draft | NUMERIC | Laplace · Glücksrad · Primzahl |
| `7e7ce00a-733b-404a-88fe-b41cf327f2f5` | stoch_laplace | zufallsexperimente | draft | NUMERIC | Laplace · Lostrommel · Niete |
| `fdd119e8-2192-4691-bda5-d6a5a03317d4` | stoch_laplace | zufallsexperimente | draft | NUMERIC | Laplace · Rückrichtung · Gesamtzahl der Kugeln |
| `0cdf2d28-abd3-4931-8b51-81fe03044974` | proportionalitaet | zuordnungen | draft | NUMERIC | Dreisatz · 2 Arbeiter schaffen eine Aufgabe in 3 Stunden. |
| `8b4bf5c8-d813-439b-b9a4-5dd412b8b0af` | proportionalitaet | zuordnungen | draft | NUMERIC | Dreisatz · 2 Pumpen leeren ein Becken in 6 Stunden. |
| `bb650a2d-6122-42ee-9fa1-3a2b1f1eda1e` | proportionalitaet | zuordnungen | draft | NUMERIC | Dreisatz · 2 Maler streichen eine Wand in 9 Stunden. |
