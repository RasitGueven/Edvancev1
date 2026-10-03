# Einspielen – Kachel „Inhalte“ nach Themen (W4)

Aus dem Worktree `~/wt/inhalte-themen` (oder nach dem Merge aus `dev`), in
dieser Reihenfolge. Beide Migrationen sind lokal gegen eine frische Wegwerf-DB
aus allen Migrationen eingespielt. `supabase/checks/skill_thema.PRUEFUNG.sql`
lief dort grün (T1–T5).

## 1. Schema

```bash
mig 20261003104615 skill_thema_schema && dbread -c "select to_regclass('public.skill_thema') as tabelle, (select relrowsecurity from pg_class where relname = 'skill_thema') as rls, (select count(*) from pg_policies where tablename = 'skill_thema') as policies, to_regprocedure('public.freigabe_thema(text,integer)') as rpc"
```

Erwartet: `skill_thema | t | 1 | freigabe_thema(text,integer)`.

## 2. Daten

```bash
mig 20261003104647 skill_thema_daten && dbread -c "select (select count(*) from skill_thema) as zugeordnet, (select string_agg(s.skill_key, ',') from skills s left join skill_thema st using (skill_key) where st.skill_key is null) as ohne"
```

Erwartet: `58 | potenzen`. Sind inzwischen Knoten aus `feat/k8-rest` oder
`feat/k9-rest` in Prod, stehen sie hier mit unter `ohne`. Dafür gibt es nach
„eingespielt“ eine Nachtrag-Migration.

## 3. Danach

```bash
bash tools/schema-snapshot.sh   # sollte keinen Diff gegen den Stand im PR zeigen
```

Bis auf die Kopfzeile „Dumped from database version“ ist der Abzug im PR aus
der Wegwerf-DB erzeugt.
