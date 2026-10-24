# Figurenbedarf F1 · Pilot-Aufgaben

Stand 18.10.2026. Alle Zahlen per `~/bin/dbread` gegen Produktion (nur lesend). Nicht committet. Erzeugt wird hier nichts, das ist F2.

## Kurzfassung

| Gruppe | Aufgaben | A nötig | davon Figur vorhanden | B hilfreich | C nicht nötig | D mangelhaft |
|---|---|---|---|---|---|---|
| Stufe 3 | 92 | 10 | 5 | 19 | 63 | 0 |
| Stufe 1 | 30 | 0 | 0 | 0 | 30 | 0 |
| Stufe 2 | 93 | 0 | 0 | 0 | 93 | 0 |
| Session | 49 | 1 | 0 | 1 | 47 | 0 |
| **gesamt (ohne Doppelzählung)** | 257 | 11 | 5 | 20 | 226 | 0 |

`vorzeichen_add_sub` (7 Aufgaben, alle C) gehört zu Stufe 2 und zur Session und steht in beiden Zeilen.

**Knoten, die nicht reichen, wenn Lena nur Aufgaben ohne A oder D nimmt:**

- **Session `gleichung_quadr_formel`**: 5 von Soll 6. Die Session braucht alle sechs Aufgaben, 5b36238f (Weg um das Beet) ist A. Zuerst diese Figur (Generator `rechtecke`, Rahmen).
- **Stufe 3 `gleichung_lgs_grafisch`**: nur streng gezählt. Fünf Aufgaben sind A, haben aber schon eine passende Figur. Ohne sie bliebe nur 49e51e4e (MC), also 1 von 2 und keine ohne MC. Zählt man die vorhandenen Figuren als erledigt, reicht der Knoten (6, davon 4 ohne MC). Keine neue Figur nötig.
- **Stufe 3 `geo_winkel_thales` reicht nur knapp**: Nach Abzug der vier A-Aufgaben bleiben genau die zwei Aufgaben, die das Soll braucht (22e90366, 9f171c32). Lehnt Lena eine davon ab, fehlt eine. Für Do/Fr 22.–23.10. ist der Thales-Generator deshalb die erste Figur.

Weitere Befunde:

- **Kein D.** Die fünf vorhandenen Figuren (alle `gleichung_lgs_grafisch`, Generator `koordinatensystem`) habe ich gerendert und nachgerechnet. Schnittpunkte und Parallelen passen zu Text und `correct_answers`, die alt-Texte haben keine Ziffern. Die Größe ist ein App-Thema und kein D.
- **Lena hat noch keine Pilot-Aufgabe entschieden** (`task_pruefungen`: 0 Zeilen). 21 Aufgaben sind geöffnet (Ausgangsfassung in `task_pruefung_ausgang`), davon hat nur 3a42b89c eine Spec (B). Eine neue Figur würde also keine Entscheidung wieder öffnen.
- **Stufe 1 und Stufe 2 brauchen keine Figur** (alle C).
- Für jeden neuen Generator braucht F2 zusätzlich: den CHECK `task_figures_generator_check` erweitern (heute nur `koordinatensystem`, `winkel`, also eine Migration) und `GENERATOREN` in `scripts/figures/upload_figures.py` ergänzen. Das gilt auch für das vorhandene `rechteck.ts`, das upload_figures heute nicht kennt.

## Grundlage

- Umfang: `tasks.pruef_pilot = true` = 257 Aufgaben. Das sind 255 laut `docs/themen/pruefung-batu-inhalte.md` plus je eine neue Aufgabe in `term_binom_gemischt` und `term_binom_quadrat` aus #258.
- Gruppe aus `pruef_soll.sort`: 1xx Stufe 1, 2xx Stufe 2, 3xx Session (`batu_session`), 4xx–5xx Stufe 3. Soll und Mindestzahl ohne MC aus `pruef_soll`.
- Vorhandene Figuren aus `task_figures` (generator, params, alt_text). Lenas Stand aus `task_pruefungen` (Entscheidung) und `task_pruefung_ausgang` (geöffnet). `task_pruef_ausschluss` ist leer.
- Teilaufgaben aus `tasks.parts`. Alle MULTI_PART-Teile sind „x =“, „y =“ oder „kleinere/größere Lösung“ und ändern keine Einstufung.
- „Lena“ in den Tabellen: offen = nie geöffnet, geöffnet = Ausgangsfassung geschrieben, aber keine Entscheidung.
- Alle Specs sind „schematisch, nicht maßstäblich, ohne Gitter“, weil gerechnet und nicht gemessen wird. `c_lage_grad` bei Thales ist der gezeichnete Winkel ∠BMC, also wo C auf dem Bogen sitzt. Er liegt bei allen sechs Aufgaben bewusst 10° bis 30° neben dem wahren Wert (wahr ist 2α).

## 1. Einstufung je Aufgabe

### Stufe 3

