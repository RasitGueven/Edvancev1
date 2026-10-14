# Offene Punkte K1 (Konten für Mitarbeitende)

Stand 14.10.2026 · Branch `feat/rasit-konto-k1` · Migration `20261014121000_konto_k1`

## Entscheidungen, die ich treffen musste

1. **Vorprüfung der Adresse über `konto_email_vorhanden`** (nur `service_role`). `inviteUserByEmail` lehnt eine
   schon vorhandene, aber noch nicht bestätigte Adresse nicht ab, sondern schickt still eine neue Einladung. Ohne
   Vorprüfung hätte „neu“ ein fremdes, offenes Konto (in Prod: 6 Eltern ohne Bestätigung, dbread 14.10.) per
   Profil-Upsert zum Coach gemacht. Jetzt: 409 `email_vergeben`, keine Mail, kein Upsert. Schlägt die Prüfung
   selbst fehl, gilt die Adresse als vergeben (fail-closed). Beleg: `einladen_test.ts` „doppelte Mail“, pgTAP C5/C6.
2. **Mailtexte in `supabase/functions/auth_mail/texte.ts`, nicht in `src/i18n`.** Diese Mails haben keine Vorschau in
   der Oberfläche; eine Doppelung mit Wachhund wie bei den Vertragsmails wäre reiner Aufwand.
3. **Kein „Gesendete Elemente“ für Auth-Mails** (`mailSenden({ speichern: false })`). Die Mails tragen einen gültigen
   Einladungs- oder Passwort-Link; in hello@ könnte ihn jeder mit Postfachzugriff benutzen. Die übrigen Mails
   (`mail_senden`) speichern weiter.
4. **Link-Basis `APP_URL`, sonst `site_url`.** Der Hook baut die Links selbst und nimmt `redirect_to` nicht, damit ein
   manipuliertes `redirect_to` den Link nicht auf eine fremde Seite lenken kann.
5. **Gültigkeit 24 Stunden** (`otp_expiry = 86400`). Mit dem Standard (1 Stunde) wäre eine Einladung, die abends
   kommt, am Morgen tot. Die Einstellung gilt in Supabase für alle Mail-Links, also auch für „Passwort vergessen“.
6. **`provision_coach` antwortet 410** (Entscheidung 10). Bestandsaufnahme der Aufrufer: nur
   `src/pages/admin/CoachesPage.tsx` über `src/lib/supabase/provisionCoach.ts`; keine Tests, Werkzeuge, Skripte,
   Seeds (`git grep -n 'provision_coach\|provisionCoach'`, Ausgabe im PR). Die Lib-Datei ist gelöscht.
7. **Login-Texte nach i18n ausgelagert** (§12 Punkt 4, Namespace `konto`), weil `Login.tsx` für den Link ohnehin
   angefasst wurde. Verhalten unverändert (Vitest „Login (auch Tablet/Kiosk) unverändert“).
8. **Unbekannte Mailart → 400** mit `unbekannte Mailart: <art>`, protokolliert als `unbekannt`. Das betrifft heute nur
   die Art `email` (Code-Login per OTP), die Edvance nicht nutzt. Wer sie einschaltet, sieht den Fehler sofort.

## Entscheidungen Rasit (14.10.2026, nach dem ersten PR-Stand)

1. Migration `20261014121000_konto_k1` ist freigegeben (CLAUDE.md §4).
2. **`auth_mail` lehnt `email_change` ab:** 403 `email_change ist gesperrt: Adressaenderung nur ueber den Admin`, mit
   Protokollzeile und ohne Mail. Das gilt, bis es einen Weg über den Admin gibt. Die Seite `/auth/bestaetigen` nimmt
   `type=email_change` nicht mehr an.
   - Lokal belegt: `PUT /auth/v1/user {email}` → Supabase antwortet 500 („Unexpected status code returned from hook:
     403“). Die Adresse bleibt, `email_change` bleibt leer, es kommt keine Mail.
3. **`provision_student` antwortet nach dem Deploy mit 410** wie `provision_coach`. Aufrufer: keine (`git grep` über
   src, scripts, tools, supabase/tests). `scripts/seed-test-student.ts` ruft nur die RPC `app_provision_student`, die
   bleibt.
