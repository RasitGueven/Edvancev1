# Bauauftrag Slots — Menüpunkt „Slots“ in der Admin-App (Fassung 1)

**Stand:** 09.10.2026 · **Entscheider:** Rasit · **Grundlage:** `Anforderung-Slots.md` (Tolunay, 25.09.2026),
`slots-dummy.html`, Edvancev1 `origin/dev` 242b660, Admin-Hülle H1 bis H4b und Coach-Hülle H6 (gemergt).

**Rangfolge bei Widersprüchen:** Maßgebliche Entscheidungen in dieser Datei, dann die Anforderung, dann der Dummy.
Für das **Aussehen** gilt der Dummy gar nicht: Er zeigt Ablauf und Verhalten. Maßstab für die Optik ist die
Admin-Hülle mit „Heute“ und „Verträge“ (Abschnitt C). Der Dummy ist am 25.09. entstanden, also vor der Hülle. Er hat
noch die alte Kopfnavigation, das Navy-Band und je Zeile drei Knöpfe. Genau das soll die echte Oberfläche nicht übernehmen.

## Pakete

| Paket | Inhalt | Worktree · Branch | Migrationen | Wegwerf-DB |
|---|---|---|---|---|
| SL1 | Datenmodell, Planung, Regeln, Lese- und Schreibfunktionen, nächster Termin, Datenvertrag, `src/lib`-Schicht, vier gemeinsame Bausteine | `../Edvancev1-sl1` · `feat/rasit-slots-sl1-datenmodell` | `20261013100000`–`135959` | Port 55450, `~/wegwerf-db-sl1` |
| SL2 | Admin-Oberfläche: Wochenplan, Termin, Kinder, Kind, Coaches, Einstellungen, Dialoge; alte Slot-Seiten weg | `../Edvancev1-sl2` · `feat/rasit-slots-sl2-oberflaeche` | keine | keine |
| SL3 | Coach „Meine Einsätze“, Session öffnen aus dem Plan, „Heute im Betrieb“ und Absagen auf „Heute“, nächste Session bei Coach und Eltern, Verweise in der Akte | `../Edvancev1-sl3` · `feat/rasit-slots-sl3-coach-heute` | keine | keine |

Reihenfolge: **SL1** zuerst, bis es gemergt und eingespielt ist. Danach laufen **SL2 und SL3 parallel**. Beide sind
reines Frontend und bauen nur auf dem Datenvertrag aus SL1 auf.

Warum drei Pakete statt einem: Datenbank und Oberfläche in einem Lauf heißt in der Praxis, dass die Oberfläche am Ende
schnell fertig gemacht wird. Die Oberfläche ist hier aber der Punkt. SL2 bekommt deshalb einen eigenen Lauf mit
eigener Gestaltungs-Abnahme.

**Vorbereitung durch Rasit:** Diese Datei, `Anforderung-Slots.md` und `slots-dummy.html` liegen in den
Windows-Downloads. SL1 holt sie in Schritt 0 nach `docs/slots/`.

---

## Was es schon gibt (Ist, `origin/dev` 242b660)

- **Anwesenheit:** `session_students.attendance` hat schon genau die Zustände der Anforderung:
  `planned | present | cancelled | unexcused | cancelled_by_us`. `einheit_verbraucht()` ist true für present und
  unexcused. Das stammt aus Schülerakte S1, Entscheidungen 4 und 5.
- **Kalender:** `ferien_nrw` reicht bis zu den Sommerferien 2030 (Ende 06.08.2030). `feiertage_nrw` gibt es für
  2026–2030, mit Pfingstferientag (Art
  `pfingstferien`). Dazu gibt es `betriebstag(datum)` und `betriebstage(von, bis)`.
- **Einheiten:** `einheiten_stand()` und `einheiten_stand_intern()` zählen heute nur über `session_students` ×
  `coaching_sessions`, ohne Testläufe. `board_schueler()` und die Akte bauen darauf auf.
- **Zugang:** `session_platz_zugang(student, datum)` und Trigger ZG001: Einen Platz bekommt nur ein Kind mit laufendem
  Vertrag.
- **Vertrag:** `vertraege` hat `tier_id`, `laufzeit_monate`, `einheiten`, `vertragsbeginn`, `vertrag_ende` (Stichtag),
  `fach` und `klasse`. `tier_laufzeiten` enthält Basic, Standard und Premium für 6 und 12 Monate, mit 19/38, 29/57
  und 38/76 Einheiten.
- **Session:** `coaching_sessions` steht für einen Raum zu einer Zeit, mit einem Coach und höchstens 5 Kindern. Davon
  geht die ganze Session-Engine und die Coach-Live-Sicht aus. Die Buchung in `session_students` machen laut
  Session-P1, Entscheidung 2, „Admin bzw. Slots“.
- **Altlast S10:** `slots`, `slot_wishes` und `slot_assignments` hängen am Lead und an einem festen Raum. Dazu gehören
  `SlotsManagePage`, `SlotPickerPage`, `slots/SlotCalendarGrid`, `lib/slotGrid.ts` und `lib/supabase/slots.ts`. Das
  passt nicht zum neuen Modell (Kind statt Lead, Raum je Termin). `session_series` gibt es nicht. Die Annahme in
  Frage 1 der Anforderung ist damit überholt.
- **Stundenplan** (`SchedulePage`, `/admin/schedule`) legt `coaching_sessions` von Hand an. Darüber laufen auch
  Testläufe, und T2 baut dort den Testlauf-Schalter.
- **Hülle:** Es gibt `AppShell`, `PageHeader`, `adminNav.ts`, `coachNav.ts` und `useAdminZaehler`. Auf „Heute“ gibt
  es `KennzahlenLeiste`, `ArbeitsListe` und `HeuteImBetrieb` mit fünf Platz-Punkten je Raum. Dazu kommen
  `Reiterleiste` (Verträge), `EdvanceTable`, die Varianten von `EdvanceBadge`, `Modal`, `CardMenu` (Leads, 44 px),
  die Chips aus `LeadFilterBar` und `SELECT_MD`.

---

## Maßgebliche Entscheidungen

### A — Fachlich

1. Die Anforderung gilt in den Abschnitten A bis K, mit den Regeln, Grenzfällen und Abnahmefällen 1–15. Wo diese
   Datei etwas genauer festlegt, gilt diese Datei.
2. **Rhythmus** (Frage 10) wie in Anforderung E 25, aber als Tabelle `slot_rhythmus(tier_id, laufzeit_monate,
   woechentlich, vierzehntaeglich)`. So lässt er sich ohne Code ändern.
3. **Basic Halbjahr** (Frage 11): Der Bau ändert daran nichts. Die Planbilanz zeigt „reicht bis …“. Ob Einheiten oder
   Preis angepasst werden, entscheiden die Gründer getrennt davon.
4. **Toleranz der Planbilanz** (Frage 12): 2 Einheiten. Der Wert ist eine Stellschraube in `session_einstellungen`
   (Schlüssel `slots_planbilanz_toleranz`, Zahl, ganzzahlig, 0–5, Einheit `anzahl`) und erscheint auf der bestehenden
   Seite Stellschrauben. Die Beschreibung sagt, dass die Änderung sofort auf die Planbilanz wirkt, nicht erst ab der
   nächsten Session. `session_r1.test.sql` zählt danach 30 statt 29 Stellschrauben.
5. **Doppelstunde** (Frage 13): nein. Es gilt höchstens ein Termin pro Tag, auch bei Premium.
6. **Volle Wunschslots** (Frage 14): keine Warteliste. Der Admin weicht auf den nächstbesten Slot aus.
7. **Uhrzeiten** (Frage 15): Die Platzhalter 14–20 Uhr stündlich kommen als Startinhalt in die pflegbare Liste.
8. **Wer in den Slots vorkommt:** Kinder mit laufendem oder kommendem Vertrag. Testkonten (`ist_test`) und Testläufe
   bleiben außen vor. Einzel-Sessions und Testläufe laufen weiter über `/admin/schedule`.
9. **Übergang:** Sessions, die vor den Slots von Hand angelegt wurden (zum Beispiel der erste echte Fall Ende Oktober),
   zählen weiter. Sie werden nicht nachträglich in Slot-Termine umgewandelt.

### B — Technik (beantwortet die technischen Fragen 1–9)

10. **Neue Tabellen**, die Namen sind verbindlich:
    - `slot_zeiten` (beginn, ende = beginn + 60 min, aktiv_ab, inaktiv_ab)
    - `raeume` (name, aktiv_ab, inaktiv_ab)
    - `stammschichten` (coach_id, wochentag 1–5 nach ISO, slot_zeit_id, raum_id, gueltig_ab, gueltig_bis)
    - `schicht_abweichungen` (datum, slot_zeit_id, raum_id, art `vertretung | faellt_aus | zusatz`, coach_id)
    - `slot_rhythmus`
    - `stammplaetze` (student_id, vertrag_id, wochentag, slot_zeit_id, takt `woechentlich | a_woche | b_woche`,
      gueltig_ab, gueltig_bis, vorgaenger_id)
    - `kind_termine` (siehe 11)

    Keine Tabelle wird gedroppt. Stammdaten (Räume, Uhrzeiten, Stammschichten, Stammplätze) werden nie gelöscht,
    sondern ab einem Datum beendet. Löschen dürfen nur die Slot-Funktionen, und nur zwei Arten von Zeilen: geplante
    Kind-Termine ohne Session (beim Abgleich, bei der Rücknahme einer Umbuchung, bei Widerruf oder Kündigung) und
    Schicht-Abweichungen (Vertretung zurücknehmen). Die S10-Tabellen bleiben unangetastet: kein DROP und keine
    Datenänderung. Nur ihre Oberfläche verschwindet (SL2).
