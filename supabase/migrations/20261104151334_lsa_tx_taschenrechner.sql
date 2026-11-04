-- LSA-TX (04.11.2026): Taschenrechner fuer 12 Aufgaben zu Aehnlichkeit, zentrischer Streckung und Strahlensaetzen.
--
-- Entscheidung Rasit 04.11.2026 (docs/lsa-tx-taschenrechner.md): Geprueft wird der Ansatz, nicht das Rechnen mit
-- Dezimalzahlen; ohne Rechner wuerde ein Rechenfehler als Luecke im Strahlensatz gebucht.
--
-- Reine Daten (DML), kein DDL. Schreibt nur tasks.taschenrechner; Text, Loesung und Status bleiben. Der Trigger
-- tasks_pruef_version zaehlt pruef_version hoch, kein Trigger setzt dabei den Status zurueck (geprueft per pg_proc).
-- Jede Zeile trifft die Aufgabe per ID und nur mit dem alten Wert (taschenrechner = false). Alle 12 sind nicht
-- freigegeben (draft); die Freigabe bleibt, wie sie ist.
-- Ohne die Aufgaben (Neuaufbau in der CI) aendert die Migration nichts und laeuft trotzdem durch.

with ziel(id) as (values
   ('93e695a0-efbe-490f-b931-299545068f26'::uuid)  -- Flaechen und Volumen bei Aehnlichkeit: Wandbild, Liter Farbe
  ,('e9add498-a88c-46e5-8905-25a5d1ec9ce7'::uuid)  -- Flaechen und Volumen bei Aehnlichkeit: Volumen grosser Quader
  ,('421cad19-9629-4f75-8e01-c63e86692329'::uuid)  -- Erster Strahlensatz: Metallstangen, B bis D
  ,('cff72027-8549-47c3-a12c-e1ff333fa4fd'::uuid)  -- Erster Strahlensatz: Strassen, B bis D
  ,('f06ce97a-7c42-400e-8cb0-7b53f6f98be1'::uuid)  -- Erster Strahlensatz: B bis D
  ,('f8083d9b-72c9-4a72-a0c0-0adb8787bfce'::uuid)  -- Erster Strahlensatz: S bis D
  ,('59b87dce-2116-4855-9e94-54dff17ff05a'::uuid)  -- Zweiter Strahlensatz: C bis D
  ,('59bdf7d8-248a-4c9a-8f96-01aba8f098c1'::uuid)  -- Zweiter Strahlensatz: A bis B
  ,('9e52eb0d-bf0a-4770-aec2-d9598a087c45'::uuid)  -- Zweiter Strahlensatz: S bis A
  ,('ae9f75b4-3990-401b-bab1-479503f08594'::uuid)  -- Zweiter Strahlensatz: Stab und Baum
  ,('51490b4f-18e9-4a15-8ee2-7e160526f2d9'::uuid)  -- Streckfaktor und zentrische Streckung: kuerzeste Bildseite
  ,('75cb4657-94a9-4348-b6b1-807f241f4914'::uuid)  -- Streckfaktor und zentrische Streckung: Originalstrecke
)
update public.tasks t
   set taschenrechner = true
  from ziel
 where t.id = ziel.id
   and t.taschenrechner = false;

do $$
begin
  if exists (select 1 from public.tasks
              where taschenrechner = false
                and id in ('93e695a0-efbe-490f-b931-299545068f26', 'e9add498-a88c-46e5-8905-25a5d1ec9ce7',
                           '421cad19-9629-4f75-8e01-c63e86692329', 'cff72027-8549-47c3-a12c-e1ff333fa4fd',
                           'f06ce97a-7c42-400e-8cb0-7b53f6f98be1', 'f8083d9b-72c9-4a72-a0c0-0adb8787bfce',
                           '59b87dce-2116-4855-9e94-54dff17ff05a', '59bdf7d8-248a-4c9a-8f96-01aba8f098c1',
                           '9e52eb0d-bf0a-4770-aec2-d9598a087c45', 'ae9f75b4-3990-401b-bab1-479503f08594',
                           '51490b4f-18e9-4a15-8ee2-7e160526f2d9', '75cb4657-94a9-4348-b6b1-807f241f4914')) then
    raise exception 'LSA-TX: Taschenrechner nicht bei allen 12 Aufgaben gesetzt';
  end if;
end $$;
