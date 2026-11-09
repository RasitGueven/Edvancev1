# FR-0 · Bestandsaufnahme Freigabe (LSA, Bauformen, Erklärvideos)

**Stand:** 09.11.2026, Prod per `dbread` (nur lesend), Code auf `origin/dev` @ `b837fc1e`.
**Für:** Rasit, Tolunay, Ashkan · **Auftrag:** FR-0 (Gründerentscheidungen vom 09.11.2026).

Jede Zahl trägt eine Abfrage-Nummer `[Qnn]` aus dem Anhang. Code-Belege mit `Datei:Zeile`. Die Schema-Stellen
beziehen sich auf `supabase/schema-erwartet.sql`, den Abzug von Prod auf `origin/dev`.

---

## 0 · Kurzfassung

1. **Heute läuft für keine Klassenarbeit der Klassen 8–10 eine vollständige LSA.** 0 von 501 abgeleiteten Paketen sind
   LSA-fähig [Q12]. In Klasse 9 startet die Thema-LSA bei 26 von 176 Plan-Themen, in Klasse 10 bei keinem [Q07].
2. **Größter Hebel sind sechs Grundlagen-Skills, die nur am gleichen Aufgabentext scheitern.** `dezimal_add_sub`,
   `dezimal_mult`, `dezimal_div`, `bruch_kuerzen`, `bruch_dezimal` und `term_zusammenfassen` haben 3–4 ready-Aufgaben,
   aber jeweils nur einen Textschlüssel [Q10]. Allein die drei `dezimal_*`-Skills liegen in 501, 476 bzw. 421 der 501
   Pakete [Q18]. Eine LSA-Sitzung
   gibt keine zweite Aufgabe mit gleichem Text aus (LSA-L2, `schema-erwartet.sql:7926`). Deshalb bleibt bei diesen
   Skills der Zweitbeleg aus.
3. **Familien-Erben schaltet nach heutigem Code keinen einzigen Skill frei** [Q24]. Mitglieder einer Familie haben
   denselben Textschlüssel und zählen in einer Sitzung nur einmal. 651 von 887 LSA-Aufgaben sind außerdem
   Einzelgänger [Q21].
4. **Lena muss nicht alle Entwürfe prüfen, sondern nur, was die Pakete brauchen.** Für Klasse 10 fehlen
   92 Aufgabentexte. Bei Lenas Passt-Quote von 80,5 % [Q35] sind das rund 114 Prüfungen bzw. 3,8 Stunden
   [Q36, Abschnitt 8]. Alle 308 betroffenen Entwürfe zu prüfen, dauert 10,3 Stunden [Q26].
5. **Die 47 Bauformen sind noch ungeprüft** (alle `zur_pruefung`, 0 ready) [Q30]. Für die LSA helfen sie nur bei
   7 fehlenden Skills, nämlich den quadratischen Kern-Skills [Q32]. Damit eine Bauform LSA-Instanzen erzeugen kann,
   müssen drei CHECKs und `lsa_im_pool` geändert werden (Abschnitt 5c).
6. **Erklärvideos:** In Prod gibt es eine Sequenz (V1, Entwurf, nur Skelett, keine Freigabe) [Q34]. Mit der neuen
   Regel sinken die Prüfschritte für Reihe 1 von 40 auf 24. Lenas Anteil sinkt von 32 auf 8 (Abschnitt 6b).
   „Prüfer ≠ Autor“ bleibt im Trigger `studio_freigabe_regeln` (`schema-erwartet.sql:22203`).

---

## 1 · LSA-Pool

**Pool `lsa` nach Status** [Q01, Q02]

| Status | Aufgaben | davon ziehbar (`lsa_im_pool`) |
|---|---|---|
| draft | 717 | 0 |
| zur Freigabe (`review`) | 0 | 0 |
| ready | 168 | 166 |
| sonstige (`rueckfrage`) | 2 | 0 |
| **gesamt** | **887** | **166** |

`lsa_im_pool` (`schema-erwartet.sql:8201`) verlangt mehr als `ready`: aktiv, kein Tutorial, `exercise`, vollständige
Lösung, eindeutiges Eingabeformat. Zwei ready-Aufgaben fallen dadurch heraus [Q01].

**Je Format** [Q02]: MC 24 draft / 12 ready · MULTI_PART 87 / 13 · NUMERIC 593 / 136 (+2 Rückfrage) · TERM 13 / 7.

**Je Doppeljahrgang** (Herkunftsklasse des Skills) [Q02]: 5/6: 135 / 37 · 7/8: 276 / 101 (+2) · 9/10: 306 / 30.

**Je Thema** (`skill_thema`) [Q37]: ready-Aufgaben gibt es fast nur in Stufe 5–8 und bei `reelle_zahlen` (30). Alle
übrigen 13 Themen der Stufe 9/10 haben **0 ready** und je 6–30 Entwürfe. Die Tabelle je Skill steht in Anhang B
[Q38].

**Wer hat geprüft und freigegeben?** Die Prüfentscheidungen stehen in `task_pruefungen` (append-only, Trigger
`task_pruefungen_nur_anhaengen`) [Q03, Q04].

- **Lena** hat 163 LSA-Aufgaben mit 174 Entscheidungen geprüft. Letzte Entscheidung: 135 × passt, 28 × unsicher [Q03].
- Ein Testkonto („ZZ Test Coach“) hat eine Entscheidung abgegeben [Q03].
- **Admin-Freigabe:** Alle 168 ready-Aufgaben hat Rasit freigegeben (`reviewed_by`). Bei 136 davon liegt ein
  „passt“ von Lena vor, 32 sind ohne Lenas „passt“ ready [Q04]. Das ist zum Teil der ältere Weg über
  `freigabe_muster`, der ausdrücklich nur Aufgaben ohne Prüfung nimmt (`schema-erwartet.sql:4716`).

---

## 2 · Abdeckung je Klasse

### 2a · Wie die LSA ein Thema auflöst (Code, nicht geraten)

`lsa_select_next_core` (`schema-erwartet.sql:8957`) arbeitet mit zwei verschiedenen Zuordnungen:

| Fall | Skills | Tiefe | Beleg |
|---|---|---|---|
| Thema der Sitzung (Klassenarbeit noch nicht geschrieben) | **`thema_einstieg`**, nicht `skill_thema` | volle transitive Hülle über `skill_kante` (`lsa_abschluss`, ohne Tiefen- und Klassengrenze) | `:9075–9085`, `lsa_abschluss` `:6953` |
| Vorschau (Klassenarbeit geschrieben, `ka_modus = vorschau_zuerst`) | **`skill_thema`** der nächsten 3 Plan-Themen; nie deren eigene Skills, nur der „Rand“ darunter | Rand + Abschluss des Randes, nur `klasse_herkunft ≤ Klasse` | `:8971`, `:9211–9264`, `:9404` |

**Abweichung zum Auftrag:** Der Auftrag nennt `skill_thema` für „Thema → Skills“. Die Thema-LSA nutzt aber
`thema_einstieg`. Nur 22 der 37 Themen haben Einstiegsknoten [Q06]. 17 Skills aus `skill_thema` der Plan-Themen
liegen in keinem Themenraum, darunter `fkt_quadr_extrem` und `gleichung_quadr_anzahl`. Die LSA fragt sie nie direkt
ab [Q33]. In dieser Auswertung gilt der Code: Themenraum = Einstieg ∪ `lsa_abschluss(Einstieg)`.

### 2b · LSA-Regel je Skill

Die Regel „mindestens 2 ready, davon mindestens eine ohne MC“ steht **nicht** in der Auswahl. Sie steht als Daten in
`pruef_soll` (`soll = 2`, `min_ohne_mc = 1`, Anlässe `batu_lsa`, `lsa_vorschau`) und wird im Board über
`pruef_board_soll` gezählt (`schema-erwartet.sql:12535`). Die Auswahl selbst braucht je Knoten **eine** freie Aufgabe
(`lsa_freie_aufgabe`, `:7912`). Eine zweite braucht sie, wenn die erste MC war oder falsch beantwortet wurde
(Zweitbeleg, `:9288`, `:10599–10625`). Daraus folgen drei Abweichungen:

1. Ein richtiges Nicht-MC-Ergebnis ist sofort final (`:10600`). Der Code braucht also keine zwei Aufgaben, wenn die
   erste ohne MC ist und stimmt.
2. **Zwei Aufgaben mit gleichem Textschlüssel zählen in einer Sitzung als eine.** `lsa_text_schluessel` ersetzt
   Zahlen durch `#` (`:10221`). `lsa_freie_aufgabe` schließt jeden schon ausgegebenen Schlüssel aus (`:7926`).
3. „Ready“ heißt im Code `lsa_im_pool`, nicht `status = 'ready'`.

Ausgewertet wird deshalb: **mindestens 2 verschiedene Textschlüssel im Pool und mindestens 1 Pool-Aufgabe ohne MC.**

| | Skills |
|---|---|
| alle Skills | 130 |
| Regel erfüllt | **36** |
| mindestens 1 Aufgabe im Pool | 45 |
| Regel erfüllt, wenn man den Textschlüssel ignoriert | 43 |
| **scheitern nur am gleichen Text** | **7** |

[Q05]

### 2c · Anteil der Themen, für die eine LSA heute vollständig laufen könnte

„Startet“ heißt: Die Thema-LSA kommt zustande (`v_mit_thema`, `:9075`). „Einstieg ok“ heißt: Alle Einstiegsknoten
erfüllen die Regel. „Vollständig“ heißt: Der ganze Themenraum erfüllt die Regel. [Q07]

| Klasse | Quelle | Kombinationen (Schule × Thema) | startet | Einstieg ok | vollständig |
|---|---|---|---|---|---|
| 8 | 30 Schulpläne | 173 | 141 | 117 | **0** |
| 8 | Kernlehrplan | 11 | 7 | 5 | 0 |
| 9 | 28 Schulpläne | 176 | 26 | 26 | **0** |
| 9 | Kernlehrplan | 14 | 1 | 1 | 0 |
| 10 | 25 Schulpläne | 141 | 0 | 0 | **0** |
| 10 | Kernlehrplan | 14 | 1 | 1 | 0 |

Kein einziger Themenraum ist vollständig [Q06]. Die Hülle reicht bis in die Klassen 5/6 hinab, und dort fehlen
die sechs Grundlagen-Skills aus 2d. Je Thema mit Einstiegsknoten [Q09]: Ein Themenraum umfasst 5–28 Skills, davon fehlen 4–16.

<details><summary>Je Schule: startende Themen / Themen im Plan (vollständig) [Q08]</summary>

| Schule | Klasse 8 | Klasse 9 | Klasse 10 |
|---|---|---|---|
| Albertus-Magnus-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Apostelgymnasium | 4/5 (voll 0) | 1/6 (voll 0) | 0/5 (voll 0) |
| Deutzer Gymnasium Schaurtestraße | 5/7 (voll 0) | 1/9 (voll 0) | 0/6 (voll 0) |
| Dreikönigsgymnasium | 5/6 (voll 0) | 1/7 (voll 0) | 0/6 (voll 0) |
| Elisabeth-von-Thüringen-Gymnasium | 4/5 (voll 0) | 1/6 (voll 0) | 0/5 (voll 0) |
| Erich Kästner-Gymnasium | 4/5 (voll 0) | 1/6 (voll 0) | 0/5 (voll 0) |
| Erzbischöfliche Liebfrauenschule | 5/7 (voll 0) | 1/9 (voll 0) | 0/5 (voll 0) |
| Erzbischöfliches Irmgardis-Gymnasium | 4/6 (voll 0) | 0/7 (voll 0) | 0/5 (voll 0) |
| Friedrich-Wilhelm-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Genoveva-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Georg-Büchner-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/5 (voll 0) |
| Gymnasium Köln-Pesch | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Gymnasium Müngersdorf | 5/6 (voll 0) | – | – |
| Gymnasium Rodenkirchen | 5/6 (voll 0) | 1/7 (voll 0) | 0/6 (voll 0) |
| Gymnasium Thusneldastraße | 4/5 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Gymnasium Zusestraße | 4/5 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Hansa-Gymnasium | 5/5 (voll 0) | 1/9 (voll 0) | 0/5 (voll 0) |
| Heinrich-Heine-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/5 (voll 0) |
| Heinrich-Mann-Gymnasium | 3/4 (voll 0) | 0/1 (voll 0) | – |
| Hildegard-von-Bingen-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | – |
| Humboldt-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/5 (voll 0) |
| Kaiserin-Augusta-Schule | 4/5 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Kaiserin-Theophanu-Schule | 5/6 (voll 0) | 1/7 (voll 0) | 0/6 (voll 0) |
| Kernlehrplan | 7/11 (voll 0) | 1/14 (voll 0) | 1/14 (voll 0) |
| Königin-Luise-Schule | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Leonardo-da-Vinci-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | – |
| Lessing-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Maximilian-Kolbe-Gymnasium | 5/6 (voll 0) | – | – |
| Rhein-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Schiller-Gymnasium | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |
| Stadtgymnasium Köln-Porz | 5/6 (voll 0) | 1/6 (voll 0) | 0/6 (voll 0) |

</details>

### 2d · Skills, die die Regel nicht erfüllen, nach Hebel

Hebel = Zahl der Kombinationen (Schule × Klasse × Thema, Klassen 8–10, nur Schulpläne), in deren Themenraum der
Skill liegt. Insgesamt: 107 Skills liegen in mindestens einem Themenraum. 36 davon erfüllen die Regel, 71 nicht.
Hinter diesen 71 stehen 435 Entwürfe, und für jeden der 71 gibt es mindestens einen Entwurf [Q11].

| # | Skill | Kl. | Hebel | im Pool | Texte | ohne MC | draft |
|---|---|---|---|---|---|---|---|
| 1 | dezimal_add_sub | 5 | 485 | 3 | **1** | 3 | 8 |
| 2 | dezimal_mult | 6 | 460 | 3 | **1** | 3 | 6 |
| 3 | dezimal_div | 6 | 380 | 3 | **1** | 3 | 6 |
| 4 | bruch_kuerzen | 6 | 205 | 3 | **1** | 3 | 4 |
| 5 | bruch_dezimal | 6 | 145 | 4 | **1** | 4 | 2 |
| 6 | term_zusammenfassen | 7 | 136 | 3 | **1** | 3 | 4 |
| 7 | geo_pythagoras_hypotenuse | 9 | 84 | 0 | 0 | 0 | 6 |
| 8 | geo_aehnlich_streckfaktor | 9 | 79 | 0 | 0 | 0 | 6 |
| 9 | geo_massstab | 6 | 79 | 0 | 0 | 0 | 11 |
| 10 | geo_kreis_flaeche | 9 | 67 | 0 | 0 | 0 | 6 |
| 11 | geo_kreis_umfang | 9 | 67 | 0 | 0 | 0 | 6 |
| 12 | prozent_prozentwert | 7 | 66 | 0 | 0 | 0 | 9 |
| 13 | term_minusklammer | 7 | 57 | 0 | 0 | 0 | 6 |
| 14 | zahl_potenz_gesetze | 9 | 55 | 0 | 0 | 0 | 6 |
| 15 | zahl_potenz_negativ | 9 | 55 | 0 | 0 | 0 | 6 |
| 16 | geo_trigo_verhaeltnis | 10 | 50 | 0 | 0 | 0 | 6 |
| 17 | gleichung_quadr_formel | 9 | 50 | 0 | 0 | 0 | 6 |
| 18 | gleichung_quadr_wurzel | 9 | 50 | 0 | 0 | 0 | 6 |
| 19 | stoch_bedingt_umkehr | 9 | 39 | 0 | 0 | 0 | 6 |
| 20 | stoch_bedingt_unabhaengig | 9 | 39 | 0 | 0 | 0 | 6 |
| 21 | stoch_bedingt_vierfeld | 9 | 39 | 0 | 0 | 0 | 6 |
| 22 | stoch_bedingt_wkeit | 9 | 39 | 0 | 0 | 0 | 6 |
| 23 | fkt_linear_graph | 8 | 30 | 0 | 0 | 0 | 6 |
| 24 | gleichung_neg_koeffizient | 7 | 30 | 0 | 0 | 0 | 5 |
| 25 | zahl_potenz_rechnen | 9 | 30 | 0 | 0 | 0 | 6 |
| 26 | zahl_potenz_zehner | 9 | 30 | 0 | 0 | 0 | 6 |
| 27 | geo_aehnlich_flaeche | 9 | 29 | 0 | 0 | 0 | 6 |
| 28 | geo_aehnlich_strahlen_abschnitt | 9 | 29 | 0 | 0 | 0 | 6 |
| 29 | geo_aehnlich_strahlen_parallel | 9 | 29 | 0 | 0 | 0 | 6 |
| 30 | fkt_quadr_normalform | 9 | 27 | 0 | 0 | 0 | 6 |

