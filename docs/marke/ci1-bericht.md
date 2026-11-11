# CI-1 · Abnahme und Bericht · `Edvancev1`

**Stand:** 11.11.2026 · Teil A, B und D. Teil C (`edvance-app`) berichtet die andere Session.

## PRs (alle gegen `dev`, gestapelt, in dieser Reihenfolge mergen)

| Schritt | PR | Inhalt |
|---|---|---|
| 0 | #387 | `docs/marke/ci1-bestand.md` (ohne Namen) |
| 1 | #388 | Logo „Funke“ aus den SVG-Dateien, Favicon |
| 2 | #389 | Login (Teil A) |
| 3 | #390 | Navigation, Heute, Tokens, weißer Rand, Home-Bildschirm-App (Teil B) |
| 3b | #391 | Testdaten ausblenden, Datenmigration (Teil D) |
| 5 | dieser PR | Bericht, Abnahmefotos, Korrekturen aus der Abnahme |

Gemergt am 11.11.2026 per Squash in dieser Reihenfolge; vor jedem Merge wurde `dev` in den nächsten Branch
eingemischt. Dabei fiel in #390 ein Test auf, der an der Uhrzeit hing (eine laufende Session schrieb „Läuft
gerade · Coach“ in ein Element); das Label steht jetzt in einem eigenen Element.

## 1. Ansichten (Abnahmefotos in `docs/marke/ci1-fotos/`)

| Ansicht | Foto |
|---|---|
| Login, iPad quer | `login-ipad-quer.png` |
| Login, iPad hoch | `login-ipad-hoch.png` |
| Login, iPhone | `login-iphone.png` |
| Admin „Heute“, iPad quer (laufende Session als Navy-Karte) | `heute-ipad-quer.png` |
| Admin „Heute“, iPad hoch (Kopfzeile mit Menü) | `heute-ipad-hoch.png` |
| Admin „Heute“, iPhone | `heute-iphone.png` |
| Schmale Leiste mit vier Bereichen (1000 px) | `leiste-schmal.png` |
| Coach-Heute (Freigabe 7.4) | `coach-heute.png` |
| Lena-Board / Item-Pflege (Freigabe 7.4) | `lena-board.png` |
| Lead-Board mit Schalter „Testdaten anzeigen (2)“ | `leads-testdaten.png` |

Login-Fotos aus dem echten Dev-Server; alle anderen aus einem Wegwerf-Harness mit erfundenen Daten (kein Zugriff
auf die Datenbank, kein Request an Supabase). Aufnahme in Desktop-Chromium mit den Maßen von iPad und iPhone —
keine Geräteaufnahme.

**Korrekturen aus der Abnahme (in diesem PR):** Knöpfe ohne enge Laufweite (Plus Jakarta Sans hat ein schmales
Leerzeichen, „NeuerLead“), Betrieb-Karten brechen auf dem iPhone um statt Raum und Coach abzuschneiden,
Kennzahl-Labels und -Unterzeilen brechen um, Titel ohne `tracking-tight`, `accent-color` für Checkboxen,
`--color-text-tertiary` auf AA (siehe 10).

**Auffällig, nicht geändert:** Auf Coach-Heute ist die laufende Session weiter eine weiße Karte mit grüner Pille
„läuft“ (Coach bekommt laut Auftrag nur das neue Aussehen). Der Bindestrich in „Live-Sicht“ wirkt in der Schrift
leicht gesperrt.

**Abweichungen von den Mockups**
- Logo überall aus den SVG-Dateien (`public/marke/`, unverändert kopiert), nichts nachgezeichnet.
- Laufende Session auf „Heute“: Die Karte trägt die vorhandene eine Aktion der Zeile („Live-Sicht“, wenn die
  Session schon angelegt ist, sonst „Session öffnen“). Beide Aktionen gleichzeitig bräuchten die Session-ID eines
  noch nicht geöffneten Raum-Termins, also eine neue Abfrage — nicht gebaut.
- Schmale Leiste: ein Eintrag je Bereich (Ziel = erster Unterpunkt). Die Unterpunkte erreicht man dort über
  „Menü“ (volle Leiste als Überlagerung), wie bisher alle Einträge.
