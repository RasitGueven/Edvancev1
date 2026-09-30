# Retro 2026-09-30 — Schülerakte S2 (Menü „Schüler“: Board und Akte)

## Was gebaut wurde
- **Routen:** `/admin/akten` (Board) und `/admin/akten/:studentId` (Akte), eine Routenfamilie für Admin und Coach.
- **Einstieg:** Kachel „Schüler“ im AdminDashboard (vorher inaktive Platzhalter-Kachel „Schülerakte“) und im CoachDashboard.
- **Board:**
  - eine Spalte je vorhandener Klassenstufe, seitlich scrollbar, jede Spalte scrollt für sich;
  - Karte mit Name, Schule, Ampel + „x von y verbraucht“ bzw. „startet am …“, letzte Session, bei ruhend der Zustand;
  - Suche je Spalte („x von y“) und über alle Klassen (Trefferzahl), beide wirken zusammen;
  - Sortierung Nachname / größter Rückstand;
  - Zustandsfilter nur für Admin (aktiv Standard, ruhend, alle).
- **Akte:**
  - Kopf: Name, Klasse, Schule, Akte seit, Zustand; Hinweisbox bei ruhend.
  - Einheiten-Stand: Balken, Soll-Markierung, Ampel, Satz „… x Einheiten pro Betriebswoche — gleichmäßig verteilt wären es y“; „Startet am …“ vor Beginn; kein Einheiten-Stand bei ruhend.
  - Sessions: fünf Anwesenheitszustände, Summe je Zustand, letzte 8, Rest aufklappbar.
  - Notizen: Kategorie Pflicht, Live-Prüfung gegen `akte_wortliste`, dauerhafter Hinweis. Admin kann ausblenden (mit Grund), einblenden und eine Gesundheitsangabe endgültig entfernen, jeweils inline bestätigt.
  - Stammdaten: Admin ändert Klasse und Schule (Schulliste mit „neu anlegen“), Coach liest; Fächer nur Anzeige.
  - Reports aus `eltern_reports`; Fortschritt als Platzhalter für S3.
- **Keine Rechenlogik im Frontend.** Board aus `board_schueler`, Einheiten-Stand aus `einheiten_stand`, Zustand aus `schuelerakten`. Notizen laufen nur über die S1-RPCs.
- **Alle Texte über i18n,** neuer Namespace `akte`.

## Entscheidungen
- **Coach auf einer ruhenden Akte:** `schuelerakten` liefert nichts, die Seite leitet aufs Board mit „Ruhende Akten sind für Coaches nicht sichtbar.“ Ein Coach kann eine ruhende nicht von einer unbekannten Akte unterscheiden. Das ist gewollt, die Datenbank verrät es nicht.
- **Die Live-Prüfung der Wortliste** im Frontend spiegelt `akte_wortliste_treffer`. Verbindlich prüft `notiz_anlegen`.
- **Dashboards:** nur je eine Kachel ergänzt, weil ein paralleler Fix-PR die Dashboards umbaut.

## Grenzen ohne DDL (für das Foundation-Fenster)
- **Name des Kindes ist nicht editierbar.** `profiles` hat keine UPDATE-Policy; dafür braucht es eine RPC.
- **Sessions in der Akte:** Ein Coach sieht nur Sessions, die er selbst geleitet hat (RLS `session_students_coach_rw`). Für die volle Liste braucht es eine SECURITY-DEFINER-RPC.
- **Sessions ohne Fach, „woran gearbeitet“ und Badge-Bestätigung:** Diese Daten gibt es an `coaching_sessions` nicht.
- **Report-PDF:** `pdf_pfad` ist heute überall NULL. Der Link nutzt den angenommenen Bucket `eltern-reports`, den erst das Feature Eltern-Reports anlegt.

## Offen
- **Testdaten über die Oberfläche** (je eine Akte im Plan, leicht, deutlich, startet noch, ruhend) und **Screenshots** als Admin und als Coach. Braucht ein Admin-Login; Anleitung im PR.
- **Konflikt mit dem parallelen Dashboard-Fix-PR** beim Mergen auflösen.
