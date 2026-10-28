# Bauauftrag B · Live-Checkliste nach dem Merge

Stand 27.10.2026. Alle Migrationen von B sind in Prod (siehe `fortschritt.md`). Diese Liste prüft, was lokal nicht prüfbar war:
Vercel-Umgebung, ElevenLabs, Vercel Sandbox, Storage-Upload und das Zusammenspiel auf dem iPad.
Je Punkt: erledigt (Datum, wer) oder Befund.

## 0 · Vorbereitung (Rasit)

- [ ] PRs in dieser Reihenfolge gemergt: edvance-app #50 (B0b) → Edvancev1 #329 (B0) → #336 (B1) → #337 (B2) → #340 (B3) → #343 (B4) → #346 (B5) → #351 (B6) → #354 (B7) → #355 (B8) → B9; edvance-app #56 (B6 App) nach #50.
- [ ] Vercel (Projekt Edvancev1, alle Umgebungen): `ELEVENLABS_API_KEY`, `STUDIO_GIT_TOKEN` (GitHub-Token mit Lesezugriff auf das Repo); `VITE_SUPABASE_URL` und `VITE_SUPABASE_ANON_KEY` stehen den Functions zur Verfügung.
- [ ] Vercel Sandbox im Team freigeschaltet (Functions bekommen `VERCEL_OIDC_TOKEN`).
- [ ] Konto für Ashkan anlegen (Rolle coach; Admin nur, wenn gewünscht).
- [ ] Rollen im Studio (als Admin, z. B. im SQL-Editor als Admin-Aufruf oder später über die Oberfläche):
      `studio_rolle_setzen(<Ashkan>, 'autor', true)`, `studio_rolle_setzen(<Ashkan>, 'gruender', true)`,
      `studio_rolle_setzen(<Tolunay>, 'gruender', true)`, `studio_rolle_setzen(<Rasit>, 'gruender', true)`,
      `studio_rolle_setzen(<Rasit>, 'fachlich', true)`, `studio_rolle_setzen(<Lena>, 'fachlich', true)`.
      Prüfabfrage (dbread): `select p.full_name, r.rolle from studio_rolle r join profiles p on p.id = r.person_id order by 1, 2;`

## 1 · Stimme

- [ ] Ashkan wählt drei Stimmen, vertont mit jeder b1–b3 eines Skripts; die Gründer entscheiden blind (Anforderung §15.1).
- [ ] Rasit trägt die Stimmen-ID im Studio ein (Panel Stimme, nur Admin).
- [ ] V1 einfügen (`docs/reihe1/B/skripte/V1.json`, „Skript einfügen“ → Prüfen → Speichern). Erwartet: keine Sperre, Hinweise höchstens zu Zwillingen.
- [ ] „Fehlende erzeugen“: alle Sätze vertont, kein Platzhalter mehr; ein zweiter Klick erzeugt nichts neu (Fingerabdruck).
- [ ] Einen Satz ändern, speichern: nur dieser Satz ist wieder offen (Abnahmefall 3).

## 2 · Vorschau und Render

- [ ] Vorschau spielt mit Stimme, Kapitel springen, reduzierte Bewegung wirkt.
- [ ] Server-Render Skelett: Status wartet → läuft → fertig; Dateien unter `studio/render/<seq>/skelett/<fp>/<auftrag>/`.
      Bei Fehler `installation`: Paketliste in `api/studio/render.ts` (`CHROME_PAKETE`) prüfen; Rückfall lokal:
      `STUDIO_EMAIL=… STUDIO_PASSWORT=… npm run studio:render -- <sequenz-id> --welt skelett` (Ashkans Mac).
- [ ] MP4 abspielen: Kapitel stimmen mit der Vorschau überein; Untertitel stimmen mit der Stimme überein.
- [ ] Satz ändern → „Render veraltet“ erscheint.
- [ ] Bausteine B7 (Parabel, Flächenmodell) in allen vier Welten: Abnahme durch Ashkan anhand
      `docs/reihe1/B/abnahme/b7/bausteine-*.jpg` und im Studio mit `docs/reihe1/B/abnahme/b7/bausteine-demo.json`.

## 3 · Prüfung und Freigabe

- [ ] Ashkan reicht ein. Ashkan kann nicht selbst fachlich/verständlich prüfen (Knopf gesperrt, Abnahmefall 4).
- [ ] Lena: „passt nicht“ an einem Beat mit Kommentar → zurück an Ashkan, Kommentar steht am Beat (Fall 5).
- [ ] Ashkan ändert, rendert neu, reicht ein; Tolunay bestätigt verständlich, Lena fachlich → Skelett „Für Kinder sichtbar“.
- [ ] Prüfabfrage (dbread): `select welt, version_skelett, freigegeben_am from studio_ausgabe where zurueckgezogen_am is null;`
- [ ] Die Mini-Check-Aufgaben sind `ready`: `select t.status, count(*) from tasks t where t.source = 'edvance_studio' group by 1;`

## 4 · Ausspielung

- [ ] Testkind Batu (Welt Skelett): Session mit Skill `fkt_quadr_parabel` → Erklärung kommt als Video; am Anker steht der Mini-Check rechts.
- [ ] Falsche Antwort mit Rücksprung (V1: −16 bei (−4)²) → Rückmeldung, Sprung zu „Ein Quadrat ist nie negativ“, danach (−5)² (Fall 6).
- [ ] `studio_welt_setzen(<Batu>, 'fussball')` ohne freigegebene Fußball-Fassung → Batu sieht das Skelett (Fall 7).
- [ ] Nach einer Änderung an der freigegebenen Sequenz sieht Batu bis zur neuen Freigabe die alte Fassung (Fall 8).
- [ ] Zuhause (Auftrag D): Mediathek zeigt nur freigegebene Videos offener Kompetenzen, keine Mini-Checks; nach dem Abspielen
      nur ein Eintrag in `studio_angesehen` (Fall 9).
- [ ] Eddie (Auftrag D) verlinkt nur freigegebene Sequenzen (Fall 10): `select count(*) from eddie_index(<Batu>);`
- [ ] Kopfhörer je Platz vorhanden.

## 5 · Danach

- [ ] Prüfzeit von Lena je Video notieren (Anforderung §15.4).
- [ ] V2–V8 einfügen, vertonen, rendern, prüfen.
