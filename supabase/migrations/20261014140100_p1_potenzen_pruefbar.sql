-- P1 · M1: potenzen für Lena prüfbar.
--
-- 1. Die 13 Beanstandungen an potenzen sind ein Testrest aus dem Prüfblock der A20-Migration
--    20260723150000_a20_review_und_labels.sql (Punkt 2: lena_beanstande_muster(…, 'fehlbild_falsch', 'Probe') mit
--    Admin 35e4f9ac-…). Der Block sollte zurückrollen, lief aber ohne begin/rollback durch. Sie gehen zurück auf
--    draft, und zwar nur dort, wo die letzte task_reviews-Zeile genau diese Probe ist (Kategorie, Notiz, Prüfer,
--    Zeitstempel). Weg: task_status_set(…, 'draft') — erlaubt beanstandet → draft und räumt task_pruefung_ausgang;
--    pruef_rueckgaengig scheitert selbst an pruef_lena_sperren (team_beanstandet). task_reviews bleibt als Historie.
-- 2. potenzen hat keine skill_thema-Zeile → pruef_ausschluss = 'ohne_fertigkeit' für alle 24 Aufgaben (kein
--    Testlauf-Pool, nicht in pruef_board). Entscheidung Rasit 14.10.2026: Thema rationale_zahlen (klasse_herkunft 7,
--    Nachbarn vorzeichen_*). Batus Abstieg läuft über skill_kante/thema_einstieg und ist davon nicht berührt.
--
-- Das Pilot-Flag für potenzen setzt M2 (20261014140200). Idempotent; fehlen Aufgaben, Skill oder Thema
-- (CI-Neuaufbau), passiert nichts. Kein begin/commit: mig klammert mit psql -1.

do $p1m1$
declare
  v_n integer := 0;
  r record;
begin
  -- task_status_set lässt nur Admin oder Systemaufruf durch. In Prod läuft die Migration als postgres ohne JWT
  -- (Systemaufruf); in der CI-Grundlage fällt auth.role() auf 'anon' zurück. Gilt nur bis zum Transaktionsende.
  perform set_config('request.jwt.claim.role', 'service_role', true);

  for r in
    select t.id
      from public.tasks t
      join lateral (select rv.kategorie, rv.notiz, rv.geprueft_von, rv.geprueft_am
                      from public.task_reviews rv
                     where rv.task_id = t.id
                     order by rv.geprueft_am desc nulls last
                     limit 1) l on true
     where t.skill_key = 'potenzen'
       and t.status = 'beanstandet'
       and l.kategorie = 'fehlbild_falsch'
       and l.notiz = 'Probe'
       and l.geprueft_von = '35e4f9ac-d9aa-421c-8ba8-3948b1575f41'::uuid
       and l.geprueft_am = '2026-07-24 06:48:02.349088+00'::timestamptz
     order by t.id
  loop
    perform public.task_status_set(r.id, 'draft');
    v_n := v_n + 1;
  end loop;
  raise notice 'p1_m1: % Probe-Beanstandung(en) zurueck auf draft', v_n;

  insert into public.skill_thema (skill_key, thema_key)
  select 'potenzen', 'rationale_zahlen'
   where exists (select 1 from public.skills where skill_key = 'potenzen')
     and exists (select 1 from public.themen where thema_key = 'rationale_zahlen')
  on conflict (skill_key) do nothing;
  get diagnostics v_n = row_count;
  raise notice 'p1_m1: skill_thema potenzen -> rationale_zahlen, % Zeile(n)', v_n;
end $p1m1$;
