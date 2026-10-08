#!/usr/bin/env bash
# trockenlauf-pruefen.sh — belegt nach einem Trockenlauf, dass nichts Echtes berührt wurde (Paket T1).
#
# Nur lesend über ~/bin/dbread. Kinder erscheinen ohne Namen, nur als „Kind n“ mit Tablet-Nummer.
#   1. Kopf: Datum (Berlin), Raum, Status, Testlauf
#   2. je Kind: Schritte nach art, Antworten nach Phase und Ergebnis, Ereignisse nach typ, Check-in, Abschluss
#   3. Prüfliste ok / nicht ok:
#      Testlauf gesetzt · nur Testkonten · keine XP · kein Lernpfad · keine Mastery · keine Einheit · nichts in der Akte
#      · home_quests_aktiv wieder aus (Stellschraube gilt für alle Sessions, Trockenlauf schaltet sie an)
#
# Aufruf: tools/trockenlauf-pruefen.sh <session_id>
# Exit:   0 alles ok · 1 mindestens ein „nicht ok“ · 2 Aufruf- oder Verbindungsfehler
set -euo pipefail

sid="${1:-}"
[[ "$sid" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] \
  || { echo "Aufruf: $0 <session_id (uuid)>" >&2; exit 2; }

DBREAD="${DBREAD:-$HOME/bin/dbread}"
[[ -x "$DBREAD" ]] || { echo "dbread fehlt: $DBREAD" >&2; exit 2; }

ausgabe="$("$DBREAD" -tA -F ' | ' -v sid="$sid" <<'SQL'
\set QUIET on
select 'KOPF' || ' | ' || coalesce((
  select to_char(cs.scheduled_at at time zone 'Europe/Berlin', 'DD.MM.YYYY HH24:MI') || ' | Raum ' || coalesce(cs.room, '–')
         || ' | Status ' || cs.status || ' | Testlauf ' || case when cs.testlauf then 'ja' else 'nein' end
         || ' | gestartet ' || coalesce(to_char(cs.gestartet_am at time zone 'Europe/Berlin', 'HH24:MI'), '–')
         || ' | beendet ' || coalesce(to_char(cs.beendet_am at time zone 'Europe/Berlin', 'HH24:MI'), '–')
    from public.coaching_sessions cs where cs.id = :'sid'), 'FEHLT');

-- Alle Kinder, die die Session berührt hat: gebucht oder mit Spuren in einer Session-Tabelle.
with beteiligt as (
  select student_id from public.session_students where session_id = :'sid'
  union select student_id from public.session_tablets where session_id = :'sid'
  union select student_id from public.session_schritte where session_id = :'sid'
  union select student_id from public.session_antworten where session_id = :'sid'
  union select student_id from public.session_ereignisse where session_id = :'sid' and student_id is not null
), kind as (
  select b.student_id, row_number() over (order by b.student_id) as n,
         coalesce(s.ist_test, false) as ist_test,
         (select st.tablet_nr from public.session_tablets st where st.session_id = :'sid' and st.student_id = b.student_id
           order by st.zugewiesen_am desc limit 1) as tablet_nr,
         (select ss.attendance from public.session_students ss where ss.session_id = :'sid' and ss.student_id = b.student_id) as anwesenheit
    from beteiligt b left join public.students s on s.id = b.student_id
)
select 'KIND' || ' | ' || k.n || ' | Tablet ' || coalesce(k.tablet_nr::text, '–')
       || ' | ' || case when k.ist_test then 'Testkonto' else 'ECHTES KIND' end
       || ' | Anwesenheit ' || coalesce(k.anwesenheit, 'nicht gebucht')
       || ' | Schritte: ' || coalesce((select string_agg(x.art || ' ' || x.c, ', ' order by x.art)
            from (select art, count(*) c from public.session_schritte where session_id = :'sid' and student_id = k.student_id group by art) x), '–')
       || ' | Antworten: ' || coalesce((select string_agg(x.phase || '/' || coalesce(x.ergebnis, 'offen') || ' ' || x.c, ', ' order by x.phase, x.ergebnis)
            from (select phase, ergebnis, count(*) c from public.session_antworten where session_id = :'sid' and student_id = k.student_id group by 1, 2) x), '–')
       || ' | Ereignisse: ' || coalesce((select string_agg(x.typ || ' ' || x.c, ', ' order by x.typ)
            from (select typ, count(*) c from public.session_ereignisse where session_id = :'sid' and student_id = k.student_id group by typ) x), '–')
       || ' | Check-in: ' || case when exists (select 1 from public.session_checkin c where c.session_id = :'sid' and c.student_id = k.student_id and c.kind_am is not null) then 'Kind' else '–' end
       || case when exists (select 1 from public.session_checkin c where c.session_id = :'sid' and c.student_id = k.student_id and c.coach_am is not null) then '+Coach' else '' end
       || ' | Abschluss: ' || coalesce((select concat_ws(', ',
              case when a.satz_gesagt then 'Satz gesagt' end,
              case when a.quest_termin is not null then 'Quest-Termin' end,
              case when a.exit_ergebnis is not null then 'Exit' end)
            from public.session_kind_abschluss a where a.session_id = :'sid' and a.student_id = k.student_id), '–')
  from kind k order by k.n;

-- Prüfliste. Zeitfenster für Zeilen ohne session_id: Start bis Ende (offen: jetzt) plus 10 Minuten.
with s as (
  select cs.*, coalesce(cs.gestartet_am, cs.scheduled_at) as von,
         coalesce(cs.beendet_am, now()) + interval '10 minutes' as bis
    from public.coaching_sessions cs where cs.id = :'sid'
), beteiligt as (
  select student_id from public.session_students where session_id = :'sid'
  union select student_id from public.session_tablets where session_id = :'sid'
  union select student_id from public.session_schritte where session_id = :'sid'
  union select student_id from public.session_antworten where session_id = :'sid'
  union select student_id from public.session_ereignisse where session_id = :'sid' and student_id is not null
), pruef(nr, titel, anzahl) as (
  select 1, 'Session ist als Testlauf markiert', (select count(*) from s where not s.testlauf)
  union all
  select 2, 'kein echtes Kind beteiligt (nur ist_test)',
         (select count(*) from beteiligt b left join public.students st on st.id = b.student_id where not coalesce(st.ist_test, false))
  union all
  select 3, 'keine XP gebucht (Schlüssel session:<id> oder im Zeitfenster)',
         (select count(*) from public.xp_events x, s
           where x.buchungs_schluessel = 'session:' || :'sid'
              or (x.student_id in (select student_id from beteiligt) and x.created_at between s.von and s.bis))
  union all
  select 4, 'keine Lernpfad-Belege (lernpfad_belege)',
         (select count(*) from public.lernpfad_belege where session_id = :'sid')
  union all
  select 5, 'kein Lernpfad-Protokoll (lernpfad_protokoll)',
         (select count(*) from public.lernpfad_protokoll where session_id = :'sid')
  union all
  select 6, 'keine Lernpfad-Zeile entstanden oder geändert',
         (select count(*) from public.lernpfad l, s
           where l.coach_session_id = :'sid' or l.letzte_session_id = :'sid'
              or (l.student_id in (select student_id from beteiligt) and (l.angelegt between s.von and s.bis or l.aktualisiert between s.von and s.bis)))
  union all
  select 7, 'keine Mastery-Zeile (student_competency_mastery im Zeitfenster)',
         (select count(*) from public.student_competency_mastery m, s
           where m.student_id in (select student_id from beteiligt)
             and (m.updated_at between s.von and s.bis or m.mastered_at between s.von and s.bis))
  union all
  select 8, 'keine Einheit verbraucht (verbrauchende Anwesenheit außerhalb eines Testlaufs)',
         (select count(*) from public.session_students ss, s
           where ss.session_id = :'sid' and public.einheit_verbraucht(ss.attendance) and not s.testlauf)
  union all
  select 9, 'nichts in die Akte übernommen (session_kind_abschluss.in_akte_am)',
         (select count(*) from public.session_kind_abschluss where session_id = :'sid' and in_akte_am is not null)
  union all
  select 10, 'home_quests_aktiv ist wieder aus',
         (select count(*) from public.session_einstellungen
           where schluessel = 'home_quests_aktiv' and wert is distinct from 'false'::jsonb)
)
select 'PRUEF' || ' | ' || case when (select count(*) from s) = 0 then 'nicht ok' when anzahl = 0 then 'ok' else 'nicht ok' end
       || ' | ' || nr || '. ' || titel || case when anzahl > 0 and nr > 1 then ' (' || anzahl || ' Zeilen)' else '' end
  from pruef order by nr;
SQL
)" || { echo "dbread fehlgeschlagen" >&2; exit 2; }

kopf="$(grep '^KOPF' <<<"$ausgabe" | cut -d'|' -f2- | sed 's/^ //')"
if [[ "$kopf" == "FEHLT" ]]; then
  echo "Session $sid gibt es nicht." >&2
  exit 2
fi

echo "Session $sid"
echo "  $kopf"
echo
echo "Kinder"
kinder="$(grep '^KIND' <<<"$ausgabe" || true)"
if [[ -z "$kinder" ]]; then
  echo "  (keines gebucht)"
else
  while IFS= read -r z; do
    IFS='|' read -r _ n rest <<<"$z"
    echo "  Kind${n%% }:"
    tr '|' '\n' <<<"$rest" | sed -E 's/^ +/    - /; s/ +$//'
  done <<<"$kinder"
fi
echo
echo "Prüfliste"
pruef="$(grep '^PRUEF' <<<"$ausgabe" | cut -d'|' -f2- | sed -E 's/^ //; s/ \| /  /')"
sed 's/^/  /' <<<"$pruef"

if grep -q '^nicht ok' <<<"$pruef"; then
  echo
  echo "Ergebnis: nicht ok"
  exit 1
fi
echo
echo "Ergebnis: ok"
