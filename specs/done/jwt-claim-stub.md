---
id: jwt-claim-stub
type: code
repo: edvancev1
branch: spec/jwt-claim-stub
depends_on: []
gates:
  - bash tools/neuaufbau-test.sh
  - psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/fehlbild_auswertung.PRUEFUNG.sql
  - psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/20260723120000_a17_platz_adaptiv_uebernahme.E2E.sql
---

## Ziel

Zwei Stellen im Repo setzen die Identität für Tests unterschiedlich. Eine von beiden wirkt nicht — welche, ist unbekannt. Das ist zu messen und zu beheben.

Solange das offen ist, weiss niemand, ob die Berechtigungsprüfungen in den E2E-Skripten tatsächlich etwas prüfen oder nur grün leuchten.

## Kontext

`supabase/test-grundlage.sql` definiert den Stub:

```sql
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
```

Gelesen wird `request.jwt.claim.sub` — **Einzahl, mit Punkt**.

`supabase/checks/20260723120000_a17_platz_adaptiv_uebernahme.E2E.sql` setzt an elf Stellen:

```sql
perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
```

Gesetzt wird `request.jwt.claims` — **Mehrzahl, als JSON**.

Das sind zwei verschiedene Einstellungen. `supabase/checks/fehlbild_auswertung.PRUEFUNG.sql` nutzt die Einzahlform und funktioniert nachweislich.

**Warum das nicht harmlos ist:** `lsa_may_act_for` gibt bei fehlender Identität nicht `false` zurück, sondern `null` — `get_my_role()` findet keine Zeile, `get_my_student_id()` ebenso. Das übliche Muster `if not lsa_may_act_for(...) then raise` feuert bei `null` **nicht**, weil `not null` wiederum `null` ist. Greift A17s Identitätswechsel nicht, laufen dort alle Berechtigungsprüfungen ins Leere, ohne dass ein Test rot wird.

## Schritt 1 — Messen, bevor etwas geändert wird

Gegen `edvance_neuaufbau` feststellen, welche Schreibweise `auth.uid()` erreicht: beide Einstellungen setzen, `auth.uid()` abfragen, Ergebnis festhalten.

Dann in A17: Liefert `auth.uid()` unmittelbar nach dem ersten `set_config` den erwarteten Wert oder `null`?

**Das Messergebnis kommt in den Bericht, auch wenn es der Vermutung widerspricht.** Ist der Verdacht falsch und A17 funktioniert, endet der Lauf hier mit einem Bericht — dann ist nichts zu tun.

## Schritt 2 — Stub an die Wirklichkeit angleichen

Bestätigt sich der Verdacht, wird **der Stub** angepasst, nicht A17. Begründung: In der echten Supabase-Umgebung ist die JSON-Form die gebräuchliche; ein Stub, der sie nicht versteht, weicht von Produktion ab. Und `fehlbild_auswertung.PRUEFUNG.sql` nutzt die Einzahlform — beide müssen weiter funktionieren.

Also beide Formen unterstützen, Einzahl zuerst:

```sql
create or replace function auth.uid() returns uuid language sql stable as $$
  select coalesce(
           nullif(current_setting('request.jwt.claim.sub', true), ''),
           nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
         )::uuid
$$;
```

Für `auth.role()` dasselbe prüfen — sie liest `request.jwt.claim.role` und hat dieselbe Schwäche.

**Vorher nachsehen, ob `test-grundlage.sql` an weiteren Stellen eingebunden wird** als in `neuaufbau-test.sh`, `schema-snapshot.sh` und `.github/workflows/schema.yml`. Änderungen dort wirken überall.

## Schritt 3 — Negativkontrolle

Ohne sie ist die Reparatur so unbelegt wie der Zustand vorher.

In `supabase/checks/` ein kleines Prüfskript `jwt_identitaet.PRUEFUNG.sql` — ohne Zeitstempel im Namen, in `begin; … rollback;`:

| # | Fall | Erwartung |
|---|---|---|
| J1 | `request.jwt.claim.sub` gesetzt | `auth.uid()` liefert genau diesen Wert |
| J2 | `request.jwt.claims` als JSON gesetzt | `auth.uid()` liefert den `sub` daraus |
| J3 | nichts gesetzt | `auth.uid()` ist `null` |
| J4 | beides gesetzt, verschiedene Werte | die Einzahlform gewinnt (dokumentierter Vorrang) |

J3 ist die eigentliche Kontrolle: Sie schlägt an, wenn jemand einen festen Wert einbaut.

## Akzeptanz

- Messergebnis aus Schritt 1 im Bericht, mit den tatsächlich beobachteten Werten
- Falls repariert: beide Schreibweisen funktionieren, belegt durch `jwt_identitaet.PRUEFUNG.sql`
- `fehlbild_auswertung.PRUEFUNG.sql` läuft weiterhin grün (Gate 2)
- A17 läuft weiterhin grün (Gate 3)
- `docs/jwt-identitaet-befund.md`: was gemessen wurde, was geändert wurde, und **welche Zusicherungen in A17 bisher wirkungslos waren** — Zeilennummern, damit nachvollziehbar ist, was seit dem 23.07. ungeprüft blieb

## Nicht-Ziele

- **Keine Änderung an A17s Logik.** Wenn dort nach der Reparatur etwas rot wird, ist das ein Fund und gehört in den Bericht — nicht weggeräumt.
- Keine Änderung an `lsa_may_act_for`, `get_my_role` oder `get_my_student_id`
- Keine Vereinheitlichung der `raise`-Muster in den RPCs. Dass AF2 sperrt und `lsa_finish` durchlässt, ist bekannt und ein eigener Punkt.
- Keine Migration — `test-grundlage.sql` ist Testgerüst, kein Schema
- Kein Zugriff auf Produktion
- Kein `src/lib/**`

## Wenn A17 nach der Reparatur rot wird

Das ist der wahrscheinliche Fall und **kein Fehlschlag dieses Laufs**. Es hiesse, dass A17 Zusicherungen enthält, die nur deshalb hielten, weil die Identität nie gesetzt war.

Dann: Lauf beenden, Befund berichten, die roten Stellen mit Zeilennummer und erwartetem Verhalten auflisten. Nicht selbst reparieren — was A17 prüfen soll, ist eine fachliche Frage.
