# SPEC S5 — P-Intake Ebene A: Datenfundament

**Repo:** Edvancev1 · **Migration: ja** · **Kein Screen, keine Optik.**
**Zweck:** Das Datenfundament für den Prozess Erstgespräch → LSA. Überlebt den Gründer-Termin,
weil rein strukturell. Die Oberfläche (Ebene B) kommt danach.

---

## 0. Ausgangslage (verifiziert — darauf aufbauen, nicht neu bauen)

**`leads` existiert bereits** und ist reich:
```
id, created_at, full_name, contact_email, contact_phone,
class_level (5–13), school_type, school_name, subjects[], goal,
known_weak_topics[], source, status, owner_id, notes,
converted_student_id → students(id), contacted_at, onboarding_scheduled_at
status: new | contacted | onboarding_scheduled | converted | rejected
```
Das Intake-Datenmodell steht also weitgehend. `converted_student_id` existiert — die Konversion
ist im Ansatz vorgesehen.

**`lsa_start(p_student_id uuid, p_grade integer, p_subject text)`** verlangt zwingend eine
`students`-Zeile. **Ein Lead hat keine.** Das ist der Kern der B5-Frage (siehe A1).

---

## A1 · LSA gegen einen Lead — DIE KERNENTSCHEIDUNG

`lsa_start` braucht `p_student_id`. Ein Interessentenkind soll die LSA machen können, **ohne** schon
ein vollwertiges Schülerkonto zu sein — und bei Absage muss alles restlos löschbar sein.

**Der Agent trifft diese Entscheidung NICHT allein. Er analysiert die Optionen und meldet.**
Drei denkbare Wege, jeweils mit Konsequenz:

**Option 1 — Provisorisches Schülerkonto pro Lead.**
Beim LSA-Start entsteht eine `students`-Zeile, verknüpft mit dem Lead (`lead_id` an `students`,
oder über `leads.converted_student_id` schon vor der Konversion). Bei Absage: Lead + provisorisches
Konto + LSA-Daten kaskadiert löschen.
*Konsequenz:* `lsa_start` bleibt unverändert. Aber „provisorisch" und „echt" müssen unterscheidbar
sein, sonst zählt ein Lead als Schüler in Statistiken/Abrechnung.

**Option 2 — `lsa_start` nimmt wahlweise einen Lead.**
Neue Signatur oder Overload, die statt `p_student_id` eine `p_lead_id` akzeptiert. Die Session
hängt am Lead, nicht am Schüler. Bei Konversion wandert die Session zum Schüler.
*Konsequenz:* Eingriff in P01/den Datenvertrag. `lsa_responses`, `result_summary` etc. müssen
beide Fälle tragen (Lead-Session vs. Schüler-Session).

**Option 3 — Session-Entität, die sowohl Lead als auch Schüler referenzieren kann.**
Eine Ebene über beiden. Sauberer, aber der größte Umbau.

**Aufgabe:** Analysiere gegen das echte Schema (P01-Funktionen, `lsa_responses`, `students`,
`leads`), welche Option den kleinsten sicheren Eingriff bedeutet und die Löschbarkeit am saubersten
erfüllt. **Empfehlung aussprechen, dann STOPPEN und auf Freigabe warten** — nicht eine Option
eigenmächtig durchbauen. Das ist eine architektonische Weiche, keine Implementierungsfrage.

---

## A2 · Vollständige Löschbarkeit (DSGVO)

„Wenn Sie sich dagegen entscheiden, löschen wir alles." Das muss einlösbar und nachweisbar sein.

- Eine Operation (RPC `lead_delete(p_lead_id)` oder Kaskade) entfernt: den Lead, alle
  Einschätzungen (A3), alle LSA-Daten des Leads (Session, `lsa_responses`, `result_summary`),
  und — falls Option 1 — das provisorische Schülerkonto.
- **Nachweisbar:** Nach der Löschung darf kein verwaistes Datum in irgendeiner Tabelle auf den
  Lead verweisen. pgTAP prüft das.
- Ein **konvertierter** Lead (→ Schülerkonto, Vertrag) wird NICHT über diesen Weg gelöscht — dort
  gelten andere Aufbewahrungspflichten. `lead_delete` verweigert bei `status = 'converted'`.
- Nur `admin` darf löschen. `revoke execute from public`, Rollenprüfung im Body.

---