- „Zu erledigen“: Reihenfolge der Listen wie bisher. Jede Liste ist eine Zeile mit Zähler, Unterzeile und einer
  Aktion (Pfeil in den Bereich); darunter stehen wie bisher bis zu drei Einträge mit ihren Knöpfen („Termin“,
  „Vertrag starten“), damit nichts von „Heute“ verloren geht.

## 2. Schriften

Plus Jakarta Sans ist die einzige Schrift der App (`--font-marke`; `--font-sans`, `--font-body` und `--font-serif`
zeigen darauf). Space Grotesk ist ganz entfernt (Logo-Komponente, Font-Link).

**Ausnahmen (Entscheidung Rasit 11.11.2026, 7.1 und 7.2):**
- Druckbogen R7 und Tablet-Präsentation behalten Schibsted Grotesk, Fraunces und Literata nach dem abgenommenen
  Muster E7 (`--font-eb-text`, `--font-eb-serif`, `--font-eb-titel`, `--font-eb-marke`; Font-Link in `index.html`).
  Der PDF-Export (`src/lib/report/bogenPdf.ts`) prüft genau diese Schriften. Eigener Auftrag folgt.
- Aufgaben-Figuren (`scripts/figures/**`) setzen Schibsted in hochgeladene SVGs. Eigener Auftrag folgt.
- Alte Dummies, Retros, Bauaufträge und `docs/report/r7/E7-Masse.md` bleiben als Historie
  (Liste in `ci1-bestand.md` 2e).

## 3. Alte Markenfarben

In den geänderten Oberflächen (Login, Leiste, Heute, Konto-Seiten) steht kein alter Wert mehr (`#2D6A9F`,
`#334D7A`, `#14213D`, `#E8A020`, `--color-gold-altgold`, `--color-gold-champagner`). `ThemeContext` zeigt die
neue Marke (Freigabe 7.3). Die Token-Umstellung (Freigabe 7.4) wirkt bewusst auch auf Coach-Flächen.

Bewusst unverändert: die Schüler-Bühne (`--color-stage-*`, neu `--color-stage-primary`/`--color-stage-accent`
mit den alten Werten, damit `--color-primary`/`--color-accent` sie nicht mehr umfärben), Druckbogen und
Präsentation (`--color-eb-*`, `--color-tp-*`).

## 4. Admin-Menüpunkte vorher → nachher

| Eintrag | Route | vorher | nachher |
|---|---|---|---|
| Heute | `/admin` | ohne Gruppe | **Heute** |
| Leads | `/admin/leads` | Vertrieb | **Kinder** |
| Schülerakten | `/admin/akten` | Betrieb | **Kinder** |
| Verträge | `/admin/vertraege` | Verwaltung | **Kinder** |
| LSA-Reports | `/admin/lsa-reports` | Verwaltung | **Kinder** |
| Eltern-Reports (bald) | — | Verwaltung | **Kinder** (bald) |
| Item-Pflege | `/admin/authoring` | Inhalte | **Inhalte** |
| LSA-Abdeckung | `/admin/lsa-abdeckung` | Inhalte | **Inhalte** |
| Klassenarbeiten | `/admin/klassenarbeiten` | Verwaltung | **Inhalte** |
| Studio | `/admin/studio` | Inhalte | **Inhalte** |
| Slots | `/admin/slots` | Betrieb | **Planung** |
| Coaches | `/admin/coaches` | Betrieb | **Planung** |
| Stellschrauben | `/admin/stellschrauben` | Verwaltung | **Fuß der Leiste** |

Routen, `aktivBei`-Muster und Zähler sind unverändert; Seiten ohne Menüpunkt (`/admin/qs`, `/admin/diagnostics`,
`/admin/assignments`, `/admin/content-gesundheit` u. a., `ci1-bestand.md` 4b) bleiben so erreichbar wie vorher.
Ein Test prüft, dass jede Route von vorher in der Leiste steht (`shell.test.tsx`).

## 5. und 6. Weißer Rand, Home-Bildschirm-App