[Q10] Der Hebel kann die Zahl der Kombinationen (490) fast erreichen, weil die Grundlagen-Skills in fast jedem
Themenraum liegen.

---

## 3 · Pakete je Klassenarbeit

### Wie `schul_themenplan` Klassenarbeiten abbildet

- `schul_themenplan` (Schule, Fach, Klasse, `position`, `thema_key`, `uv_titel`, `stunden`, `halbjahr`) kennt **keine
  Klassenarbeit**. `halbjahr` ist in 17 von 505 Zeilen der Klassen 8–10 gesetzt (nur Heinrich-Heine-Gymnasium),
  `stunden` in 363 Zeilen [Q40].
- `schul_klassenarbeiten` (bestätigte Folge je Schule) ist **leer**. `lead_klassenarbeiten` hat 3 Zeilen von
  3 Leads [Q40]. `ka_folge_schule_roh` leitet die Folge erst ab, wenn mindestens zwei Kinder einer Schule übereinstimmen
  (`schema-erwartet.sql:5735`).

**Annahmen (für die ganze Auswertung):**

- **A1:** Ein Unterrichtsvorhaben (Planzeile mit Thema) entspricht einer Klassenarbeit. Das ergibt 501 Pakete
  (176 / 176 / 149 für die Klassen 8 / 9 / 10) [Q12].
- **A2:** Die Lage im Schuljahr ergibt sich aus `halbjahr`, wenn gesetzt. Sonst aus den kumulierten `stunden`, wenn die
  Klasse sie vollständig hat. Sonst aus der Position.
- **A3:** Das Schuljahr läuft linear von 1.9. bis 30.6. Ein Quartal ist ein Viertel davon, und ein Paket zählt zum
  Quartal seiner Mitte. Das Fenster Feb–März 2027 entspricht dem Anteil [0,5; 0,7). Ein Vorhaben „läuft im Fenster“,
  wenn es diesen Bereich schneidet.
- **A4:** Paket = Themenraum des Themas (Fall „Arbeit noch nicht geschrieben“) ∪ Vorschau-Rand des Themas (Fall
  „geschrieben“: Hülle der `skill_thema`-Skills ohne die Skills von Themen, die ab dieser Arbeit noch kommen,
  `klasse_herkunft ≤ Klasse`). Das entspricht der Code-Tiefe aus 2a. Der Code nimmt in der Vorschau drei kommende
  Themen (`:8971`), das Paket nimmt nur das eine Thema der Arbeit.
- „LSA-fähig“ heißt: Jeder Skill des Pakets erfüllt die Regel aus 2b, und das Thema hat Einstiegsknoten.

### 3a/3b · Pakete je Klasse [Q12]

| Klasse | Pakete | Skills je Paket (Ø / min / max) | davon Regel erfüllt (Ø, Anteil) | LSA-fähig | nur Thema-Teil fähig | nur Vorschau-Teil fähig |
|---|---|---|---|---|---|---|
| 8 | 176 | 15,0 / 6 / 25 | 8,5 (56,7 %) | **0** | 0 | 0 |
| 9 | 176 | 15,6 / 8 / 26 | 8,0 (51,1 %) | **0** | 0 | 0 |
| 10 | 149 | 20,8 / 11 / 28 | 9,3 (44,6 %) | **0** | 0 | 0 |
| **gesamt** | **501** | 16,9 / 6 / 28 | 8,5 (50,5 %) | **0** | 0 | 0 |

Selbst der Vorschau-Teil scheitert überall, weil er bis zu den Grundlagen der Klassen 5/6 reicht.

### 3c · Bündelung nach Zeitfenster (Quartal), über alle Schulen [Q13, Q14]

| Klasse | Q1 | Q2 | Q3 | Q4 |
|---|---|---|---|---|
| 8 · Pakete / fähig / fehlend (Median, min) | 40 / 0 / 5, 4 | 46 / 0 / 4, 4 | 44 / 0 / 5, 4 | 46 / 0 / 6, 4 |
| 9 | 35 / 0 / 5, 5 | 39 / 0 / 11, 5 | 48 / 0 / 9, 5 | 54 / 0 / 8, 6 |
| 10 | 37 / 0 / 10, 7 | 36 / 0 / 8, 7 | 37 / 0 / 16, 8 | 39 / 0 / 14, 10 |

Kein Paket kommt mit 3 oder weniger fehlenden Skills aus [Q13]. Die fehlenden Skills je Fenster, sortiert nach der
Zahl der Pakete, in denen sie fehlen (Top 5 von 8 in [Q14]):

| Klasse · Quartal | fehlende Skills (Pakete) |
|---|---|
| 8 · Q1 | dezimal_add_sub 40, dezimal_mult 37, dezimal_div 33, bruch_kuerzen 29, bruch_add 17 |
| 8 · Q2 | dezimal_add_sub 46, dezimal_mult 46, term_zusammenfassen 30, term_minusklammer 24, dezimal_div 23 |
| 8 · Q3 | dezimal_add_sub 44, dezimal_div 44, dezimal_mult 44, term_zusammenfassen 33, bruch_kuerzen 26 |
| 8 · Q4 | dezimal_add_sub 46, dezimal_mult 24, dezimal_div 22, geo_winkel_dreieck 22, geo_winkel_neben_scheitel 22 |
| 9 · Q1 | dezimal_add_sub 35, dezimal_mult 35, dezimal_div 32, bruch_dezimal 26, bruch_kuerzen 26 |
| 9 · Q2 | dezimal_add_sub 39, dezimal_mult 39, dezimal_div 36, gleichung_quadr_formel 21, gleichung_quadr_wurzel 21 |
| 9 · Q3 | dezimal_add_sub 48, dezimal_mult 48, dezimal_div 47, bruch_dezimal 21, bruch_kuerzen 21 |
| 9 · Q4 | dezimal_add_sub 54, dezimal_mult 54, dezimal_div 35, bruch_dezimal 30, bruch_kuerzen 30 |
| 10 · Q1 | dezimal_add_sub 37, dezimal_div 37, dezimal_mult 37, bruch_kuerzen 21, bruch_dezimal 20 |
| 10 · Q2 | dezimal_add_sub 36, dezimal_div 36, dezimal_mult 36, geo_aehnlich_streckfaktor 21, geo_massstab 21 |
| 10 · Q3 | dezimal_add_sub 37, dezimal_div 37, dezimal_mult 37, bruch_kuerzen 36, bruch_dezimal 21 |
| 10 · Q4 | dezimal_add_sub 39, dezimal_div 39, dezimal_mult 39, geo_aehnlich_streckfaktor 32, geo_massstab 32 |

### 3d · Sonderauswertung Feb–März 2027, Klassen 9 und 10

Fall A = das Vorhaben, das im Fenster läuft (Arbeit noch nicht geschrieben, Themenraum). Fall B = das nächste
Vorhaben danach (Arbeit geschrieben, Vorschau-Rand der nächsten Arbeit). [Q16]

| Klasse | Fall | Pakete | Schulen | Themen |
|---|---|---|---|---|
| 9 | A | 58 | 28 | aehnlichkeit, kreis, potenzen, prismen_zylinder, pythagoras, quadratische_funktionen, quadratische_gleichungen |
| 9 | B | 27 | 27 | aehnlichkeit, bedingte_wahrscheinlichkeit, potenzen, prismen_zylinder, pythagoras |
| 10 | A | 51 | 25 | aehnlichkeit, bedingte_wahrscheinlichkeit, exponentialfunktionen, trigonometrie |
| 10 | B | 25 | 25 | bedingte_wahrscheinlichkeit, exponentialfunktionen, sinusfunktion, trigonometrie |

**Was fehlt, damit an allen hinterlegten Schulen eine LSA zur anstehenden Arbeit möglich ist** [Q39]:
In Klasse 9 fehlen 32 Skills (197 Entwürfe, 7 davon haben eine Bauform). In Klasse 10 fehlen 33 Skills (211 Entwürfe,
keiner hat eine Bauform). Zusammen sind es **49 Skills mit 308 Entwürfen**. Sechs davon scheitern nur am gleichen
Text.

<details><summary>Je fehlendem Skill: Pakete, Schulen, Fall, Entwürfe, Bauformen [Q15]</summary>

| Kl. | Skill | Herk. | Pakete | Schulen | Fall | im Pool | Texte | draft | Bauformen |
|---|---|---|---|---|---|---|---|---|---|
| 9 | dezimal_add_sub | 5 | 85 | 28 | AB | 3 | 1 | 8 | – |
| 9 | dezimal_mult | 6 | 85 | 28 | AB | 3 | 1 | 6 | – |
| 9 | dezimal_div | 6 | 50 | 28 | AB | 3 | 1 | 6 | – |
| 9 | bruch_dezimal | 6 | 31 | 25 | AB | 4 | 1 | 2 | – |
| 9 | bruch_kuerzen | 6 | 31 | 25 | AB | 3 | 1 | 4 | – |
| 9 | zahl_potenz_gesetze | 9 | 23 | 23 | A | 0 | 0 | 6 | – |
| 9 | zahl_potenz_negativ | 9 | 23 | 23 | A | 0 | 0 | 6 | – |
| 9 | zahl_potenz_rechnen | 9 | 23 | 23 | A | 0 | 0 | 6 | – |
| 9 | zahl_potenz_zehner | 9 | 23 | 23 | A | 0 | 0 | 6 | – |
| 9 | geo_kreis_flaeche | 9 | 22 | 20 | AB | 0 | 0 | 6 | – |
| 9 | geo_kreis_umfang | 9 | 22 | 20 | AB | 0 | 0 | 6 | – |
| 9 | gleichung_quadr_formel | 9 | 8 | 7 | A | 0 | 0 | 6 | PQ-1…4 |
| 9 | gleichung_quadr_wurzel | 9 | 8 | 7 | A | 0 | 0 | 6 | WZ-1…5 |
| 9 | term_zusammenfassen | 7 | 8 | 7 | A | 3 | 1 | 4 | – |
| 9 | geo_volumen_quader | 6 | 7 | 7 | AB | 0 | 0 | 9 | – |
| 9 | geo_pythagoras_abstand | 9 | 6 | 6 | A | 0 | 0 | 6 | – |
| 9 | geo_pythagoras_hypotenuse | 9 | 6 | 6 | A | 0 | 0 | 6 | – |
| 9 | geo_pythagoras_kathete | 9 | 6 | 6 | A | 0 | 0 | 6 | – |
| 9 | geo_pythagoras_umkehrung | 9 | 6 | 6 | A | 0 | 0 | 6 | – |
| 9 | prozent_prozentwert | 7 | 6 | 6 | B | 0 | 0 | 9 | – |
| 9 | fkt_quadr_normalform | 9 | 5 | 5 | A | 0 | 0 | 6 | NF-1…6 |
| 9 | fkt_quadr_nullstellen | 9 | 5 | 5 | A | 0 | 0 | 6 | NS-1…5 |
| 9 | fkt_quadr_parabel | 9 | 5 | 5 | A | 0 | 0 | 6 | PAR-1…5 |
| 9 | fkt_quadr_scheitel | 9 | 5 | 5 | A | 0 | 0 | 6 | SCH-1…4 |
| 9 | geo_koerper_prisma | 9 | 5 | 5 | A | 0 | 0 | 6 | – |
| 9 | geo_koerper_zylinder | 9 | 5 | 5 | A | 0 | 0 | 6 | – |
| 9 | geo_massstab | 6 | 4 | 4 | AB | 0 | 0 | 11 | – |
| 9 | gleichung_quadr_faktor | 9 | 3 | 3 | A | 0 | 0 | 6 | NP-1…4 |
| 9 | geo_aehnlich_flaeche | 9 | 1 | 1 | A | 0 | 0 | 6 | – |
| 9 | geo_aehnlich_strahlen_abschnitt | 9 | 1 | 1 | A | 0 | 0 | 6 | – |
| 9 | geo_aehnlich_strahlen_parallel | 9 | 1 | 1 | A | 0 | 0 | 6 | – |
| 9 | geo_aehnlich_streckfaktor | 9 | 1 | 1 | A | 0 | 0 | 6 | – |
| 10 | dezimal_add_sub | 5 | 76 | 25 | AB | 3 | 1 | 8 | – |
| 10 | dezimal_div | 6 | 76 | 25 | AB | 3 | 1 | 6 | – |
| 10 | dezimal_mult | 6 | 76 | 25 | AB | 3 | 1 | 6 | – |
| 10 | geo_aehnlich_streckfaktor | 9 | 45 | 24 | AB | 0 | 0 | 6 | – |
| 10 | geo_massstab | 6 | 45 | 24 | AB | 0 | 0 | 11 | – |
| 10 | geo_pythagoras_hypotenuse | 9 | 42 | 24 | AB | 0 | 0 | 6 | – |
| 10 | geo_trigo_verhaeltnis | 10 | 40 | 22 | AB | 0 | 0 | 6 | – |
| 10 | bruch_kuerzen | 6 | 33 | 25 | AB | 3 | 1 | 4 | – |
| 10 | bruch_dezimal | 6 | 31 | 25 | AB | 4 | 1 | 2 | – |
| 10 | prozent_prozentwert | 7 | 31 | 25 | AB | 0 | 0 | 9 | – |
| 10 | prozent_grundwert | 7 | 26 | 24 | AB | 0 | 0 | 11 | – |
| 10 | prozent_veraenderung | 7 | 26 | 24 | AB | 0 | 0 | 10 | – |
| 10 | prozent_zins_jahreszins | 7 | 26 | 24 | AB | 0 | 0 | 6 | – |
| 10 | prozent_zins_zinseszins | 7 | 26 | 24 | AB | 0 | 0 | 6 | – |
| 10 | zahl_potenz_gesetze | 9 | 26 | 24 | AB | 0 | 0 | 6 | – |
| 10 | zahl_potenz_negativ | 9 | 26 | 24 | AB | 0 | 0 | 6 | – |
| 10 | fkt_exp_gleichung | 10 | 25 | 24 | A | 0 | 0 | 6 | – |
| 10 | fkt_exp_halbwert | 10 | 25 | 24 | A | 0 | 0 | 6 | – |
| 10 | fkt_exp_term | 10 | 25 | 24 | A | 0 | 0 | 6 | – |
| 10 | fkt_exp_wachstum | 10 | 25 | 24 | A | 0 | 0 | 6 | – |
| 10 | geo_trigo_kosinussatz | 10 | 21 | 21 | A | 0 | 0 | 6 | – |
| 10 | geo_trigo_seite | 10 | 21 | 21 | A | 0 | 0 | 6 | – |
| 10 | geo_trigo_winkel | 10 | 21 | 21 | A | 0 | 0 | 6 | – |
| 10 | geo_kreis_flaeche | 9 | 19 | 19 | B | 0 | 0 | 6 | – |
| 10 | geo_kreis_sektor | 9 | 19 | 19 | B | 0 | 0 | 6 | – |
| 10 | geo_kreis_umfang | 9 | 19 | 19 | B | 0 | 0 | 6 | – |
| 10 | geo_aehnlich_flaeche | 9 | 3 | 3 | A | 0 | 0 | 6 | – |
| 10 | geo_aehnlich_strahlen_abschnitt | 9 | 3 | 3 | A | 0 | 0 | 6 | – |
| 10 | geo_aehnlich_strahlen_parallel | 9 | 3 | 3 | A | 0 | 0 | 6 | – |
| 10 | stoch_bedingt_umkehr | 9 | 2 | 2 | A | 0 | 0 | 6 | – |
| 10 | stoch_bedingt_unabhaengig | 9 | 2 | 2 | A | 0 | 0 | 6 | – |
| 10 | stoch_bedingt_vierfeld | 9 | 2 | 2 | A | 0 | 0 | 6 | – |
| 10 | stoch_bedingt_wkeit | 9 | 2 | 2 | A | 0 | 0 | 6 | – |

</details>

### 3e · Überschneidung [Q17, Q18]

Alle 109 Skills, die in Paketen vorkommen, liegen in mindestens 2 Paketen (100 %). 47 davon liegen in 50 oder mehr
Paketen [Q17]. Die 20 Skills mit den meisten Paketen [Q18]:

