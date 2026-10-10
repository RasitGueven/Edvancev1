# Slots — Beispiele mit echtem JSON

Erzeugt mit `tools/slots-beispiele.sql` in einer Wegwerf-DB (Paket SL1). Ausgangslage wie im Dummy: Montag, 13.03.2028,
09:12 Uhr (`p_jetzt`). Alle Namen sind erfunden. Lange Listen sind gekürzt (`"… n weitere"`), sonst ist jede Ausgabe
unverändert. Die Typen stehen in `src/types/slotplan.ts`, die Regeln in `docs/api/DATENVERTRAG.md`, Abschnitt 10.

## slots_woche

`slots_woche('2028-03-13')` — Woche KW 11. Zellen gekürzt; die Zelle Do 16 Uhr steht vollständig darunter.

```json
{
  "kw": 11,
  "kopf": {
    "belegt": 17,
    "plaetze": 155,
    "ohne_raum": 1,
    "auslastung": 0.11,
    "ohne_stammplatz": 3,
    "erster_ohne_raum": {
      "datum": "2028-03-16",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01"
    },
    "ohne_stammplatz_laufend": 1
  },
  "tage": [
    {
      "datum": "2028-03-13",
      "heute": true,
      "anlass": null,
      "betrieb": true,
      "vergangen": false,
      "wochentag": 1
    },
    {
      "datum": "2028-03-14",
      "heute": false,
      "anlass": null,
      "betrieb": true,
      "vergangen": false,
      "wochentag": 2
    },
    "… 3 weitere"
  ],
  "heute": "2028-03-13",
  "montag": "2028-03-13",
  "zeiten": [
    {
      "id": "f52baa08-e662-4390-8ac4-0eb4f7a585ee",
      "ende": "15:00",
      "beginn": "14:00"
    },
    {
      "id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "ende": "16:00",
      "beginn": "15:00"
    },
    "… 4 weitere"
  ],
  "zellen": [
    {
      "datum": "2028-03-13",
      "belegt": 0,
      "raeume": [],
      "faecher": [],
      "zeit_id": "f52baa08-e662-4390-8ac4-0eb4f7a585ee",
      "ohne_raum": 0,
      "vergangen": false,
      "kapazitaet": 0,
      "coach_fehlt": 0
    },
    {
      "datum": "2028-03-13",
      "belegt": 0,
      "raeume": [
        {
          "art": "stamm",
          "name": "Raum 1",
          "offen": true,
          "belegt": 0,
          "raum_id": "d409f49b-7e20-421f-8468-50618e14a625",
          "coach_id": "aaaaaaaa-5100-4000-8000-000000000002"
        },
        {
          "art": "stamm",
          "name": "Raum 2",
          "offen": true,
          "belegt": 0,
          "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
          "coach_id": "aaaaaaaa-5100-4000-8000-000000000003"
        }
      ],
      "faecher": [],
      "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "ohne_raum": 0,
      "vergangen": false,
      "kapazitaet": 10,
      "coach_fehlt": 0
    },
    "… 28 weitere"
  ],
  "a_woche": true
}
```

Zelle Do 16.03., 16 Uhr:

```json
{
  "datum": "2028-03-16",
  "belegt": 11,
  "raeume": [
    {
      "art": "stamm",
      "name": "Raum 1",
      "offen": true,
      "belegt": 5,
      "raum_id": "d409f49b-7e20-421f-8468-50618e14a625",
      "coach_id": "aaaaaaaa-5100-4000-8000-000000000002"
    },
    {
      "art": "faellt_aus",
      "name": "Raum 2",
      "offen": false,
      "belegt": 0,
      "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
      "coach_id": null
    },
    {
      "art": "stamm",
      "name": "Raum 3",
      "offen": true,
      "belegt": 5,
      "raum_id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717",
      "coach_id": "aaaaaaaa-5100-4000-8000-000000000004"
    }
  ],
  "faecher": [
    {
      "fach": "Mathematik",
      "zahl": 6
    },
    {
      "fach": "Deutsch",
      "zahl": 5
    }
  ],
  "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
  "ohne_raum": 1,
  "vergangen": false,
  "kapazitaet": 10,
  "coach_fehlt": 1
}
```

