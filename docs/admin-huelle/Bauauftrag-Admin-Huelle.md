# Bauauftrag Admin-Hülle — Arbeitspakete für Claude Code (Fassung 1)

**Stand:** 05.10.2026 · **Entscheider:** Rasit
**Grundlage:** Bewertung der Admin-App vom 05.10.2026 (dev-Stand `93fb3d6`), Klick-Dummy `admin-huelle-dummy.html`, Designsystem (Edvance UX Skill: „Coach/Admin = Eltern-Sprache, flach“), Farben aus `edvance-app/src/design/tokens.ts`.

## Warum

Die Admin-App hat keinen gemeinsamen Rahmen. Jede Seite baut Navbar, Navy-Kopfband und Breite selbst (fünf Breiten zwischen 768 und 1280 px), es gibt keine feste Navigation, die Startseite ist ein Kachel-Launcher ohne Inhalt, und Laptop/iPad sind nie gezielt gestaltet (im Admin gibt es keinen `md:`-Breakpoint). Dazu weicht die Farbwelt von der Schüler-App ab: dunklerer Verlauf, Amber `#E8A020` statt Gold `#D4A843`, Sora als Grundschrift. Ergebnis: Admin wirkt dunkler und unruhiger als die App.

## Maßgebliche Entscheidungen

1. **Sprache:** Admin spricht die Eltern-/Coach-Sprache des Designsystems: flach, heller Grund (`--color-bg-app`), weiße Karten, keine Glas-Effekte im Arbeitsbereich. Die dunkle Bühne `.admin-stage` entfällt.
2. **Farben folgen der Schüler-App** (`edvance-app/src/design/tokens.ts`):
   - Midnight-Verlauf mit fünf Stopps `#43608F · #3E5985 · #334B73 · #263A5B · #17263F` (die App vermerkt die Abweichung zu Edvancev1 ausdrücklich: „nachziehen oder melden“).
   - Akzent ist Gold `#D4A843` (vorhanden als `--color-gold-altgold`), nicht `--color-accent` (`#E8A020`) und nicht `--color-stage-gold-edge`.
   - Schrift auf Navy: Creme `#F7F5EE` (vorhanden als `--color-stage-text`). Schrift auf Creme: `#1A2E4A` (neu als `--color-on-cream`).
3. **Leiste:** LEISTE = navy  ← *Rasit trägt hier „navy“ oder „hell“ ein, nach Ansicht im Dummy.* Navy = Midnight-Verlauf mit Creme-Schrift; hell = weiß mit Navy-Schrift.
4. **Breiten:** unter 900 px Schublade (Menü-Knopf oben links), 900 bis 1279 px schmale Spalte (88 px, Symbol und Kurzname), ab 1280 px volle Leiste (256 px). iPad Air quer (1180) = schmale Spalte, iPad hoch (820) = Schublade, Laptop = volle Leiste.
5. **Eine Inhaltsbreite** für alle Admin-Seiten: höchstens 1400 px, Seitenränder 16 / 28 / 36 px je Breite.
6. **Seitenkopf kompakt:** Rubrik (z. B. „Vertrieb“), Titel in Fraunces 30 px, ein Satz, höchstens eine Primäraktion rechts. Kein Navy-Band, kein „← Admin“. Detailseiten (Akte, Vertragsdetail, Editor) bekommen einen Zurück-Link zu ihrer Liste.
7. **Startseite „Heute“** statt Kacheln: Kennzahlen als schmale Leiste, sechs Arbeitslisten (Neue Leads, Erstgespräche, Lernstandsanalysen, Verträge, Schüler im Rückstand, Inhalte freigeben) und rechts „Heute im Betrieb“. Jede Liste zeigt höchstens drei Einträge, die ältesten zuerst; eine leere Liste bleibt stehen und zeigt grün „nichts offen“.
8. **Boards:** Spalten teilen sich die Breite. Reicht sie nicht, wischen die Spalten seitlich (Scroll-Snap), sie brechen nicht in Blöcke um. Leads ab unter 1000 px Inhaltsbreite, Schüler-Board ab unter 700 px.
9. **Touch:** jedes Bedienelement hat mindestens 44 px Trefferfläche, auch „…“-Menüs und Chips.
10. **Noch ohne Route:** Eltern-Reports und LSA-Ergebnisse stehen in der Leiste, ausgegraut mit „bald“, nicht klickbar.
11. **Fokus-Seiten ohne Leiste:** Die Vertrags-Abschlussstrecke (`VertragPage`, Unterschrift am iPad mit den Eltern), `VertragUnterlagenPage` und der Pflege-Wizard (`PflegeWizardPage`) laufen im Vollbild ohne Leiste, mit eigenem Zurück-Link.
12. **Coaches** bekommen die Hülle nicht. Wer als Coach `/admin/akten` öffnet, sieht die bisherige Kopfzeile, bis es eine Coach-Hülle gibt. Die Hülle prüft dafür die Rolle.

