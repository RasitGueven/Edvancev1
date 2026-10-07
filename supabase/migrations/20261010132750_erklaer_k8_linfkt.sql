-- Erklärsequenzen lineare_funktionen (E2b), Migration 2 von 2 — 3 Kernideen, 11 Schritte,
-- 3 Checks zu fkt_linear_steigung.
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

Dann teilst du: hoch durch rüber. Das Ergebnis heißt Steigung $m$.

> Steigung = hoch : rüber',
  '{"svg_hash":"c7ae41a03f07aceaa34775e22f05bae9088d00ac71d50978aceea1f2e4857a20","alt":"Steigende Gerade mit den Punkten A und B im Gitter."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 1 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('886947f3-227b-4532-8d99-37fbba5390dc'::uuid, 'e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'A', 'beispiel',
  '# Die Gerade geht durch A(0|-1) und B(2|5).

1. Von A nach B geht es 2 nach rechts.
2. Dabei geht es 6 nach oben.
3. Hoch durch rüber: $m = \frac{6}{2} = 3$.',
  '{"svg_hash":"747344299311b2b5c0a01732a5791b9e0ce5bd931d583766260c79f36e7d9077","alt":"Steile Gerade durch die Punkte A und B."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 1 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('fc1eb325-4a07-47fe-8c92-ed8d4a58c646'::uuid, 'e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, 'B', 'erklaerung',
  '# Erst hoch, dann durch rüber.

Die Zahl für oben steht oben im Bruch. Die Zahl für rechts steht unten.

Von C nach D: 3 nach rechts, 6 nach oben. Also $m = \frac{6}{3} = 2$.

Umgekehrt wäre $\frac{3}{6}$ viel zu flach.

> Steigung = hoch : rüber',
  '{"svg_hash":"3ffc0cbbe2e893df2c85a195d933e80994d9718c425e3ca7db28de098b073ec3","alt":"Steigende Gerade mit den Punkten C und D im Gitter."}'::jsonb, '{steigung_kehrwert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('55a49da6-afc7-42ae-9dfd-19276cdd4820'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'A', 'erklaerung',
  '# Rechnen statt zählen

Hoch ist der Unterschied der y-Werte. Rüber ist der Unterschied der x-Werte.

Fang oben und unten mit demselben Punkt an. Fällt die Gerade, wird hoch negativ und $m$ auch.

> $m = \frac{y_B - y_A}{x_B - x_A}$',
  '{"svg_hash":"7735f0ca14ed7fba7c6c02bf880a171295e1e4a5eb25af2920b296b08fb081c7","alt":"Flach steigende Gerade mit den Punkten A und B."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('27994093-f1ef-480a-aa56-ad4e12c5abd2'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'A', 'beispiel',
  '# Die Gerade geht durch A(-1|3) und B(2|-3).

1. Hoch: $-3 - 3 = -6$. Es geht nach unten.
2. Rüber: $2 - (-1) = 3$.
3. $m = \frac{-6}{3} = -2$. Die Gerade fällt.',
  '{"svg_hash":"edea91f0c472dc400b211140a51731c4e2aa53f94ea463b5aa69c13ecc6fa8cf","alt":"Fallende Gerade durch die Punkte A und B."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('6e73778f-f342-41aa-8fb4-90d126d27fa7'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'B', 'erklaerung',
  '# Passt das Vorzeichen?

Schau zuerst aufs Bild. Steigt die Gerade, ist $m$ positiv. Fällt sie, ist $m$ negativ.

Rechne oben und unten in derselben Reihenfolge: erst Q, dann P.

P(-2|4) und Q(2|0): $m = \frac{0 - 4}{2 - (-2)} = \frac{-4}{4} = -1$.',
  '{"svg_hash":"00aaed52234395c63ed2c763aa09b63029d3eca3d4a40af971536f1588d4d2b2","alt":"Fallende Gerade mit den Punkten P und Q."}'::jsonb, '{seiten_verwechselt}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 2 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('85a03240-9f46-4451-8965-74e24bdb0727'::uuid, 'daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'C', 'erklaerung',
  '# Die y-Werte gehören nach oben.

Im Bruch stehen oben die y-Werte und unten die x-Werte. So bleibt es: hoch durch rüber.