## slots_termin

`slots_termin('2028-03-16', <16 Uhr>)` — Do 16 Uhr, Jana Keller (Raum 2) fällt aus, 11 Kinder auf 10 Plätzen.

```json
{
  "kw": 11,
  "zeit": {
    "id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
    "ende": "17:00",
    "beginn": "16:00"
  },
  "datum": "2028-03-16",
  "heute": false,
  "anlass": null,
  "belegt": 11,
  "raeume": [
    {
      "art": "stamm",
      "name": "Raum 1",
      "offen": true,
      "kinder": [
        {
          "fach": "Mathematik",
          "name": "Finn Wolf",
          "klasse": 8,
          "zustand": "planned",
          "herkunft": "stammplatz",
          "raum_fest": false,
          "termin_id": "536b1df1-70b8-4a12-a986-0bed09d6b868",
          "session_id": null,
          "student_id": "ad1638c6-1b96-4e7f-b3a1-a6e7586ca547",
          "umgebucht_von": null
        },
        "… 4 weitere"
      ],
      "raum_id": "d409f49b-7e20-421f-8468-50618e14a625",
      "coach_id": "aaaaaaaa-5100-4000-8000-000000000002",
      "gemischt": false,
      "gestartet": false,
      "coach_name": "Tom Berg",
      "session_id": null,
      "vertretung": false,
      "stamm_coach_id": "aaaaaaaa-5100-4000-8000-000000000002",
      "stamm_coach_name": "Tom Berg"
    },
    {
      "art": "faellt_aus",
      "name": "Raum 2",
      "offen": false,
      "kinder": [],
      "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
      "coach_id": null,
      "gemischt": false,
      "gestartet": false,
      "coach_name": null,
      "session_id": null,
      "vertretung": false,
      "stamm_coach_id": "aaaaaaaa-5100-4000-8000-000000000003",
      "stamm_coach_name": "Jana Keller"
    },
    {
      "art": "stamm",
      "name": "Raum 3",
      "offen": true,
      "kinder": [
        {
          "fach": "Deutsch",
          "name": "Ela Kaya",
          "klasse": 8,
          "zustand": "planned",
          "herkunft": "stammplatz",
          "raum_fest": false,
          "termin_id": "dbadca64-b7f0-492d-9f1c-8d6eea5aca2f",
          "session_id": null,
          "student_id": "77b274ae-5688-4df1-8ad9-ab82c49491d8",
          "umgebucht_von": null
        },
        "… 4 weitere"
      ],
      "raum_id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717",
      "coach_id": "aaaaaaaa-5100-4000-8000-000000000004",
      "gemischt": true,
      "gestartet": false,
      "coach_name": "Paul Weber",
      "session_id": null,
      "vertretung": false,
      "stamm_coach_id": "aaaaaaaa-5100-4000-8000-000000000004",
      "stamm_coach_name": "Paul Weber"
    }
  ],
  "betrieb": true,
  "coaches": [
    {
      "id": "aaaaaaaa-5100-4000-8000-000000000003",
      "name": "Jana Keller",
      "raum_id": null
    },
    {
      "id": "aaaaaaaa-5100-4000-8000-000000000004",
      "name": "Paul Weber",
      "raum_id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717"
    },
    "… 2 weitere"
  ],
  "begonnen": false,
  "ohne_raum": [
    {
      "fach": "Deutsch",
      "name": "Nele Busch",
      "klasse": 8,
      "zustand": "planned",
      "herkunft": "stammplatz",
      "raum_fest": false,
      "termin_id": "63da74b4-e036-4800-8708-e659b0ecd98c",
      "session_id": null,
      "student_id": "ce98a09b-5a67-431b-aeb1-3f36d960035d",
      "umgebucht_von": null
    }
  ],
  "vergangen": false,
  "kapazitaet": 10,
  "nicht_dabei": [],
  "festgeschrieben": false,
  "anwesenheit_fehlt": false,
  "raeume_schliessbar": [
    {
      "name": "Raum 2",
      "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288"
    }
  ]
}
```