## Pakete

| Paket | Inhalt | Braucht | Umfang |
|---|---|---|---|
| H1 | Tokens an die App angleichen, Kontrast-Bug, Schriften | – | klein |
| H2 | Hülle (Leiste, Seitenkopf, Layout-Route) + Leads, Verträge, Schüler umziehen | H1 gemergt | mittel |
| H3 | Startseite „Heute“ | H2 gemergt | mittel, neue Lesefunktionen in `src/lib` |
| H4a | Restliche Seiten Betrieb und Verträge umziehen | H2 gemergt | mechanisch |
| H4b | Restliche Seiten Inhalte umziehen, Altlasten löschen | H4a gemergt | mechanisch |
| H5 | Suche ⌘K (optional) | H4b gemergt | klein |

H3 läuft **interaktiv**, nicht über `scripts/claude-auto.sh`: Im autonomen Modus sperrt `guard-paths.sh` `src/lib/**`, und H3 braucht dort zwei Lesefunktionen.

## Vorbereitung durch Rasit

1. Im Dummy Navy oder Hell wählen und in Entscheidung 3 eintragen.
2. `admin-huelle-dummy.html` und diesen Bauauftrag aus dem Projekt nach `docs/admin-huelle/` im Repo legen.
3. Optional: Playwright-Plugin in Claude Code aktivieren, damit die Agenten ihre Screenshots selbst machen.

## Abnahme für jedes Paket

`npx tsc --noEmit`, `npm run lint` und `npm run test` grün, Ausgabe im PR. Screenshots in drei Größen im PR: **1440 × 900**, **1180 × 820**, **820 × 1180** (Playwright-Plugin oder Chrome-Gerätemodus). Rasit prüft zusätzlich einmal auf dem echten iPad.

---

## H1 — Tokens, Kontrast-Bug, Schriften

```text
Du arbeitest im Repo Edvancev1 (Vite + React 18 + Tailwind v4). Paket H1 des Bauauftrags Admin-Hülle.

LEITPLANKEN (nicht verhandelbar)
- Branch: git fetch && git checkout -b feat/rasit-admin-h1-tokens origin/dev · PR gegen dev, niemals main · nichts unter .github/.
- Kein DDL, keine Migrationen, keine Datenbankzugriffe. Reines Frontend.
- Rasit gibt dieses Paket ausdrücklich für src/styles/tokens.css frei (Foundation-Änderung). Andere Dateien unter
  src/lib/** und src/types/** nicht anfassen.
- Keine neuen Hex-Werte außer den unten genannten, jeweils mit Beleg-Kommentar.

KONTEXT
docs/admin-huelle/Bauauftrag-Admin-Huelle.md, Abschnitt "Maßgebliche Entscheidungen" Punkt 2.
Lies edvance-app/src/design/tokens.ts nur, wenn es lokal liegt; die Werte stehen auch hier.

UMFANG
1. src/styles/tokens.css:
   a) --gradient-midnight auf die fünf Stopps der Schüler-App umstellen, gleichmäßig verteilt, linear "to bottom":
      #43608F 0%, #3E5985 25%, #334B73 50%, #263A5B 75%, #17263F 100%.
      Kommentar: Beleg edvance-app/src/design/tokens.ts midnightGradient (Vorgabe Rasit 30.08.2026).
      Vorher alle Verwender auflisten (mindestens AdminHeader.tsx, authoring/wizard/WizardTopBar.tsx, globals.css)
      und im PR Vorher/Nachher-Screenshot je Verwender.
   b) Neu --color-on-cream: #1A2E4A (Beleg tokens.ts colors.onCream: Text auf Creme-Flächen).
   c) Neu --color-text-inverse: var(--color-stage-text). Behebt den unlesbaren aktiven Reiter: dunkle Schrift auf
      Navy in vertraege/menue/Reiterleiste.tsx (Zeilen 33 und 42), vertraege/WizardKopf.tsx:36,
      vertraege/Schritt3Weg.tsx:47. Repo-weit prüfen, ob weitere undefinierte var(--…) benutzt werden
      (Liste aller var(--x) in src/ gegen alle Definitionen in src/styles/); jede Lücke im PR nennen.
   d) --font-sans von 'Sora' auf die Body-Schrift (Schibsted Grotesk) umstellen.
2. index.html: den Sora-Link entfernen. Space Grotesk bleibt, weil EdvanceLogo die Wortmarke damit setzt.
3. Nichts an Seiten umbauen. Die dunklen Admin-Flächen verschwinden erst in H2/H3.

ABNAHME
Aktiver Reiter unter Verträge und der aktive Schritt im Vertrags-Wizard sind lesbar (Creme auf Navy).
Keine Datei in src/ benutzt eine undefinierte CSS-Variable. Screenshots wie im Bauauftrag beschrieben.
```