11. **Kind-Termine werden gespeichert** (Frage 2): Es gibt eine Zeile je Kind und Termin bis zum Stichtag, und zwar so
    viele, wie das Budget hergibt. Spalten:
    - `herkunft` (`stammplatz | zusatz`), `stammplatz_id`
    - `umgebucht_von` (Verweis auf die abgesagte Zeile)
    - `zustand` mit denselben Codes wie `session_students.attendance`
    - `absage_eingang`, `absage_erfasst_von`
    - `raum_id` und `raum_fest` (manuell verschoben)
    - `session_id`

    `termine_planen(student)` gleicht ab, statt neu anzulegen:
    - Termine, die bleiben, behalten Zeile, id und Raum-Stift. Angefasst werden nur künftige Zeilen mit Herkunft
      Stammplatz, Zustand `planned` und ohne Session.
    - **Feste Zeilen** sind alle übrigen: vergangene, Zusatz-, festgeschriebene und nicht geplante Termine. Dazu zählen
      auch Buchungen in `session_students` ohne Kind-Termin (von Hand angelegte Einzel-Sessions, Übergang nach 9),
      sofern sie nicht abgesagt sind und kein Testlauf.
    - **Budget:** Feste Zeilen mit Zustand `planned`, `present` oder `unexcused` belegen zuerst eine Einheit.
      Abgesagte (`cancelled`) und ausgefallene (`cancelled_by_us`) Zeilen bleiben stehen und sperren ihr Datum, belegen
      aber keine Einheit. Den Rest des Budgets füllen Stammplatz-Termine, der früheste zuerst.
    - Daraus folgen zwei Dinge von selbst: Ein Zusatztermin verdrängt den letzten Stammplatz-Termin (Anforderung G 45),
      und die Einheit einer rechtzeitigen Absage landet hinten.
    - Jede feste Zeile sperrt ihren Tag für einen weiteren Termin.
    - **Keine Überbuchung durch die Planung:** Hat ein Stammplatz-Datum keinen freien Platz (ein anderes Kind hat ihn
      per Zusatz oder Umbuchung belegt) oder keinen geöffneten Raum, wird es übersprungen. Das nächste Datum rückt
      nach. Die Planbilanz nennt übersprungene Daten.

    Jede Schreibfunktion ruft am Ende `termine_planen` für alle betroffenen Kinder auf. Ein Trigger auf `vertraege`
    tut das bei Widerruf, Kündigung und Abschluss.
12. **Planbilanz** wird gerechnet, nicht gespeichert. Grundlage:
    - E = Einheiten
    - V = verbraucht
    - G = geplant (auch vergangene ohne Anwesenheit)
    - O = E − V − G (ohne Termin)
    - U = Stammplatz-Termine bis zum Stichtag, für die kein Budget mehr da ist
    - Terminzahl im Sinn von K 60 = alle Stammplatz-Termine bis zum Stichtag (gespeicherte und U)

    Die Arten werden in dieser Reihenfolge geprüft:
    1. `kein_stammplatz`: O > 0 und kein aktiver Stammplatz.
    2. `aufgebraucht`: kein künftiger Termin und O = 0.
    3. `reicht_bis`: U > Toleranz. Das Datum ist der letzte Termin.
    4. `ohne_termin`: O > Toleranz. Die Zahl ist O.
    5. Sonst `passt`. Liegen U oder O zwischen 1 und der Toleranz, wird das mitgeliefert.

    Geliefert werden immer: Art, Terminzahl, U, O, das Datum des letzten Termins und übersprungene Daten (11). Die
    Kontrollwerte aus K 60 müssen so herauskommen, auch der letzte Termin bei „passt“.
13. **Zustände und Verbrauch** (Frage 3): `kind_termine.zustand` ist die eine Wahrheit für geplant, abgesagt und
    ausgefallen. `einheiten_stand_intern` zählt künftig `kind_termine`. Dazu kommen `session_students`-Zeilen ohne
    Kind-Termin (Einzel-Sessions, Übergang nach 9). Keine Buchung wird doppelt gezählt, Testläufe nie.
14. **Festschreiben:** Ein Raum-Termin wird zur `coaching_session`, sobald jemand `termin_session_anlegen(datum, zeit,
    raum)` aufruft. Das ist der Knopf „Session öffnen“ beim Coach oder im Termin beim Admin.
    - Das geht nur am Tag des Termins (Berlin) und ist idempotent. Dafür kommen die neuen Spalten
      `coaching_sessions.raum_id` und `slot_zeit_id` mit einem eindeutigen Index.
    - Die Funktion füllt `coach_id`, `room` (= Raumname, die Live-Sicht und die Listen lesen `room`) und
      `scheduled_at` (Datum + Beginn in Berlin). Sie legt `session_students` für die Kinder des Raums an und setzt
      `kind_termine.session_id`.
    - Ein Kind ohne Zugang an dem Tag (zum Beispiel ab `gekuendigt_zum`, Trigger ZG001) lässt sie aus: Sein Termin geht
      auf `cancelled_by_us`, und die Rückgabe nennt es. Die Session wird trotzdem angelegt.
    - Die Anwesenheit aus der Session (Tablet, „anwesend“, „nicht erschienen“) spiegelt ein Trigger nach
      `kind_termine.zustand`. Andere Schreiber gibt es nicht.

    **Nach dem Festschreiben** gilt für jede Schreibfunktion:
    - Ist die Session gestartet (`gestartet_am`), sind Raum, Coach und Ausfall für diesen Raum gesperrt (SL011).
      Eine Absage geht noch.
    - Vor dem Start gilt:
      - `termin_coach_setzen` zieht `coaching_sessions.coach_id` nach. Nur so liest die Vertretung die Session (RLS
        und `session_ist_coach` gehen über `coach_id`). „fällt aus“ löscht die Session, solange sie keine Session-Daten
        hat, und schickt ihre Kinder in die Zuteilung zurück.
      - `termin_raum_setzen` heißt: Zeile in Session A löschen, in Session B anlegen.
      - Absage, Ausfall, Zusatz, Umbuchung und Rücknahme schreiben in `kind_termine` und `session_students`.
      - Ein neues Kind kommt in den festgeschriebenen Raum, wenn die Zuteilung es dorthin legt. Festgeschriebene Räume
        sind für die Zuteilung der übrigen Kinder fest.
      - „Ganzer Termin fällt aus“ setzt in jeder Session alle Kinder auf `cancelled_by_us`.

    **Nächster Termin:** Weil künftige Sessions erst am Tag entstehen, finden Stellen, die „die nächste Session“ über
    `session_students` × `coaching_sessions` suchen, nichts mehr. Betroffen sind `quest_erzeugen`,
    `session_kind_kontext`, `coach_raum_live`, `session_abschluss_kind` sowie im Frontend die nächste Session im
    ParentDashboard und die Kennzahl im CoachDashboard.
    - SL1 baut `naechster_termin(p_student_id, p_nach timestamptz)` über `kind_termine` ∪ `session_students` und
      stellt die vier SQL-Stellen darauf um. Sonst ändert sich an ihnen nichts. Der Diff je Funktion kommt ins PR.
    - Die beiden Frontend-Stellen stellt SL3 um.

    **Coach am Vortag:** `coach_hat_platz` braucht eine eigene Session im Fenster gestern bis morgen. Vor dem
    Festschreiben liest ein Coach die Akte seiner Kinder deshalb nicht. Das wird bewusst so hingenommen. Eine
    Erweiterung um die Zuteilung aus `kind_termine` wäre ein eigenes Sicherheitspaket.
15. **Raumzuteilung** (Frage 9) wird in SQL berechnet und ist deterministisch:
    1. Geöffnete Räume nach Namen sortieren.
    2. Kinder mit Raum-Stift zuerst in ihren Raum.
    3. Die übrigen nach Fach gruppieren, die größte Gruppe zuerst. Innerhalb der Gruppe nach Buchungszeit, dann nach id.
    4. Ein Raum mit demselben Fach hat Vorrang, höchstens 5 Kinder je Raum.
    5. Wer übrig bleibt, steht unter „Ohne Raum“.

    Gespeichert wird nur der Raum-Stift. Beim Festschreiben landet die Zuteilung in `session_students`. Bis dahin kann
    eine neue Buchung sie verschieben. Die Oberfläche sagt das in einem Satz.
16. **Kapazität und Gleichzeitigkeit** (Frage 6):
    - Belegt sind Kind-Termine mit Zustand `planned` oder `present`. Eine späte Absage macht den Platz frei, so steht es
      in der Anforderung.
    - Die Kapazität ist geöffnete Räume × 5. Ein Raum ist geöffnet, wenn eine Stammschicht oder eine Abweichung ihm
      einen Coach gibt.
    - Jede schreibende Slot-Funktion nimmt zuerst `pg_advisory_xact_lock(hashtext('slots'))` und prüft danach.
      Damit gewinnt bei zwei Admins der erste, der zweite bekommt SL001.
    - `stammplatz_vergeben` und `stammplatz_aendern` sperren mit SL001 oder SL002, wenn einer der nächsten sechs
      Termine ab „gültig ab“ voll ist oder keinen Raum hat. Das ist dieselbe Regel wie in der Übersicht freier
      Plätze. Spätere volle Daten werden nach 11 übersprungen und in der Vorschau genannt.
