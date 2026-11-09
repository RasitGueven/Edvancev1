# FR-2 · F0 Ist-Analyse

**Stand:** 09.11.2026, Code auf `origin/dev` @ `c6fdf998` (nach Merge von #378), Prod nur lesend per `dbread`.
Schema-Stellen beziehen sich auf `supabase/schema-erwartet.sql` (Abzug von Prod). Zahlen aus dem Bericht:
`docs/freigabe/bestandsaufnahme.md` (FR-0).

---

## 1 · `lsa_select_next_core`: Themenraum (Fall A) und Vorschau-Rand (Fall B)

**Fall A, Thema der Sitzung** (`schema-erwartet.sql:9075–9088`):

- `v_mit_thema` (`:9075`): Das Thema hat Einstiegsknoten (`thema_einstieg`), und mindestens einer hat eine Aufgabe im
  Pool. Ohne das läuft die Auswahl „ohne Thema“.
- `v_einstieg` = `thema_einstieg` des Themas, `v_themenraum` = Einstieg ∪ `lsa_abschluss(Einstieg)` (`:9082`).
  `lsa_abschluss` (`:6953`) ist die volle transitive Hülle über `skill_kante`, ohne Tiefen- und Klassengrenze.
- **Direkt aufrufbar:** `lsa_abschluss(skill)`. Die Paket-Funktion ruft sie auf. Die Aufteilung in „direkte
  Voraussetzung“ (eine Kante) und „Tiefe“ kennt der Code nicht, sie kommt aus dem Auftrag (Pflicht vs. Tiefe).
  Eine Kante = `skill_kante.skill_key = Einstieg`.

**Fall B, Vorschau** (`ka_modus = 'vorschau_zuerst'`, Arbeit geschrieben):

| Schritt | Stelle | Inhalt |
|---|---|---|
| kommende Themen | `:9135–9141`, `c_vorschau_themen = 3` (`:8971`) | die nächsten 3 Plan-Themen nach der Position des Kindes |
| später | `:9142–9145` | alle Themen der Klasse ab der Position und alle der Klasse + 1 (dazu Auffüllen aus Klasse + 1, `:9178–9208`) |
| Rand | `:9215–9241` (rekursives CTE `r`, `rand`) | Voraussetzungen von `skill_thema`-Skills der kommenden Themen, die nicht zum Thema gehören. Gehört eine zu einem späteren Thema, tritt ihr Rand an ihre Stelle. Skills kommender oder späterer Themen nie. |
| Rand-Tiefe | `:9243–9252` | `lsa_abschluss(Rand)` ohne Rand und ohne Skills kommender oder späterer Themen |
| Klassengrenze | `:9404` | Rand und Rand-Tiefe werden nur mit `klasse_herkunft ≤ Klasse` gezogen |

- **Nicht direkt aufrufbar:** Der Rand steht inline in `lsa_select_next_core` als lokale Arrays (`v_rand_sk`,
  `v_tief_sk`). Es gibt keine Teilfunktion. `lsa_select_next_core` darf laut Auftrag nicht geändert werden, also
  nicht zerlegt werden. Die Paket-Funktion muss den Rand deshalb **nachbauen**: dasselbe CTE, mit „kommend =
  Themen der Arbeit“ statt der nächsten drei Plan-Themen. Bei der Rand-Tiefe ruft sie `lsa_abschluss` auf.
- **Drift-Risiko:** Ändert jemand später die Rand-Logik in `lsa_select_next_core`, weicht das Paket ab. Abhilfe in
  F1: Der Kommentar der neuen Funktion nennt die Stellen. Ein pgTAP-Fall prüft den Rand an einem kleinen Graphen mit
  dem bekannten Ergebnis. Ein gemeinsamer Aufruf ginge nur mit einer Änderung an `lsa_select_next_core` (offen.md, O1).
- **Abweichung zum Bericht A4 (kein Widerspruch zum Auftrag):** Der Bericht hat Fall B als „Hülle aller
  `skill_thema`-Skills ohne spätere Themen“ angenähert. Die Funktion nimmt jetzt den Rand wie der Code. Die Zahlen in
  F1 können deshalb leicht vom Bericht abweichen. Der Regressionstest in F1 erklärt die Unterschiede.

**Bestätigte Folge:** `lsa_select_next_core` liest `schul_klassenarbeiten` **nicht**. Die Position kommt nur aus
`schul_themenplan` (`:9124–9134`). Die Pakete nehmen eine bestätigte Folge wie im Auftrag. Die LSA-Auswahl selbst
bleibt davon unberührt (Auftrag: LSA-Auswahl unverändert).

## 2 · Klassenarbeiten: Tabellen, Funktionen, Admin-Seite

| Objekt | Stelle | Inhalt | Rechte |
|---|---|---|---|
| `schul_klassenarbeiten` | `:26894` | bestätigte Folge je Schule × Fach × Klasse × Schuljahr × `nr`, `thema_keys[]`, `datum`, `bestaetigt`, `bestaetigt_von` | RLS: nur Admin, alles (`:35459`) |
| `lead_klassenarbeiten` | `:26236` | Angaben je Kind (Erstgespräch, Check-in, Admin) | – |
| `ka_folge_schule_roh` | `:5735` | Folge je Schule und Klasse: bestätigte Zeilen, dazu abgeleitete aus Kinderangaben (ab 2 übereinstimmenden Kindern) | intern |
| `ka_folge_schule` | `:5718` | dieselbe Folge, Admin-Prüfung | nur Admin |
| `ka_folge_uebersicht` | `:5788` | Gruppen Schule × Klasse **mit Kinderangaben** | nur Admin |
| Trigger `ka_themen_pruefen` | `:31442` | prüft `thema_keys` gegen `themen` | – |

Prod heute: `schul_klassenarbeiten` leer, `lead_klassenarbeiten` 3 Zeilen von 3 Leads (Bericht Q40).

**Admin-Seite** `src/pages/admin/klassenarbeiten/KlassenarbeitenPage.tsx`:

- Links Gruppen aus `ka_folge_uebersicht` (`src/lib/supabase/kaFolge.ts:105`), rechts die Folge aus
  `ka_folge_schule` (`kaFolge.ts:135`). Je Arbeit eine Karte `KaArbeitKarte` mit „Bestätigen“ oder „Korrigieren“
  (Nr. 1–8, Themen aus dem Schulplan, Datum).
- Geschrieben wird über `bestaetigeKaSchulArbeit` (`kaFolge.ts:165`): `upsert` in `schul_klassenarbeiten` mit
  `bestaetigt = true`, `bestaetigt_von`. Bei geänderter Nummer wird die alte Zeile gelöscht. Erlaubt ist das nur
  Admins (RLS).

**Was für die Folge einer Fokus-Schule fehlt:**

1. Die Seite zeigt nur Schulen × Klassen, für die **Kinder** Angaben gemacht haben (`ka_folge_uebersicht`). Eine
   Fokus-Schule ohne Leads erscheint dort nicht.
2. Sie zeigt nur Arbeiten, die es schon gibt (abgeleitet oder bestätigt). Eine neue Arbeit anlegen kann man dort
   nicht.
3. Zum Löschen einer bestätigten Arbeit gibt es keinen Knopf.

**Folgerung für F2.5:** Ein schlichtes Formular auf der neuen Seite „LSA-Abdeckung“ (je Fokus-Schule und Klasse:
Nr., Themen aus dem Schulplan, Datum). Es schreibt über die bestehende Lib-Funktion `bestaetigeKaSchulArbeit` und
liest über `ka_folge_schule`. Es braucht keine neue Schreibfunktion und keine Migration. Die RLS verlangt Admin. Die
L5-Seite bleibt unverändert.

## 3 · Prüf-Board, Soll, Entscheidung, Freigabe

| Funktion | Stelle | Rolle | Wesentliches |
|---|---|---|---|
| `pruef_board()` | `:12491` | `darf_pruefen` | alle Aufgaben mit `pruef_ausschluss(id) is null` (`:12506`), `lena_status` aus dem Status, Anlässe aus `pruef_soll` |
| `pruef_board_soll(anlass)` | `:12535` | `darf_pruefen` | Soll je Skill aus `pruef_soll` (soll, min_ohne_mc), gezählt sind Lenas „passt“ und „freigegeben“ |
| `pruef_soll` | `:26622` | – | Anlass je Skill (`batu_lsa`, `lsa_vorschau`, `batu_session`), soll 2, min_ohne_mc 1 |
| `pruef_entscheiden` | `:12607` | `darf_pruefen` | passt → `review`, unsicher → `rueckfrage`, passt nicht → `beanstandet`. Setzt nie `ready`. |
| `pruef_freigabe_erlaubt` | `:12954` | – | letzte Entscheidung „passt“ ohne Änderungen, keine Admin-Beanstandung, Fassung unverändert |
| `pruef_sammel(aktion, ids, werte, nur_vorschau)` | `:13434` | **nur Admin** (`pruef_nur_admin`) | je Aufgabe `pruef_sammel_grund` (`:13496`): für `freigeben` nur `review` mit Lenas „passt“, `pruef_freigabe_erlaubt` **und** `freigabe_gate_fehler` null, dann `task_status_set` |
| `task_status_set` | `:23376` | Admin oder System | einziger Weg zu `ready` für Einzelaufgaben, mit Gate |

**Antwort auf die Frage aus dem Auftrag:** `pruef_sammel('freigeben', ids, '{}', false)` reicht für die
Sammelfreigabe. Die Funktion prüft je Aufgabe Lenas „passt“, `pruef_freigabe_erlaubt` und das Gate
(`freigabe_gate_fehler`) und gibt `{betrifft, ausgelassen[{task_id, grund}]}` zurück. Lena ist `coach`, nicht
`admin`, und wird von `pruef_nur_admin` abgewiesen. Mit `p_nur_vorschau = true` zeigt derselbe Aufruf vorher, was er
freigäbe (für den Zähler „Alles Geprüfte freigeben (n)“). Der Weg ist in `src/lib/supabase/pruefungAdmin.ts:78`
schon angebunden. **Kein neuer Weg zu ready.**

**Wo sich die gezielte Liste anhängt:**

- **Daten:** eine neue lesende Funktion `pruef_ziel_liste`, Rechte wie `pruef_board` (`darf_pruefen`). Sie schlägt
  nur Aufgaben vor, die im Board stehen (`pruef_ausschluss is null`). Sonst könnte Lena sie in der Prüfansicht nicht
  öffnen.
- **Oberfläche:** `PruefenUebersichtPage.tsx` hat die Bereiche `?bereich=lsa|session` (`bereich.ts:8–12`). Der neue
  Reiter „Gezielt prüfen“ kommt als erster Bereich `gezielt` dazu, der Standard ohne Parameter wird `gezielt`. Die
  bisherigen Bereiche bleiben unverändert.
- **Sprung nach der Entscheidung:** `PruefansichtPage.tsx:111–117` wählt die nächste Aufgabe über `naechsteNoetige`
  im Bereich. Für `bereich=gezielt` nimmt sie stattdessen die nächste noch offene Aufgabe der Zielliste. Das ist der
  kleinste Eingriff: ein Zweig im Weiter-Rechner, die Entscheidung selbst bleibt `pruef_entscheiden`.
- **Kein neuer `pruef_soll`-Anlass nötig:** Das Soll je Skill rechnet `pruef_ziel_liste` aus der Regel
  (Stellschrauben, Abschnitt 4) und dem Pool. Ein Anlass je Paket würde Daten doppeln, die sich bei jeder Freigabe
  ändern.

## 4 · Admin-Hülle und Stellschrauben

- **Navigation:** `src/components/edvance/admin/adminNav.ts:101–122`, Gruppe `inhalte` (Item-Pflege, Studio). Neuer
  Eintrag `lsaAbdeckung` → `/admin/lsa-abdeckung` nach „Item-Pflege“. Die Route steht in `src/App.tsx` neben
  `/admin/stellschrauben` (`App.tsx:379`), mit `ProtectedRoute allowedRoles={['admin']}`.
- **Seitenmuster:** `PageHeader` + `EdvanceCard`, im Admin `EdvanceTable` für mehr als 4 Spalten (CLAUDE.md §11),
  `LoadingPulse`, `EmptyState`, `ToastBanner`. Texte im Namespace `admin`.
- **Stellschrauben:** Tabelle `session_einstellungen` (Schlüssel, Beschreibung, Typ `zahl`, Wert, Startwert,
  min/max, Einheit). Ändern nur per `einstellung_setzen` (Admin, mit Grund, Protokoll), Seite
  `src/pages/admin/stellschrauben/StellschraubenPage.tsx`. Lesen darf jeder (`session_einstellungen_lesen`, true).
  **Für FR-2:** zwei neue Zeilen `lsa_regel_texte` (Start 2, Spanne 1–4, `anzahl`) und `lsa_regel_ohne_mc` (Start 1,
  Spanne 0–2, `anzahl`). Sie erscheinen ohne Codeänderung auf der Stellschrauben-Seite. Alle FR-2-Funktionen lesen
  sie an einer Stelle (`lsa_regel()`).

## 5 · „Entwurf mit gültiger Lösung“ und „neuer Textschlüssel“

- **Gültige Lösung** (wie Bericht Q25, alle Bedingungen von `lsa_im_pool` außer dem Status): aktiv, kein Tutorial,
  `content_type = 'exercise'`, `lsa_has_answers` und `lsa_eingabeformat_eindeutig`. Für die Prüfliste kommt
  `pruef_ausschluss(id) is null` dazu, damit die Aufgabe in Lenas Board steht. Prod heute: 716 von 717 LSA-Entwürfen
  sind nicht ausgeschlossen (1 × `gate`), 684 davon haben ein eindeutiges Eingabeformat (dbread, unten).
- **Neuer Textschlüssel:** `coalesce(lsa_text_schluessel(question, parts), id::text)` liegt nicht unter den
  Schlüsseln der Pool-Aufgaben des Skills (`lsa_im_pool(id, false)`). Ein leerer Schlüssel zählt wie im Code als
  eigener Text (`:7926`: `coalesce(… = any(…), false)`). Je neuem Schlüssel genau ein Vorschlag.
- **Nachprüfen (Q04):** ready-Aufgaben im LSA-Pool, deren letzte Entscheidung in `task_pruefungen` nicht „passt“ ist
  oder fehlt: **32** (dbread, unten). Das stimmt mit Q04 überein (168 − 136).

```
ready_lsa | ohne_passt_jemals | letzte_nicht_passt        grund    | status     | count
      168 |                31 |                 32       (keiner) | draft      |   716
                                                          gate     | draft      |     1
eindeutig | alle                                          (keiner) | rueckfrage |     2
      684 |  716
```

## 6 · Laufzeit

| Messung (dbread, Prod) | Zeit |
|---|---|
| Bericht-Abfrage Q12 über alle 501 Pakete (`basis.sql` + `paket.sql`) | **35,6 s** |
| `lsa_im_pool` über alle 887 LSA-Aufgaben | 0,17 s |
| `lsa_abschluss` für alle Einstiege bzw. alle `skill_thema` | 0,02 / 0,04 s |
| **Prototyp F1** (`docs/freigabe/fr2/f0-prototyp.sql`, mengenbasiert, alle Klassen, Rand wie Code): 501 Pakete Kl. 8–10, Ampel | **1,45 s** |
| `pruef_ausschluss` über 719 LSA-Entwürfe | 1,6 s |

Die 35 s kamen aus der Abfrageform des Berichts (Teilabfrage je Paket über `spaeter`), nicht aus den Bausteinen. Der
mengenbasierte Prototyp kommt auf 1,45 s für alle Pakete. Das Ziel < 1 s je Filter ist damit knapp verfehlt.

**Vorschlag Zwischenspeicher** (umgesetzt in F1, wenn die Messung der fertigen Funktionen über 1 s bleibt):
Tabelle `lsa_abdeckung_cache` (Schule, Klasse, Paket, Ampel, Zähler, Skills als jsonb, `berechnet_am`). Neu
berechnet wird sie von `lsa_abdeckung_auffrischen()`. Statement-Trigger stoßen die Neuberechnung an, und zwar auf
`tasks` (Status, Einsatz, Text, Skill), `task_solutions`, `schul_themenplan`, `schul_klassenarbeiten`,
`thema_einstieg`, `skill_kante`, `skill_thema` und `session_einstellungen`. Die Trigger setzen nur ein Flag „veraltet“, die
Übersicht rechnet beim nächsten Lesen neu (einmal 1,5 s, danach Tabelle). So bleibt jeder Schreibweg so schnell wie
vorher.

## 7 · Zielprüfung beim Einspielen

- Prod-Projekt-Ref: **`ztcppihxqcphlqaguhma`** (aus `.env`, `VITE_SUPABASE_URL` und `DATABASE_URL` enthalten sie,
  geprüft per `grep -c`, Wert nicht ausgegeben). `supabase/config.toml` trägt nur `project_id = "Edvancev1"`
  (lokaler Name).
- Zielprüfung im Einspiel-Skript: `psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres` und
  `grep -q ztcppihxqcphlqaguhma <<<"$DATABASE_URL"`.
- `~/bin/mig V N` macht DB-Check, Versionsprüfung, eine Transaktion und den History-Eintrag (`set -e`). Die
  Einspiel-Skripte unter `~/einspielen/` verketten Zielprüfung && Vorbedingungen per dbread && `mig` &&
  `tools/schema-snapshot.sh`.

## 8 · Weitere Feststellungen für die Leitplanken

- **Types:** `src/types/*.ts` sind in Edvancev1 handgeschrieben, einen Generator gibt es nicht
  (`docs/reihe1/A/fortschritt.md:39`). „Types neu generieren“ heißt hier: die handgeschriebenen Typen für die neuen
  Funktionen ergänzen. Der Generator `supabase gen types` gilt nur für edvance-app.
- **pgTAP:** CI (`.github/workflows/schema.yml`, Job `neuaufbau`) baut alle Migrationen in eine leere Datenbank,
  vergleicht mit `schema-erwartet.sql` und führt `supabase/tests/*.test.sql` aus (pgTAP, `seed.sql` geladen). Nur
  dort laufen schreibende Tests. Lokal geht es vorab in einer Wegwerf-DB im eigenen Cluster, nie gegen Prod und nie
  gegen die alte Shadow-DB.
- **Rechte:** Die neuen Lesefunktionen prüfen `darf_pruefen()`. Das ist wahr für Admin und für Coaches mit
  `darf_pruefen`, Kinder und Eltern sind ausgeschlossen. Sie sind `security definer`, weil `lsa_im_pool` und
  `task_solutions` sonst an RLS hängen. Prod: 2 Coaches mit `darf_pruefen` haben je geprüft.
- **Keine Änderung an den fünf gesperrten Funktionen** nötig: Alles läuft über neue Funktionen
  (`lsa_select_next_core`, `lsa_freie_aufgabe`, `lsa_im_pool`, `pruef_entscheiden`, `task_status_set` bleiben
  unberührt).

## 9 · Auslegungen (für den Bericht)

- **Gelb verlangt Einstiegsknoten.** Ziel 1 sagt „Einstieg und direkte Voraussetzungen abgedeckt“. Ohne
  `thema_einstieg` gibt es in Fall A keine Pflicht-Skills, und die Thema-LSA startet nicht (`v_mit_thema`). Ein
  solches Paket ist deshalb Rot (mit `hat_einstieg = false`), nicht Gelb.
- **Mehrere Themen je Arbeit:** Fall A nimmt die Vereinigung der Themenräume, Fall B die Themen der Arbeit als
  „kommend“. „Hat Einstieg“ verlangt Einstiegsknoten für jedes Thema der Arbeit.
- **Später-Menge der Klasse + 1:** Schulplan der Klasse + 1, ohne Plan die Kernlehrplan-Folge
  (`lsa_klp_themen`). Das ist wie `:9142` bzw. `:9188–9207`, ohne das Auffüllen auf drei Themen.
