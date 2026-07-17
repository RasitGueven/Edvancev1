-- ============================================================================
-- A08: Bild-Notwendigkeit — die didaktische Frage, getrennt vom Bild-Zustand
--
-- Der technische EMF-Befund (Bild vorhanden / kaputt / fehlt — C10) sagt NICHTS
-- darueber aus, ob die Aufgabe INHALTLICH eine Abbildung braucht. Das sind zwei
-- Fragen: "ist ein Bild da und heil?" (Technik, tasks.assets) und "braucht die
-- Aufgabe ueberhaupt eines?" (Didaktik, hier). Diese Migration gibt der zweiten
-- Frage einen eigenen Platz — pro Item UND pro Teilaufgabe.
--
-- Semantik ueberall gleich:
--   NULL   = noch nicht beurteilt (kein Vorschlag, keine Heuristik — Handarbeit)
--   true   = braucht eine Abbildung
--   false  = braucht keine Abbildung
--
-- Kern in einem Feld + einer Konvention:
--   1. tasks.needs_image boolean NULL — betrifft den Stamm (question).
--   2. Pro Element in tasks.parts[] ein optionales `needs_image` (boolean). Fehlt
--      das Feld, gilt "nicht beurteilt" (NULL-Semantik) — KEINE Altdaten-Migration.
--
-- WARUM keine Aenderung an lsa_parts_valid: der Validator hat KEIN festes Set
--   erlaubter Keys — er verlangt nr/kind/prompt (+MC-Optionen), verbietet jedes
--   Loesungsfeld und prueft eindeutige nr. Ein zusaetzliches optionales
--   `needs_image` ist damit bereits zugelassen, ohne die Validierung aufzuweichen.
--   Der pgTAP-Nachweis (inv9) zeigt: ein Teilaufgaben-`needs_image` besteht den
--   CHECK, und es taucht auf KEINER Ebene im Schueler-Payload auf.
--
-- WARUM kein Eintrag in der Schueler-Whitelist: needs_image ist ein Autoren-Feld,
--   kein Frage-Feld. lsa_question_payload baut den Payload aus einer Whitelist
--   (nie Durchreichen) und lsa_public_parts kopiert je Teilaufgabe nur
--   nr/kind/prompt/unit/table/options — needs_image bleibt draussen, item- wie
--   teilaufgabenseitig. Nichts hier zu tun; inv9 pinnt es fest.
-- ============================================================================

begin;

alter table tasks
  add column if not exists needs_image boolean;

comment on column tasks.needs_image is
  'Didaktik, nicht Technik: Braucht der Stamm eine Abbildung? NULL = noch nicht '
  'beurteilt, true/false = beurteilt. Menschliche Fachentscheidung, keine '
  'Heuristik. Getrennt vom Bild-Zustand (tasks.assets / C10-EMF-Befund). '
  'Pro Teilaufgabe traegt tasks.parts[].needs_image dieselbe Frage granular. '
  'KEIN Schueler-Feld — bleibt aus lsa_question_payload draussen (A08).';

commit;
