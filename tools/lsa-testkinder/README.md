# LSA-Testkinder (LSA-T)

Acht erfundene Kinder (Klasse 7, 8, 9) spielen je eine vollständige LSA durch die echte Auswahl und
Wertung, mit festem Antwortprofil von „macht nichts falsch“ bis „sehr, sehr schwach“, dazu ein Kind, das sich
durchklickt. Danach liegt für jedes
Kind ein Report unter `/admin/report/<sitzung>?fassung=r7`. Bauaufträge: `docs/lsa/Bauauftrag-LSA-T.md`,
`docs/lsa/Bauauftrag-LSA-T2.md` (Max, Schalter `nur`), `docs/lsa/Bauauftrag-LSA-R2.md` (Tim),
`docs/lsa/Bauauftrag-L2.md` (Batu).

| Kind | Klasse | Schule | Thema | Profil |
| --- | --- | --- | --- | --- |
| Lina Berger | 9 Gymnasium | FWG (Schulplan) | Quadratische Funktionen | alles sicher, ein Ausrutscher (Fläche Dreieck); im Ausblick nur Kreise sicher, Potenzen und Pythagoras nicht |
| Emre Kaya | 9 Gymnasium | FWG (Schulplan) | Reelle Zahlen und Wurzeln | sicher bis auf Wurzelgesetze und teilweises Wurzelziehen, Fehlbild „Wurzel einer Summe“ |
| Sophie Wagner | 8 Realschule | ohne Plan | Lineare Funktionen | Klasse 7/8 falsch (Steigung vertauscht), Koordinaten unsicher, bis Klasse 6 sicher |
| Jonas Richter | 8 Gesamtschule | ohne Plan | Terme und Gleichungen | Klasse 7–10 „Weiß ich nicht“, bis Klasse 6 falsch (Vorzeichen) |
| Nele Schmitz | 7 Gymnasium | ohne Plan | Prozent- und Zinsrechnung | Prozentwert sicher, Grundwert und Prozentsatz falsch, Brüche teils |
| Max Hoffmann | 8 Gymnasium | FWG (Schulplan) | Lineare Funktionen | nichts falsch: jede Aufgabe kanonisch richtig, auch Vorschau, Rückblick, Zweitbeleg; im Ausblick nur Binomische Formeln sicher, Zufall und Flächen nicht |
| Tim Schuster | 8 Gesamtschule | ohne Plan | Terme und Gleichungen | klickt sich durch: 2–4 s je Aufgabe, fast alles falsch, ohne feste Grenze: höchstens 40 Aufgaben (Deckel, LSA-V2); seine LSA ist **nicht auswertbar** |
| Batu (Testkind) | 9 Gymnasium | FWG (Schulplan) | Reelle Zahlen und Wurzeln, Klassenarbeit geschrieben | Profil aus einem echten Testlauf: bis Klasse 6 sicher außer Flächeneinheiten; Klasse 7/8 Terme und Zufall Übung, Geometrie gemischt; Klasse 9 sicher außer teilweises Wurzelziehen |

Die Profile stehen als Daten in `kinder.sql` (`grund` je Klassenstufe, `ausnahmen` je Skill,
bevorzugtes Fehlbild, Antwortdauer, optional `hoechstens` = Zahl der Aufgaben); `erzeugen.sql` bindet sie mit
`\ir kinder.sql` ein.

LSA-V2 (`docs/lsa/Bauauftrag-LSA-V2.md`): Max und Lina können vom Stoff, der als Nächstes kommt, nur das erste
kommende Plan-Thema. Die Einstiege der zwei Themen danach stehen in `ausnahmen` auf `uebung`. So zeigt jeder Lauf
den Ausblick und seinen Stopp (zwei Ausblick-Knoten hintereinander nicht sicher). Tim braucht `hoechstens` nicht
mehr: Seine LSA endet, wenn die Auswahl leer ist, spätestens beim Deckel 40.

### Batus Profil (LSA-L2)

