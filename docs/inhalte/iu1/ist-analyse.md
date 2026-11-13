# IU-1 · U0 Ist-Analyse: Inhalte-Übersicht

**Stand:** 13.11.2026, `origin/dev` = `75489322`. Zeilen in `supabase/schema-erwartet.sql` heißen hier kurz `S:<zeile>`.
Abfragen in `abfragen/`, Ausgaben in `ergebnisse/`. Gelesen wurde Prod nur per `dbread`.

**Dummy:** `referenz/inhalte-uebersicht-dummy.html` (aus `C:\Users\rasit\Downloads`). Einmal ganz durchgeklickt
(Playwright, 1440 × 900), Fotos in `referenz/klick/01…10`: beide Reiter, Filter Klasse 9 und 8, Detail MSA (Karten
je Bereich), Detail „Quadratische Funktionen“ (Pflicht und Tiefe, „n von 2“, „In Lenas Liste“), nicht ausgearbeitetes
Thema (Hinweis), Reihe 1 mit 7 Session-Karten, „Reihe anlegen“ (Hinweis).

---

## 1 · LSA: Themenraum, Pflicht/Tiefe, Regel, Pakete

| Baustein | Funktion | Beleg |
|---|---|---|
| Pakete je Schule × Klasse × Klassenarbeit, mit `thema_keys`, `quelle` (bestätigt/geschätzt), `datum`, `quartal` | `lsa_pakete_basis(schuljahr)` (Speicher oder live `lsa_pakete_roh`) | S:9362, S:9384 |
| Skills je Paket mit `fall` (A/B), `teil` (einstieg, voraussetzung, tiefe, rand, rand_tiefe), `pflicht` | `lsa_paket_skills_basis(schuljahr)` (Speicher oder live `lsa_paket_skills_roh`) | S:9222, S:9243 |
| Fall A: Einstieg (r 1), direkte Voraussetzungen (r 2), Abschluss über `lsa_abschluss` (r 3); `pflicht = r ≤ 2` | CTE `raum_a` in `lsa_paket_skills_roh` | S:9250–9258, S:9281–9284 |
| Regel je Skill (Texte im Pool, ohne MC, erfüllt, fehlende) | `lsa_skill_bereit_roh(p_skill)`, Regel aus `lsa_regel()` (2 / 1) | S:10620, S:9745 |
| Ampel je Paket: grün = Einstieg und alles bereit, gelb = Einstieg und Pflicht bereit, sonst rot | `lsa_status_roh` | S:10798, S:10820–10822 |
| Vorschläge für Lena (nur Skills ohne erfüllte Regel) | `pruef_ziel_roh()` | S:14998 |
| Liste „Gezielt prüfen“ | `pruef_ziel_liste(p_nur_fokus, p_quartal, p_schuljahr)`, Inner Join auf Pakete | S:14937, `join hebel` S:14977 |
| Admin-Seite | `lsa_abdeckung(p_klasse, p_quartal, p_nur_fokus, p_schuljahr)` | S:7353 |

**Vom Thema zu Paketen, Schulen, Zeitfenster:** Ein Paket trägt `thema_keys`. Alle 501 Pakete der Klassen 8–10 sind
heute geschätzt und haben genau ein Thema (`lsa_paket_cache`: 176 / 176 / 149, 0 bestätigt, 0 mit mehreren Themen).
Schulen = `distinct schule_id` der Pakete eines Themas, Zeitfenster = `quartal` (1–4, aus `lage`) und `datum` der
Pakete (S:9426–9428).

**Fall A ist je Thema überall gleich:** Für alle 22 Themen liefert `lsa_paket_skills_basis` (Fall A) in jedem Paket
dieselbe Skill-Menge mit denselben Teilen (`ergebnisse/u0-themen.txt`, Spalte `varianten` = 1 bei allen 22).
**Vorschlag U1:** Der Themenraum eines Themas wird nicht nachgebaut, sondern aus `lsa_paket_skills_basis` gelesen
(Fall A, Pakete mit genau diesem einen Thema). pgTAP sichert, dass das bei mehreren Paketen eindeutig bleibt.

