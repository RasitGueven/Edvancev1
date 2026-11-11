# CI-1 · Schritt 0 · Bestand `Edvancev1`

**Stand:** 11.11.2026 (dev `457bb600`) · Teil C (`edvance-app`) ist nicht Teil dieser Datei.

**Freigaben Rasit (11.11.2026):** Zuordnung der Menüpunkte wie unten freigegeben, `login.fuss` → „Klasse 8 – 10 · Köln“ freigegeben.
**Testdaten und offene Fragen:** entschieden am 11.11.2026 (Abschnitte 5 und 7).

## 1. Logo-Dateien

Vorhanden in `docs/marke/logo/` (13 Dateien): `edvance-logo-auf-{hell,dunkel,cobalt}.svg`, `edvance-logo-einfarbig.svg`,
`edvance-wortmarke-auf-{hell,dunkel,cobalt}.svg`, `edvance-wortmarke-einfarbig.svg`,
`edvance-zeichen-auf-{hell,dunkel,dunkel-klein,cobalt}.svg`, `edvance-zeichen-einfarbig.svg`.

Alte Logos, die ersetzt werden: `public/favicon.svg`, `public/brand/edvance-{app-icon,favicon,logo-dark,logo-light,symbol}.svg`,
`src/components/brand/EdvanceLogo.tsx` (nachgezeichnete Pfade, Wortmarke in Space Grotesk, Z. 123).
Verwendet in `src/pages/Login.tsx`, `src/pages/auth/AuthRahmen.tsx`, `src/components/edvance/EdvanceNavbar.tsx`,
`src/components/edvance/shell/ShellSidebar.tsx`, `src/components/edvance/shell/AppShell.tsx`.

## 2. Alte Schriften

Kürzel: L = Literata, S = Schibsted Grotesk, G = Space Grotesk, F = Fraunces. Fraunces fragt der Auftrag
nicht ab, ist aber die Serife hinter `--font-serif` und fällt unter „keine Serifenschrift“, deshalb mitgelistet.

### 2a. App-Code (wird umgestellt)

| Datei | Zeilen |
|---|---|
| `index.html` | 11 (G), 14 (S, F), 16 (L, S, F) — Google-Fonts-Links |
| `src/styles/tokens.css` | 4, 7, 10 (`--font-serif` = F), 11 (`--font-body` = S) |
| `src/styles/globals.css` | 150–152 (`--font-sans/serif/body` an Tailwind durchgereicht) |
| `src/components/brand/EdvanceLogo.tsx` | 123 (G) |
| `public/brand/edvance-logo-dark.svg` | 8 (G) |
| `public/brand/edvance-logo-light.svg` | 9 (G) |

Nutzer von `font-serif`/`--font-serif`/`--font-body` in `src` (laufen über die Tokens, ändern sich mit):
`AdminHeader.tsx:57`, `admin/KennzahlenLeiste.tsx:54`, `authoring/HealthOverview.tsx:43`, `report/ReportOutlook.tsx:45`,
`shell/AppShell.tsx:54`, `shell/PageHeader.tsx:39`, `pages/Login.tsx:132,146`, `admin/VertragPage.tsx:196`,
`admin/VertragUnterlagenPage.tsx:95`, `admin/heute/ArbeitsListe.tsx:78`, `admin/heute/HeuteImBetrieb.tsx:87`,
`admin/pruefen/AdminPruefansichtPage.tsx:140`, `admin/pruefen/ReiheEndePage.tsx:19`, `admin/slots/kind/KindKarten.tsx:30`,
`admin/slots/panel/TagPanel.tsx:102`, `coach/einsaetze/EinsatzKarte.tsx:59`, `coach/live/LiveKopf.tsx:48`,
`coach/live/MasteryPruefung.tsx:116`, `coach/live/Schublade.tsx:55`.
Kommentare mit F: `AdminHeader.tsx:9`, `authoring/HealthOverview.tsx:3`, `shell/PageHeader.tsx:20`, `heute/ArbeitsListe.tsx:42`.