17. **Zeit** (Frage 7):
    - Datum und Uhrzeit rechnet SQL mit `Europe/Berlin`.
    - Für die 10-Uhr-Regel gilt: rechtzeitig, wenn `(eingang at time zone 'Europe/Berlin') < datum + 10:00`. Die
      Entscheidung trifft nur der Server, die Oberfläche zeigt eine Vorschau mit derselben Regel.
    - Ein Eingang in der Zukunft wird abgelehnt.
    - Alle Funktionen haben `p_jetzt timestamptz default now()`, nur für Tests. Beachtet wird es nur bei Admin oder
      Systemaufruf (`ist_systemaufruf()`). Für Coaches gilt immer `now()`, damit niemand „nur am Tag“ umgeht. Die
      Oberfläche übergibt es nie.
18. **A- und B-Woche** (Frage 8): ISO-Kalenderwoche `extract(week from datum)`. Ungerade ist A, gerade ist B. Der
    Server ist maßgeblich. Im Frontend nur `isoWeek()` aus `lib/datetime` zur Anzeige.
19. **Wochengrenze** (G 44): Aktive Termine einer Kalenderwoche ≤ Rhythmus der Woche + 2.
    - **Aktiv** heißt Zustand `planned`, `present` oder `unexcused`, dazu Einzel-Session-Buchungen nach 11.
    - Der Rhythmus der Woche ist die Zahl der aktiven Stammplätze des Kindes, deren Takt in diese Woche fällt. So ergibt
      „1× + 14-täglich“ je nach A- oder B-Woche 1 oder 2, wie in G 44.
    - Ohne Stammplatz kommt er aus dem Paket: der wöchentliche Teil, der 14-tägliche in A-Wochen.
    - Dazu gilt höchstens ein aktiver Termin pro Tag (partieller Unique-Index auf `kind_termine`, Prüfung gegen
      Einzel-Sessions in der Funktion).
20. **Coaches** (Frage 5): Coaches sind `profiles` mit Rolle coach, `stammschichten.coach_id = profiles.id`. Coaches
    lesen keine Slot-Tabelle direkt. Sie haben nur `meine_einsaetze` und `termin_session_anlegen`, für den eigenen Raum
    am selben Tag. Jede Funktion prüft die Rolle selbst, das gilt auch für direkte Adressen.
21. **Feiertage** (Frage 4): Die Tabelle gibt es schon und sie wird wie `ferien_nrw` per Migration gepflegt. Die
    Einstellungen zeigen sie nur an.

    Die Planungsgrenze ist `max(ferien_nrw.bis)`. `termine_planen` plant bis dorthin, und die Planbilanz meldet SL012
    als Hinweis, wenn der Stichtag dahinter liegt. Schreibfunktionen mit einem Ziel-Datum dahinter brechen mit SL012
    ab.
22. **Vertrag:** Stammplätze gelten höchstens bis zum Stichtag ihres Vertrags.
    - Bei Widerruf enden sie am Widerrufstag. Bei Kündigung enden sie am Tag vor `gekuendigt_zum`.
    - Künftige geplante Termine ab diesem Tag fallen weg, festgeschriebene werden zu `cancelled_by_us`.
    - Bei einem Folgevertrag gibt es den Vorschlag „wie bisher weiterführen“ über `stammplaetze_weiterfuehren`.
      Einheiten gehen nicht über.
23. **Fehler:** Es gibt eigene Codes mit Hinweis, und die Oberfläche übersetzt sie über i18n:
    - SL001 Slot voll
    - SL002 kein Raum mit Coach
    - SL003 schon ein Termin an dem Tag
    - SL004 Wochengrenze erreicht
    - SL005 keine offenen Einheiten
    - SL006 außerhalb des Vertrags
    - SL007 Vergangenheit
    - SL008 zwei Stammplätze am selben Tag
    - SL009 Schicht doppelt (Raum oder Coach)
    - SL010 Rücknahme nicht möglich (Platz vergeben oder Termin begonnen)
    - SL011 Termin vergangen, nur Ansicht
    - SL012 jenseits der Ferientabelle

    Fehlende Rechte ergeben 42501.
24. **Rechte:** RLS auf allen neuen Tabellen: lesen nur Admin, schreiben niemand direkt, nur über SECURITY DEFINER
    mit Rollenprüfung. Kein EXECUTE für anon.
25. **Altlasten:** S10-Seiten und S10-Frontend entfernt SL2 (Routen `/admin/slots` neu, `/admin/slot-auswahl` leitet
    um). `SchedulePage` bleibt unter `/admin/schedule` als „Einzel-Sessions und Testläufe“ und fliegt aus der Leiste.
    T2 baut dort weiter. SL2 ändert an der Seite nichts außer Titel-Schlüssel und Erreichbarkeit.

### C — Oberfläche (maßgeblich, vor dem Dummy)

26. **Maßstab:** Die Admin-Hülle und die echten Seiten „Heute“ und „Verträge“, siehe `docs/screenshots/admin-h3/` und
    `docs/screenshots/admin-h2/6-vertraege-*.png`. So sieht es heute aus, und das wird ersetzt:
    `docs/screenshots/admin-h4a/1-stundenplan-*`, `2-slots-*` und `3-slot-auswahl-*` (Formular oben, Liste darunter,
    kein Überblick über die Woche). Es gilt die Coach/Admin-Sprache des Designsystems:
    - flach, heller Grund `--color-bg-app`, weiße `EdvanceCard` mit `shadow-card` und `--radius-lg`
    - 150 ms ease-out
    - kein Glas, keine Verläufe, kein Navy-Band
    - nur Tokens, keine freien Hex-Werte, keine Inline-Styles außer für berechnete Breiten
    - Lucide-Symbole wie in der Hülle
    - CLAUDE.md §11 und §12 vollständig
27. **Was gegenüber dem Dummy anders wird** (Pflicht):

    | Dummy | Neu |
    |---|---|
    | Kopfnavigation, Navy-Band | Hülle mit `PageHeader` (Rubrik „Betrieb“, Titel, ein Satz mit dem Wochenstand) |
    | Pillen-Reiter ohne Adresse | `Reiterleiste` wie Verträge mit Zählern, Reiter in der URL (`?reiter=`), Zurück funktioniert |
    | Termin und Kind ersetzen die Seite | eigene Routen mit Zurück-Link: `/admin/slots/termin/:datum/:zeitId`, `/admin/slots/kind/:studentId` |
    | Zelle: dünner Balken, „1 Raum“, „2 Raume“ | Platz-Punkte je geöffnetem Raum wie in „Heute im Betrieb“, Text nur bei Handlungsbedarf |
    | 12 Zellen „kein Raum besetzt“ | Zeitzeilen ohne geöffneten Raum in der ganzen Woche fallen zu einer schmalen Zeile zusammen. Einzelne leere Zellen sind ruhig, mit Strich und Hinweis beim Darüberfahren |
    | Ferien in jeder Zelle | Ein Tag ohne Betrieb ist eine graue Spalte mit dem Anlass einmal oben |
    | je Kind drei Bedienelemente (Raum, Absage, Umbuchen) | ein „…“-Menü je Kind (`CardMenu`, 44 px) mit Absage, Umbuchen, In Raum … verschieben, Ausgefallen (durch uns) |
    | roter Hinweisstreifen über dem Termin | „Ohne Raum“ ist die erste Karte, die Lösung steht in der Karte |
    | lange Kinder-Tabelle nach Namen | sortiert nach Handlungsbedarf, Filter-Chips, Einheiten als Stapelbalken |
    | Stammschichten als Liste | Wochenraster je Coach, ein Tippen auf eine Zelle legt an oder entfernt |
    | native Radio-Zeilen im Stammplatz-Dialog | zwei Spalten: links die Stammplatz-Zeilen mit Takt-Umschalter, rechts das Raster der freien Plätze, unten die Planbilanz |
    | gesperrter Speichern-Knopf | Die Gründe stehen als Liste direkt unter dem Knopf (CLAUDE.md: kein gesperrter Knopf ohne Grund, Abnahmefall 9) |

    **Bedienelemente:** Im Seitenkopf gibt es höchstens eine Primäraktion. Eine Zeile hat höchstens einen sichtbaren
    Knopf plus das „…“-Menü. Einzige Ausnahme ist die Karte „Ohne Raum“: Dort gibt es genau zwei Knöpfe, „Umbuchen“
    und „Ausgefallen (durch uns)“, weil das die Entscheidung ist, die dort fällt.

28. **Farbe hat Bedeutung**, über `EdvanceBadge` und Flächen aus den Tokens:

    | Bedeutung | Variante bzw. Fläche |
    |---|---|
    | passt, rechtzeitig, anwesend | `strength` |
    | Info: geplant, Zusatz, umgebucht, heute | `primary` bzw. `--color-primary-light` |
    | Achtung: ab 90 % belegt, reicht bis, x ohne Termin, Vertretung, gemischt | `warning` bzw. `--color-gold-warning-light` |
    | Handeln: mehr Kinder als Plätze, Coach fehlt, ohne Raum, kein Stammplatz bei laufendem Vertrag, unentschuldigt | `coach-emergency` bzw. `--color-error-coach-light` |
    | kein Betrieb, abgesagt, ausgefallen, vergangen | `muted` |

    Zusätzlich gilt:
    - Fächer bekommen keine Farbe (es gibt keine Tokens dafür), sondern Kürzel in neutralen Chips: M, D, E.
    - Kein `--color-accent` als Schrift.
    - Das Mastered-Grün `mastered` wird nicht verwendet.
