# FR-2 · F4.2 Zweite Aufgabentexte

**Stand:** 09.11.2026. Migration `20261109130736_fr2_zweite_texte`.

Für die sieben Skills, denen auch mit allen Entwürfen ein zweiter Textschlüssel fehlt (Bericht Q27, per dbread
bestätigt), gibt es je eine neue LSA-Aufgabe:

- anderer Aufgabentext: Sachaufgabe, Zahlenrätsel oder Gleichung mit x rechts, nicht nur andere Zahlen
- ohne MC, AFB I–II, mit Lösung
- Fehlbilder aus `fehlbild_labels` wie bei den Geschwistern
- `sondierrang` 3, weil 1 und 2 belegt sind
- Status draft, Pool `{lsa}`; Lena prüft sie in „Gezielt prüfen“, freigeben dürfen nur Admins

| Skill | Aufgabe (Kurz) | Lösung | Fehlbilder (Antwort → Slug) | AFB |
|---|---|---|---|---|
| bruch_add | Pizza: Lea 1/4, Tom 1/3 | 7/12 | 2/7 → nenner_addiert, 2/12 → zaehler_nicht_erweitert | II |
| bruch_dezimal | Glas zu 2/5 gefüllt, als Dezimalzahl | 0,4 | 2,5 → umgekehrt_geteilt, 0,25 → ziffern_gelesen | I |
| bruch_kuerzen | 18 von 24 Kindern, gekürzter Anteil | 3/4 | 9/12, 6/8 → teilgekuerzt | II |
| bruch_mult | 3/5 einer 5/6 m langen Leiste | 1/2 | 15/30, 3/6 → teilgekuerzt; 43/30 → hauptnenner_bei_mult | II |
| gleichung_beidseitig | Zahlenrätsel 5-mal + 3 = 2-mal + 15 | 4 | 6 → falsches_vorzeichen_beim_zusammenfuehren | II |
| gleichung_neg_koeffizient | 20 = 32 − 4x (x rechts) | 3 | −3 → vorzeichen_beim_umstellen, 12 → division_vergessen | I |
| term_minusklammer | 4x − (x − 6) vereinfachen | 3x + 6 | – (Geschwister ohne Fehlbilder; Term-Wertung) | I |

## Prüfung

1. **Blindlöser** (frischer Subagent nach `tools/blind-loeser/AUFTRAG.md`). Er sah nur die Aufgabentexte
   (`/tmp/claude-1000/fr2/blind/aufgaben.json`, ohne Lösungen) und hat alle sieben gelöst, keine davon als
   „unsicher“ markiert. Antworten: `neue-aufgaben-blind.json`.
2. **`tools/verify-tasks.mjs --quelle datei --pfad docs/freigabe/fr2/neue-aufgaben-charge.json --answers-from
   docs/freigabe/fr2/neue-aufgaben-blind.json --min-pass 1.0`**: Struktur 7 ok, Rechnung 7 ok, 0 Abweichungen,
   Trefferquote **100 %**.
3. **Echte Wertung in allen Schreibweisen** (Wegwerf-DB mit Prod-Inhalten, `lsa_is_correct` und `lsa_grade`):

   | Antworten | lsa_is_correct | lsa_grade |
   |---|---|---|
   | 7/12, 7 / 12; 3/4, 3 / 4; 1/2, 1 / 2 | richtig | voll |
   | 0,4 / 0.4 / 0,40 | richtig | voll |
   | 4, +4; 3, +3 | richtig | voll |
   | 3x+6, 3x + 6, 3X+6, 6+3x | richtig | voll |
   | 14/24, 9/12, 18/24, 15/30 (nicht gekürzt) | falsch | teilweise |
   | 2/7, 2,5, 6, −3, 3x−6 (Fehlbilder) | falsch | nicht |
   | 0,5 bei bruch_mult (Dezimal statt Bruch) | falsch | voll |
   | „,4“, „x=4“, „x = 3“ | falsch | nicht (das Ziffernfeld lässt sie nicht zu; Geschwister ebenso) |

   Zuerst waren „+4“, „+3“, „6+3x“ und „7 / 12“ in `lsa_grade` voll, in `lsa_is_correct` aber falsch. Sie stehen
   deshalb jetzt in `correct_answers`, „+v“ auch als `equivalents`.
4. **Pool und Board** (Wegwerf-DB): alle 7 nicht ausgeschlossen (`pruef_ausschluss` null), Eingabeformat
   eindeutig, und jede bringt einen Textschlüssel, den keine andere Aufgabe des Skills hat.
5. **Prüfliste** (Wegwerf-DB, als Lena):
   - bruch_kuerzen (Rang 4), bruch_dezimal (5) und gleichung_beidseitig (8) brauchen nur noch einen Text. Dort ist
     die neue Aufgabe der einzige Vorschlag.
   - bruch_mult (9), bruch_add (18), gleichung_neg_koeffizient (24) und term_minusklammer (25) fehlen zwei Texte.
     Dort stehen der alte Entwurf (sondierrang 1) und die neue Aufgabe zusammen.
6. **CI-Neuaufbau** (leere Basis): Das Insert trifft 0 Zeilen, ohne Fehler. Ein zweiter Lauf auf der Fixture ist
   idempotent. Der Rollback entfernt die 7 nur, solange sie unberührt sind.
