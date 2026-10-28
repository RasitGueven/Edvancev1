-- Reihe 1 · A6: Fehlbild-Schluessel, die beim Schreiben der Bauformen dazukamen (Auftrag A6.2; die Grundliste kam in
-- A2), und eine Figur-Bedingung fuer aufgabe_ziehbar.
--
-- 1) fehlbild_labels: neue qf_-Schluessel (Upsert ohne Ueberschreiben).
-- 2) aufgabe_ziehbar: eine Instanz mit Figur (task_figures, z. B. KO-1) ist erst ziehbar, wenn die Figur hochgeladen
--    ist (svg_hash gesetzt, scripts/figures/upload_figures.py). Sonst saehe das Kind die Aufgabe ohne Bild. Wie A3 es
--    fuer die Optionen der Graph-Auswahl schon verlangt. Sonst unveraendert.
--
-- Pruefabfrage: select count(*) from fehlbild_labels where slug in ('qf_binom_mittelglied_einfach',
--   'qf_binom_k_nicht_quadriert', 'qf_binom_b_statt_halb', 'qf_binom_c_statt_wurzel', 'qf_ausklammern_vorzeichen',
--   'qf_ausklammern_nicht_geteilt', 'qf_quadrat_als_verdopplung', 'qf_koordinate_vorzeichen');   vorher 0  nachher 8
insert into public.fehlbild_labels (slug, klartext, familie) values
  ('qf_binom_mittelglied_einfach', 'Nimmt beim Quadrat einer Summe d·x statt 2·d·x als mittleres Glied.', 'klammern'),
  ('qf_binom_k_nicht_quadriert', 'Quadriert beim Binom die Zahl vor x nicht mit: k·x² statt k²·x².', 'klammern'),
  ('qf_binom_b_statt_halb', 'Setzt beim Zurückschreiben in ein Quadrat die ganze Zahl vor x statt der Hälfte ein.', 'klammern'),
  ('qf_binom_c_statt_wurzel', 'Setzt beim Zurückschreiben in ein Quadrat d² statt d in die Klammer.', 'klammern'),
  ('qf_ausklammern_vorzeichen', 'Setzt beim Ausklammern das Vorzeichen in der Klammer falsch.', 'klammern'),
  ('qf_ausklammern_nicht_geteilt', 'Teilt beim Ausklammern nicht jeden Summanden durch den Faktor.', 'klammern'),
  ('qf_quadrat_als_verdopplung', 'Rechnet das Quadrat als Verdopplung: n² = 2·n.', 'potenzen_wurzeln'),
  ('qf_koordinate_vorzeichen', 'Liest das Vorzeichen einer negativen Koordinate nicht mit.', 'vorzeichen')
on conflict (slug) do nothing;

create or replace function public.aufgabe_ziehbar(p_task uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.tasks t
      join public.bauformen b on b.id = t.bauform_id
     where t.id = p_task
       and b.status = 'freigegeben' and t.bauform_version = b.version
       and t.status = 'ready' and coalesce(t.is_active, false) and 'session' = any (t.einsatz)
       and public.instanz_gruen(t.pruefmaschine)
       and not exists (select 1 from public.aufgabe_bewaehrung w
                        where w.task_id = t.id and w.status in ('pausiert', 'auffaellig'))
       -- A3: eine Graph-Auswahl erst, wenn jede Option ihr hochgeladenes Bild hat (Zweitpruefung A3, Befund 11).
       and (t.input_type <> 'GRAPH_AUSWAHL'
            or (jsonb_array_length(coalesce(t.question_payload -> 'optionen', '[]')) >= 2
                and not exists (select 1 from jsonb_array_elements(coalesce(t.question_payload -> 'optionen', '[]')) o
                                 where not exists (select 1 from public.task_figur_optionen f
                                                    where f.task_id = t.id and f.option_id = o ->> 'id'
                                                      and f.svg_hash is not null))))
       -- A6: eine Aufgabe mit Figur erst, wenn die Figur hochgeladen ist.
       and not exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is null))
$$;
revoke all on function public.aufgabe_ziehbar(uuid) from public, anon, authenticated;
