# Bauauftrag D · D0 Ist-Analyse

Stand 27.10.2026 · origin/dev edvance-app `e4cf268`, Edvancev1 `74b5b4b8` · DB-Belege per `dbread` (Prod, read-only)

## 1 · App-Aufbau (edvance-app)

- Router: expo-router, Root `app/_layout.tsx`. Gruppen: `app/(student)/` (Hub `index.tsx`, `lsa/*`, `session/*`), `app/login.tsx` außerhalb.
- Kiosk-Erkennung über das **Konto**, nicht das Gerät: `SignedInGate` (`app/_layout.tsx:78`) fragt `useIsPlatz()` (`src/lib/queries/useIsPlatz.ts`, RPC `platz_state`, 42501 = kein Platz) und verzweigt `isPlatz === true ? <KioskGate/> : <SchuelerGate/>` (`app/_layout.tsx:84`). KioskGate (`:112`) leitet nach `tablet_stand`/`platz_state` auf Session, LSA oder Warten.
- Home-Modus daneben: Ein Kinderkonto ist heute „Schüler“ → `SchuelerGate` (`:87`) → Hub `/`. Der Home-Modus wird eine eigene Routengruppe `app/(home)/` hinter `SchuelerGate`; der Kiosk-Weg bleibt unberührt (eigene Gruppe, eigene Gate-Verzweigung nur im Schülerzweig).
- Plattformweiche: `src/lib/supabase.ts:20/28` (`Platform.OS === 'web'` → localStorage, sonst SecureStore). Weitere Weiche in `app/_layout.tsx` (Zurück-Sperre nur Web).
- Texte fürs Kind: je Bereich `texte.ts` (z. B. `src/components/session/texte.ts`, `src/components/lsa/einfuehrungTexte.ts`); kein i18next in diesem Repo.

## 2 · Zugangscode aus K1 (Edvancev1)

- Spalten `vertraege.zugangscode`, `zugangscode_erzeugt_am`, `zugangscode_gesperrt_am` (`supabase/migrations/20260925120000_vertraege_erweiterung.sql:233-235`), Form `EDV-XXXX-XXXX` ohne 0/O/1/I/L (`:299-301`), eindeutig (`:305`). Kommentar: „Kein Login-Mittel in dieser Runde“ (`:249`).
- Erzeugung `zugangscode_erzeugen()` (`:560`, nur intern), beim Abschluss in `vertrag_abschliessen` (`20260929100100_schuelerakte_akte.sql:1123`).
- Gültigkeit als View-Spalte `zugangscode_gueltig` = Code da, nicht gesperrt, wirksamer Status im_widerruf/aktiv (`20261014110412_vertrag_pilot.sql:743`).
- Sperre von Hand bzw. beim Widerruf (`20260925181700_vertraege_menue_db.sql:242`).
- Versand: Anlass `zugangscode` in `vertrag_versand` (`20260928210000_vertrag_versand_mail.sql:24`).
- Admin-Oberfläche: `src/pages/admin/vertraege/ZugangscodeFeld.tsx` (Maskierung `maskIban`, Aufdecken auf Klick).
- Prod: 6 Verträge im_widerruf (5 mit Code), 5 aktiv (1 mit Code), 0 gesperrt.
  ```
  dbread: select vertrag_status, count(*), count(zugangscode), count(zugangscode_gesperrt_am) from vertraege group by 1
  |2|0|0 · im_widerruf|6|5|0 · aktiv|5|1|0
  ```
- **Fehlt zum Einlösen:** Einlöse-Weg, Geräte je Kind, Versuchsprotokoll und Sperre, „Gerät abmelden“, „Neuen Code erzeugen“ und „Freischalten“ für Admins.

## 3 · Auth und Wahl der Anmeldung

