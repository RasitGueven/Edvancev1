# Offene Punkte F2 (Phasen folgen den Kindern, Trockenlauf 10.10.)

Stand 12.10.2026, Branch `feat/rasit-session-f2-phasen`. Keine Migration. Beweis: `supabase/tests/session_f2_phasen.test.sql`,
`src/lib/session/coachLivePhase.test.ts`, `src/pages/coach/live/CoachLiveF2.test.tsx`.

## 1 Analyse Trockenlauf 10.10. (dbread, nur Testkonten)

Am 10.10. liefen drei Sessions nacheinander, alle mit `testlauf = false`, je ein Kind, alle Kinder Testkonten
(`ist_test`, Akte aktiv). Snapshot jeweils `phase_checkin_min` 5, `phase_warmup_min` 10, `warmup_aufgaben` 3. Zeiten in
Europe/Berlin.

| Session | Kind | Start | Ende | Tablet | Check-in |
|---|---|---|---|---|---|
| `64ea8d88…` | TESTLEAD Drittmann | 14:15:13 | 14:26:24 | keins | keins |
| `d3e7510f…` | TESTLEAD Zweitmann | 14:26:54 | 14:32:38 | 1, 14:27:42–14:32:38 | 14:28:52 |
| `c9465abe…` | TESTLEAD Drittmann | 14:32:55 | **läuft noch** | 1, seit 14:32:58 | 14:33:56 |

### Session `d3e7510f…` (die im Auftrag genannte)

| Zeit | Quelle | Was | Uhr zeigt |
|---|---|---|---|
| 14:26:54 | `gestartet_am` | Session gestartet | Check-in bis 14:31:54, Warm-up bis 14:41:54 |
| 14:27:42.483 | `session_ereignisse` | `phase_wechsel` checkin (`tablet_zuweisen`, Coach) | Check-in |
| 14:28:52.17 | `session_checkin.kind_am` | Kind speichert: angespannt, KA 22.10., KA-Thema „anders“ (`null`), `thema_antwort` neu, Stichwort „Prozente“; Vorschlag Schulthema | Check-in |
| 14:28:52.216 | `session_ereignisse` | `phase_wechsel` warmup (`checkin_kind_speichern`, Tablet) | Check-in |
| 14:28:52.578 | `session_ereignisse` | `phase_wechsel` **kern** (`session_naechster_schritt`, Tablet), 0,4 s nach dem Speichern | Check-in |
| 14:28:52–14:29:11 | – | Tablet wartet, **kein Eintrag** in `session_schritte` (siehe 3) | Check-in |
| 14:29:11 | `session_schritte` #24 | `warten` / kern / `pool_leer`: „Keine passende Aufgabe im Pool für Prozentwert berechnen“ | Check-in |
| 14:29:56 | `session_checkin.coach_am` | Coach: Fall Schulthema, Ziel `zinsrechnung` (letzte Wahl) | Check-in |
| 14:31:54 | Uhr | Kopf der Coach-Sicht springt auf Warm-up | Warm-up |
| 14:32:38 | `beendet_am` | Session beendet, Tablet gelöst | Warm-up |

Keine Aufgabe ausgegeben (`session_ausgegeben` 0), keine Antwort (`session_antworten` 0).

### Session `c9465abe…`

| Zeit | Quelle | Was |
|---|---|---|
| 14:32:58 | Ereignis | `phase_wechsel` checkin (Tablet zugewiesen) |
| 14:33:43 | `coach_am` | Coach wählt Fall Schulthema, Ziel `lineare_funktionen`, **bevor** das Kind speichert |
| 14:33:56 | `kind_am`, Ereignis | Kind speichert (KA 27.10., Thema Lineare Funktionen, `noch_dran`); `phase_wechsel` warmup |
| 14:33:56–14:37:31 | Tablet (App) | Ziel-Bildschirm: Der Fall stand schon, also zeigt die App das Ziel der Stunde mit „Zum Warm-up“ und wartet auf das Kind (`SessionAblauf.tsx`, Takt nur bei `art = warten`). Kein Aufruf der Engine. |
| 14:37:31 | Schritt #25, Ereignis | Kind tippt weiter: `phase_wechsel` kern, `warten` / kern / `pool_leer` (Steigung) |
| 12.10. 09:37:43 | Schritt #26, Ereignis | `fertig` / checkout. Das Tablet fragte am 12.10. erneut, die Uhr steht längst auf Check-out. |