**Themen in den Plänen der Klassen 8–10** (`schul_themenplan`, Mathematik): **22 verschiedene**, je Klasse 11 / 10 / 8.
Alle 22 haben einen Einstieg (`thema_einstieg`: 48 Zeilen, 25 Themen). Manche Themen liegen in mehreren Klassen
(`aehnlichkeit` Kl. 8/9/10 mit 4/8/17 Schulen, `quadratische_gleichungen` Kl. 9/10 mit 4/19). **Vorschlag:** Ohne
Klassenfilter steht ein Thema einmal da, in der Klasse mit den meisten Schulen. Mit Filter zählen nur die Pakete
dieser Klasse.

**Stand heute je Thema** (Fall A, `ergebnisse/u0-themen.txt`): Kein Thema hat alle Pflicht-Kompetenzen bereit. Am
nächsten sind `flaechen_vielecke` (6 von 6 Pflicht bereit, Tiefe 5 von 9), `lineare_funktionen` (7 / 8),
`terme_binomische_formeln` (7 / 8) und `reelle_zahlen` (6 / 7). Das passt zu MSA-1: alle 501 Pakete rot.

## 2 · MSA

- **Zuordnung:** `docs/msa/anhang/zuordnung.csv` hat 44 Zeilen, davon 3 „nur G9“ und 2 „prozessbezogen“ ohne Skill.
  Die übrigen ergeben **122 verschiedene Skills; alle 122 stehen in `skills`** (`abfragen/q_u0_msa.sql`, Spalte
  `fehlt_in_skills` = 0).
- **Bereiche:** Die Datei kennt 6 Inhaltsbereiche. Für die vier Bereiche der Seite gilt: „Arithmetik“ und „Größen“
  (B6-1) zählen zu „Arithmetik und Algebra“. Ein Skill steht in genau einem Bereich, nämlich dem der ersten
  MSA-Zeile in Dateireihenfolge (betrifft `groessen_volumen`: G8-2 Geometrie vor B6-1 Größen).
- **Stand nach MSA-1** (Prod, 13.11.2026):

| Bereich | Skills | bereit | teilweise | offen | fehlende Texte | nicht in Lenas Liste | Vorschläge dort | ids dort |
|---|---|---|---|---|---|---|---|---|
| Arithmetik und Algebra | 53 | 25 | 7 | 21 | 49 | 8 | 16 | 23 |
| Funktionen | 23 | 4 | 0 | 19 | 38 | 4 | 8 | 12 |
| Geometrie | 40 | 7 | 1 | 32 | 65 | 7 | 14 | 21 |
| Stochastik | 6 | 0 | 1 | 5 | 11 | 1 | 2 | 3 |
| **gesamt** | **122** | **36** | **9** | **77** | **163** | **20** | **40** | **59** |

  Gleich wie MSA-0 §2 (36 / 9 / 77, 163) und MSA-1 Abnahme 2 (20 Skills, 59 Vorschläge außerhalb der Liste).
- **Warum 20 fehlen:** `pruef_ziel_liste` verbindet `pruef_ziel_roh` per Inner Join mit `hebel` (Skills in Paketen,
  S:14958–14977). Die 20 MSA-Skills liegen in keinem Paket der Klassen 8–10 (Bericht MSA-0 §6a).
- **Ausschluss:** `docs/msa/msa1/msa-ausschluss.csv` hat 13 zu schwere und 37 zu leichte Aufgaben. Von den 13 zu
  schweren sind **3 heute im Pool** (`geo_flaeche_drachen_raute` 2, `zahl_wurzel_irrational` 1), 1 archiviert, 9 Entwürfe
  (`fkt_exp_*`, `fkt_sinus_*`). Ohne die 3 Pool-Aufgaben erfüllen zwei Skills die Regel für die MSA nicht mehr. Dann
  braucht Lena für diese Skills Vorschläge, obwohl sie die Regel allgemein erfüllen. `pruef_ziel_roh` schlägt nur für
  Skills ohne erfüllte Regel vor.
  **Vorschlag U1:** `lsa_skill_bereit_roh` und `pruef_ziel_roh` bekommen einen Parameter `p_ohne uuid[] default '{}'`
  (Aufgaben, die nicht als Beleg zählen und nicht vorgeschlagen werden). Ohne Parameter ist die Ausgabe gleich
  (Regressionstest). Beide sind nicht geschützt. Aufrufer laut `pg_proc`: `lsa_paket_skills`, `lsa_skill_bereit`,
  `lsa_status_roh`, `pruef_ziel_roh` bzw. `lsa_paket_skills`, `pruef_ziel_liste`. Sie rufen ohne den neuen Parameter.

