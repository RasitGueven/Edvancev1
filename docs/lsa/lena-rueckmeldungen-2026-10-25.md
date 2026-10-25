# Lenas Rückmeldungen vom 25.10.2026 (L1)

Stand Prod 25.10.2026 (dbread, nur lesend). Auftrag: `docs/lsa/Bauauftrag-L1.md`.

## Bestand

- Freigegeben (Lena-Board, `pruef_board()` mit `lena_status = 'freigegeben'`): **123**, gleich Rasits Zahl.
  In `tasks` stehen 136 Aufgaben auf `ready`, 13 davon ohne Pilotmarke und deshalb nicht im Board.
- Prüfprotokolle mit Rückmeldung (letzte Zeile je Aufgabe mit Notiz, Gründen oder `unsicher`/`passt_nicht`): 22.
  11 davon sind vom 19. bis 21.10. und schon beantwortet. **Die 11 neuen** sind vom 25.10., alle `unsicher`,
  ohne Antwort, Status `rueckfrage`. Um diese 11 geht es hier.
- In keiner der 11 Aufgaben gibt es eine LSA-Antwort, die einen neuen Fehler-Wert trifft. Nachträglich ist
  nichts zuzuordnen.

## Die 11 Rückmeldungen

Klären heißt `pruef_rueckfrage_klaeren`: **freigeben**, wenn nur known_errors oder Hinweise dazukommen oder nichts
geändert wird; **an_lena**, wenn sich der Aufgabentext ändert. Die Aufgabe ist dann wieder offen bei Lena.

**Nachtrag (Rasit, 25.10.):** Die vier Text-Aufgaben (2–5) hat Rasit danach direkt freigegeben
(`pruef_admin_freigeben`, `tools/l1b-nachtrag-freigeben.sql`). In den Antworten steht statt „… liegt noch einmal
bei dir.“ jetzt „Wir haben die Aufgabe direkt freigegeben.“ (`tools/l1b-antworten-nachtrag.sql`).