A(1|1) und B(4|7): $m = \frac{7 - 1}{4 - 1} = \frac{6}{3} = 2$.

Umgekehrt käme $\frac{3}{6}$ heraus. Das passt nicht zur steilen Geraden.',
  '{"svg_hash":"9d5bcf3eadadfb8ba8333414e8b05e634360b004e5e2678174e3e0232bb38dc5","alt":"Steile Gerade mit den Punkten A und B."}'::jsonb, '{steigung_kehrwert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante A · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('e1758016-20c1-4e66-a891-802d27c3e289'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'A', 'erklaerung',
  '# Jeder Schritt bringt m dazu.

Die Steigung sagt dir: So viel geht es bei einem Schritt nach rechts nach oben.

Gehst du mehrere Schritte, kommt $m$ für jeden Schritt einmal dazu.

> neuer y-Wert = alter y-Wert + Schritte · m',
  '{"svg_hash":"f928fb6c8a1a64d896708ad9ce28cc71b29dfba0d43f16c1351b17ab57ccfc0c","alt":"Steigende Gerade mit drei Punkten P, Q und R im Abstand von je einem Kästchen nach rechts."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante A · beispiel
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('7ef3f867-06f5-4ac4-9d37-734176225c1f'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'A', 'beispiel',
  '# Von P(1|-1) mit m = 2 bis x = 4

1. Von x = 1 bis x = 4 sind es 3 Schritte.
2. Jeder Schritt bringt 2 nach oben: $3 \cdot 2 = 6$.
3. $-1 + 6 = 5$. Der Punkt heißt Q(4|5).',
  '{"svg_hash":"f3ec01142dbefc08aaba3bfbf8bc6dfb8e66f62403b36b9dfb09991341ab04c8","alt":"Steigende Gerade mit den Punkten P und Q."}'::jsonb, '{}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante B · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('61343c38-a91a-4a28-9c1b-469e5eb846df'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'B', 'erklaerung',
  '# Zähl die Schritte mit.

Die Steigung gilt für einen Schritt nach rechts. Bei 4 Schritten kommt sie 4-mal dazu.

Von P nach Q mit $m = 2$: $4 \cdot 2 = 8$ nach oben, nicht nur 2.',
  '{"svg_hash":"e9695a558ee821e15d8ea9d50c2b819397352147511e5a516a16e289cdd9b803","alt":"Steigende Gerade mit den Punkten P und Q."}'::jsonb, '{nur_einmal_addiert}'::text[], 'entwurf')
on conflict do nothing;

-- fkt_linear_steigung · Kernidee 3 · Variante C · erklaerung
insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
values ('fc4d1a08-a24d-4c21-b905-1acab8de237d'::uuid, 'cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, 'C', 'erklaerung',
  '# Starte beim Punkt, nicht im Ursprung.

Diese Gerade schneidet die y-Achse nicht im Ursprung. Darum reicht $m \cdot x$ nicht.

Starte beim y-Wert des Punktes und zähl die Schritte dazu.

P(1|5), $m = 2$, gesucht y bei x = 3: $5 + 2 \cdot 2 = 9$, nicht $2 \cdot 3 = 6$.',
  '{"svg_hash":"cb77fa681a85473db06fd1f95822103df9019251a7c4636d8b1e11320d812b61","alt":"Steigende Gerade, die die y-Achse oberhalb des Ursprungs schneidet, mit den Punkten P und Q."}'::jsonb, '{b_ignoriert}'::text[], 'entwurf')
on conflict do nothing;

insert into public.erklaer_check (kernidee_id, task_id, reihenfolge) values
  -- erklaer-steigung-k1-c1
  ('e2dfaac6-3e13-4b38-b759-34f0e8e43552'::uuid, '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid, 1),
  -- erklaer-steigung-k2-c1
  ('daac561b-bc6e-4e80-be21-0281b2cd01c7'::uuid, 'a84e26a2-a6d2-4224-905f-a6a26f9eae56'::uuid, 1),
  -- erklaer-steigung-k3-c1
  ('cee436c7-dd3b-4304-87cf-e31193d2e3af'::uuid, '196e845f-909a-4b77-a5c9-45c02428dd4f'::uuid, 1)
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
