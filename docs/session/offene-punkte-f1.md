# Offene Punkte F1 (Coach-Sicht aus dem Trockenlauf, Szenario Batu)

Stand 08.10.2026, Branch `feat/rasit-session-f1-trockenlauf`. Beweis: `supabase/tests/session_f1.test.sql`,
`src/lib/session/coachLiveEingabe.test.ts`, `src/hooks/useRaumLive.test.ts`, `src/pages/coach/live/CoachLiveF1.test.tsx`.

## A6 Kernarbeit beim y-Achsenabschnitt, Steigung „offen“ (gewollt, Anzeige behoben)

**Daten** (dbread, Session `75f389ee…`, ein Kind, Testlauf):
- Die Zielliste stimmt mit trockenlauf.md 4 überein.
- `session_schritte` 1–5 laufen auf `fkt_linear_steigung`:
  - 1: `warten/pool_leer` um 12:51:22, vor dem Phasenwechsel nach `kern`.
  - danach Beispiel, Aufgabe, `kern`, `kern`.
- Antworten zur Steigung: 13:02 richtig, 13:03 falsch (`betrag_fehler`), 13:04 richtig. Alle ohne Hinweis.
- Ab Schritt 6 (13:04:03) läuft `fkt_linear_yabschnitt` mit `neu_beispiel_ohne_erklaerung`.

**Warum:** Die Engine hat richtig gehandelt.
- Stellschraube `mastery_richtig_ohne_hinweis = 2` (Snapshot der Session). Nach der zweiten richtigen Aufgabe ohne
  Hinweis gilt die Steigung als heute sicher (`session_heute_sicher`, offene-punkte-a2 F7).
- `session_zielliste` setzt sie dann auf `offen = false`, und der nächste offene Skill ist der y-Achsenabschnitt.
- Das ist gewollt (F7). Die Reihenfolge innerhalb des Pools (F11) spielt hier keine Rolle.

**Fehler in der Anzeige** (Coach-Schublade, nicht Engine):
1. „Ziel der Stunde“ zeigte den **Lernpfad-Stand** aus `ziel_fertigkeiten`.
   - Im Testlauf entstehen keine Belege, also blieb die Steigung „offen“.
   - Außerhalb des Testlaufs stünde sie erst nach den Belegen auf „Kandidat“.
2. „heute n von m“ zählte **alle Kern-Antworten der Session** und hängte die Zahl an den aktuellen Skill.
   - Zwischen 13:04 und 13:06 waren das die drei Antworten zur Steigung (2 richtig) am y-Achsenabschnitt.
   - Daraus wurde „heute 2 von 3“.

**Änderung:**
- `coach_kind_detail.heute_sicher` (Migration `20261011140100`) nennt die Skills, die die Engine heute als sicher zählt.
  Die Schublade schreibt dazu „heute sicher, weiter zum nächsten Skill“.
- „heute n von m“ kommt je Skill aus `coach_kind_detail.heute` (Kernarbeit und Eingemischtes dieses Skills).
- Die Engine ist unverändert.

## A1–A5: was offen bleibt

1. **Thema bei Fall „Klassenarbeit“.** „Thema wählen“ setzt immer Fall „Schulthema“ (`checkin_coach_setzen`).
   - Bei einer Klassenarbeit mit „anderes Thema“ (`klassenarbeit_thema_key = null`) gibt es weiter keinen Weg, das
     KA-Thema zu setzen. Wählt der Coach dort ein Thema, wechselt der Fall auf Schulthema.
   - Das ist keine neue Schreibfunktion (Auftrag). Wer: Rasit entscheidet, ob ein KA-Thema über
     `checkin_coach_setzen` kommen soll.
2. **Warm-up entfallen, Grund.**
   - `kein_stoff` heißt: Die Kernarbeit begann, als die Uhr noch Check-in oder Warm-up zeigte.
   - `zeit` heißt: Sie begann erst danach.
   - Die Engine selbst schreibt `ohne_warmup` nicht mit (`session_plan_warmup` gibt es zurück, `session_schritt_planen`
     verwirft es). Der Grund ist deshalb abgeleitet, nicht protokolliert.
   - Ein genauerer Grund (welcher Skill ohne Aufgabe) wäre eine Engine-Änderung.
3. **Kopf.** Die Ansicht folgt weiter der Uhr. Neu ist die Zeile „Kinder gerade: Kernarbeit 1 · Check-in 2“, die
   zur Ansicht der Phase springt. Ob die Ansicht selbst dem Kind folgen soll (bei mehreren Kindern in verschiedenen
   Phasen), entscheidet Rasit beim nächsten Trockenlauf.
4. **Signale hängen an der Uhr.** Der Vergleich vorher/nachher (A5) muss im selben Moment laufen:
   - `session_signale_intern` rechnet „ohne Eingabe seit n Minuten“ ab `now()`.
   - Zwei Läufe im Abstand von Minuten unterscheiden sich deshalb, auch ohne Änderung.
5. **Tempo, Stand Wegwerf-DB.**
   - Gemessen: 5 Kinder × 30 Antworten, `docs/session/f1-messung.sql`, `f1-messung-lauf.sql`.
   - Beide Funktionen bleiben im einstelligen bis niedrigen zweistelligen ms-Bereich, weit unter 300 ms.
   - Langsame Stellen gibt es nicht; alle Abfragen laufen über vorhandene Indizes (`session_*_kind_idx`).
   - Mit den F1-Feldern bleibt der Median im Rauschen der Messung (raum 7–8 ms, Kind 2 ms; Tabelle im PR).
   - Das Tempo-Problem im Trockenlauf kam aus der überlappenden Abfrage (A5, behoben), nicht aus der Datenbank.