| # | Aufgabe (skill_key · Kurztitel) | Was Lena schreibt (wörtlich) | Art | Vorschlag | Umsetzen? |
|---:|---|---|---|---|---|
| 1 | vorzeichen_vorrang · Vorrang · -3 + 4 · 2 (`a394b2eb`) | „Ich würde hier ergänzen, dass das Kind nicht nur Punkt vor Strich ignoriert. Es kann auch passieren, dass es das Minuszeichen falsch einordnet und -3 + 4 = -7 erhält und dann x2 rechnet = -14“ | Fehlbild fehlt | known_errors `-14` → `plus_minus_vertauscht` (−3 + 4 als −3 − 4 = −7, dann · 2; Punkt vor Strich zusätzlich ignoriert). Dazu `-11` → `plus_minus_vertauscht` (gleicher Vorzeichenfehler, Vorrang richtig: −3 − 8) und `11` → `vorzeichen_ignoriert` (3 + 8), wie in den übrigen Vorrang-Aufgaben. | ja, freigeben |
| 2 | term_binom_quadrat · 49² (`3b1e6f0a`) | „Ich würde hier in der Aufgabenstellung formulieren "mit Hilfe einer binom. Formel"“ | Text/Darstellung | „Berechne geschickt mit einer binomischen Formel.“ → „Berechne geschickt mit Hilfe einer binomischen Formel.“ (question und question_payload.prompt) | ja, an_lena → direkt freigegeben |
| 3 | gleichung_modellieren · Handytarif (`4f0b933d`) | „Ich würde hier in der Teilaufgabe b.) ergänzen: "Wenn die Rechnung 45 Euro beträgt, wie viel Gigabyte wurden in diesem Monat verbraucht?"“ | Text/Darstellung | Teil 2: „Wie viele Gigabyte wurden genutzt?“ → „Wenn die Rechnung 45 € beträgt, wie viele Gigabyte wurden in diesem Monat verbraucht?“ Der Stamm behält „Die Rechnung beträgt 45 €.“, weil Teil a ihn für die Gleichung braucht. | ja, an_lena → direkt freigegeben |
| 4 | gleichung_zweischrittig · 2x + 4 = 20 (`e8348c89`) | „Ich würd hier "Gib den Wert für x an" in der Aufgabenstellung weglassen. Löse die Gleichung sollte für die SuS bedeuten, dass sie den x-Wert angeben.“ | Text/Darstellung | „Löse die Gleichung. Gib den Wert für x an.“ → „Löse die Gleichung.“ Die Zahlentastatur des Tablets hat keine Buchstaben, ein „x = 8“ ist dort nicht tippbar. Nur über den Behelfs-Umschalter zur Term-Eingabe ginge es, und `lsa_is_correct` wertet „x = 8“ als falsch. | ja, an_lena → direkt freigegeben |
| 5 | gleichung_zweischrittig · 3x + 6 = 24 (`7976c81f`) | „ebd. "Löse die Gleichung" reicht als Aufgabenstellung.“ | Text/Darstellung | wie 4 | ja, an_lena → direkt freigegeben |
| 6 | gleichung_beidseitig · 5x + 3 = 2x + 18 (`19ba5f42`) | „Hier kann es passieren, dass bei den SuS ein "Error" im Gehirn entsteht, weil sie nicht wissen, dass sie auch "5x-2x" rechnen dürfen. Dann kommen sie oft nicht weiter.“ | Rückfrage ohne Änderungsbedarf | Kein falscher Wert, das Kind bleibt hängen. Das zeigt die LSA als „übersprungen“. AFB I (Lenas Änderung) bleibt. | nein, freigeben |
| 7 | term_ausmultiplizieren · 3(x + 2) (`1527a939`) | „Hier kann passieren, dass die SuS nur einen Summand mit 3 multiplizieren = 3x + 2“ | Fehlbild fehlt | Passt zu `klammer_vergessen` („die Operation trifft nur einen Teil des Terms“). TERM-Aufgaben dürfen kein `acceptance` tragen (Trigger `lsa_term_acceptance_guard`), also auch keine known_errors. Deshalb nur ein Eintrag in typical_errors ohne Fehlbild-Slug: Lena sieht ihn unter „weitere Hinweise“, erkannt wird er noch nicht. | teilweise (Hinweis), freigeben |
| 8 | term_ausmultiplizieren · -3(x + 2) (`10a764bc`) | „ich kann mir vorstellen, dass  "Gib das Ergebnis in der Form ax + b an." zu Verwirrung führen kann. Ich glaube es reicht, wenn nur der erst Satz der Aufgabe bestehen bleibt.  Ansonsten könnten ihr hinzufügen "fasse soweit wie möglich zusammen" / Hier auch typischer Fehler: Distributivgesetz nicht vollständig angewendet = -3x + 2 / Außerdem kann das Minuszeichnen nur teilweise berücksichtig werden = -3x + 6“ | Text/Darstellung + Fehlbild fehlt | Text bleibt: TERM wird Zeichen für Zeichen verglichen, `-6-3x` und `−3x−6` gelten heute als falsch (per dbread geprüft). Ohne den Satz zur Reihenfolge würden richtige Antworten abgelehnt. Fehler: `-3x+2` → `klammer_vergessen`; für `-3x+6` gibt es kein passendes Fehlbild (Vorschlag **neu**: `vorzeichen_teilweise_verteilt`, „Multipliziert mit dem Betrag richtig, nimmt das Minus aber nur beim ersten Glied mit.“). Beide als typical_errors ohne Slug, wie 7. | Text nein, Fehler teilweise (Hinweis), freigeben |
| 9 | term_zusammenfassen · 3x + 5 + 2x - 1 (`df219b8c`) | „Hier kann es wieder passieren, dass die SuS sich unsicher sind, ob sie 3x und 2x miteinander verrechnen dürfen.“ | Rückfrage ohne Änderungsbedarf | wie 6 | nein, freigeben |
| 10 | bruch_dezimal · 3/4 (`6ef85b4a`) | „Hier würde ich dann auch ergänzen, dass falsch gerechnet wurde = 4/3 = 1,3“ | Fehlbild fehlt | known_errors `1,3`, `1,33`, `1,333`, `4/3` → `umgekehrt_geteilt` (4 : 3 = 1,333…), wie bei 1/2, 1/4, 1/5 (dort `2`, `4`, `5`). | ja, freigeben |
| 11 | geo_koordinaten · Punkt ablesen · 1. Quadrant (`650eed2a`) | „ich finds hier super, dass ihr Teilaufgaben konzipiert habt! Ich glaube, dadurch ist es für die SuS einfacher den Punkt abzulesen. Sonst könnte es passieren, dass nur der X Wert (4/0) oder nur der Y Wert (0/3) abgelesen wird.“ | Rückfrage ohne Änderungsbedarf | Lob für die Teilaufgaben. Ohne sie wäre der Fehler möglich, mit ihnen fragt die Aufgabe x und y getrennt ab. | nein, freigeben |

**Gegenbeispiele:** Keine Rückmeldung verlangt eine weitere richtige Antwort, die Akzeptanz wird nirgends weiter.
Jeder neue known_error-Wert ist von der richtigen Antwort verschieden: `5` bei 1, `0,75` bei 10. Geprüft wird
das in `supabase/checks/l1b_rueckfragen.PRUEFUNG.sql` mit `lsa_grade` und `lsa_fehlbild_match`.

