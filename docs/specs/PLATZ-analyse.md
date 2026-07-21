# PLATZ — Kiosk-Mechanik für die LSA am Tablet-Platz: Analyse & Empfehlung

**Status:** Analyse. **Wird NICHT in diesem Lauf gebaut.** Wartet auf menschliche Freigabe
(Rasit). Erst nach Freigabe setzt ein eigener Lauf die gewählte Option um.

**Eingrenzung (verbindlich):** Die Platz-Mechanik ist AUSSCHLIESSLICH für die LSA — ein
Kiosk-Mechanismus für das Erstgespräch, keine allgemeine Geräte-Architektur. Ein
Platz-Kontext darf ausschließlich die ihm aktuell zugewiesene LSA-Session erreichen
(Begrüßung, Avatar-Wahl, Tutorial, LSA-Aufgaben, Abschluss). NIEMALS: Hub, XP,
student_progress, fremde oder vergangene Sessions. Nach `lsa_finish` (oder
Zuweisungs-Ende durch den Admin) ist der Platz wieder leer.

**Die Frage:** Wie authentifiziert sich das Tablet, und wie erfährt es, welcher
(provisorische) Schüler ihm zugewiesen ist?

---

## 1. Der echte Code (verifiziert, nicht geraten)

Quellen: `supabase/migrations/20250101000000_baseline.sql` (Auth-Helfer, RLS),
`20260712100000_p01_datenvertrag.sql` (LSA-RPCs, Grants),
`20260713100000_p02_multipart.sql` (aktuelle `lsa_submit`/`lsa_question_payload`),
`20260716100000_s7_lead_lsa.sql` (provisorischer Schüler, dieser Lauf).

**Autorisierung der LSA-RPCs — der zentrale Befund:**

```sql
-- lsa_may_act_for(p_student_id):
select public.get_my_role() in ('coach','admin')
    or public.get_my_student_id() = p_student_id

-- get_my_student_id():
select id from students where profile_id = auth.uid() limit 1
```

`lsa_start` prüft `lsa_may_act_for(p_student_id)`; `lsa_submit`/`lsa_finish`/`lsa_hint`
prüfen `lsa_may_act_for(v_session.student_id)`. **Ja — `lsa_start` prüft `auth.uid()`
gegen `p_student_id`**, aber ausschließlich über den Umweg
`students.profile_id = auth.uid()`.

**Konsequenz für S7:** Der provisorische Schüler hat `profile_id = NULL` (bewusste
A1-Leitplanke: kein Auth-Konto, nichts zu leaken). Damit kann **kein Auth-User der Welt**
über den Schüler-Zweig von `lsa_may_act_for` für ihn handeln — der einzige bestehende
Weg wäre die Rolle `coach`/`admin`, und die darf ein dauerhaft im Raum liegendes Tablet
niemals tragen (sieht per RLS alle Schüler, Leads, Auswertungen).

**Weitere verifizierte Fakten:**

- **Rollen sind eine geschlossene Liste:** `profiles.role check (role in
  ('student','parent','coach','admin'))` (baseline). Eine neue Rolle `platz`/`kiosk`
  hieße: CHECK erweitern **und** jede `get_my_role() in (…)`-Policy/-RPC neu bewerten —
  ein Querschnitt durchs eingefrorene Fundament.
- **Ein `student`-Konto ohne `students`-Zeile ist strukturell „nichts":**
  `get_my_student_id()` liefert NULL → alle `lsa_*` verweigern; `students_select_own`,
  `student_subscriptions_select_own` etc. matchen nichts; `leads`, `lead_assessments`,
  `lsa_sessions`, `lsa_responses` haben **keine** Studenten-Policies (Kind sieht per
  Design nie Auswertungen, P01 §5). Die einzige direkt lesbare Fläche ist
  `read_tasks_by_role`: Zeilen mit `status='ready'`.
