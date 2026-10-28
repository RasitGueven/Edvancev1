# Bauauftrag D · Live-Checkliste (nach dem Merge, mit Testkind und echtem Gerät)

Stand 27.10.2026. Voraussetzung: alle D-PRs gemergt, Migrationen eingespielt (erledigt), **Edge Function
`geraet_anmelden` deployt** (`bash ~/einspielen/D-1b-edge-function.sh`), Testkind mit laufendem Testvertrag und
Zugangscode (Schülerakte → „Geräte und Zugangscode“). Phantasiedaten.

Mit „✱“ markierte Fälle brauchen echte Auth-Sessions oder die Edge Function. Sie ließen sich vor dem Merge nicht
automatisch abnehmen; ihre Datenbanklogik ist in pgTAP abgedeckt.

## Anmeldung und Geräte (D8.1, D8.2)
- [ ] ✱ Handy: Code eingeben → Home-Start „Hi <Name>“. App schließen und neu öffnen → bleibt angemeldet.
- [ ] ✱ Tablet: derselbe Code → angemeldet. Schülerakte zeigt zwei Geräte.
- [ ] ✱ Drittes Gerät (Browser `/code`) → angemeldet; viertes Gerät → „Du bist schon auf drei Geräten angemeldet …“.
- [ ] ✱ Admin meldet das Handy in der Schülerakte ab → Handy zeigt beim nächsten Öffnen (oder nach Rückkehr in die
      App) „Dieses Gerät wurde abgemeldet …“ auf „Code eingeben“. Mit D1c sofort, ohne D1c spätestens nach einer Stunde.
- [ ] ✱ Fünf falsche Codes von einem Gerät → beim sechsten Versuch „Zu viele Versuche. Probier es in 15 Minuten …“,
      auch mit dem richtigen Code. Nach 15 Minuten geht es wieder.
- [ ] ✱ **IP-Kopf:** fünf falsche Codes per curl mit gefälschtem `x-forwarded-for: 9.9.9.9`, dann ein sechster Versuch
      ohne den Kopf. Ist der gesperrt, zählt die echte IP (gut). Sonst melden (siehe `~/einspielen/D-dashboard.md` 4).
- [ ] ✱ Neuer Code in der Schülerakte → der alte Code geht nicht mehr, angemeldete Geräte bleiben angemeldet.
- [ ] ✱ Auth-Log von `auth_mail`: Beim Einlösen geht **keine** Mail raus (generateLink ruft den Hook nicht).

## Üben und Coach (D8.3–D8.6)
- [ ] Start ohne Quest-Tage, ohne Termin-Wahl; „Starten“ geht sofort. (Ansichtstest grün.)
- [ ] ✱ Quest zum Nullprodukt (`gleichung_quadr_faktor`) dreimal durchspielen, sobald die Formate von A (A0b/A3) gemergt
      sind und D3 die Quest baut. In den Netzwerkaufrufen der App steht nur `home_uebung_melden(skill, anzahl, dauer)`,
      keine Antwort. Per dbread: `select * from home_uebung where student_id = '<testkind>'` → drei Zeilen ohne Antworten.
- [ ] ✱ Themenbaum: am Knoten „3×“ im türkisen Ring, Zustand unverändert; Blatt „Zuhause 3× geübt …“.
- [ ] ✱ Coach-Check-in (nach C0b und D2-Coach-Einbau): „3 Quests“ beim Skill, Vorschlag „Zeig's mir“; Übernehmen und
      Nicht heute werden gespeichert (`zeigs_mir`), höchstens ein Vorschlag je Kind und Session.

## Profil, Eddie (D8.7, D8.8)
- [ ] „Ich“: Pfad und Kompetenz getrennt, ohne Coach-Bestätigung nirgends „gemeistert“. (Ansichtstest grün.)
- [ ] ✱ Eddie: „Frage für meinen Coach“ → erscheint in der Coach-Kachel; „Besprochen“ räumt sie ab.

## Kiosk vor Ort (D8.9)
- [ ] Kiosk-Tablet im Browser: Login mit Platz-Konto → Warten/LSA/Session wie bisher. (Ansichtstests grün.)
- [ ] ✱ Ein Kinderkonto, das sich vor Ort im Browser mit Passwort anmeldet (kein Regelfall), landet weiter im Hub.

## Nativ (D8.10)
- [ ] ✱ Nach `eas login`: Android-Preview-Build installieren, SVG im Baum, Animationen, Schriften (Fraunces,
      Schibsted) prüfen; SecureStore hält die Session nach Neustart.
- [ ] ✱ iOS über TestFlight intern; iPad quer und hoch.
