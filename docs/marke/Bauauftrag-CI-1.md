# Bauauftrag CI-1 · Neue Marke in Login, Admin-Übersicht und LSA

**Stand:** 11.11.2026 · **Auftraggeber:** Rasit · **Repos:** `Edvancev1` (Login, Admin) und `edvance-app` (LSA-Kinderstrecke)

## Worum es geht

Die Brand Foundation v1.2 gilt seit 11.11.2026 als abgenommen. Das Logo ist entschieden:
**„R3 · Funke“** aus dem Schriftboard Wortmarke. Die Wortmarke „edvance“ ist in Plus Jakarta Sans 800 gesetzt,
das Zeichen links ist eine Schale mit Lichtpunkt.

Dieser Auftrag bringt die Marke in drei Oberflächen:

1. Login (`Edvancev1`)
2. Admin-Übersicht mit Navigation (`Edvancev1`)
3. Schüler-App während der LSA (`edvance-app`, Kinderstrecke `/lsa/*` und `/session/warten`)

Dazu kommt Teil D: Testdaten verschwinden aus den Admin-Listen, ohne gelöscht zu werden.

Die Abläufe bleiben gleich. Geändert werden Erscheinung, Schrift, Logo, Navigation und die Sichtbarkeit von Testdaten, sonst nichts.

## Verbindliche Vorgaben

### Farben (Brand Foundation v1.2)

| Name | Hex | Rolle |
|---|---|---|
| Midnight Navy | `#102038` | dunkle Basis, Navigation, Bühne der LSA, Schrift auf hell |
| Warm Ivory | `#F8F5EE` | heller Grund, Arbeitsfläche |
| Radiant Cobalt | `#4567C6` | Markenblau, Hauptaktion (genau eine je Ansicht), Fokus |
| Amber | `#DA9721` | Akzent: Lichtpunkt im Logo, Fortschritt der Stationen, Eddie |

- Weiß `#FFFFFF` ist für Karten und Eingabefelder auf Ivory erlaubt.
- Zwischentöne für Linien und Nebentext legt Schritt 0 als Tokens fest und begründet sie. Erfinde keine neuen Markenfarben.
- In `edvance-app` stimmen `lsa.navy`, `lsa.gold` und `lsa.creme` bereits mit Navy, Amber und Ivory überein. Cobalt fehlt dort und kommt dazu.

### Schrift

- **Plus Jakarta Sans** ist die einzige Schrift, in beiden Repos und für alle Texte:
  - 800 nur für die Wortmarke
  - 700 oder 600 für Titel
  - 500 für Aufgabentext und Bedienung
  - 400 für Fließtext
- **Literata entfällt vollständig**, auch für die persönlichen Titel der LSA („Hi …!“, „Das ist Eddie.“, „Geschafft!“).
- **Schibsted Grotesk entfällt** ebenfalls.
- Ziffern in Aufgaben und Eingaben sind gleich breit (Tabellenziffern, `tnum`). Prüfe das an Rechenausdrücken und Zahleneingaben.

### Logo

- **Quelle:** die SVG-Dateien von R3 · Funke aus dem Schriftboard. Sie liegen seit 11.11.2026 in beiden Repos unter `docs/marke/logo/` (`edvance-logo-*`, `edvance-wortmarke-*`, `edvance-zeichen-*`), in diesen Fassungen:
  - Zeichen und Wortmarke
  - Wortmarke allein
  - Zeichen allein
  - jeweils für hellen und dunklen Grund und für Cobalt
- **Zeichne das Logo nicht nach.** Fehlen die Dateien, stoppe den Lauf und melde es.
- Varianten nach Grund:
  - auf Ivory: Navy mit Lichtpunkt in Amber
  - auf Navy: Ivory mit Amber
  - auf Cobalt: Ivory mit Lichtpunkt in Ivory
- Kleine Größen und App-Icon: Zeichen allein. Das gilt für Favicon, Home-Bildschirm-Icon und die schmale Navigationsleiste.

## Gestaltungstiefe (gilt für alle Teile)

Die Oberflächen sollen nicht wie ein Baukasten aus gleichen Kacheln wirken. Dafür gelten diese Regeln:

- **Eine Lichtquelle:** der Amber-Lichtpunkt des Logos. Dunkle Flächen bekommen einen schwachen Amber-Schein oder Lichtsaum, helle Karten eine helle Oberkante und einen weichen Schatten nach unten.
- **Schatten immer zweistufig:** ein enger, dunklerer Schatten plus ein weiter, weicher. Keine harten Einzelschatten, keine Rahmen als Ersatz für Tiefe.
- **Rangfolge statt Gleichmaß:** Je Ansicht gibt es genau ein Hauptelement, das größer und kontrastreicher ist als der Rest. Auf „Heute“ ist das die laufende Session als dunkle Karte.
- **Kennzahlen als eine Leiste** mit Trennlinien, nicht als fünf einzelne Kacheln.
- **Horizont-Motiv** aus der Logo-Schale: im Login groß, in der Admin-Leiste unten klein. Sonst nirgends.
- **Bedienelemente fühlbar:** Hauptknopf mit leichtem Verlauf und Schatten, Tasten der LSA mit sichtbarer Unterkante, gedrückter Zustand sinkt 2 px ein.
- **Radien gestaffelt:** große Flächen 28–30, Karten 20, Felder und Knöpfe 13–15, Zähler 10.
- **Ziffern gleich breit** (`tnum`) in Kennzahlen, Zeiten und Eingaben.
- **Grenzen:** In der LSA gibt es keine Sterne während der Aufgaben und keine Dekoration außerhalb von CLAUDE.md §9. Glas nur auf dunklem Grund. Schatten und Schein dürfen nie eine Bedeutung tragen, die das Kind als Bewertung lesen könnte.

## Teil A · Login (`Edvancev1`, `src/pages/Login.tsx`)

Vorlage ist das Mockup „Login mit Tiefe“ vom 11.11.2026.

- **Grund:** vollflächiger Nachthimmel statt geteilter Ansicht. Navy-Verlauf von fast schwarz oben zu Blau unten, angelehnt an `edvance-app/src/components/lsa/ZeitHimmel.tsx`.
- **Sterne:** rund 70 an festen Positionen in drei Größen (1,6 / 2,6 / 4 px). Nur die wenigen großen leuchten leicht. Keine Zufallswerte beim Rendern.
- **Horizont:** ein sehr großer, leicht geneigter Kreisbogen im unteren Drittel, abgeleitet aus der Schale des Logos, mit feinem Amber-Lichtsaum an der Kante.
- **Lichtpunkt:** ein Amber-Punkt mit Schein knapp über dem Horizont, links der Mitte. Er ist die Lichtquelle der Ansicht.
- **Links:** oben Zeichen und Wortmarke für Navy, unten `login.markeZeile` und die Fußzeile.
- **Formular:** eine Ivory-Karte, die rechts vor dem Himmel schwebt (Radius 28, weicher zweistufiger Schatten, helle Oberkante). Titel in Plus Jakarta Sans 700, Felder weiß mit feinem Innenschatten, Fokus in Cobalt mit Ring, „Anmelden“ in Cobalt.
- **Bewegung:** höchstens sehr langsames Schimmern einzelner Sterne. Mit `prefers-reduced-motion` steht alles still.
- **Hochformat und iPhone:** Karte mittig, Horizont und Lichtpunkt darunter sichtbar, Logo darüber.
- Für das Web wird der Himmel mit CSS oder SVG gebaut. Den React-Native-Code nicht importieren.
- Die Texte aus `konto.json` bleiben, mit einer Ausnahme:
  - `login.fuss` heißt heute „Klasse 5 – 13 · Köln · Pre-Launch“.
  - Neu: „Klasse 8 – 10 · Köln“, passend zur extern kommunizierten Zielgruppe.
  - **Rasit bestätigt diese Änderung in Schritt 0.**
- Anmelde-Logik, Fehlertext `login.falsch` und „Passwort vergessen?“ bleiben unverändert.

## Teil B · Admin-Übersicht und Navigation (`Edvancev1`)

### Navigation

