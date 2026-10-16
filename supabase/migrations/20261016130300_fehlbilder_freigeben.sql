-- Freigabe der Fehlbilder binom_formel_verwechselt und ausklammern_nicht_ggt.
--
-- Beide kamen mit 20261016130100 (Stufe 3) bzw. 20261016130200 (Session E3) samt Klartext, aber ohne freigegeben_am.
-- Die Klartexte hat Rasit am 16.10. bestätigt.
--
-- freigegeben_am wird nur an zwei Stellen gelesen: antwort_abgeben (Klartext im Coach-Live-Strom der Session) und
-- lsa_fehlbild_report (Klartext im LSA-Report). Ohne Freigabe kommt dort NULL an. Lenas Board
-- (pruef_auffaelligkeiten, pruef_fehler_gruppen) und die Fehlbild-Auswahl im Editor lesen das Feld nicht.
--
-- Nur wo freigegeben_am leer und ein Klartext vorhanden ist. freigegeben_von bleibt wie bei ML2 leer: kein Board,
-- Report, keine Fehlbild-Auswahl und keine Policy liest es.
-- Idempotent; in der CI ohne diese Slugs ein No-op. Kein begin/commit: mig klammert mit psql -1.

do $fbf$
declare
  v_n integer;
begin
  update public.fehlbild_labels
     set freigegeben_am = now()
   where slug in ('binom_formel_verwechselt', 'ausklammern_nicht_ggt')
     and freigegeben_am is null
     and nullif(btrim(coalesce(klartext, '')), '') is not null;
  get diagnostics v_n = row_count;
  raise notice 'fehlbilder_freigeben: % Fehlbild(er) freigegeben', v_n;
end $fbf$;
