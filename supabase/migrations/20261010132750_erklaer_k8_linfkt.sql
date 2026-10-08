-- Erklärsequenzen lineare_funktionen (E2b), Migration 2 von 2 — 6 Kernideen, 23 Schritte,
-- 12 Checks zu fkt_linear_steigung, fkt_linear_yabschnitt.
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
  ('d22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, 'fkt_linear_yabschnitt', 3, 'b ist der Startwert', 'entwurf', 'ki')
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
  ('d22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid, '58e43502-1bd9-43da-a51d-89e129e11a3a'::uuid, 2)
on conflict do nothing;

-- Prüfungen: Fehlbilder im Katalog, Checks nur mit Einsatz check.
do $pruefung$
begin
  if exists (select 1 from unnest('{achsenabschnitt_verwechselt,addiert_statt_subtrahiert,b_ignoriert,betrag_fehler,groessen_vertauscht,m_b_vertauscht,nur_einmal_addiert,seiten_verwechselt,steigung_kehrwert}'::text[]) s(slug)
              where not exists (select 1 from public.fehlbild_labels l where l.slug = s.slug)) then
    raise exception 'erklaer: Fehlbild fehlt in fehlbild_labels';
  end if;
  if exists (select 1 from public.erklaer_check c join public.tasks t on t.id = c.task_id
              where c.kernidee_id in ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'af7337eb-f87c-4a1b-b90c-2331ee37d68d'::uuid, '6e2b6a04-9cec-4388-a92c-25db953337d0'::uuid, 'd22f7f2c-1295-48ce-ad14-6fdd13ce5c3a'::uuid)
                and t.einsatz is distinct from '{check}'::text[]) then
    raise exception 'erklaer: Check-Aufgabe mit anderem Einsatz als check';
  end if;
end
$pruefung$;