### 2b. Elternbericht R7 und Tablet-Präsentation (eigene Regeln, siehe Frage 7.1)

| Datei | Zeilen |
|---|---|
| `src/styles/tokens.css` | 220–221 (`--font-eb-titel` = F, `--font-eb-marke` = F) |
| `src/styles/elternbericht/rahmen.css` | 11 (F), 12 (S), 40, 42 (L: `--font-eb-titel` lokal Literata) |
| `src/styles/elternbericht/*.css`, `src/styles/praesentation/*.css` | nutzen `--font-eb-titel`/`--font-serif` (seite2:39, seite5:66, v4-seite4:51,158, intro:53, kopf:51, rahmen:74,211, station1-v4:78,142, station1:111, station2-detail:36, station2-v4:36, station2-zahlen:55, station2:57, station4-v4:109, station4:74) |
| `src/styles/report.css` | 96, 113 (F) |
| `src/lib/report/bogenPdf.ts` | 13, 81 (L, S — PDF bricht ab, wenn die Schriften fehlen) |
| `e2e-druck/elternbericht.spec.ts` | 7, 250, 251 (erwartet „Literata 600“, „Schibsted Grotesk 400“) |
| `scripts/report/reportCss.ts` | 26 (S), 28, 48, 132 (F) |
| `scripts/report/reportHtml.ts` | 180 (S, F) |
| `scripts/report/radar.ts` | 164 (S) |

### 2c. Aufgaben-Figuren (Generatoren, Frage 7.2)

`scripts/figures/svgBasis.ts:131`, `scripts/figures/svg_basis.py:205`, `scripts/figures/tokens.py:107`,
`scripts/figures/sichtproben_koordinatensystem.py:191,213`, `scripts/figures/test_koordinatensystem.py:130`,
`scripts/figures/test_winkel.py:227` (alle S). Außerdem `supabase/migrations/20261016151208_hochzahlen_inhalt.sql:17` (F, Hochzahlen-Inhalt).

### 2d. Vorschau-, Harness- und Werkzeugseiten

`.harness-eb/batu.html:14,18`, `.harness-eb/s7.html:14,18`, `vorschau/elternbericht.html:14,18`,
`vorschau/praesentation.html:14,18` (alle G/L/S/F), `tools/export-design-demo/index.html:9` (G),
`tools/aufgaben-qs.html:16,50,52,119,131,209,221,234,267` (F).

### 2e. Dokumente (Ausnahme laut Abnahme Punkt 2: alte Dummies, Begründung im Bericht)

Dummies: `docs/admin-huelle/admin-huelle-dummy.html`, `docs/admin-pruefansicht/admin-pruefansicht-dummy.html`,
`docs/lena-board/lena-board-dummy-v2.html`, `docs/schuelerakte/schuelerakte-dummy.html`, `docs/session/coach-live-dummy.html`,
`docs/slots/slots-dummy.html`, `docs/slots/slots-dummy-v2.html`, `docs/vertraege/vertraege-gesamt-dummy.html`,
`docs/reihe1/referenz/schueler-app-dummy.html`, `docs/reihe1/referenz/session-flow-dummy.html`,
`docs/report/praesentation/dummy-v7.html`, `docs/report/praesentation/r7-9-prototyp-station3.dc.html`,
`docs/report/v4/bericht-v4-dummy.html`, `docs/report/v4/praesentation-v4-dummy.html`, `docs/prefill/erklaer-k8-linfkt-vorschau.html`.
Blindlöser-Bilder: 112 SVGs unter `docs/reihe1/A/blindloeser/**` (S, Z. 4/5).
Text: `docs/report/r7/E7-Masse.md` (Maßblatt, 30 Zeilen), `docs/report/r7/Bauauftrag-R7.md:11,141,190`, Retros, Bauaufträge,
`docs/ROADMAP.md:316`. Diese bleiben als Historie.

## 3. Alte Markenfarben

### 3a. `#2D6A9F` und direkte Verwandte