## 3 · Session-Reihen

- **Eine Reihe heute** ist nur der Text in `bauformen.reihe` (S:27116; Default und einziger Wert
  `quadratische_funktionen_gleichungen`, 47 Bauformen, alle `zur_pruefung`). Titel und Klasse stehen nur in der
  Textdatei (`src/i18n/locales/de/bauformPruefen.json:362–365`: „Quadratische Funktionen und Gleichungen“, Klasse 9).
  Eine Tabelle der Reihen gibt es nicht.
- **Sessions:** `bauform_plan_standard()` liefert 7 Sessions mit je 2–3 Kernideen (`reihe_kernideen`, 19 Zeilen,
  9 Skills). `bauform_pruef_plan(null)` (S:1473) ordnet jede Bauform einer Session zu: Kernideen-Bauformen über
  `kernidee_key`, Voraussetzungen über die Kante zum Skill der Session. Heute: Session 1–7 mit 5 / 6 / 8 / 7 / 7 / 7 / 7
  Bauformen, keine ohne Session. Laufzeit 68 ms. Der Titel einer Session ist die Folge der Skill-Labels.
- **Geprüft** heißt `zur_freigabe` oder `freigegeben` (`src/lib/pruefung/bauformStand.ts:8`). Status der Bauformen
  laut CHECK: entwurf, zur_pruefung, rueckfrage, beanstandet, zur_freigabe, freigegeben, pausiert.
  **Vorschlag:** offen = entwurf, zur_pruefung, pausiert; Rückfrage = rueckfrage, beanstandet.
- **Themen der Reihe:** über die Kernideen-Bauformen → `skill_thema`: `quadratische_funktionen` (5 Skills) und
  `quadratische_gleichungen` (4). Die Voraussetzungs-Bauformen liegen in vier weiteren Themen (`terme_gleichungen` 3,
  `reelle_zahlen`, `terme_binomische_formeln`, `geometrische_grundbegriffe` je 1); die zählen nicht als Reihe dieser
  Themen.
- **Erklärvideos:** `studio_sequenz` hat je Sequenz einen `skill_key` und einen Status entwurf → vertont → gerendert →
  in_pruefung → freigegeben (S:29175). `freigegeben` setzt nur `studio_veroeffentlichen`, und zwar wenn die
  Skelett-Welt ausgegeben ist (S:23864–23907). Die übrigen Welten sind Varianten (`studio_freigabe.art = 'variante'`).
  **Vorschlag:** „Video freigegeben“ = eine Sequenz des Skills hat Status `freigegeben`; „in Prüfung“ = Status
  `in_pruefung`; sonst „fehlt“ (auch bei Entwurf, vertont, gerendert). Je Session zählen die Skills ihrer Kernideen,
  je Reihe die 9 Skills. Heute gibt es 1 Sequenz (`fkt_quadr_parabel`, Entwurf), also 0 von 9 freigegeben.

## 4 · Themen ohne Reihe

Themen der Pläne 8–10 ohne Kernideen-Bauform einer Reihe: 22 − 2 = **20**. **Vorarbeit, Vorschlag:**

- n Bauformen (aller Reihen), deren Skill im Themenraum (Fall A) liegt → „n Bauformen passen“
- sonst, wenn es freigegebene LSA-Aufgaben (im Pool) zu Skills des Themenraums gibt → „LSA-Aufgaben vorhanden, keine
  Bauformen“
- sonst „keine“

Sortiert nach Zeitfenster (Quartal), dann nach Schulen absteigend.

## 5 · Navigation und Muster

