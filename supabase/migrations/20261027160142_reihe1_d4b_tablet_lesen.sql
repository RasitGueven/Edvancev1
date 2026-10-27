-- Reihe 1 · D4b Themenbaum-Ausschnitt am Session-Tablet (Bauauftrag D, offener Punkt 8 im Bericht).
--
-- C zeigt im Check-out vor Ort den ThemenbaumAusschnitt. Das Tablet ist ein Platz-Konto ohne Schülerzeile; bisher gab
-- home_darf_lesen dort 42501, und der Ausschnitt blieb leer. Jetzt darf auch das Tablet lesen, an dem das Kind in einer
-- aktiven Session sitzt (Muster wie mein_lernpfad und erklaer_zugang): nur dieses Kind, nur solange die Zuweisung nicht
-- gelöst ist und das Kind nicht als abwesend markiert ist. Am Ende der Session löst session_abschliessen alle Tablets;
-- danach antworten die Funktionen 42501, der Ausschnitt in C blendet sich dann still aus.
-- Betroffen (pg_proc-Scan): home_uebung_kurz, home_pfad, kompetenz_offen, kompetenz_offen_merken, themenbaum_themen.
-- home_uebung_melden, zeigs_mir_* und coach_fragen_* prüfen eigene Rechte und ändern sich nicht.
-- Rollback: supabase/rollback/20261027160142_reihe1_d4b_tablet_lesen.sql.

create or replace function public.home_darf_lesen(p_kind uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role(), '') = 'admin'
      or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_kind))
      or coalesce(public.get_my_student_id() = p_kind, false)
      -- Session-Tablet: das Platz-Konto, an dem das Kind gerade in einer aktiven Session sitzt.
      or exists (select 1 from public.session_tablets st
                   join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
                   join public.session_students ss on ss.session_id = st.session_id and ss.student_id = st.student_id
                                                  and ss.attendance in ('planned', 'present')
                  where st.geraet_id = auth.uid() and st.student_id = p_kind and st.geloest_am is null);
$$;

comment on function public.home_darf_lesen(uuid) is
  'Intern: Kind selbst, Coach mit aktiver Akte, Admin und das Session-Tablet des Kindes (Zuweisung offen, Session aktiv, '
  'Kind anwesend oder erwartet).';