4. **„Passwort vergessen“** gilt für alle Konten mit Mail und Passwort, auch Eltern. So bleibt es.

## Bericht: Lösen andere Functions eine Auth-Mail aus? (nur gemeldet, nichts geändert)

`git grep` nach `inviteUserByEmail|generateLink|signUp|signInWithOtp|magiclink|resetPasswordForEmail` über
`supabase/functions`, `scripts`, `tools`, `src` findet außer K1 selbst nur `provision_student` (jetzt 410).

- **`vertrag_abschluss`** legt zwei Konten an, beide per `auth.admin.createUser`:
  - das Schülerkonto mit `email_confirm: true` und Zufallspasswort (`vertrag_abschluss/index.ts:152`);
  - das Elternkonto mit `email_confirm: false` und ohne Passwort (`:185`). Der Kommentar dort sagt ausdrücklich „kein
    inviteUserByEmail … keine Mail“.
  - Lokal mit genau diesen Aufrufen geprüft: 0 Mails in Mailpit, 0 Zeilen in `auth_mail_versand`. Ein
    `createUser` der Admin-API ruft den Hook nicht.
- **`tools/platz-konten.mjs`** und **`scripts/seed-test-student.ts`** nutzen `createUser` mit `email_confirm: true`.
  Sie lösen keine Mail aus.
- **Was der Hook mit einem Elternkonto aus `vertrag_abschluss` macht:** Nur wenn die Eltern selbst „Passwort
  vergessen“ nutzen, entsteht eine `recovery`-Mail. Sie geht an die Elternadresse, mit Link auf
  `/auth/neues-passwort`.
  - Lokal belegt: `recover` 200 → Mail „Neues Passwort für Edvance“ → `verify` 200.
  - Danach ist das Konto bestätigt (`email_confirmed_at` gesetzt), die Eltern legen ein Passwort fest und landen auf
    `/parent`. Das passt zu Entscheidung 4.

## Befunde

1. **`[auth.email] enable_signup = false` schaltet den ganzen E-Mail-Login ab.** Lokal geprüft: `POST
   /auth/v1/token?grant_type=password` → 422 `email_provider_disabled`. Die Registrierung sperrt allein
   `[auth] enable_signup = false` (→ `/auth/v1/signup` 422 `signup_disabled`, Einladung per Admin-API geht weiter).
   Im Dashboard deshalb **nur** „Allow new users to sign up“ ausschalten, den E-Mail-Provider **anlassen**.
2. **`email_change`: Ein Klick genügt.** Lokal (GoTrue v2.192.0, `double_confirm_changes = true`): Beide Adressen
   bekommen je eine Mail mit eigenem Link. Wer *einen* der beiden Links einlöst (`verifyOtp` mit `token_hash`), schließt
   die Änderung ab; der andere ist danach ungültig. Probiert in beiden Reihenfolgen. Das ist Supabase-Verhalten, nicht
   K1. Folge: Wer eine Sitzung hat, kann die Adresse ändern, indem er nur den Link an die neue Adresse klickt. Edvance
   bietet keine Adressänderung an. **Erledigt:** Der Hook lehnt `email_change` ab (Entscheidung 2 oben).
3. **Zeitliches Ausspähen bleibt auf API-Ebene möglich.** Die Seite „Passwort vergessen“ antwortet immer gleich. Supabase
   ruft den Hook aber nur für vorhandene Adressen; die Antwortzeit von `/auth/v1/recover` ist für sie länger (Versand über
   Graph). Wer die API direkt misst, kann daraus schließen. Nicht in unserer Hand; Rate-Limits begrenzen es.
4. **`provision_student` lädt Eltern weiter per `inviteUserByEmail` ein.** Die Function hat keinen Aufrufer mehr in der
   Oberfläche (Verträge legen Konten per `createUser` an), ist aber deployt. Mit aktivem Hook bekämen Eltern die
   neutrale Einladung („Sie wurden zu Edvance eingeladen“) und landen nach dem Passwort auf `/parent`. **Erledigt:**
   Die Function antwortet nach dem Deploy mit 410 (Entscheidung 3 oben).
