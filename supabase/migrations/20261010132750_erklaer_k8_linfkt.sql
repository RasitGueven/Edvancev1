-- Erklärsequenzen lineare_funktionen (E2b), Migration 2 von 2 — 15 Kernideen, 59 Schritte,
-- 30 Checks zu fkt_linear_steigung, fkt_linear_yabschnitt, fkt_linear_gleichung, fkt_linear_graph, fkt_linear_nullstelle.
-- Erzeugt von tools/erklaer-build.mjs aus docs/prefill/erklaer-k8-linfkt.json — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach der Check-Migration (erklaer_check verweist auf die Check-Aufgaben).
--
-- Alles ist KI-Entwurf: Kernideen und Schritte status entwurf, quelle ki. Freigegeben wird nichts;
-- Lena prüft in L6, ein Admin gibt frei (Entscheidung 18). erklaer_start liefert die Sequenz nur
-- im Testlauf (20261008124414_a2_erklaer_testlauf.sql), sonst nichts.
--
-- formeln bleibt leer, bis tools/formeln-svg.mjs gelaufen ist; Bilder {svg_hash, alt} lädt
-- tools/erklaer-bilder.mjs nach task-assets/erklaer/bilder/<svg_hash>.svg.
--
-- Idempotent: on conflict do nothing. Kein begin/commit: mig spielt mit psql -1 in einer
-- Transaktion ein, die CI ohne Klammer.