- Die heutigen Gruppen in `src/components/edvance/admin/adminNav.ts` (Vertrieb, Betrieb, Verwaltung, Inhalte) werden zu vier Arbeitsbereichen. Alle Einträge, Routen, `aktivBei`-Muster und Zähler bleiben erhalten:

| Bereich | Einträge (ID aus `ADMIN_NAV`) |
|---|---|
| **Heute** | `heute` |
| **Kinder** | `leads`, `schueler`, `vertraege`, `lsaReports`, `elternReports` (bleibt „bald“) |
| **Inhalte** | `itemPflege`, `lsaAbdeckung`, `klassenarbeiten`, `studio` |
| **Planung** | `slots`, `coaches` |
| Fuß der Leiste | `stellschrauben` (als Einstellung, über dem Konto) |

- Gruppentitel in `admin.json`: `nav.gruppe.kinder`, `nav.gruppe.inhalte`, `nav.gruppe.planung`. Die alten Schlüssel entfallen.
- Coach-Navigation (`coachNav.ts`) bleibt inhaltlich unverändert und bekommt nur das neue Aussehen.
- Schritt 0 prüft, ob es Admin-Routen gibt, die nur über Links erreichbar sind, zum Beispiel `/admin/content-gesundheit`, `/admin/qs` oder `/admin/diagnostics`. Sie bleiben so erreichbar wie heute.
- Die Leiste ist Navy:
  - **Schmale Fassung:** Zeichen oben, je Bereich Icon und kurze Beschriftung, der aktive Bereich hinterlegt in Cobalt mit etwa 35 % Deckkraft, unten die Initialen.
  - **Volle Fassung:** Wortmarke und die Unterpunkte des Bereichs.
- `ShellSidebar`, `AppShell` und die Nav-Konfiguration werden umgebaut. Die Rollenlogik der Konfiguration bleibt: Coach und Admin sehen weiterhin nur, was sie sehen dürfen.

### Übersicht „Heute“ (`HeutePage.tsx`)

Vorlage ist das Mockup „Admin Heute mit Tiefe“ vom 11.11.2026. Daten und Texte bleiben, die Anordnung ändert sich:

- **Kopf:** Datum in Amber, darunter der Gruß. „Neuer Lead“ ist die einzige Cobalt-Aktion.
- **Kennzahlen:** die fünf vorhandenen Werte als eine Leiste mit Trennlinien.
- **Heute im Betrieb:** links als Zeitachse mit Uhrzeit-Spalte. Die laufende Session ist eine dunkle Navy-Karte mit Amber-Punkt und den Aktionen „Live-Sicht“ und „Session öffnen“. Kommende Termine sind helle Karten.
- **Zu erledigen:** rechts eine Karte, die die sechs Listen als Zeilen mit Zähler, Unterzeile und einer Aktion zeigt. Reihenfolge wie heute: was am längsten wartet, steht oben. Listen ohne offene Punkte erscheinen blass mit Haken.
- „Batus Freigabeliste“ bleibt als eigene Zeile, solange sie Einträge hat.
- **Keine neuen Daten oder Abfragen.**

### Darstellungsfehler, die mit behoben werden

- **Weißer Rand beim Über-Scrollen:** Hintergrund von `html` und `body` auf den Seitengrund setzen, `overscroll-behavior: none` für die Hülle. Prüfe das auf dem iPad in Safari und als Home-Bildschirm-App.
- **Home-Bildschirm-App für das Admin:** Manifest mit Name, Icon (Zeichen allein) und Farben, `display: standalone`, Apple-Meta-Tags, Safe Areas. Ziel: auf iPhone und iPad ohne Browserleiste, solange es noch keine TestFlight-App gibt.

### Tokens

`src/styles/tokens.css` und `globals.css`: Navy, Ivory, Cobalt und Amber als Markentokens, Plus Jakarta Sans als Schrift. Alte Markenwerte wie `#2D6A9F` werden ersetzt, nicht parallel weitergeführt. Schritt 0 listet alle Fundstellen der alten Werte auf.

## Teil D · Testdaten aus dem Weg räumen (`Edvancev1`)

Wunsch Rasit, 11.11.: Die Testkinder und Testleads stehen heute im Lead-Board mit drin, vor allem in den rechten Spalten, und machen es unübersichtlich. Sie werden archiviert, nicht gelöscht.

