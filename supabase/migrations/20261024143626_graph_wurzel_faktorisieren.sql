-- Bericht v3, Paket A (Gründerrunde 24.10.2026): zwei fehlende Kanten im Voraussetzungsgraphen.
--
-- Befund in Prod (24.10.2026, dbread): Weder zahl_wurzel_teilweise noch term_binom_faktorisieren ist
-- Voraussetzung eines anderen Skills. Damit führte aus „Teilweise die Wurzel ziehen“ kein Weg zum Satz
-- des Pythagoras und aus „Faktorisieren mit binomischer Formel“ keiner zu den quadratischen Funktionen.
--
-- Nur direkte Voraussetzungen, keine transitiv redundante Kante, kein Kreis (geprüft gegen Prod):
--   - Pythagoras in Figuren und Körpern: Längen wie √72 = 6√2 werden teilweise radiziert.
--     (Nicht an geo_pythagoras_hypotenuse: deren Kante zu zahl_wurzel_quadrat bliebe nötig, aber die
--     Anwendung ist die Stelle, an der die vereinfachte Wurzel gebraucht wird.)
--   - Nullstellen quadratischer Funktionen: über die faktorisierte Form, z. B. x² − 9 = (x − 3)(x + 3).
--     (Nicht an fkt_quadr_normalform: dort machte die neue Kante die bestehende Kante
--     normalform ← term_binom_quadrat transitiv redundant.)
--
-- Wirkung über den Bericht hinaus: lsa_select_next_core und die Mitbelegung lesen skill_kante. In der
-- abgestuften LSA kann ein nicht sicherer Pythagoras- bzw. Nullstellen-Knoten jetzt auf diese beiden
-- Bereiche zurückgehen.
--
-- Die Skills kommen aus früheren Inhalts-Migrationen. Fehlt einer (leere Datenbank ohne Inhalt),
-- entfällt die Kante still statt die Migration abzubrechen.
-- Rollback: supabase/rollback/20261024143626_graph_wurzel_faktorisieren.sql.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
select k.skill_key, k.voraussetzt_skill_key
from (values
  ('geo_pythagoras_anwendung', 'zahl_wurzel_teilweise'),
  ('fkt_quadr_nullstellen', 'term_binom_faktorisieren')
) as k (skill_key, voraussetzt_skill_key)
where exists (select 1 from public.skills s where s.skill_key = k.skill_key)
  and exists (select 1 from public.skills s where s.skill_key = k.voraussetzt_skill_key)
  and not exists (
    select 1 from public.skill_kante x
    where x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt_skill_key
  );
