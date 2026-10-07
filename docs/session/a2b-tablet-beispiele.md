# A2b: Tablet-Beispiele (echtes JSON)

Ein Kind („Emir“) in einer Session, Aufruf für Aufruf so, wie das Tablet sie macht. Jedes JSON ist die echte
Antwort der Datenbank. Erzeugt mit `docs/session/a2b-tablet-beispiele.sql` in einer Wegwerf-DB aus allen
Migrationen plus `supabase/seed.sql` (07.10.2026). IDs und Zeiten ändern sich bei jedem Lauf. Skill- und
Aufgabentexte sind Testdaten (`ZZ …`). Der Vertrag dazu steht in `docs/api/DATENVERTRAG.md`, Abschnitt
„Session am Tablet“.

Ablauf:
- Session ohne Testlauf, Home Quests eingeschaltet, eine nächste Session ist gebucht.
- Das Warm-up läuft auf „ZZ Minus vor der Klammer“.
- Der Coach wählt den Fall Schulthema.
- In der Kernarbeit legt er die Prüffrage zu „ZZ Proportionale Zuordnung“ aufs Tablet und bucht danach „gemeistert“.
- Check-out: zwei Exit-Aufgaben, Termin, fertig.

Zwischen den Aufrufen stellt das Skript die Uhr der Session (Check-in, Kernarbeit ab Minute 20, Check-out ab
Minute 56). Der Coach handelt über seine eigenen Funktionen; sie stehen hier nicht, nur ihre Wirkung im
nächsten Tablet-Aufruf.

## 1. tablet_stand() — Tablet ohne Zuweisung

```json
{
    "zugewiesen": false
}
```

## 2. tablet_stand() — zugewiesen, Check-in offen

```json
{
    "phase": "checkin",
    "aufgabe": null,
    "vorname": "Emir",
    "pruefung": null,
    "tablet_nr": 1,
    "bestaetigt": [
    ],
    "session_id": "a6a63a09-54f8-4ab1-bf55-422a393f2549",
    "zugewiesen": true,
    "checkin_fertig": false
}
```

## 3. session_kind_kontext(session_id)

```json
{
    "vorname": "Emir",
    "schulthema": {
        "label": "ZZ Terme",
        "thema_key": "zz_a2_terme"
    },
    "coach_vorname": "A2",
    "quest_termine": {
        "quest_a": [
            "2026-10-09",
            "2026-10-10"
        ],
        "quest_b": "2026-10-13"
    }
}
```

## 4. session_naechster_schritt(session_id, null) — vor dem Check-in

```json
{
    "art": "warten",
    "modus": null,
    "phase": "checkin",
    "aufgabe": null,
    "task_id": null,
    "skill_key": null,
    "grund_code": "checkin_laeuft",
    "eingemischt": false,
    "skill_label": null,
    "hinweise_erlaubt": false
}
```

## 5. checkin_kind_speichern(session_id, 'gut', null, null, 'noch_dran')

```json
{
    "fertig": true
}
```

## 6. session_naechster_schritt — Warm-up-Aufgabe

```json
{
    "art": "aufgabe",
    "modus": "gefuehrt",
    "phase": "warmup",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_v1 Nr 1: Wie viel ist 3 + 4?",
        "task_id": "1fd45bdc-ff60-4a54-a636-1795beab6de0"
    },
    "task_id": "1fd45bdc-ff60-4a54-a636-1795beab6de0",
    "skill_key": "zz_a2_v1",
    "grund_code": "warmup_voraussetzung",
    "eingemischt": false,
    "skill_label": "ZZ Minus vor der Klammer",
    "hinweise_erlaubt": false
}
```

## 7. antwort_abgeben(session_id, task_id, null, '"7"') — richtig

```json
{
    "ergebnis": "richtig",
    "versuch_nr": 1,
    "gespeichert": true,
    "fehlbild_klartext": null
}
```

## 8. session_naechster_schritt — nächste Warm-up-Aufgabe

```json
{
    "art": "aufgabe",
    "modus": "selbststaendig",
    "phase": "warmup",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_v1 Nr 11: Wie viel ist 3 + 4?",
        "task_id": "5b61fa53-1d60-4e28-be3f-4db380f81763"
    },
    "task_id": "5b61fa53-1d60-4e28-be3f-4db380f81763",
    "skill_key": "zz_a2_v1",
    "grund_code": "warmup_voraussetzung",
    "eingemischt": false,
    "skill_label": "ZZ Minus vor der Klammer",
    "hinweise_erlaubt": false
}
```

## 9. antwort_abgeben(…, '"0"') — falsch, mit Fehlbild-Klartext

```json
{
    "ergebnis": "falsch",
    "versuch_nr": 1,
    "gespeichert": true,
    "fehlbild_klartext": "Nur das erste Vorzeichen geändert"
}
```

## 10. session_ziel_kind(session_id)

```json
{
    "fall": "schulthema",
    "thema_label": "ZZ Terme",
    "fertigkeiten": [
        {
            "neu": false,
            "label": "ZZ Klammern ausmultiplizieren",
            "aktuell": true
        },
        {
            "neu": true,
            "label": "ZZ Ausklammern",
            "aktuell": false
        }
    ],
    "klassenarbeit_datum": null
}
```