- `supabase/config.toml:178/180`: `enable_signup = false`, `enable_anonymous_sign_ins = false` (lokal; Prod gleich laut Verhalten, keine anonymen Nutzer: `select count(*) filter (where is_anonymous) from auth.users` → 0 von 32).
- Rollen: `profiles.role` (admin, coach, parent, student), `get_my_role()`, `get_my_student_id()` = `students.profile_id = auth.uid()` (sql, security definer). Jedes Kind hat ein echtes Auth-Konto mit E-Mail (8 von 8 Schülerkonten bestätigt), angelegt von der Edge Function `vertrag_abschluss`.
- Laufender Vertrag: `hat_zugang(p_student_id, p_datum)` (im_widerruf/aktiv oder Brücke).
- RLS-Muster für Kinder: Funktionen prüfen `get_my_student_id() = …` (z. B. `quest_inhalt`, `20261007141354_quest_kind.sql:75`).

### Sicherheitsprüfung „anonyme Anmeldung“

214 Richtlinien in public/storage gelten für `authenticated` oder `public`. 18 davon geben jedem angemeldeten Nutzer Lesezugriff, ohne Rollenprüfung (Auszug aus `pg_policies`):

| Tabelle | Richtlinie | Bedingung |
|---|---|---|
| akte_einstellungen | akte_einstellungen_authenticated_read | auth.role() = 'authenticated' |
| dokument_fassungen | dokument_fassungen_select | auth.uid() IS NOT NULL |
| screening_items | screening_items_read_active | authenticated AND active |
| feiertage_nrw, ferien_nrw, microskills, process_competencies, skill_clusters, subjects, tier_laufzeiten, tiers | *_authenticated_read | auth.role() = 'authenticated' |
| badge_catalog, pruef_einstellungen, session_einstellungen, skill_kante, skill_voraussetzung, skills, themen | *_read_all | true |

Ein anonymer Nutzer hätte die Rolle `authenticated` und damit sofort Zugriff auf `dokument_fassungen` (Vertragsdokumente), `akte_einstellungen` und `screening_items`.

### Wahl: Edge Function `geraet_anmelden`, keine anonyme Anmeldung

Die Funktion nimmt Code und Gerätenamen an und löst ein (Prüfung, Begrenzung, Protokoll per RPC mit service_role). Danach meldet sie das **eigene Konto des Kindes** über `auth.admin.generateLink(magiclink)` + `verifyOtp(token_hash)` serverseitig an und gibt der App die Session zurück. Es geht keine Mail raus. Die Session-ID aus dem JWT steht in der Gerätezeile.

Gründe:
1. Ein Kind bleibt ein Konto. `get_my_student_id()`, XP, Quests und alle Kinder-Richtlinien gelten unverändert. Bei anonymer Anmeldung bräuchte jedes Gerät eine eigene Auth-ID, und `get_my_student_id()` (die Grundfunktion fast aller Kinder-Richtlinien) müsste auf eine Gerätetabelle umgebaut werden.
2. Bei anonymer Anmeldung müssten die 18 offenen Richtlinien oben geschlossen werden, und jede künftige Richtlinie mit `authenticated` wäre ein stilles Leck. Der Schalter gilt projektweit: Jeder mit dem anon-Key kann dann Auth-Nutzer anlegen (30 je Stunde und IP).
3. Es gibt keinen Schalter im Dashboard, und auch Rasit muss keine Einstellung freigeben. Dafür muss Rasit die Edge Function einmal deployen (`supabase functions deploy geraet_anmelden`, Muster wie `vertrag_abschluss`). Das steht in `~/einspielen/`.
4. Der service_role-Key bleibt in der Edge Function (Supabase-Umgebung), nie im Frontend.

