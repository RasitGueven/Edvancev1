# Slots SL3 — offene Punkte

Stand: 12.10.2026 · Paket SL3 · Branch `feat/rasit-slots-sl3-coach-heute` (ab `origin/dev` 0a60904, SL2 #240 und F2 #238 schon drin)

## Was am Datenvertrag fehlte

Nichts, das SL3 nachbauen musste. Eine Lücke bleibt für die Eltern:

1. **`naechste_termine` liefert keinen Raum.** Die Eltern sehen den Raum der nächsten Session erst, wenn sie
   festgeschrieben ist (dann kommt er aus `coaching_sessions.room` über `session_id`). Vorher stehen nur Datum und
   Uhrzeit da. Wenn der Raum vorher sichtbar sein soll: `raum_name` in `naechste_termine` (Foundation).

## Offene Punkte

2. **`listSessionsHeute` (`src/lib/supabase/heute.ts`) ist jetzt unbenutzt.** „Heute im Betrieb“ liest nur noch
   `slots_tag`. Die Funktion und der Typ `SessionHeute` gehören beim nächsten Foundation-Lauf entfernt; SL3 darf
   `src/lib/supabase/**` nicht ändern.
3. **Geteilte Bausteine aus SL2 unter `src/pages/admin/slots/`.** Die Coach-Seite nutzt `useSlotsLaden`, `KlasseFach` und
   `slotsFormat`, die Akte `PlanbilanzBadge`. Sie werden nur importiert, nicht geändert. Ein Umzug nach
   `src/components/edvance/` wäre sauberer (Foundation).
4. **`useCoachZaehler` geändert.** Er steht nicht ausdrücklich in der Liste von SL3, gehört aber zur Coach-Hülle: Der
   Zähler „Heute“ zählt seit SL3 die Einsätze aus dem Plan mit (jede Session-ID einmal), sonst stünde dort 0, solange
   nichts festgeschrieben ist. Dafür ein zusätzlicher Aufruf `meine_einsaetze` je Seitenwechsel.
5. **Zwei Kartenformen in „Heute im Raum“** (Gestaltungs-Abnahme Befund 3): Festgeschriebene Sessions behalten die
   schmale C2-Karte mit „Briefing ansehen“ und „Session starten“, Plan-Einsätze haben die große Einsatz-Karte mit Kindern
   und „Session öffnen“. Das sind zwei Handlungen (festschreiben gegenüber starten). Eine gemeinsame Form wäre ruhiger,
   greift aber in die C2-Karte ein.
6. **Kennzahlen im CoachDashboard** (Befunde 4 und 5): Die Kennzahlen stehen unter „Heute im Raum“ in `text-3xl` sans.
   Das war schon so. Wenn sie wie auf Admin-„Heute“ als Leiste in `font-serif text-2xl` darüber stehen sollen, ist das ein
   eigener Schritt.
7. **Testlauf in Gold.** In „Heute im Betrieb“ ist „Testlauf“ `warning` wie in der C2-Karte und in „Offen geblieben“. Die
   Einzel-Session ist `primary` (Info). Laut Entscheidung 28 steht Gold für „Achtung“. Ob Testlauf eine Warnung ist,
   sollte einheitlich für alle Stellen entschieden werden (Befund 6).
8. **Drei Namen für das Planungsziel** (Befund 12): „Heute im Betrieb“ führt jetzt „Zum Wochenplan“ (`/admin/slots`),
   „Offen geblieben“ weiter „Zum Stundenplan“ (`/admin/schedule`, Einzel-Sessions und Testläufe). Es sind zwei
   verschiedene Ziele. Der Schlüssel `heute.betrieb.fuss` ist deshalb unverändert, neu ist `heute.betrieb.fussWochenplan`.
9. **„Sessions“ zählt auch noch nicht festgeschriebene Raum-Termine.** „7 Sessions · 18 Kinder“ auf Admin-„Heute“
   zählt Raum-Termine und Sessions ohne Raum. Ein Raum-Termin wird erst mit „Session öffnen“ zur Session.
   Gemeint ist „Einsätze im Haus“. Die Wortwahl bleibt offen.
10. **Coach liest die Akte erst nach dem Festschreiben** (Entscheidung 14, `coach_hat_platz`). Deshalb sind die Namen in
    „Meine Einsätze“ nicht verlinkt.
11. **`App.tsx` hat 456 Zeilen** (dev: 446). SL3 bringt nur die Route `/coach/einsaetze`. Ein Aufteilen der Routen
    gehört in ein eigenes Paket.
12. **Wochennavigation** (Befunde 10 und 11, Baustein aus SL1): „Diese Woche“ ist in der aktuellen Woche gedämpft
    (siehe offene-punkte-sl2 Nr. 5). Die Pfeile haben eine Trefferfläche von 44 px (`h-11 w-11`), sichtbar ist nur das
    Symbol. Die weite Laufweite der Zeiten kommt von `tabular-nums` in der Schrift.
13. **Bildschirmfotos** stammen aus der echten App mit Fake-Client und erfundenen Daten (Muster H3). Datum ist
    Mo 12.10.2026, KW 42. Kontaktiert wurden nur Google Fonts.
