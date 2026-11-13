# SF-1 · Offene Punkte

Stand 13.11.2026 (S2). Quellen: `docs/msa/quellen/` (Lehrplannavigator NRW, Abruf 12.11.2026). Seiten 2004 =
PDF-Seite = gedruckte Seite; Seiten 2022 als PDF-Seite (gedruckt = PDF + 1).

## 1 · KLP-Inhalte Kl. 7–10 ohne Gegenstück in `themen`

Nicht erfunden und keinem Thema zugeschlagen. Sie fehlen deshalb in `klp_themenplan` und in den Paketen.

| Inhalt | Fundstelle |
|---|---|
| Multiplikation und Division von Brüchen (in `themen` nur Kl. 5/6) | RS/GESK 2022 PDF-S. 31, KE (1) |
| Kombinatorik | RS 2022 PDF-S. 40, KE (4); GESK 2022 dort fett (nur E) |
| Logarithmieren als Umkehrung des Potenzierens | RS 2022 PDF-S. 37, KE (11); GESK 2022 fett (nur E) |
| Symmetrie als Begründungsmittel | RS 2004 S. 25; GE 2004 S. 25 kursiv-fett (nur E) |
| Viereckstypen benennen und charakterisieren | RS/GE 2004 S. 25 (nur zum Teil in `flaechen_vielecke`) |
| Netze und Schrägbilder von Zylinder, Pyramide, Kegel | RS/GE 2004 S. 30 (eher Teil der Körperthemen) |
| Funktionale Zusammenhänge in Messreihen mit digitalen Medien | RS 2022 PDF-S. 39, KE (12); GESK 2022 fett |
| Maßangaben in Sachsituationen | RS/GESK 2022 PDF-S. 40, KE (7) |
| Tabellenkalkulation mit relativen und absoluten Zellbezügen | RS/GESK 2022 PDF-S. 33, KE (9) |
| Simulation von Zufallserscheinungen | RS/GESK 2022 PDF-S. 35, KE (4) |

## 2 · Zuordnungen mit Unsicherheit

- **Nur aus dem Schriftschnitt abgeleitet.** E-Kurs-Zeilen und viele `nur_teil`-Angaben stützen sich auf Fett bzw.
  Kursiv-fett, nicht auf einen wörtlichen „G-Kurs“-Vermerk. Am ehesten nachsehen: GE 2004 S. 25 (lineare
  Zuordnungen, Winkelsätze) und S. 30 („und exponentielle“ ist fett, der Vermerk „(G-Kurs; Eigenschaften
  exponentiellen Wachstums)“ aber nicht).
- **GESK 2022, lineare Zuordnungen (PDF-S. 32).** Der Schwerpunkt ist nicht fett, die passenden Kompetenzerwartungen
  (4) bis (6) sind es teilweise. Eingetragen als `alle` mit Einschränkung.
- **`terme_binomische_formeln`.** GE 2004 steht als `alle` mit „kein Produkt von Summen“ (wörtlich), GESK 2022 als
  `E` (nur fett). Beide könnten auch einheitlich `E` sein.
- **`daten_streumasse` 7/8 nur E** (GE 2004, GESK 2022). Ohne E bleibt dem G-Kurs dort nichts Eigenes.
- **`prismen_zylinder`.** Prismen stehen in 7/8, Zylinder erst in 9/10. Nach der Regel „erste Nennung“ ist das Thema
  nur in 7/8 eingetragen.
- **Erste Nennung vor dem Hauptteil.** `lineare_funktionen` (RS 2022: in 7/8 „lineare Zuordnungen“, Steigung erst
  9/10) und `zufallsexperimente` (zweistufig erst 9/10) sind 7/8 zugeordnet.
- **`thales_konstruktionen`.** RS 2004 kennt nur den Satz des Thales (Ende 10). 2022 steht er schon in 7/8, zusammen
  mit der Mittelsenkrechten. Winkelhalbierende, Höhen sowie In- und Umkreis nennt kein Plan wörtlich.
- **`koerper_quader`.** Nur RS 2004 nennt ihn Ende 8. In GE 2004 und in beiden 2022-Plänen steht er nur in Kl. 5/6.
  Auch in RS 2004 verlangt schon Ende 6 Netze sowie Oberfläche und Volumen von Quadern (S. 21). Die Zeile 7/8 bleibt,
  weil `klp_themenplan` nur Kl. 7–10 abbildet.
- **Reihenfolge im Doppeljahrgang.** Der KLP legt keine fest. `position` folgt der üblichen Lage am Gymnasium
  (`quellen/g9_klassen.csv`). Ein Thema, das am Gymnasium in Kl. 9 liegt, kommt so auch in RS/GE eher früh in 9/10.

## 3 · Sperren mit Unsicherheit (`skill_schulform`)

- **`stoch_bedingt_unabhaengig`** ist für RS/GE/SK in allen Fassungen gesperrt: Nur der KLP G9 nennt die
  stochastische Unabhängigkeit (PDF-S. 35). **`stoch_bedingt_umkehr`** ist nur für 2004 und den G-Kurs 2022
  gesperrt. Kein Plan nennt das Umkehren ausdrücklich, auch G9 nicht; es läuft über die Vierfeldertafel, die 2022
  verlangt (fachliche Zweitprüfung 13.11.2026).
