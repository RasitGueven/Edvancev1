# Bauauftrag D · Home light · Bericht

Stand 27.10.2026 (Abschluss des Laufs) · Orchestrator-Lauf in einer Sitzung · Einspielen: auf Anweisung Rasit selbst („alle Migrationen
selbst einspielen“), jeweils nach der Zweitprüfung durch einen frischen Subagenten.

## PRs in Merge-Reihenfolge

| # | Repo | Phase | Baut auf | Stand |
|---|---|---|---|---|
| 331 | Edvancev1 | D0 Ist-Analyse (+ DATENVERTRAG-Abschnitt D) | – | offen |
| 49 | edvance-app | D0b Schnittstellen (ThemenbaumAusschnitt-Platzhalter, Home-Routen) — **zuerst, C wartet** | – | offen |
| 339 | Edvancev1 | D1 Anmeldung mit Code und Geräte, D1c, Schülerakte | 331 | offen, eingespielt |
| 52 | edvance-app | D1 Code eingeben, Weiche, Gerätewache | 49, 339 | offen |
| 344 | Edvancev1 | D2 Übung zuhause, Offen-Regeln, Zeig's mir, D2b LSA-Befunde | 339 | offen, eingespielt |
| 345 | Edvancev1 | D2 Coach-Kachel „Zuhause geübt“ | 344 (+ C0b #332 für den Einbau) | offen |
| 348 | Edvancev1 | D4 Themenliste (Backend) | 344 | offen, eingespielt |
| 57 | edvance-app | D3 Start (Quest wartet auf A), D4 Themenbaum, ThemenbaumAusschnitt | 52, 344, 348 | offen |
| 353 | Edvancev1 | D4b Session-Tablet liest den Themenbaum seines Kindes | 348 | offen, eingespielt |
| 58 | edvance-app | D5 Ich und Eddie ohne Sprachmodell | 57 | offen |
| 59 | edvance-app | D6 Geräte (iPhone, Android, iPad hoch/quer) | 58 | offen |
| 60 | edvance-app | D7 Store (app.json, eas.json, Icons, Splash, Privacy Manifest, Store-Texte) | 59 | offen |

## Migrationen (alle in Prod, per dbread geprüft)

| Version | Name | Prüfabfrage |
|---|---|---|
| 20261027130748 | reihe1_d1_geraete | 12 Funktionen, 2 Tabellen |
| 20261027132229 | reihe1_d1c_home_sitzung (Auth-Änderung, freigegeben) | t\|t\|t |
| 20261027134914 | reihe1_d2_home_uebung | 11\|4\|6 |
| 20261027140343 | reihe1_d2b_lsa_befund | t\|t\|4 |
| 20261027141641 | reihe1_d4_themenbaum | t |
| 20261027160142 | reihe1_d4b_tablet_lesen | t\|1 |

Nicht eingespielt (kein Migrationsschritt): **Edge Function `geraet_anmelden`** →
`bash ~/einspielen/D-1b-edge-function.sh` (setzt das Secret `GERAET_PEPPER` und deployt). Ohne sie endet jede
Anmeldung mit Code in „Das hat gerade nicht geklappt“. Dashboard: `~/einspielen/D-dashboard.md`.

## Abnahme (D8)

| # | Fall | Ergebnis |
|---|---|---|
| 1 | Code auf Handy/Tablet, bleibt angemeldet; viertes Gerät abgelehnt | Datenbank: pgTAP grün (84). App: Ansichtstest mit Attrappe grün. **Live ✱** (Edge Function) |
| 2 | Abgemeldetes Gerät → „Code eingeben“; fünf Fehlversuche → 15 Min. Sperre | pgTAP grün; Ansichtstest grün; Live ✱ |
| 3 | Start ohne Quest-Tage, Quest jederzeit startbar | Ansichtstest grün (iPhone, iPad quer) |
| 4 | Server speichert nur Skill, Anzahl, Dauer, Zeitpunkt | pgTAP grün (keine Spalte, Signatur, Inhalts-Hash); Netzwerkprüfung **offen** bis zur Quest (A) |
| 5 | Drei Quests → „3×“ im Ring, Zustand unverändert | Ansichtstest mit Attrappe grün; pgTAP „Home-Quest ändert keinen Zustand“ grün; Live ✱ |
| 6 | Coach-Check-in „3× geübt“, Zeig's mir, höchstens einer je Kind und Session | pgTAP grün; Kachel-Tests grün; Einbau wartet auf C0b |
| 7 | Profil trennt Pfad und Kompetenz, kein „gemeistert“ ohne Coach | Ansichtstest grün |
| 8 | Eddie ohne Sprachmodell, nur Freigegebenes, Frage an den Coach | Ansichtstest grün; Frage landet in `coach_fragen` (pgTAP) |
| 9 | Kiosk-Web-App unverändert | volle Ansichtstest-Suite grün (D1: 72/19, D3+D4: 80/19, D5–D7: 97/19 + 2 Eddie-Fälle nach Fix grün) |
| 10 | iOS- und Android-Build | **Haltepunkt:** `eas whoami` → „Not logged in“; alles vorbereitet (`docs/reihe1/D/store/rasit.md`) |

## Entscheidungen im Lauf

- Anmeldung über eine Edge Function mit dem eigenen Konto des Kindes, keine anonyme Anmeldung: 18 Richtlinien geben
  jedem `authenticated` Lesezugriff, darunter `dokument_fassungen` (Ist-Analyse §3).
- D1c (Auth): `get_my_student_id()` ist für abgemeldete Geräte null, `lsa_may_act_for` gilt nicht für Gerätesitzungen,
  `screening_tests` schreibt das Kind nur ohne Gerätesitzung.
- Offen-Regeln mit Befunden aus `lernpfad` und der jüngsten LSA (D2b); Regel 6 über Trigger.
- XP: 10 je Quest, nur die ersten zehn Quests am Tag zählen für XP.

## Offene Punkte (Entscheidung Rasit)

1. **Passwortwechsel über die Gerätesitzung:** Ein Kind könnte über die Gerätesitzung ein Passwort setzen und hätte
   dann eine Sitzung ohne Gerätezeile. Lösung (a): Kind-Zweig in `lsa_may_act_for` ganz streichen (Tests `session_e1`,
   `session_l5` umbauen). Oder (b): Passwortwechsel für Kinderkonten per Auth-Hook sperren.
2. **Regel 5** ist als „frühere Klasse“ umgesetzt, nicht als „früherer Doppeljahrgang“.
3. `attendance = 'planned'` nach Session-Ende zählt nicht als Grenze für „n×“.
4. `nicht_angesetzt` ist im Themenbaum kein Befund, in `lernpfad_aus_lsa` aber „noch nicht sicher“.
5. Das Kind sieht LSA-Befunde im Baum, bevor der Coach sie bespricht (Anforderung §2 sagt ja; bitte bestätigen).
6. **Schulplan:** Plan-Themen früherer Jahrgänge erscheinen nur einmal, an ihrer Stelle im Plan.
7. **Themenliste:** Sie scrollt bei langen Schulplänen (Anforderung: nichts scrollt). Der Baum skaliert ohne Scrollen.
8. ~~ThemenbaumAusschnitt im Check-out~~: erledigt mit D4b (`20261027160142`, eingespielt). Für C: bei 42501 (Session abgeschlossen) blendet sich der Ausschnitt still aus.
   nichts. Für C muss `home_darf_lesen` das Tablet der laufenden Session zulassen.
9. **Avatar:** AV1 fehlt auf origin/dev. Bis dahin ist `src/components/avatar/Figur.tsx` ein Platzhalter mit
   Schnittstelle `{ avatarId, size, pose }`.
10. **Rate Limit:** Token-Verifikationen in Supabase (30 je 5 Min.) für Startabende anheben.
11. **Hook-Ausrutscher:** Ich habe `git reset -q --hard` auf dem frischen, leeren D1-Branch benutzt. Der Hook prüft nur
    `git reset --hard` ohne Zwischenoption und hat deshalb nicht gegriffen. Verloren ging nichts, für die Zukunft aber zur
    Kenntnis.

## Wartet auf andere Aufträge

- A0b/A3 (Formate in edvance-app): Bis dahin ist die Quest ein ruhiger Leerzustand. Danach folgen der Quest-Bildschirm
  (fünf Aufgaben über `aufgabe_ziehen` mit Rolle home, `aufgabe_payload`, `aufgabe_werten`, Meldung) und „Quest
  geschafft“.
- B: `mediathek_kind`, `ErklaerVideo`, `eddie_index`. Bis dahin ist „Erklärsequenz · kommt bald“ ausgegraut, und Eddie
  sucht nur Skills.
- C0b (#332): Einbau der Kachel in `CHECKIN_BEITRAEGE` (eine Zeile).
