# Retro 2026-10-06 · Coach-Hülle (H6)

## Gebaut
- `coach/coachNav.ts` (Leiste: Heute, Schüler, Aufgaben prüfen nur mit `darf_pruefen`,
  Content-Gesundheit; `istFokusSeite`), `coach/CoachLayout.tsx`, `coach/useCoachZaehler.ts`
  (Sessions heute, für Lena offen — nur bestehende Lesefunktionen, keine neue lib-Datei).
- Rollenweiche in `AdminLayout`: Admin → Admin-Hülle, Coach → Coach-Hülle, Fokus-Seiten und
  andere Rollen → nur die Seite. Dieselbe Weiche als Layout-Route um `/coach`, `/coach/pruefen*`.
- Umgezogen: CoachDashboard, PruefenUebersichtPage, PruefansichtPage, BoardPage, AktePage,
  ContentHealthPage, ReportPage. Gelöscht: `AltRahmen.tsx`.

## Entscheidungen
- Rahmenwechsel einrückungsneutral (Fragment + Wrapper), damit L5 auf den Prüfseiten keine
  großen Konflikte bekommt.
- Intake und Screening-Ergebnisse nicht in der Leiste (Tabellen leer).

## Offen
- Siehe `docs/admin-huelle/offene-punkte-h6.md`, vor allem die Entscheidungsleiste der
  Prüfansicht über der Seitenleiste (L5).