- **G-Kurs 2022, quadratische Funktionen.** Gesperrt sind nur Normalform → Scheitelpunktform und Scheitelpunktform
  (fett). `fkt_quadr_parabel` bleibt zulässig, weil der G-Kurs strecken und entlang der y-Achse verschieben darf, nur
  nicht entlang der x-Achse. Zulässig bleiben auch `fkt_quadr_nullstellen` und `fkt_quadr_extrem` (nicht fett).
  Für 2004 („nur f(x)=ax²“) sind alle fünf gesperrt.
- **G-Kurs, Exponentialfunktionen.** Zulässig sind `fkt_exp_wachstum` und `fkt_exp_halbwert` (Eigenschaften bzw.
  Wachstumsprozesse). Gesperrt sind Term, Gleichung und Anwendung (Zeitpunkte berechnen).
- **Ganze Themen nur im E-Kurs** (LGS, Trigonometrie, Sinus, Thales in GE 2004; LGS, Trigonometrie, Sinus,
  bedingte Wahrscheinlichkeit in GESK 2022) stehen als `kurs = 'E'` in `klp_themenplan`, nicht als Skill-Sperre für
  den G-Kurs. Ein G-Kurs-Kind bekommt sie also nicht über das Paket, die LSA kann sie aber noch ziehen. Das muss der
  folgende LSA-Auftrag entscheiden.
- **Sekundarschule bis ZP10 2027.** Laut `docs/msa/quellen/README.md` gilt der KLP GE 2004 oder der KLP RS 2004.
  Eingetragen sind die GE-Zeilen.

## 4 · Zu entscheiden (aus der Zweitprüfung S2)

- **Gewicht der klp-Pakete.** `inhalte_*`, `lsa_abdeckung`, `lsa_wirkung`, `pruef_ziel_liste` und `lsa_status_roh`
  behandeln `'klp'` wie `'geschaetzt'`, weil sie nur `= 'bestaetigt'` filtern. Mit 57 Schulen ohne Plan neben
  32 Gymnasien mit Plan bestimmen die klp-Schätzungen jetzt die Mehrheitsklasse je Thema, die Quartalsfenster und
  `hebel_schulen`. S4 bringt den Filter nach Schulform; ob `'klp'` dort niedriger gewichtet werden soll, ist offen.
- **Gymnasien mit Teilplan** bekommen für Klassen ohne Plan weder Plan- noch klp-Pakete (Auftrag: nur Schulen ganz
  ohne Plan). Betroffen 13.11.2026: Brügelmannstraße (nur Kl. 5), Müngersdorf (5–8), Nippes (5–7), Heinrich-Mann
  (5–9), Hildegard-von-Bingen und Leonardo-da-Vinci (7–9), Maximilian-Kolbe (5–8).
- **Sinus in Klasse 10 nach KLP 2004 (RS/GE/SK) ohne Einstieg.** Einziger Einstieg von `sinusfunktion` ist
  `fkt_sinus_parameter` (a·sin(b·x)), für 2004 gesperrt. Das Paket steht deshalb mit `hat_einstieg = false` (rot).
  `fkt_sinus_graph` bleibt als Voraussetzung im Paket, weil der Filter nur den gesperrten Skill selbst entfernt.
  Lösung wäre ein Einstieg „Graph der Sinusfunktion“ für 2004. Ähnlich, aber nicht durch SF-1 verursacht:
  `daten_streumasse` und `koerper_quader` haben gar keinen Einstieg.
- **Klasse 10 ohne Folgejahr.** Für `spaeter` greift dort weiter `lsa_klp_themen('mathematik', 11)` (G9). Das wirkt
  nur auf die Abgrenzung der Rand-Skills.
- **`skill_schulform.zulaessig = true`** wirkt nirgends; alle Zeilen sind Sperren. `skill_zulaessig` ist invoker:
  Wer die Tabelle nicht lesen darf, bekommt immer „zulässig“. Der LSA-Auftrag muss sie aus einer Definer-Funktion
  aufrufen.
- **Hauptschule** ist als Schulform erlaubt, hat aber keine Zeilen in `klp_themenplan`. Eine Hauptschule bekäme
  keine Pakete. In Köln ist keine angelegt.
- **Sperren verschwinden mit dem Skill** (`on delete cascade`, nötig für bestehende Tests, die Skills löschen). Wird
  ein Skill gelöscht und neu angelegt, ist er wieder zulässig.
- **Sperrfilter gilt für jede Schule mit Schulform.** Bekommt eine Real- oder Gesamtschule später einen eigenen Plan,
  fallen auch dort gesperrte Skills aus den Paketen. Das ist gewollt, aber nicht durch einen Test abgesichert.

## 5 · Aus S1

- Der Lead trägt nur den Mathe-Kurs. E/G für Englisch und Deutsch ist am Lead nicht erfassbar (`kind_kurs` könnte es).
- `stadtteil` der 46 neuen Schulen ist leer, die Gymnasien haben keine Schulnummer.
- ESA (nach Kl. 9) ist nicht erfassbar.
