# Reihe 1 · B0 Ist-Analyse Studio (Paket S0)

Stand 27.10.2026 · Grundlage origin/dev `74b5b4b8` (Edvancev1) und `e4cf268` (edvance-app), Prod per `dbread` (nur lesend).
Belege: `Datei:Zeile` auf origin/dev; `schema-erwartet.sql` = `supabase/schema-erwartet.sql` (Abzug von Prod).

## 1 · E1-Modell und Abbildung Video ↔ Kernidee

**Bestand**

| Objekt | Beleg | Kern |
|---|---|---|
| `erklaer_kernidee` (skill_key, nr 1–9, titel, status, pruef_version) | `migrations/20261007134931_erklaer_datenmodell.sql:18` | eine Kernidee je (skill_key, nr) |
| `erklaer_schritt` (kernidee_id, variante A/B/C, art erklaerung/beispiel, inhalt, formeln, bild, fehlbild_slugs) | ebd. `:59` | Karten-Erklärung je Variante |
| `erklaer_check` (kernidee_id, task_id, reihenfolge) | ebd. `:81` | Check-Aufgaben sind normale `tasks` mit `'check' = any(einsatz)` und `status = 'ready'` (`schema-erwartet.sql:1954`) |
| `erklaer_fortschritt` (append-only, Ergebnis gezeigt/richtig/falsch/signal, fehlbild_slug) | ebd. `:92`, Trigger `:121` | Runde, Variante, offener Check |
| `erklaer_start(p_session_id, p_student_id, p_skill_key)` | `schema-erwartet.sql:2896` | erste Kernidee, Wiederaufnahme, ruft `erklaer_zeigen` |
| `erklaer_zeigen(...)` | `schema-erwartet.sql:3081` | Check = `checks[((runde-1) % n) + 1]`, also **neue Runde = nächste Check-Aufgabe** |
| `erklaer_check_abgeben(...)` | `schema-erwartet.sql:1809` | `erklaer_bewerten` → fehlbild; richtig → nächste Kernidee; falsch → Signal nach `erklaer_runden_bis_signal` (`:2718`, Stellschraube `erklaerrunden_bis_signal`, Standard 2), sonst Variante passend zum Fehlbild |
| `erklaer_nachlesen(p_student_id, p_skill_key)` | `schema-erwartet.sql:2341` | ohne Checks, nur Freigegebenes |
| Signal an den Coach | `session_ereignis(..., 'check', ...)` in `erklaer_check_abgeben` (`:1850`) | `raum_signale` liest es |
| Fehlbild aus der Antwort | `erklaer_bewerten` → `lsa_fehlbild_match` über `acceptance.known_errors` `{falscher_wert: slug}` (`:1745`, `:5483`) | |

Prod: alle vier Funktionen existieren (`pg_proc`). Inhalt: **eine** Kernidee (`gleichung_quadr_faktor` nr 1, Platzhalter, entwurf, 2 Schritte, 1 Check). Die K8-Erklärsequenzen (`20261010132750_erklaer_k8_linfkt.sql`) sind nicht in Prod (nicht Sache von B).

**Festlegung Abbildung (verbindlich für B1–B6)**

| Video (Studio) | E1 | Regel |
|---|---|---|
| `studio_sequenz` (ein Video, Titel, Autor) | – | eine Sequenz kann mehrere Kernideen und mehrere Skills abdecken (V3, V7) |
| Beat `kernidee: "k2"` | `erklaer_kernidee (skill_key der Sequenz, nr 2)` | Kurzform für den Skill der Sequenz |
| Beat `kernidee: "fkt_quadr_scheitel:k1"` | `erklaer_kernidee (fkt_quadr_scheitel, nr 1)` | Langform für einen weiteren Skill |
| Beat-Bereich einer Kernidee | zusammenhängende Beats mit diesem Schlüssel | der Import verlangt Zusammenhang; Start = Beginn des ersten, Ende = Ende des letzten Beats (aus `kapitel.json`) |
| Mini-Check `nach_beat: bN` | Check-Aufgabe der Kernidee von bN in `erklaer_check` | wird `tasks`-Zeile mit `einsatz = {check}`, `known_errors` aus den Optionen |
| Mini-Check `zwillinge` (neu, optional) | weitere Check-Aufgaben derselben Kernidee | „dieselbe Frage mit anderen Zahlen“ = nächste Runde nach `erklaer_zeigen`. Ohne Zwilling kommt nach dem Rücksprung dieselbe Aufgabe (Import meldet das als Hinweis, sperrt nicht) |
| Fragetext je Welt | Aufgabe trägt den Skelett-Text | die Welt-Fassung ersetzt beim Ausliefern nur `prompt`; Zahlen-Sperre gilt auch hier |
| Option `ruecksprung: bK` + `fehlbild` | `studio_ruecksprung` | `erklaer_check_abgeben` liefert bei diesem Fehlbild `aktion = ruecksprung` |
| Kernidee existiert noch nicht | Import legt sie als `entwurf`, `quelle = mensch`, Titel aus dem ersten Beat an | die Karten-Erklärung bleibt Sache von E1; ein freigegebenes Video genügt in B6 als Darstellung (Anforderung §15.3) |