Festgeschrieben aus Batus Testlauf vom 24.10.2026 (Klasse 9, FWG, Reelle Zahlen, 34 Aufgaben; Urteile per dbread),
ohne IDs, nur Skill-Keys und Ergebnisse:

- **Mit Urteil im Testlauf:** traegt → `sicher` (auch mitbelegt), traegt_nicht und traegt_teilweise → `uebung`
  (falsch), nicht_angesetzt → `nicht_angesetzt` („Weiß ich nicht“). Abweichend vom Grundstand also
  `groessen_flaechen` (Kl. 6), `geo_flaeche_dreieck`, `term_einsetzen` (7), `geo_flaeche_drachen_raute`,
  `gleichung_lgs_addition`, `gleichung_lgs_grafisch`, `stoch_pfad_summe`, `term_binom_faktorisieren`,
  `term_binom_quadrat` (8), `zahl_wurzel_teilweise` (9) → `uebung`; `geo_flaeche_trapez` → `nicht_angesetzt`.
- **Ohne Urteil:** Klasse ≤ 6 `sicher`. Klasse 7/8 nach Feld wie im Testlauf: **Terme & Gleichungen** `uebung`
  (dort waren 5 von 7 direkt geprüften Terme-Bereichen nicht sicher), **Zufall** `uebung` (sein einziger
  Zufall-Bereich war falsch), **Geometrie gemischt** (dort 2 sicher, 3 nicht): die ungeprüften Geometrie-Bereiche
  abwechselnd in Schlüssel-Reihenfolge, das trifft nur `geo_flaeche_rueck` → `uebung`; Zahlen, Prozent,
  Funktionen und Größen `sicher` (dort alles sicher). Klasse 9 und 10 wie das Thema: `sicher` (4 von 5
  Thema-Bereichen sicher).
- Antwortdauer 34 s (Mittel des Testlaufs), Anliegen „Grundlagen fehlen“, die 21 behandelten Themen des Leads,
  Klassenarbeit zum Thema geschrieben (kein Prüfungstermin).

## Was das Skript tut

`erzeugen.sql` ist reines SQL ohne DDL und läuft in einer Transaktion.

1. Legt je Kind einen Test-Lead mit Erstgespräch an (Phantasiedaten, Eltern-E-Mail
   `<vorname>@example.invalid`, keine Verträge) und den provisorischen Schüler mit fester UUID
   (`a5a7c41d-1ead-…` Leads, `a5a7c41d-5c00-…` Schüler). Ein zweiter Lauf aktualisiert nur die Angaben.
2. Setzt das aktuelle Thema (`lead_thema_setzen`), die behandelten Themen und das Anliegen
   (`lead_assessment_upsert`).
3. Gibt die LSA frei (`lead_lsa_freigeben`), beantwortet jede Aufgabe über `lsa_submit` und schließt mit
   `lsa_finish` ab — als bestehender Admin über `request.jwt.claims`, wie die App. Wertung, Urteile,
   Fehlbilder und `result_summary` entstehen ausschließlich in diesen Funktionen.
4. Simuliert die Uhr: `started_at` der neuen Sitzung wird vor der ersten Antwort um 20 Minuten
   zurückgesetzt, jede Antwort trägt `p_jetzt` = Beginn + bisherige Antwortdauern. Die Auswahl rechnet
   nur mit diesem Abstand, also genau wie bei einem Kind, das so lange braucht.
5. Gibt je Kind eine NOTICE (Profil, Abweichungen vom Profil) und am Ende die Tabelle aus:
   Kind · Klasse · Thema · Sitzung · Status · Aufgaben gesamt · davon ready · sicher · Übungsbedarf ·
   ohne Ansatz · auswertbar · Fehlbilder · Report-Pfad. Gezählt werden direkt geprüfte Bereiche. Die Tabelle zeigt nur
   die Kinder, die gelaufen sind.
