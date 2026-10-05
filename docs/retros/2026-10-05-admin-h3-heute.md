# Retro 2026-10-05 — Admin-Hülle H3: Startseite „Heute“

## Gebaut
- `/admin` zeigt `HeutePage` statt der Kacheln: Kopf mit Datum, Gruß und Summe offener Punkte,
  Primäraktion „Neuer Lead“ (`/admin/leads?neu=1` öffnet das Formular), Kennzahlen-Leiste (fünf Felder),
  sechs Arbeitslisten (`heute/ArbeitsListe`) und „Heute im Betrieb“.
- Neue Lesefunktionen nur in `src/lib/supabase/heute.ts`: `listSessionsHeute()` (eine Abfrage, Coach und
  Teilnehmer eingebettet, Berliner Tag), `listAufgabenInReview()` (dieselbe Menge wie `countTasksInReview`,
  mit `skill_key`), `berlinTagesGrenzen()`.
- Name in Gruß und Leistenfuß aus `profiles.full_name` (`shell/useProfilName` über `profilNamen`).
- Entfernt: `AdminDashboard`, `AdminWidgetGrid`, `LsaTodayCard`, Kartenvariante `admin-tile`, alle `.admin-*`-Klassen
  in `globals.css`, i18n `admin:dashboard.*` und `report:today.*`.

## Entscheidungen
- Listen benutzen dieselben Quellen und Mengen wie ihr Bereich: Lead-Status, `auslaufende()`/`imVerzug()`,
  `summen()` für Kennzahlen, `board_schueler().ampel` (nur aktive Akten, wie die Board-Vorgabe).
- „Erstgespräche“ = status `contacted` und `onboarding_scheduled` (wie die Board-Spalte „Termin vereinbart“)
  mit Termin ab Tagesbeginn (Nachtrag zu PR 207).
- LSA-Fertig-Signal: der Name einer fertigen Analyse verlinkt den Report, der Knopf heißt wie auf dem Board
  („Vertragsprozess“). Die Analysen von heute stehen in „Heute im Betrieb“ mit Pille „LSA“.
- Freigabe-Knopf führt nach `/admin/authoring?bereich=lsa`; Stufe aus `authoring:board.stufe.*`.
- Lena-Board (`rueckfrage`) kam mit PR 208 nach dev → Nachtrag H3-N (unten).
- `.admin-cta-gold` wurde schon vor H3 von keiner Seite mehr benutzt; es gab keinen Knopf zu ersetzen.

## Nachträge (PR 207)
- Erstgespräche zählen `contacted` und `onboarding_scheduled` wie die Board-Spalte.
- Screenshots aus der echten App mit Fake-Client und erfundenen Beispieldaten (`docs/screenshots/admin-h3/`).
  Dabei gefunden: `Intl.DateTimeFormat('de-DE', { hour })` liefert „10 Uhr“, `Number()` daraus NaN → der Gruß
  war immer „Guten Abend“. Jetzt `berlinStunde()` über `formatToParts`, mit Test.

## Nachtrag H3-N (nach PR 208)
- Rebase auf dev ohne Konflikte.
- „Inhalte freigeben“: Zeile „n Rückfragen von Lena“ mit Pille „Unsicher“, oben in der Liste, Ziel
  `/admin/authoring/liste?status=rueckfrage`. Neue Lesefunktionen `listAufgabenFuerAdmin()` und
  `countAufgabenFuerAdmin()` (review + rueckfrage) in `heute.ts`; der Leisten-Zähler „Item-Pflege“ zählt beides.
- Mit Freigabe von Rasit: `AuthoringItemsPage` liest `?status=` als Startwert des Status-Filters; unbekannte Werte
  (auch Prototyp-Namen wie `toString`) werden ignoriert. Sonst keine Item-Pflege-Datei geändert.

## Offen
- Absagen in „Heute im Betrieb“ kommen mit dem Slots-Feature.
