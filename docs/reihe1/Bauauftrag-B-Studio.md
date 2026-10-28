# Bauauftrag B · Edvance-Studio (Erklärvideos) und die acht Videos der Reihe 1

Stand 27.10.2026 · Repos **Edvancev1** (Studio, Remotion, Stimme, Render) und **edvance-app** (Video in der Session und zuhause) · Grundlage: `docs/reihe1/Anforderung-Studio.md` und `docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md` §8–9

**Vorher (Rasit, 5 Minuten)**
1. `reihe1-pakete.zip` in den Windows-Downloads-Ordner legen.
2. ElevenLabs: bezahlter Plan mit kommerziellen Rechten. Den Schlüssel als `ELEVENLABS_API_KEY` in Vercel (Projekt Edvancev1, alle Umgebungen) und lokal in `~/Edvancev1/.env.local` eintragen. Nie ins Repo. Fehlt er, baut der Agent trotzdem alles und testet die Stimme mit einem Platzhalter; echte Stimmen kommen, sobald der Schlüssel da ist.
3. `EINSPIELEN = rasit` stehen lassen oder auf `orchestrator` ändern.
4. Den Block in eine neue Claude-Code-Session in WSL kopieren (eigener Zellij-Tab).
5. Ashkan danach: die acht Skripte aus `docs/reihe1/B/skripte/` im Studio über „Skript einfügen“ einfügen und die Stimme auswählen (Anforderung §15.1).

---

