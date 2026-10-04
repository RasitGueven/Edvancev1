# Erstgespräch nachziehen (W5-c)

Zwei Teile: das aktuelle Thema eines Leads in einem Schritt setzen und eine
Terminbestätigung an die Eltern. Branch `feat/erstgespraech-nachziehen`.

## Teil 1 – Thema in einem Schritt

**Vorher.** `setAktuellesThema` (`src/lib/supabase/themen.ts`) machte zwei Aufrufe:
das alte `aktuell` desselben Fachs löschen, dann das neue per Upsert schreiben.
Brach der zweite Aufruf ab, hatte der Lead kein Thema mehr.

**Jetzt.** RPC `lead_thema_setzen(p_lead_id, p_fach, p_thema_key, p_quelle default 'gespraech')`
(Migration `20261004001333`). Security definer, eine Transaktion.

Entscheidungen:

- **Das alte `aktuell` wird gelöscht, nicht auf `behandelt` gesetzt.** Genau das hat
  die Oberfläche bisher getan. Ob ein Thema als behandelt gilt, entscheidet weiter der
  Schulplan-Abgleich in `useThemenAuswahl` (`abgleichBehandelt`), nicht dieser Schritt.
  Das Verhalten bleibt gleich, es läuft nur atomar.
- **War das neue Thema schon `behandelt`, wird diese Zeile umgestellt.** Das entspricht
  dem bisherigen Upsert auf `(lead_id, thema_key)`: Status `aktuell`, Quelle neu,
  `angelegt` = jetzt.
- **`p_thema_key null` entfernt das aktuelle Thema.** Die Oberfläche kennt das heute
  nicht (ein Klick auf das aktuelle Thema tut nichts). Die Funktion kann es trotzdem,
  weil es nur eine Zeile kostet und „entfernen“ sonst wieder zwei Schritte bräuchte.
  An der UI ist dafür nichts gebaut.
- **Rollenprüfung** wie bei der RLS-Regel `lead_themen_admin_all`: `get_my_role() = 'admin'`,
  sonst 42501. Ausführen darf nur `authenticated`, `anon` und `public` nicht.
  Das Muster ist dasselbe wie bei `vertrag_versand_protokollieren`.
- `useThemenAuswahl` blieb unverändert, weil die Signatur von `setAktuellesThema`
  kompatibel ist (neu: `themaKey` darf `null` sein, optional `quelle`). Der bestehende
  Komponententest `ThemenAuswahl.test.tsx` läuft unverändert grün. Neu ist
  `themen.test.ts`: ein RPC-Aufruf, kein Tabellenzugriff daneben, `null` wird
  durchgereicht, Fehlermeldung kommt an.

Belege: pgTAP `supabase/tests/w5_lead_thema_setzen.test.sql` mit 12 Zusicherungen
(setzen, ersetzen, entfernen, fremde Rolle, atomar bei Fehlschlag). Lokal gegen die
Wegwerf-DB mit pgTAP aus `postgresql-18-pgtap` gelaufen. Dazu das Prüfskript
`supabase/checks/lead_thema_setzen.PRUEFUNG.sql`.

## Teil 2 – Terminbestätigung

**Der Bestand reichte nicht ohne Änderung.** `mail_senden` hängt fest an `vertrag_id` und
protokolliert in `vertrag_versand` (FK auf `vertraege`). Vor dem Erstgespräch gibt es
keinen Vertrag. Die Edge Function wird deshalb erweitert, Deploy siehe unten.

Entscheidungen:

- **Neuer Anlass in `mail_senden` statt einer neuen Function.** Anmeldung, Admin-Prüfung,
  Absender `hello@` und Graph-Versand bleiben an einer Stelle. Der Lead-Zweig liegt in
  `mail_senden/termin.ts`, `index.ts` verzweigt nach der Autorisierung auf
  `anlass = 'terminbestaetigung'` mit `lead_id`. Die drei Vertragsanlässe bleiben
  unverändert.
- **Eigenes Protokoll `lead_mail_versand`** (Migration `20261004001351`) mit RPC
  `lead_mail_protokollieren`. Wie beim Vertrag wird jeder Versuch festgehalten, auch
  der gescheiterte. Neu ist `termin_at`: der Termin, der in der Mail stand. Wird der
  Termin danach verschoben, zeigt das Modal „Diese Mail nannte noch den alten Termin“.
  RLS: Lesen nur Admin, Schreiben nur über die RPC.