| id | Knoten | Typ | Stufe | Lena | Begründung |
|---|---|---|---|---|---|
| `07f970aa` | fkt_linear_gleichung | NUMERIC | **C** | offen | Steigung und Achsenabschnitt oder zwei Punkte stehen im Text; die Gleichung aufzustellen ist die Fertigkeit, ein Graph würde f(x) ablesbar machen. |
| `1bbce78e` | fkt_linear_gleichung | NUMERIC | **C** | offen | Steigung und Achsenabschnitt oder zwei Punkte stehen im Text; die Gleichung aufzustellen ist die Fertigkeit, ein Graph würde f(x) ablesbar machen. |
| `55d52e3e` | fkt_linear_gleichung | NUMERIC | **C** | offen | Steigung und Achsenabschnitt oder zwei Punkte stehen im Text; die Gleichung aufzustellen ist die Fertigkeit, ein Graph würde f(x) ablesbar machen. |
| `a61e8be9` | fkt_linear_gleichung | NUMERIC | **C** | geöffnet | Steigung und Achsenabschnitt oder zwei Punkte stehen im Text; die Gleichung aufzustellen ist die Fertigkeit, ein Graph würde f(x) ablesbar machen. |
| `b0f1b654` | fkt_linear_gleichung | NUMERIC | **C** | offen | Steigung und Achsenabschnitt oder zwei Punkte stehen im Text; die Gleichung aufzustellen ist die Fertigkeit, ein Graph würde f(x) ablesbar machen. |
| `ffc76634` | fkt_linear_gleichung | NUMERIC | **C** | offen | Steigung und Achsenabschnitt oder zwei Punkte stehen im Text; die Gleichung aufzustellen ist die Fertigkeit, ein Graph würde f(x) ablesbar machen. |
| `438b3001` | fkt_linear_steigung | NUMERIC | **C** | geöffnet | Zwei Punkte oder zwei Wertepaare stehen im Text; ein Steigungsdreieck im Bild würde die Lösung vorwegnehmen. |
| `7cd1b9af` | fkt_linear_steigung | NUMERIC | **C** | geöffnet | Zwei Punkte oder zwei Wertepaare stehen im Text; ein Steigungsdreieck im Bild würde die Lösung vorwegnehmen. |
| `9f8674f1` | fkt_linear_steigung | NUMERIC | **C** | offen | Zwei Punkte oder zwei Wertepaare stehen im Text; ein Steigungsdreieck im Bild würde die Lösung vorwegnehmen. |
| `a0451e78` | fkt_linear_steigung | NUMERIC | **C** | offen | Zwei Punkte oder zwei Wertepaare stehen im Text; ein Steigungsdreieck im Bild würde die Lösung vorwegnehmen. |
| `d8958025` | fkt_linear_steigung | NUMERIC | **C** | offen | Zwei Punkte oder zwei Wertepaare stehen im Text; ein Steigungsdreieck im Bild würde die Lösung vorwegnehmen. |
| `ffc758dc` | fkt_linear_steigung | NUMERIC | **C** | geöffnet | Zwei Punkte oder zwei Wertepaare stehen im Text; ein Steigungsdreieck im Bild würde die Lösung vorwegnehmen. |
| `1c170c59` | fkt_linear_yabschnitt | NUMERIC | **C** | offen | Funktionsgleichung oder Punkt und Steigung stehen im Text; ein Graph würde den Achsenabschnitt ablesbar machen. |
| `871303c4` | fkt_linear_yabschnitt | NUMERIC | **C** | offen | Funktionsgleichung oder Punkt und Steigung stehen im Text; ein Graph würde den Achsenabschnitt ablesbar machen. |
| `c2f24a82` | fkt_linear_yabschnitt | NUMERIC | **C** | offen | Funktionsgleichung oder Punkt und Steigung stehen im Text; ein Graph würde den Achsenabschnitt ablesbar machen. |
| `de54e58b` | fkt_linear_yabschnitt | NUMERIC | **C** | offen | Funktionsgleichung oder Punkt und Steigung stehen im Text; ein Graph würde den Achsenabschnitt ablesbar machen. |
| `e4611c3d` | fkt_linear_yabschnitt | NUMERIC | **C** | offen | Funktionsgleichung oder Punkt und Steigung stehen im Text; ein Graph würde den Achsenabschnitt ablesbar machen. |
| `fa6fb2c7` | fkt_linear_yabschnitt | NUMERIC | **C** | offen | Funktionsgleichung oder Punkt und Steigung stehen im Text; ein Graph würde den Achsenabschnitt ablesbar machen. |
| `18dbb731` | term_binom_faktorisieren | MC | **C** | offen | Reine Termumformung. |
| `88ca2551` | term_binom_faktorisieren | NUMERIC | **C** | offen | Reine Termumformung. |
| `9be9bb9c` | term_binom_faktorisieren | MC | **C** | offen | Reine Termumformung. |
| `9d904128` | term_binom_faktorisieren | MC | **C** | offen | Reine Termumformung. |
| `b2bc0cfc` | term_binom_faktorisieren | MC | **C** | offen | Reine Termumformung. |
| `e4a18d51` | term_binom_faktorisieren | MC | **C** | geöffnet | Reine Termumformung. |
| `1c519bed` | term_binom_gemischt | MC | **C** | offen | Reine Termumformung. |
| `79c7a940` | term_binom_gemischt | MC | **C** | offen | Reine Termumformung. |
| `8c4a2d71` | term_binom_gemischt | NUMERIC | **C** | offen | Reine Termumformung. |
| `b7ac3c73` | term_binom_gemischt | MC | **C** | offen | Reine Termumformung. |
| `c31fdbb1` | term_binom_gemischt | MC | **C** | offen | Reine Termumformung. |
| `dd4db5a2` | term_binom_gemischt | MC | **C** | offen | Reine Termumformung. |
| `f8364853` | term_binom_gemischt | MC | **B** | offen | Beide Seitenlängen stehen im Text, die binomische Rechnung ist die Fertigkeit; eine Skizze macht klar, dass die Beetfläche abgezogen wird. |
| `3b1e6f0a` | term_binom_quadrat | NUMERIC | **C** | offen | Reine Termumformung. |
| `513d03bd` | term_binom_quadrat | MC | **C** | offen | Ein Quadrat mit Seite (x + 4) trägt nichts bei; eine Aufteilung in x und vier wäre der Beweis der binomischen Formel und nähme die Lösung vorweg. |
| `9a598424` | term_binom_quadrat | MC | **C** | offen | Reine Termumformung. |
| `ae6fa0b8` | term_binom_quadrat | MC | **C** | offen | Reine Termumformung. |
| `de60d4ff` | term_binom_quadrat | MC | **C** | geöffnet | Reine Termumformung. |
| `ebd05f6f` | term_binom_quadrat | MC | **C** | geöffnet | Reine Termumformung. |
| `f54b2f2c` | term_binom_quadrat | MC | **C** | geöffnet | Reine Termumformung. |
| `113aea0a` | term_binom_quadratdifferenz | MC | **B** | offen | Beide Änderungen stehen im Text, die dritte binomische Formel ist die Fertigkeit; die Skizze macht sichtbar, welche Seite länger und welche kürzer wird. |
| `293413f8` | term_binom_quadratdifferenz | MC | **C** | offen | Reine Termumformung. |
| `7e027634` | term_binom_quadratdifferenz | NUMERIC | **C** | offen | Reine Termumformung. |
| `94492e5a` | term_binom_quadratdifferenz | MC | **C** | offen | Reine Termumformung. |
| `d47b8793` | term_binom_quadratdifferenz | MC | **C** | offen | Reine Termumformung. |
| `eb3f28da` | term_binom_quadratdifferenz | MC | **C** | offen | Reine Termumformung. |
| `04167489` | gleichung_lgs_addition | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `5fcdd8c8` | gleichung_lgs_addition | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `8a6667f5` | gleichung_lgs_addition | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `b0a46ab7` | gleichung_lgs_addition | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `ca914e37` | gleichung_lgs_addition | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `ffd185a0` | gleichung_lgs_addition | MC | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `158c874c` | gleichung_lgs_einsetzen | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `59fc7bef` | gleichung_lgs_einsetzen | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `686a3356` | gleichung_lgs_einsetzen | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `6ffa3e34` | gleichung_lgs_einsetzen | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `8ccd8989` | gleichung_lgs_einsetzen | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `fd5eeb1f` | gleichung_lgs_einsetzen | MULTI_PART | **C** | offen | Gleichungen stehen im Text oder sind aus dem Sachtext aufzustellen; das Verfahren ist rechnerisch. |
| `0315634a` | gleichung_lgs_grafisch | MULTI_PART | **A (Figur vorhanden, ok)** | offen | „Lies ab“: Die Aufgabe ist ohne die Geraden nicht lösbar; die vorhandene Figur passt (Schnittpunkt bei Leihdauer vier, Kosten sechs wie in correct_answers). Kein Mangel, nur Verbesserung für F2: x_min = -1 zeigt eine negative Leihdauer, die Achsen heißen x und y statt Stunden und €. Kein D, weil Text und Teilaufgaben die Achsen erklären. |
| `4888b388` | gleichung_lgs_grafisch | MC | **A (Figur vorhanden, ok)** | offen | Lösungsanzahl wird an den gezeichneten Geraden bestimmt; die Figur zeigt zwei Parallelen, passend zu „keine Lösung“. |
| `49e51e4e` | gleichung_lgs_grafisch | MC | **C** | offen | Beide Gleichungen stehen im Text; eine Zeichnung zeigte zwei aufeinanderliegende Geraden und damit die Lösung. |
| `635ae61a` | gleichung_lgs_grafisch | MULTI_PART | **A (Figur vorhanden, ok)** | offen | „Lies … ab“ ohne Gleichungen im Text; die Figur schneidet bei (2\|3), passend zu correct_answers. |
| `6bc7dd64` | gleichung_lgs_grafisch | MULTI_PART | **A (Figur vorhanden, ok)** | offen | „Lies … ab“ ohne Gleichungen im Text; die Figur schneidet bei (-2\|-1), passend zu correct_answers. |
| `a4edd0b8` | gleichung_lgs_grafisch | MULTI_PART | **A (Figur vorhanden, ok)** | offen | „Mithilfe der Zeichnung“ ohne Gleichungen im Text; die Figur schneidet bei (4\|1), passend zu correct_answers. |
| `0802547a` | geo_flaeche_drachen_raute | NUMERIC | **B** | offen | Beide Diagonalen der Fliese stehen im Text, die Formel ist die Fertigkeit; eine Raute mit Diagonalen erleichtert die Zuordnung. |
| `6274f6a5` | geo_flaeche_drachen_raute | NUMERIC | **B** | offen | Beispiel aus dem Auftrag: e, f und die Seite stehen im Text, die Formel ist die Fertigkeit. |
| `7cfb5d9f` | geo_flaeche_drachen_raute | NUMERIC | **B** | offen | Beide Stablängen stehen im Text, und der Text sagt selbst, dass sie die Diagonalen sind; eine Skizze erleichtert die Zuordnung. |
| `c1440c89` | geo_flaeche_drachen_raute | NUMERIC | **B** | offen | Beispiel aus dem Auftrag (Drachen mit e und f): alle Größen im Text, die Formel ist die Fertigkeit. |
| `ef5c0139` | geo_flaeche_drachen_raute | NUMERIC | **B** | offen | Alle Größen im Text, die Formel ist die Fertigkeit. |
| `f8054c53` | geo_flaeche_drachen_raute | NUMERIC | **B** | offen | Alle Größen im Text, die Formel ist die Fertigkeit. |
| `10f112ad` | geo_flaeche_term | MC | **B** | offen | Grundseite und Höhe stehen im Text, die Dreiecksformel mit Term ist die Fertigkeit. |
| `11390e1a` | geo_flaeche_term | MC | **A** | offen | „Eine Figur besteht aus …“: Die zusammengesetzte Form muss das Kind erst aus dem Text bauen, im Schulbuch stünde hier immer ein Bild. |
| `1f27364f` | geo_flaeche_term | NUMERIC | **C** | offen | Der Term aus „doppelt so lang wie breit“ ist die Fertigkeit; eine Skizze müsste dafür „2x“ zeigen und nähme ihn vorweg, ohne das trägt sie nichts. |
| `214345b8` | geo_flaeche_term | NUMERIC | **C** | offen | Der Term aus „3 m länger als breit“ ist die Fertigkeit; eine Skizze müsste dafür „x + 3“ zeigen und nähme ihn vorweg, ohne das trägt sie nichts. |
| `46192474` | geo_flaeche_term | MC | **B** | offen | Beide Seiten stehen im Text, der Flächenterm ist die Fertigkeit; eine Skizze erleichtert die Zuordnung. |
| `770f72e9` | geo_flaeche_term | MC | **B** | offen | Beide Seiten stehen im Text, der Flächenterm ist die Fertigkeit; eine Skizze erleichtert die Zuordnung. |
| `4bfe5d6e` | geo_flaeche_trapez | NUMERIC | **B** | offen | a, c und h stehen im Text, die Formel ist die Fertigkeit. |
| `5c219db6` | geo_flaeche_trapez | NUMERIC | **B** | offen | a, c, h und die Schenkel stehen im Text (Schenkel als Ablenker), die Formel ist die Fertigkeit. |
| `94fcae6b` | geo_flaeche_trapez | NUMERIC | **B** | offen | Beide Parallelen und ihr Abstand stehen im Text; die Skizze macht klar, dass der Abstand die Höhe ist. |
| `f1ecd67e` | geo_flaeche_trapez | NUMERIC | **B** | offen | a, c und h stehen im Text, die Formel ist die Fertigkeit. |
| `fd558d3f` | geo_flaeche_trapez | NUMERIC | **B** | offen | Beide Dachkanten und ihr Abstand stehen im Text; die Skizze macht klar, dass der Abstand auf der Dachfläche die Höhe des Trapezes ist. |
| `ffcbb7db` | geo_flaeche_trapez | NUMERIC | **B** | offen | a, c und h stehen im Text, die Formel ist die Fertigkeit. |
| `2d6edc4b` | stoch_pfad_summe | NUMERIC | **C** | offen | Alle Anzahlen und Wahrscheinlichkeiten stehen im Text. Ein Baumdiagramm ist hier die Fertigkeit selbst, vorgegeben nähme es sie vorweg; eine Urne zeigte nur die Anzahlen noch einmal. |
| `3cb3aa9d` | stoch_pfad_summe | NUMERIC | **C** | offen | Alle Anzahlen und Wahrscheinlichkeiten stehen im Text. Ein Baumdiagramm ist hier die Fertigkeit selbst, vorgegeben nähme es sie vorweg; eine Urne zeigte nur die Anzahlen noch einmal. |
| `54f5e1df` | stoch_pfad_summe | NUMERIC | **C** | offen | Alle Anzahlen und Wahrscheinlichkeiten stehen im Text. Ein Baumdiagramm ist hier die Fertigkeit selbst, vorgegeben nähme es sie vorweg; eine Urne zeigte nur die Anzahlen noch einmal. |
| `64091830` | stoch_pfad_summe | NUMERIC | **C** | offen | Alle Anzahlen und Wahrscheinlichkeiten stehen im Text. Ein Baumdiagramm ist hier die Fertigkeit selbst, vorgegeben nähme es sie vorweg; eine Urne zeigte nur die Anzahlen noch einmal. |
| `8b6561e6` | stoch_pfad_summe | NUMERIC | **C** | offen | Alle Anzahlen und Wahrscheinlichkeiten stehen im Text. Ein Baumdiagramm ist hier die Fertigkeit selbst, vorgegeben nähme es sie vorweg; eine Urne zeigte nur die Anzahlen noch einmal. |
| `939baa76` | stoch_pfad_summe | NUMERIC | **C** | offen | Alle Anzahlen und Wahrscheinlichkeiten stehen im Text. Ein Baumdiagramm ist hier die Fertigkeit selbst, vorgegeben nähme es sie vorweg; eine Urne zeigte nur die Anzahlen noch einmal. |
| `11aebc7c` | geo_winkel_thales | NUMERIC | **A** | offen | Beispiel aus dem Auftrag: Halbkreis, zwei Streben und die Lage des 32°-Winkels muss das Kind erst aus dem Text konstruieren. |
| `22e90366` | geo_winkel_thales | NUMERIC | **B** | offen | Die Lage ist die Standardfigur des Satzes in einem Satz beschrieben, nötig sind nur α und γ; eine Skizze erleichtert die Zuordnung der Winkel. |
| `3e087e16` | geo_winkel_thales | NUMERIC | **A** | offen | Die Winkel ∠AMC und ∠BMC setzen die Strecke MC voraus, die im Text nur über die Winkelnamen vorkommt; das Kind muss die ganze Lage selbst aufbauen. |
| `9ca300e1` | geo_winkel_thales | NUMERIC | **A** | offen | Der gegebene Winkel ∠BMC liegt an der Strecke MC, die im Dreieck ABC nicht vorkommt; ohne Figur prüft die Aufgabe vor allem, ob das Kind die Lage richtig aufbaut. |
| `9e7c1e4b` | geo_winkel_thales | NUMERIC | **A** | offen | Gesucht ist ∠ACM, ein Winkel an der Strecke CM, die das Kind aus dem Text erst ergänzen muss. |
| `9f171c32` | geo_winkel_thales | NUMERIC | **B** | offen | Standardfigur in einem Satz beschrieben, nötig sind nur α und β; eine Skizze erleichtert die Zuordnung. |

