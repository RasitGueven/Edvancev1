# Offene Punkte A2d (Engine: Planer nach der Erklärsequenz, Zahlen im Entscheidungssignal)

Stand 07.10.2026, Branch `feat/rasit-session-a2d-engine`. Beweis: `supabase/tests/session_a2d.test.sql`.

## 1. Planer nach der Erklärsequenz (aus offene-punkte-a2c 3)

**Beobachtung (A2c-Beispiel, Wegwerf-DB):**
- Schulthema „Lineare Funktionen“ im Testlauf. Nach der fertigen Erklärsequenz zu `fkt_linear_steigung` kam kein Lösungsbeispiel.
- Stattdessen kam `warten` / `pool_leer` zu `fkt_linear_yabschnitt`.

**Vermutung aus A2c:** Die Entwürfe ohne `difficulty` passen nicht. **Widerlegt** durch Test D:
- Entwürfe ohne Schwierigkeit stehen im Testlauf-Pool.
- `session_schwierigkeit` fällt auf den AFB zurück.
- Nach der Sequenz kommen Lösungsbeispiel und ähnliche Aufgabe zum selben Skill.
- Test D ist vor und nach dem Fix grün.

**Ursache:** zwei Dinge zusammen.
1. **Daten der Wegwerf-DB.** Die Bestandsaufgaben zu `fkt_linear_steigung` und `fkt_linear_yabschnitt` haben dort keinen `cluster_id`.
   - `pruef_ausschluss` meldet `gate` („Cluster fehlt“), also stehen sie auch im Testlauf nicht im Pool.
   - In Prod haben sie einen Cluster; dort stehen die sechs Entwürfe zur Steigung im Testlauf-Pool (dbread, 07.10.2026).
2. **Planerfehler, der das sichtbar machte.** `session_plan_kern` schaltete einem neuen Skill die Erklärsequenz auch dann vor, wenn zu dem Skill keine Aufgabe im Pool steht. Der Ablauf im Beispiel:
   - Aktueller Skill war `fkt_linear_yabschnitt` (erster offener der Zielliste), sein Pool war leer.
   - `session_schritt_planen` wich auf `fkt_linear_steigung` aus. Der Pool dort war auch leer, aber die Sequenz war da, also kam die Erklärung.
   - Nach der Sequenz blieb für beide Skills nur `pool_leer`.
   - Das Kind bekam also einen Skill erklärt, den es danach nicht üben konnte.

**Fix (Migration `20261010101318_a2d_plan_kern_pool`):**
- Die Sequenz kommt nur noch, wenn `session_aufgabe_waehlen` für den Skill eine Aufgabe findet. Sonst endet der Skill bei `pool_leer`, und der Ausweichweg in `session_schritt_planen` greift wie bisher.
- Eine laufende Sequenz und „nochmal erklären“ bleiben unberührt.

**Beleg:**
- Test P war vor dem Fix rot (3 Zusicherungen: Erklärung statt `pool_leer`, Eintrag in `session_schritte`, Coach-Vorschau) und ist nach dem Fix grün.
- Das A2c-Beispiel läuft unverändert, `a2b-tablet-beispiele.md` 24 bis 35 stimmen weiter.

**Nur eine Aufgabe im Pool (Entscheidung Rasit, 07.10.2026; vorher Restfall aus dem Consensus-Check):**
- Steht zu einem neuen Skill nur noch eine Aufgabe im Pool, entfällt das Lösungsbeispiel. Diese Aufgabe kommt als Aufgabe (`grund_code = neu_aufgabe_ohne_beispiel`).
- Ab zwei Aufgaben bleibt es bei Beispiel, dann Aufgabe. Das gilt mit und ohne Erklärsequenz.
- Gezählt wird mit der neuen internen Funktion `session_pool_anzahl`. Sie nutzt dieselbe Pool- und „schon benutzt“-Regel wie `session_aufgabe_waehlen`.
- Die Aufgabe zählt als Einführungsaufgabe (`nach_beispiel = true`); danach läuft die Kernarbeit normal.
- Belege: Test E1 (mit Sequenz), E2 (ohne), F (genau zwei). Datenvertrag 8.2 hat den neuen `grund_code`.

**Prod heute:** Es gibt noch keine Erklärsequenz (`erklaer_kernidee` leer, dbread 07.10.2026). Der Fix wirkt vorbeugend für den Durchstich.

**Offen:**
- **a)** Mit Prod-Daten (Cluster gesetzt) beginnt die Kernarbeit für dieses Kind bei `fkt_linear_yabschnitt` und nicht bei `fkt_linear_steigung`.
  - In der Zielliste (`session_zielliste`) sind beide Rolle `einstieg`. `fkt_linear_yabschnitt` steht an Platz 5, `fkt_linear_steigung` an Platz 6, nach den vier sicheren Voraussetzungen.
  - Kein Fehler des Planers. Für den Durchstich heißt das: Wer mit der Steigung beginnen soll, braucht ein Kind, bei dem `fkt_linear_yabschnitt` nicht offen ist.
- **b)** Die Wegwerf-DB (Migrationen + `seed.sql`) hat für Bestandsaufgaben aus Migrationen keinen Cluster, Prod schon. Wer Bestandsaufgaben in Tests braucht, muss den Cluster setzen.

## 2. Zahlen im Entscheidungssignal „eine Stufe tiefer?“ (aus C2)

**Migration `20261010101644_a2d_signal_zahlen`:** Der Payload des Signals (`art = entscheidung`, `grund_code = entscheidung_tiefer`) hat zusätzlich:

| Feld | Bedeutung |
|---|---|
| `voraussetzung_skill_key` | Skill der Voraussetzung (gleich `skill_key`, ausdrücklich benannt) |
| `voraussetzung_label` | Label dazu (`session_label`) |
| `warmup_aufgaben` | Zahl der Warm-up-Aufgaben **auf dieser Voraussetzung** in der Session |
| `warmup_richtig` | davon richtig (bei `MULTI_PART`: alle bis dahin beantworteten Teile richtig) |

Die Zahlen sind der Stand beim ersten Melden des Signals. Sie werden danach nicht nachgeführt (`session_ereignisse` ist append-only).

- **Was bleibt:** `skill_key`, `ziel_skill_key`, `grund` und `grund_code` sind unverändert.
- **Weg zum Coach:** `session_ereignisse.payload` → `session_signale_intern.details` → `raum_signale` und `coach_raum_live`.
- **Tablet:** Das Signal geht nie ans Tablet. `session_schritt_oeffentlich` gibt keine Signale weiter, und Test S prüft `session_naechster_schritt` und `tablet_stand`. Datenvertrag Abschnitt 8 bleibt unverändert.

**Offen:**
- **c)** Gezählt wird je Voraussetzung, nicht über das ganze Warm-up. Liegt das Warm-up auf mehreren Skills, sieht der Coach die Zahlen nur für die Voraussetzung, an der das Signal hängt. Soll C2 auch die Gesamtzahl bekommen, ist das ein weiteres Feld.
- **d)** Die Typen der Coach-Seite (`src/types/coachLive.ts`, C2) kennen die Felder noch nicht. Das Nachziehen gehört C2.
- **e)** Ein Signal, das vor dem Einspielen entstanden ist, hat die Felder nicht (`session_ereignisse` ist append-only).