## 2 · E2a-Player in edvance-app

- `src/components/sequenz/SequenzPlayer.tsx:19` (Wege `sequenz`/`nachlesen`), Steuerung `steuerung.ts`, Schritte `SequenzSchritt.tsx`; eingehängt in `src/components/session/SessionAblauf.tsx:211`.
- Andockpunkt Video: Liefert `erklaer_start` ein `video`, zeigt der Player statt `SequenzSchritt` die Komponente `src/components/video/ErklaerVideo.tsx` (Modus `session`). Der Mini-Check läuft weiter über `LsaAufgabe` und `erklaer_check_abgeben`; bei `aktion = ruecksprung` springt `ErklaerVideo` auf den Beat.
- Zuhause (Auftrag D): `ErklaerVideo` im Modus `zuhause`, ohne Checks.
- Es gibt noch **kein Videopaket** (`package.json`: weder `expo-video` noch `expo-av`). B6 nimmt `expo-video` (Web und nativ gleich).
- Vorlage Bildschirm Video: `docs/reihe1/referenz/schueler-app-dummy.html:569–707` (Variante B, Video schrumpft nach links, Rückmeldung, Sprung, Frage mit anderen Zahlen).

## 3 · Formel-Satz

`tools/formeln-svg.mjs:28–60`: `mathjax-full` (TeX → SVG, `fontCache: 'none'`, `currentColor`). Läuft mit `liteAdaptor` ohne DOM und damit auch im Browser und im Remotion-Bundle. B3 zieht `texZuSvg` in ein gemeinsames Modul (`src/studio/remotion/formel.ts`) und färbt über das Token. Die App (`src/components/sequenz/formelSvg.ts`) bleibt unberührt, sie zeigt im Video nur MP4.

## 4 · Storage und Rollen

Prod `storage.buckets`: `screening-uploads` (privat), `task-assets` (öffentlich), `vertraege` (privat). Policies nur über `get_my_role()`.
→ Neuer privater Bucket **`studio`** (Audio, MP4, Kapitel, Untertitel, Poster); Lesen für Kinder nur über signierte URLs aus `mediathek_kind` / `erklaer_start`. Signieren in der Datenbank geht nicht; die URL signiert der Client mit der Pfadangabe aus der Funktion (Policy: Lesen erlaubt, wenn der Pfad zu einem freigegebenen Render gehört).

Rollen in Prod (`profiles.role`, `darf_pruefen`): admin Rasit, Tolunay; coach mit Prüfrecht Lena, Rasit (Coach-Konto). **Ashkan hat kein Konto.** Die Rolle „Gründer“ und „Autor“ gibt es nicht.
→ Neue Tabelle `studio_rolle (person_id, rolle in autor|gruender|fachlich)`, gepflegt von Admins. Autor = Eintrag `autor` oder admin. Verständlich bestätigen = `gruender`. Fachlich = `fachlich` oder `darf_pruefen()`. Regel „Prüfer ≠ Autor“ als Check in der Freigabe-Funktion und als Trigger auf `studio_freigabe`.
Live-Checkliste: Konto für Ashkan anlegen (Rolle coach oder admin, Eintrag `autor` und `gruender`), Tolunay `gruender`, Lena `fachlich`.

## 5 · Admin-Hülle

