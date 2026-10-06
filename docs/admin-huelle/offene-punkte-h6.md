# Offene Punkte H6 · Coach-Hülle

**Stand:** 06.10.2026 · Branch `feat/rasit-coach-h6-huelle`

1. **Erstgespräch und Screening-Ergebnisse nicht in der Leiste.** `intake_sessions` und
   `screening_tests` haben auf Prod 0 Zeilen (dbread, 06.10.2026); C0 nennt beide nur als
   Routen. `/coach/intake` und `/coach/screening-results` bleiben bestehen, außerhalb der
   Layout-Route, mit eigenem Rahmen (`EdvanceNavbar`, harte deutsche Texte). Die Kacheln im
   Coach-Dashboard verlinken sie weiter. Entscheiden: löschen oder in die Hülle holen.
2. **`/coach/reports` (ReportsPage)** ist seit X0 nur Admin, nicht in der Coach-Leiste und
   nicht in der Admin-Leiste („Eltern-Reports“ ist dort „bald“). Bleibt außerhalb der
   Layout-Route mit `EdvanceNavbar`. Offen aus X0: Fällt die Altseite neben `eltern_reports` weg?
3. **Entscheidungsleiste der Prüfansicht überdeckt die Leiste.** `Entscheidungsleiste` und
   `EntscheidungsMeldung` (`src/components/edvance/pruefen/`, L5) sind `fixed inset-x-0` bzw.
   am Fenster zentriert. In der Hülle liegt die Leiste unten über dem Fuß der Seitenleiste
   („Abmelden“ bei 1440 und 1180 verdeckt, siehe Fotos). Vorschlag für L5: links um die
   Leistenbreite einrücken (`--container-leiste` / `--container-leiste-schmal`, in der
   Schublade 0) oder AppShell stellt dafür eine Variable bereit. Nicht angefasst, weil L5
   diese Dateien gerade ändert.
4. **Prüfansicht ohne PageHeader.** Der Kopf der Seite ist `PruefKopf` (L5); ein zusätzlicher
   PageHeader hätte den Titel doppelt gezeigt.
5. **`AdminHeader.tsx` bleibt.** `VertragPage` (Fokus-Seite Vertragsabschluss, nur Admin) nutzt
   ihn noch, ebenso `EdvanceNavbar`. Die Seite ist nicht Teil der Coach-Sicht.
6. **`EdvanceNavbar`** steht noch auf Schüler-/Eltern-Seiten (gewollt), `ScreeningSession`
   (Schüler, Coach als Beobachter), `VertragPage` (mit Eltern am iPad) und den Altseiten aus 1
   und 2.
7. **Live-Sicht `/coach/session/*`** gibt es auf dev noch nicht (C1). Die Regel steht:
   `istFokusSeite` in `coachNav.ts`, ausgewertet in der Rollenweiche (`AdminLayout`). Hängt C1
   die Route außerhalb jeder Layout-Route ein, greift sie ohnehin nicht.
8. **Druckbild des Eltern-Reports** hat keine eigene Route: `/admin/report/:sessionId` druckt
   aus der Hülle; Leiste und Kopf tragen `print-hide`, `AppShell` schaltet im Druck auf
   `print:block`. Getestet ist nur die Klasse an der Leiste, nicht das Druckbild selbst.
9. **Zurück-Link im Eltern-Report** zeigt für Coaches weiter auf `/admin/leads` (nur Admin,
   Coach landet per Umleitung auf `/coach`). Unverändert übernommen, keine Fachlogik.
10. **Kleine Knöpfe im Coach-Dashboard** (`size="sm"`, 36 px) aus C0 bleiben: nur Rahmen umgebaut.
    Ebenso harte deutsche Texte im Dashboard-Inhalt (außer dem Titel, der jetzt über i18n läuft).
11. **`useImShell`** wird nicht mehr benutzt (alle Seiten stehen für Admin und Coach in einer
    Hülle). Liegt in `shell/` (H5-Zone), deshalb nicht gelöscht.
