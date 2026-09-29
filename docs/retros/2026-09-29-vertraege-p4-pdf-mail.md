# Retro 2026-09-29 — Verträge P4: PDF, Archiv, Mailversand

Vier PRs auf `dev`: #169 (P4a-1), #170 (P4a-2), #171 (P4b), #172 (Fix).
Alle Migrationen in Produktion, alle Prüfskripte gegen Prod gelaufen.

## Gebaut

**Datenbank**
- `20260928160000_vertrag_dateien` — eine Zeile je erzeugtem Dokument mit Pfad,
  SHA-256 und Urheber. `unique (vertrag_id, art)` ist die Regel „nicht
  überschreiben" als Datenbankbedingung; `on delete restrict` hält den Vertrag
  fest, solange etwas im Archiv liegt.
- `20260928190000_dokument_fassungen` — AGB, Widerruf, Datenschutz und Fotos
  haben keinen Platzhalter, liegen also **einmal je Fassung** unter
  `fassungen/<art>/<fassung>.pdf`, nicht je Vertrag.
- `20260928210000_vertrag_versand_mail` — `vertrag_versand` um `anhaenge` und
  `fehler` erweitert, Anlass `zugangscode`.

**Edge Functions**
- `vertrag_pdf` — erzeugt Bündel oder Unterlagen, Admin-Gate, fail-closed.
- `mail_senden` — Microsoft Graph, Client-Credentials, drei Anlässe.
- `_shared/markdown_pdf.ts` — eigener Setzer für die fünf Konstrukte der
  Vorlagen, pdf-lib, kein Headless-Browser.
- `vertrag_abschluss` erzeugt das PDF in Schritt 6, ohne Rückrollrecht.

**Oberfläche** — Archivliste mit echten Dateien und Herkunft, „PDF ausstehend"
mit Nachhol-Knopf, Fassungen verlinkt (die zugestimmte, nicht die neueste),
drei Versand-Knöpfe, Warnung zur fehlenden Gläubiger-ID.

## Entscheidungen

**Fassungen geteilt statt je Vertrag.** Die vier vertragsfreien Unterlagen
hundertmal abzulegen hätte die Frage verloren, die zählt: *welcher* Fassung hat
dieses Elternteil zugestimmt. Die steht in `vertrag_zustimmungen`.

**Vorlagen doppelt, mit Wachhund.** Der Supabase-Bundler nimmt nur den
Import-Graph der TypeScript-Dateien mit; eine `.md` im Function-Ordner wäre nach
dem Deploy tot. `tools/dokumente-buendeln.mjs` erzeugt die gebündelten Texte,
`vorlagenGleich.test.ts` baut sie im Test noch einmal und vergleicht.
Die saubere Lösung (Vorlagentexte in `vertrag_dokumente`) steht offen.

**Gläubiger-ID: warnen, nicht blockieren** (Entscheidung Rasit). Das Mandat
entsteht mit dem Hinweis oben im Dokument, dass es nicht gültig ist.

**Helvetica statt Fraunces.** Es liegen keine lizenzierten Schriftdateien im
Repo. WinAnsi deckt deutsche Typografie ab; die schmalen Leerzeichen aus
`Intl.NumberFormat` werden ersetzt.

## Was schiefging

**pdf-lib misst mit Kerning und zeichnet ohne.** „Text" ist gemessen 1,57 pt
schmaler als gezeichnet — das folgende Wort klebte an („Den Textlegt eine").
Behoben durch zeichenweises Messen. Gefunden nur, weil das gerenderte PDF
angesehen wurde, nicht weil ein Test rot war.

**`vertrag_versand_protokollieren` gab es schon** — seit P0, mit vier
Parametern, live im Druckweg. Eine zweite Fassung wäre eine Überladung gewesen
und hätte jeden Dreiargument-Aufruf mehrdeutig gemacht. Ersetzt statt
danebengestellt. Dieselbe Falle wie `lead_convert` in P2.

**`ON DELETE RESTRICT` wirft je nach Postgres-Version einen anderen SQLSTATE** —
PG 18 `restrict_violation` (23001), Produktion auf PG 17.6
`foreign_key_violation` (23503). Das Prüfskript war lokal grün und fiel gegen
Prod durch. Lokale Wegwerf-Datenbanken sind **nicht** dieselbe Version wie Prod.

**Zwei Fehler erst im echten Versand sichtbar** (#172): vier Anhänge hießen
`platzhalter-v1.pdf`, weil der Name aus dem Pfad kam. Und fehlende Zustimmungen
wurden stillschweigend übersprungen — eine Mail ohne AGB und Widerrufsbelehrung
ging raus und sah vollständig aus. Beides stand im Protokoll, das ich gebaut
hatte; ohne `anhaenge` in `vertrag_versand` wäre es nicht aufgefallen.

## Beweise

- Prüfskripte gegen Prod: `vertrag_pdf` 8/8, `dokument_fassungen` 7/7,
  `vertrag_versand_mail` 9/9, jeweils mit Rechteprüfung.
- Deno 11/11, Vitest 513/513, typecheck + lint sauber.
- Byte-Gleichheit gemessen: alle acht archivierten Dateien stimmen mit ihrer
  eingetragenen SHA-256 und Größe überein.
- Erster echter Versand über `hello@edvanceacademy.de` angekommen.

## Offen

- **Fehlgeschlagene Versände sind unsichtbar.** `vertrag_versand` wird in der
  Oberfläche nirgends angezeigt. Nach #172 bricht der Versand bei fehlenden
  Pflichtzustimmungen ab — die Zeile landet still in der Datenbank. Größte
  verbliebene Lücke.
- **Abnahme nicht vollständig nachgewiesen.** Der beobachtete Versand mit fünf
  Anhängen war der Anlass `unterlagen` **vor** dem Fix (08:35, Fix deployt
  09:37). Eine `bestaetigung` mit den fünf getrennten Dokumenten und den
  korrigierten Namen steht nicht im Protokoll. Rasit hat das Thema bewusst
  abgeschlossen; beim nächsten echten Abschluss fällt es ohnehin auf.
- Gläubiger-ID eintragen (Tolunay) → danach alle Mandate neu erzeugen; das alte
  PDF muss wegen `upsert:false` vorher weg.
- Vorlagentexte in die Datenbank, damit die Doppelung samt Wachhund entfällt.
- Schriften einbetten (Fraunces/Schibsted Grotesk als lizenzierte `.ttf`).
- Aufräumen im Bucket: bricht ein Lauf zwischen Upload und Eintrag ab, bleibt
  eine Datei ohne Zeile liegen.
- Aus P2/P3: Null-Prüfung für `p_student_email`, `*.swp` in `.gitignore`
  (`..env.swp` liegt ungeschützt im Arbeitsbaum), `--color-text-muted` in fünf
  Dateien, `VertragPage.tsx` über 400 Zeilen.
