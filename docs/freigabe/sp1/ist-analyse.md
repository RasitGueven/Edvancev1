# SP-1 · S0 Ist-Analyse

Stand 11.11.2026, origin/dev `77098887`. Zeilen in `supabase/schema-erwartet.sql` (kurz `SE`) und im Code auf diesem
Stand. Prod-Abfragen per `dbread` (read-only), Ausgabe gekürzt.

## 1 · Seiten, Komponenten, Datenzugriffe

| Teil | Datei | Daten |
|---|---|---|
| Liste „Session-Muster prüfen“ (M1) | `src/pages/coach/pruefen/bauformen/BauformListePage.tsx` (130 Z.), Route `src/App.tsx:147` | `getBauformPlan` → `bauform_pruef_plan` (SE:1369), `getPlanKinder` → `bauform_plan_kinder`, `getAuffaellig`, `getPrueffragen`; Admin: `bauformFreigeben` → `bauform_freigeben` (SE:1149) |
| Session-Gruppe | `src/components/edvance/pruefen/bauform/MusterSessionGruppe.tsx` | Karte je Bauform: Schlüssel groß, `kernidee_titel` bzw. „Voraussetzung: Skill“, Format-Schlüssel roh (`b.format`, Z. 81), Version, „n grün“; „Session n freigeben“ nur `isAdmin` (Z. 58) |
| Gruppierung, Filter | `src/lib/pruefung/bauformPlan.ts`, `bauformStand.ts` | Filter `alle, zur_pruefung, rueckfrage, zur_freigabe, freigegeben`; „geprüft“ = zur_freigabe ∪ freigegeben |
| Prüfansicht (A5) | `src/pages/coach/pruefen/bauformen/BauformDetailPage.tsx` (83 Z.), Route `src/App.tsx:155` | `getBauformDetail(id, seed)` → `bauform_pruef_detail` (SE:1283); `bauformPruefen` → `bauform_pruefen` (SE:1429) |
| Steckbrief, Befund | `.../bauform/BauformSteckbrief.tsx` | zeigt `steckbrief.text` mit `{platzhalter}` roh, Rollen als Schlüssel (`warmup, uebung, home`), Stufen als Generator-Regel, Fehlbild-Schlüssel `qf_…` in Monospace (Z. 49) |
| Beispiel | `.../bauform/BauformBeispiel.tsx` | `PreviewStage` (wie im Player), Lösung, Fehlbilder nur der neuen Formate (`loesung.fehlbilder`, Schlüssel roh), Hinweise, Lösungsweg; Rolle roh (`detail.rolle`) |
| Entscheidung | `.../bauform/BauformEntscheidung.tsx` | passt / unsicher / passt nicht, Gründe, Notiz |
| Lib | `src/lib/supabase/bauformPruefung.ts` | alle RPCs über `rufe()` mit try/catch; Typen `src/types/bauformPruefung.ts` |
| Texte | `src/i18n/locales/de/bauformPruefen.json` (145 Z.) | `liste.titel` = „Session-Muster prüfen“ |

## 2 · Tabelle `bauformen` und Steckbrief

`bauformen` (SE:26575): `schluessel, reihe, skill_key, kernidee_key, format, rollen text[], steckbrief jsonb, version,
status, pruefprotokoll, blindloeser, verdacht, freigegeben_am/_von`. **Kein Titelfeld.** Der Titel in der Liste ist
heute `reihe_kernideen.titel` (Kern) bzw. `skills.label` (Voraussetzung):

```
PAR-2|fkt_quadr_parabel:K2|Streckfaktor a: enger, weiter, nach unten geöffnet
PAR-5|fkt_quadr_parabel:K2|Streckfaktor a: enger, weiter, nach unten geöffnet     ← gleich
NF-2/4/5/6 → alle „Quadratische Ergänzung mit a = 1“; EX-0..3 → alle gleich; DI-1..3 → alle gleich
```

Steckbrief (alle 47 gleich gebaut, dbread `jsonb_object_keys`): `text, stufen, fehlbilder, hinweise, loesungsweg, warum,
kontext, figur, zeit_sek, kann_entfallen, generator_hash`. Beispiel EIN-1:

```
"text": "Berechne f({x0}) für f(x) = {term}."
"stufen": {"1": "f(x) = x² + b·x + c, x von 1 bis 6 (ohne 2)", "2": "a = 1, x von −1 bis −6 (ohne −2)",
           "3": "a ∈ {−3, −2, 2, 3}, x von −1 bis −5 (ohne −2)"}
"zeit_sek": 60
"fehlbilder": [{"key": "qf_quadrat_als_verdopplung", "regel": "x² als 2·x gerechnet",
                "rueckmeldung": "x² heißt x mal x, nicht 2 mal x.", "gilt_fuer_stufen": [1,2,3]}, …]
```