`src/components/edvance/admin/adminNav.ts:97–117`, Gruppe `inhalte` mit nur „Item-Pflege“. → Neuer Eintrag `studio`, Route `/admin/studio` (`src/App.tsx`, ProtectedRoute `admin`; Autoren ohne Admin-Rolle bekommen die Route über `coach` + `studio_rolle`, geprüft in der Datenbank).
Seitenmuster: Reiterleiste (`src/components/edvance/Reiterleiste.tsx`), `EdvanceTable` für Listen > 4 Spalten.

## 6 · Remotion, Rendern

- **Das Repo ist kein Next.js**, sondern Vite + React 18.3 als SPA auf Vercel (`package.json`, `vercel.json`). Server-Routen gibt es bisher nicht; Edge Functions liegen unter `supabase/functions/` (Deno, Supabase-Secrets).
- Festlegung: Stimme und Render als **Vercel Functions** unter `api/studio/*.ts` (der ElevenLabs-Schlüssel liegt laut Auftrag in Vercel). `vercel.json` schließt `/api/` von der SPA-Umleitung aus. Die Funktion prüft das Supabase-JWT des Aufrufers und die Rolle per RPC.
- Remotion `4.0.539` (`npm view`), `@remotion/player` peer `react >=16.8` → passt zu React 18.3. Paket unter `src/studio/remotion/` (Bausteine, Welten, Komposition), Einstieg für den Renderer `remotion/index.ts`.
- Rendern: `@vercel/sandbox` `3.9.0` aus `api/studio/render.ts` (Sandbox klont das Repo, `npx remotion render`, lädt hoch). Lokaler Rückfall `npm run studio:render -- <sequenz>` mit `@remotion/renderer` (lädt die Daten per anon-Key + Login, rendert, lädt hoch).
- Lizenz: kostenlose Lizenz (drei Gründer, Entscheidung Rasit 27.10.), kein Hinweis in der Oberfläche.

## 7 · Fehlbild-Katalog

Katalog = `fehlbild_labels.slug` (162 Zeilen in Prod), nicht ein Feld je Aufgabe. Es fehlen in Prod alle Schlüssel aus Konzept §8 und aus dem Referenz-Skript:

```
qf_quadrat_negativ, qf_streckfaktor_umgekehrt, qf_verschiebung_vorzeichen, qf_ergaenzung_nicht_abgezogen,
qf_nur_positive_loesung, qf_null_vergessen, qf_halbes_p_nicht_quadriert, qf_scheitel_statt_nullstelle   → legt A in A2 an
haelfte_statt_wurzel, flaeche_mit_umfang_verwechselt, quadriert_statt_wurzel                             → nur Referenz-Skript
```

Ähnliche vorhandene Schlüssel: `wurzel_halbiert` (= haelfte_statt_wurzel). Bis A liefert, lehnt der Import in Prod diese Schlüssel ab; die Tests prüfen gegen einen Test-Katalog.

## 8 · Projekt-Ref Prod

`ztcppihxqcphlqaguhma` (aus `VITE_SUPABASE_URL` in `.env`; `supabase/config.toml` trägt nur `project_id = "Edvancev1"`). Die Einspiel-Skripte prüfen, dass `$DATABASE_URL` diese Ref enthält und `current_database() = postgres`.

## 9 · Abnahme-Umgebung

pgTAP läuft in der CI (`.github/workflows/schema.yml:114–138`, PG 16, alle Migrationen + `seed.sql`) und lokal in einem eigenen Wegwerf-Cluster `~/wegwerf-db-reihe1b` (eigener Port). Kein `supabase start`, nicht die Shadow-DB. Schreibende Abnahmefälle laufen dort; Storage, Vercel Sandbox und ElevenLabs kommen in die Live-Checkliste.

## 10 · Befunde und offene Punkte

1. E1-Modell und E2a-Player existieren (Prod und origin/dev) → kein Haltepunkt für B6.
2. Ashkan hat kein Konto (Live-Checkliste).
3. `ELEVENLABS_API_KEY` fehlt lokal (`~/Edvancev1/.env.local` gibt es nicht) → B2 mit Platzhalter-Anbieter.
4. Kein Next.js: Server-Routen als Vercel Functions (`api/`), neu im Repo.
5. Check-Aufgaben brauchen `status = 'ready'`. Die Studio-Freigabe (fachlich) setzt die Mini-Check-Aufgaben der Sequenz auf `ready` (B5).
6. Referenz-Skript: zehn Beats (nicht neun), Schlüssel außerhalb des Katalogs (siehe 7).
