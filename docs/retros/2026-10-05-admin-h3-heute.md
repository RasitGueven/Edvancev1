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
- „Erstgespräche“ = status `contacted` mit Termin ab Tagesbeginn (Bauauftrag). `onboarding_scheduled` steht
  auf dem Board in derselben Spalte, hier nicht.
- LSA-Fertig-Signal: der Name einer fertigen Analyse verlinkt den Report, der Knopf heißt wie auf dem Board
  („Vertragsprozess“). Die Analysen von heute stehen in „Heute im Betrieb“ mit Pille „LSA“.
- Freigabe-Knopf führt nach `/admin/authoring?bereich=lsa`; Stufe aus `authoring:board.stufe.*`.
- Lena-Board (`rueckfrage`) war beim Bau nicht in dev → keine Rückfragen-Zeile.
- `.admin-cta-gold` wurde schon vor H3 von keiner Seite mehr benutzt; es gab keinen Knopf zu ersetzen.

## Offen
- Screenshots in drei Größen fehlen: Der Vite-Harness mit Fake-Client über einen lokalen Prod-Abzug wurde
  vom Auto-Mode-Classifier abgelehnt. Rasit macht sie im Browser oder gibt den Harness frei.
- Absagen in „Heute im Betrieb“ kommen mit dem Slots-Feature.
