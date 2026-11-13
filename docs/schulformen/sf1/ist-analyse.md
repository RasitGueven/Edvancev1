# SF-1 · S0 Ist-Analyse Schulformen

**Stand:** 13.11.2026. Code auf `origin/dev` @ `75489322`, Datenbank per `dbread` (nur lesend).
Zeilen ohne Datei beziehen sich auf `supabase/schema-erwartet.sql` (Prod-Abzug auf `origin/dev`).
Vorarbeit: MSA-0 (`docs/msa/bestandsaufnahme.md` §5), deren Befunde hier nachgeprüft und ergänzt sind.

---

## 1 · Lead, Kind und Schule

| Stelle | Schule als FK | Schulform | Beleg |
|---|---|---|---|
| `leads` | `schule_id uuid` (seit W1-4), dazu Freitext `school_name` | `school_type text` mit CHECK | `:27603–27657` |
| `students` | `schule_id uuid`, dazu Freitext `school_name` | `school_type text` mit CHECK | `:28946–28958` |
| `vertraege` | `schule_id uuid`, dazu Freitext `schule` | keine | `:29450` ff. |
| `schulen` | – | `schulform text` mit CHECK | `:28266–28277` |

- **Lead-Aufnahme:** `src/pages/admin/intake/SectionLead.tsx:84–107`. Erst die Schulform als `<select>` aus
  `SCHOOL_TYPES` (`intakeConstants.ts:7–12`), dann `SchulAuswahl` (`src/pages/admin/intake/SchulAuswahl.tsx`), die
  `schulen` nach der gewählten Schulform filtert und `schule_id` + `school_name` setzt; Freitext ohne `schule_id`
  bleibt möglich.
- **Vertrag:** `vertrag_starten` sucht die Schule **über den Namen** (`lower(s.name) = lower(btrim(school_name))`,
  `:26233–26236`), nicht über `leads.schule_id`. `vertrag_abschliessen` legt das Kind mit `class_level` und
  `school_name` an (`:25621–25633`) und setzt `students.schule_id` nur, wenn sie leer ist (`:25653–25656`). Die
  **Schulform wird beim Vertrag nicht übernommen** (`vertraege` hat keine Spalte dafür). Oberfläche:
  `src/pages/admin/vertraege/SchuleAuswahl.tsx` (Liste aller Schulen, „neu anlegen“).
- **Schülerakte:** `src/pages/admin/akten/StammdatenKachel.tsx:93–100` (gleiche `SchuleAuswahl`), schreibt über
  `akte_stammdaten_aendern(p_student_id, p_name, p_klasse, p_schule_id)` (`:279`). Schulform und Kurs sind dort nicht
  erfassbar.
- **LSA:** `lsa_schule_von_sitzung` (`:9762`) nimmt `students.schule_id`, sonst `leads.schule_id`, sonst einen
  eindeutigen Namenstreffer von `students.school_name` in `schulen`. Die Klasse kommt aus der Sitzung
  (`v_sess.grade`, `lsa_select_next_core` `:9916` ff.). Die Schulform liest die LSA **nirgends**; sie folgt nur dem
  Plan der Schule (`schul_themenplan`) oder dem G9-Rückfall `lsa_klp_themen`.
- **Prod:** 48 Leads, davon 15 mit `schule_id`; alle Nicht-Gymnasium-Leads und -Kinder sind Testdaten
  (`ist_test = true`). „Gesamtschule Holweide“ steht nur als Freitext an einem Test-Lead und einem Test-Kind.

**Folge für S1/S3:** Kurs und Abschlussziel brauchen einen Ort am Lead (vor Vertrag) und am Kind (Verlauf). Die
Übernahme beim Vertragsabschluss muss dort ansetzen, wo `vertrag_abschliessen` das Kind dem Lead zuordnet
(`students.lead_id`).

## 2 · CHECKs und Listen der Schulformen

| Ort | Werte | Beleg |
|---|---|---|
| `schulen_schulform_check` | Gymnasium, Gesamtschule, Realschule, Hauptschule (oder null) | `:28277` |
| `leads_school_type_check` | dieselben vier | `:27657` |
| `students_school_type_check` | dieselben vier | `:28958` |
| `src/types/domain.ts:5` | `SchoolKind` (vier) | |
| `src/types/onboarding.ts:4` | `SchoolType` (vier + `''`) | |
| `src/pages/admin/intake/intakeConstants.ts:7–12` | `SCHOOL_TYPES` (vier) | |
| `skill_clusters.school_types text[]` | ohne CHECK | `:28607` |

- Die Werte werden in `SectionLead.tsx:94–98` **ohne i18n** als Rohwert angezeigt (Verstoß gegen §12, wird in S3 mit
  behoben).
- Funktionen mit `schulform`/`school_type` im Text (pg_proc-Scan): `app_provision_student`, `lead_lsa_freigeben` —
  beide reichen den Wert nur durch.
- In den Textdateien (`src/i18n/locales/de/*.json`) steht keine Liste der Schulformen.

## 3 · Paket-Berechnung

- **`lsa_pakete_roh(p_schuljahr)`** (`:9384`): Quellen sind `schul_klassenarbeiten` (bestätigt) und
  `schul_themenplan` (geschätzt); bestätigte Arbeiten einer Schule/Klasse verdrängen den Plan (`plan … not exists
  best`). Lage: Halbjahr, sonst Stunden, sonst gleichmäßig. `spaeter` nutzt für Klasse + 1 den Plan, sonst
  `lsa_klp_themen`.
- **`lsa_paket_skills_roh(p_schuljahr)`** (`:9243`): rechnet aus `lsa_pakete_roh` die Skills (Fall A Einstieg/
  Voraussetzung/Tiefe, Fall B Rand). Kennt keine Schulform.