6. Nimmt die Wertung eine ganz richtige Antwort nicht als richtig an (`lsa_responses.correct` nicht true),
   bricht der Lauf nicht ab: je Fall eine NOTICE `LSA-T: richtig beantwortet, nicht angenommen` mit
   task_id, skill_key, input_type und der gesendeten Antwort, ohne Kindername. Ist Max gelaufen, folgt
   nach der Tabelle seine Liste „richtig beantwortet, nicht angenommen“. Jeder Eintrag ist ein
   Inhaltsfehler für Lena; leer heißt: alles angenommen.

Gezogen wird aus dem Testkonto-Pool (`students.ist_test` → Entwürfe ohne Prüfausschluss), weil noch wenig
auf „ready“ steht; „davon ready“ zeigt, wie viele der gezogenen Aufgaben schon freigegeben sind.

## Starten

Erst prüfen, dass `DATABASE_URL` auf den Supabase-Pooler und die Datenbank `postgres` zeigt (`dbcheck`
prüft das nicht), dann laufen lassen. Alle acht Kinder:

```bash
[[ "$DATABASE_URL" == *pooler.supabase.com* ]] && \
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/lsa-testkinder/erzeugen.sql
```

Nur einzelne Kinder mit `-v nur=…` (Vorname, mehrere mit Komma, z. B. `-v nur=Max,Lina`):

```bash
[[ "$DATABASE_URL" == *pooler.supabase.com* ]] && \
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v nur=Max -1 -f tools/lsa-testkinder/erzeugen.sql
```

Ein unbekannter Name bricht vor dem ersten Schreiben ab (`LSA-T: unbekannte Kinder in nur: …`, mit der
Liste der bekannten). Ohne `-1` läuft jeder Block für sich; dann bleibt bei einem Fehler ein halber Stand
stehen.

## Erneut laufen lassen

Jeder Lauf legt je Kind eine **neue** Sitzung an und löscht nichts (Rohdaten bleiben append-only). Die
Tabelle nennt die Sitzung dieses Laufs.

- **Nach LSA-V (neue Auswahl):** einfach erneut starten. Die neuen Sitzungen zeigen die neue Auswahl an
  denselben Kindern; die alten Sitzungen bleiben zum Vergleich stehen.
- **Nach R7-11 (neuer Report):** kein neuer Lauf nötig. Der Report rechnet beim Öffnen neu — dieselben
  Report-Pfade erneut öffnen.
- **Neue Aufgaben im Pool:** erneut starten; „davon ready“ steigt mit jeder Freigabe.

## Simulation vorher/nachher (LSA-V2, LSA-L2)

`simulation.sh [<migration> [<variante> …]]` baut im lokalen Postgres eine Grundlage-DB (CI-Neuaufbau ohne die
Migration, Standard `*_lsa_l2_wiederholung.sql`) und daraus je Stand eine Kopie: „vorher“, „nachher“ (mit der
Migration) und je Variante eine (statt der Migration die Variante, etwa mit einer anderen Konstante). Je Stand und
Pool (`POOLS="neuaufbau prod"`) laufen Fixture, `erzeugen.sql`, `auswertung.sql` und `l2-auswertung.sql` in einer
Transaktion, die zurückgerollt wird. Sitzungs- und Aufgaben-ids sind fest, damit vorher/nachher nur die Änderung
zeigt. Nie gegen Prod.

- `neuaufbau-fixture.sql`: Admin und drei Aufgaben je Skill (dieselbe Fixture wie der pgTAP-Test).
- `l2-fixture.sql` mit `l2-pool-fixture.sql`: genau der freigegebene Prod-Pool (id, Skill, Eingabeart,
  Sondierrang, Text-Hash; keine Inhalte), alle anderen Aufgaben inaktiv. Neu erzeugen: die Abfrage, die
  `l2-pool.sql` für die Fast-Duplikate benutzt, mit `left(md5(norm), 12)` über `lsa_im_pool(id, false)`.