## slots_tag

`slots_tag('2028-03-13')` — Montag; Emir Yılmaz hat um 07:55 abgesagt.

```json
{
  "datum": "2028-03-13",
  "anlass": null,
  "absagen": [
    {
      "fach": "Mathematik",
      "name": "Emir Yılmaz",
      "beginn": "15:00",
      "klasse": 9,
      "zustand": "cancelled",
      "termin_id": "5d775989-0d8c-4038-ac6f-b92b11bc6068",
      "student_id": "94049743-7b12-4c25-a2cb-8c07abd57f1e",
      "rechtzeitig": true,
      "absage_eingang": "2028-03-13T07:55:00+01:00"
    }
  ],
  "betrieb": true,
  "raum_termine": [
    {
      "art": "stamm",
      "ende": "16:00",
      "beginn": "15:00",
      "belegt": 0,
      "status": null,
      "raum_id": "d409f49b-7e20-421f-8468-50618e14a625",
      "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "coach_id": "aaaaaaaa-5100-4000-8000-000000000002",
      "gestartet": false,
      "raum_name": "Raum 1",
      "coach_name": "Tom Berg",
      "kapazitaet": 5,
      "session_id": null
    },
    {
      "art": "stamm",
      "ende": "16:00",
      "beginn": "15:00",
      "belegt": 0,
      "status": null,
      "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
      "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "coach_id": "aaaaaaaa-5100-4000-8000-000000000003",
      "gestartet": false,
      "raum_name": "Raum 2",
      "coach_name": "Jana Keller",
      "kapazitaet": 5,
      "session_id": null
    },
    "… 4 weitere"
  ],
  "sessions_ohne_raum": []
}
```

## slots_zaehler

`slots_zaehler()` — Efe Demir und Mara Kowalski beginnen erst in 19 Tagen und zählen hier noch nicht.

```json
{
  "gesamt": 2,
  "ohne_raum": 1,
  "ohne_stammplatz": 1
}
```

## slots_kinder

`slots_kinder()` — gekürzt auf zwei Kinder.

```json
[
  {
    "fach": "Deutsch",
    "name": "Ben Albers",
    "paket": "Basic",
    "beginn": "2028-03-01",
    "klasse": 9,
    "geplant": 38,
    "rhythmus": {
      "woechentlich": 1,
      "vierzehntaeglich": 0
    },
    "stichtag": "2029-02-28",
    "einheiten": 38,
    "planbilanz": {
      "art": "reicht_bis",
      "zahl": 3,
      "datum": "2029-02-07",
      "geplant": 38,
      "hinweis": null,
      "toleranz": 2,
      "einheiten": 38,
      "abweichung": null,
      "terminzahl": 41,
      "verbraucht": 0,
      "ohne_termin": 0,
      "ohne_einheit": 3,
      "letzter_termin": "2029-02-07",
      "jenseits_ferientabelle": false
    },
    "student_id": "a7f47680-c8b8-4af1-b665-877dc2734051",
    "verbraucht": 0,
    "vertrag_id": "110482f1-ce4d-4dfe-b41b-02a6a286c49e",
    "stammplaetze": [
      {
        "id": "a2a80bf3-ba98-4062-bf02-e12f8a58ab64",
        "takt": "woechentlich",
        "beginn": "17:00",
        "zeit_id": "36ed3c22-6bb0-466b-ab84-ae195a3c60a6",
        "wochentag": 3,
        "gueltig_ab": "2028-03-01",
        "gueltig_bis": null,
        "vorgaenger_id": null
      }
    ],
    "weiterfuehren": null,
    "gekuendigt_zum": null,
    "vertrag_laeuft": true,
    "folgevertrag_ab": null,
    "laufzeit_monate": 12,
    "ohne_stammplatz": false
  },
  {
    "fach": "Deutsch",
    "name": "Efe Demir",
    "paket": "Standard",
    "beginn": "2028-04-01",
    "klasse": 7,
    "geplant": 0,
    "rhythmus": {
      "woechentlich": 1,
      "vierzehntaeglich": 0
    },
    "stichtag": "2028-11-30",
    "einheiten": 29,
    "planbilanz": {
      "art": "kein_stammplatz",
      "zahl": null,
      "datum": null,
      "geplant": 0,
      "hinweis": null,
      "toleranz": 2,
      "einheiten": 29,
      "abweichung": null,
      "terminzahl": 0,
      "verbraucht": 0,
      "ohne_termin": 29,
      "ohne_einheit": 0,
      "letzter_termin": null,
      "jenseits_ferientabelle": false
    },
    "student_id": "0e4fbc00-eacb-47fc-a5ca-119cb273ee67",
    "verbraucht": 0,
    "vertrag_id": "4dd5a76d-9b45-44f8-961a-72c18f8d0fde",
    "stammplaetze": [],
    "weiterfuehren": null,
    "gekuendigt_zum": null,
    "vertrag_laeuft": false,
    "folgevertrag_ab": null,
    "laufzeit_monate": 6,
    "ohne_stammplatz": true
  },
  "… 16 weitere"
]
```