## A3 · Die zwei Einschätzungen (Eltern + Kind, getrennt)

Neue Tabelle `lead_assessments`:
- `lead_id → leads(id) on delete cascade`
- `source text check (source in ('parent','child'))`
- `content` — die Einschätzung „wo liegen die Schwierigkeiten". Struktur: Freitext plus optional
  strukturierte Themen-Tags (an `known_weak_topics` / Kompetenzen anlehnbar — prüfen, was passt).
- `created_at`
- Unique pro (lead_id, source): je eine Eltern- und eine Kind-Einschätzung.

**Verdeckt voneinander:** Beim Erheben sieht die eine Seite nie die andere. Das ist primär
UI (Ebene B), aber die Datenstruktur darf es nicht unterlaufen — keine Funktion gibt beide
zusammen an einen Client, der nur eine erheben soll.

**KRITISCH — die Einschätzung darf die LSA NICHT steuern:**
Sie ist Metadatum für den späteren Reveal (Eltern-Vermutung vs. Kind-Vermutung vs. gemessenes
Ergebnis), NIE Input für `lsa_start` / die Aufgabenauswahl. Sonst testet die LSA das, was das Kind
ohnehin für sein Problem hält, statt neutral zu messen — und der Reveal-Moment (das Verkaufsargument)
bricht.
- `lsa_start` und der Ziehalgorithmus dürfen `lead_assessments` **nicht lesen**.
- pgTAP: Es gibt keinen Pfad, über den eine Einschätzung die Item-Auswahl beeinflusst.

---

## A4 · Tutorial-Pool (`is_tutorial`)

- `tasks.is_tutorial boolean not null default false` (prüfen, ob ein solches Feld schon existiert).
- Ein kleiner Satz trivialer Aufgaben (3–5) nur zum Formate-Zeigen. Über das Feld markiert.
- **Nie im LSA-Pool:** `lsa_start` zieht ausschließlich `is_tutorial = false`. Ergänzen.
- Tutorial-Antworten werden nicht in `lsa_responses` geschrieben und nie ausgewertet.
- pgTAP: Ein Tutorial-Item kann nie in eine LSA-Session gelangen; die 14 (bald mehr) echten
  Pool-Items sind unberührt.

---

## A5 · Fundament-Abstieg unabhängig vom Intake

- Der Intake (`leads.class_level`, `known_weak_topics`) setzt den **oberen** Rand: kein Stoff
  oberhalb der Klassenstufe.
- Der Abstieg nach unten (`curriculum_grade` < `class_level`) läuft **unabhängig** — die LSA testet
  Fundament-Skills, auch wenn der Intake sie nicht nennt. Sonst findet sie nie die Klasse-6-Lücke.
- `lsa_start` entsprechend: oberer Rand aus dem Lead, unterer Rand nicht durch den Intake begrenzt.
- Solange `curriculum_grade` im Pool leer ist, Fallback auf `class_level` (in A01 bereits so vorgesehen).
- **Falls A1 noch offen ist** (Session-gegen-Lead ungelöst), wird A5 als Vorbereitung umgesetzt,
  aber erst mit A1 scharf geschaltet — nicht blockieren, sauber trennen.

---

## Definition of Done (Ebene A)

- [ ] A1 analysiert, Empfehlung ausgesprochen, **Freigabe eingeholt** bevor durchgebaut
- [ ] `lead_assessments`: zwei getrennte, verdeckte Einschätzungen pro Lead
- [ ] Einschätzungen für `lsa_start` **nicht lesbar** — pgTAP belegt die Trennung
- [ ] `is_tutorial` gesetzt, Tutorial nie im LSA-Pool — pgTAP
- [ ] `lead_delete`: vollständig, nachweisbar, verweigert bei `converted` — pgTAP
- [ ] Fundament-Abstieg unabhängig vom Intake-Rand
- [ ] Bestehende 14 Pool-Items und alle P01-Invarianten (INV-1..8) unberührt — Regression grün
- [ ] pgTAP, tsc, db lint grün

## Explizit NICHT in Ebene A

- Keine Screens, keine Optik, kein Avatar, kein Intake-Formular.
- Keine Einschätzung, die die Aufgabenwahl steuert.
- Kein Tutorial-Item im echten Pool.
- Keine Report-Darstellung.
- A1 nicht eigenmächtig durchbauen — Empfehlung, dann Freigabe.
- Kein Deploy.