- `auswertung.sql` (LSA-V2): je Kind Aufgaben, Dauer, Ende, Ausblick, tiefste Klasse, Zweitbelege.
- `l2-auswertung.sql` (LSA-L2): je Kind Themenraum geprüft/vorgesehen und die Wiederholungen (a)–(e); für Batu die
  Folge, die Abdeckung je Gruppe (`l2-gruppen.sql`) und die Signal-Voraussetzungen je kommender Klassenarbeit.
  `erzeugen.sql` merkt sich dafür die Folge je Kind (`lsat.folge`).

```bash
bash tools/lsa-testkinder/simulation.sh supabase/migrations/<V>_lsa_l2_wiederholung.sql /pfad/variante.sql
bash tools/lsa-testkinder/l2-messung.sh   # Laufzeit „Weiter“ in den DBs der Simulation
```

Ergebnisse: `docs/lsa/lsa-v2-simulation.md` (22.10.2026), `docs/lsa/l2-simulation.md` (25.10.2026).
Ist-Stand gegen Prod (nur lesend): `l2-pool.sql`, `l2-freigabeliste.sql`.

## Test

`supabase/tests/lsa_testkinder.test.sql` lässt das Skript im CI-Neuaufbau zweimal laufen (mit
`neuaufbau-fixture.sql`, der Neuaufbau hat keine LSA-Aufgaben) und prüft je Kind Abschluss, Profil,
Uhr, Fehlbild und den zweiten Lauf; für Max zusätzlich 100 % sicher und eine leere Liste „richtig
beantwortet, nicht angenommen“. Tim ist nicht auswertbar, die sieben anderen (mit Batu, LSA-L2) sind auswertbar (LSA-R2,
`lsa_durchklick_stand`). LSA-V2: Max und Lina mit Ausblick und Stopp, kein Kind über 40 Aufgaben, Tim endet durch
den Deckel oder die leere Auswahl, „Weiß ich nicht“ ohne Zweitbeleg, Jonas bis Klasse 5/6. Danach ein Lauf mit `nur=Max` (genau eine neue Sitzung) und einer mit
unbekanntem Namen (Abbruch).

Hinweis zu Tim: Alle Antworten eines Laufs liegen in einer Transaktion und tragen dieselbe Abgabezeit. Die
Reihenfolge der Abgaben ist dann nicht die echte; die Anteilsregel (ab 10 Antworten, 40 % schnell falsch)
macht ihn trotzdem sicher nicht auswertbar.

## LSA-L3: Klassenarbeits-Stand (Simulation)

Seit L3 setzt `erzeugen.sql` auch `leads.klassenarbeit_status` und `letzte_klassenarbeit_note` (Felder `ka_status`,
`ka_note` im Profil; die acht Kinder oben haben keinen Status, laufen also `thema_zuerst`). Für die Simulation gibt
es weitere Kinder in `l3-kinder.sql` (Batu bevorstehend, geschrieben, Note 4, „stark“ mit Note 2; Mia Klasse 7 mit
Auffüllen aus Klasse 8, geschrieben und bevorstehend). Sie laufen nur mit `KINDER_ZUSATZ`, nicht im pgTAP-Test:

```bash
KINDER_ZUSATZ=$(pwd)/tools/lsa-testkinder/l3-kinder.sql AUSWERTUNG=l3-auswertung.sql \
  bash tools/lsa-testkinder/simulation.sh supabase/migrations/<V>_lsa_l3_ka_modus.sql
```

`l3-auswertung.sql` (mit `l3-gruppen.sql`) gibt je Kind Modus, Aufgaben und Minuten je Gruppe, die direkt geprüften
Bericht-Voraussetzungen der nächsten drei Klassenarbeiten, Themenraum, Ausblick, Aufgaben über der Klasse,
Wiederholungen und einen md5 der Folge aus. Ergebnisse: `docs/lsa/l3-simulation.md`. Die Laufzeitmessung
`tools/lsa-weiter-messung.sql` nimmt `-v ka=geschrieben` für den Modus `vorschau_zuerst`.
