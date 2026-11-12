-- Q07 · Abschnitt 3a/3b: je Variante (2, 3, 4 Texte + 1 Reserve) notwendige Aufgaben nach Herkunft, Skills mit zu wenig Texten
-- braucht: msa_basis.sql soll.sql
\set QUIET on
select v.n texte,
       (select count(*) from menge) skills,
       (select count(*) from notwendig w where w.n = v.n) notwendig,
       (select count(*) from notwendig w where w.n = v.n and w.rolle = 'regel') davon_regel,
       (select count(*) from notwendig w where w.n = v.n and w.rolle = 'reserve') davon_reserve,
       (select count(*) from notwendig w where w.n = v.n and w.rang = 1) schon_frei,
       (select count(*) from notwendig w where w.n = v.n and w.rang = 2) lena_passt_offen,
       (select count(*) from notwendig w where w.n = v.n and w.rang in (3, 4)) lena_muss_pruefen,
       (select count(*) from notwendig w where w.n = v.n and w.rang in (3, 4) and w.rolle = 'regel') pruefen_ohne_reserve,
       (select count(*) from je_skill j where j.n = v.n and j.texte_moeglich < v.n) skills_zu_wenig_texte,
       (select count(*) from je_skill j where j.n = v.n and j.texte_moeglich = v.n) skills_ohne_reserve,
       (select count(*) from je_skill j where j.n = v.n and j.texte_ohne_mc = 0) skills_ohne_nicht_mc,
       (select coalesce(sum(greatest(v.n - j.texte_moeglich, 0)), 0) from je_skill j where j.n = v.n) texte_neu_schreiben
  from var v order by 1;