## Antwort an Lena

| # | Aktion | Antwort an Lena |
|---:|---|---|
| 1 | freigeben | Danke, guter Punkt! −14 ist jetzt als Fehler hinterlegt (Fehlerbild „Plus und Minus vertauscht“): −3 + 4 als −7 gerechnet und dann mal 2. Mitgenommen haben wir auch −11 (derselbe Vorzeichenfehler, aber Punkt vor Strich richtig) und 11 (Minus ganz weggelassen), wie bei den anderen Vorrang-Aufgaben. Dein AFB I bleibt. Freigegeben. |
| 2 | an_lena → freigegeben | Danke! Der Text lautet jetzt „Berechne geschickt mit Hilfe einer binomischen Formel.“ (vorher „… mit einer binomischen Formel.“). Wir haben die Aufgabe direkt freigegeben. Offen ist bei uns noch, dass man 49² mit dem Taschenrechner auch direkt ausrechnen kann. Das klären wir. |
| 3 | an_lena → freigegeben | Danke, übernommen! Teilaufgabe b lautet jetzt „Wenn die Rechnung 45 € beträgt, wie viele Gigabyte wurden in diesem Monat verbraucht?“ (vorher „Wie viele Gigabyte wurden genutzt?“). Der Satz mit den 45 € bleibt oben stehen, weil Teil a ihn für die Gleichung braucht. Wir haben die Aufgabe direkt freigegeben. |
| 4 | an_lena → freigegeben | Danke, übernommen! Da steht jetzt nur noch „Löse die Gleichung.“, ohne „Gib den Wert für x an.“ Wir haben die Aufgabe direkt freigegeben. |
| 5 | an_lena → freigegeben | Danke, übernommen! Wie bei 2x + 4 = 20 steht jetzt nur noch „Löse die Gleichung.“ Wir haben die Aufgabe direkt freigegeben. |
| 6 | freigeben | Danke für die Einordnung! Bleibt ein Kind hier hängen und überspringt die Aufgabe, steht sie in der Auswertung als „übersprungen“. Auch das sagt uns etwas. An der Aufgabe ändern wir deshalb nichts. Dein AFB I bleibt. Freigegeben. |
| 7 | freigeben | Danke, guter Hinweis! 3x + 2 ist genau der Fehler „Klammer nur teilweise ausmultipliziert“. Bei Term-Eingaben kann das Tablet Fehler leider noch nicht automatisch erkennen, es prüft nur, ob der Term stimmt. Wir haben den Fehler deshalb als Hinweis an der Aufgabe hinterlegt, die Erkennung kommt später. Freigegeben. |
| 8 | freigeben | Danke! Die beiden Fehler (−3x + 2 und −3x + 6) haben wir als Hinweise an der Aufgabe hinterlegt. Automatisch erkennen kann das Tablet sie bei Termen noch nicht. Den Satz „Gib das Ergebnis in der Form ax + b an.“ lassen wir vorerst stehen: Das Tablet vergleicht den Term Zeichen für Zeichen, ohne den Satz würde zum Beispiel −6 − 3x als falsch gewertet. Sobald die Reihenfolge egal ist, ändern wir das bei allen Term-Aufgaben. Wäre dann „Multipliziere aus und fasse so weit wie möglich zusammen.“ für dich gut? Freigegeben. |
| 9 | freigeben | Danke für die Einordnung! Ist ein Kind unsicher und überspringt die Aufgabe, steht sie in der Auswertung als „übersprungen“. Auch das sagt uns etwas. An der Aufgabe ändern wir deshalb nichts. Freigegeben. |
| 10 | freigeben | Danke, übernommen! 4 : 3 = 1,3 (auch 1,33, 1,333 oder 4/3) ist jetzt als Fehler hinterlegt, Fehlerbild „Beim Teilen wurde die Reihenfolge umgedreht“, so wie schon bei 1/2, 1/4 und 1/5. Freigegeben. |
| 11 | freigeben | Danke, freut uns! Genau dafür sind die Teilaufgaben da. Wir ändern nichts. Freigegeben. |

## Zusatzprüfung der 123 freigegebenen Aufgaben (nur gelistet, nichts geändert)

Hilfsmittel laut `pruef_einstellungen`: „Taschenrechner, Stift und Zettel“.

### Mit Taschenrechner ohne die geprüfte Methode lösbar

**A · Die Aufgabe verlangt eine Methode, der Taschenrechner umgeht sie** (wie 47² − 43²). Hier fällt die Diagnose
weg: Eine richtige Antwort sagt nichts über die Methode.