| Skill | Pakete | Regel | im Pool | Texte | draft |
|---|---|---|---|---|---|
| dezimal_add_sub | 501 | nein | 3 | 1 | 8 |
| dezimal_mult | 476 | nein | 3 | 1 | 6 |
| dezimal_div | 421 | nein | 3 | 1 | 6 |
| potenzen | 407 | ja | 19 | 8 | 5 |
| vorzeichen_add_sub | 407 | ja | 7 | 3 | 0 |
| vorzeichen_mult_div | 407 | ja | 7 | 6 | 0 |
| vorzeichen_vorrang | 266 | ja | 3 | 2 | 6 |
| term_einsetzen | 263 | ja | 3 | 3 | 3 |
| bruch_kuerzen | 246 | nein | 3 | 1 | 4 |
| proportionalitaet | 245 | ja | 2 | 2 | 15 |
| gleichung_einschrittig | 228 | ja | 2 | 2 | 4 |
| geo_koordinaten | 196 | ja | 3 | 3 | 3 |
| zahl_wurzel_quadrat | 164 | ja | 5 | 4 | 0 |
| bruch_dezimal | 156 | nein | 4 | 1 | 2 |
| term_ausmultiplizieren | 138 | ja | 4 | 3 | 3 |
| term_zusammenfassen | 138 | nein | 3 | 1 | 4 |
| groessen_laengen | 124 | ja | 2 | 2 | 7 |
| runden_ueberschlag | 124 | ja | 10 | 3 | 3 |
| fkt_linear_steigung | 118 | ja | 2 | 2 | 4 |
| gleichung_zweischrittig | 113 | ja | 4 | 2 | 2 |

Die Überschneidung ist der Grund, Pakete nicht einzeln abzuarbeiten. Ein Grundlagen-Skill gilt für fast alle Pakete
zugleich.

### 3f · Klasse 10 vollständig (alle 149 Pakete, 25 Schulen) [Q19, Q20]

- **49 fehlende Skills** mit 308 Entwürfen. Für jeden gibt es mindestens einen Entwurf. 43 haben keine Aufgabe im
  Pool, 6 eine im Pool, aber nur einen Text [Q19].
- Nach Herkunftsklasse: 12 aus Klasse 10, 24 aus Klasse 9, 13 aus Klasse 8 oder früher [Q19].
- Nur 3 der 49 haben eine Bauform (NP, PQ, WZ) [Q19].
- Zum Vergleich je Klasse: Klasse 8 fehlen 34 Skills (213 Entwürfe), Klasse 9 38 (233), Klassen 8–10 zusammen
  73 Skills (453 Entwürfe) [Q20].
- Bis zur Regel fehlen für Klasse 10 **92 Aufgabentexte**, für die Klassen 8–10 137 [Q36].

Liste Klasse 10 (Entwürfe in Klammern) [Q19]: fkt_exp_gleichung (6), fkt_exp_halbwert (6), fkt_exp_term (6),
fkt_exp_wachstum (6), fkt_sinus_bogenmass (6), fkt_sinus_einheitskreis (6), fkt_sinus_graph (6),
fkt_sinus_parameter (6), geo_trigo_kosinussatz (6), geo_trigo_seite (6), geo_trigo_verhaeltnis (6),
geo_trigo_winkel (6), geo_aehnlich_flaeche (6), geo_aehnlich_strahlen_abschnitt (6),
geo_aehnlich_strahlen_parallel (6), geo_aehnlich_streckfaktor (6), geo_koerper_kegel (6), geo_koerper_kugel (6),
geo_koerper_prisma (6), geo_koerper_pyramide (6), geo_koerper_zylinder (6), geo_kreis_flaeche (6),
geo_kreis_sektor (6), geo_kreis_umfang (6), geo_pythagoras_hypotenuse (6), gleichung_quadr_faktor (6),
gleichung_quadr_formel (6), gleichung_quadr_wurzel (6), stoch_bedingt_umkehr (6), stoch_bedingt_unabhaengig (6),
stoch_bedingt_vierfeld (6), stoch_bedingt_wkeit (6), zahl_potenz_gesetze (6), zahl_potenz_negativ (6),
zahl_potenz_rechnen (6), zahl_potenz_zehner (6), prozent_grundwert (11), prozent_prozentwert (9),
prozent_veraenderung (10), prozent_zins_jahreszins (6), prozent_zins_zinseszins (6), term_zusammenfassen (4),
bruch_dezimal (2), bruch_kuerzen (4), dezimal_div (6), dezimal_mult (6), geo_massstab (11), geo_volumen_quader (9),
dezimal_add_sub (8).

---

## 4 · Aufgabenfamilien im LSA-Pool

**Schlüssel wie vorgegeben:** skill_key + Format + normalisierter Text + Menge der Fehlbild-Schlüssel aus
`acceptance.known_errors` + Figurengenerator. Der normalisierte Text entsteht aus Frage und Teil-Prompts: Zahlen
werden durch `#` ersetzt, Leerraum vereinheitlicht, alles klein geschrieben. Die Fehlbild-Schlüssel sind die Slugs,
nicht die falschen Antworten. Der Figurengenerator kommt aus `task_figures.generator`, ist bei LSA-Aufgaben aber nie
gesetzt. Grundlage: alle 887 LSA-Aufgaben.

**Größenverteilung** [Q21]

| Größe | Familien | Aufgaben |
|---|---|---|
| 1 (Einzelgänger) | **651** | 651 |
| 2 | 37 | 74 |
| 3–4 | 25 | 83 |
| 5–9 | 14 | 79 |

76 Familien haben 2 oder mehr Mitglieder. Ohne Fehlbild-Schlüssel wären es ebenfalls 76 Familien, aber mit
258 statt 236 Aufgaben [Q23]. Die Fehlbilder trennen also wenig.

**Erbfähigkeit der Entwürfe** [Q22]

| Lage der Familie | Familien mit Entwurf | Entwürfe |
|---|---|---|
| sofort erbfähig (≥ 2 Mitglieder von Lena geprüft und ready) | 8 | **20** |
| ein Beispiel fehlt (genau 1 geprüft und ready) | 14 | 26 |
| kein geprüftes Mitglied | 603 | 671 |

**Wie viele Skills aus 2d und 3d würden allein durch Erben LSA-fähig? Keiner** [Q24]. Die 20 erbfähigen Entwürfe
gehören zu bruch_dezimal, bruch_kuerzen, dezimal_add_sub, dezimal_div, dezimal_mult, gleichung_beidseitig,
gleichung_zweischrittig und term_zusammenfassen. Jeder davon teilt den Textschlüssel seiner geprüften Geschwister.
Mehr ready-Aufgaben desselben Textes bringen in einer Sitzung keinen Zweitbeleg (2b, Punkt 2).

**Obergrenze ohne Erben:** Würden alle Entwürfe mit gültiger Lösung ready, erfüllten 121 von 129 Skills mit
LSA-Aufgaben die Regel [Q25]. Für 7 fehlende Skills reicht auch das nicht, weil alle ihre Aufgaben denselben Text
haben: bruch_add, bruch_dezimal, bruch_kuerzen, bruch_mult, gleichung_beidseitig, gleichung_neg_koeffizient,
term_minusklammer [Q27]. Zwei davon (bruch_dezimal, bruch_kuerzen) betreffen Klasse 10.

### Beispielfamilien (vollständige Texte) [Q29]

1. **potenzen · NUMERIC · „Berechne. #² = ?“** · Fehlbilder basis_exponent_vertauscht, mal_exponent · 5 Mitglieder,
   alle ready, alle von Lena geprüft: 3² = ? · 5² = ? · 6² = ? · 7² = ? · 10² = ?
2. **bruch_kuerzen · NUMERIC · „Kürze den Bruch vollständig. #/# = ?“** · additiv_gekuerzt, teilgekuerzt ·
   3 ready (4/12, 8/12, 18/24), 4 Entwürfe (12/16, 20/24, 16/24, 12/18).
3. **dezimal_mult · NUMERIC · „Berechne. # · # = ?“** · komma_ignoriert, kommastellen_zu_viel, kommastellen_zu_wenig ·
   3 ready (0,3 · 0,4; 0,2 · 0,7; 0,6 · 0,4), 3 Entwürfe (0,5 · 0,6; 0,8 · 0,5; 0,9 · 0,3).
4. **geo_flaeche_dreieck · NUMERIC · „Ein Dreieck hat die Grundseite # cm und die zugehörige Höhe # cm. Eine weitere
   Seite ist # cm lang. Wie groß ist die Fläche in cm²?“** · falsche_hoehe, halbieren_vergessen · 1 ready (6/8/5),
   3 Entwürfe (12/5/8, 10/4/7, 8/6/7).
5. **runden_ueberschlag · NUMERIC · „Runde auf eine Nachkommastelle. # = ?“** · abgeschnitten, falsche_stelle ·
   4 ready: 2,85 · 4,45 · 9,25 · 3,47 (alle runden **auf**).

### Grenzfälle

- **G1 · gleichung_beidseitig, „Löse die Gleichung. Gib den Wert für x an. #x + # = #x + #“:** Eine Familie mit
  7 Mitgliedern. Bei 6x + 2 = 5x + 8 und 4x + 3 = 3x + 11 ist der x-Koeffizient nach dem Zusammenführen 1, also gibt
  es keinen Divisionsschritt (AFB I). Bei 5x + 5 = 3x + 25, 6x + 4 = 2x + 28 und 7x + 2 = 3x + 30 kommt ein
  Divisionsschritt dazu (AFB II). Fachlich sind das zwei Stufen. Der Schlüssel trennt sie nicht, obwohl `afb` es schon
  zeigt.
- **G2 · dezimal_add_sub, „Berechne. # + # = ?“:** Zwei Familien mit gleichem Text werden über die Fehlbilder
  getrennt: `stellenwert_ignoriert` (0,25 + 0,4) gegen `uebertrag_vergessen` (0,6 + 0,4). Die Trennung ist richtig.
  Aber 0,9 + 0,35 = 1,25 steht in der Stellenwert-Familie und hat zugleich einen Übertrag über die Eins, ist also
  fachlich gemischt. Und beide Familien teilen den LSA-Textschlüssel: In der Sitzung gilt nur eine von beiden.
- Gegenbeispiel, das trägt: Bei **runden_ueberschlag** trennt die Fehlbild-Menge „aufrunden“ (2,85 → 2,9) von
  „abrunden“ (3,71 → 3,7, Fehlbild immer_aufgerundet). Bei **vorzeichen_add_sub** trennt der Text selbst
  „-# - #“ (−3 − 5) von „# - #“ (3 − 8), weil das Minus vor der Zahl im Text stehen bleibt.

**Merkmale, die die Gruppierung schärfen:** (1) AFB, (2) Vorzeichenmuster je Zahl und des Ergebnisses
(negativ ja/nein), (3) Zahlart je Platzhalter (ganz, Dezimal mit Stellenzahl, Bruch), (4) Ergebnis-Eigenschaften
(ganzzahlig, > 1, gekürzt), (5) bei Gleichungen der Koeffizient nach dem Zusammenführen (= 1 heißt kein
Divisionsschritt), (6) Übertrag oder Stellenwertwechsel, (7) `sondierrang`, weil er die Rolle in der Auswahl
festlegt. (1) und (7) stehen schon in `tasks`. (2)–(6) müsste ein Rechner aus den Zahlen ableiten, wie es die
Bauform-Stufen tun.

### Prüft die LSA heute schon eine „grüne Prüfmaschine“?

| Prüfung | LSA-Aufgabe heute | Bauform (Konzept §5) |
|---|---|---|
| Unabhängig nachgerechnet | Blindlöser über `tools/verify-tasks.mjs` (Stufe 2, LLM oder Subagent per `--answers-from`), nur auf Anstoß, Ergebnis nicht gespeichert | sympy aus dem fertigen Text, für jede Instanz, Ergebnis in `tasks.pruefmaschine` |
| Struktur | `verify-tasks.mjs` Stufe 1: Lösung da, Skill gesetzt, Text nicht leer, wortgleiche Dublette (`tools/verify-tasks.mjs:143–170`); Gate beim Freigeben `freigabe_gate_fehler` (`schema-erwartet.sql:4687`) | ja |
| Angenehme Zahlen je Stufe | nein | ja (§5.2) |
| Fehlbilder durchgespielt (eindeutig, ≠ richtig) | teilweise: `pruef_auffaelligkeiten` meldet `fehler_als_richtig`, `mc_ablenker_ohne_fehlbild`, `werte_widersprechen` u. a. in Lenas Ansicht (`schema-erwartet.sql:12262`), kein Gate | ja (§5.3) |
| Wertung getestet in allen Schreibweisen | nur von Hand: `pruef_wertung_testen` (`schema-erwartet.sql:13887`) | ja, über `lsa_grade` / `wertung_testen` (§5.4) |
| Schreibweise („+ −3x“, „1x²“) | nein | ja (§5.5) |
| Figur nachgemessen | nicht nötig (keine Figuren im LSA-Pool) | ja (§5.6) |
| Dubletten | nur wortgleich (Stufe 1) | gleiche Zahlen bei gleichem Skill, auch gegen LSA (`scripts/bauformen/pruefmaschine.py:226–251`) |
| Ergebnis an der Aufgabe | **nein**: `tasks.pruefmaschine` ist bei allen 887 LSA-Aufgaben leer [Q41] | ja: `instanz_gruen` (`schema-erwartet.sql:5538`) |

**Reicht das für das Erben?** Nein. Es fehlt ein gespeichertes, je Aufgabe wiederholbares Prüfergebnis
(`pruefmaschine` + `instanz_gruen`) mit Nachrechnen, Fehlbild-Durchspiel und Wertungstest. Ohne dieses Ergebnis
kann `freigabe_*` nicht entscheiden, ob ein Mitglied „grün“ ist. Der einfachste Weg ist eine klassische
Prüfmaschine für Bestandsaufgaben: `scripts/bauformen/klassisch.py` gibt es schon für die Wertung
(`pruefmaschine.py:176`), sie müsste das Ergebnis in `tasks.pruefmaschine` schreiben.

---

## 5 · Bauformen

### 5a · Stand der 47 Bauformen [Q30, Q31]

| Status | Bauformen | Blindlöser bestanden | Lena entschieden | Admin freigegeben | Instanzen | ready | nicht grün |
|---|---|---|---|---|---|---|---|
| zur_pruefung | 47 | 47 | **0** | 0 | 2429 | **0** | 0 |

Die Prüfmaschine ist für alle 2429 Instanzen der aktuellen Version grün [Q30]. Instanzen je Rolle, alle im Pool
`session` [Q31]:

| Gruppe | Skill | Bauformen | Instanzen je Rolle |
|---|---|---|---|
| AUS | term_ausklammern | 1 | home 24, uebung 23, warmup 24 |
| BIN | term_binom_quadrat | 2 | home 27, uebung 31, warmup 32 |
| DI | gleichung_quadr_anzahl | 3 | beispiel 16, generalprobe 62, home 24, recap 40, transfer 20, uebung 32, warmup 32 |
| EIN | term_einsetzen | 1 | home 24, uebung 23, warmup 24 |
| EX | fkt_quadr_extrem | 4 | beispiel 16, generalprobe 43, home 24, transfer 39, uebung 24, warmup 24 |
| GL | gleichung_zweischrittig | 1 | home 24, uebung 24, warmup 24 |
| KO | geo_koordinaten | 1 | home 21, uebung 21, warmup 22 |
| NF | fkt_quadr_normalform | 6 | beispiel 8, generalprobe 84, home 38, recap 16, transfer 31, uebung 95, warmup 23 |
| NP | gleichung_quadr_faktor | 4 | beispiel 26, generalprobe 44, home 34, recap 8, transfer 16, uebung 46, warmup 15 |
| NS | fkt_quadr_nullstellen | 5 | beispiel 23, generalprobe 58, home 31, recap 21, transfer 8, uebung 67, warmup 16 |
| PAR | fkt_quadr_parabel | 5 | beispiel 9, generalprobe 18, home 34, recap 22, transfer 40, uebung 71, warmup 25 |
| PQ | gleichung_quadr_formel | 4 | beispiel 16, generalprobe 48, home 48, recap 23, transfer 15, uebung 72, warmup 32 |
| QW | zahl_wurzel_quadrat | 1 | home 13, uebung 12, warmup 15 |
| SCH | fkt_quadr_scheitel | 4 | beispiel 15, generalprobe 84, home 24, recap 24, transfer 48, uebung 56, warmup 32 |
| WZ | gleichung_quadr_wurzel | 5 | beispiel 6, generalprobe 48, home 22, recap 8, transfer 24, uebung 45, warmup 8 |

### 5b · Welche Bauformen betreffen fehlende LSA-Skills? [Q32]

- **Die Voraussetzungs-Bauformen BIN, AUS, EIN, QW, KO, GL betreffen keinen fehlenden Skill.** term_binom_quadrat,
  term_ausklammern, term_einsetzen, zahl_wurzel_quadrat, geo_koordinaten und gleichung_zweischrittig erfüllen die
  LSA-Regel schon.
