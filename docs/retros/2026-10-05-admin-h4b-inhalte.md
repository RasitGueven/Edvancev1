# Retro 2026-10-05 — Admin-Hülle H4b: Inhalte

## Gebaut
- In die Hülle (PageHeader statt EdvanceNavbar/AdminHeader, kein eigener Wrapper, kein `max-w-*`):
  Item-Pflege (Board), Expertenliste, Editor („← Item-Pflege“), Content-Gesundheit, QS, Diagnostik, Eltern-Report.
- Expertenliste heißt jetzt im Kopf „Expertenliste“ (Rubrik „Item-Pflege“); der Knopf „Expertenliste“ auf dem
  Board steht auf hellem Grund und bleibt outline.
- Lena-Board-Teile unverändert übernommen (LenaInfo, RueckfrageKlaeren, PruefEinstellungenKarte, `?status=`).
- Pflege-Strecke: Fokus-Seite ohne Leiste und jetzt auch ohne EdvanceNavbar; WizardTopBar ist der einzige Kopf
  (Midnight-Verlauf `--gradient-midnight`).
- Editor- und QS-Speicherleiste `sticky` statt `fixed` (fixed lag über der Leiste); Editor-Kopf als
  `authoring/EditorKopf.tsx` (Editor sonst über 400 Zeilen). `PageHeader` kann `zurueckState` (Rückweg in die Strecke).
- Druck in der Hülle: Leiste/Kopfzeile `print-hide`, Raster und Scrollbereich `print:` aufgelöst.
- Alias-Block in `tokens.css` gelöscht, 17 Aufrufstellen auf Zielnamen; QS ohne `var(--…, #hex)`.
- i18n: Diagnostik (`admin:diagnostik.*`), QS-Rahmen und Freigabe-Schritt (`screening-editor:qs.*`,
  `save.*`), `report:page.untertitel`. Entfernt: `admin:breadcrumbs`, `authoring:page.listSubtitle`,
  `authoring:wizard.subtitle`.

## Entscheidungen
- Coach sieht Content-Gesundheit und Eltern-Report weiter im alten Rahmen (Entscheidung 12) — über `AltRahmen`
  (jetzt mit `max-w-3xl` und `blatt` fürs Druckbild), damit EdvanceNavbar/AdminHeader nur dort stehen.
- AdminHeader bleibt: `VertragPage` (Fokus-Seite Vertragsabschluss am iPad) und `AltRahmen` (Coach) importieren ihn.
- Content-Gesundheit, QS, Diagnostik: Zurück führt zur Item-Pflege (dort sind sie in der Leiste einsortiert).

## Offen
- QsPage (≈940 Zeilen) über dem 400-Zeilen-Limit, Schritte 1–4 und `STEPS`/`FORMATS` noch mit festen Texten.
- Diagnostik-Kinder (`NewTaskForm`, `TaskRow`) noch mit festen Texten.
- Content-Gesundheit, QS und Diagnostik sind in der Leiste nicht direkt verlinkt (früher Kacheln).
- `ShowcaseSections` listet weitere nie definierte Token-Namen (`--text-primary`, `--surface`, …) als
  dynamische Strings — kein `var(--…)`-Literal, deshalb außerhalb der Abnahme.
