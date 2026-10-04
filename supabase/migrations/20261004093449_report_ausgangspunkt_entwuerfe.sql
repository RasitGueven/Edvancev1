-- Report-Bausteine fuer nachgetragene Themenraeume (W5-d, Teil 5).
-- Begruendung und Abnahmeliste: docs/report/rueckbezug-texte.md (Abschnitt
-- "Ausgangspunkt") und docs/report/themenraum-entscheidungen.md.
--
-- Vier alte Sitzungen bekommen nachtraeglich das Thema "Terme und Gleichungen"
-- (Migration danach). Gewaehlt hat es niemand: die alte LSA begann fuer alle bei
-- den Gleichungen. Der Report darf dort NICHT "Gewaehlt war das Thema …" sagen.
-- Er nimmt stattdessen den Slot 'ausgangspunkt' — und solange der nicht
-- abgenommen ist, entfaellt der Satz ganz (src/lib/report/suche.ts,
-- ausgangspunktSatz). Ein Rueckfall auf den "Gewaehlt"-Satz existiert nicht.
--
-- 1. Neue Zeilen: text ist der Entwurf, freigegeben_am bleibt NULL. Der Lesepfad
--    liefert sie nicht aus. on conflict do nothing: ein schon (anders)
--    abgenommener Satz wird nie ueberschrieben.
-- 2. fazit.keine.a sagt "Das aktuelle Thema steht" — setzt ein gewaehltes,
--    aktuelles Thema voraus und spricht von "tragen". Entwurf in entwurf, der
--    alte Satz bleibt bis zur Abnahme live (Schutz: woertlicher Altstand).
-- 3. Kommentar der Spalte entwurf: eine Abnahme-Anweisung fuer beide Faelle.
--
-- Platzhalter {thema} fuellt ausgangspunktSatz mit dem Label des Themas.
-- Wiederholbar. Ohne begin/commit: der Runner klammert.

insert into public.report_bausteine (schluessel, slot, fall, variante, text)
values
  ('ausgangspunkt.thema.a', 'ausgangspunkt', 'thema', 'a',
   'Ausgangspunkt der Analyse war das Thema „{thema}“.'),
  ('ausgangspunkt.thema.b', 'ausgangspunkt', 'thema', 'b',
   'Die Analyse hat beim Thema „{thema}“ begonnen.'),
  ('ausgangspunkt.ungeprueft.a', 'ausgangspunkt', 'ungeprueft', 'a',
   'Ausgangspunkt der Analyse war das Thema „{thema}“. Aufgaben direkt zu diesem Thema kamen darin nicht vor.'),
  ('ausgangspunkt.ungeprueft.b', 'ausgangspunkt', 'ungeprueft', 'b',
   'Die Analyse hat im Umfeld des Themas „{thema}“ begonnen; Aufgaben direkt zu diesem Thema kamen dabei nicht vor.')
on conflict (schluessel) do nothing;

update public.report_bausteine b
   set entwurf = v.entwurf
  from (values
  ('fazit.keine.a',
   'Das aktuelle Thema steht, und die Grundlagen darunter tragen. Wir halten dieses Niveau und arbeiten am kommenden Stoff weiter.',
   'In den Bereichen, die wir geprüft haben, ist Ihr Kind sicher. Wir halten dieses Niveau und arbeiten am kommenden Stoff weiter.')
  ) as v(schluessel, alt, entwurf)
 where b.schluessel = v.schluessel
   and b.text = v.alt
   and b.entwurf is null;

comment on column public.report_bausteine.entwurf is
  'W5-d: unabgenommene Neufassung von text. Wird nie ausgeliefert. Abnahme je Fall '
  '(gilt auch fuer neue, noch nie abgenommene Zeilen, deren Entwurf in text steht): '
  'update report_bausteine set text = coalesce(entwurf, text), entwurf = null, '
  'freigegeben_am = now(), freigegeben_von = ''<profil-uuid>'' where slot = ''<slot>'' '
  'and fall = ''<fall>'' and (entwurf is not null or freigegeben_am is null);';