Vorgaben aus D0.3 damit:
- Einmal je Gerät, danach angemeldet: SecureStore (nativ) bzw. localStorage (Web) mit Refresh-Token.
- Höchstens drei aktive Geräte je Kind: Prüfung in der Einlöse-RPC.
- Admin meldet ein Gerät ab: Die Gerätezeile bekommt `abgemeldet_am`, und die Auth-Session wird gelöscht (`auth.sessions`, dann schlägt der Refresh fehl). Zusätzlich prüft `geraet_status()` beim App-Start und bei der Rückkehr in die App. Ein abgemeldetes Gerät landet so sofort auf „Code eingeben“. Die Home-RPCs verweigern Sessions abgemeldeter Geräte.
- Neuer Code: Der alte wird ungültig. Bereits angemeldete Geräte bleiben angemeldet, solange der Admin sie nicht abmeldet.
- Der Code allein gibt nach dem Einlösen keinen Zugriff: Er ist kein Passwort. Er tauscht sich nur gegen eine Gerätesitzung (höchstens drei je Kind). Zugriff hat nur die Sitzung.
- Versuche begrenzt: 5 Fehlversuche je Installation oder je IP-Hash in 15 Minuten, dann 15 Minuten Sperre. Das Protokoll speichert keinen Klartext-Code.
- Nur bei laufendem Vertrag: `hat_zugang(student_id)` und der Code nicht gesperrt.

## 4 · Pfad und XP

- Tabellen `xp_events` (Buchungsschlüssel), `xp_rules`, `student_progress` (xp_total, level, presence_streak_*, home_streak_*). Buchung `xp_buchen(uuid,integer,text,text,uuid)` mit Kern `xp_buchen_intern` (`20261007100100_x0_xp_buchen.sql:71`).
- Abzeichen: `badge_catalog` (id, label, rarity, form, klasse, trigger) und `student_badges` (ohne „vergeben von“). Spalten `badge_family` und `badge_tier` gibt es nicht.
- Coach-Bestätigung: `lernpfad.stand_coach` ∈ {gemeistert, vertagt} mit `coach_von`/`coach_am`, gesetzt über `mastery_entscheiden`. Dazu `student_competency_mastery.mastered_by` (alt, Microskills) und der Trigger `enforce_mastery_gate()`.
- Q1 Home Quests (Bestand): `quests`/`quest_aufgaben` mit Termin, `quest_erledigt` bucht 50 XP und eine Wochenserie. Das Modell hat Quest-Tage und widerspricht damit Entscheidung 2. D baut daneben `home_uebung`, löscht nichts und ruft Q1 nicht mehr auf.

## 5 · Themenbaum

- Nicht gebaut. `schueler_kompetenz_offen` gibt es nicht (`to_regclass` → null).
- Vorhanden: `skills` (skill_key, label, klasse_herkunft, fundament_tiefe), `skill_kante` (skill_key, voraussetzt_skill_key), `skill_thema`, `themen` (klasse, sort, klp), `lead_themen` (status „aktuell“), `schul_themenplan`.
- Befunde: `lernpfad.stand_system` ∈ {offen, aktiv, sicher, noch_nicht_sicher, kandidat} mit `quelle` lsa/session/coach. Daneben `lsa_skill_urteil` je LSA-Sitzung, `mein_lernpfad()` für das Kind. Prod: 6 sicher, 5 noch nicht sicher, kein stand_coach.
- Level: gibt es noch nicht, wird aus Befunden je Thema gerechnet (D4).

## 6 · Avatar AV1

`src/components/avatar/` gibt es auf origin/dev nicht. Vorhanden ist `src/components/lsa/AvatarFigur.tsx` (Props `id: AvatarId`, `size`; vier Figuren, keine Posen). D legt einen Platzhalter `src/components/avatar/` mit derselben Schnittstelle an (id, size, pose optional, wird ignoriert) und nennt ihn im Bericht.

## 7 · Native Bereitschaft

