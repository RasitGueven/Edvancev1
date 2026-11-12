-- SP-1c · C3 NS-4 Klartext: Stufen 2 und 3 (sp1b/offen.md B1). Abstand der Nullstellen 2, 4 oder 6 statt „gerade“
-- (ns_4.py: |Scheitel-y| ≤ 9 lässt nur halbe Abstände bis 3 zu). Geprüft von einem frischen Subagenten
-- (docs/freigabe/sp1c/ns4-pruefung.md). Nur Daten an bauform_stufen: kein Steckbrief → keine neue Version.
--
-- Prüfabfrage:
--   select (select count(*) from bauform_stufen where beschreibung is not null and beispiel is not null) as klartext,
--          (select count(*) from bauform_stufen) as stufen;
--   → klartext 112, stufen 112

update public.bauform_stufen s set beschreibung = v.beschreibung, beispiel = v.beispiel, geaendert_am = now()
  from (values
    ('NS-4', 2, 'Zwei ganzzahlige Nullstellen zwischen −5 und 5 (nie 0, nie Gegenzahlen), ihr Abstand ist 2, 4 oder 6; der Scheitel hat ganze Koordinaten. Nach oben geöffnet wie die Normalparabel, drei Parabeln zur Auswahl.', 'Welche Parabel hat die Nullstellen x = −1 und x = 3? (Drei Parabeln zur Auswahl.)'),
    ('NS-4', 3, 'Zwei ganzzahlige Nullstellen zwischen −5 und 5 (nie 0, nie Gegenzahlen), ihr Abstand ist 2, 4 oder 6; der Scheitel hat ganze Koordinaten. Nach oben geöffnet wie die Normalparabel oder nach unten wie die gespiegelte Normalparabel; die Frage nennt die Öffnung, alle drei Parabeln zur Auswahl sind gleich geöffnet.', 'Welche Parabel hat die Nullstellen x = −1 und x = 3 und ist nach unten geöffnet? (Drei Parabeln zur Auswahl.)')
  ) v(schluessel, stufe, beschreibung, beispiel)
  join public.bauformen b on b.schluessel = v.schluessel
 where s.bauform_id = b.id and s.stufe = v.stufe;
