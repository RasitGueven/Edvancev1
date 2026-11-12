-- Rollback zu 20261112083401_sp1_klartext: Klartexte zurück auf leer (die Ansicht zeigt dann wieder die Generator-Regeln).
-- Kein Inhalt geht verloren: die Texte stehen in docs/freigabe/sp1/klartext-entwurf.json.
update public.bauformen set titel = null where titel is not null;
update public.bauform_stufen set beschreibung = null, beispiel = null where beschreibung is not null or beispiel is not null;