- `app.json`: name „edvance-app“, scheme `edvance`, orientation default, `ios.supportsTablet`. **Es fehlen** `bundleIdentifier`/`package`, Splash-Konfiguration, Privacy Manifest und Berechtigungen. Die Android-Hintergrundfarbe ist ein Expo-Standard-Hex.
- `eas.json` fehlt, `ios/` und `android/` fehlen (Continuous Native Generation, `expo prebuild` möglich).
- Assets: Expo-Standard-Icons (`assets/icon.png`, `splash-icon.png`, Android adaptive). Echte Marken-Icons fehlen.
- Schriften über `@expo-google-fonts/*` mit `useFonts` (nativ fähig). `react-native-svg` 15.15.4, `react-native-reanimated` 4.5.0 mit `react-native-worklets` installiert, Babel-Plugin gesetzt.
- Expo SDK 57, RN 0.86. `eas` ist in WSL nicht installiert (`npx --no-install eas` → nicht gefunden).

## 8 · Aufgaben zuhause und Prüffunktion

- Rein prüfende Funktionen: `lsa_is_correct`/`lsa_grade` (immutable) sowie `session_bewerten(uuid,integer,jsonb)` und `erklaer_bewerten` (stable, schreiben nicht).
- Q1 `quest_inhalt` liefert Aufgaben **mit Lösungsweg** zur Selbstkontrolle, nur mit Termin.
- `aufgabe_ziehen`, `aufgabe_payload` und `aufgabe_werten` von A fehlen in Prod (`pg_proc` ohne Treffer am 27.10.). D baut gegen die Signatur aus §9 und zeigt bis dahin einen Leerzustand.

## 9 · Projekt-Ref von Prod

`ztcppihxqcphlqaguhma` (aus `.env` `EXPO_PUBLIC_…/VITE_SUPABASE_URL` und `DATABASE_URL`, auch in `supabase/functions/provision_student/index.ts:16`). Zielprüfung in den Einspiel-Skripten: `current_database() = postgres` **und** `$DATABASE_URL` enthält `ztcppihxqcphlqaguhma`.

## 10 · Abnahme-Umgebung

pgTAP läuft in CI (`.github/workflows/schema.yml`, Job `neuaufbau`: alle Migrationen in einer frischen Postgres-DB, dann `supabase/tests/*.test.sql`). Lokal läuft das genauso in einer Wegwerf-DB im eigenen Cluster. Schreibende Abnahmefälle laufen dort. Fälle, die Auth-Sessions oder die Edge Function brauchen, kommen in die Live-Checkliste.

## Übersicht

| Teil des Ziels | vorhanden | fehlt | Phase |
|---|---|---|---|
| Anmeldung mit Code | Code, Erzeugung, Maskierung, Sperre, Versand | Einlösen, Geräte, Versuche, Admin-Aktionen, Bildschirm | D1 |
| Kiosk-Weiche | Platz-Konto-Weiche | Home-Gruppe im Schülerzweig | D0b/D1 |
| Übung zuhause | Q1 mit Quest-Tagen (bleibt liegen) | home_uebung, Meldung, Kurzfassung | D2 |
| Zeig's mir | – | Vorschlag, Entscheidung, Kachel | D2 |
| Offen-Regeln | Kanten, Themen, Befunde (lernpfad) | kompetenz_offen | D2 |
| XP | xp_buchen, student_progress | Buchung je Home-Quest, Wochen mit Übung | D2/D3 |
| Start und Quests | – | Bildschirme; Aufgaben von A | D3 (wartet auf A) |
| Themenbaum | Daten | Komponenten, Level, Ring | D0b/D4 |
| Profil, Abzeichen | badge_catalog, student_badges, lernpfad.stand_coach | Bildschirm, Avatar-Posen (AV1) | D5 |
| Eddie ohne Sprachmodell | – | Suche, Vorschläge, Frage an den Coach; eddie_index von B | D5 |
| Nativ und Stores | Expo 57, SVG, Reanimated, Schriften | Bundle-ID, eas.json, Icons, Splash, Privacy Manifest, eas-Login | D6/D7 |