## slots_kind

`slots_kind(<Lena Hoffmann>)` — Standard Jahr, Di wöchentlich + Do A-Woche; Di 14.03. auf Mi 15.03. umgebucht.

```json
{
  "kind": {
    "fach": "Mathematik",
    "name": "Lena Hoffmann",
    "klasse": 8,
    "student_id": "6a69a363-eff5-48e0-9c7d-5fd99264d764"
  },
  "letzte": [
    {
      "datum": "2028-03-07",
      "beginn": "16:00",
      "zustand": "planned",
      "herkunft": "stammplatz",
      "termin_id": "8f4c0715-0b4e-4f48-8e74-6994dcb34764",
      "session_id": null
    },
    {
      "datum": "2028-03-02",
      "beginn": "16:00",
      "zustand": "planned",
      "herkunft": "stammplatz",
      "termin_id": "95cb3d78-61dd-4f5b-9a10-b89f0ca97a38",
      "session_id": null
    },
    "… 11 weitere"
  ],
  "vertrag": {
    "paket": "Standard",
    "beginn": "2027-09-01",
    "rhythmus": {
      "woechentlich": 1,
      "vierzehntaeglich": 1
    },
    "stichtag": "2028-08-31",
    "einheiten": 57,
    "vertrag_id": "ce784b3e-c731-4d2d-8d10-4af58b8d5e0e",
    "gekuendigt_zum": null,
    "laufzeit_monate": 12
  },
  "naechste": [
    {
      "ende": "17:00",
      "datum": "2028-03-14",
      "beginn": "16:00",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
      "zustand": "cancelled",
      "herkunft": "stammplatz",
      "termin_id": "d63666a0-3479-48fe-89d7-045544382a61",
      "umgebucht_von": null,
      "absage_eingang": "2028-03-13T08:30:00+01:00",
      "festgeschrieben": false
    },
    {
      "ende": "17:00",
      "datum": "2028-03-15",
      "beginn": "16:00",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
      "zustand": "planned",
      "herkunft": "zusatz",
      "termin_id": "ff979a48-bc49-477d-b9c6-d38d692cd5ea",
      "umgebucht_von": "2028-03-14",
      "absage_eingang": null,
      "festgeschrieben": false
    },
    "… 22 weitere"
  ],
  "einheiten": {
    "gesamt": 57,
    "geplant": 36,
    "verbraucht": 0
  },
  "planbilanz": {
    "art": "ohne_termin",
    "zahl": 21,
    "datum": null,
    "geplant": 36,
    "hinweis": null,
    "toleranz": 2,
    "einheiten": 57,
    "abweichung": null,
    "terminzahl": 36,
    "verbraucht": 0,
    "ohne_termin": 21,
    "ohne_einheit": 0,
    "uebersprungen": [],
    "letzter_termin": "2028-08-31",
    "jenseits_ferientabelle": false
  },
  "zugelassen": true,
  "stammplaetze": [
    {
      "id": "cc9a0f88-a6ab-49b4-a4db-5e057a5ce28e",
      "takt": "woechentlich",
      "beginn": "16:00",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
      "wochentag": 2,
      "gueltig_ab": "2028-01-10",
      "gueltig_bis": null,
      "vorgaenger_id": null
    },
    {
      "id": "32201567-0546-46b5-9e1a-7f56ac2d6ffa",
      "takt": "a_woche",
      "beginn": "16:00",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
      "wochentag": 4,
      "gueltig_ab": "2028-01-10",
      "gueltig_bis": null,
      "vorgaenger_id": null
    }
  ],
  "weiterfuehren": null,
  "vertrag_laeuft": true,
  "fruehere_stammplaetze": []
}
```