- In 2d/3d fehlen **NF, NS, PAR, SCH, NP, PQ, WZ** (fkt_quadr_normalform/-nullstellen/-parabel/-scheitel in je
  27 Paketen; gleichung_quadr_faktor in 23, gleichung_quadr_formel und gleichung_quadr_wurzel in je 50).
- **DI und EX** (gleichung_quadr_anzahl, fkt_quadr_extrem) liegen in keinem Paket. Die LSA fragt diese Skills nie
  direkt ab (2a, [Q33]).

### 5c · Was sich ändern müsste, damit eine Bauform LSA-Instanzen erzeugt (nur Beschreibung)

| Stelle | Heute | Nötig |
|---|---|---|
| CHECK `tasks_bauform_instanz` (`schema-erwartet.sql:12230`) | eine Instanz hat `einsatz = {session}` | `einsatz = {session}` **oder** `{lsa}` (genau eins) |
| CHECK `tasks_rolle_check` (`:12250`), `bauformen_rollen_check` (`:25930`) | 7 Session-Rollen | Rolle `lsa` dazu |
| CHECK `tasks_einsatz_ein_pool` (`:12237`) | nie `lsa` und `session` zugleich | **bleibt unverändert und hält die Pool-Trennung weiter** (je Zeile ein Pool). Dazu braucht es eine Regel „Rolle lsa ⇔ Pool lsa“, damit eine Instanz der Rolle lsa nie im Pool session landet |
| Generator `scripts/bauformen/basis.py:27` (`ROLLEN`), `:140` (`stufen_der_rolle`) | keine Rolle lsa | Rolle lsa nur für Stufen mit AFB I–II, also Stufe 1–4. Die AFB setzt heute `export.py:253` (`transfer` → III, Stufe ≤ 2 → I, sonst II) |
| Export `scripts/bauformen/export.py:309` | `einsatz` fest `'{session}'` | Rolle lsa → `'{lsa}'`. Hinweise leer lassen (`hints = []`), `sondierrang` je Stufe setzen. Die Prüfmaschine braucht ein neues Kriterium „keine Hinweise“ |
| Prüfmaschine Punkt 7 (`scripts/bauformen/pruefmaschine.py:226–251`) | Dublette nur gegen LSA-Aufgaben (gleiche Zahlenfolge) | für Rolle lsa auch gegen die **Session-Instanzen** aller Rollen derselben Bauform prüfen, umgekehrt Session gegen lsa. Damit gibt es keine Dublette zwischen den Pools |
| LSA-Auswahl `lsa_im_pool` (`schema-erwartet.sql:8201`) | prüft nur Status, Einsatz und Lösung, **nicht** Bauform, Version, `instanz_gruen` oder Bewährung | bei `bauform_id is not null` zusätzlich die Bedingungen aus `aufgabe_ziehbar` (`:951`): Bauform freigegeben, aktuelle Version, `instanz_gruen`, nicht pausiert, Figur hochgeladen |
| `aufgabe_ziehen` (`:981`) | Rolle aus 7 Werten | unverändert. Die Rolle lsa zieht nur die LSA, nie die Session |
| Textschlüssel (LSA-L2) | Instanzen einer Bauform haben denselben Textschlüssel | eine Bauform liefert je LSA-Sitzung **eine** Probe. Für den Zweitbeleg braucht ein Skill zwei Bauformen mit verschiedenem Text, oder LSA-L2 wird angepasst (Frage an die Gründer) |
| Freigabe `bauform_freigeben` (`:1149`) | setzt alle grünen Instanzen der Version ready | unverändert nutzbar. Die Prüfung der Rolle lsa ist ein eigener Schritt (Lena: „Unterschied zur Session“) |

### 5d · Wie Session-Aufgaben gesammelt freigegeben werden

`bauform_freigeben(p_reihe | p_thema_key | p_schluessel[])` (`schema-erwartet.sql:1149`) nimmt alle Bauformen mit
Status `zur_freigabe`. Die Auswahl geht nach Reihe, nach Thema über `skill_thema` oder nach einer Schlüsselliste
(M1: je Session über `bauform_pruef_plan`, `src/pages/coach/pruefen/bauformen/BauformListePage.tsx:63`). Alle grünen
Instanzen der aktuellen Version werden dann ready und kommen in die Bewährung.

**Passt das auf Pakete je Klassenarbeit?** Teilweise. Die Schlüsselliste kann jedes Paket abbilden, wenn eine Funktion
das Paket in Bauform-Schlüssel übersetzt. Es fehlen:

- ein Paketbegriff in der Datenbank (Klassenarbeit fehlt, Abschnitt 3);
- eine Übersetzung Paket → Skills (Themenraum ∪ Vorschau-Rand), die zur LSA-Auswahl passt;
- für LSA-Einzelaufgaben ein Gegenstück. `freigabe_thema` (`:4751`) geht nur über `skill_thema` des einen Themas,
  nicht über die Voraussetzungen. `freigabe_muster` (`:4716`) geht je Skill, aber nur für Aufgaben ohne Prüfung.

---

## 6 · Erklärvideos

### 6a · Studio-Sequenzen [Q34]

| Sequenz | Skill | Status | Autor | Welten | verständlich | fachlich | Varianten | Render aktuell | Freigabe-Zeilen |
|---|---|---|---|---|---|---|---|---|---|
| Die Normalparabel (V1) | fkt_quadr_parabel | entwurf | Rasit Güven | 1 (nur Skelett) | – | – | – | – | 0 |

Geplant sind für Reihe 1 acht Videos V1–V8 (`docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md:307–320`), dazu je
drei Welten (fussball, gaming, musik, CHECK `studio_sequenz_welten_check`).

### 6b · Freigabeschritte für Reihe 1

| | je Sequenz | Reihe 1 (8 Videos) | davon Lena |
|---|---|---|---|
| **heute** (Anforderung Studio §8) | verständlich 1 (Gründer ≠ Autor) + fachlich 1 (Lena) + Variante je Welt 3 (Rolle `fachlich`, also Lena oder Rasit) = 5 | **40** | **32** |
| **neu** | verständlich 1 + Skelett fachlich 1 (Lena) + alle Welten gemeinsam 1 (Gründer ≠ Autor) = 3 | **24** | **8** |

Annahme: Jede Sequenz bekommt drei Welten, und jeder Schritt geht im ersten Durchgang durch. Rücksprünge kosten in
beiden Fällen dasselbe.

### 6c · Wo die Regel steht und was sich ändert (nur Beschreibung)

- **Datenbank:** `studio_pruefen` (`schema-erwartet.sql:22319`) verlangt für `verstaendlich` die Rolle `gruender`,
  für **alles andere, also auch `variante`, die Rolle `fachlich`** (`:22326`). In `studio_rolle` hat die Rolle
  `fachlich` Lena und Rasit, die Rolle `gruender` Ashkan, Tolunay und Rasit [Q42]. Jeder Aufruf schreibt **eine** Zeile
  für **eine** Welt. `studio_freigabe_gueltig` (`:22174`) prüft je Welt Version und Render-Fingerabdruck.
- **„Prüfer ≠ Autor“** steht im Trigger `studio_freigabe_regeln` (`:22190–22216`). Ausgeschlossen sind Autor und
  Bearbeiter (`:22203`). Verständlich und fachlich prüfen zwei verschiedene Personen (`:22209`). Die Tabelle ist
  append-only.
- **Oberfläche:** `src/pages/admin/studio/FreigabeReiter.tsx:138–148`. Die Knöpfe je Welt hängen an
  `stand.darf.fachlich` (`:146`). `studio_freigabe_stand.darf` (`schema-erwartet.sql:22229`) kennt keinen Schlüssel
  `variante`.
- **Für die neue Regel ändert sich:** (1) In `studio_pruefen` verlangt `variante` die Rolle `gruender` statt
  `fachlich`. (2) Ein Aufruf „alle Welten“ schreibt je Welt eine Zeile im selben Zug. Die Zeile je Welt bleibt, weil
  `studio_freigabe_gueltig` und die Ausgabe je Welt rechnen. (3) `darf.variante` = Gründer und nicht Autor oder
  Bearbeiter. (4) Ein gemeinsamer Knopf im Freigabe-Reiter. (5) Anforderung Studio §2 und §8.4 nachziehen
  (`docs/reihe1/Anforderung-Studio.md:23`, `:116`).
- **Unverändert:** Der Trigger mit Autor-Ausschluss bleibt und gilt für alle drei Arten, also auch für die
  gebündelte Welten-Freigabe. Die Vier-Augen-Regel betrifft nur verständlich gegen fachlich. Ein Gründer darf
  verständlich **und** die Welten freigeben, solange er nicht der Autor ist.

---

## 7 · Freigabe-Mechanik im Code

**Wo `ready` gesetzt wird**

| Weg | Funktion | Körnigkeit | Oberfläche |
|---|---|---|---|
| Admin einzeln | `pruef_admin_freigeben` (`schema-erwartet.sql:11941`) → `task_status_set` | eine Aufgabe | Admin-Prüfansicht, `src/pages/admin/pruefen/useAdminAktionen.ts:82` |
| Admin Sammlung | `pruef_sammel('freigeben', ids[])` (`:13434`) → `task_status_set` | Liste | Expertenliste, `src/lib/supabase/pruefungAdmin.ts:78` |
| Admin je Thema | `freigabe_thema(thema, klasse)` (`:4751`) | `skill_thema` eines Themas, nur `review` mit `pruef_freigabe_erlaubt` | Item-Board, `src/components/edvance/authoring/board/Arbeitsbereich.tsx:86` |
| Admin je Skill (alt) | `freigabe_muster(skill, ids)` (`:4716`) | Skill, **nur ohne jede Prüfung** | `src/pages/admin/AuthoringItemsPage.tsx:236` |
| Admin je Cluster (alt) | `freigabe_cluster` (`:4655`) | Cluster | – |
| Bauformen | `bauform_freigeben` (`:1149`) | Reihe, Thema oder Schlüsselliste (Session) | M1-Board, `BauformListePage.tsx:63` |

`task_status_set` (`:23376`) ist der einzige Weg zu `ready` für Einzelaufgaben: nur Admin oder Systemaufruf, mit Gate
`freigabe_gate_fehler`. Der Trigger `tasks_pruefer_guard` (`:23454`) sperrt Status und Steuerfelder für
Nicht-Admins. `bauform_freigeben` setzt die Instanzen direkt per `update`.

**„Prüfer ≠ Autor“:** Bei Aufgaben gibt es keinen Autor in `tasks`. Die Trennung läuft über Rollen. Lena setzt nie
ready: `pruef_entscheiden` (`:12607`) setzt passt → `review`, und `reviewed_by` bleibt leer. Nur Admins geben frei.
`pruef_freigabe_erlaubt` (`:12954`) verlangt, dass Lenas letzte Entscheidung „passt“ ohne eigene Änderungen ist und
kein Admin beanstandet hat. Bei Bauformen prüft `bauform_pruefen` (`:1429`) nur `darf_pruefen` und die
Prüfmaschine, Admins geben frei. Bei Videos steht die Regel im Trigger (6c).

**Woran die LSA-Auswahl eine ziehbare Aufgabe erkennt:** `lsa_freie_aufgabe` (`:7912`) nimmt Aufgaben des Skills, die
in der Sitzung noch nicht ausgegeben oder beantwortet sind, deren Textschlüssel noch nicht vorkam (`:7926`) und die
`lsa_im_pool` sind (`:8201`). Sortiert wird nach Nicht-MC zuerst (Zweitbeleg), dann `sondierrang`, dann Zufall je
Sitzung.

**Wie Lena-Board, Muster-Ansicht (M1) und Admin-Freigabe zusammenhängen**

- **Lena-Board LSA** (`src/pages/coach/pruefen/PruefenUebersichtPage.tsx`, `pruef_board`, `pruef_board_soll` über
  `src/lib/supabase/pruefung.ts:54,61`): Lena entscheidet je Aufgabe (`pruef_entscheiden`). Das Soll je Skill
  kommt aus `pruef_soll` (Anlass, `soll`, `min_ohne_mc`). **Das ist der vorhandene Hebel für Pakete:** ein Anlass je
  Paket bzw. Zeitfenster.
- **Muster-Ansicht M1** (`BauformListePage.tsx`, `bauform_pruef_plan`): Lena prüft Bauformen je Session der Reihe. Die
  Admin-Sammelfreigabe läuft auf derselben Seite über `bauform_freigeben(p_schluessel)`.
- **Admin-Freigabe** (Prüfansicht, Expertenliste, Item-Board): gibt frei, was Lena auf `review` gesetzt hat.

---

## 8 · Szenarien: Lenas Prüfzeit

**Grundlage** [Q26, Q35, Q36]: Ziel ist „LSA vollständig“, also alle fehlenden Skills der Pakete aus Abschnitt 3.

| | Kl. 10 | Kl. 8–10 |
|---|---|---|
| fehlende Skills | 49 | 73 |
| Entwürfe dieser Skills | 308 | 453 |
| Familien mit Entwurf: Einzelgänger / 2+ | 264 / 17 | 362 / 29 |
| Skills mit Bauform / Bauformen | 3 / 13 | 7 / 33 |
| Skills, die auch mit allen Entwürfen keinen 2. Text hätten | 2 | 7 |
| fehlende Texte bis zur Regel | 92 | 137 |

Lenas gemessene Dauer je LSA-Aufgabe: Median 35,5 s, Mittel 145 s. Ihr Anteil „passt“ liegt bei 80,5 % [Q35]. Die
Vorgabe „2 Minuten je Aufgabe“ liegt nahe am Mittel.

**Annahmen:** Szenario A wie vorgegeben 2 Min je Aufgabe. Szenario B 5 Min je Familie mit 2+ Mitgliedern,
Einzelgänger weiter 2 Min. Szenario C 8 Min je neue Bauform bzw. 3 Min je Bauform, die für die Session schon geprüft
ist. „Voll“ = alle Entwürfe der fehlenden Skills. „Gezielt“ = nur so viele, wie die Regel braucht, geteilt durch
0,805. Die Entwürfe der Bauform-Skills (18 bzw. 42, je 6) sind als Einzelgänger gerechnet.

| Variante | Rechnung Kl. 10 | **Kl. 10** | Rechnung Kl. 8–10 | **Kl. 8–10** |
|---|---|---|---|---|
| A voll | 308 × 2 | **616 Min ≈ 10,3 h** | 453 × 2 | **906 Min ≈ 15,1 h** |
| A gezielt | 92 / 0,805 ≈ 114 × 2 | **≈ 229 Min ≈ 3,8 h** | 137 / 0,805 ≈ 170 × 2 | **≈ 340 Min ≈ 5,7 h** |
| B voll | 17 × 5 + 264 × 2 | **613 Min ≈ 10,2 h** | 29 × 5 + 362 × 2 | **869 Min ≈ 14,5 h** |
| B gezielt | wie A gezielt: Erben liefert keinen 2. Text | **≈ 3,8 h** | wie A gezielt | **≈ 5,7 h** |
| C voll (Bauformen schon für Session geprüft) | 613 − 18 × 2 + 13 × 3 + 2 × 8 | **632 Min ≈ 10,5 h** | 869 − 42 × 2 + 33 × 3 + 7 × 8 | **940 Min ≈ 15,7 h** |
| C voll (Bauformen neu) | 613 − 36 + 13 × 8 + 16 | **697 Min ≈ 11,6 h** | 869 − 84 + 33 × 8 + 56 | **1105 Min ≈ 18,4 h** |
| C gezielt | A gezielt + 2 neue Bauformen × 8 | **≈ 245 Min ≈ 4,1 h** | A gezielt + 7 × 8 | **≈ 396 Min ≈ 6,6 h** |

**Was neu geschrieben werden muss:** Für A und B je eine Aufgabe mit anderem Text für 2 Skills (Kl. 10: bruch_dezimal,
bruch_kuerzen) bzw. 7 Skills (Kl. 8–10) [Q27]. Für C stattdessen 2 bzw. 7 Bauformen mit Rolle lsa. Die übrigen
LSA-Instanzen für NF, NS, PAR, SCH, NP, PQ, WZ entstehen aus den vorhandenen Bauformen, sobald 5c umgesetzt ist.

**Lesart:** Familien und Bauformen sparen in der LSA kaum Zeit. Die LSA braucht je Skill nur zwei bis drei Texte,
während Bauformen dort lohnen, wo viele Instanzen gebraucht werden (Session). **Der große Hebel ist „gezielt statt
voll“**, also ein Soll je Paket, gegen das Lena prüft. Das spart für Klasse 10 rund 6,5 Stunden.

---

## 9 · Empfehlung

