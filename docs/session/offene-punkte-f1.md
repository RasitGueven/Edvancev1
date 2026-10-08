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
   - Die F1-Felder kosten etwa 2–6 ms je Aufruf (Messung im PR).
   - Das Tempo-Problem im Trockenlauf kam aus der überlappenden Abfrage (A5, behoben), nicht aus der Datenbank.
6. **Migrationsversionen** `20261011140000`, `20261011140100` liegen im Auftragsbereich, also in der Zukunft
   (CLAUDE.md §10 verlangt `date -u`). Per dbread am 08.10. geprüft: frei; Prod-Maximum `20261011100200`.
7. **Schema-Abzug** erst nach dem Einspielen (Auftrag). Bis dahin ist der CI-Schemavergleich rot.

## Szenario Batu (B): offen bis zur Abnahme

Siehe `docs/szenario/batu.md` Abschnitt 0:
- **E1:** Es gibt keinen Lead mit `ist_test`.
- **E2:** Ohne Testlauf ist der LSA-Pool leer; ein Testlauf erzeugt keinen Lernpfad.
- **E3:** Das Warm-up wählt bei Gleichstand alphabetisch.