## slots_frei

`slots_frei('woechentlich', '2028-03-14', <Jonas Köhler>)` — Raster gekürzt.

```json
{
  "ab": "2028-03-14",
  "takt": "woechentlich",
  "zeiten": [
    {
      "id": "f52baa08-e662-4390-8ac4-0eb4f7a585ee",
      "ende": "15:00",
      "beginn": "14:00"
    },
    {
      "id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "ende": "16:00",
      "beginn": "15:00"
    },
    "… 4 weitere"
  ],
  "zellen": [
    {
      "frei": 0,
      "raum": false,
      "voll": false,
      "termine": 6,
      "zeit_id": "f52baa08-e662-4390-8ac4-0eb4f7a585ee",
      "wochentag": 1
    },
    {
      "frei": 9,
      "raum": true,
      "voll": false,
      "termine": 6,
      "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "wochentag": 1
    },
    "… 28 weitere"
  ]
}
```

## slots_planbilanz_vorschau

`slots_planbilanz_vorschau(<Jonas Köhler>, [Do 16 wöchentlich, Do 17 A-Woche], '2028-03-14')` — zwei Stammplätze am Donnerstag: Sperrgrund SL008.

```json
{
  "gruende": [
    {
      "code": "SL001",
      "datum": "2028-03-16",
      "zeile": 0
    },
    {
      "code": "SL008",
      "zeile": 1
    }
  ],
  "planbilanz": {
    "art": "ohne_termin",
    "zahl": 8,
    "datum": null,
    "geplant": 30,
    "hinweis": null,
    "toleranz": 2,
    "einheiten": 38,
    "abweichung": null,
    "terminzahl": 30,
    "verbraucht": 0,
    "ohne_termin": 8,
    "ohne_einheit": 0,
    "uebersprungen": [
      "2028-03-16"
    ],
    "letzter_termin": "2029-01-25",
    "jenseits_ferientabelle": false
  },
  "terminzahl": 30,
  "uebersprungen": [
    "2028-03-16"
  ],
  "letzter_termin": "2029-01-25"
}
```

## slots_ziele

`slots_ziele(<Mia Schulz>, <Termin Do 16.03.>, '2028-03-15 18:40', '2028-03-13', 1)` — rechtzeitige Absage, nächste Woche.

```json
{
  "ab": "2028-03-13",
  "ziele": [
    {
      "ende": "16:00",
      "frei": 10,
      "datum": "2028-03-13",
      "beginn": "15:00",
      "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "verdraengt": null
    },
    {
      "ende": "17:00",
      "frei": 10,
      "datum": "2028-03-13",
      "beginn": "16:00",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
      "verdraengt": null
    },
    "… 12 weitere"
  ],
  "wochen": 1,
  "kein_budget": false,
  "alt_verbraucht": false
}
```

