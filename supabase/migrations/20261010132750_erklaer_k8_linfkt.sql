-- Erklärsequenzen lineare_funktionen (E2b), Migration 2 von 2 — 3 Kernideen, 11 Schritte,
-- 6 Checks zu fkt_linear_steigung.
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
  ('cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'fkt_linear_steigung', 3, 'Mit der Steigung weiterrechnen', 'entwurf', 'ki')
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
  ('cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'eb9da0e1-e2c6-4e7e-bc06-fc2d42a3931c'::uuid, 2)
on conflict do nothing;

-- Prüfungen: Fehlbilder im Katalog, Checks nur mit Einsatz check.
do $pruefung$
begin
  if exists (select 1 from unnest('{b_ignoriert,nur_einmal_addiert,seiten_verwechselt,steigung_kehrwert}'::text[]) s(slug)
              where not exists (select 1 from public.fehlbild_labels l where l.slug = s.slug)) then
    raise exception 'erklaer: Fehlbild fehlt in fehlbild_labels';
  end if;
  if exists (select 1 from public.erklaer_check c join public.tasks t on t.id = c.task_id
              where c.kernidee_id in ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid)
                and t.einsatz is distinct from '{check}'::text[]) then
    raise exception 'erklaer: Check-Aufgabe mit anderem Einsatz als check';
  end if;
end
$pruefung$;