- **Markierung, die es schon gibt:** `leads.ist_test` und `students.ist_test`. Das Lead-Board zählt Testleads heute nicht mit (`zaehlt={(lead) => lead.ist_test !== true}`), zeigt sie aber an.
- **Neu:** Testdaten sind überall standardmäßig ausgeblendet:
  - Lead-Board, alle Spalten
  - Schülerakten
  - LSA-Reports
  - Verträge
  - die Listen auf „Heute“
- **Schalter „Testdaten anzeigen (n)“** oben rechts im Lead-Board und in den Akten, aus per Default. Die Wahl merkt sich die Seite pro Browser.
- **Testläufe bleiben nutzbar:**
  - Coach-Sicht, Session-Testläufe (`coaching_sessions.testlauf`) und die Testkinder in Lenas Prüfansicht funktionieren wie heute.
  - Ausgeblendet wird nur in den Admin-Listen.
- **Schritt 0 prüft per dbread, ob alle Testdaten wirklich markiert sind:**
  - Liste aller Leads und Schüler mit Namen wie Batu, Max, „Test“, Testkind, Rasit und so weiter
  - jeweils mit dem heutigen Wert von `ist_test`
  - Rasit hakt die Liste ab. Fehlende Markierungen setzt danach eine kleine Datenmigration, mit Prüfabfrage und ohne Löschung.
- **Keine Schemaänderung.** Die Felder gibt es schon. Ob Batu, dessen Daten echt sind, als Test gilt, entscheidet Rasit in der Liste.

## Teil C · Schüler-App während der LSA (`edvance-app`)

- Gilt für die Kinderstrecke `/lsa/*` und `/session/warten`.
- Vorlage ist das Mockup „LSA-Fläche mit Tiefe“ vom 11.11.2026.
- **Aufbau bleibt.** Die LSA nutzt `LsaAufgabe` mit `layout="flaeche"`:
  - Navy-Grund
  - oben links die Stationsspur, oben rechts der Rechner
  - die cremefarbene Arbeitsfläche mit Aufgabe, Linie, Antwort und eigener Tastatur
  - Zeitlicht
  - Eddie unten links ohne Satz daneben, „Ich weiß es nicht“ über die Eddie-Leiste
  - „Weiter“ unten rechts
  - Maße aus `tokensLsa.ts` (`lsaMassstab` 1180 × 820)
- Die Session (`zweispaltig`) gehört nicht zu diesem Auftrag.
- **`tokensLsa.ts`:** Alle Einträge von `lsaFonts` stellst du auf Plus Jakarta Sans um, über `@expo-google-fonts/plus-jakarta-sans`. Größen, Zeilenhöhe und Laufweite der Textstile prüfst du neu: Literata ist schmaler als Plus Jakarta Sans. Achte vor allem auf:
  - `hero`, `titel`, `geschafft`
  - lange Namen
  - die Aufgabentexte nach LSA-TX
- **Cobalt** kommt als `lsa.cobalt` für die Hauptaktion („Weiter“) und den Fokus des Eingabefelds dazu.
- **Logo:** Wo heute Wortmarke oder Symbol erscheinen (Willkommen, Warten), stehen jetzt Zeichen und Wortmarke von R3 in der Fassung für Navy.
- **Unverändert gilt CLAUDE.md §6 (Diagnose):** kein Richtig oder Falsch, keine Farbe pro Item, keine XP, kein Score, „Geschafft“ ohne Ergebnis.
- **Unverändert gilt CLAUDE.md §9:** Verläufe und Bewegung nur wie dort beschrieben, `useReducedMotion` bleibt.
- **CLAUDE.md:** §9 und der neue §11 „Marke“ sind seit 11.11.2026 angepasst (beide Repos). Nach dem Umbau den Übergangssatz „der Code stellt sie mit Bauauftrag CI-1 um“ entfernen.
- **Globale Tokens:** Die globalen Tokens (`colors.*`, Hub und Session) gleichst du in diesem Auftrag **nicht** an. Das bleibt ein eigener Auftrag, siehe CLAUDE.md §8. Schriftart und Logo dürfen in der ganzen App wechseln, wenn das nur über eine zentrale Stelle läuft. Klärt Schritt 0, dass das nicht geht, bleibt es bei der Kinderstrecke.

