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
- **Mitbring-Hinweis** wörtlich aus dem Auftrag: Mathe-Heft (Schulheft), Hausaufgabenheft,
  falls vorhanden die letzte Klassenarbeit. Er nennt fest Mathe; bisher gibt es nur den
  Mathe-Katalog.
- **Ablauf in zwei Sätzen** nach `docs/specs/SPEC-prozess-erstgespraech.md`
  (P1 Intake, P2 LSA am Tablet parallel zum Elterngespräch, P4 Ergebnisgespräch).

## Befunde (für Rasit)

1. **Die Adresse des Standorts fehlt im Bestand.** `leads.erstgespraech_standort` kennt
   nur `'koeln'`, eine Anschrift steht nirgends: nicht im Schema, nicht in i18n, nicht in
   `docs/`. In der Vorlage steht deshalb der Platzhalter `[ADRESSE FEHLT: Standort Köln]`.
   **Solange er drin steht, ist Senden gesperrt.** Das Modal zeigt den Grund, und die
   Edge Function lehnt mit 400 ab. Eine Mail mit Platzhalter soll nicht an die erste
   echte Familie gehen.
   *Freischalten:* in `src/i18n/locales/de/vertraege.json` den Wert `mail.terminOrt_koeln`
   durch die Anschrift ersetzen, `node tools/dokumente-buendeln.mjs` laufen lassen,
   committen und `mail_senden` erneut deployen.
2. **Die Dauer ist abgeleitet, nicht bestätigt.** Eingetragen ist „etwa 60 Minuten“: P1
   ~10 min, P2 20 min, P3 2–3 min, dazu das Ergebnisgespräch ohne Zeitangabe in der Spec.
   Bitte bestätigen. Ändern lässt es sich in `mail.terminDauer` mit demselben Ablauf wie
   bei 1.
3. Ein Kontakt außer „antworten Sie auf diese Mail“ (Telefon) ist im Bestand nicht
   hinterlegt, deshalb nennt die Mail nur die Antwort an `hello@`.

## Einspielen

```
mig 20261004001333 lead_thema_setzen
mig 20261004001351 lead_mail_versand
npx supabase functions deploy mail_senden --project-ref ztcppihxqcphlqaguhma
```

Die Reihenfolge ist wichtig: Das Frontend ruft `lead_thema_setzen` auf, sobald `dev`
ausgeliefert ist. Die Function protokolliert über `lead_mail_protokollieren`.
Danach `~/bin/dbread -f supabase/checks/lead_thema_setzen.PRUEFUNG.sql` (Teile 1–2;
Teil 3 überspringt sich read-only) und `bash tools/schema-snapshot.sh`. Der Abzug in
diesem PR stammt aus der Wegwerf-DB und muss danach unverändert bleiben.