```text
Du bist der Orchestrator für Bauauftrag B der Sessionreihe 1 bei Edvance. Du führst alle Phasen B0 bis B9 nacheinander bis zum Ende durch, ohne nach jeder Phase zu fragen. Du stoppst nur an den unten genannten Haltepunkten.

EINSPIELEN = rasit

ZIEL
Das Studio aus der Anforderung (Pakete S0–S6) ist gebaut: Ashkan fügt ein Skript ein, vertont, sieht die Vorschau, rendert per Knopf, reicht ein. Gründer und Lena geben frei. Kinder sehen freigegebene Videos in der Session mit Mini-Checks und Rücksprung und zuhause in der Mediathek. Dazu die zwei neuen Bausteine für quadratische Funktionen und die acht Skripte V1–V8 der Reihe als prüfbare Entwürfe.

SCHRITT 0 · UNTERLAGEN, WORKTREES
1. Repos ~/Edvancev1 und ~/edvance-app (sonst suchen), in beiden git fetch.
2. Worktrees nur für diesen Auftrag (andere Aufträge laufen parallel):
   git -C ~/Edvancev1 worktree add ../Edvancev1-B -b feat/rasit-reihe1-b0 origin/dev
   git -C ~/edvance-app worktree add ../edvance-app-B -b feat/rasit-reihe1-b6-app origin/dev
   Existieren sie: weiterverwenden. Nur dort arbeiten. npm ci, .env/.env.local aus dem Haupt-Checkout kopieren (nie committen).
3. mkdir -p docs/reihe1 && unzip -o "/mnt/c/Users/$WINUSER/Downloads/reihe1-pakete.zip" -d docs/reihe1 (beide Worktrees). Fehlt die Datei: melden und STOPP.
4. Lies vollständig: CLAUDE.md beider Repos, docs/reihe1/Anforderung-Studio.md (verbindlich), Konzept-Sessionreihe-1-und-Bauformen.md §8 und §9, dieses Dokument. Liegt studio-dummy.html im Repo oder in Downloads, öffne ihn als Vorlage für die Oberfläche (Abweichungen: Anforderung §11).
5. Lege docs/reihe1/B/fortschritt.md an und schreib nach jedem Schritt eine Zeile hinein (Datum, Phase, Ergebnis, PR-Link).

LEITPLANKEN (nicht verhandelbar)
- CLAUDE.md gilt vollständig. Keine Hex-Werte außerhalb der Tokens (auch in Remotion-Bausteinen und Welten-Skins: eigener Token-Block), keine Inline-Styles, Texte über die Textdateien.
- Kein ANTHROPIC_API_KEY, kein Chat mit Claude im Studio. Skripte kommen per „Skript einfügen“ (Anforderung §4).
- Der ElevenLabs-Schlüssel nur serverseitig aus der Umgebung; nie im Browser, nie im Repo, nie in Logs.
- Datenbank lesen nur über dbread, keine schreibende Abfrage gegen Prod.
- DDL nur als Migration nach supabase/migrations/ mit Rollback nach supabase/rollback/. Keine löschenden Anweisungen auf Inhalte.
- Vor Änderungen an Spalten oder an erklaer_start/erklaer_check_abgeben: pg_proc-Scan aller Funktionen, die sie nutzen (Ergebnis in die PR).
- Zweitprüfung jeder Schemaänderung durch einen frischen Subagenten ohne deinen Kontext (nur Migration, Anforderung §12 und Konzept §9, Frage „Was ist falsch, was fehlt, was bricht?“). Ergebnis an die PR.
- Einspielen:
  - EINSPIELEN = rasit: fertigen Befehl als ~/einspielen/B-<nr>-<name>.sh ablegen (Zielprüfung: `psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres` und ein Test, dass $DATABASE_URL die Projekt-Ref von Prod enthält, die du in der Ist-Analyse aus supabase/config.toml bzw. .env festgestellt hast; dann per dbread die vorausgesetzten Objekte anderer Aufträge prüfen, sonst Abbruch mit klarer Meldung && Migration && History-Eintrag nach Repo-Muster && tools/schema-snapshot.sh, mit && verkettet), in PR und Protokoll schreiben, Jede Migration bekommt eine eigene Prüfabfrage (bei Datenmigrationen eine Zählabfrage), die als Kommentar im Skript steht. Warte, indem du diese Abfrage per dbread wiederholst: je Warteschritt ein Bash-Aufruf `sleep 540 && dbread …` mit timeout 600000 ms, ins Protokoll nur eine kurze Zeile je Stunde. Arbeite in der Wartezeit an allem weiter, was nicht davon abhängt. Nach 48 Stunden ohne Ergebnis: Bericht mit dem Stand schreiben, dann STOPP.
  - EINSPIELEN = orchestrator: nach grüner Zweitprüfung genau diesen Befehl selbst ausführen, per dbread prüfen, protokollieren; bei Fehler Rollback, melden, STOPP für diese Phase.
- Nach jedem Einspielen und nach jedem Rebase: Types in beiden Repos neu generieren (Befehle laut Repo) und committen. Generierte Dateien nie von Hand zusammenführen.
- Je Phase ein Branch auf dem vorherigen (feat/rasit-reihe1-b1-modell usw.), je Phase eine PR gegen dev, nie main, mit „Baut auf PR #… auf“. Nie selbst mergen, nichts unter .github/. Vor jeder PR git fetch && git rebase origin/dev; gemeinsame Dateien (DATENVERTRAG.md, schema.sql, Types, Tokens) so zusammenführen, dass beide Seiten erhalten bleiben.
- Tests: npm run typecheck && npm test nach jeder Änderung; pgTAP wie im Repo üblich; edvance-app vor jeder PR npm run test:views.
- Abnahme-Umgebung: Schreibende Tests laufen dort, wo das Repo pgTAP heute ausführt (die Ist-Analyse klärt das), sonst in einem lokalen Supabase-Stack (`supabase start`, Docker), falls vorhanden, mit allen Migrationen und einem Seed (Testkind Batu, eine freigegebene Reihe). Die alte Shadow-DB auf 127.0.0.1 nicht verwenden. Gibt es beides nicht, kommen Abnahmefälle, die Schreibrechte brauchen, in die Live-Checkliste nach dem Merge und sind im Bericht so markiert.
- Warten auf andere Aufträge nach Konzept §9 („Schnittstellen-PR zuerst“, „Warten auf eine Datenbank-Funktion“). Fremde Funktionen erkennst du am Namen in pg_proc und am Kommentar 'reihe1 fertig'; die Signatur liest du im DATENVERTRAG im Worktree des Besitzers (../Edvancev1-A, ../Edvancev1-B usw.). Deine eigenen fertigen Funktionen markierst du in der Migration mit `comment on function … is 'reihe1 fertig';`. Fremde Funktionen rufst du nur aus plpgsql auf.
- Höchstens ein Subagent gleichzeitig. Skripte prüft nie der Agent, der sie geschrieben hat.
- Schnittstellen: Du besitzt alles, was im Konzept §9 bei B steht. Tabellen und Funktionen von A, C und D fasst du nicht an. In der Schüler-App besitzt du die Videowiedergabe (Komponente ErklaerVideo) und die Mediathek-Daten; Auftrag C ruft deine Komponente in der Session auf, Auftrag D zuhause.
- Lizenz: Die Gründer sind drei Personen, damit gilt die kostenlose Remotion-Lizenz (Entscheidung Rasit 27.10.). Keine Lizenzhinweise in die Oberfläche.

HALTEPUNKTE
- Warten auf eingespielte Migrationen, auf die Fehlbild-Schlüssel von A (für B8) und auf kompetenz_offen von D (für B6).
- Fehlende Unterlagen in Schritt 0.
- B0 findet, dass das E1-Modell (erklaer_start, erklaer_check_abgeben, erklaer_nachlesen, Kernideen) oder der E2a-Player nicht existiert: Befund ins Protokoll, B1–B5 trotzdem bauen (sie hängen nicht davon ab), B6 erst, wenn E1 auf origin/dev bzw. in Prod existiert (Warteschleife wie oben).
- Eine Phase scheitert nach zwei Korrekturrunden an derselben Prüfung: Befund ins Protokoll, mit der nächsten unabhängigen Phase weiter.

B0 · IST-ANALYSE (Paket S0, nur lesen)
docs/reihe1/B/ist-analyse.md mit Belegen (Datei:Zeile auf origin/dev oder dbread samt Ausgabe):
1. E1-Modell: Tabellen und Funktionen der Erklärsequenz, Kernideen, Check-Aufgaben, Varianten je Fehlbild, Signal an den Coach. Abbildung „Videosequenz ↔ Kernidee ↔ Beat-Bereich“ als Tabelle festlegen.
2. E2a-Player in edvance-app: Komponenten, wo ein Video samt Mini-Check und Rücksprung andocken kann.
3. Formel-Satz (MathJax-Pipeline aus E1.4): wiederverwendbar in Remotion?
4. Supabase Storage: Buckets, Rechte, signierte URLs; Rollen Autor, Admin, Lena, Gründer.
5. Admin-Hülle: Navigation, Seitenmuster, wo /admin/studio unter „Inhalte“ hinkommt.
6. Remotion: passende Version für das Next.js des Repos, Player im Admin, Rendern über Vercel Sandbox (@vercel/sandbox) aus einer Route, lokaler Rückfall über einen Befehl.
7. Fehlbild-Katalog (known_errors): welche Schlüssel aus Konzept §8 fehlen (die legt Auftrag A in Phase A2 an; bis dahin lehnt der Import sie in Prod ab).
8. Projekt-Ref von Prod (aus supabase/config.toml bzw. .env) für die Zielprüfung.
PR „Reihe 1 · B0 Ist-Analyse“ (nur docs).

B0b · SCHNITTSTELLEN-PR (edvance-app, klein, zuerst zu mergen)
src/components/video/ErklaerVideo.tsx als Platzhalter mit den festen Props aus Konzept §9 (Video, Kapitel, Beat-Bereich, Mini-Checks, Modus session | zuhause); ohne Video zeigt er einen ruhigen Hinweis. Props auch im DATENVERTRAG (Edvancev1). PR „Reihe 1 · B0b Schnittstellen“ mit „Bitte zuerst mergen, C und D warten darauf.“ Dann weiter.

B1 · DATENMODELL, IMPORT, BEAT-EDITOR (Paket S1)
Datenmodell nach Anforderung §12 (an E1 angedockt, wie in B0 festgelegt), Rollenregel „Prüfer ≠ Autor“ in der Datenbank. Seite /admin/studio: Sequenzliste, Sequenzkopf, Reiter Skript, Mini-Check, Freigabe, Welten-Reiter (Skelett, Fußball, Gaming, Musik). „Skript einfügen“ mit allen Importprüfungen aus §4 (Baustein bekannt, Parameter gültig, Beat-IDs eindeutig, Sprungmarke ≤ 40 Zeichen, Rücksprünge gültig, Zahlen-Sperre, keine Formeln im Sprechtext, Fehlbild im Katalog). Die Prüfung ist eine eigene, getestete Funktion, die auch ohne Oberfläche läuft (für B8). Mini-Checks aus dem Import werden Check-Aufgaben im E1-Modell.
Abnahme: docs/reihe1/referenz/quadratwurzel-skript.json (vollständiges Beispiel mit neun Beats und Mini-Check) importiert ohne Befund; docs/reihe1/referenz/quadratwurzel-skript-fehler.json (Musik-b3 sagt „fünfzig“) sperrt nur die Musik-Variante. Im Test prüft der Import die Fehlbild-Schlüssel gegen einen Test-Katalog mit den Schlüsseln aus den beiden Dateien und aus Konzept §8; gegen den echten Katalog erst, wenn A die Schlüssel in Prod hat.
PR, Einspielen laut Regel.

B2 · STIMME (Paket S2)
Server-Route nach §5: ElevenLabs „with timestamps“, mehrsprachiges Modell, feste Stimme aus einer Einstellung (Stimmen-ID änderbar durch Admins), Aussprache-Wörterbuch, Satz davor und danach als Kontext, Fingerabdruck aus Stimme, Modell und Satz als Dateiname, Ablage privat in Supabase Storage, „Fehlende erzeugen“. Aufrufen dürfen nur Autor und Admin. Ohne Schlüssel: Platzhalter-Anbieter mit stummer Datei passender Länge, deutlich als Platzhalter markiert, damit B3–B5 testbar sind.
Abnahme: Ein unveränderter Satz wird nie neu vertont; eine Variante ohne eigenen Satz übernimmt die Datei des Skeletts.
PR, Einspielen laut Regel.

B3 · REMOTION UND VORSCHAU (Paket S3)
Remotion-Paket im Repo (Ort laut B0), Startbausteine Titelkarte, Raster, Term-Zeile, Merksatz, Endkarte (Variante B: Video schrumpft nach links), Formeln über die E1-Pipeline, Welten als Skin (Farben aus einem Token-Block, Einheiten und Gegenstände je Welt), ruhige Bewegung, reduzierte Bewegung. Jeder Beat ist eine Sequence, deren Länge aus der Audiodatei kommt. Vorschau im Studio mit dem Remotion Player, Zeitleiste der Beats als Kapitel, Klick springt.
Abnahme: Quadratwurzeln in allen vier Welten in der Vorschau.
PR.

B4 · RENDERN (Paket S4)
Render-Auftrag je Welt per Knopf über Vercel Sandbox: MP4 (H.264, 1920 × 1080, -preset veryfast), kapitel.json, untertitel.vtt, Vorschaubild. Auftrag mit Status und Fingerabdruck; „Render veraltet“, wenn sich Inhalte geändert haben. Lokaler Rückfall: npm run studio:render -- <sequenz> lädt die Daten, rendert und lädt hoch (für Ashkans Mac).
Abnahme: MP4 und Kapitel stimmen auf 0,1 s mit der Vorschau überein (lokal gerendert geprüft, ohne Hochladen nach Prod; Hochladen und Server-Render nach dem Merge in der Live-Checkliste).
PR, Einspielen laut Regel.

B5 · PRÜFUNG UND FREIGABE (Paket S5)
Reiter Freigabe nach §8: geschrieben, verständlich bestätigt (Gründer außer dem Autor), fachlich geprüft (Lena oder Rasit, „passt nicht“ immer an einem Beat mit Kommentar), Varianten-Texte je Welt, Stimme vollständig, Render aktuell. Jede Änderung setzt die betroffene Freigabe zurück; Kinder sehen bis zur neuen Freigabe die alte Fassung.
Abnahme: Anforderung §14 Fälle 4, 5 und 8.
PR, Einspielen laut Regel.

B6 · AUSSPIELUNG (Paket S6, beide Repos)
1. Edvancev1: erklaer_start liefert zur Kernidee das Video der Welt des Kindes (sonst Skelett) mit Beat-Bereich und Kapiteln; erklaer_check_abgeben bekommt die Antwortart ruecksprung (Beat, Rückmeldung, danach dieselbe Frage mit anderen Zahlen); ohne Rücksprung gilt die bestehende Variantenlogik. Nach erklaerrunden_bis_signal Runden das Signal an den Coach wie bisher.
2. mediathek_kind(p_kind) nach Konzept §9: alle freigegebenen Videos der offenen Kompetenzen, signierte URLs, Kapitel. „Offen“ liefert kompetenz_offen von Auftrag D (warten nach Konzept §9, bis dahin gegen die Signatur bauen und mit Attrappe in der Testtransaktion testen). Zuhause speichert mediathek_angesehen höchstens „angesehen“, keine Mini-Checks.
3. eddie_index(p_kind): freigegebene Sequenzen mit Sprungmarken. Eine Sequenz im Entwurf erscheint nie.
3a. Alle fertigen Funktionen bekommen den Kommentar 'reihe1 fertig'.
4. edvance-app: die echte Komponente src/components/video/ErklaerVideo.tsx hinter den Props aus B0b (normaler Videoplayer mit MP4, Untertitel-Schalter, Sprung auf Kapitel, Mini-Check-Ebene mit Rücksprung, Modus „zuhause“ ohne Checks). Sie wird im E2a-Ablauf der Session eingesetzt, nach dem Schüler-App-Dummy (Bildschirm Video). Läuft in der Web-Ausgabe und nativ gleich.
Abnahme: Anforderung §14 Fälle 6, 7, 9 und 10.
Zwei PRs (Backend, App), Einspielen laut Regel.

B7 · NEUE BAUSTEINE FÜR DIE REIHE
1. Koordinatensystem mit Parabel: Achsen, Raster, Parabel zeichnen, strecken, stauchen, spiegeln, verschieben (animiert zwischen zwei Parametersätzen), Scheitel und Nullstellen markieren, Gerade y = c, Wertetabelle daneben.
2. Raster als Flächenmodell: Quadrat x · x plus zwei Streifen b/2 · x, fehlendes Eckquadrat (b/2)² einblenden, für die quadratische Ergänzung.
Beide mit Parametern, Vorschau in allen vier Welten, Tests, die Parameter prüfen. Abnahme durch Ashkan steht als Punkt in der Live-Checkliste.
PR.

B8 · SKRIPTE V1–V8 DER REIHE
1. Schreib die acht Skripte nach Konzept §8 im Importformat aus Anhang A: Skelett, 6–12 Beats, 2–3 Mini-Checks mit Rücksprung, Fehlbild-Schlüssel aus dem Katalog bzw. aus Konzept §4, Bausteine aus B3 und B7. Sprache für 14- bis 16-Jährige, ein Gedanke je Beat, Zahlen ausgeschrieben im Sprechtext, Formeln nur in den Bildparametern.
2. Prüf jedes Skript mit der Importprüfung aus B1 als Test (alle acht bestehen), mit dem Test-Katalog aus Konzept §8 und den Schlüsseln, die A in seinem DATENVERTRAG bzw. in ../Edvancev1-A/docs/reihe1/A/ führt. Nur Schlüssel verwenden, die dort stehen.
3. Ein frischer Subagent ohne deinen Kontext prüft jedes Skript fachlich (stimmt jede Rechnung, führt jeder Rücksprung an die Stelle, die das Fehlbild erklärt, ist der Mini-Check ohne Video lösbar?) und sprachlich. Befunde einarbeiten, Ergebnis nach docs/reihe1/B/skripte/pruefung.md.
4. Ablage docs/reihe1/B/skripte/V1.json … V8.json. Ashkan fügt sie im Studio ein (keine Schreibzugriffe auf Prod durch dich). Vor dem Bericht wartest du, bis die Fehlbild-Schlüssel von A in Prod sind (Prüfabfrage per dbread), und prüfst alle acht Skripte noch einmal gegen den echten Katalog.
PR „Reihe 1 · B8 Skripte V1–V8“.

B9 · ABNAHME UND BERICHT
1. Alle Abnahmefälle der Anforderung §14 per Test, Ansichtstest oder dbread, Ergebnis ins Protokoll.
2. Ansichtstests: Studio bei 1440 × 900 und iPad quer 1180 × 820; ErklaerVideo bei 1180 × 820, 1024 × 768, 820 × 1180 und 390 × 844. Bildschirmfotos nach docs/reihe1/B/abnahme/.
3. docs/reihe1/B/live-checkliste.md für die Zeit nach dem Merge: Schlüssel gesetzt, Stimme gewählt, V1 einfügen, vertonen, Server-Render, Freigabe durch Tolunay und Lena, Session-Wiedergabe mit Rücksprung, Mediathek zuhause.
4. docs/reihe1/B/bericht.md: PRs in Merge-Reihenfolge, Migrationen (eingespielt oder wartend), Abnahme, offene Punkte (z. B. Stimme, Welten). Im Terminal höchstens 20 Zeilen. Dann STOPP.
```
