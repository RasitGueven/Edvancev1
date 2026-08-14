# Sondierrang — Bericht zur Auswahl

**Erzeugt von `scripts/content/sondierrang_vorschlag.py`. Nicht von Hand pflegen.**

Vorschlag für `tasks.sondierrang` über **245 freigegebene
Fundament-Aufgaben** in **38 Skills**: je Skill eine Aufgabe auf Rang 1
und eine auf Rang 2, zusammen **76 `UPDATE`s** in
`scripts/sql/sondierrang_setzen.sql`. Alles Weitere bleibt `NULL`.

Das hier ist das Dokument, an dem das fachliche Urteil einsteigt. Der Agent hat
**nichts in die Datenbank geschrieben**; der Probelauf
(`scripts/sql/sondierrang_probelauf.sql`) setzt und verwirft wieder.

## Das Verfahren

Rang 1 kommt aus dem **breitesten Fehlbildprofil** — der Aufgabe, die die
meisten Denkfehler sichtbar machen kann. Rang 2 aus einem *anderen* Profil, denn
zwei Aufgaben desselben Profils zeigen dieselben Denkfehler; die zweite
Sondierung wäre verschenkt. Hat ein Skill nur ein Profil, entscheidet die
Zahlenwahl — kleinere Zahlen zuerst, gemessen als Summe der Zahlen im Fragetext.

Unter den übrigen Profilen wird für Rang 2 dasjenige gewählt, das **am meisten
Neues** beiträgt — nicht einfach das zweitbreiteste. Ein Profil, das ganz in
Rang 1 enthalten ist, zeigt nichts, was Rang 1 nicht schon zeigt.

## Überblick — was die zweite Sondierung einbringt

| | Skills |
|---|---|
| Rang 2 zeigt zusätzliche Fehlbilder | 8 |
| Rang 2 ist Teilmenge von Rang 1 — nichts Neues | 13 |
| nur ein Fehlbildprofil, Auswahl über die Zahlen | 17 |

Bei **13 Skills** ist das breiteste Profil eine Obermenge aller
übrigen: `bruch_add`, `bruch_mult`, `bruch_div`, `geo_flaeche_rechteck`, `bruch_dezimal`, `proportionalitaet`, `vorzeichen_vorrang`, `geo_massstab`, `gleichung_einschrittig`, `groessen_flaechen`, `groessen_volumen`, `prozent_prozentwert`, `prozent_prozentsatz`. Dort *kann* keine zweite Aufgabe ein neues Fehlbild
beitragen — das liegt am Bestand, nicht an der Auswahl. Wenn die zweite
Sondierung dort etwas zeigen soll, müssten die `known_errors` dieser Skills
ergänzt werden; das ist ein inhaltlicher Auftrag, kein technischer.

## Ein Befund, der die Durchsicht betrifft

Die Spec beschreibt das Fehlbildprofil als „die Menge der **Schlüssel** in
`task_solutions.acceptance -> 'known_errors'`". Die Daten sagen etwas anderes.
`known_errors` ist ein Objekt `{"<falsche Antwort>": "<Fehlbild>"}`:

```json
{"3/7": "nenner_addiert", "11/7": "nenner_addiert_zaehler_ok", "3/12": "zaehler_nicht_erweitert"}
```

Die **Schlüssel** sind die konkreten falschen Antworten. Sie hängen an den
Zahlen der jeweiligen Aufgabe und sind deshalb fast überall verschieden — nach
Schlüsseln gruppiert hätten 245 Aufgaben 231 „Profile", also praktisch je eines
pro Aufgabe. Das Kriterium könnte dann nichts bündeln, und „Rang 2 aus einem
anderen Profil" wäre für jedes beliebige Paar erfüllt.