5. **„Passwort vergessen“ steht auf der gemeinsamen Login-Seite** und funktioniert damit für jedes Konto mit echter
   Adresse, auch Eltern. Eine Einschränkung auf Mitarbeitende ginge nur mit einer Aussage, ob die Adresse einem
   Mitarbeiter gehört — genau das darf die Seite nicht verraten. Tablet-Konten haben Adressen, an die keine Mail geht.
   **Entschieden:** So bleibt es (Entscheidung 4 oben).
6. **Einladung eingelöst, Passwort nicht gesetzt:** Wer „Weiter“ klickt und dann abbricht, ist bestätigt, hat aber kein
   Passwort. Die Coach-Liste zeigt „aktiv seit …“, „erneut senden“ gibt es dann nicht mehr. Weg: „Passwort vergessen“.
7. **Repo-`config.toml` und Supabase-CLI 2.99.0:** Der Abschnitt `[local_smtp]` lässt `supabase start` mit „failed to
   parse config“ scheitern (auch auf `origin/dev`, ohne K1). Für den lokalen Durchlauf lief eine Kopie unter
   `C:\Users\rasit\k1-lokal` mit `[inbucket]`, eigenen Ports (544xx) und ohne Realtime/Studio/Analytics.
8. **Kein Löschen alter Protokollzeilen** in `auth_mail_versand` und keine Oberfläche dafür; lesen kann ein Admin per SQL.
9. **Dateigröße:** `src/App.tsx` hat jetzt 474 Zeilen (vorher 456, schon über §4). Die Konto-Routen sind 25 Zeilen davon.
10. **Umfang:** Das Paket liegt über den 300 Zeilen aus §4; es ist laut Auftrag ein PR.
11. **Neu laden nach „Weiter“:** Wer nach dem Einlösen, aber vor dem Passwort die Seite neu lädt, sieht „Link gilt
    nicht mehr“ (der Token ist aus der Adresse entfernt, die Sitzung besteht). Weg: „Passwort vergessen“. Hinweis der
    Zweitprüfung, nur UX.
12. **Weitere Ausspäh-Kanäle auf API-Ebene** (Zweitprüfung): GoTrue antwortet nur für vorhandene Adressen mit 429
    („nur alle 60 s“) bzw. 500, wenn der Hook scheitert. Die Seite zeigt beides nicht an; wer `/auth/v1/recover`
    direkt ruft, sieht es. Supabase-inhärent wie Punkt 3.
13. **`slots_sl2b` lokal 4 rot (62–65)** — auch auf reinem `origin/dev` in einer eigenen Wegwerf-DB, also nicht K1.
    Steht nicht in `bekannt-rot.txt`; vermutlich datumsabhängig. Gehört zu SL2b.
14. **Auth-/RLS-nah:** Neue SECURITY-DEFINER-Funktionen lesen `auth.users`, neue Tabelle mit RLS. Bestehende Policies
    und Auth-Einstellungen in Prod sind nicht geändert. Laut CLAUDE.md §4 braucht das Rasits ausdrückliche Bestätigung
    vor dem Einspielen.

## Beim Einspielen (14.10.2026)

- **Hook-Block in `config.toml` ist im Repo aus** (`enabled = false`). Die CLI prüft den Block auch bei `functions
  deploy`. Mit `enabled = true` und ohne gesetztes `SEND_EMAIL_HOOK_SECRET` brach jeder Deploy mit „Invalid hook config“
  ab, auch für fremde Functions.
  - Für einen lokalen Durchlauf mit Mails: auf `true` setzen und `supabase/.env` anlegen.
  - In Prod schaltet das Dashboard den Hook.
- **`APP_URL` fehlte in den Prod-Secrets** (Stand 10:52; `SEND_EMAIL_HOOK_SECRET` und `MS_*` sind gesetzt). Ohne
  `APP_URL` gilt:
  - `auth_mail` nimmt den Ursprung der Site URL.
  - `coach_einladen` nimmt den Ursprung des Browsers.
  - Beides geht, aber `APP_URL` ist die vorgesehene feste Quelle.

## Nach dem Einspielen prüfen

- `select version from supabase_migrations.schema_migrations where version = '20261014121000'` (dbread).
- `tools/schema-snapshot.sh` gegen Prod: nur der Kopf darf sich gegenüber `supabase/schema-erwartet.sql` ändern.
- Echte Einladung an eine Test-Adresse mit Rasit (Mail von hello@, Link auf studio.edvanceacademy.de).
