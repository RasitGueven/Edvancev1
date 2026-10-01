# W1-4 Phase 0 – Befund vor dem Schema

Stand: 01.10.2026, gelesen gegen die Ziel-DB (read-only, Guard `current_database() = postgres`, Pooler, nicht lokal) und gegen `origin/dev` (96fabf5).

## a) `public.themen` und `public.skill_voraussetzung`

- `themen`: 8 Zeilen, alle `fach = 'mathematik'`, alle `klasse = 8`:
  `daten_streumasse`, `kreis`, `lineare_funktionen`, `lineare_gleichungen_lgs`,
  `prismen_zylinder`, `terme_binomische_formeln`, `zinsrechnung`, `zufallsexperimente`.
  RLS: `themen_read_all` (select für anon, authenticated, service_role).
- `skill_voraussetzung`: 0 Zeilen. FK auf `themen` und `skills`, beide on delete cascade.
- **Gelesen wird keine der beiden.** Kein Treffer in `pg_proc.prosrc` (Schema public),
  keine View/Regel hängt daran (`pg_depend` über `pg_rewrite`), kein Treffer in
  `src/` oder `supabase/functions/`. Die Treffer für `themen` in
  `src/lib/authoring/board.ts` sind eine lokale Variable (Gruppierung nach
  `skill_clusters`), nicht die Tabelle. Erwartung bestätigt.

## b) Wie das Intake die Lead-Felder füllt

| Feld | Quelle im Intake | Schreibweg |
|---|---|---|
| `class_level` | Select in `SectionLead.tsx` und `TopicSelect.tsx` (5–13) | `intakeToLeadInput` → `createLead`/`updateLead` (`src/lib/supabase/leads.ts`, direkt auf `leads`) |
| `school_type` | Select `SchoolKind` (Gymnasium, Gesamtschule, Realschule, Hauptschule) | dito |
| `school_name` | Freitext-Input „Schule (optional)" | dito, leer → NULL |
| `current_topic_cluster_id` | `TopicSelect.tsx`: `getSubjects()` → `getClustersBySubject(subjectId, class_level)` aus `skill_clusters`; wird bei Klassenwechsel auf NULL gesetzt | dito; Pflicht für die LSA-Freigabe (`LeadIntakeForm.tsx:187`) |

`src/lib/supabase/intake.ts` schreibt nur `intake_sessions`, nicht `leads`.
In der DB lesen `lead_lsa_freigeben`, `app_provision_student`, `vertrag_abschliessen`,
`vertrag_starten`, `akte_basis`, `lsa_lead_kontext` mindestens eines der vier Felder.

Ist-Daten: 29 Leads, 3 mit `school_name`, 11 mit `current_topic_cluster_id`;
`school_type` 16× Gymnasium, 5× Gesamtschule, 1× Hauptschule, 7× leer.

## c) Kernlehrplan Mathematik G9 NRW (2019), inhaltliche Schwerpunkte

Quelle: https://lehrplannavigator.nrw.de/system/files/media/document/file/g9_m_klp_3401_2019_06_23_0.pdf
(Abschnitt 2.3 Erprobungsstufe, 2.4.1 Erste Stufe, 2.4.2 Zweite Stufe). Hier nur Stichworte.

| Stufe | Arithmetik/Algebra | Funktionen | Geometrie | Stochastik |
|---|---|---|---|---|
| Erprobung (5/6) | Grundrechenarten, Brüche, Dezimalzahlen, Teilbarkeit, Primfaktoren, Anteile | Zusammenhang zwischen Größen, Dreisatz, Maßstab | ebene Figuren, Körper, Symmetrie, Koordinatensystem, Umfang/Fläche, Quader-Volumen | Daten, Häufigkeiten, Mittelwert/Median, Boxplot |
| Erste (7/8) | rationale Zahlen, Terme und Variablen, binomische Formeln, lineare Gleichungen und LGS | (anti)proportionale Zuordnung, lineare Funktionen (Steigung, Steigungsdreieck), Prozent- und Zinsrechnung | Dreiecke/Vierecke (Fläche), Winkelsätze, Kongruenz, Thales, Konstruktionen | Zufallsexperimente, Baumdiagramm, Laplace, Pfadregeln |
| Zweite (9/10) | reelle Zahlen, Potenzen, Wurzeln, Logarithmen, quadratische Gleichungen | quadratische, exponentielle, Sinusfunktionen | Kreis, Körper (Prisma, Zylinder, Kegel, Pyramide, Kugel), Ähnlichkeit, Pythagoras, Trigonometrie | bedingte Wahrscheinlichkeit, Vierfeldertafel |

**Kürzel für `themen.klp`:** Der KLP vergibt für inhaltsbezogene Kompetenzen keine
Kürzel, sondern nummeriert die Erwartungen je Inhaltsfeld und Stufe `(1)`, `(2)` …
Konvention hier: `Ari-n`, `Fkt-n`, `Geo-n`, `Sto-n` mit der KLP-Nummer; eindeutig
zusammen mit `themen.stufe`. Beispiel Zweite Stufe: `Geo-3` = Längen/Flächen an Kreisen,
`Geo-5` = Oberfläche/Volumen von Körpern – bestätigt die Umstufung von `kreis` und
`prismen_zylinder` nach `zweite`.

## Abweichungen vom Auftrag

1. **`public.schulen` existiert bereits** (Vertraege P1, `20260925120000_vertraege_erweiterung.sql`):
   `id, name, ort (nullable), created_at, created_by`, Unique-Index auf
   `(lower(name), coalesce(ort, ''))`, RLS nur Admin (`schulen_admin_all`), Verweise aus
   `students.schule_id` und `vertraege.schule_id`, gelesen/geschrieben von
   `src/lib/supabase/schulen.ts` (Vertragsformular, Akte). Bestand: 1 Zeile
   (`name = 'Gymnasium'`, `ort = 'Köln'`) – sieht nach Testeintrag aus.
   → Migration 1 erweitert die Tabelle (schulform, stadtteil, traeger, website,
   `ort default 'Köln'`) statt sie anzulegen. Der bestehende Unique-Index ersetzt
   `unique (name, ort)` (er ist strenger). RLS bleibt Admin-only; der Auftrag will
   für neue Tabellen „lesen admin + coach" – für `schulen` wäre das eine
   RLS-Änderung an einer bestehenden Tabelle und ist **nicht** enthalten.
2. **`themen.stufe` not null** braucht Werte für die 8 Bestandszeilen. Migration 1 setzt
   sie gleich KLP-richtig (`kreis`, `prismen_zylinder` → `zweite`, Rest → `erste`),
   damit kein falscher Zwischenstand sichtbar ist. Phase B baut darauf auf.
3. **`themen.klasse` bleibt not null.** Phase B muss für neue Themen einen Wert setzen
   (erste Klasse der Stufe), oder Migration 2 hebt not null auf.
4. **`schema.sql` gibt es nicht.** Das Repo führt `supabase/schema-erwartet.sql`, einen
   read-only Abzug der Ziel-DB (`tools/schema-snapshot.sh`). Er wird nach dem Einspielen
   neu erzeugt und mitcommittet.
5. **`pdftotext` ist nicht installiert** (für Phase C). Für den KLP wurde `pypdf` im
   Scratchpad benutzt; für Phase C entweder `poppler-utils` installieren oder `pypdf`.