29. **Schrift und Zahlen:**
    - Zahlen und Uhrzeiten mit `tabular-nums`.
    - Fraunces (`font-serif`) nur für den Seitentitel und große Zahlen, wie auf „Heute“. Kartentitel sind sans
      semibold.
    - Unter dem Seitenkopf höchstens drei Größen: `text-xs`, `text-sm` und `font-serif text-2xl` für Kennzahlen.
      Der Titel aus `PageHeader` kommt dazu, wie auf „Heute“ und „Verträge“. Das ist die einzige Abweichung von
      CLAUDE.md §11 („höchstens drei je Screen“), und sie gilt für alle Hüllen-Seiten gleich.
    - Datum über Intl in `Europe/Berlin`: kurz „Do 16.03.“, lang „Donnerstag, 16. März“.
30. **Breiten und Touch:**
    - Jede Seite funktioniert in 1440 × 900 (volle Leiste), 1180 × 820 (schmale Spalte) und 820 × 1180 (Schublade).
    - Container-Queries mit Breakpoint-Tokens in `globals.css`, Muster `--container-heute-*`.
    - Jede Trefferfläche mindestens 44 px, auch Zellen, Chips und Punkte-Menüs.
31. **Zustände:**
    - Laden über `LoadingPulse` in der Form der Seite (Wochenraster als Skelett).
    - Leer über `EmptyState`, einladend und mit Aktion, zum Beispiel „Noch keine Räume. Lege den ersten Raum an.“
    - Fehler ruhig, SL-Code übersetzt.
    - Erfolg über `ToastBanner type="success"`.
    - Bestätigungen inline, nicht als Modal (CLAUDE.md), außer bei „Ganzer Termin fällt aus“. Dort zeigt eine
      Bestätigung, wie viele Kinder betroffen sind.

---

## Datenvertrag (Kurzform; SL1 schreibt ihn vollständig als Abschnitt 10 in `docs/api/DATENVERTRAG.md`)

Die Lesefunktionen liefern fertiges jsonb für genau einen Bildschirm, damit die Oberfläche nichts nachrechnet.

| Funktion | Wer | Liefert bzw. tut |
|---|---|---|
| `slots_woche(p_montag)` | Admin | Tage mit Betrieb oder Anlass, Uhrzeiten, je Zelle: Kapazität, belegt, Räume mit Coach, Art und belegt, ohne Raum, Coach fehlt, Fach-Mix, vergangen; Kopf: Plätze, belegt, Auslastung, ohne Raum, ohne Stammplatz |
| `slots_termin(p_datum, p_zeit_id)` | Admin | Räume (offen oder geschlossen, Coach, Stamm-Coach, Art, gemischt, Session-ID, Kinder), „Ohne Raum“, „Nicht dabei“ mit Eingang und rechtzeitig, vergangen, festgeschrieben |
| `slots_kinder()` | Admin | je Kind: Klasse, Fach, Paket, Laufzeit, Rhythmus, Stammplätze, Einheiten, verbraucht, geplant, Beginn, Stichtag, Vertrag läuft, Folgevertrag ab, Planbilanz (Art, Datum, Zahl, Abweichung) |
| `slots_kind(p_student_id)` | Admin | Kind, Vertragsauszug, Rhythmus, Stammplätze mit Historie, nächste und letzte Termine, Einheiten, Planbilanz |
| `slots_frei(p_takt, p_ab)` | Admin | Raster Wochentag × Zeit: freie Plätze als kleinster Wert der nächsten sechs Termine, Raum ja oder nein |
| `slots_planbilanz_vorschau(p_student_id, p_zeilen, p_ab)` | Admin | Planbilanz, Zahl der Termine, letzter Termin, Sperrgründe (Codes), ohne zu speichern |
| `slots_ziele(p_student_id, p_ausser_termin_id, p_eingang, p_ab, p_wochen)` | Admin | nur gültige Ziele für Umbuchen und Zusatz, mit freien Plätzen und dem Datum, das verdrängt würde. `p_eingang` (null bei Zusatz) entscheidet, ob die alte Einheit verbraucht ist |
| `slots_kandidaten(p_datum, p_zeit_id)` | Admin | Kinder, für die ein Zusatztermin hier alle Regeln erfüllt, mit offenen Einheiten und dem Datum, das verdrängt würde |
| `slots_coaches(p_montag)` | Admin | je Coach: Stammschichten, Stunden pro Woche, Abweichungen der Woche |
| `slots_einstellungen()` | Admin | Räume mit Zahl der Stammschichten, Uhrzeiten, Tage ohne Betrieb bis Ende des Schuljahrs |
| `slots_tag(p_datum)` | Admin | für „Heute“: Raum-Termine des Tages (Zeit, Raum, Coach, belegt, Session-ID), dazu alle `coaching_sessions` des Tages ohne `raum_id` (Einzel-Sessions, Testläufe gekennzeichnet), jede Session genau einmal; Absagen des Tages mit rechtzeitig |
| `naechste_termine(p_student_id, p_anzahl)` | Admin, Eltern des Kindes | die nächsten Termine über `naechster_termin` (Datum, Uhrzeit, festgeschrieben ja oder nein), für ParentDashboard und Akte |
| `slots_zaehler()` | Admin | Zähler für die Leiste: Kinder ohne Stammplatz (Vertrag läuft oder beginnt in 14 Tagen) + Kind-Termine ohne Raum in den nächsten 7 Tagen |
| `meine_einsaetze(p_montag)` | Coach | eigene Raum-Termine der Woche, Kinder (Name, Klasse, Fach), Session-ID, heute ja oder nein. Keine Absagen, kein Vertrag |
| `stammplatz_vergeben(p_student_id, p_zeilen, p_ab)` · `stammplatz_aendern(p_id, p_ab, …)` · `stammplatz_beenden(p_id, p_ab)` · `stammplaetze_weiterfuehren(p_student_id)` | Admin | E 28–33 |
| `termin_absagen(p_termin_id, p_eingang)` · `termin_umbuchen(p_termin_id, p_eingang, p_ziel_datum, p_ziel_zeit_id)` · `absage_zuruecknehmen(p_termin_id)` · `zusatztermin_buchen(p_student_id, p_datum, p_zeit_id)` · `termin_ausgefallen(p_termin_id)` · `termin_faellt_aus(p_datum, p_zeit_id)` | Admin | F, G, D 21–23 |
| `termin_raum_setzen(p_termin_id, p_raum_id)` · `termin_coach_setzen(p_datum, p_zeit_id, p_raum_id, p_coach_id)` (null = fällt aus) · `termin_raum_oeffnen(p_datum, p_zeit_id, p_raum_id, p_coach_id)` | Admin | D 19–20, H 49 |
| `stammschicht_anlegen(…)` · `stammschicht_beenden(p_id, p_ab)` · `raum_anlegen` · `raum_deaktivieren` · `slot_zeit_anlegen` · `slot_zeit_deaktivieren` | Admin | H 47–52, B 7–8 |
| `termin_session_anlegen(p_datum, p_zeit_id, p_raum_id)` | Admin, Coach (eigener Raum, selber Tag) | Entscheidung 14, gibt die Session-ID zurück |

---

## Prompt SL1 — Datenmodell, Planung und Regeln

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket SL1 des Bauauftrags Slots: das ganze Backend des Menüpunkts Slots, die
src/lib-Schicht dazu und vier gemeinsame Bausteine, die SL2 und SL3 danach parallel benutzen. Keine Seiten.