### Stufe 1

| id | Knoten | Typ | Stufe | Lena | Begründung |
|---|---|---|---|---|---|
| `0b7e781c` | zahl_wurzel_irrational | NUMERIC | **C** | geöffnet | Reine Zahl- oder Zählaufgabe zu rationalen und irrationalen Zahlen, nichts Räumliches. |
| `54382934` | zahl_wurzel_irrational | NUMERIC | **C** | geöffnet | Reine Zahl- oder Zählaufgabe zu rationalen und irrationalen Zahlen, nichts Räumliches. |
| `834de179` | zahl_wurzel_irrational | NUMERIC | **C** | offen | Reine Zahl- oder Zählaufgabe zu rationalen und irrationalen Zahlen, nichts Räumliches. |
| `9935f4bb` | zahl_wurzel_irrational | NUMERIC | **C** | geöffnet | Reine Zahl- oder Zählaufgabe zu rationalen und irrationalen Zahlen, nichts Räumliches. |
| `ae8478c7` | zahl_wurzel_irrational | NUMERIC | **C** | geöffnet | Reine Zahl- oder Zählaufgabe zu rationalen und irrationalen Zahlen, nichts Räumliches. |
| `d851f251` | zahl_wurzel_irrational | NUMERIC | **C** | offen | Reine Zahl- oder Zählaufgabe zu rationalen und irrationalen Zahlen, nichts Räumliches. |
| `0b9229a0` | zahl_wurzel_naeherung | NUMERIC | **C** | offen | Wurzel näherungsweise bestimmen; ein Quadrat-Kontext (Teppich, Beet) liefert nur die Fläche, eine Skizze trüge nichts zur Wurzel bei. |
| `6585552b` | zahl_wurzel_naeherung | MULTI_PART | **C** | offen | Wurzel näherungsweise bestimmen; ein Quadrat-Kontext (Teppich, Beet) liefert nur die Fläche, eine Skizze trüge nichts zur Wurzel bei. |
| `81015f65` | zahl_wurzel_naeherung | NUMERIC | **C** | offen | Wurzel näherungsweise bestimmen; ein Quadrat-Kontext (Teppich, Beet) liefert nur die Fläche, eine Skizze trüge nichts zur Wurzel bei. |
| `9af2a3ce` | zahl_wurzel_naeherung | NUMERIC | **C** | offen | Wurzel näherungsweise bestimmen; ein Quadrat-Kontext (Teppich, Beet) liefert nur die Fläche, eine Skizze trüge nichts zur Wurzel bei. |
| `cd35f4b2` | zahl_wurzel_naeherung | NUMERIC | **C** | offen | Wurzel näherungsweise bestimmen; ein Quadrat-Kontext (Teppich, Beet) liefert nur die Fläche, eine Skizze trüge nichts zur Wurzel bei. |
| `fde9c9a1` | zahl_wurzel_naeherung | NUMERIC | **C** | offen | Wurzel näherungsweise bestimmen; ein Quadrat-Kontext (Teppich, Beet) liefert nur die Fläche, eine Skizze trüge nichts zur Wurzel bei. |
| `0bcc83c8` | zahl_wurzel_teilweise | NUMERIC | **C** | offen | Teilweises Wurzelziehen ist reine Termumformung; der Spielplatz liefert nur die Fläche. |
| `1dece473` | zahl_wurzel_teilweise | NUMERIC | **C** | offen | Teilweises Wurzelziehen ist reine Termumformung; der Spielplatz liefert nur die Fläche. |
| `21427340` | zahl_wurzel_teilweise | NUMERIC | **C** | offen | Teilweises Wurzelziehen ist reine Termumformung; der Spielplatz liefert nur die Fläche. |
| `ad08897e` | zahl_wurzel_teilweise | NUMERIC | **C** | offen | Teilweises Wurzelziehen ist reine Termumformung; der Spielplatz liefert nur die Fläche. |
| `df6b2bcd` | zahl_wurzel_teilweise | NUMERIC | **C** | offen | Teilweises Wurzelziehen ist reine Termumformung; der Spielplatz liefert nur die Fläche. |
| `ef90a8ac` | zahl_wurzel_teilweise | NUMERIC | **C** | offen | Teilweises Wurzelziehen ist reine Termumformung; der Spielplatz liefert nur die Fläche. |
| `4f7652bf` | zahl_wurzel_gesetze | NUMERIC | **C** | offen | Wurzelgesetze sind reine Rechnung; die Beete und das Feld liefern nur Zahlen, die Form spielt keine Rolle. |
| `760fc0ad` | zahl_wurzel_gesetze | NUMERIC | **C** | offen | Wurzelgesetze sind reine Rechnung; die Beete und das Feld liefern nur Zahlen, die Form spielt keine Rolle. |
| `88c99e21` | zahl_wurzel_gesetze | NUMERIC | **C** | offen | Wurzelgesetze sind reine Rechnung; die Beete und das Feld liefern nur Zahlen, die Form spielt keine Rolle. |
| `926f4f6e` | zahl_wurzel_gesetze | NUMERIC | **C** | offen | Wurzelgesetze sind reine Rechnung; die Beete und das Feld liefern nur Zahlen, die Form spielt keine Rolle. |
| `a0a8c04b` | zahl_wurzel_gesetze | NUMERIC | **C** | offen | Wurzelgesetze sind reine Rechnung; die Beete und das Feld liefern nur Zahlen, die Form spielt keine Rolle. |
| `ce24db36` | zahl_wurzel_gesetze | NUMERIC | **C** | offen | Wurzelgesetze sind reine Rechnung; die Beete und das Feld liefern nur Zahlen, die Form spielt keine Rolle. |
| `16d6e3b7` | zahl_wurzel_quadrat | NUMERIC | **C** | geöffnet | Quadratwurzel ziehen ist reine Rechnung; der Platz und die Tischplatte liefern nur die Fläche. |
| `4b3b14a9` | zahl_wurzel_quadrat | NUMERIC | **C** | offen | Quadratwurzel ziehen ist reine Rechnung; der Platz und die Tischplatte liefern nur die Fläche. |
| `55239bfc` | zahl_wurzel_quadrat | NUMERIC | **C** | offen | Quadratwurzel ziehen ist reine Rechnung; der Platz und die Tischplatte liefern nur die Fläche. |
| `5f9d6c06` | zahl_wurzel_quadrat | NUMERIC | **C** | offen | Quadratwurzel ziehen ist reine Rechnung; der Platz und die Tischplatte liefern nur die Fläche. |
| `99b7829c` | zahl_wurzel_quadrat | NUMERIC | **C** | offen | Quadratwurzel ziehen ist reine Rechnung; der Platz und die Tischplatte liefern nur die Fläche. |
| `afc3b977` | zahl_wurzel_quadrat | NUMERIC | **C** | offen | Quadratwurzel ziehen ist reine Rechnung; der Platz und die Tischplatte liefern nur die Fläche. |

