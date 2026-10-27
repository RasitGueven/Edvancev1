# Bauauftrag D · Fortschritt

| Datum | Phase | Ergebnis | PR |
|---|---|---|---|
| 2026-10-27 | Schritt 0 | Worktrees ~/edvance-app-D (feat/rasit-reihe1-d0) und ~/Edvancev1-D (feat/rasit-reihe1-d1-db) ab origin/dev, npm ci grün, .env kopiert (ignoriert), Unterlagen entpackt und gelesen | – |
| 2026-10-27 | D0 | Ist-Analyse: Anmeldung über Edge Function mit dem eigenen Konto des Kindes statt anonymer Anmeldung (18 offene `authenticated`-Richtlinien) | https://github.com/RasitGueven/Edvancev1/pull/331 |
| 2026-10-27 | D0b | Platzhalter ThemenbaumAusschnitt + Home-Routengruppe; typecheck, 353 Tests, Ansichtstests 69/19 übersprungen grün | https://github.com/RasitGueven/edvance-app/pull/49 |
| 2026-10-27 | D1 Backend | Migration 20261027130748 (Geräte, Versuche, Einlösen, Admin), Edge Function geraet_anmelden, pgTAP 76 grün, Deno 7 grün | – |
| 2026-10-27 | D1 Zweitprüfung 1 | 2 blockierend (Sperre umgehbar, verwaiste Zeilen), 6 sollte → Korrekturrunde 1: IP-Pflicht, Lock je IP, Bremse, Abbruch nach 2 Min., Gültigkeit je Vertrag, HMAC, Löschfrist; D1c (Auth-Änderung, Freigabe Rasit) | – |
| 2026-10-27 | D1 App | Code eingeben, Weiche web/nativ, Gerätewache; 361 Unit-Tests, home-code Ansichtstests 3/3 | – |
| 2026-10-27 | D1 Zweitprüfung 2 | 1 blockierend (Passwortwechsel über Gerätesitzung → Sitzung ohne Gerätezeile) bleibt als Entscheidung Rasit offen, Rest behoben: tote Sessions, Selbst-Abmelden, Bremse 2000, IPv6 /64, Rollback-Guard, get_my_student_id an Schülerzeile gebunden (3 µs statt 2 µs für Nicht-Kinder), screening_tests ohne Gerätesitzung; volle pgTAP-Suite grün | – |
| 2026-10-27 | D1 PR | https://github.com/RasitGueven/Edvancev1/pull/339 | – |
| 2026-10-27 | D1 eingespielt | Anweisung Rasit „alle Migrationen selbst einspielen“: 20261027130748 (Prüfabfrage 12\|t) und 20261027132229 (t\|t\|t), Lesetest in Prod (Kind erkannt, Admin unverändert). Edge Function noch nicht deployt (kein Migrationsschritt, ~/einspielen/D-1b-edge-function.sh). schema-erwartet aus dem Neuaufbau, weil Prod schon A/B/C-Migrationen trägt | – |
| 2026-10-27 | D2 Backend | Migration 20261027134914; Zweitprüfung 2 blockierend (KA-Status, Regel 6) + 6 sollte behoben; eingespielt, Prüfabfrage 11\|4\|6 | – |
| 2026-10-27 | D2b | LSA als Befundquelle (Batu in Prod vorher 0 sicher); Zweitprüfung 1 blockierend (Regel 6 bei LSA-Herabstufung) behoben; eingespielt t\|t\|4; Batu jetzt 25 sicher · 8 noch nicht sicher · 50 offen · 47 gesperrt | – |
| 2026-10-27 | D2 Coach | Kachel „Zuhause geübt“ (eigene Komponente, 4 Tests); Einbau wartet auf C0b (#332) | – |
| 2026-10-27 | D1 App | PR geöffnet, Ansichtstests 72 bestanden / 19 übersprungen | https://github.com/RasitGueven/edvance-app/pull/52 |