SCHRITT 0 (direkt nach dem Anlegen des Worktrees)
- In /mnt/c/Users/*/Downloads/ liegen Bauauftrag-Slots.md, Anforderung-Slots.md und slots-dummy.html. Prüfe, dass es
  jede genau einmal gibt und dass die erste Zeile von Bauauftrag-Slots.md "(Fassung 1)" enthält. Sonst abbrechen und
  melden.
- Kopiere alle drei nach docs/slots/. Erster Commit: "docs: Bauauftrag, Anforderung und Dummy Slots".
- Danach liest du nur noch die Dateien im Repo.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-sl1 -b feat/rasit-slots-sl1-datenmodell origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel laufen andere Pakete in eigenen Worktrees.
- PR gegen dev, niemals main. Nichts unter .github/. CLAUDE.md gilt vollständig (§4, §7, §8, §10, §12).
- Kein DDL und keine schreibende Abfrage gegen Produktion. Lesen nur über dbread.
- Migrationen nur unter supabase/migrations/, Zeitstempel nur im Bereich 20261013100000 bis 20261013135959. Vor dem
  Einspielen per dbread prüfen, dass jede Version frei ist.
- Tests nur in deiner Wegwerf-DB: Port 55450, ~/wegwerf-db-sl1, mit supabase/seed.sql wie in der CI,
  PGOPTIONS='-c search_path=public,extensions' (Muster tools/lena-board-wegwerf-db.sh). Jeder psql-Aufruf mit
  ausdrücklichem Datenbanknamen; nie edvance_shadow, nie Produktion.
- supabase/schema-erwartet.sql, schema.sql und schema_content.sql erst nach dem Einspielen anfassen.
- Bestehende Funktionen, die du ersetzt (einheiten_stand_intern, ggf. board_schueler), nimmst du aus Prod (dbread,
  pg_get_functiondef) als Ausgangspunkt. Signatur, SECURITY, search_path und Grants bleiben unverändert. Der Diff je
  Funktion kommt ins PR.
- Nicht anfassen: session_naechster_schritt samt Planer-Hilfen, SchedulePage. Die Session-Engine bekommt nur die zwei
  neuen Spalten an coaching_sessions und den Spiegel-Trigger aus Entscheidung 14. In quest_erzeugen,
  session_kind_kontext, coach_raum_live und session_abschluss_kind änderst du nur die Suche nach dem nächsten Termin
  (auf naechster_termin, Entscheidung 14). Alles andere an diesen Funktionen bleibt, ihre bestehenden Tests bleiben
  unverändert grün.
- Consensus-Check (CLAUDE.md §8): Vor dem PR prüft eine zweite, frische Instanz Migrationen, RLS und Rechte gegen
  die Entscheidungen 10–25. Ihre Befunde kommen ins PR.
- Keine Seiten. Im Frontend nur: src/types/slotplan.ts, src/lib/supabase/slotplan.ts (Aufrufe mit try/catch und
  SupabaseResult), src/lib/slots/fehler.ts (SL-Code -> i18n-Schlüssel, Texte in de/slots.json) und die gemeinsamen
  Bausteine aus P8. Höchstens 400 Zeilen je Datei.
- Geht etwas nicht oder widerspricht der Bestand einer Entscheidung: in docs/slots/offene-punkte-sl1.md, im PR
  nennen, weiterarbeiten, wo es ohne Raten geht. Nichts erfinden. STOPP nach dem PR.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/slots/Bauauftrag-Slots.md vollständig, vor allem "Was es schon gibt", die Entscheidungen 1–25 und den
   Datenvertrag.
2. docs/slots/Anforderung-Slots.md (Abschnitte A–K, Regeln und Grenzfälle, Abnahmefälle, Kontrollwerte K 60–62).
3. docs/schuelerakte/entscheidungen.md (4, 5, 6), die Migration 20260929100000_schuelerakte_basis.sql,
   einheiten_stand_intern und betriebstag in supabase/schema-erwartet.sql.
4. docs/session/Bauauftrag-Session-P1.md Entscheidung 2, docs/session/offene-punkte-x0.md Punkt 2 (coach_hat_platz),
   die Trigger an coaching_sessions und session_students (Löschschutz, Testlauf, ZG001).
5. docs/api/DATENVERTRAG.md Abschnitt 8 als Muster für Abschnitt 10.

PHASEN (je Phase ein Commit)
P0 Ist-Abgleich per dbread: Prüfe jede Aussage aus "Was es schon gibt". Zahl der echten (nicht ist_test) Kinder mit
   laufendem Vertrag, der coaching_sessions und session_students (echt und Testlauf), Inhalt von tiers und
   tier_laufzeiten, Spannweite von ferien_nrw und feiertage_nrw. Nur Anzahlen, keine Namen. Ergebnis in
   offene-punkte-sl1.md.
P1 Tabellen, Startinhalte (slot_zeiten 14–20 stündlich, slot_rhythmus nach Anforderung E 25 über tiers.name,
   Stellschraube slots_planbilanz_toleranz = 2), Indizes (u. a. höchstens ein aktiver Kind-Termin pro Tag,
   coaching_sessions eindeutig je raum_id und Zeitpunkt), RLS und Grants nach Entscheidung 24.
P2 Planung: Kandidaten-Termine je Stammplatz (Takt, Gültigkeit, betriebstag, Vertragszeitraum), termine_planen
   (Abgleich nach 11), Planbilanz (12), Trigger auf vertraege (22).
P3 Raum-Termine: geöffnete Räume je Datum und Zeit (Stammschicht, Abweichungen, Raum aktiv), Kapazität, Zuteilung (15).
P4 Schreibfunktionen aus dem Datenvertrag, jede mit Rollenprüfung, Lock (16), Regeln (17–19), SL-Codes (23) und
   termine_planen am Ende.
P5 Lesefunktionen aus dem Datenvertrag, je Bildschirm eine, ohne N+1.
P6 Festschreiben (14): termin_session_anlegen mit allen Regeln "nach dem Festschreiben", Spiegel-Trigger
   session_students -> kind_termine, einheiten_stand_intern nach 13, naechster_termin und naechste_termine, die vier
   SQL-Stellen darauf umstellen.
P7 src-Schicht und Datenvertrag Abschnitt 10 mit echtem JSON aus der Wegwerf-DB (erfundene Namen).
P8 Gemeinsame Bausteine unter src/components/edvance/ (ohne Fachlogik, mit Tests, Texte über i18n). Die bisherigen
   Aufrufer stellst du um, sie sehen danach genauso aus wie vorher (Vitest und Vorher/Nachher-Bild):
   - PlatzPunkte: aus der privaten Funktion in heute/HeuteImBetrieb.tsx. Mehrere Räume, je 5 Plätze, Überhang als
     "+n" in Handeln-Farbe, aria-label "4 von 5 Plätzen belegt". HeuteImBetrieb benutzt sie danach.
   - Reiterleiste: aus vertraege/menue/Reiterleiste.tsx. Generischer Schlüssel, Zähler optional, Ton für den Zähler
     (neutral oder Handeln). VertraegeMenuePage benutzt sie danach.
   - KennzahlenLeiste: aus heute/KennzahlenLeiste.tsx nach components/edvance/admin/, mit optionalem Ton je Feld
     (neutral oder Handeln) und der Container-Breite als Parameter. HeutePage benutzt sie danach.
   - WochenNavigation: "‹", Kalenderwoche mit Datumsspanne, "›", "Diese Woche", Pfeiltasten. Montag als ISO-Datum
     rein und raus, Berlin.

TESTS (pgTAP supabase/tests/slots_*.test.sql in der Wegwerf-DB, Vitest für die src-Schicht; Ausgabe ins PR)
1  K 60: alle sieben Fälle mit Terminzahl und Planbilanz, p_jetzt = Vertragsbeginn. Weicht ein Wert ab: Ursache
   belegen (z. B. Ferientabelle), nicht still angleichen.
2  K 61: die vier Fälle der 10-Uhr-Regel, dazu ein Termin am Montag nach der Zeitumstellung (27.03.2028, Eingang
   09:59 Sommerzeit).
3  K 62: Wochengrenze und "schon ein Termin an dem Tag".
4  Abnahmefälle 2–13 und 15 auf Datenebene, je ein Test mit der Nummer im Namen.
5  Abgleich: Eine Absage und eine Rücknahme ändern nur die betroffenen Zeilen. Ein Raum-Stift überlebt termine_planen.
   Ein Zusatztermin bei vollem Budget verdrängt den letzten Stammplatz-Termin.
6  Kapazität beim Speichern: zwei Buchungen auf den letzten Platz in zwei parallelen psql-Sitzungen, eine bekommt
   SL001 (kleines Skript, Ausgabe ins PR).
7  Festschreiben: idempotent, nur am Tag, Coach nur eigener Raum. Absage nach dem Festschreiben setzt beide Tabellen.
   "nicht erschienen" in der Session landet als unexcused in kind_termine.
8  Verbrauch: einheiten_stand zählt jede Buchung genau einmal (Slot-Termin festgeschrieben, Slot-Termin ohne Session,
   Einzel-Session ohne Kind-Termin), Testläufe nie. Bestehende Akten-Tests bleiben grün.
9  Widerruf und Kündigung: Stammplätze enden am Widerrufstag bzw. am Tag vor gekuendigt_zum, künftige Termine weg
   bzw. cancelled_by_us. termin_session_anlegen mit einem gekündigten Kind im Raum legt die Session an und lässt nur
   dieses Kind aus.
10 A/B-Woche über KW 52, 53 und 1. Feiertag und Pfingstferientag erzeugen keinen Termin. Ein Stichtag hinter
   max(ferien_nrw.bis) plant bis dorthin und meldet SL012 in der Planbilanz.
11 Rechte: Coach und Konto ohne Profil bekommen 42501 auf allen Admin-Funktionen. meine_einsaetze liefert nur den
   eigenen Raum und keine Absage. Ein Coach mit p_jetzt eines anderen Tages kann keine Session festschreiben.
   anon ohne EXECUTE. inv4_rls_coverage bleibt grün.
12 Überspringen: Ein Stammplatz-Datum, das per Zusatz voll ist, bekommt keinen Termin. Das nächste rückt nach, und
   die Planbilanz nennt es. Eine Einzel-Session-Buchung ohne Kind-Termin belegt Budget und sperrt den Tag.
13 Nächster Termin: quest_erzeugen findet bei 2× pro Woche den nächsten Slot-Termin vor dem Festschreiben (nicht
   Session-Tag + 7). session_abschluss_kind liefert naechste_session wieder.
14 Nach dem Festschreiben: Coach tauschen zieht coach_id nach, und die Vertretung liest die Session. Raum setzen
   verschiebt die Buchung zwischen zwei Sessions. Nach gestartet_am ergibt das SL011.
15 Alle bestehenden pgTAP-Dateien grün (session_r1.test.sql zählt 30 Stellschrauben); npm run typecheck, lint, test
   grün.

EINSPIELEN
Erst nach "SL1 einspielen": origin/dev einmischen (merge, kein rebase), Tests erneut, je Migration nach CLAUDE.md §10,
danach tools/schema-snapshot.sh, Abzug committen, per dbread prüfen (Tabellen, Funktionen, Stellschraube,
einheiten_stand für ein Testkind unverändert). Bei Fehler sofort anhalten und melden.

PR (gegen dev)
Titel: feat(slots-sl1): Datenmodell, Planung und Regeln der Slots
Inhalt: Kurzfassung, Tabellen und Funktionen, Diff je ersetzter Funktion, Testausgabe mit allen Kontrollwerten,
Befunde des Consensus-Checks, Link auf DATENVERTRAG Abschnitt 10, offene Punkte. Dann STOPP.
```

---

## Prompt SL2 — Admin-Oberfläche

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket SL2 des Bauauftrags Slots: die Admin-Oberfläche des Menüpunkts Slots.
Das Ziel ist ausdrücklich eine Oberfläche, die besser aussieht und sich besser bedienen lässt als der Klick-Dummy und
als der heutige Stundenplan. Sie soll auf dem Niveau von "Heute" und "Verträge" liegen.

VORAUSSETZUNG
SL1 ist in dev gemergt und eingespielt: docs/api/DATENVERTRAG.md Abschnitt 10, src/lib/supabase/slotplan.ts,
src/types/slotplan.ts und die gemeinsamen Bausteine PlatzPunkte, Reiterleiste, KennzahlenLeiste und WochenNavigation
unter src/components/edvance/ gibt es. Wenn nicht: melden und anhalten.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-sl2 -b feat/rasit-slots-sl2-oberflaeche origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel läuft SL3 in ../Edvancev1-sl3. In App.tsx änderst du
  nur die Admin-Routen der Slots, SL3 nur die Route /coach/einsaetze. Wer als Zweiter mergt, mischt vorher origin/dev
  ein (merge, kein rebase).
- Die gemeinsamen Bausteine aus SL1 benutzt du, statt eigene zu bauen. Fehlt einem eine Kleinigkeit, erweiterst du ihn
  rückwärtsverträglich und nennst das im PR.
- PR gegen dev, niemals main. Nichts unter .github/. CLAUDE.md gilt vollständig, vor allem §11 (nur Tokens, keine
  Inline-Styles, EdvanceCard, EmptyState, LoadingPulse, 44 px, kein gesperrter Knopf ohne Grund, Admin-Tabellen über
  EdvanceTable) und §12 (alle Texte über i18n, Namespace slots; Datum und Zahl über Intl).
- Reines Frontend. Keine Migration, keine Änderung in src/lib/supabase/** oder src/types/**. Einzige Ausnahme ist das
  Löschen der S10-Altlasten unten: lib/supabase/slots.ts, types/slots.ts und die Zeile `from './slots'` in
  types/index.ts. Fehlt etwas im
  Datenvertrag: offener Punkt in docs/slots/offene-punkte-sl2.md, die Stelle in der Oberfläche ruhig weglassen, nicht
  selbst nachbauen und nichts im Frontend nachrechnen, was der Server entscheidet (10-Uhr-Regel nur als Vorschau mit
  derselben Regel, Kapazität, Wochengrenze, Planbilanz).
- Keine neue Abhängigkeit. Höchstens 400 Zeilen je Datei. Neue Teile unter src/pages/admin/slots/ (Unterordner
  wochenplan/, termin/, kinder/, kind/, coaches/, einstellungen/, dialoge/), reine Logik als *.model.ts mit Tests.
- Dir gehören: die Routen /admin/slots*, /admin/slot-auswahl (Umleitung), der Eintrag in adminNav.ts, der Zähler
  "slots" in useAdminZaehler, und das Löschen von SlotsManagePage, SlotPickerPage, slots/SlotCalendarGrid,
  lib/slotGrid(.test).ts, lib/supabase/slots.ts und types/slots.ts (S10), sobald nichts mehr sie importiert
  (Entscheidung 25). Die S10-Tabellen in der Datenbank bleiben.
  Nicht anfassen: Coach-Seiten, HeutePage samt heute/, Akte (das macht SL3), SchedulePage außer Titel-Schlüssel.
- Bildschirmfotos nur aus der echten App mit Fake-Client und erfundenen Daten (Muster H3,
  docs/retros/2026-10-05-admin-h3-heute.md). Echte Daten nie.
- Offene Punkte in docs/slots/offene-punkte-sl2.md. STOPP nach dem PR.

KONTEXT (in dieser Reihenfolge lesen)
1. docs/slots/Bauauftrag-Slots.md, vor allem Abschnitt C (Entscheidungen 26–31). Er ist maßgeblich vor dem Dummy.
2. docs/api/DATENVERTRAG.md Abschnitt 10 und src/lib/supabase/slotplan.ts.
3. docs/slots/slots-dummy.html (Ablauf und Verhalten aller Bildschirme und Dialoge) und docs/slots/Anforderung-Slots.md.
4. Die Muster, nach denen sich alles richtet: src/pages/admin/HeutePage.tsx und heute/ (KennzahlenLeiste, ArbeitsListe,
   HeuteImBetrieb mit Platz-Punkten), VertraegeMenuePage und vertraege/menue/ (Reiterleiste, EdvanceTable,
   statusFarben.ts), leads/ (LeadFilterBar-Chips, CardMenu), components/edvance/shell/ (PageHeader, Container-Tokens),
   docs/screenshots/admin-h3/ und admin-h2/6-vertraege-*. Was ersetzt wird: docs/screenshots/admin-h4a/1-stundenplan-*,
   2-slots-*, 3-slot-auswahl-*.

UMFANG
1. Leiste und Routen: Der Eintrag "Stundenplan" wird "Slots" (/admin/slots, aktiv auch für /admin/slots* und
   /admin/schedule), mit Zähler aus slots_zaehler(). /admin/slot-auswahl leitet auf /admin/slots?reiter=kinder um.
   SchedulePage heißt "Einzel-Sessions und Testläufe" und ist über die Einstellungen erreichbar.
   Alle /admin/slots*-Routen nur für Admins. Ein Coach wird über ProtectedRoute mit
   umleitungFuer={{ coach: '/coach/einsaetze' }} umgeleitet (Abnahmefall 14, auch für direkte Adressen), mit Test.
2. Seitenrahmen /admin/slots: PageHeader mit Rubrik "Betrieb", Titel "Slots" und einem Satz zum Stand der gewählten
   Woche, z. B. "KW 11 · 62 von 130 Plätzen belegt · 3 Kinder ohne Stammplatz". Darunter die Reiterleiste Wochenplan ·
   Kinder (Zähler ohne Stammplatz, rot, wenn ein Vertrag schon läuft) · Coaches (Zähler Abweichungen dieser Woche) ·
   Einstellungen. Die Reiter stehen in der URL.
3. Wochenplan:
   - KennzahlenLeiste mit fünf Feldern: Plätze in besetzten Räumen · Belegt · Auslastung · Kinder ohne Raum
     (Handeln-Farbe bei > 0, Sprung zum ersten betroffenen Termin) · Kinder ohne Stammplatz (Sprung in die gefilterte
     Kinder-Liste).
   - Eine EdvanceCard mit dem Raster. Im Kopf rechts die Wochennavigation: "‹", "KW 11 · 13.–17. März 2028", "›",
     "Diese Woche". Pfeiltasten links und rechts blättern.
   - Die Kopfzeile mit Wochentag und Datum bleibt beim Scrollen stehen. "heute" ist hervorgehoben (Fläche
     primary-light). Vergangene Zellen sind gedämpft, bleiben aber klickbar zur Ansicht.
   - Zelle (ganze Zelle ist der Klick, mind. 44 px):
       ┌───────────────────────────┐
       │ 8 / 10          M 5 · D 2 · E 1 │   Zahl: belegt fett, Kapazität grau; Fach-Mix rechts, text-xs
       │ ●●●●●  ●●●○○                    │   je geöffnetem Raum fünf Punkte; mehr Kinder als Plätze: "+2" in Handeln-Farbe
       │ Coach fehlt · 2 ohne Raum       │   nur bei Handlungsbedarf, sonst keine dritte Zeile
       └───────────────────────────┘
     Fläche und 3-px-Rand links nur bei Zustand: ab 90 % Achtung, überbucht oder Coach fehlt Handeln. Sonst weiß.
   - Leere Zelle: ruhig, nur ein Strich, Hinweis "kein Raum besetzt" beim Darüberfahren und für Screenreader.
     Zeitzeilen, die in der ganzen Woche keinen geöffneten Raum haben, fallen zu einer schmalen Zeile zusammen
     ("14:00 · kein Raum besetzt"). Ein Schalter "leere Zeiten zeigen" klappt sie auf.
   - Tag ohne Betrieb: Die ganze Spalte ist grau, der Anlass steht einmal oben ("Osterferien", "Christi Himmelfahrt").
   - Die Legende steht in einer Zeile im Kartenfuß.
   - Unter der Container-Breite --container-slots-woche (Token, ca. 760 px) wird statt des Rasters ein Tag gezeigt:
     ein Umschalter Mo–Fr und darunter die Uhrzeiten als Zeilen.
4. Termin (/admin/slots/termin/:datum/:zeitId):
   - PageHeader: Rubrik "Slots · KW 11", Titel "Donnerstag, 16. März · 16:00–17:00", Satz "10 Kinder · 5 Plätze ·
     1 von 2 Räumen geöffnet", Zurück "Wochenplan" (zur selben Woche). Primäraktion "Kind hinzufügen". Daneben ein
     "…"-Menü mit "Raum öffnen" und "Ganzer Termin fällt aus".
   - Reihenfolge der Karten: zuerst "Ohne Raum", wenn es Kinder ohne Raum gibt (Handeln-Fläche; je Kind genau zwei
     Knöpfe, "Umbuchen" und "Ausgefallen (durch uns)", beide sekundär; ein Satz, was zu tun ist). Dann die Räume nebeneinander:
     zwei Spalten ab --container-slots-raeume, sonst untereinander. Am Ende "Nicht dabei".
   - Raum-Karte: Kopf mit Raumname, Coach-Auswahl (SELECT_MD, nur für diesen Termin, mit Option "fällt aus"),
     Abzeichen "Vertretung" bzw. "gemischt", Platz-Punkte und "4/5". Je Kind eine Zeile: Name, "Kl. 9 · M", Abzeichen
     nur, wenn es nicht der Stammplatz ist ("umgebucht von Di 14.03.", "Zusatz"), rechts das "…"-Menü.
     Ein geschlossener Raum (Coach fällt aus) ist gestrichelt und gedämpft: "Geschlossen · Stammschicht Jana Keller",
     dazu Vertretung wählen.
   - "Nicht dabei": Name, Zustand (abgesagt, unentschuldigt, ausgefallen), "Eingang Mi 18:40", rechtzeitig oder nicht,
     "Zurücknehmen", solange der Termin nicht begonnen hat.
   - Am Tag des Termins je Raum "Session öffnen" (termin_session_anlegen, danach Link zur Live-Sicht). Ein Satz:
     "Die Raumzuteilung wird beim Öffnen der Session festgeschrieben."
   - Vergangene Termine: nur Ansicht, Anwesenheit als Abzeichen, keine Aktionen, Hinweis "Anwesenheit aus der Session".
     Termine ohne Anwesenheit sind als Achtung markiert.
5. Kinder (Reiter):
   - Oben "Ohne Stammplatz" im Stil der ArbeitsListe. Je Kind: Name, "Kl. 8 · M", Paket und Rhythmus, "läuft seit
     01.03." (Handeln) bzw. "beginnt am 01.04." (neutral). Ein Knopf "Stammplatz vergeben" (Stil wie "Termin" auf
     Heute). Bei einem Folgevertrag heißt der Knopf "Wie bisher weiterführen (Di 16:00)", und "Stammplatz vergeben"
     wandert ins "…"-Menü.
   - Darunter Filter-Chips (Alle · Kein Stammplatz · Reicht nicht · Einheiten übrig · Aufgebraucht · Passt) und die
     Suche.
   - Dann eine EdvanceTable mit diesen Spalten:
     - Kind (Name, darunter Klasse · Fach)
     - Paket (Basic · Halbjahr, darunter der Rhythmus)
     - Stammplätze ("Di 16:00", "Do 17:00 · A")
     - Einheiten: Stapelbalken mit verbraucht (primary), geplant (primary-light) und frei (Rand), daneben "27 / 38",
       darunter "10 geplant"
     - Stichtag
     - Planbilanz-Abzeichen
   - Sortierung nach Handlungsbedarf (kein Stammplatz, reicht bis, ohne Termin, aufgebraucht, passt), dann nach Namen.
     Ein Klick auf
     eine Zeile öffnet das Kind.
   - Unter --container-slots-tabelle wird aus jeder Zeile eine Karte mit denselben Feldern.
6. Kind (/admin/slots/kind/:studentId):
   - PageHeader: Rubrik "Slots · Kinder", Titel Name, Satz "Klasse 8 · Englisch · Premium Halbjahr · 1× pro Woche +
     14-täglich", Zurück "Kinder", Primäraktion "Zusatztermin buchen", Link "Akte".
   - Zwei Spalten ab --container-slots-kind, sonst untereinander.
   - Rechts (steht beim Scrollen): Karte "Einheiten" mit Stapelbalken und drei Zahlen (verbraucht, geplant, gesamt),
     darunter das Planbilanz-Abzeichen und der Satz dazu (Entscheidung 12, Wortlaut nach Anforderung J 57). Karte
     "Aus dem Vertrag" mit Paket, Laufzeit, Einheiten, Beginn und Stichtag, nur Ansicht, Link "Vertrag öffnen".
   - Links Karte "Stammplätze": die aktuellen mit "Ändern ab …" und "Beenden" (inline mit Datum), die früheren
     zugeklappt "Frühere Stammplätze (1)".
   - Karte "Nächste Termine": zuerst 8, dann "alle zeigen". Je Zeile Datum, Uhrzeit, Zustand und das "…"-Menü (Absage,
     Umbuchen).
   - Karte "Letzte Termine" mit der Anwesenheit.
7. Coaches (Reiter):
   - Links die Liste der Coaches: Name, Stunden pro Woche, Tage als Chips, Abzeichen für die Abweichungen dieser Woche.
   - Rechts der gewählte Coach als Wochenraster (Mo–Fr × Uhrzeiten). Eine Stammschicht ist ein Chip mit dem Raum.
   - Ein Tippen auf eine leere Zelle legt an: Raum wählen, inline. Ein Tippen auf einen Chip entfernt nach einer
     Bestätigung inline. SL009 erscheint als Satz an der Zelle.
   - Darunter "Abweichungen diese Woche" mit Links in den Termin.
   - Unter --container-slots-coaches stehen Liste und Raster untereinander.
8. Einstellungen (Reiter): Karte "Räume" (aktiv ab, inaktiv ab, Zahl der Stammschichten, "Deaktivieren ab …" inline,
   "Raum hinzufügen"). Karte "Uhrzeiten" (Chips, hinzufügen, deaktivieren ab). Karte "Tage ohne Betrieb bis Ende des
   Schuljahrs" (nur Ansicht, Ferien als Zeitraum, Feiertage als Tag, mit dem Satz zum Vertragsende). Karte
   "Einzel-Sessions und Testläufe" mit Link auf /admin/schedule.
9. Dialoge (Modal, Fokus auf dem ersten Feld, Escape schließt):
   - Absage: Kind und Termin; Eingang (Datum und Uhrzeit, vorbelegt mit jetzt in Berlin); ein Satz als Vorschau, der
     sich beim Ändern sofort umstellt ("Rechtzeitig, die Einheit bleibt offen." bzw. "Nach 10:00 Uhr: unentschuldigt,
     die Einheit ist verbraucht.").
   - Umbuchen: Absage-Teil wie oben, dazu die Ziele der nächsten vier Wochen als kleines Raster (Wochen ×
     Mo–Fr, je Ziel ein Chip mit Uhrzeit und "3 frei"). Nur gültige Ziele aus slots_ziele. Bei später Absage der Satz,
     dass der neue Termin eine weitere Einheit braucht und welcher Termin dann wegfällt.
   - Kind hinzufügen (Zusatztermin, vom Termin aus): durchsuchbare Liste aus slots_kandidaten mit Klasse, Fach und
     offenen Einheiten, mit Hinweis auf den Termin, der wegfällt.
   - Zusatztermin buchen (vom Kind aus): wie Umbuchen ohne Absage-Teil.
   - Raum öffnen: Raum und Coach.
   - Stammplatz vergeben und ändern, zweispaltig ab --container-slots-dialog:
     - Links die Zeilen nach dem Rhythmus: Tag, Uhrzeit und Takt als Umschalter (wöchentlich, A-Woche, B-Woche).
       Darunter "gültig ab".
     - Rechts das Raster der freien Plätze aus slots_frei. Ein Tippen übernimmt den Slot in die aktive Zeile. "voll"
       und "kein Raum" erscheinen gedämpft und sind nicht wählbar.
     - Unten die Planbilanz-Vorschau mit Satz.
     - Speichern ist gesperrt, solange slots_planbilanz_vorschau Sperrgründe liefert. Die Gründe stehen als Liste
       direkt unter dem Knopf (Abnahmefall 9). Übersprungene Daten (Entscheidung 11) stehen als Hinweis daneben,
       sperren aber nicht.
   - Ganzer Termin fällt aus: Bestätigung mit der Zahl der betroffenen Kinder, Satz "Die Einheiten bleiben offen".
   Nach jedem Speichern: ToastBanner, die Ansicht lädt neu, der Fokus bleibt sinnvoll.
10. Fehler: Jeder SL-Code als ruhiger Satz an der Stelle, an der er entsteht, über src/lib/slots/fehler.ts.

TESTS (Vitest, Ausgabe ins PR)
1  *.model.ts: Zellzustand (normal, ab 90 %, überbucht, Coach fehlt, kein Raum, kein Betrieb, vergangen),
   Zusammenfalten leerer Zeitzeilen, Sortierung und Filter der Kinder, Reiter <-> URL, Wochenwechsel über den
   Jahreswechsel.
2  Absage-Dialog: Vorschau wechselt zwischen 09:59 und 10:00 (K 61). Gesendet wird der Eingang, nicht das Ergebnis.
3  Stammplatz-Dialog: Speichern gesperrt mit den Gründen aus der Vorschau (Abnahmefall 9). Ein Tippen ins Raster
   übernimmt den Slot.
4  Umbuchen zeigt nur Ziele aus slots_ziele (Abnahmefall 5 und 6).
5  Termin: "Ohne Raum" steht zuerst und nur, wenn es Kinder ohne Raum gibt. Vergangener Termin ohne Aktionen.
6  Keine hart codierten Strings (bestehende i18n-Prüfung), alle SL-Codes haben einen Text.
7  Leiste: Slots aktiv auf /admin/slots*, /admin/schedule; Umleitung /admin/slot-auswahl. Bestehende Hüllen-Tests
   angepasst, nicht gelöscht.
8  npm run typecheck, lint, test grün.

GESTALTUNGS-ABNAHME
- Daten für die Bildschirmfotos wie im Dummy: Montag, 13.03.2028, 09:12 Uhr. Am Donnerstag 16 Uhr fällt der Coach in
  Raum 2 aus (fünf Kinder ohne Raum). Ein Kind ist von Dienstag auf Mittwoch umgebucht, eine Absage ist um 07:55 Uhr
  eingegangen, am Freitag gibt es einen Zusatztermin. Ein Kind hat einen laufenden Vertrag ohne Stammplatz, zwei
  beginnen am 01.04. Ab 10.04. sind Osterferien. Die Kinder zeigen alle Planbilanz-Arten. Alle Namen sind erfunden.
- Bildschirmfotos nach docs/screenshots/slots-sl2/ in 1440 × 900, 1180 × 820 und 820 × 1180: Wochenplan, Termin mit
  Ausfall, Termin vergangen, Kinder, Kind, Coaches, Einstellungen, Stammplatz-Dialog, Umbuchen-Dialog. Dazu je
  Bildschirm der Dummy im selben Zustand (1440 × 900) und, wo es ihn gibt, der heutige Stand aus
  docs/screenshots/admin-h4a/.
- Danach prüft eine frische Instanz (nicht du) nur mit Abschnitt C des Bauauftrags und den Bildschirmfotos gegen diese
  Liste:
  - kein Navy-Band
  - ein Seitenkopf
  - höchstens eine Primäraktion im Seitenkopf
  - Farbe nur mit Bedeutung (Entscheidung 28)
  - keine Zelle "kein Raum besetzt" in Serie
  - je Zeile höchstens ein sichtbarer Knopf plus "…"-Menü, Ausnahme "Ohne Raum" mit genau zwei (Entscheidung 27)
  - 44 px
  - nichts abgeschnitten oder überlappend in 820 × 1180
  - leere Zustände einladend
  - Zahlen in tabular-nums
  - höchstens drei Schriftgrößen im Arbeitsbereich

  Befunde beheben oder begründet ins PR.

PR (gegen dev)
Titel: feat(slots-sl2): Admin-Oberfläche der Slots
Inhalt: Kurzfassung, Tabelle "heute | Dummy | neu | warum" je Bildschirm mit den Bildschirmfotos nebeneinander, Ergebnis der
Gestaltungs-Abnahme, gelöschte Altlasten (grep-Beleg, dass nichts mehr importiert), Testausgabe, offene Punkte.
Dann STOPP.
```

---

## Prompt SL3 — Coach-Sicht, „Heute“ und Akte

```text
Du arbeitest im Repo Edvancev1 (WSL). Paket SL3 des Bauauftrags Slots: Was Coaches und die Startseite von den Slots
sehen.

VORAUSSETZUNG
SL1 ist in dev gemergt und eingespielt (docs/api/DATENVERTRAG.md Abschnitt 10, src/lib/supabase/slotplan.ts, die
gemeinsamen Bausteine PlatzPunkte, KennzahlenLeiste und WochenNavigation unter src/components/edvance/). Wenn nicht:
melden und anhalten.

LEITPLANKEN (nicht verhandelbar)
- Eigener Worktree: git fetch && git worktree add ../Edvancev1-sl3 -b feat/rasit-slots-sl3-coach-heute origin/dev
  (existiert er: weiterverwenden). Nur dort arbeiten. Parallel läuft SL2 in ../Edvancev1-sl2. In App.tsx änderst du
  nur die Route /coach/einsaetze, SL2 die Admin-Routen der Slots. Wer als Zweiter mergt, mischt vorher origin/dev ein
  (merge, kein rebase).
- Die gemeinsamen Bausteine aus SL1 benutzt du, statt eigene zu bauen.
- PR gegen dev, niemals main. Nichts unter .github/. CLAUDE.md gilt vollständig (§11, §12).
- Reines Frontend. Keine Migration, keine Änderung in src/lib/supabase/** oder src/types/**. Fehlt etwas: offener
  Punkt in docs/slots/offene-punkte-sl3.md, nicht nachbauen.
- Dir gehören: coachNav.ts, die Route /coach/einsaetze, CoachDashboard und seine Teile, ParentDashboard (nur die
  nächste Session), HeutePage samt heute/, die Akte-Kacheln SessionsKachel und EinheitenKachel. Nicht anfassen:
  /admin/slots* samt ihren Routen und Umleitungen, adminNav.ts, useAdminZaehler (SL2), die Live-Sicht und alles unter
  src/pages/coach/live/ (C-Pakete).
- Gestaltung nach Abschnitt C des Bauauftrags. Coach-Seiten sprechen die Coach-Sprache (flach, wie die Coach-Hülle
  H6). Der Coach sieht nie Absagen, Umbuchungen, Stammplätze, Planbilanz, Paket oder Vertrag (Anforderung I 54).
- Bildschirmfotos nur mit Fake-Client und erfundenen Daten (Muster H3). STOPP nach dem PR.

KONTEXT
1. docs/slots/Bauauftrag-Slots.md (Entscheidungen 14, 15, 20, 26–31), docs/slots/Anforderung-Slots.md Abschnitt I,
   Dummy-Ansicht "Coach" in docs/slots/slots-dummy.html (oben rechts umschalten).
2. docs/api/DATENVERTRAG.md Abschnitt 10 (meine_einsaetze, termin_session_anlegen, slots_tag).
3. src/components/edvance/coach/ (coachNav, CoachLayout), src/pages/coach/CoachDashboard.tsx und SessionCard.tsx,
   src/pages/admin/HeutePage.tsx und heute/ (HeuteImBetrieb, KennzahlenLeiste, useHeuteDaten), docs/screenshots/coach-h6/
   und admin-h3/.

UMFANG
1. Coach "Meine Einsätze" (/coach/einsaetze, Leisten-Eintrag "Einsätze" in der Gruppe Arbeit):
   - PageHeader mit Titel "Meine Einsätze" und Satz "KW 11 · 5 Einsätze · 12 Kinder". Wochennavigation wie im
     Wochenplan.
   - Die Einsätze stehen nach Tagen gruppiert, der Tageskopf bleibt beim Scrollen stehen. Je Einsatz eine Karte:
     Uhrzeit groß (tabular), Raum, Platz-Punkte, die Kinder mit Name, Klasse und Fach-Kürzel.
   - "Session öffnen" nur am Tag des Einsatzes: termin_session_anlegen, dann /coach/session/:id/live. An anderen Tagen
     kein Knopf, nur der Satz "Öffnen am Tag des Einsatzes".
   - Ein Einsatz ohne Kinder ist eine ruhige Zeile, keine volle Karte.
   - Leer: EmptyState "Diese Woche hast du keine Einsätze."
2. Coach "Heute" (CoachDashboard): Die Einsätze von heute kommen aus meine_einsaetze und haben "Session öffnen".
   Bereits festgeschriebene und Einzel-Sessions bleiben sichtbar, aber ohne Doppelung (gleiche Session-ID nur einmal).
   Die Kennzahl "nächste Session" nimmt den nächsten Einsatz aus meine_einsaetze, auch wenn er noch nicht
   festgeschrieben ist.
3. Admin "Heute":
   - "Heute im Betrieb" liest alles aus slots_tag: die Raum-Termine (Zeit, Raum, Coach, Platz-Punkte) und die
     Einzel-Sessions und Testläufe ohne Raum-Termin (gekennzeichnet). Jede Session erscheint genau einmal. Die LSA
     bleiben wie bisher. Der Fußlink heißt "Zum Wochenplan" (/admin/slots).
   - Neuer Block "Absagen heute": Name, Uhrzeit, "abgesagt um 08:12", Abzeichen rechtzeitig (strength) oder
     unentschuldigt (coach-emergency), darunter ein Satz zur 10-Uhr-Regel. So zeigt es der Hüllen-Dummy.
   - Die Kennzahl "Coaches" zählt "heute im Einsatz" aus den Raum-Terminen.
4. Akte: SessionsKachel bekommt den Link "Termine planen" (/admin/slots/kind/:id, nur Admin). EinheitenKachel zeigt
   das Planbilanz-Abzeichen aus slots_kind, nur Admin. Coaches sehen in der Akte nichts Neues.
5. Eltern: Die nächste Session im ParentDashboard kommt aus naechste_termine, damit sie vor dem Festschreiben nicht
   leer bleibt (Entscheidung 14).

TESTS (Vitest, Ausgabe ins PR)
1  Meine Einsätze: Gruppierung nach Tagen, "Session öffnen" nur heute, keine Absage- oder Vertragsfelder im Modell.
2  CoachDashboard: keine Doppelung zwischen Plan und festgeschriebener Session.
3  Heute im Betrieb und Absagen heute aus slots_tag; leere Liste zeigt "nichts offen" wie die übrigen Listen.
4  Nächste Session: CoachDashboard und ParentDashboard zeigen einen Slot-Termin, der noch nicht festgeschrieben ist.
5  Bestehende Tests von Heute, Coach-Hülle, Eltern und Akte angepasst, nicht gelöscht; npm run typecheck, lint, test
   grün.

ABNAHME
Bildschirmfotos nach docs/screenshots/slots-sl3/ in 1440 × 900, 1180 × 820 und 820 × 1180: Meine Einsätze, Coach
Heute, Admin Heute mit Absagen. Die Gestaltungs-Abnahme durch eine frische Instanz läuft wie in SL2.

PR (gegen dev)
Titel: feat(slots-sl3): Meine Einsätze, Session aus dem Plan, Heute mit Absagen
Inhalt: Kurzfassung, Bildschirmfotos, Testausgabe, offene Punkte. Dann STOPP.
```

---

## Abnahme gesamt (Rasit)

1. Auf dem Laptop und auf dem echten iPad (quer und hoch) eine Woche durchklicken. Dabei einen Stammplatz vergeben,
   eine Absage vor und nach 10 Uhr erfassen, umbuchen und einen Coach ausfallen lassen.
2. Im Termin des Ausfalls „Ohne Raum“ auflösen und danach am selben Tag „Session öffnen“. Die Coach-Live-Sicht zeigt
   genau die Kinder des Raums.
3. Die Akte zeigt dieselben Einheiten wie die Kinder-Liste der Slots.
4. Tolunay prüft die Planbilanz der Kontrollfälle gegen ihre Anforderung (K 60).
