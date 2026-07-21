-- ============================================================================
-- A09: Lizenz-/Attributionstext an der Aufgabe
--
-- Die VERA-8-Abbildungen stehen unter CC BY 4.0 (IQB). CC BY verlangt beim
-- Einblenden eine Namensnennung — Titel, Autor, Quelle, Lizenz, soweit
-- verfuegbar (TASL). Ohne einen Ort, an dem dieser Text steht, koennen wir das
-- Bild nicht rechtssicher zeigen: der Lizenzstatus im Quellenbeleg
-- (_grounding.lizenz_status) sagt nur, DASS attribuiert werden muss, nicht WIE.
--
-- EIN Feld an der AUFGABE, bewusst nicht pro Asset und nicht pro Teilaufgabe:
--   Ein Item traegt in der Praxis eine Abbildung, und selbst bei mehreren stammen
--   sie aus derselben Quelle mit derselben Lizenz. Ein Lizenzfeld je Bild waere
--   dieselbe Zeile mehrfach — mit dem Risiko, dass sie auseinanderlaeuft.
--
-- NULLABLE, weil die grosse Mehrheit der Items kein Bild hat und damit auch
--   nichts zu attribuieren. Die Pflicht ist bedingt ("Bild da → Text da") und
--   gehoert deshalb ins Freigabe-Gate des Autoren-Tools (flags.ts,
--   licenceMissing), nicht in einen CHECK: ein CHECK ueber assets waere bei
--   jedem Import und jedem Altbestand-Update im Weg.
--
-- KEIN Schueler-Feld auf diesem Weg: lsa_question_payload baut den Payload aus
--   einer Whitelist (nie Durchreichen), lsa_public_assets reicht je Asset nur
--   { url, alt } durch. Der Lizenztext wird spaeter beim Einblenden bewusst
--   dazugeholt — er kommt nicht versehentlich mit.
-- ============================================================================

begin;

alter table tasks
  add column if not exists licence_text text;

comment on column tasks.licence_text is
  'Der einblendbare Attributionstext der Aufgabe (CC BY 4.0 / TASL). NULL = '
  'keiner noetig (Aufgabe ohne Bild) oder noch nicht gepflegt. Vorbefuellt aus '
  'dem Quellenbeleg (buildAttribution in src/lib/authoring/attribution.ts), vom '
  'Pfleger ueberschreibbar — eingebettetes Fremdmaterial in einer VERA-Aufgabe '
  'braucht eine abweichende Nennung. Pflicht, sobald tasks.assets nicht leer '
  'ist; durchgesetzt im Freigabe-Gate des Autoren-Tools (A09).';

commit;
