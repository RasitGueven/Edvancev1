-- U4 Abnahme per dbread (als Admin über request.jwt.claims; nichts wird geschrieben).
select set_config('request.jwt.claims', '{"sub":"' || (select id from profiles where role = 'admin' order by created_at limit 1) || '","role":"authenticated"}', false) \g /dev/null
\echo '--- b) MSA-Zeile = inhalte_lsa_pruefziel (Kopfzeile)'
select komp_bereit, komp_teil, komp_offen, fehlende_texte, aufgaben_zu_pruefen, ampel from inhalte_lsa_pruefziel('msa_zp10') where bereich is null;
\echo '--- c) „In Lenas Liste“: je Kompetenz aller Themen offene_task_ids = task_ids der Liste (p_skill filtert nur diese Liste, pgTAP 5f)'
with k as (select distinct x.skill_key, x.offene_task_ids
             from inhalte_lsa_themen() t cross join lateral inhalte_lsa_thema(t.thema_key) x
            where not x.erfuellt and x.zu_pruefen > 0),
l as (select skill_key, task_ids from pruef_ziel_liste() where abschnitt = 'gezielt')
select count(*) kompetenzen,
       count(*) filter (where array(select unnest(l.task_ids) order by 1) = array(select unnest(k.offene_task_ids) order by 1)) gleich,
       count(*) filter (where l.skill_key is null) nicht_in_liste
  from k left join l using (skill_key);
\echo '--- d) Lena sieht unter MSA die Kompetenzen ohne Paket (U0: 20 Skills, 59 Aufgaben)'
select count(*) filter (where hebel_pakete = 0) skills_ohne_paket,
       sum(cardinality(task_ids)) filter (where hebel_pakete = 0) aufgaben_ohne_paket,
       count(*) skills_gesamt
  from pruef_ziel_liste(p_pruefziel => 'msa_zp10') where abschnitt = 'gezielt';
\echo '--- f) Reihe 1: Zahlen aus bauformen und studio_sequenz, Sessions'
select r.sessions, r.bf_freigegeben + r.bf_zur_freigabe + r.bf_rueckfrage + r.bf_offen bauformen_funktion,
       (select count(*) from bauformen b where b.reihe = r.reihe) bauformen_tabelle, r.vid_gesamt, r.vid_freigegeben,
       (select count(*) from studio_sequenz q where q.status = 'freigegeben') sequenzen_freigegeben,
       (select count(*) from inhalte_session_reihe(r.reihe) s where s.nr is not null) session_zeilen
  from inhalte_session_reihen() r where r.reihe = 'quadratische_funktionen_gleichungen';
\echo '--- g) Themen ohne Reihe enthalten kein Thema mit Kernideen-Bauform einer Reihe'
select count(*) treffer from inhalte_themen_ohne_reihe() o
 where o.thema_key in (select st.thema_key from bauformen b join skill_thema st using (skill_key) where b.kernidee_key is not null);
\echo '--- h) Laufzeit: Speicher frisch?'
select inhalte_cache_frisch() frisch, (select veraltet from lsa_paket_cache_stand) paket_speicher_veraltet;