**Reihenfolge der nächsten Bauaufträge**

1. **FR-1 · Sechs Textschlüssel-Skills sofort schließen** (ohne Code). Für dezimal_add_sub, dezimal_mult, dezimal_div
   und term_zusammenfassen gibt es Entwürfe mit anderem Text, Lena prüft je einen. Für bruch_kuerzen und
   bruch_dezimal braucht es je eine neue Aufgabe mit anderem Text. Hebel: Diese sechs Skills liegen in bis zu 501 von
   501 Paketen [Q18]. Hängt von nichts ab.
2. **FR-2 · Pakete und Übersicht.** Klassenarbeit als Begriff in `schul_themenplan` oder `schul_klassenarbeiten`
   (Nummer, Halbjahr oder Datum, Themen je Arbeit). Dazu eine Funktion Paket → Skills (Themenraum ∪ Vorschau-Rand,
   gleiche Logik wie `lsa_select_next_core`) und ein Soll je Paket bzw. Zeitfenster als `pruef_soll`-Anlass, damit
   Lenas Board „gezielt“ zeigt. Admin-Übersicht je Klasse und Fenster: fähig ja/nein, fehlende Skills. Hängt von den
   Gründerfragen 1–3 ab.
3. **FR-3 · Gebündelte Welten-Freigabe** (Studio, 6c). Klein und unabhängig, spart Lena 24 von 32 Schritten in
   Reihe 1.
4. **FR-4 · Prüfmaschine für Bestandsaufgaben** (Abschnitt 4): Ergebnis in `tasks.pruefmaschine`, wiederholbar.
   Erst damit wird Familien-Erben sicher, und es lohnt erst, wenn Gründerfrage 4 entschieden ist.
5. **FR-5 · Bauformen mit Rolle lsa** (5c). Erst nach Lenas Session-Prüfung der 47 Bauformen. Lohnt für die
   quadratischen Kern-Skills (7 Skills, bis zu 50 Pakete) und für die 7 Skills, denen ein zweiter Text fehlt.
   Braucht eine Schema-Änderung mit Consensus-Prüfung (CLAUDE.md §8).

**Offene Fragen an die Gründer**

1. **Was ist eine Klassenarbeit?** Ist 1 Unterrichtsvorhaben = 1 Arbeit (Annahme A1) richtig, oder gibt es eine feste
   Zahl Arbeiten je Halbjahr? Wer pflegt die Zuordnung je Schule (Admin, aus Elternangaben über `ka_folge_schule`)?
2. **Wie tief ist „vollständig“?** Heute ist der Themenraum die volle Hülle bis Klasse 5. Reicht für die Freigabe
   „Einstieg + direkte Voraussetzungen“, oder soll ein Paket erst bei voller Tiefe als fähig gelten?
3. **Zeitfenster:** Quartal mit linearem Schuljahr (A3), oder sollen die Schulen `halbjahr` bzw. Termine pflegen?
4. **LSA-L2 und Familien:** Soll der Textschlüssel weiter für jede Sitzung gelten (dann bringt Erben der LSA nichts),
   oder soll innerhalb eines Skills für den Zweitbeleg ein Familienmitglied mit anderen Zahlen erlaubt sein?
5. **Regel je Skill:** Bleibt sie „2 Texte, davon 1 ohne MC“, oder genügt eine Nicht-MC-Aufgabe (der Code macht ein
   richtiges Nicht-MC-Ergebnis sofort final)?
6. **32 ready-Aufgaben ohne Lenas „passt“** [Q04]: nachträglich prüfen lassen oder so lassen?
7. **Themen ohne Einstiegsknoten** (15 von 37, z. B. `rationale_zahlen`, `statistik_beurteilen`) und Skills, die die
   LSA nie direkt fragt (17, [Q33]): ergänzen oder bewusst so lassen?
8. **Videos:** Gilt „jeder Gründer außer dem Autor“ auch für Rasit, der die Rolle `fachlich` hat und V1 selbst
   geschrieben hat? (Für V1 schließt der Trigger ihn als Autor ohnehin aus.)

---

## 10 · Nachprüfung durch einen frischen Subagenten

Ein frischer Subagent ohne Kontext hat fünf Zahlen per `shuf` aus den Abschnitten 2, 3 und 4 gezogen und lesend
per `dbread` nachgeprüft. Bei drei davon hat er zusätzlich eine eigene, unabhängig geschriebene Abfrage benutzt.
**Keine Abweichung.**

| Nr. | Fundstelle | Bericht | Anhang-Abfrage | eigene Abfrage | Ergebnis |
|---|---|---|---|---|---|
| 1 | 2d, geo_aehnlich_strahlen_abschnitt, Hebel [Q10] | 29 (Pool 0, draft 6) | 29 (0 / 6) | 29 (0 / 6), direkt aus `schul_themenplan` | gleich |
| 2 | 2c, Kaiserin-Theophanu-Schule, Klasse 9 [Q08] | 1/7 (voll 0) | 1 / 7 / 0 | 1 / 7, Startbedingung wie `v_mit_thema` | gleich |
| 3 | 3d, Klasse 10 bruch_kuerzen [Q15] | 33 Pakete / 25 Schulen | 33 / 25 | – | gleich |
| 4 | 3f, „3 der 49 mit Bauform“ [Q19] | 3 / 49 | 3 / 49 (auch 308, 43, 6, 12/24/13) | – | gleich |
| 5 | 4, Familien der Größe 2 [Q21] | 37 / 74 | 37 / 74 | 37, eigene Gruppierung | gleich |

Hinweise des Prüfers:

- In `known_errors` ist die falsche Antwort der Schlüssel und der Fehlbild-Slug der Wert. Der Bericht gruppiert nach
  den Slugs (`jsonb_each_text … value`). Wer nach den Schlüsseln gruppiert, landet bei 8 statt 37 Familien der
  Größe 2. Eine künftige Familien-Freigabe muss diese Wahl festschreiben.
- `basis.sql` filtert den Pool zusätzlich auf `'lsa' = any(einsatz)`, `v_mit_thema` im Code nicht. Da `lsa_im_pool`
  den Einsatz `lsa` selbst verlangt, ändert das nichts am Ergebnis.

---

## Anhang A · Abfragen

Alle Abfragen laufen read-only über `dbread`. Viele bauen auf gemeinsamen Blöcken auf, die vorangestellt werden:

Gemeinsame Blöcke: `basis.sql`, `paket.sql` (an `basis.sql` anzuhängen), `familie.sql`. `familie_cont.sql` ist
`familie.sql` mit `, ` statt `with ` in der ersten Zeile. Bei jeder Abfrage steht, welche Blöcke sie braucht.

Laufzeit der Abfragen mit `paket.sql`: 30–120 s.

### Gemeinsame Blöcke

#### basis.sql · Pool, Regel je Skill, Pläne Kl. 8–10, Themenraum, Stand je Thema

```sql
with pool as (            -- ziehbar = lsa_im_pool(id, false), wie lsa_freie_aufgabe für echte Kinder
  select t.id, t.skill_key, t.input_type,
         coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
    from tasks t where 'lsa' = any (t.einsatz) and public.lsa_im_pool(t.id, false)),
sk as (                   -- Regel je Skill: >= 2 verschiedene Aufgabentexte im Pool, davon >= 1 ohne MC
  select s.skill_key, s.klasse_herkunft,
         count(p.id)::int n_pool, count(distinct p.ts)::int n_text,
         (count(p.id) filter (where p.input_type <> 'MC'))::int n_ohne_mc,
         (select count(*) from tasks d where d.skill_key = s.skill_key and 'lsa' = any (d.einsatz)
                                       and d.status = 'draft')::int n_draft
    from skills s left join pool p on p.skill_key = s.skill_key group by 1, 2),
regel as (select sk.*, (n_text >= 2 and n_ohne_mc >= 1) ok, n_pool >= 1 min1 from sk),
plan as (                 -- Klassen 8–10: Schulpläne, dazu der Kernlehrplan als Rückfall (lsa_klp_themen)
  select s.id::text quelle, s.name, p.klasse, p.position, p.thema_key, p.stunden
    from schul_themenplan p join schulen s on s.id = p.schule_id
   where lower(p.fach) = 'mathematik' and p.klasse between 8 and 10 and p.thema_key is not null
  union all
  select 'KLP', 'Kernlehrplan', k.klasse, f.nr::int, f.thema_key, null
    from generate_series(8, 10) k(klasse),
         unnest(public.lsa_klp_themen('mathematik', k.klasse)) with ordinality f(thema_key, nr)),
raum as (                 -- Themenraum wie lsa_select_next_core: thema_einstieg + lsa_abschluss (volle Hülle)
  select thema_key, skill_key, bool_or(einstieg) einstieg from (
    select te.thema_key, te.skill_key, true einstieg from thema_einstieg te
    union all
    select te.thema_key, a.skill_key, false
      from thema_einstieg te cross join lateral public.lsa_abschluss(te.skill_key) a) x
   group by 1, 2),
thema_stand as (          -- je Thema: Startet die Thema-LSA? Einstieg komplett? Themenraum komplett?
  select th.thema_key,
         count(r.skill_key)::int n_raum,
         (count(r.skill_key) filter (where r.einstieg))::int n_einstieg,
         coalesce(bool_or(g.min1) filter (where r.einstieg), false) startet,
         coalesce(bool_and(g.ok) filter (where r.einstieg), false) einstieg_ok,
         coalesce(bool_and(g.ok), false) raum_ok,
         (count(*) filter (where r.skill_key is not null and not g.ok))::int n_fehlt
    from themen th left join raum r on r.thema_key = th.thema_key
    left join regel g on g.skill_key = r.skill_key
   group by 1)
```

#### paket.sql · Unterrichtsvorhaben = Klassenarbeit, Lage im Schuljahr, Pakete (an basis.sql anzuhängen)

```sql
,
uv as (                   -- Annahme: 1 Unterrichtsvorhaben (Planzeile mit Thema) = 1 Klassenarbeit; Lage im Schuljahr
  select p.schule_id, s.name, p.klasse, p.position, p.thema_key, p.halbjahr,
         -- Anteil am Schuljahr [beginn, ende): halbjahr, sonst kumulierte Stunden (wenn vollständig), sonst Position
         case when bool_and(p.halbjahr is not null) over w then
                (p.halbjahr - 1) * 0.5 + 0.5 * (row_number() over (partition by p.schule_id, p.klasse, p.halbjahr order by p.position) - 1)
                                           / count(*) over (partition by p.schule_id, p.klasse, p.halbjahr)
              when count(p.stunden) over w = count(*) over w then
                (sum(p.stunden) over (w order by p.position) - p.stunden)::numeric / sum(p.stunden) over w
              else (row_number() over (w order by p.position) - 1)::numeric / count(*) over w end as beginn,
         case when bool_and(p.halbjahr is not null) over w then
                (p.halbjahr - 1) * 0.5 + 0.5 * row_number() over (partition by p.schule_id, p.klasse, p.halbjahr order by p.position)
                                           / count(*) over (partition by p.schule_id, p.klasse, p.halbjahr)
              when count(p.stunden) over w = count(*) over w then
                sum(p.stunden) over (w order by p.position)::numeric / sum(p.stunden) over w
              else (row_number() over (w order by p.position))::numeric / count(*) over w end as ende
    from schul_themenplan p join schulen s on s.id = p.schule_id
   where lower(p.fach) = 'mathematik' and p.klasse between 8 and 10 and p.thema_key is not null
  window w as (partition by p.schule_id, p.klasse)),
uvf as (                  -- Fenster: Quartal nach Mitte (Schuljahr linear 1.9.–30.6.); Feb–März = [0,5; 0,7)
  select uv.*, 1 + least(3, floor((beginn + ende) / 2 * 4))::int quartal,
         (beginn < 0.7 and ende > 0.5) feb_maerz from uv),
spaeter as (              -- Themen, die nach der Arbeit kommen (gleiche Klasse ab dieser Position, Klasse + 1)
  select u.schule_id, u.klasse, u.position, p.thema_key
    from uvf u join schul_themenplan p on p.schule_id = u.schule_id and lower(p.fach) = 'mathematik'
     and p.thema_key is not null and ((p.klasse = u.klasse and p.position >= u.position) or p.klasse = u.klasse + 1)),
paket_skill as (          -- Paket je Arbeit: Themenraum (Fall „noch nicht geschrieben“) ∪ Vorschau-Rand (Fall „geschrieben“)
  select u.schule_id, u.klasse, u.position, r.skill_key, true thema, false vorschau
    from uvf u join raum r on r.thema_key = u.thema_key
  union all
  select u.schule_id, u.klasse, u.position, a.skill_key, false, true
    from uvf u join skill_thema st on st.thema_key = u.thema_key
    cross join lateral public.lsa_abschluss(st.skill_key) a
    join skills s on s.skill_key = a.skill_key and s.klasse_herkunft <= u.klasse
   where not exists (select 1 from skill_thema x join spaeter sp on sp.thema_key = x.thema_key
                      where x.skill_key = a.skill_key and sp.schule_id = u.schule_id
                        and sp.klasse = u.klasse and sp.position = u.position)),
paket_skill1 as (select schule_id, klasse, position, skill_key, bool_or(thema) thema, bool_or(vorschau) vorschau
                   from paket_skill group by 1,2,3,4),
paket as (
  select u.schule_id, u.name, u.klasse, u.position, u.thema_key, u.quartal, u.feb_maerz,
         count(ps.skill_key)::int n_skills,
         (count(ps.skill_key) filter (where g.ok))::int n_ok,
         (count(ps.skill_key) filter (where ps.thema))::int n_thema,
         (count(ps.skill_key) filter (where ps.vorschau))::int n_vorschau,
         coalesce(bool_and(g.ok), false) and exists (select 1 from thema_einstieg te where te.thema_key = u.thema_key) faehig,
         coalesce(bool_and(g.ok) filter (where ps.thema), false) faehig_thema,
         coalesce(bool_and(g.ok) filter (where ps.vorschau), true) faehig_vorschau
    from uvf u left join paket_skill1 ps using (schule_id, klasse, position)
    left join regel g on g.skill_key = ps.skill_key
   group by 1,2,3,4,5,6,7)
```

#### familie.sql · Familienschlüssel der LSA-Aufgaben

```sql
with lena as (select id from profiles where full_name = 'Lena Klever'),
t as (                    -- LSA-Aufgaben mit Familienschlüssel
  select t.id, t.skill_key, t.input_type, t.status, t.afb, t.sondierrang, t.question, t.parts,
         lower(btrim(regexp_replace(regexp_replace(coalesce(t.question,'') || ' ' ||
               coalesce((select string_agg(e.p ->> 'prompt', ' ' order by e.nr)
                           from jsonb_array_elements(case when jsonb_typeof(t.parts) = 'array' then t.parts else '[]'::jsonb end)
                                with ordinality e(p, nr)), ''),
               '[0-9]+([.,][0-9]+)*', '#', 'g'), '[[:space:]]+', ' ', 'g'))) text_norm,
         coalesce((select string_agg(distinct v.value, ',' order by v.value)
                     from task_solutions s, jsonb_each_text(case when jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
                                                                 then s.acceptance -> 'known_errors' else '{}' end) v
                    where s.task_id = t.id), '') fehlbilder,
         coalesce((select string_agg(distinct f.generator, ',') from task_figures f where f.task_id = t.id), '') figur,
         public.lsa_im_pool(t.id, false) im_pool,
         exists (select 1 from task_pruefungen p where p.task_id = t.id and p.geprueft_von in (select id from lena)) lena,
         -- „von Lena geprüft und ready“: letzte Lena-Entscheidung passt und Aufgabe ready
         (t.status = 'ready' and coalesce((select p.entscheidung = 'passt' from task_pruefungen p
                                            where p.task_id = t.id and p.geprueft_von in (select id from lena)
                                            order by p.geprueft_am desc limit 1), false)) lena_ready
    from tasks t where 'lsa' = any (t.einsatz)),
fam as (
  select md5(skill_key || '|' || input_type || '|' || text_norm || '|' || fehlbilder || '|' || figur) fam_id, t.*
    from t),
fam_n as (
  select fam_id, skill_key, count(*) n, count(*) filter (where lena_ready) n_lena_ready,
         count(*) filter (where status = 'draft') n_draft, count(*) filter (where im_pool) n_pool
    from fam group by 1, 2)
```

### Abfragen

#### Q01 · LSA-Pool nach Status, Format, Doppeljahrgang; "im Pool" = lsa_im_pool(id,false)

Ausführen: `dbread -f q01.sql`