| Fertigkeit | n | Aufgaben | Warum |
|---|---:|---|---|
| zahl_wurzel_gesetze | 6 | `ce24db36`, `926f4f6e`, `88c99e21`, `a0a8c04b`, `760fc0ad`, `4f7652bf` | „exakt“ mit Wurzelgesetz, z. B. √2 · √8 oder √50 : √2, direkt eintippbar |
| zahl_wurzel_teilweise | 6 | `ef90a8ac`, `1dece473`, `ad08897e`, `21427340`, `0bcc83c8`, `df6b2bcd` | a = √72 : √2 bzw. b = (6√3)² direkt; teilweises Wurzelziehen wird nicht gebraucht |
| zahl_wurzel_quadrat | 6 | `afc3b977`, `16d6e3b7`, `55239bfc`, `99b7829c`, `4b3b14a9`, `5f9d6c06` | √-Taste liefert den Wert |
| *nicht im Bestand der 123:* term_binom_quadrat | 1 | `3b1e6f0a` (49², Rückmeldung 2) | „geschickt mit binomischer Formel“, 49² direkt |

**B · Reine Rechenaufgabe, das Ergebnis ist der eingetippte Ausdruck.** Mit Taschenrechner prüft die Aufgabe nur
das Eintippen. Ob das gewollt ist, hängt an den Hilfsmitteln für die Grundlagen-Bereiche.

| Fertigkeit | n | Aufgaben |
|---|---:|---|
| potenzen | 19 | `01f22500`, `25539057`, `a3343b39`, `855d22d3`, `89ad1d12`, `e5da9c79`, `e7c7b1c6`, `796659c3`, `bbc88883`, `aef364ee`, `83839a0b`, `db07cb07`, `5c73a51d`, `59c982b3`, `e1aeb6a9`, `fd7c0327`, `744b2ea7`, `72d61822`, `9ee7cbb7` |
| vorzeichen_add_sub | 7 | `e96cd37d`, `17674b19`, `27f51c08`, `c92aa7e8`, `3b44eada`, `3e6fb055`, `738de19f` |
| vorzeichen_mult_div | 7 | `38aa9504`, `7db70449`, `751f9c63`, `0438a9f9`, `2e8ce53f`, `e58cb290`, `ba0701ff` |
| vorzeichen_vorrang | 2 | `864f0b02`, `573dd0b7` (der Rechner beachtet Punkt vor Strich selbst) |
| dezimal_add_sub / _mult / _div | 9 | `024143bf`, `172db197`, `be8ce7e4`, `3d066cef`, `3038721a`, `0cbaacfd`, `6b531762`, `bdf4d10a`, `400b8905` |
| bruch_dezimal | 3 | `de2aabbf`, `80105584`, `3768ecdc` |
| zahl_wurzel_naeherung | 6 | `9af2a3ce`, `fde9c9a1`, `0b9229a0`, `6585552b`, `cd35f4b2`, `81015f65` (Wurzel per Taste, geprüft wird nur noch das Runden) |

Nicht gelistet: Bei Geometrie, Größen, Proportionalität, Runden, Gleichungen, Modellieren, Terme (TERM/MC),
term_einsetzen, zahl_wurzel_irrational und bruch_kuerzen braucht man den Ansatz trotz Rechner. Grenzfälle sind
bruch_kuerzen und `9935f4bb` (0,375 als Bruch): Rechner mit Bruchtaste kürzen bzw. wandeln selbst um.

### Ohne einen einzigen known_error

4 von 123, alle vom Typ TERM. Dort ist kein known_error möglich (`lsa_term_acceptance_guard`):
`2d1dc092` 4(x + 5), `696f6d98` 5(x − 3), `b779c26b` 2x + 7 + 6x − 10, `c83b34e8` 4x + 9 + 3x − 2.

## Offene Punkte

- **TERM-Fehlbilder:** known_errors für TERM sind gesperrt, und die Bewertung vergleicht Zeichen für Zeichen.
  Foundation-Thema: Reihenfolge normieren und known_errors für TERM erlauben, dann die typical_errors aus 7 und 8
  übernehmen, das neue Fehlbild `vorzeichen_teilweise_verteilt` anlegen und den Satz „in der Form ax + b“ bei allen
  TERM-Aufgaben ersetzen (ready 4, rueckfrage 3, draft 13).
- **„Gib den Wert für x an.“** steht noch in 7 freigegebenen und 15 Entwurfs-Aufgaben, dazu in 19ba5f42 (6).
  Wenn Lenas Regel allgemein gelten soll, in einem eigenen Paket angleichen (Textänderung, also zurück an Lena).
- **Taschenrechner:** Liste A ist ein Diagnoseproblem. Entscheidung Rasit: Hilfsmittel je Bereich
  (z. B. ohne Taschenrechner für Wurzel/Potenz) oder Aufgaben so umbauen, dass der Ansatz gefragt ist.