---

## H2 — Hülle und die ersten drei Bereiche

```text
Du arbeitest im Repo Edvancev1. Paket H2 des Bauauftrags Admin-Hülle. H1 ist gemergt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-admin-h2-huelle origin/dev · PR gegen dev, niemals main · nichts unter .github/.
- Kein DDL, keine Migrationen. Datenzugriff nur über bestehende Funktionen in src/lib/. Fehlt eine Zählfunktion
  (Aufgaben im Status review), darf sie als reine Lesefunktion in src/lib/supabase/taskAuthoring.ts ergänzt werden.
- Regeln aus CLAUDE.md §11 und §12 gelten: nur Tokens, keine Inline-Styles, keine freien Hex-Werte, EdvanceCard,
  LoadingPulse, EmptyState, alle Texte über i18n (Namespace admin), Dateien höchstens 400 Zeilen.
- Keine neuen npm-Abhängigkeiten. Die Leiste ist eigener Code (React 18: die aktuellen shadcn-Bausteine sind auf
  React 19 ohne forwardRef ausgelegt; das entscheiden wir separat).
- Bestehende Tests anpassen, nicht löschen (außer zu Dateien, die das Paket ausdrücklich löscht).
- Der Dummy docs/admin-huelle/admin-huelle-dummy.html zeigt Aufbau, Verhalten und Farben. Farben und Maße kommen
  aus den Tokens, nicht aus dem Dummy-CSS.

KONTEXT
docs/admin-huelle/Bauauftrag-Admin-Huelle.md (Entscheidungen 1–12 sind maßgeblich), Dummy (Ansicht wechseln:
Laptop, iPad quer, iPad hoch; Schalter "Hinweise" zeigt Quellen und Abweichungen).

UMFANG
1. Neue Bausteine unter src/components/edvance/admin/:
   - adminNav.ts: Konfiguration der Leiste. Gruppen und Einträge in dieser Reihenfolge:
     Heute (/admin) · Vertrieb: Leads (/admin/leads) · Betrieb: Stundenplan (/admin/schedule, aktiv auch für
     /admin/slots und /admin/slot-auswahl), Schüler (/admin/akten*), Coaches (/admin/coaches, /admin/assignments) ·
     Verwaltung: Verträge (/admin/vertraege*), Eltern-Reports (bald), LSA-Ergebnisse (bald) ·
     Inhalte: Item-Pflege (/admin/authoring*, /admin/pflege, /admin/content-gesundheit, /admin/qs,
     /admin/diagnostics, /admin/report/*). Je Eintrag: i18n-Schlüssel für Name und Kurzname, Lucide-Symbol.
   - useLayoutModus.ts: 'schublade' unter 900 px, 'spalte' 900–1279 px, 'voll' ab 1280 px (matchMedia).
     Breakpoints als Tokens in globals.css (@theme), nicht als Zahl im Code.
   - AdminSidebar.tsx: Logo (EdvanceSymbol + Wortmarke, auf Navy in Creme mit Gold-Pfeil), Einträge mit Zähler,
     Fuß mit Name, E-Mail und Abmelden. Zähler: Leads = neue Leads (getAdminStats().leadsNew), Verträge = offene
     Anträge (wie Reiter "Offene Anträge"), Item-Pflege = Aufgaben im Status review. Zähler-Pille: Gold
     (--color-gold-altgold) mit --color-on-cream auf Navy; Navy mit Creme bei heller Leiste.
     Aktiver Eintrag: Creme 14 % Fläche, Symbol in Gold (navy) bzw. --color-primary-light (hell).
     In der schmalen Spalte: Symbol über Kurzname (11 px), Gruppen als feine Trennlinie, Zähler als Punkt oben rechts,
     unten ein Knopf "Menü", der die volle Leiste als Überlagerung ausklappt.
     Schublade: volle Leiste von links mit Abdunklung dahinter; schließt bei Tippen daneben, Escape und Seitenwechsel.
   - AdminPageHeader.tsx: Rubrik, Titel (font-serif, 30 px), ein Satz, Aktionen rechts, umbrechend. Optional
     zurueckZu/zurueckLabel für Detailseiten.
   - AdminLayout.tsx: CSS-Grid Leiste | Inhalt, Inhalt scrollt für sich, die Leiste steht. In schublade: Kopfzeile
     mit Menü-Knopf (44 px) und Logo. Inhalt: max-w 1400 px zentriert, Ränder 16 / 28 / 36 px je Modus.
     Rolle admin → Hülle. Andere Rollen → nur <Outlet/> (Coach sieht auf /admin/akten weiter die bisherige Kopfzeile).
2. App.tsx: Admin-Routen als Kinder einer Layout-Route mit AdminLayout. Jede Kind-Route behält ihre
   ProtectedRoute unverändert. VertragPage, VertragUnterlagenPage und PflegeWizardPage bleiben AUSSERHALB der
   Layout-Route (Fokus-Seiten, Entscheidung 11).
3. Diese Seiten umziehen: LeadsPage, VertraegeMenuePage, akten/BoardPage, akten/AktePage.
   Je Seite: EdvanceNavbar, AdminHeader, den äußeren min-h-screen-Wrapper und das eigene max-w-* entfernen,
   AdminPageHeader einsetzen. AktePage bekommt "← Schüler".
4. Boards (Entscheidung 8): leads/BoardColumns und akten/BoardSpalte: Spalten teilen die Breite
   (grid, minmax(0,1fr)); unter der Schwelle seitlich wischbar mit scroll-snap, Spaltenbreite 300 px
   (Tailwind-v4-Container-Queries auf dem Inhaltsbereich, nicht Viewport).
5. Leads-Filter: Fach und Klasse als Chips statt nativer Select-Felder; "Archiv anzeigen" bleibt. CardMenu-Knopf
   mit 44 px Trefferfläche.
6. AdminDashboard bleibt in diesem Paket als Startseite in der Hülle, aber ohne .admin-stage (heller Grund).
   Die Kacheln ersetzt H3.

ABNAHME
- Laptop 1440 × 900: volle Leiste, Leads-Board vierspaltig, Board beginnt oberhalb von 300 px.
- iPad quer 1180 × 820: schmale Spalte, Menü-Knopf klappt die Leiste als Überlagerung aus.
- iPad hoch 820 × 1180: Schublade; Leads-Spalten wischen seitlich, kein 2 × 2-Umbruch.
- Als Coach eingeloggt: /admin/akten wie bisher, keine Leiste.
- Fokus-Seiten (Vertrags-Abschluss, Unterlagen, Pflege-Wizard) ohne Leiste.
Screenshots aller fünf Fälle im PR.
```