insert into public.erklaer_kernidee (id, skill_key, nr, titel, status, quelle) values
  ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'fkt_linear_steigung', 1, 'Steigung: hoch durch rüber', 'entwurf', 'ki'),
  ('daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'fkt_linear_steigung', 2, 'Steigung aus zwei Punkten berechnen', 'entwurf', 'ki'),
  ('cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'fkt_linear_steigung', 3, 'Mit der Steigung weiterrechnen', 'entwurf', 'ki'),
  ('af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, 'fkt_linear_yabschnitt', 1, 'b ist der Schnitt mit der y-Achse', 'entwurf', 'ki'),
  ('6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'fkt_linear_yabschnitt', 2, 'b aus Steigung und Punkt berechnen', 'entwurf', 'ki'),
  ('d22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, 'fkt_linear_yabschnitt', 3, 'b ist der Startwert', 'entwurf', 'ki'),
  ('9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'fkt_linear_gleichung', 1, 'Gleichung aus m und b, dann einsetzen', 'entwurf', 'ki'),
  ('e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, 'fkt_linear_gleichung', 2, 'Gleichung aus zwei Punkten', 'entwurf', 'ki'),
  ('8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, 'fkt_linear_gleichung', 3, 'Gleichung im Sachzusammenhang', 'entwurf', 'ki'),
  ('4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'fkt_linear_graph', 1, 'b und m am Graphen ablesen', 'entwurf', 'ki'),
  ('ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'fkt_linear_graph', 2, 'Punkte am Graphen ablesen', 'entwurf', 'ki'),
  ('e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, 'fkt_linear_graph', 3, 'Graph im Sachzusammenhang', 'entwurf', 'ki'),
  ('525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, 'fkt_linear_nullstelle', 1, 'Nullstelle: Schnitt mit der x-Achse', 'entwurf', 'ki'),
  ('0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'fkt_linear_nullstelle', 2, 'Nullstelle berechnen', 'entwurf', 'ki'),
  ('ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, 'fkt_linear_nullstelle', 3, 'Nullstelle im Sachzusammenhang', 'entwurf', 'ki')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 1 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('3dbc87cd-0ff1-4eed-837b-66d7bf465f40'::uuid, 'e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'A', 'erklaerung',
  '# Wie steil ist die Gerade?

Geh auf der Geraden von A nach B. Zähl die Kästchen nach rechts und die Kästchen nach oben.

Dann teilst du: hoch durch rüber. Das Ergebnis heißt Steigung $m$. Hier: $4 : 2 = 2$.

> Steigung = hoch : rüber',
  '{"svg_hash":"9aacb25371418d17b50bc281924199681c9516122e95bc57f0355204f2277e0a","alt":"Steigende Gerade mit den Punkten A und B im Gitter. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 1 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('886947f3-227b-4532-8d99-37fbba5390dc'::uuid, 'e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'A', 'beispiel',
  '# Die Gerade geht durch A(0|-1) und B(2|5).

1. Von A nach B geht es 2 nach rechts.
2. Dabei geht es 6 nach oben.
3. Hoch durch rüber: $m = \frac{6}{2} = 3$.',
  '{"svg_hash":"57ba92d9b34155753000ffa4cb2e79b5cf021fc782d7a84775210e1a8b443bad","alt":"Steile Gerade durch die Punkte A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 1 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('fc1eb325-4a07-47fe-8c92-ed8d4a58c646'::uuid, 'e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'B', 'erklaerung',
  '# Erst hoch, dann durch rüber.

Wie weit es nach oben geht, steht oben im Bruch. Wie weit es nach rechts geht, steht unten.

Von C nach D: 3 nach rechts, 6 nach oben. Also $m = \frac{6}{3} = 2$.

Umgekehrt wäre $\frac{3}{6}$ viel zu flach.

> Steigung = hoch : rüber',
  '{"svg_hash":"3a1e6f580fc25bb0c2a478a12d0fb220b100fea3df4cb2b459b3f898bbc3793e","alt":"Steigende Gerade mit den Punkten C und D im Gitter. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{steigung_kehrwert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('55a49da6-afc7-42ae-9dfd-19276cdd4820'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'A', 'erklaerung',
  '# Rechnen statt zählen

Hoch = y von B minus y von A. Rüber = x von B minus x von A.

A(-3|1) und B(1|3): $m = \frac{3 - 1}{1 - (-3)} = \frac{2}{4}$, also 0,5.

Fällt die Gerade, wird hoch negativ und $m$ auch.

> $m = \dfrac{y_B - y_A}{x_B - x_A}$',
  '{"svg_hash":"20666b23d9fed3fed3c617a87b917a5df460b2636cef390d4c3aafbe70a78c5a","alt":"Flach steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('27994093-f1ef-480a-aa56-ad4e12c5abd2'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'A', 'beispiel',
  '# Die Gerade geht durch A(2|5) und B(5|-1).

1. Hoch: $-1 - 5 = -6$. Es geht nach unten.
2. Rüber: $5 - 2 = 3$.
3. $m = \frac{-6}{3} = -2$. Die Gerade fällt.',
  '{"svg_hash":"4e22a983355386d814f7bcc6ea480439f24be354cc1ace86ad0ffdbcae5f9f8b","alt":"Fallende Gerade durch die Punkte A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('6e73778f-f342-41aa-8fb4-90d126d27fa7'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'B', 'erklaerung',
  '# Passt das Vorzeichen?

Steigt die Gerade, ist $m$ positiv. Fällt sie, ist $m$ negativ. Ohne Bild: Wird y mit x größer, steigt sie.

Rechne oben und unten in derselben Reihenfolge: erst Q, dann P.

P(-1|5) und Q(3|1): $m = \frac{1 - 5}{3 - (-1)} = \frac{-4}{4} = -1$.',
  '{"svg_hash":"6efb0f94373b77bd16d6a505a8ff0d26c51609749b9b2d357b1c67035605531b","alt":"Fallende Gerade mit den Punkten P und Q. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{seiten_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('85a03240-9f46-4451-8965-74e24bdb0727'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'C', 'erklaerung',
  '# Die y-Werte gehören nach oben.

Im Bruch stehen oben die y-Werte und unten die x-Werte. So bleibt es: hoch durch rüber.

A(0|-3) und B(2|5): $m = \frac{5 - (-3)}{2 - 0} = \frac{8}{2} = 4$.

Umgekehrt käme $\frac{2}{8}$ heraus. Das passt nicht zur steilen Geraden.',
  '{"svg_hash":"7ce6458bc01b32c13082683f5503e30a4ad31f427111cb7bccaf7160fa93f23b","alt":"Sehr steile Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{steigung_kehrwert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('e1758016-20c1-4e66-a891-802d27c3e289'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'A', 'erklaerung',
  '# Jeder Schritt bringt m dazu.

Ein Schritt heißt: 1 nach rechts. Bei jedem Schritt geht es um $m$ nach oben. Ist $m$ negativ, geht es nach unten.

Gehst du mehrere Schritte, kommt $m$ für jeden Schritt einmal dazu.

> neuer y-Wert = alter y-Wert + Schritte · m',
  '{"svg_hash":"358fea42920248661b1151ae9c8dc03c69bcd66b96508c3892cd758646164f9a","alt":"Steigende Gerade mit vier Punkten P, Q, R und S im Abstand von je einem Kästchen nach rechts. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('7ef3f867-06f5-4ac4-9d37-734176225c1f'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'A', 'beispiel',
  '# Von P(1|-1) mit m = 2 bis x = 4

1. Von x = 1 bis x = 4 sind es 3 Schritte.
2. Jeder Schritt bringt 2 nach oben: $3 \cdot 2 = 6$.
3. $-1 + 6 = 5$. Der Punkt heißt Q(4|5).',
  '{"svg_hash":"787587f9a1f37756e8c26e885bfb8db14c4868915c54d5693ec261db69c4d5d8","alt":"Steigende Gerade mit den Punkten P und Q. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('61343c38-a91a-4a28-9c1b-469e5eb846df'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'B', 'erklaerung',
  '# Zähl die Schritte mit.

Die Steigung gilt für einen Schritt nach rechts. Bei 4 Schritten kommt sie 4-mal dazu.

P(0|-2), $m = 2$, 4 Schritte: $-2 + 4 \cdot 2 = 6$, also Q(4|6). Nicht $-2 + 2 = 0$.',
  '{"svg_hash":"d409706d50eea0d0a1c6283829823ca0607c1b847e8c9c1ffc63e9d014b96a20","alt":"Steigende Gerade mit den Punkten P und Q. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{nur_einmal_addiert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('fc4d1a08-a24d-4c21-b905-1acab8de237d'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'C', 'erklaerung',
  '# Starte beim Punkt, nicht im Ursprung.

Diese Gerade geht nicht durch den Ursprung. Steigung mal x allein reicht deshalb nicht.

Starte beim y-Wert des Punktes und zähl die Schritte dazu.

P(2|3), $m = 3$, gesucht y bei x = 4: 2 Schritte, $3 + 2 \cdot 3 = 9$. Nicht $3 \cdot 4 = 12$.',
  '{"svg_hash":"76d94746a2372be37816001a21db75fd12600e5862305212f37de4ebf66e6ede","alt":"Steigende Gerade, die nicht durch den Ursprung geht, mit den Punkten P und Q. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{b_ignoriert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 1 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('766259d6-0394-41f5-a51b-03eb435c9a0d'::uuid, 'af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, 'A', 'erklaerung',
  '# Wo trifft die Gerade die y-Achse?

In $y = mx + b$ ist m die Steigung. Die y-Achse liegt bei x = 0. Dort fällt $m \cdot x$ weg.

Übrig bleibt b. Bei $y = 2x + 1$ ist das 1, der Punkt S(0|1).

> Der y-Achsenabschnitt ist b, die Zahl ohne x.',
  '{"svg_hash":"38c8c670f784698f24fee85440c3a646b83f1b2ef422aa9a54fc9ba2a24e14ac","alt":"Steigende Gerade, die die y-Achse im Punkt S schneidet."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 1 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('cd117773-6f5f-47a7-bd74-42c26a68cf33'::uuid, 'af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, 'A', 'beispiel',
  '# Beispiel: f(x) = 3x - 5

1. Die Zahl ohne x ist -5. Das Minus davor gehört dazu.
2. Probe mit x = 0: $3 \cdot 0 - 5 = -5$.
3. Der Graph trifft die y-Achse in S(0|-5). Der y-Achsenabschnitt ist -5.',
  '{"svg_hash":"c477e709f1cb474c974b3be9015adfb7c3cd645d8d99649f4d5cf925ee976b4d","alt":"Steigende Gerade, die die y-Achse unterhalb der x-Achse im Punkt S schneidet."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 1 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('99d39321-c8d8-4ef6-b757-2fa9249389a3'::uuid, 'af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, 'B', 'erklaerung',
  '# Welche Zahl ist b?

In $y = mx + b$ steht m direkt vor dem x. b steht allein, ohne x.

Das Vorzeichen gehört zu b. Bei $y = 2x - 3$ ist $b = -3$, nicht 2 und nicht 3.

Im Bild trifft die Gerade die y-Achse unterhalb der x-Achse, in S(0|-3).',
  '{"svg_hash":"3aa4e9e4b6e07b59bd025dfefa31a74332b94a127944a00e7a82a9ca1b7edeb2","alt":"Steigende Gerade, die die y-Achse unterhalb der x-Achse im Punkt S schneidet."}'::jsonb, '{m_b_vertauscht,betrag_fehler}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 1 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('ec36f387-ebf4-4d14-ab68-791e31893c7c'::uuid, 'af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, 'C', 'erklaerung',
  '# y-Achse, nicht x-Achse

Der y-Achsenabschnitt liegt auf der y-Achse, also bei x = 0.

Wo die Gerade die x-Achse trifft, ist y = 0. Das ist die Nullstelle, etwas anderes.

Bei $y = 2x - 2$: S(0|-2) auf der y-Achse, N(1|0) auf der x-Achse.',
  '{"svg_hash":"891e3be2490c77205cb44d37c6b1dc04fb79c03a0708cbc81db23e0ef65cc14c","alt":"Steigende Gerade mit dem Punkt S auf der y-Achse und dem Punkt N auf der x-Achse."}'::jsonb, '{achsenabschnitt_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 2 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('9b560487-f5b1-4eef-b90d-b2dd13e13df0'::uuid, '6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'A', 'erklaerung',
  '# Zurück zur y-Achse

Kennst du m und einen Punkt P, gehst du von P zurück bis x = 0. Jeder Schritt nach links nimmt m einmal weg.

P(3|7), $m = 2$: $b = 7 - 2 \cdot 3 = 1$, also S(0|1).

> $b = y_P - m \cdot x_P$',
  '{"svg_hash":"fb45e18bb1662a7f5744ccdc14668d86dae676ffb0581bbb2c4fc4676db2c826","alt":"Steigende Gerade mit dem Punkt P und dem Punkt S auf der y-Achse. Ein Steigungsdreieck reicht von S bis P."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 2 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('015be76a-1a62-4699-b8d4-3749b93727e8'::uuid, '6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'A', 'beispiel',
  '# m = -1, die Gerade geht durch P(4|1).

1. Von P bis x = 0 sind es 4 Schritte nach links.
2. $b = 1 - (-1) \cdot 4 = 1 + 4 = 5$.
3. Die Gerade trifft die y-Achse in S(0|5). Das Dreieck zeigt denselben Weg von S aus: rüber 4, hoch -4.',
  '{"svg_hash":"b4f43f84340355fe11db2c9caad39f896a6573f710b86f2783ee0868e923137b","alt":"Fallende Gerade mit dem Punkt P und dem Punkt S auf der y-Achse. Ein Steigungsdreieck reicht von S bis P."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 2 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('9e22644c-6e2c-4dd2-a081-cff7ed0e83ce'::uuid, '6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'B', 'erklaerung',
  '# Zurück heißt: abziehen.

Von P zur y-Achse gehst du nach links. Dabei nimmst du m für jeden Schritt weg.

P(1|5), $m = 4$: $b = 5 - 4 \cdot 1 = 1$. Nicht $5 + 4 \cdot 1 = 9$.

Die Gerade steigt, also liegt S(0|1) tiefer als P.',
  '{"svg_hash":"5dc8956cb2d9e554b36c7c00c83edcf5f0b11dafadf841f7c543622f96fa7d8a","alt":"Steile Gerade mit dem Punkt P und dem tiefer liegenden Punkt S auf der y-Achse."}'::jsonb, '{addiert_statt_subtrahiert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 2 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('5cda40fd-5936-4357-9dd3-3e6221011cd6'::uuid, '6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'C', 'erklaerung',
  '# Passt das Vorzeichen von b?

Über der x-Achse ist b positiv, darunter negativ. Ohne Bild: Rechne Schritt für Schritt und schreib jedes Minus mit.

P(3|2), $m = 2$: $b = 2 - 2 \cdot 3 = -4$. S(0|-4) liegt unter der x-Achse.',
  '{"svg_hash":"9d65a006e65d23c8ccef85c3d68b522113a28ecfd337f8e09d0c4f32d888109d","alt":"Steigende Gerade mit dem Punkt P über und dem Punkt S unter der x-Achse. Ein Steigungsdreieck reicht von S bis P."}'::jsonb, '{betrag_fehler}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 3 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('b48bbd1e-5ac6-471a-9d6e-91c6a2092d87'::uuid, 'd22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, 'A', 'erklaerung',
  '# Der Startwert ist b.

In Sachaufgaben steht x oft für eine Zeit oder eine Menge. Bei x = 0 ist noch nichts passiert.

Dann bleibt nur b übrig. Das ist der Startwert, zum Beispiel ein Grundpreis. Hier startet die Gerade bei 3.

> Startwert = Wert bei x = 0 = b',
  '{"svg_hash":"25acda1241a72a3feb00585cd6b1863b163fcddd8ed8c8b9907b93e1737c1530","alt":"Steigende Gerade im ersten Quadranten. Der Punkt S auf der y-Achse markiert den Startwert."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 3 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('dbb8567c-5cba-43ba-9ec6-ad5cf2eafc73'::uuid, 'd22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, 'A', 'beispiel',
  '# Ein Abo kostet K(x) = 2x + 5 Euro für x Filme.

1. Ohne Film ist x = 0.
2. $K(0) = 2 \cdot 0 + 5 = 5$.
3. Der Grundpreis ist 5 Euro. Pro Film kommen 2 Euro dazu.',
  '{"svg_hash":"f10c55a5ac01ea081333dd48e84fdf455fdd6052506455ead240700f270f5c5a","alt":"Steigende Gerade im ersten Quadranten mit dem Punkt S auf der y-Achse."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 3 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('3b4c35c5-1bb4-4359-9e6f-cc9839b8d830'::uuid, 'd22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, 'B', 'erklaerung',
  '# Fest oder pro Stück?

Die Zahl vor dem x kommt bei jedem Stück neu dazu. Das ist die Rate m.

Die Zahl ohne x ist von Anfang an da. Das ist der Grundbetrag b.

Bei $K(x) = 2x + 6$ ist der Grundbetrag 6 Euro, nicht 2 Euro.',
  '{"svg_hash":"23f350a9ae6baeac44036d7879fb15e325fc122d6a713c103e5520dfb5f098df","alt":"Steigende Gerade im ersten Quadranten mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck zeigt den Zuwachs pro Stück."}'::jsonb, '{groessen_vertauscht}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_yabschnitt · Kernidee 3 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('4455afbf-c741-458e-b163-2e06e6e61504'::uuid, 'd22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, 'C', 'erklaerung',
  '# Gesucht ist der Anfang.

Der Startwert ist der Wert bei x = 0. Er liegt auf der y-Achse.

Wann der Wert 0 erreicht, ist eine andere Frage. Das ist die Nullstelle.

Ein Tank hat $h(x) = -2x + 8$ Liter. Zu Beginn sind 8 Liter drin. Leer ist er erst bei x = 4.',
  '{"svg_hash":"a3a024e77bf53d4217ee173696f241e81879c07a33c66b82dd0832f258ce47b7","alt":"Fallende Gerade mit dem Startpunkt S auf der y-Achse und dem Punkt N auf der x-Achse."}'::jsonb, '{achsenabschnitt_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 1 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('3c8d474e-0de6-4d22-8511-4e6c03f1d856'::uuid, '9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'A', 'erklaerung',
  '# m und b einsetzen

Eine lineare Funktion hat die Form $y = mx + b$. Statt y schreibt man auch f(x).

Für m setzt du die Steigung ein, für b den y-Achsenabschnitt. Ein Minus schreibst du mit.

Bei $m = 2$ und $b = -1$ heißt sie $y = 2x - 1$.

> $f(x) = mx + b$',
  '{"svg_hash":"c920d82c69938878bb9ba3b56c939a953d31be903bf53814a7168db8a6dc2c12","alt":"Steigende Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 1 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('137437c6-c0e8-473e-b3bb-f5a0b19913b1'::uuid, '9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'A', 'beispiel',
  '# m = -3 und b = 5. Wie groß ist f(2)?

1. Die Gleichung heißt $f(x) = -3x + 5$.
2. Setz x = 2 ein: $f(2) = -3 \cdot 2 + 5$.
3. $-6 + 5 = -1$. Also ist f(2) = -1, der Punkt P(2|-1).',
  '{"svg_hash":"440df1a5468d40b1596e9c6d5a256f05d6487d85cb15a39b03cd3e61c0702ed6","alt":"Fallende Gerade mit dem Punkt S auf der y-Achse und dem Punkt P unterhalb der x-Achse."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 1 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('7765d314-250d-4dcc-a973-ddb836da20a9'::uuid, '9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'B', 'erklaerung',
  '# m steht vor dem x.

Die Steigung gehört direkt vor das x. Der y-Achsenabschnitt steht allein am Ende.

Steigung 3, y-Achsenabschnitt 1: $y = 3x + 1$. Nicht $y = 1x + 3$.

Im Bild startet die Gerade bei S(0|1) und steigt steil.',
  '{"svg_hash":"37e425537704be9eeb6f5d7d0f089e04a731587a8fb02ad163abd63629faf836","alt":"Steile Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{m_b_vertauscht}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 1 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('70458d07-c30d-46a5-afab-a3f07276db40'::uuid, '9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'C', 'erklaerung',
  '# Das Minus gehört zur Zahl.

Ist m oder b negativ, schreibst du das Minus mit in die Gleichung.

Steigung 2, y-Achsenabschnitt -3: $y = 2x - 3$. Bei x = 2: $4 - 3 = 1$. Nicht $4 + 3 = 7$.

Prüf dein Ergebnis am Bild: Liegt der Punkt über oder unter der x-Achse?',
  '{"svg_hash":"5a6484f4efc29e27f7b36ad83bff2b36bbe8af7a47afd8c7a85964c5b5455f84","alt":"Steigende Gerade mit dem Punkt S unterhalb der x-Achse auf der y-Achse und dem Punkt P darüber."}'::jsonb, '{vorzeichen_ignoriert,betrag_fehler}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 2 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('80809fb2-761a-451d-990d-29b93787b835'::uuid, 'e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, 'A', 'erklaerung',
  '# Erst m, dann b

Aus den Punkten A und B rechnest du zuerst die Steigung: hoch durch rüber.

Dann setzt du einen Punkt ein und rechnest b aus: $b = y - m \cdot x$.

> erst $m = \dfrac{y_B - y_A}{x_B - x_A}$, dann b',
  '{"svg_hash":"1dfe1d691ee49beae9ee9d18a234cbec86f87a791ceed2259f2025de7a49b8fd","alt":"Steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 2 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('83537d37-3665-48dd-8975-be30e6c30394'::uuid, 'e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, 'A', 'beispiel',
  '# Die Gerade geht durch A(1|-2) und B(3|4).

1. $m = \frac{4 - (-2)}{3 - 1} = \frac{6}{2} = 3$. Minus Minus heißt plus.
2. A einsetzen: $b = -2 - 3 \cdot 1 = -5$.
3. Die Gleichung heißt $y = 3x - 5$.',
  '{"svg_hash":"6a1940703c040f567d6318135bb5574877422c076348d4212290086edfd4f662","alt":"Steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 2 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('2681c224-76aa-4f29-85d3-e5be4fa3546b'::uuid, 'e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, 'B', 'erklaerung',
  '# Hoch durch rüber, gleiche Reihenfolge

Oben stehen die y-Werte, unten die x-Werte. Fang oben und unten mit demselben Punkt an.

A(1|2) und B(4|8): $m = \frac{8 - 2}{4 - 1} = \frac{6}{3} = 2$.

Nicht $\frac{3}{6}$ und nicht $\frac{8 - 2}{1 - 4} = -2$.',
  '{"svg_hash":"dab3374fae80e7865b241cca5a830b6a149cfe27a7c33725fcffaabd5a5dee66","alt":"Steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht."}'::jsonb, '{steigung_kehrwert,seiten_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 2 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('325dbd65-9fe5-4490-b1ee-a853241a8a3c'::uuid, 'e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, 'C', 'erklaerung',
  '# Für b wird abgezogen.

Setz einen Punkt in $y = mx + b$ ein. Dann ziehst du $m \cdot x$ auf beiden Seiten ab.

P(2|9) und $m = 3$: $9 = 3 \cdot 2 + b$, also $b = 9 - 6 = 3$.

Nicht $9 + 6 = 15$. Lies genau, was gefragt ist: m oder b.',
  '{"svg_hash":"a5b4bd8ea2d362aa69f9f375e6acc8a6dfe5234071545b8994d2a5106a845a1d","alt":"Steile Gerade mit dem Punkt P und dem Punkt S auf der y-Achse."}'::jsonb, '{addiert_statt_subtrahiert,falsche_groesse_beantwortet}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 3 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('43a1657b-bf9e-4b87-a89a-61f603da099b'::uuid, '8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, 'A', 'erklaerung',
  '# Was ist m, was ist b?

Der feste Betrag am Anfang ist b. Was pro Stück, Stunde oder Kilometer dazukommt, ist m.

Nimmt etwas ab, ist m negativ: 15 cm, pro Stunde 2 cm weniger, $h(x) = -2x + 15$.

> Wert = m · Menge + Startwert b',
  '{"svg_hash":"64b0affda37084274c3f889c538d9c325a498184c32aee535c6d70225d4aeb9f","alt":"Steigende Gerade im ersten Quadranten mit dem Startpunkt S auf der y-Achse. Ein Steigungsdreieck zeigt den Zuwachs pro Einheit."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 3 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('a41f8cc9-340a-4dc8-a684-284f12483588'::uuid, '8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, 'A', 'beispiel',
  '# Eintritt: 3 Euro Grundpreis, 2 Euro pro Stunde

1. Grundpreis $b = 3$, pro Stunde $m = 2$.
2. Die Gleichung heißt $K(x) = 2x + 3$.
3. Für 4 Stunden: $K(4) = 2 \cdot 4 + 3 = 11$ Euro.',
  '{"svg_hash":"f8af467a9c46f0c6b08f24b2815d8b46fce27f3d88df5a10b3782ab9e51ae18d","alt":"Steigende Gerade im ersten Quadranten mit dem Startpunkt S und dem Punkt P."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 3 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('f8ebcde5-0352-4ac5-a34b-b6c6d16b5282'::uuid, '8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, 'B', 'erklaerung',
  '# Grundbetrag einmal, Betrag pro Stück jedes Mal

Der Grundbetrag kommt nur einmal dazu. Der Betrag pro Stück kommt für jedes Stück dazu.

5 Euro Grundgebühr, 2 Euro pro km, 3 km: $2 \cdot 3 + 5 = 11$ Euro.

Nicht $5 \cdot 3 + 2 = 17$. Und nicht nur $2 \cdot 3 = 6$, dann fehlt die Grundgebühr.',
  '{"svg_hash":"3ddab4de751286f27f3d811fccfbf8191bc15bf70163feee3a0cf7d4d833c03f","alt":"Steigende Gerade im ersten Quadranten mit dem Startpunkt S und dem Punkt P."}'::jsonb, '{groessen_vertauscht,b_ignoriert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_gleichung · Kernidee 3 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('887a710b-9f77-47dd-b419-3644ce5178b5'::uuid, '8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, 'C', 'erklaerung',
  '# Nimmt es ab, ist m negativ.

Ein Tank hat 12 Liter. Pro Minute fließen 2 Liter ab. Also $V(x) = -2x + 12$.

Nach 4 Minuten: $-2 \cdot 4 + 12 = 4$ Liter. Nicht $2 \cdot 4 + 12 = 20$.

Gefragt ist, was noch drin ist. Nicht die $2 \cdot 4 = 8$ Liter, die abgeflossen sind.',
  '{"svg_hash":"6cabd7c811739859697efc0dfaadf3b62f66ab9204a585865c3fa1ed61cba7db","alt":"Fallende Gerade im ersten Quadranten mit dem Startpunkt S und dem Punkt P."}'::jsonb, '{vorzeichen_ignoriert,falsche_groesse_beantwortet}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 1 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('e86add7e-f382-42bc-879b-20d1dcefb33f'::uuid, '4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'A', 'erklaerung',
  '# b und m am Graphen ablesen

b liest du dort ab, wo die Gerade die y-Achse schneidet.

Geh nach rechts, bis die Gerade genau eine Kästchenecke trifft. Zähl, wie weit es hoch oder runter geht. Hoch durch rüber ist m.

Hier: S(0|-1), rüber 2, hoch 4. Also $b = -1$ und $m = 4 : 2 = 2$.',
  '{"svg_hash":"e0b0c785d2df30b830c4839af58777e46f354e9e10dee577fa1d8f4d434f4947","alt":"Steigende Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck beginnt bei S."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 1 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('9d57e74e-24ea-4071-9069-4449d7e57b24'::uuid, '4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'A', 'beispiel',
  '# Beispiel: eine fallende Gerade

1. Die Gerade schneidet die y-Achse bei S(0|3). Also $b = 3$.
2. Von S geht es 2 nach rechts und 3 nach unten, also hoch -3.
3. $m = \frac{-3}{2} = -1,5$. Die Gerade fällt, m ist negativ.',
  '{"svg_hash":"b9f0a221c2d8b329726c70c27b041268d1c85f55b8b0612f6855fe83a3a04983","alt":"Fallende Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck beginnt bei S."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 1 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('6ba5a565-1279-4eb3-9ecf-47b5fea7bd9f'::uuid, '4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'B', 'erklaerung',
  '# b sitzt auf der y-Achse.

b ist ein Wert auf der y-Achse. Es sagt nichts darüber, wie steil die Gerade ist.

Wo die Gerade die x-Achse schneidet, liegt die Nullstelle. Das ist nicht b.

Hier: S(0|2), also $b = 2$. Die Steigung ist 0,5, sie gehört nicht zu b. N(-4|0) ist die Nullstelle.',
  '{"svg_hash":"43d7555d59eef192e7faa3645b105cb1ce1708122af7a065da9caa8c7f07e771","alt":"Flach steigende Gerade mit dem Punkt S auf der y-Achse und dem Punkt N auf der x-Achse."}'::jsonb, '{m_b_vertauscht,achsenabschnitt_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 1 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('c8c83187-aaf1-4379-9850-7073209165c7'::uuid, '4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'C', 'erklaerung',
  '# Vorzeichen und Bruch prüfen

Liegt S unter der x-Achse, ist b negativ. Fällt die Gerade, ist m negativ.

Hier: S(0|-1), also $b = -1$, nicht 1.

Von S nach P(4|-2): rüber 4, hoch -1. $m = \frac{-1}{4} = -0,25$. Nicht $\frac{4}{-1} = -4$.',
  '{"svg_hash":"b81a9a9037f8a76ed98542b9321ecf0f185b7f02cc8d2fed70d0dce3adc56268","alt":"Flach fallende Gerade mit den Punkten S und P unterhalb der x-Achse. Ein Steigungsdreieck reicht von S bis P."}'::jsonb, '{steigung_kehrwert,betrag_fehler}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 2 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('cdf49256-d07f-4bf2-8924-dfec237b3404'::uuid, 'ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'A', 'erklaerung',
  '# Erst x, dann y

Ist x gegeben: Geh von x auf der x-Achse senkrecht zur Geraden, dann waagerecht zur y-Achse. Dort liest du y ab.

Ist y gegeben: Geh umgekehrt, von y auf der y-Achse waagerecht zur Geraden, dann senkrecht zur x-Achse.

Hier: P(2|3). Zu x = 2 gehört y = 3. Umgekehrt gehört zu y = 3 die Stelle x = 2.

> Punkt P(x|y): erst x, dann y',
  '{"svg_hash":"f0f46e98e2a07db9347fede08ea9fac1e963cf193a3797d208ce5647ae6d1d79","alt":"Steigende Gerade mit dem Punkt P."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 2 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('63b90f86-bf2a-409e-b510-331b2d19c32a'::uuid, 'ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'A', 'beispiel',
  '# Welchen y-Wert hat die Gerade bei x = 3?

1. Starte auf der x-Achse bei 3.
2. Geh senkrecht bis zur Geraden. Du triffst P(3|-2).
3. Der y-Wert ist -2. Er liegt unter der x-Achse, also mit Minus.',
  '{"svg_hash":"059e3e873b9900054c5459bec4f762c40125f4aab1c6c88debafd0a22e2d962b","alt":"Fallende Gerade mit dem Punkt P unterhalb der x-Achse."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 2 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('bee7f6c1-140a-4b3b-b474-fcc96e357d68'::uuid, 'ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'B', 'erklaerung',
  '# Was ist gegeben, was gesucht?

Ist x gegeben, suchst du y. Ist y gegeben, suchst du x.

Hier liegt Q(2|4) auf der Geraden. Zu x = 2 gehört y = 4, nicht 2.

Zu y = 4 gehört x = 2, nicht 4. Dafür startest du auf der y-Achse bei 4 und gehst waagerecht zur Geraden.',
  '{"svg_hash":"420465a21f8a4170693a0a4a5f7fa12108320058c83e3978da5ce2009be2cbc2","alt":"Steigende Gerade mit dem Punkt Q."}'::jsonb, '{koordinaten_vertauscht,falsche_groesse_beantwortet}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 2 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('3ffb431b-611b-4fd9-9d61-c3409c44416c'::uuid, 'ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'C', 'erklaerung',
  '# Unter der x-Achse ist y negativ.

Liegt ein Punkt unter der x-Achse, hat sein y-Wert ein Minus. Links der y-Achse hat x ein Minus.

Hier: R(3|-4). Der y-Wert ist -4, nicht 4.',
  '{"svg_hash":"9baca816d40461a7fc0c8095df8e291a6ba924d7c6ded722706d652fc548f589","alt":"Fallende Gerade mit dem Punkt R unterhalb der x-Achse."}'::jsonb, '{koordinate_vorzeichen_verloren}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 3 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('9eb20dd7-55cb-4e9b-bea1-cffa4158dd01'::uuid, 'e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, 'A', 'erklaerung',
  '# Startwert und pro Einheit

Der Startwert bei x = 0 ist b. Du liest ihn an der y-Achse ab.

Was pro Einheit dazukommt, ist m. Geh 1 nach rechts und lies ab, wie viel dazukommt.

Trifft die Gerade bei 1 nach rechts keine Kästchenecke, geh weiter, bis sie eine trifft. Dann: hoch durch rüber.

Hier: Start bei S(0|1), pro Einheit kommt 2 dazu.',
  '{"svg_hash":"91917fafd9ffadb60443611e97309cb66402c9515659d40a7b7b968489a148c4","alt":"Steigende Gerade im ersten Quadranten mit dem Startpunkt S. Ein Steigungsdreieck zeigt den Zuwachs pro Einheit."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 3 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('12274a10-0802-4093-85ac-bc2bd808c916'::uuid, 'e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, 'A', 'beispiel',
  '# Handytarif: Kosten y in Euro für x GB

1. An der y-Achse startet die Gerade bei S(0|5). Der Grundpreis ist 5 Euro.
2. Von P(1|7) nach Q(2|9) geht es $9 - 7 = 2$ hoch.
3. Jedes weitere GB kostet 2 Euro.',
  '{"svg_hash":"aff76c8eb908ea9438e01ac9700e1b8beae4608915001029a19a5c60081b52e3","alt":"Steigende Gerade im ersten Quadranten mit dem Startpunkt S und den Punkten P und Q. Ein Steigungsdreieck reicht von P bis Q."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 3 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('273b568b-3a19-461f-91e7-98833a50411b'::uuid, 'e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, 'B', 'erklaerung',
  '# Start oder pro Einheit?

Der Startwert steht an der y-Achse. Er kommt nur einmal vor.

Pro Einheit zählt, wie weit es je Kästchen nach rechts hoch geht. Das ist m.

Hier: Start 6. Rüber 2, hoch 3, also pro Einheit $3 : 2 = 1,5$. Die 6 ist der Start, nicht der Betrag pro Einheit.',
  '{"svg_hash":"7be76c11a6844db955a060fc1f0a9fad5a66105ba7403bd09af44448460f83d8","alt":"Steigende Gerade im ersten Quadranten mit dem Startpunkt S. Ein Steigungsdreieck zeigt den Zuwachs."}'::jsonb, '{groessen_vertauscht}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_graph · Kernidee 3 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('174e0dd5-925f-4960-bd0a-1b3984f37c20'::uuid, 'e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, 'C', 'erklaerung',
  '# Pro Einheit: hoch durch rüber

Wie viel kommt pro Einheit dazu? Teile, wie weit es hoch geht, durch wie weit es rüber geht.

Hier: rüber 2, hoch 5. $5 : 2 = 2,5$ pro Einheit. Nicht $2 : 5 = 0,4$.',
  '{"svg_hash":"4875726b3def140c3c62d3814c948d57a22f58a565e386930fa5587431daf3be","alt":"Steile Gerade im ersten Quadranten mit dem Startpunkt S. Ein Steigungsdreieck zeigt den Zuwachs."}'::jsonb, '{steigung_kehrwert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 1 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('60796899-1c44-4a2f-ac45-528733587178'::uuid, '525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, 'A', 'erklaerung',
  '# Wo trifft die Gerade die x-Achse?

Auf der x-Achse ist y = 0. Die Stelle x, an der die Gerade die x-Achse trifft, heißt Nullstelle.

Hier trifft sie die x-Achse in N(2|0). Die Nullstelle ist x = 2.

> Nullstelle: die Stelle x mit y = 0',
  '{"svg_hash":"7b42b675e0504bb99e3d21b0538aad0c612f710b731e2eb054710dbd55d0aee3","alt":"Steigende Gerade, die die x-Achse im Punkt N schneidet."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 1 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('baaabcfb-3483-4f49-993f-30660858c66d'::uuid, '525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, 'A', 'beispiel',
  '# Beispiel: Lies die Nullstelle ab.

1. Die Gerade gehört zu $f(x) = -2x - 2$. Such die Stelle, an der sie die x-Achse trifft.
2. Das ist N(-1|0). Dort ist y = 0.
3. Die Nullstelle ist x = -1. Probe: $-2 \cdot (-1) - 2 = 0$.',
  '{"svg_hash":"66ea12fbee4539cd0943a0b4071f7e94daa015cebd3e8f4f570704793f1f1f32","alt":"Fallende Gerade, die die x-Achse links vom Ursprung im Punkt N schneidet."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 1 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('50afea36-726a-432d-b022-81669886418b'::uuid, '525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, 'B', 'erklaerung',
  '# x-Achse, nicht y-Achse

Die Nullstelle liegt auf der x-Achse. Der Punkt auf der y-Achse gehört zum y-Achsenabschnitt.

Hier: N(2|0) ist die Nullstelle, also x = 2. S(0|1) gehört zum y-Achsenabschnitt, nicht zur Nullstelle.',
  '{"svg_hash":"c31e94e077940a096d9ae8a5a8c499c8fae02a38dcda2d6415e410876815ef6f","alt":"Flach fallende Gerade mit dem Punkt N auf der x-Achse und dem Punkt S auf der y-Achse."}'::jsonb, '{achsenabschnitt_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 1 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('b1a1dc40-3ddf-44a7-974c-1ad13704df97'::uuid, '525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, 'C', 'erklaerung',
  '# Links vom Ursprung ist x negativ.

Trifft die Gerade die x-Achse links vom Ursprung, ist die Nullstelle negativ.

Hier: N(-2|0). Die Nullstelle ist -2, nicht 2.',
  '{"svg_hash":"8abf861f2d17d54d26286b0f7e4b065f78e5e84257cfa5f9dc0c73388c6c51db","alt":"Steigende Gerade, die die x-Achse links vom Ursprung im Punkt N schneidet."}'::jsonb, '{betrag_fehler}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 2 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('46109547-49c1-49c4-83aa-2f25cfe7d75d'::uuid, '0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'A', 'erklaerung',
  '# f(x) = 0 setzen und umstellen

Setz $f(x) = 0$. Rechne b mit der Gegenrechnung auf die andere Seite. Teile dann durch m.

Bei $f(x) = 3x - 9$: $3x - 9 = 0$. Plus 9 auf beiden Seiten: $3x = 9$. Durch 3: $x = 3$.

> Nullstelle: $mx + b = 0$ nach x umstellen',
  '{"svg_hash":"e2758b8749d220b9e97fea28db5b01f44eb54826b3ed2943d573f7a645e28ed4","alt":"Steile Gerade, die die x-Achse im Punkt N schneidet."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 2 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('110256d7-6c34-4420-baec-7582cc611ae4'::uuid, '0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'A', 'beispiel',
  '# Nullstelle von f(x) = -3x + 3

1. $-3x + 3 = 0$.
2. Minus 3 auf beiden Seiten: $-3x = -3$.
3. Durch -3 teilen: $x = 1$. Probe: $-3 \cdot 1 + 3 = 0$.',
  '{"svg_hash":"b7bffd215d53bf999fcde96546d288511fc46f8423a28d61f98e328a3d29ec10","alt":"Fallende Gerade, die die x-Achse im Punkt N schneidet."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 2 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('ba35a67f-9188-4cd9-95a5-723e9e296478'::uuid, '0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'B', 'erklaerung',
  '# Zum Schluss durch m teilen

Rechne jeden Schritt rückwärts: Aus minus wird plus, aus mal wird geteilt.

Nach dem Umstellen steht dort noch $m \cdot x$. Teile durch m, dann steht x allein.

$2x - 10 = 0$. Plus 10: $2x = 10$. Durch 2: $x = 5$. Nicht 10 und nicht $10 \cdot 2 = 20$.',
  null, '{division_vergessen,falsche_gegenoperation}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 2 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('b95956d2-7e56-496c-8c78-c62b8397e7a8'::uuid, '0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'C', 'erklaerung',
  '# Passt das Vorzeichen?

Mach die Probe: Setz dein Ergebnis in f ein. Es muss 0 herauskommen.

$f(x) = 2x + 8$: $x = -4$, denn $2 \cdot (-4) + 8 = 0$. Mit 4 käme 16 heraus.

Ist m negativ: $-2x + 6 = 0$, $-2x = -6$, $x = 3$. Minus durch Minus gibt Plus.',
  '{"svg_hash":"fa8145de0f2f204b91848d75bfa04a00b82c284e545324ad5ecd435ab735374c","alt":"Steigende Gerade, die die x-Achse links vom Ursprung im Punkt N schneidet."}'::jsonb, '{betrag_fehler,vorzeichen_beim_umstellen}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 3 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('3bea9285-6950-41ef-b1e8-c7839e394235'::uuid, 'ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, 'A', 'erklaerung',
  '# Wann ist es leer?

In Sachaufgaben fragt die Nullstelle: Wann ist der Wert 0? Zum Beispiel: Wann ist der Tank leer?

Setz den Term gleich 0 und stell nach x um.

> leer, verbraucht, aufgebraucht: Wert = 0',
  '{"svg_hash":"4fbb0109cd13b3be63900e3b359d10a621da4fc3fa6155bb09e7a1d952516197","alt":"Fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 3 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('bb3a5f70-92f8-4663-83d7-8a3ac52a0f7e'::uuid, 'ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, 'A', 'beispiel',
  '# Ein Tank: V(x) = -3x + 12 Liter nach x Minuten

1. Leer heißt $V(x) = 0$: $-3x + 12 = 0$.
2. $-3x = -12$, also $x = 4$.
3. Nach 4 Minuten ist der Tank leer.',
  '{"svg_hash":"63b9c449dd8f582864c898610cb077bf6f3ac116a3ba35d623d7d2ce3c5ac4e8","alt":"Fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 3 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('3ac1a488-87e0-4d40-bc77-a070e7c4f4d2'::uuid, 'ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, 'B', 'erklaerung',
  '# Gesucht ist das Ende, nicht der Start.

Der Wert bei x = 0 ist der Start. Die Nullstelle ist der Zeitpunkt, an dem nichts mehr da ist.

$V(x) = -2x + 10$: Am Start sind 10 Liter drin. Leer: $-2x + 10 = 0$, $-2x = -10$, also nach 5 Minuten.',
  '{"svg_hash":"ded44c9a13a51fbe7ac21c19b3585cebe7de36016e2d9ed5355d763b95708cf3","alt":"Fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse."}'::jsonb, '{achsenabschnitt_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_nullstelle · Kernidee 3 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('66a3a2a5-57d1-4aac-93d3-c8979b6dc809'::uuid, 'ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, 'C', 'erklaerung',
  '# Eine Zeit ist nie negativ.

Kommt bei einer Zeit ein Minus heraus, prüf das Umstellen.

$-4x + 8 = 0$, also $-4x = -8$. Durch -4 teilen: $x = 2$. Minus durch Minus gibt Plus.',
  '{"svg_hash":"a70cdf16cc71635deb2e4c6dd66f7d76212f6de7adb64998407bf567457ccd6c","alt":"Steil fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse."}'::jsonb, '{vorzeichen_beim_umstellen}'::text[], 'entwurf')
on conflict do nothing;

insert into public.erklaer_check (kernidee_id, task_id, reihenfolge) values
  -- erklaer-steigung-k1-c1
  ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid, 1),
  -- erklaer-steigung-k1-c2
  ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid, 2),
  -- erklaer-steigung-k2-c1
  ('daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'a84e26a2-a6d2-4224-905f-a6a26f9eae56'::uuid, 1),
  -- erklaer-steigung-k2-c2
  ('daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'ddb0a7df-2c8b-4c51-84c9-1c1a8e0a05cd'::uuid, 2),
  -- erklaer-steigung-k3-c1
  ('cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, '196e845f-909a-4b77-a5c9-45c02428dd4f'::uuid, 1),
  -- erklaer-steigung-k3-c2
  ('cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'eb9da0e1-e2c6-4e7e-bc06-fc2d42a3931c'::uuid, 2),
  -- erklaer-yabschnitt-k1-c1
  ('af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, '9a7cc9ef-d806-45b3-b17e-c60364fc2fa3'::uuid, 1),
  -- erklaer-yabschnitt-k1-c2
  ('af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, '31b05259-95e6-4f67-a5db-6d75c546029e'::uuid, 2),
  -- erklaer-yabschnitt-k2-c1
  ('6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, '5bb6895e-1e3e-4cc5-8ff5-05424673198c'::uuid, 1),
  -- erklaer-yabschnitt-k2-c2
  ('6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, '8361e4fe-9f16-466e-979b-4b8d36388c4a'::uuid, 2),
  -- erklaer-yabschnitt-k3-c1
  ('d22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, '7d2e7681-e25f-449b-86ee-879fad3fdd41'::uuid, 1),
  -- erklaer-yabschnitt-k3-c2
  ('d22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, '58e43502-1bd9-43da-a51d-89e129e11a3a'::uuid, 2),
  -- erklaer-gleichung-k1-c1
  ('9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'e84865b2-c51d-4ddc-8bda-ea4c7ffe28bb'::uuid, 1),
  -- erklaer-gleichung-k1-c2
  ('9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, '8cd6769f-a01b-4c39-a21d-b43a98be7a1a'::uuid, 2),
  -- erklaer-gleichung-k2-c1
  ('e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, '111cb005-dd01-42e5-82c7-b170c2f2b16e'::uuid, 1),
  -- erklaer-gleichung-k2-c2
  ('e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, 'ca204655-57c3-46fa-8c0f-9e9ba76298f0'::uuid, 2),
  -- erklaer-gleichung-k3-c1
  ('8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, '9ea9a1bf-a20b-4ec7-8c57-d0db00b0fdd3'::uuid, 1),
  -- erklaer-gleichung-k3-c2
  ('8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, 'c370761f-1548-4e76-b0e6-a8037d67c5af'::uuid, 2),
  -- erklaer-graph-k1-c1
  ('4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'd5eabf2b-3603-4510-9ce7-3c5ae2688969'::uuid, 1),
  -- erklaer-graph-k1-c2
  ('4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, '6438c86f-ee39-4e7e-a9c1-971be7e06069'::uuid, 2),
  -- erklaer-graph-k2-c1
  ('ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, '91d726e8-4888-4275-ad51-36bc9a077543'::uuid, 1),
  -- erklaer-graph-k2-c2
  ('ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'ee23f394-6d4a-4c7b-bd94-179c203cc08c'::uuid, 2),
  -- erklaer-graph-k3-c1
  ('e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, '6b821b19-4285-48f0-93ea-0174c96c1c43'::uuid, 1),
  -- erklaer-graph-k3-c2
  ('e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, 'f96fd8ba-b402-4297-99df-c77b0651c824'::uuid, 2),
  -- erklaer-nullstelle-k1-c1
  ('525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, '985685e5-40db-479c-b16f-f18936be6239'::uuid, 1),
  -- erklaer-nullstelle-k1-c2
  ('525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, '823a8ccd-87da-47bf-84c1-11c37cff55ef'::uuid, 2),
  -- erklaer-nullstelle-k2-c1
  ('0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'ed40914f-4971-4e7a-9073-ede80153d7da'::uuid, 1),
  -- erklaer-nullstelle-k2-c2
  ('0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'f6702b76-d1f0-4f84-925d-9326b665f02d'::uuid, 2),
  -- erklaer-nullstelle-k3-c1
  ('ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, '0ae0e101-66a5-4911-a6fc-d01c78303f63'::uuid, 1),
  -- erklaer-nullstelle-k3-c2
  ('ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid, 'a56dc93d-8b1c-4f22-bede-b8195d0c71a0'::uuid, 2)
on conflict do nothing;

-- Prüfungen: Fehlbilder im Katalog, Checks nur mit Einsatz check.
do $pruefung$
begin
  if exists (select 1 from unnest('{achsenabschnitt_verwechselt,addiert_statt_subtrahiert,b_ignoriert,betrag_fehler,division_vergessen,falsche_gegenoperation,falsche_groesse_beantwortet,groessen_vertauscht,koordinate_vorzeichen_verloren,koordinaten_vertauscht,m_b_vertauscht,nur_einmal_addiert,seiten_verwechselt,steigung_kehrwert,vorzeichen_beim_umstellen,vorzeichen_ignoriert}'::text[]) s(slug)
              where not exists (select 1 from public.fehlbild_labels l where l.slug = s.slug)) then
    raise exception 'erklaer: Fehlbild fehlt in fehlbild_labels';
  end if;
  if exists (select 1 from public.erklaer_check c join public.tasks t on t.id = c.task_id
              where c.kernidee_id in ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, '6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'd22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, '9549c4e4-3b2c-44b1-b827-73a727f497d9'::uuid, 'e07a31ff-e639-4836-8c0b-da67e8749aab'::uuid, '8c60d046-68e0-4b63-b06c-23157d216f33'::uuid, '4a1c8d85-5c33-4014-8ade-4f1b0dd0adb1'::uuid, 'ec19354a-b80f-4d56-82bd-71a8fd10ac46'::uuid, 'e1d94c8d-dd53-4161-94fb-5c608c52cd6f'::uuid, '525ef0b8-dd71-4ce4-bbb7-d49f498b5c12'::uuid, '0e6523ee-a135-4f5c-9882-cc121bd0bf55'::uuid, 'ed384522-ec0a-4e86-be88-283c2c6cbb85'::uuid)
                and t.einsatz is distinct from '{check}'::text[]) then
    raise exception 'erklaer: Check-Aufgabe mit anderem Einsatz als check';
  end if;
end
$pruefung$;