## slots_kandidaten

`slots_kandidaten('2028-03-17', <16 Uhr>)` — Kinder, die Fr 16 Uhr dazukommen dürfen.

```json
[
  {
    "fach": "Deutsch",
    "name": "Ben Albers",
    "offen": 0,
    "klasse": 9,
    "student_id": "a7f47680-c8b8-4af1-b665-877dc2734051",
    "verdraengt": "2029-02-07"
  },
  {
    "fach": "Deutsch",
    "name": "Ela Kaya",
    "offen": 14,
    "klasse": 8,
    "student_id": "77b274ae-5688-4df1-8ad9-ab82c49491d8",
    "verdraengt": null
  },
  "… 13 weitere"
]
```

## slots_coaches

`slots_coaches('2028-03-13')` — gekürzt.

```json
{
  "kw": 11,
  "montag": "2028-03-13",
  "raeume": [
    {
      "id": "d409f49b-7e20-421f-8468-50618e14a625",
      "name": "Raum 1"
    },
    {
      "id": "8c083e3d-c705-46f6-b45a-503b4540c288",
      "name": "Raum 2"
    },
    {
      "id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717",
      "name": "Raum 3"
    }
  ],
  "zeiten": [
    {
      "id": "f52baa08-e662-4390-8ac4-0eb4f7a585ee",
      "ende": "15:00",
      "beginn": "14:00"
    },
    {
      "id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "ende": "16:00",
      "beginn": "15:00"
    },
    "… 4 weitere"
  ],
  "coaches": [
    {
      "id": "aaaaaaaa-5100-4000-8000-000000000003",
      "name": "Jana Keller",
      "abweichungen": [
        {
          "art": "faellt_aus",
          "datum": "2028-03-16",
          "beginn": "16:00",
          "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
          "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
          "raum_name": "Raum 2"
        }
      ],
      "stammschichten": [
        {
          "id": "d9e9ec01-4c24-4901-bd4a-aea209d766e8",
          "beginn": "15:00",
          "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
          "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
          "raum_name": "Raum 2",
          "wochentag": 1,
          "gueltig_ab": "2027-09-01",
          "gueltig_bis": null
        },
        {
          "id": "3975c7fb-4668-4e49-8d45-09bae7f9a45f",
          "beginn": "16:00",
          "raum_id": "8c083e3d-c705-46f6-b45a-503b4540c288",
          "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
          "raum_name": "Raum 2",
          "wochentag": 1,
          "gueltig_ab": "2027-09-01",
          "gueltig_bis": null
        },
        "… 13 weitere"
      ],
      "stunden_pro_woche": 15
    },
    {
      "id": "aaaaaaaa-5100-4000-8000-000000000004",
      "name": "Paul Weber",
      "abweichungen": [],
      "stammschichten": [
        {
          "id": "a0d6fe5f-c97b-4993-8489-bffcac5bdfb6",
          "beginn": "16:00",
          "raum_id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717",
          "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
          "raum_name": "Raum 3",
          "wochentag": 2,
          "gueltig_ab": "2027-09-01",
          "gueltig_bis": null
        },
        {
          "id": "0994a9a8-6dd7-4175-a334-38ab44d58d84",
          "beginn": "16:00",
          "raum_id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717",
          "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
          "raum_name": "Raum 3",
          "wochentag": 4,
          "gueltig_ab": "2027-09-01",
          "gueltig_bis": null
        }
      ],
      "stunden_pro_woche": 2
    },
    "… 2 weitere"
  ]
}
```

## slots_einstellungen

`slots_einstellungen()` — gekürzt.

