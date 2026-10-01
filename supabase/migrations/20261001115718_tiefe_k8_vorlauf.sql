-- K8-/K9-Vorlauf, Migration 1 von 3 — Fundamenttiefe auf 1..12 anheben.
--
-- Einspiel-Reihenfolge: diese Datei, dann <...>_substrat_k8_vorlauf.sql, dann
-- <...>_aufgaben_k8_vorlauf.sql. Die Themen-Laeufe (Lineare Funktionen, Zins,
-- Kreis) brauchen diese Datei vor ihrer Phase A.
--
-- ----------------------------------------------------------------------------
-- Befund (Live-DB, 2026-10-01, nur gelesen)
-- ----------------------------------------------------------------------------
-- skills_fundament_tiefe_check erlaubt 1..8. skill_kante_tiefe_guard verlangt
-- eine ECHT flachere Voraussetzung. Vier Knoten liegen schon an der Decke:
-- prozent_veraenderung, gleichung_modellieren, term_binom_faktorisieren,
-- term_binom_gemischt (alle 8). zins_eszins braeuchte 9 und wuerde abgewiesen.
-- Der Binom-PR (#150) hat das im Kopf von 20260830120000 vermerkt.
--
-- Wer liest fundament_tiefe (pg_proc, prosrc ilike '%fundament_tiefe%')?
--   skill_kante_tiefe_guard  vergleicht nur relativ:
--                            v_tiefe_voraussetzt >= v_tiefe_skill -> Fehler.
--   lsa_select_next_core     sortiert nur: order by fundament_tiefe desc
--                            (Abstieg, Schritt 3; neues Blatt, Schritt 4).
--                            Die Schleifengrenze (v_iter > 100) ist eine
--                            Iterationsbremse, keine Tiefe.
-- Keine Funktion nimmt 8 als Konstante an (keine Normierung auf 8, keine
-- Schleife bis 8, kein "8 = oben"). Views, Mat-Views und Policies lesen die
-- Spalte nicht. Damit ist die Grenze ein reiner CHECK.
--
-- Warum 12 und nicht "offen": die Tiefe bleibt eine Graphposition mit Grenze,
-- damit ein Tippfehler (80 statt 8) weiter abgewiesen wird. 12 laesst ueber der
-- heutigen Decke vier Stufen — genug fuer die K8-/K9-Themen dieser Welle.
--
-- Prueffrage vor dem Einspielen (gegen die Live-DB, 2026-10-01):
--   max(fundament_tiefe) = 8, 63 Kanten, 0 Kanten verletzen den Guard.
-- Der neue CHECK ist damit sofort erfuellt; ADD CONSTRAINT validiert alle
-- 43 Zeilen beim Einspielen.
--
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne
-- --single-transaction. Zwischen DROP und ADD duerfte kein Abbruch liegen —
-- sonst stuende skills kurz ohne jede Tiefengrenze da.

begin;

alter table public.skills
  drop constraint skills_fundament_tiefe_check;

alter table public.skills
  add constraint skills_fundament_tiefe_check
  check (fundament_tiefe >= 1 and fundament_tiefe <= 12);

comment on table public.skills is
  'Die Fundament-Skills der LSA-Auswahl. fundament_tiefe = Stufe im Fundament '
  '(1 traegt alles, erlaubt 1..12), nicht Schwierigkeit und keine Klassenstufe.';

commit;