```sql
-- A1 · LSA-Pool nach Status, Format, Doppeljahrgang; "im Pool" = lsa_im_pool(id,false)
select t.status,
       count(*) as aufgaben,
       count(*) filter (where public.lsa_im_pool(t.id, false)) as im_pool
  from tasks t where 'lsa' = any (t.einsatz)
 group by rollup (t.status) order by 1 nulls last;
```

#### Q02 · LSA-Pool je Format und je Doppeljahrgang (skills.klasse_herkunft) und Status

Ausführen: `dbread -f q02.sql`

```sql
-- A2 · LSA-Pool je Format und je Doppeljahrgang (skills.klasse_herkunft) und Status
select t.input_type,
       count(*) filter (where t.status='draft') draft,
       count(*) filter (where t.status='review') zur_freigabe,
       count(*) filter (where t.status='ready') ready,
       count(*) filter (where t.status not in ('draft','review','ready')) sonstige
  from tasks t where 'lsa' = any (t.einsatz) group by rollup (1) order by 1 nulls last;
select case when s.klasse_herkunft<=6 then '5/6' when s.klasse_herkunft<=8 then '7/8' when s.klasse_herkunft<=10 then '9/10' else 'ohne Skill' end dj,
       count(*) filter (where t.status='draft') draft,
       count(*) filter (where t.status='review') zur_freigabe,
       count(*) filter (where t.status='ready') ready,
       count(*) filter (where t.status not in ('draft','review','ready')) sonstige
  from tasks t left join skills s on s.skill_key=t.skill_key
 where 'lsa' = any (t.einsatz) group by 1 order by 1;
```

#### Q03 · Prüfentscheidungen (task_pruefungen) an LSA-Aufgaben: je Prüfer und letzter Entscheidung

Ausführen: `dbread -f q03.sql`

```sql
-- A3 · Prüfentscheidungen (task_pruefungen) an LSA-Aufgaben: je Prüfer und letzter Entscheidung
with l as (
  select distinct on (p.task_id) p.task_id, p.entscheidung, pr.full_name, pr.role
    from task_pruefungen p join tasks t on t.id=p.task_id and 'lsa'=any(t.einsatz)
    left join profiles pr on pr.id=p.geprueft_von
   order by p.task_id, p.geprueft_am desc)
select coalesce(full_name,'(ohne Prüfer)') pruefer, role, entscheidung, count(*) from l group by rollup((1,2),3) order by 1,3;
-- Aufgaben mit mindestens einer Entscheidung von Lena (role coach, Name Lena Klever)
select count(distinct p.task_id) lena_gepruefte_aufgaben,
       count(*) lena_entscheidungen
  from task_pruefungen p join tasks t on t.id=p.task_id and 'lsa'=any(t.einsatz)
  join profiles pr on pr.id=p.geprueft_von where pr.full_name='Lena Klever';
```

#### Q04 · ready-Aufgaben im LSA-Pool: wer hat freigegeben (reviewed_by), mit/ohne Lena-Prüfung

Ausführen: `dbread -f q04.sql`

```sql
-- A4 · ready-Aufgaben im LSA-Pool: wer hat freigegeben (reviewed_by), mit/ohne Lena-Prüfung
select coalesce(pr.full_name,'(leer)') freigegeben_von, pr.role,
       count(*) ready,
       count(*) filter (where exists (select 1 from task_pruefungen p join profiles l on l.id=p.geprueft_von
                                       where p.task_id=t.id and l.full_name='Lena Klever' and p.entscheidung='passt')) davon_lena_passt
  from tasks t left join profiles pr on pr.id=t.reviewed_by
 where 'lsa'=any(t.einsatz) and t.status='ready' group by 1,2 order by 3 desc;
```

#### Q05 · Skills nach LSA-Regel (alle 130 Skills) und Themen nach Stand

Ausführen: `cat basis.sql q05.sql | dbread -f -`

```sql
-- B1 · Skills nach LSA-Regel (alle 130 Skills) und Themen nach Stand
select count(*) skills, count(*) filter (where ok) regel_erfuellt, count(*) filter (where min1) mind_1_im_pool,
       count(*) filter (where n_pool >= 2 and n_ohne_mc >= 1) regel_ohne_textschluessel,
       count(*) filter (where n_pool >= 2 and n_ohne_mc >= 1 and not ok) nur_wegen_gleichem_text
  from regel;
```

#### Q06 · Themenstand (37 Themen): Einstiegsknoten vorhanden, Thema-LSA startet, Einstieg/Themenraum vollständig

Ausführen: `cat basis.sql q06.sql | dbread -f -`

```sql
-- B2 · Themenstand (37 Themen): Einstiegsknoten vorhanden, Thema-LSA startet, Einstieg/Themenraum vollständig
select count(*) themen, count(*) filter (where n_einstieg>0) mit_einstieg, count(*) filter (where startet) startet,
       count(*) filter (where einstieg_ok) einstieg_ok, count(*) filter (where raum_ok) raum_ok
  from thema_stand;
```

#### Q07 · Je Klasse: Anteil der Plan-Themen (Schule × Klasse × Thema), deren Themenraum vollständig die Regel erfüllt

Ausführen: `cat basis.sql q07.sql | dbread -f -`

```sql
-- B3 · Je Klasse: Anteil der Plan-Themen (Schule × Klasse × Thema), deren Themenraum vollständig die Regel erfüllt
select klasse, case when quelle='KLP' then 'Kernlehrplan' else 'Schulpläne' end art,
       count(distinct quelle) quellen, count(*) kombis,
       count(*) filter (where ts.startet) startet, count(*) filter (where ts.einstieg_ok) einstieg_ok,
       count(*) filter (where ts.raum_ok) raum_ok,
       round(100.0*count(*) filter (where ts.raum_ok)/count(*),1) raum_ok_pct
  from (select distinct quelle, klasse, thema_key from plan) p join thema_stand ts using (thema_key)
 group by 1,2 order by 1,2;
```

#### Q08 · Je Schule und Klasse: Themen im Plan, davon Themenraum vollständig (Thema-LSA vollständig lauffähig)

Ausführen: `cat basis.sql q08.sql | dbread -f -`

```sql
-- B4 · Je Schule und Klasse: Themen im Plan, davon Themenraum vollständig (Thema-LSA vollständig lauffähig)
select p.name, p.klasse, count(*) themen, count(*) filter (where ts.startet) startet, count(*) filter (where ts.raum_ok) vollstaendig
  from (select distinct quelle, name, klasse, thema_key from plan) p join thema_stand ts using (thema_key)
 group by 1,2 order by (p.name='Kernlehrplan') desc, 1, 2;
```

#### Q09 · Je Thema der Klassen 8–10: Einstiegsknoten, Themenraum, fehlende Skills, Plan-Kombinationen

Ausführen: `cat basis.sql q09.sql | dbread -f -`

```sql
-- B5 · Je Thema der Klassen 8–10: Einstiegsknoten, Themenraum, fehlende Skills, Plan-Kombinationen
select ts.thema_key, th.stufe, th.klasse, ts.n_einstieg, ts.n_raum, ts.n_fehlt,
       ts.startet, ts.einstieg_ok,
       (select count(*) from (select distinct quelle, klasse from plan p where p.thema_key=ts.thema_key and p.quelle<>'KLP') x) schul_kombis,
       (select count(*) from skill_thema st where st.thema_key=ts.thema_key) n_skill_thema
  from thema_stand ts join themen th using (thema_key)
 where ts.thema_key in (select thema_key from plan)
 order by th.sort;
```

#### Q10 · Skills, die die Regel NICHT erfüllen, nach Hebel = Kombinationen (Schule × Klasse × Thema, Kl. 8–10, nur

Ausführen: `cat basis.sql q10.sql | dbread -f -`

```sql
-- B6 · Skills, die die Regel NICHT erfüllen, nach Hebel = Kombinationen (Schule × Klasse × Thema, Kl. 8–10, nur
--      Schulpläne), in deren Themenraum sie liegen. Top 30 mit draft-Aufgaben.
select g.skill_key, g.klasse_herkunft kl, count(*) hebel, g.n_pool im_pool, g.n_text texte, g.n_ohne_mc ohne_mc, g.n_draft draft
  from (select distinct quelle, klasse, thema_key from plan where quelle <> 'KLP') p
  join raum r using (thema_key) join regel g on g.skill_key = r.skill_key
 where not g.ok
 group by 1,2,4,5,6,7 order by 3 desc, 1 limit 30;
```

#### Q11 · Zusammenfassung 2d: Skills in irgendeinem Themenraum (Kl. 8–10), erfüllt/nicht erfüllt, draft dahinter

Ausführen: `cat basis.sql q11.sql | dbread -f -`

```sql
-- B7 · Zusammenfassung 2d: Skills in irgendeinem Themenraum (Kl. 8–10), erfüllt/nicht erfüllt, draft dahinter
select count(*) skills_im_raum, count(*) filter (where g.ok) erfuellt, count(*) filter (where not g.ok) fehlt,
       count(*) filter (where not g.ok and g.n_draft = 0) fehlt_ohne_draft,
       sum(g.n_draft) filter (where not g.ok) draft_hinter_fehlenden
  from regel g where g.skill_key in (select r.skill_key from raum r join plan p using (thema_key));
```

#### Q12 · Pakete je Klasse: Anzahl, Skills je Paket, LSA-fähig (alle Skills erfüllen die Regel)

Ausführen: `cat basis.sql paket.sql q12.sql | dbread -f -`

```sql
-- C1 · Pakete je Klasse: Anzahl, Skills je Paket, LSA-fähig (alle Skills erfüllen die Regel)
select klasse, count(*) pakete, round(avg(n_skills),1) skills_avg, min(n_skills) skills_min, max(n_skills) skills_max,
       round(avg(n_ok),1) ok_avg, round(100.0*sum(n_ok)/nullif(sum(n_skills),0),1) ok_pct,
       count(*) filter (where faehig) faehig, count(*) filter (where faehig_thema) faehig_thema,
       count(*) filter (where faehig_vorschau) faehig_vorschau
  from paket group by rollup(1) order by 1;
```

#### Q13 · Pakete je Klasse und Quartal: Anzahl, fähig, fehlende Skills je Paket (Median, Min)

Ausführen: `cat basis.sql paket.sql q13.sql | dbread -f -`

```sql
-- C2 · Pakete je Klasse und Quartal: Anzahl, fähig, fehlende Skills je Paket (Median, Min)
select klasse, quartal, count(*) pakete, count(*) filter (where faehig) faehig,
       percentile_disc(0.5) within group (order by n_skills - n_ok) fehlend_median,
       min(n_skills - n_ok) fehlend_min, count(*) filter (where n_skills - n_ok <= 3) bis_3_fehlend
  from paket group by 1,2 order by 1,2;
```

#### Q14 · Je Klasse und Quartal die fehlenden Skills nach Zahl der Pakete, in denen sie fehlen (Top 8 je Fenster)

Ausführen: `cat basis.sql paket.sql q14.sql | dbread -f -`

```sql
-- C3 · Je Klasse und Quartal die fehlenden Skills nach Zahl der Pakete, in denen sie fehlen (Top 8 je Fenster)
select * from (
  select p.klasse, p.quartal, ps.skill_key, count(*) pakete, g.n_draft draft,
         row_number() over (partition by p.klasse, p.quartal order by count(*) desc, ps.skill_key) rang
    from paket p join paket_skill1 ps using (schule_id, klasse, position) join regel g on g.skill_key = ps.skill_key
   where not g.ok group by 1,2,3,5) x
 where rang <= 8 order by 1,2,6;
```

#### Q15 · Feb–März 2027, Klasse 9 und 10: Fall A = laufendes Vorhaben (Themenraum), Fall B = nächstes Vorhaben

Ausführen: `cat basis.sql paket.sql q15.sql | dbread -f -`

```sql
-- C4 · Feb–März 2027, Klasse 9 und 10: Fall A = laufendes Vorhaben (Themenraum), Fall B = nächstes Vorhaben
--      (Vorschau-Rand). Je fehlendem Skill: Pakete, in denen er fehlt, draft-Aufgaben, Bauformen.
, fm as (
  select u.schule_id, u.klasse, u.position, 'A' fall from uvf u where u.feb_maerz and u.klasse in (9,10)
  union
  select u.schule_id, u.klasse, min(u.position), 'B' from uvf u
   where u.klasse in (9,10) and u.position > (select max(x.position) from uvf x where x.feb_maerz
                                                and x.schule_id = u.schule_id and x.klasse = u.klasse)
   group by 1,2),
fm_skill as (
  select f.*, ps.skill_key from fm f join paket_skill1 ps using (schule_id, klasse, position)
   where (f.fall = 'A' and ps.thema) or (f.fall = 'B' and ps.vorschau))
select fs.klasse, fs.skill_key, g.klasse_herkunft kl, count(distinct (fs.schule_id, fs.position, fs.fall)) pakete,
       count(distinct fs.schule_id) schulen, string_agg(distinct fs.fall, '') faelle,
       g.n_pool im_pool, g.n_text texte, g.n_draft draft,
       (select count(*) from bauformen b where b.skill_key = fs.skill_key) bauformen,
       (select string_agg(b.schluessel, ' ' order by b.schluessel) from bauformen b where b.skill_key = fs.skill_key) bf
  from fm_skill fs join regel g on g.skill_key = fs.skill_key
 where not g.ok group by 1,2,3,7,8,9 order by 1, 4 desc, 2;
```

#### Q16 · Feb–März 2027: Zahl der Pakete und Schulen je Klasse und Fall

Ausführen: `cat basis.sql paket.sql q16.sql | dbread -f -`

```sql
-- C5 · Feb–März 2027: Zahl der Pakete und Schulen je Klasse und Fall
, fm as (
  select u.schule_id, u.klasse, u.position, 'A' fall from uvf u where u.feb_maerz and u.klasse in (9,10)
  union
  select u.schule_id, u.klasse, min(u.position), 'B' from uvf u
   where u.klasse in (9,10) and u.position > (select max(x.position) from uvf x where x.feb_maerz
                                                and x.schule_id = u.schule_id and x.klasse = u.klasse)
   group by 1,2)
select f.klasse, f.fall, count(*) pakete, count(distinct f.schule_id) schulen,
       count(distinct u.thema_key) themen, string_agg(distinct u.thema_key, ', ') themenliste
  from fm f join uvf u using (schule_id, klasse, position) group by 1,2 order by 1,2;
```

#### Q17 · Überschneidung: Skills nach Zahl der Pakete (Kl. 8–10, 501 Pakete); Anteil in 2+ Paketen

Ausführen: `cat basis.sql paket.sql q17.sql | dbread -f -`

```sql
-- C6 · Überschneidung: Skills nach Zahl der Pakete (Kl. 8–10, 501 Pakete); Anteil in 2+ Paketen
, n as (select skill_key, count(*) pakete from paket_skill1 group by 1)
select count(*) skills, count(*) filter (where pakete >= 2) in_2plus,
       round(100.0 * count(*) filter (where pakete >= 2) / count(*), 1) pct_2plus,
       count(*) filter (where pakete >= 50) in_50plus from n;
```

#### Q18 · Die 20 Skills mit den meisten Paketen (Kl. 8–10), mit Regelstand

Ausführen: `cat basis.sql paket.sql q18.sql | dbread -f -`

```sql
-- C7 · Die 20 Skills mit den meisten Paketen (Kl. 8–10), mit Regelstand
, n as (select skill_key, count(*) pakete from paket_skill1 group by 1)
select n.skill_key, n.pakete, g.ok regel, g.n_pool im_pool, g.n_text texte, g.n_draft draft
  from n join regel g using (skill_key) order by 2 desc, 1 limit 20;
```

#### Q19 · Klasse 10 vollständig (alle 149 Pakete): fehlende Skills, Summe draft, ohne Pool, mit Bauform, nach Herkunftsklasse

Ausführen: `cat basis.sql paket.sql q19.sql | dbread -f -`

```sql
-- C8 · Klasse 10 vollständig (alle 149 Pakete): fehlende Skills, Summe draft, ohne Pool, mit Bauform, nach Herkunftsklasse
, f as (select distinct ps.skill_key from paket_skill1 ps join regel g using (skill_key) where ps.klasse = 10 and not g.ok)
select count(*) fehlende_skills, sum(g.n_draft) draft, count(*) filter (where g.n_draft = 0) ohne_draft,
       count(*) filter (where g.n_pool = 0) ohne_pool,
       count(*) filter (where g.n_pool >= 1) teilweise,
       count(*) filter (where exists (select 1 from bauformen b where b.skill_key = f.skill_key)) mit_bauform,
       count(*) filter (where g.klasse_herkunft = 10) kl10, count(*) filter (where g.klasse_herkunft = 9) kl9,
       count(*) filter (where g.klasse_herkunft <= 8) kl_bis8,
       string_agg(f.skill_key || ' (' || g.n_draft || ')', ', ' order by g.klasse_herkunft desc, f.skill_key) liste
  from f join regel g using (skill_key);
```