```json
{
  "heute": "2028-03-13",
  "ferien": [
    {
      "art": "ostern",
      "bis": "2028-04-22",
      "von": "2028-04-10",
      "name": "Ostern 2028"
    },
    {
      "art": "sommer",
      "bis": "2028-08-22",
      "von": "2028-07-10",
      "name": "Sommer 2028"
    }
  ],
  "raeume": [
    {
      "id": "d409f49b-7e20-421f-8468-50618e14a625",
      "name": "Raum 1",
      "aktiv_ab": "2027-09-01",
      "inaktiv_ab": null,
      "stammschichten": 15
    },
    {
      "id": "8c083e3d-c705-46f6-b45a-503b4540c288",
      "name": "Raum 2",
      "aktiv_ab": "2027-09-01",
      "inaktiv_ab": null,
      "stammschichten": 15
    },
    {
      "id": "f4b15d18-06de-4349-b2da-4ef8bc1a3717",
      "name": "Raum 3",
      "aktiv_ab": "2027-09-01",
      "inaktiv_ab": null,
      "stammschichten": 2
    }
  ],
  "zeiten": [
    {
      "id": "f52baa08-e662-4390-8ac4-0eb4f7a585ee",
      "ende": "15:00",
      "beginn": "14:00",
      "aktiv_ab": "2026-01-01",
      "inaktiv_ab": null
    },
    {
      "id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "ende": "16:00",
      "beginn": "15:00",
      "aktiv_ab": "2026-01-01",
      "inaktiv_ab": null
    },
    "… 4 weitere"
  ],
  "feiertage": [
    {
      "art": "feiertag",
      "name": "Tag der Arbeit",
      "datum": "2028-05-01"
    },
    {
      "art": "feiertag",
      "name": "Christi Himmelfahrt",
      "datum": "2028-05-25"
    },
    "… 3 weitere"
  ],
  "schuljahr_bis": "2028-08-22",
  "planungsgrenze": "2030-08-06"
}
```

## naechste_termine

`naechste_termine(<Ben Albers>, 3)` — rechnet immer ab `now()` (hier 10.10.2026), nicht ab dem Szenario-Tag.

```json
[
  {
    "ende": "18:00",
    "datum": "2028-03-01",
    "beginn": "2028-03-01T17:00:00+01:00",
    "uhrzeit": "17:00",
    "session_id": null,
    "festgeschrieben": false
  },
  {
    "ende": "18:00",
    "datum": "2028-03-08",
    "beginn": "2028-03-08T17:00:00+01:00",
    "uhrzeit": "17:00",
    "session_id": null,
    "festgeschrieben": false
  },
  {
    "ende": "18:00",
    "datum": "2028-03-15",
    "beginn": "2028-03-15T17:00:00+01:00",
    "uhrzeit": "17:00",
    "session_id": null,
    "festgeschrieben": false
  }
]
```

## termin_session_anlegen

`termin_session_anlegen('2028-03-13', <15 Uhr>, <Raum 1>)` — Admin am Tag des Termins.

```json
{
  "neu": true,
  "session_id": "39b00bdd-3071-45ab-a15f-33d434fb8d79",
  "ausgelassen": []
}
```

## meine_einsaetze

`meine_einsaetze('2028-03-13')` als Tom Berg — `heute` kommt aus `now()`.

```json
{
  "kw": 11,
  "heute": "2026-10-10",
  "montag": "2028-03-13",
  "einsaetze": [
    {
      "ende": "16:00",
      "datum": "2028-03-13",
      "heute": false,
      "beginn": "15:00",
      "kinder": [],
      "raum_id": "d409f49b-7e20-421f-8468-50618e14a625",
      "zeit_id": "7d2e624a-b804-40f3-b15d-6c4c27a370c2",
      "raum_name": "Raum 1",
      "session_id": "39b00bdd-3071-45ab-a15f-33d434fb8d79"
    },
    {
      "ende": "17:00",
      "datum": "2028-03-13",
      "heute": false,
      "beginn": "16:00",
      "kinder": [],
      "raum_id": "d409f49b-7e20-421f-8468-50618e14a625",
      "zeit_id": "60b23444-8a85-4519-8e3b-3e6a3ea5ee01",
      "raum_name": "Raum 1",
      "session_id": null
    },
    "… 12 weitere"
  ]
}
```