### Stufe 2

| id | Knoten | Typ | Stufe | Lena | Begründung |
|---|---|---|---|---|---|
| `01f22500` | potenzen | NUMERIC | **C** | geöffnet | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `25539057` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `2fe1feb6` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `451bd34e` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `59c982b3` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `5c73a51d` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `72d61822` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `744b2ea7` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `796659c3` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `83839a0b` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `855d22d3` | potenzen | NUMERIC | **C** | geöffnet | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `89ad1d12` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `9ee7cbb7` | potenzen | NUMERIC | **C** | geöffnet | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `a3343b39` | potenzen | NUMERIC | **C** | geöffnet | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `aef364ee` | potenzen | NUMERIC | **C** | geöffnet | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `bb125765` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `bbc88883` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `c5ff0008` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `db07cb07` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `e04a700d` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `e1aeb6a9` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `e5da9c79` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `e7c7b1c6` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `fd7c0327` | potenzen | NUMERIC | **C** | offen | Reine Potenzrechnung; beim Würfelkarton steht die Formel V = a³ im Text. |
| `3768ecdc` | bruch_dezimal | NUMERIC | **C** | offen | Reine Umrechnung Bruch in Dezimalzahl. |
| `6bdc7d4e` | bruch_dezimal | NUMERIC | **C** | offen | Reine Umrechnung Bruch in Dezimalzahl. |
| `6ef85b4a` | bruch_dezimal | NUMERIC | **C** | offen | Reine Umrechnung Bruch in Dezimalzahl. |
| `80105584` | bruch_dezimal | NUMERIC | **C** | offen | Reine Umrechnung Bruch in Dezimalzahl. |
| `8ea44368` | bruch_dezimal | NUMERIC | **C** | offen | Reine Umrechnung Bruch in Dezimalzahl. |
| `de2aabbf` | bruch_dezimal | NUMERIC | **C** | offen | Reine Umrechnung Bruch in Dezimalzahl. |
| `1debff4f` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `400b8905` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `6b531762` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `6fc6f305` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `730dae3f` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `865b6e60` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `91390c63` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `bdf4d10a` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `fa305352` | dezimal_div | NUMERIC | **C** | offen | Reine Division; Schnur, Saft und Erde sind Sachkontext ohne Form. |
| `0cbaacfd` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `1983282b` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `21f1c9f4` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `24310ee2` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `3038721a` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `3d066cef` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `98441ffc` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `d183eca3` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `e8e6eeb7` | dezimal_mult | NUMERIC | **C** | offen | Reine Multiplikation; bei der Fliese sind Breite und Höhe genannt, die Rechnung ist die Fertigkeit. |
| `0438a9f9` | vorzeichen_mult_div | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `2e8ce53f` | vorzeichen_mult_div | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `38aa9504` | vorzeichen_mult_div | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `751f9c63` | vorzeichen_mult_div | NUMERIC | **C** | geöffnet | Reine Vorzeichenrechnung. |
| `7db70449` | vorzeichen_mult_div | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `ba0701ff` | vorzeichen_mult_div | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `e58cb290` | vorzeichen_mult_div | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `0bb7e6c8` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `0cd53103` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `17eff311` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `1c31db89` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `20c27486` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `4ff59e5f` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `6f816c36` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `865abaf9` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `963d2134` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `a982bbce` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `ad9cec47` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `c6e71bcf` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `d9d683a3` | runden_ueberschlag | NUMERIC | **C** | offen | Reines Runden. |
| `024143bf` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `0cb5d1f1` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `172db197` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `20321d30` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `2084724c` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `37a501b6` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `5699500a` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `6a8e9bc1` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `a07cbf96` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `be8ce7e4` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `da4f1646` | dezimal_add_sub | NUMERIC | **C** | offen | Reine Addition oder Subtraktion. |
| `1244b84c` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `2e40939a` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `41004d1a` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `9a6bf378` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `9a70682a` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `b7fbaaca` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `bba44bae` | bruch_kuerzen | NUMERIC | **C** | offen | Reines Kürzen. |
| `17674b19` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `27f51c08` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `3b44eada` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `3e6fb055` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `738de19f` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `c92aa7e8` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `e96cd37d` | vorzeichen_add_sub | NUMERIC | **C** | geöffnet | Reine Vorzeichenrechnung. |

### Session

| id | Knoten | Typ | Stufe | Lena | Begründung |
|---|---|---|---|---|---|
| `17674b19` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `27f51c08` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `3b44eada` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `3e6fb055` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `738de19f` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `c92aa7e8` | vorzeichen_add_sub | NUMERIC | **C** | offen | Reine Vorzeichenrechnung. |
| `e96cd37d` | vorzeichen_add_sub | NUMERIC | **C** | geöffnet | Reine Vorzeichenrechnung. |
| `02b24419` | term_ausklammern | MC | **C** | offen | Reine Termumformung. |
| `4baeeda9` | term_ausklammern | MC | **C** | offen | Reine Termumformung. |
| `65841bd8` | term_ausklammern | MC | **C** | offen | Reine Termumformung. |
| `81f97d0e` | term_ausklammern | MC | **C** | offen | Reine Termumformung. |
| `b15b6be0` | term_ausklammern | MC | **C** | offen | Reine Termumformung. |
| `ea237a07` | term_ausklammern | MC | **C** | offen | Reine Termumformung. |
| `152bcdcd` | gleichung_einschrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `4f6f7cdd` | gleichung_einschrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `6fc6928a` | gleichung_einschrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `bfd877b9` | gleichung_einschrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `d19c8070` | gleichung_einschrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `fbd28765` | gleichung_einschrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `17f3e728` | gleichung_zweischrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `7976c81f` | gleichung_zweischrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `9d15a93e` | gleichung_zweischrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `b01451c0` | gleichung_zweischrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `e8348c89` | gleichung_zweischrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `ff5710af` | gleichung_zweischrittig | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `3a42b89c` | gleichung_quadr_wurzel | NUMERIC | **B** | geöffnet | Fläche und Verlängerung stehen im Text, die Gleichung ist die Fertigkeit; die Skizze zeigt, dass jede Seite um dasselbe Stück wächst. |
| `4d1a2438` | gleichung_quadr_wurzel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `504bbd98` | gleichung_quadr_wurzel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `9264f90a` | gleichung_quadr_wurzel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `bc0cdfe9` | gleichung_quadr_wurzel | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `cd6693f5` | gleichung_quadr_wurzel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `1c4a31af` | gleichung_quadr_faktor | MULTI_PART | **C** | offen | Gleichung oder Term steht fertig da; ein Graph der Wurfhöhe würde die Nullstellen zeigen. |
| `90635757` | gleichung_quadr_faktor | NUMERIC | **C** | offen | Gleichung oder Term steht fertig da; ein Graph der Wurfhöhe würde die Nullstellen zeigen. |
| `9879542e` | gleichung_quadr_faktor | NUMERIC | **C** | offen | Gleichung oder Term steht fertig da; ein Graph der Wurfhöhe würde die Nullstellen zeigen. |
| `b47ef7d3` | gleichung_quadr_faktor | MULTI_PART | **C** | offen | Gleichung oder Term steht fertig da; ein Graph der Wurfhöhe würde die Nullstellen zeigen. |
| `c3be2e88` | gleichung_quadr_faktor | MULTI_PART | **C** | offen | Gleichung oder Term steht fertig da; ein Graph der Wurfhöhe würde die Nullstellen zeigen. |
| `d7d81e80` | gleichung_quadr_faktor | MULTI_PART | **C** | offen | Gleichung oder Term steht fertig da; ein Graph der Wurfhöhe würde die Nullstellen zeigen. |
| `1271aabc` | gleichung_quadr_formel | NUMERIC | **C** | offen | Gleichung steht fertig da. |
| `1f2a206f` | gleichung_quadr_formel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `43f39bc1` | gleichung_quadr_formel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `5b36238f` | gleichung_quadr_formel | NUMERIC | **A** | offen | Ein Weg „rundherum, überall gleich breit“ ist eine Lage, die das Kind erst konstruieren muss; dass das Beet auf beiden Seiten um die doppelte Wegbreite wächst, ist ohne Bild vor allem eine Leseaufgabe. |
| `725448a1` | gleichung_quadr_formel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `b6e77404` | gleichung_quadr_formel | MULTI_PART | **C** | offen | Gleichung steht fertig da. |
| `0c3d2396` | gleichung_quadr_anzahl | NUMERIC | **C** | offen | Gleichung steht fertig da; ein Parabelgraph würde die Anzahl der Lösungen zeigen. |
| `56540a88` | gleichung_quadr_anzahl | NUMERIC | **C** | offen | Gleichung steht fertig da; ein Parabelgraph würde die Anzahl der Lösungen zeigen. |
| `95077a87` | gleichung_quadr_anzahl | NUMERIC | **C** | offen | Gleichung steht fertig da; ein Parabelgraph würde die Anzahl der Lösungen zeigen. |
| `9f9ab204` | gleichung_quadr_anzahl | NUMERIC | **C** | offen | Gleichung steht fertig da; ein Parabelgraph würde die Anzahl der Lösungen zeigen. |
| `a549083d` | gleichung_quadr_anzahl | NUMERIC | **C** | offen | Gleichung steht fertig da; ein Parabelgraph würde die Anzahl der Lösungen zeigen. |
| `ef911123` | gleichung_quadr_anzahl | NUMERIC | **C** | offen | Gleichung steht fertig da; ein Parabelgraph würde die Anzahl der Lösungen zeigen. |

