#!/usr/bin/env node
/**
 * szenario-zuruecksetzen.mjs — entfernt, was tools/szenario-lsa.mjs fuer ein Kind angelegt hat (Paket F1, B3).
 * Grundlage ist das Protokoll des Laufs (Session-ID, Lead, Lead-Thema vorher). In einer Transaktion:
 *   1. lernpfad_protokoll: die Uebernahme-Zeilen dieser LSA (aktion 'uebernahme', neu.lsa_session_id)
 *   2. lernpfad: die Zeilen dieser LSA (quelle 'lsa', lsa_session_id) - Abbruch, wenn eine schon Belege, eine
 *      Coach-Entscheidung oder weitere Protokollzeilen hat (dann wurde mit dem Lernpfad gearbeitet)
 *   3. lsa_sessions (Antworten, Urteile, Ausgaben haengen per Cascade daran) - Abbruch bei einem Eltern-Report
 *   4. lead_themen: das gesetzte Thema wieder entfernen bzw. das vorherige wieder setzen
 * Fuer Loeschungen gibt es keine Funktion; geloescht wird direkt, nur in diesen Zeilen. Bricht ab, wenn das Kind
 * kein Testkonto ist. --dry-run zeigt jeden Schritt und rollt zurueck.
 *
 *   node tools/szenario-zuruecksetzen.mjs --dry-run --protokoll ~/szenario/batu-<kind>.json
 */
import fs from 'node:fs'
import { pathToFileURL } from 'node:url'
import { adminClaims, argumente, literal, redigieren, sqlAusfuehren, verbindung } from './szenario-lib.mjs'

export function zuruecksetzenSql(p, admin, dryRun) {
  return `${adminClaims(admin)}
do $z$
declare
  v_sess  uuid := ${literal(p.session_id)}::uuid;
  v_kind  uuid := ${literal(p.kind)}::uuid;
  v_lead  uuid := ${literal(p.lead)}::uuid;
  v_thema text := ${literal(p.thema)};
  v_vorher text := ${p.lead_thema_vorher ? literal(p.lead_thema_vorher) : 'null'};
  v_neu   boolean := ${p.lead_thema_neu ? 'true' : 'false'};
  n int;
begin
  if not coalesce((select ist_test from public.students where id = v_kind), false) then
    raise exception 'szenario: Kind ist kein Testkonto - Abbruch';
  end if;
  if not exists (select 1 from public.lsa_sessions where id = v_sess and student_id = v_kind) then
    raise notice 'OK lsa_session % gibt es nicht (mehr): nichts zu tun', v_sess;
    return;
  end if;
  if exists (select 1 from public.lernpfad l where l.student_id = v_kind and l.lsa_session_id = v_sess
              and (l.belege <> '[]'::jsonb or l.stand_coach is not null))
     or exists (select 1 from public.lernpfad_protokoll p where p.student_id = v_kind and p.aktion <> 'uebernahme') then
    raise exception 'szenario: mit dem Lernpfad wurde schon gearbeitet (Belege, Coach, Protokoll) - Abbruch';
  end if;
  if exists (select 1 from public.eltern_reports e where e.lsa_session_id = v_sess) then
    raise exception 'szenario: es gibt einen Eltern-Report zu dieser LSA - Abbruch';
  end if;

  delete from public.lernpfad_protokoll p where p.student_id = v_kind and p.aktion = 'uebernahme'
     and p.neu ->> 'lsa_session_id' = v_sess::text;
  get diagnostics n = row_count; raise notice 'LOESCHT lernpfad_protokoll: % Zeilen', n;
  delete from public.lernpfad l where l.student_id = v_kind and l.lsa_session_id = v_sess and l.quelle = 'lsa';
  get diagnostics n = row_count; raise notice 'LOESCHT lernpfad: % Zeilen', n;
  delete from public.lsa_sessions where id = v_sess;
  get diagnostics n = row_count; raise notice 'LOESCHT lsa_sessions (mit Antworten, Urteilen, Ausgaben): % Zeile', n;

  if v_neu then
    delete from public.lead_themen where lead_id = v_lead and thema_key = v_thema;
    get diagnostics n = row_count; raise notice 'LOESCHT lead_themen %: % Zeile', v_thema, n;
    if v_vorher is not null then
      perform public.lead_thema_setzen(v_lead, 'mathematik', v_vorher, 'gespraech');
      raise notice 'SCHREIBT lead_thema_setzen: wieder %', v_vorher;
    end if;
  end if;
end $z$;
${dryRun ? `do $r$ begin raise notice 'DRY-RUN: Rollback, nichts geaendert'; end $r$;\nrollback;` : ''}
`
}

function main() {
  const a = argumente(process.argv.slice(2))
  if (!a.protokoll) throw new Error('--protokoll <datei> fehlt (Ausgabe von szenario-lsa.mjs).')
  const p = JSON.parse(fs.readFileSync(a.protokoll, 'utf8'))
  for (const k of ['session_id', 'kind', 'lead', 'thema']) if (!p[k]) throw new Error(`Protokoll ohne ${k}.`)
  try {
    for (const h of sqlAusfuehren(verbindung(a.db), zuruecksetzenSql(p, a.admin, a.dryRun))) console.log(h)
  } catch (e) {
    for (const h of e.hinweise ?? []) console.log(h)
    console.error(`Abbruch: ${redigieren(e.message)}`)
    process.exit(1)
  }
  if (!a.dryRun) console.log(`Zurueckgesetzt. Protokoll ${a.protokoll} kann weg.`)
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main()