---

## H3 — Startseite „Heute“

```text
Du arbeitest im Repo Edvancev1, INTERAKTIV (nicht über claude-auto.sh). Paket H3 des Bauauftrags Admin-Hülle.
H2 ist gemergt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-admin-h3-heute origin/dev · PR gegen dev, niemals main · nichts unter .github/.
- Kein DDL, keine Migrationen, keine schreibenden Abfragen außer über bestehende Funktionen (vertragStarten,
  updateLead über den bestehenden TerminModal). Neue Lesefunktionen nur in src/lib/supabase/heute.ts.
  Lesend gegen die Datenbank nur nach `dbcheck` = "PROD OK" bzw. über dbread.
- CLAUDE.md §11/§12 wie in H2. Jede Datei höchstens 400 Zeilen.
- Keine Rechenlogik zu Verträgen im Frontend: auslaufende() und imVerzug() aus src/lib/vertrag/menue.ts benutzen,
  Ampel aus board_schueler.

KONTEXT
docs/admin-huelle/Bauauftrag-Admin-Huelle.md (Entscheidung 7), Dummy Seite "Heute" mit eingeschalteten Hinweisen.

UMFANG
1. src/pages/admin/HeutePage.tsx als Index-Route /admin; Bausteine unter src/pages/admin/heute/.
2. Kopf: Datum (Intl, Europe/Berlin, z. B. "Montag, 5. Oktober"), Gruß nach Tageszeit mit Vornamen, ein Satz mit der
   Summe offener Punkte. Primäraktion "Neuer Lead" (öffnet das bestehende LeadIntakeForm, z. B. per
   Navigation auf /admin/leads mit Parameter neu=1, LeadsPage öffnet dann das Formular).
3. Kennzahlen-Leiste (eine EdvanceCard, fünf Felder, ab 700 px Inhaltsbreite nebeneinander, darunter 2 Spalten):
   Aktive Schüler, Offene Leads (davon neu), Laufende Verträge (davon im Widerruf), Abbuchung diesen Monat
   (Summe beitrag_diesen_monat_cents der laufenden Verträge, Intl EUR), Coaches. Jedes Feld führt in seinen Bereich.
4. Sechs Arbeitslisten (eine gemeinsame Komponente ArbeitsListe: Symbol, Titel, Unterzeile, Zahl in Fraunces,
   höchstens drei Zeilen, "und n weitere", Fußlink in den Bereich; leer = grüne Zeile "nichts offen"):
   a) Neue Leads: status new, älteste zuerst; Zeile Name, "Kl. x · Fächer", Pille "seit n Tagen" (Amber ab 7 Tagen),
      Knopf "Termin" öffnet den bestehenden TerminModal.
   b) Erstgespräche: status contacted mit erstgespraech_at ab heute, nächste zuerst; Datum, Uhrzeit, Standort.
   c) Lernstandsanalysen: lsa_freigegeben (mit Platz/Uhrzeit aus listActivePlaetzeByLead) und lsa_fertig
      (Report aus listReportSessionsByLead) mit Knopf "Vertrag starten" (vertragStarten, nur admin, wie LeadsPage).
      LsaTodayCard wandert hierher und verschwindet von der Leads-Seite.
   d) Verträge: offene Anträge (wie Reiter, ohne abgelehnte), auslaufende (auslaufende()), Zahlungsverzüge
      (imVerzug(); bei 0 grüne Zeile "Keine Zahlungsverzüge").
   e) Schüler im Rückstand: board_schueler mit ampel deutlich, dann leicht, je nach rueckstand absteigend;
      Pille mit Ampeltext, "x von y verbraucht". Kein "gemeistert" irgendwo.
   f) Inhalte freigeben: Aufgaben im Status review, gruppiert nach Thema (über skill_key und skill_thema),
      Zeile Thema, Stufe, Anzahl, Knopf "Freigeben" führt in die Item-Pflege. Rückfragen von Lena erst, wenn es
      dafür einen Status gibt (Lena-Board v2); bis dahin keine Zeile.
5. "Heute im Betrieb" (rechte Spalte ab 980 px Inhaltsbreite, darunter unter den Listen): Sessions von heute aus
   coaching_sessions (Europe/Berlin) mit Uhrzeit, Raum, Coach, belegten Plätzen von 5 (fünf Punkte), dazu
   Lernstandsanalysen von heute mit Pille "LSA". Neue Lesefunktion listSessionsHeute() in heute.ts, eine Abfrage
   ohne N+1. Absagen erst mit dem Slots-Feature; jetzt keinen Block dafür bauen.
6. AdminDashboard.tsx, AdminWidgetGrid.tsx, die .admin-*-Klassen in globals.css und ihre Tests löschen.
   i18n-Schlüssel dashboard.* durch heute.* ersetzen.

ABNAHME
Mit Prod-Testdaten: jede Liste zeigt dieselben Zahlen wie ihr Bereich (Leads-Board, Reiter unter Verträge,
Schüler-Board). Leere Listen zeigen "nichts offen". Auf dem Laptop sind ohne Scrollen sichtbar: Kopf, Kennzahlen,
die erste Reihe der Listen und "Heute im Betrieb". Screenshots in drei Größen.
```