## 2. Specs für A, B und D

### Stufe 3

#### `f8364853` · term_binom_gemischt · B

- Generator: **neu: rechtecke**
- params: `{"teile":[{"name":"Grundstück","seite_text":"(x + 3) m"},{"name":"Beet","seite_text":"(x - 1) m","lage":"ecke_unten_links","hervorgehoben":true}],"restflaeche_markiert":true,"massstaeblich":false}`
- Sichtbar: Großes Quadrat „(x + 3) m“, in einer Ecke ein kleineres Quadrat „(x - 1) m“ abgesetzt, die Restfläche getönt.
- Ausdrücklich nicht sichtbar: Nicht die Breite des Reststreifens („4 m“ wäre ein Lösungsschritt), keine Zerlegung der Restfläche, kein Gitter.
- Beschriftung: „(x + 3) m“, „(x - 1) m“, Minus wie im Aufgabentext.
- alt_text: Ein quadratisches Grundstück, in einer Ecke ist ein kleineres quadratisches Beet abgetrennt. Beide Seitenlängen sind als Term mit x beschriftet, die Restfläche ist getönt.

#### `113aea0a` · term_binom_quadratdifferenz · B

- Generator: **neu: rechtecke**
- params: `{"teile":[{"name":"Quadrat","seite_text":"x m","gestrichelt":true},{"name":"Rechteck","verlaengert_text":"5 m","verkuerzt_text":"5 m"}],"massstaeblich":false}`
- Sichtbar: Ursprüngliches Quadrat gestrichelt mit „x m“, darüber das neue Rechteck: eine Seite um ein Stück „5 m“ verlängert, die andere um „5 m“ gekürzt (gekürztes Stück schraffiert).
- Ausdrücklich nicht sichtbar: Keine Beschriftung „x + 5“ oder „x − 5“ an den neuen Seiten (das ist der Übersetzungsschritt), kein Gitter.
- Beschriftung: „x m“, „5 m“ (Verlängerung), „5 m“ (Kürzung).
- alt_text: Ein gestricheltes Quadrat mit der Seitenlänge x. Darüber ein Rechteck, bei dem eine Seite um ein Stück verlängert und die andere um ein gleich langes Stück gekürzt ist.

#### `0315634a` · gleichung_lgs_grafisch · A

- Generator: `koordinatensystem` (vorhanden, keine Änderung nötig)
- params: `{"x_max":8,"x_min":-1,"y_max":9,"y_min":-1,"funktionen":[{"b":2,"m":1,"typ":"linear","label":"f"},{"b":4,"m":0.5,"typ":"linear","label":"g"}]}`
- alt_text (vorhanden): Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.
- Hinweis: Kein Mangel, nur Verbesserung für F2: x_min = -1 zeigt eine negative Leihdauer, die Achsen heißen x und y statt Stunden und €. Kein D, weil Text und Teilaufgaben die Achsen erklären.

#### `4888b388` · gleichung_lgs_grafisch · A

- Generator: `koordinatensystem` (vorhanden, keine Änderung nötig)
- params: `{"x_max":5,"x_min":-5,"y_max":5,"y_min":-5,"funktionen":[{"b":2,"m":0.5,"typ":"linear","label":"f"},{"b":-1,"m":0.5,"typ":"linear","label":"g"}]}`
- alt_text (vorhanden): Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.

#### `635ae61a` · gleichung_lgs_grafisch · A

- Generator: `koordinatensystem` (vorhanden, keine Änderung nötig)
- params: `{"x_max":5,"x_min":-5,"y_max":5,"y_min":-5,"funktionen":[{"b":1,"m":1,"typ":"linear","label":"f"},{"b":4,"m":-0.5,"typ":"linear","label":"g"}]}`
- alt_text (vorhanden): Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.

#### `6bc7dd64` · gleichung_lgs_grafisch · A

- Generator: `koordinatensystem` (vorhanden, keine Änderung nötig)
- params: `{"x_max":5,"x_min":-5,"y_max":5,"y_min":-5,"funktionen":[{"b":1,"m":1,"typ":"linear","label":"f"},{"b":-2,"m":-0.5,"typ":"linear","label":"g"}]}`
- alt_text (vorhanden): Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.

#### `a4edd0b8` · gleichung_lgs_grafisch · A

- Generator: `koordinatensystem` (vorhanden, keine Änderung nötig)
- params: `{"x_max":7,"x_min":-2,"y_max":6,"y_min":-3,"funktionen":[{"b":-1,"m":0.5,"typ":"linear","label":"f"},{"b":5,"m":-1,"typ":"linear","label":"g"}]}`
- alt_text (vorhanden): Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.

#### `0802547a` · geo_flaeche_drachen_raute · B

- Generator: **neu: viereck_diagonalen**
- params: `{"form":"raute","e":20,"f":12,"einheit":"cm","masse":["e","f"],"massstaeblich":false}`
- Sichtbar: Eine Fliese als Raute, beide Diagonalen gestrichelt, Maße „20 cm“ und „12 cm“ an den Diagonalen.
- Ausdrücklich nicht sichtbar: Nicht die ganze Wand und nicht die Anzahl der Fliesen (die Multiplikation mit vierzig ist Teil der Aufgabe). Keine Fläche, kein Gitter.
- Beschriftung: „20 cm“, „12 cm“.
- alt_text: Eine rautenförmige Fliese mit ihren beiden gestrichelten Diagonalen, an beiden Diagonalen steht die Länge.

#### `6274f6a5` · geo_flaeche_drachen_raute · B

- Generator: **neu: viereck_diagonalen**
- params: `{"form":"raute","e":24,"f":10,"seite":13,"einheit":"cm","masse":["e","f","seite"],"massstaeblich":false}`
- Sichtbar: Raute mit beiden Diagonalen e und f gestrichelt, Maße an e und f, an einer Seite „13 cm“ (Ablenker aus dem Text).
- Ausdrücklich nicht sichtbar: Keine Höhe, kein Rechter-Winkel-Zeichen am Diagonalenschnittpunkt nötig, kein Gitter.
- Beschriftung: „e = 24 cm“, „f = 10 cm“, „13 cm“ an einer Seite.
- alt_text: Eine Raute mit den beiden gestrichelten Diagonalen e und f. An den Diagonalen und an einer Seite steht die Länge.

#### `7cfb5d9f` · geo_flaeche_drachen_raute · B

- Generator: **neu: viereck_diagonalen**
- params: `{"form":"drachen","e":90,"f":60,"einheit":"cm","e_name":"Längsstab","f_name":"Querstab","masse":["e","f"],"massstaeblich":false}`
- Sichtbar: Drachenviereck mit senkrechtem Längsstab und waagerechtem Querstab als Diagonalen, Maße „90 cm“ und „60 cm“.
- Ausdrücklich nicht sichtbar: Keine Seitenlängen, kein Schwanz, kein Gitter. Wo sich die Stäbe kreuzen, nennt der Text nicht; die Skizze wählt eine übliche Lage im oberen Drittel und beschriftet die Teilstrecken nicht.
- Beschriftung: „Längsstab 90 cm“, „Querstab 60 cm“.
- alt_text: Ein Drachen in Form eines Drachenvierecks mit einem senkrechten Längsstab und einem waagerechten Querstab. An beiden Stäben steht die Länge.

#### `c1440c89` · geo_flaeche_drachen_raute · B