## Ablauf

| Schritt | Inhalt | Ergebnis |
|---|---|---|
| 0 | Bestandsaufnahme in beiden Repos: <br>• Fundstellen von Literata, Schibsted Grotesk und den alten Markenfarben <br>• alle Admin-Menüpunkte und Routen mit Vorschlag zur Bereichszuordnung <br>• vorhandene Datenquellen für „Heute“ <br>• Logo-Dateien vorhanden? | `docs/marke/ci1-bestand.md`, **Halt für Rasits Freigabe der Zuordnung** |
| 1 | Logo-Komponenten in beiden Repos aus den SVG-Dateien, Favicon und Icons | PR je Repo |
| 2 | Teil A Login | PR `Edvancev1` |
| 3 | Teil B Navigation, Heute, Tokens, weißer Rand, Home-Bildschirm-App | PR `Edvancev1` |
| 3b | Teil D Testdaten ausblenden, Schalter, ggf. Datenmigration für fehlende Markierungen | PR `Edvancev1` |
| 4 | Teil C LSA-Schrift, Cobalt, Logo, CLAUDE.md §9 | PR `edvance-app` |
| 5 | Abnahme und Bericht | `docs/marke/ci1-bericht.md` |

**Regeln aus beiden CLAUDE.md:**
- Ein Lauf, ein Branch, ein PR, immer gegen `dev`.
- Typecheck und Tests müssen grün sein.
- Den Merge macht der Mensch.
- **Keine Schema- oder Funktionsänderung.** Braucht „Heute“ eine neue Abfrage, stoppe den Lauf und melde es. Einzige erlaubte Datenänderung ist die Markierung `ist_test` aus Teil D, nach Rasits Freigabe der Liste.

## Abnahme

1. Login, Admin „Heute“ und LSA-Aufgabe sehen auf dem iPad quer, dem iPad hoch und dem iPhone aus wie die Mockups vom 11.11.2026, mit diesen Abweichungen:
   - Die LSA behält die Arbeitsfläche mit allen Maßen aus `tokensLsa.ts`.
   - Das Logo kommt aus den SVG-Dateien.
   Lege für jede Ansicht ein Abnahmefoto in den Bericht.
2. Keine Fundstelle von Literata oder Schibsted Grotesk mehr in beiden Repos. Ausnahmen: alte Dummies und `design-reference/`, Begründung im Bericht.
3. Keine alten Markenfarben in den geänderten Oberflächen.
4. Jeder Admin-Menüpunkt von vorher ist über einen der vier Bereiche erreichbar. Lege eine Liste „vorher → nachher“ in den Bericht.
5. Kein weißer Rand beim Über-Scrollen, geprüft auf dem iPad in Safari und als Home-Bildschirm-App.
6. Die Admin-App lässt sich auf dem iPhone als Home-Bildschirm-App ohne Browserleiste öffnen.
7. LSA:
   - `e2e/lsa-aufgabentext.spec.ts` ist grün, kein Aufgabentext wird abgeschnitten.
   - Lange Namen in „Hi …!“ und „Geschafft“ passen.
   - Zahlen und Einheit brechen nicht um.
8. LSA-Regeln nachweislich unverändert: kein Feedback pro Item, keine XP, `done` ohne Ergebnis.
9. Testdaten: Lead-Board, Akten, LSA-Reports, Verträge und „Heute“ zeigen ohne den Schalter keine Zeile mit `ist_test`. Mit dem Schalter sind alle wieder da. Testläufe in der Coach-Sicht funktionieren wie vorher.
10. Kontrast mindestens WCAG AA für Text auf Navy, Ivory und Cobalt. Messwerte im Bericht.

## Nicht in diesem Auftrag

- Neugestaltung der Session-Oberfläche: eigene Aufgabe bei Tolunay und Rasit.
- Globale Tokens für Hub und Session in `edvance-app`.
- Website, Print, Social Media.
- TestFlight und das Apple-Entwicklerkonto: eigene Aufgabe bei Tolunay.
