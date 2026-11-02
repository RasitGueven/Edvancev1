# Methoden-Aufgaben und Taschenrechner

Stand 30.10.2026, gelesen aus Prod per `dbread`: alle LSA-Aufgaben in `ready` oder `rueckfrage` aus den Skills
`zahl_wurzel_*` und `term_binom_*`. Das sind 42 von 170. Außerhalb dieser Skills verlangt kein Arbeitsauftrag eine
Methode wörtlich („geschickt“, „im Kopf“, „vorteilhaft“, „mit binomischer Formel“, „teilweise radizieren“,
„Nenner rational machen“, Potenz- oder Wurzelgesetze).

Bei diesen Aufgaben würde ein Rechner die geprüfte Methode umgehen. Deshalb bleibt `tasks.taschenrechner` hier
`false`. Ausnahme sind die fünf Aufgaben mit „ja“: Sie brauchen einen Näherungswert und laufen mit Rechner
(Entscheidung Rasit, 30.10.2026, Migration `20261030091351_lsa_taschenrechner`). Bei ihnen wird nur noch das Runden
geprüft; siehe `docs/lsa/lena-rueckmeldungen-2026-10-25.md`, Liste B.

„Wörtlich“ heißt: Der Arbeitsauftrag nennt die Methode selbst. Sonst steht die Aufgabe wegen ihres Skills in der Liste.


## `term_binom_faktorisieren` (2)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `88ca2551-82bf-4ca3-b971-32cd4292a146` | nein | wörtlich | Berechne geschickt mit einer binomischen Formel. 47² - 43² = ? |
| `e4a18d51-9545-4f17-b1aa-10dc72c35cd3` | nein | Skill | Faktorisiere vollständig. Welcher Term ist richtig? 2x² - 18 = ? |

## `term_binom_gemischt` (3)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `79c7a940-7a41-4b6b-b4ff-ce464425c758` | nein | Skill | Multipliziere aus und fasse zusammen. Welcher Term ist richtig? (x + 6)(x - 6) + (x + 2)² = ? |
| `8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24` | nein | wörtlich | Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein. (x + 5)² - (x + 2)(x - 2) = ? |
| `c31fdbb1-9a48-4cd8-9b0c-35393af84330` | nein | Skill | Multipliziere aus und fasse zusammen. Welcher Term ist richtig? (x + 3)² - (x - 3)² = ? |

## `term_binom_quadrat` (5)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13` | nein | wörtlich | Berechne geschickt mit Hilfe einer binomischen Formel. 49² = ? |
| `9a598424-963b-4981-91ad-9a81cead51f4` | nein | Skill | Multipliziere aus. Welcher Term ist richtig? (x - 5)² = ? |
| `ae6fa0b8-283c-4570-b9d2-6271c17e3384` | nein | Skill | Multipliziere aus. Welcher Term ist richtig? (x + 3)² = ? |
| `de60d4ff-c473-4358-b050-85a54dd903a1` | nein | Skill | Multipliziere aus. Welcher Term ist richtig? (2x + 3)² = ? |
| `f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa` | nein | Skill | Schreibe als Quadrat einer Klammer. Welcher Term ist richtig? x² + 20x + 100 = ? |

## `term_binom_quadratdifferenz` (2)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `293413f8-8e31-4f0b-b64e-7ac2a183606e` | nein | Skill | Multipliziere aus. Welcher Term ist richtig? (x + 4)(x - 4) = ? |
| `7e027634-1c45-4c70-8357-198dad0f1797` | nein | wörtlich | Berechne geschickt mit einer binomischen Formel. 102 · 98 = ? |

## `zahl_wurzel_gesetze` (6)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `4f7652bf-34f5-46ce-b17b-54ffd1fdd0d3` | nein | Skill | Ein rechteckiges Feld ist √8 m lang und √18 m breit. Wie groß ist sein Flächeninhalt in Quadratmetern? Gib das Ergebnis exakt an. |
| `760fc0ad-d0c6-4a09-889b-c116a2f0ff78` | nein | Skill | Berechne √50 : √2. Gib das Ergebnis exakt an. |
| `88c99e21-a70e-42e5-b426-07e29b93d3fe` | nein | Skill | Zwei quadratische Beete haben die Flächeninhalte 9 m² und 16 m². Sie sollen durch ein einziges quadratisches Beet ersetzt werden, das genau so groß ist wie beide zusammen. Wie lang ist eine Seite des neuen Beets? Gib das Ergebnis exakt an. |
| `926f4f6e-7eca-43f5-92c2-855eff8167b4` | nein | Skill | Berechne √(36 + 64). Gib das Ergebnis exakt an. |
| `a0a8c04b-145b-4010-8c46-b5c7520d54bb` | nein | Skill | Berechne √2 · √8. Gib das Ergebnis exakt an. |
| `ce24db36-6dac-4b3f-8395-e815549a7689` | nein | Skill | Berechne √(1,44 + 0,81). Gib das Ergebnis exakt an. |