#### Q20 · Fehlende Skills je Klasse (Vereinigung über alle Pakete der Klasse) und Klasse 8–10 gesamt, mit draft

Ausführen: `cat basis.sql paket.sql q20.sql | dbread -f -`

```sql
-- C9 · Fehlende Skills je Klasse (Vereinigung über alle Pakete der Klasse) und Klasse 8–10 gesamt, mit draft
, f as (select distinct ps.klasse, ps.skill_key, g.n_draft from paket_skill1 ps join regel g using (skill_key) where not g.ok)
select klasse::text, count(*) fehlende_skills, sum(n_draft) draft from f group by 1
union all
select '8–10', count(*), sum(n_draft) from (select distinct skill_key, n_draft from f) x order by 1;
```

#### Q21 · Familien: Anzahl, Größenverteilung, Einzelgänger

Ausführen: `cat familie.sql q21.sql | dbread -f -`

```sql
-- D1 · Familien: Anzahl, Größenverteilung, Einzelgänger
select case when n = 1 then '1 (Einzelgänger)' when n = 2 then '2' when n <= 4 then '3–4' when n <= 9 then '5–9' else '10+' end groesse,
       count(*) familien, sum(n) aufgaben from fam_n group by 1 order by min(n);
```

#### Q22 · draft-Aufgaben nach Erbfähigkeit ihrer Familie (>= 2 / genau 1 / 0 Mitglieder von Lena geprüft und ready)

Ausführen: `cat familie.sql q22.sql | dbread -f -`

```sql
-- D2 · draft-Aufgaben nach Erbfähigkeit ihrer Familie (>= 2 / genau 1 / 0 Mitglieder von Lena geprüft und ready)
select case when n_lena_ready >= 2 then 'a) sofort erbfähig (>=2 geprüft+ready)'
            when n_lena_ready = 1 then 'b) ein Beispiel fehlt (1 geprüft+ready)'
            else 'c) kein geprüftes Mitglied' end lage,
       count(*) filter (where n_draft > 0) familien_mit_draft, sum(n_draft) draft
  from fam_n group by 1 order by 1;
```

#### Q23 · Empfindlichkeit der Gruppierung: Familien mit 2+ Mitgliedern und Aufgaben darin, je Schlüsselvariante

Ausführen: `cat familie.sql q23.sql | dbread -f -`

```sql
-- D3 · Empfindlichkeit der Gruppierung: Familien mit 2+ Mitgliedern und Aufgaben darin, je Schlüsselvariante
select 'voll (Skill+Format+Text+Fehlbilder+Figur)' variante, count(*) filter (where n >= 2) fam_2plus, sum(n) filter (where n >= 2) aufgaben_darin
  from fam_n
union all
select 'ohne Fehlbilder', count(*) filter (where n >= 2), sum(n) filter (where n >= 2)
  from (select count(*) n from fam group by skill_key, input_type, text_norm, figur) x
union all
select 'nur Skill+Text', count(*) filter (where n >= 2), sum(n) filter (where n >= 2)
  from (select count(*) n from fam group by skill_key, text_norm) x;
```

#### Q24 · Erben je Skill: Skills, die die Regel heute nicht erfüllen und durch Erben (Familien mit >= 2 Lena-geprüften

Ausführen: `cat familie.sql q24.sql | dbread -f -`

```sql
-- D4 · Erben je Skill: Skills, die die Regel heute nicht erfüllen und durch Erben (Familien mit >= 2 Lena-geprüften
--      ready-Mitgliedern: deren draft-Mitglieder werden ready) erfüllen würden. Achtung: Mitglieder einer Familie
--      teilen den Textschlüssel → zählen für die Regel als EIN Text.
, regel_heute as (
  select skill_key, count(distinct coalesce(public.lsa_text_schluessel(question, parts), id::text)) filter (where im_pool) texte,
         count(*) filter (where im_pool and input_type <> 'MC') ohne_mc from fam group by 1),
erbt as (select f.* from fam f join fam_n n using (fam_id) where n.n_lena_ready >= 2 and f.status = 'draft'),
regel_erbe as (
  select skill_key, count(distinct coalesce(public.lsa_text_schluessel(question, parts), id::text)) filter (where im_pool or e) texte,
         count(*) filter (where (im_pool or e) and input_type <> 'MC') ohne_mc
    from (select fam.*, fam.id in (select id from erbt) e from fam) x group by 1)
select count(*) filter (where not (h.texte >= 2 and h.ohne_mc >= 1)) heute_nicht_ok,
       count(*) filter (where not (h.texte >= 2 and h.ohne_mc >= 1) and e.texte >= 2 and e.ohne_mc >= 1) durch_erben_ok,
       (select count(*) from erbt) erbende_drafts,
       (select string_agg(distinct skill_key, ', ') from erbt) skills_der_erben
  from regel_heute h join regel_erbe e using (skill_key);
```

#### Q25 · Obergrenze: Würde die Regel erfüllt, wenn alle draft-Aufgaben mit gültiger Lösung ready würden?

Ausführen: `cat familie.sql q25.sql | dbread -f -`

```sql
-- D5 · Obergrenze: Würde die Regel erfüllt, wenn alle draft-Aufgaben mit gültiger Lösung ready würden?
--      (draft zählt, wenn lsa_has_answers und lsa_eingabeformat_eindeutig gelten — die übrigen Bedingungen von lsa_im_pool
--      außer dem Status). Je Skill: verschiedene Textschlüssel, davon ohne MC; dazu Familien je Skill.
, pot as (
  select f.skill_key, f.id, f.input_type, f.fam_id, coalesce(public.lsa_text_schluessel(f.question, f.parts), f.id::text) ts,
         f.im_pool or (f.status = 'draft' and exists (
           select 1 from tasks t2 join task_solutions s on s.task_id = t2.id where t2.id = f.id
              and coalesce(t2.is_active, false) and not coalesce(t2.is_tutorial, false) and t2.content_type = 'exercise'
              and public.lsa_has_answers(t2.input_type, t2.parts, s.correct_answers)
              and public.lsa_eingabeformat_eindeutig(t2.input_type, t2.bruch, t2.unit, t2.parts, s.correct_answers))) zaehlt
    from fam f),
je as (select skill_key, count(distinct ts) filter (where zaehlt) texte, count(*) filter (where zaehlt and input_type <> 'MC') ohne_mc,
              count(distinct fam_id) filter (where zaehlt) familien, count(*) filter (where zaehlt) aufgaben
         from pot group by 1)
select count(*) skills_mit_lsa_aufgaben, count(*) filter (where texte >= 2 and ohne_mc >= 1) regel_bei_allen_drafts,
       count(*) filter (where texte < 2) zu_wenig_texte, sum(familien) familien_gesamt, sum(aufgaben) aufgaben_gesamt
  from je;
```

#### Q26 · Szenario-Grundlage: fehlende Skills (Kl. 10 bzw. Kl. 8–10, aus den Paketen) → draft-Aufgaben, Familien mit

Ausführen: `cat basis.sql paket.sql familie_cont.sql q26.sql | dbread -f -`

```sql
-- E1 · Szenario-Grundlage: fehlende Skills (Kl. 10 bzw. Kl. 8–10, aus den Paketen) → draft-Aufgaben, Familien mit
--      draft (Einzelgänger / 2+), Skills mit Bauform und deren Zahl, Skills, die auch mit allen drafts zu wenig Texte haben
, ziel as (select distinct case when ps.klasse = 10 then 'Kl10' end z, ps.skill_key from paket_skill1 ps join regel g using (skill_key)
            where not g.ok and ps.klasse = 10
           union select distinct 'Kl8-10', ps.skill_key from paket_skill1 ps join regel g using (skill_key) where not g.ok),
fd as (select fam_id, skill_key, count(*) filter (where status = 'draft') d, count(*) n from fam group by 1,2),
pot as (select skill_key, count(distinct coalesce(public.lsa_text_schluessel(question, parts), id::text)) filter (where status in ('draft','ready')) texte,
               count(*) filter (where status in ('draft','ready') and input_type <> 'MC') ohne_mc from fam group by 1)
select z.z ziel, count(distinct z.skill_key) skills,
       (select sum(d) from fd where fd.skill_key in (select skill_key from ziel z2 where z2.z = z.z)) drafts,
       (select count(*) from fd where d > 0 and n = 1 and fd.skill_key in (select skill_key from ziel z2 where z2.z = z.z)) fam_einzel,
       (select count(*) from fd where d > 0 and n >= 2 and fd.skill_key in (select skill_key from ziel z2 where z2.z = z.z)) fam_mehr,
       (select count(distinct b.skill_key) from bauformen b where b.skill_key in (select skill_key from ziel z2 where z2.z = z.z)) skills_mit_bauform,
       (select count(*) from bauformen b where b.skill_key in (select skill_key from ziel z2 where z2.z = z.z)) bauformen,
       (select count(*) from pot where (pot.texte < 2 or pot.ohne_mc < 1) and pot.skill_key in (select skill_key from ziel z2 where z2.z = z.z)) auch_mit_drafts_zu_wenig
  from ziel z group by 1 order by 1;
```

#### Q27 · Fehlende Skills (Kl. 8–10), die auch mit allen draft-Aufgaben die Regel nicht erreichen

Ausführen: `cat basis.sql paket.sql familie_cont.sql q27.sql | dbread -f -`

```sql
-- E2 · Fehlende Skills (Kl. 8–10), die auch mit allen draft-Aufgaben die Regel nicht erreichen
, z as (select distinct ps.skill_key from paket_skill1 ps join regel g using (skill_key) where not g.ok)
select f.skill_key, count(distinct coalesce(public.lsa_text_schluessel(question, parts), id::text)) filter (where status in ('draft','ready')) texte,
       count(*) filter (where status in ('draft','ready') and input_type <> 'MC') ohne_mc, count(*) aufgaben,
       (select count(*) from bauformen b where b.skill_key = f.skill_key) bauformen,
       bool_or(f.skill_key in (select skill_key from paket_skill1 where klasse = 10)) kl10
  from fam f where f.skill_key in (select skill_key from z) group by 1
having count(distinct coalesce(public.lsa_text_schluessel(question, parts), id::text)) filter (where status in ('draft','ready')) < 2
    or count(*) filter (where status in ('draft','ready') and input_type <> 'MC') < 1;
```

#### Q28 · Familien mit 2+ Mitgliedern: Überblick (für die Auswahl der Beispiele)

Ausführen: `cat familie.sql q28.sql | dbread -f -`

```sql
-- D6 · Familien mit 2+ Mitgliedern: Überblick (für die Auswahl der Beispiele)
select n.fam_id, n.skill_key, n.n, n.n_lena_ready, n.n_draft, min(f.input_type) fmt, min(f.fehlbilder) fb, left(min(f.text_norm), 90) text
  from fam_n n join fam f using (fam_id) where n.n >= 2 group by 1,2,3,4,5 order by n.n_lena_ready desc, n.n desc limit 40;
```

#### Q29 · Mitglieder ausgewählter Familien mit Volltext, Lösung, Status, AFB, sondierrang

Ausführen: `cat familie.sql q29.sql | dbread -f -`

```sql
-- D7 · Mitglieder ausgewählter Familien mit Volltext, Lösung, Status, AFB, sondierrang
select left(f.fam_id, 6) fam, f.skill_key, f.status, f.lena_ready lena, f.afb, f.sondierrang sr,
       replace(f.question, E'\n', ' ') frage, (select s.correct_answers::text from task_solutions s where s.task_id = f.id) loesung, f.fehlbilder
  from fam f where left(f.fam_id, 6) in ('71af6c','2996f1','cf1fb4','adcfd8','e6b1b6','faeecd','e95942','1b17e9','e29b07','75f2ba','8a359c','68953')
 order by f.skill_key, 1, f.status desc, f.sondierrang;
```

#### Q30 · Bauformen: Status, Prüfmaschine, Blindlöser, letzte Lena-Entscheidung, Freigabe, ready-Instanzen je Rolle

Ausführen: `dbread -f q30.sql`

```sql
-- F1 · Bauformen: Status, Prüfmaschine, Blindlöser, letzte Lena-Entscheidung, Freigabe, ready-Instanzen je Rolle
with lp as (select distinct on (p.bauform_id) p.bauform_id, p.entscheidung, p.version
              from bauform_pruefungen p order by p.bauform_id, p.geprueft_am desc),
inst as (select bauform_id, count(*) n, count(*) filter (where status = 'ready') ready,
                count(*) filter (where not public.instanz_gruen(pruefmaschine)) nicht_gruen,
                string_agg(rolle || ':' || cnt, ' ' order by rolle) filter (where true) je_rolle
           from (select bauform_id, rolle, status, pruefmaschine, count(*) over (partition by bauform_id, rolle) cnt
                   from tasks t where t.bauform_id is not null and t.bauform_version = (select version from bauformen b where b.id = t.bauform_id)) x
          group by 1)
select b.status, count(*) bauformen, count(*) filter (where b.blindloeser ->> 'bestanden' = 'true') blind_ok,
       count(*) filter (where lp.entscheidung is not null) lena_entschieden,
       count(*) filter (where lp.entscheidung = 'passt') lena_passt, count(*) filter (where b.freigegeben_am is not null) freigegeben,
       sum(i.n) instanzen, sum(i.ready) ready, sum(i.nicht_gruen) nicht_gruen
  from bauformen b left join lp on lp.bauform_id = b.id left join inst i on i.bauform_id = b.id
 group by rollup (1) order by 1 nulls last;
```

#### Q31 · Bauformen je Gruppe (Präfix) und Skill: Anzahl, Instanzen je Rolle (aktuelle Version), davon ready

Ausführen: `dbread -f q31.sql`

```sql
-- F2 · Bauformen je Gruppe (Präfix) und Skill: Anzahl, Instanzen je Rolle (aktuelle Version), davon ready
with i as (select split_part(b.schluessel,'-',1) gruppe, b.skill_key, t.rolle, count(*) n, count(*) filter (where t.status='ready') r
             from bauformen b join tasks t on t.bauform_id = b.id and t.bauform_version = b.version group by 1,2,3)
select g.gruppe, g.skill_key, g.bauformen, string_agg(i.rolle || ':' || i.n, ' ' order by i.rolle) instanzen_je_rolle, sum(i.r) ready
  from (select split_part(schluessel,'-',1) gruppe, skill_key, count(*) bauformen from bauformen group by 1,2) g
  join i using (gruppe, skill_key) group by 1,2,3 order by 1;
```

#### Q32 · Skills mit Bauform: LSA-Regel heute, Pool, draft, und ob sie in einem Paket der Kl. 8–10 fehlen (Pakete, in denen sie fehlen)

Ausführen: `cat basis.sql paket.sql q32.sql | dbread -f -`

```sql
-- F3 · Skills mit Bauform: LSA-Regel heute, Pool, draft, und ob sie in einem Paket der Kl. 8–10 fehlen (Pakete, in denen sie fehlen)
select split_part(min(b.schluessel),'-',1) gruppe, g.skill_key, g.klasse_herkunft kl, g.ok regel, g.n_pool im_pool, g.n_text texte, g.n_draft draft,
       (select count(*) from paket_skill1 ps where ps.skill_key = g.skill_key) pakete
  from bauformen b join regel g on g.skill_key = b.skill_key group by 2,3,4,5,6,7 order by 1;
```

#### Q33 · Abweichung skill_thema ↔ LSA: Skills der Plan-Themen (Kl. 8–10, skill_thema), die in keinem Themenraum liegen

Ausführen: `cat basis.sql q33.sql | dbread -f -`

```sql
-- B8 · Abweichung skill_thema ↔ LSA: Skills der Plan-Themen (Kl. 8–10, skill_thema), die in keinem Themenraum liegen
--      (weder Einstieg noch Voraussetzung eines Einstiegs) — die Thema-LSA fragt sie nie direkt; letzte Zeile = Summe
select coalesce(st.thema_key, '(Summe)') thema, string_agg(st.skill_key, ', ' order by st.skill_key) nicht_im_themenraum, count(*) n
  from skill_thema st
 where st.thema_key in (select thema_key from plan)
   and not exists (select 1 from raum r where r.skill_key = st.skill_key)
 group by rollup (st.thema_key) order by st.thema_key nulls last;
```

#### Q34 · Studio-Sequenzen: Status, Autor, Welten, gültige Freigaben je Art/Welt, Render aktuell je Welt

Ausführen: `dbread -f q34.sql`