6. **Migrationsversionen** `20261011140000`, `20261011140100` liegen im Auftragsbereich, also in der Zukunft
   (CLAUDE.md §10 verlangt `date -u`). Per dbread am 08.10. geprüft: frei; Prod-Maximum `20261011100200`.
7. **Schema-Abzug** erst nach dem Einspielen (Auftrag). Bis dahin ist der CI-Schemavergleich rot.

## Szenario Batu (B)

Muster abgenommen („Muster Batu ok“, Rasit 08.10.). Entscheidungen E1 bis E3 in `docs/szenario/batu.md` 0.

8. **E2 nur in der adaptiven LSA.** Umgesetzt in `lsa_select_next_core` (Migration `20261011140200`); `lsa_im_pool`
   selbst bleibt unverändert, weil es das Kind nicht kennt. Der alte Modus `fest` in `lsa_start` prüft weiter nur
   `lsa_im_pool(t, p_testlauf)`: Ein Testkonto bekommt dort ohne Testlauf keine Entwürfe. Der Modus wird nur noch
   ausdrücklich gewählt. Wer: Rasit, falls `fest` für Testkonten gebraucht wird. Beweis:
   `supabase/tests/lsa_pool_testkonten.test.sql` (P2 ohne Migration rot, mit grün).
9. **E3 Kandidatenmenge (Rasit 08.10.: bleibt).** Mit der unveränderten Menge greifen (1) und (2) nur bei Skills, die
   heute schon im Warm-up dran waren; wirksam ist vor allem (3). Beweis: `session_f1` E3 (vorher rot: `zz_f1_a` statt
   `zz_f1_b`).
10. **Kanten zu Quadratische Gleichungen (an die Inhaltspflege, nichts geändert).** dbread 09.10. `skill_kante`:

    | Skill | setzt voraus |
    |---|---|
    | gleichung_quadr_faktor (Einstieg) | gleichung_einschrittig, term_ausklammern |
    | gleichung_quadr_formel (Einstieg) | gleichung_quadr_wurzel, term_einsetzen |
    | gleichung_quadr_wurzel | gleichung_zweischrittig, **zahl_wurzel_quadrat** |
    | gleichung_quadr_anzahl | gleichung_quadr_formel |

    Ein Wurzel-Skill **ist** Voraussetzung, aber nur über `gleichung_quadr_wurzel` (x² = a lösen). Der erste offene
    Ziel-Skill eines Kindes ohne Lernpfad im Thema ist meist `gleichung_quadr_faktor` (Ausklammern, Nullprodukt):
    Der braucht keine Wurzel. Deshalb führt bei Batu kein Weg vom Warm-up zur Wurzel. Kanten, die nach den Inhalten
    fehlen dürften (Vorschlag, Entscheidung Inhaltspflege):
    - `gleichung_quadr_formel → zahl_wurzel_teilweise`: Die p-q-Formel liefert Lösungen wie −2 ± √12 = −2 ± 2√3.
    - `gleichung_quadr_formel → zahl_wurzel_naeherung`: Lösungen als Näherungswert („auf zwei Stellen runden“).
    - schwächer: `gleichung_quadr_anzahl → zahl_wurzel_irrational` (rationale oder irrationale Lösungen).

    Folge, falls die Kanten kommen: zahl_wurzel_teilweise und …_naeherung (bei Batu noch nicht sicher) stünden als
    Voraussetzung in der Zielliste. Batus Kernarbeit könnte dann bei einer Wurzel-Voraussetzung beginnen, nicht bei
    faktor.
11. **Einmischen (F13) mit derselben Schwäche.** `session_misch_kandidaten` ordnet Voraussetzung, zuletzt geübt, dann
    `skill_key`. Nach einer LSA sind alle mitbelegten Fundamente gleich „nie geübt“; es gewinnt das Alphabet. Bei Batu
    kommt zahl_wurzel_quadrat erst als etwa vierter eingemischter Skill. Nicht geändert (nicht Teil von E3). Wer:
    Rasit, ob F17 auch fürs Mischen gelten soll.
12. **Zurücksetzen löscht `lernpfad_protokoll`.** Nur die Übernahme-Zeilen der Szenario-LSA. Die Tabelle hat keine
    Lösch-Sperre. Abbruch, sobald es andere Protokollzeilen, Belege oder eine Coach-Entscheidung gibt. Soll das
    Protokoll unantastbar sein, bleibt nach dem Zurücksetzen dort eine Spur. Wer: Rasit.
13. **Szenario-LSA endet vor der Breite.** Das Werkzeug ruft `lsa_finish` beim ersten Item außerhalb des Musters; ein
    echtes Kind säße bis Minute 19. `lsa_skill_urteil` trägt die übrigen Themenraum-Skills als `ungeprueft`; sie gehen
    nicht in den Lernpfad.
14. **Platzhalter-Sequenz ersetzen.** Migration `20261011140400`, ids `e7dce277…` (Kernidee), `151258bb…`/`7d7b0e1e…`
    (Schritte), `a368a0d0…` (Check-Aufgabe, `source = 'edvance_f1_platzhalter'`). Bei einer echten Sequenz für
    gleichung_quadr_faktor diese Zeilen löschen. Bis dahin sieht man sie nur im Testlauf.
15. **Hinweise im Testlauf** zeigen „nicht verfügbar“ (Paket T3); in batu-session.md vermerkt.
16. **Migrationsversionen** `20261011140200` bis `…140400` liegen wie 6. im Auftragsbereich (Zukunft, §10). Per dbread
    09.10. geprüft: frei.
