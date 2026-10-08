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

Seit A2c (Nachtrag R2) mit der Nummer des eigenen Geräts für den Warte-Bildschirm. Ein Gerät ohne Nummer bekommt
`"tablet_nr": null`. Schülerkonto, Coach und Konto ohne Profil bekommen nur `{"zugewiesen": false}`
(`session_a2c.test.sql`, Block T).

```json
{
    "tablet_nr": 1,
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
    "weitere": true,
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

## Erklärsequenz im Testlauf (A2c)

Ein zweites Kind („Jonas“, Testkonto) in einer Testlauf-Session, Aufruf für Aufruf vom Tablet, immer mit
`p_student_id = null`. Erzeugt mit `docs/session/a2c-tablet-erklaer.sql` (gleiche Wegwerf-DB, 07.10.2026). Die
Inhalte der Erklärsequenz kommen aus der Fixture von `session_e1` („Steigung aus dem Graphen“: drei Kernideen, je
Variante A und B, Formeln als SVG-URL, ein Bild). Die Aufgaben zur Steigung sind ZZ-Testdaten.

Ablauf:
- Schulthema „Lineare Funktionen“; die Voraussetzungen sind sicher, die Steigung ist neu. Der Coach wählt Schulthema, die Uhr steht in der Kernarbeit.
- `session_naechster_schritt` schaltet die Erklärsequenz vor; die App ruft `erklaer_start`.
- Check 1 falsch (`variante`, Variante B), dann richtig (`weiter`, Kernidee 2); Kernidee 2 und 3 richtig, danach `uebergang = ueben`.
- Übergang ins Üben: Lösungsbeispiel, dann die erste Aufgabe mit Hinweis (`weitere`, A2c).
- `erklaer_nachlesen` ohne Kind; zum Schluss ein Tablet ohne Platz.

## 24. session_naechster_schritt(session_id, null) — Erklärsequenz vorgeschaltet

```json
{
    "art": "erklaerung",
    "modus": "gefuehrt",
    "phase": "kern",
    "aufgabe": null,
    "task_id": null,
    "skill_key": "fkt_linear_steigung",
    "grund_code": "neu_erklaerung",
    "eingemischt": false,
    "skill_label": "Steigung einer linearen Funktion",
    "erklaerung_weg": "sequenz",
    "hinweise_erlaubt": false
}
```

## 25. erklaer_start(session_id, null, 'fkt_linear_steigung')

```json
{
    "check": {
        "aufgabe": {
            "kind": "short_input",
            "assets": [
            ],
            "prompt": "Die Gerade geht durch (0|0) und (1|2). Um wie viel steigt sie pro Schritt nach rechts?",
            "task_id": "aed4fa60-f3fc-4bdd-99e3-c8fe09973330"
        },
        "task_id": "aed4fa60-f3fc-4bdd-99e3-c8fe09973330"
    },
    "runde": 1,
    "aktion": "start",
    "kernidee": {
        "nr": 1,
        "von": 3,
        "titel": "Steigung: wie viel es pro Schritt nach rechts hoch- oder runtergeht"
    },
    "schritte": [
        {
            "art": "erklaerung",
            "bild": {
                "alt": "Steigungsdreieck an einer Geraden",
                "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                "content_type": "image/svg+xml"
            },
            "inhalt": "Kernidee 1, Variante A, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/c4d30e056e72b3d62cc0cfa351e07875c3bc243a2517bf049d7dcb261e86c79b.svg"
            ]
        },
        {
            "art": "beispiel",
            "inhalt": "Kernidee 1, Variante A, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/f47a90bd7afee52869a870ad8400c663c1dc7f19ee9fcf30f7a256310545557c.svg"
            ]
        }
    ],
    "variante": "A"
}
```

## 26. session_naechster_schritt — Sequenz läuft (App lädt neu)

```json
{
    "art": "erklaerung",
    "modus": "gefuehrt",
    "phase": "kern",
    "aufgabe": null,
    "task_id": null,
    "skill_key": "fkt_linear_steigung",
    "grund_code": "erklaerung_laeuft",
    "eingemischt": false,
    "skill_label": "Steigung einer linearen Funktion",
    "hinweise_erlaubt": false
}
```

## 27. erklaer_check_abgeben(session_id, null, check_task_id, '{"text":"7"}') — falsch

```json
{
    "check": {
        "aufgabe": {
            "kind": "short_input",
            "assets": [
            ],
            "prompt": "Die Gerade geht durch (0|0) und (1|2). Um wie viel steigt sie pro Schritt nach rechts?",
            "task_id": "aed4fa60-f3fc-4bdd-99e3-c8fe09973330"
        },
        "task_id": "aed4fa60-f3fc-4bdd-99e3-c8fe09973330"
    },
    "runde": 2,
    "aktion": "variante",
    "kernidee": {
        "nr": 1,
        "von": 3,
        "titel": "Steigung: wie viel es pro Schritt nach rechts hoch- oder runtergeht"
    },
    "schritte": [
        {
            "art": "erklaerung",
            "bild": {
                "alt": "Steigungsdreieck an einer Geraden",
                "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                "content_type": "image/svg+xml"
            },
            "inhalt": "Kernidee 1, Variante B, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/ae14e699bacee2fa2256dbc3d3866f8a2bf9388f4a148359d4a26ee162be65b9.svg"
            ]
        },
        {
            "art": "beispiel",
            "inhalt": "Kernidee 1, Variante B, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/f3adff34b9f7115a707e6cdac4bdca51317f242523e4ab69050171fac6609d4b.svg"
            ]
        }
    ],
    "variante": "B"
}
```

## 28. erklaer_check_abgeben(…, '{"text":"2"}') — richtig, nächste Kernidee

```json
{
    "check": {
        "aufgabe": {
            "kind": "short_input",
            "assets": [
            ],
            "prompt": "Die Gerade geht durch (0|1) und (4|3). Bestimme die Steigung mit dem Steigungsdreieck.",
            "task_id": "ca71a9f6-ae39-45a3-a218-b249a4b87d2e"
        },
        "task_id": "ca71a9f6-ae39-45a3-a218-b249a4b87d2e"
    },
    "runde": 1,
    "aktion": "weiter",
    "kernidee": {
        "nr": 2,
        "von": 3,
        "titel": "Steigungsdreieck: Δy durch Δx"
    },
    "schritte": [
        {
            "art": "erklaerung",
            "bild": {
                "alt": "Steigungsdreieck an einer Geraden",
                "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                "content_type": "image/svg+xml"
            },
            "inhalt": "Kernidee 2, Variante A, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/a7388b00c7b109d15f9d6795b7717e7b6507d75c0d980714bc1390c0366b6510.svg"
            ]
        },
        {
            "art": "beispiel",
            "inhalt": "Kernidee 2, Variante A, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/ade5dd5c4e61163f1aea7e3122284e81861fff1eed88d5c63fc360802add78bc.svg"
            ]
        }
    ],
    "variante": "A"
}
```

## 29. erklaer_check_abgeben(…, '{"text":"0,5"}') — richtig, nächste Kernidee

```json
{
    "check": {
        "aufgabe": {
            "kind": "short_input",
            "assets": [
            ],
            "prompt": "Die Gerade geht durch (0|4) und (2|0). Bestimme die Steigung.",
            "task_id": "eec5de50-acad-4f62-9d7a-fc6e3769d9c8"
        },
        "task_id": "eec5de50-acad-4f62-9d7a-fc6e3769d9c8"
    },
    "runde": 1,
    "aktion": "weiter",
    "kernidee": {
        "nr": 3,
        "von": 3,
        "titel": "Negative Steigung: Der Graph fällt"
    },
    "schritte": [
        {
            "art": "erklaerung",
            "bild": {
                "alt": "Steigungsdreieck an einer Geraden",
                "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                "content_type": "image/svg+xml"
            },
            "inhalt": "Kernidee 3, Variante A, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/6dc910a2f4c4a11cd583181780acdf71938a52aef5478bd5c8c685b489e11da7.svg"
            ]
        },
        {
            "art": "beispiel",
            "inhalt": "Kernidee 3, Variante A, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
            "formeln": [
                "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/8a1a6d5a07b3af24fa69240f5adc7858982df31629dceeb51c42dc137a89bd67.svg"
            ]
        }
    ],
    "variante": "A"
}
```

## 30. erklaer_check_abgeben(…, '{"text":"-2"}') — richtig, Sequenz durch

```json
{
    "aktion": "weiter",
    "uebergang": "ueben"
}
```

## 31. session_naechster_schritt — Übergang ins Üben

```json
{
    "art": "beispiel",
    "modus": "gefuehrt",
    "phase": "kern",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 fkt_linear_steigung Nr 7: Wie viel ist 3 + 4?",
        "task_id": "7b508e78-dbd3-483a-af16-f923b8a2f0e5"
    },
    "task_id": "7b508e78-dbd3-483a-af16-f923b8a2f0e5",
    "skill_key": "fkt_linear_steigung",
    "grund_code": "neu_beispiel",
    "eingemischt": false,
    "loesungsweg": "ZZ-LOESUNGSWEG: 3 + 4 = 7",
    "skill_label": "Steigung einer linearen Funktion",
    "hinweise_erlaubt": false
}
```

## 32. session_naechster_schritt — nach Weiter: Aufgabe zur Steigung

```json
{
    "art": "aufgabe",
    "modus": "gefuehrt",
    "phase": "kern",
    "aufgabe": {
        "kind": "short_input",
        "assets": [
        ],
        "prompt": "ZZ A2 fkt_linear_steigung Nr 12: Wie viel ist 3 + 4?",
        "task_id": "cb2d34df-404b-4b2f-bc87-9bf1f5580cab"
    },
    "task_id": "cb2d34df-404b-4b2f-bc87-9bf1f5580cab",
    "skill_key": "fkt_linear_steigung",
    "grund_code": "neu_aehnliche_aufgabe",
    "eingemischt": false,
    "skill_label": "Steigung einer linearen Funktion",
    "hinweise_erlaubt": true
}
```

## 33. hinweis_abrufen(session_id, task_id, 1) — mit weitere (A2c)

```json
{
    "text": "ZZ Hinweis: Zaehle weiter.",
    "stufe": 1,
    "weitere": true,
    "verfuegbar": true
}
```

## 34. erklaer_nachlesen(null, 'fkt_linear_steigung')

```json
{
    "kernideen": [
        {
            "nr": 1,
            "titel": "Steigung: wie viel es pro Schritt nach rechts hoch- oder runtergeht",
            "schritte": [
                {
                    "art": "erklaerung",
                    "bild": {
                        "alt": "Steigungsdreieck an einer Geraden",
                        "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                        "content_type": "image/svg+xml"
                    },
                    "inhalt": "Kernidee 1, Variante A, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
                    "formeln": [
                        "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/c4d30e056e72b3d62cc0cfa351e07875c3bc243a2517bf049d7dcb261e86c79b.svg"
                    ]
                },
                {
                    "art": "beispiel",
                    "inhalt": "Kernidee 1, Variante A, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
                    "formeln": [
                        "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/f47a90bd7afee52869a870ad8400c663c1dc7f19ee9fcf30f7a256310545557c.svg"
                    ]
                }
            ]
        },
        {
            "nr": 2,
            "titel": "Steigungsdreieck: Δy durch Δx",
            "schritte": [
                {
                    "art": "erklaerung",
                    "bild": {
                        "alt": "Steigungsdreieck an einer Geraden",
                        "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                        "content_type": "image/svg+xml"
                    },
                    "inhalt": "Kernidee 2, Variante A, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
                    "formeln": [
                        "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/a7388b00c7b109d15f9d6795b7717e7b6507d75c0d980714bc1390c0366b6510.svg"
                    ]
                },
                {
                    "art": "beispiel",
                    "inhalt": "Kernidee 2, Variante A, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
                    "formeln": [
                        "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/ade5dd5c4e61163f1aea7e3122284e81861fff1eed88d5c63fc360802add78bc.svg"
                    ]
                }
            ]
        },
        {
            "nr": 3,
            "titel": "Negative Steigung: Der Graph fällt",
            "schritte": [
                {
                    "art": "erklaerung",
                    "bild": {
                        "alt": "Steigungsdreieck an einer Geraden",
                        "url": "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/bilder/ab12.svg",
                        "content_type": "image/svg+xml"
                    },
                    "inhalt": "Kernidee 3, Variante A, erklaerung: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
                    "formeln": [
                        "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/6dc910a2f4c4a11cd583181780acdf71938a52aef5478bd5c8c685b489e11da7.svg"
                    ]
                },
                {
                    "art": "beispiel",
                    "inhalt": "Kernidee 3, Variante A, beispiel: Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$.",
                    "formeln": [
                        "https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/erklaer/formeln/8a1a6d5a07b3af24fa69240f5adc7858982df31629dceeb51c42dc137a89bd67.svg"
                    ]
                }
            ]
        }
    ],
    "skill_key": "fkt_linear_steigung"
}
```

## 35. Fehler: erklaer_start von einem Tablet ohne Platz in dieser Session

```json
{
    "message": "erklaer_start: kein zugewiesener Platz an diesem Tablet",
    "sqlstate": "42501"
}
```
