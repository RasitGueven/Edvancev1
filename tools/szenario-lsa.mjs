#!/usr/bin/env node
/**
 * szenario-lsa.mjs — spielt das LSA-Muster eines Szenarios (docs/szenario/batu.json) fuer genau ein Testkonto ein
 * (Paket F1, Umfang B3). Ueber dieselben Funktionen wie eine echte LSA, nicht als Testlauf:
 *   1. lead_thema_setzen  (Thema des Musters als aktuelles Schulthema des Leads)
 *   2. lsa_start          (adaptiv, Start um start_vor_minuten zurueckgelegt, testlauf = false)
 *   3. lsa_submit         je Item, das der Server ausgibt, mit der Antwort nach Muster
 *   4. lsa_finish         (Report: lsa_sessions.result_summary)
 *   5. lernpfad_aus_lsa   (Lernpfad aus den Urteilen)
 * Den Pool bestimmt der Server; fuer Testkonten gilt seit F1 auch ohne Testlauf der Testlauf-Pool
 * (Migration 20261011140200). Kommt ein Item zu einem Skill ausserhalb des Musters, endet die LSA mit lsa_finish.
 *
 * Alles laeuft in EINER Transaktion als Admin (Claims transaktionslokal). --dry-run zeigt jeden Schreibschritt
 * und rollt am Ende zurueck. Bricht ab, wenn das Kind kein Testkonto ist oder schon LSA/Lernpfad hat. Gibt es
 * die Szenario-LSA schon (gleiches Thema, abgeschlossen), tut ein zweiter Lauf nichts.
 *
 *   cd ~/Edvancev1 && node ../Edvancev1-f1/tools/szenario-lsa.mjs --dry-run
 *   node tools/szenario-lsa.mjs --db 'host=/tmp/... dbname=...' --kind <uuid> --admin <uuid> --protokoll <datei>
 *
 * Ergebnis (Session-ID, ob das Lead-Thema neu war) geht nach --protokoll bzw. ~/szenario/<szenario>-<kind>.json;
 * tools/szenario-zuruecksetzen.mjs liest es.
 */
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { pathToFileURL } from 'node:url'
import { adminClaims, argumente, literal, redigieren, sqlAusfuehren, verbindung } from './szenario-lib.mjs'