## `zahl_wurzel_irrational` (6)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `0b7e781c-60ae-4a93-afb8-2ee2b400b15a` | nein | Skill | Wie viele der Zahlen 1, 2, 3, …, 60 haben eine Quadratwurzel, die eine rationale Zahl ist? Gib die Anzahl als ganze Zahl an. |
| `54382934-12e4-4819-8dc4-5f4f5650471f` | nein | Skill | Wie viele der folgenden Zahlen sind irrational? √2; √9; 0,5; √5; 3/7 Gib die Anzahl als ganze Zahl an. |
| `834de179-1fbd-4491-9d86-fd572310f3dd` | nein | Skill | Wie viele der folgenden Zahlen sind rational? √16; √12; 0,333… (Periode 3); π; √0,25; −5 Gib die Anzahl als ganze Zahl an. |
| `9935f4bb-1222-4ead-bf3c-6b8cfd134395` | nein | Skill | Schreibe 0,375 als vollständig gekürzten Bruch. Gib den Nenner an. |
| `ae8478c7-f104-407a-a75a-087d71e20757` | nein | Skill | Die Zahl 0,454545… (Periode 45) ist rational. Schreibe sie als vollständig gekürzten Bruch und gib den Nenner an. |
| `d851f251-cbe5-4804-b74d-2458c7a855af` | nein | Skill | Ein Betrieb stellt quadratische Fliesen mit diesen Flächeninhalten her (in cm²): 49; 50; 2,25; 8; 0,64; 12,1 Bei wie vielen dieser Fliesen ist die Seitenlänge in cm eine rationale Zahl? Gib die Anzahl als ganze Zahl an. |

## `zahl_wurzel_naeherung` (6)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `0b9229a0-db38-4fc4-8b64-1213b5198f50` | ja | Skill | Berechne √30. Runde auf zwei Stellen nach dem Komma. |
| `6585552b-bb6b-4345-98cb-d427378cdfed` | nein | Skill | √50 liegt zwischen zwei aufeinanderfolgenden ganzen Zahlen. Gib beide Zahlen an. |
| `81015f65-8ac0-4ef3-abb8-9a7b87c44940` | ja | Skill | Ein quadratischer Teppich soll einen Flächeninhalt von mindestens 6 m² haben. Wie lang muss eine Seite mindestens sein? Gib ganze Zentimeter an und runde dafür auf. |
| `9af2a3ce-78dc-48b8-b5bc-c50b2fc1f9bd` | ja | Skill | Berechne √0,9. Runde auf zwei Stellen nach dem Komma. |
| `cd35f4b2-62da-4f01-9215-bc9504f8e67a` | ja | Skill | Ein quadratisches Beet hat einen Flächeninhalt von 11 m². Wie lang ist eine Seite des Beets? Runde auf zwei Stellen nach dem Komma. |
| `fde9c9a1-f05a-42ff-ab98-d94ee6894d07` | ja | Skill | Berechne √10. Runde auf eine Stelle nach dem Komma. |

## `zahl_wurzel_quadrat` (6)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `16d6e3b7-86f0-4661-b750-70bf5764e3ba` | nein | Skill | Berechne √0,0016. Gib das Ergebnis exakt an. |
| `4b3b14a9-0603-40d7-90b1-60f3517f7348` | nein | Skill | Welche positive Zahl ergibt quadriert 225? Gib das Ergebnis exakt an. |
| `55239bfc-349a-4285-b29e-2b1c105e6033` | nein | Skill | Berechne √0,49. Gib das Ergebnis exakt an. |
| `5f9d6c06-c962-4b38-9096-4a1ab9c97292` | nein | Skill | Ein quadratischer Platz hat einen Flächeninhalt von 1296 m². Er soll ringsum eingezäunt werden. Wie viele Meter Zaun werden gebraucht? Gib das Ergebnis exakt an. |
| `99b7829c-3536-4278-a84e-3dbeea10637c` | nein | Skill | Eine quadratische Tischplatte hat einen Flächeninhalt von 2,25 m². Wie lang ist eine Seite der Tischplatte in Zentimetern? Gib das Ergebnis exakt an. |
| `afc3b977-389b-4e8d-a157-9952b087c8e2` | nein | Skill | Berechne √(9/16). Gib das Ergebnis exakt an. Du kannst einen Bruch oder eine Dezimalzahl eingeben. |

## `zahl_wurzel_teilweise` (6)

| ID | Rechner | Grund | Arbeitsauftrag |
|---|---|---|---|
| `0bcc83c8-42f0-4956-b1d0-00446cb6e5e2` | nein | Skill | Es gilt √72 = a · √2. Bestimme a. a ist eine natürliche Zahl. Gib a exakt an. |
| `1dece473-758d-4108-9969-02b495dbf4ed` | nein | Skill | Es gilt √18 · √6 = a · √3. Bestimme a. a ist eine natürliche Zahl. Gib a exakt an. |
| `21427340-fc85-41c4-abea-99ad0121b83c` | nein | Skill | Es gilt √48 = a · √3. Bestimme a. a ist eine natürliche Zahl. Gib a exakt an. |
| `ad08897e-a44b-43fb-a779-96b889c069db` | nein | Skill | Es gilt √200 = a · √2. Bestimme a. a ist eine natürliche Zahl. Gib a exakt an. |
| `df6b2bcd-8643-46b2-9553-db75854b597d` | nein | Skill | Ein quadratischer Spielplatz hat einen Flächeninhalt von 180 m². Seine Seitenlänge lässt sich exakt als a · √5 m schreiben. Bestimme a. a ist eine natürliche Zahl. Gib a exakt an. |
| `ef90a8ac-bbd4-4c36-9e02-26144cc9d9b0` | nein | Skill | Es gilt 6 · √3 = √b. Bestimme b. b ist eine natürliche Zahl. Gib b exakt an. |
