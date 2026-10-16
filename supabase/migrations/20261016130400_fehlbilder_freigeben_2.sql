-- Freigabe der Fehlbilder faktor_nicht_quadriert und mischglieder_nicht_aufgehoben (Nachtrag zu 20261016130300).
--
-- Beide kamen mit 20261016130100 samt Klartext, aber ohne freigegeben_am. Rasit hat die Texte am 16.10. geprüft:
-- faktor_nicht_quadriert bleibt unverändert, mischglieder_nicht_aufgehoben bekommt einen neuen Klartext
-- (das Beispiel nennt jetzt das richtige Ergebnis). Die Erklärung bleibt bei beiden.
--
-- freigegeben_am wird nur in antwort_abgeben (Coach-Live-Strom der Session) und lsa_fehlbild_report (LSA-Report)
-- gelesen; Lenas Board und die Fehlbild-Auswahl im Editor lesen es nicht.
--
-- 1. klartext nur für mischglieder_nicht_aufgehoben.
-- 2. freigegeben_am = now() für beide Slugs, nur wo leer und mit Klartext. freigegeben_von bleibt leer.
-- Idempotent; kein begin/commit: mig klammert mit psql -1.

do $fbf2$
declare
  v_n integer;
begin
  update public.fehlbild_labels
     set klartext = 'Multipliziert (a + b)(a − b) aus und behält ein x-Glied, obwohl sich die Mischglieder aufheben: (x + 4)(x − 4) = x² − 8x − 16 statt x² − 16.'
   where slug = 'mischglieder_nicht_aufgehoben'
     and klartext is distinct from 'Multipliziert (a + b)(a − b) aus und behält ein x-Glied, obwohl sich die Mischglieder aufheben: (x + 4)(x − 4) = x² − 8x − 16 statt x² − 16.';
  get diagnostics v_n = row_count;
  raise notice 'fehlbilder_freigeben_2: mischglieder_nicht_aufgehoben Klartext gesetzt, % Zeile(n)', v_n;

  update public.fehlbild_labels
     set freigegeben_am = now()
   where slug in ('faktor_nicht_quadriert', 'mischglieder_nicht_aufgehoben')
     and freigegeben_am is null
     and nullif(btrim(coalesce(klartext, '')), '') is not null;
  get diagnostics v_n = row_count;
  raise notice 'fehlbilder_freigeben_2: % Fehlbild(er) freigegeben', v_n;
end $fbf2$;