export function laufSql(muster, kind, admin, dryRun) {
  const m = literal(JSON.stringify(muster))
  return `${adminClaims(admin)}
do $lauf$
declare
  m        jsonb := ${m}::jsonb;
  v_kind   uuid := ${literal(kind)}::uuid;
  v_lead   uuid;
  v_thema  text := m -> 'lsa' ->> 'thema_key';
  v_fach   text := m -> 'lsa' ->> 'subject';
  v_vorher text;
  v_neu    boolean;
  v_t0     timestamptz := now() - ((m -> 'lsa' ->> 'start_vor_minuten')::int * interval '1 minute');
  v_schritt interval := ((m -> 'lsa' ->> 'sekunden_je_antwort')::int * interval '1 second');
  v_start  jsonb;
  v_sess   uuid;
  v_task   uuid;
  t        public.tasks;
  s        public.task_solutions;
  v_probe  int;
  v_art    text;
  v_fb     text;
  v_key    text;
  v_wert   text;
  v_resp   jsonb;
  v_n      int := 0;
  v_ende   text := 'kein weiteres Item';
  r        record;
begin
  if not exists (select 1 from public.students where id = v_kind) then
    raise exception 'szenario: Kind % nicht gefunden', v_kind;
  end if;
  if not (select ist_test from public.students where id = v_kind) then
    raise exception 'szenario: Kind ist kein Testkonto (students.ist_test) - Abbruch';
  end if;

  -- Schon eingespielt? Dann nichts tun (zweiter Lauf).
  select ls.id into v_sess from public.lsa_sessions ls
   where ls.student_id = v_kind and ls.thema_key = v_thema and ls.status = 'completed' and not ls.testlauf
   order by ls.completed_at desc limit 1;
  if v_sess is not null then
    raise notice 'BESTEHT lsa_session % (Thema %): nichts zu tun', v_sess, v_thema;
    raise notice 'SZENARIO-ERGEBNIS %', jsonb_build_object('session_id', v_sess, 'schon_da', true);
    return;
  end if;
  if exists (select 1 from public.lsa_sessions where student_id = v_kind) then
    raise exception 'szenario: Kind hat schon eine andere LSA - Abbruch (erst zuruecksetzen)';
  end if;
  if exists (select 1 from public.lernpfad where student_id = v_kind) then
    raise exception 'szenario: Kind hat schon einen Lernpfad - Abbruch';
  end if;

  -- 1. Schulthema des Leads
  v_lead := public.lsa_lead_von_schueler(v_kind);
  if v_lead is null then raise exception 'szenario: Kind hat keinen Lead'; end if;
  select lt.thema_key into v_vorher from public.lead_themen lt
   where lt.lead_id = v_lead and lt.status = 'aktuell' and lower(lt.fach) = lower(v_fach);
  v_neu := v_vorher is distinct from v_thema;
  if v_neu then
    perform public.lead_thema_setzen(v_lead, lower(v_fach), v_thema, 'gespraech');
    raise notice 'SCHREIBT lead_thema_setzen(Lead, %, %) (vorher: %)', lower(v_fach), v_thema, coalesce(v_vorher, 'keins');
  else
    raise notice 'OK Lead-Thema ist schon %', v_thema;
  end if;

  -- 2. Start
  v_start := public.lsa_start(v_kind, (m -> 'lsa' ->> 'grade')::int, v_fach, 'adaptiv', v_t0, false);
  v_sess := (v_start ->> 'session_id')::uuid;
  raise notice 'SCHREIBT lsa_start -> Session % (testlauf %, Start %)', v_sess, v_start ->> 'testlauf', v_t0;

  -- 3. Antworten nach Muster
  loop
    select a.task_id into v_task from public.lsa_ausgegeben a
     where a.session_id = v_sess
       and not exists (select 1 from public.lsa_responses x where x.session_id = v_sess and x.task_id = a.task_id)
     limit 1;
    if v_task is null then exit; end if;
    select * into t from public.tasks where id = v_task;
    if not (m -> 'skills') ? t.skill_key then
      v_ende := 'Item zu ' || coalesce(t.skill_key, '?') || ' (nicht im Muster)';
      exit;
    end if;
    select count(distinct x.task_id) into v_probe from public.lsa_responses x join public.tasks y on y.id = x.task_id
     where x.session_id = v_sess and y.skill_key = t.skill_key;
    v_art := m -> 'skills' -> t.skill_key -> 'proben' ->> v_probe;
    if v_art is null then
      raise exception 'szenario: Muster hat fuer % keine Probe %', t.skill_key, v_probe + 1;
    end if;
    v_fb := m -> 'skills' -> t.skill_key ->> 'fehlbild';
    select * into s from public.task_solutions where task_id = v_task;

    if t.input_type = 'MULTI_PART' then
      -- je Teil: richtig = erste Loesung, falsch = Teil-known_error bzw. Zahl + 1 (ohne Fehlbild)
      select jsonb_object_agg(p ->> 'nr', jsonb_build_object('text',
               case when v_art = 'richtig' then s.correct_answers -> (p ->> 'nr') ->> 0
                    else coalesce((select k from jsonb_object_keys(s.acceptance -> (p ->> 'nr') -> 'known_errors') k
                                    order by (s.acceptance -> (p ->> 'nr') -> 'known_errors' ->> k) = v_fb desc, k limit 1),
                                  (replace(s.correct_answers -> (p ->> 'nr') ->> 0, ',', '.')::numeric + 1)::text) end))
        into v_resp from jsonb_array_elements(t.parts) e(p);
      v_wert := v_resp::text;
    else
      if v_art = 'richtig' then
        v_wert := s.correct_answers ->> 0;
      else
        select k into v_key from jsonb_object_keys(s.acceptance -> 'known_errors') k
         order by (s.acceptance -> 'known_errors' ->> k) = v_fb desc, k limit 1;
        v_wert := coalesce(v_key, (replace(s.correct_answers ->> 0, ',', '.')::numeric + 1)::text);
        if v_key is null then raise notice 'HINWEIS % ohne known_errors: falsch ohne Fehlbild', t.source_ref; end if;
      end if;
      v_resp := jsonb_build_object('text', v_wert);
    end if;

    v_n := v_n + 1;
    perform public.lsa_submit(v_sess, v_task, v_resp, (m -> 'lsa' ->> 'sekunden_je_antwort')::int * 1000, v_t0 + v_n * v_schritt);
    raise notice 'SCHREIBT lsa_submit #% % (%) Probe % %: % -> %', v_n, t.skill_key, t.source_ref, v_probe + 1, v_art, v_wert,
      (select u.zustand || case when u.offen then ' (offen)' else '' end from public.lsa_skill_urteil u
        where u.session_id = v_sess and u.skill_key = t.skill_key);
  end loop;

  -- 4. Report, 5. Lernpfad
  perform public.lsa_finish(v_sess);
  raise notice 'SCHREIBT lsa_finish (%): % Antworten', v_ende, v_n;
  raise notice 'SCHREIBT lernpfad_aus_lsa -> %', public.lernpfad_aus_lsa(v_kind);

  for r in select u.skill_key, u.zustand, u.belegt_direkt from public.lsa_skill_urteil u where u.session_id = v_sess
              and u.zustand <> 'ungeprueft'
            order by u.belegt_direkt desc, u.skill_key loop
    raise notice 'URTEIL % % %', r.skill_key, r.zustand, case when r.belegt_direkt then '' else '(mitbelegt)' end;
  end loop;
  raise notice 'URTEIL ungeprueft (Themenraum, nicht in den Lernpfad): %',
    (select count(*) from public.lsa_skill_urteil u where u.session_id = v_sess and u.zustand = 'ungeprueft');
  for r in select l.skill_key, l.stand_system from public.lernpfad l where l.student_id = v_kind order by l.stand_system, l.skill_key loop
    raise notice 'LERNPFAD % %', r.skill_key, r.stand_system;
  end loop;
  raise notice 'SZENARIO-ERGEBNIS %', jsonb_build_object('session_id', v_sess, 'kind', v_kind, 'lead', v_lead,
    'lead_thema_vorher', v_vorher, 'lead_thema_neu', v_neu, 'thema', v_thema, 'antworten', v_n, 'schon_da', false);
end $lauf$;
${dryRun ? `do $r$ begin raise notice 'DRY-RUN: Rollback, nichts geschrieben'; end $r$;\nrollback;` : ''}
`
}