Gebaut: `html` trägt den Seitengrund (Login: Navy), `overscroll-behavior: none` auf `html`, `body` und dem
Scrollbereich der Hülle; `manifest.webmanifest` (`display: standalone`, Navy, Icons 192/512/maskable aus
`edvance-zeichen-auf-dunkel.svg`), `apple-touch-icon`, `apple-mobile-web-app-*`, `viewport-fit=cover` und
Safe-Area-Abstände in Leiste, Kopfzeile, Inhalt und Login.

**Nicht geprüft:** iPad-Safari, iPad- und iPhone-Home-Bildschirm habe ich hier nicht. Bitte auf den Geräten
abnehmen (Vercel-Preview von #390 bzw. nach dem Merge). Im Desktop-Chromium tritt kein weißer Rand auf.

## 7. und 8. LSA

Teil C, andere Session (`edvance-app`).

## 9. Testdaten

- Datenmigration `20261111133355_ci1_testdaten_markieren` eingespielt (29 Leads, 1 Schüler false → true,
  nichts gelöscht). Vorher leads 18/30, students 42/2 (test/echt); nachher 47/1 und 43/1.
- Ohne Schalter zeigen Lead-Board, Akten (Admin-Sicht), LSA-Reports, Verträge und „Heute“ keine Zeile mit
  `ist_test`. Der Schalter „Testdaten anzeigen (n)“ holt sie zurück und merkt sich die Wahl pro Seite.
- Coach-Sicht, Session-Testläufe und Lenas Prüfansicht sind nicht berührt.
- **Kind B:** Alle vier Einträge (zwei Leads, zwei Schülerinnen) standen schon auf `ist_test = true` und stehen
  weiter so (Auftrag: nichts ändern). Ohne Schalter steht deshalb nur Kind A in den Listen. Soll Kind B
  erscheinen, braucht es eine kleine Datenmigration true → false.

## 10. Kontraste (WCAG 2.1, berechnet aus den Token-Werten)

| Text / Grund | Verhältnis | AA |
|---|---|---|
| Ivory auf Navy (Leiste, Login, laufende Session) | 15,0 : 1 | ja |
| Navy auf Ivory (Login-Karte, Titel) | 15,0 : 1 | ja |
| Weiß auf Cobalt (Hauptknopf) | 5,2 : 1 | ja |
| Cobalt auf Ivory (Link) | 4,8 : 1 | ja |
| Cobalt auf Weiß (Links in Karten) | 5,2 : 1 | ja |
| Amber-Schrift (`--color-marke-amber-text` #89672A) auf Ivory (Datum, Uhrzeit) | 4,8 : 1 | ja |
| Navy auf Amber (Zähler-Pille) | 6,6 : 1 | ja |
| Ivory 76 % auf Navy (Leisten-Einträge) | 9,1 : 1 | ja |
| Ivory 60 % auf Navy (Gruppentitel) | 6,2 : 1 | ja |
| Ivory auf aktivem Bereich (Cobalt 35 % über Navy) | 10,3 : 1 | ja |
| Navy 72 % auf Ivory (Login-Untertitel) | 6,2 : 1 | ja |
| Ivory 64 % auf Himmel unten (Login-Fuß) | 5,4 : 1 | ja |
| Nebentext `--color-text-tertiary` auf Ivory | 5,0 : 1 (vorher 3,3) | ja |
| Nebentext `--color-text-tertiary` auf Weiß | 5,4 : 1 (vorher 3,6) | ja |
| Amber pur auf Ivory | 2,3 : 1 | nur Deko, nie Text |

Korrektur aus der Abnahme: `--color-text-tertiary` war `#888884` (3,3 : 1 auf Ivory) und ist jetzt ein
Navy-Zwischenton (65 % Navy, 35 % Ivory).

## Offene Punkte

1. Geräteabnahme iPad/iPhone (Punkte 5 und 6).
2. Kind B: Markierung bleibt `true`, bis Rasit anders entscheidet.
3. Eigene Aufträge: Schriften im Druckbogen R7/Präsentation und in den Aufgaben-Figuren.
