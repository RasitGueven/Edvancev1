# Retro 2026-10-03 – Kachel „Inhalte“ nach Themen (W4)

## Gebaut

- `skill_thema`: Heimat-Thema je Skill, mit RLS (lesen admin/coach). Dazu die
  RPC `freigabe_thema(thema, klasse)`. Migration `20261003104615`.
- Daten: 58 von 59 Skills zugeordnet. `potenzen` bleibt ohne Zuordnung
  (Befund). Migration `20261003104647`.
- Board: Themengebiet = Heimat-Thema, Abschnitte nach Stufe (die Stufe der
  Klasse zuerst), „Ohne Thema“ zuletzt. Aktive Klassen kommen aus den Daten,
  dadurch ist Klasse 9 heute aktiv.
- Expertenliste: Filter „Thema“.
- Prüfskript `supabase/checks/skill_thema.PRUEFUNG.sql` (T1–T5), lokal grün.

## Entscheidungen

Siehe `docs/inhalte-themen/entscheidungen.md`. Die wichtigsten: Das Fach hängt
weiter am Cluster, und es gibt eine eigene Freigabe-RPC je Thema und Klasse.

## Offen

- `potenzen` klären, siehe `docs/inhalte-themen/befunde.md`.
- Ein Nachtrag für die Knoten aus k8-rest/k9-rest, sobald sie in Prod sind.
- Schülersicht, Screening-Berichte und der Altlead-Fallback im Report gliedern
  noch nach Cluster.

## Technik-Notiz

Die Board-Screenshots kommen aus einem Wegwerf-Harness: Vite mit Aliassen auf
gemockte Wrapper und Prod-Daten aus `dbread`. Der Vite-Root muss der Worktree
sein, sonst erzeugt Tailwind v4 keine Utilities. Playwright-Chromium braucht in
WSL `libasound.so.2`. Ohne Root-Rechte geht das per `apt-get download` +
`dpkg-deb -x` und `LD_LIBRARY_PATH`.
