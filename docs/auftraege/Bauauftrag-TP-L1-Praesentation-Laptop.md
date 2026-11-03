# Bauauftrag TP-L1 — Präsentation füllt den Laptop-Bildschirm

**Repo:** Edvancev1 · **Basis:** `dev` (Stand 40bc8bf, 03.11.2026) · **PR gegen:** `dev` · **Branch:** `feat/tp-l1-laptop`

## Problem (geprüft)

Die Präsentation (`Praesentation.tsx`, Styles unter `src/styles/praesentation/`) ist für das iPad im Querformat gebaut, 1180 × 820, so wie in `e2e-praesentation` getestet. Die Ebene `.tp` füllt zwar den ganzen Bildschirm (`position: fixed; inset: 0`). Fast alle Maße stecken aber in festen `px`: 86 Schriftgrößen in px, Abstände, Karten. Die Szene ist zudem auf `max-width: 1590px` begrenzt.

Auf einem Laptop mit 1920 × 970 wirkt deshalb alles wie ein iPad-Layout in der Mitte eines großen Bildschirms: kleine Schrift und viel Leerraum. Dazu kommt die Browserleiste, die Höhe kostet.

Ein Gegenversuch in Chrome hat das bestätigt: Mit `zoom: min(innerWidth/1180, innerHeight/820)` auf `.tp` füllt die Präsentation den Bildschirm im iPad-Verhältnis. Die Verbindungslinien in Station 03 sitzen dabei weiter richtig.

## Ziel

Auf Laptop und großen Bildschirmen wird die Präsentation gleichmäßig größer, bis sie den Bildschirm füllt. Sie lässt sich im echten Vollbild zeigen, also ohne Browserleiste. Auf dem iPad, im Hoch- wie im Querformat, ändert sich nichts.

## Entscheidungen

1. **Referenz ist die iPad-Bühne 1180 × 820.** Der Faktor ist `f = max(1, min(innerWidth / 1180, innerHeight / 820))`.
   - Es wird nur vergrößert, nie verkleinert. Bei 1180 × 820 und bei 820 × 1180 ist `f = 1`, das Bild bleibt dort pixelgleich.
   - Eine Obergrenze gibt es nicht.
2. **Umsetzung über CSS `zoom` auf `.tp`.**
   - Ein Hook `useBuehnenZoom` setzt die Variable `--tp-zoom` am `.tp`-Element, das CSS übernimmt sie mit `zoom: var(--tp-zoom, 1)`.
   - Neu berechnet wird bei `resize` und bei `fullscreenchange`.
   - Den Faktor rechnet eine reine Funktion `buehnenFaktor(w, h)` aus, getestet mit Vitest.
   - Kein `transform: scale`, weil das die Messungen per `getBoundingClientRect` verfälschen würde.
3. **Viewport-Einheiten passen zur Bühne** (geändert am 03.11.2026 nach dem STOPP-Befund). Die rund 40 Stellen mit `vw`/`vh` in den Styles der Präsentation werden zu `calc(Xvw / var(--tp-zoom, 1))` bzw. `calc(Xvh / var(--tp-zoom, 1))`.
   - Keine Container-Einheiten: WebKit vergrößert `cqw`/`cqh` unter `zoom` doppelt, auch mit innerem Wrapper. Gemessen hat das der Agent.
   - Bei `f = 1` ergibt das genau den heutigen Wert, das iPad bleibt pixelgleich.
   - Prüfgröße: Das Verhältnis von Titelgröße zu Bühnenbreite ist bei 1920 × 1080 gleich wie bei 1180 × 820, Toleranz ±2 %, in Chromium und WebKit.
4. **Vollbild:**
   - **Einstieg:** Klickt man in `ReportPage` auf „Präsentation“, ruft der Klick-Handler selbst `document.documentElement.requestFullscreen()` auf, nicht erst ein Effekt danach, sonst fehlt die Nutzergeste. Das gilt nur, wenn `document.fullscreenEnabled` und die Seite nicht im Standalone-Modus läuft (`display-mode: standalone`, iPad vom Home-Bildschirm). Scheitert der Aufruf, wird das still geschluckt.
   - **Knopf im Kopf:** Neben dem X kommt ein Knopf „Vollbild“ (Icon `Maximize2`, Tooltip). Er ist nur sichtbar, wenn Vollbild möglich ist und gerade nicht läuft. Damit klappt es auch, wenn die Präsentation über einen Link geöffnet wurde, etwa aus der Liste LSA-Reports (`?ansicht=praesentation`), wo es keine Nutzergeste gibt.
   - **Schließen** der Präsentation beendet auch das Vollbild.
   - **Esc im Vollbild** beendet nur das Vollbild (Browserverhalten), die Präsentation bleibt offen. Esc ohne Vollbild schließt sie weiter wie bisher.