- **LSA-Abdeckung:** Eintrag in `src/components/edvance/admin/adminNav.ts:83` (Gruppe Inhalte), Route
  `src/App.tsx:382`. Die Seite hält Klasse und Quartal nur im Zustand, nicht in der Adresse
  (`src/pages/admin/lsaAbdeckung/LsaAbdeckungPage.tsx:27–29`). Ein Link mit Filter geht also nicht. Die Spalte Wirkung
  verlinkt deshalb ungefiltert.
- **Reiter:** `Reiterleiste` (`src/components/edvance/Reiterleiste.tsx:16`), Reiter in der Adresse wie bei Slots
  (`src/pages/admin/slots/slots.model.ts:12–18`, `?reiter=`).
- **Kopf mit Zurück:** `PageHeader` hat `zurueckZu`/`zurueckLabel` (`src/components/edvance/shell/PageHeader.tsx:23`).
- **Kennzahlen:** `KennzahlenLeiste` (`src/components/edvance/admin/KennzahlenLeiste.tsx`), eine Leiste statt Kacheln
  (Marke). **Tabellen:** `EdvanceTable` (`src/components/edvance/EdvanceTable.tsx:32`), im Admin ab 5 Spalten erlaubt.
- **Lenas Liste:** `/coach/pruefen` ohne `?bereich` = Reiter „Gezielt prüfen“
  (`src/pages/coach/pruefen/PruefenUebersichtPage.tsx:39`, `:138–146`), Inhalt `GezieltPruefen.tsx`, Rechnungen
  `src/lib/pruefung/gezielt.ts`, Aufruf `src/lib/supabase/lsaAbdeckung.ts` (`getPruefZielListe`).
- **Session-Aufgaben prüfen:** `/coach/pruefen/bauformen` (`src/App.tsx:148`), Freigabe je Session dort für Admins.
  **Studio:** `/admin/studio` (`src/App.tsx:373`). **LSA-Freigabe:** Sammelfreigabe auf der LSA-Abdeckung
  (`FreigabeLeiste.tsx`).

## 6 · Laufzeit (Prod, Ausführungszeit auf dem Server)

| Abfrage | Zeit |
|---|---|
| `lsa_paket_skills_basis` live | 690 ms (mit Speicher ≈ 20 ms) |
| `lsa_pakete_basis` live | 370 ms |
| `lsa_skill_bereit_roh(null)` | 110 ms |
| `pruef_ziel_roh()` | 875 ms |
| `pruef_ziel_liste()` | 2 010 ms |
| `bauform_pruef_plan(null)` | 68 ms |

**Befund:** Der Paket-Speicher aus FR-2 frischt sich in Prod nie auf. `lsa_paket_cache_stand` zeigt seit 11.11.
`veraltet = t` und den Fehler „DELETE requires a WHERE clause“. Ursache: Die Rolle `authenticator` lädt `safeupdate`
(`pg_roles.rolconfig`). `lsa_paket_cache_auffrischen` löscht mit `delete from public.lsa_paket_cache` ohne WHERE
(S:9135). Deshalb rechnen alle FR-2-Funktionen live.

**Ohne Abhilfe** bräuchte der Reiter Lernstandsanalyse rund 2–3 s: Pakete live, `pruef_ziel_roh` einmal für die Themen
und einmal mit Ausschluss für die MSA. Der Reiter Session-Reihen läge unter 0,2 s.

**Vorschlag U1:**

1. `lsa_paket_cache_auffrischen`: `delete … where true`. Das ist keine geschützte Funktion; Aufrufer laut `pg_proc`:
   `lsa_abdeckung_auffrischen`. Damit wird der FR-2-Speicher wieder frisch.
2. Zwischenspeicher je Skill und Prüfziel wie in FR-2: `inhalte_skill_cache` mit Stand-Zeile. Anweisungs-Trigger
   auf `tasks`, `task_solutions`, `task_pruefungen`, `session_einstellungen` und den Prüfziel-Tabellen setzen
   `veraltet`. `inhalte_auffrischen()` (Admins) rechnet beim Laden der Seite neu, wenn nötig. Die lesenden Funktionen
   nehmen den Speicher, wenn er frisch ist, sonst rechnen sie live.