```sql
-- G1 · Studio-Sequenzen: Status, Autor, Welten, gültige Freigaben je Art/Welt, Render aktuell je Welt
select s.titel, s.skill_key, s.status, a.full_name autor, (select count(*) from studio_welt w where w.sequenz_id = s.id) welten,
       public.studio_freigabe_gueltig(s.id, 'verstaendlich', 'skelett') verstaendlich,
       public.studio_freigabe_gueltig(s.id, 'fachlich', 'skelett') fachlich,
       (select string_agg(w.welt || '=' || public.studio_freigabe_gueltig(s.id, 'variante', w.welt)::text, ' ' order by w.welt)
          from studio_welt w where w.sequenz_id = s.id and w.welt <> 'skelett') varianten,
       (select string_agg(r.welt || '=' || r.aktuell::text, ' ' order by r.welt) from public.studio_render_stand(s.id) r) render_aktuell,
       (select count(*) from studio_freigabe f where f.sequenz_id = s.id) freigabe_zeilen
  from studio_sequenz s join profiles a on a.id = s.autor_id order by s.skill_key, s.titel;
```

#### Q35 · Lenas gemessene Prüfdauer je LSA-Aufgabe (task_pruefungen.dauer_sek) und Quote „passt“

Ausführen: `dbread -f q35.sql`

```sql
-- E3 · Lenas gemessene Prüfdauer je LSA-Aufgabe (task_pruefungen.dauer_sek) und Quote „passt“
select count(*) entscheidungen, count(dauer_sek) mit_dauer,
       percentile_cont(0.5) within group (order by dauer_sek) median_sek,
       round(avg(dauer_sek)) mittel_sek,
       round(100.0 * count(*) filter (where entscheidung = 'passt') / count(*), 1) passt_pct
  from task_pruefungen p join tasks t on t.id = p.task_id and 'lsa' = any (t.einsatz)
 where p.geprueft_von = (select id from profiles where full_name = 'Lena Klever');
```

#### Q36 · Mindestbedarf: je fehlendem Skill fehlende Texte bis zur Regel (2 − vorhandene Texte, mind. 0) und fehlende

Ausführen: `cat basis.sql paket.sql q36.sql | dbread -f -`

```sql
-- C10 · Mindestbedarf: je fehlendem Skill fehlende Texte bis zur Regel (2 − vorhandene Texte, mind. 0) und fehlende
--       Nicht-MC-Aufgabe; Summe für Klasse 10 und für Klasse 8–10
, f as (select distinct ps.klasse, ps.skill_key from paket_skill1 ps join regel g using (skill_key) where not g.ok),
b as (select g.skill_key, greatest(2 - g.n_text, case when g.n_ohne_mc = 0 then 1 else 0 end) bedarf, g.n_pool from regel g)
select 'Kl10' ziel, count(*) skills, count(*) filter (where b.n_pool = 0) ohne_pool, sum(b.bedarf) texte_fehlen
  from (select distinct skill_key from f where klasse = 10) x join b using (skill_key)
union all
select 'Kl8-10', count(*), count(*) filter (where b.n_pool = 0), sum(b.bedarf)
  from (select distinct skill_key from f) x join b using (skill_key);
```

#### Q37 · LSA-Pool je Thema (skill_thema): Status und Regelstand der Skills

Ausführen: `cat basis.sql q37.sql | dbread -f -`

```sql
-- B9 · LSA-Pool je Thema (skill_thema): Status und Regelstand der Skills
select coalesce(th.thema_key, '(ohne Thema)') thema, th.stufe, count(distinct g.skill_key) skills,
       count(distinct g.skill_key) filter (where g.ok) skills_ok,
       count(t.id) filter (where t.status = 'draft') draft, count(t.id) filter (where t.status = 'review') zur_freigabe,
       count(t.id) filter (where t.status = 'ready') ready, count(t.id) filter (where t.status not in ('draft','review','ready')) sonstige
  from regel g left join skill_thema st using (skill_key) left join themen th on th.thema_key = st.thema_key
  left join tasks t on t.skill_key = g.skill_key and 'lsa' = any (t.einsatz)
 group by 1, 2, th.sort order by th.stufe, th.sort;
```

#### Q38 · LSA-Pool je Skill: Status, im Pool, verschiedene Texte, ohne MC, Regel

Ausführen: `cat basis.sql q38.sql | dbread -f -`

```sql
-- B10 · LSA-Pool je Skill: Status, im Pool, verschiedene Texte, ohne MC, Regel
select g.skill_key, g.klasse_herkunft kl, count(t.id) filter (where t.status='draft') draft, count(t.id) filter (where t.status='ready') ready,
       count(t.id) filter (where t.status not in ('draft','ready')) sonst, g.n_pool im_pool, g.n_text texte, g.n_ohne_mc ohne_mc, g.ok regel
  from regel g left join tasks t on t.skill_key = g.skill_key and 'lsa' = any (t.einsatz)
 group by 1,2,6,7,8,9 order by 2, 1;
```

#### Q39 · Feb–März 2027 Zusammenfassung: fehlende Skills je Klasse und vereinigt (Kl. 9 ∪ 10), draft dahinter, mit Bauform,

Ausführen: `cat basis.sql paket.sql q39.sql | dbread -f -`

```sql
-- C11 · Feb–März 2027 Zusammenfassung: fehlende Skills je Klasse und vereinigt (Kl. 9 ∪ 10), draft dahinter, mit Bauform,
--       nur mit gleichem Text blockiert (im Pool, aber < 2 Texte)
, fm as (
  select u.schule_id, u.klasse, u.position, 'A' fall from uvf u where u.feb_maerz and u.klasse in (9,10)
  union
  select u.schule_id, u.klasse, min(u.position), 'B' from uvf u
   where u.klasse in (9,10) and u.position > (select max(x.position) from uvf x where x.feb_maerz
                                                and x.schule_id = u.schule_id and x.klasse = u.klasse)
   group by 1,2),
fs as (select distinct f.klasse::text kl, ps.skill_key from fm f join paket_skill1 ps using (schule_id, klasse, position)
        where (f.fall = 'A' and ps.thema) or (f.fall = 'B' and ps.vorschau)),
z as (select kl, skill_key from fs union select '9+10', skill_key from fs)
select z.kl, count(*) fehlende_skills, sum(g.n_draft) draft,
       count(*) filter (where exists (select 1 from bauformen b where b.skill_key = z.skill_key)) mit_bauform,
       count(*) filter (where g.n_pool > 0) nur_textschluessel
  from z join regel g using (skill_key) where not g.ok group by 1 order by 1;
```

#### Q40 · Klassenarbeit im Datenmodell: schul_themenplan Kl. 8–10 (Zeilen, halbjahr, stunden, ohne Thema, Schulen mit

Ausführen: `dbread -f q40.sql`

```sql
-- Q40 · Klassenarbeit im Datenmodell: schul_themenplan Kl. 8–10 (Zeilen, halbjahr, stunden, ohne Thema, Schulen mit
--       halbjahr), schul_klassenarbeiten, lead_klassenarbeiten
select (select count(*) from schul_themenplan where klasse between 8 and 10) zeilen_8_10,
       (select count(halbjahr) from schul_themenplan where klasse between 8 and 10) mit_halbjahr,
       (select string_agg(distinct s.name, ', ') from schul_themenplan p join schulen s on s.id = p.schule_id
         where p.klasse between 8 and 10 and p.halbjahr is not null) schulen_mit_halbjahr,
       (select count(stunden) from schul_themenplan where klasse between 8 and 10) mit_stunden,
       (select count(*) from schul_themenplan where klasse between 8 and 10 and thema_key is null) ohne_thema,
       (select count(*) from schul_klassenarbeiten) schul_klassenarbeiten,
       (select count(*) from lead_klassenarbeiten) lead_ka_zeilen,
       (select count(distinct lead_id) from lead_klassenarbeiten) lead_ka_leads;
```

#### Q41 · Prüfmaschinen-Ergebnis an Aufgaben je Pool

Ausführen: `dbread -f q41.sql`

```sql
-- Q41 · Prüfmaschinen-Ergebnis an Aufgaben je Pool
select einsatz, count(*) aufgaben, count(*) filter (where pruefmaschine is not null and pruefmaschine <> '{}'::jsonb) mit_pruefmaschine
  from tasks group by 1 order by 1;
```

#### Q42 · Studio-Rollen

Ausführen: `dbread -f q42.sql`

```sql
-- Q42 · Studio-Rollen
select r.rolle, string_agg(p.full_name, ', ' order by p.full_name) personen from studio_rolle r join profiles p on p.id = r.person_id group by 1 order by 1;
```

## Anhang B · LSA-Pool je Skill [Q38]

| Skill | Kl. | draft | ready | sonst | im Pool | Texte | ohne MC | Regel |
|---|---|---|---|---|---|---|---|---|
| dezimal_add_sub | 5 | 8 | 3 | 0 | 3 | 1 | 3 | nein |
| geo_flaeche_rechteck | 5 | 4 | 2 | 0 | 2 | 2 | 2 | ja |
| geo_umfang | 5 | 4 | 2 | 0 | 2 | 2 | 2 | ja |
| groessen_laengen | 5 | 7 | 2 | 0 | 2 | 2 | 2 | ja |
| groessen_massen | 5 | 8 | 0 | 0 | 0 | 0 | 0 | nein |
| groessen_zeit | 5 | 9 | 0 | 0 | 0 | 0 | 0 | nein |
| runden_ueberschlag | 5 | 3 | 10 | 0 | 10 | 3 | 10 | ja |
| bruch_add | 6 | 7 | 0 | 0 | 0 | 0 | 0 | nein |
| bruch_dezimal | 6 | 2 | 4 | 0 | 4 | 1 | 4 | nein |
| bruch_div | 6 | 7 | 0 | 0 | 0 | 0 | 0 | nein |
| bruch_kuerzen | 6 | 4 | 3 | 0 | 3 | 1 | 3 | nein |
| bruch_mult | 6 | 7 | 0 | 0 | 0 | 0 | 0 | nein |
| dezimal_div | 6 | 6 | 3 | 0 | 3 | 1 | 3 | nein |
| dezimal_mult | 6 | 6 | 3 | 0 | 3 | 1 | 3 | nein |
| geo_koordinaten | 6 | 3 | 3 | 0 | 3 | 3 | 3 | ja |
| geo_massstab | 6 | 11 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_volumen_quader | 6 | 9 | 0 | 0 | 0 | 0 | 0 | nein |
| groessen_flaechen | 6 | 9 | 2 | 0 | 2 | 2 | 2 | ja |
| groessen_gemischt | 6 | 11 | 0 | 0 | 0 | 0 | 0 | nein |
| groessen_volumen | 6 | 10 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_flaeche_dreieck | 7 | 7 | 2 | 0 | 2 | 2 | 2 | ja |
| geo_winkel_summe | 7 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_beidseitig | 7 | 3 | 4 | 0 | 4 | 1 | 4 | nein |
| gleichung_einschrittig | 7 | 4 | 2 | 0 | 2 | 2 | 2 | ja |
| gleichung_neg_koeffizient | 7 | 5 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_zweischrittig | 7 | 2 | 4 | 0 | 4 | 2 | 4 | ja |
| potenzen | 7 | 5 | 19 | 0 | 19 | 8 | 19 | ja |
| proportionalitaet | 7 | 15 | 2 | 0 | 2 | 2 | 2 | ja |
| prozent_grundwert | 7 | 11 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_prozentsatz | 7 | 9 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_prozentwert | 7 | 9 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_veraenderung | 7 | 10 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_zins_jahreszins | 7 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_zins_rueckrechnung | 7 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_zins_teilzins | 7 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| prozent_zins_zinseszins | 7 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| term_ausklammern | 7 | 5 | 2 | 0 | 2 | 2 | 1 | ja |
| term_ausmultiplizieren | 7 | 3 | 4 | 0 | 4 | 3 | 4 | ja |
| term_einsetzen | 7 | 3 | 3 | 0 | 3 | 3 | 3 | ja |
| term_minusklammer | 7 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| term_zusammenfassen | 7 | 4 | 3 | 0 | 3 | 1 | 3 | nein |
| vorzeichen_add_sub | 7 | 0 | 7 | 0 | 7 | 3 | 7 | ja |
| vorzeichen_mult_div | 7 | 0 | 7 | 0 | 7 | 6 | 7 | ja |
| vorzeichen_vorrang | 7 | 6 | 3 | 0 | 3 | 2 | 3 | ja |
| fkt_linear_gleichung | 8 | 1 | 3 | 2 | 3 | 3 | 3 | ja |
| fkt_linear_graph | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_linear_nullstelle | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_linear_steigung | 8 | 4 | 2 | 0 | 2 | 2 | 2 | ja |
| fkt_linear_yabschnitt | 8 | 4 | 2 | 0 | 2 | 2 | 2 | ja |
| geo_flaeche_drachen_raute | 8 | 3 | 3 | 0 | 3 | 2 | 3 | ja |
| geo_flaeche_rueck | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_flaeche_term | 8 | 4 | 2 | 0 | 2 | 2 | 1 | ja |
| geo_flaeche_trapez | 8 | 4 | 2 | 0 | 2 | 2 | 2 | ja |
| geo_flaeche_zusammengesetzt | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_winkel_dreieck | 8 | 5 | 1 | 0 | 1 | 1 | 1 | nein |
| geo_winkel_neben_scheitel | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_winkel_parallelen | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_winkel_thales | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_lgs_addition | 8 | 4 | 2 | 0 | 2 | 2 | 1 | ja |
| gleichung_lgs_einsetzen | 8 | 3 | 3 | 0 | 3 | 3 | 3 | ja |
| gleichung_lgs_gleichsetzen | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_lgs_grafisch | 8 | 4 | 2 | 0 | 2 | 2 | 1 | ja |
| gleichung_lgs_sachaufgabe | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_modellieren | 8 | 7 | 3 | 0 | 3 | 3 | 3 | ja |
| stoch_gegenereignis | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_kenngroessen | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_laplace | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_pfad_produkt | 8 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_pfad_summe | 8 | 4 | 2 | 0 | 1 | 1 | 1 | nein |
| term_binom_faktorisieren | 8 | 4 | 2 | 0 | 2 | 2 | 1 | ja |
| term_binom_gemischt | 8 | 4 | 3 | 0 | 3 | 3 | 1 | ja |
| term_binom_quadrat | 8 | 2 | 5 | 0 | 5 | 5 | 1 | ja |
| term_binom_quadratdifferenz | 8 | 4 | 2 | 0 | 2 | 2 | 1 | ja |
| fkt_quadr_extrem | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_quadr_normalform | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_quadr_nullstellen | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_quadr_parabel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_quadr_scheitel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_aehnlich_flaeche | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_aehnlich_strahlen_abschnitt | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_aehnlich_strahlen_parallel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_aehnlich_streckfaktor | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_koerper_kegel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_koerper_kugel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_koerper_prisma | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_koerper_pyramide | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_koerper_zylinder | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_kreis_flaeche | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_kreis_rueck | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_kreis_sektor | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_kreis_umfang | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_kreis_zusammen | 9 | 0 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_pythagoras_abstand | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_pythagoras_anwendung | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_pythagoras_hypotenuse | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_pythagoras_kathete | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_pythagoras_umkehrung | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_quadr_anzahl | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_quadr_faktor | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_quadr_formel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| gleichung_quadr_wurzel | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_bedingt_irrefuehrend | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_bedingt_umkehr | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_bedingt_unabhaengig | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_bedingt_vierfeld | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| stoch_bedingt_wkeit | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| zahl_potenz_gesetze | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| zahl_potenz_negativ | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| zahl_potenz_rechnen | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| zahl_potenz_zehner | 9 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| zahl_wurzel_gesetze | 9 | 0 | 6 | 0 | 6 | 5 | 6 | ja |
| zahl_wurzel_irrational | 9 | 0 | 6 | 0 | 6 | 6 | 6 | ja |
| zahl_wurzel_naeherung | 9 | 0 | 6 | 0 | 6 | 5 | 6 | ja |
| zahl_wurzel_quadrat | 9 | 0 | 6 | 0 | 5 | 4 | 5 | ja |
| zahl_wurzel_teilweise | 9 | 0 | 6 | 0 | 6 | 4 | 6 | ja |
| fkt_exp_anwendung | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_exp_gleichung | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_exp_halbwert | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_exp_term | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_exp_wachstum | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_sinus_bogenmass | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_sinus_einheitskreis | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_sinus_graph | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_sinus_parameter | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| fkt_sinus_periodisch | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_trigo_anwendung | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_trigo_kosinussatz | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_trigo_seite | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_trigo_verhaeltnis | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
| geo_trigo_winkel | 10 | 6 | 0 | 0 | 0 | 0 | 0 | nein |