### Warum der Pool leer war und das Warm-up entfiel

- Kein Testlauf, also nur freigegebene Aufgaben (`lsa_im_pool(t, false)`: `status = 'ready'`).
- dbread 12.10.: `prozent_prozentwert` hat 9 Aufgaben (0 ready), `fkt_linear_steigung` 6 (0 ready). In ganz Prod liegen
  13 Aufgaben im echten Pool, 872 im Testlauf-Pool.
- Warm-up: TESTLEAD Zweitmann hat 6 sichere Skills, aber keine freigegebene Aufgabe dazu → `session_plan_warmup` gibt
  `ohne_warmup` zurück, die Kernarbeit beginnt sofort (gewollt). Drittmann hat keine sicheren Skills.
- Das Ausweichen auf den nächsten offenen Ziel-Skill (Consensus-Check Befund 3) findet ebenfalls nichts.

### Schlussfolgerung

- **Nicht die Engine.** In beiden Sessions mit Check-in ging das Tablet sofort nach dem Check-in weiter, bei `d3e7510f`
  0,4 s nach dem Speichern, bei `c9465abe` mit dem Tippen auf „Zum Warm-up“. In keiner Session hat die Engine auf die Uhr
  gewartet. Die Uhr zeigte dabei noch Check-in.
- **Fehlender Testlauf:** Darum war der Pool leer. Das Kind wartete (`pool_leer`) und das Warm-up entfiel.
- **Coach-Ansicht:** Der Kopf folgte der Uhr. Er zeigte 5 Minuten lang Check-in und danach Warm-up, während das Kind schon
  in der Kernarbeit wartete. Das ist das „5 Minuten Check-in, 10 Minuten Warm-up“ aus dem Trockenlauf.
- **Fall:** Zum Zeitpunkt des Check-ins von `d3e7510f` noch nicht gewählt (Thema „neu“), daher zuerst kein Ziel. Für das
  Warten danach nicht ursächlich, denn auch mit Ziel war der Pool leer.

## 2 Beweis in der Wegwerf-DB

Eigener Cluster (Port 55450, `~/wegwerf-db-f2`), alle Migrationen plus `seed.sql` wie in der CI, pgTAP 1.3.4.
`session_f2_phasen.test.sql` (23 Zusicherungen, grün, ohne Migration):

- Check-in gespeichert → sofort Warm-up-Aufgabe, Uhr Check-in.
- Nach `warmup_aufgaben` (3) Warm-up-Aufgaben → Kernarbeit mit Stoff, Uhr Check-in bzw. Warm-up (Minute 6).
- Ohne Stoff (keine sicheren Skills) → sofort Kernarbeit, `warmup_entfallen = kein_stoff`, Uhr Check-in.
- Nachgestellt 10.10.: Testkonto, kein Testlauf, nur Entwürfe → sofort `warten`/kern/`pool_leer`. Dasselbe im Testlauf →
  Kernarbeit mit Aufgabe.
- `coach_raum_live` meldet je Kind die Phase des Kindes, unabhängig von der Uhr.

Alle `session_*.test.sql` grün (18 Dateien, 1 046 Zusicherungen).

## 3 Was offen bleibt

1. **Erstes Warten ohne Skill wird nicht protokolliert (Engine, nicht gebaut).** `session_naechster_schritt` überspringt
   den Eintrag bei wiederholtem Warten mit
   `not (v ->> 'art' in ('warten','erklaerung') and v_letzt.art = v ->> 'art' and … and v_letzt.skill_key is not distinct from v ->> 'skill_key')`.
   Ohne vorigen Schritt ist `v_letzt` leer. Der Vergleich `v_letzt.art = 'warten'` ergibt `null`. Bei `skill_key = null`
   (`kein_ziel`) bleibt der ganze Ausdruck `null`, und `if null` schreibt nichts. Beleg: Prod `d3e7510f` (Phasenwechsel kern
   um 14:28:52.578 ohne Schritt) und die Nachstellung in der Wegwerf-DB (kein_ziel als erster Schritt: 0 Zeilen in
   `session_schritte`, Phasenwechsel bis kern). Folge: Der Coach sieht für dieses Warten keinen Grund, und die Zeitleiste
   der Analyse hat eine Lücke. **Vorschlag** (nicht gebaut, Funktion gesperrt wegen SL1/T2/T3):
   `if v_letzt.id is null or not (…)`. **Wer:** T4 (Rasit 12.10.), hier nicht gebaut. **Erledigt mit T4** (`20261013162641`).