5. **Messungen in Bühnen-Pixeln** (geändert am 03.11.2026). In beiden Engines liefern `getBoundingClientRect` und `clientX`/`clientY` Bildschirm-Pixel, `offset*` und `scroll*` dagegen Bühnen-Pixel.
   - Wo beides gemischt wird, rechnet ein Helfer an einer Stelle um (`/ f`), in beiden Engines. Bekannt sind zwei Stellen: Ziehen mit der Maus in Station 03 (`useLernwegBedienung.ts`) und `holeInSicht` in `Station2.tsx`.
   - Alle übrigen Messstellen werden ebenfalls auf gemischte Maße geprüft.
   - Die Linien in Station 03 rechnen über Offsets und bleiben unverändert.
6. **Nur die Präsentation ändert sich.** Druckbogen, Report-Ansicht und Schüler-App bleiben unberührt.

## Umfang

- `src/components/edvance/praesentation/useBuehnenZoom.ts` (neu) mit `buehnenFaktor`.
- `Praesentation.tsx`: Hook einbinden, Vollbild-Knopf im Kopf (`Kopf.tsx`), Vollbild beim Schließen beenden.
- `ReportPage.tsx`: `requestFullscreen` im Klick-Handler von „Präsentation“.
- `src/styles/praesentation/*.css`: `zoom`, Container und `vw`/`vh` → `cqw`/`cqh`.
- i18n `praesentation.json`: Texte für den Vollbild-Knopf.

## Tests / Abnahme

1. **Vitest:**
   - `buehnenFaktor` mit 1180×820 → 1, 820×1180 → 1, 1024×700 → 1, 1440×900 → ≈1,098, 1920×1080 → ≈1,317, 2560×1440 → ≈1,756.
   - Vollbild-Knopf nur bei `fullscreenEnabled` und ohne laufendes Vollbild.
   - Schließen ruft `exitFullscreen`.
2. **Playwright** (`e2e-praesentation`, neue Spec `laptop.spec.ts`), Viewports 1440×900, 1920×1080 und 2560×1440, Fälle wie in `lernweg.spec.ts`:
   - `--tp-zoom` entspricht `buehnenFaktor`.
   - In keiner Station läuft etwas über.
   - Verhältnis Titel zu Bühnenbreite wie bei 1180 × 820 (±2 %).
   - Station 03: Linienenden liegen an den Kartenkanten (±1 px), auch in „Ganzen Lernweg zeigen“.
   - Alle bestehenden Specs bei 1180×820 und 820×1180 bleiben grün und unverändert. Zusätzlich je Station ein Screenshot-Vergleich dieser beiden Größen gegen den Stand vor dem Umbau.
   - Einmal mit `TP_WEBKIT=1`. Falls WebKit in WSL nicht installierbar ist, im Bericht vermerken.
3. **Abnahmebilder** je Station und Viewport unter `docs/report/praesentation/abnahme/laptop/`.

## Leitplanken

- Keine Migration, keine DB, keine Edge Function.
- Nur Design-Tokens, keine freien Hex-Werte und keine Inline-Styles. `--tp-zoom` per `style.setProperty` am `.tp`-Element ist die einzige Ausnahme.
- Keine Änderung an Inhalt, Reihenfolge oder Animationen der Stationen.
- PR gegen `dev`, nie `main`.
- Bei Kollision mit dem Code oder abweichendem Verhalten in WebKit: STOPP und Befund melden.

---

## Startprompt für den Agenten

```
Lies den Bauauftrag Bauauftrag-TP-L1-Praesentation-Laptop.md (liegt in Windows-Downloads, kopiere ihn ins Repo nach docs/auftraege/) und setze ihn vollständig um.
Basis: aktueller dev. Branch: feat/tp-l1-laptop. PR gegen dev, nie main.
Leitplanken: keine Migration/DB/Edge Function, nur Design-Tokens, iPad (1180x820 und 820x1180) muss pixelgleich bleiben; 1376x1032 darf vergrößert werden, ohne Überlauf.
Bei Kollision mit dem Code oder abweichendem WebKit-Verhalten: STOPP, Befund melden.
Am Ende: geänderte Dateien, Testergebnisse (vitest, playwright chromium + webkit), Pfad der Abnahmebilder, PR-Link.
```
