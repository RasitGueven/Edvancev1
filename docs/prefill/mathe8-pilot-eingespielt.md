# Pilot mathe8-pilot — eingespielt am 30.09.2026

Datei `supabase/migrations/20260930150000_prefill_mathe8_pilot.sql` (Commit `0c61ed7`, md5 `339d99a25e89987761fa7482f5c02cb8`),
einmalig nach Rasits Muster eingespielt:

    dbcheck (current_database() = postgres)
    && Version 20260930150000 nicht in supabase_migrations.schema_migrations
    && psql -v ON_ERROR_STOP=1 -1 -f supabase/migrations/20260930150000_prefill_mathe8_pilot.sql
    && insert into supabase_migrations.schema_migrations(version,name) values ('20260930150000','prefill_mathe8_pilot')
    && tools/schema-snapshot.sh

Versionsausnahme von der Regel aus #180: Die Datei muss nach `20260930140000_tasks_vorbefuellt` liegen, das vorab mit
Zukunftszeit vergeben wurde (Entscheidung Rasit, Variante A).

## Unmittelbar vorher (nur lesend)

Prod-Abgleich neu gezogen und mit `mathe8-pilot-prod-abgleich.md` verglichen: identisch (72 Zeilen, alle Felder leer,
alle 18 Aufgaben `draft`, keine Beanstandung, kein Kennzeichen) — kein HALT.

## Ergebnis

| Schritt | Ergebnis |
|---|---|
| Einspielen | 72 Anweisungen, je genau 1 Zeile (72 Zeilen) |
| History | `20260930150000 prefill_mathe8_pilot` eingetragen |
| (a) Prod gegen CSV | 72/72 Felder gesetzt wie geplant (Wert + Kennzeichen-Art) |
| (b) Status | alle 18 weiterhin `draft`, `reviewed_by` nirgends gesetzt, 18/18 mit Kennzeichen |
| (c) zweiter Lauf | alle 72 WHERE-Bedingungen (Compare-and-set) als `count(*)` gelesen: Summe 0 — ein zweiter Lauf aendert nichts |
| Schema-Snapshot | Pilot aendert kein Schema. Der Abzug zeigte aber `public.fortschritt(uuid)` aus S3 (`20260930113231_akte_fortschritt`), das eine andere Session eingespielt hat und dessen Datei nicht in diesem Branch liegt — **nicht** hier committet (CI wuerde sonst eine Funktion ohne Migration erwarten); gehoert in den S3-Branch. |
