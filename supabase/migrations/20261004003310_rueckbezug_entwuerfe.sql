-- Rueckbezug-Bausteine: Entwuerfe in der Sprache des Reports (W5-d, Nachtrag 2).
-- Setzt 20261004003309_report_bausteine_entwurf voraus.
-- Begruendung und Abnahmeliste: docs/report/rueckbezug-texte.md.
--
-- Elf abgenommene Saetze sprechen noch die Sprache vor #189: "tragen",
-- "Ebenen", "Fundament", "unterhalb des aktuellen Themas". Der Report sagt
-- sonst ueberall "sicher / noch nicht sicher" und "Grundlagen, auf denen das
-- Thema aufbaut". grundlagen_offen wird seit W5-d auch fuer Sitzungen ohne
-- Thema gezogen — sein Entwurf nennt deshalb kein "aktuelles Thema".
--
-- Nur ENTWURF: text und freigegeben_am bleiben unberuehrt, Eltern sehen bis zu
-- Lenas Abnahme den alten Satz. Geschrieben wird nur, wo text noch woertlich
-- dem alten Stand entspricht und noch kein Entwurf steht (wiederholbar; ein
-- schon geaenderter Satz wird nicht ueberdeckt). Sicherheitsgrenze nur nach
-- oben. Platzhalter: nur {belege}, wie bisher.
--
-- Ohne begin/commit: der Runner klammert.

do $$
declare n int;
begin
  update public.report_bausteine b
     set entwurf = v.entwurf
    from (values
  ('rueckbezug.grundlagen_bestaetigend_durchgehend.a',
   'Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich. Die Lücken reichen bis auf die tiefste Ebene, die wir geprüft haben — dort setzen wir an.',
   'Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich. Selbst bei den grundlegendsten Bereichen, die wir unter dem Thema geprüft haben, ist Ihr Kind noch nicht überall sicher — dort setzen wir an.'),

  ('rueckbezug.grundlagen_bestaetigend_durchgehend.b',
   'Sie hatten vermutet, dass Grundlagen fehlen. Die Analyse zeigt das über mehrere Ebenen hinweg, bis ganz nach unten.',
   'Sie hatten vermutet, dass Grundlagen fehlen. Die Analyse zeigt das: Bis hin zu den grundlegendsten Bereichen, auf denen das Thema aufbaut, ist noch nicht alles sicher.'),

  ('rueckbezug.grundlagen_bestaetigend_mitte.a',
   'Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich — allerdings nicht ganz unten. Die tiefsten Ebenen, die wir geprüft haben, tragen; die Lücken liegen dazwischen.',
   'Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich — allerdings nicht ganz unten. Die grundlegendsten Bereiche, die wir unter dem Thema geprüft haben, sind sicher; noch nicht sicher ist Ihr Kind bei einzelnen Schritten dazwischen.'),

  ('rueckbezug.grundlagen_bestaetigend_mitte.b',
   'Sie hatten vermutet, dass Grundlagen fehlen. Das trifft zu, aber genauer gesagt: Nicht das Fundament als Ganzes fehlt, sondern einzelne Stufen darin.',
   'Sie hatten vermutet, dass Grundlagen fehlen. Das trifft zu, aber genauer gesagt: Nicht die Grundlagen als Ganzes fehlen, sondern einzelne Schritte zwischen ihnen und dem Thema.'),

  ('rueckbezug.grundlagen_entlastend.a',
   'Sie hatten vermutet, dass Grundlagen fehlen. Unterhalb des aktuellen Themas hat jeder geprüfte Bereich getragen — dieser Punkt hat sich so nicht bestätigt.',
   'Sie hatten vermutet, dass Grundlagen fehlen. Bei den Grundlagen, auf denen das Thema aufbaut, war Ihr Kind in allen {belege} Bereichen sicher, die wir geprüft haben — dieser Punkt hat sich so nicht bestätigt.'),

  ('rueckbezug.grundlagen_entlastend.b',
   'Zu Ihrer Vermutung, dass Grundlagen fehlen: Alle Bereiche unterhalb des aktuellen Themas, die wir geprüft haben, tragen.',
   'Zu Ihrer Vermutung, dass Grundlagen fehlen: Alle {belege} Bereiche, auf denen das Thema aufbaut und die wir geprüft haben, sind sicher.'),

  ('rueckbezug.grundlagen_entlastend_schmal.a',
   'Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich unterhalb des aktuellen Themas, den wir geprüft haben, trägt. Das ist noch kein vollständiges Bild — der Coach geht die Ebenen darunter im Unterricht durch.',
   'Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich, auf dem das Thema aufbaut und den wir geprüft haben, ist sicher. Das ist noch kein vollständiges Bild — der Coach geht die übrigen Grundlagen im Unterricht durch.'),

  ('rueckbezug.grundlagen_entlastend_schmal.b',
   'Zu Ihrer Vermutung, dass Grundlagen fehlen: Was wir unterhalb des aktuellen Themas angesehen haben, hat getragen. Es war allerdings nur ein Bereich — mehr sagt diese Analyse dazu nicht.',
   'Zu Ihrer Vermutung, dass Grundlagen fehlen: Was wir von den Grundlagen des Themas angesehen haben, war sicher. Es war allerdings nur ein Bereich — mehr sagt diese Analyse dazu nicht.'),

  ('rueckbezug.grundlagen_offen.a',
   'Sie hatten vermutet, dass Grundlagen fehlen. Unterhalb des aktuellen Themas ist in dieser Analyse zu wenig geprüft worden, um das zu beantworten. Der Coach geht die Ebenen darunter im Unterricht durch.',
   'Sie hatten vermutet, dass Grundlagen fehlen. Dafür hat diese Analyse die Grundlagen zu wenig geprüft, um es zu beantworten. Der Coach geht sie im Unterricht durch.'),

  ('rueckbezug.grundlagen_offen.b',
   'Zu Ihrer Vermutung, dass Grundlagen fehlen: Diese Analyse ist unterhalb des aktuellen Themas nicht weit genug gekommen, um dazu etwas zu sagen.',
   'Zu Ihrer Vermutung, dass Grundlagen fehlen: Diese Analyse hat die Grundlagen nicht ausreichend geprüft, um dazu etwas zu sagen.'),

  ('rueckbezug.textverstaendnis_bestaetigend.b',
   'Was Sie zum Textverständnis gesagt haben, findet sich in der Analyse wieder — der Schritt vom Text zur Rechnung trägt noch nicht.',
   'Was Sie zum Textverständnis gesagt haben, findet sich in der Analyse wieder — beim Schritt vom Text zur Rechnung ist Ihr Kind noch nicht sicher.')
    ) as v(schluessel, alt, entwurf)
   where b.schluessel = v.schluessel
     and b.text = v.alt
     and b.entwurf is null;
  get diagnostics n = row_count;
  if n > 11 then raise exception 'Erwartet hoechstens 11 Entwuerfe, geschrieben %', n; end if;
  -- Ein Satz, dessen text vom alten Wortlaut abweicht, bekommt keinen Entwurf:
  -- sichtbar machen statt still zu ueberspringen (PRUEFUNG 1 faengt ihn auch).
  if n < 11 then raise warning 'rueckbezug: nur % von 11 Entwuerfen geschrieben (bereits vorhanden oder text geaendert)', n; end if;
  raise notice 'rueckbezug: % Entwuerfe geschrieben', n;
end $$;
