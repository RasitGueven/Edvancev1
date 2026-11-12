# MSA-1 · Offene Befunde

## O1 · Haltepunkt `geo_flaeche_drachen_raute` (M0, 12.11.2026) — ERLEDIGT

**Erledigt am 12.11.2026:** Rasit hat entschieden, die 13 zu schweren Aufgaben nicht zu archivieren
(`ist.md` §1). Mit der Auswahl nach `soll.sql` verliert kein Skill die Regel (S02 wiederholt).
Ursprünglicher Befund:

Archiviert man die 13 zu schweren Aufgaben (Gründerentscheidung), verliert `geo_flaeche_drachen_raute` alle Texte im
Pool. Heute sind es 2 Texte bei 3 ready-Aufgaben, alle drei mit der Fläche über die Diagonalen e·f/2. Der Skill erfüllt
die Regel dann nicht mehr. Das ist laut Auftrag ein Haltepunkt (`ist.md` §1, Abfrage S02).

Mögliche Auflösungen (Entscheidung der Gründer):

1. Die 3 Aufgaben trotzdem archivieren. Dann bleibt der Skill offen, bis Lena 2 der 3 Entwürfe prüft und ein Admin sie
   freigibt. Vorher ist zu prüfen, ob die Entwürfe ebenfalls e·f/2 verlangen.
2. Die 3 Aufgaben aktiv lassen (Ausnahme von der Entscheidung „13 archivieren“) und in der MSA-LSA nur über ein
   künftiges Prüfziel ausblenden.
3. Den Skill für die MSA bewusst aufgeben. Drachen und Raute über die Diagonalen stehen nicht im KLP RS 2004 und
   nicht in der Formelsammlung MSA.

## O2 · CI-Infrastruktur: `neuaufbau` rot (12.11.2026, ab ca. 15:30 UTC) — STOPP

Der Schritt „pgTAP bereitstellen“ in `.github/workflows/schema.yml:106` scheitert:
`postgresql-16-pgtap 1.3.4-1.pgdg13+2 Depends postgresql-16 (> 16.16)`. Der Dienst-Container `postgres:16` ist älter.
Das betrifft jede PR, auch reine Doku (#404, eine Wiederholung ebenfalls rot), und hat mit MSA-1 nichts zu tun.
Die Abhilfe liegt unter `.github/` (pgtap-Version festnageln oder `image: postgres:16` auf eine Version ≥ 16.17 heben)
und ist für diesen Auftrag gesperrt. Laut „Einspielen und Mergen“ ist ohne grüne CI weder Merge noch Einspielen
erlaubt. **Haltepunkt, STOPP.**

## O3 · Hinweise der Zweitprüfung M1 (nicht behoben, bewusst)

- `read_tasks_by_role` (`schema-erwartet.sql`, Policy) lässt jede Rolle ready-Aufgaben ohne `is_active`-Filter
  lesen. Archivierte ready-Aufgaben samt `archiviert_von` sind damit per PostgREST lesbar. Die Lücke bestand schon
  vorher.
- `task_status_set` und `pruef_admin_freigeben` können eine archivierte Aufgabe auf ready setzen; nach dem
  Wiederherstellen ist sie dann sofort im Pool. Admin-Direktupdates (`updateTaskDiagnostic`) können `archiviert_*` am
  Protokoll vorbei ändern. Beides ist nur für Admins erreichbar. `task_status_set` ist geschützt und wurde nicht
  geändert.
- `tasks_pruef_version` zählt bei Archivieren und Wiederherstellen hoch. Ein offener Editor bekommt dann einen
  Versionskonflikt (`pruef_sperren`), es geht aber nichts verloren.
- Für M2: Die Datenmigration muss in der CI `request.jwt.claims` auf service_role setzen und ihre ids vorher auf
  „existiert und aktiv“ filtern (im Neuaufbau gibt es die Prod-ids nicht).
