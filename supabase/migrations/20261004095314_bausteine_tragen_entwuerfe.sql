-- Report-Bausteine ohne "tragen": Entwuerfe (W5-d, offener Punkt).
-- Begruendung und Abnahmeliste: docs/report/rueckbezug-texte.md (Abschnitt
-- "Weitere Bausteine mit tragen").
--
-- Der Report sagt seit #189 "sicher / noch nicht sicher". Fuenf abgenommene,
-- gerenderte Saetze sagen noch "tragen" / "traegt": befund_traegt.standard.a/b
-- (Fuss unter der Liste "Das traegt"), empfehlung.keine.b, fazit.mehrere.b,
-- fazit.zwei.b. Inhalt und Platzhalter ({traegt}, {geprueft}) bleiben.
--
-- Gleiches Verfahren wie 20261004003310_rueckbezug_entwuerfe: nur entwurf wird
-- gesetzt; text und freigegeben_am bleiben, Eltern sehen bis zu Lenas Abnahme
-- den alten Satz. Nur wo text woertlich dem alten Stand entspricht und noch kein
-- Entwurf steht. Wiederholbar. Ohne begin/commit: der Runner klammert.

do $$
declare n int;
begin
  update public.report_bausteine b
     set entwurf = v.entwurf
    from (values
  ('befund_traegt.standard.a',
   '{traegt} von {geprueft} geprüften Bereichen tragen sicher.',
   '{traegt} von {geprueft} geprüften Bereichen sind sicher.'),

  ('befund_traegt.standard.b',
   'Von {geprueft} geprüften Bereichen tragen {traegt}.',
   'Von {geprueft} geprüften Bereichen sind {traegt} sicher.'),

  ('empfehlung.keine.b',
   'Der Lernstand trägt. Dieser Rhythmus genügt, um ihn zu halten.',
   'Was wir geprüft haben, ist sicher. Dieser Rhythmus genügt, um diesen Stand zu halten.'),

  ('fazit.mehrere.b',
   'Was noch nicht trägt, liegt in mehreren Themen verteilt. Deshalb gehen wir der Reihe nach vor und fangen bei den Grundlagen an, auf denen das Übrige aufbaut.',
   'Was noch nicht sicher ist, liegt in mehreren Themen verteilt. Deshalb gehen wir der Reihe nach vor und fangen bei den Grundlagen an, auf denen das Übrige aufbaut.'),

  ('fazit.zwei.b',
   'Was noch nicht trägt, liegt in zwei Themen. Wir beginnen mit dem, was weiter unten liegt, und gehen von dort nach oben.',
   'Was noch nicht sicher ist, liegt in zwei Themen. Wir beginnen mit dem, was weiter unten liegt, und gehen von dort nach oben.')
    ) as v(schluessel, alt, entwurf)
   where b.schluessel = v.schluessel
     and b.text = v.alt
     and b.entwurf is null;
  get diagnostics n = row_count;
  if n > 5 then raise exception 'Erwartet hoechstens 5 Entwuerfe, geschrieben %', n; end if;
  if n < 5 then raise warning 'bausteine: nur % von 5 Entwuerfen geschrieben (bereits vorhanden oder text geaendert)', n; end if;
  raise notice 'bausteine: % Entwuerfe geschrieben', n;
end $$;