- **Ort des Gesprächs als Pflichtfeld im Versand-Dialog** (Nachtrag nach Rasits Vorgabe,
  Migration `20261004003339`). Edvance hat keinen festen Standort, das Gespräch findet
  bei der Familie, im Coworking oder anderswo statt. Die Vorlage hat deshalb keinen
  Standorttext mehr, `mail.terminOrt_koeln` ist entfallen. Der Admin trägt den Ort als
  Freitext ein (max. 300 Zeichen); er steht in der Vorschau, in der Mail und mit dem
  Termin in `lead_mail_versand.ort` (`not null`, nicht leer). Ohne Ort ist Senden
  gesperrt: in der Oberfläche (Knopf mit Begründung als Tooltip), in der Edge Function
  (400, kein Versand, kein Protokoll) und in der Datenbank (Check). Beim erneuten Senden
  ist der Ort des letzten Versands vorbelegt.
  `lead_mail_protokollieren` bekommt dafür `p_ort`. Weil sich die Signatur ändert, wird
  die Funktion per drop + create ersetzt, nicht überladen. Aufrufer gab es noch keine,
  `mail_senden` war nicht deployt, und die Tabelle war beim Einspielen leer (per `dbread`
  geprüft), deshalb geht `not null` ohne Vorbelegung.
  `leads.erstgespraech_standort` bleibt unverändert; die Mail liest es nicht mehr.
- **Der Empfänger ist immer `leads.contact_email`.** Die Function liest die Adresse
  selbst und nimmt keine aus dem Request an. So taugt sie nicht als Versandweg an
  beliebige Adressen.
- **Eine Vorlage für Vorschau und Versand.** Die Texte stehen in
  `de/vertraege.json → mail.termin*`, dort, wo schon die anderen Elternmails liegen und
  von wo `tools/dokumente-buendeln.mjs` sie für die Edge Function nach `texte.ts`
  bündelt. Der Wächter `vorlagenGleich.test.ts` hält beide Seiten gleich. Datum und
  Uhrzeit formatieren Vorschau (`src/lib/terminBestaetigung.ts`) und Function
  (`termin.ts`) mit denselben Intl-Optionen, fest `de-DE` und `Europe/Berlin`. Die Mail
  ist deutsch, und die Vorschau soll zeigen, was ankommt. Beide Seiten haben je einen
  Test mit derselben Erwartung („Donnerstag, 8. Oktober 2026, 16:00 Uhr“).
- **Kein Automatismus.** Ausgelöst wird über das Kartenmenü in der Spalte „Termin
  vereinbart“ („Terminbestätigung senden“). Der Eintrag erscheint nur für Admins und nur
  bei gesetztem Termin. Das Modal zeigt Empfänger, Betreff und Text. Erneutes Senden geht
  und wird mit Datum, Empfänger und gegebenenfalls dem alten Termin angezeigt.
- **Anrede „Guten Tag,“** ohne Namen, weil der Lead keinen Elternnamen trägt
  (`full_name` und `first_name` sind die des Kindes). Das Kind wird mit Rufnamen
  genannt, ohne Rufnamen mit dem vollen Namen.
- **Dauer:** „etwa 60 Minuten – Gespräch und eine 20-minütige Lernstandsanalyse am
  Tablet“ (`mail.terminDauer`, Vorgabe Rasit).
- **Mitbring-Hinweis** wörtlich aus dem Auftrag: Mathe-Heft (Schulheft), Hausaufgabenheft,
  falls vorhanden die letzte Klassenarbeit. Er nennt fest Mathe; bisher gibt es nur den
  Mathe-Katalog.
- **Ablauf in zwei Sätzen** nach `docs/specs/SPEC-prozess-erstgespraech.md`
  (P1 Intake, P2 LSA am Tablet parallel zum Elterngespräch, P4 Ergebnisgespräch).

## Befunde

- Eine Telefonnummer als Kontakt ist im Bestand nicht hinterlegt. Die Mail nennt nur
  die Antwort an `hello@`.

## Einspielen

Eingespielt und per `dbread` geprüft (04.10.):
`20261004001333_lead_thema_setzen`, `20261004001351_lead_mail_versand`. Das Prüfskript lief
in Teil 1 und 2 grün, und der Schema-Abzug aus Prod stimmt in diesen Teilen mit dem Repo
überein.

Noch offen, in dieser Reihenfolge:

```
mig 20261004003339 lead_mail_versand_ort
npx supabase functions deploy mail_senden --project-ref ztcppihxqcphlqaguhma
```

Die Migration muss vor dem Deploy kommen, weil die Function `lead_mail_protokollieren`
mit `p_ort` aufruft. Danach `~/bin/dbread -f supabase/checks/lead_thema_setzen.PRUEFUNG.sql`
(es erwartet die neue Signatur) und `bash tools/schema-snapshot.sh`.