- Generator: **neu: viereck_diagonalen**
- params: `{"form":"drachen","e":8,"f":6,"einheit":"cm","masse":["e","f"],"massstaeblich":false}`
- Sichtbar: Drachenviereck mit gestrichelten Diagonalen e und f und deren Maßen.
- Ausdrücklich nicht sichtbar: Keine Seitenlängen, kein Gitter.
- Beschriftung: „e = 8 cm“, „f = 6 cm“.
- alt_text: Ein Drachenviereck mit den beiden gestrichelten Diagonalen e und f, an beiden steht die Länge.

#### `ef5c0139` · geo_flaeche_drachen_raute · B

- Generator: **neu: viereck_diagonalen**
- params: `{"form":"drachen","e":7.5,"f":4.8,"einheit":"cm","masse":["e","f"],"massstaeblich":false}`
- Sichtbar: Drachenviereck mit gestrichelten Diagonalen e und f und deren Maßen.
- Ausdrücklich nicht sichtbar: Keine Seitenlängen, kein Gitter.
- Beschriftung: „e = 7,5 cm“, „f = 4,8 cm“ (Dezimalkomma).
- alt_text: Ein Drachenviereck mit den beiden gestrichelten Diagonalen e und f, an beiden steht die Länge.

#### `f8054c53` · geo_flaeche_drachen_raute · B

- Generator: **neu: viereck_diagonalen**
- params: `{"form":"raute","e":10,"f":7,"einheit":"cm","masse":["e","f"],"massstaeblich":false}`
- Sichtbar: Raute mit gestrichelten Diagonalen e und f und deren Maßen.
- Ausdrücklich nicht sichtbar: Keine Seitenlängen, kein Gitter.
- Beschriftung: „e = 10 cm“, „f = 7 cm“.
- alt_text: Eine Raute mit den beiden gestrichelten Diagonalen e und f, an beiden steht die Länge.

#### `10f112ad` · geo_flaeche_term · B

- Generator: dreieck (Spec specs/active/figur-dreieck.md, noch nicht gebaut) + Term-Beschriftung
- params: `{"art":"beliebig","grundseite_text":"(x + 4) cm","hoehe_text":"6 cm","massstaeblich":false}`
- Sichtbar: Dreieck mit waagerechter Grundseite „(x + 4) cm“ und gestrichelter Höhe „6 cm“.
- Ausdrücklich nicht sichtbar: Kein Gitter, keine Zerlegung in Teildreiecke, kein Rechteck drumherum (das wäre der Lösungsweg).
- Beschriftung: „(x + 4) cm“, „6 cm“.
- alt_text: Ein Dreieck mit waagerechter Grundseite und gestrichelter Höhe. An Grundseite und Höhe steht jeweils die Länge, die Grundseite als Term mit x.

#### `11390e1a` · geo_flaeche_term · A

- Generator: **neu: rechtecke**
- params: `{"teile":[{"name":"Rechteck","breite_text":"x cm","hoehe_text":"4 cm"},{"name":"Quadrat","seite_text":"4 cm","angesetzt_an":"rechts"}],"trennlinie":true,"massstaeblich":false}`
- Sichtbar: Rechteck mit „x cm“ an der langen und „4 cm“ an der kurzen Seite, rechts an der kurzen Seite ein Quadrat mit „4 cm“, Trennlinie zwischen beiden.
- Ausdrücklich nicht sichtbar: Keine Gesamtlänge „x + 4“ (das ist ein Lösungsschritt), kein Gitter, keine Teilflächen-Beschriftung.
- Beschriftung: „x cm“, „4 cm“ (Rechteck), „4 cm“ (Quadrat).
- alt_text: Eine Figur aus einem Rechteck und einem rechts angesetzten Quadrat. Die lange Rechteckseite ist mit x beschriftet, die kurze Rechteckseite und die Quadratseite mit ihrer Länge.

#### `46192474` · geo_flaeche_term · B

- Generator: rechteck (rechteck.ts vorhanden) + Term-Beschriftung, in upload_figures aufnehmen
- params: `{"laenge_text":"x cm","breite_text":"5 cm","massstaeblich":false}`
- Sichtbar: Rechteck mit „x cm“ und „5 cm“.
- Ausdrücklich nicht sichtbar: Kein Gitter.
- Beschriftung: „x cm“, „5 cm“.
- alt_text: Ein Rechteck, die Länge ist mit x beschriftet, an der Breite steht die Länge.

#### `770f72e9` · geo_flaeche_term · B

- Generator: rechteck (rechteck.ts vorhanden) + Term-Beschriftung, in upload_figures aufnehmen
- params: `{"laenge_text":"(x + 3) cm","breite_text":"4 cm","massstaeblich":false}`
- Sichtbar: Rechteck mit „(x + 3) cm“ und „4 cm“.
- Ausdrücklich nicht sichtbar: Keine Aufteilung der Länge in x und drei (das wäre der Distributiv-Schritt), kein Gitter.
- Beschriftung: „(x + 3) cm“, „4 cm“.
- alt_text: Ein Rechteck, die Länge ist als Term mit x beschriftet, an der Breite steht die Länge.

#### `4bfe5d6e` · geo_flaeche_trapez · B

- Generator: **neu: trapez**
- params: `{"a":8,"c":4,"h":5,"einheit":"cm","masse":["a","c","h"],"massstaeblich":false}`
- Sichtbar: Trapez mit a unten, c oben, Höhe h gestrichelt mit Rechter-Winkel-Zeichen an a.
- Ausdrücklich nicht sichtbar: Keine Schenkellängen, kein Gitter.
- Beschriftung: „a = 8 cm“, „c = 4 cm“, „h = 5 cm“.
- alt_text: Ein Trapez mit der unteren Seite a, der oberen Seite c und der gestrichelten Höhe h. An allen drei steht die Länge.

#### `5c219db6` · geo_flaeche_trapez · B

- Generator: **neu: trapez**
- params: `{"a":11,"c":5,"h":4,"schenkel":5,"art":"gleichschenklig","einheit":"cm","masse":["a","c","h","schenkel"],"massstaeblich":false}`
- Sichtbar: Gleichschenkliges Trapez, a unten, c oben, h gestrichelt, an beiden Schenkeln „5 cm“.
- Ausdrücklich nicht sichtbar: Nicht die Überstände von drei Zentimetern auf a (nicht im Text), kein Gitter.
- Beschriftung: „a = 11 cm“, „c = 5 cm“, „h = 4 cm“, „5 cm“ an beiden Schenkeln.
- alt_text: Ein gleichschenkliges Trapez mit der unteren Seite a, der oberen Seite c, der gestrichelten Höhe h und den beiden gleich langen Schenkeln. An allen steht die Länge.

#### `94fcae6b` · geo_flaeche_trapez · B

- Generator: **neu: trapez**
- params: `{"a":32,"c":24,"h":18,"einheit":"m","masse":["a","c","h"],"massstaeblich":false}`
- Sichtbar: Trapez als Grundstück, untere Seite „32 m“, obere „24 m“, Abstand gestrichelt „18 m“.
- Ausdrücklich nicht sichtbar: Kein Preis im Bild, kein Gitter.
- Beschriftung: „32 m“, „24 m“, „18 m“.
- alt_text: Ein trapezförmiges Grundstück mit zwei parallelen Seiten und ihrem gestrichelt gezeichneten Abstand. An allen drei steht die Länge.

#### `f1ecd67e` · geo_flaeche_trapez · B

- Generator: **neu: trapez**
- params: `{"a":10,"c":6,"h":7,"einheit":"cm","masse":["a","c","h"],"massstaeblich":false}`
- Sichtbar: Trapez mit a unten, c oben, Höhe h gestrichelt.
- Ausdrücklich nicht sichtbar: Keine Schenkellängen, kein Gitter.
- Beschriftung: „a = 10 cm“, „c = 6 cm“, „h = 7 cm“.
- alt_text: Ein Trapez mit der unteren Seite a, der oberen Seite c und der gestrichelten Höhe h. An allen drei steht die Länge.

#### `fd558d3f` · geo_flaeche_trapez · B

- Generator: **neu: trapez**
- params: `{"a":12,"c":8,"h":5,"einheit":"m","masse":["a","c","h"],"massstaeblich":false}`
- Sichtbar: Dachfläche als Trapez in Draufsicht, untere Kante „12 m“, obere „8 m“, Abstand gestrichelt „5 m“.
- Ausdrücklich nicht sichtbar: Kein Haus und keine Schrägansicht (sonst sähe der Abstand verkürzt aus), kein Gitter.
- Beschriftung: „12 m“, „8 m“, „5 m“.
- alt_text: Eine trapezförmige Dachfläche von vorn gesehen, mit unterer und oberer Dachkante und ihrem gestrichelten Abstand. An allen drei steht die Länge.

#### `ffcbb7db` · geo_flaeche_trapez · B

- Generator: **neu: trapez**
- params: `{"a":6.5,"c":3.5,"h":4.2,"einheit":"cm","masse":["a","c","h"],"massstaeblich":false}`
- Sichtbar: Trapez mit a unten, c oben, Höhe h gestrichelt.
- Ausdrücklich nicht sichtbar: Keine Schenkellängen, kein Gitter.
- Beschriftung: „a = 6,5 cm“, „c = 3,5 cm“, „h = 4,2 cm“ (Dezimalkomma).
- alt_text: Ein Trapez mit der unteren Seite a, der oberen Seite c und der gestrichelten Höhe h. An allen drei steht die Länge.

