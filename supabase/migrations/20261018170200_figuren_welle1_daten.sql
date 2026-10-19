-- Figuren Welle 1 (F2, PR 2): 13 Figuren fuer Pilot-Aufgaben.
--
-- Quelle: docs/figuren/welle1.json (Specs aus docs/figuren/bedarf.json, F1), erzeugt mit
-- tools/figuren-welle1.py sql. Setzt PR 1 voraus (CHECK kennt thales, rechtecke, rechteck).
--
-- Gezielt je Aufgabe und nur, wenn
--   - die Aufgabe den Text hat, fuer den die Figur gebaut ist (md5 der Frage wie beim Bau), und
--   - noch keine Figur hat (on conflict do nothing).
-- svg_hash bleibt leer: Erst upload_figures.py erzeugt, prueft, laedt hoch und stempelt. Bis dahin
-- erscheint nichts im Payload (lsa_task_assets verlangt svg_hash). tasks bleibt unberuehrt — Status,
-- pruef_version und Lenas Pruefstand aendern sich nicht.

with neu (task_id, frage_md5, generator, params, alt_text) as (values
  ('11aebc7c-d30e-4577-89d5-52efed7d379f'::uuid, 'afb230ec01a763ea51ce91f02a4ef857', 'thales', '{"c_grad": 75, "form": "halbkreis", "mittelpunkt": false, "wahre_lage_grad": 64, "winkel": [{"ecke": "A", "schenkel": ["C", "B"], "text": "32°"}, {"ecke": "B", "schenkel": ["C", "A"], "text": "?"}]}'::jsonb,
   'Halbkreisförmiger Fensterbogen über der Unterkante AB. Von A und B führen zwei gerade Streben zu einem Punkt C auf dem Bogen. Der Winkel bei A ist angegeben, der Winkel bei B ist gesucht.'),
  ('3e087e16-bd3e-4489-b3d9-6c6759c4ce74'::uuid, 'd7c60b0368df6f4eec9fd7a323f192fa', 'thales', '{"c_grad": 60, "form": "kreis", "mc": true, "wahre_lage_grad": 70, "winkel": [{"ecke": "M", "schenkel": ["A", "C"], "text": ""}, {"ecke": "M", "schenkel": ["B", "C"], "text": ""}, {"ecke": "A", "schenkel": ["B", "C"], "text": "α = ?"}]}'::jsonb,
   'Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck, zusätzlich ist die Strecke von M nach C gezeichnet. Die beiden Winkel bei M sind markiert, der Winkel Alpha bei A ist gesucht.'),
  ('9ca300e1-76b9-4bb9-96cf-44cfda31824b'::uuid, 'd655a9ca78ce1c1afa3ef695be39e6f4', 'thales', '{"c_grad": 80, "form": "kreis", "mc": true, "wahre_lage_grad": 64, "winkel": [{"ecke": "M", "schenkel": ["B", "C"], "text": "64°"}, {"ecke": "A", "schenkel": ["B", "C"], "text": "α = ?"}]}'::jsonb,
   'Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck, zusätzlich ist die Strecke von M nach C gezeichnet. Der Winkel zwischen MB und MC ist angegeben, der Winkel Alpha bei A ist gesucht.'),
  ('9e7c1e4b-d317-44cf-8865-071c653ef2cf'::uuid, '7ff74db612797210cea11e971efda349', 'thales', '{"c_grad": 110, "form": "kreis", "mc": true, "wahre_lage_grad": 80, "winkel": [{"ecke": "A", "schenkel": ["B", "C"], "text": "40°"}, {"ecke": "C", "schenkel": ["A", "M"], "text": "?"}]}'::jsonb,
   'Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck, zusätzlich ist die Strecke von C nach M gezeichnet. Der Winkel bei A ist angegeben, der Winkel zwischen CA und CM ist gesucht.'),
  ('22e90366-5528-4685-993e-42e88f3623f6'::uuid, '3976c1b7fe047edfbaada3b833d1b57a', 'thales', '{"c_grad": 70, "form": "kreis", "wahre_lage_grad": 56, "winkel": [{"ecke": "A", "schenkel": ["B", "C"], "text": "α = 28°"}, {"ecke": "C", "schenkel": ["A", "B"], "text": "γ = ?"}]}'::jsonb,
   'Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck. Der Winkel Alpha bei A ist angegeben, der Winkel Gamma bei C ist gesucht.'),
  ('9f171c32-9786-4617-b2e4-161c88071ea5'::uuid, 'e64a2c4f5b1e6839e5000535c653e062', 'thales', '{"c_grad": 100, "form": "kreis", "wahre_lage_grad": 70, "winkel": [{"ecke": "A", "schenkel": ["B", "C"], "text": "α = 35°"}, {"ecke": "B", "schenkel": ["A", "C"], "text": "β = ?"}]}'::jsonb,
   'Kreis mit Mittelpunkt M und Durchmesser AB. Ein Punkt C auf dem Kreis bildet mit A und B ein Dreieck. Der Winkel Alpha bei A ist angegeben, der Winkel Beta bei B ist gesucht.'),
  ('11390e1a-2fc1-4cf1-93da-890ac936b56a'::uuid, 'e1be7212f1d995a0f73e98805de91864', 'rechtecke', '{"masse": [{"bis": [7, 0], "seite": "unten", "text": "x cm", "von": [0, 0]}, {"bis": [0, 4], "seite": "links", "text": "4 cm", "von": [0, 0]}, {"bis": [11, 0], "seite": "unten", "text": "4 cm", "von": [7, 0]}], "rechtecke": [{"b": 7, "h": 4, "stil": "kontur", "x": 0, "y": 0}, {"b": 4, "h": 4, "stil": "kontur", "x": 7, "y": 0}]}'::jsonb,
   'Eine Figur aus einem Rechteck und einem rechts angesetzten Quadrat. Die lange Rechteckseite ist mit x beschriftet, die kurze Rechteckseite und die Quadratseite mit ihrer Länge.'),
  ('f8364853-03fa-4d7e-807c-b0a20dbe09e3'::uuid, '5125d7b0fdcb89d08e8306cab7d039d8', 'rechtecke', '{"masse": [{"bis": [8, 8], "seite": "oben", "text": "(x + 3) m", "von": [0, 8]}, {"bis": [5, 0], "seite": "unten", "text": "(x - 1) m", "von": [0, 0]}], "rechtecke": [{"b": 3, "h": 8, "stil": "flaeche", "x": 5, "y": 0}, {"b": 5, "h": 3, "stil": "flaeche", "x": 0, "y": 5}, {"b": 8, "h": 8, "stil": "kontur", "x": 0, "y": 0}, {"b": 5, "h": 5, "stil": "kontur", "x": 0, "y": 0}], "texte": [{"text": "Beet", "x": 2.5, "y": 2.5}]}'::jsonb,
   'Ein quadratisches Grundstück, in einer Ecke ist ein kleineres quadratisches Beet abgetrennt. Beide Seitenlängen sind als Term mit x beschriftet, die Restfläche ist getönt.'),
  ('113aea0a-276a-4042-b634-805ef1e11db2'::uuid, '0a6cf4495db99d5d9951db8efc6d7443', 'rechtecke', '{"masse": [{"bis": [6, 0], "seite": "unten", "text": "x m", "von": [0, 0]}, {"bis": [8, 0], "seite": "unten", "text": "5 m", "von": [6, 0]}, {"bis": [0, 6], "seite": "links", "text": "5 m", "von": [0, 4]}], "rechtecke": [{"b": 6, "h": 6, "stil": "gestrichelt", "x": 0, "y": 0}, {"b": 8, "h": 4, "stil": "kontur", "x": 0, "y": 0}]}'::jsonb,
   'Ein gestricheltes Quadrat mit der Seitenlänge x. Darüber ein Rechteck, bei dem eine Seite um ein Stück verlängert und die andere um ein gleich langes Stück gekürzt ist.'),
  ('3a42b89c-7f8a-4b64-94ff-d1d4ac576c32'::uuid, '95c2363826e173d97ff0446f083b8950', 'rechtecke', '{"masse": [{"bis": [5, 0], "seite": "unten", "text": "?", "von": [0, 0]}, {"bis": [7, 0], "seite": "unten", "text": "3 cm", "von": [5, 0]}, {"bis": [0, 7], "seite": "links", "text": "3 cm", "von": [0, 5]}], "rechtecke": [{"b": 5, "h": 5, "stil": "gestrichelt", "x": 0, "y": 0}, {"b": 7, "h": 7, "stil": "kontur", "x": 0, "y": 0}], "texte": [{"text": "neues Quadrat: 121 cm²", "x": 3.5, "y": 7.9}]}'::jsonb,
   'Ein gestricheltes kleines Quadrat mit unbekannter Seitenlänge liegt in der Ecke eines größeren Quadrats. Das große Quadrat ist an zwei Seiten um dasselbe Stück länger, sein Flächeninhalt steht darüber.'),
  ('5b36238f-c64c-4578-bd63-55249f185c78'::uuid, '41f2ff9d2099547b76f62b0c907efa16', 'rechtecke', '{"masse": [{"bis": [11, 4.5], "seite": "oben", "text": "?", "von": [9.5, 4.5]}], "rechtecke": [{"b": 11, "h": 9, "stil": "kontur", "x": 0, "y": 0}, {"b": 8, "h": 6, "stil": "kontur", "x": 1.5, "y": 1.5}], "texte": [{"text": "Beet", "x": 6, "y": 3.2}, {"text": "20 m", "x": 5.5, "y": 6.8}, {"text": "15 m", "x": 2.8, "y": 4.5}, {"text": "Weg", "x": 5.5, "y": 0.75}]}'::jsonb,
   'Ein rechteckiges Beet, an dessen Seiten innen die Länge steht. Ringsum verläuft ein überall gleich breiter Weg, seine Breite ist gesucht.'),
  ('46192474-3c40-4cec-a9de-742684e86e01'::uuid, 'baa2a0c6c1b8bebef9a3e24d40683edd', 'rechteck', '{"breite_text": "5 cm", "laenge_text": "x cm", "verhaeltnis": 2}'::jsonb,
   'Ein Rechteck, die Länge ist mit x beschriftet, an der Breite steht die Länge.'),
  ('770f72e9-c73c-45fc-9803-e3b20846de70'::uuid, '5d5577b53358f01ed57fe944e4f32596', 'rechteck', '{"breite_text": "4 cm", "laenge_text": "(x + 3) cm", "verhaeltnis": 2}'::jsonb,
   'Ein Rechteck, die Länge ist als Term mit x beschriftet, an der Breite steht die Länge.')
), eingefuegt as (
  insert into public.task_figures (task_id, generator, params, alt_text)
  select n.task_id, n.generator, n.params, n.alt_text
    from neu n
    join public.tasks t on t.id = n.task_id and md5(t.question) = n.frage_md5
  on conflict (task_id) do nothing
  returning task_id
)
select 'figuren-welle1: ' || count(*) || ' Figuren angelegt' as figuren_welle1 from eingefuegt;
