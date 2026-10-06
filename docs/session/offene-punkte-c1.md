# Offene Punkte C1 (Coach-Live-Sicht mit Beispieldaten)

Stand 06.10.2026, Branch `feat/rasit-session-c1-coach-live`. Jeder Punkt: was, warum, wer löst ihn.

## Offen

1. **Tokens fehlen.** Der Dummy nutzt `--navy-line` (#D3DCEA), `--line` (#DCDCD8), `--hover` (#FAFAF8),
   `--warn-line` (#F0D29A) und eine grüne Randfarbe (#BFE0CB). In `src/styles/tokens.css` gibt es sie nicht.
   C1 erfindet keine: Ersatz sind Deckkraft-Stufen vorhandener Tokens (`border-primary/25`,
   `border-[var(--color-gold-warning)]/40`, `bg-[var(--color-bg-subtle)]/50`, `border-[var(--color-success)]/30`)
   und `--color-neutral-unknown` (#D4D4D0) für `--line`. Wer: Foundation-Fenster, falls die Töne exakt sein sollen.
2. **Mehr als drei Schriftgrößen pro Ansicht.** CLAUDE.md §11 erlaubt drei; der Dummy (maßgeblich laut Auftrag)
   nutzt `text-xs`, `text-sm`, `text-base`, dazu Uhr (`text-2xl`) und Fraunces-Titel (`text-xl`). Übernommen wie im
   Dummy. Wer: Rasit entscheidet, ob die Regel für Fokus-Seiten gilt.
3. **Satz im Check-out ist editierbar.** Entscheidung 12: Vorschlag aus festem Bausteinkatalog. Den Katalog gibt es
   noch nicht (offene-punkte-r1 Nr. 12); C1 zeigt zwei Beispielsätze je Kind, der Coach kann sie anpassen und
   bestätigt mit „Als gesagt markieren“. Wer: C2 (Bausteinkatalog, `satzVorschlaege`).
4. **„Nicht erschienen“ bleibt im Client.** R1 setzt beim Abschluss jedes Kind ohne Tablet auf „nicht erschienen“
   (offene-punkte-r1 Nr. 6). C1 listet die Kinder ohne Tablet in „Danach“ und sperrt „Session abschließen“, bis
   der Coach jedes bestätigt hat. Eine Server-Funktion dafür gibt es nicht; sie ist auch nicht nötig, solange die
   Seite die einzige ist, die `session_abschliessen` ruft. Wer: C2 prüft das.
5. **„Ist da“ vor dem Tablet** ist nur ein Zustand auf dem Coach-Gerät. R1 kennt die Ankunft nur über
   `tablet_zuweisen`. Deshalb ist Lea im Check-in nicht schon „ist da“ wie im Dummy. Wer: bleibt so, außer Rasit
   will einen Server-Zustand.
6. **Kein „Rückgängig“ bei Mastery.** Der Dummy hat ihn; `mastery_entscheiden` (A1) ist anhängend und hat kein
   Zurücknehmen. C1 lässt den Knopf weg. „Ändern“ bei der Pfad-Entscheidung bleibt, weil `pfad_entscheiden` erneut
   gerufen werden kann. Wer: A1/C2, falls ein Zurücknehmen gewünscht ist.
7. **„Gemeistert bestätigen“ erst nach zwei Haken.** Entscheidung 16 verlangt vier Schritte; der Dummy sperrt den
   Knopf nicht. C1 sperrt ihn, bis „Prüffrage gestellt“ und „hat den Weg selbst erklärt“ angehakt sind (mit
   sichtbarem Grund). Vertagen geht ohne Haken, aber nur mit Grund.
8. **Briefing („Vorher“) und „Heute im Blick“** haben keine Server-Funktion (offene-punkte-r1 Nr. 19). Die
   Beispieldaten zeigen, was gebraucht wird; „Im Blick“ und die Detailzeilen sind dort Fließtext.
   Wer: C2 bzw. ein Folgepaket (eine Briefing-Funktion je Session).
9. **Signale je Kind und `coach_kind_detail`.** `ladeRaumLive` liefert heute alles in einem Aufruf. Mit echten
   Daten wären das `coach_raum_live` plus fünf `coach_kind_detail` alle 4 s. Vorschlag für C2: Detail nur für das
   Kind mit offener Schublade abfragen. Wer: C2.
10. **Fehler-Codes.** Die Datenquelle meldet `fehlbildPflicht`, `grundPflicht`, `ohneTabletOffen`, `tabletBelegt`,
    `abgeschlossen` (i18n `coachLive:fehler.*`). R1/A1 liefern SQLSTATE (22023, 42501, …). Wer: C2 bildet sie ab.
11. **Zurück-Knopf „Heute“** führt Coaches nach `/coach`, Admins nach `/admin`. Ein Link von der Coach-Startseite
    in die Live-Sicht fehlt noch. Wer: H6 (Coach-Hülle) bzw. C2.
12. **Gemeinsame Komponente angepasst.** `src/pages/admin/intake/ThemaSuche.tsx` hat zwei optionale Props bekommen
    (`startEingabe`, `inputId`), damit die Suche im Check-in mit dem Stichwort des Kindes öffnet. Das Erstgespräch
    verhält sich unverändert.
13. **Abfrage-Takt** `LIVE_ABFRAGE_MS = 4000` (Entscheidung 17: „alle paar Sekunden“; C0 empfiehlt 3–5 s).

## Abweichungen vom Dummy

- Fachhinweise und Stellschrauben-Schalter des Dummys sind nicht nachgebaut (Auftrag: lesen, nicht nachbauen).
- Meldungen erscheinen oben als `ToastBanner` statt unten als dunkle Leiste (CLAUDE.md §11, Erfolgsmeldung).
- Alter in der Warteschlange immer in Minuten („20 Min“) statt „seit 16:42“.
- Skill-Zeilen ohne Zusätze wie „(vom 29.09.)“, „(neu)“ oder „Pythagoras:“; Deniz übt „Grundwert berechnen“.
- Emirs Klassenarbeit zeigt Datum und Abstand („Di 27.10.: … · in 21 Tagen“) statt „in 3 Wochen, Termin offen“.
- Check-out: Zusammenfassung als „8 Aufgaben, 7 richtig · Kathete berechnen“; Quest A (vom Kind) und Quest B
  (vorbelegt) stehen getrennt. Deniz hat noch keinen Quest-A-Termin, damit das Nachtragen durch den Coach sichtbar
  ist („Quest-Termine 4 von 5“).
- Danach: neuer Abschnitt „Ohne Tablet“ (Auftrag Punkt 11). „Aufgaben bearbeitet“ ist die Summe der Kinder (32),
  der Dummy hatte fest 36.
- Schublade: zusätzlich der Grund des letzten Schritts (z. B. „Über der Ziel-Erfolgsquote (80 %) …“) unter der
  Aufgabe; bei Jonas ist das Fehlbild aus Runde 1 für Stufe 3/4 vorbelegt.

## Für C2: Herkunft je Feld

| Feld im Ansichtsmodell (`src/types/coachLive.ts`) | Quelle |
|---|---|
| `session.id`, `beginn`, `raum`, `coachName`, `abgeschlossen` | R1 `coach_raum_live.session` (`scheduled_at`, `room`, `coach_name`, `beendet_am`) |
| `session.jetzt` | Uhr des Geräts (Beispiel: feste Zeit je Zeitpunkt) |
| `session.fach`, `session.klassen` | `themen.fach` des Ziels bzw. Min/Max von `kinder[].klasse` |
| `session.plaetze` | fest 5 (Entscheidung 1) |
| `einstellungen` | R1 `coaching_sessions.einstellungen` (Snapshot aus `session_starten`) |
| `zeitleiste` | `zeitleisteAusSnapshot(einstellungen)` |
| `zeitpunkt` | R1 `coach_raum_live.kinder[].phase` bzw. `session.status`/`gestartet_am`/`beendet_am` |
| `kinder[].name`, `klasse`, `tablet`, `tabletSeit`, `phase` | R1 `coach_raum_live.kinder` |
| `kinder[].nichtErschienen` | Client (Punkt 4) |
| `kinder[].status`, `signale`, `signale` (Raum) | R1 `coach_raum_live.kinder[].status/signale`, `raum_signale` |
| `kinder[].taetigkeit`, `aufgabeNr` | R1 `phase`, `aufgabe.nr_in_phase`; Erklärung aus E1 `erklaer_fortschritt` |
| `kinder[].skill` | R1 `aufgabe.skill_key` → Label aus `skill_thema` |
| `kinder[].ergebnisfolge`, `meta` | R1 `ergebnisfolge`, `hinweise_genutzt` |
| `kinder[].ziel.fallVorschlag/fallCoach/themaKey/themaLabel` | R1 `coach_raum_live.kinder` (`fall_vorschlag`, `fall_coach`, `ziel_thema_key`, `ziel_thema_label`) |
| `kinder[].ziel.klassenarbeit` | R1 `session_checkin` (`klassenarbeit_datum`, `klassenarbeit_thema_key`) |
| `kinder[].ziel.lsaLuecke` | A1 `naechste_luecke` |
| `kinder[].zielFertigkeiten` | A1 `ziel_fertigkeiten` (mit `pruefung_faellig`); Notizen aus `ergebnisfolge` |
| `kinder[].aufgabe` | R1 `coach_kind_detail.aufgabe_detail` (Musterlösung nur hier) |
| `kinder[].versuche`, `hinweise` | R1 `coach_kind_detail.versuche` (`fehlbild_klartext`), `.hinweise` |
| `kinder[].eingreifen.eingriffe` | R1 `coach_kind_detail.eingriffe` |
| `kinder[].eingreifen.empfohlen`, `fehlbild` | aus Signalart (haengt/ohne Eingabe) und letztem Versuch mit `fehlbild_slug` |
| `kinder[].erklaersequenz`, `sequenzBalken` | E1 `erklaer_fortschritt` |
| `kinder[].masteryKandidat` | A1 `mastery_vorschlaege` + `skill_pruefung_lesen`; Entscheidung aus `mastery_entscheiden` |
| `kinder[].pfadVorschlag`, `pfadEntscheidung` | R1 Signal `entscheidung` + `coach_kind_detail.entscheidungen`; A1 `pfad_tiefer` |
| `kinder[].info` | R1 Signal `hinweis` (Stimmung), `tablet_seit`, `session_checkin.klassenarbeit_datum` |
| `kinder[].heute`, `grundLetzterSchritt` | R1 `ergebnisfolge` (`phase`, `eingemischt`); Grund aus A1-Auswahl (fehlt noch) |
| `kinder[].checkin` | R1 `session_checkin` |
| `kinder[].checkout.satz/gesagt/notiz/flags` | R1 `session_kind_abschluss` |
| `kinder[].checkout.satzVorschlaege` | Bausteinkatalog (fehlt, Punkt 3) |
| `kinder[].checkout.exit`, `aufgaben`, `richtig`, `eingriffe` | R1 `exit_ergebnis`, `session_antworten`, Ereignisse `eingriff` |
| `kinder[].checkout.questA/questB` | Q1 Quest-Termine (`quest_termin`) |
| `kinder[].briefing`, `imBlick` | keine Funktion (Punkt 8): `lead_themen`, `schueler_notizen`, letzter Check-in, A1, Q1 |
| `masteryEntschieden` | R1 `coach_raum_live.session.mastery_bestaetigt` (heute Platzhalter) |
| `erklaersequenzenFertig` | E1 `erklaer_fortschritt` |
| Themenkatalog (`themenKatalog`) | `listThemen` aus `src/lib/supabase/themen.ts` |