#### `11aebc7c` · geo_winkel_thales · A

- Generator: **neu: thales**
- params: `{"form":"halbkreis","punkte":["A","B","C"],"mittelpunkt":null,"strecken":["AB","AC","CB"],"winkel":[{"bei":"A","zwischen":["AC","AB"],"text":"32°"},{"bei":"B","zwischen":["CB","AB"],"text":"?"}],"c_lage_grad":75,"massstaeblich":false}`
- Sichtbar: Halbkreisbogen über der waagerechten Unterkante AB, Punkt C auf dem Bogen, Streben AC und CB, Winkelbogen bei A mit „32°“, Winkelbogen bei B mit „?“.
- Ausdrücklich nicht sichtbar: Kein Rechter-Winkel-Zeichen und kein Winkelbogen bei C. C nicht an der wahren Lage (wahr wären 64° Mittelpunktswinkel von B aus), damit nicht gemessen wird. Kein Mittelpunkt, kein Fensterrahmen.
- Beschriftung: A, B, C; „32°“ bei A; „?“ bei B.
- alt_text: Halbkreisförmiger Fensterbogen über der Unterkante AB. Von A und B führen zwei gerade Streben zu einem Punkt C auf dem Bogen. Der Winkel bei A ist angegeben, der Winkel bei B ist gesucht.

#### `22e90366` · geo_winkel_thales · B

- Generator: **neu: thales**
- params: `{"form":"kreis","punkte":["A","B","C","M"],"strecken":["AB","AC","BC"],"winkel":[{"bei":"A","zwischen":["AB","AC"],"text":"α = 28°"},{"bei":"C","zwischen":["CA","CB"],"text":"γ = ?"}],"c_lage_grad":70,"massstaeblich":false}`
- Sichtbar: Kreis mit Durchmesser AB und Mittelpunkt M, Punkt C auf dem Kreis, Dreieck ABC, Bogen bei A mit „α = 28°“, Bogen bei C mit „γ = ?“.
- Ausdrücklich nicht sichtbar: Gesucht ist γ = 90°: bei C ausdrücklich ein runder Bogen, kein Rechter-Winkel-Zeichen. Keine Strecke MC.
- Beschriftung: A, B, C, M; „α = 28°“; „γ = ?“.
- alt_text: Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck. Der Winkel Alpha bei A ist angegeben, der Winkel Gamma bei C ist gesucht.

#### `3e087e16` · geo_winkel_thales · A

- Generator: **neu: thales**
- params: `{"form":"kreis","punkte":["A","B","C","M"],"strecken":["AB","AC","BC","MC"],"winkel":[{"bei":"M","zwischen":["MA","MC"],"text":""},{"bei":"M","zwischen":["MB","MC"],"text":""},{"bei":"A","zwischen":["AB","AC"],"text":"α = ?"}],"c_lage_grad":60,"massstaeblich":false}`
- Sichtbar: Kreis mit Durchmesser AB und Mittelpunkt M, Punkt C auf dem Kreis, Dreieck ABC, Strecke MC, zwei unbeschriftete Winkelbögen bei M, Winkelbogen bei A mit „α = ?“.
- Ausdrücklich nicht sichtbar: Keine Gradzahlen bei M (der Text nennt nur den Unterschied von 40°), kein Rechter-Winkel-Zeichen bei C, C nicht an der wahren Lage (wahr: ∠BMC = 70°).
- Beschriftung: A, B, C, M; „α = ?“.
- alt_text: Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck, zusätzlich ist die Strecke von M nach C gezeichnet. Die beiden Winkel bei M sind markiert, der Winkel Alpha bei A ist gesucht.

#### `9ca300e1` · geo_winkel_thales · A

- Generator: **neu: thales**
- params: `{"form":"kreis","punkte":["A","B","C","M"],"strecken":["AB","AC","BC","MC"],"winkel":[{"bei":"M","zwischen":["MB","MC"],"text":"64°"},{"bei":"A","zwischen":["AB","AC"],"text":"α = ?"}],"c_lage_grad":80,"massstaeblich":false}`
- Sichtbar: Kreis mit Durchmesser AB und Mittelpunkt M, Punkt C auf dem Kreis, Dreieck ABC, Strecke MC, Winkelbogen ∠BMC mit „64°“, Winkelbogen bei A mit „α = ?“.
- Ausdrücklich nicht sichtbar: Kein Rechter-Winkel-Zeichen bei C, kein Bogen bei B, C nicht an der wahren Lage.
- Beschriftung: A, B, C, M; „64°“ bei M; „α = ?“.
- alt_text: Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck, zusätzlich ist die Strecke von M nach C gezeichnet. Der Winkel zwischen MB und MC ist angegeben, der Winkel Alpha bei A ist gesucht.

#### `9e7c1e4b` · geo_winkel_thales · A

- Generator: **neu: thales**
- params: `{"form":"kreis","punkte":["A","B","C","M"],"strecken":["AB","AC","BC","MC"],"winkel":[{"bei":"A","zwischen":["AB","AC"],"text":"40°"},{"bei":"C","zwischen":["CA","CM"],"text":"?"}],"c_lage_grad":110,"massstaeblich":false}`
- Sichtbar: Kreis mit Durchmesser AB und Mittelpunkt M, Punkt C auf dem Kreis, Dreieck ABC, Strecke MC, Winkelbogen bei A mit „40°“, Winkelbogen zwischen CA und CM mit „?“.
- Ausdrücklich nicht sichtbar: Kein Rechter-Winkel-Zeichen bei C, kein Bogen für den ganzen Winkel γ, keine Markierung gleich langer Strecken MA und MC (das ist der Lösungsschritt), C nicht an der wahren Lage.
- Beschriftung: A, B, C, M; „40°“ bei A; „?“ bei C zwischen CA und CM.
- alt_text: Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck, zusätzlich ist die Strecke von C nach M gezeichnet. Der Winkel bei A ist angegeben, der Winkel zwischen CA und CM ist gesucht.

#### `9f171c32` · geo_winkel_thales · B

- Generator: **neu: thales**
- params: `{"form":"kreis","punkte":["A","B","C","M"],"strecken":["AB","AC","BC"],"winkel":[{"bei":"A","zwischen":["AB","AC"],"text":"α = 35°"},{"bei":"B","zwischen":["BA","BC"],"text":"β = ?"}],"c_lage_grad":100,"massstaeblich":false}`
- Sichtbar: Kreis mit Durchmesser AB und Mittelpunkt M, Punkt C auf dem Kreis, Dreieck ABC, Bogen bei A mit „α = 35°“, Bogen bei B mit „β = ?“.
- Ausdrücklich nicht sichtbar: Kein Rechter-Winkel-Zeichen und kein Bogen bei C (der rechte Winkel ist der Lösungsschritt). C nicht an der wahren Lage.
- Beschriftung: A, B, C, M; „α = 35°“; „β = ?“.
- alt_text: Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck. Der Winkel Alpha bei A ist angegeben, der Winkel Beta bei B ist gesucht.

### Session

#### `3a42b89c` · gleichung_quadr_wurzel · B · von Lena geöffnet

- Generator: **neu: rechtecke**
- params: `{"teile":[{"name":"altes Quadrat","seite_text":"?"},{"name":"neues Quadrat","zusatz_text":"3 cm","flaeche_text":"121 cm²"}],"massstaeblich":false}`
- Sichtbar: Kleines Quadrat mit „?“ an der Seite, in einer Ecke eines größeren Quadrats; an zwei Seiten das Zusatzstück „3 cm“; im großen Quadrat „121 cm²“.
- Ausdrücklich nicht sichtbar: Nicht die Seite des großen Quadrats („11 cm“ ist ein Lösungsschritt), keine Beschriftung „x + 3“, kein Gitter.
- Beschriftung: „?“, „3 cm“ (zweimal), „121 cm²“.
- alt_text: Ein kleines Quadrat mit unbekannter Seitenlänge liegt in der Ecke eines größeren Quadrats. Das große Quadrat ist an zwei Seiten um dasselbe Stück länger, sein Flächeninhalt steht in der Mitte.

#### `5b36238f` · gleichung_quadr_formel · A

- Generator: **neu: rechtecke**
- params: `{"teile":[{"name":"Beet","laenge_text":"20 m","breite_text":"15 m"},{"name":"Weg","rahmen":true,"breite_text":"?"}],"massstaeblich":false}`
- Sichtbar: Rechteckiges Beet „20 m“ × „15 m“, ringsum ein gleich breiter Rahmen (Weg), Wegbreite an einer Stelle mit „?“.
- Ausdrücklich nicht sichtbar: Keine Außenmaße („20 + 2x“ ist der Lösungsschritt), die 500 m² nicht im Bild, kein Gitter, nicht maßstäblich (die Wegbreite wäre sonst messbar).
- Beschriftung: „20 m“, „15 m“, „?“ an der Wegbreite.
- alt_text: Ein rechteckiges Beet, an dessen Seiten die Länge steht. Ringsum verläuft ein überall gleich breiter Weg, seine Breite ist gesucht.

## 3. Fehlende Generator-Typen