- **`lsa_question_payload(p_task_id)` trägt KEINE Autorisierung** und ist an
  `authenticated` ge-grantet (P01 §7): jedes eingeloggte Konto kann für eine beliebige
  task_id das Frage-Payload ziehen. Es leakt beweisbar keine Lösung (inv2/inv3/inv8),
  aber es ist nicht sessionsgebunden — für die strenge Platz-Anforderung („über KEINEN
  Weg etwas außerhalb der Session lesen") muss die Umsetzung das mitdenken (s. §4).
- **Session → Name funktioniert ohne neue Spalte:** `lsa_sessions.student_id →
  students.lead_id → leads.first_name` (S7). Eine Begrüßungs-RPC kann „Hi <Name>"
  liefern, ohne dass das Tablet `leads` lesen darf.
- **Muster für „Tor vor bestehender RPC" existiert schon:** `task_preview_payload`
  (a02) gated `lsa_question_payload` für Coaches — additive SECURITY-DEFINER-Hülle,
  keine zweite Wahrheit. Genau dieses Muster passt für Platz-Wrapper.
- **Supabase-Auth praktisch:** Ein einmal eingeloggtes Gerät hält sich über den
  Refresh-Token dauerhaft (autoRefreshToken im JS-Client). „Einmal beim Einrichten
  einloggen, nie wieder Passwort am Empfang" ist der Normalfall, kein Sonderbau.

---

## 2. Bewertung der Optionen

Achsen: **(a) Sicherheit** (kein Tablet sieht fremde/vergangene Sessions oder mehr),
**(b) Betrieb** (dauerhaft eingeloggt, kein Passwort-Tippen, Zuweisung am Empfang),
**(c) RLS-Verträglichkeit** (welche Rolle sieht was; Eingriff ins eingefrorene P01?),
**(d) Aufwand**.

### Option 1 — Platz-Konten, `lsa_*` laufen direkt im Platz-Kontext

Jedes Tablet dauerhaft als eigener Auth-User (`platz1@…`), Admin weist Lead→Platz zu,
das Tablet ruft die bestehenden `lsa_*` direkt auf. Damit das autorisiert, gibt es nur
zwei Wege — beide schlecht:

**1a — `lsa_may_act_for` um eine Zuweisungs-Tabelle erweitern.**
Direkter Eingriff in die eingefrorene P01-Autorisierungsfunktion, die in `lsa_start`,
`lsa_submit`, `lsa_hint`, `lsa_finish` steckt. Und sie ist **schüler-scoped, nicht
session-scoped**: ein zugewiesener Platz dürfte damit auch `lsa_start` selbst aufrufen
und **vergangene/parallele Sessions desselben Schülers** bedienen — genau das, was die
Eingrenzung verbietet. Um das zu verhindern, müsste die Zuweisungsprüfung in jede
einzelne RPC differenziert einwandern → noch mehr Vertragschirurgie.
- (a) Sicherheit: nur mit Zusatzchirurgie session-scharf. **(c): Eingriff in P01 — hoch
  riskant.** (d): täuschend klein, real groß (jede INV-Assertion neu prüfen).

**1b — `students.profile_id` bei Zuweisung auf den Platz-User umbiegen.**
Kein Code-Eingriff (`get_my_student_id()` löst dann auf), aber: verletzt die
A1-Leitplanke „profile_id bleibt bei provisorischen Zeilen NULL"; `profile_id` ist
`on delete cascade` — das Löschen eines Platz-Auth-Users würde den Schülerdatensatz
mitreißen; die Identität des Datensatzes wird bei jeder Zuweisung mutiert (Flip-Fehler
= Kind A schreibt in Session von Kind B); und der Platz erbt die **komplette
Schüler-Lesefläche** statt nur der Session. Betrieblich charmant, strukturell das
Gegenteil der S7-Guards (die Trigger-Schleuse müsste für den Flip schon wieder
Ausnahmen bekommen).
- (a): student-scoped statt session-scoped → vergangene Sessions desselben Schülers
  erreichbar. (b): gut. (c): keine Migration, aber Identitäts-Mutation als Betriebsmodus.
  (d): klein — und genau deshalb verführerisch. **Abgelehnt.**

### Option 2 — Reiner Session-Claim (kurzlebiges Token / Deep-Link, ohne Konto)

Freigabe erzeugt ein Token; das Tablet löst es ein und „ist" danach der provisorische
Schüler. Ohne eingeloggtes Konto heißt das: die Einlöse- und alle Folge-RPCs müssten an
`anon` ge-grantet werden — gegen die bestehende Härtung (P01/a3 nehmen `anon`
konsequent alles weg). Ein Deep-Link muss außerdem irgendwie **auf genau dieses Tablet**
kommen (QR abtippen/scannen am Empfang = der Betriebsaufwand, den die Platz-Idee gerade
vermeiden will). Und „agiert danach als der Schüler" hat dasselbe Scope-Problem wie 1b,
sofern es über `lsa_may_act_for` läuft.
- (a): Token-Leak = Session-Zugriff ohne jede Gerätebindung. (b): Link-Zustellung pro
  Kind = manueller Schritt. (c): `anon`-Grants nötig — Verschlechterung. (d): mittel.

### Option 3 — EMPFEHLUNG: Kiosk-Konto + kurzlebige Platz-Zuweisung + Session-gebundene `platz_*`-Tore

Die tragfähige Mechanik kombiniert das Beste aus 1 und 2 und fasst **nichts**
Eingefrorenes an:

1. **Auth:** Ein dauerhafter Auth-User je Platz (`platz1@…`), einmal beim Einrichten
   eingeloggt (Refresh-Token hält). `profiles.role = 'student'`, **ohne**
   `students`-Zeile — nach §1 ist so ein Konto strukturell „nichts": alle `lsa_*`
   verweigern, praktisch keine RLS-Fläche. Keine neue Rolle, kein CHECK-Umbau.
   (Kennzeichnung z. B. über eine Spalte/Tabelle `platz_devices`, nicht über die Rolle.)
2. **Zuweisung:** Tabelle `platz_assignments(platz_profile_id, session_id, expires_at,
   released_at)` — **session-scoped, nicht schüler-scoped**. Der Admin erzeugt sie bei
   der LSA-Freigabe (Erweiterung um `p_platz` oder separate `platz_assign`-RPC);
   `unique` auf aktive Zuweisung je Platz. Ablauf über `expires_at` (z. B. 2 h),
   Release durch `lsa_finish` (Trigger analog `lsa_session_lead_fertig_trg` aus S7)
   oder Admin. RLS: admin all; der Platz-User liest **nur die eigene aktive Zeile**
   (macht Realtime möglich; Polling reicht für den Start).
3. **Zugriff:** Additive `platz_*`-RPCs nach dem a02-Muster („Tor vor bestehender RPC,
   keine zweite Wahrheit"): `platz_state()` (wartet/zugewiesen + „Hi <Name>" über
   session → students.lead_id → leads.first_name), `platz_next()`,
   `platz_submit(task_id, response, duration_ms)`. Jede davon löst **ausschließlich**
   über die aktive, nicht abgelaufene Zuweisung von `auth.uid()` auf die EINE
   `session_id` auf und ruft intern die unveränderten `lsa_question_payload` /
   `lsa_submit` / `lsa_finish` auf. Kein `p_session_id`-Parameter von außen — das
   Tablet kann gar nicht nach einer fremden Session fragen.

**Bewertung:**
- (a) Sicherheit: **session-scharf per Konstruktion.** Der Platz-Kontext hat keinen
  einzigen weiteren Weg: `lsa_*` verweigern (kein `get_my_student_id`), RLS zeigt fast
  nichts, `platz_*` binden an genau eine Session mit Ablauf. Fremde und vergangene
  Sessions sind nicht adressierbar.
- (b) Betrieb: Tablets bleiben dauerhaft eingeloggt; am Empfang wird nur zugewiesen
  (ein Klick im Admin); das Tablet pollt `platz_state()` und begrüßt von selbst.
- (c) RLS: keine Policy des Fundaments ändert sich; `lsa_may_act_for` bleibt
  byte-identisch; eine neue Tabelle mit eigener, enger RLS.
- (d) Aufwand: 1 Tabelle, 3–4 kleine RPCs, 1 Release-Trigger, pgTAP — vergleichbar mit
  dem S7-Lauf selbst. Kein Eingriff in P01, keine INV-Neuprüfung nötig.

---

## 3. pgTAP-Anforderungen an die spätere Umsetzung

Die Kernanforderung: **Ein Platz-Kontext kann über KEINEN Weg etwas außerhalb seiner
zugewiesenen Session lesen.** Konkret zu beweisen:

1. Platz-User ohne Zuweisung: `platz_state()` = „leer"; `lsa_start`/`lsa_submit`/
   `lsa_finish`/`lsa_hint` → 42501; `select` auf `students`, `leads`,
   `lead_assessments`, `lsa_sessions`, `lsa_responses`, `student_progress` → 0 Zeilen.
2. Platz-User mit Zuweisung: `platz_next`/`platz_submit` erreichen genau die
   zugewiesene Session; eine **zweite** Session (anderer Lead, anderer Platz) ist über
   keinen Parameter erreichbar (die RPCs nehmen keine session_id von außen).
3. Nach `lsa_finish` bzw. `expires_at` bzw. Admin-Release: alle `platz_*` fallen auf
   „leer" zurück; die alte Session ist nicht mehr adressierbar (keine vergangenen
   Sessions).