| Fundstelle | Wert |
|---|---|
| `src/context/ThemeContext.tsx:8` | `edvance: { primary: '#2D6A9F', light: '#98C0D8', dark: '#1B2A3E' }` (Vorschau im ThemePanel, Frage 7.3) |
| `tools/aufgaben-qs.html:20` | `--brand:#2D6A9F; --brand-dark:#21527D; --brand-soft:#E8F0F7` |
| `scripts/generate-assets.ts:88`, `scripts/canva-prompts/lambacher-8-nrw.md:124` | Prompt-Texte |
| `.claude/agents/reviewer.md:27` | Beispiel im Agenten-Text |

### 3b. Die tatsächlich gültigen alten Markentokens (`src/styles/tokens.css`)

`#2D6A9F` steht in den Tokens nicht mehr. Die App fährt heute auf diesen Werten:

| Token | Wert | Ersatz (Vorschlag) | Nutzung in `src` |
|---|---|---|---|
| `--color-primary` (Z. 14) | `#334D7A` | Cobalt `#4567C6` bzw. Navy, je nach Rolle | 483 Treffer / 163 Dateien |
| `--color-primary-hover` (15) | `#253D6A` | dunkleres Cobalt | 8 / 5 |
| `--color-primary-light` (16) | `#EEF2F8` | Cobalt-Wash | 92 / 59 |
| `--color-navy-deep` (17) | `#14213D` | Navy `#102038` | 16 / 6 |
| `--color-on-cream` (57) | `#1A2E4A` | Navy | 2 / 1 |
| `--color-text-link` (52) | `#334D7A` | Cobalt | 36 / 29 |
| `--color-accent`, `--color-accent-streak` (60–61) | `#E8A020` | Amber `#DA9721` | 71 / 25 |
| `--color-bg-app` (43) | `#F7F7F5` | Ivory `#F8F5EE` | — |
| Bühnen-Verlauf (35–39) | `#43608F … #17263F` | Navy-Verlauf | — |
| `--color-stage-*` (142–152) | `#2E3E63`, `#1E2B49`, `#3D5A8A`, `#243960`, `#263D6A`, … | Navy | 67 / 7 (Student-Bühne) |
| `--color-report-navy/-gold/-cream` (74–76) | `#102038` / `#DA9721` / `#F8F5EE` | stimmen schon mit der Marke | — |

Hex außerhalb der Tokens: `src/components/edvance/moments/LevelUpModal.tsx` (`#334D7A`), `src/components/ui/card.tsx` (`#1A2E4A`),
`src/pages/demo/v2/V2Kit.tsx` (`#E8A020`), alle Dateien unter `public/brand/` und `public/favicon.svg` (`#334D7A`, `#E8A020`).

**Umfang:** Teil B ersetzt die Werte in `tokens.css`. Da 163 Dateien `--color-primary` nutzen, ändert sich damit auch
Coach-, Student- und Schüler-Demo-Optik. Vorschlag in Frage 7.4.

## 4. Admin-Navigation

### 4a. Einträge aus `adminNav.ts` → neue Bereiche (freigegeben)

| ID | Route | `aktivBei` | Zähler | heute | neu |
|---|---|---|---|---|---|
| `heute` | `/admin` | — | — | start | **Heute** |
| `leads` | `/admin/leads` | — | `leads` | Vertrieb | **Kinder** |
| `schueler` | `/admin/akten` | `/admin/akten*` | — | Betrieb | **Kinder** |
| `vertraege` | `/admin/vertraege` | `/admin/vertraege*` | `vertraege` | Verwaltung | **Kinder** |
| `lsaReports` | `/admin/lsa-reports` | `/admin/lsa-reports`, `/admin/report/*` | — | Verwaltung | **Kinder** |
| `elternReports` | — (bald) | — | — | Verwaltung | **Kinder** (bleibt „bald“) |
| `itemPflege` | `/admin/authoring` | `/admin/authoring*`, `/admin/content-gesundheit`, `/admin/qs`, `/admin/diagnostics`, `/admin/pruefen/erklaerungen*` | `itemPflege` | Inhalte | **Inhalte** |
| `lsaAbdeckung` | `/admin/lsa-abdeckung` | — | — | Inhalte | **Inhalte** |
| `klassenarbeiten` | `/admin/klassenarbeiten` | — | — | Verwaltung | **Inhalte** |
| `studio` | `/admin/studio` | — | — | Inhalte | **Inhalte** |
| `slots` | `/admin/slots` | `/admin/slots*`, `/admin/schedule`, `/admin/slot-auswahl` | `slots` | Betrieb | **Planung** |
| `coaches` | `/admin/coaches` | `/admin/coaches`, `/admin/assignments` | — | Betrieb | **Planung** |
| `stellschrauben` | `/admin/stellschrauben` | — | — | Verwaltung | **Fuß der Leiste** |