function main() {
  const a = argumente(process.argv.slice(2))
  const muster = JSON.parse(fs.readFileSync(path.resolve(path.dirname(new URL(import.meta.url).pathname), '..', a.muster), 'utf8'))
  const kind = a.kind ?? muster.kind?.student_id
  if (!kind) throw new Error('Kein Kind: --kind oder kind.student_id im Muster.')
  const conn = verbindung(a.db)
  let hinweise
  try {
    hinweise = sqlAusfuehren(conn, laufSql(muster, kind, a.admin, a.dryRun))
  } catch (e) {
    for (const h of e.hinweise ?? []) console.log(h)
    console.error(`Abbruch: ${redigieren(e.message)}`)
    process.exit(1)
  }
  for (const h of hinweise) console.log(h)
  const erg = hinweise.find((h) => h.startsWith('SZENARIO-ERGEBNIS '))
  if (!a.dryRun && erg && !JSON.parse(erg.slice('SZENARIO-ERGEBNIS '.length)).schon_da) {
    const ziel = a.protokoll ?? path.join(os.homedir(), 'szenario', `${path.basename(a.muster, '.json')}-${kind}.json`)
    fs.mkdirSync(path.dirname(ziel), { recursive: true })
    fs.writeFileSync(ziel, `${erg.slice('SZENARIO-ERGEBNIS '.length)}\n`, { mode: 0o600 })
    console.log(`Protokoll: ${ziel}`)
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
