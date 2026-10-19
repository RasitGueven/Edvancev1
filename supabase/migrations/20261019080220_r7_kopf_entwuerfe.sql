-- Report-Bausteine fuer die Ueberschrift des Eltern-Berichts R7 (Slot 'kopf').
-- Begruendung: docs/report/r7/Bauauftrag-R7.md (Entscheidung 8, Anhang B).
-- Abnahmeliste: docs/report/r7/kopf-texte.md.
--
-- Fall aus kopfFall (src/lib/report/elternbericht/bereiche.ts):
--   gemischt = es gibt Sicheres und Uebungsbedarf
--   sicher   = kein Uebungsbedarf
--   uebung   = nichts sicher
-- {name} ist der Rufname, sonst "Ihr Kind"; jeder Satz passt fuer beides.
--
-- Neue Zeilen: text ist der Entwurf, freigegeben_am bleibt NULL. Der Lesepfad
-- liefert sie erst nach Lenas Abnahme aus; bis dahin steht auf Seite 1 die
-- Ersatzueberschrift aus i18n (elternbericht:s1.kopfErsatz). on conflict do
-- nothing: ein schon (anders) abgenommener Satz wird nie ueberschrieben.
--
-- Kein DDL. Wiederholbar. Ohne begin/commit: der Runner klammert.

insert into public.report_bausteine (schluessel, slot, fall, variante, text)
values
  ('kopf.gemischt.a', 'kopf', 'gemischt', 'a',
   '{name} zeigt sichere Ansätze. Bei einigen Rechenschritten ist noch Übung nötig.'),
  ('kopf.gemischt.b', 'kopf', 'gemischt', 'b',
   '{name} löst vieles schon sicher. An einigen Stellen ist noch Übung nötig.'),
  ('kopf.sicher.a', 'kopf', 'sicher', 'a',
   '{name} war in den untersuchten Bereichen sicher.'),
  ('kopf.sicher.b', 'kopf', 'sicher', 'b',
   'In allen untersuchten Bereichen war {name} sicher.'),
  ('kopf.uebung.a', 'kopf', 'uebung', 'a',
   'In den untersuchten Bereichen braucht {name} noch Übung.'),
  ('kopf.uebung.b', 'kopf', 'uebung', 'b',
   '{name} braucht in den untersuchten Bereichen noch Übung. Genau dort setzen wir an.')
on conflict (schluessel) do nothing;