Gruppenschlüssel: `nav.gruppe.{vertrieb,betrieb,verwaltung,inhalte}` → `nav.gruppe.{kinder,inhalte,planung}` (`admin.json:320`).

### 4b. Admin-Routen ohne eigenen Menüpunkt

Alle aus `src/App.tsx`. „erreichbar über“ = eingehender Link im Code.

| Route | erreichbar über | Bereich (aktiv) |
|---|---|---|
| `/admin/qs` | **kein Link im Code**, nur Adresse | Inhalte (über `itemPflege`) |
| `/admin/diagnostics` | **kein Link im Code**, nur Adresse | Inhalte |
| `/admin/assignments` | **kein Link im Code**, nur Adresse | Planung (über `coaches`) |
| `/admin/content-gesundheit` | Coach-Leiste (`coachNav.ts:57`); für Admin nur Adresse | Inhalte |
| `/admin/authoring/liste` | Item-Board, Prüfreihe (`reihe.ts:32`), `useListenZustand.ts:11` | Inhalte |
| `/admin/authoring/:id` | Item-Zeilen, Befunde | Inhalte |
| `/admin/pruefen/erklaerungen[/:id]` | Knopf im Item-Board (`ItemBoardPage.tsx:152`) | Inhalte |
| `/admin/pruefen/:taskId`, `/admin/pruefen/ende` | Prüfreihe (Fokusseite, ohne Leiste) | — |
| `/admin/pflege` | Umleitung → `/admin/authoring/liste` | — |
| `/admin/akten/:studentId` | Akten-Board, Slots-Kind | Kinder |
| `/admin/report/:sessionId` | LSA-Reports, Lead-Karte, Heute | Kinder |
| `/admin/vertraege/:id/detail` | Vertragsmenü, Heute | Kinder |
| `/admin/vertraege/:id`, `/admin/vertraege/:id/unterlagen` | Leads, Heute (Fokusseiten ohne Leiste) | — |
| `/admin/slots/kind/:studentId` | Slots-Kinder, Akte | Planung |
| `/admin/slots/termin/:datum/:zeitId`, `/admin/schedule`, `/admin/slot-auswahl` | Umleitungen in Slots | Planung |
| `/coach/reports` | nur Adresse (Altseite, nur Admin, eigener Rahmen) | — |

Der Umbau ändert keine Route und kein `aktivBei`. Die drei Seiten ohne Link bleiben so erreichbar wie heute (Adresse).

## 5. Teil D · Testdaten (entschieden)

Abgefragt per `dbread` am 11.11.2026, read-only: 48 Leads (18 als Test markiert), 44 Schüler (42 als Test markiert).
Die Liste mit Namen bleibt lokal (nicht im Repo). Entscheidung Rasit, 11.11.2026: echt sind nur Kind A (`060b316e`) und Kind B (siehe unten),
alles andere ist Test.

### 5a. Leads mit `ist_test = false` vor der Migration (30)