Die **Werte** sind die Fehlbilder. Nach ihnen gruppiert hat jeder Skill ein bis
vier Profile — das ist die Achse, die die Spec inhaltlich meint („welche
Denkfehler eine Aufgabe sichtbar machen kann").

**Gewählt wurde nach den Werten.** `supabase/checks/sondierrang.PRUEFUNG.sql`
prüft in P4 nach Schlüsseln und bleibt unverändert; die Auswahl erzwingt
zusätzlich verschiedene Schlüsselprofile, wo ein Skill mehr als eines hat. Beide
Lesarten sind damit erfüllt. Sollte die Schlüssel-Lesart die gemeinte sein, ist
die Auswahl trotzdem gültig — nur die Begründungen unten wären dann hinfällig.

Zwei weitere Punkte fürs Protokoll:

- Die Spec spricht von „245 `UPDATE`s". Es sind **76** — 245 ist der Bestand,
  gesetzt werden nur Rang 1 und 2 je Skill. Eine vollständige Durchnummerierung
  schließen die Nicht-Ziele ausdrücklich aus, und P3 der Prüfung würde sie
  ablehnen.
- Die Vorlage trägt **kein Erzeugungsdatum** — weder vorher noch jetzt. Der
  befürchtete Datums-Lärm tritt hier nicht auf.

---

## `bruch_kuerzen` — Brüche kürzen

7 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `brueche-kuerzen-07` · Kürze den Bruch vollständig. 4/12 = ?
  - Fehlbilder: `additiv_gekuerzt`, `teilgekuerzt`
  - `9a70682a-428d-4b75-8567-e5d9f7cb607e`

- **Rang 2** · `brueche-kuerzen-03` · Kürze den Bruch vollständig. 8/12 = ?
  - Fehlbilder: `additiv_gekuerzt`, `teilgekuerzt`
  - `9a6bf378-2cd4-4ca5-afeb-bb856d5853f8`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `dezimal_add_sub` — Dezimalzahlen addieren/subtrahieren

8 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `dezimal-addieren-05` · Berechne. 0,25 + 0,4 = ?
  - Fehlbilder: `stellenwert_ignoriert`
  - `024143bf-840e-4ad5-aefe-b18c223aefcf`

- **Rang 2** · `dezimal-addieren-04` · Berechne. 0,6 + 0,4 = ?
  - Fehlbilder: `uebertrag_vergessen`
  - `be8ce7e4-d8f2-4b45-b6b1-447b102cf500`

Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile zeigen gleich viele Fehlbilder (1); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 2 Fehlbilder.

## `vorzeichen_add_sub` — Negative Zahlen addieren/subtrahieren

7 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `vorzeichen-addieren-01` · Berechne. -3 - 5 = ?
  - Fehlbilder: `betrag_fehler`, `mult_add_verwechslung`, `vorzeichen_ignoriert`
  - `e96cd37d-0254-4051-bf2d-71a6f7fa2aaf`

- **Rang 2** · `vorzeichen-addieren-04` · Berechne. -6 - 2 = ?
  - Fehlbilder: `betrag_fehler`, `mult_add_verwechslung`, `vorzeichen_ignoriert`
  - `27f51c08-6a47-4ceb-b189-f5f07cbcf1cf`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `bruch_add` — Brüche addieren

7 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `brueche-addieren-04` · Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/2 + 1/6 = ?
  - Fehlbilder: `nenner_addiert`, `nenner_addiert_zaehler_ok`, `teilgekuerzt`, `zaehler_nicht_erweitert`
  - `c81ae9db-193f-4154-9db9-d6062f21a587`

- **Rang 2** · `brueche-addieren-01` · Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/4 + 2/3 = ?
  - Fehlbilder: `nenner_addiert`, `nenner_addiert_zaehler_ok`, `zaehler_nicht_erweitert`
  - `d0c1132b-4d85-4f7a-867e-22d6f36f6415`

Rang 1 aus dem breitesten Fehlbildprofil (4 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `bruch_mult` — Brüche multiplizieren

7 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `brueche-multiplizieren-02` · Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 2/3 · 3/4 = ?
  - Fehlbilder: `hauptnenner_bei_mult`, `teilgekuerzt`
  - `590b9c87-620f-4d53-90fc-fe6d40d16cba`

- **Rang 2** · `brueche-multiplizieren-04` · Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/2 · 3/5 = ?
  - Fehlbilder: `hauptnenner_bei_mult`
  - `f7175bad-c4e5-469c-bbf4-6b8c1ca0215e`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `dezimal_mult` — Dezimalzahlen multiplizieren

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `dezimal-multiplizieren-01` · Berechne. 0,3 · 0,4 = ?
  - Fehlbilder: `komma_ignoriert`, `kommastellen_zu_viel`, `kommastellen_zu_wenig`
  - `3038721a-abdd-4030-b683-33b3e8d3efb9`

- **Rang 2** · `dezimal-multiplizieren-02` · Berechne. 0,2 · 0,7 = ?
  - Fehlbilder: `komma_ignoriert`, `kommastellen_zu_viel`, `kommastellen_zu_wenig`
  - `3d066cef-b5e1-45db-b560-dd86d1c5b38c`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `runden_ueberschlag` — Runden und Überschlag

10 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `runden-02` · Runde auf eine Nachkommastelle. 2,85 = ?
  - Fehlbilder: `abgeschnitten`, `falsche_stelle`
  - `0cd53103-432c-41a2-9f48-383c1f7580cd`

- **Rang 2** · `runden-08` · Runde auf eine Nachkommastelle. 3,71 = ?
  - Fehlbilder: `falsche_stelle`, `immer_aufgerundet`
  - `4ff59e5f-dab3-4ef4-80bd-ad7e96e11080`

Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile zeigen gleich viele Fehlbilder (2); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 3 Fehlbilder.

## `vorzeichen_mult_div` — Negative Zahlen multiplizieren/dividieren

7 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `vorzeichen-punktrechnung-01` · Berechne. -3 · 5 = ?
  - Fehlbilder: `mult_add_verwechslung`, `vorzeichen_ignoriert`
  - `0438a9f9-bdb4-4f29-ab59-adc7946ade36`

- **Rang 2** · `vorzeichen-punktrechnung-02` · Berechne. -4 · (-6) = ?
  - Fehlbilder: `mult_add_verwechslung`, `vorzeichen_ignoriert`
  - `2e8ce53f-1357-48b2-8d76-0633ae836980`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `bruch_div` — Brüche dividieren

7 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `brueche-dividieren-02` · Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/2 : 3/4 = ?
  - Fehlbilder: `falschen_gestuerzt`, `nicht_gestuerzt`, `teilgekuerzt`
  - `6e2e4f8f-3442-4cf9-90da-2623554106f0`

- **Rang 2** · `brueche-dividieren-03` · Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 3/4 : 2/3 = ?
  - Fehlbilder: `falschen_gestuerzt`, `nicht_gestuerzt`
  - `802069f8-d538-4d03-a4cb-e31af86593a6`

Rang 1 aus dem breitesten Fehlbildprofil (3 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `dezimal_div` — Dezimalzahlen dividieren

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `dezimal-dividieren-06` · Berechne. 1,2 : 0,3 = ?
  - Fehlbilder: `falsche_richtung`, `komma_nicht_verschoben`
  - `6b531762-47e8-4b29-aeee-ce70b560486a`

- **Rang 2** · `dezimal-dividieren-04` · Berechne. 2,4 : 0,4 = ?
  - Fehlbilder: `falsche_richtung`, `komma_nicht_verschoben`
  - `bdf4d10a-9cf2-4ed5-a59b-54fec4b3851f`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `geo_flaeche_rechteck` — Fläche von Rechteck und Quadrat

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `geo-flaeche-rechteck-01` · Ein Rechteck ist 4 cm lang und 7 cm breit. Wie groß ist die Fläche in cm²?
  - Fehlbilder: `nur_eine_seite`, `plus_statt_mal`, `umfang_statt_flaeche`
  - `008adff9-e38e-4620-a6aa-97862f85367d`

- **Rang 2** · `geo-flaeche-rechteck-04` · Ein Quadrat hat die Seitenlänge 5 cm. Wie groß ist die Fläche in cm²?
  - Fehlbilder: `plus_statt_mal`, `umfang_statt_flaeche`
  - `af8ccf14-4373-4bb9-b892-c650265dd0cd`

Rang 1 aus dem breitesten Fehlbildprofil (3 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `geo_umfang` — Umfang von Rechteck und Dreieck

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `geo-umfang-03` · Ein Rechteck ist 3 cm lang und 7 cm breit. Wie groß ist der Umfang in cm?
  - Fehlbilder: `flaeche_statt_umfang`, `nur_einmal_addiert`
  - `485f81e3-48fb-47c7-b333-964baa6ad10c`

- **Rang 2** · `geo-umfang-04` · Ein Dreieck hat die Seiten 6 cm, 7 cm und 9 cm. Wie groß ist der Umfang in cm?
  - Fehlbilder: `seite_vergessen`
  - `e09a9496-8650-4a39-b2be-e54e512b8cab`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 3 Fehlbilder.

## `geo_winkel_summe` — Winkelsummen im Dreieck und Viereck

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `geo-winkel-summe-01` · In einem Dreieck sind zwei Winkel 50° und 60° groß. Wie groß ist der dritte Winkel in Grad?
  - Fehlbilder: `differenz_vergessen`, `summe_360_statt_180`
  - `c3e86490-5d41-4f55-9aa8-b170123409b8`

- **Rang 2** · `geo-winkel-summe-04` · In einem Viereck sind drei Winkel 90°, 90° und 100° groß. Wie groß ist der vierte Winkel in Grad?
  - Fehlbilder: `differenz_vergessen`, `summe_180_statt_360`
  - `60d58ee6-d2cd-40f3-985d-fe0a1ed8ec4e`

Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile zeigen gleich viele Fehlbilder (2); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 3 Fehlbilder.

## `groessen_laengen` — Längen umrechnen

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `groessen-laengen-01` · Wandle um. 3 m = ? cm
  - Fehlbilder: `einheit_uebersprungen`, `faktor_zehn_daneben`, `richtung_vertauscht`
  - `62bbb1fe-9401-4ac2-8b24-e5a603f77e22`

- **Rang 2** · `groessen-laengen-03` · Wandle um. 4,2 m = ? mm
  - Fehlbilder: `einheit_uebersprungen`, `faktor_zehn_daneben`, `richtung_vertauscht`
  - `b9e84b84-77df-42d9-b34e-f6ccc283e930`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `groessen_massen` — Massen umrechnen

5 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `groessen-massen-01` · Wandle um. 3 kg = ? g
  - Fehlbilder: `faktor_hundert_statt_tausend`, `faktor_zehn_daneben`, `richtung_vertauscht`
  - `4e34f73b-5593-4807-91a4-b9c5d3fada5d`

- **Rang 2** · `groessen-massen-03` · Wandle um. 4 t = ? kg
  - Fehlbilder: `faktor_hundert_statt_tausend`, `faktor_zehn_daneben`, `richtung_vertauscht`
  - `5d6a704a-cc38-4144-adee-ad396d532457`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `bruch_dezimal` — Bruch in Dezimalzahl

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `dezimal-umwandeln-03` · Schreibe den Bruch als Dezimalzahl. 1/2 = ?
  - Fehlbilder: `umgekehrt_geteilt`, `ziffern_gelesen`
  - `de2aabbf-8988-47d4-9f51-c4e80232b374`

- **Rang 2** · `dezimal-umwandeln-01` · Schreibe den Bruch als Dezimalzahl. 3/4 = ?
  - Fehlbilder: `ziffern_gelesen`
  - `6ef85b4a-1f14-49b4-acf6-05aa01567e4f`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `geo_flaeche_dreieck` — Fläche von Dreieck und Parallelogramm

7 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `geo-flaeche-dreieck-05` · Ein Parallelogramm hat die Grundseite 7 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 5 cm lang. Wie groß ist die Fläche in cm²?
  - Fehlbilder: `falsche_hoehe`, `halbieren_faelschlich`
  - `d602bc49-3ee0-48fb-8cd3-467b2ae0abc2`

- **Rang 2** · `geo-flaeche-dreieck-04` · Ein Dreieck hat die Grundseite 6 cm und die zugehörige Höhe 8 cm. Eine weitere Seite ist 5 cm lang. Wie groß ist die Fläche in cm²?
  - Fehlbilder: `falsche_hoehe`, `halbieren_vergessen`
  - `ecb3d12b-a21e-4031-b562-a1596deeb815`

Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile zeigen gleich viele Fehlbilder (2); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 3 Fehlbilder.

## `geo_volumen_quader` — Volumen und Oberfläche des Quaders

7 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `geo-volumen-quader-01` · Ein Quader hat die Kanten 2 cm, 3 cm und 4 cm. Wie groß ist das Volumen in cm³?
  - Fehlbilder: `oberflaeche_statt_volumen`, `zwei_kanten`
  - `6a448f69-d164-4cf6-82ca-461a8bae980f`

- **Rang 2** · `geo-volumen-quader-05` · Ein Quader hat die Kanten 2 cm, 3 cm und 5 cm. Wie groß ist die Oberfläche in cm²?
  - Fehlbilder: `mal_zwei_vergessen`, `volumen_statt_oberflaeche`
  - `7d305269-159f-40cc-9965-c343c2bb4c15`

Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile zeigen gleich viele Fehlbilder (2); Rang 2 aus dem Profil, das am meisten Neues beitraegt (2 weitere Fehlbilder) — zusammen 4 Fehlbilder.

## `groessen_zeit` — Zeitspannen umrechnen

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `groessen-zeit-02` · Wandle um. 66 min = ? h
  - Fehlbilder: `dezimal_statt_sexagesimal`, `faktor_hundert_statt_sechzig`, `richtung_vertauscht`
  - `b1ede380-80c7-44df-9263-dad843ee33d5`

- **Rang 2** · `groessen-zeit-05` · Wandle um. 75 min = ? h
  - Fehlbilder: `dezimal_statt_sexagesimal`, `faktor_hundert_statt_sechzig`, `richtung_vertauscht`
  - `9f7f0cd7-128b-4a4d-9281-16c78804a1b4`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `potenzen` — Potenzen und Quadratzahlen

3 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `potenzen-14` · Berechne. -2^2 = ?
  - Fehlbilder: `vorzeichen_potenz`
  - `a3343b39-bedb-491f-a214-6b6817ce2768`

- **Rang 2** · `potenzen-15` · Berechne. √36 = ?
  - Fehlbilder: `wurzel_halbiert`
  - `aef364ee-8c7f-49af-9e55-c2c65b7e36db`

Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile zeigen gleich viele Fehlbilder (1); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 2 Fehlbilder.

## `proportionalitaet` — Dreisatz, proportionale Zuordnung

14 Aufgaben · 4 Fehlbildprofile

- **Rang 1** · `proportionalitaet-02` · 2 Hefte kosten 3 €. Was kosten 6 Hefte?
  - Fehlbilder: `antiproportional_verwechselt`, `einheit_verrutscht`, `falscher_bezug`
  - `82215b1c-332b-4ca4-b167-090460b594bd`

- **Rang 2** · `proportionalitaet-01` · 2 L Saft kosten 3 €. Was kosten 4 L?
  - Fehlbilder: `antiproportional_verwechselt`, `einheit_verrutscht`
  - `9372380c-8cf0-47a1-9fb5-330d44b6a975`

Rang 1 aus dem breitesten Fehlbildprofil (3 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `term_zusammenfassen` — Terme zusammenfassen

7 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `term-zusammenfassen-01` · Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 3x + 5 + 2x - 1 = ?
  - Fehlbilder: _(keine gepflegt)_
  - `df219b8c-887d-43c2-b544-ca2df4f32e66`

- **Rang 2** · `term-zusammenfassen-02` · Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 4x + 9 + 3x - 2 = ?
  - Fehlbilder: _(keine gepflegt)_
  - `c83b34e8-e6e7-4142-83ff-fae510201c5c`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `vorzeichen_vorrang` — Vorrangregeln mit Vorzeichen

7 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `vorzeichen-vorrang-01` · Berechne. 4 + (-2) · 3 = ?
  - Fehlbilder: `vorrang_ignoriert`, `vorzeichen_ignoriert`
  - `573dd0b7-5fd2-4b4e-9263-3630affba5da`

- **Rang 2** · `vorzeichen-vorrang-03` · Berechne. -3 + 4 · 2 = ?
  - Fehlbilder: `vorrang_ignoriert`
  - `a394b2eb-df58-4b57-9c79-ae8ff0c62b24`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `geo_massstab` — Maßstab

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `geo-massstab-04` · Auf einer Karte im Maßstab 1:100 ist eine Strecke 25 cm lang. Wie lang ist die Strecke in Wirklichkeit in m?
  - Fehlbilder: `einheit_ignoriert`, `faktor_zehn_daneben`, `richtung_vertauscht`
  - `ceb26573-de3f-488a-9956-6a8cf7eb81cf`

- **Rang 2** · `geo-massstab-01` · Auf einer Karte im Maßstab 1:25000 ist eine Strecke 4 cm lang. Wie lang ist die Strecke in Wirklichkeit in km?
  - Fehlbilder: `einheit_ignoriert`, `faktor_zehn_daneben`
  - `fe3a88b0-7d72-4896-929c-b7f0c379cfa3`

Rang 1 aus dem breitesten Fehlbildprofil (3 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `gleichung_einschrittig` — Einschrittige Gleichungen

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `gleichung-einschrittig-02` · Löse die Gleichung. Gib den Wert für x an. x − 4 = 9
  - Fehlbilder: `falsche_gegenoperation`, `seiten_verwechselt`
  - `4f6f7cdd-3415-4185-8eae-95083d061b71`

- **Rang 2** · `gleichung-einschrittig-03` · Löse die Gleichung. Gib den Wert für x an. 3x = 18
  - Fehlbilder: `falsche_gegenoperation`
  - `152bcdcd-897b-452b-9a8f-402375540a3f`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `groessen_flaechen` — Flächeneinheiten

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `groessen-flaechen-01` · Wandle um. 3 dm² = ? cm²
  - Fehlbilder: `einheit_uebersprungen`, `linearer_faktor`, `richtung_vertauscht`
  - `b7b814a6-d2c9-4988-855c-3d51b5148da0`

- **Rang 2** · `groessen-flaechen-04` · Wandle um. 3000000 mm² = ? m²
  - Fehlbilder: `einheit_uebersprungen`, `linearer_faktor`
  - `f531dcee-04cf-4e14-ad5e-9032f72f0668`

Rang 1 aus dem breitesten Fehlbildprofil (3 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `groessen_gemischt` — Gemischte Schreibweise

6 Aufgaben · 4 Fehlbildprofile

- **Rang 1** · `groessen-gemischt-04` · Wandle um. 2,5 h = ? min
  - Fehlbilder: `dezimal_statt_sexagesimal`, `komma_als_trenner`
  - `20cdce1e-0e9d-478d-820e-b77ff90c94bc`

- **Rang 2** · `groessen-gemischt-01` · Wandle um. 1,05 m = ? cm
  - Fehlbilder: `fuehrende_null_ignoriert`
  - `2a55970e-6a27-496b-8229-35813122e30b`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus dem Profil, das am meisten Neues beitraegt (1 weiteres Fehlbild) — zusammen 3 Fehlbilder.

## `term_ausmultiplizieren` — Ausmultiplizieren

7 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `term-ausmultiplizieren-01` · Multipliziere aus. Gib das Ergebnis in der Form ax + b an. 3(x + 2) = ?
  - Fehlbilder: _(keine gepflegt)_
  - `1527a939-6199-4d8c-9163-6f34b0cd0e13`

- **Rang 2** · `term-ausmultiplizieren-04` · Multipliziere aus. Gib das Ergebnis in der Form ax + b an. -3(x + 2) = ?
  - Fehlbilder: _(keine gepflegt)_
  - `10a764bc-9657-4a5a-b11d-64b2a0014b05`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `gleichung_zweischrittig` — Zweischrittige Gleichungen

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `gleichung-zweischrittig-02` · Löse die Gleichung. Gib den Wert für x an. 2x + 4 = 20
  - Fehlbilder: `addiert_statt_subtrahiert`, `b_ignoriert`, `division_vergessen`
  - `e8348c89-67cb-4650-be91-235e69321776`

- **Rang 2** · `gleichung-zweischrittig-01` · Löse die Gleichung. Gib den Wert für x an. 3x + 6 = 24
  - Fehlbilder: `addiert_statt_subtrahiert`, `b_ignoriert`, `division_vergessen`
  - `7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `groessen_volumen` — Volumeneinheiten

5 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `groessen-volumen-01` · Wandle um. 2 l = ? cm³
  - Fehlbilder: `linearer_faktor`, `liter_kubik_falsch`, `richtung_vertauscht`
  - `34d5e69b-f8c9-4837-8dc8-84c73400141d`

- **Rang 2** · `groessen-volumen-04` · Wandle um. 4 dm³ = ? cm³
  - Fehlbilder: `linearer_faktor`, `richtung_vertauscht`
  - `d36af517-b33f-4633-8a86-57cacc015bfd`

Rang 1 aus dem breitesten Fehlbildprofil (3 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `prozent_prozentwert` — Prozentwert berechnen

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `prozent-wert-03` · Ein Rucksack kostet 60 €. Der Preis wird um 25 % reduziert. Wie viel Euro beträgt die Ermäßigung?
  - Fehlbilder: `dezimalverschiebung`, `grundwert_verwechselt`
  - `4d9e1f4d-8f87-4bbe-a6b4-cdbd459bfc1f`

- **Rang 2** · `prozent-wert-01` · Ein Pullover kostet 80 €. Der Preis wird um 15 % reduziert. Wie viel Euro beträgt die Ermäßigung?
  - Fehlbilder: `dezimalverschiebung`
  - `8337d39e-ff22-4393-94e5-35f0c835cd45`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `term_minusklammer` — Minusklammer auflösen

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `term-minusklammer-01` · Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 5 - (2x - 3) = ?
  - Fehlbilder: _(keine gepflegt)_
  - `04cc98ff-2c04-4bd4-9db9-3947a1e8fbd3`

- **Rang 2** · `term-minusklammer-03` · Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 7 - (4x - 2) = ?
  - Fehlbilder: _(keine gepflegt)_
  - `ba6f456d-2525-4989-8da7-937501699018`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `gleichung_beidseitig` — Beidseitige Gleichungen

5 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `gleichung-beidseitig-02` · Löse die Gleichung. Gib den Wert für x an. 4x + 2 = 2x + 14
  - Fehlbilder: `falsches_vorzeichen_beim_zusammenfuehren`, `variablen_nicht_zusammengefuehrt`
  - `e647e2ec-7e4c-404d-96cd-b6f402b6a981`

- **Rang 2** · `gleichung-beidseitig-01` · Löse die Gleichung. Gib den Wert für x an. 5x + 3 = 2x + 18
  - Fehlbilder: `falsches_vorzeichen_beim_zusammenfuehren`, `variablen_nicht_zusammengefuehrt`
  - `19ba5f42-6cd4-4191-afe0-fd8a09c4ac35`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `gleichung_neg_koeffizient` — Gleichungen mit negativem Koeffizienten

5 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `gleichung-negativ-03` · Löse die Gleichung. Gib den Wert für x an. 15 − 5x = 5
  - Fehlbilder: `division_vergessen`, `vorzeichen_beim_umstellen`
  - `4a0fe6b6-7b4f-436f-9788-8579b3a218f8`

- **Rang 2** · `gleichung-negativ-02` · Löse die Gleichung. Gib den Wert für x an. 20 − 4x = 8
  - Fehlbilder: `division_vergessen`, `vorzeichen_beim_umstellen`
  - `b11655f3-ac29-4030-9e82-49d5371d2f04`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `prozent_grundwert` — Grundwert berechnen

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `prozent-grundwert-01` · 12 Bücher sind 15 % aller Bücher. Wie viele Bücher sind es insgesamt?
  - Fehlbilder: `dezimalverschiebung`, `multipliziert_statt_dividiert`
  - `7875948d-3789-43cb-8e1a-861de7167ece`

- **Rang 2** · `prozent-grundwert-05` · 12 Hefte sind 25 % aller Hefte. Wie viele Hefte sind es insgesamt?
  - Fehlbilder: `dezimalverschiebung`, `multipliziert_statt_dividiert`
  - `7eba6b75-1852-4713-8f6b-bf0e626fa52b`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `prozent_prozentsatz` — Prozentsatz berechnen

6 Aufgaben · 2 Fehlbildprofile

- **Rang 1** · `prozent-satz-03` · Von 60 Schülerinnen und Schülern haben 15 eine Eins. Wie viel Prozent sind das?
  - Fehlbilder: `bezug_vertauscht`, `faktor_100_vergessen`
  - `846c8ff7-9816-4ac7-b75a-3e51954270db`

- **Rang 2** · `prozent-satz-01` · Von 80 Schülerinnen und Schülern haben 12 eine Eins. Wie viel Prozent sind das?
  - Fehlbilder: `faktor_100_vergessen`
  - `fee8aa29-db31-46e0-a21b-fe17279e7813`

Rang 1 aus dem breitesten Fehlbildprofil (2 Fehlbilder); Rang 2 aus einem anderen Profil, das aber eine Teilmenge des ersten ist — mehr gibt der Bestand hier nicht her, die zweite Sondierung zeigt kein zusaetzliches Fehlbild.

## `term_ausklammern` — Ausklammern

6 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `term-ausklammern-01` · Klammere so weit wie möglich aus. Welcher Term ist richtig? 4x + 8 = ?
  - Fehlbilder: _(keine gepflegt)_
  - `4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af`

- **Rang 2** · `term-ausklammern-02` · Klammere so weit wie möglich aus. Welcher Term ist richtig? 6x + 12 = ?
  - Fehlbilder: _(keine gepflegt)_
  - `65841bd8-ee27-454f-b2a4-ea6f1bb0db33`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.

## `prozent_veraenderung` — Prozentuale Veränderung

5 Aufgaben · 1 Fehlbildprofil

- **Rang 1** · `prozent-veraenderung-04` · Ein Buch kostet 60 €. Der Preis sinkt um 25 %. Wie viel Euro kostet es danach?
  - Fehlbilder: `falsche_richtung`, `nur_prozentwert`
  - `2155cd07-b21f-46d1-a1d9-bb78345641d8`

- **Rang 2** · `prozent-veraenderung-02` · Ein Pullover kostet 80 €. Der Preis sinkt um 25 %. Wie viel Euro kostet es danach?
  - Fehlbilder: `falsche_richtung`, `nur_prozentwert`
  - `be903a02-c572-4378-96cf-b264ee161494`

Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.