4. Abgelaufene Zuweisung ≠ gelöschte Zuweisung: `expires_at < now()` wird in jeder
   RPC geprüft, nicht nur beim Anlegen.
5. Regression: `lsa_may_act_for`, `lsa_start`-Signatur und der gesamte P01-Datenvertrag
   byte-identisch (Muster inv_a3/s7).
6. **Offener Punkt, vor dem Bau zu entscheiden:** `lsa_question_payload` ist heute für
   `authenticated` frei aufrufbar (ohne Session-Bindung, leakt keine Lösung). Entweder
   (i) bewusst tolerieren und im Test dokumentieren, oder (ii) das Grant auf
   `service_role` + Tore (`task_preview_payload`, `platz_next`) zurückziehen — (ii) ist
   der sauberere Schnitt, braucht aber einen Blick auf den bestehenden
   Studenten-Client, der die Funktion heute evtl. direkt ruft.

## 4. Was NICHT Teil der Platz-Mechanik ist

- Kein allgemeines Geräte-Management, kein MDM, keine Geräte-Registrierung über die
  LSA hinaus. Nach Vertragsabschluss läuft alles über normale Schüler-Logins.
- Keine neue Rolle im `profiles.role`-CHECK (die Eingrenzung braucht sie nicht).
- Kein Eingriff in `lsa_may_act_for`, `lsa_start`, `lsa_submit`, `lsa_finish`,
  `lsa_question_payload` oder deren Grants — mit Ausnahme der bewussten Entscheidung
  zu §3.6(ii), falls gewählt.

---

## 5. EMPFEHLUNG — Option 3 (Kiosk-Konto + kurzlebige Zuweisung + `platz_*`-Tore)

Weil sie als einzige alle vier Achsen gleichzeitig hält: session-scharfe Sicherheit
per Konstruktion (nicht per Konvention), dauerhaft eingeloggte Tablets ohne
Empfangs-Passwörter, null Eingriff in den eingefrorenen P01-Datenvertrag, und ein
Aufwand in der Größenordnung eines normalen Feature-Laufs. Option 1a scheitert an der
Vertragschirurgie, 1b an der Identitäts-Mutation und dem Schüler- statt Session-Scope,
Option 2 an `anon`-Grants und der Token-Zustellung.

**STOPP.** Die Platz-Mechanik wird erst nach Freigabe gebaut.