| ID | Status | Entscheidung |
|---|---|---|
| `4080fefe` | rejected | test |
| `dde9f9d0` | rejected | test |
| `8169556f` | rejected | test |
| `2ded60a7` | rejected | test |
| `5f236f5f` | rejected | test |
| `e2ca04a6` | rejected | test |
| `c4a542f1` | rejected | test |
| `875ee8ad` | rejected | test |
| `f63564ac` | rejected | test |
| `1c9f68c9` | rejected | test |
| `d9e54bcb` | rejected | test |
| `613a825c` | rejected | test |
| `57919102` | rejected | test |
| `17914091` | rejected | test |
| `ec0ae5d3` | converted | test |
| `8d9cb9b9` | converted | test |
| `5cccc8ca` | rejected | test |
| `1ebcd18f` | converted | test |
| `d01b50b7` | converted | test |
| `d35f9a72` | converted | test |
| `75adb56f` | converted | test |
| `c7760dd0` | rejected | test |
| `fccc3c01` | converted | test |
| `1f1828d9` | converted | test |
| `bb2362c1` | converted | test |
| `8f2b7c14` | converted | test |
| `429c3a5b` | converted | test |
| `61e36cda` | rejected | test |
| `8cbee0cf` | lsa_fertig | test |
| `060b316e` | lsa_fertig | **echt** (bleibt `false`) |

### 5b. Schüler mit `ist_test = false` vor der Migration (2)

| ID | Lead | Entscheidung |
|---|---|---|
| `5d03e892` | `8cbee0cf` | test |
| `f9e42014` | `060b316e` | **echt** (bleibt `false`) |

### 5c. Bereits als Test markiert

18 Leads und 42 Schüler stehen schon auf `true`. Die Migration ändert dort nichts (nur `false` → `true`).

**Kind B (Rückfrage):** Es gibt zwei Leads (`f2a17e03` lsa_fertig, `c31107a7` rejected) und zwei Schülerinnen
(`4e58dc0a`, `f4be729c`). **Alle vier stehen heute auf `ist_test = true`.** Laut Auftrag ändere ich nichts.
Folge: Ohne den Schalter steht danach nur Kind A in den Admin-Listen; Kind B erscheint erst, wenn ihre
Markierung auf `false` gesetzt wird (Entscheidung Rasit).

### 5d. Datenmigration

`update leads set ist_test = true where id in (29 IDs aus 5a) and ist_test = false` und
`update students set ist_test = true where id = '5d03e892-…' and ist_test = false`. Nichts gelöscht, keine Schemaänderung,
Prüfabfrage vorher und nachher.

## 6. Datenquellen „Heute“ (keine neuen)

`src/pages/admin/heute/useHeuteDaten.ts`, parallel:
`getAdminStats` (`adminStats.ts`, zählt Leads schon mit `ist_test = false`), `listLeads`, `listActivePlaetzeByLead`,
`listVertraegeAktuell` (View `vertraege_aktuell`), `listVertraege` (`vertraege` + `lead:leads(*)`), `listBoardSchueler`
(RPC `board_schueler`), `listAufgabenFuerAdmin`, `listSkillThemen`, `ladeTag` (`slots_tag`), `listTodaysLsaSessions`,
danach `listReportSessionsByLead`. Eigene Ladestellen: `FreigabelisteListe` (`getPruefBoard`, `getPruefSoll`),
`OffeneSessionsListe` (`sessionsOffen`, `sessionsNichtGestartet`).

## 7. Entscheidungen (Rasit, 11.11.2026)

1. Elternbericht R7, Tablet-Präsentation: in CI-1 unverändert (Literata/Schibsted/Fraunces nach Muster E7), Ausnahme im Bericht.
2. Aufgaben-Figuren (`scripts/figures/**`): in CI-1 unverändert, Ausnahme im Bericht.
3. `ThemeContext.tsx`: Vorschauwert `edvance` auf die neue Marke, freigegeben.
4. Tokens: `--color-primary` → Cobalt, Navy-Tokens → Navy, `--color-accent` → Amber, `--color-bg-app` → Ivory, auch für Coach.
   Student-Bühne (`--color-stage-*`) unangetastet. Danach Kontraste nach WCAG AA, Fotos Coach-Heute und Lena-Board im Bericht.
5. Neue Lese-Funktion in `src/lib/supabase/` für `ist_test` aus `students` und `leads`; darüber filtern Heute, Akten, Verträge.