- **`lsa_klp_themen(p_fach, p_klasse)`** (`:8866`): G9-Stufen (≤ 6 erprobung, ≤ 8 erste, sonst zweite) aus `themen`.
- **Aufrufer (pg_proc-Scan 13.11.2026):** `lsa_klp_themen` ← `lsa_pakete_roh`, `lsa_select_next_core`.
  `lsa_pakete_roh`/`lsa_paket_skills_roh` ← `lsa_pakete_basis`, `lsa_paket_skills_basis`,
  `lsa_paket_cache_auffrischen`, `lsa_paket_skills_roh`. Cache: `lsa_paket_cache` mit
  `lsa_paket_cache_quelle_check` (`bestaetigt`, `geschaetzt`, `:9354`) — **eine neue Quelle `klp` braucht eine
  Änderung dieses CHECKs.**
- **Schule ohne Plan:** bekommt **keine Pakete**, weil `plan` nur aus `schul_themenplan` liest (MSA-0 §5a).
  Prod heute: 1.082 Pakete an 32 Schulen, alle `geschaetzt`; 11 Gymnasien und die namenlose Schule haben keine.

## 4 · Wie die Gymnasien angelegt wurden

- Migration `supabase/migrations/20261001125708_schulen_schulplaene_koeln.sql:12–55`, erzeugt von
  `scripts/schulplaene/bauen.py` aus `scripts/schulplaene/schulen.json`.
- Quelle: Stadt Köln, „Alphabetische Liste der Gymnasien“ (URL im Kopf der Migration).
- Felder: `name, ort ('Köln'), schulform, stadtteil, traeger ('öffentlich'|'privat'), website`.
  **Keine Schulnummer**, kein Bezirk. Eindeutigkeit über `schulen_name_ort_uniq (lower(name), coalesce(ort,''))`
  (`:31969`); die Migration nutzt `on conflict … do update`.
- RLS: `schulen_admin_all` (`:37177`).
- Prod: 43 Gymnasien in Köln (37 öffentlich, 6 privat), 32 mit Plan; dazu eine Zeile „Gymnasium“ ohne Schulform.

**Muster für die neuen Schulen (S1):** gleiche Felder; Quelle diesmal das amtliche Schulverzeichnis NRW
(Open Data, siehe unten). Weil die Aufgabe Doppelte über die Schulnummer erkennen soll, bekommt `schulen` eine
Spalte `schulnummer` (eindeutig, nullable). `stadtteil` steht nicht im Verzeichnis und bleibt leer (nicht aus der PLZ
geraten). Die Liste der Stadt Köln (Realschulen/Gesamtschulen) nennt ebenfalls keinen Stadtteil.

### Amtliche Quelle für S1

- `https://www.schulministerium.nrw.de/BiPo/OpenData/Schuldaten/schuldaten.csv` (Weiterleitung auf
  `apps.schulministerium.nrw.de`), abgerufen 13.11.2026 08:22 UTC, SHA-256 `8732daec…502c59`, dazu
  `key_schulformschluessel.csv`, `key_rechtsform.csv`, `key_schulbetriebsschluessel.csv`.
- Filter: Schulform 10 (Realschule), 13 (Primus), 14 (Sekundarschule), 15 (Gesamtschule); Ort Köln bzw.
  Gemeindeschlüssel Kerpen `05362032`.
- Ergebnis: **Köln 20 Realschulen (18 öffentlich, 2 privat), 25 Gesamtschulen (19 öffentlich, 6 privat), keine
  Sekundarschule, keine Primusschule. Kerpen: 1 Gesamtschule** (Willy-Brandt-Gesamtschule, 191942). Alle mit
  Schulbetriebsschlüssel 1.
- Damit: **„Primusschule“ wird nicht zugelassen.** „Sekundarschule“ wird laut Auftrag trotzdem zugelassen (Kinder
  aus dem Umland, Kursmodell wie GE).

## 5 · Kernlehrplan-Fassung nach Klasse und Schuljahr

Amtliche Regel: RdErl. d. MSB v. 02.06.2022 (526-2022-05-0001474), abgedruckt im KLP GE/SK 2022, S. 4, und im
KLP RS 2022, S. 4: **„Die Kernlehrpläne treten zum 01.08.2022 beginnend mit Klasse 5 aufsteigend in Kraft.“**
(`docs/msa/quellen/klp_gesk_m_klp_2022_06_17.pdf`, `klp_rs_m_klp_2022_06_17.pdf`). Die Vorgaben ZP10 2027 nennen
die KLP 2004, die Vorgaben 2028 die KLP 2022 (`docs/msa/quellen/README.md` a).

**Regel:** Ein Kind in Klasse *k* im Schuljahr mit Beginn *y* war im Schuljahr *y − (k − 5)* in Klasse 5.
Fassung **2022**, wenn *y − (k − 5) ≥ 2022*, sonst **2004**.

| Schuljahr | Kl. 5–9 | Kl. 10 |
|---|---|---|
| 2026/27 | 2022 | **2004** (ZP10 2027) |
| 2027/28 | 2022 | 2022 (erste ZP10 nach neuem KLP 2028) |

Das bestätigt die Annahme des Auftrags. Für Gymnasien gilt weiter der KLP G9 2019 (ohne Klassenzuordnung).

## Offene Punkte aus S0

1. `vertrag_starten` sucht die Schule über den Namen statt `leads.schule_id` (`:26233`). Nicht Teil von SF-1;
   für S3 relevant, weil die Liste den Namen exakt setzt.
2. Schulnummern der 43 Gymnasien fehlen; S1 trägt sie nicht nach (kein Auftrag), Doppelprüfung greift nur für neue
   Schulen.
3. Die Schulform-Anzeige im Intake ist nicht übersetzt (S3).