---

## H4a — Betrieb und Verträge umziehen

```text
Du arbeitest im Repo Edvancev1. Paket H4a des Bauauftrags Admin-Hülle. H2 ist gemergt.

LEITPLANKEN
- Branch: git fetch && git checkout -b feat/rasit-admin-h4a-betrieb origin/dev · PR gegen dev, niemals main · nichts unter .github/.
- Kein DDL, keine Änderungen in src/lib/** oder src/types/**. Nur Seitenrahmen umbauen, keine Fachlogik.
- CLAUDE.md §11/§12 wie in H2.

UMFANG
Seiten: SchedulePage, SlotsManagePage, SlotPickerPage, CoachesPage, AssignmentsPage, VertragDetailPage.
Je Seite: EdvanceNavbar, AdminHeader, äußeren Wrapper und eigenes max-w-* entfernen, AdminPageHeader einsetzen.
Formulare, die heute schmal sind (Stundenplan 768 px), dürfen schmal bleiben, stehen aber links im Inhaltsbereich
statt mittig; Listen und Raster nutzen die volle Breite. VertragDetailPage bekommt "← Verträge".

ABNAHME
Keine dieser Seiten importiert noch EdvanceNavbar oder AdminHeader. Screenshots je Seite auf 1440 und 820.
```