- **Text:** Platzhalter in `{…}`, Namen generatorintern (`{x0}`, `{term}`); keine Zuordnung Platzhalter → Wort.
- **Stufen:** ein Text je Stufe (`object`), in Generator-Sprache (Mengenschreibweise, Ausschlüsse „ohne 2“). Kein Beispiel.
- **Rollen:** `bauformen.rollen` (SE:26575, CHECK `bauformen_rollen_check`), je Instanz `tasks.rolle`.
- **Zeit:** **ein Wert je Bauform** (`steckbrief.zeit_sek`), beim Export je Instanz in `tasks.est_duration_sec`
  kopiert (`scripts/bauformen/export.py:308`). Nicht je Rolle, nicht je Stufe. Werte 30–300 s (dbread).
- **Fehlbilder:** `key, regel, rueckmeldung, gilt_fuer_stufen` – alles da.
- **Klartext-Namen:** `fehlbild_labels.klartext` gibt es für alle 50 Schlüssel der Bauformen (dbread: 50 von 50), aber
  als Satz („Rechnet (a·x)² statt a·x²: auch a wird quadriert.“), nicht als kurzer Name wie „Zahl vor x² mitquadriert“.
  Ein kurzer Name fehlt → S2.3 (Textdatei).
- **Achtung Versionierung:** Jede Änderung an `steckbrief` erhöht die Version (Trigger, Abschnitt 4). Klartext und Zeit
  dürfen deshalb **nicht** in `steckbrief` stehen.

## 3 · Prüfentscheidungen (`bauform_pruefungen`)

Tabelle SE:26543: `id, bauform_id, version, entscheidung (passt|unsicher|passt_nicht|zurueckgenommen|reaktiviert),
gruende text[], notiz, dauer_sek, geprueft_von, geprueft_am`; Trigger `bauform_pruefungen_nur_anhaengen` (append-only);
RLS lesen `darf_pruefen()`, schreiben nur über SECURITY-DEFINER-Funktionen. Gründe ohne Katalog (freie `text[]`).
Repo-Muster für Grundlisten: Funktion, die `text[]` liefert, geprüft mit `gruende <@ …` (`pruef_admin_gruende`, SE:12574).

`bauform_pruefen` (SE:1429): `passt` → `zur_freigabe`; `unsicher` (Notiz Pflicht) → `rueckfrage`; `passt_nicht`
(Grund Pflicht) → `beanstandet`. Erlaubt nur bei Status `zur_pruefung` **oder** `rueckfrage`, gleicher Version, kein
Verdacht, Prüfmaschine ≤ 30 % rot und Blindlöser bestanden.

**Wer arbeitet eine Rückfrage ab?** Niemand per Funktion. Es gibt keinen Antwortweg (anders als bei Einzelaufgaben,
`task_pruefungen.antwort`, SE:13918). Eine Bauform in `rueckfrage` bleibt für Lena entscheidbar (SE:1447) und sperrt
„Session n freigeben“ (`bauformPlan.ts:46`). In der Praxis endet sie erst, wenn ein Export die Bauform ändert: dann
setzt der Trigger sie auf `zur_pruefung` (Abschnitt 4), und Lena prüft erneut.

Prod: `select count(*) from bauform_pruefungen` → **0**; `status` → **47 × zur_pruefung**.

## 4 · Versionswechsel

Einzige Stelle: Trigger `bauformen_versionswechsel` BEFORE UPDATE → `bauform_versionswechsel()` (SE:1550).
Ändert sich `(steckbrief, format, rollen, skill_key, kernidee_key)`:
- alte Fassung nach `bauform_versionen`, `version + 1`, Freigabe gelöscht;
- **ohne** Export-Flag: Protokoll/Blindlöser/Verdacht leer, Status → `zur_pruefung` (außer `entwurf`);
- **mit** `edvance.bauform_export = '1'` (Datenmigration aus `export.py:282`): Status
  `zur_freigabe | freigegeben | pausiert | beanstandet | rueckfrage` → `zur_pruefung` (bzw. `entwurf` bei Verdacht).

pg_proc-Scan (Funktionen, die `bauformen` schreiben oder das Flag nutzen):

```
dbread: prosrc ~* 'update public.bauformen|insert into public.bauformen|bauform_export|bauform_versionswechsel'
aufgabe_melden | bauform_freigeben | bauform_pruefen | bauform_reaktivieren | bauform_versionswechsel | bauform_zur_ueberarbeitung
```

