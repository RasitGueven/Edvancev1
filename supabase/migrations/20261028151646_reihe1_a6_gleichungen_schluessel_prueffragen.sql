-- Reihe 1 · A6 Gleichungen: zwei neue Fehlbild-Schluessel (WZ-5, DI-1) und die Coach-Pruefgespraeche der vier
-- Gleichungs-Skills (Auftrag A6.4, Status entwurf = zur Pruefung bei Lena).
--
-- Pruefabfrage: select (select count(*) from fehlbild_labels where slug in ('qf_quadriert_statt_wurzel', 'qf_diskriminante_ohne_p')),
--                      (select count(*) from skill_pruefung where skill_key like 'gleichung_quadr_%');   nachher 2 | 7
insert into public.fehlbild_labels (slug, klartext, familie) values
  ('qf_quadriert_statt_wurzel', 'Quadriert, statt die Wurzel zu ziehen: x² = 7 gibt 49.', 'potenzen_wurzeln'),
  ('qf_diskriminante_ohne_p', 'Lässt (p/2)² unter der Wurzel weg und rechnet nur mit −q.', 'rechenart_formel')
on conflict (slug) do nothing;

-- Coach-Prüffragen (Auftrag A6.4): je Kern-Skill 1–2, Prüffrage in neuem Kontext, Erwartung, Kriterium.
-- Status entwurf = zur Prüfung bei Lena (skill_pruefung_entscheiden), frei gibt ein Admin. Zweimal einspielen legt
-- nichts doppelt an (gleiche Frage je Skill).
insert into public.skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle)
select v.skill_key, v.frage, v.erwartung, v.kriterium, 'entwurf', 'ki'
  from (values
  ('gleichung_quadr_wurzel',
   'Ein quadratisches Beet hat 49 m² Fläche. Lina rechnet x² = 49 und schreibt x = 7 oder x = −7. Welche Lösung passt zum Beet, und warum hat die Gleichung trotzdem zwei?',
   'Die Gleichung hat zwei Lösungen, weil auch (−7)² = 49 ist. Für das Beet passt nur 7 m, weil eine Seitenlänge nicht negativ ist.',
   'Nennt beide Lösungen der Gleichung und begründet, warum im Sachzusammenhang nur die positive passt.'),
  ('gleichung_quadr_wurzel',
   'Erkläre, wie du (x − 2)² = 25 löst, ohne die Klammer auszumultiplizieren.',
   'Wurzel ziehen: x − 2 = 5 oder x − 2 = −5, also x = 7 oder x = −3.',
   'Zieht die Wurzel auf beiden Seiten, rechnet beide Fälle und stellt nach x um.'),
  ('gleichung_quadr_faktor',
   'Tim teilt x² = 3x durch x und bekommt x = 3. Was ist an seinem Weg problematisch?',
   'Durch x teilen ist nur erlaubt, wenn x ≠ 0 ist. So geht die Lösung x = 0 verloren. Richtig: x² − 3x = 0, x(x − 3) = 0, L = {0; 3}.',
   'Nennt, dass x = 0 verloren geht, und zeigt den Weg über Ausklammern und Nullprodukt.'),
  ('gleichung_quadr_faktor',
   'Warum kann man (x + 4)(x − 1) = 0 lösen, ohne auszumultiplizieren, (x + 4)(x − 1) = 6 aber nicht?',
   'Ein Produkt ist nur dann 0, wenn ein Faktor 0 ist. Für das Produkt 6 gibt es diese Regel nicht.',
   'Erklärt den Satz vom Nullprodukt und dass er nur für die 0 gilt.'),
  ('gleichung_quadr_formel',
   'Bevor du 2x² + 8x − 10 = 0 mit der p-q-Formel löst: Was musst du zuerst tun, und was sind dann p und q?',
   'Durch 2 teilen: x² + 4x − 5 = 0, also p = 4 und q = −5.',
   'Bringt die Gleichung in Normalform und liest p und q mit Vorzeichen ab.'),
  ('gleichung_quadr_formel',
   'Ein Mitschüler setzt bei x² − 6x + 5 = 0 in die Formel x = −3 ± √(9 − 5) ein. Wo ist der Fehler?',
   'p = −6, also ist −p/2 = 3 und nicht −3. Richtig: x = 3 ± 2, L = {1; 5}.',
   'Findet den Vorzeichenfehler bei −p/2 und rechnet richtig zu Ende.'),
  ('gleichung_quadr_anzahl',
   'Ohne die Gleichung zu lösen: Wie viele Lösungen hat x² + 2x + 3 = 0? Begründe.',
   '(p/2)² − q = 1 − 3 = −2 ist negativ. Aus einer negativen Zahl kann man keine Wurzel ziehen, also keine Lösung.',
   'Berechnet den Ausdruck unter der Wurzel und schließt aus dem Vorzeichen auf die Anzahl.')
  ) as v(skill_key, frage, erwartung, kriterium)
 where exists (select 1 from public.skills s where s.skill_key = v.skill_key)
   and not exists (select 1 from public.skill_pruefung p where p.skill_key = v.skill_key and p.frage = v.frage);