## H4b — Inhalte umziehen, Altlasten löschen

```text
Du arbeitest im Repo Edvancev1. Paket H4b des Bauauftrags Admin-Hülle. H4a ist gemergt.

LEITPLANKEN
Wie H4a. Branch: feat/rasit-admin-h4b-inhalte.

UMFANG
1. Seiten: AuthoringItemsPage, ItemBoardPage, AuthoringEditorPage ("← Item-Pflege"), ContentHealthPage,
   QsPage, DiagnosticsPage, ReportPage. Umbau wie H4a. Der Knopf "Expertenliste" (ItemBoardPage) steht danach
   auf hellem Grund und bleibt outline.
2. PflegeWizardPage bleibt Fokus-Seite ohne Leiste; WizardTopBar nutzt den neuen Midnight-Verlauf aus H1.
3. Altlasten: AdminHeader.tsx löschen, wenn nichts es mehr importiert; EdvanceNavbar nur noch dort, wo
   Nicht-Admin-Rollen es brauchen. Unbenutzte .admin-*-Klassen und die Kachel-Texte in admin.json entfernen.

ABNAHME
grep über src/pages/admin findet weder EdvanceNavbar noch AdminHeader (außer in Fokus-Seiten, falls nötig, mit
Begründung im PR). Screenshots je Seite auf 1440 und 820.
```

## H5 — Suche ⌘K (optional)

```text
Du arbeitest im Repo Edvancev1. Paket H5 des Bauauftrags Admin-Hülle. H4b ist gemergt.

LEITPLANKEN
Wie H2. Eine neue Abhängigkeit ist erlaubt: cmdk (läuft mit React 18). Branch: feat/rasit-admin-h5-suche.

UMFANG
Suchfeld oben in der Leiste (in der schmalen Spalte als Symbol "Suchen"), Tastenkürzel ⌘K / Strg+K, Escape schließt.
Treffer gruppiert: Seiten, Schüler (board_schueler), Leads (listLeads), Verträge (listVertraegeAktuell).
Auswahl springt in den Bereich und setzt dort den Suchbegriff. Daten erst beim Öffnen laden.

ABNAHME
Drei Buchstaben eines Nachnamens finden in den Testdaten das Kind (Schüler), den Lead und den Vertrag mit diesem
Namen; Tastatur hoch/runter/Enter funktioniert.
```

---

## Außerhalb der Pakete

- **React 19:** Die aktuellen shadcn-Bausteine (Sidebar, Command, Dialog) sind auf React 19 ausgelegt. Ein Upgrade von Edvancev1 (React 18.3) ist eine eigene Entscheidung; die Hülle braucht es nicht.
- **Dark Mode:** weiterhin offen (DESIGN_SYSTEM.md). Die Hülle arbeitet nur über Tokens, ein späterer Dark Mode muss nur die Tokens umdefinieren.
- **Coach-Hülle:** gleiche Bausteine mit eigener Leiste (Schüler, Sessions), später.
- **Wortmarke:** Space Grotesk wird nur für „edvance“ im Logo geladen. Als SVG-Pfad gespeichert fiele die Schrift weg.
