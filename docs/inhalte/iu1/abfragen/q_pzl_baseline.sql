-- Regressionsbasis: pruef_ziel_liste() ohne neue Parameter, als Admin. Vorher (U0) und nachher (U1, U4 e) gleich.
select set_config('request.jwt.claims', '{"sub":"' || (select id from profiles where role = 'admin' order by created_at limit 1) || '","role":"authenticated"}', false) \g /dev/null
select md5(string_agg(row(z.*)::text, E'\n' order by z.abschnitt, z.sort)) md5, count(*) zeilen,
       sum(cardinality(task_ids)) ids, sum(rest) rest
  from pruef_ziel_liste() z;
