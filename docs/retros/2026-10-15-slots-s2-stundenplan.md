# Retro Slots S2 — Stundenplan aufräumen und Sofort-Dialog (15.10.2026)

Branch `feat/rasit-slots-s2-stundenplan` ab `origin/dev` 2d5d405 (S1 gemergt, in Prod eingespielt und per dbread geprüft).

## Gebaut

- **Reiter Stundenplan** (`src/pages/admin/slots/stundenplan/`): `StundenplanReiter` lädt `stundenplan_woche` für die
  Woche aus der URL, gruppiert nach Berliner Tag, filtert nach Leitung. `SessionKarte` (aus der alten `SchedulePage`
  herausgelöst) zeigt Uhrzeit, Raum, Leitung mit „Admin“, Testlauf, Kinder mit „Test“, Status und Live-Sicht;
  „Kinder zuweisen“ nutzt `kinder_buchbar(Tag, Session)`. `SessionPlanen` legt spätere Einzel-Sessions mit Raum aus der
  Raumliste an (kein Freitext).
- **KindAuswahl** (geteilt): alle Kinder mit Suchfeld, nicht buchbare ausgegraut mit Grund aus `slots.json`, Datum über
  `Intl.DateTimeFormat`, höchstens 5 je Raum.
- **Sofort-Dialog** (`src/pages/admin/slots/sofort/`): Knopf im Slots-Kopf und in der Akte (Kind vorgewählt). Leitung
  vorbelegt mit dem angemeldeten Admin, Raum Pflicht, „Starten“ gesperrt mit Satz bei Mischung, ohne Kind, ohne Leitung
  oder Raum. Ablehnungen als Satz mit Namen des Kindes (Detail = student_id).
- `/admin/schedule` leitet auf `/admin/slots?reiter=stundenplan`; `SchedulePage` und der Link unter Einstellungen
  entfallen; `admin.json` `schedule.*` gelöscht.

## Entscheidungen und Abweichungen

Siehe `docs/slots/offene-punkte-s2.md`, Punkte 1–7 (ein primärer Knopf je Bildschirm, Grenze 5 in der Karte,
Coach-Filter nicht in der URL, Text `vertrag_ab`).

## Gelernt

- Ein Hook-Mock, der bei jedem Aufruf ein neues `user`-Objekt liefert, ließ den Dialog in einer Endlosschleife laden
  (Vitest-Worker lief in den Speicherfehler). Abhängigkeit ist jetzt `user?.id`, nicht das Objekt.
- jsdom löst `onChange` auch an einer gesperrten Checkbox aus; die Wahl prüft die Sperre deshalb selbst.

## Offen

`docs/slots/offene-punkte-s2.md`, Punkte 8–14.