Keine dieser Funktionen ändert Steckbrief/Format/Rollen/Skill/Kernidee; sie setzen nur `status` bzw. Freigabe. Ein
Versionswechsel entsteht also ausschließlich durch die Export-Migrationen (`tools/bauform.sh` → `export.py`, Upsert
`on conflict (schluessel) do update`, Z. 283–296). Der Upsert setzt `status` selbst nicht zurück (Z. 293–296), das tut
nur der Trigger. → Für S1.5 genügt eine Änderung im Trigger.

## 5 · Falsche Antworten je Instanz

Gespeichert, nicht nur als Regel (dbread, je eine Instanz):

| Bauform (Format) | Ort | Inhalt |
|---|---|---|
| EIN-1 (zahl) | `task_solutions.acceptance.known_errors` | `{"-78": "qf_quadrat_als_verdopplung", "177": "qf_ax_quadriert", "-123": "qf_einsetzen_vorzeichen", "−78": …}` (Varianten mit Unicode-Minus) |
| PAR-5 (mc) | `acceptance.known_errors` | `{"b": "qf_oeffnung_vertauscht", "d": "qf_streckfaktor_umgekehrt"}` |
| NP-2 (loesungsmenge) | `correct_answers[0].fehlbilder` | `[{"key": "qf_null_vergessen", "menge": ["11/6"]}, …]` |
| KO-1 (feldmaske) | `correct_answers[0].fehlbilder` | `[{"key": "qf_scheitel_koordinaten_vertauscht", "werte": {"x": "-3", "y": "-1"}}, …]` |
| PAR-2 (graph_auswahl) | `correct_answers[0].fehlbilder` | `[{"key": "qf_streckfaktor_umgekehrt", "option": "a"}, …]` |

`bauform_pruef_detail` liefert beides schon (`loesung` = `correct_answers -> 0`, `known_errors`). Die heutige Ansicht
zeigt `known_errors` aber nicht an (`BauformBeispiel.tsx` liest nur `loesung.fehlbilder`). Nichts muss im Browser
nachgerechnet werden. Bei `known_errors` gibt es je Fehlbild mehrere Schreibweisen (ASCII- und Unicode-Minus): die
Ansicht nimmt je Schlüssel eine.

## 6 · Bearbeitungszeit in der Session-Planung

**Die Session-Planung liest keine Aufgabenzeit.** `est_duration_sec` lesen nur (SE-Scan): LSA „fest“ (SE:10319), Quests
(SE:14739), LSA-Liste (SE:15084). Die Reihenplanung (`reihe_planen`, SE:15783) rechnet mit Minuten je **Kernidee** aus
Stellschrauben (`reihe_wert('reihe_kapazitaet_min')`, neu 12 / gesehen 6, Konzept §2.3), die Session-Schritte
(`session_plan_kern`, `session_plan_warmup`, SE:17694–18150) ziehen Aufgaben ohne Zeitbudget. Im Frontend kommt die Zeit
nur im Autoren-Editor vor. → Befund in `offen.md` (Annahme des Auftrags „die Stelle aus S0.6 liest künftig die Zeit der
Stufe“ hat heute keinen Leser).

## 7 · „Andere Beispiele“

`bauform_pruef_detail(p_bauform, p_seed)` (SE:1283): Kandidaten = grüne Instanzen der aktuellen Version mit Lösungszeile;
erst je Stufe eine (`row_number() over (partition by stufe order by md5(seed||id))`), dann auffüllen, `limit 6`. Ein
neuer `p_seed` (`BauformDetailPage.tsx:68`, `setSeed(s+1)`) tauscht **alle sechs**. „Diese Instanz behalten“ ist heute
nicht ausdrückbar. Möglich: zusätzlicher Parameter `p_behalten uuid[]`, die Funktion setzt diese zuerst und füllt den
Rest; wegen Überladung die Funktion ersetzen (drop + create), nicht daneben stellen.

## Folgerungen für S1

- Klartext und Zeit je Stufe in **eigener Tabelle** `bauform_stufen` (kein Versionswechsel), Titel als eigene Spalte
  außerhalb von `steckbrief`.
- Gründe je Anker über eine Funktion `bauform_kommentar_gruende(anker) → text[]` (Repo-Muster) und CHECK.
- `bauform_pruefen` bleibt, ein neuer Aufruf mit Kommentaren ruft sie auf (Rückfrage über `unsicher` mit Notiz).
- Versionswechsel: nur im Trigger eine Ausnahme für Bauformen in Überarbeitung einer Rückfrage mit Kommentaren.
- Zeit: lesbar über eine Funktion je Instanz; ein Leser in der Planung fehlt (offen).