2. **Session `c9465abe…` abgeschlossen (erledigt 12.10.).** Einmalige Ausnahme von „kein Schreiben in Prod“ (Rasit 12.10.).
   Vorher per dbread: Status `active`, `testlauf = false`, ein gebuchtes Kind (Testkonto TESTLEAD Drittmann, `present`),
   Tablet 1 ohne `geloest_am`, einziges offenes Tablet und einzige aktive Session in Prod. Aufgerufen wurde genau die
   Funktion der Live-Sicht (`sessionAbschliessen` → `session_abschliessen`), einmal, mit Admin-Claims wie in
   trockenlauf.md Schritt 6, in einer Transaktion, kein direktes UPDATE. Ergebnis
   `{"kinder": 1, "anwesend": 1, "nicht_in_akte": [], "einheit_verbraucht": 1}`. Nachher per dbread: Status `done`,
   `beendet_am` 12.10. 11:30:15, Tablet 1 `geloest_am` gesetzt, 0 offene Tablets, 0 aktive Sessions. Sonst nur, was die
   Funktion immer schreibt: eine Zeile `session_kind_abschluss` (ohne Notiz, ohne Flags, Zusammenfassung 0 Aufgaben).
   Kein XP (keine gelöste Aufgabe), keine Notiz, Schritte 2, Ereignisse 4, Antworten 0 unverändert.
3. **Check-out im Kopf (entschieden 12.10.).** Zeigt die Uhr Check-out (`phase_checkout_min` vor Schluss), zeigt auch der
   Kopf Check-out, egal wo die Kinder sind. Er ist die einzige Phase an der Uhr, und der Coach muss dann abschließen
   (`zeitpunktAus`; Fixture `raum_checkout`: Minute 56, Kind in kern → Kopf Check-out).
4. **Phasenreiter.** Die gefüllte Phase und die goldene Marke der Zeitleiste zeigen weiter die Uhr. Der Rahmen
   (`aria-pressed`) zeigt die Ansicht, also jetzt die Phase der Kinder. Beides kann auseinanderfallen. So gewollt (Uhr als
   Restzeit), beim nächsten Trockenlauf ansehen.
5. **Testkonto nicht im Payload.** `coach_raum_live` liefert `ist_test` je Kind nicht. Der Hinweis „kein Testlauf“ liest es
   über die vorhandene Lib-Funktion `getStudentIstTest` (students, RLS `students_coach_select` bei aktiver Akte), einmal je
   Kind und nur, wenn der Hinweis in Frage kommt. Ohne aktive Akte gilt das Kind als kein Testkonto, dann erscheint kein
   Hinweis. Schöner wäre `ist_test` in `session_kind_live`. **Wer:** Foundation, wenn coach_raum_live wieder offen ist.
6. **Kinder ohne Tablet halten den Check-in-Bereich offen.** Solange ein gebuchtes Kind kein Tablet hat und nicht als
   „nicht erschienen“ bestätigt ist, steht über dem Raster der Abschnitt „Ankommen“. Das ist gewollt (der Coach muss noch
   zuweisen). Bestätigen kann man „nicht erschienen“ bisher nur im Abschluss.
7. **Zwischen Fall-Wahl und Wartegrund.** Bei `d3e7510f` liegt der erste protokollierte Schritt mit Ziel (14:29:11) vor dem
   gespeicherten `coach_am` (14:29:56). `session_checkin` hält nur die letzte Coach-Wahl. Wahrscheinlich hat der Coach zweimal
   gewählt. Ein Protokoll der Coach-Wahl gibt es nicht. Nur zur Einordnung, ohne Folgen.