| Typ | neu? | Aufgaben | davon A | Aufgaben-ids | Was er können muss |
|---|---|---|---|---|---|
| viereck_diagonalen | neu | 6 | 0 | `0802547a`, `6274f6a5`, `7cfb5d9f`, `c1440c89`, `ef5c0139`, `f8054c53` | Raute oder Drachenviereck mit gestrichelten Diagonalen e und f, optional eine Seitenlänge, eigene Namen für die Diagonalen („Längsstab“). |
| trapez | neu | 6 | 0 | `4bfe5d6e`, `5c219db6`, `94fcae6b`, `f1ecd67e`, `fd558d3f`, `ffcbb7db` | Trapez mit a unten, c oben, gestrichelter Höhe h, optional gleichschenklig mit Schenkelmaß. |
| thales | neu | 6 | 4 | `11aebc7c`, `22e90366`, `3e087e16`, `9ca300e1`, `9e7c1e4b`, `9f171c32` | Kreis oder Halbkreis mit Durchmesser AB, Mittelpunkt M, Punkt C auf dem Bogen, einbeschriebenes Dreieck, optional Strecke MC, Winkelbögen mit Text („32°“, „?“). Die Spec `figur-kreis.md` (nicht gebaut) deckt das nicht ab: Sie kennt keine Punkte, kein Dreieck und keine Winkelbögen. |
| rechtecke | neu | 5 | 2 | `3a42b89c`, `5b36238f`, `f8364853`, `113aea0a`, `11390e1a` | Achsenparallele Rechtecke und Quadrate zusammengesetzt: angesetzt, in einer Ecke abgetrennt, verlängert oder gekürzt, mit Rahmen (Weg). Maße als Text, auch Terme mit x und „?“, Teilflächen tönbar. |
| rechteck | Erweiterung | 2 | 0 | `46192474`, `770f72e9` | `scripts/figures/rechteck.ts` ist vorhanden, kennt aber nur Zahlenmaße und ist nicht in `upload_figures.py`. Braucht Text-Maße (Terme). |
| dreieck | Erweiterung | 1 | 0 | `10f112ad` | Vorhanden als Spec `specs/active/figur-dreieck.md`, nicht gebaut. Braucht zusätzlich Text-Maße (Term „(x + 4) cm“), die Spec sieht nur Zahlen vor. |

Summe: 26 Aufgaben mit neuer oder erweiterter Figur. Dazu kommen 5 Aufgaben mit vorhandener, passender Figur (`koordinatensystem`).

## 4. Reicht jeder Knoten ohne A und D?

„streng“ = nur Aufgaben ohne A oder D. „vorh. ok“ = Aufgaben, die A sind, aber schon eine passende Figur haben, zählen mit. Nur die Figurenfrage: Ob eine Aufgabe auch sonst tauglich ist (Musterlösung, Befunde), steht in `docs/themen/pruefung-batu-inhalte.md` und ist hier nicht eingerechnet.

### Stufe 3

| Knoten | gesamt | A | B | C | D | Soll / min. ohne MC | streng (ohne MC) | reicht streng | vorh. ok (ohne MC) | reicht | zuerst |
|---|---|---|---|---|---|---|---|---|---|---|---|
| fkt_linear_gleichung | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| fkt_linear_steigung | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| fkt_linear_yabschnitt | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| term_binom_faktorisieren | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (1) | ja | 6 (1) | ja | – |
| term_binom_gemischt | 7 | 0 | 1 | 6 | 0 | 2 / 1 | 7 (1) | ja | 7 (1) | ja | – |
| term_binom_quadrat | 7 | 0 | 0 | 7 | 0 | 2 / 1 | 7 (1) | ja | 7 (1) | ja | – |
| term_binom_quadratdifferenz | 6 | 0 | 1 | 5 | 0 | 2 / 1 | 6 (1) | ja | 6 (1) | ja | – |
| gleichung_lgs_addition | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (5) | ja | 6 (5) | ja | – |
| gleichung_lgs_einsetzen | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| gleichung_lgs_grafisch | 6 | 5 | 0 | 1 | 0 | 2 / 1 | 1 (0) | **nein** | 6 (4) | ja | keine (Figuren vorhanden) |
| geo_flaeche_drachen_raute | 6 | 0 | 6 | 0 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| geo_flaeche_term | 6 | 1 | 3 | 2 | 0 | 2 / 1 | 5 (2) | ja | 5 (2) | ja | – |
| geo_flaeche_trapez | 6 | 0 | 6 | 0 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| stoch_pfad_summe | 6 | 0 | 0 | 6 | 0 | 2 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| geo_winkel_thales | 6 | 4 | 2 | 0 | 0 | 2 / 1 | 2 (2) | ja | 2 (2) | ja | thales (Reserve, reicht nur knapp) |

### Stufe 1

| Knoten | gesamt | A | B | C | D | Soll / min. ohne MC | streng (ohne MC) | reicht streng | vorh. ok (ohne MC) | reicht | zuerst |
|---|---|---|---|---|---|---|---|---|---|---|---|
| zahl_wurzel_irrational | 6 | 0 | 0 | 6 | 0 | 6 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| zahl_wurzel_naeherung | 6 | 0 | 0 | 6 | 0 | 6 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| zahl_wurzel_teilweise | 6 | 0 | 0 | 6 | 0 | 6 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| zahl_wurzel_gesetze | 6 | 0 | 0 | 6 | 0 | 6 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| zahl_wurzel_quadrat | 6 | 0 | 0 | 6 | 0 | 6 / 1 | 6 (6) | ja | 6 (6) | ja | – |

### Stufe 2

| Knoten | gesamt | A | B | C | D | Soll / min. ohne MC | streng (ohne MC) | reicht streng | vorh. ok (ohne MC) | reicht | zuerst |
|---|---|---|---|---|---|---|---|---|---|---|---|
| potenzen | 24 | 0 | 0 | 24 | 0 | 3 / 1 | 24 (24) | ja | 24 (24) | ja | – |
| bruch_dezimal | 6 | 0 | 0 | 6 | 0 | 3 / 1 | 6 (6) | ja | 6 (6) | ja | – |
| dezimal_div | 9 | 0 | 0 | 9 | 0 | 3 / 1 | 9 (9) | ja | 9 (9) | ja | – |
| dezimal_mult | 9 | 0 | 0 | 9 | 0 | 3 / 1 | 9 (9) | ja | 9 (9) | ja | – |
| vorzeichen_mult_div | 7 | 0 | 0 | 7 | 0 | 3 / 1 | 7 (7) | ja | 7 (7) | ja | – |
| runden_ueberschlag | 13 | 0 | 0 | 13 | 0 | 3 / 1 | 13 (13) | ja | 13 (13) | ja | – |
| dezimal_add_sub | 11 | 0 | 0 | 11 | 0 | 3 / 1 | 11 (11) | ja | 11 (11) | ja | – |
| bruch_kuerzen | 7 | 0 | 0 | 7 | 0 | 3 / 1 | 7 (7) | ja | 7 (7) | ja | – |
| vorzeichen_add_sub | 7 | 0 | 0 | 7 | 0 | 3 / 1 | 7 (7) | ja | 7 (7) | ja | – |

### Session

| Knoten | gesamt | A | B | C | D | Soll / min. ohne MC | streng (ohne MC) | reicht streng | vorh. ok (ohne MC) | reicht | zuerst |
|---|---|---|---|---|---|---|---|---|---|---|---|
| vorzeichen_add_sub | 7 | 0 | 0 | 7 | 0 | 7 / 0 | 7 (7) | ja | 7 (7) | ja | – |
| term_ausklammern | 6 | 0 | 0 | 6 | 0 | 6 / 0 | 6 (0) | ja | 6 (0) | ja | – |
| gleichung_einschrittig | 6 | 0 | 0 | 6 | 0 | 6 / 0 | 6 (6) | ja | 6 (6) | ja | – |
| gleichung_zweischrittig | 6 | 0 | 0 | 6 | 0 | 6 / 0 | 6 (6) | ja | 6 (6) | ja | – |
| gleichung_quadr_wurzel | 6 | 0 | 1 | 5 | 0 | 6 / 0 | 6 (6) | ja | 6 (6) | ja | – |
| gleichung_quadr_faktor | 6 | 0 | 0 | 6 | 0 | 6 / 0 | 6 (6) | ja | 6 (6) | ja | – |
| gleichung_quadr_formel | 6 | 1 | 0 | 5 | 0 | 6 / 0 | 5 (5) | **nein** | 5 (5) | **nein** | rechtecke (Rahmen) für `5b36238f` |
| gleichung_quadr_anzahl | 6 | 0 | 0 | 6 | 0 | 6 / 0 | 6 (6) | ja | 6 (6) | ja | – |

### Reihenfolge für F2

1. **thales**: 6 Aufgaben, 4 davon A. Stufe 3 ist ab Do 22.10. dran, und der Knoten hat ohne die Figur keine Reserve.
2. **rechtecke**: 5 Aufgaben, 2 davon A. 5b36238f entscheidet, ob die Session `gleichung_quadr_formel` vollständig ist. 11390e1a ist A in `geo_flaeche_term` (reicht auch ohne).
3. **viereck_diagonalen**, **trapez**: je 6 Aufgaben, alle B. Kein Knoten hängt daran.
4. **rechteck**, **dreieck** mit Term-Beschriftung: 3 Aufgaben, alle B.