## 11. session_naechster_schritt — Aufgabe in der Kernarbeit

```json
{
    "art": "aufgabe",
    "modus": "gefuehrt",
    "phase": "kern",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_s1 Nr 7: Wie viel ist 3 + 4?",
        "task_id": "0b70fcbd-2d23-4bf0-8867-2eaa162b0717"
    },
    "task_id": "0b70fcbd-2d23-4bf0-8867-2eaa162b0717",
    "skill_key": "zz_a2_s1",
    "grund_code": "kern",
    "eingemischt": false,
    "skill_label": "ZZ Klammern ausmultiplizieren",
    "hinweise_erlaubt": true
}
```

## 12. hinweis_abrufen(session_id, task_id, 1)

```json
{
    "text": "ZZ Hinweis: Zaehle weiter.",
    "stufe": 1,
    "verfuegbar": true
}
```

## 13. antwort_abgeben — richtig nach Hinweis

```json
{
    "ergebnis": "richtig",
    "versuch_nr": 1,
    "gespeichert": true,
    "fehlbild_klartext": null
}
```

## 14. tablet_stand() — Prüffrage liegt auf dem Tablet

```json
{
    "phase": "kern",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_s1 Nr 7: Wie viel ist 3 + 4?",
        "task_id": "0b70fcbd-2d23-4bf0-8867-2eaa162b0717"
    },
    "vorname": "Emir",
    "pruefung": {
        "frage": "3 Hefte kosten 4,50 €. Erklär mir, wie du den Preis für 7 Hefte findest.",
        "skill_label": "ZZ Proportionale Zuordnung"
    },
    "tablet_nr": 1,
    "bestaetigt": [
    ],
    "session_id": "a6a63a09-54f8-4ab1-bf55-422a393f2549",
    "zugewiesen": true,
    "checkin_fertig": true
}
```

## 15. tablet_stand() — nach „gemeistert“ durch den Coach

```json
{
    "phase": "kern",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_s1 Nr 7: Wie viel ist 3 + 4?",
        "task_id": "0b70fcbd-2d23-4bf0-8867-2eaa162b0717"
    },
    "vorname": "Emir",
    "pruefung": null,
    "tablet_nr": 1,
    "bestaetigt": [
        {
            "am": "2026-10-07T10:10:04.315961+02:00",
            "skill_key": "zz_a2_v2",
            "skill_label": "ZZ Proportionale Zuordnung"
        }
    ],
    "session_id": "a6a63a09-54f8-4ab1-bf55-422a393f2549",
    "zugewiesen": true,
    "checkin_fertig": true
}
```

## 16. session_naechster_schritt — Exit-Aufgabe

```json
{
    "art": "exit",
    "modus": "selbststaendig",
    "phase": "checkout",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_s1 Nr 22: Wie viel ist 3 + 4?",
        "task_id": "365335dd-a215-43b1-b8c7-f1fd79117c50"
    },
    "task_id": "365335dd-a215-43b1-b8c7-f1fd79117c50",
    "skill_key": "zz_a2_s1",
    "grund_code": "exit",
    "eingemischt": false,
    "skill_label": "ZZ Klammern ausmultiplizieren",
    "hinweise_erlaubt": false
}
```

## 17. antwort_abgeben — Exit (neutral)

```json
{
    "versuch_nr": 1,
    "gespeichert": true
}
```

## 18. session_naechster_schritt — zweite Exit-Aufgabe

```json
{
    "art": "exit",
    "modus": "selbststaendig",
    "phase": "checkout",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 zz_a2_s1 Nr 12: Wie viel ist 3 + 4?",
        "task_id": "4b7b6cda-8985-46fa-a2e8-5b3c2d3abbec"
    },
    "task_id": "4b7b6cda-8985-46fa-a2e8-5b3c2d3abbec",
    "skill_key": "zz_a2_s1",
    "grund_code": "exit",
    "eingemischt": false,
    "skill_label": "ZZ Klammern ausmultiplizieren",
    "hinweise_erlaubt": false
}
```

## 19. session_naechster_schritt — Termin wählen (Home Quests an)

```json
{
    "art": "termin",
    "modus": null,
    "phase": "checkout",
    "aufgabe": null,
    "task_id": null,
    "skill_key": null,
    "grund_code": "termin",
    "eingemischt": false,
    "skill_label": null,
    "hinweise_erlaubt": false
}
```

## 20. quest_termin_setzen(session_id, null, termin) — R1-Fassung, Quest A (liefert void)

```json
null
```

## 21. session_naechster_schritt — fertig

```json
{
    "art": "fertig",
    "modus": null,
    "phase": "checkout",
    "aufgabe": null,
    "task_id": null,
    "skill_key": null,
    "grund_code": "fertig",
    "eingemischt": false,
    "skill_label": null,
    "hinweise_erlaubt": false
}
```

## 22. session_abschluss_kind(session_id)

```json
{
    "xp": 50,
    "geuebt": [
        "ZZ Klammern ausmultiplizieren"
    ],
    "naechste_session": "2026-10-14T16:30:00+02:00"
}
```

## 23. Fehler: session_ziel_kind von einem Tablet ohne Platz in dieser Session

```json
{
    "message": "session_ziel_kind: kein zugewiesener Platz an diesem Tablet",
    "sqlstate": "42501"
}
```
