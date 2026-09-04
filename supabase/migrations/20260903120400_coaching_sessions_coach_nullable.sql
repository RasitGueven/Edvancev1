-- coaching_sessions.coach_id wird nullable.
--
-- Termine entstehen aus einer Serie (slots) als Zeitraster. Wer sie
-- begleitet, ist ein eigener Arbeitsschritt in der Wochenplanung und steht
-- beim Erzeugen noch nicht fest. slots traegt bewusst keinen Coach: in der
-- Kleingruppe arbeitet jeder Schueler an seinem eigenen Pfad, und wer am
-- Mittwoch im Raum steht, kann pro Woche wechseln.
--
-- Folge fuer die Sichtbarkeit: coaching_sessions_coach_rw filtert auf
-- coach_id = auth.uid(). Ein Termin ohne Coach faellt damit durch alle
-- Coach-Policies und ist nur fuer Admin sichtbar. Das ist beabsichtigt --
-- unbesetzte Termine sind Planungsarbeit, keine Coach-Ansicht. Soll ein
-- Coach freie Termine selbst uebernehmen koennen, braucht es dafuer eine
-- eigene Policy; die gibt es hier bewusst noch nicht.

alter table public.coaching_sessions
  alter column coach_id drop not null;

comment on column public.coaching_sessions.coach_id is
  'Begleitender Coach. Null = noch nicht zugewiesen; solche Termine sind nur fuer Admin sichtbar.';
