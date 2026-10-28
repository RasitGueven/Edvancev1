-- ============================================================================
-- Reihe 1 · A4 Bauform-Motor (Migration 20261027142701_reihe1_a4_versionswechsel): der Export aktualisiert Steckbrief,
-- Pruefprotokoll, Blindloeser und Status in einem Update — was das Update setzt, bleibt; der Rest wird fuer die neue
-- Version zurueckgesetzt. Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(6);

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_r1a4', 'ZZ R1 A4', 9, 1);
insert into bauformen (schluessel, skill_key, format, rollen, steckbrief, status, pruefprotokoll, blindloeser)
values ('ZZ-4', 'zz_r1a4', 'loesungsmenge', '{uebung}', '{"text":"alt"}', 'freigegeben', '{"lauf_am":"1"}', '{"bestanden":true}');

-- 1) Export (Schalter gesetzt) mit neuem Steckbrief UND neuem Lauf: Lauf und Blindloeser bleiben, zur Pruefung.
select set_config('edvance.bauform_export', '1', true);
update bauformen set steckbrief = '{"text":"neu"}', pruefprotokoll = '{"lauf_am":"2"}', blindloeser = '{"bestanden":true,"n":2}',
       status = 'freigegeben'
 where schluessel = 'ZZ-4';
select is((select version || '/' || status from bauformen where schluessel = 'ZZ-4'), '2/zur_pruefung',
          '1 neuer Steckbrief: Version 2, wieder zur Pruefung (nie schon freigegeben)');
select is((select pruefprotokoll ->> 'lauf_am' from bauformen where schluessel = 'ZZ-4'), '2', '1 der mitgegebene Lauf bleibt');
select is((select blindloeser ->> 'n' from bauformen where schluessel = 'ZZ-4'), '2', '1 der mitgegebene Blindloeser bleibt');

-- 2) Ohne Export-Schalter (Abnahme 10 wie in A2): Lauf und Blindloeser verfallen.
select set_config('edvance.bauform_export', '', true);
update bauformen set steckbrief = '{"text":"noch neuer"}' where schluessel = 'ZZ-4';
select is((select pruefprotokoll from bauformen where schluessel = 'ZZ-4'), '{}'::jsonb, '2 ohne neuen Lauf verfaellt der alte');
select is((select blindloeser from bauformen where schluessel = 'ZZ-4'), null, '2 ohne neuen Blindloeser verfaellt der alte');

-- 3) Ein Export mit Verdacht setzt den Status ausdruecklich auf entwurf; das bleibt.
select set_config('edvance.bauform_export', '1', true);
update bauformen set steckbrief = '{"text":"verdaechtig"}', verdacht = 'Blindloeser: 30 % abweichend', status = 'entwurf'
 where schluessel = 'ZZ-4';
select is((select status from bauformen where schluessel = 'ZZ-4'), 'entwurf', '3 Verdacht: entwurf bleibt (nicht im Board)');

select * from finish();
rollback;
